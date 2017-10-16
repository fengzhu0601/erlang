%%-----------------------------------------------------------------t
%%-
%% @author zlb
%% @doc 组队模块
%%
%% @end
%%-------------------------------------------------------------------

-module(team_mod).
-behaviour(gen_server).

-export([
    start_link/1
]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-export([
    create_arena_team/0,
    create_team/3,
    get_member_ids/1,
    get_team_power/1,
    is_join_team/1,
    join/1,
    join_ex/1,
    quit/0,
    quit/2,
    kickout/1,
    disband/0,
    disband/1,
    is_team_ids_full/1,
    set_master_id/2,
    member_leave/2,
    pkg_members/1,
    pkg_member/1,
    get_team_info_by_leader/1
]).

-include("inc.hrl").
-include("player.hrl").
-include("game.hrl").
-include("team_struct.hrl").
-include("team_mng_reply.hrl").

%% @spec create_arena_team() -> {ok, TeamId} | {error, Reason}
%% @doc 创建竞技场队伍
create_arena_team() ->
    create_team(?TEAM_TYPE_MULTI_ARENA, <<>>, 0).

%% @spec create_team(TeamType) -> {ok, TeamId} | {error, Reason}
%% @doc 创建队伍
create_team(TeamType, TeamName, TeamLeader) ->
    case team_svr:is_create_team(TeamLeader, TeamType) of
        ?true ->
            TM = get_team_member(),
            case team_svr:create_team({TeamType, TeamName, TeamLeader, TM}) of
                {ok, TeamId} ->
                    put(?pd_team_id, TeamId),
                    %?DEBUG_LOG("TM---------------------------:~p",[TM]),
                    %?DEBUG_LOG("TeamId-------------------------------:~p",[TeamId]),
                    %?DEBUG_LOG("TeamName----------------------------:~p",[TeamName]),
                    ?player_send(team_sproto:pkg_msg(?MSG_TEAM_CREATE, {TeamId, TeamType, TeamName, pkg_members([TM])})),
                    {ok, TeamId};
                _Err ->
                    _Err
            end;
        Error ->
            %{error, team_type_ill}
            %?DEBUG_LOG("Error------------------------:~p",[Error]),
            Error
    end.

get_team_info_by_leader(TeamId) ->
    SelfId = get(?pd_id),
    case ets:lookup(?team_info, TeamId) of
        [#team{master_id = SelfId} =T] ->
            {?true, T};
        _ ->
            ?false
    end.


%% 队伍是否可以加入，并返回战力
is_join_team(TeamId) ->
    case ets:lookup(?team_info, TeamId) of
        [] ->
            {false,0};
        _ ->
            [#team{members = TMs, power = Power}] = ets:lookup(?team_info, TeamId),
            {(length(TMs) < ?TEAM_MEMBERS_MAX), Power}
    end.
is_team_ids_full(TeamId) ->
    case ets:lookup(?team_info, TeamId) of
        [] ->
            {false,0};
        _ ->
            [#team{members = TMs, power = Power}] = ets:lookup(?team_info, TeamId),
            {(length(TMs) >= ?TEAM_MEMBERS_MAX), Power}
    end.

%% 获取队伍中成员id列表
get_member_ids(TeamId) ->
    case ets:lookup(?team_info, TeamId) of
        [] -> [];
        [#team{members = TMs}] ->
            [Id || #team_member{id = Id} <- TMs]
    end.

%% 获取队伍战力
get_team_power(TeamId) ->
    [#team{power = Power}] = ets:lookup(?team_info, TeamId),
    Power.

is_can_join(TeamId) ->
    Is = 
    case ets:lookup(?team_info, TeamId) of
        [#team{members = TMs}] ->
            lists:keymember(get(?pd_id), #team_member.id, TMs);
        _ ->
            case team_svr:get_team_id_by_player(get(?pd_id)) of
                ?none ->
                    ?false;
                _ ->
                    ?true
            end
    end,
    ?DEBUG_LOG("Is--------------------------:~p",[Is]),
    Is.


%% 加入队伍
join(TeamId) ->
    ?ifdo(is_can_join(TeamId), ?return_err(?ERR_TEAM_NOT_JOIN_SELF)),
    case ets:lookup(?team_info, TeamId) of
        [#team{pid = Pid, team_name=TeamName, type=TeamType, members = TMs}] when length(TMs) < ?TEAM_MEMBERS_MAX ->
            TM = get_team_member(),
            case gen_server:call(Pid, {join, TM}) of
                ok ->
                    ets:insert(?team_mem_index, {TM#team_member.id, TeamId}),
                    [#team{members = TMs1}] = ets:lookup(?team_info, TeamId),
                    lists:foreach(fun(#team_member{id = Id}) ->
                            world:send_to_player_if_online(Id, 
                                ?to_client_msg(team_sproto:pkg_msg(?MSG_TEAM_MEMBER_JOIN, {pkg_member(TM)})))
                    end,
                    TMs),
                    ?DEBUG_LOG("Join TeamId---------------------:~p",[TeamId]),
                    put(?pd_team_id, TeamId),
                    team_svr:sava_not_full_team_id(length(TMs1), TeamType, TeamId),
                    ?player_send(team_sproto:pkg_msg(?MSG_TEAM_JOIN, {TeamId, TeamType, TeamName, pkg_members(TMs1)})),
                    ok;
                _ ->
                    {error, ?ERR_SYSTEM}
            end;
        [#team{type=TeamType}] ->
            team_svr:sava_not_full_team_id(3, TeamType, TeamId),
            {error, ?ERR_TEAM_IS_FULL};
        [] ->
            {error, ?ERR_TEAM_FAST_JOIN}
    end.
    % case Ret of
    %     {ok, NTMs} ->
    %         ?player_send(team_sproto:pkg_msg(?MSG_TEAM_JOIN, {?REPLY_MSG_TEAM_JOIN_OK, TeamId, <<>>, pkg_members(NTMs)}));
    %     {error, Reason} ->
    %         Reply = 
    %         if
    %             Reason =:= team_full ->
    %                 ?REPLY_MSG_TEAM_JOIN_1;
    %             ?true ->
    %                 ?REPLY_MSG_TEAM_JOIN_255
    %         end,
    %         ?player_send(team_sproto:pkg_msg(?MSG_TEAM_JOIN, {Reply, TeamId, <<>>, []}))
    % end.


join_ex(TeamId) ->
    case ets:lookup(?team_info, TeamId) of
        [#team{pid = Pid, team_name=TeamName, type=TeamType, members = TMs}] when length(TMs) < ?TEAM_MEMBERS_MAX ->
            TM = get_team_member(),
            case gen_server:call(Pid, {join, TM}) of
                ok ->
                    ets:insert(?team_mem_index, {TM#team_member.id, TeamId}),
                    [#team{members = TMs1}] = ets:lookup(?team_info, TeamId),
                    lists:foreach(fun(#team_member{id = Id}) ->
                            world:send_to_player_if_online(Id, 
                                ?to_client_msg(team_sproto:pkg_msg(?MSG_TEAM_MEMBER_JOIN, {pkg_member(TM)})))
                    end,
                    TMs),
                    put(?pd_team_id, TeamId),
                    team_svr:sava_not_full_team_id(length(TMs1), TeamType, TeamId),
                    ?player_send(team_sproto:pkg_msg(?MSG_TEAM_JOIN, {TeamId, TeamType, TeamName, pkg_members(TMs1)})),
                    ok;
                _ ->
                    {error, ?ERR_SYSTEM}
            end;
        [#team{type=TeamType}] ->
            team_svr:sava_not_full_team_id(3, TeamType, TeamId),
            {error, ?ERR_TEAM_IS_FULL}
    end.

% join_ex(TeamId) ->
%     Ret = case ets:lookup(?team_info, TeamId) of
%               [#team{pid = Pid, members = TMs}] when length(TMs) < ?TEAM_MEMBERS_MAX ->
%                   TM = get_team_member(),
%                   case gen_server:call(Pid, {join, TM}) of
%                       ok ->
%                           ets:insert(?team_mem_index, {TM#team_member.id, TeamId}),
%                           [#team{members = TMs1}] = ets:lookup(?team_info, TeamId),
%                           lists:foreach
%                           (
%                               fun(#team_member{id = Id}) ->
%                                   world:send_to_player_if_online(Id, ?to_client_msg(team_sproto:pkg_msg(?MSG_TEAM_MEMBER_JOIN, {pkg_member(TM)})))
%                               end,
%                               TMs
%                           ),
%                           % ?INFO_LOG("================================= put pd_team_id ~p 141", [?MODULE]),
%                           put(?pd_team_id, TeamId),
%                           % ?INFO_LOG("playerid ~w Join", [{get(?pd_id), TeamId, get(?pd_team_id)}]),
%                           {ok, TMs1};
%                       _ ->
%                           {error, join_fail}
%                   end;
%               _ ->
%                   {error, team_full}
%           end,
%     case Ret of
%         {ok, NTMs} ->
%             % ?INFO_LOG("MSG_TEAM_JOIN ~p",[{?REPLY_MSG_TEAM_JOIN_OK, TeamId, pkg_members(NTMs)}]),
%             ?player_send(team_sproto:pkg_msg(?MSG_TEAM_JOIN, {?REPLY_MSG_TEAM_JOIN_OK, <<>>, TeamId, pkg_members(NTMs)})),
%             ok;
%         {error, Reason} ->
%             Reply = if
%                         Reason =:= team_full ->
%                             ?REPLY_MSG_TEAM_JOIN_1;
%                         ?true ->
%                             ?REPLY_MSG_TEAM_JOIN_255
%                     end,
%             ?player_send(team_sproto:pkg_msg(?MSG_TEAM_JOIN, {Reply, TeamId, []})),
%             {error, Reason}
%     end.


%% 退出队伍
quit() ->            %% 角色进程调用
    PlayerId = get(?pd_id),
    put(?pd_team_id, ?undefined),
    case team_svr:playerid2teamid(PlayerId) of
        TeamId when is_integer(TeamId) ->
            quit(PlayerId, TeamId);
        ?undefined ->
            {error, ?ERR_TEAM_INS_ROOM_NOT_EXIST}
    end.

quit(PlayerId, TeamId) ->  %% 非角色进程调用
    case ets:lookup(?team_info, TeamId) of
        [#team{pid = Pid, members = TMs}] ->
            case lists:keymember(PlayerId, #team_member.id, TMs) of
                ?true ->
                    Pid ! {quit, PlayerId},
                    ok;
                ?false ->
                    {error, ?ERR_TEAM_NOT_EXIST_PLAYER}
            end;
        _ ->
            {error, ?ERR_TEAM_INS_ROOM_NOT_EXIST}
    end.
%% 踢人
kickout(PlayerId) ->
    SelfId = get(?pd_id),
    TeamId = get(?pd_team_id),
    case ets:lookup(?team_info, TeamId) of
        [#team{pid = Pid, members = [#team_member{id = LId} | _] = TMs}] ->
            %?DEBUG_LOG("kickout TMs---------------------------------:~p",[TMs]),
            IsIn = lists:keymember(PlayerId, #team_member.id, TMs),
            %?DEBUG_LOG("IsIn-----------------------------------------:~p",[IsIn]),
            if
                SelfId =/= LId ->
                    {error, ?ERR_TEAM_NOT_LEADER};
                IsIn =:= ?false ->
                    {error, ?ERR_TEAM_NOT_EXIST_PLAYER};
                ?true ->
                    Pid ! {kickout, PlayerId},
                    %lists:foreach(fun(#team_member{id = Id}) ->
                    %    ?DEBUG_LOG("Id------------------------------------------:~p",[Id]),
                    %    world:send_to_player_if_online(Id, ?to_client_msg(team_sproto:pkg_msg(?MSG_TEAM_QUIT, {PlayerId})))
                    %end, 
                    %TMs),
                    ok
            end;
        _ -> 
            {error, ?ERR_TEAM_INS_ROOM_NOT_EXIST}
    end.

do_broadcast_of_player_leave_team(Members, LeavePlayerId) ->
    lists:foreach(fun(#team_member{id = Id}) ->
        world:send_to_player_if_online(Id, ?to_client_msg(team_sproto:pkg_msg(?MSG_TEAM_QUIT, {LeavePlayerId})))
    end, 
    Members).

%% 解散队伍
disband() ->
    TeamId = get(?pd_team_id),
    disband(TeamId).
disband(TeamId) ->
    TeamId = get(?pd_team_id),
    Ret = 
    case ets:lookup(?team_info, TeamId) of
        [#team{pid = Pid, type=TeamType, members = TMs = [#team_member{id = LId} | _]}] ->
            team_svr:sava_not_full_team_id(3, TeamType, TeamId),
            SelfId = get(?pd_id),
            if
                SelfId =/= LId ->
                    {error, ?ERR_TEAM_NOT_LEADER};
                ?true ->
                    Pid ! disband,
                    lists:foreach(fun(#team_member{id = Id}) ->
                        world:send_to_player_if_online(Id, ?to_client_msg(team_sproto:pkg_msg(?MSG_TEAM_DISSOLVE, {})))
                    end, TMs),
                    ok
            end;
        _E -> 
            {error, ?ERR_TEAM_INS_ROOM_NOT_EXIST}
    end,
    put(?pd_team_id, ?undefined),
    Ret.

set_master_id(TeamId, PlayerId) ->
    case ets:lookup(?team_info, TeamId) of
        [#team{pid = Pid, members = Members}] ->
            case lists:keymember(PlayerId, #team_member.id, Members) of
                ?true ->
                    Pid ! {set_master_id, PlayerId};
                _ ->
                    ?DEBUG_LOG("player : ~p not in team : ~p", [PlayerId, TeamId])
            end;
        _ ->
            ?DEBUG_LOG("can not find team info in ets, player_id:~p, team_id:~p", [PlayerId, TeamId])
    end.

member_leave(PlayerId, TeamId) ->
    case ets:lookup(?team_info, TeamId) of
        [#team{pid = Pid, members = Members}] ->
            case lists:keymember(PlayerId, #team_member.id, Members) of
                ?true ->
                    Pid ! {member_leave, PlayerId};
                _ ->
                    ?DEBUG_LOG("player : ~p not in team : ~p", [PlayerId, TeamId])
            end;
        _ ->
            ?DEBUG_LOG("can not find team info in ets, player_id:~p, team_id:~p", [PlayerId, TeamId])
    end.

%%--------------------------------------------------------------------
%% @doc Starts the server
%% @spec start_link(Team) -> {ok, Pid} | ignore | {error, Error}
%% @end
start_link(Team) ->
    %?DEBUG_LOG("start_link  Team---------------:~p",[Team]),
    gen_server:start_link(?MODULE, [Team], []).

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Initializes the server
%%
%% @spec init(Args) -> {ok, State} |
%%                     {ok, State, Timeout} |
%%                     ignore |
%%                     {stop, Reason}
%% @end
%%--------------------------------------------------------------------
-spec(init(Args :: term()) ->
    {ok, State :: #team{}} | {ok, State :: #team{}, timeout() | hibernate} |
    {stop, Reason :: term()} | ignore).

init([Team = #team{}]) ->
    {ok, Team#team{pid = self()}}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling call messages
%%
%% @end
%%--------------------------------------------------------------------
-spec(handle_call(Request :: term(), From :: {pid(), Tag :: term()}, State :: #team{}) ->
    {reply, Reply :: term(), NewState :: #team{}} |
    {reply, Reply :: term(), NewState :: #team{}, timeout() | hibernate} |
    {noreply, NewState :: #team{}} |
    {noreply, NewState :: #team{}, timeout() | hibernate} |
    {stop, Reason :: term(), Reply :: term(), NewState :: #team{}} |
    {stop, Reason :: term(), NewState :: #team{}}).

%% 加入队伍
handle_call({join, TM}, _From, Team = #team{members = TMs}) ->
    %?DEBUG_LOG("TM-----------------------:~p",[TM]),
    FinalTeam = 
    case lists:keymember(TM#team_member.id, #team_member.id, TMs) of
        ?true ->
            Team;
        ?false ->
            TMs1 = lists:reverse(TMs),
            %?DEBUG_LOG("TMs1----------------------------:~p",[TMs1]),
            NTMs = lists:reverse([TM | TMs1]),
            %?DEBUG_LOG("NTMs---------------------------------:~p",[NTMs]),
            NTPower = clac_team_power(NTMs),
            NTeam = Team#team{members = NTMs, power = NTPower},
            %?DEBUG_LOG("NTeam-------------------------------:~p",[NTeam]),
            ets:insert(?team_info, NTeam),
            NTeam
    end,
    {reply, ok, FinalTeam};

handle_call(_Request, _From, State) ->
    {reply, ok, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling cast messages
%%
%% @end
%%--------------------------------------------------------------------
-spec(handle_cast(Request :: term(), State :: #team{}) ->
    {noreply, NewState :: #team{}} |
    {noreply, NewState :: #team{}, timeout() | hibernate} |
    {stop, Reason :: term(), NewState :: #team{}}).
handle_cast(_Request, State) ->
    {noreply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling all non call/cast messages
%%
%% @spec handle_info(Info, State) -> {noreply, State} |
%%                                   {noreply, State, Timeout} |
%%                                   {stop, Reason, State}
%% @end
%%--------------------------------------------------------------------
-spec(handle_info(Info :: timeout | term(), State :: #team{}) ->
    {noreply, NewState :: #team{}} |
    {noreply, NewState :: #team{}, timeout() | hibernate} |
    {stop, Reason :: term(), NewState :: #team{}}).

%% 退出队伍
handle_info({quit, PlayerId}, Team = #team{id = TeamId, type=TeamType, members = TMs}) ->
    %%     %?DEBUG_LOG("quit-------------------------------------------:~p",[Team]),
    put(?pd_team_id, ?undefined),
    Len = length(TMs),
    if
        Len =< 1 ->
            %% old---------------------------------------------------
            %% 最后一个人退出队伍的时候直接解散队伍
            %Team1 = #team{id = TeamId, members = []},
            %{stop, normal, Team1};
            %% old-----------------------------------------------------
            world:send_to_player_if_online(PlayerId, ?to_client_msg(team_sproto:pkg_msg(?MSG_TEAM_QUIT, {PlayerId}))),
            {stop, normal, Team};
        ?true ->
            NTMs = lists:keydelete(PlayerId, #team_member.id, TMs),
            %%NTPower = clac_team_power(NTMs),
            %%NTeam = Team#team{members = NTMs, power = NTPower},
            NTeam = Team#team{members = NTMs},
            team_svr:sava_not_full_team_id(length(NTMs), TeamType, TeamId),
            ets:insert(?team_info, NTeam),
            ets:delete(?team_mem_index, PlayerId),
            %% 重新将队伍加入到加入队伍列表中
            %%arena_m_p2p:add_join_team(TeamId),
            do_broadcast_of_player_leave_team(TMs, PlayerId),
            {noreply, NTeam}
    end;
%% 踢人
handle_info({kickout, PlayerId}, Team = #team{id=TeamId, type=TeamType, members = TMs}) ->
    NTMs = lists:keydelete(PlayerId, #team_member.id, TMs),
    NTPower = clac_team_power(NTMs),
    NTeam = Team#team{members = NTMs, power = NTPower},
    ets:insert(?team_info, NTeam),
    ets:delete(?team_mem_index, PlayerId),
    team_svr:sava_not_full_team_id(length(NTMs), TeamType, TeamId),

    do_broadcast_of_player_leave_team(TMs, PlayerId),
    {noreply, NTeam};

handle_info({update_team_msg_list, PlayerId, DoType}, Team) ->
    NewTeam = team_svr:update_team_msg_list(Team, PlayerId, DoType),
    {noreply, NewTeam};

handle_info({update_team_flg, IsFlg}, Team) ->
    NewTeam = Team#team{auto_flg=IsFlg},
    ets:insert(?team_info, NewTeam),
    {noreply, NewTeam};

%% 设置队长
handle_info({set_master_id, PlayerId}, Team) ->
    FinalTeam = Team#team{master_id = PlayerId},
    ets:insert(?team_info, FinalTeam),
    {noreply, Team#team{master_id = PlayerId}};
%% 成员离队
handle_info({member_leave, PlayerId}, #team{id=TeamId,type=_TeamType, members = Members, master_id = MasterId} = Team) ->
    %?DEBUG_LOG("member_leave------------------------------------------:~p",[Members]),
    case PlayerId =:= MasterId of
        true ->
            List = [M#team_member.id || M <- Members, M#team_member.id =/= PlayerId, world:is_player_online(M#team_member.id)],
            case List =/= [] of
                true ->
                    NewMasterId = lists:nth(1, List),
                    NextMembers = lists:keydelete(PlayerId, #team_member.id, Members),
                    do_broadcast_of_player_leave_team(Members, PlayerId),
                    ?DEBUG_LOG("TeamLeader is leave member------------------------------------------:~p",[NewMasterId]),
                    Msg = ?to_client_msg(main_instance_sproto:pkg_msg(?MSG_MAIN_INSTANCE_NOTIFY_TEAM_MASTER, {NewMasterId})),
                    members_notify(NextMembers, Msg),
                    FinalTeam = Team#team{master_id = NewMasterId, members = NextMembers},
                    ets:delete(?team_mem_index, PlayerId),
                    ets:insert(?team_info, FinalTeam),
                    {noreply, FinalTeam};
                _ ->
                    ?DEBUG_LOG("2--------------------------------------------"),
                    do_broadcast_of_player_leave_team(Members, PlayerId),
                    ets:delete(?team_mem_index, PlayerId),
                    gwgc_server:update_npc_status_by_teamid(TeamId, 0),
                    {stop, normal, Team}
            end;
        _ ->
            case lists:keymember(PlayerId, #team_member.id, Members) of
                ?true ->
                    NTMs = lists:keydelete(PlayerId, #team_member.id, Members),
                    NTeam = Team#team{members = NTMs},
                    ets:delete(?team_mem_index, PlayerId),
                    if
                        NTMs =:= [] ->
                            ?DEBUG_LOG("3--------------------------------------------"),
                            gwgc_server:update_npc_status_by_teamid(TeamId, 0),
                            do_broadcast_of_player_leave_team(Members, PlayerId),
                            {stop, normal, NTeam};
                        true ->
                            ?DEBUG_LOG("4--------------------------------------------"),
                            do_broadcast_of_player_leave_team(Members, PlayerId),
                            ets:insert(?team_info, NTeam),
                            {noreply, NTeam}
                    end;
                ?false ->
                    {noreply, Team}
            end
    end;

handle_info(scene_notice_disband, #team{members = TMs} = Team) ->
    ?DEBUG_LOG("scene_notice_disband----------------------:~p",[TMs]),
    lists:foreach(fun(#team_member{id = Id}) ->
        world:send_to_player_if_online(Id, ?to_client_msg(team_sproto:pkg_msg(?MSG_TEAM_DISSOLVE, {})))
    end, TMs),
    {stop, normal, Team};


%% 解散队伍
handle_info(disband, Team) ->
    ?DEBUG_LOG("team_mod disband-------------------------------"),
    {stop, normal, Team};

handle_info(_Info, State) ->
    {noreply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% This function is called by a gen_server when it is about to
%% terminate. It should be the opposite of Module:init/1 and do any
%% necessary cleaning up. When it returns, the gen_server terminates
%% with Reason. The return value is ignored.
%%
%% @spec terminate(Reason, State) -> void()
%% @end
%%--------------------------------------------------------------------
-spec(terminate(Reason :: (normal | shutdown | {shutdown, term()} | term()),
    State :: #team{}) -> term()).
terminate(normal, Team) ->
    ?DEBUG_LOG("team_mod terminate------------------------2---------------"),
    terminate(Team),
    ok;
terminate(_Reason, Team) ->
    terminate(Team),
    ?ERROR_LOG("队伍进程意外销毁原因~w", [_Reason, self()]),
    ok.


%%--------------------------------------------------------------------
%% @private
%% @doc
%% Convert process state when code is changed
%%
%% @spec code_change(OldVsn, State, Extra) -> {ok, NewState}
%% @end
%%--------------------------------------------------------------------
-spec(code_change(OldVsn :: term() | {down, term()}, State :: #team{},
    Extra :: term()) ->
    {ok, NewState :: #team{}} | {error, Reason :: term()}).
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.


terminate(#team{id = Id, members = TMs, type = TeamType}) ->
    ?DEBUG_LOG("del_join_team, del_match_team----------------------------------- :~p",[{Id, TeamType}]),
    % arena_m_p2p:del_join_team(Id),
    % arena_m_p2p:del_match_team(Id),
    ets:delete(?team_info, Id),
    [
        begin
            ets:delete(?team_mem_index, MId),
            %ets:delete(?team_info, MId),
            team_svr:sava_not_full_team_id(3, TeamType, Id),
            ok
        end
        || #team_member{id = MId} <- TMs
    ],
    team_svr ! {team_disappear, Id, TeamType}.

clac_team_power(TMs) ->
    lists:foldl(fun(#team_member{power = Power}, TPower) -> TPower + Power end, 0, TMs).

get_team_member() ->
    Id = get(?pd_id),
    Name = get(?pd_name),
    Lev = get(?pd_level),
    Car = get(?pd_career),
    Power = get(?pd_combat_power),
    MaxHp = attr_new:get_attr_item(?pd_attr_max_hp),
    #team_member{id = Id, name = Name, lev = Lev, career = Car, power = Power, max_hp = MaxHp, online = ?TRUE}.

pkg_members(TMs) ->
    [pkg_member(TM) || TM <- TMs].

pkg_member(#team_member{id = Id, name = Name, lev = Lev, power = Power, career = Car, max_hp = MaxHp, online = Online}) ->
    JiFen = rank_mng:get_gwgc_jifen(Id),
    {Id, Name, Lev, JiFen, Power, Car, MaxHp, Online}.

members_notify(Members, Msg) ->
    [world:send_to_player_if_online(M#team_member.id, Msg) || M <- Members].