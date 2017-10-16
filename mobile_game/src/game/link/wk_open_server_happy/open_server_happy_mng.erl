%%%-------------------------------------------------------------------
%%% @author lan
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 02. 九月 2016 下午6:18
%%%-------------------------------------------------------------------
-module(open_server_happy_mng).
-author("lan").


-include_lib("pangzi/include/pangzi.hrl").
-include("open_server_happy.hrl").
-include("inc.hrl").
-include("player_mod.hrl").
-include("handle_client.hrl").
-include("player.hrl").
-include("load_db_misc.hrl").
-include("system_log.hrl").
-include("day_reset.hrl").

-export([
	sync_task/2,
	sync_task/3,
	get_day/0,
	update_gem/2,
	ride_levelup/2
]).

%% 获取统计数据
-export([
	get_day_finish_player_count/0,
	get_all_finish_player_count/0,
	get_prize_player_count/0,
	player_pay_money_count/1
]).

%% 临时存储数据任务数据
-define(pd_sync_task_state, pd_sync_task_state).

load_db_table_meta() ->
	[
		#db_table_meta
		{
			name = ?player_open_server_2_tab,
			fields = ?record_fields(?player_open_server_2_tab),
			shrink_size = 1,
			flush_interval = 3
		}
	].

load_mod_data(PlayerId) ->
	case dbcache:load_data(?player_open_server_2_tab, PlayerId) of
		[] ->
%%			?INFO_LOG("can't find player_open_server_happy_tab playerId:~p", [PlayerId]),
			create_mod_data(PlayerId),
			load_mod_data(PlayerId);
		[#player_open_server_2_tab{
			type_task = TypeTask,
			prize_state_list = PrizeStateList,
			is_get_prize = IsGetPrize,
			is_record_on_day_task_state = OndayState,
			is_record_all_task_state = AllTaskState,
			today_pay_money = Money,
			pay_day_count = DayCount}] ->
			?pd_new(?pd_type_server_happy_task_list, TypeTask),
			?pd_new(?pd_server_happy_get_prize_state, PrizeStateList),
			?pd_new(?pd_server_happy_is_get_prize, IsGetPrize),
			?pd_new(?pd_server_happy_is_record_on_day_task_state, OndayState),
			?pd_new(?pd_server_happy_is_record_all_task_state, AllTaskState),
			?pd_new(?pd_player_pay_money, Money),
			?pd_new(?pd_server_happy_pay_day_count, DayCount)
	end,
	ok.

create_mod_data(PlayerId) ->
	%% 创建任务的列表根据配置表happy_open_task.txt中配置的task_1,task_2,task_3列表
	TaskIdList = load_cfg_open_server_happy:get_task_list(),

%%	?INFO_LOG("TaskIdList = ~p", [TaskIdList]),
	TypeTask =
		lists:foldl
		(
			fun(Id, AccTree) ->
				case get_cfg_task_condition_count(Id) of
					{error, _} ->
						AccTree;
					{Type, _Con} ->
						case gb_trees:lookup(Type, AccTree) of
							?none ->
								gb_trees:insert(Type, [{Id, 0}], AccTree);
							{?value, List} ->
								gb_trees:update(Type, [{Id, 0} | List], AccTree)
						end
				end
			end,
			gb_trees:empty(),
			TaskIdList
		),

	GetPrizeList = [{TaskId, ?task_not_finish, ?init_get_prize_state} || TaskId <- TaskIdList],
	case dbcache:insert_new(?player_open_server_2_tab,
		#player_open_server_2_tab{id = PlayerId, type_task = TypeTask, prize_state_list = GetPrizeList}) of
		?true ->
			ok;
		?false ->
			?ERROR_LOG("insert player_open_server_happy_tab error")
	end,
	ok.

save_data(PlayerId) ->
	SaveTable =
		#player_open_server_2_tab{
			id = PlayerId,
			type_task = get(?pd_type_server_happy_task_list),
			prize_state_list = get(?pd_server_happy_get_prize_state),
			is_get_prize = get(?pd_server_happy_is_get_prize),
			is_record_on_day_task_state = get(?pd_server_happy_is_record_on_day_task_state),
			is_record_all_task_state = get(?pd_server_happy_is_record_all_task_state),
			today_pay_money = get(?pd_player_pay_money),
			pay_day_count = get(?pd_server_happy_pay_day_count)
		},
	dbcache:update(?player_open_server_2_tab, SaveTable),
	ok.

