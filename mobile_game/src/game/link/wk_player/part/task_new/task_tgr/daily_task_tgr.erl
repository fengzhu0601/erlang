-module(daily_task_tgr).

%% API
-export([
    % handle_event/4,
    start/1,
    get_event_type/1,
    do_daily_task/2,
    flush_daily_task/0,
    submit_daily_task/1, 
    baoxiang_data/0,
    get_npc_event_type/1,
    flush_daily_num/0,
    cancel_daily_task/1
]).

-include("inc.hrl").

-include("player.hrl").
-include("task_new_def.hrl").
-include("task_def.hrl").
-include("load_task_progress.hrl").
-include("system_log.hrl").
-include("../../wk_open_server_happy/open_server_happy.hrl").
-include("achievement.hrl").

-define(TASK_GOAL,
    [
        {?task_ev_gem_he_cheng, ?ev_gem_he_cheng, 1},
        {?task_ev_pet_hatching, ?ev_pet_hatching, 1},
        {?task_ev_pet_advance, ?ev_pet_advance, 1},
        {?task_ev_pet_skill_level, ?ev_pet_skill_level, 1},
        {?task_ev_pet_treasure, ?ev_pet_treasure, 1},
        {?task_ev_guild_tech_level, ?ev_guild_tech_level, 2},
        {?task_ev_guild_activity, ?ev_guild_activity, 1},
        {?task_ev_friend_add, ?ev_friend_add, 1},
        {?task_ev_crown_exchange, ?ev_crown_exchange, 1},
        {?task_ev_crown_imbue, ?ev_crown_imbue, 1},
        {?task_ev_crown_level, ?ev_crown_level, 1},
        {?task_ev_arena_pve_fight, ?ev_arena_pve_fight, 1},
        {?task_ev_arena_pev_fight_win, ?ev_arena_pve_win, 1},
        {?task_ev_seller_buy_item, ?ev_seller_buy_item, 1},
        {?task_ev_get_item, ?ev_get_item, 2},
        {?task_ev_equ_he_cheng, ?ev_equ_he_cheng, 1},
        {?task_ev_equ_ji_cheng, ?ev_equ_ji_cheng, 1},
        {?task_ev_equ_qiang_hua, ?ev_equ_qiang_hua, 1},
        {?task_ev_equ_xiangqian, ?ev_equ_xiangqian, 1}, 
        {?TG_SINGLE_INSTANCE, ?ev_main_ins_pass, 2},
        {?TG_NPC_TALK, ?ev_npc_talk, 2},
        {?TG_KILL_MONSTER, ?ev_kill_monster, 2},
        {?TG_COLLECT_VIRTUAL_GOODS, ?ev_collect_item, 2},
        {?task_ev_blessing, ?ev_npc_talk,1}
    ]).


get_npc_event_type(Event) ->
    case lists:keyfind(Event, 1, ?TASK_GOAL) of
        ?false ->
            ?none;
        {_, EventType2, _} ->
            EventType2
    end.

get_event_type(Event) ->
    case lists:keyfind(Event, 2, ?TASK_GOAL) of
        false ->
            ?none;
        {EventType, _, _} ->
            EventType
    end.

put_accpet_get_item_data_of_daily_task(D) ->
    L = attr_new:get(?accpet_get_item_data_of_daily_task, []),
    NewL = 
    case lists:member(D, L) of
        ?false ->
            [D|L];
        ?true ->
            L
    end,
    put(?accpet_get_item_data_of_daily_task, NewL).


