%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 29. 六月 2015 上午11:18
%%%-------------------------------------------------------------------
-module(load_pay_order).
-author("clark").

%% API
-export([
    get_day_return_diamond/1,
    get_state_num_list/0,
    get_state_num/1,
    get_diamond_by_payid/1,
    get_limit_day_by_payid/1,
    get_pay_prize_id/1,
    get_pay_rmb_by_payid/1
]).


-include("inc.hrl").
-include_lib("config/include/config.hrl").
-include("load_pay_order.hrl").


get_pay_rmb_by_payid(PayId) ->
    case lookup_pay_order_cfg(PayId) of
        #pay_order_cfg{pay_rmb=D1} when D1 > 0 ->
            D1;
        _ ->
            0
    end.

get_pay_prize_id(PayId) ->
    case lookup_pay_order_cfg(PayId) of
        #pay_order_cfg{pay_prize_id=D1} when D1 > 0 ->
            D1;
        _ ->
            ?none
    end.

get_diamond_by_payid(PayId) ->
    case lookup_pay_order_cfg(PayId) of
        ?none ->
            {0,0,0};
        #pay_order_cfg{give_diamond=D1, give_bind_diamond=D2,give_day_bind_diamond=D3} ->
            {D1, D2,D3}
    end.

get_limit_day_by_payid(PayId) ->
    case lookup_pay_order_cfg(PayId) of
        ?none ->
            0;
        #pay_order_cfg{limit_day=T} ->
            T
    end.


get_state_num(PayId) ->
    case lookup_pay_order_cfg(PayId) of
        ?none ->
            ?none;
        #pay_order_cfg{state_num=Type} ->
            Type
    end.

get_state_num_list() ->
    lists:foldl(fun({_Key, P}, L) ->
        case erlang:is_record(P, pay_order_cfg) of
            ?true ->
                Id = P#pay_order_cfg.id,
                StateNum = P#pay_order_cfg.state_num,
                [{Id, StateNum}|L];
            ?false ->
                L
        end
    end,
    [],
    ets:tab2list(pay_order_cfg)).



load_config_meta() ->
    [
        #config_meta{
            record = #pay_order_cfg{},
            fields = ?record_fields(pay_order_cfg),
            file = "pay.txt",
            keypos = #pay_order_cfg.id,
            all = [#pay_order_cfg.id],
            verify = fun verify/1}
    ].


verify(#pay_order_cfg{id = Id, pay_rmb = PayRmb, give_vip = GiveVip, give_card_vip = GiveCardVip,
    next_level = NextLevel, give_diamond = GiveDiamond, give_bind_diamond = GiveBindDiamond,
    give_day_bind_diamond = GiveDayBindDiamond, limit_day = LimitDay,
    state_num = StateNum, order_type = OrderType}) ->
    ?check(PayRmb > 0, "pay.txt中， [~p] pay_rmb~p 配置无效。", [Id, PayRmb]),
    ?check(GiveVip >= 0, "pay.txt中， [~p] give_vip~p 配置无效。", [Id, GiveVip]),
    ?check(GiveCardVip >= 0, "pay.txt中， [~p] give_card_vip~p 配置无效。", [Id, GiveCardVip]),
    ?check(NextLevel >= 0, "pay.txt中， [~p] next_level~p 配置无效。", [Id, NextLevel]),
    ?check(GiveDiamond >= 0, "pay.txt中， [~p] give_diamond~p 配置无效。", [Id, GiveDiamond]),
    ?check(GiveBindDiamond >= 0, "pay.txt中， [~p] give_bind_diamond~p 配置无效。", [Id, GiveBindDiamond]),
    ?check(GiveDayBindDiamond >= 0, "pay.txt中， [~p] give_day_bind_diamond~p 配置无效。", [Id, GiveDayBindDiamond]),
    ?check(LimitDay >= -1, "pay.txt中， [~p] limit_day~p 配置无效。", [Id, LimitDay]),
    %?check(StateId >= 0, "pay.txt中， [~p] state_id~p 配置无效。", [Id, StateId]),
    ?check(StateNum >= 0, "pay.txt中， [~p] state_num~p 配置无效。", [Id, StateNum]),
    ?check(OrderType > 0, "pay.txt中， [~p] order_type~p 配置无效。", [Id, OrderType]),
    ok.

do_get_diamond([], _CardVip) -> 0;
do_get_diamond([Head | TailList], CardVip) ->
    Cfg = load_pay_order:lookup_pay_order_cfg(Head),
    case Cfg of
        #pay_order_cfg{
            id = _Id,
            pay_rmb = _PayRmb,
            give_card_vip = GiveCardVip,
            give_day_bind_diamond = GiveDayBindDiamond,
            order_type = OrderType} ->
            if
                OrderType =:= 1 andalso GiveCardVip == CardVip ->
                    GiveDayBindDiamond;
                true ->
                    do_get_diamond(TailList, CardVip)
            end;
        _ ->
            do_get_diamond(TailList, CardVip)
    end.

get_day_return_diamond(CardVip) ->
    IdList = lookup_all_pay_order_cfg(#pay_order_cfg.id),
    case IdList of
        none ->
            ?DEBUG_LOG("get_day_return_diamond IdList is none , ~p", [CardVip]),
            0;
        _ ->
            do_get_diamond(IdList, CardVip)
    end.