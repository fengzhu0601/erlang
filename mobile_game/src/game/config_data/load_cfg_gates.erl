%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 10. 三月 2016 下午9:23
%%%-------------------------------------------------------------------
-module(load_cfg_gates).
-author("clark").

%% API
-export([]).

-include_lib("config/include/config.hrl").
-include("inc.hrl").
-include("load_cfg_gates.hrl").


load_config_meta() ->
    [
        #config_meta
        {
            record = #scene_gates_cfg{},
            fields = ?record_fields(scene_gates_cfg),
            file = "gates.txt",
            keypos = #scene_gates_cfg.id,
            verify = fun verify/1
        }
    ].

verify(_) -> ok.
% verify(#scene_gates_cfg{sceneId = SceneId, position = Position, outOffset = OutOffset, approachArea = ApproachArea}) ->
%     List = my_ets:get(?pd_offset_gate_msg, []),
%     List2 = [{SceneId, Position, OutOffset, ApproachArea}|List],
%     my_ets:set(?pd_offset_gate_msg, List2),
%     ok.

