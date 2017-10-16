%%%-------------------------------------------------------------------
%%% @author fengzhu
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%     开服冲榜
%%% @end
%%% Created : 21. 九月 2016 下午2:41
%%%-------------------------------------------------------------------
-module(impact_ranking_list_handle_client).
-author("fengzhu").

-include("inc.hrl").
-include("game.hrl").
-include("player.hrl").
-include("player_mod.hrl").
-include("handle_client.hrl").
-include("system_log.hrl").
-include("item_new.hrl").
-include_lib("pangzi/include/pangzi.hrl").
-include("load_item.hrl").
-include("rank.hrl").
-include("day_reset.hrl").

%% API
-export([

    update_suit_list_to_client/1
    , send_suit_list_to_client/0
    , update_new_suit_ranking_list/1
    , push_rank_shop_buy_count/0
    ]).

%% 排行榜商店返回吗
-define(REPLY_MSG_RANK_SHOP_OK, 0).    %% 购买成功
-define(REPLY_MSG_RANK_SHOP_1, 1).     %% 背包空间不足
-define(REPLY_MSG_RANK_SHOP_2, 2).     %% 消耗不足
-define(REPLY_MSG_RANK_SHOP_3, 3).     %% 次数不足
-define(REPLY_MSG_RANK_SHOP_255, 255). %% 未知错误

-define(MAX_BUY_COUNT, 10).
-define(RIDE_SHOP, 1).
-define(PET_SHOP, 2).

-define(player_ever_suit_info_tab, player_ever_suit_info_tab).

-record(player_ever_suit_info_tab, {
	id,
	ever_suit_count = 0,      %% 曾经获得的套装个数
	ever_suit_list = [],     %% 曾经获得的套装列表
    ever_suit_power = 0      %% 曾经获得的套装总战力
}).

load_db_table_meta() ->
    [
        #db_table_meta{
            name = ?player_ever_suit_info_tab,
            fields = ?record_fields(?player_ever_suit_info_tab),
            record_name = ?player_ever_suit_info_tab,
            shrink_size = 1,
            load_all = false,
            flush_interval = 3
        }
    ].

