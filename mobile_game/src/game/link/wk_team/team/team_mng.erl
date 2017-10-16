%% coding:utf-8
%%-------------------------------------------------------------------
%% @author zlb
%% @doc 组队
%%
%% @end
%%-------------------------------------------------------------------

-module(team_mng).

-include("inc.hrl").
-include("player.hrl").
-include("player_mod.hrl").
-include("team.hrl").
-include("team_struct.hrl").
-include("gem.hrl").
-include("handle_client.hrl").


-export([
    playerid2team/1, 
    playerid2teamid/1,
    public_offline/1,
    broadcast/1
]).

handle_frame(_) -> ok.


create_mod_data(_SelfId) ->
    ok.


load_mod_data(_PlayerId) ->
    ok.


public_offline(PlayerId) ->
    case playerid2team(PlayerId) of
        #team{id = TeamId, pid = _TeamPid} ->
            %% TODO: 下线的时候修正上线状态
            ?DEBUG_LOG("team_mng offline TeamId-------------------------------:~p",[TeamId]),
            team_mod:quit(PlayerId, TeamId),
            ok;
        _E -> ignore
    end,
    ok.



init_client() ->
    ignore.

view_data(Msg) ->
    Msg.
%% 通过角色id获取队伍id
playerid2teamid(PlayerId) ->
    case ets:lookup(?team_mem_index, PlayerId) of
        [{_, TeamId}] -> TeamId;
        _ -> ?undefined
    end.

%% 通过角色id获取队伍信息
playerid2team(PlayerId) ->
    case ets:lookup(?team_mem_index, PlayerId) of
        [{_, TeamId}] ->
            case ets:lookup(?team_info, TeamId) of
                [Team] -> Team;
                _ -> ?undefined
            end;
        _ -> ?undefined
    end.
online() ->
    PlayerId = get(?pd_id),
    case playerid2team(PlayerId) of
        #team{id = _TeamId, pid = _TeamPid, members = _TMs} ->
            ok;
            %% TODO: 上线的时候修正上线状态
%%             put(?pd_team_id, TeamId);
    %%?player_send(team_sproto:pkg_msg(?MSG_TEAM_CREATE,{TeamId, TMs}) );
        _E ->
            ignore
    end,
    ok.


offline(_PlayerId) ->
    ok.

save_data(_) -> ok.

handle_client({Pack, Arg}) ->
    handle_client(Pack, Arg).

handle_client(?MSG_TEAM_CREATE, {TeamType, TeamName}) ->
    %?DEBUG_LOG("TeamType-----------:~p----TeamName----:~p",[TeamType, TeamName]),
    case ets:info(gwgc_info) of
        ?undefined ->
            ?return_err(?ERR_GWGC_NOT_STAR);
        _ ->
            case team_mod:create_team(TeamType, TeamName, get(?pd_id)) of
                {error, Err} ->
                    %?DEBUG_LOG("MSG_TEAM_CREATE-------------------:~p",[Err]),
                    ?return_err(Err);
                _E ->
                    %?DEBUG_LOG("e-----------------------------------:~p",[_E]),
                    pass
            end
    end;


handle_client(?MSG_TEAM_GC_LIST_BY_TYPE, {TeamType}) -> 
    %?DEBUG_LOG("TeamType----------------------------------:~p",[TeamType]),
    Bin = team_svr:get_team_list_info(TeamType),
    %?DEBUG_LOG("Bin------------------------------------:~p",[Bin]),
    ?player_send(team_sproto:pkg_msg(?MSG_TEAM_GC_LIST_BY_TYPE, {Bin}));

handle_client(?MSG_TEAM_GC_APPLY_JOIN, {TeamId}) ->
    %?DEBUG_LOG("TeamId--------------------------------:~p",[TeamId]),
    case team_svr:apply_join_team(TeamId) of
        ok ->
            %?DEBUG_LOG("MSG_TEAM_GC_APPLY_JOIN---1"),
            ?player_send(team_sproto:pkg_msg(?MSG_TEAM_GC_APPLY_JOIN, {1}));
        {auto_pass, ok} ->
            %?DEBUG_LOG("MSG_TEAM_GC_APPLY_JOIN---2"),
            ?player_send(team_sproto:pkg_msg(?MSG_TEAM_GC_APPLY_JOIN, {1}));
        {auto_pass, {error, Err}} ->
            ?return_err(Err);
        _ ->
            ?return_err(?ERR_TEAM_INS_ROOM_NOT_EXIST)
    end;

