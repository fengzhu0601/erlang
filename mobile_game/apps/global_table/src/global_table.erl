%%% coding:utf-8
%%%-------------------------------------------------------------------
%%% @author zl
%%% @doc 用于存储游戏全局运行时信息
%%%      所有存储的操作都必须定义API 其他模块不能直接使用ets函数来操作
%%%
%%% @end
%%%-------------------------------------------------------------------

-module(global_table).


-behaviour(gen_server).
-export([start_link/0]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-export([]).


-include_lib("common/include/inc.hrl").

start_link() ->
    gen_server:start_link({local,?MODULE}, ?MODULE, [], []).

init([]) ->
    process_flag(trap_exit, true),
    com_process:init_name(<<"global_table">>),
    ?MODULE = ets:new(?MODULE, [?named_table, ?public, {?write_concurrency, ?true}, {?read_concurrency, ?true}]),
    erlang:send_after(5 * 60 * 1000, ?MODULE, {'DO_ONLINE_COUNT'}),
    {ok, <<"globad_table">>}.

handle_call(Request, From, State) ->
    ?ERROR_LOG("~p recv unrecognized call: ~p, ~p~n", [?pname(), Request, From]),
    {noreply, State}.

handle_cast(Msg, State) ->
    ?ERROR_LOG("~p recv unrecognized cast: ~p~n", [?pname(), Msg]),
    {noreply, State}.

handle_info({'DO_ONLINE_COUNT'}, State) ->
    world:do_online_count(),
    erlang:send_after(5 * 60 * 1000, ?MODULE, {'DO_ONLINE_COUNT'}),
    {noreply, State};
handle_info(Info, State) ->
    ?ERROR_LOG("~p unrecognized info: ~p~n", [?pname(), Info]),
    {noreply, State}.

terminate(Reason, _State) ->
    true = ets:delete(?MODULE),
    ?if_else(
        Reason =:= ?normal orelse Reason  =:= ?shutdown,
        ?INFO_LOG("~p Terminate with ~p", [?pname(), Reason]),
        ?ERROR_LOG("~p Creash with ~p", [?pname(), Reason])
    ),
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.
