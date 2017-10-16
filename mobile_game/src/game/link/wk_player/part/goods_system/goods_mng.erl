%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 27. 七月 2015 下午9:41
%%%-------------------------------------------------------------------
-module(goods_mng).
-author("clark").

%% API
-export(
[
    send_add_goods_list/2,
    send_del_goods_list/2,
    send_qty_goods_list/2,
    send_up_goods_list/2,
    send_bucket_unlock/2
]).


-include("inc.hrl").
-include("handle_client.hrl").
-include("player.hrl").
-include("item_mng_reply.hrl").
-include("item_bucket.hrl").
-include("bucket_interface.hrl").
-include("achievement.hrl").
-include("load_phase_ac.hrl").
-include("../../../wk_open_server_happy/open_server_happy.hrl").


handle_client({Pack, Arg}) ->
    handle_client(Pack, Arg).

%% 查看所有背包信息
handle_client(?MSG_ITEM_BUCKET_ALL_INFO, {BucketType}) ->
    Ret = goods_system:get_bucket_info(BucketType),
    % player_log_service:add_crash_log(get(?pd_id), get(?pd_name), {BucketType, Ret}),
    case Ret of
        #bucket_info{} ->
            ?player_send(item_sproto:pkg_msg(?MSG_ITEM_BUCKET_ALL_INFO,
                {
                    Ret#bucket_info.bucketType,
                    Ret#bucket_info.unlockSize,
                    Ret#bucket_info.uT,
                    Ret#bucket_info.items
                }
            ));
        _ -> ignore
    end;

%% 整理背包，绑定和非绑不会合并
handle_client(?MSG_ITEM_BUCKET_SORT, {BucketType}) ->
    Ret = goods_system:bucket_sort(BucketType),
    ReplyNum =
        case Ret of
            ok -> ?REPLY_MSG_ITEM_BUCKET_SORT_OK;
            {error, cant_bucket_type_eqm} -> ?REPLY_MSG_ITEM_BUCKET_SORT_255;
            {error, not_private} -> ?REPLY_MSG_ITEM_BUCKET_SORT_255;
            _ -> ?REPLY_MSG_ITEM_BUCKET_SORT_255
        end,
    ?player_send(item_sproto:pkg_msg(?MSG_ITEM_BUCKET_SORT, {ReplyNum}));

%% 移动物品（同一背包内--装备背包不能用此功能
handle_client(?MSG_ITEM_BUCKET_MOVE, {BucketType, Goods, ToPos}) ->
    Ret = goods_system:try_move_goods(BucketType, Goods, ToPos),
    ReplyNum =
        case Ret of
            ok -> ?REPLY_MSG_ITEM_BUCKET_MOVE_OK;
            {error, cant_bucket_type_eqm} -> ?REPLY_MSG_ITEM_BUCKET_MOVE_255;
            {error, not_private} -> ?REPLY_MSG_ITEM_BUCKET_MOVE_255;
            {error, ill_new_pos} -> ?REPLY_MSG_ITEM_BUCKET_MOVE_1;   %% 新位置未解锁
            {error, same_pos} -> ?REPLY_MSG_ITEM_BUCKET_MOVE_2;      %% 位置未发生变化，无需移动
            _ -> ?REPLY_MSG_ITEM_BUCKET_SORT_255
        end,
    ?player_send(item_sproto:pkg_msg(?MSG_ITEM_BUCKET_MOVE, {ReplyNum}));

%% 拆分物品
handle_client(?MSG_ITEM_BUCKET_SPLIT, {BucketType, Goods, GoodsNum}) ->
    Ret = goods_system:try_bucket_split(BucketType, Goods, GoodsNum),
    ReplyNum =
        case Ret of
            ok -> ?REPLY_MSG_ITEM_BUCKET_SPLIT_OK;
            {error, cant_bucket_type_eqm} -> ?REPLY_MSG_ITEM_BUCKET_SPLIT_255;
            {error, not_private} -> ?REPLY_MSG_ITEM_BUCKET_SPLIT_255;
            {error, split_num_biger_qua} -> ?REPLY_MSG_ITEM_BUCKET_SPLIT_1;   %% 拆分数量大于实际数量
            {error, same_pos} -> ?REPLY_MSG_ITEM_BUCKET_MOVE_2;      %% 位置未发生变化，无需移动
            _ -> ?REPLY_MSG_ITEM_BUCKET_SPLIT_255
        end,
    ?player_send(item_sproto:pkg_msg(?MSG_ITEM_BUCKET_SPLIT, {ReplyNum}));

