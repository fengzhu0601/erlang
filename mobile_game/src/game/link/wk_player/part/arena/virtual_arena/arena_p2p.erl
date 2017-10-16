%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 29. 十二月 2015 下午2:12
%%%-------------------------------------------------------------------
-module(arena_p2p).
-author("clark").

%% API
-export([
    challenge_player/1
]).

-include("i_arena.hrl").
-include("arena.hrl").
-include("inc.hrl").
-include("player.hrl").
-include("arena_struct.hrl").
-include("achievement.hrl").
-include("load_phase_ac.hrl").
-include("team.hrl").
-include("scene_agent.hrl").
-include("load_spirit_attr.hrl").
-include("../../wonderful_activity/bounty_struct.hrl").

start() ->
    [{{TimeH, TimeM, TimeS}, DurationM}] = misc_cfg:get_arena_p2p_start_time(),
    LaunchTime = (TimeH * 60 * 60) + (TimeM * 60) + TimeS,
    CloseTime = LaunchTime + (DurationM * 60),
    NowTime = util:get_today_passed_seconds(),
    if
        DurationM >= 1440 ->                                            %%  如果配置时间大于或等于24小时则表示竞技场一整天都可以匹配
            start_arena();
        (CloseTime < NowTime) orelse (NowTime < LaunchTime) ->          %%  如果当前时间大于结束时间或者小于开始时间，返回不在活动时间的消息码
            ret:error(p2p_outtime);
        true ->
            start_arena()
    end.

start_arena() ->
    PlayerId = get(?pd_id),
    PlayerName = get(?pd_name),
    Job = attr_new:get(?pd_career),
    Lev = get(?pd_level),
    Power = attr_new:get(?pd_combat_power),
    EquipList = api:get_equip_change_list(PlayerId),
    EffList = api:get_efts_list(PlayerId),
    P2pCount = limit_value_eng:get_daily_value_int(?day_arena_p2p_count),
    case misc_cfg:get_arena_p2p_count() of
        P2pCountMax when P2pCount >= P2pCountMax, P2pCountMax =/= 0 ->
            ret:error(max_count);
        _ ->
            {CenterSvrNode, IsLink} = my_ets:get(center_svr_node_info, {0, false}),
            case IsLink of
                true -> %% 跨服
                    rpc:cast(CenterSvrNode, arena_server, player_match_p2p, [{PlayerId, self(), PlayerName, Job, Lev, Power, EquipList, EffList, com_time:now()}]);
                _ ->    %% 本地
                    arena_server:player_match_p2p({PlayerId, PlayerName, Job, Lev, Power, EquipList, EffList, com_time:now()})
            end,
            ret:ok()
    end.

challenge_player(PlayerId) ->
    put(?cur_arena_type, ?ARENA_TYPE_P2P),
    MyId = get(?pd_id),
    Name = get(?pd_name),
    Job = attr_new:get(?pd_career),
    Lev = get(?pd_level),
    Power = attr_new:get(?pd_combat_power),
    EquipList = api:get_equip_change_list(MyId),
    EffList = api:get_efts_list(MyId),
    case arena_server:p2p_challenge_player({MyId, Name, Job, Lev, Power, EquipList, EffList, com_time:now()}, PlayerId) of
        ok ->
            ?player_send(arena_sproto:pkg_msg(?MSG_ARENA_MATCH, {0})),
            ok;
        E ->
            E
    end.

stop() ->
    PlayerId = get(?pd_id),
    {CenterSvrNode, IsLink} = my_ets:get(center_svr_node_info, {0, false}),
    case IsLink of
        true ->
            rpc:cast(CenterSvrNode, arena_server, player_match_p2p_cancel, [PlayerId]),
            ok;
        _ ->
            arena_server:player_match_p2p_cancel(PlayerId)
    end.

start_match({SceneId, X, Y, Dir, Party}) ->
    put(pd_party, Party),
    CountSet = attr_new:get(?pd_is_near_player_count_set),
    if
        CountSet =:= 0 -> erlang:put(?pd_is_near_player_count_set, 1);
        true -> ok
    end,
    case scene_mng:enter_scene_request(SceneId, X, Y, Dir) of
        approved ->
            bounty_mng:do_bounty_task(?BOUNTY_TASK_ARENA_P2P, 1),
            limit_value_eng:inc_daily_value(?day_arena_p2p_count),
            erlang:put(pd_is_send_prize, false),
            ok;
        _E ->
            ?ERROR_LOG("enter p2p fail. Reason ~w", [_E]),
            ok
    end.

