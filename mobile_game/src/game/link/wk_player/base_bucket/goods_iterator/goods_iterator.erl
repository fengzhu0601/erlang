%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 10. 十二月 2015 下午4:59
%%%-------------------------------------------------------------------
-module(goods_iterator).
-author("clark").

%% API
-export
([
    can_add/3         %% 增加物品
    , can_del/3         %% 减少物品
    , find/3
    , add/3
    , del/3
]).





-include("inc.hrl").
-include("bucket_interface.hrl").
-include("item_bucket.hrl").
-include("load_item.hrl").
-include("player.hrl").



can_add(Bucket = #bucket_interface{}, Type, TPar) ->
    case get_iterator(Type) of
        nil -> ret:error(cant_add);
        Mod -> Mod:can_add(Bucket, TPar)
    end.

can_del(Bucket = #bucket_interface{}, Type, TPar) ->
    case get_iterator(Type) of
        nil -> ret:error(cant_del);
        Mod -> Mod:can_del(Bucket, TPar)
    end.

find(Bucket = #bucket_interface{}, Type, TPar) ->
    case get_iterator(Type) of
        nil -> ret:error(cant_find);
        Mod -> Mod:find(Bucket, TPar)
    end.

add(Bucket = #bucket_interface{}, Type, TPar) ->
    case get_iterator(Type) of
        nil -> ret:error(cant_add);
        Mod -> Mod:add(Bucket, TPar)
    end.

del(Bucket = #bucket_interface{}, Type, TPar) ->
    case get_iterator(Type) of
        nil -> ret:error(cant_del);
        Mod -> Mod:del(Bucket, TPar)
    end.

%% ------------------------------------
get_iterator(Type) ->
    case Type of
        item_by_id      -> goods_id_iterator;
        by_id           -> goods_id_iterator;
        by_bid          -> goods_bid_iterator;
        any_by_bid      -> goods_bid_iterator;
        by_pos          -> goods_pos_iterator;
        item_by_pos     -> goods_pos_iterator;
        _               -> nil
    end.

%% get_practice_bucket(Bucket = #bucket_interface{save_key = SaveKey}) ->
%%     PreaBucket =
%%         case SaveKey of
%%             ?pd_equip_bucket ->
%%                 attr_new:get
%%                 (
%%                     ?pd_equip_bucket_prea,
%%                     #bucket_interface{save_key = ?pd_equip_bucket_prea, temp_key = -99}
%%                 );
%%             ?pd_goods_bucket ->
%%                 attr_new:get
%%                 (
%%                     ?pd_goods_bucket_prea,
%%                     #bucket_interface{save_key = ?pd_goods_bucket_prea, temp_key = -99}
%%                 );
%%             ?pd_depot_bucket ->
%%                 attr_new:get
%%                 (
%%                     ?pd_depot_bucket_prea,
%%                     #bucket_interface{save_key = ?pd_depot_bucket_prea, temp_key = -99}
%%                 );
%%             _ ->
%%                 ?ERROR_LOG("unknown_buckey"),
%%                 ret:error(unknown_buckey)
%%         end,
%%     case PreaBucket#bucket_interface.temp_key of
%%         -99 ->
%%             %% 未初始化的进行初始化
%%             PracBucket1 = practice_init_data(PreaBucket, Bucket),
%%             PracBucket1;
%%         _ ->
%%             PreaBucket
%%     end.
%%
%% practice_init_data(PracBucket, Bucket = #bucket_interface{}) ->
%%     PracBucket1 =
%%         PracBucket#bucket_interface
%%         {
%%             id = Bucket#bucket_interface.id                     %% 背包接口
%%             , type = Bucket#bucket_interface.type               %% 背包类型
%%             , user_type = Bucket#bucket_interface.user_type     %% 用户类型
%%             , goods_list = Bucket#bucket_interface.goods_list   %% 物品[goods()]
%%             , field = Bucket#bucket_interface.field             %% 字段
%%         },
%%     goods_bucket:save(PracBucket1),
%%     PracBucket1.
%%
%% practice_init() ->
%%     attr_new:set(?pd_equip_bucket, #bucket_interface{save_key = ?pd_equip_bucket, temp_key = -99}),
%%     attr_new:set(?pd_goods_bucket, #bucket_interface{save_key = ?pd_goods_bucket, temp_key = -99}),
%%     attr_new:set(?pd_depot_bucket, #bucket_interface{save_key = ?pd_depot_bucket, temp_key = -99}).