%%%-------------------------------------------------------------------
%%% @author fengzhu
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 31. 十二月 2015 下午3:32
%%%-------------------------------------------------------------------
-module(load_cfg_title).
-author("fengzhu").

%% API
-export([
  lookup_global_title/0
]).

-include_lib("config/include/config.hrl").
-include("inc.hrl").
-include("load_cfg_title.hrl").


load_config_meta() ->
  [
    #config_meta{record = #title_cfg{},
      fields = ?record_fields(title_cfg),
      file = "title.txt",
      keypos = #title_cfg.id,
      groups = [#title_cfg.type],
      verify = fun verify_title_cfg/1}
  ].

verify_title_cfg(_) -> ok.

lookup_global_title() ->
  lookup_group_title_cfg(#title_cfg.type, ?global_title_type).

