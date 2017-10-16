%% coding: utf-8
-module(cost).

-include_lib("config/include/config.hrl").

-include("inc.hrl").
-include("cost.hrl").
-include("item.hrl").

-export_type([id/0]).
-type id() :: non_neg_integer().

%% API
-export
([
    get_cost/1
    , cost/2
    , check_cost_not_empty/3
    , camp_cost/3 %%神魔消耗，入侵对方阵营消耗百分比增加
    , do_cost_tp/1
    , get_cost_item_list/3
    , do_get_cost_item_list/2
    , cost_times/3
    , cost_times/4
    , get_cost_list/1
]).

-define(item_id_assets_max, 1000).
check_cost_not_empty(CostId, Format, Arg) when is_list(Format) ->
    ?check(is_exist_cost_cfg(CostId), Format, Arg),
    #cost_cfg{goods = GoodsList} = lookup_cost_cfg(CostId),
    do_cost_not_empty(GoodsList, Format, Arg),
    ok.

do_cost_not_empty([], _Fmt, _Arg) -> ok;
do_cost_not_empty([GI | GL], Fmt, Arg) ->
    case GI of
        {_, Count} when Count =< 0 ->
            ?ERROR_LOG(Fmt, Arg);
        {_, Count, _} when Count =< 0 ->
            ?ERROR_LOG(Fmt, Arg);
        _ ->
            do_cost_not_empty(GL, Fmt, Arg)
    end.

get_cost_list(CostId) ->
    #cost_cfg{goods = GoodsList} = lookup_cost_cfg(CostId),
    GoodsList.

%% @spec get_cost(CostId) -> ItemL
%% @doc 获取花费列表
get_cost(CostId) ->
    #cost_cfg{goods = GoodsList} = lookup_cost_cfg(CostId),
    do_cost_tp(GoodsList).

do_cost_tp(GoodsList) ->
    lists:foldr(fun({Bid, Count}, AccIn) when Bid < ?item_id_assets_max ->
        [{Bid, Count} | AccIn];
        ({Bid, Count}, AccIn) ->
            [{by_bid, {Bid, Count}} | AccIn];
        ({Bid, Count, _Bind}, AccIn) ->
            [{by_bid, {Bid, Count}} | AccIn]
    end, [], GoodsList).

%% 按照比例计算每个道具的消耗
do_cost_tp(GoodsList, CostPercent) ->
    Fun = fun(CountNum) -> com_util:ceil(CountNum * (CostPercent / 100)) end,
    lists:foldr(fun({Bid, Count}, AccIn) when Bid < ?item_id_assets_max ->
        [{Bid, Fun(Count)} | AccIn];
        ({Bid, Count}, AccIn) ->
            [{by_bid, {Bid, Fun(Count)}} | AccIn];
        ({Bid, Count, _Bind}, AccIn) ->
            [{by_bid, {Bid, Fun(Count)}} | AccIn]
    end, [], GoodsList).

%% @spec cost(CostId) -> {error, Reason} | _
%% @doc 花费
cost(CostId, Reason) ->
    case lookup_cost_cfg(CostId) of
        ?none -> {error, not_found_cost};
        #cost_cfg{goods = GoodsList} ->
            DelTpL = do_cost_tp(GoodsList),
            game_res:try_del(DelTpL, Reason)
    end.

cost_times(GoodsList, Times, Reason) when is_list(GoodsList) ->
    NewGoodsList = item_goods:merge_goods(lists:flatten(lists:duplicate(Times, GoodsList))),
    DelTpL = do_cost_tp(NewGoodsList),
    game_res:try_del(DelTpL, Reason);

cost_times(CostId, Times, Reason) ->
    case lookup_cost_cfg(CostId) of
        ?none -> {error, not_found_cost};
        #cost_cfg{goods = GoodsList} ->
            NewGoodsList = item_goods:merge_goods(lists:flatten(lists:duplicate(Times, GoodsList))),
            DelTpL = do_cost_tp(NewGoodsList),
            game_res:try_del(DelTpL, Reason)
    end.

cost_times(GoodsList, Times, CostPercent, Reason) ->
    NewGoodsList = item_goods:merge_goods(lists:flatten(lists:duplicate(Times, GoodsList))),
    DelTpL = do_cost_tp(NewGoodsList, CostPercent),
    game_res:try_del(DelTpL, Reason).

camp_cost(CostId, CostPercent, Reason) ->
    case lookup_cost_cfg(CostId) of
        ?none -> {error, not_found_cost};
        #cost_cfg{goods = GoodsList} ->
            DelTpL = do_cost_tp(GoodsList, CostPercent),
            game_res:try_del(DelTpL, Reason)
    end.


get_cost_item_list(CostIdList, CostPercent, Rate) ->
    AllGoodsList = 
    lists:foldl(fun(CostId, List) ->
        case lookup_cost_cfg(CostId) of
            ?none ->
                List;
            #cost_cfg{goods = GoodsList} ->
                do_get_cost_item_list(GoodsList, List)
        end
    end,
    [],
    CostIdList),
    Fun = fun(CountNum) -> com_util:ceil(CountNum * (CostPercent / Rate)) end,
    lists:foldl(fun
        ({Bid, Count}, AccIn) ->
            [{Bid, Fun(Count)} | AccIn];
        ({Bid, Count, _Bind}, AccIn) ->
            [{Bid, Fun(Count)} | AccIn]
    end, 
    [], 
    AllGoodsList).


do_get_cost_item_list([], List) ->
    List;
do_get_cost_item_list([{GoodId, Count} = H|T], List) ->
    case lists:keyfind(GoodId, 1, List) of
        ?false ->
            do_get_cost_item_list(T,[H|List]);
        {_, Num} ->
            do_get_cost_item_list(T, lists:keyreplace(GoodId, 1, List, {GoodId, Num+Count}))
    end.

load_config_meta() ->
    [
        #config_meta{record = #cost_cfg{},
            fields = record_info(fields, cost_cfg),
            file = "cost.txt",
            keypos = #cost_cfg.id,
            verify = fun verify/1}
    ].

verify(#cost_cfg{id = Id, goods = ItemList}) ->
    case erlang:is_list(ItemList) of
        ?true ->
            lists:foreach(fun({ItemId, Count}) ->  %% 默认绑定非绑都行
                ?check(load_item:check_normal_item(ItemId), "cost 配置 id~w 中itemid~w 没有在item表中找到", [Id, ItemId]),
                ?check(com_util:is_valid_uint64(Count), "cost 配置 id~w 中 itemid ~w itemcout~w 无效", [Id, ItemId, Count]);
                ({ItemId, Count, Bind}) ->
                    ?check(load_item:check_normal_item(ItemId), "cost 配置 id~w 中itemid~w 没有在item表中找到", [Id, ItemId]),
                    ?check(com_util:is_valid_uint64(Count), "cost 配置 id~w 中itemid ~w itemcount~w 无效", [Id, ItemId, Count]),
                    ?check(com_util:is_valid_cli_bool(Bind), "cost 配置 id~w 中itembind~w 无效", [Id, Bind]);
                (_E) ->
                    ?ERROR_LOG("cost 配置物品 id:~w goods~w", [Id, _E])
            end,
                ItemList);   %% 没有奖励的时候GoodsList可以为[]
        ?false ->
            ?ERROR_LOG("cost 配置 id:~p　goods字段~w不是list格式", [Id, ItemList]),
            exit(bad)
    end;

verify(_R) ->
    ?ERROR_LOG("cost 配置　错误格式"),
    exit(bad).


