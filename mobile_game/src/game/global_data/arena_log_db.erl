%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 16. 十月 2015 下午5:47
%%%-------------------------------------------------------------------
-module(arena_log_db).
-author("clark").

%% API
-export(
[
    init_arena_log/1,
    update_arena_log/2,
    get_challeng_log/1
]).

-include("inc.hrl").
-include("arena_log_db.hrl").
-include_lib("pangzi/include/pangzi.hrl").
-include("player.hrl").
-include("item_bucket.hrl").
-include("load_spirit_attr.hrl").
-include("load_career_attr.hrl").
-include("achievement.hrl").
-include("scene.hrl").

%% 数据库建表(表不存在时进行)
load_db_table_meta() ->
    [
        #?db_table_meta
        {
            name = ?player_arena_log_tab,
            fields = ?record_fields(?player_arena_log_tab),
            shrink_size = 10,
            flush_interval = 5 %% dirty
        }
    ].

init_arena_log(PlayerID) ->
    case dbcache:load_data(?player_arena_log_tab, PlayerID) of
        [] ->
            dbcache:insert_new(?player_arena_log_tab, #player_arena_log_tab{id = PlayerID, log = []});
        _ ->
            ret:ok()
    end.

update_arena_log(PlayerID, Log) ->
    LogList = dbcache:load_data(?player_arena_log_tab, PlayerID),
    LogList1 = get_items([], 10, [Log|LogList]),
    dbcache:update(?player_arena_log_tab, #player_arena_log_tab{id = PlayerID, log = LogList1}).


get_challeng_log(PlayerID) -> dbcache:load_data(?player_arena_log_tab, PlayerID).



get_items(RetList, 0, _ItemList) -> RetList;
get_items(RetList, _Num, []) -> RetList;
get_items(RetList, Num, [Item|ItemList]) ->
    get_items([Item|RetList], Num-1, ItemList).

