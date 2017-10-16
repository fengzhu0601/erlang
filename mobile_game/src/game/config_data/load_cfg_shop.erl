%%%-------------------------------------------------------------------
%%% @author fengzhu
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 04. 一月 2016 下午4:48
%%%-------------------------------------------------------------------
-module(load_cfg_shop).
-author("fengzhu").

%% API
-export([]).

-include_lib("config/include/config.hrl").
-include("inc.hrl").
-include("load_cfg_shop.hrl").
-include("player_def.hrl").

-define(MONEY_TYPES, [
  ?PL_MONEY,
  ?PL_DIAMOND
]
).  %% 商店价格类型 公会功能联调完成  公会功能联调完成

load_config_meta() ->
  [
    #config_meta{record = #shop_cfg{},
      fields = record_info(fields, shop_cfg),
      file = "shop.txt",
      keypos = #shop_cfg.id,
      verify = fun verify/1}
  ].

verify(#shop_cfg{id = Id, item_bid = ItemBid, money_type = MoneyType, price = Price}) ->
  ?check(com_util:is_valid_uint64(Id), "shop.txt id [~w] 无效! ", [Id]),
  ?check(load_item:is_exist_item_attr_cfg(ItemBid), "shop.txt id [~w] item_bid [~w] 物品不存在! ", [Id, ItemBid]),
  ?check(lists:member(MoneyType, ?MONEY_TYPES), "shop.txt  id [~w]  money_type [~w] 无效  ", [Id, MoneyType]),
  ?check(com_util:is_valid_uint64(Price), "shop.txt  id [~w]  price [~w] 无效  ", [Id, Price]),

  ok;
verify(_R) ->
  ?ERROR_LOG("shop.txt ~p 无效格式", [_R]),
  exit(bad).