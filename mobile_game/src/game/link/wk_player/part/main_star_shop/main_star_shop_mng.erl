-module(main_star_shop_mng).

-include_lib("pangzi/include/pangzi.hrl").

-include("inc.hrl").
-include("player.hrl").
-include("player_mod.hrl").
-include("handle_client.hrl").
-include("main_star_shop.hrl").
-include("item_new.hrl").
-include("load_cfg_main_star_shop.hrl").
-include("day_reset.hrl").
-include("system_log.hrl").
-include("../../../wk_open_server_happy/open_server_happy.hrl").
-define(main_star_shop_refresh, main_star_shop_refresh).
-define(main_star_shop_refresh_timerref, main_star_shop_refresh_timerref).


on_day_reset(_SelfId) ->
    %?DEBUG_LOG("main_star_shop_mng-----------------------on day reset"),
    init_data(),
    ok.

load_db_table_meta() ->
    [
        #db_table_meta{name = ?player_main_star_shop_tab,
            fields = ?record_fields(?player_main_star_shop_tab),
            shrink_size = 10,
            flush_interval = 2}
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
    {_, OpenLv} = misc_cfg:get_main_ins_shop_info(),
    if
        Lv =:= OpenLv ->
            init_data();
        true -> 
            ok
    end;

handle_frame(Frame) ->
    ?err({unknown_frame, Frame}).

handle_msg(_FromMod, ?main_star_shop_refresh) ->
    init_data();
handle_msg(_FromMod, Msg) ->
    ?err({unknown_msg, Msg}).

online() ->
    ok.

offline(_SelfId) ->
    ok.

save_data(SelfId) ->
    dbcache:update(?player_main_star_shop_tab, #player_main_star_shop_tab{id = SelfId,
    item_list = get(?pd_main_star_shop_item_list),
    count = get(?pd_main_star_shop_count)}).


handle_client({Pack, Arg}) ->
    Lv = get(?pd_level),
    {_, OpenLv} = misc_cfg:get_main_ins_shop_info(),
    if
        Lv >= OpenLv ->
            handle_client(Pack, Arg);
        true -> 
            ?return_err(?ERR_MAIN_STAR_SHOP_NOT_OPEN)
    end.

handle_client(?MSG_MAIN_STAR_SHOP_DATA, {1}) ->
    ItemList = get(?pd_main_star_shop_item_list),
    Count = get(?pd_main_star_shop_count),
    Time = get(?pd_main_star_shop_refresh_time),
    %?DEBUG_LOG("ItemList------------------------:~p",[ItemList]),
    %?DEBUG_LOG("Count------------------------:~p",[Count]),
    %?DEBUG_LOG("Time------------------------:~p",[Time]),
    %{JinXing, YinXing} = main_instance_mng:get_jin_and_yin_xing(),
    ?player_send(main_star_shop_sproto:pkg_msg(?MSG_MAIN_STAR_SHOP_DATA, {Time, Count, ItemList}));

handle_client(?MSG_MAIN_STAR_SHOP_DATA, {2}) ->
    VipLevel = attr_new:get_vip_lvl(),
    %?DEBUG_LOG("VipLevel-----------------------------:~p",[VipLevel]),
    %case load_vip_right:get_main_ins_shop_times_count(VipLevel) of
    case load_vip_new:get_vip_main_ins_shop_times_by_vip_level(VipLevel) of
        ?none ->
            %?DEBUG_LOG("DATA 1------------------------------------1"),
            pass;
        List ->
            Size = length(List),
            Count = get(?pd_main_star_shop_count),
            NewCount = Count + 1,
            %?DEBUG_LOG("NewCount-----------------------:~p",[NewCount]),
            %?DEBUG_LOG("List-----------------------------:~p",[List]),
            if
                NewCount =< Size ->
                    case game_res:try_del([{?PL_DIAMOND, lists:nth(NewCount, List)}], ?FLOW_REASON_FUBEN_SHOP) of
                        ok ->
                            %?DEBUG_LOG("DATA 2------------------------------------2"),
                            flush_data(NewCount);
                        _ ->
                            %?DEBUG_LOG("DATA 3------------------------------------3"),
                            ?return_err(?ERR_COST_DIAMOND_FAIL)
                    end;
                true ->
                    %?DEBUG_LOG("DATA 4------------------------------------4"),
                    ?return_err(?ERR_MAX_COUNT)
            end
    end,
    ok;