handle_client(?MSG_TEAM_GC_SHENQING_LIST, {}) ->
    %?DEBUG_LOG("MSG_TEAM_GC_SHENQING_LIST---------------------------"),
    TeamId = get(?pd_team_id),
    case team_svr:get_team_shenqing_list_info(TeamId) of
        {error, Err} ->
            ?return_err(Err);
        Bin ->
            ?player_send(team_sproto:pkg_msg(?MSG_TEAM_GC_SHENQING_LIST, {Bin}))
    end;

handle_client(?MSG_TEAM_GC_DEAL_SHENQING, {DoType, PlayerId}) ->
    %?DEBUG_LOG("DoType-----------:~p----PlayerId-----:~p",[DoType, PlayerId]),
    TeamId = get(?pd_team_id),
    case team_svr:leader_deal_shenqing_list(TeamId, PlayerId, DoType) of
        ok ->
            ?player_send(team_sproto:pkg_msg(?MSG_TEAM_GC_DEAL_SHENQING, {1}));
        {error, Err} ->
            ?return_err(Err);
        _E ->
            ?DEBUG_LOG("_E_--------------------------------:~p",[_E])
    end;

handle_client(?MSG_TEAM_GC_JOIN_MY_TAEA, {Size, PlayerBin}) ->
    PlayerList = util:pkg_player_bin(PlayerBin, Size, []),
    %?DEBUG_LOG("PlayerList----------------------:~p",[PlayerList]),
    case get(?pd_team_id) of
        ?undefined ->
            ?ERROR_LOG("not find team id --------------------");
        TeamId ->
            TeamName = team_svr:get_team_name(TeamId),
            %?DEBUG_LOG("TeamName--------:~p--------TeamId----:~p",[TeamName, TeamId]),
            world:send_to_player_if_online(PlayerList,
            ?to_client_msg(team_sproto:pkg_msg(?MSG_TEAM_GC_NOTICE_JOIN_MY_TEAM_OF_PLAYERS, {TeamId, TeamName})))
    end;

handle_client(?MSG_TEAM_GC_FAST_JOIN, {TeamType}) ->
    %?DEBUG_LOG("Fast join --------------------------------"),
    case team_svr:fast_join(TeamType) of
        {error, Err} ->
            ?return_err(Err);
        _ ->
            pass
    end;

handle_client(?MSG_TEAM_AUTO_JOIN_FLG, {Flg}) ->
    %?DEBUG_LOG("MSG_TEAM_AUTO_JOIN_FLG join --------------------------------"),
    TeamId = get(?pd_team_id),
    case team_svr:is_leader(get(?pd_id)) of
        ?true ->
            %?DEBUG_LOG("Flg---------------------------:~p",[Flg]),
            team_svr:update_team_flg(TeamId, Flg);
        _ ->
            ?return_err(?ERR_TEAM_NOT_LEADER)
    end;

handle_client(?MSG_TEAM_QUIT, {}) ->
    %?DEBUG_LOG("MSG_TEAM_QUIT------------------------------"),
    case team_mod:quit() of
        {error, Err} ->
            ?return_err(Err);
        _ ->
            pass
    end;

handle_client(?MSG_TEAM_KICKOUT, {PlayerId}) ->
    %?DEBUG_LOG("MSG_TEAM_KICKOUT------------------------------:~p",[PlayerId]),
    case team_mod:kickout(PlayerId) of
        {error, Err} ->
            ?return_err(Err);
        _ ->
            pass
    end;

handle_client(?MSG_TEAM_GC_RE, {IsOk}) ->
    %gwgc_server:update_player_to_broadcast_list(1, IsOk),
    ok;

