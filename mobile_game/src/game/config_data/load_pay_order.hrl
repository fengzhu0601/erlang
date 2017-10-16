%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 29. 六月 2015 上午11:18
%%%-------------------------------------------------------------------
-author("clark").


%% 订单
-record(pay_order_cfg,
{
    %% 订单号（必须从1开始）
    id,

    %% 购买价格（人民币）
    pay_rmb,

    %% 永久卡VIP
    give_vip,

    %% 值卡VIP等级
    give_card_vip,

    %% 下一等级(没有配置为0）
    next_level,

    %% 钻石
    give_diamond,

    %% 直接返还绑定钻石数
    give_bind_diamond,

    %% 每日返还绑定砖石（仅限月卡，没有配0）
    give_day_bind_diamond,

    %% 期限（按天计算，没有配0）
    limit_day,

    %% 限定购买次数（0为无限，否则为开关Id)
    %state_id,

    state_num = 0,

    %% 订单类型(1,充值卡，2永久，3充值)
    order_type,
    pay_prize_id=0
}).
