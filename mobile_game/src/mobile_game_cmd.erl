%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 07. 十二月 2015 下午1:48
%%%-------------------------------------------------------------------
-module(mobile_game_cmd).
-author("clark").

%% API
-export
([
    start/0
    , stop/0
]).

-export
([
    start_pangzi/0
]).


%% ------------------------------------------------
%% game
%% ------------------------------------------------

base_apps() ->
    % [global_table, pangzi, esqlite, config, lc, system_broadcast].
    [global_table, pangzi, config, lc, system_broadcast,cron].

start() ->
%%    virtual_time:init_uptime(),
    lager:start(),
    inets:start(),
    [ok = application:start(App) || App <- base_apps()],
    application:start(mobile_game),
    application:start(gm_controller_server),
    io:format("~n~n[============= Server Start =============] ~n~n"),
    version:show(),
    ok.

stop() ->
    application:stop(gm_controller_server),
    application:stop(mobile_game),
    [application:stop(App) || App <- lists:reverse(base_apps())],
    init:stop(),
    io:format("~n~n[============= Server Stop =============] ~n~n"),
    ok.


%% ------------------------------------------------
%% pangzi
%% ------------------------------------------------

start_pangzi() ->
    application:start(pangzi),
    timer:sleep(5000),
    application:stop(pangzi),
    init:stop().