handle_client(?MSG_TEAM_JOIN, {TeamId}) ->
    %?DEBUG_LOG("MSG_TEAM_JOIN----------------------:~p",[TeamId]),
    team_mod:join(TeamId);
handle_client(?MSG_TEAM_DISSOLVE, {}) ->
    case team_mod:disband() of
        {error, Err} ->
            ?return_err(Err);
        _ ->
            pass
    end;

handle_client(?MSG_TEAM_REFUSE_ASK, {TeamId}) ->
    LeaderPlayerId = team_svr:get_leader_by_teamid(TeamId),
    [Name] = player:lookup_info(LeaderPlayerId, [?pd_name]),
    world:send_to_player_if_online(LeaderPlayerId, ?to_client_msg(team_sproto:pkg_msg(?MSG_TEAM_NOTICE_MASTER_REFUSE_ASK, {Name})));

handle_client(?MSG_TEAM_INVITE, {PlayerId, Type, SceneId}) ->
    SelfId = get(?pd_id),
    Name = get(?pd_name),
    PlayerName = player:lookup_info(PlayerId, ?pd_name),
    case is_can_invite(SelfId, Type) of
        true ->
            IsInMainTown = api:player_is_in_normalRoom(PlayerId),
            case SelfId =/= PlayerId andalso IsInMainTown =:= ?TRUE of
                true ->
                    case is_player_in_team(PlayerId) of
                        true ->
                            ?player_send(team_sproto:pkg_msg(?MSG_TEAM_INVITE_RESULT, {PlayerId, PlayerName, 3}));
                        _ ->
                            world:send_to_player_if_online(PlayerId, ?to_client_msg(team_sproto:pkg_msg(?MSG_TEAM_BE_INVITE, {SelfId, Name, Type, SceneId})))
                    end;
                _ ->
                    ?player_send(team_sproto:pkg_msg(?MSG_TEAM_INVITE_RESULT, {PlayerId, PlayerName, 2}))
            end;
        _ ->
            pass
    end;

handle_client(?MSG_TEAM_HANDLE_INVITE, {PlayerId, Type, SceneId, Result}) ->
    Ret = case Result of
        1 ->
            case is_player_in_team(get(?pd_id)) of
                true -> 7;
                _ ->
                    case api:player_is_in_normalRoom(get(?pd_id)) of
                        ?TRUE ->
                            case PlayerId =:= get(?pd_id) of
                                true -> 6;
                                _ ->
                                    case Type of
                                        ?TEAM_TYPE_MAIN_INS ->
                                            case main_ins_mod:can_get_prize_from_room(SceneId) of
                                                true ->
                                                    case join_team(PlayerId, Type, SceneId) of
                                                        ok -> 1;
                                                        {error, lev_beyond} -> 3;
                                                        _ -> 2
                                                    end;
                                                {_, max_count} -> 4;
                                                {_, sp_not_enough} -> 5;
                                                _ -> 2
                                            end;
                                        _ ->
                                            case join_team(PlayerId, Type, SceneId) of
                                                ok -> 1;
                                                _ -> 2
                                            end
                                    end
                            end;
                        _ ->
                            6
                    end
            end;
        _ ->
            Result
    end,
    ?player_send(team_sproto:pkg_msg(?MSG_TEAM_HANDLE_INVITE, {Ret}));

%% 发送队伍召唤消息（类型为1,2,3,4转到世界聊天模块类型为3,4,5,6）
handle_client(?MSG_TEAM_CALL_TEAMMATE, {Type, SceneId}) ->
    chat_mng:send_team_world_msg(Type + 2, integer_to_binary(SceneId));

