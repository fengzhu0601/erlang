%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 05. 四月 2016 下午3:57
%%%-------------------------------------------------------------------
-author("clark").

-include("inc.hrl").
-include("porsche_gearbox.hrl").

-define(net_room_player_type,   playr_room).
-define(net_room_team_type,     team_room).

%% 联机房间
-record(net_room_cfg,
{
    type,
    id,
    cfg_bid
}).



%% 进入房间结构
-record(enter_room_args,
{
    x,                          %% 坐标
    y,                          %% 坐标
    dir,                        %% 方向
    player_id,                  %% 玩家ID
    type,
    machine_screen_w,           %% 机器屏幕
    machine_screen_h,           %% 机器屏幕
    hp,                         %% HP
    mp,                         %% MP
    anger=0,                      %% 怒气值
    attr,                       %% 属性
    lvl,                        %% 等级
    shape_data,                 %% 外形数据
    equip_shape_data,           %% 装备外形数据
    shapeshift_data,            %% 外形数据
    ride_data,                  %% 坐骑数据
    near_limit,                 %% 周边限制人数
    skill_modify,                %% 技能修改集id列表
    team_id = 0,
    party = 0,
    from_pid = 0
}).

%% 退出房间结构
-record(exit_room_args,
{
    idx
}).

