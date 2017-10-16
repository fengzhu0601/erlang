-module(course_mng).

-include_lib("pangzi/include/pangzi.hrl").

-include("inc.hrl").
-include("player.hrl").

-include("scene.hrl").
-include("player_mod.hrl").
-include("system_log.hrl").
-include("handle_client.hrl").
-include("load_course.hrl").
-include("main_ins_struct.hrl").
-include("load_cfg_main_ins.hrl").
-include("achievement.hrl").
-include("day_reset.hrl").

-export([
    unlock_course_boss_ins/1,
    ins_complete/3
]).

on_day_reset(_SelfId) ->
    put(?pd_course_count, 0),
    put(?pd_course_buy_count, 0),
    put(?pd_course_flush_count, 0),
    put(?pd_course_buy_flush_count, 0),
    get_course_boss_ist(),
    send_best_prize_info(),
    ok.

get_count_by_course_id(Id) ->
    List = attr_new:get(?pd_course_data_list, []),
    case lists:keyfind(Id, 1, List) of
        ?false ->
            1;
        {_, Count} ->
            Count
    end.

update_count_by_course_id(Id) ->
    List = attr_new:get(?pd_course_data_list, []),
    {NewList,FinalCount} = 
    case lists:keyfind(Id, 1, List) of
        ?false ->
            {[{Id, 1}|List], 1};
        {_, Count} ->
            NewCount = Count + 1, 
            {lists:keyreplace(Id, 1, List, {Id, NewCount}), NewCount}
    end,
    put(?pd_course_data_list, NewList),
    FinalCount.




handle_client({Pack, Arg}) ->
    handle_client(Pack, Arg).

%% @doc 进入活动副本
handle_client(?MSG_ENTER_COURSE, {Id}) when Id > 0 ->
    ?DEBUG_LOG("Id----------------------:~p",[Id]),
    case load_course:get_course_ins_id(Id) of
        ?false ->
            pass;
        InsId ->
            put(course_id, Id),
            ?player_send(course_sproto:pkg_msg(?MSG_ENTER_COURSE, {})),
            main_ins_mod:fight_start(course, InsId)
    end;

handle_client(?MSG_COURSE_CHALLENGE_BOSS_ENTER, {Id}) when Id > 0 ->
    %?DEBUG_LOG("MSG_COURSE_CHALLENGE_BOSS_ENTER----------------------:~p",[Id]),
    case load_course:get_boss_challenge_id(Id) of
        ?false ->
            ?player_send(course_sproto:pkg_msg(?MSG_COURSE_CHALLENGE_BOSS_ENTER, {2}));
        {?true, InsId} ->
            ?player_send(course_sproto:pkg_msg(?MSG_COURSE_CHALLENGE_BOSS_ENTER, {1})),
            main_ins_mod:fight_start(course, InsId)
    end;


handle_client(?MSG_COURSE_PRIZE, {Id}) ->
    ?DEBUG_LOG("Id2----------------------:~p",[Id]),
    case load_course:get_course_state_id(Id) of
        ?false ->
            pass;
        _StateId ->
            ?DEBUG_LOG("course type-----------------------:~p",[load_course:get_course_type2(erase(course_id))]),
            case load_course:get_course_type2(Id) of
                0 ->
                    achievement_mng:do_ac(?chaojixueyuan);
                1 ->
                    achievement_mng:do_ac(?tiancaixueyuan);
                2 ->
                    achievement_mng:do_ac(?xueba);
                _ ->
                    pass
            end,
            CoursePrizeAttenuation = misc_cfg:get_course_prize_attenuation(),
            Size = length(CoursePrizeAttenuation),
            Count = get_count_by_course_id(Id),
            if
                Count >= Size ->
                    ?player_send(course_sproto:pkg_msg(?MSG_COURSE_PRIZE,{[]}));
                true -> 
                    FinalCount = update_count_by_course_id(Id),
                    PrizeId = load_course:get_course_prize(Id),
                    ItemList = prize:get_itemlist_by_prizeid(PrizeId),
                    FinalItemList = util:list_multiply_coefficient(ItemList, lists:nth(FinalCount, CoursePrizeAttenuation) / 100,[]),
                    %?DEBUG_LOG("FinalItemList----------------------:~p",[FinalItemList]),
                    case prize:send_prize_of_itemlist(FinalItemList, ?S_MAIL_COURSE_INS_PRIZE, ?FLOW_REASON_COURSE) of
                        {error, _} ->
                            ?player_send(course_sproto:pkg_msg(?MSG_COURSE_PRIZE,{[]}));
                        PrizeInfo ->
                            ?player_send(course_sproto:pkg_msg(?MSG_COURSE_PRIZE,{PrizeInfo}))
                    end
            end
    end;



