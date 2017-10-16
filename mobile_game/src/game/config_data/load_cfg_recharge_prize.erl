%%%-------------------------------------------------------------------
%%% @author fengzhu
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 19. 九月 2016 上午10:55
%%%-------------------------------------------------------------------
-module(load_cfg_recharge_prize).
-author("fengzhu").

-include_lib("config/include/config.hrl").
-include("inc.hrl").
-include("load_cfg_recharge_prize.hrl").

%% API
-export([
    get_total_recharge_by_id/1
    , get_prizeId_by_id/1
]).

load_config_meta() ->
    [
        #config_meta{record = #recharge_prize_cfg{},
            fields = record_info(fields, recharge_prize_cfg),
            file = "recharge_prize.txt",
            keypos = #recharge_prize_cfg.id,
            all = [#recharge_prize_cfg.id],
            verify = fun verify/1}
    ].

verify(#recharge_prize_cfg{id = Id, total_recharge = TotalRecharge, total_prize = TotolPrize}) ->
    ?check(TotalRecharge >= 0, "recharge_prize.txt中， [~p] total_recharge: ~p 配置无效。", [Id, TotalRecharge]),
    ?check(prize:is_exist_prize_cfg(TotolPrize),
        "recharge_prize.txt中， [~p] prize_id :~p 没有找到! ", [Id, TotolPrize]),
    ok;

verify(_R) ->
    ?ERROR_LOG("recharge_prize.txt ~p 无效格式", [_R]),
    exit(bad).

get_total_recharge_by_id(Id) ->
	case lookup_recharge_prize_cfg(Id) of
		#recharge_prize_cfg{ total_recharge = TotalRecharge} ->
			TotalRecharge;
		_ ->
			{error, unknown_type}
	end.

get_prizeId_by_id(Id) ->
    case lookup_recharge_prize_cfg(Id) of
		#recharge_prize_cfg{ total_prize = TotalPrize} ->
			TotalPrize;
		_ ->
			{error, unknown_type}
	end.
