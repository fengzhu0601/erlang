%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 31. 七月 2015 下午9:02
%%%-------------------------------------------------------------------
-module(load_pay_prize).
-author("clark").

%% API
-export([
    init_day_cost_prize_state/0,
    init_grow_jijin/0,
    init_every_day_cost_list/0,
    init_total_cost_list/0,
    get_first_chizhi_prize/1,
    get_cfg_by_pay_prize_id/1,
    get_pay_id_by_type/1
]).



-include("inc.hrl").
-include_lib("config/include/config.hrl").
-include("load_pay_prize.hrl").



get_first_chizhi_prize(PayPrizeId) ->
    case lookup_pay_prize_cfg(PayPrizeId) of
        #pay_prize_cfg{first_prize = Id} ->
            Id;
        _ ->
            0
    end.

get_cfg_by_pay_prize_id(PayPrizeId) ->
    case lookup_pay_prize_cfg(PayPrizeId) of
        #pay_prize_cfg{type=Type, first_prize=Fp, grow_up_prize=Gup,day_prize=Dp,total_prize=Tp} ->
            {Type, Fp, Gup, Dp, Tp};
        _ ->
            ?none
    end.

init_grow_jijin() ->
    lists:foldl(fun({_, Pp}, L) ->
        case erlang:is_record(Pp, pay_prize_cfg) of
            ?true ->
                Id = Pp#pay_prize_cfg.id,
                GrowUpLvl = Pp#pay_prize_cfg.grow_up_lvl,
                if
                    GrowUpLvl =/= 0 ->
                        [{GrowUpLvl, Id}|L];
                    true ->
                        L
                end;
            _ ->
                L
        end
    end,
    [],
    ets:tab2list(pay_prize_cfg)).

get_pay_id_by_type(Type) ->
    lists:foldl(fun({_, Pp}, L) ->
        case erlang:is_record(Pp, pay_prize_cfg) of
            ?true ->
                Id = Pp#pay_prize_cfg.id,
                CfgType = Pp#pay_prize_cfg.type,
                if
                    CfgType =:= Type ->
                        [Id|L];
                    true ->
                        L
                end;
            _ ->
                L
        end
    end,
    [],
    ets:tab2list(pay_prize_cfg)).


init_every_day_cost_list() ->
    lists:foldl(fun({_, Pp}, L) ->
        case erlang:is_record(Pp, pay_prize_cfg) of
            ?true ->
                Id = Pp#pay_prize_cfg.id,
                DayCost = Pp#pay_prize_cfg.day_cost,
                if
                    DayCost =/= 0 ->
                        [{DayCost, Id}|L];
                    true ->
                        L
                end;
            _ ->
                L
        end
    end,
    [],
    ets:tab2list(pay_prize_cfg)).

init_total_cost_list() ->
    lists:foldl(fun({_, Pp}, L) ->
        case erlang:is_record(Pp, pay_prize_cfg) of
            ?true ->
                Id = Pp#pay_prize_cfg.id,
                TotalCost = Pp#pay_prize_cfg.total_cost,
                if
                    TotalCost =/= 0 ->
                        [{TotalCost, Id}|L];
                    true ->
                        L
                end;
            _ ->
                L
        end
    end,
    [],
    ets:tab2list(pay_prize_cfg)).



find_day_cost_prize_state([]) -> [];
find_day_cost_prize_state([Head | TailList]) ->
    Cfg = load_pay_prize:lookup_pay_prize_cfg(Head),
    case Cfg of
        #pay_prize_cfg{state_id = StateId, type = RecordType} ->
            if
                RecordType =:= 4 ->
                    [StateId | find_day_cost_prize_state(TailList)];
                true ->
                    find_day_cost_prize_state(TailList)
            end;
        _ ->
            find_day_cost_prize_state(TailList)
    end.



init_day_cost_prize_state() ->
    IdList = lookup_all_pay_prize_cfg(#pay_prize_cfg.id),
    DayCostList = find_day_cost_prize_state(IdList),
    [attr_new:set_sink_state(Id, 0) || Id <- DayCostList].


load_config_meta() ->
    [
        #config_meta{
            record = #pay_prize_cfg{},
            fields = ?record_fields(pay_prize_cfg),
            file = "pay_prize.txt",
            keypos = #pay_prize_cfg.id,
            all = [#pay_prize_cfg.id],
            verify = fun verify/1}
    ].


verify(#pay_prize_cfg{id = Id, state_id = StateId, type = Type, first_prize = FirstPrize, grow_up_price = Gup,
    grow_up_prize = Gup2, grow_up_lvl = Gul, day_cost = DayCost,
    day_prize = DayPrize, total_cost = TotalCost, total_prize = TotalPrize}) ->
    ?check(StateId =/= 0, "pay_prize.txt中， [~p] state_id: ~p 配置无效。", [Id, StateId]),
    ?check(Type =/= 0, "pay_prize.txt中， [~p] type: ~p 配置无效。", [Id, Type]),
    ?check(FirstPrize =:= 0 orelse prize:is_exist_prize_cfg(FirstPrize), "task.pay_prize [~p] first_prize: ~p 配置无效。", [Id, FirstPrize]),
    ?check(Gup >= 0, "pay_prize.txt中， [~p] grow_up_price: ~p 配置无效。", [Id, Gup]),
    ?check(Gup2 =:= 0 orelse prize:is_exist_prize_cfg(Gup2), "task.pay_prize [~p] grow_up_prize: ~p 配置无效。", [Id, Gup2]),
    ?check(Gul >= 0, "pay_prize.txt中， [~p] grow_up_lvl: ~p 配置无效。", [Id, Gul]),
    ?check(DayCost >= 0, "pay_prize.txt中， [~p] day_cost: ~p 配置无效。", [Id, DayCost]),
    ?check(DayPrize =:= 0 orelse prize:is_exist_prize_cfg(DayPrize), "task.pay_prize [~p] day_prize: ~p 配置无效。", [Id, DayPrize]),
    ?check(TotalCost >= 0, "pay_prize.txt中， [~p] total_cost: ~p 配置无效。", [Id, TotalCost]),
    ?check(TotalPrize =:= 0 orelse prize:is_exist_prize_cfg(TotalPrize), "task.pay_prize [~p] total_prize: ~p 配置无效。", [Id, TotalPrize]),
    ok.
