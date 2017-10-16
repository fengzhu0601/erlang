%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 23. 十一月 2015 下午9:41
%%%-------------------------------------------------------------------
-module(load_battle_coef).
-author("clark").

%% API
-export
([
    get_coef/2
]).

-include_lib("config/include/config.hrl").
-include("inc.hrl").
-include("load_battle_coef.hrl").



load_config_meta() ->
    [
        #config_meta
        {
            record = #battle_coef_cfg{},
            fields = ?record_fields(battle_coef_cfg),
            file = "battle_coef.txt",
            keypos = #battle_coef_cfg.id,
            verify = fun verify/1
        }
    ].



verify(#battle_coef_cfg{}) ->
    ok.

get_coef(Key, Pos) ->
    case lookup_battle_coef_cfg(Key) of
        #battle_coef_cfg{} = Cfg ->
            erlang:element(Pos + 3, Cfg);
        _ ->
            0
    end.