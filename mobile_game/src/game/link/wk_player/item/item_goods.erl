%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 31. 七月 2015 上午5:58
%%%-------------------------------------------------------------------
-module(item_goods).
-author("clark").

%% API
-export([
    build_gem/3,
    build_epic_gem/3,
    build_use/3,
    build_gift/3,
    build_pet_skill/3,
    build_pet_egg/3,
    build_card/3,
    build_friend_gift/3,
    build_rand_ins/3,
    build_flower/3,
    build_treasure_map/3,
    build_fumoshi/3,
    get_sink_info/2,
    merge_goods/1
]).

-include("item_new.hrl").
-include("load_item.hrl").
-include("player.hrl").

merge_goods(List) when is_list(List)->
    merge_goods_(List, []);
merge_goods(_O) ->
    [].
merge_goods_([], L) ->
    L;
merge_goods_([{Goods, Num}|T], List) ->
    case lists:keyfind(Goods, 1, List) of
        false ->
            merge_goods_(T, [{Goods, Num}|List]);
        {_, C} ->
            merge_goods_(T, lists:keyreplace(Goods, 1, List, {Goods, C+Num}))
    end;
merge_goods_([_|T], List) ->
    merge_goods_(T, List).

build_gem(Bid, Num, _BuildParList) ->
    item_new:build(Bid, Num).

build_epic_gem(Bid, _Num, BuildParList) ->
    Item = item_new:build(Bid, 1),
    case Item of
        {error, Error} -> {error, Error};
        _ ->
%%            AttrId = load_cfg_gem:get_attrid_by_bid(Bid),
            %% todo 加buf技能
            %% RandBuf = load_equip_expand:create_equip_rand_buf_attr(Bid),
            DefaultKeyVal =
                [
                    {?item_use_data, [{?item_epic_gem_exp, BuildParList}]}
                ],
            item_new:set_fields(Item, DefaultKeyVal)
    end.

build_use(Bid, Num, _BuildParList) ->
    item_new:build(Bid, Num).

build_fumoshi(Bid, Num, BuildParList) ->
    Item = item_new:build(Bid, 1),
    DefaultKeyVal =
        [
            {?item_equip_fumo_attr_list, BuildParList}
        ],
    item_new:set_fields(Item, DefaultKeyVal).

build_gift(Bid, Num, _BuildParList) ->
    %io:format("build gift---------:~p~n",[{Bid, Num, _BuildParList}]),
    item_new:build(Bid, Num).

build_pet_skill(Bid, Num, _BuildParList) ->
    item_new:build(Bid, Num).

build_pet_egg(Bid, Num, BuildParList) when BuildParList =:= [] orelse is_integer(BuildParList) ->
    %io:format("Bid------------------------------:~p~n",[{Bid, _Num}]),
    case load_item:get_is_use_type(Bid) of
        0 ->
            item_new:build(Bid, Num);
        _ ->
            PetId = load_item:get_petid_on_item_use_effect(Bid),
            ParList = 
            case load_cfg_new_pet:get_passivity_skill2(PetId) of
                none ->
                    [];
                PetPassivitySkill ->
                    [{3, PetPassivitySkill}]
            end,
            Item = item_new:build(Bid, 1),
            DefaultKeyVal =
                [
                    {?item_use_data, ParList}
                ],
            item_new:set_fields(Item, DefaultKeyVal)
    end;

build_pet_egg(Bid, _Num, BuildParList) ->
    %io:format("egg data --------:~p~n",[{Bid,_Num,BuildParList}]),
    Item = item_new:build(Bid, 1),
    DefaultKeyVal =
        [
            {?item_use_data, BuildParList}
        ],
    item_new:set_fields(Item, DefaultKeyVal).

build_card(Bid, Num, _BuildParList) ->
    item_new:build(Bid, Num).

build_friend_gift(Bid, Num, _BuildParList) ->
    item_new:build(Bid, Num).

build_rand_ins(Bid, Num, _BuildParList) ->
    item_new:build(Bid, Num).

build_flower(Bid, Num, _BuildParList) ->
    item_new:build(Bid, Num).

build_treasure_map(Bid, _Num, _BuildParList) ->
    Item = item_new:build(Bid, 1),
    DefaultKeyVal =
        [
            {?item_use_data, []}
        ],
    item_new:set_fields(Item, DefaultKeyVal).

%% 获得货物放于背包槽时的槽位信息
get_sink_info(Item, Pos) ->
    Bid = item_new:get_bid(Item),
    Cfg = load_item:get_item_cfg(Bid),
    UseData = item_new:get_field(Item, ?item_use_data, []), %% UseData = [{Key,Val}|TailList]
    FuMoData = item_equip:get_fumo_attr_list(Item),
    %io:format("FuMoData-------------------------------:~p~n",[FuMoData]),
    ItemInfo =
        {
            Item#item_new.id,               %% 物品id
            Item#item_new.bid,              %% 物品bid
            Pos,                            %% 物品位置
            Cfg#item_attr_cfg.quality,      %% 物品品质
            Item#item_new.quantity,         %% 物品数量
            Item#item_new.bind,             %% 物品绑定状态 0非绑 1绑定
            1,                              %% 是否鉴定
            0,                              %% 套装id
            0,                              %% 强化等级
            0,                              %% 装备评分
            [],                             %% 扩展属性
            [],                             %% 宝石属性
            UseData,                     %% 物品属性
            [],
            [],
            [],
            0, %% 附魔ID
            FuMoData  %% 附魔属性
        },
    ItemInfo.

















