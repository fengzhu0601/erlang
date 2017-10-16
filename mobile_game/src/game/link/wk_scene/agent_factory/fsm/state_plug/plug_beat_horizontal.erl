%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 11. 十一月 2015 下午5:20
%%%-------------------------------------------------------------------
-module(plug_beat_horizontal).
-author("clark").

%% API
-export([]).

-include("i_plug.hrl").
-include("skill_struct.hrl").
-include("load_spirit_attr.hrl").
-include("inc.hrl").
-include("scene.hrl").
-include("scene_agent.hrl").

on_event(_Agent, _Event) -> none.
can_start(#agent{}, _TPar) -> ret:ok().
start(#agent{} = Agent, TPar) -> restart(Agent, TPar).
restart(#agent{} = Agent, _TPar) -> Agent.



run(#agent{idx=Idx, x = X, y = Y, h = H} = Agent, {Dir, DtX}) ->
    X1 =
        case Dir of
            ?D_R -> X + DtX;
            ?D_L -> X - DtX
        end,
    Agent1 =
        case room_map:is_walkable(Idx, X1, Y) of
            true -> map_agent:set_position(Agent, {X1, Y, H});
            _ -> Agent
        end,
    Agent1.

stop(#agent{} = Agent) -> Agent.


can_interrupt(#agent{} = _Agent, _StatePlugList) ->
    ret:ok().
