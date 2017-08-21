-module(com_mod_sup).

-behaviour(supervisor).

%% API
-export([start_link/0]).


%% Supervisor callbacks
-export([init/1]).


%%-include("event_server.hrl").
-define(CHILD(Mod, Type, Args),
    {
        Mod,
        {Mod, start_link, Args},
        transient, 2000, Type, [Mod]
    }
).

start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).


%% @doc 开启各个功能模块
init([]) ->
    {
        ok,
        {
            {one_for_one, 1, 2},
            [
                ?CHILD(mod_config, worker, [])
            ]
        }
    }.
