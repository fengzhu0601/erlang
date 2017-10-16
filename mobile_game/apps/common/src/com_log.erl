-module(com_log).
-behaviour(gen_event).

%% set vim:foldmethod=marker

%% gen_event callbacks
-export
([
    init/1
    , handle_event/2
    , handle_call/2
    , handle_info/2
    , terminate/2
    , code_change/3
]).



%% `gen_event:start({local, Name})'
%%
%% `gen_event:stop(Name)' ->
%%                ----> Module:terminate/2
%%
%% `gen_event:add_handler(EvetMgrRef, HandlerModule, Atgs)`
%% `gen_event:add_sup_handler(EvetMgrRef, HandlerModule, Atgs)`
%%                ----> Module:init/1
%%
%% `gen_event:delete_handler(Name, Module, Args)'
%%                ----> Module:terminate/2
%%
%% `gen_event:swap_handler`
%% `gen_event:swap_sup_handle`
%%                ----> OldModule:terminate/2
%%                ----> NewdModule:init/1
%%
%% `gen_event:notify(Name, Event)' -> ok
%% `gen_event:sync_notify/2' -> ok
%%                ----> Module:handle_event/2
%%
%% `gen_event:call(EvetMgrRef, handler, Request)'
%% `gen_event:call(EvetMgrRef, handler, Request, Timeout)'
%%                ----> Module:handle_call/2
%%
%% `gen_event:which_handlers/1`
%%

%% Module Interface
%% ----------------------------

%% Module Interface   {{{--------------------------------------
-export
([
    start/1,
    stop/0,
    debug_log/2,
    info_log/2,
    waring_log/2,
    error_log/2,
    info_trace/2,
    info_trace/3
]).

-include("../include/com_log.hrl").
-include("../include/trace_eng_define.hrl").




%%----------------------------------------------------------------
%% @doc Creates an event manager
%% @spec start() -> {ok, Pid} | {error, Error}
%% @end
start(Mode) ->
    {ok, Pid} = gen_event:start({local, ?MODULE}),
    ok = gen_event:add_handler(?MODULE, ?MODULE, [Mode]),
    {ok, Pid}.

%% --------------------------------------------------------------
%% @doc stop log
%%
stop() ->
    gen_event:stop(?MODULE).

%%----------------------------------------------------------------
%% @doc write log
-spec debug_log([term()], [term()]) -> ok.
debug_log(FMT, MSG) -> gen_event:notify(?MODULE, {debug, FMT, MSG}).

-spec info_log([term()], [term()]) -> ok.
info_log(FMT, MSG) -> gen_event:notify(?MODULE, {info, FMT, MSG}).

-spec waring_log([term()], [term()]) -> ok.
waring_log(FMT, MSG) -> gen_event:notify(?MODULE, {waring, FMT, MSG}).


-spec error_log([term()], [term()]) -> ok.
error_log(FMT, MSG) -> gen_event:notify(?MODULE, {error, FMT, MSG}).

%% Module Interface end }}} -----------------------------------------

-record(state, {mode, debug_fd, info_fd, error_fd}).
%%%===================================================================
%%% gen_event callbacks {{{-------------------------------------------

%%--------------------------------------------------------------------
%% @private
%% @doc init handler Module
%%         gen_event:add_handler(Name, Module, []) call this Module:init
%% @spec init(Args) -> {ok, State} | {ok, State, hibernate} | {error, Reason}
%%       Mode log输出方式 :
%% @end
init([out_file]) ->
    {ok, FD} = file:open("xxx.log", [write]),
    io:format("Log start successed~n"),
    {ok, #state{mode=file, debug_fd= FD, info_fd=FD, error_fd=FD}};

init([out_console]) ->
    io:format("Log start successed~n"),
    FD = erlang:group_leader(),
    {ok, #state{mode=out_console, debug_fd= FD, info_fd=FD, error_fd=FD}}.


%%--------------------------------------------------------------------
%% @private
%% @spec terminate(Reason, State) -> void()
%% @end
terminate(_Reason, #state{mode=Mode, debug_fd=FD}) ->
    case Mode of
        out_file ->
            ok = file:close(FD);
        _ -> ok
    end.

%%--------------------------------------------------------------------
%% @private
%% @doc handle event from gen_event:notify/2 or gen_event:sync_notify/2
%%
%% @spec handle_event(Event, State) ->
%%                          {ok, NewState} |
%%                          {ok, NewState, hibernate} |
%%                          {swap_handler, Args1, State1, Mod2, Args2} |
%%                          remove_handler
%% @end
%% TODO  writeing effecit
handle_event({debug, FMT, MSG}, State) ->
    io:format(State#state.debug_fd, FMT, MSG),
    {ok, State};

handle_event({info, FMT, MSG}, State) ->
    io:format(State#state.info_fd, FMT, MSG),
    {ok, State};

handle_event({waring, FMT, MSG}, State) ->
    io:format(State#state.info_fd, FMT, MSG),
    {ok, State};

handle_event({error, FMT, MSG}, State) ->
    io:format(State#state.error_fd, FMT, MSG),
    {ok, State}.


%%--------------------------------------------------------------------
%% @private
%% @doc
%% Whenever an event manager receives a request sent using
%% gen_event:call/3,4, this function is called for the specified
%% event handler to handle the request.
%%
%% @spec handle_call(Request, State) ->
%%                   {ok, Reply, NewState} |
%%                   {ok, Reply, NewState, hibernate}
%%                   {remove_handler, Reply}
%%                   {swap_handler, Reply, Args1, NewState, Mod2, Args2} |
%% @end
handle_call(_Request, State) ->
    Reply = ok,
    {ok, Reply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% @spec handle_info(Info, State) ->
%%                         {ok, NewState} |
%%                         {o, NewState, hibernate}
%%                         {swap_handler, Args1, State1, Mod2, Args2} |
%%                         remove_handler
%% @end
handle_info(_Info, State) ->
    {ok, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc Convert process state when code is changed
%% @spec code_change(OldVsn, State, Extra) -> {ok, NewState}
%% @end
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%% gen_event callbacks }}}-------------------------------------------


%%%===================================================================
%%% Internal functions
info_trace(LvL, Msg) ->
    TraceNode = my_ets:get(trace_node,   0),
    case {LvL, TraceNode} of
        {0, 0} ->
%%             ?INFO_LOG("" ++ Msg ++ "~n"),
            ok;
        {1, 0} ->
%%             ?ERROR_LOG("" ++ Msg ++ "~n"),
            ok;
        _ ->
            ServerID = my_ets:get(server_id, 0),
            IP = my_ets:get(ip, 0),
            node_api:cast
            (
                TraceNode, trace_eng,
                {
                    ?trace_msg_trace_1,
                    #trace_data_trace_1
                    {
                        server_id = ServerID,
                        time = calendar:local_time(),
                        file = ?FILE,
                        line = ?LINE,
                        lvl = LvL,
                        ip = IP,
                        context = Msg
                    }
                }
            )
    end.

info_trace(LvL, FMT, ARGS) ->
    TraceNode = my_ets:get(trace_node,   0),
    case {LvL, TraceNode} of
        {0, 0} ->
            ?INFO_LOG("" ++ FMT ++ "~n", ARGS),
            ok;
        {1, 0} ->
            ?ERROR_LOG("" ++ FMT ++ "~n", ARGS),
            ok;
        _ ->
            ServerID = my_ets:get(server_id, 0),
            IP = my_ets:get(ip, 0),
            node_api:cast
            (
                TraceNode, trace_eng,
                {
                    ?trace_msg_trace_1,
                    #trace_data_trace_1_ex
                    {
                        server_id = ServerID,
                        time = calendar:local_time(),
                        file = ?FILE,
                        line = ?LINE,
                        lvl = LvL,
                        ip = IP,
                        f = FMT,
                        m = ARGS
                    }
                }
            )
    end.




