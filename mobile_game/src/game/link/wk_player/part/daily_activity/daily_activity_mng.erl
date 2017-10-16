%%%-------------------------------------------------------------------
%%% @author yujian
%%% @doc 日常活动
%%% Created : 19. 六月 2015 上午10:38
%%%-------------------------------------------------------------------
-module(daily_activity_mng).

-include_lib("pangzi/include/pangzi.hrl").
%-include_lib("config/include/config.hrl").

-include("inc.hrl").
-include("player.hrl").
-include("player_mod.hrl").
-include("main_ins_struct.hrl").

-include("scene.hrl").
-include("scene_monster.hrl").
-include("daily_struct.hrl").
-include("rank.hrl").
-include("item.hrl").
-include("load_vip_right.hrl").
-include("day_reset.hrl").
-include("load_cfg_daily_activity.hrl").
-include("load_cfg_main_ins.hrl").
-include("system_log.hrl").
-include("load_vip_new_cfg.hrl").
-include("item_new.hrl").

-export
([
    count/1,
    get_scene/1,
    lookup_cfg/3,
    select_scene/1, %选择boss场景
    lookup_type/1,
    update_type/1,  %获取某个活动的数据, 更新某个活动的数据
    ins_complete/3, %副本回调函数
    next_scene_id/2,
    reset_clock/0,
    send_cur_point/2,
    get_daily_activity_1_prize/1,
    get_daily_activity_2_prize/1,
    get_daily_activity_3_prize/1,
    get_daily_activity_4_prize/1,
    get_daily_activity_5_prize/1,
    is_activity_opening/1,
    get_activity_info/1,
    send_rank_prize/2
]).

load_db_table_meta() ->
    [
        #db_table_meta{
            name = ?player_daily_tab,
            fields = ?record_fields(?player_daily_tab),
            shrink_size = 30,
            flush_interval = 3
        },
        #db_table_meta{
            name = ?player_fishing_daily_tab,
            fields = ?record_fields(?player_fishing_daily_tab),
            shrink_size = 30,
            flush_interval = 3
        }
    ].

create_mod_data(_SelfId) ->
    ok.

load_mod_data(PlayerId) ->
    case dbcache:lookup(?player_daily_tab, PlayerId) of
        [] ->
            put(
            ?pd_daily_activity_tab,
            #player_daily_tab{
                player_id = PlayerId,
                activity_data = [
                    #daily_data{daily_id = 1},
                    #daily_data{daily_id = 2},
                    #daily_data{daily_id = 3},
                    #daily_data{daily_id = 4},
                    #daily_data{daily_id = 5}
                ]
            });
        [Tab] ->
            put(?pd_daily_activity_tab, Tab)
    end,

    case dbcache:lookup(?player_fishing_daily_tab, PlayerId) of
        [] ->
            put(?pd_fishing_daily_tab,
                #player_fishing_daily_tab{
                    player_id = PlayerId,
                    fish_bait = 30
                });
        [FishTab] ->
            put(?pd_fishing_daily_tab, FishTab)
    end.

init_client() ->
    Fun = fun(Type) ->
        case count(Type) of
            {error, _Other} -> ok;
            {DailyData, FreeCount, PayCount} ->
                BuyCount = DailyData#daily_data.daily_buy_count,
                UseFightCount = DailyData#daily_data.daily_fight_count,
                UsePayCount = DailyData#daily_data.daily_pay_count,
                Max = DailyData#daily_data.daily_asset,
                case Type of
                    ?DailyType_1 ->
                        ?player_send(<<?PUSH_DAILY_ACTIVITY_INFO:16, ?DailyType_1, BuyCount, UseFightCount, FreeCount, UsePayCount, PayCount, Max>>);
                    ?DailyType_2 ->
                        ?player_send(<<?PUSH_DAILY_ACTIVITY_INFO:16, ?DailyType_2, BuyCount, UseFightCount, FreeCount, UsePayCount, PayCount, Max:32>>);
                    ?DailyType_3 ->
                        ?player_send(daily_activity_sproto:pkg_msg(?PUSH_DAILY_ACTIVITY_INFO, {?DailyType_3, BuyCount, UseFightCount, FreeCount, UsePayCount, PayCount}))
                end
        end
    end,
    Fun(?DailyType_1),
    Fun(?DailyType_2),
    Fun(?DailyType_3),
    {Times4, _} = get_activity_info(?DailyType_4),
    Asset4 = case lookup_type(?DailyType_4) of
        Data1 when is_record(Data1, daily_data) ->
            Data1#daily_data.daily_asset;
        _ ->
            0
    end,
    {Times5, _} = get_activity_info(?DailyType_5),
    Asset5 = case lookup_type(?DailyType_5) of
        Data2 when is_record(Data2, daily_data) ->
            Data2#daily_data.daily_asset;
        _ ->
            0
    end,
    ?player_send(<<?PUSH_DAILY_ACTIVITY_INFO:16, ?DailyType_4, 0, 0, Times4, 0, 0, Asset4:32>>),
    ?player_send(<<?PUSH_DAILY_ACTIVITY_INFO:16, ?DailyType_5, 0, 0, Times5, 0, 0, Asset5:32>>).

