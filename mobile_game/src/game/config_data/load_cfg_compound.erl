%%%-------------------------------------------------------------------
%%% @author lan
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 22. 七月 2016 下午3:44
%%%-------------------------------------------------------------------
-module(load_cfg_compound).
-author("lan").


%% API
-export([
    get_compound_mes/1
]).

-include("inc.hrl").
-include_lib("config/include/config.hrl").
-include("load_cfg_compound.hrl").



load_config_meta() ->
    [
        #config_meta{
            record = #compound_cfg{},
            fields = ?record_fields(compound_cfg),
            file = "compound.txt",
            keypos = #compound_cfg.item_id,
            verify = fun verify/1}
    ].

verify(#compound_cfg{id = Id, item_id = ItemId, compound = ComTuple}) ->
  ?check(load_item:is_exist_item_cfg(ItemId), "compound.txt id [~p] item_id ~p 没有找到", [Id, ItemId]),
  ?check(is_tuple(ComTuple), "compound.txt id [~p] compound ~p 格式不正确", [Id, ComTuple]),
  {ItemId1, ItemCount} = ComTuple,
  ?check(load_item:is_exist_item_cfg(ItemId1), "compound.txt id [~p] item_id ~p 没有找到", [Id, ItemId1]),
  ?check(is_integer(ItemCount), "compound.txt id [~p] 消耗物品数量count ~p格式不正确", [Id, ItemCount]),
  ok.

get_compound_mes(ItemId) ->
    case lookup_compound_cfg(ItemId) of
        #compound_cfg{compound = ComTuple} ->
            ComTuple;
        _ ->
            ret:error(unknow_type)
    end.