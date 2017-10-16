%%%-------------------------------------------------------------------
%%% @author fengzhu
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 10. 五月 2016 下午6:04
%%%-------------------------------------------------------------------
-author("fengzhu").

-define(RIDE_ADVANCE_FLAG_TRUE, 1).    %%可进阶状态
-define(RIDE_ADVANCE_FLAG_FALSE, 0).   %%不可进阶状态

%%-define(RIDE_TYPE_NORMAL, 1).          %%坐骑类型普通
%%-define(RIDE_TYPE_RARE, 2).            %%坐骑类型稀有

%% 坐骑乘骑状态
-define(RIDE_STATUS_RIDE, 1).      %% 乘骑状态
-define(RIDE_STATUS_UNRIDE, 2).    %% 正常状态

%% 坐骑
-record(ride,
{
    id,                      % 坐骑唯一Id
    cfgid,                   % 坐骑配置Id
    formId,                  % 坐骑形象id
    status,                  % 坐骑状态
    level,                   % 等级
    speed,                   % 移动速度
    attr = [],               % 当前属性
    cost                     % 材料消耗
}).

%% 玩家坐骑表
-record(player_rides,
{
    id = 0,                %% 玩家ID int
    rides = [],            %% 拥有的所有坐骑#ride{}
    riding = 0             %% 当前乘骑的坐骑#ride.id
}).

-define(ride_global_tab, player_ride_tab).
-record(player_ride_tab,
{
    ride_id = 0,   %坐骑id
    ride_info      %坐骑信息
}).

%% 兽魂
-record(ride_soul,
{
    id,                 %% 兽魂id
    formId,             %% 兽魂形象Id
    level,              %% 兽魂等级
    exp,                %% 兽魂当前经验值
    grade,              %% 兽魂阶数
    attr,               %% 兽魂的属性
    out_price,          %% 兽魂吃撑吐出奖励
    out_cd,             %% 兽魂吐出奖励的cd
    out_num,            %% 每天喷吐次数
    happy               %% 兽魂愉悦度
}).

-define(ride_soul_global_tab, player_ride_soul_tab).
-record(player_ride_soul,
{
    id = 0,             %玩家id
    ride_soul_info      %兽魂信息
}).




