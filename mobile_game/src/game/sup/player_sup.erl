%%%-------------------------------------------------------------------
%%% @author zl
%%% @doc
%%%
%%% @end
%%%-------------------------------------------------------------------

-module(player_sup).

-behaviour(supervisor).

%% API
-export
([
    start_link/0,
    start_child/1
]).

%% Supervisor callbacks
-export
([
    init/1
]).





start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

start_child(Socket) ->
    supervisor:start_child(?MODULE, [Socket]).


init([]) ->
    {
        ok,
        {
            {simple_one_for_one, 0, 1},
            [
                {
                    player,
                    {player_eng, start_link, []},
                    temporary,
                    5000,
                    worker,
                    [player_eng]
                }
            ]
        }
    }.

