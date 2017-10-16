-module(gm_controller_sup).

-behaviour(supervisor).


%% API
-export([start_link/0,
         start_child/1]).

%% Supervisor callbacks
-export([init/1
        ]).

-define(CHILD(Id, Mod, Type, Args), {Id, {Mod, start_link, Args},
                                     permanent, 5000, Type, [Mod]}).

-define(simple_one_for_one, simple_one_for_one).
-define(one_for_one, one_for_one).
-define(one_for_all, one_for_all).
-define(rest_for_on, rest_for_one).
-define(permanent, permanent).
-define(transient, transient).
-define(temporary, temporary).
-define(brutal_kill, brutal_kill).



%%%===================================================================
%%% API functions
%%%===================================================================

%%--------------------------------------------------------------------
%% @doc
%% Starts the supervisor
%%
%% @spec start_link() -> {ok, Pid} | ignore | {error, Error}
%% @end
%%--------------------------------------------------------------------
start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

start_child(Socket) ->
    io:format("start gm proce---------~n"),
    supervisor:start_child(?MODULE, [Socket]).


init([]) ->
    ChildSpec = {gm,
                     {gm_controller_eng, start_link, []},
                     ?temporary,
                     5000,
                     worker,
                     [gm_controller_eng]
                    },
    RestartStrategy = {?simple_one_for_one, 0, 1},

    {ok, {RestartStrategy, [ChildSpec]}}.