%% 购买次数
handle_client(?MSG_COURSE_BUY_COUNT, {Type, BuyCount}) when Type =:= 2 ->
    VipLevel = attr_new:get_vip_lvl(),
    L2 = load_vip_new:get_vip_boss_challenge_flush_by_vip_level(VipLevel),
    CanFlushTimes = load_vip_new:get_vip_new_pay_times(L2),
    OldFlushTimes = attr_new:get(?pd_course_buy_flush_count, 0),
    if
        (OldFlushTimes + BuyCount) > CanFlushTimes ->
            ?return_err(?ERR_MAX_COUNT);
        true ->
            PayList = load_vip_new:get_vip_new_pay_list(L2),
            NewFlushBuyTimes = OldFlushTimes + BuyCount,
            %?DEBUG_LOG("PayList----------------------------:~p",[PayList]),
            %?DEBUG_LOG("BuyCount------:~p-----OldFlushTime----:~p",[BuyCount, OldFlushTimes]),
            DiamondNum = lists:sum(lists:sublist(PayList, OldFlushTimes+1, BuyCount)),
            CostList = [{?PL_DIAMOND, DiamondNum}],
            case game_res:can_del(CostList) of
                ok ->
                    game_res:del(CostList, ?FLOW_REASON_COURSE),
                    put(?pd_course_buy_flush_count, NewFlushBuyTimes),
                    ?player_send(course_sproto:pkg_msg(?MSG_COURSE_BUY_COUNT, {}));
                _ ->
                    ?return_err(?ERR_COST_NOT_ENOUGH)
            end
    end;
handle_client(?MSG_COURSE_BUY_COUNT, {Type, BuyCount}) when Type =:= 1 ->
    VipLevel = attr_new:get_vip_lvl(),
    L1 = load_vip_new:get_vip_course_times_by_vip_level(VipLevel),
    CanBuyTimes = load_vip_new:get_vip_new_pay_times(L1),
    OldBuyTimes = attr_new:get(?pd_course_buy_count, 0),
    if
        (OldBuyTimes + BuyCount) > CanBuyTimes ->
            ?return_err(?ERR_MAX_COUNT);
        true ->
            PayList = load_vip_new:get_vip_new_pay_list(L1),
            NewBuyTimes = OldBuyTimes + BuyCount,
            %?DEBUG_LOG("PayList--2--------------------------:~p",[PayList]),
            %?DEBUG_LOG("BuyCount---2---:~p-----OldFlushTime----:~p",[BuyCount, OldBuyTimes]),
            DiamondNum = lists:sum(lists:sublist(PayList, OldBuyTimes+1, BuyCount)),
            CostList = [{?PL_DIAMOND, DiamondNum}],
            case game_res:can_del(CostList) of
                ok ->
                    game_res:del(CostList, ?FLOW_REASON_COURSE),
                    put(?pd_course_buy_count, NewBuyTimes),
                    ?player_send(course_sproto:pkg_msg(?MSG_COURSE_BUY_COUNT, {}));
                _ ->
                    ?return_err(?ERR_COST_NOT_ENOUGH)
            end
    end;
    % CanBuyTimes =
    % if
    %     Type =:= 1 ->
    %         L1 = load_vip_new:get_vip_course_times_by_vip_level(VipLevel),
    %         load_vip_new:get_vip_new_pay_times(L1);
    %     true ->
    %         L2 = load_vip_new:get_vip_boss_challenge_flush_by_vip_level(VipLevel),
    %         load_vip_new:get_vip_new_pay_times(L2)
    % end,
    % if
    %     Type =:= ->
    %         body
    % end
    % Ret =
    % case load_vip_new:get_vip_course_times_by_vip_level(VipLevel) of
    %     ?none ->
    %         pass;
    %     List ->
    %         Size = length(List),
    %         OldCount = attr_new:get(?pd_course_buy_count, 0),
    %         case OldCount + BuyCount > Size-1 of
    %             false ->
    %                 DiamondNum = lists:sum(lists:sublist(List, OldCount+1, BuyCount)),
    %                 CostList = [{?PL_DIAMOND, DiamondNum}],
    %                 case game_res:can_del(CostList) of
    %                     ok ->
    %                         game_res:del(CostList, ?FLOW_REASON_COURSE),
    %                         put(?pd_course_buy_count, OldCount+BuyCount),
    %                         ok;
    %                     _ ->
    %                         {error, cost_not_enough}
    %                 end;
    %             _ ->
    %                 {error, max_count}
    %         end
    % end,
    % ReplyNum =
    %     case Ret of
    %         ok ->
    %             1;
    %         _ ->
    %             2
    %     end,
    % ?player_send(course_sproto:pkg_msg(?MSG_COURSE_BUY_COUNT, {ReplyNum}));

