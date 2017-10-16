%%%-------------------------------------------------------------------
%%% @author fengzhu
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 18. 九月 2016 下午5:03
%%%-------------------------------------------------------------------
-author("fengzhu").

%% 玩家开服充值奖励表,保存到数据库
-define(player_recharge_reward_tab, player_recharge_reward_tab).
-record(player_recharge_reward_tab,
{
    id = 0,
    recharge = 0,       %% 玩家累计充值金额
    reward_status = []  %% 各级奖励的状态  [{1,0},{2,0},{3,0}]
}).


-define(REWARD_STATUS_0, 0).  %% 不能领取
-define(REWARD_STATUS_1, 1).  %% 可以领取
-define(REWARD_STATUS_2, 2).  %% 已经领取

%% 领取累计充值奖励返回吗
-define(REPLY_MSG_RECHARGE_PRIZE_OK, 0).      %% 领取奖励成功
-define(REPLY_MSG_RECHARGE_PRIZE_1, 1).       %% 找不到Id
-define(REPLY_MSG_RECHARGE_PRIZE_2, 2).       %% 领取奖励失败
-define(REPLY_MSG_RECHARGE_PRIZE_255, 255).   %% 未知错误
