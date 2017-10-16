%%%-------------------------------------------------------------------
%%% @author lan
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 13. 九月 2016 下午6:40
%%%-------------------------------------------------------------------
-module(auction_new_svr).
-behaviour(gen_server).
-author("lan").

%% API
-export([
	get_auction_all/0,
	get_log_all/0,
	get_start_time_second/0,
	get_turn/0,
	get_open_hour/0,
	get_close_hour/0,
	get_black_shop_is_open/0,
	get_time_out/0,
	add_price/1,
	high_price/1,
	stone_state/0
]).

-export([start_link/0]).
-export([
	init/1,
	handle_call/3,
	handle_cast/2,
	handle_info/2,
	terminate/2,
	code_change/3
]).

-include_lib("pangzi/include/pangzi.hrl").
-include("inc.hrl").
-include("player_eng.hrl").
-include("item_new.hrl").
%%-include("load_db_misc.hrl").
-include("load_black_shop_cfg.hrl").
-include("system_log.hrl").
-include("auction_new.hrl").

-define(black_shop_state, black_shop_state).
-record(state, {
	id = black_shop,
	turn = 0,               %% 涮的次数
	is_open = 0,			%% 1开市，0休市
	end_time = 0           
}).

-define(OPEN, 1).
-define(CLOSE, 0).

-define(pd_auction_turn_count_on_day, pd_auction_turn_cunt_on_day).     %% 拍卖行一天中的拍卖次数


get_black_shop_is_open() ->
	gen_server:call(?MODULE, {get_black_shop_state}).

get_time_out() ->
	%com_time:now() + 99999999.
	gen_server:call(?MODULE, {get_time_out}).

%% 竞拍加价
add_price(CAT) ->
	gen_server:call(?MODULE, {add_price, CAT}).

%% 一口价成交
high_price(CAT) ->
	gen_server:call(?MODULE, {high_price, CAT}).

stone_state() ->
	ok.
	% gen_server:call(?MODULE, {close_server_stone_state}).


start_link() ->
	gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

init([]) ->
    process_flag(trap_exit, ?true),

	init_auction().
	

