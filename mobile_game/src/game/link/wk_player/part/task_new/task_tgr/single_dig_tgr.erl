    %%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 23. 七月 2015 下午4:43
%%%-------------------------------------------------------------------
-module(single_dig_tgr).
-author("clark").

%% API
-export([
    handle_ev_single_ins/4,
    online_reset_reg/2
]).


-include("inc.hrl").

-include("task_tgr.hrl").
-include("player.hrl").
-include("task_new_def.hrl").
-include("main_ins_struct.hrl").
-include("load_cfg_main_ins.hrl").

online_reset_reg(TaskId, TaskType) ->
    TaskDdId = {TaskType, TaskId},
    %?DEBUG_LOG("TaskId------------:~p-----------TaskType------:~p",[TaskId, TaskType]),
    case load_task_progress:get_task_goal_type(TaskId) of
        8 ->
            event_eng:reg(?ev_main_ins_pass, all, {task, TaskDdId}, {?MODULE, handle_ev_single_ins}, TaskType);
        _ ->
            pass
    end.


reset(TgrDBID) ->
    case TgrDBID of
        {TaskType, TaskId, _Key} ->
            TaskDdId = {TaskType, TaskId},
            task_system:reset_task_data(TaskDdId),
            event_eng:unreg(?ev_main_ins_pass, {task, TaskDdId});
        _ ->
            pass
    end,
    ok.

start(TgrDBID) ->
    %?DEBUG_LOG("TgrDBID---------------------------:~p",[TgrDBID]),
    case TgrDBID of
        {TaskType, TaskId, _Key} ->
            TaskDdId = {TaskType, TaskId},
            case task_system:get_tgr_config_data(TgrDBID) of
                ?task_nil ->
                    pass;
                {SceneId, Count} ->
                    event_eng:reg(?ev_main_ins_pass, all, {task, TaskDdId}, {?MODULE, handle_ev_single_ins}, TaskType),
                    TaskResult = task_system:get_tgr_db_data(TaskDdId),
                    if
                        TaskResult =:= ?task_nil; TaskResult =:= ?none ->
                            task_system:set_tgr_db_data(TaskDdId, Count, {SceneId, 0}, true);
                        true ->
                            ?DEBUG_LOG("pass----------------------------"),
                            pass
                    end
            end;
        _ ->
            pass
    end,
    ok.

stop(_TgrDBID) -> ok.
can(TgrDBID) ->
    R = 
    case TgrDBID of
        {TaskType, TaskId, _Key} ->
            TaskDdId = {TaskType, TaskId},
            case task_system:get_tgr_db_data(TaskDdId) of
                ?task_nil ->
                    false;
                {Total, {_SceneId, V}} ->
                    if
                        Total =< V ->
                            true;
                        true ->
                            false
                    end
            end;
        _ ->
            false
    end,
    %?DEBUG_LOG("single_dig_tgr---------------------------:~p",[R]),
    R.
 can_accept(_TgrDBID) ->
    true.


do(_TgrDBID) ->
    ok.

handle_ev_single_ins({task, TaskDdId} = Key, {_LastSceneId, InsId, Difficutly}, _Type, _) ->
    {TaskType, TaskId} = TaskDdId,
    %?DEBUG_LOG("TaskId-----------------------:~p",[{TaskId, TaskType, InsId, Difficutly}]),
    GoalType = load_task_progress:get_task_goal_type(TaskId),
    case task_system:get_tgr_db_data({TaskType, TaskId}) of
        ?task_nil ->
            pass;
        {Total, {SceneId, V}} ->
            %?DEBUG_LOG("SceneId --:~p--main cfg ---------:~p",[SceneId, main_ins:lookup_main_ins_cfg(SceneId)]),
            case load_cfg_main_ins:lookup_main_ins_cfg(SceneId) of
                #main_ins_cfg{ins_id = InsId, sub_type = Difficutly} ->
                    %?DEBUG_LOG("is------------------------------------"),
                    NewV = V + 1,
                    if
                        NewV =< Total ->
                            %?DEBUG_LOG("TaskId--------SceneId-------NewV-----:~p",[{TaskId, SceneId, NewV}]),
                            ?player_send(task_sproto:pkg_msg(?MSG_TASK_PROGRESS, {TaskId, GoalType, SceneId, NewV})),
                            task_system:set_tgr_db_data(TaskDdId, Total, {SceneId, NewV}, true);
                        true ->
                            pass
                    end,
                    if
                        NewV >= Total ->
                            if
                                NewV =:= Total ->
                                    task_system:finish_task_trigger_task(TaskType, TaskId);
                                true ->
                                    pass
                            end,
                            event_eng:unreg(?ev_main_ins_pass, Key),
                            task_system:try_change_state(TaskDdId);
                        true ->
                            pass
                    end;
                _ ->
                    pass
            end;
        _ ->
            pass
    end.





