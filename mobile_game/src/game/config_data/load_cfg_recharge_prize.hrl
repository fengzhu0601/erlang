%%%-------------------------------------------------------------------
%%% @author fengzhu
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 19. 九月 2016 上午10:54
%%%-------------------------------------------------------------------
-author("fengzhu").

%% 累计充值奖励表
-record(recharge_prize_cfg,
{
    id = 0,                 %% 充值奖励Id
    total_recharge = 0,     %% 累计充值金额
    total_prize = 0         %% 累计充值奖励Id
}).


