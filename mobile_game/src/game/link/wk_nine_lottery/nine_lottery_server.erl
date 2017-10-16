%%-----------------------------------
%% @Module  : nine_lottery_server
%% @Author  : Holtom
%% @Email   : 
%% @Created : 2016.9.19
%% @Description: nine_lottery_server
%%-----------------------------------
-module(nine_lottery_server).
-behaviour(gen_server).

-include("inc.hrl").
-include("load_db_misc.hrl").
-include_lib("pangzi/include/pangzi.hrl").

-define(NINE_LOTTERY_ACTIVITY_ID, 3).
-define(ACTIVITY_STATE_WAIT, 0).
-define(ACTIVITY_STATE_START, 1).
-define(ACTIVITY_STATE_END, 2).
-define(SUPER_PRIZE_INDEX, 5).
-define(MAX_NUM_REF, misc_cfg:get_nine_lottery_max_num()).
-define(nine_lottery_all_log, nine_lottery_all_log).

-define(CHECK_INTEVAL, 5).  %% 检查是否刷新的时间间隔 单位：s

-record(nine_lottery_state, {
    activity_state = 0,         %% 活动状态（0：未开启  1：进行中  2：已结束）
    day = 0,                    %% 活动第几天
    nine_lottery_prize_id = 0,  %% 当前奖池id
    is_real_random = true,      %% 是否真随机
    grid_prize_list = [],       %% 格子奖励列表
    cur_prize_num = 0,          %% 当前奖励份数（不算大奖）
    total_prize_num = 0,        %% 总的奖励份数（不算大奖）
    sup_prize_pro_list = []     %% 假随机时大奖的概率列表
}).

-record(nine_lottery_all_log, {
    id = 0,
    log_list = []
}).

% gen_server callbacks
-export([
        init/1,
        handle_call/3,
        handle_cast/2,
        handle_info/2,
        terminate/2,
        code_change/3
    ]).

%% Module Interface 
-export([
        start_link/0,
        get_nine_lottery_info/0,
        get_nine_lottery_prize/1,
        do_log/1,
        get_all_player_log/0
    ]).

%% =================================================================== 
%% Module Interface
%% ===================================================================
start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

get_nine_lottery_info() ->
    gen_server:call(?MODULE, {'GET_NINE_LOTTERY_INFO'}).

get_nine_lottery_prize(Pro) ->
    gen_server:call(?MODULE, {'GET_NINE_LOTTERY_PRIZE', Pro}).

%% ===================================================================
%% gen_server callbacks
%% ===================================================================
init([]) ->
    com_process:init_name(<<"nine_lottery_server">>),
    com_process:init_type(?MODULE),
    [YearEnd, MonthEnd, DayEnd, HourEnd, MinEnd] = load_cfg_open_server_happy:get_activity_close_time(?NINE_LOTTERY_ACTIVITY_ID),
    SecondEnd = calendar:datetime_to_gregorian_seconds({{YearEnd, MonthEnd, DayEnd}, {HourEnd, MinEnd, 0}}),
    {ActivityState, Day} = case calendar:datetime_to_gregorian_seconds(erlang:localtime()) >= SecondEnd of
        true -> %% 已结束
            {?ACTIVITY_STATE_END, 0};
        _ ->
            [YearBegin, MonthBegin, DayBegin, HourBegin, MinBegin] = load_cfg_open_server_happy:get_activity_begin_time(?NINE_LOTTERY_ACTIVITY_ID),
            StartServerTime = {_, {Hour, Min, Sec}} = load_db_misc:get(?misc_server_start_time, 0),
            SecondStartServer = calendar:datetime_to_gregorian_seconds(StartServerTime),
            case YearBegin =:= 0 orelse calendar:datetime_to_gregorian_seconds({{YearBegin, MonthBegin, DayBegin}, {HourBegin, MinBegin, 0}}) =< SecondStartServer of
                true -> %% 开服开启
                    SecondInteval = calendar:datetime_to_gregorian_seconds(erlang:localtime()) - SecondStartServer,
                    StartDayResSec = (23 - Hour) * 3600 + (59 - Min) * 60 + (59 - Sec),
                    case SecondInteval =< StartDayResSec of
                        true ->
                            {?ACTIVITY_STATE_START, 1};
                        _ ->
                            {?ACTIVITY_STATE_START, (SecondInteval - StartDayResSec) div ?SECONDS_PER_DAY + 2}
                    end;
                _ ->
                    % case calendar:datetime_to_gregorian_seconds({{YearBegin, MonthBegin, DayBegin}, {HourBegin, MinBegin, 0}}) > calendar:datetime_to_gregorian_seconds(erlang:localtime()) of
                    %     true ->
                    %         %% 定时器开启
                    {?ACTIVITY_STATE_WAIT, 0}
            end
    end,
    {NewActivityState, NewDay, NineLotteryPrizeId, IsTrueRand, GridPrize, TotalPrizeNum} = get_new_day_info(ActivityState, Day, 0),
    ProList = misc_cfg:get_nine_lottery_sup_prize_pro(),
    % ?DEBUG_LOG("NewActivityState:~p, NewDay:~p, NineLotteryPrizeId:~p, IsTrueRand:~p, GridPrize:~p, TotalPrizeNum:~p, ProList:~p", [NewActivityState, NewDay, NineLotteryPrizeId, IsTrueRand, GridPrize, TotalPrizeNum, ProList]),
    dbcache:insert_new(?nine_lottery_all_log, #nine_lottery_all_log{}),
    erlang:send_after(?CHECK_INTEVAL * 1000, ?MODULE, {'CHECK_IS_REFLUSH'}), %% 检查是否刷新定时器
    {
        ok,
        #nine_lottery_state{
            activity_state = NewActivityState, day = NewDay, nine_lottery_prize_id = NineLotteryPrizeId, is_real_random = IsTrueRand,
            grid_prize_list = GridPrize, cur_prize_num = TotalPrizeNum, total_prize_num = TotalPrizeNum, sup_prize_pro_list = ProList
        }
    }.

