%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 23. 七月 2015 上午1:38
%%%-------------------------------------------------------------------
-module(task_mng_new).
-author("clark").

-include("inc.hrl").
-include("handle_client.hrl").

-include("player_mod.hrl").
-include("task_new_def.hrl").
-include("player.hrl").
-include("task_mng_reply.hrl").
-include("cost.hrl").
-include("system_log.hrl").

-export([
    get_scene_ins_id/0,
    get_pack_data/2,
    is_doing_task/1,
    do_flush_daily_task_of_level/1,
    do_flush_daily_task/0,
    send_daily_prize/1,
    send_daily_list/1,
    get_daily_task_list/0
]).

-define(enter_game_ins_task_id, enter_game_ins_task_id).


pack_task_data_by_type(?newbie_guide_task_type) ->
    task_system:get_all_branch_task_progress();
pack_task_data_by_type(Type) ->
    AccepteP = task_system:get_accept_progress(Type),
    FinishP = task_system:get_finish_progress(Type),
    % ?DEBUG_LOG("AccepteP--:~p--FinishP--:~p---Type---:~p",[AccepteP, FinishP, Type]),
    {
        if
            FinishP =:= 0 ->
                [];
            true ->
                [{Type, FinishP}]
        end,
        if
            AccepteP =:= 0 ->
                [];
            AccepteP =:= FinishP ->
                [];
            true ->
                TaskId = load_task_progress:get_taskid(Type, AccepteP),
                %?DEBUG_LOG("TaskId-------------------:~p",[TaskId]),
                get_pack_data(Type, TaskId)
        end
    }.

get_pack_data(TaskType, TaskId) ->
    GoalType = load_task_progress:get_task_goal_type(TaskId),
    case task_system:get_tgr_db_data({TaskType, TaskId}) of
        ?task_nil ->
            [];
        ?none ->
            [{TaskId, GoalType, 0, 0}];
        {{item, _Num}, {ItemId, Count}} ->
            [{TaskId, GoalType, ItemId, Count}];
        {_G, Current} ->
            %?DEBUG_LOG("Current-------------------:~p",[Current]),
            single_dig_tgr:online_reset_reg(TaskId, TaskType),
            case Current of
                {GoalId, {_GoalId2, CurrentNum}} ->
                    [{TaskId, GoalType, GoalId, CurrentNum}];
                {GoalId, CurrentNum} ->
                    [{TaskId, GoalType, GoalId, CurrentNum}];
                Current ->
                    [{TaskId, GoalType, 0, Current}]
            end
    end.



-spec get_scene_ins_id() -> false | integer().
get_scene_ins_id() ->
    IsOpen = attr_new:get(?pd_task_is_open),
    FirstOne = erase(?first_one),
    %?DEBUG_LOG("scene ins id --------------------------"),
    if
        IsOpen =:= undefined;IsOpen =:= 0 ->
            case FirstOne of
                true ->
                    [SceneId | _] = misc_cfg:get_misc_cfg(?enter_game_ins_task_id),
                    case main_ins_mod:fight_start(?enter_game_ins_task_id, SceneId) of
                        {ok, NewSceneId} ->
                            NewSceneId;
                        _ ->
                            false
                    end;
                _ ->
                    false
            end;
        true ->
            false
    end.


do_task_load_progress_submit(TaskId) ->
    % ?DEBUG_LOG("submit task:~p", [TaskId]),
    LoadProgressData = misc_cfg:get_load_progress_data_submit(),
    case lists:keyfind(TaskId, 1, LoadProgressData) of
        ?false ->
            pass;
        {_, LoadProgressId} ->
            system_log:info_load_progress(LoadProgressId)
    end.
   
do_task_load_progress_accept(TaskId) ->
    % ?DEBUG_LOG("accept task:~p", [TaskId]),
    LoadProgressData = misc_cfg:get_load_progress_data_accept(),
    case lists:keyfind(TaskId, 1, LoadProgressData) of
        ?false ->
            pass;
        {_, LoadProgressId} ->
            system_log:info_load_progress(LoadProgressId)
    end.
   