online() -> ok.

view_data(Acc) -> Acc.

offline(PlayerId) ->
	save_data(PlayerId),
	ok.

handle_frame(_) -> todo.

init_client() ->
	Today = get_day(),
	SendTaskList = init_send_task_list(),
%%	?INFO_LOG("Today = ~p", [Today]),
%%	?INFO_LOG("open_server SendTaskList = ~p", [SendTaskList]),
%%	?INFO_LOG("sendList length = ~p", [length(SendTaskList)]),
	?player_send(open_server_happy_sproto:pkg_msg(?MSG_OPEN_SERVER_HAPPY_INIT_CLIENT, {Today, SendTaskList})),
	ok.


handle_client({Pack, Arg}) ->
%%	case task_open_fun:is_open(?OPEN_HAPPY_SERVER) of
%%		?false ->
%%			?return_err(?ERR_NOT_OPEN_FUN);
%%		?true ->
%%			handle_client(Pack, Arg)
%%	end.
	handle_client(Pack, Arg).

%% 领奖
handle_client(?MSG_GET_TASK_PRIZE, {ClientDay, TaskId}) ->
%%	?INFO_LOG("ClientDay = ~p, TaskId = ~p", [ClientDay, TaskId]),
	ReplyNum = get_prize(ClientDay, TaskId),
%%	?INFO_LOG("ReplyNum = ~p", [ReplyNum]),
	%% 领奖成功之后刷新被领奖的数据到前客户端(通过初始化协议)
	case ReplyNum of
		?GET_SERVER_HAPPY_PRIZE_OK ->
			update_get_prize_player_count(),
			SendList = [{TaskId, get_task_num(TaskId), get_task_num(TaskId), ?get_prize_state}],
			?player_send(open_server_happy_sproto:pkg_msg(?MSG_OPEN_SERVER_HAPPY_INIT_CLIENT, {get_day(), SendList}));
		_ ->
			pass
	end,
	?player_send(open_server_happy_sproto:pkg_msg(?MSG_GET_TASK_PRIZE, {ReplyNum})),
	ok;

%% 打开开服狂欢的界面
handle_client(?MSG_OPEN_SERVER_HAPPY_BOARD, {}) ->
%%	?INFO_LOG("test open server happy board"),
	OldCount = load_db_misc:get(?misc_open_server_board_count, 0),
	load_db_misc:set(?misc_open_server_board_count, OldCount + 1),
	ok;


handle_client(_Msg, _) ->
	{error, unknown_msg}.


handle_msg(_FromMod, _Msg) ->
	{error, unknown_msg}.

init_send_task_list() ->
	TaskList = get(?pd_type_server_happy_task_list),
	SendTaskList =
		lists:foldl
		(
			fun({Type, TaskList}, AccList) ->
				%% 判断任务是达成的还是累加的
				case lists:member(Type, ?task_finish_one_ok_list) of
					true ->
						RList =
							lists:map
							(
								fun({Id, FinishNum}) ->
									{_, CfgVal} = get_cfg_task_condition_count(Id),
									IsFinish =
										case lists:member(Type, ?rank_task_one_ok_list) of
											false ->
												Ret =
													case Type =:= ?IS_CROSS_FUBEN of
														true ->
															FinishNum == CfgVal;
														_ ->
															FinishNum >= CfgVal
													end,
												case Ret of
													true ->
														1;
													_ ->
														0
												end;
											_ ->
												case FinishNum =< CfgVal of
													true ->
														is_arena_rank(Type);
													_ ->
														0
												end
										end,
									{Id, get_sync_finish_count(IsFinish, Id), get_task_num(Id), get_prize_state(Id)}
								end,
								TaskList
							),
						RList ++ AccList;
					_ ->
						TList = [{Id, min(get_sync_finish_count(FinishNum, Id), get_task_num(Id)), get_task_num(Id), get_prize_state(Id)} || {Id, FinishNum} <- TaskList],
						TList ++ AccList
				end
			end,
			[],
			gb_trees:to_list(TaskList)
		),
%%	?INFO_LOG("init taskList length = ~p", [length(gb_trees:to_list(TaskList))]),
	SendTaskList.

%%
sync_task(?CROSS_FUBEN_GET_STAR_COUNT, InsId, AllStar) ->
	put(?pd_sync_task_state, {?CROSS_FUBEN_GET_STAR_COUNT, InsId}),
	sync_task(?CROSS_FUBEN_GET_STAR_COUNT, AllStar).
