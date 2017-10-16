%%%-------------------------------------------------------------------
%%% @author lan
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 02. 九月 2016 下午4:51
%%%-------------------------------------------------------------------
-author("lan").


-record(happy_open_task_cfg,
{
	day = 0,					%% 根据天数来开启相应的任务列表
	task_1 = [],
	task_2 = [],
	task_3 = [],
	task_4 = []
}).

-record(happy_open_task_condition_cfg,
{
	id,							%% 任务id
	condition,
	prize
}).

-record(open_happy_activity_cfg,
{
	id,							%% 1开服狂欢，2赏金任务
	open_time,
	close_time
}).

%% 活动开服ID
-define(OPEN_SERVER_HAPPY_ID, 1). 	%% 开服狂欢id
-define(BOUNTY_TASK_ID, 2).			%% 赏金任务Id
-define(RECHARGE_REWARD_ID, 4).		%% 充值满额送礼Id
-define(POWER_RANKING_LIST_ID, 6).  %% 战力排行榜Id
-define(RIDE_RANKING_LIST_ID, 7).   %% 坐骑排行榜Id
-define(PET_RANKING_LIST_ID, 8).    %% 宠物排行榜Id
-define(SUIT_RANKING_LIST_ID, 9).   %% 套装排行榜Id
-define(ABYSS_RANKING_LIST_ID, 10). %% 深渊排行榜Id
-define(GUILD_RANKING_LIST_ID, 11). %% 公会排行榜Id