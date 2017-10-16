%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 19. 十月 2015 下午2:53
%%%-------------------------------------------------------------------
-module(load_db_misc).
-author("clark").

%% API
-export(
[
    load/0
    ,get/2
    ,set/2
    ,get_emails/1
    ,set_emails/2
    ,init_emails/0
    ,show_emails/0
    ,get_guild_boss_reset_tm/0
    ,set_guild_boss_reset_tm/1
    ,add_bounty_type_once/1
]).

-include("inc.hrl").
-include("load_db_misc.hrl").
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
            name = ?g_misc_tab,
            fields = ?record_fields(?g_misc_tab),
            shrink_size = 10,
            flush_interval = 0 %% dirty
        }
    ].


load(_M, _M) ->
    % set(?misc_server_start_time, util:get_now_time()),
    ret:ok();

load(Min, Max) ->
    case dbcache:load_data(?g_misc_tab, Min) of
        [] ->
            dbcache:insert_new(?g_misc_tab, #g_misc_tab{id = Min, val = undefined});
        _ ->
            ret:ok()
    end,
    load(Min+1, Max).
load() -> load(?misc_begin, ?misc_end+1).

get(Key, Def) ->
    case dbcache:load_data(?g_misc_tab, Key) of
        [] -> Def;
        [#g_misc_tab{val = Val}] ->
            case Val of
                undefined -> Def;
                [] -> Def;
                _ -> Val
            end
    end.

set(Key, Val) ->
    dbcache:update(?g_misc_tab, #g_misc_tab{id = Key, val = Val}).

get_emails(PlayerID) ->
    List = get(?misc_player_email, []),
%%     ?INFO_LOG("misc_player_email g ~p",[List]),
    case lists:keyfind(PlayerID, 1, List) of
        false -> [];
        {_, MsgList} -> MsgList
    end.

set_emails(PlayerID, MsgList) ->
    List = get(?misc_player_email, []),
%%     ?INFO_LOG("misc_player_email s ~p",[List]),
    List1 = lists:keystore(PlayerID, 1, List, {PlayerID, MsgList}),
    set(?misc_player_email, List1).

init_emails() ->
    set(?misc_player_email, []).

show_emails() ->
    List = get(?misc_player_email, []),
    info_log:player(get(?pd_id), get(?pd_name), List).


get_guild_boss_reset_tm() ->
    get(?misc_guild_boss_reset_tm, 0).


set_guild_boss_reset_tm(Tm) ->
    set(?misc_guild_boss_reset_tm, Tm).

add_bounty_type_once(BountyType) ->
    gen_server:call
    (
        bounty_server,
        {
            count_bounty_times,
            BountyType
        }
    ).