%%	case is_on_date() of
%%		true ->
%%			put(?pd_sync_task_state, {?CROSS_FUBEN_GET_STAR_COUNT, InsId}),
%%			sync_task(?CROSS_FUBEN_GET_STAR_COUNT, AllStar),
%%			ok;
%%		_ ->
%%			pass
%%	end.

%% 根据任务类型相关进度
sync_task(Type, Val) ->
	case is_on_date() of
		true ->
			TaskTypeTree = get(?pd_type_server_happy_task_list),
			case gb_trees:lookup(Type, TaskTypeTree) of
				?none ->
%%				?INFO_LOG("not find Type:~p", [Type]),
					pass;
				{?value, TaskList} ->
					%% 判断任务数值是直接达成还是累加的，如果是达成则根据配置的达成条件进行比较，如果是累加则根据累加之后的结果与配置的数据进行比较
					NewTaskList =
						case lists:member(Type, ?task_finish_one_ok_list) of
							true ->
								set_reach_task(Type, TaskList, Val);
							_ ->
								set_add_reach_task(Type, TaskList, Val)
						end,
					NewTaskTree = gb_trees:update(Type, NewTaskList, TaskTypeTree),
					put(?pd_type_server_happy_task_list, NewTaskTree)
			end;
		_ ->
			pass
	end.


%% 设置根据数据直接达成的任务
set_reach_task(Type, TaskList, Val) ->
%%	?INFO_LOG("TaskList = ~p", [TaskList]),
	{SendList, RetTaskList} =
		lists:foldl
		(
			fun({Id, _FinishNum}, {AccList1, AccList2}) ->
				%% 判断任务所在的天数是否在当前天数内
%%				case load_cfg_open_server_happy:get_day_by_task(Id) =< get_day() of
%%					true ->
						case get_cfg_task_condition_count(Id) of
							{error, _} ->
								{AccList1, AccList2};
							{_Type, CfgVal} ->
								%% 根据数值是否是排行判断条件是否达成
								case lists:member(Type, ?rank_task_one_ok_list) of
									false ->
%%										?INFO_LOG("111111111111111"),
%%										?INFO_LOG("Val = ~p, CfgVal = ~p", [Val, CfgVal]),
										Ret =
											case Type =:= ?IS_CROSS_FUBEN of
												true ->
													Val == CfgVal;
												_ ->
													Val >= CfgVal
											end,
										case Ret of
											true ->
												set_task_finish(Id),
												{[{Id, get_sync_finish_count(1, Id), 1, get_prize_state(Id)} | AccList1], [{Id, Val} | AccList2]};
											_ ->
%%												{[{Id, 0, 1, get_prize_state(Id)} | AccList1],  AccList2}
												{AccList1, AccList2}
										end;
									_ ->
										case Val < CfgVal of
											true ->
												IsOK = is_arena_rank(Type),
												set_task_finish(Id),
												{[{Id, get_sync_finish_count(1, Id), IsOK, get_prize_state(Id)} | AccList1], [{Id, Val} | AccList2]};
											_ ->
%%												{[{Id, 0, 1, get_prize_state(Id)} | AccList1], AccList2}
												{AccList1, AccList2}
										end
								end
						end
%%					_ ->
%%						{AccList1, [{Id, FinishNum} | AccList2]}
%%				end

			end,
			{[], []},
			TaskList
		),
	send_sync_message(SendList),
%%	?INFO_LOG("set List = ~p", [replace_list(TaskList, RetTaskList)]),
%%	?INFO_LOG("SendList = ~p", [SendList]),
	replace_list(TaskList, RetTaskList).

%% 替换掉原列表中的元素
replace_list(List1, List2) ->
	lists:foldl
	(
		fun({Id2, Num2}, AccList) ->
			lists:keystore(Id2, 1, AccList, {Id2, Num2})
		end,
		List1,
		List2
	).