over_match({
    {
        [PlayerInfo1, PlayerInfo2], _ArenaType, IsWin, Kill, Die
    },
    AI = #arena_info
    {
        p2p_win = P2pWin,
        p2p_loss = P2pLoss,
        p2p_kill = P2pKill
    },
    #arena_cfg
    {
        p2p_win = {PWinC, PWinCTpL},
        p2p_loss = {PLossC, PLossCTpL}
    }
}) ->
    PlayerId1 = element(1, PlayerInfo1),
    PlayerId2 = element(1, PlayerInfo2),
    OpponentId = case get(?pd_id) of
        PlayerId1 -> PlayerId2;
        _ -> PlayerId1
    end,
    achievement_mng:do_ac(?pkgaoshou),
    daily_task_tgr:do_daily_task({?ev_arena_pve_fight, 0}, 1),
    NewC = trunc(load_double_prize:get_double_type_and_fanbei_of_arean(5000) * PWinC),
    NewPWinCTpL = prize:double_items(5000, PWinCTpL),
    NewPLossCTpL = prize:double_items(5000, PLossCTpL),
    {NewTab, Cent, Award} = case IsWin of
        ?TRUE ->
            achievement_mng:do_ac(?dantiaozhiwang),
            achievement_mng:do_ac(?zuiqiangwangze),
            %% 参与竞技场匹配模式且胜利的次数
            phase_achievement_mng:do_pc(?PHASE_AC_ARENA_ONE_WIN, 1),
            %% 参与竞技场匹配模式或团队模式的总胜利次数
            phase_achievement_mng:do_pc(?PHASE_AC_ARENA_WIN, 1),
            CountL = limit_value_eng:get_daily_value(?pd_day_p2p_cent_limit, []),
            case lists:keyfind(OpponentId, 1, CountL) of
                {_, Count} when Count < ?ADD_CENT_COUNT ->
                    P2pWAI = AI#arena_info{p2p_win = P2pWin + 1, p2p_kill = P2pKill + Kill},
                    NCountL = lists:keyreplace(OpponentId, 1, CountL, {OpponentId, Count + 1}),
                    limit_value_eng:set_daily_value(?pd_day_p2p_cent_limit, NCountL),
                    {load_arena_cfg:add_arena_cent(P2pWAI, NewC), NewC, NewPWinCTpL};
                ?false ->
                    P2pWAI = AI#arena_info{p2p_win = P2pWin + 1, p2p_kill = P2pKill + Kill},
                    NCountL = [{OpponentId, 1} | CountL],
                    limit_value_eng:set_daily_value(?pd_day_p2p_cent_limit, NCountL),
                    {load_arena_cfg:add_arena_cent(P2pWAI, NewC), NewC, NewPWinCTpL};
                _ ->
                    {AI#arena_info{p2p_win = P2pWin + 1, p2p_kill = P2pKill + Kill}, 0, [{24, 0}]}
            end;
        _ ->
            achievement_mng:do_ac(?jianyibuqu),
            P2pLAI = AI#arena_info{p2p_loss = P2pLoss + 1, p2p_kill = P2pKill + Kill},
            {load_arena_cfg:sub_arena_cent(P2pLAI, PLossC), -PLossC, NewPLossCTpL}
    end,
    [{_, Honor}] = Award,
    ?player_send(arena_sproto:pkg_msg(?MSG_ARENA_RESULT, {IsWin, Kill, Die, Cent, Honor, Award})),
    ?player_send(main_instance_sproto:pkg_msg(?MSG_MAIN_INSTANCE_TEAM_DISSOLVE, {})),
    {NewTab, Cent, Award}.

% create_scene_agent(SceneId, RobotId, Lev, {X, Y}, Dir, Party) ->
%     ScenePid = load_cfg_scene:get_pid(SceneId),
%     Attr = attr_new:get_oldversion_attr(),
%     RobotAgent = #agent{
%         id = RobotId,
%         pid = world:get_player_pid(RobotId),
%         type = ?agent_player,
%         x = X,
%         y = Y,
%         h = 0,
%         d = Dir,
%         rx = 30,
%         ry = 20,
%         level = Lev,
%         attr = Attr,
%         hp = attr_new:get_attr_item(?pd_attr_max_hp),
%         mp = attr_new:get_attr_item(?pd_attr_max_mp),
%         max_hp = Attr#attr.hp,
%         max_mp = Attr#attr.mp,
%         enter_view_info = player:get_player_view_info(RobotId),
%         ai_flag = 1,
%         party = Party
%     },
%     ScenePid ! ?scene_mod_msg(scene_player, {build_robot, RobotAgent}).