%%handle_client(?MSG_COURSE_BUY_COUNT, {}) ->
%%    VipLevel = attr_new:get_vip_lvl(),
%%    %case load_vip_right:get_course_boss_count(VipLevel) of
%%    case load_vip_new:get_vip_course_times_by_vip_level(VipLevel) of
%%        ?none ->
%%            %?DEBUG_LOG("pass-----------------------"),
%%            pass;
%%        List ->
%%            Size = length(List),
%%            BuyCount = get(?pd_course_buy_count),
%%            FreeTimes = load_vip_right:get_free_times(List),
%%            %?DEBUG_LOG("FreeTimes----------------------:~p",[FreeTimes]),
%%            NewBuyCount = BuyCount + 1,
%%            %?DEBUG_LOG("NewBuyCount------------------------:~p",[NewBuyCount]),
%%            if
%%                NewBuyCount =< Size ->
%%                    case game_res:try_del([{?PL_DIAMOND, lists:nth(NewBuyCount+FreeTimes, List)}], ?FLOW_REASON_COURSE) of
%%                        ok ->
%%                            put(?pd_course_buy_count, NewBuyCount),
%%                            ?player_send(course_sproto:pkg_msg(?MSG_COURSE_BUY_COUNT, {1}));
%%                        _ ->
%%                            ?player_send(course_sproto:pkg_msg(?MSG_COURSE_BUY_COUNT, {2}))
%%                    end;
%%                true ->
%%                    ?return_err(?ERR_MAX_COUNT)
%%            end
%%    end;

%% 刷新
handle_client(?MSG_COURSE_FLUSH_BOSS_INFO, {}) ->
    VipLevel = attr_new:get_vip_lvl(),
    FlushCount = attr_new:get(?pd_course_flush_count, 0),
    BuyFlushCount = attr_new:get(?pd_course_buy_flush_count, 0),
    L2 = load_vip_new:get_vip_boss_challenge_flush_by_vip_level(VipLevel),
    FlushFreeTimes = load_vip_new:get_vip_new_free_times(L2),
    TotalCanFlushTimes = BuyFlushCount + FlushFreeTimes,
    if
        FlushCount > TotalCanFlushTimes ->
            ?return_err(?ERR_MAX_COUNT);
        true ->
            NewFlushCount = FlushCount + 1,
            put(?pd_course_flush_count, NewFlushCount),
            BossList = get_course_boss_ist(),
            PrizeList = title_service:get_course_boss_prize(BossList),
            ?player_send(course_sproto:pkg_msg(?MSG_COURSE_FLUSH_BOSS_INFO, {NewFlushCount, PrizeList}))
    end;

    %case load_vip_right:get_course_boss_flush_count(VipLevel) of
