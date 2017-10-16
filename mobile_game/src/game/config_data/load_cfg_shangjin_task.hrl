%%%-------------------------------------------------------------------
%%% @author fengzhu
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 01. 九月 2016 下午8:07
%%%-------------------------------------------------------------------
-author("fengzhu").

%% 赏金任务列表
-record(bounty_task_cfg,
{
    id = 0,         %% 任务id
    condition,      %% 任务条件
    level,          %% 任务可随机的等级区间
    prize = 0,      %% 任务完成后奖励
    weight = 0,     %% 随机任务的权值
    integral = 0    %% 完成任务获得的活跃度
}).

-record(bounty_task_rank_cfg,
{
    id = 0,     %% 赏金任务排名
    prize = 0   %% 奖励Id
}).
