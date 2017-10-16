-module(db_agent).

-include("include/common.hrl").

-export([
		 init_db/0
		]).

%% ====================================================================
%% API Functions
%% ====================================================================
-spec init_db() -> ok.
%% @doc Initialize database connection.
init_db() ->
	io:format("init_db--------------------------------------:~n"),
    #{mysql_config := MysqlConfig} =global_data:get_server_info(),
    io:format("MysqlConfig------------------------:~p~n",[MysqlConfig]),
	[Host, Port, User, Password, DB, Encode] = MysqlConfig,
 	Re = mysql:start_link(?DB_POOL, Host, Port, User, Password, DB,  fun(_, _, _, _) -> ok end, Encode),
	io:format("Re--------------------------------:~p~n",[Re]),
	LTemp = lists:duplicate(10, dummy),
	[begin
		 mysql:connect(?DB_POOL, Host, Port, User, Password, DB, Encode, true)
	 end || _ <- LTemp],
	io:format("db_agent--------------------------------is ok:~n"),
	ok.

