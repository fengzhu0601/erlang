-module(load_cfg_arena_robot).

-export([]).

-include_lib("config/include/config.hrl").
-include("inc.hrl").
-include("load_cfg_arena_robot.hrl").

load_config_meta() ->
    [
	    #config_meta{
	    	record = #arena_robot_cfg{},
	        fields = ?record_fields(arena_robot_cfg),
	        file = "arena_robot.txt",
	        keypos = #arena_robot_cfg.id,
	        all = [#arena_robot_cfg.id],
	        verify = fun verify/1
	    }
    ].

verify(#arena_robot_cfg{}) -> ok.

