%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 10. 十二月 2015 下午6:20
%%%-------------------------------------------------------------------
-module(goods_bid_iterator).
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





find(Bucket = #bucket_interface{}, {Bid}) ->
    GoodsList = goods_bucket:get_goods_sink_list(Bucket),
    case lists:keyfind(Bid, #bucket_sink_interface.bid, GoodsList) of
        #bucket_sink_interface{goods = Goods} -> Goods;
        _ -> ret:error(no_item)
    end.

can_add(Bucket = #bucket_interface{}, {Bid, Num}) ->
    case load_item:get_item_cfg(Bid) of
        {error, Error} ->
            {error, Error};
        #item_attr_cfg{cant_sell = CfgBind} ->
            can_add(Bucket, {Bid, CfgBind, Num});
        _ ->
            ret:error(cant_add)
    end;

can_add(Bucket = #bucket_interface{}, {Bid, Bind, Num}) ->
    %?DEBUG_LOG("CAN ADD Bid-------:~p-----Num--------:~p",[Bid, Num]),
    CanAddByBidNum =
        fun
            (_ThisFun, [], {_, CanAddNum, NeedNum}) ->
                ret:error(left_num, {CanAddNum, NeedNum});
            (ThisFun, [Sink | TailList], {{Bid, IsBind, Max}, CanAddNum, NeedNum}) ->
                case Sink of
                    #bucket_sink_interface{goods = Goods} ->
                        CurBid = Goods#item_new.bid,
                        CurBind = Goods#item_new.bind,
                        CurNum = Goods#item_new.quantity,
                        if
                            CurBid == Bid andalso CurBind == IsBind ->
                                Sum = CurNum + NeedNum,
                                if
                                    NeedNum =:= Max -> %% 直接创建一个背包格子
                                        ret:error(direct_build);
                                    CurNum =:= Max ->%% 检查下一个格子
                                        ThisFun(ThisFun, TailList, {{Bid, IsBind, Max}, CanAddNum, NeedNum});
                                    Sum =< Max ->
                                        {1, NeedNum, 0};
                                    true ->
                                        %Left = Sum - Max,
                                        WaitA = Max - CurNum,
                                        {1, WaitA, NeedNum - WaitA}
                                        %ThisFun(ThisFun, TailList, {{Bid, IsBind, Max}, WaitA, NeedNum - WaitA})
                                end;
                            true ->
                                ThisFun(ThisFun, TailList, {{Bid, IsBind, Max}, CanAddNum, NeedNum})
                        end;
                    _ ->
                        ret:error(unknown_type)
                end
        end,
    GoodsList = goods_bucket:get_goods_sink_list(Bucket),
    % ?DEBUG_LOG("CAN ADD GoodsList-------------------------:~p",[GoodsList]),
    case load_item:get_item_cfg(Bid) of
        {error, Error} ->
            {error, Error};
        #item_attr_cfg{overlap = Max} ->
            CanAddByBidNum(CanAddByBidNum, GoodsList, {{Bid, Bind, Max}, 0, Num});
        _ ->
            ret:error(no_enough)
    end.




can_del(Bucket = #bucket_interface{}, {Bid, Num}) ->
    GoodsList = goods_bucket:get_goods_sink_list(Bucket),
    TotalNum =
        lists:foldl(
            fun(#bucket_sink_interface{goods = Goods}, Sum) ->
                case Goods of
                    #item_new{} ->
                        CurBid = Goods#item_new.bid,
                        CurNum = Goods#item_new.quantity,
                        if
                            Bid == CurBid -> (CurNum + Sum);
                            true -> Sum
                        end;
                    _ ->
                        Sum
                end
            end,
            0,
            GoodsList),
    if
        TotalNum >= Num -> ret:ok();
        true -> ret:error(no_enough)
    end.


%---------------------------------------------------------------------------------------------------------------------dsl start
add(Bucket = #bucket_interface{}, {Bid, Num}) ->
    case load_item:get_item_cfg(Bid) of
        {error, Error} ->
            {error, Error};
        #item_attr_cfg{cant_sell = CfgBind} ->
            add(Bucket, {Bid, CfgBind, Num});
        _ ->
            ret:error(cant_add)
    end;
add(Bucket = #bucket_interface{}, {Bid, Bind, Num}) ->
    AddByBidNum =
        fun
            (_ThisFun, _FunBucket, [], {_, NeedNum}) ->
                ret:error(left_num, NeedNum);
            (ThisFun, FunBucket, [Sink | TailList], {{Bid, IsBind, Max}, NeedNum}) ->
                case Sink of
                    #bucket_sink_interface{goods = Goods} ->
                        event_eng:post(?ev_get_item, Bid),
                        CurBid = Goods#item_new.bid,
                        CurBind = Goods#item_new.bind,
                        if
                            CurBid == Bid andalso CurBind == IsBind ->
                                CurNum = Goods#item_new.quantity,
                                Sum = CurNum + NeedNum,
                                if
                                    Sum =< Max ->
                                        NewGoods = Goods#item_new{quantity = Sum},
                                        NewFunBucket = goods_bucket:update(FunBucket, NewGoods),
                                        ret:data2(NewFunBucket, NewGoods);
                                    true ->
                                        Left = Sum - Max,
                                        %NewGoods = Goods#item_new{quantity = Max},
                                        %NewFunBucket = goods_bucket:update(FunBucket, NewGoods),
                                        ThisFun(ThisFun, FunBucket, TailList, {{Bid, IsBind, Max}, Left})
                                end;
                            true ->
                                ThisFun(ThisFun, FunBucket, TailList, {{Bid, IsBind, Max}, NeedNum})
                        end;
                    _ -> 
                        ret:error(no_enough)
                end
        end,
    GoodsList = goods_bucket:get_goods_sink_list(Bucket),
    case load_item:get_item_cfg(Bid) of
        {error, Error} ->
            {error, Error};
        #item_attr_cfg{overlap = Max} ->
            AddByBidNum(AddByBidNum, Bucket, GoodsList, {{Bid, Bind, Max}, Num});
        _ ->
            ret:error(cant_add)
    end.
%---------------------------------------------------------------------------------------------------------------------dsl end


del(Bucket = #bucket_interface{}, {Bid, Num}) ->
    DelBid =
        fun
            (_ThisFun, _FunBucket, [], {_, _NeedNum}) ->
                ret:error(no_enough);
            (ThisFun, FunBucket, [#bucket_sink_interface{goods = Goods} | TailList], {Bid, NeedNum}) ->
                if
                    NeedNum > 0 ->
                        GoodsID = Goods#item_new.id,
                        CurBid = Goods#item_new.bid,
                        CurNum = Goods#item_new.quantity,
                        if
                            Bid == CurBid ->
                                if
                                    CurNum > NeedNum ->
                                        NewGoodsNum = CurNum - NeedNum,
                                        NewGoods = Goods#item_new{quantity = NewGoodsNum},
                                        bucket_sync:push_qty_sync(Bucket, GoodsID, NewGoodsNum),
                                        NewFunBucket = goods_bucket:update(FunBucket, NewGoods),
                                        NewLeftGoods = Goods#item_new{id = attr_new:create_uid(), quantity = NeedNum},
                                        ret:data2(NewFunBucket, NewLeftGoods);
                                    true ->
                                        BranchKey =
                                            [
                                                #bucket_interface.goods_list,
                                                {#bucket_sink_interface.id, GoodsID, #bucket_sink_interface{}}
                                            ],
                                        NewFunBucket = util:set_branch_val(FunBucket, BranchKey, nil),
                                        bucket_sync:push_del_sync(NewFunBucket, GoodsID),
                                        if
                                            CurNum == NeedNum ->
                                                ret:data2(NewFunBucket, Goods);
                                            true ->
                                                %% 只返回最后一个（中途其它扣的不算）
                                                ThisFun(ThisFun, NewFunBucket, TailList, {Bid, NeedNum-CurNum})
                                        end
                                end;
                            true ->
                                ThisFun(ThisFun, FunBucket, TailList, {Bid, NeedNum})
                        end
                end
        end,
    GoodsList = goods_bucket:get_goods_sink_list(Bucket),
    DelBid(DelBid, Bucket, GoodsList, {Bid, Num}).