start(TaskId) ->
    put(?accpet_get_item_data_of_daily_task, []),
    {KeyList, NewList} = 
    case load_task_progress:get_task_new_cfg(TaskId) of
        #task_new_cfg{id = TaskId, goal_type = 31, goal = {GoalId,TaskBuffPoolId}} ->
            BuffList = load_cfg_task_buff_pool:get_task_buff_pool_id_list(TaskBuffPoolId),
            blessing_tgr:add_task_bless_buff(BuffList),
            [equip_buf:add_task_bless_buff(BuffId) || BuffId <- BuffList],
            {[{{?ev_npc_talk, GoalId}, TaskId}], [{{?ev_npc_talk, GoalId}, 1, 0}]};
        #task_new_cfg{id=TaskId,type=_Type, goal_type = 29,  goal=GoalList} ->
            lists:foldl(fun({GoalType, GoalId, GoalNum}, {L, List}) ->
                case lists:keyfind(GoalType, 1, ?TASK_GOAL) of
                    false ->
                        {L, List};
                    {_, ?ev_get_item, _} ->
                        BagNum = goods_bucket:count_item_size(game_res:get_bucket(1), 0, GoalId),
                        put_accpet_get_item_data_of_daily_task({?ev_get_item, GoalId}),
                        {[{{?ev_get_item, GoalId}, TaskId} | L], [{{?ev_get_item, GoalId}, GoalNum, BagNum} | List]};
                    {_, Event, _} ->
                        {[{{Event, GoalId}, TaskId} | L], [{{Event, GoalId}, GoalNum, 0} | List]}
                end
            end,
            {[],[]},
            GoalList);
        #task_new_cfg{id=TaskId,type=_Type, goal_type = GoalType,  goal=Goal} ->
            case lists:keyfind(GoalType, 1, ?TASK_GOAL) of
                false ->
                    {[], []};
                {_, Event, T} ->
                    case T of
                        1 ->
                            {[{{Event, 0}, TaskId}], [{{Event, 0}, Goal, 0}]};
                        2 ->
                            {GoalId, GoalNum} = Goal,
                            InitNum = 
                            case Event of
                                ?ev_collect_item ->
                                    single_dig:add_dig_thing(GoalId, GoalNum),
                                    0;
                                ?ev_get_item ->
                                    OldNum = goods_bucket:count_item_size(game_res:get_bucket(1), 0, GoalId),
                                    put_accpet_get_item_data_of_daily_task({?ev_get_item, GoalId}),
                                    %put(?accpet_get_item_data, {?ev_get_item, GoalId}),
                                    OldNum;
                                _ ->
                                    0     
                            end,
                            {[{{Event, GoalId}, TaskId}], [{{Event, GoalId}, GoalNum, InitNum}]}
                    end
            end;
        ?none ->
            {[], []}
    end,
    if
        NewList == [] ->
            ?false;
        true ->
            DailyList = attr_new:get(?pd_daily_task_list_event_data, []),
            NewDailyList = 
            case lists:keyfind(TaskId, 1, DailyList) of
                ?false ->
                    [{TaskId, NewList}] ++ DailyList;
                {_, OldEventList} ->
                    DailyList2 =  lists:keydelete(TaskId, 1, DailyList),
                    [{TaskId, NewList}] ++ DailyList2
            end,
            %?DEBUG_LOG("accept daily  NewDailyList-------------------:~p",[NewDailyList]),
            case update_daily_task_statue(TaskId, 1) of
                ?false ->
                    ?false;
                ?true ->
                    NewEt = update_event_to_task(KeyList),
                    %?DEBUG_LOG("NewEt-------------------:~p",[NewEt]),
                    attr_new:set(?pd_daily_event_to_task_list, NewEt),
                    attr_new:set(?pd_daily_task_list_event_data, NewDailyList),
                    true
            end
    end.




submit_daily_task(TaskId) ->
    List = attr_new:get(?pd_daily_task_list),
    case lists:keyfind(TaskId, 1, List) of
        ?false ->
            ?false;
        {_, Star, 2, PrizeId} ->
            case Star of
                9 ->
                    open_server_happy_mng:sync_task(?NINE_START_FUBEN_CROSS_COUNT, 1);
                _ ->
                    pass
            end,
            update_event_list_by_task_id(TaskId),
            put(?pd_daily_task_list, lists:keyreplace(TaskId, 1, List, {TaskId, Star, 3, PrizeId})),
            %R = prize:prize(PrizeId),
            %R = prize:prize_mail(PrizeId, ?S_MAIL_TASK, ?FLOW_REASON_DAILY_TASK),
            R = prize:prize_mail_2(2000, PrizeId, ?S_MAIL_TASK, ?FLOW_REASON_DAILY_TASK),
            pet_new_mng:add_pet_new_exp_if_fight(R),
            achievement_mng:do_ac(?renwukuangren),
            ?true;
        _ ->
            ?false
    end.


update_daily_task_statue(TaskId, Statue) ->
    List = attr_new:get(?pd_daily_task_list),
    case lists:keyfind(TaskId, 1, List) of
        ?false ->
            ?false;
        {_, Star, _, PrizeId} ->
            put(?pd_daily_task_list, lists:keyreplace(TaskId, 1, List, {TaskId, Star, Statue, PrizeId})),
            ?true
    end.


