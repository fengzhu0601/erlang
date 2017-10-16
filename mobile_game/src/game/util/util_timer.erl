%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 01. 十二月 2015 下午11:13
%%%-------------------------------------------------------------------
-module(util_timer).
-author("clark").

%% API
-export
([
    start/4,
    cancel/1
]).


-define(timers,"@timers@").

start(Time, Count, Event, Log) ->
    CallbackPid = self(),
    Ref =
        if
            is_integer(Count), Count > 0 ->
                spawn(fun() -> timer(Time, Count, {CallbackPid, Event}, Log) end);
            is_integer(Count), Count =:= -1 ->
                spawn(fun() -> timer(Time, Count, {CallbackPid, Event}, Log) end);
            true ->
                io:format("!!!!!!!!!!!!!!!!!!!! failed in timer ~p ~n",[Log]),
                none
        end,
    Ref.

cancel(Pid) -> Pid ! timer_cancel_xxx.

timer(_Time, 0, {_CallbackPid, _Event}, _Log) ->
    ok;
timer(Time, -1, {CallbackPid, Event}, Log) ->
    receive
        timer_cancel_xxx ->
            ok
    after Time ->
%%         io:format("%%%%%%%%%%%%%%%%%%%%%%%% on time ~p %%%%%%%%%%%%%%%%%%%%%%%%",[Log]),
        CallbackPid ! {self(), Event},
        timer(Time, -1, {CallbackPid, Event}, Log)
    end;
timer(Time, Count, {CallbackPid, Event}, Log) ->
    receive
        timer_cancel_xxx ->
            ok
    after Time ->
%%         io:format("%%%%%%%%%%%%%%%%%%%%%%%% on time ~p %%%%%%%%%%%%%%%%%%%%%%%%",[Log]),
        CallbackPid ! {self(), Event},
        timer(Time, Count-1, {CallbackPid, Event}, Log)
    end.

