%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 10. 十二月 2015 下午3:44
%%%-------------------------------------------------------------------
-module(bucket_sync).
-author("clark").

%% API
-export(
[
    begin_sync/1
    , end_sync/1
    , push_add_sync/3
    , push_del_sync/2
    , push_qty_sync/3
    , push_up_sync/3
]).



-include("inc.hrl").
-include("bucket_interface.hrl").
-include("item_bucket.hrl").
-include("load_item.hrl").
-include("player.hrl").
-include("achievement.hrl").




%% -------------------------------------------------------------
begin_sync(Bucket = #bucket_interface{temp_key = TempKey}) ->
    SyncTemp = attr_new:get(TempKey, #bucket_sync_tmp{}),
    NewCeginCount = SyncTemp#bucket_sync_tmp.begin_count + 1,
    NewSyncTemp =
        if
            NewCeginCount == 1 ->
                attr_new:set(TempKey, #bucket_sync_tmp{begin_count = NewCeginCount});
            true ->
                attr_new:set(TempKey, SyncTemp#bucket_sync_tmp{begin_count = NewCeginCount})
        end,
    attr_new:set(TempKey, NewSyncTemp),
    Bucket.

end_sync(Bucket = #bucket_interface{temp_key = TempKey, user_type = UserType}) ->
    goods_bucket:save(Bucket),
    SyncTemp = attr_new:get(TempKey, #bucket_sync_tmp{}),
    NewCeginCount = SyncTemp#bucket_sync_tmp.begin_count,
    if
        NewCeginCount > 1 ->
            attr_new:set(TempKey, SyncTemp#bucket_sync_tmp{begin_count = (NewCeginCount - 1)});
        true ->
            %% 发包物品更新变化列表
            UpLength = length(SyncTemp#bucket_sync_tmp.up_list),
            if
                UpLength > 0 -> goods_mng:send_up_goods_list(UserType, SyncTemp#bucket_sync_tmp.up_list);
                true -> ret:ok()
            end,
            %% 发包物品数量变化列表
            QtyLength = length(SyncTemp#bucket_sync_tmp.qty_change_list),
            if
                QtyLength > 0 -> goods_mng:send_qty_goods_list(UserType, SyncTemp#bucket_sync_tmp.qty_change_list);
                true -> ret:ok()
            end,
            %% 发送删除物品协议（前端要求有的特殊处理）
            client_need_global_remove:end_del_sync(),
            %% 发送添加物品协议
            AddLength = length(SyncTemp#bucket_sync_tmp.add_list),
            if
                AddLength > 0 -> goods_mng:send_add_goods_list(UserType, SyncTemp#bucket_sync_tmp.add_list);
                true -> ret:ok()
            end,
            attr_new:set(TempKey, #bucket_sync_tmp{})
    end,

    %% 用来处理套装之神的任务是否达成
    case attr_new:get(?pd_is_build_suit, 0) of
        1 ->
            put(?pd_is_build_suit, 0),
            SuitCount = api:get_a_suit_count(),
            achievement_mng:do_ac2(?taozhuangzhishen, 0, SuitCount);
        _ ->
            pass
    end,
    Bucket.

push_add_sync(#bucket_interface{temp_key = TempKey}, Pos, Item) ->
    %?DEBUG_LOG("push_add_sync-----------------------:~p",[Item]),
    SyncTemp = attr_new:get(TempKey, #bucket_sync_tmp{}),
    AddList = SyncTemp#bucket_sync_tmp.add_list,
    NewAddList = [goods_bucket:get_sink_info(Item, Pos) | AddList],
    NewSyncTemp = setelement(#bucket_sync_tmp.add_list, SyncTemp, NewAddList),
    attr_new:set(TempKey, NewSyncTemp).

push_del_sync(_Bucket, GoodsID) ->
    client_need_global_remove:push_del_sync(GoodsID). %% 前端要求有的特殊处理

push_qty_sync(#bucket_interface{temp_key = TempKey}, GoodsID, Num) ->
    SyncTemp = attr_new:get(TempKey, #bucket_sync_tmp{}),
    QtyList = SyncTemp#bucket_sync_tmp.qty_change_list,
    NewQtyList = [{GoodsID, Num} | QtyList],
    NewSyncTemp = setelement(#bucket_sync_tmp.qty_change_list, SyncTemp, NewQtyList),
    attr_new:set(TempKey, NewSyncTemp).

push_up_sync(#bucket_interface{temp_key = TempKey}, Pos, Item) ->
    %?DEBUG_LOG("push_up_sync-----------------------:~p",[Item]),
    SyncTemp = attr_new:get(TempKey, #bucket_sync_tmp{}),
    UpList = SyncTemp#bucket_sync_tmp.up_list,
    Sink = goods_bucket:get_sink_info(Item, Pos),
    NewUpList = [Sink | UpList],
    NewSyncTemp = setelement(#bucket_sync_tmp.up_list, SyncTemp, NewUpList),
    attr_new:set(TempKey, NewSyncTemp).