%% 设置累加达成的任务
set_add_reach_task(Type, TaskList, Val) ->
	{SendList, NewTaskList} =
		lists:foldl
		(
			fun({Id, FinishNum}, {AccList1, AccList2}) ->

				%% 充值的任务需要每天都达成
				Ret =
					if
						Type =:= ?CHONGZHI_MONEY_NUM ->
							load_cfg_open_server_happy:get_day_by_task(Id) == get_day();
						true ->
							true
					end,
				%% 判断任务所在的天数是否在当前天数内
				case Ret of
					true ->
						case get_cfg_task_condition_count(Id) of
							{error, _} ->
								{AccList1, AccList2};
							{_Type, CfgVal} ->
								NewFinishNum =
									case lists:member(Type, ?count_reach_list) of
										true ->
											Val;
										_ ->
											case get(?pd_sync_task_state) of
												{RetType, InsId} ->
													case Type =:= RetType of
														true ->
															{_, ConList, _} = load_cfg_open_server_happy:get_task_condition(Id),
															case lists:member(InsId, ConList) of
																true ->
																	FinishNum + Val;
																_ ->
																	FinishNum
															end;
														_ ->
															FinishNum + Val
													end;
												_ ->
													FinishNum + Val
											end
%%									FinishNum + Val
									end,
								case NewFinishNum >= CfgVal of
									true ->
										set_task_finish(Id);
									_ ->
										pass
								end,
								{[{Id, min(get_sync_finish_count(NewFinishNum, Id), CfgVal), CfgVal, get_prize_state(Id)} | AccList1], [{Id, NewFinishNum} | AccList2]}
						end;
					_ ->
						{AccList1, [{Id, FinishNum} | AccList2]}
				end

			end,
			{[], []},
			TaskList
		),
	send_sync_message(SendList),
	NewTaskList.



%% 发送变动的同步信息到客户端
send_sync_message(SendList) ->
	SendMes = {get_day(), SendList},
	?player_send(open_server_happy_sproto:pkg_msg(?MSG_OPEN_SERVER_HAPPY_INIT_CLIENT, SendMes)).

%% 判断是否已经参加了竞技场pk
is_arena_rank(Type) ->
	case Type =:= ?ARENA_RANK of
		true ->
			case attr_new:get(?pd_is_first_p2e_arena, 0) of
				0 ->
					0;
				_ ->
					1
			end;
		_ ->
			1
	end.

%% 领取相应的任务奖励
get_prize(ClientDay, TaskId) ->
	ServerDay = get_day(),
%%	?INFO_LOG("ClientDay = ~p ServerDay = ~p, TaskId = ~p", [ClientDay, ServerDay, TaskId]),
	case ClientDay =< ServerDay of
		true ->
			PrizeList = get(?pd_server_happy_get_prize_state),
			case lists:keyfind(TaskId, 1, PrizeList) of
				{_TaskId, IsFinish, State} ->
%%					?INFO_LOG("State = ~p", [State]),
					case State == ?get_prize_state of
						false ->
							NewPrizeList = lists:keyreplace(TaskId, 1, PrizeList, {TaskId, IsFinish, ?get_prize_state}),
							%% 给奖励
							PrizeID = load_cfg_open_server_happy:get_task_prize(TaskId),
%%							?INFO_LOG("PrizeId = ~p", [PrizeID]),
							{ok, GoodsList} = prize:get_prize(PrizeID),
%%							?INFO_LOG("GoodsList = ~p", [GoodsList]),
							case game_res:can_give(GoodsList) of
								ok ->
									game_res:give(GoodsList, ?FLOW_REASON_OPEN_SERVER_HAPPY);
								_ ->
									%% 背包空间不足发邮件
									prize:prize_mail(PrizeID, ?S_MAIL_SERVER_HAPPY_PRIZE, ?FLOW_REASON_OPEN_SERVER_HAPPY)
							end,
							put(?pd_server_happy_get_prize_state, NewPrizeList),
							?GET_SERVER_HAPPY_PRIZE_OK;
						_ ->
							?GET_PRIZE_ERROR_OF_GET
					end;
				_ ->
					?GET_PRIZE_ERROR_OF_NOFINE
			end;
		_ ->
			?GET_PRIZE_ERROR_OF_DAY
	end.

%% 任务的目标完成数
get_task_num(TaskId) ->
	case get_cfg_task_condition_count(TaskId) of
		{error, _} ->
			?ERROR_LOG("not find TaskId:~p ", [TaskId]),
			10;
		{Type, Count} ->
			case lists:member(Type, ?task_finish_one_ok_list) of
				true ->
					1;
				_ ->
					Count
			end;
		_ ->
			?ERROR_LOG("unknown_type")
	end.

%% 获取配置任务的达成数量
get_cfg_task_condition_count(TaskId) ->
	Val =
		case load_cfg_open_server_happy:get_task_condition(TaskId) of
			{error, Ret} ->
				{error, Ret};
			{Type, CfgVal} ->
				{Type, CfgVal};
			{Type, _Condition, CfgVal} ->
				{Type, CfgVal}
		end,
	Val.

