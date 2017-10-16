-module(gm_controller_acceptor).

%% API.
-export([start_link/2]).

%% Internal.
-export([loop/2]).


%% API.
-spec start_link(inet:socket(),
                 gm_listener_sup:new_socket_owner()) -> {ok, pid()}.
start_link(LSocket, Func) ->
    Pid = spawn_link(?MODULE, loop, [LSocket, Func]),
    {ok, Pid}.

%% Internal.
-spec loop(inet:socket(),
           gm_listener_sup:new_socket_owner()) -> no_return().
loop(LSocket, Func) ->
    case gen_tcp:accept(LSocket, infinity) of
        {ok, CSocket} ->
            io:format("gm_controller_acceptor 23 new gm socket request, socket :~p~n", [CSocket]),
            case Func(CSocket) of
                {ok, Pid} ->
                    case gen_tcp:controlling_process(CSocket, Pid) of
                        ok ->
                            io:format("tcp accepted!~n");
                        {error, Reason} ->
                            io:format("controlling_process error Reason:~p~n",[Reason]),
                            gen_tcp:close(CSocket)
                    end;
                R ->
                    io:format("new socket owner process start falied:~p~n", [R])
            end;
        {error, emfile} ->
            receive after 100 -> ok end;
        %% We want to crash if the listening socket got closed.
        {error, Reason} when Reason =/= closed ->
            ok;
        _Msg ->
            io:format("get a unknow msg~p\n", [_Msg])
    end,
    loop(LSocket, Func).
