-module(db_mysql).

%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("include/common.hrl").

%% --------------------------------------------------------------------
%% Exported Functions
%% --------------------------------------------------------------------
-export([
    insert/3,
    insert/4,

    replace/3,
    replace/4,

    update/4,
    update/5,
    update/6,

    select_all/4,
    select_all/6,

    select_one/4,
    select_one/6,

    select_row/3,
    select_row/4,
    select_row/6,

    select_count/3,

    get_all/2,

    delete/3,

    transaction/2,


    delete_call/3,
    update_call/4,
    update_call/5,
    update_call/6,
    insert_call/3,
    insert_call/4,

    select_limit/3,
    select_limit/4,

    execute_raw_sql/1
]).

-export([
    insert_admin_sql/2,
    insert_admin_sql/3
]).


execute_raw_sql(Sql) ->
    case mysql:fetch(?DB_POOL, Sql) of
        {data, {_, _, R, _, _}} -> 
            R;
        {error, {_, _, _, _, Reason}} -> 
            mysql_halt([Sql, Reason]);
        E ->
            io:format("execute_raw_sql--------------------------:~p~n",[Sql])
    end.
%% ====================================================================
%% API Functions
%% ====================================================================

%% 执行分页查询返回结果中的所有行
select_limit(Sql, Offset, Num) ->
    S = list_to_binary([Sql, <<" limit ">>, integer_to_list(Offset), <<", ">>, integer_to_list(Num)]),
    % io:format("db mysql S------------------------------:~p~n",[S]),
    case mysql:fetch(?DB_POOL, S) of
        {data, {_, _, R, _, _}} -> R;
        {error, {_, _, _, _, Reason}} -> mysql_halt([Sql, Reason])
    end.
select_limit(Sql, Args, Offset, Num) ->
    S = list_to_binary([Sql, <<" limit ">>, list_to_binary(integer_to_list(Offset)), <<", ">>, list_to_binary(integer_to_list(Num))]),
    mysql:prepare(s, S),
    case mysql:execute(?DB_POOL, s, Args) of
        {data, {_, _, R, _, _}} -> R;
        {error, {_, _, _, _, Reason}} -> mysql_halt([Sql, Reason])
    end.

-spec insert(atom(), atom(), list(), list()) -> integer() | abort.
%% @doc 插入数据到表。
%% 返回影响的行数，发生错误则会终止当前进程。
insert(DB_Pool, Table_name, FieldList, ValueList) ->
    Sql = db_mysqlutil:make_insert_sql(Table_name, FieldList, ValueList),
    % io:format("Sql-----------------:~p~n",[Sql]),
    execute_cast(DB_Pool, Sql).

-spec insert(atom(), atom(), list()) -> integer() | abort.
%% @doc 插入数据到表。
%% @see insert/4
insert(DB_Pool, Table_name, Field_Value_List) ->
    Sql = db_mysqlutil:make_insert_sql(Table_name, Field_Value_List),
    execute_cast(DB_Pool, Sql).

-spec insert_admin_sql(atom(), list(), list()) -> sql.
%% @doc 得到插入数据到表所需的sql语句。
%% 返回插入数据库的sql语句
insert_admin_sql(Table_name, FieldList, ValueList) ->
    db_mysqlutil:make_insert_sql(Table_name, FieldList, ValueList).

-spec insert_admin_sql(atom(), list()) -> sql.
%% @doc 得到插入数据到表所需的sql语句。
%% @see insert_admin_sql/3
insert_admin_sql(Table_name, Field_Value_List) ->
    db_mysqlutil:make_insert_sql(Table_name, Field_Value_List).

-spec replace(atom(), atom(), list(), list()) -> integer() | abort.
%% @doc 替换表中数据，如果不存在则插入。
%% 返回影响的行数，发生错误则会终止当前进程。
replace(DB_Pool, Table_name, FieldList, ValueList) ->
    Sql = db_mysqlutil:make_replace_sql(Table_name, FieldList, ValueList),
    execute(DB_Pool, Sql).

-spec replace(atom(), atom(), list()) -> integer() | abort.
%% @doc 替换表中数据，如果不存在则插入。
%% @see replace/4
replace(DB_Pool, Table_name, Field_Value_List) ->
    Sql = db_mysqlutil:make_replace_sql(Table_name, Field_Value_List),
    execute(DB_Pool, Sql).

-spec update(atom(), atom(), list(), list(), atom(), term()) -> integer() | abort.
%% @doc 根据主键更新表中数据。
%% 返回影响的行数，发生错误则会终止当前进程。
update(DB_Pool, Table_name, Field, Data, Key, Value) ->
    Sql = db_mysqlutil:make_update_sql(Table_name, Field, Data, Key, Value),
%%     io:format("update update--------------------------------------:~p~n",[Table_name]),
    %execute_cast(DB_Pool, Sql).
    execute_update(DB_Pool, Sql).


-spec update(atom(), atom(), list(), list(), list()) -> integer() | abort.
%% @doc 根据条件更新表中数据.
%% @see update/6
update(DB_Pool, Table_name, Field, Data, Where_List) ->
    Sql = db_mysqlutil:make_update_sql(Table_name, Field, Data, Where_List),
    execute_cast(DB_Pool, Sql).