view_data(Acc) -> Acc.

handle_frame({?frame_vip_levelup, _OldLevel}) ->
    init_client();

handle_frame(Frame) -> ?err({unknown_frame, Frame}).

handle_msg(_FromMod, {fishing_over}) ->
    ?INFO_LOG("fishing_over======="),
    ?player_send(daily_activity_sproto:pkg_msg(?PUSH_MSG_FISHING_OVER, {}));
handle_msg(_FromMod, Msg) -> ?err({unknown_msg, Msg}).

online() -> ok.

offline(_SelfId) -> ok.

save_data(_SelfId) ->
    case get(?pd_daily_activity_tab) of
        0 -> ok;
        PlayerDailyTab ->
            DailyData = [ActivityData#daily_data{ex = []} || ActivityData <- PlayerDailyTab#player_daily_tab.activity_data],
            dbcache:update(?player_daily_tab, PlayerDailyTab#player_daily_tab{activity_data = DailyData})
    end,
    case get(?pd_fishing_daily_tab) of
        0 -> ok;
        PlayerFishingDailyTab ->
            dbcache:update(?player_fishing_daily_tab, PlayerFishingDailyTab)
    end.

on_day_reset(_SelfId) ->
    reset_clock().

reset_clock() ->
    case get(?pd_daily_activity_tab) of
        0 ->
            ok;
        DailyTab ->
            Fun = fun(ActivityData) ->
                DataType = ActivityData#daily_data.daily_id,
                send_reset_count(DataType, ActivityData#daily_data.daily_asset),
                ActivityData#daily_data{daily_fight_count = 0, daily_pay_count = 0, daily_buy_count = 0, ex = []}
            end,
            put(?pd_daily_activity_tab, DailyTab#player_daily_tab{activity_data = lists:map(Fun, DailyTab#player_daily_tab.activity_data)})
    end,
    case get(?pd_fishing_daily_tab) of
        0 ->
            ok;
        FishingTab ->
            put(?pd_fishing_daily_tab, FishingTab#player_fishing_daily_tab{fish_bait = 30, buy_fish_bait = 0, fish_net = 0, fishing_id = 0})
    end.

get_activity_info(Type) ->
    case get(?pd_daily_activity_tab) of
        #player_daily_tab{activity_data = ActivityData} ->
            case lists:keyfind(Type, #daily_data.daily_id, ActivityData) of
                #daily_data{last_time = LastTime} ->
                    can_challenge(Type, LastTime);
                _ ->
                    ?ERROR_LOG("data error:~p", [ActivityData]),
                    {1, 0}
            end;
        _E ->
            {1, 0}
    end.

send_rank_prize(ActivityId, RankList) ->
    lists:foldl(
        fun({PlayerId, _}, Index) ->
                IdList = load_cfg_daily_activity:lookup_all_weekly_activity_rank_prize_cfg(#weekly_activity_rank_prize_cfg.id),
                case lists:filter(
                    fun(Id) ->
                            #weekly_activity_rank_prize_cfg{activity_id = AId, rank_num = [Min, Max]} = load_cfg_daily_activity:lookup_weekly_activity_rank_prize_cfg(Id),
                            ActivityId =:= AId andalso Min =< Index andalso Max >= Index
                    end,
                    IdList
                ) of
                    [NewId] ->
                        #weekly_activity_rank_prize_cfg{prize = PrizeId} = load_cfg_daily_activity:lookup_weekly_activity_rank_prize_cfg(NewId),
                        ItemList = prize:get_itemlist_by_prizeid(PrizeId),
                        MailTitle = case ActivityId =:= 1 of
                            true -> ?S_MAIL_DAILY_ACTIVITY_4_RANK_PRIZE;
                            _ -> ?S_MAIL_DAILY_ACTIVITY_5_RANK_PRIZE
                        end,
                        world:send_to_player_any_state(PlayerId, ?mod_msg(mail_mng, {weekly_rank_prize_mail, PlayerId, MailTitle, ItemList})),
                        Index + 1;
                    E ->
                        ?ERROR_LOG("can not find config id, error = ~p", [E]),
                        Index + 1
                end
        end,
        1,
        RankList
    ).

can_challenge(Type, LastTime) ->
    NowTime = com_time:now(),
    Today = com_time:day_of_the_week(),
    case is_activity_opening(Type) of
        true ->
            case com_time:is_same_day(LastTime, NowTime) =:= false orelse (NowTime - LastTime) >= 7 * ?SECONDS_PER_HOUR of
                true ->
                    {1, 0};
                _ ->
                    Time = case com_time:is_same_day(LastTime, LastTime + 7 * ?SECONDS_PER_HOUR) of
                        true -> LastTime + 7 * ?SECONDS_PER_HOUR;
                        _ ->
                            get_next_open_inteval_day(Type, Today) * ?SECONDS_PER_DAY - com_time:today_passed_sec() + NowTime
                    end,
                    {0, Time}
            end;
        _ ->
            Time = get_next_open_inteval_day(Type, Today) * ?SECONDS_PER_DAY - com_time:today_passed_sec() + NowTime,
            {0, Time}
    end.

get_next_open_inteval_day(Type, Today) ->
    {DayList, _, _} = lists:nth(Type, misc_cfg:get_daily_activity_time()),
    RetList = lists:filter(
        fun(Day) ->
            Day >= Today
        end,
        DayList
    ),
    case lists:sort(RetList) of
        [] -> lists:min(DayList) + 7 - Today;
        [Today] -> lists:min(DayList) + 7 - Today;
        [Today, Next | _] -> Next - Today;
        [Next | _] -> Next - Today
    end.

send_cur_point(Type, KillMonster) ->
    TotalPoint = kill_monster_get_point(Type, KillMonster),
    case Type of
        ?DailyType_2 ->
            daily_activity_sproto:pkg_msg(?PUSH_POINT_PRIZE, {TotalPoint});
        ?DailyType_4 ->
            daily_activity_sproto:pkg_msg(?MSG_DAILY_ACTIVITY_4_PUSH_POINT_PRIZE, {TotalPoint});
        ?DailyType_5 ->
            daily_activity_sproto:pkg_msg(?MSG_DAILY_ACTIVITY_5_PUSH_POINT_PRIZE, {TotalPoint});
        _ ->
            pass
    end.

send_reset_count(DataType, Max) ->
    {FreeCount, PayCount} = lookup_cfg(count, DataType),
    case DataType of
        ?DailyType_1 ->
            ?player_send(<<?PUSH_DAILY_ACTIVITY_INFO:16, ?DailyType_1, 0, 0, FreeCount, 0, PayCount, Max>>);
        ?DailyType_2 ->
            ?player_send(<<?PUSH_DAILY_ACTIVITY_INFO:16, ?DailyType_2, 0, 0, FreeCount, 0, PayCount, Max:32>>);
        ?DailyType_3 ->
            ?player_send(daily_activity_sproto:pkg_msg(?PUSH_DAILY_ACTIVITY_INFO, {?DailyType_3, 0, 0, FreeCount, 0, PayCount}));
        _ ->
            pass
    end.

count(Type) ->
    case lookup_type(Type) of
        {error, Other} -> {error, Other};
        DailyData ->
            {FreeCount, PayCount} = lookup_cfg(count, Type),
            {DailyData, FreeCount, PayCount}
    end.

select_scene(SceneIdList) ->
    case lookup_type(?DailyType_3) of
        {error, Other} -> {error, Other};
        DailyData ->
            Fun = fun(SceneId) ->
                load_cfg_main_ins:lookup_main_ins_cfg(SceneId) =:= ?none
            end,
            case lists:any(Fun, SceneIdList) of
                true -> {error, ?ERR_DAILY_NO_THIS_SCENE};
                false ->
                    update_type(DailyData#daily_data{ex = {random_ins(), SceneIdList}})
            end
    end.


lookup_type(Type) ->
    case get(?pd_daily_activity_tab) of
        0 -> {error, ?ERR_NOT_OPEN_FUN};
        undefined -> {error, ?ERR_NOT_OPEN_FUN};
        PdDailyTab ->
            ActivityData = PdDailyTab#player_daily_tab.activity_data,
            case lists:keyfind(Type, #daily_data.daily_id, ActivityData) of
                false -> {error, ?ERR_NOT_OPEN_FUN};
                Data -> Data
            end
    end.

update_type(DailyTypeTab) ->
    PdDailyTab = get(?pd_daily_activity_tab),
    ActivityData = PdDailyTab#player_daily_tab.activity_data,
    NewActivity = lists:keyreplace(DailyTypeTab#daily_data.daily_id, #daily_data.daily_id, ActivityData, DailyTypeTab),
    put(?pd_daily_activity_tab, PdDailyTab#player_daily_tab{activity_data = NewActivity}).

ins_complete(?ins_complete, {_MainInsCFG, KillMonster, WaveNum, _DieCount, KillMinMonsterCount, _KillBossMonsterCount, _PrizeId, _, _, _PassTime, _ReliveNum, _, _, _}, CallArg) ->
    case CallArg of
        ?DailyType_1 ->
            prize({?DailyType_1, WaveNum});
        ?DailyType_2 ->
            prize({?DailyType_2, KillMonster});
        ?DailyType_3 ->
            KillAll = KillMinMonsterCount + _KillBossMonsterCount,
            prize({?DailyType_3, KillAll});
        ?DailyType_4 ->
            prize({?DailyType_4, KillMonster});
        ?DailyType_5 ->
            prize({?DailyType_5, KillMonster});
        ?DailyType_6 ->
            pass;
        _E ->
            ?ERROR_LOG("known type:~p", [_E]),
            pass
    end;
ins_complete(_, _, _) ->
    ok.

prize({?DailyType_1, WaveNum}) ->
    DailyData = lookup_type(?DailyType_1),
    %% 刷新排行榜
    case WaveNum > DailyData#daily_data.daily_asset of
        true ->
            update_type(DailyData#daily_data{daily_asset = WaveNum}),
            ranking_lib:update(?ranking_daily_1, get(?pd_id), WaveNum);
        _ ->
            ignore
    end,
    Lev = get(?pd_level),
    {ExpList, _} = get_daily_activity_1_prize(Lev),
    {_, Count} = case WaveNum of
        0 -> {0, 0};
        _ ->
            lists:foldl(
                fun(ExpVal, {Index, TempExp}) ->
                    case WaveNum >= Index of
                        true -> {Index + 1, TempExp + ExpVal};
                        _ -> {Index + 1, TempExp}
                    end
                end,
                {1, 0},
                ExpList
            )
    end,
    PrizeInfo = prize:double_items(3000, [{?PL_EXP, Count}]),
    % pet_new_mng:add_pet_new_exp_if_fight(Count),
    game_res:try_give_ex(PrizeInfo, ?S_MAIL_DIALY_PRIZE, ?FLOW_REASON_DAILY_ACTIVITY),

    IsSuccess = case WaveNum >= ?DAILYTYPE_1_MAX_WAVE of
        true -> 1;
        _ -> 0
    end,
    ?player_send(daily_activity_sproto:pkg_msg(?PUSH_WAVE_PRIZE, {IsSuccess, WaveNum})),
    ?player_send(daily_activity_sproto:pkg_msg(?PUSH_PRIZE, {PrizeInfo}));

prize({?DailyType_2, KillMonster}) ->
    TotalPoint = kill_monster_get_point(?DailyType_2, KillMonster),
    %% 更新排行榜
    DailyData = lookup_type(?DailyType_2),
    case TotalPoint > DailyData#daily_data.daily_asset of
        true ->
            update_type(DailyData#daily_data{daily_asset = TotalPoint}),
            ranking_lib:update(?ranking_daily_2, get(?pd_id), TotalPoint);
        _ ->
            ignore
    end,
    Lev = get(?pd_level),
    {PointLongjing, _} = get_daily_activity_2_prize(Lev),
    TotalLongjing = trunc(PointLongjing * TotalPoint),
    ?INFO_LOG("TotalPoint:~p, PointLongjing:~p, TotalLongjing:~p", [TotalPoint, PointLongjing, TotalLongjing]),

    PrizeInfo = [{?YUANSU_MOLI, NewTotalLongjing}] = prize:double_items(3000, [{?YUANSU_MOLI, TotalLongjing}]),
    case game_res:try_give_ex(PrizeInfo, ?S_MAIL_DIALY_PRIZE, ?FLOW_REASON_DAILY_ACTIVITY) of
        {error, _Other} ->
            ?player_send(daily_activity_sproto:pkg_msg(?PUSH_POINT_PRIZE, {TotalPoint})),
            ?player_send(daily_activity_sproto:pkg_msg(?PUSH_PRIZE, {[{?YUANSU_MOLI, 0}]}));
        _ ->
            ?player_send(daily_activity_sproto:pkg_msg(?PUSH_POINT_PRIZE, {TotalPoint})),
            ?player_send(daily_activity_sproto:pkg_msg(?PUSH_PRIZE, {[{?YUANSU_MOLI, NewTotalLongjing}]}))
    end;

prize({?DailyType_3, KillAll}) ->
    DailyData = lookup_type(?DailyType_3),
    {[Scene1, Scene2, Scene3, Scene4], SceneList} = DailyData#daily_data.ex,
    % ?DEBUG_LOG("Scene1:~p, Scene2:~p, Scene3:~p, Scene4:~p, SceneList:~p", [Scene1, Scene2, Scene3, Scene4, SceneList]),
    Level = get(?pd_level),
    {CompletePrize, GuessPrize, _} = get_daily_activity_3_prize(Level),
    %% 竞猜奖励
    case get_right_num([Scene1, Scene2, Scene3, Scene4], SceneList) of
        0 ->
            ?player_send(daily_activity_sproto:pkg_msg(?PUSH_BOSS_PRIZE, {Scene1, Scene2, Scene3, Scene4, []}));
        Num ->
            PrizeInfo2 = prize:prize_mail(lists:nth(Num, GuessPrize), ?S_MAIL_DIALY_PRIZE, ?FLOW_REASON_DAILY_ACTIVITY),
            ?player_send(daily_activity_sproto:pkg_msg(?PUSH_BOSS_PRIZE, {Scene1, Scene2, Scene3, Scene4, PrizeInfo2}))
    end,
    %% 结算奖励
    case KillAll >= ?DailyFightIns of
        true ->
            PrizeInfo = prize:prize_mail_2(3000, CompletePrize, ?S_MAIL_DIALY_PRIZE, ?FLOW_REASON_DAILY_ACTIVITY),
            NewPrizeInfo = item_goods:merge_goods(PrizeInfo),
            ?player_send(daily_activity_sproto:pkg_msg(?PUSH_PRIZE, {NewPrizeInfo}));
        _ ->
            ?player_send(daily_activity_sproto:pkg_msg(?PUSH_PRIZE, {[]}))
    end,
    update_type(DailyData#daily_data{ex = []});

prize({?DailyType_4, KillMonster}) ->
    TotalPoint = kill_monster_get_point(?DailyType_4, KillMonster),
    %% 更新排行榜
    DailyData = lookup_type(?DailyType_4),
    case TotalPoint > DailyData#daily_data.daily_asset of
        true ->
            update_type(DailyData#daily_data{daily_asset = TotalPoint}),
            ranking_lib:update(?ranking_daily_4, get(?pd_id), TotalPoint);
        _ ->
            ignore
    end,
    Lev = get(?pd_level),
    {PointMoney, _} = get_daily_activity_4_prize(Lev),
    TotalMoney = trunc(PointMoney * TotalPoint),
    ?INFO_LOG("TotalPoint:~p, PointMoney:~p, TotalMoney:~p", [TotalPoint, PointMoney, TotalMoney]),
    PrizeInfo = [{?PL_MONEY, NewTotalMoney}] = prize:double_items(3000, [{?PL_MONEY, TotalMoney}]),
    case game_res:try_give_ex(PrizeInfo, ?S_MAIL_DIALY_PRIZE, ?FLOW_REASON_DAILY_ACTIVITY) of
        {error, _Other} ->
            ?player_send(daily_activity_sproto:pkg_msg(?MSG_DAILY_ACTIVITY_4_PUSH_POINT_PRIZE, {TotalPoint})),
            ?player_send(daily_activity_sproto:pkg_msg(?PUSH_PRIZE, {[{?PL_MONEY, 0}]}));
        _ ->
            ?player_send(daily_activity_sproto:pkg_msg(?MSG_DAILY_ACTIVITY_4_PUSH_POINT_PRIZE, {TotalPoint})),
            ?player_send(daily_activity_sproto:pkg_msg(?PUSH_PRIZE, {[{?PL_MONEY, NewTotalMoney}]}))
    end;

prize({?DailyType_5, KillMonster}) ->
    TotalPoint = kill_monster_get_point(?DailyType_5, KillMonster),
    %% 更新排行榜
    DailyData = lookup_type(?DailyType_5),
    case TotalPoint > DailyData#daily_data.daily_asset of
        true ->
            update_type(DailyData#daily_data{daily_asset = TotalPoint}),
            ranking_lib:update(?ranking_daily_5, get(?pd_id), TotalPoint);
        _ ->
            ignore
    end,
    Lev = get(?pd_level),
    {{PointYinStar, PointJinStar}, _} = get_daily_activity_5_prize(Lev),
    TotalYinStar = trunc(PointYinStar * TotalPoint),
    TotalJinStar = trunc(PointJinStar * TotalPoint),
    ?INFO_LOG("TotalPoint:~p, PointYinStar:~p, PointJinStar:~p, TotalYinStar:~p, TotalJinStar:~p", [TotalPoint, PointYinStar, PointJinStar, TotalYinStar, TotalJinStar]),
    PrizeInfo = prize:double_items(3000, [{?PL_YINXING, TotalYinStar}, {?PL_JINXING, TotalJinStar}]),
    {NewTotalYinStar, NewTotalJinStar} = case PrizeInfo of
        [{?PL_YINXING, YN}, {?PL_JINXING, JN}] -> {YN, JN};
        [{?PL_JINXING, JN}, {?PL_YINXING, YN}] -> {YN, JN};
        _ -> {0, 0}
    end,
    case game_res:try_give_ex(PrizeInfo, ?S_MAIL_DIALY_PRIZE, ?FLOW_REASON_DAILY_ACTIVITY) of
        {error, _Other} ->
            ?player_send(daily_activity_sproto:pkg_msg(?MSG_DAILY_ACTIVITY_5_PUSH_POINT_PRIZE, {TotalPoint})),
            ?player_send(daily_activity_sproto:pkg_msg(?PUSH_PRIZE, {[{?PL_YINXING, 0}, {?PL_JINXING, 0}]}));
        _ ->
            ?player_send(daily_activity_sproto:pkg_msg(?MSG_DAILY_ACTIVITY_5_PUSH_POINT_PRIZE, {TotalPoint})),
            ?player_send(daily_activity_sproto:pkg_msg(?PUSH_PRIZE, {[{?PL_YINXING, NewTotalYinStar}, {?PL_JINXING, NewTotalJinStar}]}))
    end;

prize(D) ->
    ?ERROR_LOG("error data:~p", [D]),
    pass.

%% 根据怪物列表算积分
kill_monster_get_point(?DailyType_2, KillMonster) when is_list(KillMonster) ->
    {Point1, Point2, Point3, Point4} = ?DAILYTYPE_2_POINT_LIST,
    FunFoldlMonster = fun({MonsterBid, KillNum}, AllPoint) ->
        case scene_monster:lookup_monster_cfg(MonsterBid, #monster_cfg.mtype) of
            ?MT_QUALITY_1 ->
                Point1 * KillNum + AllPoint;
            ?MT_QUALITY_2 ->
                Point2 * KillNum + AllPoint;
            ?MT_QUALITY_3 ->
                Point3 * KillNum + AllPoint;
            ?MT_QUALITY_4 ->
                Point4 * KillNum + AllPoint
        end
    end,
    lists:foldl(FunFoldlMonster, 0, KillMonster);
kill_monster_get_point(?DailyType_4, KillMonster) when is_list(KillMonster) ->
    {Point1, Point2} = ?DAILYTYPE_4_POINT_LIST,
    FunFoldlMonster = fun({MonsterBid, KillNum}, AllPoint) ->
        case scene_monster:lookup_monster_cfg(MonsterBid, #monster_cfg.mtype) of
            ?MT_QUALITY_1 ->
                Point1 * KillNum + AllPoint;
            ?MT_QUALITY_2 ->
                Point2 * KillNum + AllPoint
        end
    end,
    lists:foldl(FunFoldlMonster, 0, KillMonster);
kill_monster_get_point(?DailyType_5, KillMonster) when is_list(KillMonster) ->
    {Point1, Point2, Point3} = ?DAILYTYPE_5_POINT_LIST,
    FunFoldlMonster = fun({MonsterBid, KillNum}, AllPoint) ->
        case scene_monster:lookup_monster_cfg(MonsterBid, #monster_cfg.mtype) of
            ?MT_QUALITY_1 ->
                Point1 * KillNum + AllPoint;
            ?MT_QUALITY_2 ->
                Point2 * KillNum + AllPoint;
            ?MT_QUALITY_3 ->
                Point3 * KillNum + AllPoint
        end
    end,
    lists:foldl(FunFoldlMonster, 0, KillMonster);
kill_monster_get_point(_, _Other) ->
    0.

get_right_num(List1, List2) ->
    {_, Num} = lists:foldl(
        fun(A, {Index, Ret}) ->
                case A =:= lists:nth(Index, List2) of
                    true -> {Index + 1, Ret + 1};
                    _ -> {Index + 1, Ret}
                end
        end,
        {1, 0},
        List1
    ),
    Num.

next_scene_id({_Type, SceneAllId}, SceneId) ->
    case SceneAllId of
        [_, _, _, SceneId] -> ?none;
        [SceneId, SceneId2, _, _] -> SceneId2;
        [_, SceneId, SceneId2, _] -> SceneId2;
        [_, _, SceneId, SceneId2] -> SceneId2
    end.

get_scene(Type) ->
    case Type of
        ?DailyType_1 ->
            load_cfg_main_ins:lookup_group_main_ins_cfg(#main_ins_cfg.type, ?T_INS_DAILY_1);
        ?DailyType_2 ->
            load_cfg_main_ins:lookup_group_main_ins_cfg(#main_ins_cfg.type, ?T_INS_DAILY_2);
        ?DailyType_4 ->
            load_cfg_main_ins:lookup_group_main_ins_cfg(#main_ins_cfg.type, ?T_INS_DAILY_4);
        ?DailyType_5 ->
            load_cfg_main_ins:lookup_group_main_ins_cfg(#main_ins_cfg.type, ?T_INS_DAILY_5);
        ?DailyType_6 ->
            load_cfg_main_ins:lookup_group_main_ins_cfg(#main_ins_cfg.type, ?T_INS_DAILY_6);
        _ ->
            ?ERROR_LOG("unknown_type:~p", [Type])
    end.

random_ins() ->
    Ins = load_cfg_main_ins:lookup_group_main_ins_cfg(#main_ins_cfg.type, ?T_INS_DAILY_3),
    com_util:rand_more(Ins, 4).

lookup_cfg(count, Type) ->
    Vip = attr_new:get_vip_lvl(),
    % VipCFG = load_vip_right:lookup_vip_right_cfg(Vip),
    VipCFG = load_vip_new:lookup_vip_cfg(Vip),
    case Type of 
        ?DailyType_1 ->
            {length([I || I <- VipCFG#vip_cfg.daily_activity_1, I =:= 0]), length([I || I <- VipCFG#vip_cfg.daily_activity_1, I =/= 0])};
        ?DailyType_2 ->
            {length([I || I <- VipCFG#vip_cfg.daily_activity_2, I =:= 0]), length([I || I <- VipCFG#vip_cfg.daily_activity_2, I =/= 0])};
        ?DailyType_3 ->
            {length([I || I <- VipCFG#vip_cfg.daily_activity_3, I =:= 0]), length([I || I <- VipCFG#vip_cfg.daily_activity_3, I =/= 0])};
        _ ->
            {0, 0}
    end.

lookup_cfg(cost, Type, Count) ->
    Vip = attr_new:get_vip_lvl(),
    case Type of
        ?DailyType_1 ->
            load_vip_new:get_vip_new_need_diamond(Vip, #vip_cfg.daily_activity_1, Count);
        ?DailyType_2 ->
            load_vip_new:get_vip_new_need_diamond(Vip, #vip_cfg.daily_activity_2, Count);
        ?DailyType_3 ->
            load_vip_new:get_vip_new_need_diamond(Vip, #vip_cfg.daily_activity_3, Count)
    end.

get_daily_activity_1_prize(Lev) ->
    IdList = load_cfg_daily_activity:lookup_all_daily_activity_1_prize_cfg(#daily_activity_1_prize_cfg.id),
    [RetId] = lists:filter(
        fun(Id) ->
            #daily_activity_1_prize_cfg{lev_min = LevMin, lev_max = LevMax} = load_cfg_daily_activity:lookup_daily_activity_1_prize_cfg(Id),
            LevMin =< Lev andalso LevMax >= Lev
        end,
        IdList
    ),
    #daily_activity_1_prize_cfg{exp_prize_list = ExpList, sweep_prize = SweepExp} = load_cfg_daily_activity:lookup_daily_activity_1_prize_cfg(RetId),
    {ExpList, SweepExp}.

get_daily_activity_2_prize(Lev) ->
    IdList = load_cfg_daily_activity:lookup_all_daily_activity_2_prize_cfg(#daily_activity_2_prize_cfg.id),
    [RetId] = lists:filter(
        fun(Id) ->
            #daily_activity_2_prize_cfg{lev_min = LevMin, lev_max = LevMax} = load_cfg_daily_activity:lookup_daily_activity_2_prize_cfg(Id),
            LevMin =< Lev andalso LevMax >= Lev
        end,
        IdList
    ),
    #daily_activity_2_prize_cfg{point_longjing = PointLongjing, sweep_prize = SweepLongjing} = load_cfg_daily_activity:lookup_daily_activity_2_prize_cfg(RetId),
    {PointLongjing, SweepLongjing}.

get_daily_activity_3_prize(Lev) ->
    IdList = load_cfg_daily_activity:lookup_all_daily_activity_3_prize_cfg(#daily_activity_3_prize_cfg.id),
    [RetId] = lists:filter(
        fun(Id) ->
            #daily_activity_3_prize_cfg{lev_min = LevMin, lev_max = LevMax} = load_cfg_daily_activity:lookup_daily_activity_3_prize_cfg(Id),
            LevMin =< Lev andalso LevMax >= Lev
        end,
        IdList
    ),
    #daily_activity_3_prize_cfg{complete_prize = CompletePrize, guess_prize = GuessPrize, sweep_prize = SweepPrize} = load_cfg_daily_activity:lookup_daily_activity_3_prize_cfg(RetId),
    {CompletePrize, GuessPrize, SweepPrize}.

get_daily_activity_4_prize(Lev) ->
    IdList = load_cfg_daily_activity:lookup_all_daily_activity_4_prize_cfg(#daily_activity_4_prize_cfg.id),
    [RetId] = lists:filter(
        fun(Id) ->
            #daily_activity_4_prize_cfg{lev_min = LevMin, lev_max = LevMax} = load_cfg_daily_activity:lookup_daily_activity_4_prize_cfg(Id),
            LevMin =< Lev andalso LevMax >= Lev
        end,
        IdList
    ),
    #daily_activity_4_prize_cfg{point_money = PointMoney, sweep_prize = SweepMoney} = load_cfg_daily_activity:lookup_daily_activity_4_prize_cfg(RetId),
    {PointMoney, SweepMoney}.

get_daily_activity_5_prize(Lev) ->
    IdList = load_cfg_daily_activity:lookup_all_daily_activity_5_prize_cfg(#daily_activity_5_prize_cfg.id),
    [RetId] = lists:filter(
        fun(Id) ->
            #daily_activity_5_prize_cfg{lev_min = LevMin, lev_max = LevMax} = load_cfg_daily_activity:lookup_daily_activity_5_prize_cfg(Id),
            LevMin =< Lev andalso LevMax >= Lev
        end,
        IdList
    ),
    #daily_activity_5_prize_cfg{point_star = PointStar, sweep_prize = SweepMoney} = load_cfg_daily_activity:lookup_daily_activity_5_prize_cfg(RetId),
    {PointStar, SweepMoney}.

is_activity_opening(Type) ->
    {DayList, {BeginHour, BeginMin, BeginSec}, {EndHour, EndMin, EndSec}} = lists:nth(Type, misc_cfg:get_daily_activity_time()),
    lists:member(com_time:day_of_the_week(), DayList) andalso BeginHour * 3600 + BeginMin * 60 + BeginSec =< util:get_today_passed_seconds() andalso util:get_today_passed_seconds() =< EndHour * 3600 + EndMin * 60 + EndSec.
