%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 18. 八月 2015 下午8:38
%%%-------------------------------------------------------------------
-module(goods_bucket).
-author("clark").

%% 数据结构
-export(
[
    new_bucket/5            %% 构建新背包数据
    , save/1                 %% 保存背包
]).

%% 字段项
-export(
[
    get_info/1                  %% 获得背包信息（前端用）
    , get_sink_info/2           %% 获得物品项信息（前端用）
    , get_goods/1               %% 获得物品项
    , get_type/1                %% 获得背包类型
    , get_use_type/1            %% 获得使用类型
    , set_field/3               %% 设置字段
    , set_fields/2              %% 设置字段
    , get_field/2               %% 获得字段
    , get_field/3               %% 获得字段
    , get_empty_size/1          %% 获得剩余空间
    , count_item_size/3         %% 统计物品总数量（0 无论绑定非绑定， 1只论绑定， 2只论非绑定）
]).

%% 物品项
-export(
[
    find_goods/3             %% 查找
    , find_pos/3             %% 查找
    , add/3                  %% 增加物品
    , del/3                  %% 减少物品
    , sort/1                 %% 整理
    , update/2               %% 更新物品属性
    , update/3               %% 更新物品属性
    , isnt_buf_goods/1       %% 是否BUF物品
    , can_add/3              %% 增加物品
    , can_del/3              %% 减少物品
    , get_goods_sink_list/1
    , new_bucket_sink/4
]).

%% 通讯项
-export(
[
    begin_sync/1             %% 开始同步
    , end_sync/1             %% 结束同步
]).




-include("inc.hrl").
-include("bucket_interface.hrl").
-include("item_bucket.hrl").
-include("load_item.hrl").
-include("player.hrl").
-include("load_phase_ac.hrl").


