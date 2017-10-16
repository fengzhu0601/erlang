%% 卡片模块的回复码定义
%%----------------------------------------------------
%% ?MSG_CARD_AWARD 抽奖
-define(REPLY_MSG_CARD_AWARD_OK, 0).      %% 抽奖成功
-define(REPLY_MSG_CARD_AWARD_1, 1).      %% 抽奖失败，扣除物品失败
-define(REPLY_MSG_CARD_AWARD_255, 255).    %% 抽奖异常
