%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 27. 十月 2015 下午3:36
%%%-------------------------------------------------------------------
-module(info_log).
-author("clark").

%% API
-export
([
    init/1
    ,info_log/2
    ,info_log_ex/2
    ,terminate/2
]).

-export
([
    push/1
    ,player/3
    ,push_error/1
]).



-include_lib("common/include/com_log.hrl").
% -include_lib("system_log.hrl").
-include("event_server.hrl").


-define(io_device, io_device).
-define(GAME_LOG_FILE, "log/info_log_file.log").





init(Args) ->
    ?INFO_LOG("event_server ~p",[Args]),
    event_server:sub_info(log, {info_log, info_log}),
    event_server:sub_info(log_ex, {info_log, info_log_ex}),
    event_server:sub_terminate({info_log, terminate}),
    {ok, S} = file:open( ?GAME_LOG_FILE, [append, write,  {encoding, utf8}] ),
    erlang:put(?io_device, S),
    {ok, nil}.

push(Context) ->
    ?MODULE ! {log, {self(), Context}}.

player(PlayerId, PlayerName, Log) ->
    ?MODULE ! {log_ex, {PlayerId, PlayerName, Log}}.

push_error(Context) ->
    ?MODULE ! {log, {self(), {error, Context}}}.

info_log({Pid, Log}, State) ->
    Time = calendar:local_time(),
%%     ?INFO_LOG("Pid:~p Time:~p ~n Log:~p ~n",
%%         [
%%             Pid,
%%             Time,
%%             Log
%%         ]),
    S = erlang:get(?io_device),
    io:format(S, "Pid:~p Time:~p ~n Log:~p ~n",
        [
            Pid,
            Time,
            Log
        ]),
    ?info_noreply(State).

info_log_ex({PlayerId, PlayerName, Log}, State) ->
    S = erlang:get(?io_device),
    io:format(S, "~n~n===== TIME:~p =====~nPlayerId:~p~nName:~ts~nLog:~p~n~n", [erlang:localtime(), PlayerId, PlayerName, Log]),
    ?info_noreply(State).

terminate(_Reason, _State) ->
    S = erlang:get(?io_device),
    file:close(S).

