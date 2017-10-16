%%%-------------------------------------------------------------------
%%% @author yujian
%%% @doc 玩家进程crash日志存储
%%%-------------------------------------------------------------------
-module(player_log_service).


-behaviour(gen_server).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-export([start_link/0, add_crash_log/3]).


-include("inc.hrl").
-define(PLAYER_LOG_FILE, "log/server_player_crash.log").

-record(state, {io_device}).

add_crash_log(PlayerId, PlayerName, Reason) ->
    ?MODULE ! {player_crash_log, PlayerId, PlayerName, Reason}.

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

init([]) ->
%%     {ok, S} = file:open(?PLAYER_LOG_FILE, [append, write,  {encoding, utf8}]),
    {ok, #state{}}.

handle_call(_Request, _From, State) ->
    {reply, ok, State}.

handle_cast(_Request, State) ->
    {noreply, State}.

%% write_crash_log(PlayerId, _PlayerName, Reason) ->
%%     file:write_file
%%     (
%%         ?PLAYER_LOG_FILE,
%%         erlang:list_to_binary
%%         (
%%             io_lib:format("~n~n===== TIME:~p =====~nPlayerId:~p~n~nLog:~p~n~n", [erlang:localtime(), PlayerId, Reason])
%%         ),
%%         [append]
%%     ).

%% write_crash_log(Reason, State) ->
%%     file:write_file
%%     (
%%         "player_crash.log",
%%         erlang:list_to_binary
%%         (
%%             io_lib:format("player ~p Crash ~p ~n ~p", [get(?pd_id), Reason, State])
%%         ),
%%         [append]
%%     ).


write_crash_log(PlayerId, PlayerName, Reason) ->
    {ok, F} = file:open(?PLAYER_LOG_FILE, [append, write,  {encoding, utf8}]),
    io:format
    (
        F,
        "~n~n===== TIME:~p =====~nPlayerId:~p PlayerName:~ts ~n~nLog:~p~n~n",
        [
            erlang:localtime(),
            PlayerId,
            PlayerName,
            Reason
        ]
    ),
    file:close(F).

handle_info({player_crash_log, PlayerId, PlayerName, Reason}, State) ->
    % ?INFO_LOG("player_crash_log ~p", [Reason]),
    write_crash_log(PlayerId, PlayerName, Reason),
    {noreply, State};

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
%%     file:close(State#state.io_device),
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.