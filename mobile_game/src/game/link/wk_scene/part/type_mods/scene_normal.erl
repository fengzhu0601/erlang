%%%-------------------------------------------------------------------
%%% @author zl

%%% @doc 主场景类型
%%%
%%% @end
%%%-------------------------------------------------------------------

-module(scene_normal).

-include("inc.hrl").
-include("scene.hrl").
-include("scene_type_mod.hrl").
-include("load_cfg_scene.hrl").


type_id() -> ?SC_TYPE_NORMAL.


init(Cfg) ->
    ?assert(?SC_TYPE_NORMAL =:= Cfg#scene_cfg.type),
    ok.

uninit(_) ->
    ok.


handle_msg(Msg) ->
    ?err({unknown_msg, Msg}).

handle_timer(_, Msg) ->
    ?err({unknown_timer, Msg}).

