
%%-----------------------------------
%% @Module  : robot_new_sup
%% @Author  : Holtom
%% @Email   : 
%% @Created : 2016.6.28
%% @Description: robot_new_sup
%%-----------------------------------
-module(robot_new_sup).
-behaviour(supervisor).

%% API
-export([
    start_link/0
]).

%% Supervisor callbacks
-export([
    init/1
]).

start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

init([]) ->
    {
        ok,
        {
            {one_for_one, 1, 2},
            [
                {
                    robot_new,
                    {robot_new_server, start_link, []},
                    temporary,
                    5000,
                    worker,
                    [robot_new_server]
                }
            ]
        }
    }.

