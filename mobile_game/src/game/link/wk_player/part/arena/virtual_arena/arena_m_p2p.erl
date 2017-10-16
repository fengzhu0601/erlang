%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 29. 十二月 2015 下午2:12
%%%-------------------------------------------------------------------
-module(arena_m_p2p).
-author("clark").

%% API
-export([
     join_team/3
]).

-include("i_arena.hrl").
-include("arena.hrl").
-include("inc.hrl").
-include("player.hrl").
-include("arena_struct.hrl").
-include("achievement.hrl").
-include("timer_manager.hrl").
-include("load_phase_ac.hrl").
-include("team.hrl").
-include("../../wonderful_activity/bounty_struct.hrl").

start() ->
    case is_can_arena_m_p2p_start() of
        true ->
            MemberInfo = member_info_new(),
            {CenterSvrNode, IsLink} = my_ets:get(center_svr_node_info, {0, false}),
            case IsLink of
                true -> %% 跨服
                    [#arena_info{arena_lev = ArenaLev}] = dbcache:lookup(?player_arena_tab, get(?pd_id)),
                    rpc:cast(CenterSvrNode, arena_multi_p2p, multi_p2p_match, [{MemberInfo, self(), ArenaLev}]);
                _ ->    %% 本地
                    case team_server:quick_join(MemberInfo, 0, ?TEAM_TYPE_MULTI_ARENA) of
                        {ok, {TeamId, Members}} ->
                            %% 通知自己队伍信息
                            ?player_send(team_sproto:pkg_msg(?MSG_TEAM_JOIN, {TeamId, ?TEAM_TYPE_MULTI_ARENA, <<>>, pkg_members(Members ++ [MemberInfo])})),
                            Msg = ?to_client_msg(team_sproto:pkg_msg(?MSG_TEAM_MEMBER_JOIN, {pkg_member(MemberInfo)})),
                            members_notify(Members, Msg),
                            %% 刷新界面两个队伍成员信息
                            case team_server:try_get_matching_team(TeamId, ?TEAM_TYPE_MULTI_ARENA) of
                                {ok, MatchTeamInfo} ->
                                    MatchMembers = MatchTeamInfo#team_info.members,
                                    MsgToMyTeam = ?to_client_msg(arena_sproto:pkg_msg(?MSG_ARENA_PUSH_PLAYER_INFO, {pkg_players(Members ++ [MemberInfo], MatchMembers)})),
                                    members_notify(Members ++ [MemberInfo], MsgToMyTeam),
                                    MsgToMatchTeam = ?to_client_msg(arena_sproto:pkg_msg(?MSG_ARENA_PUSH_PLAYER_INFO, {pkg_players(MatchMembers, Members ++ [MemberInfo])})),
                                    members_notify(MatchMembers, MsgToMatchTeam),
                                    case length(Members ++ [MemberInfo]) =:= ?TEAM_MULTI_ARENA_MAX_MEMBERS andalso length(MatchMembers) =:= ?TEAM_MULTI_ARENA_MAX_MEMBERS of
                                        true -> %% start
                                            {ok, MyTeamInfo} = team_server:get_team_info(get(?pd_id), ?TEAM_TYPE_MULTI_ARENA),
                                            arena_server:start_m_p2p(MyTeamInfo, MatchTeamInfo);
                                        _ ->
                                            pass
                                    end;
                                _ ->
                                    MsgToMyTeam = ?to_client_msg(arena_sproto:pkg_msg(?MSG_ARENA_PUSH_PLAYER_INFO, {pkg_players(Members ++ [MemberInfo], [])})),
                                    members_notify(Members ++ [MemberInfo], MsgToMyTeam)
                            end;
                        _ ->
                            case team_server:create_team(MemberInfo, 0, ?TEAM_MULTI_ARENA_MAX_MEMBERS, ?TEAM_TYPE_MULTI_ARENA) of
                                {ok, TeamId} ->
                                    case team_server:try_get_matching_team(TeamId, ?TEAM_TYPE_MULTI_ARENA) of
                                        {ok, MatchTeamInfo} ->
                                            MatchMembers = MatchTeamInfo#team_info.members,
                                            MsgToMyTeam = ?to_client_msg(arena_sproto:pkg_msg(?MSG_ARENA_PUSH_PLAYER_INFO, {pkg_players([MemberInfo], MatchMembers)})),
                                            members_notify([MemberInfo], MsgToMyTeam),
                                            MsgToMatchTeam = ?to_client_msg(arena_sproto:pkg_msg(?MSG_ARENA_PUSH_PLAYER_INFO, {pkg_players(MatchMembers, [MemberInfo])})),
                                            members_notify(MatchMembers, MsgToMatchTeam);
                                        _ ->
                                            pass
                                    end,
                                    ?player_send(team_sproto:pkg_msg(?MSG_TEAM_CREATE, {TeamId, ?TEAM_TYPE_MULTI_ARENA, <<>>, pkg_members([MemberInfo])}));
                                _Err ->
                                    ?ERROR_LOG("create team error:~p", [_Err])
                            end
                    end
            end,
            ret:ok();
        E ->
            E
    end.

member_info_new() ->
    EquipList = api:get_equip_change_list(get(?pd_id)),
    EffList = api:get_efts_list(get(?pd_id)),
    #member_info{
        player_id = get(?pd_id),
        name = get(?pd_name),
        level = get(?pd_level),
        combar_power = get(?pd_combat_power),
        career = get(?pd_career),
        max_hp = attr_new:get_attr_item(?pd_attr_max_hp),
        ex_list = [{equip_list, EquipList}, {eff_list, EffList}]
    }.

