%%%-------------------------------------------------------------------
%%% @author zl
%%% @doc player process base
%%%
%%% @end
%%%-------------------------------------------------------------------

-module(player_eng).
-behaviour(gen_server).

-include("inc.hrl").
-include("game.hrl").
-include("player.hrl").
% -include("mobile_link.hrl").
-include("player_eng.hrl").
-include("client_link.hrl").

%% API
-export
([
    tcp_send/1
    , tcp_send_cork/1
    , tran_assets_pds_mix/1
    , transaction_run/2
    , transaction_start/1
    , transaction_commit/0
    , transaction_rellback/0
    , get_next_timeout/0
    , player_msg_call/2
]).

%% Module Interface
-export([start_link/1]).
%% gen_server callbacks
%% 
%%

-export
([
    init/1,
    handle_call/3,
    handle_cast/2,
    handle_info/2,
    terminate/2,
    code_change/3
]).




start_link({robot_socket, RobotId}) ->
    gen_server:start_link(?MODULE, {robot_socket, RobotId}, []);
%% @doc Starts the server
% start_link(Args = #mobile_build_player{}) ->
%     ?NODE_INFO_LOG("start_link !!! ~n"),
%     gen_server:start_link(?MODULE, Args, []);
start_link(CSocket) ->
    ?debug_log_player("Player start_link"),
    % ?DEBUG_LOG("player_eng---------------------:~p", [CSocket]),
    {ok,{IP_Address,Port}} = inet:peername(CSocket),
    erlang:put(?pd_client_ip, util:ip_to_str(IP_Address)),
    erlang:put(?pd_client_port, Port),

    ok = inet:setopts(CSocket, [binary, {nodelay, true}, {packet, 2}, {active, true}]),
    gen_server:start_link(?MODULE, CSocket, []).

init({robot_socket, RobotId}) ->
    random:seed(os:timestamp()),
    put(?pd_socket, robot_socket),
    robot_new:init_robot(RobotId),
    {ok, #connect_state{}};
% init(#mobile_build_player{node=Node, socket=Socket, ip_address=IP, port=Port, pid=Pid}) ->
%     OnlinePlayerNum = ets:info(world, size),
%     LoginPlayerMax = my_ets:get(login_player_count_max,   0),
%     case OnlinePlayerNum < LoginPlayerMax of
%         true ->
%             ?open_trap_exit(),
%             try
%                 random:seed(os:timestamp()),
%                 {'@wait_msg@', Msg} = account:init(Node, Socket, IP, Port, Pid),
%                 {ok, #connect_state{wait = Msg, name = ?MODULE}, ?ONLINE_TIMEOUT}
%             catch
%                 E:W ->
%                     ?ERROR_LOG("player init crash ~p ~p", [E, W]),
%                     {stop, crash}
%             end;
%         _ ->
%             ?NODE_INFO_LOG("Number of players has reached its limit !!! ~n"),
%             {stop, crash}
%     end;
init(CSocket) when is_port(CSocket) ->
    OnlinePlayerNum = ets:info(world, size),
    LoginPlayerMax = my_ets:get(login_player_count_max,   0),
    case OnlinePlayerNum < LoginPlayerMax of
        true ->
            ?open_trap_exit(),
            try
                random:seed(os:timestamp()),
                eng_init(),
                {'@wait_msg@', Msg} = account:init(CSocket),
                ?debug_log_player("player_mng init over"),
                {ok, #connect_state{wait = Msg, name = ?MODULE}, ?ONLINE_TIMEOUT}
            catch
                E:W ->
                    ?ERROR_LOG("player init crash ~p ~p", [E, W]),
                    {stop, crash}
            end;
        _ ->
            ?NODE_INFO_LOG("Number of players has reached its limit !!! ~n"),
            {stop, crash}
    end.

handle_call({'playre_msg_call', M, F, A}, _From, State) ->
    Ret = M:F(A),
    {reply, Ret, State, player_eng:get_next_timeout()};
handle_call(_Request, _From, State) ->
    case _Request of
        {debug_msg, Cmd, Args} ->
            Reply =
                case catch player_debug:call(Cmd, Args) of
                    {'EXIT', E} ->
                        ?ERROR_LOG("debug_msg ~p ~n~p", [Cmd, E]);
                    R ->
                        R
                end,
            {reply, Reply, State, player_eng:get_next_timeout()};
        {mod, Mod, Msg} ->
            Reply = Mod:handle_mcall(Msg, _From),
            {reply, Reply, State, player_eng:get_next_timeout()};
        _ ->
            ?ERROR_LOG("unknown call msg~p", [_Request]),
            {reply, ok, State, player_eng:get_next_timeout()}
    end.



handle_cast(_Msg, State) ->
    ?ERROR_LOG("unknown cast msg~p", [_Msg]),
    {noreply, State, player_eng:get_next_timeout()}.



handle_info(Info, State) ->
    %?DEBUG_LOG("=============== player_eng =============== ~p~n",[Info]),
    case Info of
        {?player_eng_delete, _Data} ->
            {stop, ?normal, State};

        {?player_eng_msg, Data} ->
            account:handle_client(Data#player_eng_msg.msg, State);

        {tcp, _Socket, <<_SendTime:64, _ID:16, _Data/binary>>} ->
            account:handle_client(Info, State);

        {tcp, _Socket, Data} ->
            ?ERROR_LOG("~p recv bad pkg ~p terminate player", [?pname(), Data]),
            {stop, ?normal, State};

        {tcp_closed, _Socket} ->
            put(?pd_tcp_closed, true),
            {stop, ?normal, State};

        {tcp_error, _Socket, Reason} ->
            ?ERROR_LOG("tcp_error ~p", [Reason]),
            {noreply, State, player_eng:get_next_timeout()};

        {send_to_client, Msg} ->
            %%?env_develop(check_not_offline),
            ?ENV_develop(
                case get(?pd_alread_offline) of
                    ?undefined ->
                        ok;
                    true ->
                        ?ERROR_LOG("offline connect_state send msg to client ~p", [Msg])
                end),
            ?player_send(Msg),
            {noreply, State, player_eng:get_next_timeout()};

        {mod, Mod, From, Msg} ->
            account:handle_msg(Mod, From, Msg, State);

        timeout ->
            W = State#connect_state.wait,
            case W of
                ?undefined ->
                    %NextTimeOut = timer_eng:handle_timeout(),
                    Dt1 = timer_eng:get_next_time_out(),
                    %TimeAxle = timer_server:get_timeaxle(),

                    Dt2 = timer_server:get_next_timeout_dt(),
                    NextTimeOut =
                    if
                        Dt2 =< Dt1 ->
                            timer_server:handle_min_timeout(),
                            timer_server:get_next_timeout_dt();
                        true ->
                            timer_eng:handle_timeout()
                    end,
                    {noreply, State, NextTimeOut};
                _ ->
                    ?ERROR_LOG("player login timeout wait msg ~p terminate player", [W]),
                    {stop, normal, State}
            end;

        {'EXIT', Pid, _R} ->
            case get(?pd_scene_pid) of
                Pid ->
                    ?ERROR_LOG("scene process crash Pid~p, R~p", [Pid, _R]);
                _ ->
                    ?ERROR_LOG("player receive EXIT pid ~p R ~p", [Pid, _R])
            end,
            ?ERROR_LOG("EXIT ~p", [?pname()]),
            {stop, normal, State};

        {'ROBOT_OFFLINE'} ->
            {stop, normal, State};

        _ ->
            %?ERROR_LOG("receive a unknown mag ~p", [Info]),
            ?ERROR_LOG("receive a unknown mag"),
            {noreply, State, player_eng:get_next_timeout()}
    end.


%% @spec terminate(Reason, State) -> no_return()
%%       Reason = normal | shutdown | Term
terminate(Reason, _State) ->
    ?NODE_ERROR_LOG("-------------- terminate ---------------- ~p", [{Reason, _State}]),
    Action = case Reason of
                 ?offline -> ?TRUE;
                 ?normal -> ?TRUE;
                 ?shutdown -> 
                    system_log:info_role_offline(),
                    ?TRUE;
                 ?wait_msg_unmatch -> ?TRUE;
                 _ ->
                     ?NODE_ERROR_LOG("player ~p Crash with:~p ", [?pname(), Reason]),
                     player_log_service:add_crash_log(get(?pd_id), get(?pd_name), Reason),
%%                      write_crash_log(Reason, _State),
                     ?FALSE
             end,
    account:uninit(Action).

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.


tran_assets_pds_mix(PdL) when is_list(PdL) ->
    AssetsPd = player_def:assets_pd_all(),
    lists:append([AssetsPd, PdL]).

%% @doc 执行一个事务
%% EffectPds is pd key
%% fn is code , the fn must return
%%  `commit' will commit effect, `rollback' will rollback to before run transaction connect_state.
%% return transaction_run return value is same as Fn returned.
%% `NOTE' 只在必要时使用, 不能在Fn中发送进程间消息
%% e.g.
%%   transaction_run([pd_money, pd_xx],
%%                   fun() ->
%%                       {commit, xx}
%%                   end)
%%
-spec transaction_run(EffectPds :: [atom()], Fn :: fun(() -> Ret)) -> Ret
    when Ret :: {commit, _} | {rollback, _}.
transaction_run(EffectPds, Fn) ->
    OldState = [{K, get(K)} || K <- EffectPds],
    ?pd_new('@in_transaction@', true),

    ?pd_new(?pd_tcp_cork_data, []),
    Ret = Fn(),
    TcpData = erase(?pd_tcp_cork_data),
    case Ret of
        {commit, _} ->
            ?if_(TcpData =/= [], _ = [prim_inet:send(get(?pd_socket), Pkg, []) || Pkg <- lists:reverse(TcpData)]);
        {rellback, _} ->
            _ = [put(K, V) || {K, V} <- OldState]
    end,

    erase('@in_transaction@'),
    Ret.


transaction_start(EffectPds) ->
    OldState = [{K, get(K)} || K <- EffectPds],
    ?pd_new('@in_transaction@', true),
    ?pd_new(?pd_tcp_cork_data, []),
    ?pd_new(?pd_tran_old_data, OldState),
    ok.

transaction_commit() ->
    erase('@in_transaction@'),
    erase(?pd_tran_old_data),
    TcpData = erase(?pd_tcp_cork_data),
    ?if_(TcpData =/= [], _ = [prim_inet:send(get(?pd_socket), Pkg, []) || Pkg <- lists:reverse(TcpData)]),
    ok.

transaction_rellback() ->
    erase('@in_transaction@'),
    erase(?pd_tcp_cork_data),
    OldState = erase(?pd_tran_old_data),
    lists:foreach(fun({K, V}) ->
        put(K, V)
    end, OldState),
    ok.

player_msg_call(PlayerPid, {M, F, A}) ->
    gen_server:call(PlayerPid, {'playre_msg_call', M, F, A}).


%%%===============================================================================================
%%%

eng_init() ->
    ok.

%% @doc like TCP_CORK but erlang tcp kernel not support. 
%%      so will wirte a applecation layer.
tcp_send_cork(Fn) ->
    case get(pd_is_send_msg) of
        false ->
            ignore;
        _ ->
            transaction_run([], fun() -> Fn(), {commit, ok} end)
    end.

%% tcp_send(Data) when is_binary(Data) ->
%%     io:format("tcp_send ~p~n", [Data]),
%%     Node = erlang:get(?pd_gateway_node_addr),
%%     Pid = erlang:get(?pd_gateway_node_pid),
%%     node_api:cast_ex
%%     (
%%         Node,
%%         Pid,
%%         ?client_link_msg,
%%         #client_link_msg
%%         {
%%             msg = Data
%%         }
%%     );
tcp_send(_Data) when is_binary(_Data) ->
    case get(pd_is_send_msg) of
        false ->
            ignore;
        _ ->
            Data = <<(virtual_time:get_uptime()):64, _Data/binary>>,
            case get(?pd_tcp_cork_data) of
                ?undefined ->
                    prim_inet:send(get(?pd_socket), Data, []);
                _ ->
                    put(?pd_tcp_cork_data, [Data | get(?pd_tcp_cork_data)]),
                    ok
            end
    end;
tcp_send(Data) ->
    ?ERROR_LOG("send_error datatype is not binary ~p", [Data]).




get_next_timeout() ->
    Dt1 = timer_eng:get_next_time_out(),
    %TimeAxle = timer_server:get_timeaxle(),
    Dt2 = timer_server:get_next_timeout_dt(),
    erlang:min(Dt1, Dt2).