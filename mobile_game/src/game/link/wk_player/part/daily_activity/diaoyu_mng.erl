%%%-------------------------------------------------------------------
%%% @author fengzhu
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 08. 十二月 2016 上午10:21
%%%-------------------------------------------------------------------
-module(diaoyu_mng).
-author("fengzhu").

%% API
-export([
    start_activity/1,
    stop_activity/0
]).

start_activity(Id) ->
    case daily_activity_service:start_link(Id) of
        {ok, Pid} ->
            pass;
        _E ->
            todo
    end.

stop_activity() ->
    case whereis(daily_activity_service) of
        undefined ->
            pass;
        Pid ->
            Pid ! stop_fishing
    end,
    ok.