-module(connection_mysql).


-export([
	set_mysql_connection/0,
	test_insert/0
]).

-include("include/common.hrl").


set_mysql_connection() ->
    #{mysql_config := MysqlConfig} =global_data:get_server_info(),
    io:format("MysqlConfig-------------------:~p~n",[MysqlConfig]),
	[Host, Port, User, Password, DB, Encode] = MysqlConfig,
	mysql:start_link(?DB_POOL, Host, Port, User, Password, DB,  fun(_, _, _, _) -> ok end, Encode),
	io:format("mysql start_link---------------------------------------ok~n"),
	mysql:connect(?DB_POOL, Host, Port, User, Password, DB, Encode, true),
	io:format("connection mysqln -------------------------------------ok~n"),
	%test_insert(),
	ok.

test_insert() ->
	Res3 = mysql:fetch(?DB_POOL,"select level from `player` where `player_id`=63"),
	io:format("Res3----------------------------------:~p~n",[Res3]).
