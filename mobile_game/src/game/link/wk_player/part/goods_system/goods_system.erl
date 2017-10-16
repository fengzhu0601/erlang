%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 27. 七月 2015 下午8:59
%%%-------------------------------------------------------------------
-module(goods_system).
-author("clark").


%% API
-export(
[
    get_bucket_info/1
    , restore_goods_system/0
    , bucket_sort/1
    , try_move_goods/3
    , try_bucket_split/3
    , try_move_goods_in_buckets/4
    , try_bucket_unlock/2
    , try_bucket_merge/3
    , try_goods_use/2
    , try_gift_goods_use/2
    , try_unbind_goods/1
    , sync_shapeshift_data/0
    , compound_goods/2
]).


-include("inc.hrl").
-include("bucket_interface.hrl").
-include("player.hrl").
-include("item_bucket.hrl").
-include("load_item.hrl").
-include("achievement.hrl").
-include("item.hrl").
-include("system_log.hrl").
-include("load_phase_ac.hrl").
-include("../wonderful_activity/bounty_struct.hrl").
-include("../../../wk_open_server_happy/open_server_happy.hrl").

sync_shapeshift_data() ->
    %% 同步自已和其他玩家客户端的卡牌变身效果
    IsInitCliendCompleted = attr_new:get(?pd_init_cliend_completed),
    case IsInitCliendCompleted of
        1 ->
            %%得到自己的卡牌变身数据
            CardId = attr_new:get(?pd_shapeshift_data, 0),
            case CardId of
                0 ->
                    ok;
                %%有变身卡牌效果
                CardId ->
                    shapeshift_mng:try_restore_shapeshift()
            end;
        0 ->
            ok
    end,
    ok.

restore_goods_system() ->
    BagBucket = game_res:get_bucket(?BUCKET_TYPE_BAG),
    time_bucket:restore_bucket(BagBucket),
    DepotBucket = game_res:get_bucket(?BUCKET_TYPE_DEPOT),
    time_bucket:restore_bucket(DepotBucket).




get_bucket_info(BucketType) ->
%%     ?INFO_LOG("get_bucket_info"),
    case game_res:get_bucket(BucketType) of
        {error, Error} -> {error, Error};
        Bucket -> goods_bucket:get_info(Bucket)
    end.

