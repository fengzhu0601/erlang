%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 16. 二月 2016 上午11:48
%%%-------------------------------------------------------------------
-module(tcp_eng).
-author("clark").

%% API
-export
([
    start_system/1
    , stop_system/1
    , create/1
    , on_start_link/1
    , init/1
    , send/2
]).


-include("net_eng.hrl").
-include("inc.hrl").
-include("player.hrl").

-record(tcp_eng_state,
{
    socket = nil
}).


-define(TCP_OPTIONS,
    [
        binary
        , {active, false}
        , {packet, 0}
        , {reuseaddr, true}
        , {nodelay, true}
        , {delay_send, false}
        , {send_timeout, 5000}
        , {exit_on_close, true}
        %, {keepalive, true}
    ]
).



start_system(StartChildFun) ->
    Port = 5000,
    lc_listener_sup:start_listener
    (
        game
        , 5
        , Port
        , ?TCP_OPTIONS
        , StartChildFun
    ),
    ok.


stop_system(Mod) ->
    lc_listener_sup:stop_listener(Mod).

on_start_link(_State=#tcp_eng_state{socket=Socket}) ->
    inet:setopts(Socket, [binary, {nodelay, true}, {packet, 2}, {active, true}]),
    ok.

init(_State=#tcp_eng_state{socket=Socket}) ->
    com_process:init_type(?MODULE),
    erlang:put(?pd_socket, Socket),
    {ok,{IP_Address,Port}} = inet:peername(Socket),
    IP_Address1 = util:ip_to_str(IP_Address),
    erlang:put(?pd_account_ip, IP_Address1),
    erlang:put(?pd_account_port, Port),
    ok.

create(Socket) ->
    #net_eng
    {
        mod = tcp_eng,
        state = #tcp_eng_state{socket=Socket}
    }.

send(_State=#tcp_eng_state{socket=Socket}, Data) ->
    Data1 = <<(virtual_time:get_uptime()):64, Data/binary>>,
    prim_inet:send(Socket, Data1, []);
send(_, Data) ->
    error_logger:error_msg("send_error datatype is not binary ~p", [Data]).






