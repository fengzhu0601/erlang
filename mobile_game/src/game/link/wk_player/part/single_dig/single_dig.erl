%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 23. 七月 2015 下午4:46
%%%-------------------------------------------------------------------
-module(single_dig).
-author("clark").

%% API
-export([
    can_dig/1,
    do_dig/1,
    add_dig_thing/2,
    send_player_dig_list_to_client/0,
    del_dig_thing/1,
    get_dig_of_task/0,
    add_dig_daily_task/1,
    del_dig_daily_task/1
]).


-include("inc.hrl").
-include("player.hrl").
-include("single_dig.hrl").
-include("handle_client.hrl").
-include("item_bucket.hrl").
-include("item.hrl").
-include("item_cfg.hrl").
-include("item_new.hrl").
-include("load_item.hrl").
-include("scene.hrl").
-include("load_dig_goods.hrl").
-include("system_log.hrl").

get_dig_of_task() ->
    DigList = attr_new:get(?pd_attr_dig_list, []),
    NewMainOrBriantDigList = 
    lists:foldl(fun(#single_dig_tab{id=DigID}, L) ->
        [{DigID}|L]
    end,
    [],
    DigList),
    DailyTaskDigList = attr_new:get(?pd_daily_task_collect_dig_list, []),
    util:list_add_list(NewMainOrBriantDigList, DailyTaskDigList).


can_dig(DigID) ->
    DigThingList = attr_new:get(?pd_attr_dig_list),
    case lists:keyfind(DigID, #single_dig_tab.id, DigThingList) of
        false -> false;
        #single_dig_tab{remainder_num = RemainderNum} ->
            if
                RemainderNum > 0 -> true;
                true -> false
            end
    end.

do_dig(DigID) ->
    DigThingList = attr_new:get(?pd_attr_dig_list),
    case lists:keyfind(DigID, #single_dig_tab.id, DigThingList) of
        false -> false;
        #single_dig_tab{remainder_num = RemainderNum} ->
            NewDigThingList =
                if
                    RemainderNum > 1 ->
                        NewTuple = #single_dig_tab{id = DigID, remainder_num = (RemainderNum - 1)},
                        lists:keyreplace(DigID, #single_dig_tab.id, DigThingList, NewTuple);
                    true ->
                        lists:keydelete(DigID, #single_dig_tab.id, DigThingList)
                end,
            attr_new:set(?pd_attr_dig_list, NewDigThingList)
    end.

add_dig_thing(DigID, Num) ->
    case load_dig_goods:is_can_add_dig(DigID) of
        ?true ->
            DigThingList = attr_new:get(?pd_attr_dig_list, []),
            NewDigThingList =
                case lists:keyfind(DigID, #single_dig_tab.id, DigThingList) of
                    false ->
                        NewTuple = #single_dig_tab{id = DigID, remainder_num = Num},
                        [NewTuple | DigThingList];
                    #single_dig_tab{remainder_num = RemainderNum} ->
                        NewTuple = #single_dig_tab{id = DigID, remainder_num = (RemainderNum + Num)},
                        lists:keyreplace(DigID, #single_dig_tab.id, DigThingList, NewTuple)
                end,
            attr_new:set(?pd_attr_dig_list, NewDigThingList),
            send_player_dig_list_to_client();
        ?false ->
            pass
    end.

del_dig_thing(DigID) ->
    case load_dig_goods:is_can_add_dig(DigID) of
        ?true ->
            DigThingList = attr_new:get(?pd_attr_dig_list),
            attr_new:set(?pd_attr_dig_list, lists:keydelete(DigID, #single_dig_tab.id, DigThingList)),
            ?player_send(scene_sproto:pkg_msg(?MSG_DELETE_DIG_RES_SC, {[{DigID}]}));
        ?false ->
            pass
    end.

add_dig_daily_task(DigID) ->
    DailyTaskDigList = attr_new:get(?pd_daily_task_collect_dig_list, []),
    %?DEBUG_LOG("DigID---------------:~p",[DigID]),
    case lists:member(DigID, DailyTaskDigList) of
        ?true ->
            pass;
        ?false ->
            attr_new:set(?pd_daily_task_collect_dig_list, [DigID|DailyTaskDigList]),
            send_player_dig_list_to_client()
    end.

del_dig_daily_task(DigID) ->
    DailyTaskDigList = attr_new:get(?pd_daily_task_collect_dig_list, []),
    case lists:member(DigID, DailyTaskDigList) of
        ?true ->
            attr_new:set(?pd_daily_task_collect_dig_list, lists:delete(DigID, DailyTaskDigList)),
            send_player_dig_list_to_client();
        ?false ->
            pass
    end.



send_player_dig_list_to_client() ->
    List = util:list_add_list(attr_new:get(?pd_daily_task_collect_dig_list, []), load_dig_goods:get_dig_res(get(?pd_scene_id))),
    %?DEBUG_LOG("single_dig---------list-------:~p",[List]),
    ?player_send(scene_sproto:pkg_msg(?MSG_CREATE_DIG_RES_SC, {List})).


%%----------------------------------------------------
%% 使用物品(donot delete)
use_map(ItemId, Num) ->
    BagBucket = game_res:get_bucket(?BUCKET_TYPE_BAG),
    case goods_bucket:find_goods(BagBucket, by_id, {ItemId}) of
        [Item = #item_new{bid = Bid}] when Num =< Item#item_new.quantity ->
            case load_item:lookup_item_attr_cfg(Bid) of
                #item_attr_cfg{use_type = IsUse, use_effect = Effects} when IsUse =:= ?TRUE ->
                    [{dig_goods, CfgIdList}] = Effects,
                    case make_dig_goods(CfgIdList, Item) of
                        ok -> true;
                        {error, _Reason} -> {error, item_not_found}
                    end;
                #item_attr_cfg{} -> {error, cant_use};
                _ -> {error, not_found_cfg}
            end;
        [_Item] -> {error, item_not_enough};
        _ -> {error, item_not_found}
    end.


make_dig_goods(CfgIdList, Item) ->
    %?INFO_LOG("make_dig_goods CfgIdList ~p ", [CfgIdList]),
    case item_new:get_field(Item, ?item_use_data, []) of
        [] ->
            ID = com_util:rand(CfgIdList), %% 待转成随机数
            NewItem = item_new:set_field(Item, ?item_use_data, [{?item_ex_buried_map_key, ID}]),
            BagBucket = game_res:get_bucket(?BUCKET_TYPE_BAG),
            goods_bucket:begin_sync(BagBucket),
            NewBagBucket = goods_bucket:update(BagBucket, NewItem),
            goods_bucket:end_sync(NewBagBucket);
        _ ->
            ok
    end,
    ret:ok().

post_collect_event(DigType, GoodsId) ->
    case DigType of
        1 ->
            %?DEBUG_LOG("DigType, GoodsId-------------------:~p",[{DigType, GoodsId}]),
            daily_task_tgr:do_daily_task({?ev_collect_item, GoodsId}, 1),
            event_eng:post(?ev_collect_item, GoodsId);
        true ->
            %?DEBUG_LOG("pass-----------------------"),
            pass
    end.

handle_client({Pack, Arg}) ->
    %?INFO_LOG("handle_client ~p", [{Pack, Arg}]),
    handle_client(Pack, Arg).

handle_client(?MSG_USE_DIG_RES_CS, {GoodsId}) ->
    %?INFO_LOG("MSG_USE_DIG_RES_CS 11 ~p", [GoodsId]),
    case use_map(GoodsId, 1) of
        {error, _Error} ->
            %?INFO_LOG("MSG_USE_DIG_RES_CS 22 error"),
            ?player_send(dig_sproto:pkg_msg(?MSG_USE_DIG_RES_CS, {2}));
        _ ->
            %?INFO_LOG("MSG_USE_DIG_RES_CS 33 ok"),
            ?player_send(dig_sproto:pkg_msg(?MSG_USE_DIG_RES_CS, {1}))
    end;

%% 后面要增加防止客户端刷的功能
handle_client(?MSG_DIG_RES_CS, {DigType, GoodsId}) ->
    %?INFO_LOG("----MSG_DIG_RES_CS ~p-----", [{DigType, GoodsId}]),
    BagBucket = game_res:get_bucket(?BUCKET_TYPE_BAG),
    case goods_bucket:find_goods(BagBucket, by_id, {GoodsId}) of
        [Item] ->
            Attrs = item_new:get_field(Item, ?item_use_data, []),
            %?INFO_LOG("MSG_DIG_RES_CS Attrs ~p", [Attrs]),
            case Attrs of
                [] -> ?player_send(dig_sproto:pkg_msg(?MSG_DIG_RES_CS, {2}));
                [{?item_ex_buried_map_key, DigID}] ->
                    case DigID of
                        0 -> {error, item_isnot_maked};
                        _ ->
                            PrizeId = load_dig_goods:get_dig_prize(DigID),
                            if
                                PrizeId =< 0 ->
                                    ?player_send(dig_sproto:pkg_msg(?MSG_DIG_RES_CS, {4}));
                                true ->
                                    prize:prize(PrizeId, ?FLOW_REASON_DIG),
                                    game_res:try_del([{GoodsId, {1}}], ?FLOW_REASON_DIG),
                                    post_collect_event(DigType, GoodsId),
                                    ?player_send(dig_sproto:pkg_msg(?MSG_DIG_RES_CS, {1}))
                            end
                    end;
                _ -> ok
            end;
        _ ->
            post_collect_event(DigType, GoodsId),
            ?player_send(dig_sproto:pkg_msg(?MSG_DIG_RES_CS, {3}))
    end.

