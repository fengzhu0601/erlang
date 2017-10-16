%%%-------------------------------------------------------------------
%%% @author dsl
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%%-------------------------------------------------------------------
-module(load_alchemy).

%% API
-export([get_alchemy_coin/1]).


-include("inc.hrl").
-include_lib("config/include/config.hrl").

-record(alchemy_cfg, {
    id,             %id
    coin
}).


get_alchemy_coin(PlayerLevel) ->
    case lookup_alchemy_cfg(PlayerLevel) of
        ?none ->
            0;
        Cfg ->
            Cfg#alchemy_cfg.coin
    end.





load_config_meta() ->
    [
        #config_meta{
            record = #alchemy_cfg{},
            fields = ?record_fields(alchemy_cfg),
            file = "alchemy.txt",
            keypos = #alchemy_cfg.id,
            verify = fun verify/1}
    ].


verify(#alchemy_cfg{id = Id, coin = Coin}) ->
    ?check(Id >= 1 andalso Id =< 100, "alchemy.txt中， [~p] id: ~p 配置无效。", [Id, Id]),
    ?check(Coin > 0, "alchemy.txt中， [~p] id: ~p 配置无效。", [Id, Coin]).




