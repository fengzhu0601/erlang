-module(gm_controller_server_sup).

-behaviour(supervisor).

%% API.
-export([start_link/0]).

%% supervisor.
-export([init/1]).


%% @doc 开启socket 监听系统
-spec start_link() -> {ok, pid()}.
start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

%% supervisor.
init([]) ->
    Procs = [],
    {ok, {{one_for_one, 10, 10}, Procs}}.
