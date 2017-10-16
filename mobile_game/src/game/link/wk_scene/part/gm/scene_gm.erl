%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 07. 一月 2016 下午3:06
%%%-------------------------------------------------------------------
-module(scene_gm).
-author("clark").

%% API
-export
([
    handle_call/2
]).



-include("scene_msg_sign.hrl").


handle_call
(
    {_FromPid, _Tag},
    {
        ?scene_call_player_count
    }
) ->
    scene_player:players_count();


handle_call(_Msg, _Par) ->
    ret:error(unknown).