pkg_members(Members) ->
    [pkg_member(Member) || Member <- Members].

pkg_member(#member_info{player_id = Id, name = Name, level = Lev, combar_power = Power, career = Career, max_hp = MaxHp}) ->
    {Id, Name, Lev, 0, Power, Career, MaxHp, 1}.

pkg_players(MyTeamers, MatchTeamers) ->
    MyTeamList = [pkg_player(1, Player) || Player <- MyTeamers],
    MatchTeamList = [pkg_player(2, Player) || Player <- MatchTeamers],
    MyTeamList ++ MatchTeamList.

pkg_player(Party, #member_info{player_id = Id, name = Name, career = Career, level = Lev, combar_power = Power, ex_list = [{equip_list, EquipList}, {eff_list, EffList}]}) ->
    {Party, Id, Name, Career, Lev, Power, EquipList, EffList}.

members_notify(Members, Msg) ->
    [world:send_to_player_if_online(M#member_info.player_id, Msg) || M <- Members].

stop() ->
    PlayerId = get(?pd_id),
    {CenterSvrNode, IsLink} = my_ets:get(center_svr_node_info, {0, false}),
    case IsLink of
        true ->
            rpc:cast(CenterSvrNode, arena_multi_p2p, multi_p2p_match_cancel, [{PlayerId, self()}]),
            ok;
        _ ->
            {ok, MyTeamInfo} = team_server:get_team_info(PlayerId, ?TEAM_TYPE_MULTI_ARENA),
            MatchMembers = case team_server:get_exist_match_team(MyTeamInfo#team_info.id, ?TEAM_TYPE_MULTI_ARENA) of
                {ok, MatchTeamInfo} -> MatchTeamInfo#team_info.members;
                _ -> []
            end,
            case team_server:leave_team(PlayerId, ?TEAM_TYPE_MULTI_ARENA) of
                {ok, NewMembers} ->
                    ?player_send(team_sproto:pkg_msg(?MSG_TEAM_QUIT, {PlayerId})),
                    lists:foreach(
                        fun(#member_info{player_id = Id}) ->
                                world:send_to_player_if_online(Id, ?to_client_msg(team_sproto:pkg_msg(?MSG_TEAM_QUIT, {PlayerId})))
                        end,
                        NewMembers
                    ),
                    MsgToMyTeam = ?to_client_msg(arena_sproto:pkg_msg(?MSG_ARENA_PUSH_PLAYER_INFO, {pkg_players(NewMembers, MatchMembers)})),
                    members_notify(NewMembers, MsgToMyTeam),
                    MsgToMatchTeam = ?to_client_msg(arena_sproto:pkg_msg(?MSG_ARENA_PUSH_PLAYER_INFO, {pkg_players(MatchMembers, NewMembers)})),
                    members_notify(MatchMembers, MsgToMatchTeam),
                    ok;
                _ ->
                    ok
            end
    end.

start_match({SceneId, X, Y, Dir, Party}) ->
    daily_task_tgr:do_daily_task({?ev_arena_pve_fight, 0}, 1),
    put(pd_party, Party),
    case attr_new:get(?pd_is_near_player_count_set) < 6 of
        true -> erlang:put(?pd_is_near_player_count_set, 6);
        _ -> ok
    end,
    case scene_mng:enter_scene_request(SceneId, X, Y, Dir) of
        approved ->
            bounty_mng:do_bounty_task(?BOUNTY_TASK_ARENA_M_P2P, 1),
            limit_value_eng:inc_daily_value(?day_arena_multi_p2p_count),
            erlang:put(pd_is_send_prize, false),
            ok;
        _E ->
            ?ERROR_LOG("enter multi_p2p fail. Reason ~w", [_E]),
            ok
    end.

over_match({
    {
        _PlayerInfo, _ArenaType, IsWin, Kill, Die
    },
    AI = #arena_info
    {
        m_p2p_win = MP2pWin,
        m_p2p_loss = MP2pLoss,
        m_p2p_kill = MP2pKill,
        m_p2p_die = MP2pDie
    },
    #arena_cfg
    {
        multi_p2p_win = {MPWinC, MPWinCTpL},
        multi_p2p_loss = {MPLossC, MPLossCTpL}
    }
}) ->
    achievement_mng:do_ac(?pkdashi),
    daily_task_tgr:do_daily_task({?ev_arena_pve_fight, 0},1),
    NewC = trunc(load_double_prize:get_double_type_and_fanbei_of_arean(6000) * MPWinC),
    case IsWin of
        ?TRUE ->
            achievement_mng:do_ac(?pkdashi),
            achievement_mng:do_ac(?zuiqiangwangze),
            %% 参与竞技场团队模式且胜利的次数
            phase_achievement_mng:do_pc(?PHASE_AC_ARENA_TEAM_WIN, 1),
            %% 参与竞技场匹配模式或团队模式的总胜利次数
            phase_achievement_mng:do_pc(?PHASE_AC_ARENA_WIN, 1),
            MP2pWAI = AI#arena_info{m_p2p_win = MP2pWin + 1, m_p2p_kill = MP2pKill + Kill, m_p2p_die = MP2pDie + Die},
            dbcache:update(?player_arena_tab, MP2pWAI),
            {load_arena_cfg:add_arena_cent(MP2pWAI, NewC), NewC, MPWinCTpL};
        _ ->
            MP2pLAI = AI#arena_info{ m_p2p_loss = MP2pLoss + 1, m_p2p_kill = MP2pKill + Kill, m_p2p_die = MP2pDie + Die},
            dbcache:update(?player_arena_tab, MP2pLAI),
            {load_arena_cfg:sub_arena_cent(MP2pLAI, MPLossC), -MPLossC, MPLossCTpL}
    end.

join_team(MasterId, ?TEAM_TYPE_MULTI_ARENA, SceneId) ->
    put(?cur_arena_type, ?ARENA_TYPE_MULTI_P2P),
    case is_can_arena_m_p2p_start() of
        true ->
            MemberInfo = member_info_new(),
            case team_server:get_team_info(MasterId, ?TEAM_TYPE_MULTI_ARENA) of
                {ok, TeamInfo} ->
                    case TeamInfo#team_info.state =:= ?TEAM_STATE_WAIT of
                        true ->
                            case length(TeamInfo#team_info.members) < TeamInfo#team_info.max_member_num of
                                true ->
                                    %% 加入队长队伍
                                    case team_server:join_team(MemberInfo, TeamInfo#team_info.id, ?TEAM_TYPE_MULTI_ARENA, SceneId) of
                                        {ok, {TeamId, Members}} ->
                                            %% 通知自己队伍信息
                                            ?player_send(team_sproto:pkg_msg(?MSG_TEAM_JOIN, {TeamId, ?TEAM_TYPE_MULTI_ARENA, <<>>, pkg_members(Members ++ [MemberInfo])})),
                                            Msg = ?to_client_msg(team_sproto:pkg_msg(?MSG_TEAM_MEMBER_JOIN, {pkg_member(MemberInfo)})),
                                            members_notify(Members, Msg),
                                            %% 刷新界面两个队伍成员信息
                                            case team_server:try_get_matching_team(TeamId, ?TEAM_TYPE_MULTI_ARENA) of
                                                {ok, MatchTeamInfo} ->
                                                    MatchMembers = MatchTeamInfo#team_info.members,
                                                    MsgToMyTeam = ?to_client_msg(arena_sproto:pkg_msg(?MSG_ARENA_PUSH_PLAYER_INFO, {pkg_players(Members ++ [MemberInfo], MatchMembers)})),
                                                    members_notify(Members ++ [MemberInfo], MsgToMyTeam),
                                                    MsgToMatchTeam = ?to_client_msg(arena_sproto:pkg_msg(?MSG_ARENA_PUSH_PLAYER_INFO, {pkg_players(MatchMembers, Members ++ [MemberInfo])})),
                                                    members_notify(MatchMembers, MsgToMatchTeam),
                                                    case length(Members ++ [MemberInfo]) =:= ?TEAM_MULTI_ARENA_MAX_MEMBERS andalso length(MatchMembers) =:= ?TEAM_MULTI_ARENA_MAX_MEMBERS of
                                                        true -> %% start
                                                            {ok, MyTeamInfo} = team_server:get_team_info(get(?pd_id), ?TEAM_TYPE_MULTI_ARENA),
                                                            arena_server:start_m_p2p(MyTeamInfo, MatchTeamInfo);
                                                        _ ->
                                                            pass
                                                    end;
                                                _ ->
                                                    MsgToMyTeam = ?to_client_msg(arena_sproto:pkg_msg(?MSG_ARENA_PUSH_PLAYER_INFO, {pkg_players(Members ++ [MemberInfo], [])})),
                                                    members_notify(Members ++ [MemberInfo], MsgToMyTeam)
                                            end,
                                            ?player_send(arena_sproto:pkg_msg(?MSG_ARENA_MATCH, {0})),
                                            ok;
                                        _ ->
                                            %% 队伍不存在
                                            {error, team_not_exist}
                                    end;
                                _ ->
                                    %% 匹配到敌方队伍
                                    case team_server:get_exist_match_team(TeamInfo#team_info.id, ?TEAM_TYPE_MULTI_ARENA) of
                                        {ok, MatchTeamInfo} ->  %% 敌方队伍存在，则加入
                                            case MatchTeamInfo#team_info.state =:= ?TEAM_STATE_WAIT andalso length(MatchTeamInfo#team_info.members) < MatchTeamInfo#team_info.max_member_num of
                                                true ->
                                                    case team_server:join_team(MemberInfo, MatchTeamInfo#team_info.id, ?TEAM_TYPE_MULTI_ARENA, SceneId) of
                                                        {ok, {MatchTeamId, MatchMembers}} ->
                                                            %% 通知自己队伍信息
                                                            ?player_send(team_sproto:pkg_msg(?MSG_TEAM_JOIN, {MatchTeamId, ?TEAM_TYPE_MULTI_ARENA, <<>>, pkg_members(MatchMembers ++ [MemberInfo])})),
                                                            Msg = ?to_client_msg(team_sproto:pkg_msg(?MSG_TEAM_MEMBER_JOIN, {pkg_member(MemberInfo)})),
                                                            members_notify(MatchMembers, Msg),
                                                            %% 刷新界面两个队伍成员信息
                                                            case team_server:get_exist_match_team(MatchTeamId, ?TEAM_TYPE_MULTI_ARENA) of
                                                                {ok, NewTeamInfo} ->
                                                                    NewMembers = NewTeamInfo#team_info.members,
                                                                    MsgToMyTeam = ?to_client_msg(arena_sproto:pkg_msg(?MSG_ARENA_PUSH_PLAYER_INFO, {pkg_players(MatchMembers ++ [MemberInfo], NewMembers)})),
                                                                    members_notify(MatchMembers ++ [MemberInfo], MsgToMyTeam),
                                                                    MsgToMatchTeam = ?to_client_msg(arena_sproto:pkg_msg(?MSG_ARENA_PUSH_PLAYER_INFO, {pkg_players(NewMembers, MatchMembers ++ [MemberInfo])})),
                                                                    members_notify(NewMembers, MsgToMatchTeam),
                                                                    case length(MatchMembers ++ [MemberInfo]) =:= ?TEAM_MULTI_ARENA_MAX_MEMBERS andalso length(NewMembers) =:= ?TEAM_MULTI_ARENA_MAX_MEMBERS of
                                                                        true -> %% start
                                                                            {ok, MyTeamInfo} = team_server:get_team_info(get(?pd_id), ?TEAM_TYPE_MULTI_ARENA),
                                                                            arena_server:start_m_p2p(MyTeamInfo, NewTeamInfo);
                                                                        _ ->
                                                                            pass
                                                                    end;
                                                                _ ->
                                                                    ?ERROR_LOG("error, can not find master team"),
                                                                    pass
                                                            end,
                                                            ?player_send(arena_sproto:pkg_msg(?MSG_ARENA_MATCH, {0})),
                                                            ok;
                                                        _ ->
                                                            %% 队伍不存在
                                                            {error, team_not_exist}
                                                    end;
                                                _ ->
                                                    %% 队伍不存在
                                                    {error, team_not_exist}
                                            end;
                                        _ ->    %% 敌方队伍不存在，创建队伍后匹配
                                            case team_server:create_team(MemberInfo, SceneId, ?TEAM_MULTI_ARENA_MAX_MEMBERS, ?TEAM_TYPE_MULTI_ARENA) of
                                                {ok, CreateTeamId} ->
                                                    case team_server:try_get_matching_team(CreateTeamId, ?TEAM_TYPE_MULTI_ARENA) of
                                                        {ok, MatchTeamInfo} ->
                                                            MatchMembers = MatchTeamInfo#team_info.members,
                                                            MsgToMyTeam = ?to_client_msg(arena_sproto:pkg_msg(?MSG_ARENA_PUSH_PLAYER_INFO, {pkg_players([MemberInfo], MatchMembers)})),
                                                            members_notify([MemberInfo], MsgToMyTeam),
                                                            MsgToMatchTeam = ?to_client_msg(arena_sproto:pkg_msg(?MSG_ARENA_PUSH_PLAYER_INFO, {pkg_players(MatchMembers, [MemberInfo])})),
                                                            members_notify(MatchMembers, MsgToMatchTeam);
                                                        _ ->
                                                            pass
                                                    end,
                                                    ?player_send(team_sproto:pkg_msg(?MSG_TEAM_CREATE, {CreateTeamId, ?TEAM_TYPE_MULTI_ARENA, <<>>, pkg_members([MemberInfo])})),
                                                    ?player_send(arena_sproto:pkg_msg(?MSG_ARENA_MATCH, {0})),
                                                    ok;
                                                _Err ->
                                                    ?ERROR_LOG("create team error:~p", [_Err]),
                                                    {error, team_not_exist}
                                            end
                                    end
                            end;
                        _ ->
                            %% 队伍不存在
                            {error, team_not_exist}
                    end;
                _ ->
                    %% 队伍不存在
                    {error, team_not_exist} 
            end;
        E ->
            E
    end.

is_can_arena_m_p2p_start() ->
    [{{TimeH, TimeM, TimeS}, DurationM}] = misc_cfg:get_arena_multi_p2p_start_time(),
    LaunchTime = (TimeH * 60 * 60) + (TimeM * 60) + TimeS,
    CloseTime = LaunchTime + (DurationM * 60),
    NowTime = util:get_today_passed_seconds(),
    MultiP2pCount = limit_value_eng:get_daily_value_int(?day_arena_multi_p2p_count),
    MultiP2pCountMax = misc_cfg:get_arena_p2p_count(),
    if
        %%如果当前时间大于结束时间或者小于开始时间，返回不在活动时间的消息码
        (CloseTime < NowTime) orelse (NowTime < LaunchTime) ->
            ret:error(multi_p2p_outtime);
        MultiP2pCount >= MultiP2pCountMax, MultiP2pCountMax =/= 0 ->
            ret:error(max_count);
        true ->
            true
    end.