-spec update(atom(), atom(), list(), list()) -> integer() | abort.
%% @doc 根据条件更新表中数据.
%% @see update/6
update(DB_Pool, Table_name, Field_Value_List, Where_List) ->
    Sql = db_mysqlutil:make_update_sql(Table_name, Field_Value_List, Where_List),
    execute_cast(DB_Pool, Sql).

-spec select_one(atom(), atom(), string(), list(), list(), [integer()]) -> null | term() | abort.
%% @doc Select limit value of special field from table by order.
%% If success, return null when no data, value when get data,
%% otherwise stop current process and throw reason.
%%
%% [Note]:Only one value will return, means the param Limit_num always ignore.
select_one(DB_Pool, Table_name, Fields_sql, Where_List, Order_List, Limit_num) ->
    Sql = db_mysqlutil:make_select_sql(Table_name, Fields_sql, Where_List, Order_List, Limit_num),
    get_one(DB_Pool, Sql).

-spec select_one(atom(), atom(), string(), list()) -> null | term() | abort.
%% @doc Select value of special field from table.
%% @see select_one/5
select_one(DB_Pool, Table_name, Fields_sql, Where_List) ->
    Sql = db_mysqlutil:make_select_sql(Table_name, Fields_sql, Where_List),
    get_one(DB_Pool, Sql).

-spec select_row(atom(), atom(), string(), list(), list(), [integer()]) -> [] | list() | abort.
%% @doc Select limit rows of special field from table by order.
%% Return list(maybe empty) if success,
%% otherwise stop current process and throw reason.
%%
%% [Note]:Only one row will return, means the param Limit_num always ignore.
select_row(DB_Pool, Table_name, Fields_sql, Where_List, Order_List, Limit_num) ->
    Sql = db_mysqlutil:make_select_sql(Table_name, Fields_sql, Where_List, Order_List, Limit_num),
    get_row(DB_Pool, Sql).

-spec select_row(atom(), atom(), string(), list()) -> [] | list() | abort.
%% @doc Select limit rows of special field from table.
%% @see select_row/5
select_row(Table_name, Fields_sql, Where_List) ->
   select_row(?DB_POOL, Table_name, Fields_sql, Where_List).
select_row(DB_Pool, Table_name, Fields_sql, Where_List) ->
    Sql = db_mysqlutil:make_select_sql(Table_name, Fields_sql, Where_List),
    %io:format("db_mysql 169 Sql------------------------:~p~n",[Sql]),
    get_row(DB_Pool, Sql).

-spec select_count(atom(), atom(), list()) -> [integer()] | abort.
%% @doc Select the counts of rows.
%% Return the counts in list if success,
%% otherwise stop current process and throw reason.
select_count(DB_Pool, Table_name, Where_List) ->
    select_row(DB_Pool, Table_name, "count(1)", Where_List).

-spec select_all(atom(), atom(), string(), list(), list(), [integer()]) -> [] | [list()] | abort.
%% @doc Select limit rows of special field from table by order.
%% Return list(maybe empty) of rows if success,
%% otherwise stop current process and throw reason.
select_all(DB_Pool, Table_name, Fields_sql, Where_List, Order_List, Limit_num) ->
    Sql = db_mysqlutil:make_select_sql(Table_name, Fields_sql, Where_List, Order_List, Limit_num),
    get_all(DB_Pool, Sql).

-spec select_all(atom(), atom(), string(), list()) -> [] | [list()] | abort.
%% @doc Select all rows of special field from table.
%% @see select_all/5
select_all(DB_Pool, Table_name, Fields_sql, Where_List) ->
    Sql = db_mysqlutil:make_select_sql(Table_name, Fields_sql, Where_List),
    get_all(DB_Pool, Sql).

-spec delete(atom(), atom(), list()) -> integer() | abort.
%% @doc Delete the special rows.
%% Return count of affected rows if success,
%% otherwise stop current process and throw reason.
delete(DB_Pool, Table_name, Where_List) ->
    Sql = db_mysqlutil:make_delete_sql(Table_name, Where_List),
    execute_cast(DB_Pool, Sql).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%新的API函数begin
delete_call(DB_Pool, Table_name, Where_List) ->
    Sql = db_mysqlutil:make_delete_sql(Table_name, Where_List),
    execute(DB_Pool, Sql).

update_call(DB_Pool, Table_name, Field, Data, Key, Value) ->
    Sql = db_mysqlutil:make_update_sql(Table_name, Field, Data, Key, Value),
    execute(DB_Pool, Sql).

update_call(DB_Pool, Table_name, Field, Data, Where_List) ->
    Sql = db_mysqlutil:make_update_sql(Table_name, Field, Data, Where_List),
    execute(DB_Pool, Sql).

update_call(DB_Pool, Table_name, Field_Value_List, Where_List) ->
    Sql = db_mysqlutil:make_update_sql(Table_name, Field_Value_List, Where_List),
    execute(DB_Pool, Sql).

