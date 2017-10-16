%% ?MSG_ARENA_MATCH
-define(REPLY_MSG_ARENA_MATCH_OK, 0).       %% 匹配成功
-define(REPLY_MSG_ARENA_MATCH_1, 1).       %% 正在匹配请勿重复匹配（已经有队伍了
-define(REPLY_MSG_ARENA_MATCH_2, 2).       %% 参加次数超过最大次数
-define(REPLY_MSG_ARENA_MATCH_3, 3).       %% p2p活动尚未开始
-define(REPLY_MSG_ARENA_MATCH_4, 4).       %% multi_p2p活动尚未开始
-define(REPLY_MSG_ARENA_MATCH_255, 255).     %% 匹配异常

%% ?MSG_ARENA_TRUN
-define(REPLY_MSG_ARENA_TRUN_OK, 0).       %% 抽奖成功
-define(REPLY_MSG_ARENA_TRUN_1, 1).       %% 荣耀不足
-define(REPLY_MSG_ARENA_TRUN_255, 255).     %% 抽奖异常

%% ?MSG_ARENA_COMPETE
-define(REPLY_MSG_ARENA_COMPETE_OK, 0). %%同意切磋
-define(REPLY_MSG_ARENA_COMPETE_1, 1). %%拒绝切磋
-define(REPLY_MSG_ARENA_COMPETE_2, 2). %%对方当前无法切磋
-define(REPLY_MSG_ARENA_COMPETE_3, 3). %%对方未响应邀请
-define(REPLY_MSG_ARENA_COMPETE_255, 255). %% 未知
