%%% coding:utf-8
%%%-------------------------------------------------------------------
%%% @author zl
%%% @doc 得到每个表的自增id
%%%
%%% @end
%%%-------------------------------------------------------------------

-module(gen_id).

-include_lib("pangzi/include/pangzi.hrl").
-include("inc.hrl").
-include("safe_ets.hrl").


%% API
-export([
    next_id/1,
    init/0
]).

-record(genid_tab, {tab, id}).

-define(genid_tab, genid_tab).
-define(genid_ets, genid_ets).

next_id(player_tab) ->
    dbcache:update_counter(?genid_tab, player_tab, 1);

next_id(mail_tab) ->
    dbcache:update_counter(?genid_tab, mail_tab, 1);

next_id(com_auction_tab) ->
    dbcache:update_counter(?genid_tab, com_auction_tab, 1);

next_id(guild_id_tab) ->
    dbcache:update_counter(?genid_tab, guild_id_tab, 1);

next_id(pet_id_tab) ->
    dbcache:update_counter(?genid_tab, pet_id_tab, 1);

next_id(ride_id_tab) ->
    dbcache:update_counter(?genid_tab, ride_id_tab, 1);

next_id(payment_tab) ->
    dbcache:update_counter(?genid_tab, payment_tab, 1);

next_id(auction_log_tab) ->
    dbcache:update_counter(?genid_tab, auction_log_tab, 1);

next_id(team_ins) ->
    ets:update_counter(?genid_ets, team_ins, 1) band 16#FFFFFFFF.

create_safe_ets() ->

    [
        safe_ets:new(?genid_ets,
            [?named_table, ?public, {?read_concurrency, ?true}, {?write_concurrency, ?true}],
            fun() ->
                true = ets:insert_new(?genid_ets, {team_ins, 1})
            end
        )
    ].


%%
load_db_table_meta() ->
    [
        #?db_table_meta{
            name = ?genid_tab,
            fields = record_info(fields, ?genid_tab),
            flush_interval = 0,
            shrink_size = 1,
            load_all = true,
            init = fun init/0
        }
    ].


init() ->
    dbcache:insert_new(?genid_tab, #genid_tab{tab = player_tab, id = 1}),
    dbcache:insert_new(?genid_tab, #genid_tab{tab = mail_tab, id = 1}),
    dbcache:insert_new(?genid_tab, #genid_tab{tab = com_auction_tab, id = 1}),
    dbcache:insert_new(?genid_tab, #genid_tab{tab = guild_id_tab, id = 0}),
    dbcache:insert_new(?genid_tab, #genid_tab{tab = pet_id_tab, id = 0}),
    dbcache:insert_new(?genid_tab, #genid_tab{tab = ride_id_tab, id = 1}),
    dbcache:insert_new(?genid_tab, #genid_tab{tab = payment_tab, id = 1}),
    dbcache:insert_new(?genid_tab, #genid_tab{tab = auction_log_tab, id = 1}),
    ok.
