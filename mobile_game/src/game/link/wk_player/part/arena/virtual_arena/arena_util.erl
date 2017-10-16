%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 29. 十二月 2015 下午2:10
%%%-------------------------------------------------------------------
-module(arena_util).
-author("clark").

%% API
-export
([
    stop/0,
    get_arena/1
]).

-include("arena.hrl").
-include("inc.hrl").
-include("player.hrl").
-include("arena_struct.hrl").

get_arena(ArenaType) ->
    case do_get_arena(ArenaType) of
        undefined ->
            undefined;
        CurMod ->
            erlang:put(?cur_arena_type, ArenaType),
            CurMod
    end.

stop() ->
    case erlang:get(?cur_arena_type) of
        undefined ->
            ok;
        ArenaType ->
            Mod = do_get_arena(ArenaType),
            case Mod:stop() of
                ok ->
                    erlang:erase(?cur_arena_type),
                    ok;
                _ ->
                    error
            end
    end.

do_get_arena(ArenaType) ->
    case ArenaType of
        ?ARENA_TYPE_P2E         -> arena_p2e;
        ?ARENA_TYPE_P2P         -> arena_p2p;
        ?ARENA_TYPE_MULTI_P2P   -> arena_m_p2p;
        ?ARENA_TYPE_COMPETE     -> arena_compete;
        _ -> undefined
    end.
