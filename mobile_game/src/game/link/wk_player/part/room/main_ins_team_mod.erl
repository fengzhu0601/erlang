%%-----------------------------------
%% @Module  : main_ins_team_mod
%% @Author  : Holtom
%% @Email   : 
%% @Created : 2016.4.16
%% @Description: 副本组队模块
%%-----------------------------------
-module(main_ins_team_mod).

-include("inc.hrl").
-include("scene.hrl").
-include("player.hrl").
% -include("safe_ets.hrl").
-include("mod_name_def.hrl").
-include("main_ins_struct.hrl").
% -include("main_ins_team_mod.hrl").
-include("load_cfg_main_ins.hrl").
-include("load_cfg_scene.hrl").
-include("team.hrl").

-define(PKG_MSG, main_instance_sproto:pkg_msg).

-export([
        handle_create_room/2,
        get_all_team_info/3,
        handle_quick_join/1,
        handle_msg/2,
        handle_leave_team/1,
        handle_kickout/1,
        handle_dissolve/0,
        handle_start/0,
        team_start/1,
        join_team/3,
        get_player_team_id/1,
        leave_team_if_in/1,
        leave_team_if_wait/1,
        fuben_complete/1,
        insert_new_scene/2,
        send_info_and_return_fuben/2,
        first_enter_is_master/3,
        notify_members_idx/2,
        members_notify/2
    ]).

