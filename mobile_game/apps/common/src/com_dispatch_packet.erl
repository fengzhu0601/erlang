-module(com_dispatch_packet).
-export([do/5]).
-export_type([s_call/0]).


-include("com_type.hrl").
-include("com_log.hrl").

%% 分发接收到的包， 执行回调函数
%% @doc dispatch_packet(State,  %%
%%                      raw_pkg()::record(), %% 一个完整的二进制协议
%%                      UnpackFunc::fun(), %% 解饱函数
%%                      CallFunc::fun(), %%unpacket返回call时回调的函数
%%                      CallErrFunc::fun()) %% unpacket 返回call_err 时回调的函数
%%

-type s_call() :: fun((_, {non_neg_integer(), list()}) -> {ok, _}).


%%% @doc 处理分发pkg回调函数
-spec do(_, s_raw_pkg(), s_unpack_call(), s_call(), s_call()) -> {ok, _}.
do(State, RawPkg, UnpackFunc, CallFunc, CallErrFunc) ->
    try UnpackFunc(RawPkg) of
        {ok, call, Args} ->
            CallFunc(State, Args);
        {ok, call_err, Args} ->
            CallErrFunc(State, Args);
        {error, {_Reason, _RawPkg}} ->
            ?WARN_LOG("unpacket error Reason:~p pkg:~p", [_Reason, _RawPkg]),
            {ok, State}
    catch
        error:_Error ->
            ?ERROR_LOG("unpacket catch error:~p, RawPkg:~p, callstack:~p",
                       [_Error, RawPkg, erlang:get_stacktrace()]),
            erlang:raise(error, _Error, erlang:get_stacktrace())
    end.
