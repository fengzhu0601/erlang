%%-----------------------------------
%% @Module  : arena_server
%% @Author  : Holtom
%% @Email   : 
%% @Created : 2016.7.22
%% @Description: arena_gen_server
%%-----------------------------------
-module(arena_server).
-behaviour(gen_server).

-include("inc.hrl").
-include("arena.hrl").
-include("arena_struct.hrl").
-include("load_db_misc.hrl").
-include("team.hrl").
-include("player.hrl").
-include("load_spirit_attr.hrl").
-include("load_cfg_arena_robot.hrl").
-include_lib("pangzi/include/pangzi.hrl").

-record(arena_state, {
    p2p_match_list = [],
    multi_p2p_info_list = [],   %% #multi_p2p_info{}
    p2e_rank_prize_finish_time = 0
}).

-record(multi_p2p_info, {
    scene_pid,
    arena_team_list = []    %% #multi_arena_team{}
}).

-record(multi_arena_team, {
    team_id,
    all_kill_times = 0,
    all_die_times = 0,
    leave_counts = 0,
    multi_arena_members = []    %% #arena_member{}
}).

-record(arena_member, {
    player_id,
    die_times = 0,
    kill_times = 0
}).

-define(ARENA_ROBOT_PLATFORM_ID, 3000).                     %% 竞技场机器人平台id
-define(FIRST_P2E_RANK_PRIZE_INTEVAL, 3 * 24 * 60 * 60).    %% 第一次结算为第三天(s)
-define(P2E_RANK_PRIZE_INTEVAL, 24 * 60 * 60).              %% 后面每天结算一次(s)
-define(CHECK_TIME_INTEVAL, 5).                             %% 定时检查的时间间隔，用于周重置和月重置
-define(ARENA_MATCH_TIME_INTEVAL, 5).                       %% 匹配间隔时间

% gen_server callbacks
-export([
        init/1,
        handle_call/3,
        handle_cast/2,
        handle_info/2,
        terminate/2,
        code_change/3
    ]).

%% Module Interface 
-export([
        start_link/0,
        get_p2e_prize_finish_time/0,
        get_player_id_by_rank/1,
        get_rank_by_player_id/1,
        get_rank_page/2,
        player_match_p2p/1,
        player_match_p2p_cancel/1,
        p2p_challenge_player/2,
        create_arena/2,
        start_compete/1,
        start_m_p2p/2,
        player_kill_others/5,
        player_die/2,
        player_leave/2,
        arena_timeout/1,
        is_arena_robot/1,
        init_player_p2e_arena_rank/1,
        update_arena_p2e_rank/2
    ]).

%% =================================================================== 
%% Module Interface
%% ===================================================================
start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

get_p2e_prize_finish_time() ->
    gen_server:call(?MODULE, {'GET_P2E_PRIZE_FINISH_TIME'}).

player_match_p2p({PlayerId, Name, Job, Lev, Power, EquipList, EffList, NowTime}) ->
    gen_server:cast(?MODULE, {'PLAYER_MATCH_P2P', PlayerId, Name, Job, Lev, Power, EquipList, EffList, NowTime}).

player_match_p2p_cancel(PlayerId) ->
    gen_server:call(?MODULE, {'PLAYER_MATCH_P2P_CANCEL', PlayerId}).

p2p_challenge_player(MyInfo, EnemyId) ->
    gen_server:call(?MODULE, {'P2P_CHALLENGE_PLAYER', MyInfo, EnemyId}).

create_arena(ArenaType, Args) ->
    gen_server:call(?MODULE, {'CREATE_ARENA', ArenaType, Args}).

start_compete(PlayerInfo) ->
    gen_server:cast(?MODULE, {'START_COMPETE', PlayerInfo}).

start_m_p2p(Team1, Team2) ->
    erlang:send_after(1500, ?MODULE, {'START_M_P2P', Team1, Team2}).
    % gen_server:cast(?MODULE, {'START_M_P2P', Team1, Team2}).

player_kill_others(KillerId, DeadId, DeadIdx, ArenaInfo, ScenePid) ->
    gen_server:cast(?MODULE, {'PLAYER_KILL_OTHERS', KillerId, DeadId, DeadIdx, ArenaInfo, ScenePid}).

player_die(PlayerId, ArenaInfo) ->
    gen_server:cast(?MODULE, {'PLAYER_DIE', PlayerId, ArenaInfo}).

player_leave(PlayerId, ArenaInfo) ->
    gen_server:cast(?MODULE, {'PLAYER_LEAVE', PlayerId, ArenaInfo}).

arena_timeout(ArenaInfo) ->
    gen_server:cast(?MODULE, {'ARENA_TIME_OUT', ArenaInfo}).

is_arena_robot(PlayerId) ->
    case is_integer(PlayerId) of
        true ->
            {PlatformId, _, _} = tool:un_playerid(PlayerId),
            PlatformId =:= ?ARENA_ROBOT_PLATFORM_ID;
        _ ->
            false
    end.

