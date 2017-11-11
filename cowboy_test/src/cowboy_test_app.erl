%%%-------------------------------------------------------------------
%% @doc cowboy_test public API
%% @end
%%%-------------------------------------------------------------------

-module(cowboy_test_app).

-behaviour(application).

%% Application callbacks
-export([start/2, stop/1]).

%%====================================================================
%% API
%%====================================================================

start(_StartType, _StartArgs) ->
    {ok, _} = ranch:start_listener(cowboy_test,
		ranch_tcp, [{port, 8080}], server, []),
    io:format("ranch start listener aaaaaaaa...~n"),
   cowboy_test_sup:start_link().

%%--------------------------------------------------------------------
stop(_State) ->
    ok.

%%====================================================================
%% Internal functions
%%====================================================================
