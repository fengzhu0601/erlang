%%%-------------------------------------------------------------------
%%% @author fengzhu
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 29. 一月 2016 下午5:27
%%%-------------------------------------------------------------------
-module(arena_compete).
-author("fengzhu").

%% API
-export([start/1]).

-include("i_arena.hrl").
-include("arena.hrl").
-include("inc.hrl").
-include("player.hrl").
-include("arena_struct.hrl").
-include("achievement.hrl").

start() -> ok.

start(MPlayerId) ->
    arena_server:start_compete([get(?pd_id), MPlayerId]).

stop() -> ok.

start_match({SceneId, X, Y, Dir, Party}) ->
    put(pd_party, Party),
    CountSet = attr_new:get(?pd_is_near_player_count_set),
    if
        CountSet =:= 0 -> erlang:put(?pd_is_near_player_count_set, 1);
        true -> ok
    end,
    case scene_mng:enter_scene_request(SceneId, X, Y, Dir) of
        approved ->
            erlang:put(pd_is_send_prize, false),
            ok;
        _E ->
            ?ERROR_LOG("enter compete fail. Reason ~w", [_E]),
            ok
    end.

over_match(_) -> ok.



