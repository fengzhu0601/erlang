%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 29. 七月 2015 下午5:33
%%%-------------------------------------------------------------------
-module(load_dig_goods).
-author("clark").

%% API
-export([
    get_dig_res/1,
    get_dig_prize/1,
    get_position/1,
    is_can_add_dig/1
]).




-include("inc.hrl").
-include_lib("config/include/config.hrl").
-include("load_dial_prize.hrl").
-include("load_dig_goods.hrl").


load_config_meta() ->
    [
        #config_meta{
            record = #dig_goods_cfg{},
            fields = ?record_fields(dig_goods_cfg),
            file = "dig_goods.txt",
            keypos = #dig_goods_cfg.id,
            groups = [#dig_goods_cfg.scene_id],
            verify = fun verify/1}
    ].

verify(#dig_goods_cfg{id = Id, scene_id = SceneId, dig_goods_id = DigGoodsId, type = Type, quantity_limit = Quantity}) ->
    ?check(load_cfg_scene:is_exist_scene_cfg(SceneId), "dig_goods.txt中， [~p] scene_id: ~p 配置无效。", [Id, SceneId]),
    ?check(DigGoodsId =:= 0 orelse prize:is_exist_prize_cfg(DigGoodsId), "dig_goods.txt中， [~p] dig_goods_id: ~p 配置无效。", [Id, DigGoodsId]),
    ?check(Type =/= 0, "dig_goods.txt中， [~p] type: ~p 配置无效。", [Id, Type]),
    ?check(Quantity > 0, "dig_goods.txt中， [~p] quantity_limit: ~p 配置无效。", [Id, Quantity]),
    ok.



get_dig_res(SceneId) ->
    CfgList = 
    case lookup_group_dig_goods_cfg(#dig_goods_cfg.scene_id, SceneId) of
        ?none ->
            [];
        IdList ->
            lists:foldl(
            fun(Id, Acc) ->
                case lookup_dig_goods_cfg(Id) of
                    #dig_goods_cfg{type = 4} ->
                        Acc;
                    #dig_goods_cfg{id = ID} -> 
                        [{ID} | Acc];
                    _ -> 
                        Acc
                end
            end,
            [],
            IdList)
    end,


    L = single_dig:get_dig_of_task(),
    NewL = get_dig_of_scene(SceneId, L),
    util:list_add_list(NewL, CfgList).

get_dig_of_scene(SceneId, List) ->
    lists:foldl(fun({DigID}, L) ->
        case lookup_dig_goods_cfg(DigID) of
            #dig_goods_cfg{scene_id=SceneId} ->
                [{DigID}|L];
            _ ->
                L
        end
    end,
    [],
    List).
get_position(DigID) ->
    case lookup_dig_goods_cfg(DigID) of
        #dig_goods_cfg{position = Position} -> 
            Position;
        _ -> 
            0
    end.


get_dig_prize(DigID) ->
    case lookup_dig_goods_cfg(DigID) of
        #dig_goods_cfg{dig_goods_id = DigGoodsID} -> 
            DigGoodsID;
        _ -> 
            0
    end.

is_can_add_dig(DigID) ->
    case lookup_dig_goods_cfg(DigID) of
        #dig_goods_cfg{type = 4} -> 
            true;
        _ -> 
            false
    end.