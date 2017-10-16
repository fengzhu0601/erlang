%%%-------------------------------------------------------------------
%%% @author lan
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 12. 五月 2016 下午5:10
%%%-------------------------------------------------------------------
-module(load_cfg_punchs).
-author("lan").

-include("load_cfg_punchs.hrl").
-include("inc.hrl").
-include_lib("config/include/config.hrl").

%% API
-export([
    get_punch_rate/1
    , get_all_punch_bid/0
    , get_punch_type_by_bid/1
]).

load_config_meta() ->
  [
    #config_meta
    {
      record = #punchs_cfg{},
      fields = ?record_fields(punchs_cfg),
      file = "punchs.txt",
      keypos = #punchs_cfg.id,
      all = [#punchs_cfg.id],
      verify = fun verify/1
    }
  ].

verify(#punchs_cfg{id=_Id}) ->
  ok.

get_punch_rate(Id) ->
    case lookup_punchs_cfg(Id) of
        #punchs_cfg{rate = Rate} -> Rate;
        _ -> ret:error(unknow_data)
    end.

%% 获取所有的打孔器id
get_all_punch_bid() ->
  lookup_all_punchs_cfg(#punchs_cfg.id).

%% 获得打孔器类型
get_punch_type_by_bid(Bid) ->
    case lookup_punchs_cfg(Bid) of
        #punchs_cfg{type = Type} -> Type;
        _ -> ret:error(unknow_data)
    end.


