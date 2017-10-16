-define(main_ins_cfg, main_ins_cfg).
-define(camp_ins_cfg, camp_ins_cfg).

-define(service_camp_instance, service_camp_instance).
-define(service_camp_tab, service_camp_tab).
-define(player_camp_tab, player_camp_tab).

-define(pd_timer_mng_for_camp, pd_timer_mng_for_camp). %service进程存储倒计时的key值
-define(count_down, count_down). %倒计时
-define(camp_activity, camp_activity). %神魔活动倒计时
-define(player_refresh_time, player_refresh_time). %玩家进入副本次数刷新倒计时

-define(CAMP_CFG_ID, 1).     %camp_cfg默认ID
-define(CAMP_SERVICE_ID, 1). %公共信息默认ID
-define(CAMP_EVENT_MAX_LENGTH, 60). %事件存储最大数量
-define(CAMP_GOD, 1).    %神族
-define(CAMP_MAGIC, 2).  %魔族
-define(CAMP_PERSON, 3). %人族

-define(god_win, 1).     %神族胜利
-define(magic_win, 2).   %魔族胜利
-define(tie, 3).         %平局

-define(OPEN_FUN_LV_LINIT, lv). %功能开放等级限制key
-define(camp_open_panel, camp_open_panel). %面板是否打开

-define(EVENT_TYPE_KILL_PLAYER, 1). %事件类型，杀人
-define(EVENT_TYPE_KILL_BOSS, 2). %事件类型，通关副本

-define(pd_camp_fight_type, pd_camp_fight_type).%1.本族副本 2.入侵 3.防守
-define(pd_camp_fight_state, pd_camp_fight_state). %神魔副本状态%%0初始状态 1正在对打 2在boss房间
-define(pd_camp_invade_player, pd_camp_invade_player). %% 记录入侵玩家的Pid

-define(pd_camp_next_sceneId, pd_camp_next_sceneId).
%% 神魔系统玩家表
-record(player_camp_tab, {
    player_id,                %玩家ID
    self_camp = 0,              %玩家种族 1神族, {2::人族, 2::当前活动中该人族的暂时种族}, 3魔族
    enter_count = {0, 0},       %神族副本进入次数 魔族副本进入次数
    exploit = 0,                %功勋
    camp_value = 0,             %神魔值，开放该功能由功勋转换
    fight_instance = [],        %一次战争中，该玩家通关的副本积累的奖励
    fight_endtime = 0,          %一次战争的结束时间戳
    select_camp_time = 0,       %人族选择其他种族的时间
    open_instance = {[], []}    %目前已经通关的神族魔族副本Id
}).

%% 神魔系统公共信息表
-record(service_camp_tab,
{
    id = 1,
    is_open = 0,                %0未开启 1开启
    is_fight = 0,               %0备战   1开战
    end_timestamp = 0,          %结束时间
    server_down_time = 0,       %服务器关闭时间
    priv_refresh_time = 0,      %下次进入副本次数刷新时间
    god_camp_point = 0,         %神族战绩值
    magic_camp_point = 0,       %魔族战绩值
    event_list = []             %事件，总计60条
}).

%% 副本信息表
-record(service_camp_instance,
{
    instance_id = 0,            %副本ID
    enemy_player_list = []      %敌方入侵玩家列表
}).

%%-record(camp_ins_cfg, {
%%    scene_id = 0,       %场景ID
%%    war_prize = 0,      %战争奖励
%%    inbreak_prize = 0,  %入侵成功奖励
%%    guard_prize = 0     %防守成功奖励
%%}).

%% 杂项配置表
-record(camp_cfg, {
    enter_count,             %进入敌我双方次数
    refresh_time,            %活动倒计时
    cycle_time,              %自身进入活动次数刷新时间
    add_exploit,             %功勋值获得
    enter_enemy_instance_cost, %入侵消耗百分比
    fight_tie,                 %战平战争奖励比例
    fight_fail,                %战败战争奖励比例
    kill_camp_point            %杀人获得战绩点数
}).
