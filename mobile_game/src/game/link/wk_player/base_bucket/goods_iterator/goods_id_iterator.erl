%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 10. 十二月 2015 下午5:56
%%%-------------------------------------------------------------------
-module(goods_id_iterator).
-author("clark").

%% API
-export
([
    find/2
    , can_add/2         %% 增加物品
    , can_del/2         %% 减少物品
    , add/2
    , del/2
]).



-include("inc.hrl").
-include("bucket_interface.hrl").
-include("item_bucket.hrl").
-include("load_item.hrl").
-include("player.hrl").




find(Bucket = #bucket_interface{}, {GoodsID}) ->
    GoodsList = goods_bucket:get_goods_sink_list(Bucket),
    case lists:keyfind(GoodsID, #bucket_sink_interface.id, GoodsList) of
        #bucket_sink_interface{goods = Goods} -> Goods;
        _ -> ret:error(no_item)
    end.

can_add(Bucket = #bucket_interface{}, {_Goods}) ->
    Size = goods_bucket:get_empty_size(Bucket),
    if
        Size > 0 -> ret:ok();
        true -> ret:error(no_pos)
    end.

can_del(Bucket = #bucket_interface{}, {GoodsID}) ->
    can_del(Bucket, {GoodsID, -1});
can_del(Bucket = #bucket_interface{}, {GoodsID, Num}) ->
    case goods_bucket:find_goods(Bucket, by_id, {GoodsID}) of
        {error, Error} -> {error, Error};
        Goods ->
            CurNum = Goods#item_new.quantity,
            if
                Num =< 0 ->
                    ret:ok();
                CurNum == Num ->
                    ret:ok();
                true ->
                    if
                        CurNum > Num -> ret:ok();
                        true -> ret:error(no_enough)
                    end
            end
    end.


add(Bucket = #bucket_interface{}, {Goods}) ->
    Bid = Goods#item_new.bid,
    case goods_bucket:isnt_buf_goods(Bid) of
        ok ->
            case goods_bucket:find_pos(Bucket, by_empty, {Goods}) of
                {error, Error} ->
                    {error, Error};
                Pos ->
                    event_eng:post(?ev_get_item, Bid),
                    GoodsList = goods_bucket:get_goods_sink_list(Bucket),
                    %?DEBUG_LOG("add  Pos-------:~p-----GoodsList-----:~p",[Pos, GoodsList]),
                    case lists:keyfind(Pos, #bucket_sink_interface.pos, GoodsList) of
                        #bucket_sink_interface{} ->
                            ret:error(has_item);
                        _ ->
                            BranchKey =
                                [
                                    #bucket_interface.goods_list,
                                    {#bucket_sink_interface.id, Goods#item_new.id, #bucket_sink_interface{}}
                                ],
                            NewSink = goods_bucket:new_bucket_sink(Goods#item_new.id, Goods#item_new.bid, Pos, Goods),
                            bucket_sync:push_add_sync(Bucket, Pos, Goods),
                            NewBucket = util:set_branch_val(Bucket, BranchKey, NewSink),
                            ret:data2(NewBucket, Goods)
                    end
            end;
        _ ->
            ret:data2(Bucket, Goods)
    end.



del(Bucket = #bucket_interface{}, {GoodsID}) ->
    del(Bucket, {GoodsID, -1});
del(Bucket = #bucket_interface{}, {GoodsID, Num}) ->
    case find(Bucket, {GoodsID}) of
        {error, Error} ->
            {error, Error};
        Goods ->
            CurNum = Goods#item_new.quantity,
            if
                Num =< 0 ->
                    BranchKey =
                        [
                            #bucket_interface.goods_list,
                            {#bucket_sink_interface.id, GoodsID, #bucket_sink_interface{}}
                        ],
                    NewBucket = util:set_branch_val(Bucket, BranchKey, nil),
                    bucket_sync:push_del_sync(Bucket, GoodsID),
                    ret:data2(NewBucket, Goods);
                CurNum == Num ->
                    BranchKey =
                        [
                            #bucket_interface.goods_list,
                            {#bucket_sink_interface.id, GoodsID, #bucket_sink_interface{}}
                        ],
                    NewBucket = util:set_branch_val(Bucket, BranchKey, nil),
                    bucket_sync:push_del_sync(Bucket, GoodsID),
                    ret:data2(NewBucket, Goods);
                true ->
                    if
                        CurNum > Num ->
                            NewGoodsNum = CurNum - Num,
                            NewGoods = Goods#item_new{quantity = NewGoodsNum},
                            bucket_sync:push_qty_sync(Bucket, GoodsID, NewGoodsNum),
                            NewBucket = goods_bucket:update(Bucket, NewGoods),
                            NewLeftGoods = Goods#item_new{id = attr_new:create_uid(), quantity = Num},
                            ret:data2(NewBucket, NewLeftGoods)
                    end
            end
    end.