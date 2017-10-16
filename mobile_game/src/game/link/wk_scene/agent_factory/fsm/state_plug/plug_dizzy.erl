%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 17. 五月 2016 下午3:13
%%%-------------------------------------------------------------------
-module(plug_dizzy).
-author("clark").

%% API
-export
([
    is_dizzy/1
]).



-include("i_plug.hrl").
-include("skill_struct.hrl").
-include("load_spirit_attr.hrl").
-include("inc.hrl").
-include("scene.hrl").
-include("scene_agent.hrl").

on_event(_Agent, _Event) -> none.
can_start(#agent{}, {_DizzyDt}) ->
    ret:ok().

start(#agent{} = Agent, TPar) ->
    restart(Agent, TPar).
restart(#agent{} = Agent, _TPar) ->
    Agent.

run
(
    #agent
    {
    } = Agent,
    {DizzyDt}
) ->
    CurTm = com_time:timestamp_msec(),
    Agent1 = Agent#agent{ dizzy_time = CurTm + DizzyDt },
    Agent1.


stop(#agent{} = Agent) ->
    Agent1 = Agent#agent{dizzy_time = 0},
    Agent1.


can_interrupt(#agent{} = _Agent, _StatePlugList) ->
    ret:ok().


is_dizzy(#agent{dizzy_time = EndTm}) ->
    CurTm = com_time:timestamp_msec(),
    if
        CurTm > EndTm ->
            ret:error(isnot_dizzy);
        true ->
%%             ?INFO_LOG("is dizzy true"),
            ret:ok()
    end;

is_dizzy(Idx) ->
    case ?get_agent(Idx) of
        #agent{} = Agt -> is_dizzy(Agt);
        _ -> ret:error(isnot_dizzy)
    end.


