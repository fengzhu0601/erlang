%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%% 前端需要从背包移出物品时，要跑全局移动的过程（因为前端的物品项是不分放于那个容器的,这里只能特殊处理一下了).
%%% @end
%%% Created : 25. 八月 2015 下午5:24
%%%-------------------------------------------------------------------
-module(client_need_global_remove).
-author("clark").

%% API
-export(
[
    push_del_sync/1
    , end_del_sync/0
    , init_del_sync/1
]).






-include("inc.hrl").
-include("bucket_interface.hrl").
-include("item_bucket.hrl").
-include("load_item.hrl").
-include("player.hrl").



push_del_sync(GoodsID) ->
    SyncTemp = attr_new:get(?pd_global_bucket_temp, #bucket_sync_tmp{}),
    DelList = SyncTemp#bucket_sync_tmp.del_list,
    NewDelList = [GoodsID | DelList],
    NewSyncTemp = setelement(#bucket_sync_tmp.del_list, SyncTemp, NewDelList),
    attr_new:set(?pd_global_bucket_temp, NewSyncTemp).


end_del_sync() ->
    SyncTemp = attr_new:get(?pd_global_bucket_temp, #bucket_sync_tmp{}),
    %% 发送删除物品协议
    DelLength = length(SyncTemp#bucket_sync_tmp.del_list),
    if
        DelLength > 0 ->
            goods_mng:send_del_goods_list(0, SyncTemp#bucket_sync_tmp.del_list),
            NewSyncTemp = setelement(#bucket_sync_tmp.del_list, SyncTemp, []),
            attr_new:set(?pd_global_bucket_temp, NewSyncTemp);
        true -> ret:ok()
    end.


init_del_sync(DelList) ->
    SyncTemp = attr_new:get(?pd_global_bucket_temp, #bucket_sync_tmp{}),
    NewSyncTemp = setelement(#bucket_sync_tmp.del_list, SyncTemp, DelList),
    attr_new:set(?pd_global_bucket_temp, NewSyncTemp).