handle_call({'GET_NINE_LOTTERY_INFO'}, _From, #nine_lottery_state{activity_state = ActivityState, grid_prize_list = List} = State) ->
    {reply, {ActivityState =:= ?ACTIVITY_STATE_START, List}, State};
handle_call({'GET_NINE_LOTTERY_PRIZE', Pro}, _From,
    #nine_lottery_state{
        activity_state = ActivityState, day = Day, nine_lottery_prize_id = NineLotteryPrizeId,
        is_real_random = IsTrueRand, grid_prize_list = GridPrizeList, cur_prize_num = CurPrizeNum,
        total_prize_num = TotalPrizeNum, sup_prize_pro_list = ProList
    } = State
) ->
    {Ret, NState} = case ActivityState =/= ?ACTIVITY_STATE_START of
        true ->
            {{error, ActivityState}, State};
        _ ->
            GetIndex = case IsTrueRand of
                true ->
                    NewList = lists:foldl(
                        fun({GridIndex, _PrizeId, Num, Weight}, RetList) ->
                                case Num =:= 0 of
                                    true ->
                                        RetList;
                                    _ ->
                                        [Val1, Val2] = ?MAX_NUM_REF,
                                        NewNum = case Val1 =:= Num of
                                            true -> Val2;
                                            _ -> Num
                                        end,
                                        [{GridIndex, NewNum * Weight} | RetList]
                                end
                        end,
                        [],
                        GridPrizeList
                    ),
                    % NewList = [{GridIndex, Num * Weight} || {GridIndex, _PrizeId, Num, Weight} <- GridPrizeList, Num =/= 0],
                    [Index] = util:get_val_by_weight(NewList, 1),
                    Index;
                _ ->
                    {_, _, SupPrizeNum, _} = lists:keyfind(?SUPER_PRIZE_INDEX, 1, GridPrizeList),
                    case lists:keyfind(SupPrizeNum, 1, ProList) of
                        {_, List} ->
                            {_, NewVal} = lists:max([{Per, Val} || {Per, Val} <- List, CurPrizeNum / TotalPrizeNum >= Per / 1000]),
                            case random:uniform(1000) =< NewVal + Pro of
                                true -> %% 抽中大奖
                                    ?SUPER_PRIZE_INDEX;
                                _ ->    %% 从其他奖励中抽
                                    NewList = lists:foldl(
                                        fun({GridIndex, _PrizeId, Num, Weight}, RetList) ->
                                                case Num =:= 0 orelse GridIndex =:= ?SUPER_PRIZE_INDEX of
                                                    true ->
                                                        RetList;
                                                    _ ->
                                                        [Val1, Val2] = ?MAX_NUM_REF,
                                                        NewNum = case Val1 =:= Num of
                                                            true -> Val2;
                                                            _ -> Num
                                                        end,
                                                        [{GridIndex, NewNum * Weight} | RetList]
                                                end
                                        end,
                                        [],
                                        GridPrizeList
                                    ),
                                    [Index] = util:get_val_by_weight(NewList, 1),
                                    Index
                            end;
                        _ ->
                            ?ERROR_LOG("can not find cfg with super prize num, num = ~p", [SupPrizeNum]),
                            NewList = [{GridIndex, Num * Weight} || {GridIndex, _PrizeId, Num, Weight} <- GridPrizeList, Num =/= 0],
                            [Index] = util:get_val_by_weight(NewList, 1),
                            Index
                    end
            end,
            {_, GetPrizeId, GetNum, GetWeight} = lists:keyfind(GetIndex, 1, GridPrizeList),
            NewState = case GetIndex =:= ?SUPER_PRIZE_INDEX andalso max(GetNum - 1, 0) =:= 0 of
                true ->
                    {NewActivityState, NewDay, NewId, IsTrue, GridPrize, NewTotalPrizeNum} = get_new_day_info(?ACTIVITY_STATE_START, Day, NineLotteryPrizeId),
                    State#nine_lottery_state{
                        activity_state = NewActivityState, day = NewDay, nine_lottery_prize_id = NewId, is_real_random = IsTrue,
                        grid_prize_list = GridPrize, cur_prize_num = NewTotalPrizeNum, total_prize_num = NewTotalPrizeNum
                    };
                _ ->
                    [Val1, _Val2] = ?MAX_NUM_REF,
                    {NewGridPrizeList, NewCurPrizeNum} = case GetNum of
                        Val1 ->
                            {GridPrizeList, CurPrizeNum};
                        _ ->
                            {lists:keyreplace(GetIndex, 1, GridPrizeList, {GetIndex, GetPrizeId, max(GetNum - 1, 0), GetWeight}), CurPrizeNum - 1}
                    end,
                    State#nine_lottery_state{
                        grid_prize_list = NewGridPrizeList,
                        cur_prize_num = NewCurPrizeNum
                    }
            end,
            {{GetIndex =:= ?SUPER_PRIZE_INDEX, GetIndex, GetPrizeId}, NewState}
    end,
    {reply, Ret, NState};

