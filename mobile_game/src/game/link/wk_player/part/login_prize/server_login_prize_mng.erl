%%%-------------------------------------------------------------------
%%% @author lan
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 14. 十月 2016 下午5:28
%%%-------------------------------------------------------------------
-module(server_login_prize_mng).
-author("lan").

%% API
-export([]).

-include("load_cfg_open_server_happy.hrl").
-include("handle_client.hrl").
-include("player.hrl").
-include("inc.hrl").
-include_lib("pangzi/include/pangzi.hrl").
-include("server_login_prize.hrl").
-include("system_log.hrl").
-include("load_db_misc.hrl").
-include("player_mod.hrl").
-include("day_reset.hrl").


load_db_table_meta() ->
	[
		#db_table_meta
		{
			name = ?player_server_login_prize_tab,
			fields = ?record_fields(?player_server_login_prize_tab),
			shrink_size = 1,
			flush_interval = 3
		}
	].

load_mod_data(PlayerId) ->
	case dbcache:load_data(?player_server_login_prize_tab, PlayerId) of 
		[] ->
			create_mod_data(PlayerId),
			load_mod_data(PlayerId);
		[#player_server_login_prize_tab{
			get_prize_list = PrizeList,
			zero_time_of_day = ZeroTime,
			login_day = Day
		}] ->
			?pd_new(?pd_server_login_prize_state_list, PrizeList),
			% ?INFO_LOG("-----load_mod_data-----Day = ~p", [Day]),
			NewDay =
				case ZeroTime == com_time:zero_clock_timestamp() of
					true ->
						Day;
					_ ->
						Day + 1
				end,
			?pd_new(?pd_server_login_zero_time, com_time:zero_clock_timestamp()),
			?pd_new(?pd_player_login_server_day, NewDay)
	end,
	ok.

create_mod_data(PlayerId) ->
	AllDay = load_cfg_server_login_prize:get_all_day(),
	StateList = [{Day, ?no_get_prize} || Day <- AllDay, is_integer(Day)],
	case dbcache:insert_new(?player_server_login_prize_tab,
		#player_server_login_prize_tab{
			id = PlayerId,
			get_prize_list = StateList}) of
		?true ->
			ok;
		?false ->
			?ERROR_LOG("insert player_server_login_prize_tab error")
	end,
	ok.

save_data(PlayerId) ->
	SaveTable =
		#player_server_login_prize_tab{
			id = PlayerId,
			get_prize_list = get(?pd_server_login_prize_state_list),
			zero_time_of_day = get(?pd_server_login_zero_time),
			login_day = get(?pd_player_login_server_day)
		},
	dbcache:update(?player_server_login_prize_tab, SaveTable),
	ok.

online() -> ok.

view_data(Acc) -> Acc.

offline(PlayerId) ->
	save_data(PlayerId),
	ok.

handle_frame(_) -> todo.

init_client() ->
	StateList = get(?pd_server_login_prize_state_list),
	% ?INFO_LOG("StateList = ~p",[StateList]),
	ThisDay = get(?pd_player_login_server_day),
	SendList =
		lists:foldl
		(
			fun({Day, State}, Acc) ->
				case Day =< ThisDay andalso State =/= ?is_get_prize of
					true ->
						[{Day, ?can_get_prize} | Acc];  %% 在这里初始化的时候通知前端该奖励是否可以领奖
					_ ->
						[{Day, State} | Acc]
				end
			end,
			[],
			StateList
		),
	% ?INFO_LOG("SendList = ~p", [SendList]),
	?player_send(server_login_prize_sproto:pkg_msg(?MSG_INIT_MESSAGE, {SendList})),
	ok.

handle_client({Pack, Arg}) ->
%%	case task_open_fun:is_open(?OPEN_HAPPY_SERVER) of
%%		?false ->
%%			?return_err(?ERR_NOT_OPEN_FUN);
%%			handle_client(Pack, Arg)
%%	end.
	handle_client(Pack, Arg).


%% 领奖
handle_client(?MSG_GET_PRIZE, {Day}) ->
	% ?INFO_LOG("-----handle_client-----Day = ~p", [Day]),
	Ret = get_prize(Day),
	ReplyNum =
		case Ret of
			{ok, SendList} ->
				?player_send(server_login_prize_sproto:pkg_msg(?MSG_INIT_MESSAGE, {SendList})),
				?SERVER_LOGIN_GET_PRIZE_OK;
			{error, day_error} -> ?SERVER_LOGIN_GET_PRIZE_1;
			{error, not_find_state} -> ?SERVER_LOGIN_GET_PRIZE_2;
			{error, is_get_prize} -> ?SERVER_LOGIN_GET_PRIZE_3;
			_ -> ?SERVER_LOGIN_GET_PRIZE_255
		end,
	% ?INFO_LOG("ReplyNum = ~p", [ReplyNum]),
	?player_send(server_login_prize_sproto:pkg_msg(?MSG_GET_PRIZE, {ReplyNum}));

handle_client(_Msg, _) ->
	{error, unknown_msg}.

handle_msg(_FromMod, _Msg) ->
	{error, unknown_msg}.

%%  日刷新
on_day_reset(_PlayerId) -> 
	% ?INFO_LOG("----------on_day_reset"),
	%%
	Day = get(?pd_player_login_server_day),
	ZeroTime = get(?pd_server_login_zero_time),
	NewDay =
		case ZeroTime =:= com_time:zero_clock_timestamp() of
			true ->
				Day;
			_ ->
				Day + 1
		end,
	put(?pd_player_login_server_day,NewDay),
	put(?pd_server_login_zero_time,com_time:zero_clock_timestamp()),
	init_client(),
	ok.

get_prize(Day) ->
	ThisDay = get(?pd_player_login_server_day),
	% ?INFO_LOG("login_prize ThisDay = ~p", [ThisDay]),
	% ?INFO_LOG("-------------day----------~p",[Day]),
	case lists:member(Day, load_cfg_server_login_prize:get_all_day()) of
		true ->
			case Day =< ThisDay of
				true ->
					StateList = get(?pd_server_login_prize_state_list),
					case lists:keyfind(Day, 1, StateList) of
						{Day, State} ->
							case State =:= ?is_get_prize of
								false ->
									PrizeId = load_cfg_server_login_prize:get_prize(Day),
									{ok, GoodsList} = prize:get_prize(PrizeId),
									case game_res:can_give(GoodsList) of
										ok ->
											game_res:give(GoodsList, ?FLOW_REASON_SERVER_LOGIN);
										_ ->
											prize:prize_mail(PrizeId, ?S_MAIL_SERVER_LOGIN_PRIZE, ?FLOW_REASON_SERVER_LOGIN)
									end,
									%% 设置为被领奖的状态
									NewStateList = lists:keyreplace(Day, 1, StateList, {Day, ?is_get_prize}),
									% ?INFO_LOG("NewStateList = ~p",[NewStateList]),
									put(?pd_server_login_prize_state_list, NewStateList),
									{ok, [{Day, ?is_get_prize}]};
								_ ->
									{error, is_get_prize}
							end;
						_ ->
							{error, not_find_state}
					end;
				_ ->
					{error, day_error}
			end;
		_ ->
			{error, day_error}
	end.
