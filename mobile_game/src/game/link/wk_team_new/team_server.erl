%%-----------------------------------
%% @Module  : team_server
%% @Author  : Holtom
%% @Email   : 
%% @Created : 2016.4.15
%% @Description: team_gen_server
%%-----------------------------------
-module(team_server).
-behaviour(gen_server).

-include("inc.hrl").
-include("team.hrl").
-include("player.hrl").

-record(team_state,
{
    cur_id = 0,
    matching_list = [],
    player_team_list = [],
    team_type_list = []
}).

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
        create_team/4,              %% 创建队伍
        dissolve_team/2,            %% 解散队伍
        quick_join/3,               %% 快速加入队伍
        leave_team/2,               %% 离开队伍
        kickout_member/3,           %% 踢出成员
        team_start/2,               %% 队伍开始
        get_team_id/2,              %% 获取队伍id
        get_team_info/2,            %% 获取队伍信息
        get_team_info_by_team_id/2, %% 获取队伍信息
        get_team_members/2,         %% 获取队伍成员
        insert_new_scene/3,         %% 加入新场景到场景列表
        is_team_master/2,           %% 是否是队长
        change_team_master_except_this/3,   %% 改变队伍队长
        set_team_master/3,          %% 指定为队伍队长
        try_get_matching_team/2,    %% 获取匹配队伍
        get_exist_match_team/2,     %% 获取匹配到的队伍
        join_team/4,                %% 加入队伍
        is_player_in_team/1,        %% 玩家是否已在队五中
        get_team_info_by_scene_id/3 %% 通过副本id获取可加入的队伍信息
    ]).

%% =================================================================== 
%% Module Interface
%% ===================================================================
start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

create_team(MemberInfo, SceneCfgId, MaxMembers, Type) ->
    case lists:member(Type, ?TEAM_TYPES) of
        true ->
            gen_server:call(?MODULE, {'CREATE_TEAM', MemberInfo, SceneCfgId, MaxMembers, Type});
        _ ->
            ?ERROR_LOG("error unknown team type :~p", [Type])
    end.

dissolve_team(TeamId, Type) ->
    case lists:member(Type, ?TEAM_TYPES) of
        true ->
            gen_server:call(?MODULE, {'DISSOLVE_TEAM', TeamId, Type});
        _ ->
            ?ERROR_LOG("error unknown team type :~p", [Type])
    end.

quick_join(MemberInfo, SceneCfgId, Type) ->
    case lists:member(Type, ?TEAM_TYPES) of
        true ->
            gen_server:call(?MODULE, {'QUICK_JOIN', MemberInfo, SceneCfgId, Type});
        _ ->
            ?ERROR_LOG("error unknown team type :~p", [Type])
    end.

leave_team(PlayerId, Type) ->
    case lists:member(Type, ?TEAM_TYPES) of
        true ->
            gen_server:call(?MODULE, {'LEAVE_TEAM', PlayerId, Type});
        _ ->
            ?ERROR_LOG("error unknown team type :~p", [Type])
    end.

kickout_member(PlayerId, OutId, Type) ->
    case lists:member(Type, ?TEAM_TYPES) of
        true ->
            gen_server:call(?MODULE, {'KICKOUT_MEMBER', PlayerId, OutId, Type});
        _ ->
            ?ERROR_LOG("error unknown team type :~p", [Type])
    end.

team_start(TeamId, Type) ->
    case lists:member(Type, ?TEAM_TYPES) of
        true ->
            gen_server:cast(?MODULE, {'TEAM_START', TeamId, Type});
        _ ->
            ?ERROR_LOG("error unknown team type :~p", [Type])
    end.

get_team_id(PlayerId, Type) ->
    case lists:member(Type, ?TEAM_TYPES) of
        true ->
            gen_server:call(?MODULE, {'GET_TEAM_ID', PlayerId, Type});
        _ ->
            ?ERROR_LOG("error unknown team type :~p", [Type])
    end.

get_team_info(PlayerId, Type) ->
    case lists:member(Type, ?TEAM_TYPES) of
        true ->
            gen_server:call(?MODULE, {'GET_TEAM_INFO', PlayerId, Type});
        _ ->
            ?ERROR_LOG("error unknown team type :~p", [Type])
    end.