handle_call({get_black_shop_state}, _From, State) ->
	{reply, State#state.is_open, State};

handle_call({get_time_out}, _From, State) ->
	EndTime = State#state.end_time,
	Turn = State#state.turn,
	%?DEBUG_LOG("Turn---------------------:~p",[Turn]),
	%?DEBUG_LOG("EndTime------------------:~p",[EndTime-com_time:now()]),
	{reply, EndTime, State};

%% 竞拍加价
handle_call({add_price, CAT}, _From, State) ->
	dbcache:update(?com_auction_new_tab, CAT),
	{reply, ok, State};

%% 一口价成交
handle_call({high_price, #com_auction_new_tab{bider_id = BiderId, item = Item}}, _From, State) ->
	%?INFO_LOG("high_price com_auction_tab ~p",[Item]),
	auction_new_mng:bider_win(BiderId, Item),
	{reply, ok, State};


handle_call(_Request, _From, State) ->
	{reply, ok, State}.

handle_cast(_Request, State) ->
	{noreply, State}.

%% 开市 创建拍卖列表
handle_info({start_auction, Turn}, State) ->
	%?DEBUG_LOG("start_auction----------------------:~p",[Turn]),
	notice_system:send_black_shop_start_message(),
	create_auction_list(Turn),
	OpenHour = get_open_hour(),
	%?DEBUG_LOG("OpenHour------------------------:~p",[OpenHour]),
	erlang:send_after(OpenHour * ?MICOSEC_PER_SECONDS, ?MODULE, {end_auction, Turn}),
	{noreply, State#state{turn = Turn, is_open = 1, end_time=com_time:now() + OpenHour}};

%% 开市时间到结算并删除拍卖列表
handle_info({end_auction, Turn}, State) ->
	%?DEBUG_LOG("end_auction----------------------:~p",[Turn]),
	AuctionList = get_auction_all(),
	%% 根据拍卖新列表情况进行数据结算
	case AuctionList of
		[] ->
			?INFO_LOG("auction message is empty");
		_ ->
			handle_auction_timeout(AuctionList)
	end,
	CloseHour = get_close_hour(),
	NewTurn = Turn + 1,

	TodayThisSec = util:get_today_passed_seconds(),

	Ret1 = NewTurn > get_turn() orelse CloseHour + TodayThisSec >= ?SECONDS_PER_DAY,

	case Ret1 of
		true ->
			clear_auction_log(),
			TimeOutSecond = com_time:get_seconds_to_next_day() + get_start_time_second(),
			erlang:send_after(TimeOutSecond * ?MICOSEC_PER_SECONDS, ?MODULE, {start_auction, 1}),
			{noreply, State#state{turn = 1, is_open = 0, end_time=com_time:now() + TimeOutSecond}};
		_ ->
			erlang:send_after(CloseHour * ?MICOSEC_PER_SECONDS, ?MODULE, {start_auction, NewTurn}),
			{noreply, State#state{turn = NewTurn, is_open = 0, end_time=com_time:now() + CloseHour}}
	end;

handle_info(_Info, State) ->
	{noreply, State}.

terminate(_Reason, State) ->
	?DEBUG_LOG("auction_new_svr State ------------------------ ~p", [State]),
	mnesia:dirty_write(?black_shop_state, State),
	ok.

code_change(_OldVsn, State, _Extra) ->
	{ok, State}.

load_db_table_meta() ->
	[
		#db_table_meta{
			name = ?com_auction_new_tab,
			fields = record_info(fields, ?com_auction_new_tab),
			record_name = ?com_auction_new_tab,
			load_all = true,
			shrink_size = 1,
			flush_interval = 3
		},
		#db_table_meta
		{
			name = ?auction_log_tab,
			fields = record_info(fields, ?auction_log_tab),
			record_name = ?auction_log_tab,
			shrink_size = 1,
			flush_interval = 3
		},
		#db_table_meta
		{
			name = ?black_shop_state,
			fields = record_info(fields, state),
			record_name = state,
			load_all = true,
			shrink_size = 1,
			flush_interval = 3
		}
	].




%% 初始化拍卖信息
init_auction() ->
	CurTime = com_time:now(),
	case dbcache:lookup(?black_shop_state, black_shop) of
		[#state{turn=Turn, is_open=0, end_time=EndTime} = S] ->
			?DEBUG_LOG("EndTime---------:~p-------CurTime------:~p",[EndTime, CurTime]),
			if
				CurTime >= EndTime ->
					case is_open() of
						true ->
							erlang:send_after(5 * ?MICOSEC_PER_SECONDS, ?MODULE, {start_auction, Turn}),
							{ok, S};
						_ ->
							first_start_auction()
					end;
				true ->
					T = EndTime - CurTime,
					?DEBUG_LOG("T---------:~p------Turn------:~p",[T, Turn]),
					erlang:send_after(T * ?MICOSEC_PER_SECONDS, ?MODULE, {start_auction, Turn}),
					{ok, S}
			end;
		[#state{turn=Turn, is_open=1, end_time=EndTime} = S] ->
			if
				CurTime >= EndTime ->
					erlang:send_after(5 * ?MICOSEC_PER_SECONDS, ?MODULE, {end_auction, Turn}),
					{ok, S};
				true ->
					T = EndTime - CurTime,
					erlang:send_after(T * ?MICOSEC_PER_SECONDS, ?MODULE, {end_auction, Turn}),
					{ok, S}
			end;
		_ ->
			?DEBUG_LOG("first_start_auction----------------------------------"),
			first_start_auction()
	end.


first_start_auction() ->
	%% 获取当天所过的秒数
	TodaySec = util:get_today_passed_seconds(),
	OpenSec = get_start_time_second(),
	case TodaySec >= OpenSec of
		true ->
			?DEBUG_LOG("1---------------------------------------"),
			S = get_open_hour() + TodaySec,
			if
				S >= ?SECONDS_PER_DAY ->
					TimeOutSecond = com_time:get_seconds_to_next_day() + get_start_time_second(),
 					erlang:send_after(TimeOutSecond * ?MICOSEC_PER_SECONDS, ?MODULE, {start_auction, 1}),
 					{ok, #state{is_open=0, end_time = com_time:now() + TimeOutSecond}};
 				true ->
					erlang:send_after(5 * ?MICOSEC_PER_SECONDS, ?MODULE, {start_auction, 1}),
					{ok, #state{}}
			end;
		_ ->
			EndTime = OpenSec - TodaySec,
			CloseTimeOut = EndTime * ?MICOSEC_PER_SECONDS,
			erlang:send_after(CloseTimeOut, ?MODULE, {start_auction, 1}),
			{ok, #state{is_open=0, end_time=com_time:now() + EndTime}}
	end.


%% 结算拍卖行信息
handle_auction_timeout(AuctionList) ->
	lists:foreach
	(
		fun(
			#com_auction_new_tab{
				id = Id,
				item_state = State,
				bider_id = BiderId,
				item = Item
			}
		) ->
			case BiderId of
				0 ->
					pass;
				_ ->
					case State =:= ?item_auction_ing of
						true ->
							%% 结算
							auction_new_mng:bider_win(BiderId, Item);
						_ ->
							pass
					end
			end,
			%% 删除相应的信息
			dbcache:delete(?com_auction_new_tab, Id)
		end,
		AuctionList
	).


%% 根据拍卖轮数创建本轮的拍卖信息
create_auction_list(Turn) ->
	CfgIdList = load_black_shop_cfg:get_auction_list_by_turn(Turn),
	%% 根据配置的id列表创建拍卖列表
	lists:foreach
	(
		fun(Id) ->
			#black_shop_cfg{
				item = ItemBid,
				num = Num,
				seller = Seller,
				type = Type,
				money_type = MoneyTpye,
				start_price = StartPrize,
				end_price = EndPrize,
				step_price = StepPrize
			} = load_black_shop_cfg:lookup_black_shop_cfg(Id),
			ACT =
				#com_auction_new_tab{
					id = Id,
					item = entity_factory:build(ItemBid, Num, [], ?FLOW_REASON_AUCTION),
					item_type = Type,
					seller = Seller,
					money_type = MoneyTpye,
					start_price = StartPrize,
					high_price = EndPrize,
					step_price = StepPrize,
					cur_price = StartPrize
				},
			 dbcache:insert_new(?com_auction_new_tab, ACT#com_auction_new_tab{item_state = ?item_auction_ing})
		end,
		CfgIdList
	).


%% 获取所有拍卖信息
get_auction_all() ->
	ets:tab2list(?com_auction_new_tab).

%% 获取所有的拍卖行日志信息
get_log_all() ->
	ets:tab2list(?auction_log_tab).


%% 每次休市的持续时间
get_close_hour() ->
	#{end_time := CloseHour} = misc_cfg:get_black_shop_misc(),
	CloseHour * ?SECONDS_PER_HOUR.

%%get_open_hour() -> 0.05.
%% 开市持续的时间
get_open_hour() ->
	#{start_time := OpenHour} = misc_cfg:get_black_shop_misc(),
	OpenHour * ?SECONDS_PER_HOUR.

%% 每天最早的开市时间
get_start_time_second() ->
	#{open_shop_time := {Hour, Min, Sec}} = misc_cfg:get_black_shop_misc(),
	Hour*?SECONDS_PER_HOUR + Min*?SECONDS_PER_MINUTE + Sec.

%% 每天开市的最大次数
get_turn() ->
	#{count_of_day := Count} = misc_cfg:get_black_shop_misc(),
	Count.

is_open() ->
	T = com_time:get_seconds_to_next_day(),
	T2 = get_open_hour(),
	if
		T >= T2 ->
			true;
		true ->
			false
	end.

%% 清除拍卖行的日志信息
clear_auction_log() ->
	LogList = get_log_all(),
	lists:foreach
	(
		fun(#auction_log_tab{id = Id}) ->
			dbcache:delete(?auction_log_tab, Id)
		end,
		LogList
	).