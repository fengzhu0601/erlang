%%% coding:utf-8
%%%-------------------------------------------------------------------
%%% @author zl
%%% @doc
%%%
%%% @end
%%%-------------------------------------------------------------------

-module(com_tt).
%% API
-export([t/3,t/2,t/1, tl/3,tl/2,tl/1, stop/0, s/0, new_call/0, ss/0, p/1]).

%%%===================================================================
%%% API
%%%===================================================================
%%%
t(Mod)->
    dbg:tp(Mod,[{'_', [], [{return_trace}]}]).

t(Mod,Fun)->
    dbg:tp(Mod,Fun,[{'_', [], [{return_trace}]}]).

t(Mod,Fun,Ari)->
    dbg:tp(Mod,Fun,Ari,[{'_', [], [{return_trace}]}]).


%% 指定要监控的模块，函数，函数的参数个数
tl(Mod)->
    dbg:tpl(Mod,[{'_', [], [{return_trace}]}]).


%% 指定要监控的模块，函数
tl(Mod,Fun)->
    dbg:tpl(Mod,Fun,[{'_', [], [{return_trace}]}]).


%% 指定要监控的模块，函数，函数的参数个数
tl(Mod,Fun,Ari)->
    dbg:tpl(Mod,Fun,Ari,[{'_', [], [{return_trace}]}]).

ss() ->
    dbg:tracer(),
    com_tt:tl(scene),
    dbg:p(new, c).


new_call() ->
    dbg:p(new, c).

s() ->
    dbg:tracer().

%%开启tracer。Max是记录多少条数据
p(Max)->
    FuncStopTracer =
        fun
            (_, N) when N =:= Max-> % 记录累计到上限值，追踪器自动关闭
              dbg:stop_clear(),
              io:format("#WARNING >>>>>> dbg tracer stopped <<<<<<~n~n",[]);
        (Msg, N) ->
              case Msg of
                  {trace, _Pid, call, Trace} ->
                      {M, F, A} = Trace,
                      io:format("###################~n",[]),
                      io:format("call [~p:~p,(~p)]~n", [M, F, A]),
                      io:format("###################~n",[]);
                  {trace, _Pid, return_from, Trace, ReturnVal} ->
                      {M, F, A} = Trace,
                      io:format("===================~n",[]),
                      io:format("return [~p:~p(~p)] =====>~p~n", [M, F, A, ReturnVal]),
                      io:format("===================~n",[]);
                  _ -> skip
              end,
              N + 1
      end,

case dbg:tracer(process, {FuncStopTracer, 0}) of
    {ok, _Pid} ->
        dbg:p(all, [all]);
    {error, already_started} ->
        skip
end.

stop()->
    dbg:stop_clear().
