-define(player_daily_tab, player_daily_tab).
-define(daily_activity_cfg, daily_activity_cfg).

-define(player_fishing_daily_tab, player_fishing_daily_tab).
%%-define(DailyType_1, 1).
%%-define(DailyType_2, 2).
%%-define(DailyType_3, 3).

-define(DailyType_1_Scene_Id, 26).
-define(DailyType_2_Scene_Id, 27).

-define(DailyFightIns, 4). %4个boss场景

-define(DAILYTYPE_2_POINT_LIST, lists:nth(1, misc_cfg:get_misc_cfg(daily_activity))).
-define(DAILYTYPE_4_POINT_LIST, lists:nth(2, misc_cfg:get_misc_cfg(daily_activity))).
-define(DAILYTYPE_5_POINT_LIST, lists:nth(3, misc_cfg:get_misc_cfg(daily_activity))).
-define(DAILYTYPE_1_MAX_WAVE, lists:nth(4, misc_cfg:get_misc_cfg(daily_activity))).
-define(DAILYTYPE_2_TIMEOUT, lists:nth(5, misc_cfg:get_misc_cfg(daily_activity))).

-record(player_daily_tab, {
    player_id = 0,
    activity_data = []
}).

%% 每个活动的详细信息
-record(daily_data, {
    daily_id = 0,
    daily_fight_count = 0, %每日已经免费进入次数
    daily_pay_count = 0,   %每日已经付费进入次数
    daily_buy_count = 0,   %每日购买的次数
    last_time = 0,			% 上一次挑战时间
    daily_asset = 0,       %该日常活动存储的数据，积分、到达的最大层数
    ex = []               	% 扩展字段，目前存放时空隙缝的boss击杀顺序
}).

-record(player_fishing_daily_tab, {
    player_id = 0,
    fish_bait = 0,      %% 剩余鱼饵个数
    buy_fish_bait = 0,  %% 购买鱼饵的次数
    fish_net = 0,       %% 渔网捕鱼次数
    fishing_id = 0      %% 钓鱼活动区间
}).

-define(service_fishing_instance, service_fishing_instance).

%% 钓鱼副本信息表
-record(service_fishing_instance,
{
    instance_id = 0,            %钓鱼副本ID
    player_list = []            %副本中的玩家列表
}).

-define(FISH_ROOM_MAX_PLAYER_COUNT, 30).

