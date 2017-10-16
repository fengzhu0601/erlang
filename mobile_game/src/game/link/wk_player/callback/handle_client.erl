%%%-------------------------------------------------------------------
%%% @author zl
%%% @doc 处理客户端msg 行为
%%%
%%% @end
%%%-------------------------------------------------------------------

-module(handle_client).
-include("player_def.hrl").

-export([
    defer_exception_badmatch/1
    , defer_exception_badmatch_clean/0
]).

%% @doc 处理client 的请求 返回offline 终结本进程
-callback handle_client({PROTO_ID :: non_neg_integer(), tuple()}) ->
    {error, _} |
    {'@offline@', Reason :: atom()} |
    {'@wait_msg@', Msg :: binary(), TimeOut :: non_neg_integer()} | _.


%% @doc like Golang defer 
%% 只能在handler_client 函数中使用
%% Fn 函数中不能抛出任何异常.
defer_exception_badmatch(Fn) ->
    put(?pd_defer_badmath, Fn).

defer_exception_badmatch_clean() ->
    erase(?pd_defer_badmath).
