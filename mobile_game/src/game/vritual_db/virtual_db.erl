%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 14. 十二月 2015 下午12:41
%%%-------------------------------------------------------------------
-module(virtual_db).
-author("clark").

-include_lib("erlang_mysql/include/common.hrl").

-include("virtual_db.hrl").

%% API
-export(
    [
        init_db/1,
        insert_new/4,
        lookup/4,
        lookup_element/5,
        update_element/5,
        update/4,
        delete/4,
        stop_db/1
    ]
).

%% ============================================================
%% API FUNCTIONS
%% ============================================================
init_db(DbKey) ->
	case get_mod(DbKey) of
		error ->
			?ERROR_LOG("bad DbKey with [~p] ", [DbKey]);
		Mod ->
			Mod:init_db()
	end.

insert_new(DbKey, Tab, Obj, Fields) ->
	case get_mod(DbKey) of
		error ->
			?ERROR_LOG("bad DbKey with [~p] when Tab = ~p, Obj = ~p, Fields = ~p", [DbKey, Tab, Obj, Fields]);
		Mod ->
			Mod:insert_new(Tab, Obj, Fields)
	end.

lookup(DbKey, Tab, Key, Fields) ->
	case get_mod(DbKey) of
		error ->
			?ERROR_LOG("bad DbKey with [~p] when Tab = ~p, Key = ~p, Fields = ~p", [DbKey, Tab, Key, Fields]);
		Mod ->
			Mod:lookup(Tab, Key, Fields)
	end.

lookup_element(DbKey, Tab, Key, Pos, Fields) ->
	case get_mod(DbKey) of
		error ->
			?ERROR_LOG("bad DbKey with [~p] when Tab = ~p, Key = ~p, Pos = ~p, Fields = ~p", [DbKey, Tab, Key, Pos, Fields]);
		Mod ->
			Mod:lookup_element(Tab, Key, Pos, Fields)
	end.

update_element(DbKey, Tab, Key, Pos, Fields) ->
	case get_mod(DbKey) of
		error ->
			?ERROR_LOG("bad DbKey with [~p] when Tab = ~p, Key = ~p, Pos = ~p, Fields = ~p", [DbKey, Tab, Key, Pos, Fields]);
		Mod ->
			Mod:update_element(Tab, Key, Pos, Fields)
	end.

update(DbKey, Tab, Obj, Fields) ->
	case get_mod(DbKey) of
		error ->
			?ERROR_LOG("bad DbKey with [~p] when Tab = ~p, Obj = ~p, Fields = ~p", [DbKey, Tab, Obj, Fields]);
		Mod ->
			Mod:udpate(Tab, Obj, Fields)
	end.

delete(DbKey, Tab, Key, Fields) ->
	case get_mod(DbKey) of
		error ->
			?ERROR_LOG("bad DbKey with [~p] when Tab = ~p, Key = ~p, Fields = ~p", [DbKey, Tab, Key, Fields]);
		Mod ->
			Mod:delete(Tab, Key, Fields)
	end.

stop_db(DbKey) ->
	case get_mod(DbKey) of
		error ->
			?ERROR_LOG("bad DbKey with [~p]", [DbKey]);
		Mod ->
			Mod:stop_db()
	end.


%% ============================================================
%% PRIVATE
%% ============================================================
get_mod(DbKey) ->
	case DbKey of
		?quick_db -> erlang_db;
		?safe_db -> mysql_db;
		_ -> error
	end.