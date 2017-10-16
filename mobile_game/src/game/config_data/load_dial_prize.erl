%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 27. 六月 2015 下午6:09
%%%-------------------------------------------------------------------
-module(load_dial_prize).
-author("clark").

%% API
-export([
    get_prize_of_lvl_area/1
    , get_prize_of_lvl_area_and_week/2
]).



-include("inc.hrl").
-include_lib("config/include/config.hrl").
-include("load_dial_prize.hrl").


-define(dial_prize_max, dial_prize_max). %%% 转盘抽奖记录数

load_config_meta() ->
    [
        #config_meta{
            record = #dial_prize_cfg{},
            fields = ?record_fields(dial_prize_cfg),
            file = "dial_prize.txt",
            keypos = #dial_prize_cfg.id,
            all = [#dial_prize_cfg.id],
            verify = fun verify/1}
    ].

verify(#dial_prize_cfg{id = Id, level = ListLevel, rand_prize_id = PrizeId}) ->
    ?check(is_list(ListLevel), "dial_prize.txt中， [~p] level :~p 配置无效。! ", [Id, ListLevel]),
    ?check(prize:is_exist_rd_prize_cfg(PrizeId),
        "dial_prize.txt中， [~p] rand_prize_id :~p 没有找到! ", [Id, PrizeId]),
    ok.



%% Level是否Id的等级范围内
is_lvl_area(Level) ->
    fun(Id) ->
        Cfg = load_dial_prize:lookup_dial_prize_cfg(Id),
        case Cfg of
            #dial_prize_cfg{level = LvlList, rand_prize_id = PrizeId} ->
                Left = lists:nth(1, LvlList),
                Right = lists:nth(2, LvlList),
                if
                    Level >= Left andalso Level =< Right ->
                        {true, PrizeId};
                    true ->
                        {false, 0}
                end;
            _ ->
                {false, 0}
        end
    end.



%% 获得奖励值
do_get_prize([], _Func) -> 0;
do_get_prize([Head | TailList], Func) ->
    case Func(Head) of
        {true, PrizeId} ->
            PrizeId;
        _ ->
            do_get_prize(TailList, Func)
    end.
get_prize_of_lvl_area(LeveL) ->
    IdList = lookup_all_dial_prize_cfg(#dial_prize_cfg.id),
    case IdList of
        none ->
            ?DEBUG_LOG_COLOR(?color_yellow, "verify IdList is none"),
            0;
        _ ->
            do_get_prize(IdList, is_lvl_area(LeveL))
    end.

get_prize_of_lvl_area_and_week(Level, Week) ->
    IdList = lookup_all_dial_prize_cfg(#dial_prize_cfg.id),
    case IdList of
        none ->
            ?DEBUG_LOG_COLOR(?color_yellow, "verify IdList is none"),
            0;
        _ ->
            NewIdList =
                lists:foldl(
                    fun(Id, Acc) ->
                        #dial_prize_cfg{day = Day} = lookup_dial_prize_cfg(Id),
                        if
                            Day =:= Week ->
                                [Id | Acc];
                            true ->
                                Acc
                        end
                    end,
                    [],
                    IdList
                ),
            do_get_prize(NewIdList, is_lvl_area(Level))
    end.



