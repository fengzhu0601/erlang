%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 06. 十一月 2015 下午2:47
%%%-------------------------------------------------------------------
-module(move_debug_tgr).
-author("clark").

%% API
-export(
[
    handle_timer/2
]).

-export(
[
    start/1,
    stop/1
]).



-include("inc.hrl").
-include("scene_agent.hrl").
-include("player.hrl").

start(#agent{idx = Idx}) ->
    Timer = scene_eng:start_timer(200, ?MODULE, {move_debug, Idx}),
    erlang:put({move_debug, Idx}, Timer).


stop(#agent{idx = Idx}) ->
    Timer = erlang:get({move_debug,Idx}),
    scene_eng:cancel_timer(Timer).


handle_timer(_Ref, {move_debug, Idx}) ->
    Agent = ?get_agent(Idx),
    case Agent of
        #agent{} ->
            debug:show_svr_pos(Agent),
            start(Agent);
        _ ->
            ok
    end;


handle_timer(_Ref, Msg) ->
    ?ERROR_LOG("unknown msg ~p", [Msg]).