-module(gm_controller_server_app).
-behaviour(application).

%% Application callbacks
-export([start/2, stop/1]).

-define(GM_CONTROLLER_PORT, 9010).


-define(GM_TCP_OPTIONS, 
    [binary,
        {packet, 0},
        {reuseaddr, true},
        {active, false},
        {nodelay, true},
        {delay_send, false},
        {send_timeout, 5000},
        {exit_on_close, true}
    ]
).

%% ===================================================================
%% Application callbacks
%% ===================================================================

start(_StartType, _StartArgs) ->
    gm_controller_server_sup:start_link(),
    #{gmport := GmPort} =global_data:get_server_info(),
    gm_controller_listener_sup:start_listener(
        gm_controller_server,
        5,
        GmPort,
        ?GM_TCP_OPTIONS,
        fun gm_controller_sup:start_child/1
    ),
    io:format("GM Server Start--------!!!!!!!!!!~n"),
    %global_data:add_gm_controller_port(GmPort),
    gm_controller_sup:start_link().

stop(_State) ->
    #{platform_id := PlatFormId, id := Id} =global_data:get_server_info(),
    op_player:clear_online_player(PlatFormId, Id),
    %io:format("*********************** op_player:clear_online_player *********************** ~p~n",[{PlatFormId, Id}]),
    gm_controller_listener_sup:stop_listener(?MODULE),
    ok.