cancel_daily_task(TaskId) ->
    case update_daily_task_statue(TaskId, 0) of
        ?false ->
            ?false;
        ?true ->
            L = attr_new:get(?pd_daily_event_to_task_list),
            case lists:keyfind(TaskId, 2, L) of
                ?false ->
                    pass;
                {EventId, _} ->
                    DailyList = attr_new:get(?pd_daily_task_list_event_data, []),
                    case lists:keyfind(TaskId, 1, DailyList) of
                        ?false ->
                            pass;
                        _ ->
                            case EventId of
                                {?ev_collect_item, CollectGoalId} ->
                                    single_dig:del_dig_thing(CollectGoalId);
                                _ ->
                                    pass
                            end,
                            attr_new:set(?pd_daily_task_list_event_data, lists:keydelete(TaskId, 1, DailyList))
                    end,
                    attr_new:set(?pd_daily_event_to_task_list, lists:keydelete(EventId, 1, L))
            end
    end.




update_event_to_task(List) ->
    L = attr_new:get(?pd_daily_event_to_task_list),
    lists:foldl(fun({Id, _TaskId} = D, NewL) ->
        case lists:keyfind(Id, 1, L) of
            ?false ->
                [D|NewL];
            _ ->
                NewL
        end
    end,
    L,
    List).

update_event_list_by_task_id(TaskId) ->
    L = attr_new:get(?pd_daily_event_to_task_list),
    case lists:keyfind(TaskId, 2, L) of
        ?false ->
            pass;
        {EventId, _} ->
            case EventId of
                {?ev_get_item, _} ->
                    DailyList = attr_new:get(?pd_daily_task_list_event_data, []),
                    %?DEBUG_LOG("DailyList-----------------------:~p",[DailyList]),
                    case lists:keyfind(TaskId, 1, DailyList) of
                        ?false ->
                            pass;
                        {_, OldEventList} ->
                            %case lists:keyfind(EventId, 1, OldEventList) of
                            %    {{_Event, GoalId}, GoalNum, _CurrentNum} ->
                            %        game_res:del([{GoalId, GoalNum}]);
                            %    _->
                            %        pass
                            %end
                            lists:foreach(fun({{_Event, GoalId}, GoalNum, _CurrentNum}) ->
                                game_res:del([{GoalId, GoalNum}], ?FLOW_REASON_DAILY_TASK)
                            end,
                            OldEventList)
                    end;
                _ ->
                    pass
            end,
            attr_new:set(?pd_daily_event_to_task_list, lists:keydelete(EventId, 1, L))
    end.




% update_event_list(EventId) ->
%     L = attr_new:get(?pd_daily_event_to_task_list),
%     attr_new:set(?pd_daily_event_to_task_list, lists:keydelete(EventId, 1, L)).


flush_daily_task() ->
    attr_new:set(?pd_daily_task_collect_dig_list, []),
    attr_new:set(?pd_daily_task_list_event_data, []),
    attr_new:set(?pd_daily_event_to_task_list, []),
    attr_new:set(?pd_daily_task_list, []).

flush_daily_num() ->
    put(?pd_task_daily_free_flush_times, 0),
    put(?pd_task_daily_pay_flush_times, 0),
    put(?pd_task_daily_task_times, 0),
    {BaoXiangIndex, IsTure, L} = attr_new:get(?pd_daily_task_prize_list),
    ?DEBUG_LOG("BaoXiangIndex-----------:~p---IsTure--:~p---L---:~p",[BaoXiangIndex, IsTure, L]),
    R = 
    case IsTure of
        0 ->
            GetPrizeIndex = BaoXiangIndex - 1,
            case lists:keyfind(GetPrizeIndex, 1, L) of
                ?false ->
                    ?false;
                {_, TaskCount, 1, PrizeId} when IsTure =:= 0 ->
                    ?DEBUG_LOG("send mail-------------------------------"),
                    ItemList = prize:get_itemlist_by_prizeid(PrizeId),
                    PlayerId = get(?pd_id),
                    world:send_to_player_any_state(PlayerId,?mod_msg(mail_mng, {gwgc_mail, PlayerId, ?S_MAIL_DAILY_BAOXIANG_PRIZE,ItemList})),
                    put(?pd_daily_task_prize_list, {BaoXiangIndex, 1, lists:keyreplace(GetPrizeIndex, 1, L, {GetPrizeIndex, TaskCount, 2, PrizeId})}),
                    if
                        GetPrizeIndex =:= 5 ->
                            put(?pd_daily_task_prize_list, load_richang_task:get_daily_baoxiang_prize());
                        true ->
                            pass
                    end,
                    ?true;
                _ ->
                    ?false
            end;
        _ ->
            ?false
    end,
    if
        R =:= ?true ->
            pass;
        true ->
            put(?pd_daily_task_prize_list, {BaoXiangIndex, 1, L})
    end,
    task_mng_new:send_daily_list(task_mng_new:get_daily_task_list()).


