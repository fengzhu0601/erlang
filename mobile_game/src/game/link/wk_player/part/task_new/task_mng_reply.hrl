%% ?MSG_TASK_ACCEPT  接受任务回复码
-define(REPLY_MSG_TASK_ACCEPT_OK, 0).     %接受任务成功
-define(REPLY_MSG_TASK_ACCEPT_1, 1).     %任务已接受
-define(REPLY_MSG_TASK_ACCEPT_2, 2).     %前置任务未完成
-define(REPLY_MSG_TASK_ACCEPT_3, 3).     %超过任务最大完成次数
-define(REPLY_MSG_TASK_ACCEPT_255, 255).   %接受任务异常

%% ?MSG_TASK_SUBMIT  提交任务回复码
-define(REPLY_MSG_TASK_SUBMIT_OK, 0).     %提交任务成功
-define(REPLY_MSG_TASK_SUBMIT_1, 1).     %提交失败，背包满
-define(REPLY_MSG_TASK_SUBMIT_255, 255).   %提交任务失败


%% ?MSG_TASK_STAR    刷新星级回复码
-define(REPLY_MSG_TASK_STAR_OK, 0).     %刷新星级成功
-define(REPLY_MSG_TASK_STAR_1, 1).     %刷新星级消耗不足
-define(REPLY_MSG_TASK_STAR_2, 2).     %刷新星级次数达到最大
-define(REPLY_MSG_TASK_STAR_255, 255).   %刷新星级异常
