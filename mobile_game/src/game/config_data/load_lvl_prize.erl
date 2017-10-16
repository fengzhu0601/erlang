%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 26. 六月 2015 下午4:24
%%%-------------------------------------------------------------------
-module(load_lvl_prize).
-author("clark").

%% API
-export([]).

-include("inc.hrl").
-include("load_lvl_prize.hrl").
-include_lib("config/include/config.hrl").





load_config_meta() ->
    [
        #config_meta{
            record = #lvl_prize_cfg{},
            fields = ?record_fields(lvl_prize_cfg),
            file = "lvl_prize.txt",
            keypos = #lvl_prize_cfg.id,
            verify = fun verify/1}
    ].

verify(#lvl_prize_cfg{id = Id, state = State, level = Level, prize_id = PrizeId}) ->
    ?check(State > 0, "lvl_prize.txt中， [~p] state: ~p 配置无效。", [Id, State]),
    ?check(Level > 0, "lvl_prize.txt中， [~p] level: ~p 配置无效。", [Id, Level]),
    ?check(prize:is_exist_prize_cfg(PrizeId),
        "lvl_prize.txt中， [~p] prize :~p 没有找到! ", [Id, PrizeId]),
    ok.