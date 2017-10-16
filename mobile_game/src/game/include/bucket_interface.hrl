%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 29. 七月 2015 下午9:39
%%%-------------------------------------------------------------------
-author("clark").


-include("item_new.hrl").



-define(bucket_error_unknow, bucket_error_unknow).
-define(bucket_error_no_item, bucket_error_no_item).
-define(bucket_error_has_item, bucket_error_has_item).
-define(bucket_error_no_bucket, bucket_error_no_bucket).
-define(bucket_error_no_empty, bucket_error_no_empty).
-define(bucket_error_error_pos, bucket_error_error_pos).

%% 背包结构
-record(bucket_interface,
{
    id = 0                      %% 背包接口
    , type = 0                  %% 背包类型
    , user_type = 0             %% 用户类型
    , save_key = 0              %% 数据库保存KEY
    , temp_key = 0              %% 用于临时中转数据的KEY
    , goods_list = []           %% 物品[goods()]背包槽链表 goods_list == [#bucket_sink_interface{}, #bucket_sink_interface{} ...]
    , field = []                %% 字段
}).

%% 背包槽的结构
-record(bucket_sink_interface,
{
    pos = 0
    , id = 0
    , bid = 0
    , goods %% goods == #item_new{}
}).

%% 前端需要的显示信息结构
-record(bucket_info,
{
    bucketType = 0              %% 背包类型
    , unlockSize = 0            %% 已经解锁的容量大小
    , uT = 0                    %% 解锁时间
    , items = []                %% 物品信息列表
}).
-record(item_info,
{
    id = 0                      %% 物品id item_server_id
    , bid = 0                   %% 物品bid
    , pos = 0                   %% 物品位置
    , qly = 0                   %% 物品品质
    , qua = 0                   %% 物品数量
    , bind = 0                  %% 物品绑定状态 0非绑 1绑定
    , is_jd = 0                 %% 是否鉴定
    , suit_id = 0               %% 套装id
    , qh_lvl = 0                %% 强化等级
    , power = 0                 %% 装备评分
    , extra_attr = []           %%
    , gem_info = []             %%
    , item_ex = []              %% 物品槽列表
}).



%% -------------------
%% goods_bucket nil
-define(goods_bucket_type, 111).
-define(goods_bucket_size, 1001).


%% -------------------
%% time_bucket nil
-define(time_bucket_type, 222).
-define(unlick_time_limit, 2001). %解锁到达时间