%% 获取队伍大厅信息
handle_client(?MSG_TEAM_GET_ALL_INFO, {Type, SceneId}) ->
    case Type of
        ?TEAM_TYPE_MAIN_INS ->
            TeamInfoList = main_ins_team_mod:get_all_team_info(get(?pd_level), Type, SceneId),
            MsgList = pack_teams_info(TeamInfoList),
            ?player_send(team_sproto:pkg_msg(?MSG_TEAM_GET_ALL_INFO, {MsgList}));
        ?TEAM_TYPE_GONGCHENG ->
            MsgList = team_svr:get_team_list_info1(Type),
            ?player_send(team_sproto:pkg_msg(?MSG_TEAM_GET_ALL_INFO, {MsgList}));
        _ ->
            ?player_send(team_sproto:pkg_msg(?MSG_TEAM_GET_ALL_INFO, {[]}))
    end;

handle_client(Mod, Msg) ->
    ?ERROR_LOG("no known msg Mod:~p Msg:~p", [team_sproto:to_s(Mod), Msg]).

handle_msg(_, {put_team_id_to_player_process, TeamId}) ->
    put(?pd_team_id, TeamId);

handle_msg(FromMod, Msg) ->
    ?ERROR_LOG("~p recv a unknown msg ~p from ~p", [?pname(), Msg, FromMod]).


%% 广播一条消息给队伍所有的在线玩家
broadcast(Msg) ->
    TeamPlayerPidList = get_team_player_pid_list(get(?pd_id)),
    case TeamPlayerPidList of
        [] ->
            pass;
        _ ->
            [PlayerPid ! Msg || PlayerPid <- TeamPlayerPidList]
    end.

%% 获得队伍中所有玩家的进程Id
get_team_player_pid_list(PlayerId) ->
    case team_server:get_team_info(PlayerId, 2) of
        {ok, TeamInfo1} ->
            Members1 = TeamInfo1#team_info.members,
            [world:get_player_pid(M1#member_info.player_id) || M1 <- Members1];
        _ ->
            case team_svr:get_team_id_by_player(PlayerId) of
                TeamId when is_integer(TeamId) ->
                    case team_svr:get_team_info(TeamId) of
                        ?none -> [];
                        TeamInfo2 ->
                            Members2 = TeamInfo2#team.members,
                            [world:get_player_pid(M2#team_member.id) || M2 <- Members2]
                    end;
                _ ->
                    []
            end
    end.

is_can_invite(PlayerId, Type) ->
    case Type of
        ?TEAM_TYPE_MAIN_INS ->
            team_server:is_team_master(PlayerId, Type);
        ?TEAM_TYPE_GONGCHENG ->
            team_svr:is_leader(PlayerId);
        _ ->
            false
    end.

is_player_in_team(PlayerId) ->
    case team_server:is_player_in_team(PlayerId) of
        true ->
            true;
        _ ->
            case playerid2teamid(PlayerId) of
                TeamId when is_integer(TeamId) -> true;
                _ -> false
            end
    end.

join_team(MasterId, Type, SceneId) ->
    case Type of
        ?TEAM_TYPE_MULTI_ARENA ->
            arena_m_p2p:join_team(MasterId, Type, 0);
        ?TEAM_TYPE_MAIN_INS ->
            main_ins_team_mod:join_team(MasterId, Type, SceneId);
        ?TEAM_TYPE_GONGCHENG ->
            case playerid2teamid(MasterId) of
                ?undefined ->
                    {error, error_type};
                TeamId ->
                    team_mod:join(TeamId)
            end;
        4 ->    %% 单人竞技场
            arena_p2p:challenge_player(MasterId);
        _ ->
            ?ERROR_LOG("error, bad_type master_id:~p, type:~p, scene_id:~p", [MasterId, Type, SceneId]),
            {error, error_type}
    end.

pack_teams_info(TeamInfoList) ->
    lists:foldl(
        fun(TeamInfo, Acc) ->
                TeamId = TeamInfo#team_info.id,
                TeamName = <<>>,
                MasterId = TeamInfo#team_info.master_id,
                Members = TeamInfo#team_info.members,
                MemberList = [{PlayerId, PlayerName, Job, Lev, Power} || #member_info{player_id = PlayerId, name = PlayerName, career = Job, level = Lev, combar_power = Power} <- Members],
                [{TeamId, TeamName, MasterId, MemberList} | Acc]
        end,
        [],
        TeamInfoList
    ).

