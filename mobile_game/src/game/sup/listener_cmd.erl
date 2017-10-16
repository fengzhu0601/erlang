%%% coding:utf-8
%%%-------------------------------------------------------------------
%%% @author zl
%%% @doc  客户端链接池
%%%
%%% @end
%%%-------------------------------------------------------------------

-module(listener_cmd).

-export
([
    start_child/0
    , stop_child/0
]).



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


start_child() ->
    #{port := Port} = global_data:get_server_info(),
    lc_listener_sup:start_listener
    (
        game
        , 5
        , Port
        , ?TCP_OPTIONS
        , fun player_sup:start_child/1
    ).


stop_child() ->
    lc_listener_sup:stop_listener(?MODULE).
