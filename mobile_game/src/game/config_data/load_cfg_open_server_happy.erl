%%%-------------------------------------------------------------------
%%% @author lan
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 02. 九月 2016 下午4:51
%%%-------------------------------------------------------------------
-module(load_cfg_open_server_happy).
-author("lan").

%% API
-export([
	get_task_list/0,
	get_day_list/0,
	get_open_server_begin_time/0,
	get_open_server_close_time/0,
	get_task_condition/1,
	get_task_prize/1,
	get_activity_time_by_id/1,
	is_in_activity_period/1,
    the_activity_is_over/1,
    get_activity_over_time_by_id/1,
    get_activity_begin_time/1,
    get_activity_close_time/1,
	get_onday_task_list/1,
	get_day_by_task/1
]).

-include_lib("config/include/config.hrl").
-include("inc.hrl").
-include("load_cfg_open_server_happy.hrl").

load_config_meta() ->
	[
		#config_meta
		{
			record = #happy_open_task_cfg{},
			fields = ?record_fields(happy_open_task_cfg),
			file = "happy_open_task.txt",
			keypos = #happy_open_task_cfg.day,
			all = [#happy_open_task_cfg.day],
			verify = fun verify_happy_open_task_cfg/1
		},
		#config_meta
		{
			record = #happy_open_task_condition_cfg{},
			fields = ?record_fields(happy_open_task_condition_cfg),
			file = "happy_open_task_condition.txt",
			keypos = #happy_open_task_condition_cfg.id,
			verify = fun verify_happy_open_task_condition_cfg/1
		},
		#config_meta
		{
			record = #open_happy_activity_cfg{},
			fields = ?record_fields(open_happy_activity_cfg),
			file = "open_happy_activity.txt",
			keypos = #open_happy_activity_cfg.id,
			verify = fun verify_open_happy_activity_cfg/1
		}
	].

verify_happy_open_task_cfg(#happy_open_task_cfg{day = Day, task_1 = List1, task_2 = List2, task_3 = List3, task_4 = List4}) ->
	lists:foreach
	(
		fun(TaskId) ->
			?check(is_exist_happy_open_task_condition_cfg(TaskId),
				"day:[~p] 任务id:~p 在happy_open_task_condition.txt 表中找不到 task_1:~p", [Day, TaskId, List1])
		end,
		List1
	),
	lists:foreach
	(
		fun(TaskId) ->
			?check(is_exist_happy_open_task_condition_cfg(TaskId),
				"day:[~p] 任务id:~p 在happy_open_task_condition.txt 表中找不到 task_2:~p", [Day, TaskId, List2])
		end,
		List2
	),
	lists:foreach
	(
		fun(TaskId) ->
			?check(is_exist_happy_open_task_condition_cfg(TaskId),
				"day:[~p] 任务id:~p 在happy_open_task_condition.txt 表中找不到 task_3:~p", [Day, TaskId, List3])
		end,
		List3
	),
	lists:foreach
	(
		fun(TaskId) ->
			?check(is_exist_happy_open_task_condition_cfg(TaskId),
				"day:[~p] 任务id:~p 在happy_open_task_condition.txt 表中找不到 task_4:~p", [Day, TaskId, List4])
		end,
		List4
	),
	ok.

verify_happy_open_task_condition_cfg(#happy_open_task_condition_cfg{id = Id, prize = PrizeId}) ->
	?check(prize:is_exist_prize_cfg(PrizeId),
		"happy_open_task_condition.txt id:[~p] 奖励id:~p 在配置表 prize.txt 中没有找到", [Id, PrizeId]),
	ok.

verify_open_happy_activity_cfg(#open_happy_activity_cfg{open_time = OpenTime, close_time = CloseTime}) ->
	?check(erlang:length(OpenTime) == 5, "open_happy_activity.txt open_time 格式不正确 ~p", [OpenTime]),
	?check(erlang:length(CloseTime) == 5, "open_happy_activity.txt close_time 格式不正确 ~p", [CloseTime]),
	ok.



get_task_list() ->
	TaskList =
	lists:foldl
	(
		fun(Day, AccList) ->
			Task1 = get_task_1(Day),
			Task2 = get_task_2(Day),
			Task3 = get_task_3(Day),
			Task4 = get_task_4(Day),
			Task1 ++ Task2 ++ Task3 ++ Task4 ++ AccList
		end,
		[],
		get_day_list()
	),
%%	?INFO_LOG("TaskList:~p", [TaskList]),
%%	?INFO_LOG("DayList = ~p", [get_day_list()]),
	TaskList.

%% 获得当天的任务列表
get_onday_task_list(Day) ->
	get_task_1(Day) ++ get_task_2(Day) ++ get_task_3(Day) ++ get_task_4(Day).

get_day_list() ->
	[Day || Day <- lookup_all_happy_open_task_cfg(#happy_open_task_cfg.day), is_integer(Day)].


get_task_1(Day) ->
	case lookup_happy_open_task_cfg(Day) of
		#happy_open_task_cfg{task_1 = List} ->
			List;
		_ ->
			{error, unknown_type}
	end.

get_task_2(Day) ->
	case lookup_happy_open_task_cfg(Day) of
		#happy_open_task_cfg{task_2 = List} ->
			List;
		_ ->
			{error, unknown_type}
	end.

get_task_3(Day) ->
	case lookup_happy_open_task_cfg(Day) of
		#happy_open_task_cfg{task_3 = List} ->
			List;
		_ ->
			{error, unknown_type}
	end.

get_task_4(Day) ->
	case lookup_happy_open_task_cfg(Day) of
		#happy_open_task_cfg{task_4 = List} ->
			List;
		_ ->
			{error, unknown_type}
	end.

%% 获取当前任务时哪一天的
get_day_by_task(TaskId) ->
	DayList =
		lists:foldl
		(
			fun(Day, AccList) ->
				DayTaskList = get_onday_task_list(Day),
				case lists:member(TaskId, DayTaskList) of
					true ->
						[Day | AccList];
					_ ->
						AccList
				end
			end,
			[],
			get_day_list()
		),
	[TaskDay|_] = DayList,
	TaskDay.




get_open_server_begin_time() ->
	case lookup_open_happy_activity_cfg(?OPEN_SERVER_HAPPY_ID) of
		#open_happy_activity_cfg{open_time = OpenTime} ->
			OpenTime;
		_ ->
			{error, unknown_type}
	end.

get_open_server_close_time() ->
	case lookup_open_happy_activity_cfg(?OPEN_SERVER_HAPPY_ID) of
		#open_happy_activity_cfg{close_time = CloseTime} ->
			CloseTime;
		_ ->
			{error, unknown_type}
	end.

%% 获取活动的开启和结束时间
get_activity_time_by_id(ActivityId) ->
	case lookup_open_happy_activity_cfg(ActivityId) of
		#open_happy_activity_cfg{ open_time = OpenTime, close_time = CloseTime} ->
			{ OpenTime, CloseTime };
		_ ->
			{error, unknown_type}
	end.
get_activity_over_time_by_id(ActivityId) ->
	case lookup_open_happy_activity_cfg(ActivityId) of
		#open_happy_activity_cfg{ close_time = CloseTime} ->
			CloseTime;
		_ ->
			{error, unknown_type}
	end.

%% 获取任务的触发条件
get_task_condition(TaskId) ->
	case lookup_happy_open_task_condition_cfg(TaskId) of
		#happy_open_task_condition_cfg{condition = Condition} ->
			Condition;
		_ ->
			{error, unknown_type}
	end.

%% 获取配置的任务奖励列表
get_task_prize(TaskId) ->
	case lookup_happy_open_task_condition_cfg(TaskId) of
		#happy_open_task_condition_cfg{prize = Prize} ->
			Prize;
		_ ->
			{error, unknown_type}
	end.

get_activity_begin_time(Id) ->
	case lookup_open_happy_activity_cfg(Id) of
		#open_happy_activity_cfg{open_time = OpenTime} ->
			OpenTime;
		_ ->
			{error, unknown_type}
	end.

get_activity_close_time(Id) ->
	case lookup_open_happy_activity_cfg(Id) of
		#open_happy_activity_cfg{close_time = CloseTime} ->
			CloseTime;
		_ ->
			{error, unknown_type}
	end.

%% 判断是否在活动期间
is_in_activity_period(Id) ->
	{[Y1,M1,D1,H1,Mi1],[Y2,M2,D2,H2,Mi2]} = get_activity_time_by_id(Id),
	CurTime = calendar:local_time(),
	BeginTime = {{Y1,M1,D1},{H1,Mi1,0}},
	CloseTime = {{Y2,M2,D2},{H2,Mi2,0}},
	CurTime >= BeginTime andalso CurTime =< CloseTime.

%% 判断活动是否已经结束
the_activity_is_over(Id) ->
	[Y,M,D,H,Mi] = get_activity_over_time_by_id(Id),
    CloseTime = {{Y,M,D},{H,Mi,0}},
    CurTime = calendar:local_time(),
    CurTime =< CloseTime.
