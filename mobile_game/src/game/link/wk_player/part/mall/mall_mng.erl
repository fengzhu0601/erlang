%%%-------------------------------------------------------------------
%%% @author zlb
%%% @doc 商城
%%%
%%%-------------------------------------------------------------------
-module(mall_mng).

%-include_lib("config/include/config.hrl").

-include("inc.hrl").
-include("player.hrl").
-include("player_mod.hrl").
-include("handle_client.hrl").
-include("shop_mng_reply.hrl").
-include("system_log.hrl").
-include_lib("pangzi/include/pangzi.hrl").

%-include("mall_struct.hrl").
-include("load_cfg_mall.hrl").
-include("../../wk_open_server_happy/open_server_happy.hrl").

%%-define(mall_cfg, mall_cfg).
%%-define(MALL_LABEL_TIME, 1).  %% 限时
%%-define(MALL_LABEL_NEW, 2).  %% 新品
%%-define(MALL_LABEL_RATE, 3).  %% 折扣
%%-define(MALL_LABEL_HOT, 4).  %% 热卖

%%-define(MALL_LABEL_ALL,
%%    [
%%        ?MALL_LABEL_TIME,
%%        ?MALL_LABEL_NEW,
%%        ?MALL_LABEL_RATE,
%%        ?MALL_LABEL_HOT
%%    ]
%%).