%% 获取活动开启的天数
get_day() ->

	{{Year,Month,Day},{Hour,Min,Sec}} = erlang:localtime(),
	[YearCfg,MonthCfg,DayCfg,HourCfg,MinCfg] = load_cfg_open_server_happy:get_open_server_begin_time(),

	%% 获取现在的秒数
	SecondNow = calendar:datetime_to_gregorian_seconds({{Year,Month,Day},{Hour,Min,Sec}}),

	%% 获取服务器首次开启的时间
	StartServerTime = {_, {SHour, SMin, SSec}}= load_db_misc:get(?misc_server_start_time, 0),
	StartServerSec = calendar:datetime_to_gregorian_seconds(StartServerTime),
	%% 判断配置的开启时间是否是默认时间
	case YearCfg =:= 0 of
		true ->
			%% 计算出当天的剩余时间的秒数
			RetSecond = (23 - SHour)*3600 + (59 - SMin)*60 + (59 - SSec),
			case SecondNow - StartServerSec < RetSecond of
				true ->
					1;
				_ ->
					(SecondNow - StartServerSec - RetSecond) div ?SECONDS_PER_DAY + 2
			end;
		_ ->
			SecondCfg = calendar:datetime_to_gregorian_seconds({{YearCfg,MonthCfg,DayCfg},{HourCfg,MinCfg,0}}),
			case SecondNow < SecondCfg of
				true ->
					0;
				_ ->
					RetSecond = (23 - HourCfg)*3600 + (59 - MinCfg)*60 + 59,
					case SecondNow - SecondCfg < RetSecond of
						true ->
							1;
						_ ->
							(SecondNow - SecondCfg - RetSecond) div ?SECONDS_PER_DAY + 2
					end
			end
	end.

%% 判断活动是否实在规定日期内
is_on_date() ->
	lists:member(get_day(), load_cfg_open_server_happy:get_day_list()).

%% 判断活动是否超时
%%isnt_date_out() ->
%%	[YearCfg,MonthCfg,DayCfg,HourCfg,MinCfg] = load_cfg_open_server_happy:get_open_server_close_time(),
%%	case YearCfg of
%%		0 ->
%%			true;
%%		_ ->
%%			SecondCfg = calendar:datetime_to_gregorian_seconds({{YearCfg,MonthCfg,DayCfg},{HourCfg,MinCfg,0}}),
%%			SecondCfg > com_time:now()
%%	end.

%% 获取任务的完成数量(天数没到完成数量为0)
get_sync_finish_count(FinishCount, TaskId) ->
	TaskDay = load_cfg_open_server_happy:get_day_by_task(TaskId),
	case TaskDay =< get_day() of
		true ->
			FinishCount;
		_ ->
			0
	end.


get_prize_state(TaskId) ->
	PrizeList  = get(?pd_server_happy_get_prize_state),
%%	?INFO_LOG("PrizeList = ~p", [PrizeList]),
	case lists:keyfind(TaskId, 1, PrizeList) of
		{_TaskId, _IsFinish, State1} ->
			State1;
		_ ->
			?ERROR_LOG("TaskId：~p not find state", [TaskId]),
			0
	end.

%% 合成宝石
update_gem(GemLev, Count) ->
	if
		GemLev >= 2 ->
			sync_task(?HECHENG_2_LEVEL_GEM, Count);
		GemLev >= 3 ->
			sync_task(?HECHENG_3_LEVEL_GEM, Count);
		GemLev >= 4 ->
			sync_task(?HECHENG_4_LEVEL_GEM, Count);
		true ->
			pass
	end.

%% 坐骑升级
ride_levelup(_RideId, NewLevel) ->
	sync_task(?UPDATE_RIDE_COUNT, NewLevel).

%% 充钱任务达成(单位:分)
player_pay_money_count(Money) ->
%%	?INFO_LOG("Money: ~p", [Money]),
	OldMoney = attr_new:get(?pd_player_pay_money, 0),
	put(?pd_player_pay_money, OldMoney + Money),
	sync_task(?CHONGZHI_MONEY_NUM, util:floor((OldMoney + Money)/100)),
