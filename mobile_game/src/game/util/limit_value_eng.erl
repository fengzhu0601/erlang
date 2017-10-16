%%%-------------------------------------------------------------------
%%% @author 
%%% @doc 提供有时限要求的变量存储和使用
%%% @end
%%%-------------------------------------------------------------------

-module(limit_value_eng).

-include_lib("common/include/inc.hrl").
-include_lib("pangzi/include/pangzi.hrl").

-include("inc.hrl").
-include("player.hrl").
-include("player_mod.hrl").
-include("day_reset.hrl").
-define(player_limit_value_tab, player_limit_value_tab).
-define(pd_daily_value, pd_daily_value).


%% API for player process
-export
([
    set_daily_value/2
    , inc_daily_value/1
    , get_daily_value_int/1
    , get_daily_value/1
    , get_daily_value/2
]).

-record(limit_value_tab, {id :: player_id()           %% 用户ID
    , daily_value                %% 日变量 gb_trees:empty()
}).


set_daily_value(Key, Value) ->  %% 已经有的主键会被覆盖
    Tree = get(?pd_daily_value),
    Tree2 = gb_trees:enter(Key, Value, Tree),
    put(?pd_daily_value, Tree2).

inc_daily_value(Key) ->  %% 自增每日变量
    Tree = get(?pd_daily_value),
    Tree2 =
        case gb_trees:lookup(Key, Tree) of
            {value, Value} -> gb_trees:update(Key, Value + 1, Tree);
            _ -> gb_trees:insert(Key, 1, Tree)
        end,
    put(?pd_daily_value, Tree2).

get_daily_value_int(Key) ->   %% 获取每日变量
    Tree = get(?pd_daily_value),
    case gb_trees:lookup(Key, Tree) of
        {value, Value} when is_integer(Value) -> Value;
        _E -> 0
    end.
get_daily_value(Key) ->   %% 获取每日变量
    get_daily_value(Key, ?undefined).

get_daily_value(Key, Def) ->   %% 获取每日变量
    Tree = get(?pd_daily_value),
    case gb_trees:lookup(Key, Tree) of
        {value, Value} -> Value;
        _ -> Def
    end.
create_mod_data(PlayerId) ->
    case dbcache:insert_new(?player_limit_value_tab,
        #limit_value_tab{id = PlayerId
            , daily_value = gb_trees:empty()
        }
    )
    of
        ?true -> ok;
        ?false ->
            ?ERROR_LOG("player ~p create player_limit_value_tab  not alread exists ", [PlayerId])
    end,
    ok.
load_mod_data(PlayerId) ->
    case dbcache:load_data(?player_limit_value_tab, PlayerId) of
        [] ->
            create_mod_data(PlayerId),
            load_mod_data(PlayerId);
        [#limit_value_tab{daily_value = DV}] ->
            ?pd_new(?pd_daily_value, DV)
    end,
    ok.

offline(_PlayerId) ->
    ok.

save_data(PlayerId) ->
    dbcache:update(?player_limit_value_tab, #limit_value_tab{id = PlayerId,
        daily_value = get(?pd_daily_value)}),
    ok.



init_client() -> nonused.
view_data(Acc) -> Acc.

on_day_reset(_Player) ->
    put(?pd_daily_value, gb_trees:empty()).

%% handle_frame(?frame_zero_clock) ->
%%     put(?pd_daily_value, gb_trees:empty()),
%%     ok;

handle_frame(_) -> ok.

online() ->
    case player:is_daliy_first_online() of
        true ->
            put(?pd_daily_value, gb_trees:empty());
        _ -> ignore
    end,
    ok.


handle_msg(FromMod, Msg) ->
    ?ERROR_LOG("~p recv a unknown msg ~p from ~p", [?pname(), Msg, FromMod]).

load_db_table_meta() ->
    [
        #db_table_meta{
            name = ?player_limit_value_tab,
            fields = ?record_fields(limit_value_tab),
            record_name = limit_value_tab,
            shrink_size = 1,
            flush_interval = 2
        }
    ].
