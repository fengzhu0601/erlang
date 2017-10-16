-module(erlang_db).

-include_lib("erlang_mysql/include/common.hrl").

-export(
    [
        init_db/0,
        insert_new/3,
        lookup/3,
        lookup_element/4,
        update_element/4,
        update/3,
        delete/3,
        stop_db/0
    ]
).

%% ============================================================
%% API FUNCTIONS
%% ============================================================
init_db() ->
    ok.

insert_new(Tab, Obj, _) ->
    dbcache:insert_new(Tab, Obj).

lookup(Tab, Key, _) ->
    dbcache:lookup(Tab, Key).

lookup_element(Tab, Key, Pos, _) ->
    dbcache:lookup_element(Tab, Key, Pos).

update_element(Tab, Key, Op, _) ->
    dbcache:update_element(Tab, Key, Op).

update(Tab, Obj, _) ->
    dbcache:update(Tab, Obj).

delete(Tab, Key, _) ->
    dbcache:delete(Tab, Key).

stop_db() ->
    ok.
