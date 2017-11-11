%%%-------------------------------------------------------------------
%%% @author fengzhu
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 11. 十一月 2017 下午1:22
%%%-------------------------------------------------------------------
-module(client).
-author("fengzhu").

-export([
    send/1,
    get_version/0
]).

send(BinMsg) ->
    SomeHostInNet = "localhost",
    {ok, Sock} = gen_tcp:connect(SomeHostInNet, 8080, [{active, true}, {packet, 0}]),
    io:format("server socket:~p~n",[Sock]),
    ok = gen_tcp:send(Sock, BinMsg),
    receive
        {tcp,Socket,String} ->
            io:format("Client received = ~p~n",[String]),
            gen_tcp:close(Socket);
        Data ->
            io:format("Data:~p~n", [Data])
    after 60000 ->
        exit
    end,
    ok = gen_tcp:close(Sock).

get_version() ->
    send("hello").
