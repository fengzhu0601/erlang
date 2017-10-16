%%%-------------------------------------------------------------------
%%% @author yujian
%%% @doc
%%%
%%% @end
%%%-------------------------------------------------------------------
-module(eslqite_sup).

-behaviour(supervisor).
-export([start_link/0]).
-export([init/1]).

-define(CHILD(I, Type), {I, {I, start_link, []}, permanent, 5000, Type, [I]}).

-define(SERVER, ?MODULE).

start_link() ->
    supervisor:start_link({local, ?SERVER}, ?MODULE, []).

init([]) ->
    {ok, {{one_for_one, 1000, 3600}, [?CHILD( esqlite_config, worker )]}}.