create_mod_data(_PlayerId) ->
    %?DEBUG_LOG("_PlayerId----------------------------:~p",[_PlayerId]),
    %put(?first_one, true),
    IsGuide = my_ets:get(newplayer_guide,1),
    case IsGuide of
        0 -> ok;
        _ -> put(?first_one, true)
    end,
    ok.

load_mod_data(_PlayerId) ->
    ok.

init_client() ->
    IsOpen = attr_new:get(?pd_task_is_open),
    if
        IsOpen =:= undefined;IsOpen =:= 0 ->
            case get(?first_one) of
                true ->
                    #{first_task := List} = misc_cfg:get_task_info(),
                    %?DEBUG_LOG("List--------------------:~p",[List]),
                    [task_system:accept(Id) || Id <- List];
                _ ->
                    pass
            end;
        true ->
            pass
    end,
    %?DEBUG_LOG("main-----------------------------------:~p",[pack_task_data_by_type(0)]),
    %?DEBUG_LOG("brand----------------------------------:~p",[pack_task_data_by_type(1)]),
    Tasks = [pack_task_data_by_type(Type) || Type <- ?ALL_TASK_TYPE],
    ?player_send(task_sproto:pkg_msg(?MSG_TASK_INIT_CLIENT, {Tasks})),
    ok.


save_data(_PlayerId) ->
    ok.

online() ->
    ok.
offline(_PlayerId) ->
    blessing_tgr:offline_del_task_bless_buff(),
    ok.
handle_frame(_) -> ok.

view_data(Acc) -> Acc.





handle_client({Pack, Arg}) -> handle_client(Pack, Arg).
handle_client(?MSG_TASK_ACCEPT, {TaskId}) ->
    % ?DEBUG_LOG("MSG_TASK_ACCEPT 1 TaskId-------------------------:~p",[TaskId]),
    case load_task_progress:get_task_type(TaskId) of
        ?daily_task_type ->
            MaxTime = misc_cfg:get_task_daily_up_number(),
            CurTime = attr_new:get(?pd_task_daily_task_times, 0),
            if
                CurTime >= MaxTime ->
                    ?player_send(task_sproto:pkg_msg(?MSG_TASK_ACCEPT, {?REPLY_MSG_TASK_ACCEPT_3, TaskId}));
                true ->
                    case daily_task_tgr:start(TaskId) of
                        ?true ->
                            ?player_send(task_sproto:pkg_msg(?MSG_TASK_ACCEPT, {?REPLY_MSG_TASK_ACCEPT_OK, TaskId})),
                            %daily_task_tgr:do_daily_task(erase(?accpet_get_item_data), 0);
                            [daily_task_tgr:do_daily_task(Key, 0) || Key <- erase(?accpet_get_item_data_of_daily_task)];
                        ?false ->
                            ?player_send(task_sproto:pkg_msg(?MSG_TASK_ACCEPT, {?REPLY_MSG_TASK_ACCEPT_255, TaskId}))
                    end
            end;
        _ ->
            %?DEBUG_LOG("MSG_TASK_ACCEPT 2 TaskId------------------------------------:~p",[TaskId]),
            do_task_load_progress_accept(TaskId),
            task_system:accept(TaskId),
            event_eng:post(?ev_get_item, {?ev_get_item, erase(?accpet_get_item_data)}, 0)
    end,
    ok;
handle_client(?MSG_TASK_SUBMIT, {TaskId}) ->
    % ?DEBUG_LOG("submit taskid-------------:~p",[TaskId]),
    case load_task_progress:get_task_type(TaskId) of
        ?daily_task_type ->
            daily_task_tgr:submit_daily_task(TaskId),
            ?player_send(task_sproto:pkg_msg(?MSG_TASK_SUBMIT, {?REPLY_MSG_TASK_SUBMIT_OK, TaskId})),
            NewDailyTaskCount = attr_new:get(?pd_task_daily_task_times, 0) + 1,
            attr_new:set(?pd_task_daily_task_times, NewDailyTaskCount),
            update_baoxiang_prize_statue(NewDailyTaskCount),
            auto_flush_daily_task(NewDailyTaskCount);
        _ ->
            case task_system:get_dbid_of_task(TaskId) of
                ?none ->
                    % ?DEBUG_LOG("pass-------------------"),
                    pass;
                DbId ->
                    do_task_load_progress_submit(TaskId),
                    task_system:submit(DbId)
            end
    end,
    ok;


