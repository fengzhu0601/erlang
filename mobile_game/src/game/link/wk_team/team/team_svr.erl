%%-----------------------------------------------------------------t
%%-
%% @author zlb
%% @doc 组队基础服务模块
%%
%% @end
%%-------------------------------------------------------------------

-module(team_svr).
-behaviour(gen_server).

-export([
    start_link/0,
    playerid2teamid/1,
    create_team/1,
    get_team_list_info/1,
    get_team_list_info1/1,
    apply_join_team/1,
    get_team_shenqing_list_info/1,
    leader_deal_shenqing_list/3,
    is_create_team/2,
    get_team_name/1,
    sava_not_full_team_id/3,
    fast_join/1,
    get_team_info_by_player/1,
    get_team_info/1,
    set_leader/2,
    is_leader/0,
    is_leader/1,
    get_team_id_by_player/1,
    get_team_pid_by_teamid/1,
    update_team_msg_list/3,
    update_team_flg/2,
    get_leader_by_teamid/1
]
).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-include("inc.hrl").
-include("player.hrl").
-include("safe_ets.hrl").
-include("team_struct.hrl").
-include("team_mng_reply.hrl").


-record(state, {
    auto_team_id = 1
}).

sava_not_full_team_id(Size, ?TEAM_TYPE_GONGCHENG, TeamId) when is_integer(TeamId) ->
    %?DEBUG_LOG("sava_not_full_team_id-----------:~p--Size---:~p",[TeamId, Size]),
    if
        Size <  ?TEAM_MEMBERS_MAX->
            add_is_full_team_id_list(?TEAM_TYPE_GONGCHENG, TeamId);
        true ->
            del_is_full_team_id_list(?TEAM_TYPE_GONGCHENG, TeamId)
    end;

sava_not_full_team_id(_, _, _) ->
    pass.

is_create_team(PlayerId, TeamType) ->
    case lists:member(TeamType, ?TEAM_TYPES) of
        ?true ->
            case playerid2teamid(PlayerId) of
                ?undefined ->
                    ?true;
                _ ->
                    {error, ?ERR_TEAM_ALREADY_EXIST}
            end;
        _ ->
            {error, ?ERR_TEAM_TYPE_ERROR}
    end.
playerid2teamid(PlayerId) ->
    case ets:lookup(?team_mem_index, PlayerId) of
        [{_, TeamId}] -> 
            %?DEBUG_LOG("PlayerId-------:~p-------TeamId----:~p",[PlayerId, TeamId]),
            case ets:lookup(?team_info, TeamId) of
                [] ->
                    %?DEBUG_LOG("1-------------------------------"),
                    ets:delete(?team_mem_index, PlayerId),
                    ?undefined;
                _ ->
                    TeamId
            end;
        _ -> 
            %?DEBUG_LOG("2--------------------------------"),
            ?undefined
    end.
%% 创建队伍
create_team({TeamType, TeamName, TeamLeader, TM}) ->
    gen_server:call(?MODULE, {create, TeamType, TeamName, TeamLeader, TM}).

