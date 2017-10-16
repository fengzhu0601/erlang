-module(com_listen).


-define(INFO, 1). %% show ?INFO_LOG
-include("com_log.hrl").

                                                %-define(TCP_OPTIONS, [binary, {packet, 0}, {reuseaddr, true},
                                                %{nodelay, false}, {delay_send, true}, {send_timeout, 5000},
                                                %{keepalive, true}, {exit_on_close, true}]).


-record(state, {name, lport, lsocket, new_socket_callback}).

-export([start_link/4, start/4]).

-export_type([s_new_socket_owner/0]).
%% 返回新socket 需要 controlling_process 的进程pid
-type s_new_socket_owner() :: fun((port()) -> {ok, pid()}).

start_link(RegisterName, ListenPort, TCPOptions, SocketOwner) ->
                                                %_ = code:ensure_loaded(SocketOwner),
                                                %case erlang:function_exported(Transport, name, 0) of
                                                %false ->
                                                %{error, badarg};
                                                %true ->
                                                %end
    {ok, spawn_link(?MODULE, start, [RegisterName,ListenPort,TCPOptions,SocketOwner])}.

%%===================================================================================
%% Internal funcs
%%===================================================================================

%%--------------------------------------------------------------------
%% @doc Starts the server
%% @end
-spec start(atom(),
            non_neg_integer(),
            list(),
            s_new_socket_owner()) -> {stop, atom()}.
start(RegisterName, ListenPort, TCP_Options, SocketOwner)
  when
      is_atom(RegisterName),
      ListenPort > 0, ListenPort < 65535,
      is_function(SocketOwner) ->

    erlang:register(RegisterName, erlang:self()),
    case gen_tcp:listen(ListenPort, TCP_Options) of
        %% TODO
        {ok, LSocket} ->
            ?INFO_LOG("~p start listening ~p", [RegisterName, ListenPort]),
            accept(#state{name=RegisterName, lsocket = LSocket,
                          lport=ListenPort, new_socket_callback=SocketOwner});
        {error, Reason}->
            ?INFO_LOG("~p listen error ~p", [RegisterName, Reason]),
            {stop, Reason}
                                                %{'EXIT', shutdown} -> %% recive sup stop
                                                %?INFO_LOG("")

    end.


                                                %stop(Name) ->
                                                %TODO

%%--------------------------------------------------------------------
%% Internal functions
%%--------------------------------------------------------------------
accept(#state{lsocket=LSocket, new_socket_callback=CallBack} =State) ->
    {ok, Socket} = gen_tcp:accept(LSocket),
    {ok, Pid} = CallBack(Socket),
    case gen_tcp:controlling_process(Socket, Pid) of
        ok ->
            ok;
        {error, Reason} ->
            ?ERROR_LOG("controlling_process ~p error:~p", [Pid, Reason])
    end,
    accept(State).
