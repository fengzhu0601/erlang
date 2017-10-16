%%%-------------------------------------------------------------------
%%% @author yujian
%%% @doc 神秘商人功能
%%%
%%%-------------------------------------------------------------------
-module(seller_mng).

-include_lib("pangzi/include/pangzi.hrl").
%-include_lib("config/include/config.hrl").

-include("inc.hrl").
-include("player.hrl").
-include("player_mod.hrl").
-include("handle_client.hrl").
-include("seller_struct.hrl").
-include("achievement.hrl").
-include("load_cfg_seller.hrl").
-include("item_new.hrl").
-include("system_log.hrl").

%%-define(SELLER_DEFAULT_ITEM_NUM, 6).     %默认发给前端的item数量
%%-define(SELLER_HISTORY_MAX_NUM, 60).     %购买历史记录条数
%%-define(PageMaxNum, 40).                 %购买历史记录一页数量
%%-define(SHOPPING_HISTORY_TABLE_KEY, 1).  %购买历史记录表默认key值

-define(is_not_activate_seller(), (get(?pd_seller_activation_time) =:= ?undefined)).
-define(BUY_COUNT, 1).



load_db_table_meta() ->
    [
        #db_table_meta{name = ?player_seller_tab,
            fields = ?record_fields(?player_seller_tab),
            shrink_size = 10,
            flush_interval = 2},

        #db_table_meta{name = ?player_shopping_history,
            fields = ?record_fields(?player_shopping_history),
            shrink_size = 5,
            flush_interval = 5}
    ].

create_mod_data(_SelfId) ->
    ok.

load_mod_data(_PlayerId) ->
    load_data().

init_client() ->
    ok.

view_data(Acc) -> Acc.

handle_frame({?frame_levelup, _OldLevel}) ->
    Lv = get(?pd_level),
    #{limit_level:=OpenLv} = misc_cfg:get_misc_cfg(seller_info),
    if
        Lv =:= OpenLv ->
            ?ifdo(?is_not_activate_seller(),
                init_data());
        true -> ok
    end;

handle_frame(Frame) ->
    ?err({unknown_frame, Frame}).

handle_msg(_FromMod, {?pd_seller_count_down}) ->
    Timer = com_time:now(),
    CountDown = count_down(),
    TimerDiff = (CountDown - (Timer - get(?pd_seller_activation_time)) rem CountDown),
    refresh_seller_item(Timer, TimerDiff),
    %?player_send(seller_sproto:pkg_msg(?SELLER_DATA, {get(?pd_seller_refresh_time), [{I} || I <- get(?pd_seller_itemids)]}));
    ?player_send(seller_sproto:pkg_msg(?SELLER_DATA, {get(?pd_seller_refresh_time), get(?pd_seller_itemids)}));


handle_msg(_FromMod, {?pd_seller_send_history, Time, PlayerId, Name, ItemBid, ItemCount}) ->
    ?player_send(seller_sproto:pkg_msg(?PUSH_SELLER_SHOPPING_DATA, {Time, PlayerId, Name, ItemBid, ItemCount}));

handle_msg(_FromMod, Msg) ->
    ?err({unknown_msg, Msg}).

online() ->
    ok.

offline(_SelfId) ->
    ok.

save_data(_SelfId) ->
    ?ifdo(?is_not_activate_seller() =:= ?false,
        update_data()).

handle_client({Pack, Arg}) ->
    case task_open_fun:is_open(?OPEN_SELLER) of
        ?false -> ?return_err(?ERR_SELLER_NOT_ACTIVATE);
        ?true -> handle_client(Pack, Arg)
    end.

%% 消耗钻石，刷新时间。
handle_client(?SELLER_DATA, {Type}) ->
    ?ifdo(?is_not_activate_seller(),
        ?return_err(?ERR_SELLER_NOT_ACTIVATE)),

    case Type of
        1 ->
            %?player_send(seller_sproto:pkg_msg(?SELLER_DATA, {get(?pd_seller_refresh_time), [{I, C} || I <- get(?pd_seller_itemids)]}));
            ItemIds1 = get(?pd_seller_itemids),
            ?INFO_LOG("seller 1 push client list: ~p~n", [ItemIds1]),
            ?player_send(seller_sproto:pkg_msg(?SELLER_DATA, {get(?pd_seller_refresh_time), ItemIds1}));
        2 ->
            Timer = com_time:now(),
            put(?pd_seller_activation_time, Timer),
            Minite = (get(?pd_seller_refresh_time) - Timer) div 60,
            #{minite_cost:=DiamondPercent} = misc_cfg:get_misc_cfg(seller_info),
            Diamond = com_util:ceil(Minite / DiamondPercent),
            case game_res:try_del([{?PL_DIAMOND, Diamond}], ?FLOW_REASON_SELLER) of
                {error, diamond_not_enough} -> ?return_err(?ERR_SELLER_DIAMOND_NOT_ENOUGH);
                {error, _Other} -> ?return_err(?ERR_SELLER_COST_NOT_ENOUGH);
                ok ->
                    CountDown = count_down(),
                    refresh_seller_item(Timer, CountDown),
                    %?player_send(seller_sproto:pkg_msg(?SELLER_DATA, {get(?pd_seller_refresh_time), [{I, C} || I <- get(?pd_seller_itemids)]}))
                    ItemIds2 = get(?pd_seller_itemids),
                    ?INFO_LOG("seller 2 push client list: ~p~n", [ItemIds2]),
                    ?player_send(seller_sproto:pkg_msg(?SELLER_DATA, {get(?pd_seller_refresh_time), ItemIds2}))
            end
    end;