%     case load_vip_new:get_vip_boss_challenge_flush_by_vip_level(VipLevel) of
%         ?none ->
%             pass;
%         List ->
%             Size = length(List),
%             FlushCount = attr_new:get(?pd_course_flush_count, 0),
% %%            FreeTimes = load_vip_right:get_free_times(List),
%             NewFlushCount = FlushCount + BuyCount,
%             if
%                 NewFlushCount =< Size ->
%                     case game_res:try_del([{?PL_DIAMOND, lists:sum(lists:sublist(List, FlushCount+1, BuyCount))}], ?FLOW_REASON_COURSE) of
%                         ok ->
%                             put(?pd_course_flush_count, NewFlushCount),
%                             BossList = get_course_boss_ist(),
%                             % ?DEBUG_LOG("BossList------------------:~p",[BossList]),
%                             PrizeList = title_service:get_course_boss_prize(BossList),
%                             ?player_send(course_sproto:pkg_msg(?MSG_COURSE_FLUSH_BOSS_INFO, {NewFlushCount, PrizeList}));
%                         _ ->
%                             ?return_err(?ERR_COST_NOT_ENOUGH)
%                     end;
%                 true ->
%                     ?return_err(?ERR_MAX_COUNT)
%             end
%     end;


handle_client(_Msg, _Arg) ->
    ok.

handle_msg(FromMod, Msg) ->
    ?ERROR_LOG("~p recv a unknown msg ~p from ~p", [?pname(), Msg, FromMod]).


  


send_best_prize_info() ->
    Count = get(?pd_course_count),
    BuyCount = get(?pd_course_buy_count),
    FlushCount = get(?pd_course_flush_count),
    BuyFlushCount = get(?pd_course_buy_flush_count),
    %?DEBUG_LOG("count-------------------:~p",[Count]),
    %List = get(?pd_course_boss_list),
    %List = get_course_boss_ist(),
    List = get_current_list(),
    % ?DEBUG_LOG("List------------------:~p",[List]),
    PrizeList = title_service:get_course_boss_prize(List),
    %?DEBUG_LOG("PrizeList-------------------:~p",[PrizeList]),
    ?player_send(course_sproto:pkg_msg(?MSG_COURSE_BEST_PRIZE, {Count, BuyCount, FlushCount, BuyFlushCount, PrizeList})).

send_course_fight_data() ->
    ?player_send(course_sproto:pkg_msg(?MSG_COURSE_FIGHT_DATA_OF_NOT_BOSS, {attr_new:get(?pd_course_data_list, [])})).



%%get_current_list() ->
%%    case get(?pd_course_current_list) of
%%        [] ->
%%            List = get(?pd_course_boss_list),
%%            Size = length(List),
%%            NewList =
%%            if
%%                Size =< 3 ->
%%                    List;
%%                true ->
%%                    random_course_boss_list(List, 3, [])
%%            end,
%%            put(?pd_course_current_list, NewList),
%%            NewList;
%%        L ->
%%            L
%%    end.


get_current_list() ->
    CurList = attr_new:get(?pd_course_current_list, []),
    List = attr_new:get(?pd_course_boss_list, []),
    case CurList of
        [] ->
            Size = length(List),
            NewList =
                if
                    Size =< 3 ->
                        guolu_boss_list(List, []);
                    true ->
                        random_course_boss_list(List, 3, [])
                end,
            put(?pd_course_current_list, NewList),
            NewList;
        L ->
            NewList1 =
            case length(CurList) =< 3 of
                true ->
                    NewCurList = guolu_boss_list(CurList,[]),
                    put(?pd_course_current_list, NewCurList),
                    NewCurList;
                _ ->
                    guolu_boss_list(L,[])
            end,
            NewList1
    end.





unlock_course_boss_ins(TaskId) ->
    Id = load_task_progress:get_task_unlock_course_boss(TaskId),
    %?DEBUG_LOG("TaskId---:~p---Id----------------------------:~p",[TaskId,Id]),
    case load_course:is_exist_boss_challenge_cfg(Id) of
        ?false ->
            %?DEBUG_LOG("pass----------------------------"),
            pass;
        ?true ->
            BossList = get(?pd_course_boss_list),
            case lists:keyfind(Id, 1, BossList) of
                ?false ->
                    %?DEBUG_LOG("BossList---------------:~p",[BossList]),
                    put(?pd_course_new_boss_id, Id),
                    put(?pd_course_boss_list, [Id | BossList]),
                    send_best_prize_info();
                _ ->
                    pass
            end
    end.