get_team_info_by_team_id(TeamId, Type) ->
    case lists:member(Type, ?TEAM_TYPES) of
        true ->
            gen_server:call(?MODULE, {'GET_TEAM_INFO_BY_TEAM_ID', TeamId, Type});
        _ ->
            ?ERROR_LOG("error unknown team type :~p", [Type])
    end.

get_team_members(TeamId, Type) ->
    case lists:member(Type, ?TEAM_TYPES) of
        true ->
            gen_server:call(?MODULE, {'GET_TEAM_MEMBERS', TeamId, Type});
        _ ->
            ?ERROR_LOG("error unknown team type :~p", [Type])
    end.

insert_new_scene(TeamId, SceneId, Type) ->
    case lists:member(Type, ?TEAM_TYPES) of
        true ->
            gen_server:cast(?MODULE, {'INSERT_NEW_SCENE', TeamId, SceneId, Type});
        _ ->
            ?ERROR_LOG("error unknown team type :~p", [Type])
    end.

is_team_master(PlayerId, Type) ->
    case lists:member(Type, ?TEAM_TYPES) of
        true ->
            gen_server:call(?MODULE, {'IS_TEAM_MASTER', PlayerId, Type});
        _ ->
            ?ERROR_LOG("error unknown team type :~p", [Type])
    end.

change_team_master_except_this(TeamId, PlayerId, Type) ->
    case lists:member(Type, ?TEAM_TYPES) of
        true ->
            gen_server:call(?MODULE, {'CHANGE_TEAM_MASTER_EXCEPT_THIS', TeamId, PlayerId, Type});
        _ ->
            ?ERROR_LOG("error unknown team type :~p", [Type])
    end.

set_team_master(PlayerId, TeamId, Type) ->
    case lists:member(Type, ?TEAM_TYPES) of
        true ->
            gen_server:cast(?MODULE, {'SET_TEAM_MASTER', PlayerId, TeamId, Type});
        _ ->
            ?ERROR_LOG("error unknown team type :~p", [Type])
    end.

try_get_matching_team(TeamId, Type) ->
    case lists:member(Type, ?TEAM_TYPES) of
        true ->
            gen_server:call(?MODULE, {'TRY_GET_MATCHING_TEAM', TeamId, Type});
        _ ->
            ?ERROR_LOG("error unknown team type :~p", [Type])
    end.

get_exist_match_team(TeamId, Type) ->
    case lists:member(Type, ?TEAM_TYPES) of
        true ->
            gen_server:call(?MODULE, {'GET_EXIST_MATCH_TEAM', TeamId, Type});
        _ ->
            ?ERROR_LOG("error unknown team type :~p", [Type])
    end.

join_team(MemberInfo, TeamId, Type, SceneId) ->
    case lists:member(Type, ?TEAM_TYPES) of
        true ->
            gen_server:call(?MODULE, {'JOIN_TEAM', MemberInfo, TeamId, Type, SceneId});
        _ ->
            ?ERROR_LOG("error unknown team type :~p", [Type])
    end.

is_player_in_team(PlayerId) ->
    gen_server:call(?MODULE, {'IS_PLAYER_IN_TEAM', PlayerId}).

get_team_info_by_scene_id(PlayerLev, Type, SceneId) ->
    case lists:member(Type, ?TEAM_TYPES) of
        true ->
            gen_server:call(?MODULE, {'GET_TEAM_INFO_BY_SCENE_ID', PlayerLev, Type, SceneId});
        _ ->
            ?ERROR_LOG("error unknown team type :~p", [Type])
    end.

