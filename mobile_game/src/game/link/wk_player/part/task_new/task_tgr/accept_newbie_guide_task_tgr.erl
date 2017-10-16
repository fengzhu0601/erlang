%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 20. 七月 2015 下午6:34
%%%-------------------------------------------------------------------
-module(accept_newbie_guide_task_tgr).
-author("clark").
-include("inc.hrl").

-include("task_tgr.hrl").
-include("player_def.hrl").
-include("task_new_def.hrl").

reset(TgrDBID) -> ok.

start(TgrDBID) ->
    case task_system:get_tgr_config_data(TgrDBID) of
        ?task_nil ->
            %?DEBUG_LOG("none-------------------"),
            pass;
        List ->
            %?DEBUG_LOG("accept List ---:~p", [List]),
            [task_system:accept(Id) || Id <- List]
    end.

stop(_TgrDBID) -> ok.
can(_TgrDBID) -> true.


can_accept(_TgrDBID) ->
    true.
do(TgrDBID) ->
    case TgrDBID of
        {_TaskType, TaskId, _Key} ->
            case load_task_progress:get_next_task_id(TaskId) of
                none ->
                    %?DEBUG_LOG("none-------------------"),
                    pass;
                NextTaskId ->
                    %?DEBUG_LOG("TaskId ---:~p---NextTaskId----------------:~p", [TaskId, NextTaskId]),
                    case load_task_progress:is_new_wizard_task(NextTaskId) of
                        true ->
                            task_system:accept(NextTaskId);
                        false ->
                            pass
                    end
            end;
        _ ->
            ?task_nil
    end,
    ok.