insert_call(DB_Pool, Table_name, FieldList, ValueList) ->
    Sql = db_mysqlutil:make_insert_sql(Table_name, FieldList, ValueList),
    execute(DB_Pool, Sql).

insert_call(DB_Pool, Table_name, Field_Value_List) ->
    Sql = db_mysqlutil:make_insert_sql(Table_name, Field_Value_List),
    execute(DB_Pool, Sql).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%新的API函数end



-spec transaction(atom(), function()) -> mysql:query_result() | abort.
%% @doc Execute a transaction in a connection belonging to the connection pool.
%% F is a function containing a sequence of calls to fetch() and/or execute().
transaction(DB_Pool, F) ->
    try
        case mysql:transaction(DB_Pool, F) of
            {atomic, R} -> R;
            {aborted, {Reason, _}} -> mysql_halt([Reason]);
            _ ->
%                ?NODE_ERROR_LOG("DB MYSQL unkonwn ERROR "),
                ok
        end
    of
        Value ->
            Value
    catch
        E:W ->
            ?NODE_ERROR_LOG("execute mysql error E=~p W=~p F=~ts",[E,W,F]),
            error
    end.

%% ====================================================================
%% Local Functions
%% ====================================================================
execute(DB_Pool, Sql) ->
    try
        case mysql:fetch(DB_Pool, Sql) of
            {updated, {_, _, _, R, _}} -> R;
            {error, {_, _, _, _, Reason}} -> mysql_halt([Sql, Reason]);
            _CurError ->
                ?NODE_ERROR_LOG("DB MYSQL unkonwn ERROR CurError=~ts",[_CurError]),
                ok
        end
    of
        Value ->
            Value
    catch
        E:W ->
            ?NODE_ERROR_LOG("execute mysql error E=~p W=~p Sql=~ts",[E,W,Sql]),
            error
    end.

execute_cast(DB_Pool, Sql) ->
    try
        case mysql:fetch(DB_Pool, Sql) of
            {updated, {_, _, _, R, _}} -> R;
            {error, {_, _, _, _, Reason}} -> mysql_halt([Sql, Reason]);
            _CurError ->
                ?NODE_ERROR_LOG("DB MYSQL unkonwn ERROR CurError=~ts",[_CurError]),
                ok
        end
    of
        Value ->
            Value
    catch
        E:W ->
            ?NODE_ERROR_LOG("execute mysql error E=~p W=~p Sql=~ts",[E,W,Sql]),
            error
    end.


execute_update(DB_Pool, Sql) ->
    try
        case mysql:fetch_cast(DB_Pool, Sql) of
            {updated, {_, _, _, R, _}} -> R;
            {error, {_, _, _, _, Reason}} -> mysql_halt([Sql, Reason]);
            _CurError ->
                ok
        end
    of
        Value ->
            Value
    catch
        E:W ->
            ?ERROR_LOG("execute mysql error E=~p W=~p Sql=~ts",[E,W,Sql]),
            error
    end.


get_one(DB_Pool, Sql) ->
    try
        case mysql:fetch(DB_Pool, Sql) of
            {data, {_, _, [], _, _}} -> null;
            {data, {_, _, [[R]], _, _}} -> R;
            {error, {_, _, _, _, Reason}} -> mysql_halt([Sql, Reason]);
            _CurError ->
                ?NODE_ERROR_LOG("DB MYSQL unkonwn ERROR CurError=~ts",[_CurError]),
                ok
        end
    of
        Value ->
            Value
    catch
        E:W ->
            ?NODE_ERROR_LOG("execute mysql error E=~p W=~p Sql=~ts",[E,W,Sql]),
            error
    end.


get_row(DB_Pool, Sql) ->
    try
        case mysql:fetch(DB_Pool, Sql) of
            {data, {_, _, [], _, _}} -> [];
            {data, {_, _, [R], _, _}} -> R;
            {error, {_, _, _, _, Reason}} -> mysql_halt([Sql, Reason]);
            _CurError ->
                ?NODE_ERROR_LOG("DB MYSQL unkonwn ERROR CurError=~p Sql=~ts",[_CurError,Sql]),
                []
        end
    of
        Value ->
            Value
    catch
        E:W ->
            ?NODE_ERROR_LOG("execute mysql error E=~p W=~p Sql=~ts",[E,W,Sql]),
            error
    end.


get_all(DB_Pool, Sql) ->
    try
        case mysql:fetch(DB_Pool, Sql) of
            {data, {_, _, R, _, _}} -> R;
            {error, {_, _, _, _, Reason}} -> mysql_halt([Sql, Reason]);
            _CurError ->
                ?NODE_ERROR_LOG("DB MYSQL unkonwn ERROR CurError=~p Sql=~ts",[_CurError,Sql]),
                ok
        end
    of
        Value ->
            Value
    catch
        E:W ->
            ?NODE_ERROR_LOG("execute mysql error E=~p W=~p Sql=~ts",[E,W,Sql]),
            error
    end.

mysql_halt([Sql, Reason]) ->
    ?NODE_ERROR_LOG("DB MYSQL ERROR:~ts ~p",[Sql,Reason]),
    error.
