-include("mysql.hrl").
-include_lib("common/include/com_log.hrl").
%% database config 
%% --------------------------------------------------------------------
-define(DB_MODULE, db_mysql).
-define(DB_POOL, mysql_conn).
-define(DB_POOL_ADMIN, mysql_conn_admin).
-define(DB_LABEL, 1).
-define(DB_LABEL_EFFORT, 2).

%% tcp
%% --------------------------------------------------------------------
-define(TCP_OPTIONS, [binary, {packet, 0}, {active, false}, {reuseaddr, true}, {nodelay, false}, {delay_send, true}, {send_timeout, 5000}, {keepalive, false}, {exit_on_close, true}]).

%% time
%% --------------------------------------------------------------------
-define(DIFF_SECONDS_1970_1900, 2208988800).
-define(DIFF_SECONDS_0000_1900, 62167219200).
-define(ONE_DAY_SECONDS,        86400).
-define(ONE_DAY_MILLISECONDS, 86400000).


%% JSON - RFC 4627 - for Erlang
%% --------------------------------------------------------------------
%% Given a record type definiton of ``-record(myrecord, {field1,
%% field})'', and a value ``V = #myrecord{}'', the code
%% ``?JSON_FROM_RECORD(myrecord, V)'' will return a JSON "object"
%% with fields corresponding to the fields of the record. The macro
%% expands to a call to the `from_record' function.
-define(JSON_FROM_RECORD(RName, R),
		json:from_record(R, RName, record_info(fields, RName))).

%% Given a record type definiton of ``-record(myrecord, {field1,
%% field})'', and a JSON "object" ``J = {obj, [{"field1", 123},
%% {"field2", 234}]}'', the code ``?JSON_TO_RECORD(myrecord, J)''
%% will return a record ``#myrecord{field1 = 123, field2 = 234}''.
%% The macro expands to a call to the `to_record' function.
-define(JSON_TO_RECORD(RName, R),
		json:to_record(R, #RName{}, record_info(fields, RName))).
%% --------------------------------------------------------------------


%% ets define
%% --------------------------------------------------------------------
-define(ETS_SERVER_NODE, ets_server_node).
-define(ETS_SYSTEM_INFO,  ets_system_info).
-define(ETS_MONITOR_PID,  ets_monitor_pid).
-define(ETS_STAT_SOCKET, ets_stat_socket).
-define(ETS_STAT_DB, ets_stat_db).								%% 数据库访问统计(表名，操作，次数)

%% 查询标识
-define(SERCH_FLAG_ALL, 0).
-define(SERCH_FLAG_STORE, 1).
