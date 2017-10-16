%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 31. 七月 2015 下午9:03
%%%-------------------------------------------------------------------
-author("clark").




%% VIP权限
-record(pay_prize_cfg,
{
    %% 功能ID
    id = 0,

    %% 开关ID
    state_id = 0,

    %% 类型(1, 首冲；2，成长基金购买；3，领取成长基金；4, 每日消费；5累计消费）
    type = 0,

    %% 首冲奖励ID
    first_prize = 0,

    %% 首冲奖励（prize表ID）
    grow_up_price = 0,

    %% 成长基金价格（人民币）
    grow_up_prize = 0,

    %% 成长基金领取等级
    grow_up_lvl = 0,

    %% 每日消费数（钻石）
    day_cost = 0,

    %% 每日消费奖励id（prize表ID)
    day_prize = 0,

    %% 累计消费数(钻石）
    total_cost = 0,

    %% 累计消费奖励id（prize表ID）
    total_prize = 0
}).