get_course_boss_ist() ->
    List = get(?pd_course_boss_list),
    %?DEBUG_LOG("List-------------------------:~p",[List]),
    NewCurrentList = 
    case get(?pd_course_new_boss_id) of
        ?undefined ->
            random_course_boss_list(List, 3, []);
        BossId ->
            [BossId|random_course_boss_list(List, 2, [])]
    end,
    put(?pd_course_current_list, NewCurrentList),
    NewCurrentList.    


random_course_boss_list(_, 0, List2) ->
    random_course_boss_list_(List2, []);
random_course_boss_list([], _Num, List2) ->
    random_course_boss_list_(List2, []);
random_course_boss_list(List, Num, List2) ->
    BossId = lists:nth(random:uniform(length(List)), List),
    case load_course:get_course_type(BossId) of
        ?false ->
            random_course_boss_list(lists:delete(BossId, List), Num, List2);
        Type ->
            %?DEBUG_LOG("Type-----:~p-----List2------:~p",[Type, List2]),
            case load_course:is_display_of_boss(BossId) of
                ?true ->
                    case lists:keyfind(Type, 1, List2) of
                        ?false ->
                            random_course_boss_list(lists:delete(BossId, List), Num - 1,  [{Type, BossId}|List2]);
                        _ ->
                            random_course_boss_list(lists:delete(BossId, List), Num, List2)
                    end;
                ?false ->
                    random_course_boss_list(lists:delete(BossId, List), Num, List2)
            end
    end.

random_course_boss_list_([], L) ->
    L;
random_course_boss_list_([{_Type, Id}|T], L) ->
    random_course_boss_list_(T, [Id|L]).

guolu_boss_list([], L) ->
    L;
guolu_boss_list([BossId|T], L) ->
    case load_course:is_display_of_boss(BossId) of
        ?true ->
            guolu_boss_list(T, [BossId|L]);
        ?false ->
            guolu_boss_list(T, L)
    end.


%% 
ins_complete(_, {Cfg, _KillMonster, _WaveNum, _DieCount, _KillMinMonsterCount, 
                _KillBossMonsterCount, _Prize, MaxDoubleHit, ShoujiCount, PassTime, _ReliveNum, _AbyssPercent, _AbyssScore,
    MonsterBidList}, _CallArg) ->
    CourseBossId = Cfg#main_ins_cfg.id,
    %?DEBUG_LOG("ins_complete MaxDoubleHit-----------:~p-----ShoujiCount---:~p",[MaxDoubleHit, ShoujiCount]),
    BossChallengeId = title_service:get_boss_challenge_id_of_course_boss_prize(CourseBossId),
    %?DEBUG_LOG("CourseBossId-----:~p-----BossChallengeId---:~p",[CourseBossId, BossChallengeId]),
    PrizeInfo =
    case is_send_course_prize(BossChallengeId, MaxDoubleHit, ShoujiCount, PassTime, MonsterBidList) of
        ?true ->
            PrizeId = title_service:get_course_boss_prize_by_id(CourseBossId),
            %?DEBUG_LOG("CourseBossId--------:~p----PrizeId----:~p",[CourseBossId, PrizeId]),
            NewCount = get(?pd_course_count) + 1,
            put(?pd_course_count, NewCount),
            ?player_send(course_sproto:pkg_msg(?MSG_COURSE_USE_COUNT, {NewCount})),
            PrizeList = pack_course_prize(PrizeId, []),
            prize:send_prize_of_itemlist(PrizeList, ?S_MAIL_COURSE_INS_PRIZE, ?FLOW_REASON_COURSE),
            PrizeList;
        ?false ->
            []
    end,
    %?DEBUG_LOG("course_mng------------------PrizeInfo----:~p",[PrizeInfo]),
    ?player_send(course_sproto:pkg_msg(?MSG_COURSE_CHALLENGE_BOSS_PRIZE_INFO, {PrizeInfo})).

pack_course_prize([], List) ->
    List;
pack_course_prize([{_Index, ItemId, Count}|T], List) ->
    pack_course_prize(T, [{ItemId, Count}|List]). 