%%load_config_meta() ->
%%    [
%%        #config_meta{record = #mall_cfg{},
%%            fields = ?record_fields(?mall_cfg),
%%            file = "mall.txt",
%%            keypos = #mall_cfg.id,
%%            verify = fun verify_mall/1}
%%    ].
%%
%%verify_mall(#mall_cfg{id = Id, item_bid = ItemBid, money_type = MoneyType, price = Price, rate = Rate, time = Time, label = Labels}) ->
%%    ?check(com_util:is_valid_uint64(Id), "mall.txt id [~w] 无效! ", [Id]),
%%    ?check(load_item:is_exist_item_attr_cfg(ItemBid), "mall.txt id [~w] item_bid [~w] 物品不存在! ", [Id, ItemBid]),
%%    ?check(player_def:is_valid_special_item_id(MoneyType), "mall.txt  id [~w]  money_type [~w] 无效  ", [Id, MoneyType]),
%%    ?check(com_util:is_valid_uint64(Price), "mall.txt  id [~w]  price [~w] 无效  ", [Id, Price]),
%%    ?check(com_util:is_valid_uint16(Rate), "mall.txt id [~w] rate [~w] 无效! ", [Id, Rate]),
%%    ?check(check_time(Time), "mall.txt id [~w] time [~w] 无效! ", [Id, Time]),
%%    lists:foreach(fun(Label) ->
%%        ?check(lists:member(Label, ?MALL_LABEL_ALL), "mall.txt id [~w] time [~w] 无效! ", [Id, Labels])
%%    end, Labels),
%%    ok.

%%check_time(?undefined) -> ?true;
%%check_time({DateTimeS = {{_Y, _M, _D}, {_H, _Mi, _S}}, DateTimeE = {{_YE, _ME, _DE}, {_HE, _MiE, _SE}}}) ->
%%    case catch com_time:localtime_to_sec(DateTimeS) of
%%        SSec when is_integer(SSec) ->
%%            case catch com_time:localtime_to_sec(DateTimeE) of
%%                ESec when is_integer(ESec) -> ?true;
%%                _ -> ?false
%%            end;
%%        _ -> ?false
%%    end;
%%
%%check_time({DateTime = {{_Y, _M, _D}, {_H, _Mi, _S}}, HourLen}) ->
%%    case catch com_time:localtime_to_sec(DateTime) of
%%        Sec when is_integer(Sec) ->
%%            com_util:is_valid_uint16(HourLen);
%%        _ -> ?false
%%    end.


init_mall() ->
    lists:foldl(fun({_, Pac}, L) ->
        Id = Pac#mall_cfg.id,
        Num = Pac#mall_cfg.number,
        [{Id, Num} | L]
    end,
    [],
    ets:tab2list(mall_cfg)).




create_mod_data(SelfId) ->
    dbcache:insert_new(?player_mall_tab, #player_mall_tab{id = SelfId, list = init_mall()}),
    ok.

load_mod_data(PlayerId) -> 
    case dbcache:load_data(?player_mall_tab, PlayerId) of
        [] ->
            create_mod_data(PlayerId),
            load_mod_data(PlayerId);
        [#player_mall_tab{list = List}] ->
            ?pd_new(?pd_mall_list, List)
    end,
    ok.

init_client() ->
    ok.

view_data(Acc) -> Acc.

handle_frame(_Frame) -> ok.

handle_msg(_FromMod, _Msg) -> ok.

online() ->
    ok.

offline(SelfId) -> 
    dbcache:update(?player_mall_tab, #player_mall_tab{id = SelfId,
    list = get(?pd_mall_list)}),
    ok.
save_data(_) -> ok.

handle_client({Pack, Arg}) ->
    handle_client(Pack, Arg).

handle_client(?MSG_MALL_SHOPPING, {CfgId, ItemCount}) ->
    case load_cfg_mall:lookup_mall_cfg(CfgId) of
        #mall_cfg{item_bid = ItemBid, money_type = MoneyType, rate = Rate, price = Price, label = Lables} ->
            Sec = load_cfg_mall:get_time(CfgId),
            CanTime =
            case lists:member(?MALL_LABEL_TIME, Lables) of
                ?true when Sec > 0 -> 
                    ?true;
                ?true -> 
                    ?false;
                _ -> 
                    ?true
            end,

            if
                not CanTime ->  %% 限时物品超过时限
                    ?player_send(mall_sproto:pkg_msg(?MSG_MALL_SHOPPING, {?REPLY_MSG_SHOP_BUY_4}));
                ?true ->
                    NPrice = com_util:ceil(Price * Rate / 100),
                    TotalPrice = NPrice * ItemCount,
                    IsCanDel = game_res:can_del([{MoneyType, TotalPrice}]),
                    IsCanGive = game_res:can_give([{ItemBid, ItemCount}]),
                    % Retun = 
                    % case {IsCanDel, IsCanGive} of
                    %     {ok, ok} ->
                    %         try 
                    %             gen_server:call(mall_server, {is_can_buy, CfgId, ItemCount}, 5000)
                    %         of
                    %             ?true ->
                    %                 game_res:del([{MoneyType, TotalPrice}], ?FLOW_REASON_SHOP_BUY),
                    %                 game_res:give_ex([{ItemBid, ItemCount}], ?FLOW_REASON_SHOP_BUY),
                    %                 {ok, ?REPLY_MSG_SHOP_BUY_OK};
                    %             _ ->
                    %                 {error, ?ERPLY_MSG_SHOP_BUY_5}
                    %         catch
                    %              E:W ->
                    %                 {error, ?REPLY_MSG_SHOP_BUY_255}
                    %         end;
                    %     _ ->
                    %         {error, ?REPLY_MSG_SHOP_BUY_1}
                    % end,
                    MallList = get(?pd_mall_list),
                    Retun = 
                    case {IsCanDel, IsCanGive} of
                        {ok, ok} ->
                            case lists:keyfind(CfgId, 1, MallList) of
                                {_, Num} when Num =:= -1->
                                    game_res:del([{MoneyType, TotalPrice}], ?FLOW_REASON_SHOP_BUY),
                                    game_res:give_ex([{ItemBid, ItemCount}], ?FLOW_REASON_SHOP_BUY),
                                    {ok, ?REPLY_MSG_SHOP_BUY_OK};
                                {_, Num} when (Num - ItemCount) >= 0 ->
                                    game_res:del([{MoneyType, TotalPrice}], ?FLOW_REASON_SHOP_BUY),
                                    game_res:give_ex([{ItemBid, ItemCount}], ?FLOW_REASON_SHOP_BUY),
                                    put(?pd_mall_list, lists:keyreplace(CfgId, 1, MallList, {CfgId, erlang:max(0, Num-ItemCount)})),
                                    {ok, ?REPLY_MSG_SHOP_BUY_OK};
                                _ ->
                                    {error, ?ERPLY_MSG_SHOP_BUY_5}
                            end;
                        _ ->
                            {error, ?REPLY_MSG_SHOP_BUY_1}
                    end,
                    %?DEBUG_LOG("Retun---------------------------------:~p",[Retun]),
                    case Retun of
                        {error, ReplyNum} ->
                            ?player_send(mall_sproto:pkg_msg(?MSG_MALL_SHOPPING, {ReplyNum}));
                        {ok, _OK} ->
                            open_server_happy_mng:sync_task(?STORE_BUY_COUNT, 1),
                            ?player_send(mall_sproto:pkg_msg(?MSG_MALL_SHOPPING, {?REPLY_MSG_SHOP_BUY_OK}))
                    end
                    % case shop_mng:buy(ItemBid, MoneyType, NPrice, ItemCount) of
                    %     {error, ReplyNum} ->
                    %         ?player_send(mall_sproto:pkg_msg(?MSG_MALL_SHOPPING, {ReplyNum}));
                    %     {ok, _OK} ->
                    %         open_server_happy_mng:sync_task(?STORE_BUY_COUNT, 1),
                    %         ?player_send(mall_sproto:pkg_msg(?MSG_MALL_SHOPPING, {?REPLY_MSG_SHOP_BUY_OK}))
                    % end
            end;
        _Other ->
            ?player_send(mall_sproto:pkg_msg(?MSG_MALL_SHOPPING, {?REPLY_MSG_SHOP_BUY_255}))
    end;

handle_client(?MSG_MALL_TIME_INFOS, {CfgIds}) ->
    TimeInfos = [{CfgId, load_cfg_mall:get_time(CfgId)} || CfgId <- CfgIds],
    ?player_send(mall_sproto:pkg_msg(?MSG_MALL_TIME_INFOS, {TimeInfos}));

handle_client(?MSG_MALL_ID_INFOS, {CfgIds}) ->
    ItemInfos = [{CfgId, get_mall_count(CfgId)} || CfgId <- CfgIds],
    %?DEBUG_LOG("ItemInfos------------------------:~p",[ItemInfos]),
    ?player_send(mall_sproto:pkg_msg(?MSG_MALL_ID_INFOS, {ItemInfos}));



handle_client(Mod, Msg) ->
    ?ERROR_LOG("no known msg Mod:~p Msg:~p", [mall_sproto:to_s(Mod), Msg]),
    {error, unknown_msg}.

%%get_time(CfgId) ->
%%    case lookup_mall_cfg(CfgId) of
%%        #mall_cfg{time = {DateTime, Time}} ->
%%            Now = com_time:now(),
%%            StarSec = com_time:localtime_to_sec(DateTime),
%%            case Now - StarSec of
%%                Sec when Sec > 0, is_integer(Time) ->
%%                    TimeLenSec = ?SECONDS_PER_HOUR * Time,
%%                    case (TimeLenSec - Sec) > 0 of
%%                        ?true ->
%%                            StarSec + TimeLenSec;
%%                        _ -> 0
%%                    end;
%%                Sec when Sec > 0 ->
%%                    EndTimeSec = com_time:localtime_to_sec(Time),
%%                    case EndTimeSec - Now > 0 of
%%                        ?true -> EndTimeSec;
%%                        _ -> 0
%%                    end;
%%                _ -> 0
%%            end;
%%        _Other -> 0
%%    end.

get_mall_count(CfgId) ->
    MallList = get(?pd_mall_list),         
    case lists:keyfind(CfgId, 1, MallList) of
        {_, Num} ->
            Num;
        _ ->
            -1
    end.


load_db_table_meta() ->
    [
        #db_table_meta{name = ?player_mall_tab,
            fields = ?record_fields(player_mall_tab),
            load_all = ?true,
            shrink_size = 1,
            flush_interval = 5}
    ].
