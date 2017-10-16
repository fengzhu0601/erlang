-module(load_cfg_gwgc).

%% API
-export([
    get_gwgc_prize/1
]).



-include("inc.hrl").
-include_lib("config/include/config.hrl").
-include("load_cfg_gwgc.hrl").


get_gwgc_prize(Id) ->
    case lookup_guaiwu_gc_prize_cfg(Id) of
        ?none ->
            pass;
        #guaiwu_gc_prize_cfg{prize=PrizeId} ->
            PrizeId
    end.


load_config_meta() ->
    [
        #config_meta{
            record = #guaiwu_gc_prize_cfg{},
            fields = ?record_fields(guaiwu_gc_prize_cfg),
            file = "guaiwu_gc_prize.txt",
            keypos = #guaiwu_gc_prize_cfg.id,
            verify = fun verify/1}
    ].

verify(#guaiwu_gc_prize_cfg{id = Id, prize = PrizeId}) ->
    ?check(prize:is_exist_prize_cfg(PrizeId),"guaiwu_gc_prize.txt中， [~p] prize :~p 没有找到! ", [Id, PrizeId]),
    ok.



