%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 13. 十一月 2015 下午10:33
%%%-------------------------------------------------------------------
-module(dead_tgr).
-author("clark").

%% API
-export(
[
    start/2
    , stop/1
    , is_run/1
]).

-export(
[
    handle_timer/2
]).


-include("inc.hrl").
-include("scene.hrl").
-include("scene_agent.hrl").





start(#agent{idx = Idx} = Agent, DelayTm) ->
    ?INFO_LOG("dead_tgr start"),
    Agent1 = stop(Agent),
    Tref = scene_eng:start_timer(DelayTm, ?MODULE, {dead, Idx}),
    Agent2 = Agent1#agent{pl_del_timer = Tref},
    ?update_agent(Idx, Agent2),
    Agent2.



stop(#agent{idx = Idx, pl_del_timer = TimerRef} = Agent) ->
    if
        TimerRef =/= ?none -> scene_eng:cancel_timer(TimerRef);
        true -> ok
    end,
    ?assert(not scene_eng:is_wait_timer(TimerRef)),
    Agent1 = Agent#agent{pl_del_timer = ?none},
    ?update_agent(Idx, Agent1),
    Agent1.

is_run(#agent{pl_del_timer = TimerRef}) ->
    scene_eng:is_wait_timer(TimerRef).




%% ----------------------
%% private
%% ----------------------
handle_timer(_Ref, {dead, Idx}) ->
    ?INFO_LOG("dead_tgr handle_timer"),
    map_agent:delete(Idx);

handle_timer(_Ref, Msg) ->
    ?ERROR_LOG("unknown msg ~p", [Msg]).

