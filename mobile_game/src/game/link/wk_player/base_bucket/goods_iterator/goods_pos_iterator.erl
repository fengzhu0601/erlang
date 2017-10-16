%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 13. 十二月 2015 下午8:02
%%%-------------------------------------------------------------------
-module(goods_pos_iterator).
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


find(Bucket = #bucket_interface{}, {Pos}) ->
    GoodsList = goods_bucket:get_goods_sink_list(Bucket),
    case lists:keyfind(Pos, #bucket_sink_interface.pos, GoodsList) of
        #bucket_sink_interface{goods = Goods} -> Goods;
        _ -> ret:error(no_item)
    end.

can_add(Bucket = #bucket_interface{}, {_Goods, Pos}) ->
    Size = goods_bucket:get_empty_size(Bucket),
    if
        Size > 0 ->
            GoodsList = goods_bucket:get_goods_sink_list(Bucket),
            case lists:keyfind(Pos, #bucket_sink_interface.pos, GoodsList) of
                #bucket_sink_interface{} -> ret:error(?bucket_error_has_item);
                _ -> ret:ok()
            end;
        true -> ret:error(no_pos)
    end.

can_del(Bucket = #bucket_interface{}, {Pos}) ->
    GoodsList = goods_bucket:get_goods_sink_list(Bucket),
    case lists:keyfind(Pos, #bucket_sink_interface.pos, GoodsList) of
        #bucket_sink_interface{} -> ret:ok();
        _ -> ret:error(no_enough)
    end.





add(Bucket = #bucket_interface{}, {Goods, Pos}) ->
    Bid = Goods#item_new.bid,
    case goods_bucket:isnt_buf_goods(Bid) of
        ok ->
            GoodsList = goods_bucket:get_goods_sink_list(Bucket),
            case lists:keyfind(Pos, #bucket_sink_interface.pos, GoodsList) of
                #bucket_sink_interface{} ->
                    ret:error(has_item);

                _ ->
                    event_eng:post(?ev_get_item, Bid),
                    BranchKey =
                        [
                            #bucket_interface.goods_list,
                            {#bucket_sink_interface.pos, Pos, #bucket_sink_interface{}}
                        ],
                    NewSink = goods_bucket:new_bucket_sink(Goods#item_new.id, Goods#item_new.bid, Pos, Goods),
                    bucket_sync:push_add_sync(Bucket, Pos, Goods),
                    NewBucket = util:set_branch_val(Bucket, BranchKey, NewSink),
                    ret:data2(NewBucket, Goods)
            end;
        _ ->
            ret:data2(Bucket, Goods)
    end.


del(Bucket = #bucket_interface{}, {Pos}) ->
    GoodsList = goods_bucket:get_goods_sink_list(Bucket),
    GoodsSink = lists:keyfind(Pos, #bucket_sink_interface.pos, GoodsList),
    case GoodsSink of
        #bucket_sink_interface{id = GoodsID, goods = Goods} ->
            BranchKey =
                [
                    #bucket_interface.goods_list,
                    {#bucket_sink_interface.pos, Pos, #bucket_sink_interface{}}
                ],
            NewBucket = util:set_branch_val(Bucket, BranchKey, nil),
            bucket_sync:push_del_sync(Bucket, GoodsID),
            ret:data2(NewBucket, Goods);
        _ ->
            ret:error(no_enough)
    end.