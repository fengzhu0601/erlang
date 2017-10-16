%%-----------------------------------
%% @Module  : honest_user_mng
%% @Author  : Holtom
%% @Email   : 
%% @Created : 2016.4.27
%% @Description: 忠实用户模块
%%-----------------------------------
-module(honest_user_mng).

-export([
	is_change_level_prize_state/1,
	is_change_suit_prize_state/0
]).

-include("inc.hrl").
-include("game.hrl").
-include("player.hrl").
-include("player_mod.hrl").
-include("handle_client.hrl").
-include_lib("pangzi/include/pangzi.hrl").
-include("operating_activity.hrl").
-include("rank.hrl").
-include("load_honest_user_cfg.hrl").
-include("system_log.hrl").

create_mod_data(SelfId) ->
    case dbcache:insert_new(?player_honest_user_tab, #player_honest_user_tab{id = SelfId}) of
        ?true -> ok;
        ?false ->
            ?ERROR_LOG("player ~p create new player_honest_user_tab not alread exists ", [SelfId])
    end,
    ok.

load_mod_data(PlayerId) ->
    case dbcache:load_data(?player_honest_user_tab, PlayerId) of
        [] ->
            ?ERROR_LOG("player ~p can not find player_honest_user_tab mode", [PlayerId]),
            create_mod_data(PlayerId),
            load_mod_data(PlayerId);
        [#player_honest_user_tab{level_prize_state = State1, suit_prize_state = State2}] ->
            put(level_prize_state, State1),
            put(suit_prize_state, State2),
            ok
    end,
    ok.

init_client() ->
    ignore.

view_data(Msg) ->
    Msg.

handle_frame(_) -> ok.

online() ->
	State1 = get(level_prize_state),
	State2 = get(suit_prize_state),
	case State1 =:= ?CAN_GET orelse State2 =:= ?CAN_GET of
		true ->
			?player_send(honest_user_sproto:pkg_msg(?MSG_HONEST_USER_GET_INFO, {State1, State2}));
		_ ->
			ignore
	end.

offline(PlayerId) ->
	save_data(PlayerId),
    ok.

save_data(PlayerId) ->
	State1 = get(level_prize_state),
	State2 = get(suit_prize_state),
	NewTab = #player_honest_user_tab{id = PlayerId, level_prize_state = State1, suit_prize_state = State2},
	dbcache:update(?player_honest_user_tab, NewTab),
	ok.

load_db_table_meta() ->
    [
        #db_table_meta{
            name = ?player_honest_user_tab,
            fields = ?record_fields(?player_honest_user_tab),
            record_name = ?player_honest_user_tab,
            shrink_size = 1,
            load_all = false,
            flush_interval = 3
        }
    ].

handle_client({Pack, Arg}) ->
	handle_client(Pack, Arg).

handle_client(?MSG_HONEST_USER_GET_INFO, {}) ->
	State1 = get(level_prize_state),
	State2 = get(suit_prize_state),
	% SuitInfo = api:get_player_suit_info(),
	% Suit1 = tuple_to_list(lists:nth(1, SuitInfo)),
	% Suit2 = tuple_to_list(lists:nth(2, SuitInfo)),
	% Suit3 = tuple_to_list(lists:nth(3, SuitInfo)),
	% Suit4 = tuple_to_list(lists:nth(4, SuitInfo)),
	?player_send(honest_user_sproto:pkg_msg(?MSG_HONEST_USER_GET_INFO, {State1, State2}));

handle_client(?MSG_HONEST_USER_GET_PRIZE, {Index}) ->
	[PrizeId] = case load_honest_user_cfg:lookup_honest_user_cfg(Index) of
		Cfg when is_record(Cfg, honest_user_cfg) ->
			Cfg#honest_user_cfg.prize_test1;
		_ ->
			?ERROR_LOG("can't find prize :~p", [Index])
	end,
	?DEBUG_LOG("PrizeId:~p", [PrizeId]),
	case Index of
		?LEVEL_ACTIVITY_INDEX ->
			State = get(level_prize_state),
			case State =:= ?CAN_GET of
				true ->
					case prize:prize_mail(PrizeId, ?S_MAIL_LEVEL_PRIZE, ?FLOW_REASON_HONEST_USER) of
						List when is_list(List) ->
							?player_send(honest_user_sproto:pkg_msg(?MSG_HONEST_USER_GET_PRIZE, {Index, ?GET_PRIZE_SUCC})),
							put(level_prize_state, ?HAS_GOT);
						E ->
							?player_send(honest_user_sproto:pkg_msg(?MSG_HONEST_USER_GET_PRIZE, {Index, ?GET_PRIZE_FAIL})),
							?ERROR_LOG("send prize error : ~p", [E])
					end;
				_ ->
					?player_send(honest_user_sproto:pkg_msg(?MSG_HONEST_USER_GET_PRIZE, {Index, ?GET_PRIZE_FAIL})),
					?ERROR_LOG("get prize error with State:~p", [State])
			end;
		?SUIT_ACTIVITY_INDEX ->
			State = get(suit_prize_state),
			case State =:= ?CAN_GET of
				true ->
					case prize:prize_mail(PrizeId, ?S_MAIL_LEVEL_PRIZE, ?FLOW_REASON_HONEST_USER) of
						List when is_list(List) ->
							?player_send(honest_user_sproto:pkg_msg(?MSG_HONEST_USER_GET_PRIZE, {Index, ?GET_PRIZE_SUCC})),
							put(suit_prize_state, ?HAS_GOT);
						E ->
							?player_send(honest_user_sproto:pkg_msg(?MSG_HONEST_USER_GET_PRIZE, {Index, ?GET_PRIZE_FAIL})),
							?ERROR_LOG("send prize error : ~p", [E])
					end;
				_ ->
					?player_send(honest_user_sproto:pkg_msg(?MSG_HONEST_USER_GET_PRIZE, {Index, ?GET_PRIZE_FAIL})),
					?ERROR_LOG("get prize error with State:~p", [State])
			end
	end;

handle_client(_Mod, _Msg) ->
    ?err(notmatch).

handle_msg(FromMod, Msg) ->
    ?ERROR_LOG("~p recv a unknown msg ~p from ~p", [?pname(), Msg, FromMod]).

is_change_level_prize_state(Level) ->
	State1 = get(level_prize_state),
	State2 = get(suit_prize_state),
	NewState = case State1 =:= ?CANT_GET andalso Level >= 40 of
		true ->
			player_data_db:update_level_prize_times(),
			?player_send(honest_user_sproto:pkg_msg(?MSG_HONEST_USER_GET_INFO, {?CAN_GET, State2})),
			?CAN_GET;
		_ ->
			State1
	end,
	put(level_prize_state, NewState).

is_change_suit_prize_state() ->
	State1 = get(level_prize_state),
	State2 = get(suit_prize_state),
	% Condition = case load_honest_user_cfg:lookup_honest_user_cfg(?SUIT_ACTIVITY_INDEX) of
	% 	Cfg when is_record(Cfg, honest_user_cfg) ->
	% 		Cfg#honest_user_cfg.condition;
	% 	_ ->
	% 		100
	% end,
	SuitInfo = api:get_player_suit_info(),
	NewState = case size(lists:nth(1, SuitInfo)) =:= 6 andalso size(lists:nth(2, SuitInfo)) =:= 6
	andalso size(lists:nth(3, SuitInfo)) =:= 6 andalso size(lists:nth(4, SuitInfo)) =:= 6 of
		true ->
			case State2 of
				?CANT_GET ->
					player_data_db:add_suit_prize_times(),
					?player_send(honest_user_sproto:pkg_msg(?MSG_HONEST_USER_GET_INFO, {State1, ?CAN_GET})),
					?CAN_GET;
				_ ->
					State2
			end;
		_ ->
			case State2 of
				?CAN_GET ->
					player_data_db:reduce_suit_prize_times(),
					?player_send(honest_user_sproto:pkg_msg(?MSG_HONEST_USER_GET_INFO, {State1, ?CANT_GET})),
					?CANT_GET;
				_ ->
					State2
			end
	end,
	put(suit_prize_state, NewState),
	ranking_lib:update(?ranking_suit, get(?pd_id), get_suit_score(SuitInfo)).

get_suit_score(SuitInfo) ->
	Suit1 = lists:nth(1, SuitInfo),
	Suit2 = lists:nth(2, SuitInfo),
	Suit3 = lists:nth(3, SuitInfo),
	Suit4 = lists:nth(4, SuitInfo),
	lists:foldl(
		fun(Suit, {SuitNum, EquipNum, Power}) ->
				case size(Suit) =:= 6 of
					true ->
						{SuitNum + 1, EquipNum, Power};
					_ ->
						{SuitNum, EquipNum + size(Suit), Power}
				end
		end,
		{0, 0, get(?pd_combat_power)},
		[Suit1, Suit2, Suit3, Suit4]
	).