handle_client(?MSG_TASK_DAILY_LIST, {1}) ->
    FreeCount = misc_cfg:get_task_daily_free_flush_times(),
    PayCount = misc_cfg:get_task_daily_pay_flush_times(),
    FreeFlushTime = attr_new:get(?pd_task_daily_free_flush_times),
    PayFlushTime = attr_new:get(?pd_task_daily_pay_flush_times),
    TotalNum = FreeFlushTime + PayFlushTime,
    Ret = 
    if
        FreeFlushTime < FreeCount ->
            do_flush_daily_task(),
            attr_new:set(?pd_task_daily_free_flush_times, FreeFlushTime + 1),
            ok;
        TotalNum >= FreeCount + PayCount, PayCount =/= 0 ->
            {error, flush_max};
        ?true ->
            CostId = misc_cfg:get_task_daily_flush_cost(),
            %% TODO:未作回退
            case cost:cost(CostId, ?FLOW_REASON_DAILY_TASK) of
                ok ->
                    attr_new:set(?pd_task_daily_pay_flush_times, PayFlushTime + 1),
                    do_flush_daily_task(),
                    ok;
                _ ->
                    {error, cost_not_enought}
            end
    end,
    _ReplyNum =
    case Ret of
        ok ->
            ?REPLY_MSG_TASK_STAR_OK;
        {error, Reason} ->
            if
                Reason == cost_not_enought ->
                    ?REPLY_MSG_TASK_STAR_1;
                Reason == flush_max ->
                    ?REPLY_MSG_TASK_STAR_2;
                ?true ->
                    ?REPLY_MSG_TASK_STAR_255
            end
     end;



handle_client(?MSG_TASK_DAILY_LIST, {0}) ->
    send_daily_list(get_daily_task_list());

handle_client(?MSG_TASK_DAILY_BAOXIANG_GET_PRIZE, {Index}) ->
    send_daily_prize(Index);


handle_client(?MSG_TASK_DAILY_TALK_NPC, {_TaskId, EventType, NpcId}) ->
    daily_task_tgr:do_daily_task({daily_task_tgr:get_npc_event_type(EventType), NpcId}, 1),
    ?player_send(task_sproto:pkg_msg(?MSG_TASK_DAILY_TALK_NPC, {}));

handle_client(?MSG_TASK_DAILY_CANCEL_TASK, {TaskId}) ->
    case load_task_progress:get_task_type(TaskId) of
        ?daily_task_type ->
            daily_task_tgr:cancel_daily_task(TaskId),
            ?player_send(task_sproto:pkg_msg(?MSG_TASK_DAILY_CANCEL_TASK, {TaskId}));
        ?newbie_guide_task_type ->%% reset 
            case load_simple_task:get_simple_task_type_and_progress(TaskId) of
                ?false ->
                    ?return_err(?ERR_NO_CFG);%% return not find progress cfg
                {_Type, _P} ->
                    case task_system:reset_task(TaskId) of
                        ok ->
                            ?player_send(task_sproto:pkg_msg(?MSG_TASK_DAILY_CANCEL_TASK, {TaskId}));
                        _ ->
                            ?return_err(?ERR_NO_CFG)%% return not find progress cfg
                    end
            end
    end.


handle_msg(_, {flush_daily_task}) ->
    daily_task_tgr:flush_daily_num(),
    do_flush_daily_task();

handle_msg(FromMod, Msg) ->
    ?ERROR_LOG("~p recv a unknown msg ~p from ~p", [?pname(), Msg, FromMod]).

get_daily_task_list() ->    
    case attr_new:get(?pd_daily_task_list,[]) of
        [] ->
            DailyList = load_richang_task:get_daily_task_id_list_by_player_level(),
            attr_new:set(?pd_daily_task_list, DailyList),
            DailyList;
        List ->
            List
    end.

