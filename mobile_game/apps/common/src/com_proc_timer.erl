%%% coding:utf-8
%%%-------------------------------------------------------------------
%%% @author zl
%%% @doc 一个在单个进程中使用的计时器.
%%%   用来代替大量需要start_timer 或 send_after, 的操作
%%%
%%%
%%%  gb_trees {Timeout, [timer()]}
%%%  timer : {Ref, Msg} Ref is start_timer -> return Ref
%%%  Ref = {Tiemout, Key}
%%%
%%% @end
%%%-------------------------------------------------------------------

-module(com_proc_timer).

%% start_timer
%% cancel_timer
%% next_timeout

-include("com_define.hrl").

-export([new/0
         ,start_timer/3
         ,cancel_timer/2
         ,read_timer/1
         ,is_member/2
         ,next_timeout/1
         ,take_timeout_timer/1
         ,take_next_timeout_timer/1
         ,take_next_timeout_timer/2
        
         ,test/0
        ]).

-define(make_timer(Ref, Msg), {Ref, Msg}).
-define(make_tref(Timeout, Ref), {Timeout, Ref}).

-type tref() :: {Timeout::non_neg_integer(), Ref::reference()}.
-type timer() :: {tref(), Msg::term()}.

new() ->
    gb_trees:empty().

%% -> {Ref, Mng}
%% @doc add a timer
start_timer(TimeMsec, Msg, Mng) ->
    Timeout = TimeMsec + com_time:timestamp_msec(),

    Ref = ?make_tref(Timeout, erlang:make_ref()),
    NewMng=
        case gb_trees:lookup(Timeout, Mng) of
            ?none ->
                gb_trees:insert(Timeout, [?make_timer(Ref, Msg)], Mng);
            {?value, List} ->
                gb_trees:update(Timeout, [?make_timer(Ref, Msg)|List], Mng)
        end,

    {Ref, NewMng}.


%% @doc cancel a tiemr return new Mng
cancel_timer({Timeout,_}=Ref, Mng) ->
    case gb_trees:lookup(Timeout, Mng) of
        ?none ->
            Mng;
        {?value, [{Ref,_Msg}]} ->
            gb_trees:delete(Timeout, Mng);
        {?value, [{_OtherRef,_Msg}]} ->
            Mng;
        {?value, TimerList} ->
            gb_trees:update(Timeout,
                            lists:keydelete(Ref, 1, TimerList),
                            Mng)
    end.

%% @doc gate remain time.
%% INLINE
-spec read_timer(tref()) -> Remain :: integer().
read_timer({Timeout, _}) ->
    Timeout - com_time:timestamp_msec().

%% @doc test a specific tref is a member of Mng.
-spec is_member(tref(), _) -> boolean().
is_member({Timeout, _}=Ref, Mng) ->
    case gb_trees:lookup(Timeout, Mng) of
        ?none ->
            ?false;
        {?value, [{Ref,_}]} ->
            ?true;
        {?value, [{_OtherRef,_Msg}]} ->
            ?false;
        {?value, TimerList} ->
            case lists:keyfind(Ref,1,TimerList) of
                ?false -> ?false;
                _ -> ?true
            end
    end.

%%-> infinity | time 毫秒 0-xxx
-spec next_timeout(_) -> ?infinity | non_neg_integer().
next_timeout(Mng) ->
    case gb_trees:is_empty(Mng) of
        ?true ->
            ?infinity;
        ?false ->
            {Timeout, _V} = gb_trees:smallest(Mng),
            erlang:max(0, Timeout - com_time:timestamp_msec())
    end.


%% @doc返回最小的一个timer超时的消息如果有的话,和删除这个timer后的Mng.
%% INLINE
take_next_timeout_timer(Mng) ->
    take_next_timeout_timer(com_time:timestamp_msec(), Mng).

-spec take_next_timeout_timer(_, _) -> ?none | {tref(), Msg ::_, Mng::_}.
take_next_timeout_timer(NowMsec, Mng) ->
    case gb_trees:is_empty(Mng) of
        ?true ->
            ?none;
        ?false ->
            case gb_trees:take_smallest(Mng) of
                {Timeout, TimerList, Mng1} when Timeout =< NowMsec+2 ->
                    case TimerList of
                        [{TRef, Msg}] ->
                            {TRef, Msg, Mng1};
                        _ ->
                            [{TRef, Msg} | Other] = lists:reverse(TimerList),
                            {TRef, Msg, gb_trees:insert(Timeout, lists:reverse(Other), Mng1)}
                    end;
                _ ->
                    ?none
            end
    end.




%% 得到到时所有超时的timers和删除这些timer的Mng.
-spec take_timeout_timer(_) -> {[timer()], Mng::_}.
take_timeout_timer(Mng) ->
    case gb_trees:is_empty(Mng) of
        ?true -> {[], Mng};
        ?false ->
            timeout_timer__(com_time:timestamp_msec(), [], Mng)
    end.

timeout_timer__(Now, TimerList, Mng) ->
    case gb_trees:is_empty(Mng) of
        ?true -> {lists:reverse(TimerList), Mng};
        ?false ->
            {Timeout, V, Mng_2} = gb_trees:take_smallest(Mng),
            if Timeout > Now + 2 ->
                    {lists:reverse(TimerList), Mng};
               ?true ->
                    timeout_timer__(Now, V ++ TimerList, Mng_2)
            end
    end.

-include_lib("eunit/include/eunit.hrl").
test() ->
    %%erlang:erase(),
    Mng = new(),
    {Ref, Mng1}= start_timer(323, aa, Mng),
    {Ref1, Mng2}= start_timer(323, aa, Mng1),
    {Ref2, Mng3}= start_timer(323, aa, Mng2),


    ?assert(com_proc_timer:is_member(Ref, Mng3)),
    ?assert(com_proc_timer:is_member(Ref1, Mng3)),
    ?assert(com_proc_timer:is_member(Ref2, Mng3)),

    Mng4 = cancel_timer(Ref2, Mng3),
    %%io:format("cancel ref ~p mng4 ~p~n", [Ref2, Mng4]),
    ?assert(not com_proc_timer:is_member(Ref2, Mng4)), 
    ?assert(com_proc_timer:is_member(Ref,  Mng4)),
    ?assert(com_proc_timer:is_member(Ref1, Mng4)),

    Mng5 =cancel_timer(Ref, Mng4),
    %%io:format("cancel Ref~p mng5 ~p~n", [Ref, Mng5]),
    ?assert(com_proc_timer:is_member(Ref1, Mng5)),
    ?assert(not com_proc_timer:is_member(Ref, Mng5)),

    Mng6 = cancel_timer(Ref1, Mng5),
    ?assert(not com_proc_timer:is_member(Ref1, Mng6)),
    ok.
