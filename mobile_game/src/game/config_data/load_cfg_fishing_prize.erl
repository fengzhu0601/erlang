%%%-------------------------------------------------------------------
%%% @author fengzhu
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 06. 十二月 2016 上午10:08
%%%-------------------------------------------------------------------
-module(load_cfg_fishing_prize).
-author("fengzhu").

-include_lib("config/include/config.hrl").
-include("inc.hrl").
-include("load_cfg_fishing_prize.hrl").

%% API
-export([
    get_fishing_prize_by_type/1
]).

load_config_meta() ->
    [
        #config_meta
        {
            record = #fishing_prize_cfg{},
            fields = ?record_fields(fishing_prize_cfg),
            file = "fishing_prize.txt",
            keypos = #fishing_prize_cfg.type,
            verify = fun verify/1
        }
    ].

verify(#fishing_prize_cfg{type = Type, prize = PrizeId}) ->
    ?check(?is_pos_integer(Type), "fishing_prize.txt [~p] type 无效 ", [Type]),
    ?check(prize:is_exist_prize_cfg(PrizeId),"fishing_prize.txt中， [~p] prize :~p 没有找到! ", [Type, PrizeId]),
    ok.


get_fishing_prize_by_type(Type) ->
    case lookup_fishing_prize_cfg(Type) of
        #fishing_prize_cfg{prize = PrizeId} ->
            PrizeId;
        _ ->
            {error, unknown_type}
    end.