create_safe_ets() ->
    [
        safe_ets:new(?team_mem_index, [?named_table, ?ordered_set, {?keypos, 1}, ?public, {?read_concurrency, ?true}, {?write_concurrency, ?true}]),
        safe_ets:new(?team_type_index, [?named_table, ?ordered_set, {?keypos, 1}, ?public, {?read_concurrency, ?true}, {?write_concurrency, ?true}]),
        safe_ets:new(?is_full_team_id_list, [?named_table, ?ordered_set, {?keypos, 1}, ?public, {?read_concurrency, ?true}, {?write_concurrency, ?true}]),
        safe_ets:new(?team_info, [?named_table, ?ordered_set, {?keypos, #team.id}, ?public, {?read_concurrency, ?true}, {?write_concurrency, ?true}])
    ].
%%--------------------------------------------------------------------
%% @doc Starts the server
%% @spec start_link() -> {ok, Pid} | ignore | {error, Error}
%% @end
start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

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
    {ok, State :: #state{}} | {ok, State :: #state{}, timeout() | hibernate} |
    {stop, Reason :: term()} | ignore).
init([]) ->
    process_flag(trap_exit, ?true),
    {ok, #state{}}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling call messages
%%
%% @end
%%--------------------------------------------------------------------
-spec(handle_call(Request :: term(), From :: {pid(), Tag :: term()}, State :: #state{}) ->
    {reply, Reply :: term(), NewState :: #state{}} |
    {reply, Reply :: term(), NewState :: #state{}, timeout() | hibernate} |
    {noreply, NewState :: #state{}} |
    {noreply, NewState :: #state{}, timeout() | hibernate} |
    {stop, Reason :: term(), Reply :: term(), NewState :: #state{}} |
    {stop, Reason :: term(), NewState :: #state{}}).

%% 创建队伍
handle_call({create, TeamType, TeamName, TeamLeader, TM}, _From, State = #state{auto_team_id = TeamId}) ->
    Team = #team{id = TeamId, team_name=TeamName, 
                members = [TM], power = TM#team_member.power, 
                type = TeamType,
                master_id=TeamLeader},
    case team_mod:start_link(Team) of
        {ok, TeamPid} ->
            %?DEBUG_LOG("Team----------------------------:~p",[Team]),
            ets:insert(?team_mem_index, {TM#team_member.id, TeamId}),
            ets:insert(?team_info, Team#team{pid = TeamPid}),
            add_team_type_index(TeamType, TeamId),
            add_is_full_team_id_list(TeamType, TeamId),
            {reply, {ok, TeamId}, State#state{auto_team_id = TeamId + 1}};
        _E ->
            ?debug_log_team("create_team fail, reason ~w", [_E]),
            {reply, {error, create_team_fail}, State}
    end;
handle_call(_Request, _From, State) ->
    {reply, ok, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling cast messages
%%
%% @end
%%--------------------------------------------------------------------
-spec(handle_cast(Request :: term(), State :: #state{}) ->
    {noreply, NewState :: #state{}} |
    {noreply, NewState :: #state{}, timeout() | hibernate} |
    {stop, Reason :: term(), NewState :: #state{}}).
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
-spec(handle_info(Info :: timeout | term(), State :: #state{}) ->
    {noreply, NewState :: #state{}} |
    {noreply, NewState :: #state{}, timeout() | hibernate} |
    {stop, Reason :: term(), NewState :: #state{}}).
handle_info({ets_insert, Table, Value}, State) ->
    ets:insert(Table, Value),
    {noreply, State};
handle_info({ets_del, Table, Key}, State) ->
    ets:delete(Table, Key),
    {noreply, State};
handle_info({ets_update, Table, Value}, State) ->
    ets:insert(Table, Value),
    {noreply, State};

handle_info({all_team_disband, Type}, State) ->
    all_team_disband(Type),
    {noreply, State};

handle_info({team_disappear, TeamId, TeamType}, State) ->
    %?DEBUG_LOG("team_disappear------------:~p",[{TeamId, TeamType}]),
    del_team_type_index(TeamType, TeamId),
    {noreply, State};

handle_info({'EXIT', _Pid, normal}, State) ->
    {noreply, State};

handle_info({'EXIT', Pid, Reason}, State) ->
    ?ERROR_LOG("队伍进程[~w]异常挂掉: ~w", [Pid, {Reason}]),
    ets:match_delete(?team_info, #team{pid = Pid, _ = '_'}),
    {noreply, State};

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
    State :: #state{}) -> term()).
terminate(_Reason, _State) ->
    ?ERROR_LOG("_Reason---------------------------------------:~p",[_Reason]),
    ok.


%%--------------------------------------------------------------------
%% @private
%% @doc
%% Convert process state when code is changed
%%
%% @spec code_change(OldVsn, State, Extra) -> {ok, NewState}
%% @end
%%--------------------------------------------------------------------
-spec(code_change(OldVsn :: term() | {down, term()}, State :: #state{},
    Extra :: term()) ->
    {ok, NewState :: #state{}} | {error, Reason :: term()}).
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

get_team_info_by_player(PlayerId) ->
    case ets:lookup(?team_mem_index, PlayerId) of
        [] ->
            %?DEBUG_LOG("1--------------------"),
            ?none;
        [{_,TeamId}] ->
            case ets:lookup(?team_info, TeamId) of
                [T] ->
                    T;
                _E ->
                    ?DEBUG_LOG("2---------------------:~p",[_E]),
                    ?none
            end
    end.


get_team_id_by_player(PlayerId) ->
    case ets:lookup(?team_mem_index, PlayerId) of
        [] ->
            ?none;
        [{_,TeamId}] ->
            TeamId
    end.

add_team_type_index(TeamType, TeamId) ->
    NTeamIds =
        case ets:lookup(?team_type_index, TeamType) of
            [{_, TeamIds}] ->
                [TeamId | TeamIds];
            _ ->
                [TeamId]
        end,
    ets:insert(?team_type_index, {TeamType, NTeamIds}).


del_team_type_index(TeamType, TeamId) ->
    case ets:lookup(?team_type_index, TeamType) of
        [{_, TeamIds}] ->
            ets:insert(?team_type_index, {TeamType, lists:delete(TeamId, TeamIds)});
        _E ->
            ignore
    end.

get_team_type_index(TeamType) ->
    case ets:lookup(?team_type_index, TeamType) of
        [{_, TeamIds}] ->
            TeamIds;
        _->
            []
    end.    

add_is_full_team_id_list(TeamType, TeamId) ->
   %?DEBUG_LOG("TeamType----+++--------------:~p-------------TeamId---:~p",[TeamType, TeamId]),
    NTeamIds = 
    case ets:lookup(?is_full_team_id_list, TeamType) of
        [{_, TeamIds}] -> 
            case lists:member(TeamId, TeamIds) of
                ?true ->
                    TeamIds;
                _ ->
                    [TeamId|TeamIds]
            end;
        _ -> 
            [TeamId]
   end,
   %?DEBUG_LOG("NTeamIds----:~p",[NTeamIds]),
    ets:insert(?is_full_team_id_list, {TeamType, NTeamIds}).


del_is_full_team_id_list(TeamType, TeamId) ->
    case ets:lookup(?is_full_team_id_list, TeamType) of
        [{_, TeamIds}] -> 
            ets:insert(?is_full_team_id_list, {TeamType, lists:delete(TeamId, TeamIds)});
        _ -> 
            pass
    end.

get_is_full_team_id_list(TeamType) ->
    case ets:lookup(?is_full_team_id_list, TeamType) of
        [{_, TeamIds}] ->
            TeamIds;
        _->
            ?none
    end.    


get_team_info(TeamId) ->
    case ets:lookup(?team_info, TeamId) of
        [] ->
            ?none;
        [T] ->
            T
    end.

get_team_name(TeamId) ->
    case ets:lookup(?team_info, TeamId) of
        [] ->
            <<>>;
        [#team{team_name=Name}] ->
            Name
    end.

get_team_pid_by_teamid(TeamId) ->
    case ets:lookup(?team_info, TeamId) of
        [#team{pid = Pid}] ->
            Pid;
        _ ->
            ?none
    end.

get_leader_by_teamid(TeamId) ->
    case ets:lookup(?team_info, TeamId) of
        [#team{master_id = Id}] ->
            Id;
        _ ->
            ?none
    end.

set_leader(TeamId, PlayerId) ->
    %?DEBUG_LOG("TeamId------:~p-----PlayerId----:~p",[TeamId, PlayerId]),
    case ets:lookup(?team_info, TeamId) of
        [#team{master_id = PlayerId}] ->
            PlayerId;
        [#team{pid = Pid}] ->
            Pid ! {set_master_id, PlayerId},
            PlayerId;
        _ ->
            ?DEBUG_LOG("can not find team info in ets, player_id:~p,-- team_id:~p", [PlayerId, TeamId])
    end.

is_leader() ->
    SelfId = get(?pd_id),
    %?DEBUG_LOG("is_leader------------------------:~p",[SelfId]),
    TeamId = get(?pd_team_id),
    case ets:lookup(?team_info, TeamId) of
        [#team{master_id = SelfId}] ->
            ?true;
        _ ->
            ?false
    end.

is_leader(PlayerId) ->
    IsLeader = 
    case ets:lookup(?team_mem_index, PlayerId) of
        [] ->
            % ?DEBUG_LOG("1----------------------------------"),
            ?false;
        [{_, TeamId}] ->
            % ?DEBUG_LOG("TeamId-------------------------------:~p",[TeamId]),
            case ets:lookup(?team_info, TeamId) of
                [#team{master_id = PlayerId}] ->
                    ?true;
                _ ->
                    ?false
            end
    end,
    %?DEBUG_LOG("PlayerId-----:~p----IsLeader---:~p",[PlayerId, IsLeader]),
    IsLeader.

all_team_disband(TeamType) ->
    TeamIdList = get_team_type_index(TeamType),
    lists:foreach(fun(TeamId) ->
        case get_team_info(TeamId) of
            ?none ->
                pass;
            #team{pid = Pid, members=Ms}->
                    Pid ! disband,
                    lists:foreach(fun(#team_member{id = Id}) ->
                        world:send_to_player_if_online(Id, ?to_client_msg(team_sproto:pkg_msg(?MSG_TEAM_DISSOLVE, {})))
                    end, 
                    Ms)
        end
    end,
    TeamIdList).


get_team_list_info(TeamType) ->
    TeamIdList = get_team_type_index(TeamType),
    {NewBin, Total} = lists:foldl(
        fun(TeamId, {Bin, Size}) ->
                case get_team_info(TeamId) of
                    ?none ->
                        {Bin, Size};
                    #team{id=Id, team_name=TeamName, master_id=_MasterId, members=Ms}->
                        MsBin = pkg_all_members_to_bin(Ms),
                        {<<Bin/binary, Id:32,?pkg_sstr(TeamName), MsBin/binary>>, Size+1}
                end
        end,
        {<<>>,0},
        TeamIdList
    ),
    <<Total:16, NewBin/binary>>.

get_team_list_info1(TeamType) ->
    TeamIdList = get_team_type_index(TeamType),
    lists:foldl(
        fun(TeamId, Acc) ->
                case get_team_info(TeamId) of
                    #team{team_name = TeamName, master_id = MasterId, members = Ms} ->
                        ML = [{PlayerId, PlayerName, Job, Lev, Power} || #team_member{id = PlayerId, name = PlayerName, career = Job, lev = Lev, power = Power} <- Ms],
                        [{TeamId, TeamName, MasterId, ML} | Acc];
                    _ ->
                        Acc
                end
        end,
        [],
        TeamIdList
    ).

pkg_all_members_to_bin(Ms) ->
    lists:foldl(fun(M, Acc) ->
        PlayerBin = pkg_members_to_bin(M),
        <<Acc/binary, PlayerBin/binary>>
    end,
    <<(length(Ms)):16>>,
    Ms).

pkg_members_to_bin(#team_member{id = Id, name = Name, lev = Lev, 
    power = Power, career = Car, max_hp = MaxHp, online = Online}) ->
    JiFen = rank_mng:get_gwgc_jifen(Id),
    <<Id:64, ?pkg_sstr(Name), Lev:8, JiFen:32, Power:32, Car:8, MaxHp:32, Online:8>>.


update_team_msg_list(Team, PlayerId, DoType) ->
    TeamMsg = Team#team.team_msg,
    %?DEBUG_LOG("TeamMsg---------------------------:~p",[TeamMsg]),
    NewTeamMsg = 
    if
        DoType =:= 1 ->
            case lists:member(PlayerId, TeamMsg) of
                ?false ->
                    [PlayerId|TeamMsg];
                _ ->
                    TeamMsg
            end;
        DoType =:= 2 ->
            lists:delete(PlayerId, TeamMsg)
    end,
    %?DEBUG_LOG("NewTeamMsg--------------------------:~p",[NewTeamMsg]),
    NewTeam = Team#team{team_msg=NewTeamMsg},
    ets:insert(?team_info, NewTeam),
    NewTeam.


update_team_flg(TeamId, IsFlg) ->
    case get_team_info(TeamId) of
        ?none ->
            pass;
        #team{pid=Pid} ->
            Pid ! {update_team_flg, IsFlg}
    end.

is_team_auto_flg(TeamId) ->
    case get_team_info(TeamId) of
        #team{auto_flg=1} ->
            ?true;
        _ ->
            ?false
    end.


apply_join_team(TeamId) ->
    case get_team_info(TeamId) of
        ?none ->
            %?DEBUG_LOG("apply_join_team---------------------------------1"),
            ?none;
        #team{pid=Pid} ->
            %?DEBUG_LOG("apply_join_team------------------------------------2"),
            case is_team_auto_flg(TeamId) of
                ?true ->
                    %?DEBUG_LOG("apply_join_team----------------------------3"),
                    R = team_mod:join(TeamId),
                    {auto_pass, R};
                _ ->
                    %?DEBUG_LOG("apply_join_team-------------------------------------4"),
                    PlayerId = get(?pd_id),
                    Pid ! {update_team_msg_list, PlayerId, 1},
                    ok
            end
    end.

get_team_shenqing_list_info(TeamId) ->
    SelfId = get(?pd_id),
    case get_team_info(TeamId) of
        ?none ->
            {error, ?ERR_TEAM_INS_ROOM_NOT_EXIST};
        #team{master_id=SelfId, team_msg=TeamMsg}->
            {NewAcc, Total} =
            lists:foldl(fun(PlayerId, {Acc, Size}) ->
                case player:lookup_info(PlayerId, [?pd_name, ?pd_level, ?pd_combat_power, ?pd_career]) of
                    [?none] ->
                        {Acc, Size};
                    [Name, Lev, Power, Car] ->
                        %?DEBUG_LOG("Lev-----:~p-----Car----:~p",[Lev, Car]),
                        IsOnline = util:bool_to_int(world:is_player_online(PlayerId)),
                        {<<Acc/binary, PlayerId:64, ?pkg_sstr(Name), Lev:8, Power:32, Car:8, IsOnline:8>>, Size+1}
                end
           end,
           {<<>>, 0},
           TeamMsg),
            <<Total:8, NewAcc/binary>>;
        _ ->
            {error, ?ERR_TEAM_NOT_LEADER}
    end.

leader_deal_shenqing_list(TeamId, PlayerId, DoType) ->
    SelfId = get(?pd_id),
    case get_team_info(TeamId) of
        ?none ->
            {error, ?ERR_TEAM_INS_ROOM_NOT_EXIST};
        #team{master_id=SelfId} = Team->
            do_leader_deal_shenqing_list(Team, PlayerId, DoType);
        _ ->
            {error, ?ERR_TEAM_NOT_LEADER}
    end.
do_leader_deal_shenqing_list(Team, PlayerId, 1) ->
    #team{members = TMS} = Team,
    %?DEBUG_LOG("do_leader_deal_shenqing_list------------------------------:~p",[Team]),
    Size = length(TMS),
    TeamId = Team#team.id,
    TeamType = Team#team.type,
    Pid = Team#team.pid,
    if
        Size < ?TEAM_MEMBERS_MAX ->
            case get_team_info_by_player(PlayerId) of
                ?none ->
                    case new_team_member(PlayerId) of
                        ?false ->
                            {error, ?ERR_ROLE_NOT_EXIST};
                        NewMt ->
                            case gen_server:call(Pid, {join, NewMt}) of
                                ok ->
                                    ets:insert(?team_mem_index, {PlayerId, TeamId}),
                                    [#team{team_name = TeamName, members = TMs1} = _NewTeam] = ets:lookup(?team_info, TeamId),
                                    %?DEBUG_LOG("NewTeam------------------------------------:~p",[NewTeam]),
                                    lists:foreach(fun(#team_member{id = Id}) ->
                                        world:send_to_player_if_online(Id, 
                                        ?to_client_msg(team_sproto:pkg_msg(?MSG_TEAM_MEMBER_JOIN, {team_mod:pkg_member(NewMt)})))
                                    end,
                                    TMs1),
                                    world:send_to_player_if_online(PlayerId,
                                    ?to_client_msg(team_sproto:pkg_msg(?MSG_TEAM_JOIN, {TeamId, TeamType, TeamName, team_mod:pkg_members(TMs1)}))),
                                    Pid ! {update_team_msg_list, PlayerId, 2},
                                    sava_not_full_team_id(length(TMs1), TeamType, TeamId),
                                    ?DEBUG_LOG("do_leader_deal_shenqing_list------------:~p",[TeamId]),
                                    %put(?pd_team_id, TeamId),
                                    world:send_to_player_any_state(PlayerId,?mod_msg(team_mng, {put_team_id_to_player_process, TeamId})),
                                    ok;
                                _ ->
                                    {error, ?ERR_SYSTEM}
                            end
                    end;
                _ ->
                    Pid ! {update_team_msg_list, PlayerId, 2},
                    {error, ?ERR_TEAM_ALREADY_EXIST}
            end;
        true ->
            sava_not_full_team_id(3, TeamType, TeamId),
            {error, ?ERR_TEAM_IS_FULL}
    end;
do_leader_deal_shenqing_list(#team{pid=Pid}, PlayerId, 2) ->
    Pid ! {update_team_msg_list, PlayerId, 2},
    ok.




new_team_member(PlayerId) ->
    case player:lookup_info(PlayerId, [?pd_name, ?pd_level, ?pd_combat_power, ?pd_career,?pd_hp]) of
        [?none] ->
            ?false;
        [Name, Lev, Power, Car, Hp] ->
            #team_member{id = PlayerId, name = Name, lev = Lev, career = Car, power = Power, max_hp = Hp, online = ?TRUE}
    end.


fast_join(TeamType) ->
    case get_is_full_team_id_list(TeamType) of
        ?none ->
            {error, ?ERR_TEAM_FAST_JOIN};
        [] ->
            {error, ?ERR_TEAM_FAST_JOIN};
        L ->
            %?DEBUG_LOG("L------------------------------:~p",[L]),
            TeamId = lists:nth(1, L),
            case gwgc_server:get_npc_status_by_teamid(TeamId) of
                ?true ->
                    team_mod:join(lists:nth(1, L));
                ?false ->
                    {error, ?ERR_TEAM_FAST_JOIN}
            end
    end.