%% 移动物品(不同背包之间
handle_client(?MSG_ITEM_BUCKET_MOVE_CROSS, {SBucketType, SItemId, DBucketType, DItemPos}) ->
    Ret = goods_system:try_move_goods_in_buckets(SBucketType, SItemId, DBucketType, DItemPos),
    ReplyNum =
        case Ret of
            ok -> ?REPLY_MSG_ITEM_BUCKET_MOVE_CROSS_OK;
            {error, not_dest_free_pos} -> ?REPLY_MSG_ITEM_BUCKET_SPLIT_1;        %% 新位置不可用
            {error, cant_in_depot} -> ?REPLY_MSG_ITEM_BUCKET_MOVE_CROSS_2;       %% 该物品不能存入仓库
            _ -> ?REPLY_MSG_ITEM_BUCKET_MOVE_CROSS_255
        end,
    ?player_send(item_sproto:pkg_msg(?MSG_ITEM_BUCKET_MOVE_CROSS, {ReplyNum}));

%% 一键移动物品（不同背包之间
handle_client(?MSG_ITEM_BUCKET_ONE_KEY_MOVE_CROSS, {_SBucketType, _ItemIdL, _DBucketType}) ->
    ok;

%% 解锁格子
handle_client(?MSG_ITEM_BUCKET_UNLOCK, {BucketType, UnlockType}) ->
    %?DEBUG_LOG("BucketType----------------:~p",[BucketType]),
    {Ret, NTU} = goods_system:try_bucket_unlock(BucketType, UnlockType),
    ReplyNum =
        case {Ret, NTU} of
            {ok, _} ->
                phase_achievement_mng:do_pc(?PHASE_AC_BEIBAO_STAR, 10003, api:get_bag_page_count()),
                case BucketType of
                    ?BUCKET_TYPE_BAG ->
                        open_server_happy_mng:sync_task(?BAG_GRID_OPEN_COUNT, api:get_bag_grid_num());
                    ?BUCKET_TYPE_DEPOT ->
                        open_server_happy_mng:sync_task(?DEPOT_GRID_OPEN_COUNT, api:get_depot_grid_num());
                    _ ->
                        pass
                end,
                ?REPLY_MSG_ITEM_BUCKET_UNLOCK_OK;
            {error, already_unlock} -> ?REPLY_MSG_ITEM_BUCKET_UNLOCK_1;          %% 已经解锁过了，无需解锁
            {error, cant_yueji_unlock} -> ?REPLY_MSG_ITEM_BUCKET_UNLOCK_2;       %% 解锁需要一步一步来
            {error, diamond_not_enough} -> ?REPLY_MSG_ITEM_BUCKET_UNLOCK_3;      %% 钻石不足
            {error, unlock_ing} -> ?REPLY_MSG_ITEM_BUCKET_UNLOCK_4;              %% 正在解锁中
            _ -> ?REPLY_MSG_ITEM_BUCKET_UNLOCK_255
        end,
    ?player_send(item_sproto:pkg_msg(?MSG_ITEM_BUCKET_UNLOCK, {ReplyNum, BucketType, UnlockType, max(0, NTU)}));


%% 合并物品
handle_client(?MSG_ITEM_BUCKET_MERGE, {BucketType, SItemId, DItemId}) ->
    Ret = goods_system:try_bucket_merge(BucketType, SItemId, DItemId),
    ReplyNum =
        case Ret of
            ok -> ?REPLY_MSG_ITEM_BUCKET_MERGE_OK;
            {error, cant_merge} -> ?REPLY_MSG_ITEM_BUCKET_MERGE_1;
            {error, not_same_item} -> ?REPLY_MSG_ITEM_BUCKET_MERGE_2;
            _ -> ?REPLY_MSG_ITEM_BUCKET_MERGE_255
        end,
    ?player_send(item_sproto:pkg_msg(?MSG_ITEM_BUCKET_MERGE, {ReplyNum}));

%% 使用物品
handle_client(?MSG_ITEM_USE, {ItemId, Num}) ->
    Ret = goods_system:try_goods_use(ItemId, Num),
    ReplyNum =
        case Ret of
            ok -> ?REPLY_MSG_ITEM_USE_OK;
            {ok, ItemList} -> {?REPLY_MSG_ITEM_USE_OK, ItemList};
            {error, cant_use} -> ?REPLY_MSG_ITEM_USE_1;
            {error, item_not_found} -> ?REPLY_MSG_ITEM_USE_2;
            {error, item_not_enough} -> ?REPLY_MSG_ITEM_USE_3;
            _ -> ?REPLY_MSG_ITEM_USE_255
        end,
    case ReplyNum of
        {ReplyState, []} ->
            ?player_send(item_sproto:pkg_msg(?MSG_ITEM_USE, {ReplyState}));
        {ReplyState, ItemList1} ->
            ?player_send(item_sproto:pkg_msg(?MSG_GIFT_ITEM_USE, {ItemList1})),
            ?player_send(item_sproto:pkg_msg(?MSG_ITEM_USE, {ReplyState}));
        ReplyNum ->
            ?player_send(item_sproto:pkg_msg(?MSG_ITEM_USE, {ReplyNum}))
    end;

%% 使用礼包物品
handle_client(?MSG_GIFT_ITEM_USE, {ItemId, Num}) ->
    case goods_system:try_gift_goods_use(ItemId, Num) of
        ok -> ok;
        {error, no_enough_size} -> ?return_err(?ERR_BAG_FULL);
        {error, _Other} -> ?return_err(_Other)
    end;

%% 解绑道具
handle_client(?MSG_ITEM_UNBIND, {ItemId}) ->
    ReplyNum = case goods_system:try_unbind_goods(ItemId) of
        {error, no_enough_cost} -> {?REPLY_MSG_ITEM_UNBIND_1, 0};
        {error, _} -> {?REPLY_MSG_ITEM_UNBIND_255, 0};
        {ok, Bid} -> {?REPLY_MSG_ITEM_UNBIND_OK, Bid}
    end,
    ?player_send(item_sproto:pkg_msg(?MSG_ITEM_UNBIND, ReplyNum));

%% 合成物品
handle_client(?MSG_GOODS_COMPOUND, {ItemBid, Count}) ->
    %?INFO_LOG("ItemBid = ~p, Count = ~p", [ItemBid, Count]),
    attr_new:begin_sync_attr(),
    Ret = goods_system:compound_goods(ItemBid, Count),
    attr_new:end_sync_attr(),
    ReplyNum =
        case Ret of
            ok -> ?REPLY_MSG_GOODS_COMPOUND_OK;
            {error, cost_not_enough} -> ?REPLY_MSG_GOODS_COMPOUND_1;
            {error, bag_not_enough} -> ?REPLY_MSG_GOODS_COMPOUND_2;
            _ -> ?REPLY_MSG_GOODS_COMPOUND_255
        end,
    %?INFO_LOG("hecheng goods ReplyNum = ~p", [ReplyNum]),
    ?player_send(item_sproto:pkg_msg(?MSG_GOODS_COMPOUND, {ReplyNum}));

handle_client(Mod, Msg) ->
    ?ERROR_LOG("no known msg Mod:~p Msg:~p", [item_sproto:to_s(Mod), Msg]).


send_add_goods_list(UserType, AddIL) ->
    %?DEBUG_LOG("AddIL---------------------------:~p",[AddIL]),
    ?player_send(item_sproto:pkg_msg(?MSG_ITEM_BUCKET_ADD_ITEMS, {?ITEM_ADD, UserType, AddIL})).

send_del_goods_list(UserType, DelIdL) ->
    %?INFO_LOG("send_del_goods_list ~p", [[UserType, DelIdL]]),
    ?player_send(item_sproto:pkg_msg(?MSG_ITEM_BUCKET_PUSH_DEL_IDS, {UserType, DelIdL})).

send_qty_goods_list(UserType, QtyIdL) ->
    %?INFO_LOG("send_qty_goods_list ~p", [[UserType, QtyIdL]]),
    ?player_send(item_sproto:pkg_msg(?MSG_ITEM_BUCKET_PUSH_CHG, {1, UserType, QtyIdL})).

send_bucket_unlock(BucketType, NeedSceccnd) ->
    ?player_send(item_sproto:pkg_msg(?MSG_ITEM_BUCKET_UNLOCK, {?REPLY_MSG_ITEM_BUCKET_UNLOCK_OK, BucketType, ?UNLOCK_TYPE_TIME, NeedSceccnd})).

send_up_goods_list(UserType, AddIL) ->
    ?player_send(item_sproto:pkg_msg(?MSG_ITEM_BUCKET_ADD_ITEMS, {?ITEM_UPDATE, UserType, AddIL})).