init_player_p2e_arena_rank(PlayerId) ->
    case dbcache:lookup(?arena_p2e_rank_tab, 0) of
        [#arena_p2e_rank_tab{count = Count, rank_list = RankList} = Tab] ->
            case lists:keyfind(PlayerId, 2, RankList) of
                {Rank, PlayerId} ->
                    Rank;
                _ ->
                    dbcache:update(?arena_p2e_rank_tab, Tab#arena_p2e_rank_tab{count = Count + 1, rank_list = [{Count + 1, PlayerId} | RankList]}),
                    Count + 1
            end;
        _O ->
            0
    end.

update_arena_p2e_rank({Rank1, Id1}, {Rank2, Id2}) ->
    case dbcache:lookup(?arena_p2e_rank_tab, 0) of
        [#arena_p2e_rank_tab{rank_list = RankList} = Tab] ->
            List1 = lists:keyreplace(Rank1, 1, RankList, {Rank1, Id1}),
            List2 = lists:keyreplace(Rank2, 1, List1, {Rank2, Id2}),
            dbcache:update(?arena_p2e_rank_tab, Tab#arena_p2e_rank_tab{rank_list = List2});
        _ ->
            pass
    end.

%% ===================================================================
%% gen_server callbacks
%% ===================================================================
init([]) ->
	process_flag(trap_exit, true),
    case dbcache:lookup(?arena_p2e_rank_tab, 0) of
        [#arena_p2e_rank_tab{count = Count}] when Count =/= 0 ->
            pass;
        _ ->
            init_arena_robot()
    end,
    FinishTime = start_p2e_rank_prize_timer(),   %% 人机排行奖励计时器
    erlang:send_after(?ARENA_MATCH_TIME_INTEVAL * 1000, ?MODULE, {'ARENA_MATCH'}),
    erlang:send_after(?CHECK_TIME_INTEVAL * 1000, ?MODULE, {'CHECK_IS_RESET'}),
	{ok, #arena_state{p2e_rank_prize_finish_time = FinishTime}}.

handle_call({'GET_P2E_PRIZE_FINISH_TIME'}, _From, #arena_state{p2e_rank_prize_finish_time = Time} = State) ->
    {reply, Time, State};
handle_call({'PLAYER_MATCH_P2P_CANCEL', PlayerId}, _From, #arena_state{p2p_match_list = P2PMatchList} = State) ->
    {Ret, NewP2PMatchList} = case lists:keyfind(PlayerId, 1, P2PMatchList) of
        {PlayerId, _, _, _, _, _, _, _} ->
            {ok, lists:keydelete(PlayerId, 1, P2PMatchList)};
        _ ->
            {error, P2PMatchList}
    end,
    ?DEBUG_LOG("Ret:~p", [Ret]),
    {reply, Ret, State#arena_state{p2p_match_list = NewP2PMatchList}};
handle_call({'P2P_CHALLENGE_PLAYER', MyInfo, EnemyId}, _From, #arena_state{p2p_match_list = P2PMatchList} = State) ->
    {Ret, NewState} = case lists:keyfind(EnemyId, 1, P2PMatchList) of
        {PlayerId, Name, Job, Lev, Power, EquipList, EffList, Time} ->
            {PlayerId1, Name1, Job1, Lev1, Power1, EquipList1, EffList1, Time1} = MyInfo,
            world:send_to_player_if_online(PlayerId, ?to_client_msg(arena_sproto:pkg_msg(?MSG_ARENA_PUSH_PLAYER_INFO, {[{1, PlayerId, Name, Job, Lev, Power, EquipList, EffList}, {2, PlayerId1, Name1, Job1, Lev1, Power1, EquipList1, EffList1}]}))),
            world:send_to_player_if_online(PlayerId1, ?to_client_msg(arena_sproto:pkg_msg(?MSG_ARENA_PUSH_PLAYER_INFO, {[{1, PlayerId1, Name1, Job1, Lev1, Power1, EquipList1, EffList1}, {2, PlayerId, Name, Job, Lev, Power, EquipList, EffList}]}))),
            erlang:send_after(2000, ?MODULE, {'CREATE_ARENA', ?ARENA_TYPE_P2P, [{PlayerId, Lev, Power, Time}, {PlayerId1, Lev1, Power1, Time1}]}),
            NewList = lists:keydelete(EnemyId, 1, P2PMatchList),
            {ok, State#arena_state{p2p_match_list = NewList}};
        _ ->
            {error, State}
    end,
    {reply, Ret, NewState};
handle_call({'CREATE_ARENA', ArenaType, Args}, _From, State) ->
    Ret = create_arena_scene(ArenaType, Args),
    {reply, Ret, State};
handle_call(_Request, _From, State) ->
    ?ERROR_LOG("receive unknown call msg:~p", [_Request]),
    {reply, ok, State}.

handle_cast({'PLAYER_MATCH_P2P', PlayerId, Name, Job, Lev, Power, EquipList, EffList, NowTime}, #arena_state{p2p_match_list = P2PMatchList} = State) ->
    NewP2PMatchList = case lists:keyfind(PlayerId, 1, P2PMatchList) of
        {PlayerId, _, _, _, _, _, _, _} ->
            lists:keyreplace(PlayerId, 1, P2PMatchList, {PlayerId, Name, Job, Lev, Power, EquipList, EffList, NowTime});
        _ ->
            [{PlayerId, Name, Job, Lev, Power, EquipList, EffList, NowTime} | P2PMatchList]
    end,
    {noreply, State#arena_state{p2p_match_list = NewP2PMatchList}};
handle_cast({'START_COMPETE', PlayerInfo}, State) ->
    case create_arena_scene(?ARENA_TYPE_COMPETE, PlayerInfo) of
        {ok, SceneId, _ScenePid} ->
            [PlayerId1, PlayerId2] = PlayerInfo,
            {_, XY1, XY2} = misc_cfg:get_arena_single_p2p_scene(),
            lists:foreach(
                fun({TempPlayerId, XY, Dir, Party}) ->
                        world:send_to_player_if_online(TempPlayerId, ?mod_msg(arena_mng, {compete_start, SceneId, XY, Dir, Party})),
                        world:send_to_player_if_online(TempPlayerId, ?to_client_msg(main_instance_sproto:pkg_msg(?MSG_MAIN_INSTANCE_NOTIFY_TEAM_MASTER, {PlayerId1})))
                end,
                [{PlayerId1, XY1, ?D_R, 1}, {PlayerId2, XY2, ?D_L, 2}]
            );
        _Err ->
            ?ERROR_LOG("Created compete scene fail:~p", [_Err])
    end,
    {noreply, State};
handle_cast({'PLAYER_KILL_OTHERS', KillerId, DeadId, DeadIdx, ArenaInfo, ScenePid}, #arena_state{multi_p2p_info_list = MultiP2PList} = State) ->
    NewState = case ArenaInfo of
        {p2e, PlayerInfo} ->
            world:send_to_player(KillerId, ?mod_msg(arena_mng, {finish_arena, PlayerInfo, ?ARENA_TYPE_P2E, ?TRUE, 1, 0})),
            State;
        {p2p, PlayerInfo} ->
            world:send_to_player(KillerId, ?mod_msg(arena_mng, {finish_arena, PlayerInfo, ?ARENA_TYPE_P2P, ?TRUE, 1, 0})),
            world:send_to_player(DeadId, ?mod_msg(arena_mng, {finish_arena, PlayerInfo, ?ARENA_TYPE_P2P, ?FALSE, 0, 1})),
            State;
        {multi_p2p, PlayerInfo} ->
            % do_log(KillerId, DeadId),
            erlang:send_after(3000, ?MODULE, {'AGENT_RELIVE', ScenePid, DeadIdx}),  %% relive after 3 seconds
            NewList = case {lists:keyfind(KillerId, 1, PlayerInfo), lists:keyfind(DeadId, 1, PlayerInfo)} of
                {{KillerId, KillerTeam, _}, {DeadId, DeadTeam, _}} ->
                    case lists:keyfind(ScenePid, #multi_p2p_info.scene_pid, MultiP2PList) of
                        MultiP2PInfo when is_record(MultiP2PInfo, multi_p2p_info) ->
                            AreanTeamList = MultiP2PInfo#multi_p2p_info.arena_team_list,
                            NewAreanTeamList = case {lists:keyfind(KillerTeam, #multi_arena_team.team_id, AreanTeamList), lists:keyfind(DeadTeam, #multi_arena_team.team_id, AreanTeamList)} of
                                {KillTeamInfo = #multi_arena_team{}, DeadTeamInfo = #multi_arena_team{}} ->
                                    OldAllKillTimes = KillTeamInfo#multi_arena_team.all_kill_times,
                                    KillMems = KillTeamInfo#multi_arena_team.multi_arena_members,
                                    OldAllDeadTImes = DeadTeamInfo#multi_arena_team.all_die_times,
                                    DeadMems = DeadTeamInfo#multi_arena_team.multi_arena_members,
                                    {NewKillMems, NewDeadMems} = case {lists:keyfind(KillerId, #arena_member.player_id, KillMems), lists:keyfind(DeadId, #arena_member.player_id, DeadMems)} of
                                        {Killer = #arena_member{}, Dead = #arena_member{}} ->
                                            OldKillTimes = Killer#arena_member.kill_times,
                                            NewKill = Killer#arena_member{kill_times = OldKillTimes + 1},
                                            OldDieTimes = Dead#arena_member.die_times,
                                            NewDead = Dead#arena_member{die_times = OldDieTimes + 1},
                                            {lists:keyreplace(KillerId, #arena_member.player_id, KillMems, NewKill), lists:keyreplace(DeadId, #arena_member.player_id, DeadMems, NewDead)};
                                        _ ->
                                            ?ERROR_LOG("can not find player info :~p", [{KillerId, KillerTeam, DeadId, DeadTeam, PlayerInfo, MultiP2PList}]),
                                            {KillMems, DeadMems}
                                    end,
                                    NewKillTeamInfo = KillTeamInfo#multi_arena_team{all_kill_times = OldAllKillTimes + 1, multi_arena_members = NewKillMems},
                                    NewDeadTeamInfo = DeadTeamInfo#multi_arena_team{all_die_times = OldAllDeadTImes + 1, multi_arena_members = NewDeadMems},
                                    [NewKillTeamInfo, NewDeadTeamInfo];
                                _ ->
                                    ?ERROR_LOG("can not find player team info :~p", [{KillerId, KillerTeam, DeadId, DeadTeam, PlayerInfo, MultiP2PList}]),
                                    AreanTeamList
                            end,
                            lists:keyreplace(ScenePid, #multi_p2p_info.scene_pid, MultiP2PList, MultiP2PInfo#multi_p2p_info{arena_team_list = NewAreanTeamList});
                        _ ->
                            ?ERROR_LOG("can not find arena scene info:~p", [{ScenePid, MultiP2PList}]),
                            MultiP2PList
                    end;
                _ ->
                    ?ERROR_LOG("can not find player info :~p", [KillerId, DeadId, PlayerInfo]),
                    MultiP2PList
            end,
            State#arena_state{multi_p2p_info_list = NewList};
        {compete, _PlayerInfo} ->
            world:send_to_player(KillerId, ?mod_msg(arena_mng, {finish_compete, ?TRUE})),
            world:send_to_player(DeadId, ?mod_msg(arena_mng, {finish_compete, ?FALSE})),
            State;
        _ ->
            State
    end,
    {noreply, NewState};
handle_cast({'PLAYER_DIE', PlayerId, ArenaInfo}, State) ->
    case ArenaInfo of
        {p2e, PlayerInfo} ->    %% 只匹配人机的，玩家死亡在玩家击杀时一起统计了
            world:send_to_player(PlayerId, ?mod_msg(arena_mng, {finish_arena, PlayerInfo, ?ARENA_TYPE_P2E, ?FALSE, 0, 1}));
        _ ->
            pass
    end,
    {noreply, State};
handle_cast({'PLAYER_LEAVE', PlayerId, {ScenePid, ArenaInfo}}, #arena_state{multi_p2p_info_list = MultiP2PList} = State) ->
    NewState = case ArenaInfo of
        {p2e, PlayerInfo} ->
            world:send_to_player(PlayerId, ?mod_msg(arena_mng, {finish_arena, PlayerInfo, ?ARENA_TYPE_P2E, ?FALSE, 0, 0})),
            State;
        {p2p, PlayerInfo} ->
            [{PlayerId1, _, _, _}, {PlayerId2, _, _, _}] = PlayerInfo,
            OpponentId = case PlayerId of
                PlayerId1 -> PlayerId2;
                _ -> PlayerId1
            end,
            world:send_to_player(OpponentId, ?mod_msg(arena_mng, {finish_arena, PlayerInfo, ?ARENA_TYPE_P2P, ?TRUE, 0, 0})),
            world:send_to_player(PlayerId, ?mod_msg(arena_mng, {finish_arena, PlayerInfo, ?ARENA_TYPE_P2P, ?FALSE, 0, 0})),
            State;
        {multi_p2p, PlayerInfo} ->
            member_leave_team(PlayerId, ?TEAM_TYPE_MULTI_ARENA),
            {PlayerId, LeaveTeamId, _} = lists:keyfind(PlayerId, 1, PlayerInfo),
            NewList = case lists:keyfind(ScenePid, #multi_p2p_info.scene_pid, MultiP2PList) of
                MultiP2PInfo when is_record(MultiP2PInfo, multi_p2p_info) ->
                    TeamList = MultiP2PInfo#multi_p2p_info.arena_team_list,
                    [#multi_arena_team{team_id = TeamId1, leave_counts = LeaveCounts1, multi_arena_members = Mems1} = Team1, #multi_arena_team{team_id = TeamId2, leave_counts = LeaveCounts2, multi_arena_members = Mems2} = Team2] = TeamList,
                    case LeaveTeamId of
                        TeamId1 ->
                            NewLeaveCounts1 = LeaveCounts1 + 1,
                            case NewLeaveCounts1 >= ?TEAM_MULTI_ARENA_MAX_MEMBERS of
                                true ->
                                    multi_p2p_result(TeamId2, TeamId1, Mems2, Mems1, PlayerInfo),
                                    lists:keydelete(ScenePid, #multi_p2p_info.scene_pid, MultiP2PList);
                                _ ->
                                    NewTeamList = [Team1#multi_arena_team{leave_counts = NewLeaveCounts1}, Team2],
                                    lists:keyreplace(ScenePid, #multi_p2p_info.scene_pid, MultiP2PList, MultiP2PInfo#multi_p2p_info{arena_team_list = NewTeamList})
                            end;
                        _ ->
                            NewLeaveCounts2 = LeaveCounts2 + 1,
                            case NewLeaveCounts2 >= ?TEAM_MULTI_ARENA_MAX_MEMBERS of
                                true ->
                                    multi_p2p_result(TeamId1, TeamId2, Mems1, Mems2, PlayerInfo),
                                    lists:keydelete(ScenePid, #multi_p2p_info.scene_pid, MultiP2PList);
                                _ ->
                                    NewTeamList = [Team1, Team2#multi_arena_team{leave_counts = NewLeaveCounts2}],
                                    lists:keyreplace(ScenePid, #multi_p2p_info.scene_pid, MultiP2PList, MultiP2PInfo#multi_p2p_info{arena_team_list = NewTeamList})
                            end
                    end;
                _ ->
                    MultiP2PList
            end,
            State#arena_state{multi_p2p_info_list = NewList};
        {compete, PlayerInfo} ->
            [PlayerId1, PlayerId2] = PlayerInfo,
            OpponentId = case PlayerId of
                PlayerId1 -> PlayerId2;
                _ -> PlayerId1
            end,
            world:send_to_player(OpponentId, ?mod_msg(arena_mng, {finish_compete, ?TRUE})),
            world:send_to_player(PlayerId, ?mod_msg(arena_mng, {finish_compete, ?FALSE})),
            State;
        _ ->
            State
    end,
    {noreply, NewState};
handle_cast({'ARENA_TIME_OUT', ArenaInfo}, #arena_state{multi_p2p_info_list = MultiP2PList} = State) ->
    NewState = case ArenaInfo of
        {p2e, PlayerInfo} ->
            [PlayerId | _] = PlayerInfo,     %% 人机模式第一个是玩家
            world:send_to_player(PlayerId, ?mod_msg(arena_mng, {finish_arena, PlayerInfo, ?ARENA_TYPE_P2E, ?FALSE, 0, 0})),
            State;
        {p2p, PlayerInfo} ->
            [{PlayerId1, _, Pow1, _}, {PlayerId2, _, Pow2, _}] = PlayerInfo,
            case Pow1 >= Pow2 of
                true ->
                    world:send_to_player(PlayerId1, ?mod_msg(arena_mng, {finish_arena, PlayerInfo, ?ARENA_TYPE_P2P, ?TRUE, 0, 0})),
                    world:send_to_player(PlayerId2, ?mod_msg(arena_mng, {finish_arena, PlayerInfo, ?ARENA_TYPE_P2P, ?FALSE, 0, 0}));
                _ ->
                    world:send_to_player(PlayerId1, ?mod_msg(arena_mng, {finish_arena, PlayerInfo, ?ARENA_TYPE_P2P, ?FALSE, 0, 0})),
                    world:send_to_player(PlayerId2, ?mod_msg(arena_mng, {finish_arena, PlayerInfo, ?ARENA_TYPE_P2P, ?TRUE, 0, 0}))
            end,
            State;
        {multi_p2p, {ScenePid, PlayerInfo}} ->
            NewList = case lists:keyfind(ScenePid, #multi_p2p_info.scene_pid, MultiP2PList) of
                MultiP2PInfo when is_record(MultiP2PInfo, multi_p2p_info) ->
                    TeamList = MultiP2PInfo#multi_p2p_info.arena_team_list,
                    [#multi_arena_team{team_id = TeamId1, all_kill_times = AllKillTimes1, multi_arena_members = Mems1}, #multi_arena_team{team_id = TeamId2, all_kill_times = AllKillTimes2, multi_arena_members = Mems2}] = TeamList,
                    if
                        AllKillTimes1 > AllKillTimes2 ->
                            multi_p2p_result(TeamId1, TeamId2, Mems1, Mems2, PlayerInfo);
                        AllKillTimes1 < AllKillTimes2 ->
                            multi_p2p_result(TeamId2, TeamId1, Mems2, Mems1, PlayerInfo);
                        true ->    %% 总血量高的队伍获胜
                            [{Team1, Pow1}, {Team2, Pow2}] = lists:foldl(
                                fun({_, TeamId, Mem}, TempList) ->
                                        case lists:keyfind(TeamId, 1, TempList) of
                                            {TeamId, Pow} ->
                                                lists:keyreplace(TeamId, 1, TempList, {TeamId, Pow + Mem#member_info.combar_power});
                                            _ ->
                                                [{TeamId, Mem#member_info.combar_power} | TempList]
                                        end
                                end,
                                [],
                                PlayerInfo
                            ),
                            WinTeam = case Pow1 >= Pow2 of
                                true -> Team1;
                                _ -> Team2
                            end,
                            case WinTeam of
                                TeamId1 -> multi_p2p_result(TeamId1, TeamId2, Mems1, Mems2, PlayerInfo);
                                _ -> multi_p2p_result(TeamId2, TeamId1, Mems2, Mems1, PlayerInfo)
                            end
                    end,
                    lists:keydelete(ScenePid, #multi_p2p_info.scene_pid, MultiP2PList);
                _ ->
                    ?ERROR_LOG("can not find scene info :~p", [{ScenePid, MultiP2PList}]),
                    MultiP2PList
            end,
            State#arena_state{multi_p2p_info_list = NewList};
        {compete, PlayerInfo} ->
            [PlayerId1, PlayerId2] = PlayerInfo,
            [Pow1] = player:lookup_info(PlayerId1, [?pd_combat_power]),
            [Pow2] = player:lookup_info(PlayerId2, [?pd_combat_power]),
            case Pow1 >= Pow2 of
                true ->
                    world:send_to_player(PlayerId1, ?mod_msg(arena_mng, {finish_compete, ?TRUE})),
                    world:send_to_player(PlayerId2, ?mod_msg(arena_mng, {finish_compete, ?FALSE}));
                _ ->
                    world:send_to_player(PlayerId1, ?mod_msg(arena_mng, {finish_compete, ?FALSE})),
                    world:send_to_player(PlayerId2, ?mod_msg(arena_mng, {finish_compete, ?TRUE}))
            end,
            State;
        _ ->
            State
    end,
    {noreply, NewState};
handle_cast(_Msg, State) ->
    ?ERROR_LOG("receive unknown cast msg:~p", [_Msg]),
    {noreply, State}.

handle_info({'ARENA_MATCH'}, #arena_state{p2p_match_list = P2PMatchList} = State) ->
    %% 1v1 match
    RetList = lists:foldl(
        fun({PlayerId, Name, Job, Lev, Power, EquipList, EffList, Time}, Acc) ->
                case Acc of
                    [] ->
                        [{PlayerId, Name, Job, Lev, Power, EquipList, EffList, Time}];
                    PlayerInfo ->
                        [{PlayerId1, Name1, Job1, Lev1, Power1, EquipList1, EffList1, Time1}] = PlayerInfo,
                        world:send_to_player_if_online(PlayerId, ?to_client_msg(arena_sproto:pkg_msg(?MSG_ARENA_PUSH_PLAYER_INFO, {[{1, PlayerId, Name, Job, Lev, Power, EquipList, EffList}, {2, PlayerId1, Name1, Job1, Lev1, Power1, EquipList1, EffList1}]}))),
                        world:send_to_player_if_online(PlayerId1, ?to_client_msg(arena_sproto:pkg_msg(?MSG_ARENA_PUSH_PLAYER_INFO, {[{1, PlayerId1, Name1, Job1, Lev1, Power1, EquipList1, EffList1}, {2, PlayerId, Name, Job, Lev, Power, EquipList, EffList}]}))),
                        erlang:send_after(2000, ?MODULE, {'CREATE_ARENA', ?ARENA_TYPE_P2P, [{PlayerId, Lev, Power, Time}, {PlayerId1, Lev1, Power1, Time1}]}),
                        []
                end
        end,
        [],
        lists:keysort(5, P2PMatchList)
    ),
    erlang:send_after(?ARENA_MATCH_TIME_INTEVAL * 1000, ?MODULE, {'ARENA_MATCH'}),
    {noreply, State#arena_state{p2p_match_list = RetList}};
handle_info({'CREATE_ARENA', ?ARENA_TYPE_P2P, [{PlayerId, Lev, Power, Time}, {PlayerId1, Lev1, Power1, Time1}]}, State) ->
    case create_arena_scene(?ARENA_TYPE_P2P, [{PlayerId, Lev, Power, Time}, {PlayerId1, Lev1, Power1, Time1}]) of
        {ok, SceneId, _ScenePid} ->
            {_, XY1, XY2} = misc_cfg:get_arena_single_p2p_scene(),
            lists:foreach(
                fun({TempPlayerId, XY, Dir, Party}) ->
                        world:send_to_player_if_online(TempPlayerId, ?mod_msg(arena_mng, {p2p_start, SceneId, XY, Dir, Party})),
                        world:send_to_player_if_online(TempPlayerId, ?to_client_msg(main_instance_sproto:pkg_msg(?MSG_MAIN_INSTANCE_NOTIFY_TEAM_MASTER, {PlayerId})))
                end,
                [{PlayerId, XY1, ?D_R, 1}, {PlayerId1, XY2, ?D_L, 2}]
            );
        _Err ->
            ?ERROR_LOG("Created p2p arena scene fail:~p", [_Err])
    end,
    {noreply, State};
handle_info({'START_M_P2P', Team1, Team2}, #arena_state{multi_p2p_info_list = OldList} = State) ->
    %% 3v3 match
    #team_info{id = TeamId1, master_id = MasterId, members = Members1} = Team1,
    #team_info{id = TeamId2, members = Members2} = Team2,
    PlayerTeamList1 = [{Mem1#member_info.player_id, TeamId1, Mem1} || Mem1 <- Members1],
    PlayerTeamList2 = [{Mem2#member_info.player_id, TeamId2, Mem2} || Mem2 <- Members2],
    NewMultiP2PList = case create_arena_scene(?ARENA_TYPE_MULTI_P2P, PlayerTeamList1 ++ PlayerTeamList2) of
        {ok, SceneId, ScenePid} ->
            {_, XYR1, XYR2} = misc_cfg:get_arena_multi_p2p_scene(),
            XYList1 = get_xy_list(XYR1),
            XYList2 = get_xy_list(XYR2),
            {NewMemList1, _} = lists:foldl(
                fun(#member_info{player_id = PlayerId1}, {MemList, Index1}) ->
                        Party1 = 1,
                        world:send_to_player_if_online(PlayerId1, ?mod_msg(arena_mng, {p2p_multi_start, SceneId, lists:nth(Index1, XYList1), ?D_R, Party1})),
                        world:send_to_player_if_online(PlayerId1, ?to_client_msg(main_instance_sproto:pkg_msg(?MSG_MAIN_INSTANCE_NOTIFY_TEAM_MASTER, {MasterId}))),
                        NewMem = #arena_member{player_id = PlayerId1},
                        {[NewMem | MemList], Index1 + 1}
                end,
                {[], 1},
                Members1
            ),
            ArenaTeam1 = #multi_arena_team{team_id = TeamId1, multi_arena_members = NewMemList1},
            {NewMemList2, _} = lists:foldl(
                fun(#member_info{player_id = PlayerId2}, {TempMemList, Index2}) ->
                        Party2 = 2,
                        world:send_to_player_if_online(PlayerId2, ?mod_msg(arena_mng, {p2p_multi_start, SceneId, lists:nth(Index2, XYList2), ?D_L, Party2})),
                        world:send_to_player_if_online(PlayerId2, ?to_client_msg(main_instance_sproto:pkg_msg(?MSG_MAIN_INSTANCE_NOTIFY_TEAM_MASTER, {MasterId}))),
                        NewTempMem = #arena_member{player_id = PlayerId2},
                        {[NewTempMem | TempMemList], Index2 + 1}
                end,
                {[], 1},
                Members2
            ),
            ArenaTeam2 = #multi_arena_team{team_id = TeamId2, multi_arena_members = NewMemList2},
            team_server:team_start(TeamId1, ?TEAM_TYPE_MULTI_ARENA),
            team_server:team_start(TeamId2, ?TEAM_TYPE_MULTI_ARENA),
            [#multi_p2p_info{scene_pid = ScenePid, arena_team_list = [ArenaTeam1, ArenaTeam2]}];
        _Err ->
            ?ERROR_LOG("Created multi p2p arena scene fail:~p", [_Err]),
            []
    end,
    {noreply, State#arena_state{multi_p2p_info_list = OldList ++ NewMultiP2PList}};
handle_info({'P2E_RANK_PRIZE'}, State) ->
    p2e_rank_prize_info_reset(),
    TodayPassSeconds = util:get_today_passed_seconds(),
    NewInteval = case TodayPassSeconds =< 3600 of
        true -> ?P2E_RANK_PRIZE_INTEVAL - TodayPassSeconds;
        _ -> ?P2E_RANK_PRIZE_INTEVAL + ?P2E_RANK_PRIZE_INTEVAL - TodayPassSeconds
    end,
    erlang:send_after(NewInteval * 1000, ?MODULE, {'P2E_RANK_PRIZE'}),
    {noreply, State#arena_state{p2e_rank_prize_finish_time = com_time:now() + NewInteval}};
handle_info({'CHECK_IS_RESET'}, State) ->
    {{Year, Month, Day}, {H, M, S}} = calendar:local_time(),
    case calendar:day_of_the_week(Year, Month, Day) =:= 1 andalso H =:= 0 andalso M =:= 0 andalso S < ?CHECK_TIME_INTEVAL of
        true -> %% 周重置
            week_reset();
        _ ->
            pass
    end,
    case Day =:= 1 andalso H =:= 0 andalso M =:= 0 andalso S < ?CHECK_TIME_INTEVAL of
        true -> %% 月重置
            month_reset();
        _ ->
            pass
    end,
    erlang:send_after(?CHECK_TIME_INTEVAL * 1000, ?MODULE, {'CHECK_IS_RESET'}),
    {noreply, State};
handle_info({'AGENT_RELIVE', ScenePid, DeadIdx}, State) ->
    ScenePid ! ?scene_mod_msg(scene_player, {arena_relive, DeadIdx}),
    {noreply, State};
handle_info(_Info, State) ->
    ?ERROR_LOG("receive unknown info msg:~p", [_Info]),
    {noreply, State}.

terminate(_Reason, _State) ->
    ?INFO_LOG("process shutdown with reason = ~p", [_Reason]),
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% ===================================================================
%% private
%% ===================================================================
load_db_table_meta() ->
    [
        #db_table_meta{
            name = ?arena_robot_tab,
            fields = ?record_fields(?arena_robot_tab),
            record_name = ?arena_robot_tab,
            shrink_size = 10,
            load_all = false,
            flush_interval = 4
        },
        #db_table_meta{
            name = ?arena_p2e_rank_tab,
            fields = ?record_fields(?arena_p2e_rank_tab),
            record_name = ?arena_p2e_rank_tab,
            shrink_size = 10,
            load_all = true,
            flush_interval = 4
        }
    ].

init_arena_robot() ->
    RobotCfgIdList = load_cfg_arena_robot:lookup_all_arena_robot_cfg(#arena_robot_cfg.id),
    #{platform_id := _PlatformId, id := ServerId} = global_data:get_server_info(),
    lists:foreach(
        fun(CfgId) ->
                #arena_robot_cfg{rank = Rank, lev = Lev, attr_list = [AttrIdMin, AttrIdMax], skills = Skills} = load_cfg_arena_robot:lookup_arena_robot_cfg(CfgId),
                AttrMin = case load_spirit_attr:lookup_attr(AttrIdMin) of
                    A = #attr{} -> A;
                    _ -> #attr{}
                end,
                AttrMax = case load_spirit_attr:lookup_attr(AttrIdMax) of
                    B = #attr{} -> B;
                    _ -> #attr{}
                end,
                create_robot(Rank, Lev, [AttrMin, AttrMax], Skills, ServerId)
        end,
        RobotCfgIdList
    ).

create_robot([RankMin, RankMax], _, _, _, _) when RankMin > RankMax -> ok;
create_robot([RankMin, RankMax], [LevMin, LevMax], [AttrMin, AttrMax], {_, _, _, _, Num} = Skills, ServerId) ->
    RobotId = tool:make_player_id(?ARENA_ROBOT_PLATFORM_ID, ServerId, RankMin),
    Name = get_robot_name(RobotId),
    Career = case random:uniform(3) of
        3 -> 4;
        Index -> Index
    end,
    Lev = com_util:random(LevMin, LevMax),
    Attr = get_random_attr(AttrMin, AttrMax),
    SkillList = element(Career, Skills),
    RobotSkillList = util:get_val_by_weight([{SkillId, 1} || SkillId <- SkillList], Num),
    dbcache:insert_new(?arena_robot_tab, #arena_robot_tab{id = RobotId, name = Name, career = Career, lev = Lev, attr = Attr, skills = RobotSkillList}),
    case dbcache:lookup(?arena_p2e_rank_tab, 0) of
        [#arena_p2e_rank_tab{count = Count, rank_list = RankList} = Tab] ->
            dbcache:update(arena_p2e_rank_tab, Tab#arena_p2e_rank_tab{count = Count + 1, rank_list = [{Count + 1, RobotId} | RankList]});
        _ ->
            dbcache:insert_new(?arena_p2e_rank_tab, #arena_p2e_rank_tab{id = 0, count = 1, rank_list = [{RankMin, RobotId}]})
    end,
    create_robot([RankMin + 1, RankMax], [LevMin, LevMax], [AttrMin, AttrMax], Skills, ServerId).

get_robot_name(RobotId) ->
    Name = load_robot_cfg:get_random_robot_name(),
    case platfrom:register_name(Name, RobotId) of
        ok -> Name;
        _ -> get_robot_name(RobotId)
    end.

get_random_attr(AttrMin, AttrMax) ->
    ListMin = tuple_to_list(?r2t(AttrMin)),
    ListMax = tuple_to_list(?r2t(AttrMax)),
    NewList = lists:zipwith(
        fun(X, Y) ->
                {NewX, NewY} = case X =< Y of
                    true -> {X, Y};
                    _ -> {Y, X}
                end,
                com_util:random(NewX, NewY)
        end,
        ListMin,
        ListMax
    ),
    Attr = #attr{
        id = lists:nth(1, NewList),
        hp = lists:nth(2, NewList),
        mp = lists:nth(3, NewList),
        sp = lists:nth(4, NewList),
        np = lists:nth(5, NewList),
        strength = lists:nth(6, NewList),
        intellect = lists:nth(7, NewList),
        nimble = lists:nth(8, NewList),
        strong = lists:nth(9, NewList),
        atk = lists:nth(10, NewList),
        def = lists:nth(11, NewList),
        crit = lists:nth(12, NewList),
        block = lists:nth(13, NewList),
        pliable = lists:nth(14, NewList),
        pure_atk = lists:nth(15, NewList),
        break_def = lists:nth(16, NewList),
        atk_deep = lists:nth(17, NewList),
        atk_free = lists:nth(18, NewList),
        atk_speed = lists:nth(19, NewList),
        precise = lists:nth(20, NewList),
        thunder_atk = lists:nth(21, NewList),
        thunder_def = lists:nth(22, NewList),
        fire_atk = lists:nth(23, NewList),
        fire_def = lists:nth(24, NewList),
        ice_atk = lists:nth(25, NewList),
        ice_def = lists:nth(26, NewList),
        move_speed = lists:nth(27, NewList),
        run_speed = lists:nth(28, NewList),
        suck_blood = lists:nth(29, NewList),
        reverse = lists:nth(30, NewList),
        bati = lists:nth(31, NewList)
    },
    attr_new:get_all_attr_by_lv1_attr(Attr).

get_player_id_by_rank(Rank) ->
    case dbcache:lookup(?arena_p2e_rank_tab, 0) of
        [#arena_p2e_rank_tab{rank_list = RankList}] ->
            case lists:keyfind(Rank, 1, RankList) of
                {Rank, PlayerId} -> PlayerId;
                _ -> 0
            end;
        _ ->
            0
    end.

get_rank_by_player_id(PlayerId) ->
    case dbcache:lookup(?arena_p2e_rank_tab, 0) of
        [#arena_p2e_rank_tab{rank_list = RankList}] ->
            case lists:keyfind(PlayerId, 2, RankList) of
                {Rank, PlayerId} -> Rank;
                _ -> 0
            end;
        _ ->
            0
    end.

start_p2e_rank_prize_timer() ->
    case load_db_misc:get(?misc_arena_pre_over_tm, 0) of
        0 ->
            TodayPassSeconds = util:get_today_passed_seconds(),
            erlang:send_after((?FIRST_P2E_RANK_PRIZE_INTEVAL - TodayPassSeconds) * 1000, ?MODULE, {'P2E_RANK_PRIZE'}),
            com_time:now() + ?FIRST_P2E_RANK_PRIZE_INTEVAL - TodayPassSeconds;
        _LastTime ->
            TodayPassSeconds = util:get_today_passed_seconds(),
            erlang:send_after((?P2E_RANK_PRIZE_INTEVAL - TodayPassSeconds) * 1000, ?MODULE, {'P2E_RANK_PRIZE'}),
            com_time:now() + ?P2E_RANK_PRIZE_INTEVAL - TodayPassSeconds
    end.

p2e_rank_prize_info_reset() ->
    [#arena_p2e_rank_tab{rank_list = RankList}] = dbcache:lookup(?arena_p2e_rank_tab, 0),
    load_db_misc:set(?misc_arena_pre_rank_data, RankList),
    load_db_misc:set(?misc_arena_pre_over_tm, com_time:now()),
    spawn(fun() -> send_arena_phase_ranking_prize() end).

send_arena_phase_ranking_prize() ->
    lists:foreach(
        fun
            (#arena_info{id = PlayerId, arena_lev = Lev}) ->
                case load_arena_cfg:lookup_arena_cfg(Lev) of
                    #arena_cfg{daily_award = AwardList} ->
                        case AwardList of
                            [] -> pass;
                            _ -> world:send_to_player_any_state(PlayerId, ?mod_msg(mail_mng, {arena_phase_ranking_prize, PlayerId, ?S_MAIL_ARENA_DAY, AwardList}))
                        end;
                    _ -> pass
                end;
            (_) ->
                pass
        end,
        ets:tab2list(?player_arena_tab)
    ).

get_rank_page(Star, Len)->
    [#arena_p2e_rank_tab{rank_list = RankList}] = dbcache:lookup(?arena_p2e_rank_tab, 0),
    case RankList of
        [] ->
            [];
        R ->
            List1 = lists:keysort(1, R),
            lists:sublist(List1, Star, Len)
    end.

create_arena_scene(ArenaType, Args) ->
    case ArenaType of
        ?ARENA_TYPE_P2E ->
            {SceneCfgId, _XY1, _MonId, _XY2} = misc_cfg:get_arena_single_p2e_scene(),
            SceneId = scene:make_scene_id(?SC_TYPE_ARENA, p2e, SceneCfgId, Args),
            case scene_sup:start_scene(SceneId, {p2e, Args}) of
                ScenePid when is_pid(ScenePid) ->
                    {ok, SceneId, ScenePid};
                Err ->
                    {error, Err}
            end;
        ?ARENA_TYPE_P2P ->
            {SceneCfgId, _XY1, _XY2} = misc_cfg:get_arena_single_p2p_scene(),
            SceneId = scene:make_scene_id(?SC_TYPE_ARENA, p2p, SceneCfgId, Args),
            case scene_sup:start_scene(SceneId, {p2p, Args}) of
                ScenePid when is_pid(ScenePid) ->
                    {ok, SceneId, ScenePid};
                Err ->
                    {error, Err}
            end;
        ?ARENA_TYPE_MULTI_P2P ->
            {SceneCfgId, _XY1, _XY2} = misc_cfg:get_arena_multi_p2p_scene(),
            SceneId = scene:make_scene_id(?SC_TYPE_ARENA, multi_p2p, SceneCfgId, Args),
            case scene_sup:start_scene(SceneId, {multi_p2p, Args}) of
                ScenePid when is_pid(ScenePid) ->
                    {ok, SceneId, ScenePid};
                Err ->
                    {error, Err}
            end;
        ?ARENA_TYPE_COMPETE ->
            {SceneCfgId, _XY1, _XY2} = misc_cfg:get_arena_single_p2p_scene(),
            SceneId = scene:make_scene_id(?SC_TYPE_ARENA, compete, SceneCfgId, Args),
            case scene_sup:start_scene(SceneId, {compete, Args}) of
                ScenePid when is_pid(ScenePid) ->
                    {ok, SceneId, ScenePid};
                Err ->
                    {error, Err}
            end;
        _ ->
            ?ERROR_LOG("unknown arena type:~p", [ArenaType])
    end.

get_xy_list({X, Y, R}) ->
    [{X, Y}, {X, Y - R}, {X, Y + R}].

% do_log(KillerId, DeadId) ->
%     [KillerName, KillerCareer, KillerLevel, KillerHonour] = player:lookup_info(KillerId, [?pd_name, ?pd_career, ?pd_level, ?pd_honour]),
%     KillerRank = case dbcache:lookup(?player_arena_tab, KillerId) of
%         [#arena_info{arena_lev = Lev}] ->
%             Lev;
%         _E ->
%             0
%     end,
%     world:send_to_player_if_online(DeadId, ?mod_msg(arena_mng, {info_player_arena_die_log, {KillerId, KillerName, KillerCareer, KillerLevel, KillerHonour, KillerRank}})).

multi_p2p_result(_WinTeamId, _LossTeamId, WinMems, LossMems, PlayerInfo) ->
    #{platform_id := _PlatformId, id := ServerId} = global_data:get_server_info(),
    WinMemsInfo = lists:foldl(
        fun(#arena_member{player_id = PlayerId, kill_times = KillTimes, die_times = DieTimes}, {AllNKill, RetList}) ->
                world:send_to_player(PlayerId, ?mod_msg(arena_mng, {finish_arena, PlayerInfo, ?ARENA_TYPE_MULTI_P2P, ?TRUE, KillTimes, DieTimes})),
                [#arena_info{arena_lev = ArenaLev}] = dbcache:lookup(?player_arena_tab, PlayerId),
                #arena_cfg{
                    kill_ratio = KillPer,
                    multi_p2p_win = {MPWinC, _}
                } = load_arena_cfg:lookup_arena_cfg(ArenaLev),
                NKill = max(0, (KillTimes - DieTimes) * KillPer),
                {PlayerId, _, Mem} = lists:keyfind(PlayerId, 1, PlayerInfo),
                {AllNKill + NKill, [{ArenaLev, PlayerId, Mem#member_info.name, Mem#member_info.career, Mem#member_info.level, ServerId, KillTimes, DieTimes, MPWinC} | RetList]}
        end,
        {0, []},
        WinMems
    ),
    LossMemsInfo = lists:foldl(
        fun(#arena_member{player_id = PlayerId, kill_times = KillTimes, die_times = DieTimes}, {AllNKill, RetList}) ->
                world:send_to_player(PlayerId, ?mod_msg(arena_mng, {finish_arena, PlayerInfo, ?ARENA_TYPE_MULTI_P2P, ?FALSE, KillTimes, DieTimes})),
                [#arena_info{arena_lev = ArenaLev}] = dbcache:lookup(?player_arena_tab, PlayerId),
                #arena_cfg{
                    kill_ratio = KillPer,
                    multi_p2p_loss = {MPLossC, _}
                } = load_arena_cfg:lookup_arena_cfg(ArenaLev),
                NKill = max(0, (KillTimes - DieTimes) * KillPer),
                {PlayerId, _, Mem} = lists:keyfind(PlayerId, 1, PlayerInfo),
                {AllNKill + NKill, [{ArenaLev, PlayerId, Mem#member_info.name, Mem#member_info.career, Mem#member_info.level, ServerId, KillTimes, DieTimes, MPLossC} | RetList]}
        end,
        {0, []},
        LossMems
    ),
    [
        begin
            Pkg = arena_sproto:pkg_msg(?MSG_ARENA_MULTI_RESULT, {[WinMemsInfo, LossMemsInfo]}),
            world:send_to_player_if_online(PlayerId, ?to_client_msg(Pkg))
        end || {PlayerId, _, _} <- PlayerInfo
    ].

member_leave_team(PlayerId, Type) ->
    case team_server:is_team_master(PlayerId, Type) of
        true ->
            {ok, TeamId} = team_server:get_team_id(PlayerId, Type),
            Members = team_server:get_team_members(TeamId, Type),
            case team_server:change_team_master_except_this(TeamId, PlayerId, Type) of
                {ok, MasterId} ->
                    Msg = ?to_client_msg(main_instance_sproto:pkg_msg(?MSG_MAIN_INSTANCE_NOTIFY_TEAM_MASTER, {MasterId})),
                    members_notify(Members, Msg);
                _ ->
                    ignore
            end;
        _ ->
            ignore
    end,
    case team_server:leave_team(PlayerId, Type) of
        {ok, NewMembers} ->
            world:send_to_player_if_online(PlayerId, ?to_client_msg(team_sproto:pkg_msg(?MSG_TEAM_QUIT, {PlayerId}))),
            lists:foreach(
                fun(#member_info{player_id = Id}) ->
                        world:send_to_player_if_online(Id, ?to_client_msg(team_sproto:pkg_msg(?MSG_TEAM_QUIT, {PlayerId})))
                end,
                NewMembers
            );
        _ ->
            world:send_to_player_if_online(PlayerId, ?to_client_msg(team_sproto:pkg_msg(?MSG_TEAM_QUIT, {PlayerId})))
    end.

members_notify(Members, Msg) ->
    [world:send_to_player_if_online(M#member_info.player_id, Msg) || M <- Members].

week_reset() -> ok.

month_reset() -> ok.
