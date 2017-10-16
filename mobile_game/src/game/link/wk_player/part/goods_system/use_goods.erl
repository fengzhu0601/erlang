%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 02. 八月 2015 下午3:01
%%%-------------------------------------------------------------------
-module(use_goods).
-author("clark").

%% API
-export(
[
    use_item/3,
    get_item_ex/3,
    get_item_ex/1,
    set_item_ex/3
]).


-include("inc.hrl").
-include("player.hrl").
-include("item_mng_reply.hrl").
-include("item.hrl").
-include("item_new.hrl").
-include("load_item.hrl").
-include("system_log.hrl").
-include("../../wk_open_server_happy/open_server_happy.hrl").

use_item([], {_Item, _ItemCfg, _Num}, ItemList) -> ItemList;
use_item([{friend_gift_qua, EndQua} | T], {Item, ItemCfg, Num}, ItemList) ->
    StarQua = max(0, EndQua - 1),
    case friend_gift_svr:update_gift_quality(get(?pd_id), StarQua, EndQua) of
        ok ->
            event_eng:post(?ev_friend_gift_quality, {?ev_friend_gift_quality, 0}, EndQua),
            use_item(T, {Item, ItemCfg, Num}, ItemList);
        {error, _Reason} -> {error, ?REPLY_MSG_ITEM_USE_4}
    end;

use_item([{friend_gift_num, Qua, GiftNum} | T], {Item, ItemCfg, Num}, ItemList) ->
    case friend_gift_svr:update_gift_quantity(get(?pd_id), Qua, GiftNum) of
        ok ->
            event_eng:post(?ev_friend_gift_num, {?ev_friend_gift_num, 0}, GiftNum),
            use_item(T, {Item, ItemCfg, Num}, ItemList);
        {error, _Reason} -> {error, ?REPLY_MSG_ITEM_USE_4}
    end;

use_item([{pet, 2, PetCfgId} | T], {Item, ItemCfg, Num}, ItemList) ->
    Attrs = get_item_ex(Item, ?item_use_data, []),
    case pet_new_mng:create_pet(PetCfgId, ItemCfg#item_attr_cfg.bid, Attrs) of
        ok ->
            Quality = load_item:get_item_quality(ItemCfg#item_attr_cfg.bid),
            open_server_happy_mng:sync_task(?FUHUA_PET_QUALITY, Quality),
            use_item(T, {Item, ItemCfg, Num}, ItemList);
        {error, _Reason} -> {error, ?REPLY_MSG_ITEM_USE_5}
    end;

%% 使用坐骑卡
use_item([{ride, PetCfgId} | T], {Item, ItemCfg, Num}, ItemList) ->
    Attrs = get_item_ex(Item, ?item_use_data, []),
    case ride_mng:create_ride(PetCfgId, Attrs) of
        ok -> use_item(T, {Item, ItemCfg, Num}, ItemList);
        {error, _Reason} -> {error, ?REPLY_MSG_ITEM_USE_6}
    end;

% use_item([{gift_bag, PrizeId} | T], {Item, ItemCfg, Num}, _ItemList) ->
%     case prize:prize(PrizeId) of
%         {error, Reason} -> {error, Reason};
%         ItemList1 -> use_item(T, {Item, ItemCfg, Num}, ItemList1)
%     end;

use_item([{gift_bag, PrizeId} | _T], {_Item, _ItemCfg, Num}, _ItemList) ->
    NewItemList = 
    case prize:is_rd_prize(PrizeId, rd_prize) of
        true ->
            util:prize_cumsum_by_num(PrizeId, Num);
        _ ->
            ItemList = prize:get_itemlist_by_prizeid(PrizeId),
            util:list_multiply_coefficient(ItemList, Num, [])
    end,
    %?DEBUG_LOG("NewItemList-----------------------:~p",[NewItemList]),
    case game_res:try_give_ex(NewItemList, ?FLOW_REASON_USE_ITEM) of
        {error, Other} -> 
            {error, Other};
        _ -> 
            NewItemList
    end;
use_item([{fireworks, BroadcastType, EffectId} | T], {Item, ItemCfg, Num}, ItemList) ->
    scene_mng:scene_broadcast_effect(BroadcastType, EffectId),
    use_item(T, {Item, ItemCfg, Num}, ItemList);

% use_item([{add_exp, Exp} | T], {Item, ItemCfg, Num}, ItemList) ->
%     player:add_value(?pd_exp, Exp),
%     use_item(T, {Item, ItemCfg, Num}, [{?PL_EXP, Exp} | ItemList]);

use_item([{add_exp, Exp} | _T], {_Item, _ItemCfg, Num}, _ItemList) ->
    TotalExp = Exp * Num,
    player:add_value(?pd_exp, TotalExp),
    [{?PL_EXP, TotalExp}];

% use_item([{add_exp_per, Per} | T], {Item, ItemCfg, Num}, ItemList) ->
%     Exp = player:add_value(pd_exp_per, Per),
%     use_item(T, {Item, ItemCfg, Num}, [{?PL_EXP, Exp} | ItemList]);


use_item([{add_exp_per, Per} | _T], {_Item, _ItemCfg, Num}, _ItemList) ->
    TotalExp = Per * Num,
    player:add_value(pd_exp_per, TotalExp),
    [{?PL_EXP, TotalExp}];

use_item([{dig_goods, ParList} | T], {Item, ItemCfg, Num}, ItemList) ->
    ?ERROR_LOG("dig_goods ~p", [{ParList, Item, ItemCfg, Num}]),
    use_item(T, {Item, ItemCfg, Num}, ItemList);

use_item([Effect | _T], {_Item, _ItemCfg, _Num}, _ItemList) ->
    ?ERROR_LOG("未定义物品使用效果 ~w", [Effect]),
    {error, not_found_effect}.
get_item_ex(Item) ->
    item_new:get_field(Item, ?item_use_data, []).
get_item_ex(Item, Key, DefVal) ->
    item_new:get_field(Item, Key, DefVal).

set_item_ex(Item, Key, Val) ->
    item_new:set_fields(Item, [{Key, Val}]).