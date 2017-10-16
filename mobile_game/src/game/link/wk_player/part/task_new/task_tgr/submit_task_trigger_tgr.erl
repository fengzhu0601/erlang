%%%-------------------------------------------------------------------
%%% @author dsl
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%%-------------------------------------------------------------------
-module(submit_task_trigger_tgr).
-author("clark").
-include("inc.hrl").

-include("task_tgr.hrl").
-include("player_def.hrl").
-include("task_new_def.hrl").


reset(_TgrDBID) -> ok.

start(_TgrDBID) -> ok.
stop(_TgrDBID) -> ok.
can(_TgrDBID) -> true.

can_accept(_TgrDBID) ->
    true.

do(TgrDBID) ->
    case task_system:get_tgr_config_data(TgrDBID) of
        ?task_nil ->
            %?DEBUG_LOG("none-------------------"),
            pass;
        List ->
            %?DEBUG_LOG("submit TgrDBID----:~p-- List ---:~p", [TgrDBID, List]),
            [task_system:accept(Id) || Id <- List]
    end.