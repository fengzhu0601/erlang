%%%-------------------------------------------------------------------
%% @doc learn_erlang top level supervisor.
%% @end
%%%-------------------------------------------------------------------

-module(learn_erlang_sup).

-behaviour(supervisor).
%% API
-export([start_link/0]).

%% Supervisor callbacks
-export([init/1]).


%% Helper macro for declaring children of supervisor
-define(CHILD(I, Type), {I, {I, start_link, []}, transient, 5000, Type, [I]}).

%% ===================================================================
%% API functions
%% ===================================================================

start_link() ->
	supervisor:start_link({local, ?MODULE}, ?MODULE, []).

%% ===================================================================
%% Supervisor callbacks
%% ===================================================================
init([]) ->
	{
		ok,
		{
			{one_for_one, 3, 5},
			[
				?CHILD(com_mod_sup, supervisor)
%%				?CHILD(scene_sup, supervisor),
%%				?CHILD(player_sup, supervisor), %% 本来是工作进程，这里改成监督进程
%%                ?CHILD(robot_new_sup, supervisor),
%%				otp_util:com_sup_link_declaration(room_sup, room_sup, [])
			]
		}
	}.

