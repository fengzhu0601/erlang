%%% coding:utf-8
%%%-------------------------------------------------------------------
%%% @author zl
%%% @doc
%%%
%%% @end
%%%-------------------------------------------------------------------

-module(lib_clock_tests).
-export([stper1w/0]).

%% smp send msg to 5000 pid < 10ms
%% smp send msg to 10000 pid < 15ms
%% no smp  send msg to 10000 pid ~= 5ms

pingpong() ->
    receive
        _ ->
            pingpong()
                                                %after 60 ->
                                                %io:format("time out "),
                                                %pingpong()
    end.

stper1w() ->
    _i=lib_clock:start_link(),
    timer:sleep(1000),
    lists:foreach((fun(_) ->
                           spawn(fun() -> lib_clock:reg_self(100), pingpong() end)
                   end),
                  lists:seq(1,10000)),
    ok.
