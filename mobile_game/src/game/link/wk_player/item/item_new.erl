%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 31. 七月 2015 下午2:36
%%%-------------------------------------------------------------------
-module(item_new).
-author("clark").

%% API
-export([
    build/2
    , set_field/3
    , set_fields/2
    , get_main_type/1
    , get_type/1
    , get_bid/1
    , get_field/2
    , get_field/3
    , get_fields/1
    , get_num/1
    , can_overlap/2
    , get_item_new_field_value_by_key/4
]).



-include("inc.hrl").
-include("item_new.hrl").
-include("load_item.hrl").
-include("player.hrl").


build(Bid, Num) ->
    case load_item:lookup_item_attr_cfg(Bid) of
        #item_attr_cfg{type = GoodsType, overlap = OverLap} ->
            if
                OverLap == 1 ->
                    #item_new
                    {
                        id = attr_new:create_uid(),
                        bid = Bid,
                        type = GoodsType,
                        quantity = 1,
                        bind = 0
                    };
                true ->
                    #item_new
                    {
                        id = attr_new:create_uid(),
                        bid = Bid,
                        type = GoodsType,
                        quantity = Num,
                        bind = 0
                    }
            end;
        _ ->
            {error, unknown_type}
    end.

get_main_type(#item_new{bid = Bid}) -> load_item:get_main_type(Bid).

get_type(#item_new{type = CurGoodsType}) -> CurGoodsType.

get_bid(#item_new{bid = Bid}) -> Bid.

get_num(#item_new{quantity = Quantity}) -> Quantity.

set_field(Item = #item_new{field = FieldList}, Key, Val) ->
    NewList = lists:keystore(Key, 1, FieldList, {Key, Val}),
    setelement(#item_new.field, Item, NewList).

set_fields(Item = #item_new{}, []) -> Item;
set_fields(Item = #item_new{}, [{Key, Val} | TailList]) ->
    NewItem = set_field(Item, Key, Val),
    set_fields(NewItem, TailList).

get_field(Item = #item_new{}, Key) -> get_field(Item, Key, 0).
get_field(#item_new{field = FieldList}, Key, Default) ->
    case lists:keyfind(Key, 1, FieldList) of
        {_Key, Val} -> Val;
        _ -> Default
    end.
get_fields(#item_new{field = FieldList}) ->
    FieldList.

get_item_new_field_value_by_key(#item_new{field=FieldList}, Key1, Key2, Default) ->
    case lists:keyfind(Key1, 1, FieldList) of
        {_, L} ->
            case lists:keyfind(Key2, 1, L) of
                {_, V} ->
                    V;
                _ ->
                    Default
            end;
        _ ->
            Default
    end;
get_item_new_field_value_by_key(_Item, _, _, Default) ->
    Default.


can_overlap(#item_new{bid = BidLeft, quantity = LeftQty}, #item_new{bid = BidRitht, quantity = RightQty}) ->
    if
        BidLeft =/= BidRitht -> ret:error(cant_overlap);
        true ->
            case load_item:get_item_cfg(BidLeft) of
                {error, ErrorForm} ->
                    {error, ErrorForm};
                CfgLeft ->
                    Sum = LeftQty + RightQty,
                    if
                        CfgLeft#item_attr_cfg.overlap < Sum -> ret:error(cant_overlap);
                        true -> ret:ok()
                    end
            end
    end.


