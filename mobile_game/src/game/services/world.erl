-module(world).

-behaviour(gen_server).
-export([start_link/0]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-include_lib("common/include/inc.hrl").


%% @doc 只是创建prog world
%% 存入所有的上线的玩家

-include("game.hrl").
-include("type.hrl").
-include("player_def.hrl").
-include("msg_def.hrl").
-include("player_sproto.hrl").
-include("err_info_def.hrl").

-define(online_account, online_account).
-record (online_account, {
    account_name,
    socket,
    id
}).

%% API
-export([enter_world/1,
    leave_world/0,
    broadcast/1,
    is_player_online/1,
    get_player_pid/1,
    kick_out_player/1,
    send_to_player/2,
    send_to_player_if_online/2,
    send_to_player_if_online_by_pid/2,
    broadcast2/1,
    send_to_player_any_state/2,
    zero_clock/0,
    update_online_account/3,
    add_online_account/2,
    del_online_account/1,
    is_online_account/1,
    is_online_account_to_kick_account_and_player/1,
    get_socket/1,
    do_online_count/0
    %%get_player_position/1
]).


%% @doc 凌晨零点
zero_clock() ->
    ?DEBUG_LOG("zero　clock ~p", [date()]),
    broadcast(?mod_msg(player_mng, {?msg_game_frame, ?frame_zero_clock})),
    friend_gift_svr:zore_reset(),
    guild_service:zore_reset(),
    ok.


enter_world(PlayerId) ->
    com_prog:join_sync(?MODULE, PlayerId).

leave_world() ->
    com_prog:leave_sync(?MODULE).

update_online_account(AccountName, Socket, PlayerId) ->
    ets:insert(?online_account, #online_account{account_name=AccountName, socket=Socket, id=PlayerId}).
add_online_account(AccountName, Socket) ->
    case ets:insert(?online_account, #online_account{account_name=AccountName, socket=Socket}) of
        ?true ->
            ok;
        ?false ->
            ?ERROR_LOG("alreadly join online_account :~p",[AccountName])
    end.
del_online_account(AccountName) ->
    case ets:lookup(?online_account, AccountName) of
        [] ->
            pass;
        [#online_account{id = PlayerId}] ->
            case is_player_online(PlayerId) of
                ?true ->
                    pass;
                _ ->
                    ets:delete(?online_account, AccountName)
            end
    end.

is_online_account(AccountName) ->
    ets:member(?online_account, AccountName).

is_online_account_to_kick_account_and_player(AccountName) ->
    case ets:lookup(?online_account, AccountName) of
        [] ->
            ?false;
        [#online_account{socket = Socket, id = PlayerId}] ->
            case is_player_online(PlayerId) of
                ?true ->
                    kick_out_player(PlayerId),
                    ?false;
                _ ->
                    ?true,
                    B = <<?MSG_PLAYER_ERROR:16, ?MSG_PLAYER_ACCOUNT_LOGIN:16, ?ERR_ACCOUNT_ONLY_JOIN_ONE:16>>,
                    Data = <<(virtual_time:get_uptime()):64, B/binary>>,
                    % ?DEBUG_LOG("world Data--------------------:~p",[Data]),
                    % ?DEBUG_LOG("world Socket-------------------:~p",[Socket]),
                    gen_tcp:send(Socket, Data)
                    %del_online_account(AccountName)
            end
    end.

do_online_count() ->
    Count = case ets:info(world, size) of
        Num when is_integer(Num) -> max(0, Num);
        _ -> 0
    end,
    system_log:info_online_count(Count).

%%%% @doc 得到一个玩家当前的位置坐标
%%%% 不能得到自己的
%%-spec get_player_position(player_id()) -> ?none | {SceneId, X, Y}.
%%get_player_position(PlayerId) ->
%%case get_player_pid(PlayerId) of
%%?none ->
%%?none;
%%Pid ->
%%end


%% @doc kick out a online player.
kick_out_player(PlayerId) ->
    ?Assert(com_process:get_type() =/= ?MODULE, "world call kick_out_player will be occur dead lock"),
    case get_player_pid(PlayerId) of
        ?none ->
            ok;
        Pid ->
            case erlang:is_process_alive(Pid) of
                true ->
                    ?ERROR_LOG("********************** kick_out_player ********************** ~p", [Pid]),
                    ?send_mod_msg(Pid, player_mng, {?msg_kickout, self()}),
                    receive
                        ?offline_ok ->
                            ?DEBUG_LOG("offline_ok------------------------"),
                            ok;
                        _M ->
                            ?ERROR_LOG("bad rr ~p", [_M])
                    after 5000 ->
                        ?ERROR_LOG("~p kick out plyaer ~p timeout", [?pname(), PlayerId]),
                        exit(failed)
                    end,
                    ok;
                false ->
                    com_prog:del_member(?MODULE, PlayerId),
                    ok
            end
    end,
    ok.


is_player_online(PlayerId) ->
    ?none =/= get_player_pid(PlayerId).

 % spawn(fun()-> send_to_player_if_online_new(PlayerIdList, Msg) end);

%% 不管玩家是否离线都能受到
-spec send_to_player([player_id()] | player_id(), _) -> _.
send_to_player(PlayerIdList, Msg)
    when is_list(PlayerIdList) ->
    [spawn(fun() -> send_to_player(Id, Msg) end) || Id <- PlayerIdList];
send_to_player(RecvPlayerId, Msg) ->
    case get_player_pid(RecvPlayerId) of
        ?none ->
            ok;
        Pid ->
            Pid ! Msg
    end.


send_to_player_any_state(PlayerIdList, Msg)
    when is_list(PlayerIdList) ->
    [spawn(fun() -> send_to_player(Id, Msg) end) || Id <- PlayerIdList];
send_to_player_any_state(RecvPlayerId, Msg) ->
    case get_player_pid(RecvPlayerId) of
        ?none ->
            %?DEBUG_LOG("send_to_player -----------------------:~p",[RecvPlayerId]),
%%             ?INFO_LOG("any_state"),
            %List = load_db_misc:get_emails(RecvPlayerId),
            %List1 = [Msg | List],
            %load_db_misc:set_emails(RecvPlayerId, List1),
            mail_mng:update_offline_mail(RecvPlayerId, Msg),
            ok;
        Pid ->
            Pid ! Msg
    end.



%% @doc 如果玩家在线，那么发送Msg给对应的process。
-spec send_to_player_if_online([player_id()] | player_id(), _) -> _.
send_to_player_if_online(PlayerIdList, Msg) when is_list(PlayerIdList) ->
    [spawn(fun() -> send_to_player_if_online(Id, Msg) end) || Id <- PlayerIdList];
send_to_player_if_online(RecvPlayerId, Msg) when is_integer(RecvPlayerId) ->
    case get_player_pid(RecvPlayerId) of
        ?none ->
            ok;
        Pid ->
            Pid ! Msg
    end.

send_to_player_if_online_by_pid(PlayerPidList, Msg)
    when is_list(PlayerPidList) ->
    [spawn(fun() -> send_to_player_if_online_by_pid(Pid, Msg) end) || Pid <- PlayerPidList];
send_to_player_if_online_by_pid(Pid, Msg)
    when is_pid(Pid) ->
    Pid ! Msg.


-spec get_player_pid(player_id()) -> ?none | pid().
get_player_pid(PlayerId) ->
    com_prog:get_member(?MODULE, PlayerId).

broadcast(Msg) ->
    [spawn(fun() -> Pid ! Msg end) || {_, Pid} <- com_prog:get_members(?MODULE)],
    ok.

broadcast2(Msg) ->
    [spawn(fun() -> Pid ! Msg end) || {_, Pid} <- lists:keydelete(self(), 2, com_prog:get_members(?MODULE))].



get_socket(PlayerId) ->
    case robot_new:is_robot(PlayerId) of
        ?true ->
            self();
        _ ->
            get(?pd_socket)
    end.


start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

init([]) ->
%%    process_flag(trap_exit, true),
    com_process:init_name(<<"world">>),
    com_prog:create(?MODULE),
    ets:new(?online_account, [public,set,named_table,{keypos, #online_account.account_name}]),
    ?INFO_LOG("~p Start", [?pname()]),
    {ok, <<"world">>}.

handle_call(Request, From, State) ->
    ?ERROR_LOG("world recv unrecognized call: ~p, ~p~n", [Request, From]),
    {noreply, State}.

handle_cast(Msg, State) ->
    ?ERROR_LOG("world recv unrecognized cast: ~p~n", [Msg]),
    {noreply, State}.

handle_info(Info, State) ->
    ?ERROR_LOG("world unrecognized info: ~p~n", [Info]),
    {noreply, State}.

terminate(Reason, _State) ->
    com_prog:delete(?MODULE),
    ets:delete(?online_account),
    ?if_else(Reason =:= ?normal orelse Reason =:= ?shutdown,
        ?INFO_LOG("~p Terminate with ~p", [?pname(), Reason]),
        ?ERROR_LOG("~p Creash with ~p", [?pname(), Reason])),
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.
