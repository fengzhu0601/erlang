-module(room_scene).
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


-include("evt_util.hrl").
-include("room_system.hrl").



%% ------------------------------------------------------------------
%% gen_server Function Definitions
%% ------------------------------------------------------------------
%% 单人联机房间
init([_RootArgs, RunArgs]) ->
    ok = room_system:on_init_room(RunArgs),
    {ok, {}}.

handle_call(Request = #enter_room_args{}, {FromPid, _}, State) ->
    Ret = room_system:on_enter_room(Request, FromPid),
    {reply, Ret, State, player_eng:get_next_timeout()};

handle_call(Request = #exit_room_args{}, {FromPid, _}, State) ->
    Ret = room_system:on_exit_room(Request, FromPid),
    {reply, Ret, State, player_eng:get_next_timeout()};

handle_call(_Request, _From, State) ->
    {reply, ok, State, player_eng:get_next_timeout()}.

handle_cast(_Msg, State) ->
    {noreply, State, player_eng:get_next_timeout()}.


handle_info(#evt_util{evt=Data}, State) when is_record(Data, room_delete_end) ->
    {stop, normal, State};

handle_info(#evt_util{}=Info, State) ->
    evt_util:call(Info),
    {noreply, State, get_next_timeout()};

handle_info(kill_pid, State) ->
    ?DEBUG_LOG("room_system-------------------------------------------------------killpid"),
    {stop, normal, State};

handle_info(timeout, State) ->
    %TimeAxle = timer_server:get_timeaxle(),
    timer_server:handle_min_timeout(),
    {noreply, State, get_next_timeout()};

handle_info({mod, Mod, Msg}, State) ->
    case catch Mod:handle_msg(Msg) of
        {'EXIT', W} -> ?ERROR_LOG("handle mod msg ~p ~p ~p", [Mod, Msg, W]);
        {error, R} -> ?ERROR_LOG("handle mod msg ~p ~p ~p ", [Mod, Msg, R]);
        _ -> ok
    end,
    {noreply, State, get_next_timeout()};

handle_info(_Info, State) ->
    {noreply, State, get_next_timeout()}.

terminate(_Reason, _State) ->
    ok = room_system:on_uninit_room(),
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.


%% ------------------------------------------------------------------
%% Internal Function Definitions
%% ------------------------------------------------------------------
get_next_timeout() ->
    %TimeAxle = timer_server:get_timeaxle(),
    timer_server:get_next_timeout_dt().