is_send_course_prize(CourseBossId, MaxDoubleHit, ShoujiCount, PassTime, MonsterBidList) ->
    %?DEBUG_LOG("MaxDoubleHit----:~p---ShoujiCount---:~p---PassTime--:~p----MonsterBidLIst---:~p",[MaxDoubleHit, ShoujiCount, PassTime, MonsterBidList]),
    case load_course:get_course_complete_conditions(CourseBossId) of
        ?false ->
            ?false;
        List ->
            %?DEBUG_LOG("CourseBossId-------:~p-----List----:~p",[CourseBossId, List]),
            Total = length(List),
            L = 
            lists:foldl(fun({?lianji, 0, Gold}, Acc) when Gold =< MaxDoubleHit ->
                        [1|Acc];
                    ({?shouji, 0, Gold}, Acc) when Gold > ShoujiCount ->
                        [2 |Acc];
                    ({?passtime, 0, Gold}, Acc) when Gold =< PassTime->
                        [3|Acc];
                    ({?kill_monster, MonsterBid, Count}, Acc) ->
                        case lists:keyfind(MonsterBid, 1, MonsterBidList) of
                            ?false ->
                                Acc;
                            {_, Num} when Num >= Count ->
                                [4|Acc];
                            _ ->
                                Acc
                        end;
                    (_, Acc) ->
                        Acc
            end,
            [],
            List),
            %?DEBUG_LOG("Total----:~p---------L------:~p",[Total, L]),
            case length(L) of
                Size when Size < Total ->
                    ?false;
                _ ->
                    ?true
            end
    end.

create_course_tab(PlayerId) ->
    case dbcache:insert_new(?player_course_tab, #player_course_tab{id=PlayerId}) of
        true ->
            ok;
        false ->
            ?ERROR_LOG("create ~p module ~p data is already_exist", [PlayerId, ?MODULE])
    end,
    ok.

create_mod_data(PlayerId) ->
    case dbcache:insert_new(?player_course_boss_tab, #player_course_boss_tab{id=PlayerId}) of
        true ->
            ok;
        false ->
            ?ERROR_LOG("create ~p module ~p data is already_exist", [PlayerId, ?MODULE])
    end,
    ok.

load_mod_data(PlayerId) ->
    case dbcache:load_data(?player_course_tab, PlayerId) of
        [] ->
            create_course_tab(PlayerId);
        [#player_course_tab{list=Data}]->
            put(?pd_course_data_list, Data)
    end,

    case dbcache:load_data(?player_course_boss_tab, PlayerId) of
        [] ->
            create_mod_data(PlayerId),
            load_mod_data(PlayerId);
        [#player_course_boss_tab{courseind_list=_List, count=Count, buy_count=BuyCount,
            flush_count=FlushCount, current_list=CurrentList, buy_flush_count = BuyFlushCount}] ->
            put(?pd_course_boss_list, lists:seq(1,24)),
            put(?pd_course_count, Count),
            put(?pd_course_buy_count, BuyCount),
            ?pd_new(?pd_course_flush_count, FlushCount, 0),
            ?pd_new(?pd_course_current_list, CurrentList, []),
            ?pd_new(?pd_course_buy_flush_count, BuyFlushCount)
    end,
    ok.

init_client() ->
    ok.


save_data(PlayerId) ->
    dbcache:update(?player_course_boss_tab, 
            #player_course_boss_tab{
                    id=PlayerId,
                    count=get(?pd_course_count),
                    buy_count=get(?pd_course_buy_count),
                    flush_count = get(?pd_course_flush_count),
                    courseind_list=get(?pd_course_boss_list),
                    current_list=get(?pd_course_current_list),
                    buy_flush_count = get(?pd_course_buy_flush_count)
            }),

    dbcache:update(?player_course_tab, 
            #player_course_tab{
                id=PlayerId,
                list=get(?pd_course_data_list)
            }),
    ok.

online() ->
    send_best_prize_info(),
    send_course_fight_data(),
    ok.
offline(_PlayerId) ->
    ok.
handle_frame(_) -> ok.

view_data(Acc) -> Acc.


load_db_table_meta() ->
    [
        #db_table_meta{
            name = ?player_course_boss_tab,
            fields = ?record_fields(player_course_boss_tab),
            shrink_size = 1,
            flush_interval = 3
        },

        #db_table_meta{
            name = ?player_course_tab,
            fields = ?record_fields(player_course_tab),
            shrink_size = 1,
            flush_interval = 3
        }
    ].