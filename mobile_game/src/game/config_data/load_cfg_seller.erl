%%%-------------------------------------------------------------------
%%% @author fengzhu
%%% @copyright (C) 2016, <COMPANY>
%%% @doc 神秘商人
%%%
%%% @end
%%% Created : 04. 一月 2016 下午3:57
%%%-------------------------------------------------------------------
-module(load_cfg_seller).
-author("fengzhu").

%% API
-export([]).

-include_lib("config/include/config.hrl").
-include("inc.hrl").
-include("load_cfg_seller.hrl").

load_config_meta() ->
  [
    #config_meta{record = #seller_cfg{},
      fields = ?record_fields(?seller_cfg),
      file = "seller_items.txt",
      keypos = #seller_cfg.id,
      verify = fun verify_seller/1},

    #config_meta{record = #seller_refresh_cfg{},
      fields = ?record_fields(?seller_refresh_cfg),
      file = "seller_refresh.txt",
      keypos = #seller_refresh_cfg.id,
      all = [#seller_refresh_cfg.id],
      verify = fun verify_seller_refresh/1}
  ].

verify_seller(#seller_cfg{id = Id, item_bid = ItemBid, money_type = MoneyType, price = Price}) ->
  ?check(com_util:is_valid_uint64(Id), "seller_items.txt id [~w] 无效! ", [Id]),
  ?check(load_item:is_exist_item_attr_cfg(ItemBid), "seller_items.txt id [~w] item_bid [~w] 物品不存在! ", [Id, ItemBid]),
  ?check(?is_pos_integer(MoneyType), "seller_items.txt  id [~w]  money_type [~w] 无效  ", [Id, MoneyType]),
  ?check(com_util:is_valid_uint64(Price), "seller_items.txt  id [~w]  price [~w] 无效  ", [Id, Price]),
  ok.

verify_seller_refresh(#seller_refresh_cfg{id = Id, lv_range = LvRange, sellerIds_and_career = SellerIdsByCareer}) ->
  ?check(com_util:is_valid_uint64(Id), "seller_refresh.txt id [~w] 无效! ", [Id]),
  [MinLv, MaxLv] = LvRange,
  ?check(?is_pos_integer(MinLv) and ?is_pos_integer(MaxLv) and (MinLv =< MaxLv), "seller_refresh.txt  id [~w]  lv_range [~w] 无效  ", [Id, LvRange]),
  ?check(is_exist_seller_id(SellerIdsByCareer), "seller_refresh.txt  id [~w]  sellerIds_and_career [~w] 无效  ", [Id, SellerIdsByCareer]),
  ok.

is_exist_seller_id(SellerIdsByCareer) ->
  lists:all(
    fun({Career, SellerIds}) ->
      player_def:is_valid_career(Career) and is_exist_seller(SellerIds)
    end,
    SellerIdsByCareer).

is_exist_seller({SellerId, Weight}) ->
  case lookup_seller_cfg(SellerId) of
    #seller_cfg{} ->
      if
        (Weight >= 0) and (Weight =< 100) -> true;
        true -> false
      end;
    _ -> false
  end;

is_exist_seller(SellerIds) when is_tuple(hd(SellerIds)) ->

  if
    length(SellerIds) >= ?SELLER_DEFAULT_ITEM_NUM ->
      lists:all(fun(SellerId) -> is_exist_seller(SellerId) end, SellerIds);
    true -> false
  end.