daily_task_progress(TaskId, EventData) ->
    %?DEBUG_LOG("TaskId---:~p----EventData---------------------:~p",[TaskId, EventData]),
    EventBin = 
    lists:foldl(fun({{Event, GoalId}, _GoalNum, CurrentNum}, Bin) ->
            GoalType = daily_task_tgr:get_event_type(Event),
            %?DEBUG_LOG("Event--:~p---GoalId---:~p---CurrentNum----:~p",[Event, GoalId, CurrentNum]),
            <<Bin/binary, GoalType:8, GoalId:32, CurrentNum:8>>
          
    end,
    <<(length(EventData))>>,
    EventData),
    ?player_send(task_sproto:pkg_msg(?MSG_TASK_DAILY_PROGRESS, {TaskId, EventBin})).



do_daily_task(EventId, Count) ->
    %?DEBUG_LOG("do daily EventId-------------------------:~p",[EventId]),
    L = attr_new:get(?pd_daily_event_to_task_list),
    %?DEBUG_LOG("do daily task L-----------------------------:~p",[L]),
    case lists:keyfind(EventId, 1, L) of
        ?false ->
            pass;
        {_, TaskId} ->
            %?DEBUG_LOG("do daily task TaskId---------------------------:~p",[TaskId]),
            DailyList = attr_new:get(?pd_daily_task_list_event_data, []),
            %?DEBUG_LOG("DailyList-----------------------:~p",[DailyList]),
            case lists:keyfind(TaskId, 1, DailyList) of
                ?false ->
                    pass;
                {_, OldEventList} ->
                    %?DEBUG_LOG("OldEventList------------------:~p",[OldEventList]),
                    case lists:keyfind(EventId, 1, OldEventList) of
                        {{_Event, _GoalId} = A, GoalNum, CurrentNum} ->
                            NewCurrentNum = erlang:max((CurrentNum + Count), 0),
                            V = 
                            if
                                NewCurrentNum >= GoalNum ->
                                    case EventId of
                                        {?ev_collect_item, CollectGoalId} ->
                                            single_dig:del_dig_thing(CollectGoalId);
                                        _ ->
                                            pass
                                    end,
                                    {A, GoalNum, GoalNum};
                                true ->
                                    {A, GoalNum, NewCurrentNum} 
                            end,
                            Data = lists:keyreplace(EventId, 1, OldEventList, V),
                            NewEvent = {TaskId, Data},
                            %?DEBUG_LOG("NewEvent---------------:~p",[NewEvent]),
                            NewDailyList = lists:keyreplace(TaskId, 1, DailyList, NewEvent),
                            attr_new:set(?pd_daily_task_list_event_data, NewDailyList),
                            daily_task_progress(TaskId, Data),
                            case is_update_daily_task_statue(Data) of
                                true ->
                                    update_daily_task_statue(TaskId, 2);
                                false ->
                                    update_daily_task_statue(TaskId, 1)
                            end;
                        _->
                            pass
                    end
            end
    end,
    ok.
is_update_daily_task_statue([]) ->
    true;
is_update_daily_task_statue([{_, N, N}|T]) ->
    is_update_daily_task_statue(T);
is_update_daily_task_statue([{_, _N, _M}|_T]) ->
    false.

baoxiang_data() ->
    {_, _, L}= attr_new:get(?pd_daily_task_prize_list, []),
    CfgL = misc_cfg:get_task_daily_baoxiang(),
    %?DEBUG_LOG("is_check_baoxiang_data--------------:~p",[is_check_baoxiang_data()]),
    NewL = 
    case is_check_baoxiang_data() of
        ?false ->
            CfgL;
        ?true ->
            L
    end,
    ?DEBUG_LOG("NewL-----------------------:~p",[NewL]),
    lists:foldl(fun({Index, _, Statue, _}, Acc) ->
        <<Acc/binary, Index, Statue>>
    end,
    <<(length(NewL))>>,
    NewL).

is_check_baoxiang_data() ->
     {_, _, L}= attr_new:get(?pd_daily_task_prize_list, []),
     is_check_baoxiang_data_(L).
is_check_baoxiang_data_([]) ->
    ?false;
is_check_baoxiang_data_([{_, _, 2,_}|T]) ->
    is_check_baoxiang_data_(T);
is_check_baoxiang_data_(_) ->
    ?true.