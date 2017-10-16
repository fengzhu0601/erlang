%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 20. 七月 2015 下午5:48
%%%-------------------------------------------------------------------
-module(talk_npc_tgr).
-author("clark").




-include("task_tgr.hrl").

reset(TgrDBID) -> 
 	case TgrDBID of
        {TaskType, TaskId, _Key} ->
            TaskDdId = {TaskType, TaskId},
            task_system:reset_task_data(TaskDdId);
        _ ->
            pass
    end,
    ok.

start(_TgrDBID) -> ok.
stop(_TgrDBID) -> ok.
do(_TgrDBID) ->
    ok.


can(TgrDBID) ->
    _NPC_ID = task_system:get_tgr_config_data(TgrDBID),
    true.

can_accept(_TgrDBID) ->
    true.