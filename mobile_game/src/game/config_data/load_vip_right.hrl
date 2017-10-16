%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 27. 六月 2015 下午6:32
%%%-------------------------------------------------------------------
-author("clark").



%% VIP权限
-record(vip_right_cfg,
{
    %% VIP等级
    id,

    %% 充值底限（当前等级的砖石数）
    base_diamond = 0,

    %% 特权奖励(prize表ID）
    vip_prize_id = 0,

    %% 扫荡特权（副本结算未达到三星是否可扫荡，1是，0否）
    auto_fight_limit = 0,

    %% 购买体力次数
    buy_power_limit = 0,

    %% 登陆奖励所获得的货币类为普通用户的百分比（百分比）
    login_prize_rate = 0,

    %% 抽奖所扣钻石
    dial_prize_diamond = 0,

    %% 领奖开关
    state_id = 0,

    daily_activity_1 = [], %日常活动守卫美人鱼公主挑战次数[消耗钻石数量]
    daily_activity_2 = [], %日常活动桑尼号挑战次数[消耗钻石数量]
    daily_activity_3 = [], %日常活动时空裂缝挑战次数[消耗钻石数量]
    abyss_enter = [],          %挑战次数[消耗钻石数量]
    abyss_reset = [],          %虚空深渊重置次数
    relive = [],               %一次副本复活次数
    add_hp_limit = [],         %一次副本加血次数
    vip_buy_sp = [],            %购买体力次数
%%     task_daily_cost=[]       %每日任务刷新消耗
    buy_arena_challeng = 0,
    alchemy_cost_diamond = [],
    boos_challenges = [],
    boss_challenge_flush = [],
    main_ins_shop_times,
    abyss_integral = 0,
    equipcompound_locknum = []
}).

