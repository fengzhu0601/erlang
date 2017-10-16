%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 06. 十一月 2015 下午12:21
%%%-------------------------------------------------------------------
-module(debug).
-author("clark").

%% API
-export
([
    show_svr_pos/1,
    show_hit_area/2,
    show_error/2
]).


-include("inc.hrl").
-include("scene_agent.hrl").
-include("player.hrl").



show_svr_pos(#agent{idx = Idx, x = X, y = Y, debug_x=DX, debug_y=DY} = Agent) -> ok.
%%     if
%%         X =/= DX orelse Y =/= DY ->
%%             ?INFO_LOG("test debug id:~p, pos:~p", [Idx, {Agent#agent.x, Agent#agent.y, Agent#agent.h}]),
%%             Agent1 = Agent#agent{debug_x=X, debug_y=Y},
%%             ?update_agent(Idx, Agent1),
%%             map_aoi:broadcast_view_me_agnets_and_me(Agent, debug_sproto:pkg_msg(?MSG_DEBUG_MOVE, {Idx, Agent#agent.x, Agent#agent.y, Agent#agent.h}));
%%
%%         true ->
%%             pass
%%     end.



show_hit_area(#agent{idx = Idx} = Agent, XYList) -> ok.
%%     ?INFO_LOG("show_hit_area ~p", [{Agent, XYList}]),
%%     Pkg = debug_sproto:pkg_msg(?MSG_DEBUG_SKILL_HIT_AREA, {Idx, XYList}),
%%     map_aoi:broadcast_view_me_agnets_and_me(Agent, Pkg).


show_error(_Error, _Tpar) -> ok.
%%     Msg = erlang:iolist_to_binary(io:format("~ts ~p",[Error, Tpar])),
%%     ?player_send(debug_proto:pkg_msg(?MSG_DEBUG_ERROR_MSG, Msg)).

