%%%-------------------------------------------------------------------
%%% @author hank
%%% @copyright (C) 2016, <SANTI>
%%% @doc
%%%
%%% @end
%%% Created : 21. Apr 2016 8:28 PM
%%%-------------------------------------------------------------------
-module(player_payment).
-author("hank").

%% API
-include_lib("pangzi/include/pangzi.hrl").
-include("inc.hrl").
-include("payment.hrl").
%-include("player_mod.hrl").

-export([lookup_player_payment/2,
    lookup_player_payment/3,
    set_player_payment/3]).

% db struct
load_db_table_meta() ->
    [
        #db_table_meta{
            name = payment_tab,
            fields = ?record_fields(payment_tab),
            flush_interval = 0,
            shrink_size = 1
        },
        #db_table_meta{
            name = player_payment_tab,
            fields = ?record_fields(player_payment_tab),
            shrink_size = 20,
            flush_interval = 4
        }
    ].

%%API

lookup_player_payment(PlayerId, Key) ->
    lookup_player_payment(PlayerId, Key, undefined).

lookup_player_payment(PlayerId, Key, Def) ->
    case dbcache:lookup(player_payment_tab, PlayerId) of
        [#player_payment_tab{val = Tree}] ->
            case gb_trees:lookup(Key, Tree) of
                {value, Val} -> Val;
                _ -> Def
            end;
        _ ->
            Misc = #player_payment_tab{id = PlayerId, val = player:init_misc(gb_trees:empty())},
            case dbcache:insert_new(player_payment_tab, Misc) of
                true -> ok;
                _ ->
                    ?ERROR_LOG("player ~p create player_payment_tab but alread exists ", [PlayerId])
            end,
            Def
    end.

set_player_payment(PlayerId, Key, Val) ->
    case dbcache:lookup(player_payment_tab, PlayerId) of
        [PMisc = #player_payment_tab{val = Tree}] ->
            NTree = gb_trees:enter(Key, Val, Tree),
            dbcache:update(player_payment_tab, PMisc#player_payment_tab{val = NTree});
        _ ->
            ?ERROR_LOG("player_misc_tab not found ~w", [PlayerId]),
            exit(not_found)
    end.