can_add(Bucket = #bucket_interface{}, Type, TPar)->
    case goods_iterator:can_add(Bucket, Type, TPar) of
        {error, Error} -> {error, Error};
        {1, L, M} ->
            {1, L, M};
        _ -> ret:ok()
    end.

can_del(Bucket = #bucket_interface{}, Type, TPar)->
    case goods_iterator:can_del(Bucket, Type, TPar) of
        {error, Error} -> {error, Error};
        _ -> ret:ok()
    end.


%% 创建槽
new_bucket(ID, SaveKey, TempKey, UserType, Size) ->
    #bucket_interface{id = ID,
        type = ?goods_bucket_type,
        save_key = SaveKey,
        temp_key = TempKey,
        user_type = UserType,
        field = [{?goods_bucket_size, Size}]
    }.

%% 保存
save(Bucket = #bucket_interface{}) ->
    Ret = attr_new:set(Bucket#bucket_interface.save_key, Bucket),
    %% 临时兼容老版本的装备，因为目前查看功能是拿这张表处理的。
    CurUseType = Bucket#bucket_interface.save_key,
    if
        CurUseType == ?pd_equip_bucket ->
            PlayerID = attr_new:get(?pd_id),
            NewDBRecord = player_data_db:new_bucket_db_record(PlayerID, Bucket),
            dbcache:update(?player_equip_tab, NewDBRecord);
        true ->
            ok
    end,
    Ret.

%% 获得使用类型
get_use_type(#bucket_interface{user_type = UserType}) -> UserType.

%% 设置字段
set_field(Bucket = #bucket_interface{field = FieldList}, Key, Val) ->
    NewList = lists:keystore(Key, 1, FieldList, {Key, Val}),
    setelement(#bucket_interface.field, Bucket, NewList).

%% 设置字段
set_fields(Bucket = #bucket_interface{}, []) -> Bucket;
set_fields(Bucket = #bucket_interface{}, [{Key, Val} | TailList]) ->
    NewBucket = set_field(Bucket, Key, Val),
    set_fields(NewBucket, TailList).

%% 获得字段
get_field(Bucket = #bucket_interface{}, Key) -> get_field(Bucket, Key, 0).
get_field(#bucket_interface{field = FieldList}, Key, Default) ->
    case lists:keyfind(Key, 1, FieldList) of
        {_Key, Val} -> Val;
        _ -> Default
    end.

%% 取空位
get_empty_size(Bucket = #bucket_interface{}) ->
    TotalSize = get_field(Bucket, ?goods_bucket_size, 0),
    Left = TotalSize - length(get_goods_sink_list(Bucket)),
    if
        Left > 0 -> Left;
        true -> 0
    end.

%% 获得物品槽列表
get_goods_sink_list(#bucket_interface{goods_list = GoodsList}) ->
    GoodsList.


%------------------------------------------------------------------------------------------------------dsl start
get_info(Bucket = #bucket_interface{}) ->
    Size = get_field(Bucket, ?goods_bucket_size, 0),
    GoodsList = get_goods_sink_list(Bucket),
    ItemS = do_get_info(GoodsList, 1, Size + 1, []),
    #bucket_info{
        bucketType = Bucket#bucket_interface.user_type,
        unlockSize = Size,
        uT = 0,
        items = ItemS
    }.
do_get_info(_GoodsList, _Max, _Max, List) ->
    List;
do_get_info(GoodsList, Min, Max, List) ->
    case lists:keyfind(Min, #bucket_sink_interface.pos, GoodsList) of
        #bucket_sink_interface{pos = Pos, goods = Goods} ->
            SinkInfo = get_sink_info(Goods, Pos),
            do_get_info(GoodsList, Min + 1, Max, [SinkInfo|List]);
        _ ->
            do_get_info(GoodsList, Min + 1, Max, List)
    end.


%% 获得背包信息(前端用)
% get_info(Bucket = #bucket_interface{}) ->
%     %% 获得背包项信息
%     GetItems =
%         fun
%             (_ThisFun, #bucket_interface{}, _M, _M) -> [];
%             (ThisFun, Bucket = #bucket_interface{}, I, M) ->
%                 GoodsList = get_goods_sink_list(Bucket),
%                 case lists:keyfind(I, #bucket_sink_interface.pos, GoodsList) of
%                     #bucket_sink_interface{pos = Pos, goods = Goods} ->
%                         SinkInfo = get_sink_info(Goods, Pos),
%                         [SinkInfo | ThisFun(ThisFun, Bucket, I + 1, M)];
%                     _ ->
%                         ThisFun(ThisFun, Bucket, I + 1, M)
%                 end
%         end,
%     Size = get_field(Bucket, ?goods_bucket_size, 0),
%     Items = GetItems(GetItems, Bucket, 1, Size + 1),
%     BucketInfo =
%         #bucket_info
%         {
%             bucketType = Bucket#bucket_interface.user_type,
%             unlockSize = Size,
%             uT = 0,
%             items = Items
%         },
%     BucketInfo.

get_goods(Bucket = #bucket_interface{}) ->
    GoodsList = get_goods_sink_list(Bucket),
    TotalSize = get_field(Bucket, ?goods_bucket_size, 0),
    do_get_goods(GoodsList, 1, TotalSize + 1, []).

do_get_goods(_GoodsList, _Max, _Max, List) ->
    List;
do_get_goods(GoodsList, Min, Max, List) ->
    case lists:keyfind(Min, #bucket_sink_interface.pos, GoodsList) of
        #bucket_sink_interface{goods = Goods} ->
            do_get_goods(GoodsList, Min + 1, Max, [Goods|List]);
        _ ->
            do_get_goods(GoodsList, Min + 1, Max, List)
    end.


% get_goods(Bucket = #bucket_interface{}) ->
%     DoGetGoods =
%         fun
%             (_ThisFun, _GoodsSinkList, M, M) -> [];
%             (ThisFun, GoodsSinkList, I, M) ->
%                 case lists:keyfind(I, #bucket_sink_interface.pos, GoodsSinkList) of
%                     #bucket_sink_interface{goods = Goods} ->
%                         [Goods | ThisFun(ThisFun, GoodsSinkList, I + 1, M)];
%                     _ ->
%                         ThisFun(ThisFun, GoodsSinkList, I + 1, M)
%                 end
%         end,
%     GoodsList = get_goods_sink_list(Bucket),
%     TotalSize = get_field(Bucket, ?goods_bucket_size, 0),
%     DoGetGoods(DoGetGoods, GoodsList, 1, TotalSize + 1).

%----------------------------------------------------------------------------------------------------dsl end

%% 背包槽信息
get_sink_info(Item = #item_new{}, Pos) ->
    MainType = item_new:get_main_type(Item),
    case MainType of
        ?val_item_main_type_goods -> item_goods:get_sink_info(Item, Pos);
        ?val_item_main_type_equip -> item_equip:get_sink_info(Item, Pos);
        _ -> ret:system_error(unknown_type, {goods_bucket, get_sink_info})
    end.

%% 获得类型
get_type(#bucket_interface{type = BucketType}) -> BucketType.


%% -----------------------------------------------------------------------------------------------------------dsl start
count_item_size(Bucket = #bucket_interface{}, CountType, Bid) ->
    GoodsList = get_goods_sink_list(Bucket),
    do_count_item_size(GoodsList, CountType, Bid, 0).
do_count_item_size([], _CountType, _Bid, Total) ->
    Total;
do_count_item_size([Sink|T], CountType, Bid, Total) ->
    Num = 
    case Sink of
        #bucket_sink_interface{goods = Goods} ->
            CurBid = Goods#item_new.bid,
            if
                CurBid == Bid ->
                    CurBind = Goods#item_new.bind,
                    if
                        CountType == 0 -> 
                            Goods#item_new.quantity;
                        CountType == 1 andalso CurBind == 1 -> 
                            Goods#item_new.quantity;
                        CountType == 2 andalso CurBind == 0 -> 
                            Goods#item_new.quantity;
                        true -> 
                            0
                    end;
                true -> 
                    0
            end;
        _ -> 
            0
    end,
    do_count_item_size(T, CountType, Bid, Num + Total).

%% 统计物品总数量（0 无论绑定非绑定， 1只论绑定， 2只论非绑定）
% count_item_size(Bucket = #bucket_interface{}, CountType, Bid) ->
%     CountItem =
%         fun
%             (_ThisFun, [], _CountType, _Bid) -> 0;
%             (ThisFun, [Sink | GoodsList], CountType, Bid) ->
%                 case Sink of
%                     #bucket_sink_interface{goods = Goods} ->
%                         CurBid = Goods#item_new.bid,
%                         Num =
%                             if
%                                 CurBid == Bid ->
%                                     CurBind = Goods#item_new.bind,
%                                     if
%                                         CountType == 0 -> Goods#item_new.quantity;
%                                         CountType == 1 andalso CurBind == 1 -> Goods#item_new.quantity;
%                                         CountType == 2 andalso CurBind == 0 -> Goods#item_new.quantity;
%                                         true -> 0
%                                     end;
%                                 true -> 0
%                             end,
%                         Num + ThisFun(ThisFun, GoodsList, CountType, Bid);
%                     _ -> 0
%                 end
%         end,
%     GoodsList = get_goods_sink_list(Bucket),
%     CountItem(CountItem, GoodsList, CountType, Bid).
%% -----------------------------------------------------------------------------------------------------------dsl end


%% 创建槽
new_bucket_sink(ID, BidID, Pos, Goods) ->
    NewGoods = Goods#item_new{pos = Pos},
    #bucket_sink_interface{pos = Pos, id = ID, bid = BidID, goods = NewGoods}.


%% 整理
sort(Bucket = #bucket_interface{}) ->
    TempBucket = Bucket#bucket_interface{goods_list = []},
    AddGoodsEx =
        fun
            (_ThisFun, FunBucket, [], DelList) -> ret:data2(FunBucket, DelList);
            (ThisFun, FunBucket, [#bucket_sink_interface{goods = Goods} | TailList], DelList) ->
                NewDelList = [Goods#item_new.id | DelList],
                NewFunBucket =
                    case can_add(FunBucket, any_by_bid, {Goods#item_new.bid, Goods#item_new.bind, Goods#item_new.quantity}) of
                        {error, {left_num, {CanAddNum, LeftNum}}} when CanAddNum =/= 0 ->
                            {TempFunBucket1, _} = add(FunBucket, any_by_bid, {Goods#item_new.bid, Goods#item_new.bind, CanAddNum}),
                            NewGoods = Goods#item_new{quantity = LeftNum},
                            {TempFunBucket2, _} = add(TempFunBucket1, item_by_id, {NewGoods}),
                            TempFunBucket2;
                        {error, _E} ->
                            {TempFunBucket1, _} = add(FunBucket, item_by_id, {Goods}),
                            TempFunBucket1;
                        {1, CanAddNum, 0} ->
                            {TempFunBucket1, _} = add(FunBucket, any_by_bid, {Goods#item_new.bid, Goods#item_new.bind, CanAddNum}),
                            TempFunBucket1;
                        {1, CanAddNum, LeftNum} ->
                            {TempFunBucket1, _} = add(FunBucket, any_by_bid, {Goods#item_new.bid, Goods#item_new.bind, CanAddNum}),
                            NewGoods = Goods#item_new{quantity = LeftNum},
                            {TempFunBucket2, _} = add(TempFunBucket1, item_by_id, {NewGoods}),
                            TempFunBucket2;
                        _A ->
                            {TempFunBucket1, _} = add(FunBucket, any_by_bid, {Goods#item_new.bid, Goods#item_new.bind, Goods#item_new.quantity}),
                            TempFunBucket1
                    end,
                ThisFun(ThisFun, NewFunBucket, TailList, NewDelList)
        end,
    GetAddList =
        fun
            (_ThisFun, [], AddList) -> AddList;
            (ThisFun, [#bucket_sink_interface{goods = Goods, pos = Pos} | TailList], AddList) ->
                NewAddList = [get_sink_info(Goods, Pos) | AddList],
                ThisFun(ThisFun, TailList, NewAddList)
        end,

    GoodsList = get_goods_sink_list(Bucket),
    NewGoodsList11 = item_sort(GoodsList),
%    NewGoodsList11 = lists:reverse(GoodsList),    %% 放进背包时是压栈放进的
    {NewBucket, DelList} = AddGoodsEx(AddGoodsEx, TempBucket, NewGoodsList11, []),
    NewGoodsList = get_goods_sink_list(NewBucket),
    AddList = GetAddList(GetAddList, NewGoodsList, []),
    Key = Bucket#bucket_interface.temp_key,
    NewSyncTemp = #bucket_sync_tmp{begin_count = 1},
    NewSyncTemp1 = setelement(#bucket_sync_tmp.del_list, NewSyncTemp, []),
    client_need_global_remove:init_del_sync(DelList),
    NewSyncTemp2 = setelement(#bucket_sync_tmp.add_list, NewSyncTemp1, AddList),
    attr_new:set(Key, NewSyncTemp2),

    NewBucket.

%% 寻找位
find_pos(Bucket = #bucket_interface{}, by_id, {GoodsID}) ->
    GoodsList = get_goods_sink_list(Bucket),
    case lists:keyfind(GoodsID, #bucket_sink_interface.id, GoodsList) of
        #bucket_sink_interface{pos = Pos} -> Pos;
        _ -> ret:error(no_empty)
    end;
%% 寻找背包里的空位
find_pos(Bucket = #bucket_interface{}, by_empty, _Par) ->
    FindEmpty =
        fun
            (_ThisFun, _GoodsList, _Max, _Max) -> ret:error(no_empty);
            (ThisFun, GoodsList, I, M) ->
                case lists:keyfind(I, #bucket_sink_interface.pos, GoodsList) of
                    #bucket_sink_interface{} -> ThisFun(ThisFun, GoodsList, I + 1, M);
                    _ -> I
                end
        end,
    GoodsList = get_goods_sink_list(Bucket),
    Size = get_field(Bucket, ?goods_bucket_size, 0),
    FindEmpty(FindEmpty, GoodsList, 1, Size + 1);
find_pos(_Bucket, _Key, _Val) ->
    ret:error(failed_in_find_pos).

begin_sync(Bucket = #bucket_interface{}) ->
    bucket_sync:begin_sync(Bucket).

end_sync(Bucket = #bucket_interface{}) ->
    bucket_sync:end_sync(Bucket).

isnt_buf_goods(Bid) ->
    case load_item:get_type(Bid) of
        ?val_item_type_room_buf -> ret:error(cant);
        _ -> ret:ok()
    end.

%% 更新物品属性
update(Bucket = #bucket_interface{}, Goods = #item_new{}) ->
    update(Bucket,Goods, true).
update(Bucket = #bucket_interface{}, Goods = #item_new{}, IsSync) ->
    GoodsID = Goods#item_new.id,
    GoodsList = get_goods_sink_list(Bucket),
    case lists:keyfind(GoodsID, #bucket_sink_interface.id, GoodsList) of
        #bucket_sink_interface{pos = Pos} ->
            NewSink = new_bucket_sink(Goods#item_new.id, Goods#item_new.bid, Pos, Goods),
            NewList = lists:keyreplace(GoodsID, #bucket_sink_interface.id, GoodsList, NewSink),
            if
                IsSync ->
                    bucket_sync:push_up_sync(Bucket, Pos, Goods);
                true ->
                    ok
            end,
            Bucket#bucket_interface{goods_list = NewList};
        _ ->
            ret:system_error(?bucket_error_no_item, {goods_bucket, update})
    end.



%% -------------------------------------------------------------------------------------
%% 查找
find_goods(Bucket = #bucket_interface{}, Type, Par) ->
    goods_iterator:find(Bucket, Type, Par).

%% 增加物品
add(Bucket = #bucket_interface{}, Type, TPar) ->
    goods_iterator:add(Bucket, Type, TPar).

%% 减少物品
del(Bucket = #bucket_interface{}, Type, TPar) ->
    goods_iterator:del(Bucket, Type, TPar).

%% 物品排序
item_sort(GoodsList) ->
    TypeSortList = misc_cfg:get_misc_cfg(item_type_index),
    TypeLength = length(TypeSortList),
    TempTypeSortList = lists:zip(TypeSortList, lists:duplicate(TypeLength, [])),
    %% 先按类型排序
    GoodsTypeSortList = lists:foldl(
        fun(Goods, TempList) ->
            GoodsType = load_item:get_type(Goods#bucket_sink_interface.bid),
            case lists:keyfind(GoodsType, 1, TempList) of
                false ->
                    TempList ++ [{GoodsType, [Goods]}];
                {GoodsType, List} ->
                    lists:keyreplace(GoodsType, 1, TempList, {GoodsType, List ++ [Goods]})
            end
        end,
        TempTypeSortList,
        GoodsList
    ),
    %% 先按使用等级排序，再按品质排序
    CreateFun = fun(Goods, TempList) ->
        UseLev = load_item:get_use_lev(Goods#bucket_sink_interface.bid),
        Quality = load_item:get_item_quality(Goods#bucket_sink_interface.bid),
        TempList ++ [{{UseLev, Quality}, Goods}]
    end,
    TwoKeySortFun = fun({{A1, B1}, _}, {{A2, B2}, _}) ->
        case A1 > A2 of
            true ->
                true;
            _ ->
                case A1 =:= A2 of
                    true ->
                        B1 >= B2;
                    _ ->
                        false
                end
        end
    end,
    GoodsLevSortList = 
    [
        {Type, lists:sort(TwoKeySortFun, lists:foldl(CreateFun, [], TypeList))}
        || {Type, TypeList} <- GoodsTypeSortList, TypeList =/= []
    ],
    LevQuaSortFun = fun({Key, Goods}, TempList) ->
        case lists:keyfind(Key, 1, TempList) of
            false ->
                TempList ++ [{Key, [Goods]}];
            {Key, List} ->
                lists:keyreplace(Key, 1, TempList, {Key, List ++ [Goods]})
        end
    end,
    NewGoodsList = [{Type, lists:foldl(LevQuaSortFun, [], TypeList)} || {Type, TypeList} <- GoodsLevSortList],
    %% 装备按评分高到低排序，宝石按属性type由小到大排序（暂时忽略），特殊物品和礼包按Bid由小到大
    %% 评分或Bid相同，非绑定优先于绑定
    FinalList = lists:foldl(
        fun({ItemType, GoodsLevQuaSortList}, TempList) ->
            case ItemType of
                ?val_item_type_gem ->
                    TempList ++ [lists:reverse(List) || {{_UseLv, _Qua}, List} <- GoodsLevQuaSortList];
                ?val_item_type_use ->
                    NewList = 
                    [
                        [
                            {
                                {
                                    Goods#bucket_sink_interface.bid,
                                    (Goods#bucket_sink_interface.goods)#item_new.bind
                                },
                                Goods
                            } || Goods <- List
                        ] || {{_UseLv, _Qua}, List} <- GoodsLevQuaSortList
                    ],
                    NewList1 = lists:reverse(lists:sort(TwoKeySortFun, lists:flatten(NewList))),
                    TempList ++ [X || {{_Bid, _IsBind}, X} <- NewList1];
                ?val_item_main_type_slot ->
                    NewList =
                        [
                            [
                                {
                                    {
                                        Goods#bucket_sink_interface.bid,
                                        (Goods#bucket_sink_interface.goods)#item_new.bind
                                    },
                                    Goods
                                } || Goods <- List
                            ] || {{_UseLv, _Qua}, List} <- GoodsLevQuaSortList
                        ],
                    NewList1 = lists:reverse(lists:sort(TwoKeySortFun, lists:flatten(NewList))),
                    TempList ++ [X || {{_Bid, _IsBind}, X} <- NewList1];
                ?val_item_type_fumo_scroll_debris ->
                    NewList =
                        [
                            [
                                {
                                    {
                                        Goods#bucket_sink_interface.bid,
                                        (Goods#bucket_sink_interface.goods)#item_new.bind
                                    },
                                    Goods
                                } || Goods <- List
                            ] || {{_UseLv, _Qua}, List} <- GoodsLevQuaSortList
                        ],
                    NewList1 = lists:reverse(lists:sort(TwoKeySortFun, lists:flatten(NewList))),
                    TempList ++ [X || {{_Bid, _IsBind}, X} <- NewList1];
                ?val_item_type_fumo_scroll ->
                    NewList =
                        [
                            [
                                {
                                    {
                                        Goods#bucket_sink_interface.bid,
                                        (Goods#bucket_sink_interface.goods)#item_new.bind
                                    },
                                    Goods
                                } || Goods <- List
                            ] || {{_UseLv, _Qua}, List} <- GoodsLevQuaSortList
                        ],
                    NewList1 = lists:reverse(lists:sort(TwoKeySortFun, lists:flatten(NewList))),
                    TempList ++ [X || {{_Bid, _IsBind}, X} <- NewList1];
                ?val_item_type_fumo_stone ->
                    NewList =
                        [
                            [
                                {
                                    {
                                        Goods#bucket_sink_interface.bid,
                                        (Goods#bucket_sink_interface.goods)#item_new.bind
                                    },
                                    Goods
                                } || Goods <- List
                            ] || {{_UseLv, _Qua}, List} <- GoodsLevQuaSortList
                        ],
                    NewList1 = lists:reverse(lists:sort(TwoKeySortFun, lists:flatten(NewList))),
                    TempList ++ [X || {{_Bid, _IsBind}, X} <- NewList1];
                ?val_item_type_suit_chip ->
                    NewList =
                        [
                            [
                                {
                                    {
                                        Goods#bucket_sink_interface.bid,
                                        (Goods#bucket_sink_interface.goods)#item_new.bind
                                    },
                                    Goods
                                } || Goods <- List
                            ] || {{_UseLv, _Qua}, List} <- GoodsLevQuaSortList
                        ],
                    NewList1 = lists:reverse(lists:sort(TwoKeySortFun, lists:flatten(NewList))),
                    TempList ++ [X || {{_Bid, _IsBind}, X} <- NewList1];
                ?val_item_type_gift ->
                    NewList = 
                    [
                        [
                            {
                                {
                                    Goods#bucket_sink_interface.bid,
                                    (Goods#bucket_sink_interface.goods)#item_new.bind
                                },
                                Goods
                            } || Goods <- List
                        ] || {{_UseLv, _Qua}, List} <- GoodsLevQuaSortList
                    ],
                    NewList1 = lists:reverse(lists:sort(TwoKeySortFun, lists:flatten(NewList))),
                    TempList ++ [X || {{_Bid, _IsBind}, X} <- NewList1];
                _ ->
                    NewList = lists:flatten([List || {{_UseLv, _Qua}, List} <- GoodsLevQuaSortList]),
                    NewList1 = lists:foldl(
                        fun(Goods, TempList1) ->
                            case load_item:get_main_type(Goods#bucket_sink_interface.bid) of
                                ?val_item_main_type_equip ->
                                    Power = lists:keyfind(?item_equip_power, 1, (Goods#bucket_sink_interface.goods)#item_new.field),
                                    Key2 = case (Goods#bucket_sink_interface.goods)#item_new.bind of
                                        0 ->
                                            1;
                                        _ ->
                                            0
                                    end,
                                    TempList1 ++ [{{Power, Key2}, Goods}];
                                _ ->
                                    Key1 = (Goods#bucket_sink_interface.goods)#item_new.bid,
                                    TempList1 ++ [{{Key1, 0}, Goods}]
                            end
                        end,
                        [],
                        NewList
                    ),
                    NewList2 = lists:sort(TwoKeySortFun, NewList1),
                    TempList ++ [X || {{_Bid, _IsBind}, X} <- NewList2]
            end
        end,
        [],
        NewGoodsList
    ),
    lists:flatten(FinalList).
