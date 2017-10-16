%%% coding:utf-8
%%%-------------------------------------------------------------------
%%% @author zl
%%% @doc socket监听系统supervisor
%%%
%%% @end
%%%-------------------------------------------------------------------

-module(lc_sup).

-behaviour(supervisor).

%% API.
-export([start_link/0]).

%% supervisor.
-export([init/1]).

-include("../../common/include/com_log.hrl").

%% API.

%% @doc 开启socket 监听系统
-spec start_link() -> {ok, pid()}.
start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).


%% supervisor.
init([]) ->
    ?INFO_LOG("Start ~p!", [?MODULE]),
    Procs=
        [],
    {ok, {{one_for_one, 10, 10}, Procs}}.
