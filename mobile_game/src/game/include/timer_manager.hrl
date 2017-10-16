-define(timer_manager_dict, timer_manager_dict). %存储目前的倒计时
-define(timer_manager_tick, timer_manager_tick). %固定倒计时，每隔10s倒计时一次
-define(timer_manager_prepare_tick, timer_manager_prepare_tick). %活动准备公告倒计时

-define(timer_manager_cfg, timer_manager_cfg).
-record(timer_manager_cfg, {
    id = 0,
    activity_key = 0,            %活动关联模块
    activity_launch = 0,         %活动开始时间,0表示永久
    activity_close = 0,          %活动截止日期,0表示永久
    period = 0,                   %周期 1月 2周 3天
    cycle_time = 0,               %每次活动开始时间
    prepare_start_time_set = 0,  %开始前公告播放设置({提前多少秒播放，每隔多少秒播放})
    prepare_start_notice = [],  %开始前公告
    start_notice = [],          %开始公告
    prepare_finish_time_set = 0, %结束前公告播放设置({提前多少秒播放，每隔多少秒播放})
    prepare_finish_notice = [], %结束前公告
    finish_notice = []         %结束公告
}).
% 中途关掉跑马灯(例外情况)，开关的广播 活动提前结束
-define(timer_tick_tab, timer_tick_tab). %维护处于开放中的活动内存表
-define(TIMER_MANAGER_TICK_S, 10).
-define(TIMER_MANAGER_TICK, ?TIMER_MANAGER_TICK_S * 1000). %心跳倒计时
-define(TIMER_SUM_TIME(Hour, Minite, Second), ((Hour * 60 * 60) + (Minite * 60) + Second)). %{时分秒}转化为秒数
-define(timer_period_month, 1). %按月循环
-define(timer_period_week, 2).  %按周循环
-define(timer_period_day, 3).   %按天循环

-define(timer_sky_service, timer_sky_service).  %天空之城活动定时器

-define(timer_rpc, [
    {?timer_sky_service, {sky_service, do_open, {}}}
]).