send_daily_prize(Index) when Index > 0 ->
    %?DEBUG_LOG("Index---------------------------:~p",[Index]),
    {Num, IsTure, L} = attr_new:get(?pd_daily_task_prize_list, []),
    %?DEBUG_LOG("L-----------------------------:~p",[L]),
    case lists:keyfind(Index, 1, L) of
        ?false ->
            ?return_err(?ERR_ERROR_DAILY_TASK_PRIZE);
        {_, TaskCount, 1, PrizeId} ->
            prize:prize_mail(PrizeId, ?S_MAIL_DAILY_BAOXIANG_PRIZE, ?FLOW_REASON_DAILY_TASK),
            put(?pd_daily_task_prize_list, {Num, IsTure, lists:keyreplace(Index, 1, L, {Index, TaskCount, 2, PrizeId})}),
            if
                Index =:= 5 ->
                    put(?pd_daily_task_prize_list, load_richang_task:update_daily_baoxiang_prize());
                true ->
                    pass
            end,
            ?player_send(task_sproto:pkg_msg(?MSG_TASK_DAILY_BAOXIANG_GET_PRIZE, {}));
            %send_daily_prize(Index-1);
        _ ->
            %send_daily_prize(Index-1)
            ?return_err(?ERR_ERROR_DAILY_TASK_PRIZE)
    end;
send_daily_prize(_Index) ->
    pass.

% send_daily_prize(_Index) ->
%     %?ERROR_LOG("_Index----------------------------:~p",[_Index]),
%     ?player_send(task_sproto:pkg_msg(?MSG_TASK_DAILY_BAOXIANG_GET_PRIZE, {})),
%     {_Num, _IsTure, L} = attr_new:get(?pd_daily_task_prize_list, []),
%     ?DEBUG_LOG("send_daily_prize--------------------------:~p",[L]),
%     Size = length(L),
%     case lists:keyfind(Size, 1, L) of
%         ?false ->
%             pass;
%         {_, _TaskCount, 2, _PrizeId} ->
%             ?DEBUG_LOG("1-------------------------------------------"),
%             put(?pd_daily_task_prize_list, load_richang_task:update_daily_baoxiang_prize(get(?pd_task_daily_task_times))),
%             update_baoxiang_prize_statue(get(?pd_task_daily_task_times)),
%             send_daily_list(get_daily_task_list());
%         _ ->
%             pass
%     end.


update_baoxiang_prize_statue(TaskCount) ->
    ?DEBUG_LOG("TaskCount-------------------------:~p",[TaskCount]),
    {CurIndex, IsTure, L} = attr_new:get(?pd_daily_task_prize_list, []),
    ?DEBUG_LOG("CurIndex----:~p-----IsTure----:~p---L----:~p",[CurIndex, IsTure, L]),
    if
        IsTure =:= 1; TaskCount =:= 20 ->
            Size = length(L),
            if
                CurIndex > Size  ->
                    pass;
                true -> 
                    case lists:keyfind(CurIndex, 1, L) of
                        ?false ->
                            pass;
                        {_, TaskCount, _Statue, PrizeId} ->
                            put(?pd_daily_task_prize_list, {CurIndex+1, 0, lists:keyreplace(CurIndex, 1, L, {CurIndex, TaskCount, 1, PrizeId})}),
                            ?DEBUG_LOG("list---------------------------:~p",[get(?pd_daily_task_prize_list)]),
                            send_daily_list(get_daily_task_list());
                        _ ->
                            pass
                    end
            end;
        true ->
            pass
    end.

% update_baoxiang_prize_statue(TaskCount) ->
%     {Index, IsTure, L} = attr_new:get(?pd_daily_task_prize_list, []),
%     %IsTure = 1,
%     %?DEBUG_LOG("L-----------------------------:~p",[L]),
%     case IsTure of
%         1 ->
%             NewIndex = Index + 1,
%             Size = length(L),
%             if
%                 NewIndex > Size  ->
%                     pass;
%                 true -> 
%                     case lists:keyfind(Index+1, 1, L) of
%                         ?false ->
%                             pass;
%                         {_, TaskCount, _Statue, PrizeId} ->
%                             put(?pd_daily_task_prize_list, {NewIndex, 0, lists:keyreplace(NewIndex, 1, L, {NewIndex, TaskCount, 1, PrizeId})}),
%                             send_daily_list(get_daily_task_list());
%                         _ ->
%                             pass
%                     end
%             end;
%         _ ->
%             pass
%     end.

do_flush_daily_task_of_level(17) ->
    do_flush_daily_task();
do_flush_daily_task_of_level(_) ->
    pass.

