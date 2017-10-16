%% 好友模块
%%----------------------------------------------------
%% ?MSG_FRIEND_APPLY 申请添加好友
-define(REPLY_MSG_FRIEND_APPLY_OK, 0).   %% 申请添加好友成功
-define(REPLY_MSG_FRIEND_APPLY_1, 1).   %% 已经是好友了
-define(REPLY_MSG_FRIEND_APPLY_2, 2).   %% 好友数量达到最大值
-define(REPLY_MSG_FRIEND_APPLY_3, 3).   %% 不能添加自己为好友
-define(REPLY_MSG_FRIEND_APPLY_4, 4).   %% 所添加的好友不存在
-define(REPLY_MSG_FRIEND_APPLY_5, 5).   %% 已经申请，请勿重复申请
-define(REPLY_MSG_FRIEND_APPLY_255, 255).   %% 申请添加好友失败，请重试


%%----------------------------------------------------
%% ?MSG_FRIEND_REPLY_APPLY  添加好友回复
-define(REPLY_MSG_FRIEND_REPLY_APPLY_OK, 0).   %% 添加好友回复成功
-define(REPLY_MSG_FRIEND_REPLY_APPLY_1, 1).   %% 已经是好友了
-define(REPLY_MSG_FRIEND_REPLY_APPLY_2, 2).   %% 好友数量达到最大值
-define(REPLY_MSG_FRIEND_REPLY_APPLY_3, 3).   %% 好友申请超时
-define(REPLY_MSG_FRIEND_REPLY_APPLY_255, 255).   %% 添加好友回复异常

%%----------------------------------------------------
%% ?MSG_FRIEND_ASK_FOR_GIFT  索取红包申请 
-define(REPLY_MSG_FRIEND_ASK_FOR_GIFT_OK, 0).   %% 索取红包申请成功
-define(REPLY_MSG_FRIEND_ASK_FOR_GIFT_1, 1).   %% 不能向自己索取红包
-define(REPLY_MSG_FRIEND_ASK_FOR_GIFT_2, 2).   %% 发送红包数量已达上限
-define(REPLY_MSG_FRIEND_ASK_FOR_GIFT_3, 3).   %% 已经领取过礼包
-define(REPLY_MSG_FRIEND_ASK_FOR_GIFT_4, 4).   %% 领取礼包数量已达到上限
-define(REPLY_MSG_FRIEND_ASK_FOR_GIFT_5, 5).   %% 已经申请过
-define(REPLY_MSG_FRIEND_ASK_FOR_GIFT_6, 6).   %% 索取的对象不在线
-define(REPLY_MSG_FRIEND_ASK_FOR_GIFT_255, 255).   %% 索取红包异常

%%----------------------------------------------------
%% ?MSG_FRIEND_REP_ASK_FOR_GIFT  索取红包申请 
-define(REPLY_MSG_FRIEND_REP_ASK_FOR_GIFT_OK, 0).   %% 回复索取红包成功
-define(REPLY_MSG_FRIEND_REP_ASK_FOR_GIFT_1, 1).   %% 发送红包已达上限
-define(REPLY_MSG_FRIEND_REP_ASK_FOR_GIFT_2, 2).   %% 接受红包已达上限
-define(REPLY_MSG_FRIEND_REP_ASK_FOR_GIFT_3, 3).   %% 已经获得红包
-define(REPLY_MSG_FRIEND_REP_ASK_FOR_GIFT_4, 4).   %% 申请已超时
-define(REPLY_MSG_FRIEND_REP_ASK_FOR_GIFT_255, 255).   %% 回复索取红包异常

%%----------------------------------------------------
%% ?MSG_FRIEND_ROB_GIFT   抢红包
-define(REPLY_MSG_FRIEND_ROB_GIFT_OK, 0).   %% 抢红包成功
-define(REPLY_MSG_FRIEND_ROB_GIFT_1, 1).   %% 对方未开启抢红包模式
-define(REPLY_MSG_FRIEND_ROB_GIFT_2, 2).   %% 对方发送红包数量已达上限
-define(REPLY_MSG_FRIEND_ROB_GIFT_3, 3).   %% 接受红包数量已达上限
-define(REPLY_MSG_FRIEND_ROB_GIFT_4, 4).   %% 已经抢过对方红包
%-define(REPLY_MSG_FRIEND_ROB_GIFT_5,    5).   %% 占位 
-define(REPLY_MSG_FRIEND_ROB_GIFT_6, 6).   %% 你这个禽兽居然抢自己的红包
-define(REPLY_MSG_FRIEND_ROB_GIFT_7, 7).   %% 所抢玩家不在线
-define(REPLY_MSG_FRIEND_ROB_GIFT_255, 255). %% 抢红包异常

%%----------------------------------------------------
%% ?MSG_FRIEND_SEND_GIFT  送红包
-define(REPLY_MSG_FRIEND_SEND_GIFT_OK, 0).   %% 送红包成功
-define(REPLY_MSG_FRIEND_SEND_GIFT_1, 1).   %% 发送红包数量已达上限
-define(REPLY_MSG_FRIEND_SEND_GIFT_2, 2).   %% 对方接受红包数量已达上限
-define(REPLY_MSG_FRIEND_SEND_GIFT_3, 3).   %% 已经领取过红包
-define(REPLY_MSG_FRIEND_SEND_GIFT_4, 4).   %%  不能自己给自己发红包哟
-define(REPLY_MSG_FRIEND_SEND_GIFT_5, 5).   %%  所赠送的玩家不在线
-define(REPLY_MSG_FRIEND_SEND_GIFT_255, 255). %% 抢红包异常


%%----------------------------------------------------
%% ?MSG_FRIEND_ACCEPT_SEND_GIFT  接受赠送红包
-define(REPLY_MSG_FRIEND_ACCEPT_SEND_GIFT_OK, 0).   %% 接受赠送红包超时
-define(REPLY_MSG_FRIEND_ACCEPT_SEND_GIFT_1, 1).   %% 接受赠送红包超时
-define(REPLY_MSG_FRIEND_ACCEPT_SEND_GIFT_255, 255). %% 接受赠送红包异常
