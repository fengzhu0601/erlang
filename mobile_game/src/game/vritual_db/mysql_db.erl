-module(mysql_db).

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
    #{mysql_config := MysqlConfig} = global_data:get_server_info(),
    [Host, Port, User, Password, DB, Encode] = MysqlConfig,
    msyql:start_link(?DB_POOL, Host, Port, User, Password, DB, fun(_, _, _, _) -> ok end, Encode),
    [
        begin
                mysql:connect(?DB_POOL, Host, Port, User, Password, DB, Encode, true)
        end || _ <- lists:duplicate(2, dummy)
    ],
    ok.

insert_new(Tab, Obj, [_RecordName | Fields]) ->
    [_ | Values] = tuple_to_list(Obj),
    db_mysql:insert(?DB_POOL, Tab, Fields, Values).

lookup(Tab, Key, [RecordName | Fields]) ->
    [Field | _] = Fields,
    case db_mysql:select_row(?DB_POOL, Tab, "*", [{Field, Key}]) of
        [] ->
            [];
        List ->
            [list_to_tuple([RecordName | List])]
    end.

lookup_element(Tab, Key, Pos, Fields) ->
    case lookup(Tab, Key, Fields) of
        [] ->
            [];
        [Record] ->
            element(Pos, Record)
    end.

update_element(Tab, Key, Op, [_ | Fields]) ->
    {ChangeField, Value} = Op,
    [Field | _] = Fields,
    db_mysql:update(?DB_POOL, Tab, [ChangeField], [Value], Field, Key).

update(Tab, Obj, [_RecordName | Fields]) ->
    [Field | _] = Fields,
    [_ | Values] = tuple_to_list(Obj),
    [Value | _] = Values,
    db_mysql:update(?DB_POOL, Tab, Fields, Values, Field, Value).

delete(Tab, Key, [_RecordName | Fields]) ->
    [Field | _] = Fields,
    db_mysql:delete(?DB_POOL, Tab, [{Field, Key}]).

stop_db() ->
    ok.