handle_client(?MSG_MAIN_STAR_SHOP_BUY, {Id}) ->
    %?DEBUG_LOG("Id----------------------------:~p",[Id]),
    case load_cfg_main_star_shop:lookup_main_ins_star_shop_cfg(Id) of
        ?none ->
            %?DEBUG_LOG("1------------------------------------------"),
            todo;
        #main_ins_star_shop_cfg{item = {Type, _} = ItemTuple, price = Price} ->
            case is_can_buy(Id) of
                ?true ->
                    %?DEBUG_LOG("Price-------------------------:~p",[Price]),
                    case game_res:try_del([Price], ?FLOW_REASON_FUBEN_SHOP) of
                        ok ->
                            %?DEBUG_LOG("3---------------------------"),
                            game_res:try_give_ex([ItemTuple], ?FLOW_REASON_FUBEN_SHOP),
                            update_item_list_status(Id),
                            open_server_happy_mng:sync_task(?STAT_SHOP_COUNT, 1),
                            %{JinXing, YinXing} = main_instance_mng:get_jin_and_yin_xing(),
                            ?player_send(main_star_shop_sproto:pkg_msg(?MSG_MAIN_STAR_SHOP_BUY, {}));
                        _ ->
                            if
                                Type =:= 13 ->
                                    ?return_err(?ERR_JINXING_FAIL);
                                Type =:= 14 ->
                                    ?return_err(?ERR_YINXING_FAIL)
                            end
                    end;
                _ ->
                    %?DEBUG_LOG("4-------------------------------"),
                    todo
            end
    end;


handle_client(_MSG, _) ->
    {error, unknown_msg}.

load_data() ->
    case dbcache:lookup(?player_main_star_shop_tab, get(?pd_id)) of
        [] -> 
            Lv = get(?pd_level),
            {_, OpenLv} = misc_cfg:get_main_ins_shop_info(),
            if
                Lv >= OpenLv ->
                    init_data();
                true -> 
                    pass
            end;
        [#player_main_star_shop_tab{item_list = ItemIdList, count = Count}] ->
            ?pd_new(?pd_main_star_shop_item_list, ItemIdList, load_cfg_main_star_shop:get_main_star_shop_id_list_by_player_level()),
            ?pd_new(?pd_main_star_shop_count, Count, 0),
            do_refresh_star_shop_time()
    end.

init_data() ->
    % ?DEBUG_LOG("init_data-----------------------------"),
    Time = do_refresh_star_shop_time(),
    ItemList = load_cfg_main_star_shop:get_main_star_shop_id_list_by_player_level(),
    put(?pd_main_star_shop_item_list, ItemList),
    put(?pd_main_star_shop_count, 0),
    %{JinXing, YinXing} = main_instance_mng:get_jin_and_yin_xing(),
    ?player_send(main_star_shop_sproto:pkg_msg(?MSG_MAIN_STAR_SHOP_DATA, {Time, 0, ItemList})).

flush_data(Count) ->
    % ?DEBUG_LOG("flush_data------------------------------------"),
    Time = do_refresh_star_shop_time(),
    ItemList = load_cfg_main_star_shop:get_main_star_shop_id_list_by_player_level(),
    put(?pd_main_star_shop_item_list, ItemList),
    put(?pd_main_star_shop_count, Count),
    %{JinXing, YinXing} = main_instance_mng:get_jin_and_yin_xing(),
    ?player_send(main_star_shop_sproto:pkg_msg(?MSG_MAIN_STAR_SHOP_DATA, {Time, Count, ItemList})).

do_refresh_star_shop_time() ->
    {RefreshTimeList, _} = misc_cfg:get_main_ins_shop_info(),
    SortList = lists:keysort(1, RefreshTimeList),
    NewTime = time(),
    OutTime = do_refresh_star_shop_time_(SortList, lists:nth(1, SortList), NewTime),
    % ?DEBUG_LOG("OutTime----------------------:~p",[OutTime]),
    % ?DEBUG_LOG("NowTime ----------------------:~p",[com_time:now()]),
    put(?pd_main_star_shop_refresh_time, OutTime),
    tool:do_send_after(?MICOSEC_PER_SECONDS * OutTime,
        ?mod_msg(?MODULE, ?main_star_shop_refresh),
        ?main_star_shop_refresh_timerref),
    OutTime.


do_refresh_star_shop_time_([], MinTime, _NewTime) ->
    {Hours, _, _} = MinTime,
    % ?DEBUG_LOG("Hours--------------------:~p",[Hours]),
    com_time:get_seconds_to_next_day(Hours);
do_refresh_star_shop_time_([H|T], MinTime, NewTime) ->
    % ?DEBUG_LOG("H------------:~p----NewTime---:~p",[H, NewTime]),
    if
        H  > NewTime->
            {Hours, _, _} = H,
            % ?DEBUG_LOG("Hours2---------------------:~p",[Hours]),
            com_time:get_seconds_to_specific_hour_today(Hours);
        true ->
            do_refresh_star_shop_time_(T, MinTime, NewTime)
    end.


update_item_list_status(ItemId) ->
    ItemList = get(?pd_main_star_shop_item_list),
    case lists:keyfind(ItemId, 1, ItemList) of
        ?false ->
            pass;
        {_, 0} ->
            pass;
        {_, 1} ->
            put(?pd_main_star_shop_item_list, lists:keyreplace(ItemId, 1, ItemList, {ItemId, 0}))
    end.

is_can_buy(Id) ->
    ItemList = get(?pd_main_star_shop_item_list),
    case lists:keyfind(Id, 1, ItemList) of
        {_, 1} ->
            ?true;
        _ ->
            ?false
    end.

is_enough_jinxing_or_yinxing(Type, N) ->
    if
        Type =:= ?JINXING ->
            main_instance_mng:is_enough_jinxing(N);
        Type =:= ?YINXING ->
            main_instance_mng:is_enough_yinxing(N);
        true ->
            false
    end.