%%	?INFO_LOG("Money = ~p, Money1 = ~p, OldMoney = ~p, NewM = ~p", [Money, Money1, OldMoney, OldMoney + Money1]),
	if
		Money >= 1 ->
			OldDay = attr_new:get(?pd_server_happy_pay_day_count, 0),
			put(?pd_server_happy_pay_day_count, OldDay+1),
			case attr_new:get(?pd_server_happy_pay_day_count, 0) > ?server_happy_activity_day-1 of		%% 判断连续充值天数配置表定的
				true ->
					sync_task(?PAY_MONEY_LIST, util:floor((Money+OldMoney)/100));
				_ ->
					pass
			end;
		Money > 0 ->
			OldDay = attr_new:get(?pd_server_happy_pay_day_count, 0),
			put(?pd_server_happy_pay_day_count, OldDay+1);
		true ->
			pass
	end,
	ok.

%% private ----------
%% 记录领奖的玩家数量
update_get_prize_player_count() ->
	case attr_new:get(?pd_server_happy_is_get_prize, 0) of
		0 ->
			GetPrizePlayerCount = load_db_misc:get(?misc_open_server_get_prize_player_count, 0),
			load_db_misc:set(?misc_open_server_get_prize_player_count, GetPrizePlayerCount+1),
			put(?pd_server_happy_is_get_prize, 1);
		_ ->
			pass
	end.


%% 设置任务完成状态
set_task_finish(TaskId) ->
	TaskStateList = get(?pd_server_happy_get_prize_state),
	PrizeState =
		case lists:keyfind(TaskId, 1, TaskStateList) of
			{_TaskId, _FinishState, PState} ->
				PState;
			_ ->
				?init_get_prize_state
		end,
	NewStateList = lists:keyreplace(TaskId, 1, TaskStateList, {TaskId, ?task_is_finished, PrizeState}),
	put(?pd_server_happy_get_prize_state, NewStateList),
	%% 记录统计数据
	%% 记录完成全部任务的玩家数量
	FinishCount = erlang:length(lists:filter(fun({_,State, _}) -> State =:= ?task_is_finished end, NewStateList)),
	case FinishCount =:= erlang:length(NewStateList) of
		true ->
			case get(?pd_server_happy_is_record_all_task_state) of
				0 ->
					FinishAllTaskCount = load_db_misc:get(?misc_open_server_finish_all_task_count, 0),
					load_db_misc:set(?misc_open_server_finish_all_task_count, FinishAllTaskCount+1),
					put(?pd_server_happy_is_record_all_task_state, 1);
				_ ->
					pass
			end;
		_ ->
			pass
	end,

	%% 记录开服当天完成全部任务的玩家数量
	OnDayTaskList = load_cfg_open_server_happy:get_onday_task_list(get_day()),
	OnDayList = [{Id, FinishState, PrizeState} || {Id, FinishState, PrizeState} <- TaskStateList, lists:member(Id, OnDayTaskList)],
	FinishCount1 = erlang:length(lists:filter(fun({_, State, _}) -> State =:= ?task_is_finished end, OnDayList)),
	case FinishCount1 =:= erlang:length(OnDayList) of
		true ->
			case get(?pd_server_happy_is_record_on_day_task_state) of
				0 ->
					OnDayCount = load_db_misc:get(?misc_open_server_finish_all_task_on_day_count, 0),
					load_db_misc:set(?misc_open_server_finish_all_task_on_day_count, OnDayCount+1),
					put(?pd_server_happy_is_record_on_day_task_state, 1);
				_ ->
					pass
			end;
		_ ->
			pass
	end.

on_day_reset(_Player) ->
	Count = load_db_misc:get(?misc_open_server_finish_all_task_on_day_count, 0),
	case Count of
		0 ->
			pass;
		_ ->
			load_db_misc:set(?misc_open_server_finish_all_task_on_day_count, 0)
	end,
	put(?pd_server_happy_is_record_on_day_task_state, 0),
	put(?pd_player_pay_money, 0),
	init_client(),
	ok.

%% 获取完成当天所有任务的玩家数量
get_day_finish_player_count() ->
	Count = load_db_misc:get(?misc_open_server_finish_all_task_on_day_count, 0),
	{get_day(), Count}.

%% 获取完成所有任务的玩家数量
get_all_finish_player_count() ->
	Count = load_db_misc:get(?misc_open_server_finish_all_task_count, 0),
	Count.

%% 获取所有参与领奖的玩家数量
get_prize_player_count() ->
	Count = load_db_misc:get(?misc_open_server_get_prize_player_count, 0),
	Count.