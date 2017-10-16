-module(system_broadcast_worker).


-behaviour(gen_server).
-export([start_link/0]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).


-export([do_broadcast/0]).

-define(broadcast_list_ing, broadcast_list_ing).

start_link() ->
    gen_server:start_link({local,?MODULE}, ?MODULE, [], []).

init([]) ->
    process_flag(trap_exit, true),
    {ok, none}.

handle_call(_Request, _From, State) ->
    {noreply, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(start_system_broadcast, State) ->
    io:format("start_system_broadcast--------------------:~n"),
    cancel_sendafter(erase(?broadcast_list_ing)),
    BroadcastData = gm_data:get_broadcast_info(),

    NowTime = com_time:now(),

    BroadcastRefList = 
    lists:foldl(fun(Pl, Acc) ->
            BroadcastID = lists:nth(2, Pl),
            Title = lists:nth(7, Pl),
            Content = lists:nth(8, Pl),
            _Type = lists:nth(6, Pl),
            EndTime = lists:nth(4, Pl),
            Timeout = lists:nth(5, Pl),
            FinalEndTime = EndTime - NowTime,
            io:format("Title-----------------------:~p~n",[Title]),
            io:format("Content-------------------:~p~n",[Content]),
            NewContent = <<Title/bytes,Content/bytes>>,
            Ref = erlang:send_after(Timeout * 1000, self(), {next_broadcast, BroadcastID, FinalEndTime, Timeout, NewContent}),
            M = {BroadcastID, Ref},
            [M|Acc]
    end,
    [],
    BroadcastData),
    put(?broadcast_list_ing, BroadcastRefList),
    {noreply, State};

handle_info({next_broadcast, BroadcastID, FinalEndTime, Timeout, NewContent}, State) ->
    chat_mng:system_broadcast(NewContent),
    if
        FinalEndTime >= Timeout ->
            Ref = erlang:send_after(Timeout * 1000, self(), {next_broadcast, BroadcastID, (FinalEndTime-Timeout), Timeout, NewContent}),
            flush_broadcast_list_info(BroadcastID, Ref);
        true ->
            pass
    end,
    {noreply, State}.


terminate(_Reason, _State) ->
    ok.


code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

flush_broadcast_list_info(BroadcastID, Ref) ->
    case get(?broadcast_list_ing) of
        undefined ->
            put(?broadcast_list_ing, [{BroadcastID, Ref}]);
        List ->
            put(?broadcast_list_ing, lists:keyreplace(BroadcastID, 1, List, {BroadcastID, Ref}))
    end.

cancel_sendafter(undefined) ->
    pass;
cancel_sendafter(List) ->
    lists:foreach(fun({_BroadcastID, Ref}) ->
        erlang:cancel_timer(Ref)
    end,
    List).


do_broadcast() ->
    io:format("do_broadcast---------------------------------~n"),
    system_broadcast_worker ! start_system_broadcast.
