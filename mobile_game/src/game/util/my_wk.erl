-module(my_wk).
-behaviour(gen_server).
-define(SERVER, ?MODULE).


%% ------------------------------------------------------------------
%% gen_server Function Exports
%% ------------------------------------------------------------------
-export
([
    init/1
    , handle_call/3
    , handle_cast/2
    , handle_info/2
    , terminate/2
    , code_change/3
]).



%% ------------------------------------------------------------------
%% gen_server Function Definitions
%% ------------------------------------------------------------------
init([_RootArgs, _RunArgs]) ->
    io:format("=============== my_wk init ~p ~p ===============~n", [_RootArgs, _RunArgs]),
    {ok, {}}.

handle_call(_Request, _From, State) ->
    {reply, ok, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(timeout, State) ->
    %TimeAxle = timer_server:get_timeaxle(),
    timer_server:handle_min_timeout(),
    {noreply, State, get_next_timeout()};

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.


%% ------------------------------------------------------------------
%% Internal Function Definitions
%% ------------------------------------------------------------------
get_next_timeout() ->
    %TimeAxle = timer_server:get_timeaxle(),
    timer_server:get_next_timeout_dt().