%% ===================================================================
%% gen_server callbacks
%% ===================================================================
init([]) ->
    com_process:init_name(<<"team_server">>),
    com_process:init_type(?MODULE),
    {ok, #team_state{}}.

handle_call({'CREATE_TEAM', MemberInfo, SceneCfgId, MaxMembers, Type}, _From, #team_state{cur_id = CurId} = State) ->
    PlayerTeamList = State#team_state.player_team_list,
    TeamTypeList = State#team_state.team_type_list,
    PlayerId = MemberInfo#member_info.player_id,
    {Reply, NewState} = case is_already_in_team(Type, PlayerId, PlayerTeamList) of
        true ->
            {{error, already_in_team}, State};
        _ ->
            TeamInfo = new_team(CurId + 1, MemberInfo, SceneCfgId, MaxMembers, Type),
            TeamId = TeamInfo#team_info.id,
            NewPlayerTeamList = insert_player_team(PlayerTeamList, Type, {PlayerId, TeamId}),
            NewTeamTypeList = insert_team(TeamTypeList, Type, TeamInfo),
            {
                {ok, TeamInfo#team_info.id},
                State#team_state{cur_id = CurId + 1, player_team_list = NewPlayerTeamList, team_type_list = NewTeamTypeList}
            }
    end,
    {reply, Reply, NewState};
handle_call({'DISSOLVE_TEAM', TeamId, Type}, _From, State) ->
    MatchingList = State#team_state.matching_list,
    PlayerTeamList = State#team_state.player_team_list,
    TeamTypeList = State#team_state.team_type_list,
    Members = case get_team_info(TeamId, Type, TeamTypeList) of
        TeamInfo when is_record(TeamInfo, team_info) ->
            TeamInfo#team_info.members;
        W ->
            ?ERROR_LOG("get_team_info error TeamId:~p reason:~p", [TeamId, W]),
            []
    end,
    NewPlayerTeamList = delete_player_team(PlayerTeamList, Type, [Member#member_info.player_id || Member <- Members]),
    NewTeamTypeList = delete_team(TeamTypeList, Type, TeamId),
    NewMatchingList = case lists:keyfind(TeamId, 1, MatchingList) of
        {TeamId, Id} ->
            List1 = lists:keydelete(TeamId, 1, MatchingList),
            lists:keydelete(Id, 1, List1);
        _ ->
            MatchingList
    end,
    NewState = State#team_state{
        matching_list = NewMatchingList,
        player_team_list = NewPlayerTeamList,
        team_type_list = NewTeamTypeList
    },
    {reply, {ok, Members}, NewState};
handle_call({'QUICK_JOIN', MemberInfo, SceneCfgId, Type}, _From, State) ->
    PlayerTeamList = State#team_state.player_team_list,
    TeamTypeList = State#team_state.team_type_list,
    PlayerId = MemberInfo#member_info.player_id,
    PlayerLev = MemberInfo#member_info.level,
    {Reply, NewState} = case is_already_in_team(Type, PlayerId, PlayerTeamList) of
        true ->
            {{error, already_in_team}, State};
        _ ->
            case get_can_join_random_team(SceneCfgId, PlayerLev, Type, TeamTypeList) of
                TeamInfo when is_record(TeamInfo, team_info) ->
                    Members = TeamInfo#team_info.members,
                    NewInfo = TeamInfo#team_info{members = [MemberInfo | Members]},
                    NewPlayerTeamList = insert_player_team(PlayerTeamList, Type, {PlayerId, TeamInfo#team_info.id}),
                    NewTeamTypeList = insert_team(TeamTypeList, Type, NewInfo),
                    {
                        {ok, {TeamInfo#team_info.id, Members}}, 
                        State#team_state{player_team_list = NewPlayerTeamList, team_type_list = NewTeamTypeList}
                    };
                Error ->
                    {Error, State}
            end
    end,
    {reply, Reply, NewState};
handle_call({'LEAVE_TEAM', PlayerId, Type}, _From, State) ->
    MatchingList = State#team_state.matching_list,
    PlayerTeamList = State#team_state.player_team_list,
    TeamTypeList = State#team_state.team_type_list,
    {Reply, NewState} = case is_already_in_team(Type, PlayerId, PlayerTeamList) of
        true ->
            TeamId = get_team_id(PlayerId, Type, PlayerTeamList),
            case get_team_info(TeamId, Type, TeamTypeList) of
                TeamInfo when is_record(TeamInfo, team_info) ->
                    NewPlayerTeamList = delete_player_team(PlayerTeamList, Type, [PlayerId]),
                    Members = TeamInfo#team_info.members,
                    {RetMembers, NewTeamTypeList, NewList} = case length(Members) =:= 1 of
                        true ->
                            NewMatchingList = case lists:keyfind(TeamId, 1, MatchingList) of
                                {TeamId, Id} ->
                                    List1 = lists:keydelete(TeamId, 1, MatchingList),
                                    lists:keydelete(Id, 1, List1);
                                _ ->
                                    MatchingList
                            end,
                            {[], delete_team(TeamTypeList, Type, TeamInfo#team_info.id), NewMatchingList};
                        _ ->
                            {NewMaster, NewMembers} = case TeamInfo#team_info.master_id =:= PlayerId of
                                true ->
                                    Members1 = lists:keydelete(PlayerId, #member_info.player_id, Members),
                                    {(lists:nth(1, Members1))#member_info.player_id, Members1};
                                _ ->
                                    {TeamInfo#team_info.master_id, lists:keydelete(PlayerId, #member_info.player_id, Members)}
                            end,
                            NewTeamInfo = TeamInfo#team_info{
                                id = TeamInfo#team_info.id,
                                master_id = NewMaster,
                                members = NewMembers
                            },
                            TeamTypeList1 = delete_team(TeamTypeList, Type, TeamInfo#team_info.id),
                            {NewMembers, insert_team(TeamTypeList1, Type, NewTeamInfo), MatchingList}
                    end,
                    {
                        {ok, RetMembers},
                        State#team_state{
                            matching_list = NewList,
                            player_team_list = NewPlayerTeamList,
                            team_type_list = NewTeamTypeList
                        }
                    };
                _ ->
                    {{error, not_exist_team}, State}
            end;
        _ ->
            {{error, not_in_team}, State}
    end,
    {reply, Reply, NewState};
handle_call({'KICKOUT_MEMBER', PlayerId, OutId, Type}, _From, State) ->
    PlayerTeamList = State#team_state.player_team_list,
    TeamTypeList = State#team_state.team_type_list,
    {Reply, NewState} = case is_already_in_team(Type, PlayerId, PlayerTeamList) of
        true ->
            TeamId1 = get_team_id(PlayerId, Type, PlayerTeamList),
            TeamId2 = get_team_id(OutId, Type, PlayerTeamList),
            case TeamId1 =:= TeamId2 of
                true ->
                    TeamInfo = get_team_info(TeamId1, Type, TeamTypeList),
                    {NewMembers, NewPlayerTeamList} = case TeamInfo#team_info.master_id =:= PlayerId of
                        true ->
                            {
                                lists:keydelete(OutId, #member_info.player_id, TeamInfo#team_info.members),
                                delete_player_team(PlayerTeamList, Type, [OutId])
                            };
                        _ ->
                            {TeamInfo#team_info.members, PlayerTeamList}
                    end,
                    NewTeamInfo = TeamInfo#team_info{members = NewMembers},
                    TeamTypeList1 = delete_team(TeamTypeList, Type, TeamInfo#team_info.id),
                    TeamTypeList2 = insert_team(TeamTypeList1, Type, NewTeamInfo),
                    {
                        {ok, NewMembers},
                        State#team_state{
                            player_team_list = NewPlayerTeamList,
                            team_type_list = TeamTypeList2
                        }
                    };
                _ ->
                    {{error, not_in_team}, State}
            end;
        _ ->
            {{error, not_in_team}, State}
    end,
    {reply, Reply, NewState};
handle_call({'GET_TEAM_ID', PlayerId, Type}, _From, State) ->
    PlayerTeamList = State#team_state.player_team_list,
    Ret = case get_team_id(PlayerId, Type, PlayerTeamList) of
        Id when is_integer(Id) ->
            {ok, Id};
        Other ->
            {error, Other}
    end,
    {reply, Ret, State};
handle_call({'GET_TEAM_INFO', PlayerId, Type}, _From, State) ->
    PlayerTeamList = State#team_state.player_team_list,
    TeamTypeList = State#team_state.team_type_list,
    Ret = case get_team_id(PlayerId, Type, PlayerTeamList) of
        TeamId when is_integer(TeamId) ->
            case get_team_info(TeamId, Type, TeamTypeList) of
                TeamInfo when is_record(TeamInfo, team_info) ->
                    {ok, TeamInfo};
                Other ->
                    Other
            end;
        _ ->
            {error, none}
    end,
    {reply, Ret, State};
handle_call({'GET_TEAM_INFO_BY_TEAM_ID', TeamId, Type}, _From, State) ->
    TeamTypeList = State#team_state.team_type_list,
    Ret = case get_team_info(TeamId, Type, TeamTypeList) of
        TeamInfo when is_record(TeamInfo, team_info) ->
            {ok, TeamInfo};
        Other ->
            Other
    end,
    {reply, Ret, State};
handle_call({'GET_TEAM_MEMBERS', TeamId, Type}, _From, State) ->
    TeamTypeList = State#team_state.team_type_list,
    Ret = case get_team_info(TeamId, Type, TeamTypeList) of
        TeamInfo when is_record(TeamInfo, team_info) ->
            TeamInfo#team_info.members;
        _ ->
            []
    end,
    {reply, Ret, State};
handle_call({'IS_TEAM_MASTER', PlayerId, Type}, _From, State) ->
    PlayerTeamList = State#team_state.player_team_list,
    TeamTypeList = State#team_state.team_type_list,
    Ret = case get_team_id(PlayerId, Type, PlayerTeamList) of
        TeamId when is_integer(TeamId) ->
            case get_team_info(TeamId, Type, TeamTypeList) of
                TeamInfo when is_record(TeamInfo, team_info) ->
                    TeamInfo#team_info.master_id =:= PlayerId;
                _ ->
                    false
            end;
        _ ->
            false
    end,
    {reply, Ret, State};
handle_call({'CHANGE_TEAM_MASTER_EXCEPT_THIS', TeamId, PlayerId, Type}, _From, State) ->
    TeamTypeList = State#team_state.team_type_list,
    {Ret, NewState} = case get_team_info(TeamId, Type, TeamTypeList) of
        TeamInfo when is_record(TeamInfo, team_info) ->
            Members = TeamInfo#team_info.members,
            case [M#member_info.player_id || M <- Members, M#member_info.player_id =/= PlayerId] of
                [] ->
                    {{error, none}, State};
                [NewId | _] ->
                    NewTeamInfo = TeamInfo#team_info{master_id = NewId},
                    TeamTypeList1 = delete_team(TeamTypeList, Type, TeamId),
                    TeamTypeList2 = insert_team(TeamTypeList1, Type, NewTeamInfo),
                    {{ok, NewId}, State#team_state{team_type_list = TeamTypeList2}}
            end;
        _ ->
            {{error, none}, State}
    end,
    {reply, Ret, NewState};
handle_call({'TRY_GET_MATCHING_TEAM', TeamId, Type}, _From, State) ->
    MatchingList = State#team_state.matching_list,
    TeamTypeList = State#team_state.team_type_list,
    {Ret, NewState} = case lists:keyfind(TeamId, 1, MatchingList) of
        {TeamId, MatchId} ->
            case get_team_info(MatchId, Type, TeamTypeList) of
                TeamInfo when is_record(TeamInfo, team_info) ->
                    {{ok, TeamInfo}, State};
                _ ->
                    ?ERROR_LOG("can not find team_info, team_id:~p", [MatchId]),
                    {{error, none}, State#team_state{matching_list = lists:keydelete(TeamId, 1, MatchingList)}}
            end;
        _ ->
            case get_matching_team_from_list(TeamId, TeamTypeList, MatchingList, Type) of
                TeamInfo when is_record(TeamInfo, team_info) ->
                    {{ok, TeamInfo}, State#team_state{matching_list = MatchingList ++ [{TeamId, TeamInfo#team_info.id}, {TeamInfo#team_info.id, TeamId}]}};
                _ ->
                    {{error, none}, State}
            end
    end,
    {reply, Ret, NewState};
handle_call({'GET_EXIST_MATCH_TEAM', TeamId, Type}, _From, State) ->
    MatchingList = State#team_state.matching_list,
    TeamTypeList = State#team_state.team_type_list,
    {Ret, NewState} = case lists:keyfind(TeamId, 1, MatchingList) of
        {TeamId, MatchId} ->
            case get_team_info(MatchId, Type, TeamTypeList) of
                TeamInfo when is_record(TeamInfo, team_info) ->
                    {{ok, TeamInfo}, State};
                _ ->
                    ?ERROR_LOG("can not find team_info, team_id:~p", [MatchId]),
                    {{error, none}, State#team_state{matching_list = lists:keydelete(TeamId, 1, MatchingList)}}
            end;
        _ ->
            {{error, none}, State}
    end,
    {reply, Ret, NewState};
handle_call({'JOIN_TEAM', MemberInfo, TeamId, Type, SceneId}, _From, State) ->
    PlayerTeamList = State#team_state.player_team_list,
    TeamTypeList = State#team_state.team_type_list,
    PlayerId = MemberInfo#member_info.player_id,
    PlayerLev = MemberInfo#member_info.level,
    {Reply, NewState} = case is_already_in_team(Type, PlayerId, PlayerTeamList) of
        true ->
            {{error, already_in_team}, State};
        _ ->
            case get_team_info(TeamId, Type, TeamTypeList) of
                TeamInfo when is_record(TeamInfo, team_info) ->
                    case is_can_join(TeamInfo, PlayerLev, Type, SceneId) of
                        true ->
                            Members = TeamInfo#team_info.members,
                            NewInfo = TeamInfo#team_info{members = [MemberInfo | Members]},
                            NewPlayerTeamList = insert_player_team(PlayerTeamList, Type, {PlayerId, TeamInfo#team_info.id}),
                            NewTeamTypeList = insert_team(TeamTypeList, Type, NewInfo),
                            {
                                {ok, {TeamId, Members}},
                                State#team_state{player_team_list = NewPlayerTeamList, team_type_list = NewTeamTypeList}
                            };
                        {false, E} ->
                            {{error, E}, State};
                        _ ->
                            {{error, not_exist_team}, State}
                    end;
                _ ->
                    {{error, not_exist_team}, State}
            end
    end,
    {reply, Reply, NewState};
handle_call({'IS_PLAYER_IN_TEAM', PlayerId}, _From, State) ->
    PlayerTeamList = State#team_state.player_team_list,
    Ret = lists:foldl(
        fun(Type, Acc) ->
                case lists:keyfind(Type, 1, PlayerTeamList) of
                    {Type, PlayerList} ->
                        case lists:keyfind(PlayerId, 1, PlayerList) of
                            {PlayerId, _TeamId} -> true;
                            _ -> false orelse Acc
                        end;
                    _ ->
                        false orelse Acc
                end
        end,
        false,
        ?TEAM_TYPES
    ),
    {reply, Ret, State};
handle_call({'GET_TEAM_INFO_BY_SCENE_ID', PlayerLev, Type, SceneId}, _From, State) ->
    TeamTypeList = State#team_state.team_type_list,
    TeamList = get_can_join_all_teams(SceneId, PlayerLev, Type, TeamTypeList),
    {reply, TeamList, State};
handle_call(_Request, _From, State) ->
    ?ERROR_LOG("receive unknown call msg:~p", [_Request]),
    {reply, ok, State}.

handle_cast({'TEAM_START', TeamId, Type}, State) ->
    TeamTypeList = State#team_state.team_type_list,
    TeamInfo = get_team_info(TeamId, Type, TeamTypeList),
    NewTeamInfo = TeamInfo#team_info{state = ?TEAM_STATE_START, start_time = com_time:now()},
    TeamTypeList1 = delete_team(TeamTypeList, Type, TeamInfo#team_info.id),
    TeamTypeList2 = insert_team(TeamTypeList1, Type, NewTeamInfo),
    {noreply, State#team_state{team_type_list = TeamTypeList2}};
handle_cast({'INSERT_NEW_SCENE', TeamId, SceneId, Type}, State) ->
    TeamTypeList = State#team_state.team_type_list,
    NewState = case get_team_info(TeamId, Type, TeamTypeList) of
        TeamInfo when is_record(TeamInfo, team_info) ->
            SceneIdList = TeamInfo#team_info.scene_id_list,
            case lists:member(SceneId, SceneIdList) of
                true ->
                    State;
                _ ->
                    NewTeamInfo = TeamInfo#team_info{scene_id_list = SceneIdList ++ [SceneId]},
                    TeamTypeList1 = delete_team(TeamTypeList, Type, TeamInfo#team_info.id),
                    TeamTypeList2 = insert_team(TeamTypeList1, Type, NewTeamInfo),
                    State#team_state{team_type_list = TeamTypeList2}
            end;
        _ ->
            State
    end,
    {noreply, NewState};
handle_cast({'SET_TEAM_MASTER', PlayerId, TeamId, Type}, State) ->
    TeamTypeList = State#team_state.team_type_list,
    NewState = case get_team_info(TeamId, Type, TeamTypeList) of
        TeamInfo when is_record(TeamInfo, team_info) ->
            NewTeamInfo = TeamInfo#team_info{master_id = PlayerId},
            TeamTypeList1 = delete_team(TeamTypeList, Type, TeamId),
            TeamTypeList2 = insert_team(TeamTypeList1, Type, NewTeamInfo),
            State#team_state{team_type_list = TeamTypeList2};
        _ ->
            State
    end,
    {noreply, NewState};
handle_cast(_Msg, State) ->
    ?ERROR_LOG("receive unknown cast msg:~p", [_Msg]),
    {noreply, State}.

handle_info(_Info, State) ->
    handle_cast(_Info, State). %% 跨服调用走的是info过程， 这里兼容下。

terminate(_Reason, _State) ->
    ?INFO_LOG("process shutdown with reason = ~p", [_Reason]),
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% =====================================================================
%% private
%% =====================================================================
is_already_in_team(Type, PlayerId, PlayerTeamList) ->
    case lists:keyfind(Type, 1, PlayerTeamList) of
        {Type, PlayerList} ->
            case lists:keyfind(PlayerId, 1, PlayerList) of
                {PlayerId, _} ->
                    true;
                _ ->
                    false
            end;
        _ ->
            false
    end.

new_team(Id, MemberInfo, SceneCfgId, MaxMembers, _Type) ->
    #team_info{
        % id = gen_id:next_id(team_ins),
        id = Id,
        master_id = MemberInfo#member_info.player_id,
        max_member_num = MaxMembers,
        members = [MemberInfo],
        scene_id_list = [SceneCfgId]
    }.

insert_player_team(PlayerTeamList, Type, Element) ->
    case lists:keyfind(Type, 1, PlayerTeamList) of
        {Type, PlayerList} ->
            case lists:member(Element, PlayerList) of
                true ->
                    PlayerTeamList;
                _ ->
                    lists:keyreplace(Type, 1, PlayerTeamList, {Type, [Element] ++ PlayerList})
            end;
        _ ->
            [{Type, [Element]} | PlayerTeamList]
    end.

delete_player_team(List, _, []) -> List;
delete_player_team(PlayerTeamList, Type, [PlayerId | Res]) ->
    case lists:keyfind(Type, 1, PlayerTeamList) of
        {Type, PlayerList} ->
            NewList = lists:keydelete(PlayerId, 1, PlayerList),
            NewList1 = lists:keyreplace(Type, 1, PlayerTeamList, {Type, NewList}),
            delete_player_team(NewList1, Type, Res);
        _ ->
            PlayerTeamList
    end.

insert_team(TeamTypeList, Type, TeamInfo) ->
    case lists:keyfind(Type, 1, TeamTypeList) of
        {Type, TeamList} ->
            TeamId = TeamInfo#team_info.id,
            NewList = case lists:keyfind(TeamId, #team_info.id, TeamList) of
                OldTeamInfo when is_record(OldTeamInfo, team_info) ->
                    lists:keyreplace(TeamId, #team_info.id, TeamList, TeamInfo);
                _ ->
                    [TeamInfo | TeamList]
            end,
            lists:keyreplace(Type, 1, TeamTypeList, {Type, NewList});
        _ ->
            [{Type, [TeamInfo]} | TeamTypeList]
    end.

delete_team(TeamTypeList, Type, TeamId) ->
    case lists:keyfind(Type, 1, TeamTypeList) of
        {Type, TeamList} ->
            NewList = lists:keydelete(TeamId, #team_info.id, TeamList),
            case NewList of
                [] ->
                    lists:keydelete(Type, 1, TeamTypeList);
                _ ->
                    lists:keyreplace(Type, 1, TeamTypeList, {Type, NewList})
            end;
        _ ->
            TeamTypeList
    end.

get_team_id(PlayerId, Type, PlayerTeamList) ->
    case lists:keyfind(Type, 1, PlayerTeamList) of
        {Type, PlayerList} ->
            case lists:keyfind(PlayerId, 1, PlayerList) of
                {PlayerId, TeamId} ->
                    TeamId;
                _ ->
                    none
            end;
        _ ->
            none
    end.

get_team_info(TeamId, Type, TeamTypeList) ->
    case lists:keyfind(Type, 1, TeamTypeList) of
        {Type, TeamList} ->
            case lists:keyfind(TeamId, #team_info.id, TeamList) of
                TeamInfo when is_record(TeamInfo, team_info) ->
                    TeamInfo;
                _ ->
                    {error, not_exist_team}
            end;
        _ ->
            {error, not_exist_team}
    end.

get_can_join_random_team(SceneCfgId, PlayerLev, Type, TeamTypeList) ->
    case lists:keyfind(Type, 1, TeamTypeList) of
        {Type, TeamList} ->
            CanJoinTeams = lists:filter(
                fun(TeamInfo) ->
                        is_can_join(TeamInfo, PlayerLev, Type, SceneCfgId)
                end,
                TeamList
            ),
            case CanJoinTeams of
                [] ->
                    {error, not_can_join_team};
                [Team] ->
                    case Type of
                        ?TEAM_TYPE_MULTI_ARENA ->
                            case lists:filter(
                                fun(#team_info{max_member_num = MMN, members = ML, state = TeamState}) ->
                                        length(ML) =:= MMN andalso TeamState =:= ?TEAM_STATE_WAIT
                                end,
                                TeamList
                            ) of
                                [] ->
                                    case com_util:random(0, 1) of
                                        1 -> Team;
                                        _ -> {error, not_can_join_team}
                                    end;
                                _ ->
                                    Team
                            end;
                        _ ->
                            RandomNum = com_util:random(1, length(CanJoinTeams)),
                            lists:nth(RandomNum, CanJoinTeams)
                    end;
                _ ->
                    RandomNum = com_util:random(1, length(CanJoinTeams)),
                    lists:nth(RandomNum, CanJoinTeams)
            end;
        _ ->
            {error, not_can_join_team}
    end.

get_can_join_all_teams(SceneId, PlayerLev, Type, TeamTypeList) ->
    case lists:keyfind(Type, 1, TeamTypeList) of
        {Type, TeamList} ->
            lists:filter(
                fun(TeamInfo) ->
                        is_can_join(TeamInfo, PlayerLev, Type, SceneId)
                end,
                TeamList
            );
        _ ->
            []
    end.

get_matching_team_from_list(TeamId, TeamTypeList, MatchList, Type) ->
    Teams = case lists:keyfind(Type, 1, TeamTypeList) of
        {Type, TeamList} ->
            lists:filter(
                fun(#team_info{id = Id, state = TeamState}) ->
                    TeamId =/= Id andalso TeamState =:= ?TEAM_STATE_WAIT andalso lists:keyfind(Id, 1, MatchList) =:= false
                end,
                TeamList
            );
        _ ->
            []
    end,
    case Teams of
        [] ->
            {error, not_can_match_team};
        _ ->
            RandomNum = com_util:random(1, length(Teams)),
            lists:nth(RandomNum, Teams)
    end.

is_can_join(#team_info{max_member_num = MMN, members = ML, scene_id_list = SceneIdList, state = TeamState}, PlayerLev, Type, SceneId) ->
    case Type of
        ?TEAM_TYPE_MAIN_INS ->
            %% 组队副本类型，匹配规则：最大等级与最小等级不能超过20级
            case length(ML) < MMN andalso [SceneId] =:= SceneIdList andalso TeamState =:= ?TEAM_STATE_WAIT of
                true ->
                    case length(ML) of
                        1 ->
                            [#member_info{level = MasterLevel}] = ML,
                            erlang:abs(MasterLevel - PlayerLev) =< 20;
                        2 ->
                            [#member_info{level = Lev1}, #member_info{level = Lev2}] = ML,
                            max(Lev1, Lev2) - 20 =< PlayerLev andalso min(Lev1, Lev2) + 20 >= PlayerLev;
                        _ ->
                            {false, lev_beyond}
                    end;
                _ ->
                    false
            end;
        _ ->
            length(ML) < MMN andalso TeamState =:= ?TEAM_STATE_WAIT
    end.
