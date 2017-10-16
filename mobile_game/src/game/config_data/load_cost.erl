%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 13. 八月 2015 下午3:21
%%%-------------------------------------------------------------------
-module(load_cost).
-author("clark").

%% API
-export(
[
    get_cost_list/1
    ,get_cost_list/2
]).


-include_lib("config/include/config.hrl").
-include("inc.hrl").
-include("load_cost.hrl").

-define(item_id_assets_max, 1000).

load_config_meta() ->
    [
        #config_meta{record = #cost_new_cfg{},
            fields = record_info(fields, cost_new_cfg),
            file = "cost.txt",
            keypos = #cost_new_cfg.id,
            verify = fun verify/1}
    ].


verify(#cost_new_cfg{id = Id, goods = ItemList}) ->
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


get_cost_list(CostID) ->
    case lookup_cost_new_cfg(CostID) of
        #cost_new_cfg{goods = GoodsList} ->
            DelTpL = do_cost_tp(GoodsList),
            DelTpL;
        _ ->
            ret:error(not_found_cost)
    end.


get_cost_list(CostList, Rate) when is_list(CostList) ->
    CostList1 = lists:map(fun({N, C}) -> {N, C * Rate} end, CostList),
    DelTpL = do_cost_tp(CostList1),
    DelTpL;

get_cost_list(CostID, Rate) ->
    case lookup_cost_new_cfg(CostID) of
        #cost_new_cfg{goods = CostList} ->
            CostList1 = lists:map(fun({N, C}) -> {N, C * Rate} end, CostList),
            DelTpL = do_cost_tp(CostList1),
            DelTpL;
        _ ->
            ret:error(not_found_cost)
    end.





do_cost_tp(GoodsList) ->
    lists:foldr(
        fun({Bid, Count}, AccIn) when Bid < ?item_id_assets_max -> [{Bid, Count} | AccIn];
            ({Bid, Count}, AccIn) -> [{Bid, Count} | AccIn];
            ({Bid, Count, _Bind}, AccIn) -> [{Bid, Count} | AccIn]
        end,
        [],
        GoodsList).