handle_create_room(ConfigId, _IsAllowMidwayJoin) ->
    MainInsCfg = load_cfg_main_ins:lookup_main_ins_cfg(ConfigId),
    ?if_(MainInsCfg =:= ?none, ?return_err(none_cfg)),
    MaxMembers = MainInsCfg#main_ins_cfg.max_members,
    ?if_(MaxMembers =< 1, ?return_err(not_team_main_ins)),
    %%?ifdo(get(?pd_level) < MainInsCfg#main_ins_cfg.level_limit,
    %%?return_err(level_limit)),
    %%scene:lookup_scene_cfg(ConfigId, #scene_cfg.level_limit), 
    MemberInfo = member_info_new(),
    case team_server:create_team(MemberInfo, ConfigId, MaxMembers, ?TEAM_TYPE_MAIN_INS) of
        {ok, TeamId} ->
            ?player_send(?PKG_MSG(?MSG_MAIN_INSTANCE_TEAM_CREATE, {TeamId}));
        {error, Why} ->
            ?ERROR_LOG("error with:~p", [Why])
    end.

get_all_team_info(PlayerLev, Type, SceneId) ->
    team_server:get_team_info_by_scene_id(PlayerLev, Type, SceneId).

handle_quick_join(ConfigId) ->
    MemberInfo = member_info_new(),
    case team_server:quick_join(MemberInfo, ConfigId, ?TEAM_TYPE_MAIN_INS) of
        {ok, {TeamId, Members}} ->
            Msg = ?to_client_msg(?PKG_MSG(?MSG_MAIN_INSTANCE_TEAM_MEMBER_JOIN, {pack_member_info(MemberInfo)})),
            members_notify(Members, Msg),
            ?player_send(?PKG_MSG(?MSG_MAIN_INSTANCE_TEAM_QUICK_JOIN, {ConfigId, TeamId, [pack_member_info(M) || M <- Members]}));
        {error, _Why} ->
            ?player_send_err(?MSG_MAIN_INSTANCE_TEAM_QUICK_JOIN, ?ERR_TEAM_INS_ROOM_NOT_EXIST)
    end.

handle_leave_team(PlayerId) ->
    case team_server:leave_team(PlayerId, ?TEAM_TYPE_MAIN_INS) of
        {ok, Members} ->
            Msg = ?to_client_msg(?PKG_MSG(?MSG_MAIN_INSTANCE_TEAM_LEAVE, {PlayerId})),
            members_notify([#member_info{player_id = PlayerId}], Msg),
            members_notify(Members, ?to_client_msg(?PKG_MSG(?MSG_MAIN_INSTANCE_TEAM_LEAVE, {PlayerId})));
        {error, Why} ->
            ?ERROR_LOG("error with:~p", [Why])
    end.

handle_kickout(MemberId) ->
    case team_server:kickout_member(get(?pd_id), MemberId, ?TEAM_TYPE_MAIN_INS) of
        {ok, Members} ->
            members_notify([#member_info{player_id = MemberId}], ?to_client_msg(?PKG_MSG(?MSG_MAIN_INSTANCE_TEAM_KICKOUT, {MemberId}))),
            members_notify(Members, ?to_client_msg(?PKG_MSG(?MSG_MAIN_INSTANCE_TEAM_LEAVE, {MemberId})));
        {error, Why} ->
            ?ERROR_LOG("error with:~p", [Why])
    end.

handle_dissolve() ->
    case team_server:get_team_id(get(?pd_id), ?TEAM_TYPE_MAIN_INS) of
        {ok, TeamId} ->
            dissolve_team(TeamId, ?TEAM_TYPE_MAIN_INS);
        _ ->
            ignore
    end.

handle_start() ->
    case team_server:get_team_info(get(?pd_id), ?TEAM_TYPE_MAIN_INS) of
        {ok, TeamInfo} ->
            [SceneCfgId] = TeamInfo#team_info.scene_id_list,
            TeamId = TeamInfo#team_info.id,
            MainInsCfg = load_cfg_main_ins:lookup_main_ins_cfg(SceneCfgId),
            case room_system:get_room_pid_by_cfg(SceneCfgId, TeamId, {MainInsCfg#main_ins_cfg.is_monster_match_level, get(?pd_level), length(TeamInfo#team_info.members)}) of
                Pid when is_pid(Pid) -> %% 多人正常情况走这里
                    members_notify(TeamInfo#team_info.members, ?mod_msg(main_instance_mng, {team_start, {TeamInfo}})),
                    team_server:team_start(TeamId, ?TEAM_TYPE_MAIN_INS);
                E ->
                    ?ERROR_LOG("create team pid error:~p", [E]),
                    SceneId = scene:make_scene_id(?SC_TYPE_TEAM, team, SceneCfgId, TeamId),
                    case scene_sup:start_scene(SceneId, #run_arg{match_level = get(?pd_level), is_match = MainInsCfg#main_ins_cfg.is_monster_match_level}) of
                        {error, E} ->
                            {error, E};
                        _Pid ->
                            members_notify(TeamInfo#team_info.members, ?mod_msg(main_instance_mng, {team_start, {TeamId, SceneCfgId}})),
                            {ok, SceneId}
                    end
            end;
        {error, Why} ->
            ?ERROR_LOG("error with:~p", [Why])
    end.

team_start({TeamInfo}) ->
    [SceneCfgId] = TeamInfo#team_info.scene_id_list,
    MainInsCfg = load_cfg_main_ins:lookup_main_ins_cfg(SceneCfgId),
    put(?main_instance_id_ing, SceneCfgId),
    case main_ins_mod:can_get_prize_from_room(SceneCfgId) of
        ?true ->
            main_instance_mng:add_challenge_times(SceneCfgId),
            main_instance_mng:push_challenge_info_by_id(SceneCfgId),
            main_ins_mod:cost(MainInsCfg#main_ins_cfg.sp_cost, MainInsCfg#main_ins_cfg.cost, {MainInsCfg#main_ins_cfg.type, MainInsCfg#main_ins_cfg.sub_type}),
            attr_new:set(?pd_cost_sp, MainInsCfg#main_ins_cfg.sp_cost),
            attr_new:set(?pd_can_get_prize_from_room, true);
        _ ->
            ?return_err(?ERR_MAX_COUNT)
            %% main_instance_mng:push_challenge_info_by_id(SceneCfgId),
            %% main_ins_mod:cost(0, MainInsCfg#main_ins_cfg.cost, {MainInsCfg#main_ins_cfg.type, MainInsCfg#main_ins_cfg.sub_type}),
            %% attr_new:set(?pd_cost_sp, 0),
            %% attr_new:set(?pd_can_get_prize_from_room, false)
    end,
    main_instance_mng:init_open_card_data(SceneCfgId),
    Pid = room_system:get_room_pid_by_cfg(SceneCfgId, TeamInfo#team_info.id, {0, 0, 1}),
    {X, Y} = load_cfg_scene:get_enter_pos_by_cfg(SceneCfgId),
    player_room_part:begin_enter_room_by_client({Pid, SceneCfgId, 1, X, Y, ?D_R}),
    %% 统计赏金任务挑战副本
    main_ins_mod:count_bounty_fight_room(MainInsCfg#main_ins_cfg.sub_type),
    achievement_mng:init_instance_ac(MainInsCfg#main_ins_cfg.stars, []);
team_start({TeamId, SceneId}) ->
    ?INFO_LOG("==++----------------------------------team_start get_team_id"),
    case team_server:get_team_id(get(?pd_id), ?TEAM_TYPE_MAIN_INS) of
        {ok, TeamId} ->
            case scene_mng:enter_scene_request(SceneId) of
                approved ->
                    put(?main_instance_id_ing, SceneId),
                    ?debug_log_team_ins("enter scene requset approved");
                disapproved ->
                    %% single_instance will auto terminal
                    ?ERROR_LOG("enter_single_instance request ~p disapproved", [TeamId])
            end;
        _E ->
            ?ERROR_LOG("start instance but not in same room ~p ~p", [TeamId, _E])
    end.

join_team(MasterId, Type, SceneId) ->
    case team_server:get_team_info(MasterId, ?TEAM_TYPE_MAIN_INS) of
        {ok, TeamInfo} -> %% 加入队长队伍
            MemberInfo = member_info_new(),
            case team_server:join_team(MemberInfo, TeamInfo#team_info.id, Type, SceneId) of
                {ok, {TeamId, Members}} ->
                    Msg = ?to_client_msg(?PKG_MSG(?MSG_MAIN_INSTANCE_TEAM_MEMBER_JOIN, {pack_member_info(MemberInfo)})),
                    members_notify(Members, Msg),
                    ?player_send(?PKG_MSG(?MSG_MAIN_INSTANCE_TEAM_QUICK_JOIN, {SceneId, TeamId, [pack_member_info(M) || M <- Members]})),
                    ok;
                E ->
                    E
            end;
        _E ->
            _E
    end.

handle_msg(From, Msg) ->
    ?ERROR_LOG("receive unknown msg from : ~p msg : ~p", [From, Msg]).

%% 玩家离线调用
leave_team_if_wait(PlayerId) ->
    case team_server:get_team_info(PlayerId, ?TEAM_TYPE_MAIN_INS) of
        {ok, TeamInfo} ->
            case TeamInfo#team_info.state of
                ?TEAM_STATE_WAIT ->     % 处于等待状态,自己离队
                    case team_server:is_team_master(PlayerId, ?TEAM_TYPE_MAIN_INS) of
                        true ->
                            dissolve_team(TeamInfo#team_info.id, ?TEAM_TYPE_MAIN_INS);
                        _ ->
                            handle_leave_team(PlayerId)
                    end;
                _ ->
                    Members = TeamInfo#team_info.members,
                    case lists:any(
                        fun(M) ->
                                M#member_info.player_id =/= PlayerId andalso world:is_player_online(M#member_info.player_id)
                        end,
                        Members
                    ) of
                        true ->
                            check_change_master_except_this(PlayerId);
                        _ ->
                            dissolve_team(TeamInfo#team_info.id, ?TEAM_TYPE_MAIN_INS)
                    end
            end;
        _ ->
            case team_svr:get_team_id_by_player(PlayerId) of
                ?none ->
                    %?DEBUG_LOG("leave_team_if_wait-------------------------------"),
                    pass;
                TeamId ->
                    %?DEBUG_LOG("leave_team_if_wait--playerid--:~p----TeamId---:~p",[PlayerId, TeamId]),
                    case gwgc_server:get_team_fighting_data(TeamId) of
                        ?none ->
                            ?DEBUG_LOG("leave_team_if_wait------------------------------------pass"),
                            team_mng:public_offline(PlayerId);
                        _ ->
                            team_mod:member_leave(PlayerId, TeamId)
                    end
            end
    end.

%% 玩家回城调用
leave_team_if_in(PlayerId) ->
    case team_server:get_team_info(PlayerId, ?TEAM_TYPE_MAIN_INS) of
        {ok, TeamInfo} ->
            Members = TeamInfo#team_info.members,
            case lists:any(
                fun(M) ->
                        M#member_info.player_id =/= PlayerId andalso world:is_player_online(M#member_info.player_id)
                end,
                Members
            ) of
                true ->
                    check_change_master_except_this(PlayerId),
                    handle_leave_team(PlayerId);
                _ ->
                    dissolve_team(TeamInfo#team_info.id, ?TEAM_TYPE_MAIN_INS)
            end;
        _ ->
            case team_svr:get_team_id_by_player(PlayerId) of
                ?none ->
                    %?DEBUG_LOG("leave_team_if_in-------------------------------"),
                    pass;
                TeamId ->
                    %?DEBUG_LOG("leave_team_if_in--playerid--:~p----TeamId---:~p",[PlayerId, TeamId]),
                    case gwgc_server:get_team_fighting_data(TeamId) of
                        ?none ->
                            ?DEBUG_LOG("leave_team_if_in------------------------------------pass");
                        _ ->
                            team_mod:member_leave(PlayerId, TeamId)
                    end
            end
    end.
    % case team_server:get_team_id(PlayerId, ?TEAM_TYPE_MAIN_INS) of
    %     {ok, _TeamId} ->
    %         check_change_master_except_this(PlayerId),
    %         handle_leave_team(PlayerId);
    %     _ ->
    %         ok
    % end.

fuben_complete(TeamId) ->
    case get(pd_scene_type) of
        playr_room ->
            case team_server:get_team_members(TeamId, ?TEAM_TYPE_MAIN_INS) of
                [] ->
                    pass;
                Members ->
                    members_notify(Members, ?to_client_msg(?PKG_MSG(?MSG_MAIN_INSTANCE_NOTIFY_COMPLETE, {}))),
                    dissolve_team(TeamId, ?TEAM_TYPE_MAIN_INS)
            end;
        gwgc_type ->
            case team_svr:get_team_info(TeamId) of
                ?none ->
                    pass;
                GwgcTeamInfo ->
                    case team_svr:playerid2teamid(get(pd_ori_team_master)) of
                        TeamId ->
                            team_svr:set_leader(TeamId, get(pd_ori_team_master)),
                            gongcheng_mng:notice_members(GwgcTeamInfo, ?to_client_msg(?PKG_MSG(?MSG_MAIN_INSTANCE_NOTIFY_TEAM_MASTER, {get(pd_ori_team_master)})));
                        _ ->
                            pass
                    end,
                    ?DEBUG_LOG("fuben_complete---gwinfo--------------------:~p",[ets:info(gwgc_rank_data,size)]),
                    gwgc_server ! {is_over, TeamId},
                    gongcheng_mng:notice_members(GwgcTeamInfo, ?to_client_msg(?PKG_MSG(?MSG_MAIN_INSTANCE_NOTIFY_COMPLETE, {})))
            end;
        _E ->
            ?ERROR_LOG("known type:~p", [_E])
    end.

insert_new_scene(TeamId, SceneId) ->
    team_server:insert_new_scene(TeamId, SceneId, ?TEAM_TYPE_MAIN_INS).

send_info_and_return_fuben(PlayerId, TeamId) ->
    case team_server:get_team_info(PlayerId, ?TEAM_TYPE_MAIN_INS) of
        {ok, TeamInfo} ->
            Members = TeamInfo#team_info.members,
            [FirstSceneId | _] = SceneIdList = TeamInfo#team_info.scene_id_list,
            EnterSceneId = lists:last(SceneIdList),
            case room_system:get_room_pid_by_cfg(EnterSceneId, TeamId, {0, 0, 1}) of
                Pid when is_pid(Pid) ->
                    put(?main_instance_id_ing, FirstSceneId),
                    attr_new:set(?pd_can_get_prize_from_room, true),
                    MainInsCfg = load_cfg_main_ins:lookup_main_ins_cfg(FirstSceneId),
                    achievement_mng:init_instance_ac(MainInsCfg#main_ins_cfg.stars, []),
                    ?player_send(?PKG_MSG(?MSG_MAIN_INSTANCE_TEAM_QUICK_JOIN, {EnterSceneId, TeamId, [pack_member_info(M) || M <- Members, M#member_info.player_id =/= PlayerId]})),
                    {X, Y} = load_cfg_scene:get_enter_pos_by_cfg(EnterSceneId),
                    player_room_part:begin_enter_room_by_client({Pid, EnterSceneId, 1, X, Y, ?D_R});
                _ ->
                    error
            end;
        _ ->
            error
    end.

first_enter_is_master(PlayerId, TeamId, playr_room) ->
    team_server:set_team_master(PlayerId, TeamId, ?TEAM_TYPE_MAIN_INS),
    case team_server:get_team_members(TeamId, ?TEAM_TYPE_MAIN_INS) of
        [] -> pass;
        Members -> members_notify(Members, ?to_client_msg(?PKG_MSG(?MSG_MAIN_INSTANCE_NOTIFY_TEAM_MASTER, {PlayerId})))
    end;
first_enter_is_master(PlayerId, TeamId, gwgc_type) ->
    case team_svr:get_team_info(TeamId) of
        ?none ->
            pass;
        GwgcTeamInfo ->
            TeamLeader = team_svr:set_leader(TeamId, PlayerId),
            ?DEBUG_LOG("first_enter_is_master--------------------:~p",[{PlayerId, TeamLeader}]),
            gongcheng_mng:notice_members(GwgcTeamInfo, ?to_client_msg(?PKG_MSG(?MSG_MAIN_INSTANCE_NOTIFY_TEAM_MASTER, {TeamLeader})))
    end;
first_enter_is_master(_, _, Type) ->
    ?ERROR_LOG("known type:~p", [Type]).

notify_members_idx(PlayerId, Idx) ->
    case team_server:get_team_id(PlayerId, ?TEAM_TYPE_MAIN_INS) of
        {ok, TeamId} ->
            Members = team_server:get_team_members(TeamId, ?TEAM_TYPE_MAIN_INS),
            members_notify(Members, ?to_client_msg(?PKG_MSG(?MSG_MAIN_INSTANCE_ID_INFO, {PlayerId, Idx})));
        _ ->
            case team_svr:get_team_info_by_player(PlayerId) of
                ?none ->
                    pass;
                GwgcTeamInfo ->
                    gongcheng_mng:notice_members(GwgcTeamInfo, ?to_client_msg(?PKG_MSG(?MSG_MAIN_INSTANCE_ID_INFO, {PlayerId, Idx})))
            end
    end.

get_player_team_id(PlayerId) ->
    case team_server:get_team_id(PlayerId, ?TEAM_TYPE_MAIN_INS) of
        {ok, TeamId} ->
            TeamId;
        _ ->
            none
    end.

dissolve_team(TeamId, Type) ->
    case team_server:dissolve_team(TeamId, Type) of
        {ok, Members} ->
            members_notify(Members, ?to_client_msg(?PKG_MSG(?MSG_MAIN_INSTANCE_TEAM_DISSOLVE, {})));
        {error, Why} ->
            ?ERROR_LOG("error with:~p", [Why])
    end.

member_info_new() ->
    #member_info{
        player_id = get(?pd_id),
        name = get(?pd_name),
        level = get(?pd_level),
        combar_power = get(?pd_combat_power),
        career = get(?pd_career),
        max_hp = attr_new:get_attr_item(?pd_attr_max_hp)
    }.

pack_member_info(#member_info{player_id = Id, name = Name, level = Lev, combar_power = Power, career = Career, max_hp = MaxHp}) ->
    {Id, Name, Lev, Power, Career, MaxHp}.

members_notify(Members, Msg) ->
    [world:send_to_player_if_online(M#member_info.player_id, Msg) || M <- Members].

check_change_master_except_this(PlayerId) ->
    case team_server:is_team_master(PlayerId, ?TEAM_TYPE_MAIN_INS) of
        true ->
            ?INFO_LOG("==++----------------------------------check_change_master_except_this get_team_id"),
            {ok, TeamId} = team_server:get_team_id(PlayerId, ?TEAM_TYPE_MAIN_INS),
            Members = team_server:get_team_members(TeamId, ?TEAM_TYPE_MAIN_INS),
            case team_server:change_team_master_except_this(TeamId, PlayerId, ?TEAM_TYPE_MAIN_INS) of
                {ok, MasterId} ->
                    members_notify(Members, ?to_client_msg(?PKG_MSG(?MSG_MAIN_INSTANCE_NOTIFY_TEAM_MASTER, {MasterId})));
                _ ->
                    ignore
            end;
        _ ->
            ignore
    end.
