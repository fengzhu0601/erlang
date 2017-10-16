%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 03. 六月 2016 上午11:11
%%%-------------------------------------------------------------------
-module(load_db_guild_first_kill).
-author("clark").

%% API
-export
([
    get/2,
    set/2
]).


-include("load_db_guild_first_kill.hrl").
-include_lib("pangzi/include/pangzi.hrl").
-include("inc.hrl").



%% 数据库建表(表不存在时进行)
load_db_table_meta() ->
    [
        #?db_table_meta
        {
            name = ?guild_boss_first_kill,
            fields = ?record_fields(?guild_boss_first_kill),
            shrink_size = 10,
            flush_interval = 5 %% dirty
        }
    ].


get(Key, Def) ->
    case dbcache:load_data(?guild_boss_first_kill, Key) of
        [] -> Def;
        [#guild_boss_first_kill{killer_id = Val}] -> Val
    end.

set(Key, Val) ->
    dbcache:update(?guild_boss_first_kill, #guild_boss_first_kill{record_id = Key, killer_id = Val}).

