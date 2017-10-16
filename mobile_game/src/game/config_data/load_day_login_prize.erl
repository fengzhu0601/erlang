%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 27. 六月 2015 下午5:47
%%%-------------------------------------------------------------------
-module(load_day_login_prize).
-author("clark").

%% API
-export([get_cfg_list/2]).


-include("inc.hrl").
-include_lib("config/include/config.hrl").
-include("load_day_login_prize.hrl").





load_config_meta() ->
    [
        #config_meta{
            record = #day_login_prize_cfg{},
            fields = ?record_fields(day_login_prize_cfg),
            file = "day_login_prize.txt",
            keypos = #day_login_prize_cfg.id,
            verify = fun verify/1}
    ].


verify(#day_login_prize_cfg{id = Id, prize_id = PrizeId}) ->
    ?check(prize:is_exist_prize_cfg(PrizeId),
        "day_login_prize.txt中， [~p] prize_id :~p 没有找到! ", [Id, PrizeId]),
    ok.





get_cfg_list(StartDayId, Count) ->
    {{Year, Month, _}, {_, _, _}} = erlang:localtime(),
    Key = Year * 10000 + Month * 100 + StartDayId,
    do_get_cfg_list(Key, Count).



do_get_cfg_list(Key, Count) ->
    if
        Count >= 0 ->
            Cfg = load_day_login_prize:lookup_day_login_prize_cfg(Key),
            case Cfg of
                #day_login_prize_cfg{id = _CfgId, prize_id = _PrizeId, diamond = _Diamond} ->
                    [Cfg | do_get_cfg_list(Key + 1, Count - 1)];
                _Other ->
                    do_get_cfg_list(Key + 1, Count - 1)
            end;
        true ->
            []
    end.

