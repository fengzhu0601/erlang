%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 20. 七月 2015 下午5:54
%%%-------------------------------------------------------------------
-module(collect_thing_tgr).
-author("clark").

-include("inc.hrl").
-include("task_tgr.hrl").
-include("task_new_def.hrl").
-include("task_def.hrl").
-include("player.hrl").
-include("load_task_progress.hrl").


-export([handle_ev_collect_item/4]).


do(_TgrDBID) -> ok.


reset(TgrDBID) ->
    case TgrDBID of
        {TaskType, TaskId, _Key} ->
            TaskDdId = {TaskType, TaskId},
            case load_task_progress:get_task_new_cfg(TaskId) of
                #task_new_cfg{id = TaskId, type = _Type, goal = {CollectId, _Count}} ->
                    single_dig:del_dig_thing(CollectId),
                    task_system:reset_task_data(TaskDdId),
                    event_eng:unreg(?ev_collect_item, {task, TaskDdId});
                ?none ->
                    pass
            end;
        _ ->
            %?DEBUG_LOG("collect pass--------------------------"),
            pass
    end,
    ok.


start(TgrDBID) ->
    %?DEBUG_LOG("collect_thing_tgr tgrdbid-----------:~p", [TgrDBID]),
    case TgrDBID of
        {TaskType, TaskId, _Key} ->
            TaskDdId = {TaskType, TaskId},
            case load_task_progress:get_task_new_cfg(TaskId) of
                #task_new_cfg{id = TaskId, type = Type, goal = {CollectId, Count}} ->
                    event_eng:reg(?ev_collect_item, CollectId, {task, TaskDdId}, {?MODULE, handle_ev_collect_item}, Type),
                    single_dig:add_dig_thing(CollectId, Count),
                    task_system:set_tgr_db_data(TaskDdId, Count, {CollectId, 0}, true);
                ?none ->
                    pass
            end;
        _ ->
            %?DEBUG_LOG("collect pass--------------------------"),
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
                {Total, {_OldCollectId, V}} ->
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


handle_ev_collect_item({task, TaskDdId} = Key, _CollectId, _Type, _) ->
    %?DEBUG_LOG("CollectId------------:~p", [CollectId]),
    {TaskType, TaskId} = TaskDdId,
    GoalType = load_task_progress:get_task_goal_type(TaskId),
    case task_system:get_tgr_db_data(TaskDdId) of
        ?task_nil ->
            event_eng:unreg(?ev_collect_item, Key);
        {Total, {OldCollectId, V}} ->
            %?DEBUG_LOG("OldCollectId --:~p", [{OldCollectId, V}]),
            NewV = V + 1,
            ?assert(NewV =< Total),
            ?player_send(task_sproto:pkg_msg(?MSG_TASK_PROGRESS, {TaskId,GoalType, OldCollectId, NewV})),
            task_system:set_tgr_db_data(TaskDdId, Total, {OldCollectId, NewV}, true),
            if
                NewV >= Total ->
                    if
                        NewV =:= Total ->
                            task_system:finish_task_trigger_task(TaskType, TaskId);
                        true ->
                            pass
                    end,
                    single_dig:del_dig_thing(OldCollectId),
                    event_eng:unreg(?ev_collect_item, Key),
                    task_system:try_change_state(TaskDdId);
                true ->
                    pass
            end
    end.