do_flush_daily_task() ->
    daily_task_tgr:flush_daily_task(),
    DailyList = load_richang_task:get_daily_task_id_list_by_player_level(),
    attr_new:set(?pd_daily_task_list, DailyList),
    %?DEBUG_LOG("DailyList-----------------------:~p",[DailyList]),
    send_daily_list(DailyList).

send_daily_list(NewList) ->
    %?DEBUG_LOG("NewList-----------------:~p",[NewList]),
    DailyListEventData = attr_new:get(?pd_daily_task_list_event_data, []),
    %?DEBUG_LOG("DailyListEventData-----------------:~p",[DailyListEventData]),
    NewListBin = 
    lists:foldl(fun({TaskId, Star, Statue, PrizeId}, Acc) ->
        if
            Statue =:= 0 ->
                <<Acc/binary, TaskId:16, Star:8, Statue:8, PrizeId:16>>;
            Statue =:= 1 ->
                case lists:keyfind(TaskId, 1, DailyListEventData) of
                    ?false ->
                        <<Acc/binary, TaskId:16, Star:8, Statue:8, PrizeId:16>>;
                    {_, OldEventList} ->
                        %?DEBUG_LOG("TaskId-------:~p-----OldEventList---:~p",[TaskId, OldEventList]),
                        EventBin = 
                        lists:foldl(fun({{Event, GoalId}, _GoalNum, CurrentNum}, Bin) ->
                            GoalType = daily_task_tgr:get_event_type(Event),
                            <<Bin/binary, GoalType:8, GoalId:32, CurrentNum:8>>
                        end,
                        <<(length(OldEventList))>>,
                        OldEventList),
                        <<Acc/binary, TaskId:16, Star:8, Statue:8, PrizeId:16, EventBin/binary>>
                end;
            Statue =:= 2; Statue =:= 3 ->
                <<Acc/binary, TaskId:16, Star:8, Statue:8, PrizeId:16>>;
            true ->
                Acc
        end
    end,
    <<(length(NewList))>>,
    NewList),
    DailyCount = attr_new:get(?pd_task_daily_task_times, 0),
    FlushCount = attr_new:get(?pd_task_daily_pay_flush_times, 0) + attr_new:get(?pd_task_daily_free_flush_times, 0),
    BaoxiangBin = daily_task_tgr:baoxiang_data(),
    {_BaoXiangIndex, IsTure, _L} = attr_new:get(?pd_daily_task_prize_list),
    %?DEBUG_LOG("send_daily_list---------------------:~p",[_L]),
    %?DEBUG_LOG("DailyCount----------------:~p",[DailyCount]),
    % ?DEBUG_LOG("FlushCount------------------:~p",[FlushCount]),
    ?player_send(task_sproto:pkg_msg(?MSG_TASK_DAILY_LIST, {DailyCount, FlushCount, IsTure, BaoxiangBin, NewListBin})).

auto_flush_daily_task(NewDailyTaskCount) ->
    IsTure = is_flush(),
    ?DEBUG_LOG("IsTure--------------------------------:~p",[IsTure]),
    if
        NewDailyTaskCount =:= 20 ->
            pass;
        IsTure =:= true ->
            do_flush_daily_task();
        true ->
            pass
    end.

is_flush() ->
    NewList = attr_new:get(?pd_daily_task_list, []), 
    % ?DEBUG_LOG("auto flush NewList--------------------:~p",[NewList]),
    case lists:keyfind(2, 3, NewList) of
        ?false ->
            case lists:keyfind(1, 3, NewList) of
                ?false ->
                    case lists:keyfind(0, 3, NewList) of
                        ?false ->
                            ?true;
                        _ ->
                            ?false
                    end;
                _ ->
                    ?false
            end;
        _ ->
            ?false
    end.

is_doing_task(TaskId) ->
    case task_system:get_dbid_of_task(TaskId) of
        ?none ->
            false;
        DbId ->
            TaskList = attr_new:get(?pd_task_list, []),
            case lists:keyfind(DbId, #task_tab.task_dbid, TaskList) of
                TaskTab when is_record(TaskTab, task_tab) ->
                    TaskTab#task_tab.task_state =:= ?task_finishing;
                _ ->
                    false
            end
    end.
