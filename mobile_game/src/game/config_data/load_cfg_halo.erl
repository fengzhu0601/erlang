-module(load_cfg_halo).

-export([]).

-include_lib("config/include/config.hrl").
-include("inc.hrl").
-include("load_cfg_halo.hrl").

load_config_meta() ->
    [
	    #config_meta{
	    	record = #halo_cfg{},
	        fields = ?record_fields(halo_cfg),
	        file = "halo.txt",
	        keypos = #halo_cfg.id,
	        verify = fun verify_halo_cfg/1
	    }
    ].

verify_halo_cfg(#halo_cfg{}) -> ok.

