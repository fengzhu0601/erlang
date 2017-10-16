%%%-------------------------------------------------------------------
%%% @author yujian
%%% @doc 时空隙缝
%%%-------------------------------------------------------------------
-module(daily_activity_handle_client).

-include("inc.hrl").
-include("player.hrl").
-include("handle_client.hrl").
-include("daily_struct.hrl").
-include("rank.hrl").
-include("main_ins_struct.hrl").
-include("load_cfg_daily_activity.hrl").
-include("system_log.hrl").
-include("item_new.hrl").

handle_client({?PUSH_DAILY_ACTIVITY_INFO, {Type}}) -> handle_client(?PUSH_DAILY_ACTIVITY_INFO, {Type});
handle_client({?MSG_DAILY_ACTIVITY_GET_NEW_ACTIVITY_INFO, {Type}}) -> handle_client(?MSG_DAILY_ACTIVITY_GET_NEW_ACTIVITY_INFO, {Type});
handle_client({Pack, Arg}) ->
    case task_open_fun:is_open(?OPEN_DAILY_ACTIVITY) of
        ?false -> ?return_err(?ERR_NOT_OPEN_FUN);
        ?true -> handle_client(Pack, Arg)
    end.

%% @doc 1.随机服务端副本ID 2.存储玩家选择副本ID 3.进入第一个场景 4.返回服务器端副本
handle_client(?MSG_SELECT_IDS, {SceneId1, SceneId2, SceneId3, SceneId4}) ->
    case daily_activity_mng:select_scene([SceneId1, SceneId2, SceneId3, SceneId4]) of
        {error, Other} -> ?return_err(Other);
        _ -> ?player_send(daily_activity_sproto:pkg_msg(?MSG_SELECT_IDS, {}))
    end;