handle_call(_Request, _From, State) ->
    ?ERROR_LOG("receive unknown call msg:~p", [_Request]),
    {reply, ok, State}.

handle_cast(_Msg, State) ->
    ?ERROR_LOG("receive unknown cast msg:~p", [_Msg]),
    {noreply, State}.

handle_info({'CHECK_IS_REFLUSH'}, #nine_lottery_state{activity_state = ActivityState, day = Day} = State) ->
    {_, {H, M, S}} = calendar:local_time(),
    NewState = case H =:= 0 andalso M =:= 0 andalso S < ?CHECK_INTEVAL of
        true ->
            {NewActivityState, NewDay, NewId, IsTrue, GridPrize, NewTotalPrizeNum} = get_new_day_info(ActivityState, Day + 1, 0),
            State#nine_lottery_state{
                activity_state = NewActivityState, day = NewDay, nine_lottery_prize_id = NewId, is_real_random = IsTrue,
                grid_prize_list = GridPrize, cur_prize_num = NewTotalPrizeNum, total_prize_num = NewTotalPrizeNum
            };
        _ ->
            State
    end,
    erlang:send_after(?CHECK_INTEVAL * 1000, ?MODULE, {'CHECK_IS_REFLUSH'}), %% 检查是否刷新定时器
    {noreply, NewState};
handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ?INFO_LOG("process shutdown with reason = ~p", [_Reason]),
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% =====================================================================
%% private
%% =====================================================================
load_db_table_meta() ->
    [
        #db_table_meta{
            name = ?nine_lottery_all_log,
            fields = ?record_fields(?nine_lottery_all_log),
            record_name = ?nine_lottery_all_log,
            shrink_size = 1,
            load_all = false,
            flush_interval = 3
        }
    ].

do_log([]) -> ok;
do_log(List) ->
    case dbcache:load_data(?nine_lottery_all_log, 0) of
        [#nine_lottery_all_log{log_list = LogList} = Tab] ->
            dbcache:update(?nine_lottery_all_log, Tab#nine_lottery_all_log{log_list = LogList ++ List});
        E ->
            ?ERROR_LOG("can not find tab : nine_lottery_all_log error:~p", [E])
    end.

get_all_player_log() ->
    case dbcache:load_data(?nine_lottery_all_log, 0) of
        [#nine_lottery_all_log{log_list = LogList}] ->
            CurNum = length(LogList),
            case CurNum =< 100 of
                true -> LogList;
                _ -> lists:sublist(LogList, CurNum - 100 + 1, 100)
            end;
        _ ->
            []
    end.

get_new_day_info(ActivityState, Day, ExcepeId) ->
    {NewActivityState, NewDay, NineLotteryPrizeId, IsTrueRand, GridPrize} = case ActivityState of
        ?ACTIVITY_STATE_START ->
            case load_nine_lottery_cfg:get_day_prize_info_without_one(Day, ExcepeId) of
                {Id, IsTrue} ->
                    GridPrizeList = load_nine_lottery_cfg:get_grid_prize_list(Id),
                    {?ACTIVITY_STATE_START, Day, Id, IsTrue, GridPrizeList};
                _ ->
                    {?ACTIVITY_STATE_END, Day, 0, false, []}
            end;
        _ ->
            {ActivityState, 0, 0, false, []}
    end,
    TotalPrizeNum = lists:foldl(
        fun({GridIndex, _PrizeId, Num, _Weight}, Count) ->
                [Val1, Val2] = ?MAX_NUM_REF,
                NewNum = case Val1 =:= Num of
                    true -> Val2;
                    _ -> Num
                end,
                case GridIndex =/= ?SUPER_PRIZE_INDEX of
                    true -> Count + NewNum;
                    _ -> Count
                end
        end,
        0,
        GridPrize
    ),
    {NewActivityState, NewDay, NineLotteryPrizeId, IsTrueRand, GridPrize, TotalPrizeNum}.