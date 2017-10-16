%%%-------------------------------------------------------------------
%%% @author lan
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 14. 十月 2016 下午5:36
%%%-------------------------------------------------------------------
-module(load_cfg_server_login_prize).
-author("lan").

%% API
-export([
	get_prize/1,
	get_all_day/0
]).

-include("load_cfg_server_login_prize.hrl").
-include_lib("config/include/config.hrl").
-include("inc.hrl").


load_config_meta() ->
	[
		#config_meta
		{
			record = #login_prize_cfg{},
			fields = ?record_fields(login_prize_cfg),
			file = "seven_login_prize.txt",
			keypos = #login_prize_cfg.id,
			all = [#login_prize_cfg.id],
			verify = fun verify/1
		}
	].

verify(#login_prize_cfg{id = Id, prize_id = PrizeId}) ->
	?check(prize:is_exist_prize_cfg(PrizeId), "login_prize.txt Id:~p prizeId :~p 在pirze.txt 中没有找到", [Id, PrizeId]),
	ok.

get_prize(Day) ->
	case lookup_login_prize_cfg(Day) of
		#login_prize_cfg{prize_id = PrizeId} ->
			PrizeId;
		_ ->
			?INFO_LOG("not find prize id day:~p", [Day]),
			0
	end.

get_all_day() ->
	lookup_all_login_prize_cfg(#login_prize_cfg.id).