create_mod_data(SelfId) ->
    case dbcache:insert_new(?player_ever_suit_info_tab, #player_ever_suit_info_tab{id = SelfId}) of
        ?true -> ok;
        ?false ->
            ?ERROR_LOG("player ~p create new player_ever_suit_info_tab not alread exists ", [SelfId])
    end,
    ok.

load_mod_data(PlayerId) ->
    case dbcache:load_data(?player_ever_suit_info_tab, PlayerId) of
        [] ->
            ?ERROR_LOG("player ~p can not find player_nine_lottery_tab mode", [PlayerId]),
            create_mod_data(PlayerId),
            load_mod_data(PlayerId);
        [#player_ever_suit_info_tab{ever_suit_count = Counts, ever_suit_list = SuitList, ever_suit_power = SuitPowers}] ->
        	put(pd_ever_suit_count, Counts),
            put(pd_ever_suit_list, SuitList),
            put(pd_ever_suit_power, SuitPowers),
            ok
    end,
    ok.

init_client() -> ok.

view_data(Msg) ->
    Msg.

handle_frame(_) -> ok.

online() -> ok.

offline(Id) ->
	save_data(Id),
	ok.

save_data(PlayerId) ->
	SuitCounts = get(pd_ever_suit_count),
	SuitList = get(pd_ever_suit_list),
    SuitPowers = get(pd_ever_suit_power),
	Tab = #player_ever_suit_info_tab{
		id = PlayerId,
		ever_suit_count = SuitCounts,
		ever_suit_list = SuitList,
        ever_suit_power = SuitPowers
	},
	dbcache:update(?player_ever_suit_info_tab, Tab),
	ok.

%% 隔天重置刷新次数
on_day_reset(_Player) ->
    attr_new:set(?pd_rank_ride_buy_count, 0),
    attr_new:set(?pd_rank_pet_buy_count, 0),
    push_rank_shop_buy_count().


handle_client({Pack, Arg}) ->
    handle_client(Pack, Arg).

handle_client(?MSG_IMPACT_RANKING_LIST_BUY_PRIZE, {Id}) ->
    {PrizeList, Cost} = load_cfg_impact_ranking_list:get_rank_shop_prize_and_cost_by_id(Id),
    MaxBuyCount = get_rank_shop_count_by_id(Id),
    Reply =
        case Id of
            ?RIDE_SHOP ->
                RideBuyCount = attr_new:get(?pd_rank_ride_buy_count, 0),
                if
                    RideBuyCount < MaxBuyCount ->
                        case game_res:try_del([Cost], ?FLOW_REASON_RANK_SHOP) of
                            ok->
                                case game_res:can_give(PrizeList, ?S_MAIL_TASK) of
                                    ok ->
                                        game_res:give(PrizeList, ?S_MAIL_TASK, ?FLOW_REASON_RANK_SHOP),
                                        attr_new:set(?pd_rank_ride_buy_count, RideBuyCount + 1),
                                        push_rank_shop_buy_count(),
                                        ?REPLY_MSG_RANK_SHOP_OK;
                                    _ ->
                                        ?REPLY_MSG_RANK_SHOP_255
                                end;
                            {error, cant_del} ->
                                ?REPLY_MSG_RANK_SHOP_2;
                            _ ->
                                ?INFO_LOG("============255 cost"),
                                ?REPLY_MSG_RANK_SHOP_255
                        end;
                    true ->
                        ?REPLY_MSG_RANK_SHOP_3
                end;
            ?PET_SHOP ->
                PetBuyCount = attr_new:get(?pd_rank_pet_buy_count, 0),
                if
                    PetBuyCount < MaxBuyCount ->
                        case game_res:try_del([Cost], ?FLOW_REASON_RANK_SHOP) of
                            ok->
                                case game_res:can_give(PrizeList, ?S_MAIL_TASK) of
                                    ok ->
                                        game_res:give(PrizeList, ?S_MAIL_TASK, ?FLOW_REASON_RANK_SHOP),
                                        attr_new:set(?pd_rank_pet_buy_count, PetBuyCount + 1),
                                        push_rank_shop_buy_count(),
                                        ?REPLY_MSG_RANK_SHOP_OK;
                                    _ ->
                                        ?REPLY_MSG_RANK_SHOP_255
                                end;
                            {error, cant_del} ->
                                ?REPLY_MSG_RANK_SHOP_2;
                            _ ->
                                ?INFO_LOG("============255 cost"),
                                ?REPLY_MSG_RANK_SHOP_255
                        end;
                    true ->
                        ?REPLY_MSG_RANK_SHOP_3
                end;
            _ ->
                ?INFO_LOG("============255 cost"),
                ?REPLY_MSG_RANK_SHOP_255
        end,
    ?INFO_LOG("Reply:~p", [Reply]),
    ?player_send(impact_ranking_list_sproto:pkg_msg(?MSG_IMPACT_RANKING_LIST_BUY_PRIZE, { Reply }));

handle_client(_Mod, _Msg) ->
    ?err("unkonu msg").

handle_msg(FromMod, Msg) ->
    ?ERROR_LOG("~p recv a unknown msg ~p from ~p", [?pname(), Msg, FromMod]).

%% 更新套装排行榜
update_new_suit_ranking_list(Goods) ->
    case api:is_suit(Goods) of
        ?true ->
            case erlang:get(back_shop) of
                is_back_shop ->
                    pass;
                _ ->
                    SuitNum = get(pd_ever_suit_count),
                    NewSuitNum = SuitNum + 1,
                    put(pd_ever_suit_count, NewSuitNum),

                    SuitPower = get(pd_ever_suit_power),
                    GoodsPower = item_new:get_field(Goods, ?item_equip_power),
                    NewSuitPower = SuitPower + GoodsPower,
                    put(pd_ever_suit_power, NewSuitPower),

                    [Lev, Power] = player:lookup_info(get(?pd_id), [?pd_level, ?pd_combat_power]),
                    ranking_lib:update(?ranking_suit_new, get(?pd_id), {NewSuitNum,NewSuitPower,Lev,Power}),
                    util:is_flush_rank_only_by_rankname(?ranking_suit_new, get(?pd_id)),
                    update_suit_list_to_client(Goods)
            end;
        _ ->
            pass
    end.

update_suit_list_to_client(Goods) ->
    SuitBid = Goods#item_new.bid,
    SuitList = get(pd_ever_suit_list),
    NewSuitList =
        case lists:keyfind(SuitBid, 1, SuitList) of
            {SuitBid, Num} ->
                lists:keyreplace(SuitBid, 1, SuitList, {SuitBid, Num + 1});
            _ ->
                [{SuitBid, 1} | SuitList]
        end,
    put(pd_ever_suit_list, NewSuitList),
    send_suit_list_to_client().

send_suit_list_to_client() ->
    SuitList = get(pd_ever_suit_list),
    PkgMsg = impact_ranking_list_sproto:pkg_msg(?MSG_IMPACT_RANKING_LIST_SUIT_INFO, { SuitList }),
    ?player_send(PkgMsg).

get_rank_shop_count_by_id(Id) ->
    Lists = misc_cfg:get_zuiqiang_rank_shop_count(),
    case lists:keyfind(Id, 1, Lists) of
        {Id, Count} ->
            Count;
        _ ->
            0
    end.

push_rank_shop_buy_count() ->
    RideCount = attr_new:get(?pd_rank_ride_buy_count, 0),
    PetCount = attr_new:get(?pd_rank_pet_buy_count, 0),
    Lists = misc_cfg:get_zuiqiang_rank_shop_count(),
    {RideShopId, MaxRideCount} = lists:keyfind(?RIDE_SHOP, 1, Lists),
    {PetShopId, MaxPetCount} = lists:keyfind(?PET_SHOP, 1, Lists),
    NewList = [{RideShopId, MaxRideCount - RideCount},{PetShopId, MaxPetCount - PetCount}],
    ?player_send(impact_ranking_list_sproto:pkg_msg(?MSG_IMPACT_RANK_BUY_LIST_INFO, { NewList })).
