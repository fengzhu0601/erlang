%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 29. 三月 2016 下午3:13
%%%-------------------------------------------------------------------
-module(evt_util).
-author("clark").

%% API
-export
([
    send/1,
    sub/2,
    sub/3,
    unsub/2
]).

-export
([
    call/1
]).

-include("inc.hrl").
-include("evt_util.hrl").
-define(evt, '@evt_0329@').


send(Event) ->
    self() ! #evt_util{evt=Event}.


call(#evt_util{evt=Event}) ->
    List = util:get_pd_field( erlang:element(1, Event), [] ),
    % ?DEBUG_LOG("------------------ call ~p ------------------", [{Event, List}]),
    lists:foreach
    (
        fun
            ({_Key, CallBack}) ->
                CallBack(Event)
        end,
        List
    );

call(Event) ->
    call(#evt_util{evt=Event}).


sub(EventType, CallBack) ->
    sub(EventType, CallBack, CallBack).


sub(EventType, FunKey, CallBack) ->
    Key = erlang:element(1, EventType),
    List = util:get_pd_field(Key, []),
    List1 = List ++ [{FunKey, CallBack}],
    util:set_pd_field(Key, List1).


unsub(EventType, FunKey) ->
    Key = erlang:element(1, EventType),
    List = util:get_pd_field(Key, []),
    List1 = lists:keydelete(FunKey, 1, List),
    util:set_pd_field(Key, List1).