handle_client(?MSG_SELLER_SHOPPING, {SellerId, ItemCount}) ->
    ?ifdo(?is_not_activate_seller(),
        ?return_err(?ERR_SELLER_NOT_ACTIVATE)),
    SellerIdList = get(?pd_seller_itemids),
    ?INFO_LOG("MSG_SELLER_SHOPPING SellerId = ~p, ItemCount = ~p", [SellerId, ItemCount]),
    case load_cfg_seller:lookup_seller_cfg(SellerId) of
        #seller_cfg{item_bid = ItemBid, money_type = MoneyType, price = Price} ->                
            case lists:keyfind(SellerId, 1, SellerIdList) of
                ?false ->
                    ?return_err(?ERR_SELLER_NO_THIS_RANDOM_ID);
                {_, 0} ->
                    ?return_err(?ERR_SELLER_BUY_COUNT_NOT_ENOUGH);
                _ ->
                    case shop_mng:buy(ItemBid, MoneyType, Price, ItemCount) of
                        {error, Other} -> ?return_err(Other);
                        {ok, _OK} ->

                            %% 从NPC处购买日志
                            MoneyBefore =
                                case MoneyType of
                                    ?MONEY_BID ->
                                        attr_new:get(?pd_money, 0);
                                    ?DIAMOND_BID ->
                                        attr_new:get(?pd_diamond, 0);
                                    _ ->
                                       0
                                end,
                            MoneyAfter = MoneyBefore - Price * ItemCount,
                            NPCId = get(?pd_save_scene_id),
                            NPCName = "",
                            ItemPay = Price * ItemCount,
                            ItemId = ItemBid,
                            ItemType = load_item:get_type(ItemBid),
                            BuyItemCount = ItemCount,
                            GetItemCount = ItemCount,
                            system_log:info_npc_buy_log(MoneyBefore, MoneyAfter, NPCId, NPCName, ItemPay, ItemId, ItemType, BuyItemCount, GetItemCount),

                            put(?pd_seller_itemids, lists:keyreplace(SellerId, 1, SellerIdList, {SellerId, 0})),
                            event_eng:post(?ev_seller_buy_item, {?ev_seller_buy_item, 0}, 1),
                            daily_task_tgr:do_daily_task({?ev_seller_buy_item, 0}, 1),
                            add_seller_history(ItemBid, ItemCount),
                            achievement_mng:do_ac(?chucigouwu),
                            ?player_send(seller_sproto:pkg_msg(?MSG_SELLER_SHOPPING, {}))
                    end
            end;
        _Other -> ?return_err(?ERR_SELLER_NO_THIS_CONFIG)
    end;

handle_client(?MSG_SELLER_SHOPPING_HISTORY, {PageStart, PageEnd}) ->
    ?ifdo(?is_not_activate_seller(),
        ?return_err(?ERR_SELLER_NOT_ACTIVATE)),

    ?ifdo(PageStart =< 0 orelse PageEnd > ?SELLER_HISTORY_MAX_NUM orelse PageStart > PageEnd orelse ((PageEnd - PageStart) > ?PageMaxNum),
        ?return_err(?ERR_SELLER_ARG_ERROR)),

    Data = select_seller_history(PageStart, PageEnd),
    ?player_send(seller_sproto:pkg_msg(?MSG_SELLER_SHOPPING_HISTORY, {Data}));

handle_client(_MSG, _) ->
    {error, unknown_msg}.

