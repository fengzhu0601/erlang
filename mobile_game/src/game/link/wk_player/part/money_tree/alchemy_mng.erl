-module(alchemy_mng).

-include_lib("pangzi/include/pangzi.hrl").


-include("inc.hrl").
-include("player.hrl").
-include("player_mod.hrl").
-include("handle_client.hrl").
-include("day_reset.hrl").
-include("../wonderful_activity/bounty_struct.hrl").
-include("../../../wk_open_server_happy/open_server_happy.hrl").
-include("system_log.hrl").

-export([]).

-define(player_alchemy_tab, player_alchemy_tab).
-define(pd_alchemy_count, pd_alchemy_count).
-define(pd_alchemy_pay_count, pd_alchemy_pay_count).
-record(player_alchemy_tab,
{
    id,             %id
    count = 0,
    pay_count = 0
}).



handle_client({Pack, Arg}) ->
    handle_client(Pack, Arg).

handle_client(?MSG_ALCHEMY_ROCK, {BuyCount}) ->
    VipLevel = attr_new:get_vip_lvl(),
    case load_vip_new:get_vip_zuan_to_jin_by_vip_level(VipLevel) of
        ?none ->
            %?DEBUG_LOG("pass-----------------------"),
            pass;
        List ->
            PlayerLevel = get(?pd_level),
            Size = length(List),
            Count = get(?pd_alchemy_count),
            NewCount = Count + BuyCount,
            %?DEBUG_LOG("Count---size-----:~p",[{Count, Size}]),
            if
                NewCount =< Size ->
                    Cost = get_alchemy_cost(BuyCount, Count+1, List),
                    case game_res:try_del([{?PL_DIAMOND, Cost}], ?FLOW_REASON_ALCHEMY) of
                        ok ->
                            bounty_mng:do_bounty_task(?BOUNTY_TASK_LIANJIN, BuyCount),
                            open_server_happy_mng:sync_task(?USE_LIANJINSHOU_COUNT, BuyCount),
                            attr_new:begin_sync_attr(),
                            entity_factory:build(?PL_MONEY, load_alchemy:get_alchemy_coin(PlayerLevel) * BuyCount, [], ?FLOW_REASON_ALCHEMY),
                            attr_new:end_sync_attr(),
                            put(?pd_alchemy_count, NewCount),
                            ?player_send(alchemy_sproto:pkg_msg(?MSG_ALCHEMY_ROCK, {NewCount}));
                        _ ->
                            pass
                    end;
                true ->
                    pass
            end
    end,
    ok;

handle_client(Mod, Msg) ->
    ?ERROR_LOG("no known msg Mod:~p Msg:~p", [Mod, Msg]).

handle_msg(FromMod, Msg) ->
    ?ERROR_LOG("~p recv a unknown msg ~p from ~p", [?pname(), Msg, FromMod]).

on_day_reset(_) ->
    put(?pd_alchemy_count, 0),
    put(?pd_alchemy_pay_count, 0),
    ?player_send(alchemy_sproto:pkg_msg(?MSG_ALCHEMY_INIT_DATA, {0})),
    ok.

create_mod_data(SelfId) ->
    case dbcache:insert_new(?player_alchemy_tab, #player_alchemy_tab{id = SelfId}) of
        true -> ok;
        false ->
            ?ERROR_LOG("create ~p module ~p data is already_exist", [SelfId, ?MODULE])
    end.


load_mod_data(PlayerId) ->
    case dbcache:load_data(?player_alchemy_tab, PlayerId) of
        [] ->
            create_mod_data(PlayerId),
            load_mod_data(PlayerId);
        [#player_alchemy_tab{count = Count, pay_count = PayCount}] ->
            ?pd_new(?pd_alchemy_count, Count),
            ?pd_new(?pd_alchemy_pay_count, PayCount)
    end,
    ok.


init_client() ->
    ?player_send(alchemy_sproto:pkg_msg(?MSG_ALCHEMY_INIT_DATA, {get(?pd_alchemy_count)})),
    ok.

view_data(Acc) -> Acc.

online() -> nonused.

offline(_PlayerId) ->
    ok.

handle_frame(_) -> ok.

save_data(PlayerId) ->
    dbcache:update(?player_alchemy_tab,
        #player_alchemy_tab
        {
            id = PlayerId,
            count = get(?pd_alchemy_count),
            pay_count = get(?pd_alchemy_pay_count)
        }).

load_db_table_meta() ->
    [
        #db_table_meta{
            name = ?player_alchemy_tab,
            fields = ?record_fields(player_alchemy_tab),
            shrink_size = 5,
            flush_interval = 1
        }
    ].

get_alchemy_cost(Count, Num, List) ->
    PayList = load_vip_new:get_vip_new_pay_list(List),
    SubList = lists:sublist(PayList, Num, Count),
    lists:sum(SubList).