try_move_goods(BucketType, GoodsID, ToPos) ->
%%     ?INFO_LOG("try_move_goods"),
    case game_res:get_bucket(BucketType) of
        {error, Error} -> {error, Error};
        Bucket ->
            Size = goods_bucket:get_field(Bucket, ?goods_bucket_size, 0),
            if
                Size < ToPos -> {error, unknown_type};
                true ->
                    case goods_bucket:find_goods(Bucket, by_id, {GoodsID}) of
                        {error, Error} -> {error, Error};
                        _ ->
                            case goods_bucket:find_goods(Bucket, by_pos, {ToPos}) of
                                {error, _} ->
                                    goods_bucket:begin_sync(Bucket),
                                    {NewBucket, NewGoods} = goods_bucket:del(Bucket, item_by_id, {GoodsID}),
                                    {NewPushBucket, _} = goods_bucket:add(NewBucket, item_by_pos, {NewGoods, ToPos}),
                                    goods_bucket:end_sync(NewPushBucket),
                                    ok;
                                _Goods ->
                                    goods_bucket:begin_sync(Bucket),
                                    {NewBucket, NewGoods1} = goods_bucket:del(Bucket, item_by_pos, {ToPos}),
                                    {NewBucket1, NewGoods2} = goods_bucket:del(NewBucket, item_by_id, {GoodsID}),
                                    {NewPushBucket2, _} = goods_bucket:add(NewBucket1, item_by_pos, {NewGoods2, ToPos}),
                                    {NewPushBucket3, _} = goods_bucket:add(NewPushBucket2, item_by_pos, {NewGoods1, NewGoods2#item_new.pos}),
                                    goods_bucket:end_sync(NewPushBucket3),
                                    ok
                            end
                    end
            end
    end.

try_bucket_split(BucketType, GoodsID, GoodsNum) ->
%%     ?INFO_LOG("try_bucket_split"),
    case game_res:get_bucket(BucketType) of
        {error, Error} -> {error, Error};
        Bucket ->
            Size = goods_bucket:get_empty_size(Bucket),
            if
                Size > 0 ->
                    case goods_bucket:can_del(Bucket, item_by_id, {GoodsID, GoodsNum}) of
                        {error, Error} -> {error, Error};
                        _ ->
                            goods_bucket:begin_sync(Bucket),
                            {NewBucket, NewGoods} = goods_bucket:del(Bucket, item_by_id, {GoodsID, GoodsNum}),
                            {NewBucket1, _NewGoods1} = goods_bucket:add(NewBucket, item_by_id, {NewGoods}),
                            goods_bucket:end_sync(NewBucket1),

                            ok
                    end;
                true ->
                    ret:error(unknown_type)
            end
    end.

try_bucket_merge(BucketType, SItemId, DItemId) ->
%%     ?INFO_LOG("try_bucket_merge ~p", [{SItemId, DItemId}]),
    case game_res:get_bucket(BucketType) of
        {error, Error} -> {error, Error};
        Bucket ->
            case goods_bucket:find_goods(Bucket, by_id, {SItemId}) of
                {error, Error} -> {error, Error};
                FromGoods ->
                    case goods_bucket:find_goods(Bucket, by_id, {DItemId}) of
                        {error, Error} -> {error, Error};
                        ToGoods ->
                            case item_new:can_overlap(FromGoods, ToGoods) of
                                {error, _Error} ->
                                    Sum1 = load_item:get_overlap(FromGoods#item_new.bid),
                                    Sum2 = FromGoods#item_new.quantity + ToGoods#item_new.quantity - Sum1,
                                    NewToGoods = ToGoods#item_new{quantity = Sum1},
                                    NewFromGoods = FromGoods#item_new{quantity = Sum2},
                                    goods_bucket:begin_sync(Bucket),
                                    NewBucket1 = goods_bucket:update(Bucket, NewToGoods),
                                    NewBucket2 = goods_bucket:update(NewBucket1, NewFromGoods),
                                    goods_bucket:end_sync(NewBucket2),
                                    ok;
                                ok ->
                                    Sum = FromGoods#item_new.quantity + ToGoods#item_new.quantity,
                                    NewToGoods = ToGoods#item_new{quantity = Sum},

                                    goods_bucket:begin_sync(Bucket),
                                    {NewBucket, _} = goods_bucket:del(Bucket, item_by_id, {FromGoods#item_new.id}),
                                    NewBucket1 = goods_bucket:update(NewBucket, NewToGoods),
                                    goods_bucket:end_sync(NewBucket1),

                                    ok;
                                _ -> {error, unknown_type}
                            end
                    end
            end
    end.


try_bucket_unlock(BucketType, ?UNLOCK_TYPE_DIAMOND) ->
%%     ?INFO_LOG("try_bucket_unlock"),
    Bucket =
        case BucketType of
            ?BUCKET_TYPE_BAG -> attr_new:get(?pd_goods_bucket);
            ?BUCKET_TYPE_DEPOT -> attr_new:get(?pd_depot_bucket);
            _ -> {error, unknown_type}
        end,
    case Bucket of
        {error, Error} -> {error, Error};
        _ ->
            case time_bucket:can_add_page(Bucket) of
                ok ->
                    CfgID = time_bucket:get_cfg_id(Bucket),
                    Diamond =
                        case BucketType of
                            ?BUCKET_TYPE_BAG -> load_unlock:get_bag_dimand_cost(CfgID);
                            ?BUCKET_TYPE_DEPOT -> load_unlock:get_depot_dimand_cost(CfgID)
                        end,
                    case game_res:can_del([{by_bid, {?DIAMOND_BID, Diamond}}]) of
                        ok ->
                            game_res:del([{?DIAMOND_BID, Diamond}], ?FLOW_REASON_BUCKET_UNLOCK),
                            goods_bucket:begin_sync(Bucket),
                            NewBucket = time_bucket:add_page(Bucket),
                            goods_bucket:end_sync(NewBucket),
                            if
                                BucketType =:= 1 ->
                                    achievement_mng:do_ac2(?beibaodaren, 0, 1);
                                BucketType =:= 2 ->
                                    achievement_mng:do_ac2(?cangkudaren, 0, 1)
                            end,
                            ret:ok(0);
                        _ ->
                            {false, unknown_type}
                    end;
                {error, Error} -> {error, Error};
                _ -> {error, unknown_type}
            end
    end;

try_bucket_unlock(BucketType, ?UNLOCK_TYPE_TIME) ->
%%     ?INFO_LOG("try_bucket_unlock"),
    Bucket =
        case BucketType of
            ?BUCKET_TYPE_BAG -> attr_new:get(?pd_goods_bucket);
            ?BUCKET_TYPE_DEPOT -> attr_new:get(?pd_depot_bucket);
            _ -> {error, unknown_type}
        end,
    case Bucket of
        {error, Error} -> {error, Error};
        _ ->
            case time_bucket:can_start_add_page_timer(Bucket) of
                ok ->
                    NeedTime = time_bucket:start_add_page_timer(Bucket),
                    phase_achievement_mng:do_pc(?PHASE_AC_BEIBAO_STAR, 10003, api:get_bag_page_count()),
                    case BucketType of
                        ?BUCKET_TYPE_BAG ->
                            open_server_happy_mng:sync_task(?BAG_GRID_OPEN_COUNT, api:get_bag_grid_num());
                        ?BUCKET_TYPE_DEPOT ->
                            open_server_happy_mng:sync_task(?DEPOT_GRID_OPEN_COUNT, api:get_depot_grid_num());
                        _ ->
                            pass
                    end,
                    ret:ok(NeedTime);
                {error, Error1} -> {error, Error1}
            end
    end.

try_goods_use(ItemId, Num) ->
%%     ?INFO_LOG("try_goods_use"),
    case game_res:get_bucket(?BUCKET_TYPE_BAG) of  %%获取背包物品
        {error, Error} -> {error, Error};
        Bucket ->
            case goods_bucket:can_del(Bucket, item_by_id, {ItemId, Num}) of  %%物品是否能删除
                {error, Error} -> {error, Error};
                ok ->
                    Goods = goods_bucket:find_goods(Bucket, by_id, {ItemId}),
                    Bid = Goods#item_new.bid,

                    % ?INFO_LOG("item_attr_cfg ~p", [load_item:get_item_cfg(Bid)]),
                    % Mycfg = load_item:get_item_cfg(Bid),
                    % #item_attr_cfg{use_type = TTTUse} = Mycfg,
                    % ?INFO_LOG("item_attr_cfg isUse: ~p", [TTTUse]),
                    case load_item:get_item_cfg(Bid) of
                        {error, Error} -> {error, Error};

                        Cfg = #item_attr_cfg{type = ItemType,use_type = IsUse, use_effect = Effects} when IsUse =:= ?TRUE ->
                            case use_goods:use_item(Effects, {Goods, Cfg, Num}, []) of
                                {error, _Other} ->
                                    {error, _Other};
                                [] ->
                                    %%物品类型为7表示变身卡牌
                                    case ItemType of
                                        ?ITEM_TYPE_CARD ->
                                            shapeshift_mng:use_card(Bid);
                                        ?ITEM_TYPE_PET_EGG ->
                                            pet_new_mng:auto_figth_of_first_pay(Bid),
                                            open_server_happy_mng:sync_task(?HATCH_PET_COUNT, 1),
                                            bounty_mng:do_bounty_task(?BOUNTY_TASK_FUHUA_PET, 1);
                                        _ ->
                                            ok
                                    end,
                                    %%删除物品更新背包
                                    NewBucket = attr_new:get(?pd_goods_bucket),
                                    goods_bucket:begin_sync(NewBucket),
                                    {FinalBucket, _} = goods_bucket:del(NewBucket, item_by_id, {ItemId, Num}),
                                    goods_bucket:end_sync(FinalBucket),
                                    {ok, []};
                                ItemList ->
                                    NewBucket = attr_new:get(?pd_goods_bucket),
                                    goods_bucket:begin_sync(NewBucket),
                                    {FinalBucket, _} = goods_bucket:del(NewBucket, item_by_id, {ItemId, Num}),
                                    goods_bucket:end_sync(FinalBucket),
                                    {ok, ItemList}
                            end;
                        #item_attr_cfg{} -> {error, cant_use};
                        _ -> {error, not_found_cfg}
                    end;
                _ -> ret:error(unknown_type)
            end
    end.

%% @doc 批量使用礼包
% do_use_gitf(_ItemId, Num, Num) -> ok;
% do_use_gitf(ItemId, Num, TotalNum) ->
%     case try_goods_use(ItemId, 1) of
%         {ok, ItemList} ->
%             ?player_send(item_sproto:pkg_msg(?MSG_GIFT_ITEM_USE, {ItemList})),
%             do_use_gitf(ItemId, Num + 1, TotalNum);
%         {error, Error} -> {error, Error}
%     end.


%% 使用礼包物品
try_gift_goods_use(ItemId, Num) ->
    % ?INFO_LOG("try_gift_goods_use"),
    % do_use_gitf(ItemId, 0, Num).
    case try_goods_use(ItemId, Num) of
        {ok, ItemList} ->
            ?player_send(item_sproto:pkg_msg(?MSG_GIFT_ITEM_USE, {ItemList}));
        {error, Error} -> 
            {error, Error}
    end.

try_move_goods_in_buckets(SBucketType, SItemId, DBucketType, DItemPos) ->
    case game_res:get_bucket(SBucketType) of
        {error, Error} -> 
            {error, Error};
        FromBucket ->
            case game_res:get_bucket(DBucketType) of
                {error, Error} -> 
                    {error, Error};
                ToBucket ->
                    Size = goods_bucket:get_field(ToBucket, ?goods_bucket_size, 0),
                    if
                        Size >= DItemPos ->
                            case goods_bucket:find_goods(FromBucket, by_id, {SItemId}) of
                                {error, Error} -> 
                                    {error, Error};
                                FromGoods ->
                                    case goods_bucket:find_goods(ToBucket, by_pos, {DItemPos}) of
                                        {error, _} ->
                                            %% 放入
                                            goods_bucket:begin_sync(FromBucket),
                                            goods_bucket:begin_sync(ToBucket),
                                            {NewFromBucket, _} = goods_bucket:del(FromBucket, item_by_id, {SItemId}),
                                            {NewToBucket, _} = goods_bucket:add(ToBucket, item_by_pos, {FromGoods, DItemPos}),
                                            goods_bucket:end_sync(NewFromBucket),
                                            goods_bucket:end_sync(NewToBucket),
                                            game_res:do_extra_something_by_buckettype(SBucketType, FromGoods, 0),
                                            game_res:do_extra_something_by_buckettype(DBucketType, FromGoods, 1),
                                            ok;
                                        _ ->
                                            %% 交换
                                            goods_bucket:begin_sync(FromBucket),
                                            goods_bucket:begin_sync(ToBucket),
                                            {NewToBucket, NewToGoods} = goods_bucket:del(ToBucket, item_by_pos, {DItemPos}),
                                            {NewFromBucket, NewFromGoods} = goods_bucket:del(FromBucket, item_by_id, {SItemId}),
                                            {NewToPushBucket, _} = goods_bucket:add(NewToBucket, item_by_pos, {NewFromGoods, DItemPos}),
                                            {NewFromPushBucket, _} = goods_bucket:add(NewFromBucket, item_by_pos, {NewToGoods, NewFromGoods#item_new.pos}),
                                            goods_bucket:end_sync(NewToPushBucket),
                                            goods_bucket:end_sync(NewFromPushBucket),
                                            ok
                                    end
                            end;
                        true -> 
                            {error, unknown_type}
                    end
            end
    end.




%% 整理背包，绑定和非绑不会合并
bucket_sort(BucketType) ->
    ?INFO_LOG("bucket_sort"),
    case game_res:get_bucket(BucketType) of
        {error, Error} -> {error, Error};
        Bucket ->
            goods_bucket:begin_sync(Bucket),
            NewBucket = goods_bucket:sort(Bucket),
            goods_bucket:end_sync(NewBucket),
            ok
    end.


%% 解绑道具
try_unbind_goods(ItemId) ->
    case game_res:get_bucket(?BUCKET_TYPE_BAG) of
        {error, Error1} -> {error, Error1};
        Bucket ->
            case goods_bucket:can_del(Bucket, item_by_id, {ItemId, 1}) of
                {error, Error2} -> {error, Error2};
                ok ->
                    Goods = goods_bucket:find_goods(Bucket, by_id, {ItemId}),
                    case Goods#item_new.bind of
                        1 ->
                            UnbindCostId = misc_cfg:get_misc_cfg(unbind_cost_id),
                            case goods_bucket:can_del(Bucket, any_by_bid, {UnbindCostId, 1}) of
                                {error, _} -> {error, no_enough_cost};
                                _ ->
                                    case goods_bucket:can_add(Bucket, item_by_id, {ItemId}) of
                                        {error, _Error} -> {error, no_enough_size};
                                        _ ->
                                            goods_bucket:begin_sync(Bucket),
                                            {Bucket1, BindGoods} = goods_bucket:del(Bucket, item_by_id, {ItemId, 1}),
                                            {Bucket2, _} = goods_bucket:del(Bucket1, any_by_bid, {UnbindCostId, 1}),
                                            {Bucket3, UnBindGoods} = goods_bucket:add(Bucket2, item_by_id, {BindGoods#item_new{bind = 0}}),
                                            goods_bucket:end_sync(Bucket3),
                                            {ok, UnBindGoods#item_new.id}
                                    end
                            end;
                        _ ->
                            {error, already_unbind}
                    end
            end
    end.

%% 物品合成
compound_goods(ItemBid, Count) ->
    {CostItemBid, CostCount} = load_cfg_compound:get_compound_mes(ItemBid),  %% 在读配置表时有验证，所以直接匹配
    %% 计算消耗品的数量
    CostAllCount = Count * CostCount,
    %% 判断消耗是否充足
    case game_res:can_del([{by_bid, {CostItemBid, CostAllCount}}]) of
        ok ->
            %% 判断背包的空间是否足够
            BagEqmBucket = game_res:get_bucket(?BUCKET_TYPE_BAG),
            LeftSize = goods_bucket:get_empty_size(BagEqmBucket),
            OverLap = load_item:get_overlap(ItemBid),
            case Count =< OverLap * LeftSize of
                true ->
                    game_res:del([{by_bid, {CostItemBid, CostAllCount}}], ?FLOW_REASON_ITEM_HECHENG),
                    game_res:try_give_ex([{ItemBid, Count}], ?FLOW_REASON_ITEM_HECHENG),
                    ok;
                _ ->
                    {error, bag_not_enough}
            end;
        _ ->
            {error, cost_not_enough}
    end.