load_data() ->
    ?DEBUG_LOG("seller mng load data =------------------------------"),
    case dbcache:lookup(?player_seller_tab, get(?pd_id)) of
        [] -> [];
        [#player_seller_tab{seller_item_list = ItemIdList, activation_time = ActivationTime, refresh_time = RefreshTime}] ->
            Timer = com_time:now(),
            if
                Timer < RefreshTime ->
                    TimerDiff = RefreshTime - Timer,
                    ?pd_new(?pd_seller_itemids, ItemIdList),
                    ?pd_new(?pd_seller_refresh_time, RefreshTime),
                    timer_eng:start_tmp_timer(?pd_seller_count_down, TimerDiff * 1000, ?MODULE, {?pd_seller_count_down});
                ?true ->
                    CountDown = count_down(),
                    TimerDiff = (CountDown - (Timer - ActivationTime) rem CountDown),
                    refresh_seller_item(Timer, TimerDiff)
            end,
            ?pd_new(?pd_seller_activation_time, ActivationTime)
    end.

init_data() ->
    TimerNow = com_time:now(),
    put(?pd_seller_activation_time, TimerNow),
    CountDown = count_down(),
    refresh_seller_item(TimerNow, CountDown).

count_down() ->
    #{refresh_time:={Hour, Minite, Second}} = misc_cfg:get_misc_cfg(seller_info),
    Hour * 60 * 60 + Minite * 60 + Second.

refresh_seller_item(TimerNow, CountDownSecond) ->
    ItemIdList = random_item(),
    put(?pd_seller_itemids, ItemIdList),
    put(?pd_seller_refresh_time, (TimerNow + CountDownSecond)),
    timer_eng:start_tmp_timer(?pd_seller_count_down, CountDownSecond * 1000, ?MODULE, {?pd_seller_count_down}).

random_item() ->
    Career = get(?pd_career),
    Lv = get(?pd_level),
    RefreshList = [load_cfg_seller:lookup_seller_refresh_cfg(Id) || Id <- load_cfg_seller:lookup_all_seller_refresh_cfg(#seller_refresh_cfg.id)],
    [SellerIdsByCareer | _R] = [SellerIds || #seller_refresh_cfg{lv_range = [MinLv, MaxLv], sellerIds_and_career = SellerIds} <- RefreshList, MinLv =< Lv, Lv =< MaxLv],
    ItemIdList =
        case lists:keyfind(Career, 1, SellerIdsByCareer) of
            false ->
                [];
            {_, SellerIds} ->
                {Res, OtherData} = random_item(SellerIds),
                CountRes = length(Res),
                if
                    CountRes =:= ?SELLER_DEFAULT_ITEM_NUM ->
                        Res;
                    true ->
                        [{S,M,N} || {S, M, N} <- com_util:rand_more(OtherData, (?SELLER_DEFAULT_ITEM_NUM - CountRes))] ++ Res
                end
        end,
    lists:foldl
    (
        fun({SId,_ItemBid, _N}, Acc) ->
            [{SId, ?BUY_COUNT}|Acc]
        end,
        [],
        ItemIdList
    ).

random_item(SellerIds) ->
    Fun =
        fun({SellerId, Weight}) ->
            #seller_cfg{item_bid = ItemBid} = load_cfg_seller:lookup_seller_cfg(SellerId),
            {SellerId, ItemBid, Weight}
        end,
    random_item(lists:map(Fun, SellerIds), [], [], 0).

random_item(_, Data, _OtherData, _) when length(Data) =:= ?SELLER_DEFAULT_ITEM_NUM -> {Data, []};
random_item([], Data, OtherData, Count) when Count =:= 2 -> {Data, OtherData};
random_item([], Data, OtherData, Count) -> random_item(OtherData, Data, [], Count + 1);
random_item([{SellerId,ItemBid, Weight} | Other], Data, OtherData, Count) ->
    Random = ?random(100),
    if
        Random > Weight -> random_item(Other, Data, [{SellerId,ItemBid, Weight} | OtherData], Count);
        true -> random_item(Other, [{SellerId,ItemBid,Weight} | Data], OtherData, Count)
    end.

add_seller_history(ItemBid, ItemNum) ->
    Now = com_time:now(),
    PlayerId = get(?pd_id),
    Name = get(?pd_name),
    HistoryTab = case dbcache:lookup(?player_shopping_history, ?SHOPPING_HISTORY_TABLE_KEY) of
                     [] -> #player_shopping_history{seller_history = [{Now, PlayerId, Name, ItemBid, ItemNum}]};
                     [#player_shopping_history{seller_history = History}] ->
                         if
                             length(History) =:= ?SELLER_HISTORY_MAX_NUM ->
                                 RObject = lists:reverse(tl(lists:keysort(1, History))),
                                 #player_shopping_history{seller_history = [{Now, PlayerId, Name, ItemBid, ItemNum} | RObject]};
                             true ->
                                 #player_shopping_history{seller_history = [{Now, PlayerId, Name, ItemBid, ItemNum} | History]}
                         end
                 end,
    dbcache:update(?player_shopping_history, HistoryTab),
    world:broadcast(?mod_msg(seller_mng, {?pd_seller_send_history, Now, PlayerId, Name, ItemBid, ItemNum})).

select_seller_history(PageStart, PageEnd) ->
    case dbcache:lookup(?player_shopping_history, ?SHOPPING_HISTORY_TABLE_KEY) of
        [] -> [];
        [#player_shopping_history{seller_history = History}] ->
            lists:sublist(History, PageStart, (PageEnd - PageStart + 1))
    end.

update_data() ->
    dbcache:update(?player_seller_tab, #player_seller_tab{player_id = get(?pd_id),
        seller_item_list = get(?pd_seller_itemids),
        activation_time = get(?pd_seller_activation_time),
        refresh_time = get(?pd_seller_refresh_time)}).
