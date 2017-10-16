-module(shop_mng).

%-include_lib("config/include/config.hrl").
-include_lib("pangzi/include/pangzi.hrl").


-include("inc.hrl").
-include("player.hrl").
-include("player_mod.hrl").
-include("item_new.hrl").
-include("item_bucket.hrl").
-include("shop_mng_reply.hrl").
-include("handle_client.hrl").
-include_lib("stdlib/include/ms_transform.hrl").
-include("load_cfg_shop.hrl").
-include("../part/wonderful_activity/bounty_struct.hrl").
-include("../../../wk_open_server_happy/open_server_happy.hrl").
-include("system_log.hrl").

-export([
    buy/4,
    add_back_item/1,
    test_shop_buy_back/1
]).

%%%% 商店配置结构
%%-record(shop_cfg, {
%%    id = 0,  %% 售卖id（item_bid*1000+type
%%    type = 0,  %% 商店类型
%%    item_bid = 0,  %% 物品bid
%%    money_type = 0,  %% 货币类型(10金币
%%    price = 0   %% 出售价格
%%}).
%% 商店回购列表结构
-record(shop_back_tab,
{
    id = 0,          %% 角色id
    ver = 0,         %% 版本号
    item_infos = []  %% 物品信息
}).


-define(player_shop_back_tab, player_shop_back_tab). %% 回购物品数据表
-define(pd_back_items, pd_back_items).  %% 记录回购物品
-define(BACK_ITEMS_LEN_MAX, 15).  %% 回购物品记录的最大长度

%%-define(MONEY_TYPES, [
%%    ?PL_MONEY,
%%    ?PL_DIAMOND
%%]
%%).  %% 商店价格类型 公会功能联调完成  公会功能联调完成

%% @doc  买物品
-spec buy(integer(), integer(), integer(), integer()) -> integer().
buy(ItemBid, MoneyType, Price, ItemCount) when ItemCount > 0 ->
    TotalPrice = Price * ItemCount,
    case buy_item(ItemBid, MoneyType, TotalPrice, ItemCount) of
        ok ->  %% 购买物品成功
            {ok, ?REPLY_MSG_SHOP_BUY_OK};
        {error, Reason} ->
            {error, Reason}
    end;

buy(_ItemBid, _MoneyType, _Price, _ItemCount) ->
    {error, buy_error}.


buy_item(ItemBid, MoneyType, TotalPrice, ItemCount) ->
    game_res:set_res_reasion(<<"购买">>),
    IsCanDel = game_res:can_del([{MoneyType, TotalPrice}]),
    IsCanGive = game_res:can_give([{ItemBid, ItemCount}]),
    case {IsCanDel, IsCanGive} of
        {ok, ok} ->
            game_res:del([{MoneyType, TotalPrice}], ?FLOW_REASON_SHOP_BUY),
            game_res:give_ex([{ItemBid, ItemCount}], ?FLOW_REASON_SHOP_BUY),
            ok;
        _ ->
            {error, ?REPLY_MSG_SHOP_BUY_2}
    end.

get_back_items() ->
    case get(?pd_back_items) of
        ?undefined -> [];
        ItemVL ->
            ?debug_log_shop("back items ~w", [ItemVL]),
            ItemVL
    end.

add_back_item({Item, Val}) ->
    NItem = Item#item_new{id = attr_new:create_uid()},
    ItemVL = get_back_items(),
    %% ?DEBUG_LOG("add ~w, back items ~w", [{NItem, Val}, ItemVL]),
    NItemVL = lists:sublist([{NItem, Val} | ItemVL], ?BACK_ITEMS_LEN_MAX),
    put(?pd_back_items, NItemVL).

del_back_item(ItemV, ItemVL) ->
    NItemVL = lists:delete(ItemV, ItemVL),
    %% ?DEBUG_LOG("del ~w, back items ~w", [ItemV, ItemVL]),
    put(?pd_back_items, NItemVL).


%% @spec sell(ItemId, Count) -> ok | {error, Reason}
%% @doc 出售物品
sell(ItemId, Count) when Count > 0 ->
    ?debug_log_shop("ItemId ~w, Count ~w", [ItemId, Count]),
    shop_system:sell(ItemId, Count);
%%     BagBucket = game_res:get_bucket(?BUCKET_TYPE_BAG),
%%     case goods_bucket:find(by_id, BagBucket, {ItemId}) of
%%         Item = #item_new{bid=Bid, type = Type} ->
%%             ItemVal = case equip:is_valid_type(Type) of
%%                           ?true -> equip:get_eqm_val(Item);
%%                           _ -> load_item:get_price(Bid)
%%                       end,
%%             TotalItemVal = ItemVal * Count,
%%             IsCanDel = game_res:can_del([{by_id, {ItemId, Count}}]),
%%             IsCanGive = game_res:can_give_ex([{?PL_MONEY, TotalItemVal}]),
%%             case {IsCanDel, IsCanGive} of
%%                 {ok, ok} ->
%%                     game_res:del([{by_id, {ItemId, Count}}]),
%%                     game_res:give_ex([{?PL_MONEY, TotalItemVal}]),
%%                     add_back_item({Item#item_new{quantity = Count}, TotalItemVal}),
%%                     ok;
%%                 _ ->
%%                     {error, cant_sell}
%%             end;
%%         _E ->
%%             {error, not_found_item}
%%     end;

sell(_ItemId, _Count) ->
    {error, sell_error}.
%% @spec back_to_bag(BackPos) -> ok | {error, Reason}
%% @doc 回购物品
back_to_bag(BackPos) ->
    ItemVL = get_back_items(),
    case length(ItemVL) of
        Len when Len >= BackPos, BackPos > 0 ->
            {Item, Val} = lists:nth(BackPos, ItemVL),
            case game_res:try_del([{?PL_MONEY, Val}], ?FLOW_REASON_SHOP_BACK_BUY) of
                ok ->
                    game_res:set_res_reasion(<<"回购">>),
                    erlang:put(back_shop, is_back_shop),
                    case game_res:try_give_ex([{Item}], ?FLOW_REASON_SHOP_BACK_BUY) of
                        TpL when is_list(TpL) ->
                            erlang:erase(back_shop),
                            del_back_item({Item, Val}, ItemVL),
                            ok;
                        {error, _ReasonAdd} -> {error, bucket_full}
                    end;
                {error, diamond_not_enough} -> {error, diamond_not_enough};
                {error, _ReasonDel} -> {error, cost_not_enough}
            end;
        _ -> {error, not_found_item}
    end.


%% 玩家第一次登陆是调用
create_mod_data(SelfId) ->
    ShopBackTab = #shop_back_tab{id = SelfId},
    case dbcache:insert_new(?player_shop_back_tab, ShopBackTab) of
        ?true -> ok;
        _ ->
            ?ERROR_LOG("player ~w create new shop_back ~w", [SelfId, ShopBackTab])
    end.


load_mod_data(SelfId) ->
    case dbcache:load_data(?player_shop_back_tab, SelfId) of
        [] ->
            ?ERROR_LOG("player ~w can not find shop_back ~w", [SelfId, ?MODULE]),
            create_mod_data(SelfId),
            load_mod_data(SelfId);
        [#shop_back_tab{item_infos = ItemInfos}] ->
            ?pd_new(?pd_back_items, ItemInfos)
    end.

init_client() ->
    ignore.

view_data(Acc) -> Acc.

online() ->
    ok.

offline(_SelfId) ->
    ok.

save_data(SelfId) ->
    ItemInfos = get(?pd_back_items),
    ShopBack = #shop_back_tab{id = SelfId, item_infos = ItemInfos},
    dbcache:update(?player_shop_back_tab, ShopBack),
    ok.

handle_frame(_) -> ok.

handle_client({Pack, Arg}) ->
    handle_client(Pack, Arg).

%% 购买物品
handle_client(?MSG_SHOP_BUY, {_ShopType, Itemid, Count}) ->
    ReplyState =
        case load_cfg_shop:lookup_shop_cfg(Itemid) of
            #shop_cfg{item_bid = ItemBid, money_type = MoneyType, price = Price} ->
                buy(ItemBid, MoneyType, Price, Count);
            _Other -> {error, ?REPLY_MSG_SHOP_BUY_255}
        end,
    case ReplyState of
        {ok, ReplyNum} ->
            bounty_mng:do_bounty_task(?BOUNTY_TASK_SHOP_BUY, Count),
            open_server_happy_mng:sync_task(?SHOP_COUNT, Count),
            ?player_send(shop_sproto:pkg_msg(?MSG_SHOP_BUY, {ReplyNum}));
        {error, Other} ->
            ?player_send(shop_sproto:pkg_msg(?MSG_SHOP_BUY, {Other}))
    end;

%% 出售物品
handle_client(?MSG_SHOP_SELL, {ItemId, Count}) ->
    Pds = player_eng:tran_assets_pds_mix([?pd_bag]),
    player_eng:transaction_start(Pds),
    ReplyNum = case sell(ItemId, Count) of
                   ok -> %% 出售物品成功
                       player_eng:transaction_commit(),
                       api:sync_phase_prize_data(),
                       bounty_mng:do_bounty_task(?BOUNTY_TASK_SHOP_SELL, Count),
                       ?REPLY_MSG_SHOP_SELL_OK;
                   {error, Reason} ->
                       player_eng:transaction_rellback(),
                       if
                           Reason == is_bind ->  %% 绑定物品不能出售
                               ?REPLY_MSG_SHOP_SELL_1;
                           ?true -> %% 出售物品失败，请重试。重试失败，请联系GM。
                               ?debug_log_shop("shop sell error ~w", [Reason]),
                               ?REPLY_MSG_SHOP_SELL_255
                       end
               end,
    ?player_send(shop_sproto:pkg_msg(?MSG_SHOP_SELL, {ReplyNum}));

%% 回购物品
handle_client(?MSG_SHOP_BUY_BACK, {BackPos}) ->
    Pds = player_eng:tran_assets_pds_mix([?pd_bag]),
    player_eng:transaction_start(Pds),
    ReplyNum = case back_to_bag(BackPos) of
                   ok ->   %% 回购物品成功
                       player_eng:transaction_commit(),
                       ?REPLY_MSG_SHOP_BUY_BACK_OK;
                   {error, Reason} ->
                       ?debug_log_shop("back error ~w", [Reason]),
                       player_eng:transaction_rellback(),
                       if
                           Reason == diamond_not_enough ->   %% 钻石不足
                               ?REPLY_MSG_SHOP_BUY_BACK_1;
                           Reason == cost_not_enough ->      %% 金币不足
                               ?REPLY_MSG_SHOP_BUY_BACK_2;
                           Reason == bucket_full ->          %% 背包已满
                               ?REPLY_MSG_SHOP_BUY_BACK_3;
                           ?true ->              %% 回购物品失败，请重试。重试失败，请联系GM。
                               ?REPLY_MSG_SHOP_BUY_BACK_255
                       end
               end,
    ?player_send(shop_sproto:pkg_msg(?MSG_SHOP_BUY_BACK, {ReplyNum}));

%% 获取回购物品列表
handle_client(?MSG_SHOP_BUY_BACK_LIST, {}) ->
    ItemVL = get_back_items(),
    ItemPkg = [{goods_bucket:get_sink_info(ItemInfo, 0), ItemPrice} || {ItemInfo, ItemPrice} <- ItemVL],
    ?player_send(shop_sproto:pkg_msg(?MSG_SHOP_BUY_BACK_LIST, {ItemPkg}));


handle_client(Mod, Msg) ->
    ?ERROR_LOG("no known msg Mod:~p Msg:~p", [shop_sproto:to_s(Mod), Msg]).

handle_msg(_FromMod, {buy_back_list}) ->
    handle_client(?MSG_SHOP_BUY_BACK_LIST, {});
handle_msg(FromMod, Msg) ->
    ?ERROR_LOG("~p recv a unknown msg ~p from ~p", [?pname(), Msg, FromMod]),
    {noreply}.

load_db_table_meta() ->
    [
        %% 玩家回购列表数据
        #db_table_meta{
            name = ?player_shop_back_tab,
            fields = ?record_fields(shop_back_tab),
            record_name = shop_back_tab,
            shrink_size = 1,
            flush_interval = 2
        }
    ].


test_shop_buy_back(PlayerId) ->
    world:send_to_player(PlayerId, ?mod_msg(shop_mng, {buy_back_list})).