%% 进入副本
handle_client(?MSG_ENTER_SCENE, {Type}) when Type =< ?DailyType_3 ->
    case daily_activity_mng:is_activity_opening(Type) of
        true ->
            case daily_activity_mng:count(Type) of
                {error, Other} -> ?return_err(Other);
                {DailyData, FreeCount, _PayCount} ->
                    IsFight = if
                        DailyData#daily_data.daily_fight_count < FreeCount ->
                            {ok, DailyData#daily_data{daily_fight_count = DailyData#daily_data.daily_fight_count + 1, last_time = com_time:now()}};
                        DailyData#daily_data.daily_pay_count < DailyData#daily_data.daily_buy_count ->
                            {ok, DailyData#daily_data{daily_pay_count = DailyData#daily_data.daily_pay_count + 1, last_time = com_time:now()}};
                        true ->
                            {error, ?ERR_MAX_COUNT}
                    end,
                    case IsFight of
                        {ok, UpdateDailyData} ->
                            daily_activity_mng:update_type(UpdateDailyData),
                            case Type of
                                ?DailyType_1 ->
                                    [SceneId | _] = daily_activity_mng:get_scene(?DailyType_1),
                                    main_ins_mod:handle_start(daily_activity_mng, {?DailyType_1, SceneId}),
                                    ?player_send(daily_activity_sproto:pkg_msg(?MSG_ENTER_SCENE, {}));
                                ?DailyType_2 ->
                                    [SceneId | _] = daily_activity_mng:get_scene(?DailyType_2),
                                    main_ins_mod:handle_start(daily_activity_mng, {?DailyType_2, {SceneId, ?DAILYTYPE_2_TIMEOUT}}),
                                    ?player_send(daily_activity_sproto:pkg_msg(?MSG_ENTER_SCENE, {}));
                                ?DailyType_3 ->
                                    {[SceneId, SceneId2, SceneId3, SceneId4], _PlayerSelectScene} = UpdateDailyData#daily_data.ex,
                                    main_ins_mod:handle_start(daily_activity_mng, {?DailyType_3, SceneId, [SceneId, SceneId2, SceneId3, SceneId4]}),
                                    ?player_send(<<?MSG_ENTER_SCENE:16, SceneId:32, SceneId2:32, SceneId3:32, SceneId4:32>>)
                            end;
                        {error, Other} -> ?return_err(Other)
                    end
            end;
        _ ->
            ?ERROR_LOG("activity ~p not open", [Type]),
            pass
    end;

handle_client(?MSG_ENTER_SCENE, {Type}) when Type == ?DailyType_6->
    case whereis(daily_activity_service) of
        undefined ->
            ?ERROR_LOG("activity ~p not open", [Type]),
            pass;
        _ ->
            PlayerFishingDailyTab = get(?pd_fishing_daily_tab),
            CurFishingId = PlayerFishingDailyTab#player_fishing_daily_tab.fishing_id,
            NewFishingId = daily_activity_service:get_fishing_id_info(),
            if
                CurFishingId =:= NewFishingId ->
                    push_fishing_info();
                true ->
                    put(?pd_fishing_daily_tab,PlayerFishingDailyTab#player_fishing_daily_tab{
                        fish_bait = 30,
                        buy_fish_bait = 0,
                        fish_net = 0,
                        fishing_id = NewFishingId
                    }),
                    push_fishing_info()
            end,
            %% 所有钓鱼场景的Id
            NotFullFishingRoomList = daily_activity_service:get_not_full_fishing_room(),
            case NotFullFishingRoomList of
                [] ->
                    [SceneId | _] = daily_activity_mng:get_scene(?DailyType_6),
                    main_ins_mod:handle_start(daily_activity_mng, {?DailyType_6, SceneId});
                _ ->
                    [SceneId | _] = daily_activity_mng:get_scene(?DailyType_6),
                    Roomid = lists:last(NotFullFishingRoomList),
                    main_ins_mod:handle_start(daily_activity_mng, {fish_room, Roomid, SceneId})
            end,
            ?player_send(daily_activity_sproto:pkg_msg(?MSG_ENTER_SCENE, {}))
    end;

handle_client(?MSG_ENTER_SCENE, {Type}) ->
    case daily_activity_mng:is_activity_opening(Type) of
        true ->
            {Times, _} = daily_activity_mng:get_activity_info(Type),
            case Times > 0 of
                true ->
                    case Type of
                        ?DailyType_4 ->
                            [SceneId | _] = daily_activity_mng:get_scene(?DailyType_4),
                            main_ins_mod:handle_start(daily_activity_mng, {?DailyType_4, SceneId}),
                            ?player_send(daily_activity_sproto:pkg_msg(?MSG_ENTER_SCENE, {})),
                            DailyData = daily_activity_mng:lookup_type(Type),
                            NewData = DailyData#daily_data{last_time = com_time:now()},
                            daily_activity_mng:update_type(NewData);
                        ?DailyType_5 ->
                            [SceneId | _] = daily_activity_mng:get_scene(?DailyType_5),
                            main_ins_mod:handle_start(daily_activity_mng, {?DailyType_5, SceneId}),
                            ?player_send(daily_activity_sproto:pkg_msg(?MSG_ENTER_SCENE, {})),
                            DailyData = daily_activity_mng:lookup_type(Type),
                            NewData = DailyData#daily_data{last_time = com_time:now()},
                            daily_activity_mng:update_type(NewData);
                        _ ->
                            ?ERROR_LOG("known daily_activity type:~p", [Type]),
                            pass
                    end;
                _ ->
                    ?return_err(?ERR_MAX_COUNT)
            end;
        _ ->
            ?ERROR_LOG("activity ~p not open", [Type]),
            pass
    end;

handle_client(?MSG_DAILY_ACTIVITY_SWEEP, {Type}) when Type =< ?DailyType_3 ->
    case daily_activity_mng:is_activity_opening(Type) of
        true ->
            SweepCost = case Type of
                ?DailyType_1 ->
                    load_vip_new:get_daily_activity1_sweep_info_by_vip_level(attr_new:get_vip_lvl());
                ?DailyType_2 ->
                    load_vip_new:get_daily_activity2_sweep_info_by_vip_level(attr_new:get_vip_lvl());
                ?DailyType_3 ->
                    load_vip_new:get_daily_activity3_sweep_info_by_vip_level(attr_new:get_vip_lvl());
                _ ->
                    error
            end,
            case is_integer(SweepCost) of
                true ->
                    case daily_activity_mng:count(Type) of
                        {error, Other} -> ?return_err(Other);
                        {DailyData, FreeCount, _PayCount} ->
                            Ret = if
                                DailyData#daily_data.daily_fight_count < FreeCount ->   %% 还有免费次数
                                    {ok, SweepCost, DailyData#daily_data{daily_fight_count = DailyData#daily_data.daily_fight_count + 1}};
                                DailyData#daily_data.daily_pay_count  < DailyData#daily_data.daily_buy_count ->      %% 还有购买次数
                                    {ok, SweepCost, DailyData#daily_data{daily_pay_count = DailyData#daily_data.daily_pay_count + 1}};
                                true ->
                                    {error, ?ERR_MAX_COUNT}
                            end,
                            case Ret of
                                {ok, Cost, NewData} ->
                                    case game_res:try_del([{?PL_DIAMOND, Cost}], ?FLOW_REASON_DAILY_ACTIVITY) of
                                        ok ->
                                            daily_activity_mng:update_type(NewData),
                                            RetPrize = case Type of
                                                ?DailyType_1 ->
                                                    {_, Exp} = daily_activity_mng:get_daily_activity_1_prize(get(?pd_level)),
                                                    PrizeInfo = prize:double_items(3000, [{?PL_EXP, Exp}]),
                                                    game_res:try_give_ex(PrizeInfo, ?S_MAIL_DIALY_PRIZE, ?FLOW_REASON_DAILY_ACTIVITY),
                                                    PrizeInfo;
                                                ?DailyType_2 ->
                                                    {_, Longjing} = daily_activity_mng:get_daily_activity_2_prize(get(?pd_level)),
                                                    PrizeInfo = prize:double_items(3000, [{?YUANSU_MOLI, Longjing}]),
                                                    game_res:try_give_ex(PrizeInfo, ?S_MAIL_DIALY_PRIZE, ?FLOW_REASON_DAILY_ACTIVITY),
                                                    PrizeInfo;
                                                ?DailyType_3 ->
                                                    {_, _, Prize} = daily_activity_mng:get_daily_activity_3_prize(get(?pd_level)),
                                                    prize:prize_mail_2(3000, Prize, ?S_MAIL_DIALY_PRIZE, ?FLOW_REASON_DAILY_ACTIVITY)
                                            end,
                                            ?player_send(daily_activity_sproto:pkg_msg(?MSG_DAILY_ACTIVITY_SWEEP, {RetPrize}));
                                        {error, _} ->
                                            ?return_err(?ERR_COST_DIAMOND_FAIL)
                                    end;
                                {error, Other} ->
                                    ?return_err(Other)
                            end
                    end;
                _ ->
                    ?ERROR_LOG("daily_activity can not sweep, vip = ~p", [attr_new:get_vip_lvl()])
            end;
        _ ->
            ?ERROR_LOG("activity ~p not open", [Type]),
            pass
    end;
handle_client(?MSG_DAILY_ACTIVITY_SWEEP, {Type}) ->
    case daily_activity_mng:is_activity_opening(Type) of
        true ->
            SweepCost = case Type of
                ?DailyType_4 ->
                    load_vip_new:get_daily_activity4_sweep_info_by_vip_level(attr_new:get_vip_lvl());
                ?DailyType_5 ->
                    load_vip_new:get_daily_activity5_sweep_info_by_vip_level(attr_new:get_vip_lvl());
                _ ->
                    error
            end,
            case is_integer(SweepCost) of
                true ->
                    {Times, _} = daily_activity_mng:get_activity_info(Type),
                    case Times > 0 of
                        true ->
                            case game_res:try_del([{?PL_DIAMOND, SweepCost}], ?FLOW_REASON_DAILY_ACTIVITY) of
                                ok ->
                                    DailyData = daily_activity_mng:lookup_type(Type),
                                    daily_activity_mng:update_type(DailyData#daily_data{last_time = com_time:now()}),
                                    RetPrize = case Type of
                                        ?DailyType_4 ->
                                            {_, Money} = daily_activity_mng:get_daily_activity_4_prize(get(?pd_level)),
                                            PrizeInfo = [{?PL_MONEY, Money}],
                                            game_res:try_give_ex(PrizeInfo, ?S_MAIL_DIALY_PRIZE, ?FLOW_REASON_DAILY_ACTIVITY),
                                            PrizeInfo;
                                        ?DailyType_5 ->
                                            {_, {YinStar, JinStar}} = daily_activity_mng:get_daily_activity_5_prize(get(?pd_level)),
                                            PrizeInfo = [{?PL_YINXING, YinStar}, {?PL_JINXING, JinStar}],
                                            game_res:try_give_ex(PrizeInfo, ?S_MAIL_DIALY_PRIZE, ?FLOW_REASON_DAILY_ACTIVITY),
                                            PrizeInfo
                                    end,
                                    ?player_send(daily_activity_sproto:pkg_msg(?MSG_DAILY_ACTIVITY_SWEEP, {RetPrize}));
                                {error, _} ->
                                    ?return_err(?ERR_COST_DIAMOND_FAIL)
                            end;
                        _ ->
                            ?return_err(?ERR_MAX_COUNT)
                    end;
                _ ->
                    ?ERROR_LOG("daily_activity can not sweep, vip = ~p", [attr_new:get_vip_lvl()])
            end;
        _ ->
            ?ERROR_LOG("activity ~p not open", [Type]),
            pass
    end;

handle_client(?MSG_DAILY_ACTIVITY_BY_CHALLENGE_TIMES, {Type, Num}) ->
    %% 购买挑战次数对应vip表
    VipLevel = get(?pd_vip),
    CostList =
        case Type of
            ?DailyType_1 ->
                load_vip_new:get_daily_activity_1_by_vip_level(VipLevel);
            ?DailyType_2 ->
                load_vip_new:get_daily_activity_2_by_vip_level(VipLevel);
            ?DailyType_3 ->
                load_vip_new:get_daily_activity_3_by_vip_level(VipLevel);
            _ ->
                ?player_send(daily_activity_sproto:pkg_msg(?MSG_DAILY_ACTIVITY_BY_CHALLENGE_TIMES, {1}))
        end,
    PayBattleCount = load_vip_new:get_vip_new_pay_times(CostList),
    DailyData = daily_activity_mng:lookup_type(Type),
    BuyCount = DailyData#daily_data.daily_buy_count,
    if
        BuyCount + Num > PayBattleCount ->
            ?player_send(daily_activity_sproto:pkg_msg(?MSG_DAILY_ACTIVITY_BY_CHALLENGE_TIMES, {1}));
            %%?return_err(?ERR_BUY_CHALLENGE_NOT_ENOUGH);
        true ->
            PayCostList = load_vip_new:get_vip_new_pay_list(CostList),
            CostNum = get_battle_cost(BuyCount, Num, PayCostList),
            case game_res:try_del([{?PL_DIAMOND, CostNum}], ?FLOW_REASON_BUY_FUBEN_TIMES) of
                ok ->
                    daily_activity_mng:update_type(DailyData#daily_data{daily_buy_count = DailyData#daily_data.daily_buy_count + Num}),
                    ?player_send(daily_activity_sproto:pkg_msg(?MSG_DAILY_ACTIVITY_BY_CHALLENGE_TIMES, {0}));
                {error, _Other} ->
                    ?player_send(daily_activity_sproto:pkg_msg(?MSG_DAILY_ACTIVITY_BY_CHALLENGE_TIMES, {1}))
            end
    end;

handle_client(?MSG_DAILY_ACTIVITY_GET_NEW_ACTIVITY_INFO, {Type}) ->
    case Type =:= ?DailyType_4 orelse Type =:= ?DailyType_5 of
        true ->
            Ret = daily_activity_mng:get_activity_info(Type),
            ?player_send(daily_activity_sproto:pkg_msg(?MSG_DAILY_ACTIVITY_GET_NEW_ACTIVITY_INFO, Ret));
        _ ->
            ?player_send(daily_activity_sproto:pkg_msg(?MSG_DAILY_ACTIVITY_GET_NEW_ACTIVITY_INFO, {0, 0}))
    end;

handle_client(?MSG_DAILY_ACTIVITY_6_FISHING, {Type}) ->
    #player_fishing_daily_tab{
                fish_bait=FishBait,
                fish_net = FishNet
            } = FishingDailyTab = get(?pd_fishing_daily_tab),
    Vip = get(?pd_vip),
    Reply =
        if
            Type =< 3 ->
                if
                    FishBait =< 0 ->
                        {error, no_times};
                    true ->
                        ok
                end;
            true ->
                List = load_vip_new:get_fish_net_count_by_vip_level(Vip),
                if
                    FishNet >= length(List) ->
                        {error, no_times};
                    true ->
                        CostFishBait = lists:nth(FishNet+1,List),
                        if
                            CostFishBait > FishBait->
                                {error, no_times};
                            true ->
                                CostFishBait
                        end
                end
        end,
    case Reply of
        {error, no_times} ->
            pass;
        ok ->
            put(?pd_fishing_daily_tab, FishingDailyTab#player_fishing_daily_tab{fish_bait = FishBait - 1}),
            PrizeId = load_cfg_fishing_prize:get_fishing_prize_by_type(Type),
            PrizeInfo = prize:prize_mail(PrizeId, ?S_MAIL_FISHING, ?FLOW_REASON_FISHING),
            push_fishing_info(),
            ?player_send(daily_activity_sproto:pkg_msg(?MSG_DAILY_ACTIVITY_6_FISHING, {PrizeInfo}));
        CostFishNet ->
            put(?pd_fishing_daily_tab,
                FishingDailyTab#player_fishing_daily_tab{fish_bait = FishBait - CostFishNet, fish_net = FishNet + 1}),
            PrizeId = load_cfg_fishing_prize:get_fishing_prize_by_type(Type),
            PrizeInfo = prize:prize_mail(PrizeId, ?S_MAIL_FISHING, ?FLOW_REASON_FISHING),
            push_fishing_info(),
            ?player_send(daily_activity_sproto:pkg_msg(?MSG_DAILY_ACTIVITY_6_FISHING, {PrizeInfo}))
    end;


handle_client(?MSG_DAILY_ACTIVITY_6_BUY_FISHING_COUNT, {Count}) ->
    case get(?pd_fishing_daily_tab) of
        0 ->
            ?player_send(daily_activity_sproto:pkg_msg(?MSG_DAILY_ACTIVITY_6_BUY_FISHING_COUNT, {1}));
        PlayerFishingDailyTab ->
            BuyFishBaitCount = PlayerFishingDailyTab#player_fishing_daily_tab.buy_fish_bait,
            FishBaitCount = PlayerFishingDailyTab#player_fishing_daily_tab.fish_bait,
            {MaxBuyCount, GiveFishBait, CostCount } = misc_cfg:get_fish_count(),
            if
                BuyFishBaitCount+Count > MaxBuyCount ->
                    ?player_send(daily_activity_sproto:pkg_msg(?MSG_DAILY_ACTIVITY_6_BUY_FISHING_COUNT, {1}));
                true ->
                    case game_res:try_del([{?DIAMOND_BID,CostCount}], ?FLOW_REASON_FISHING) of
                        {error, _E} ->
                            ?player_send(daily_activity_sproto:pkg_msg(?MSG_DAILY_ACTIVITY_6_BUY_FISHING_COUNT, {1}));
                        _ ->
                            put(?pd_fishing_daily_tab,
                                PlayerFishingDailyTab#player_fishing_daily_tab{
                                    buy_fish_bait = BuyFishBaitCount + Count,
                                    fish_bait = FishBaitCount + GiveFishBait}),
                            push_fishing_info(),
                            ?player_send(daily_activity_sproto:pkg_msg(?MSG_DAILY_ACTIVITY_6_BUY_FISHING_COUNT, {0}))
                    end
            end
    end;

handle_client(_Msg, _Arg) ->
    ok.

get_battle_cost(Count, Num, List) ->
    SubList = lists:sublist(List, Count+1, Num),
    lists:sum(SubList).

push_fishing_info() ->
    case get(?pd_fishing_daily_tab) of
        0 ->
            pass;
        PlayerFishingDailyTab ->
            #player_fishing_daily_tab{
                fish_bait = FishBait,
                buy_fish_bait = BuyFishBait,
                fish_net = FishNet
            } = PlayerFishingDailyTab,
            Vip = get(?pd_vip),
            List = load_vip_new:get_fish_net_count_by_vip_level(Vip),
            ?player_send(daily_activity_sproto:pkg_msg(?PUSH_MSG_FISHING_INFO, {FishBait, BuyFishBait, (length(List) - FishNet)}))
    end.

