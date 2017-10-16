
%% Use def
%-type bucket_type() :: 
%  ?BUCKET_TYPE_BAG | ?BUCKET_TYPE_DEPOT | ?BUCKET_TYPE_EQM.

-include("item_bucket_def.hrl").


-define(UNLOCK_TYPE_DIAMOND, 1).  %% 钻石解锁格子
-define(UNLOCK_TYPE_TIME, 2).  %% 时间解锁格子


%% 普通私人背包类型
-define(BUCKET_TYPE_PRIVATE_GENERAL,
    [
        ?BUCKET_TYPE_BAG
        , ?BUCKET_TYPE_DEPOT
    ]
).
%% 所有的私人背包类型
-define(BUCKET_TYPE_PRIVATE,
    [
        ?BUCKET_TYPE_EQM
        | ?BUCKET_TYPE_PRIVATE_GENERAL
    ]
).

%% 装备可以直接提升的背包
-define(BUCKET_EQM_UP,
    [
        ?BUCKET_TYPE_BAG
        , ?BUCKET_TYPE_EQM
    ]
).
%% 添加/更新物品标志
-define(ITEM_ADD, 1).   %% 添加
-define(ITEM_UPDATE, 2).   %% 更新


%% 用于物品属性改变发包
-define(ITEM_CHG_QTY, 1).  %% 数量
-define(ITEM_CHG_POS, 2).  %% 位置
-define(ITEM_CHG_JD, 3).  %% 鉴定属性
-define(ITEM_CHG_QLY, 4).  %% 品质变化



-define(item_id_assets_max, 1000). %% 资产物品最大id

%% 口袋结构()
%% 老版本的容器（一上来就有时间解锁有资产的，太强大了，不需要这么复杂的，需要的只是一个纯碎的装脱东西的容器即可，其它的待子类扩展）
-record(bucket, {
    id = 0                              %% 角色id
    , type = 0                           %% 背包类型 1背包 2仓库 3装备
    , bucket_ver = 0                     %% 背包结构版本号
    , item_ver = 0                     %% #item{}版本号
    , unlock_volume = 0                   %% 解锁的背包容量
    , unlock_time = 0                    %% 解锁超时时间
    , volume = 0                          %% 背包容量
    , free_pos = []                    %% 空位置 [int()]
    , items = []                    %% 物品[item()]
    , assets = []                    %% 资产类[{AssetsId, AssetsVal}]
}).

%% 将口袋类型转化为进程字典
-define(bucket_type2pd(BucketType),
    item_bucket_def:bucket_type_to_a(BucketType)
).


-record(unlock_cfg, {
    id,
    open_time,   %% 开启格子所需时间（单位：s）
    diamond,      %% 开启格子所需元宝数量
    grid_index,   %% 第一个开启的格子index
    unlock_num    %% 开启的数量
}).

-define(bucket_page_size, 16).   %% 仓库页大小（用于解锁，目前各个背包相同，如果发生变化时，需要处理
-define(bucket_max_size, 80).

-record(bucket_sync_tmp,
{
    begin_count = 0,
    pos_change_list = [],       %% 发包物品位置属性变化列表
    qty_change_list = [],       %% 发包物品数量变化列表
    add_list = [],              %% 发送添加物品协议
    up_list = [],               %% 发送更新物品协议
    del_list = []               %% 发送删除物品协议
}).

