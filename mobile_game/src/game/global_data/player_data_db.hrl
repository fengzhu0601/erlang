%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 26. 六月 2015 上午4:04
%%%-------------------------------------------------------------------
-author("clark").


-include("bucket_interface.hrl").
-define(sinks_state_len, 400).               %% 状态表字节空间 400 = 50*8

%% 转盘数据
-record(dial_prize,
{
    dial_prize = [{1, 0, 0, 0}, {2, 0, 0, 0}, {3, 0, 0, 0}, {4, 0, 0, 0}, {5, 0, 0, 0}, {6, 0, 0, 0}, {7, 0, 0, 0}, {8, 0, 0, 0}],  %% 转盘奖励
    dial_count = 0                          %% 已转盘次数
}).

%% 登陆奖励数据
-record(login_prize,
{
    give_count = 0,                         %% 奖励次数
    login_count = 1                         %% 登陆次数
}).

-record(login_prize_new,
{
    sign_info_list = []                     %% 登陆奖励信息
}).

%% 订单记录
-record(pay_orders,
{
    total_orders_count = 0,                 %% 历史订单计数
    pay_orders = []                         %% 订单记录 list<{id:u32, money:u32, timestamp:u32, state:u8}>
}).


%% ------------------------------------------------------------------------------------------------
%% 平台name 对游戏人物的id映射
-record(player_platform_id_tab,
{
    id = 0,                                 %%  平台ID
    player_id = 0                           %%  玩家ID
}).

%% 玩家账号信息
-record(account_tab,
{
    account_name,
    player_id=[],
    platform_id,
    create_time,
    password,
    player_statue = 1,
    account_statue = 1
}).

%% 防同名
-record(player_name_tab,
{
    name,
    id                                      %%  player_id
}).


%% 数据库玩家数据
-record(player_data_tab,
{
    player_id = 0,                          %% 玩家ID
    field_data = []                         %% 角色属性
}).


%% 客户端私有数据表
-record(player_client_data_tab,
{
    id,
    data %% dict
}).


%% 在线玩家表
-record(player_tab,
{
    id,
    name,
    career,
    level = 1,
    hp = 0,
    mp = 0,
    longwens = 0,
    pearl = 0,
    long_wen = 0,
    exp = 0,                        %本级经验
    money = 0,                      %铜钱
    diamond = 0,                      %% 钻石
    %%bind_diamond=0,               %%绑定钻石
    fragment = 0,                     %% 碎片
    honour = 0,                       %% 荣耀
    sp = 0,                           %% 体力
    sp_buy_count = 0,                 %% 体力购买次数
    scene_id,
    x = -1,
    y = -1,

    save_scene_id,
    save_x = -1,
    save_y = -1,

    create_time,                    %% first create time sec
    last_login_time,
    last_logout_time = 0,

    combat_power = 10,                %% 战斗力
    item_id = 1,                      %% 物品id
    add_hp_mp_info = {0, {0, 0}},   %% 加hp/mp信息{Count, {InsId, HardId}}
    main_ins_jinxing = 0,
    main_ins_yinxing = 0
}).


%% 玩家属性表
-record(player_attr_tab,
{
    id,
    attr
}).


%% 杂项
-record(player_misc_tab,
{
    id,
    val = gb_trees:empty()
}).

-record(player_backet_tab,
{
    id,
    bucket
}).


%% 镜像数据
-record(player_attr_image_tab,
{
    id,
    attr_new
}).

-define(account_prize_tab, account_prize_tab).
-record(account_prize_tab, {
    account_name,
    level_prize_state = 0,
    suit_prize_state = 0,
    phase_list = []
}).