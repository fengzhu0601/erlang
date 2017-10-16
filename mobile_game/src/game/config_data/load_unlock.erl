%%% coding:utf-8
%%%-------------------------------------------------------------------
%%% @author zl
%%% @doc 各种背包解锁配置
%%%
%%% @end
%%%-------------------------------------------------------------------

-module(load_unlock).

-define(no_config_transform, 1).
-include_lib("config/include/config.hrl").
-behaviour(?config_behavior).
-export([load_config_meta/0]).
-export([lookup_unlock_cfg/2]).
-include("item_bucket.hrl").
-include("inc.hrl").

%% API
-export(
[
    get_bag_dimand_cost/1
    , get_depot_dimand_cost/1
]).




load_config_meta() ->
    [
        #config_meta
        {
            record = #unlock_cfg{},
            name = 'bag_unlock_cfg', %背包格子解锁
            fields = record_info(fields, unlock_cfg),
            file = "bag_unlock.txt",
            keypos = #unlock_cfg.id,
            verify = fun verify/1
        },

        #config_meta
        {
            record = #unlock_cfg{},
            name = 'depot_unlock_cfg',%仓库格子解锁
            fields = record_info(fields, unlock_cfg),
            file = "depot_unlock.txt",
            keypos = #unlock_cfg.id,
            verify = fun verify/1
        }
    ].

%% config 目前不能给同类型的　record 生成正确的查询函数
%% 手写一个
lookup_unlock_cfg(pd_bag, Index) ->
    case ets:lookup(bag_unlock_cfg, Index) of
        [] ->
            ?none;
        [{_, X}] ->
            X
    end;

lookup_unlock_cfg(pd_depot, Index) ->
    case ets:lookup(depot_unlock_cfg, Index) of
        [] ->
            ?none;
        [{_, X}] ->
            X
    end.


verify(#unlock_cfg{id = Id, open_time = OpenTime, diamond = NeedGoldIngod, unlock_num = Num}) ->
    ?check(erlang:is_integer(Id), "unlock[~p] id 不是数字! ", [Id]),
    ?check(OpenTime >= 0, "unlock[~p] open_time ~p 无效, 必须 >= 0 ", [Id, OpenTime]),
    ?check(NeedGoldIngod >= 0, "unlock[~p] money ~p 无效, 必须 >= 0 ", [Id, NeedGoldIngod]),
    ?check(Num >= 0 andalso is_integer(Num), "unlock[~p] ~p open_grid_num 无效, 必须 >= 0 ", [Id, Num]),
    ok;

verify(_R) ->
    ?ERROR_LOG("goods ~p 无效格式", [_R]),
    exit(bad).


get_bag_dimand_cost(Id) ->
    case lookup_unlock_cfg(pd_bag, Id) of
        #unlock_cfg{diamond = Diamond} ->
            Diamond;
        _ ->
            9999999
    end.

get_depot_dimand_cost(Id) ->
    case lookup_unlock_cfg(pd_depot, Id) of
        #unlock_cfg{diamond = Diamond} ->
            Diamond;
        _ ->
            9999999
    end.