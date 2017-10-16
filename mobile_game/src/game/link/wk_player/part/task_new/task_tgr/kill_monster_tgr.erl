%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 20. 七月 2015 下午5:52
%%%-------------------------------------------------------------------
-module(kill_monster_tgr).
-author("clark").




%% API
-include("inc.hrl").
-include("task_tgr.hrl").
-include("task_new_def.hrl").
-include("task_def.hrl").
-include("player.hrl").
-include("load_task_progress.hrl").


-export([handle_ev_kill_monster/4]).

do(_TgrDBID) -> ok.

reset(TgrDBID) ->
    case TgrDBID of
        {TaskType, TaskId, _Key} ->
            TaskDdId = {TaskType, TaskId},
            task_system:reset_task_data(TaskDdId),
            event_eng:unreg(?ev_kill_monster_by_bid, {task, TaskDdId});
        _ ->
            ?DEBUG_LOG("handle_ev_kill_monster pass--------------------------"),
            pass
    end,
    ok.


start(TgrDBID) ->
    case TgrDBID of
        {TaskType, TaskId, _Key} ->
            TaskDdId = {TaskType, TaskId},
            case load_task_progress:get_task_new_cfg(TaskId) of
                #task_new_cfg{id = TaskId, type = Type, goal = {MonsterId, Count}} ->
                    event_eng:reg(?ev_kill_monster_by_bid, MonsterId, {task, TaskDdId}, {?MODULE, handle_ev_kill_monster}, Type),
                    task_system:set_tgr_db_data(TaskDdId, Count, {MonsterId, 0}, true);
                ?none ->
                    pass
            end;
        _ ->
            ?DEBUG_LOG("handle_ev_kill_monster pass--------------------------"),
            pass
    end,
    ok.

stop(_TgrDBID) ->
    ok.

can(TgrDBID) ->
    case TgrDBID of
        {TaskType, TaskId, _Key} ->
            TaskDdId = {TaskType, TaskId},
            case task_system:get_tgr_db_data(TaskDdId) of
                ?task_nil ->
                    false;
                {Total, {_OldMonsterId, V}} ->
                    if
                        Total =< V ->
                            true;
                        true ->
                            false
                    end
            end;
        _ ->
            false
    end.


can_accept(_TgrDBID) ->
    true.

handle_ev_kill_monster({task, TaskDdId} = Key, MonsterId, _Type, _) ->
    ?DEBUG_LOG("MonsterId------------:~p", [MonsterId]),
    {TaskType, TaskId} = TaskDdId,
    GoalType = load_task_progress:get_task_goal_type(TaskId),
    case task_system:get_tgr_db_data(TaskDdId) of
        ?task_nil ->
            event_eng:unreg(?ev_kill_monster_by_bid, Key);
        {Total, {OldMonsterId, V}} ->
            ?DEBUG_LOG("OldMonsterId --:~p", [OldMonsterId]),
            NewV = V + 1,
            ?assert(NewV =< Total),
            ?player_send(task_sproto:pkg_msg(?MSG_TASK_PROGRESS, {TaskId, GoalType, OldMonsterId, NewV})),
            task_system:set_tgr_db_data(TaskDdId, Total, {OldMonsterId, NewV}, true),
            if
                NewV >= Total ->
                    if
                        NewV =:= Total ->
                            task_system:finish_task_trigger_task(TaskType, TaskId);
                        true ->
                            pass
                    end,
                    event_eng:unreg(?ev_kill_monster_by_bid, Key),
                    task_system:try_change_state(TaskDdId);
                true ->
                    pass
            end
    end.