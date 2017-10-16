%%% coding:utf-8
%%%-------------------------------------------------------------------
%%% @author zl
%%% @doc 一个可替换的AOI 管理模块
%%%
%%%
%%%   所有对象的aoi 存在
%%%   {idx, aoi} key 的pd 中
%%%   
%%%   block 
%%%   vblock 是大小相同的地图块
%%%
%%%       
%%% @end
%%%-------------------------------------------------------------------

-module(map_aoi).

-export(
[
    stop_if_moving/1
    , stop_if_moving_and_notify/1
    , stop_moving_and_sync_position/2

    , broadcast_view_block_agnets/2
    , broadcast_view_me_agnets/2
    , broadcast_view_me_agnets_and_me/2

    , broadcast_create/1
    , broadcast_delete/1
    , broadcast_all_create/1
    , broadcast_postion/3
    , broadcast_except_main_client_if_monster/2
    , reset_view_agent/1
    % , broadcast_near_msg_exclude_me/2
]).

%% cb
-export(
[
    init/2
]).



-include("inc.hrl").
-include("scene.hrl").
-include("scene_agent.hrl").
-include("team.hrl").


-define(MAX_SCENE_LIMIT, 100).


init(W, H) -> map_observers:init(W, H).

-spec stop_if_moving(#agent{}) -> #agent{}.
stop_if_moving(#agent{idx = Idx} = Agent) ->
    MV4 = move_tgr_util:stop_all_move_tgr(Agent#agent.move_vec),
    H = Agent#agent.h,
    Agent1 = Agent#agent{move_vec = MV4},
    if
        H > 0 -> move_h_tgr:start_freely_fall(Agent1);
        true -> Agent1
    end,
    ?update_agent(Idx, Agent1),
    Agent1.

-spec stop_if_moving_and_notify(#agent{}) -> #agent{}.
stop_if_moving_and_notify(#agent{idx = Idx} = _A) ->
    A = stop_if_moving(_A),
    ?update_agent(Idx, A),
    broadcast_except_main_client_if_monster(A, scene_sproto:pkg_msg(?MSG_SCENE_MOVE_STOP, {Idx, A#agent.x, A#agent.y, A#agent.h})),
    A.


-spec stop_moving_and_sync_position(_, _) -> #agent{}.
stop_moving_and_sync_position(#agent{x = X, y = Y} = _A, {SX, SY, SH}) ->
    A = stop_if_moving(_A),
    if
        X =/= SX orelse Y =/= SY ->
            map_agent:set_position(A, {SX, SY, SH});
        true ->
            A
    end.

% broadcast_near_msg_exclude_me(#agent{idx = MeIdx}, Msg) ->
%     List = get_near_players(MeIdx),
%     lists:foreach(
%         fun(Idx) when Idx > 0 andalso Idx =/= MeIdx ->
%                 case ?get_agent(Idx) of
%                     ?undefined -> ok;
%                     Agent -> ?send_to_client(Agent#agent.pid, Msg)
%                 end;
%             (_) ->
%                 ok
%         end,
%         List
%     ).

broadcast_view_block_agnets(_BlockId, _Msg) -> ok.
    % ObserverList = scene_player:get_all_player_idx(),
    % lists:foreach(
    %     fun(Idx) when Idx > 0 ->
    %             case ?get_agent(Idx) of
    %                 #agent{} = Agent -> ?send_to_client(Agent#agent.pid, Msg);
    %                 _ -> ok
    %             end;
    %         (_) ->
    %             ok
    %     end,
    %     ObserverList
    % ).

broadcast_view_me_agnets(#agent{id = MeIdx}, Msg) ->
    List0 = scene_player:get_all_player_idx(),
    List = lists:sublist(List0, 1, 100),
    lists:foreach
    (
        fun
            (Idx) when Idx > 0 andalso Idx =/= MeIdx ->
                case ?get_agent(Idx) of
                    ?undefined -> ok;
                    Agent -> ?send_to_client( Agent#agent.pid, Msg )
                end;

            (_Error) ->
                ok
        end,
        List
    ).

broadcast_view_me_agnets_and_me(#agent{idx = Idx, pid = Pid} = Agent, Msg) ->
    if
        Idx > 0 -> ?send_to_client(Pid, Msg);
        true -> pass
    end,
    broadcast_view_me_agnets(Agent, Msg).

broadcast_all_create(#agent{idx = Idx}) ->
    PlayerList = get_near_players(Idx),
    a_see_b(PlayerList, [Idx]),
    UnPlayerList = scene_player:get_all_unplayer_idx(),
    a_see_b([Idx], PlayerList ++ UnPlayerList).

broadcast_create(#agent{idx = Idx, p_block_id = PBlockId, view_blocks = VBs} = _Agent) ->
    ObserverList = map_observers:get_player_by_blockid(PBlockId),
    a_see_b(ObserverList, [Idx]),
    BlockAgentList = map_block:get_window_agents(VBs),
    a_see_b([Idx], BlockAgentList).

broadcast_delete(#agent{idx = Idx, p_block_id = PBlockId, view_blocks = _VBs} = _Agent) ->
    %?INFO_LOG("broadcast_delete ~p", [{Idx}]),
    ObserverList = map_observers:get_player_by_blockid(PBlockId),
    a_unseen_b(ObserverList, [Idx]).
    %%     BlockAgentList = map_block:get_window_agents(VBs),
    %%     a_unseen_b([Idx], BlockAgentList).


broadcast_postion(#agent{idx = Idx} = _Agent, {FromBlockID, OldVBs}, {ToBlockID, NewVBs}) ->
    %% 其它人看我
    if
        FromBlockID =/= ToBlockID ->
            case map_observers:get_osn_of_block_agents(FromBlockID, ToBlockID) of
                same ->
                    ret:ok();
                {[], _, []} ->
                    ret:ok();
                {ExitPlayers, _, EnterPlayers} ->
                    a_unseen_b(ExitPlayers, [Idx]),
                    a_see_b(EnterPlayers, [Idx]);
                _ ->
                    ?INFO_LOG("failed in broadcast_move")
            end;
        true ->
            ret:ok()
    end,
    %% 我看其它人
    if
        OldVBs =/= NewVBs andalso Idx > 0 ->
            case map_block:get_osn_of_window_agents(OldVBs, NewVBs) of
                same ->
                    ret:ok();
                {[], _, []} ->
                    ret:ok();
                {ExitPlayers1, _, EnterPlayers1} ->
                    a_unseen_b([Idx], ExitPlayers1),
                    a_see_b([Idx], EnterPlayers1);
                _ ->
                    ?INFO_LOG("----------------------- failed in broadcast_move")
            end; 
        true ->
            ret:ok()
    end.

% broadcast_except_main_client_if_monster(#agent{idx = Idx} = A, Msg) ->
%     List0 = scene_player:get_all_player_idx(),
%     List = lists:sublist(List0, 1, 100),
%     lists:foreach
%     (
%         fun(Idx)
%     ).

% broadcast_except_main_client_if_monster_new(Idx, ObserverList, Msg) ->
%     lists:foreach(
%         fun(Id) ->
%                 Pid = world:get_player_pid(Id),
%                 case team_server:is_team_master(Id, ?TEAM_TYPE_MAIN_INS) orelse team_svr:is_leader(Id) of
%                     true ->
%                         case Idx < 0 of
%                             true ->
%                                 ignore;
%                             _ ->
%                                 ?send_to_client(Pid, Msg)
%                         end;
%                     _ ->
%                         ?send_to_client(Pid, Msg)
%                 end
%         end,
%         ObserverList
%     ).

broadcast_except_main_client_if_monster(#agent{idx = AIdx}, Msg) ->
    List0 = scene_player:get_all_player_idx(),
    List = lists:sublist(List0, 1, 100),
    lists:foreach(
        fun(Idx) ->
            case ?get_agent(Idx) of
                Agent when is_record(Agent, agent) ->
                    case team_server:is_team_master(Agent#agent.id, ?TEAM_TYPE_MAIN_INS) orelse team_svr:is_leader(Agent#agent.id) of
                        true ->
                            case AIdx < 0 of
                                true ->
                                    ignore;
                                _ ->
                                    ?send_to_client(Agent#agent.pid, Msg)
                            end;
                        _ ->
                            ?send_to_client(Agent#agent.pid, Msg)
                    end;
                _ ->
                    ignore
            end
        end,
        List
    ).

%% -----------------------------
%% private
%% -----------------------------

do_a_see_b_data(AIdx, List) ->
    %?DEBUG_LOG("AIdx------:~p------List------:~p",[AIdx, List]),
    do_a_see_b_data_(AIdx, List, [], [], 0).

do_a_see_b_data_(AIdx, L, PlayerList, MonsterList, Total) when L =:= [] orelse Total > 50->
    {PlayerList, MonsterList};
do_a_see_b_data_(AIdx, [?undefined|Tail], PlayerList, MonsterList, Total) ->
    do_a_see_b_data_(AIdx, Tail, PlayerList, MonsterList, Total);
do_a_see_b_data_(AIdx, [HeadIdx|Tail], PlayerList, MonsterList, Total) when HeadIdx =/= AIdx andalso HeadIdx > 0 ->
    {NPlayerList, NMonsterList, NTotal} =
    case ?get_agent(HeadIdx) of
        FA when is_record(FA, agent) ->
            case FA#agent.type =/= ?agent_ob of
                true ->
                    {[scene_agent:get_view_info(FA) | PlayerList], MonsterList, Total + 1};
                _ ->
                    {PlayerList, MonsterList, Total}
            end;
        _ ->
            {PlayerList, MonsterList, Total}
    end,
    do_a_see_b_data_(AIdx, Tail, NPlayerList, NMonsterList, NTotal);
do_a_see_b_data_(AIdx, [HeadIdx|Tail], PlayerList, MonsterList, Total) when HeadIdx =/= AIdx andalso HeadIdx < 0 ->
    {NPlayerList, NMonsterList, NTotal} =
    case ?get_agent(HeadIdx) of
        FA when is_record(FA, agent) ->
            {PlayerList, [scene_agent:get_monster_view_info(FA) | MonsterList], Total};
        _ ->
            {PlayerList, MonsterList, Total}
    end,
    do_a_see_b_data_(AIdx, Tail, NPlayerList, NMonsterList, NTotal);
do_a_see_b_data_(AIdx, [_|Tail], PlayerList, MonsterList, Total) ->
    do_a_see_b_data_(AIdx, Tail, PlayerList, MonsterList, Total).

do_a_see_b_send(AIdsList, GetEnterAgents) ->
    do_a_see_b_send_(AIdsList, GetEnterAgents, 50).
do_a_see_b_send_([], _, Total) ->
    pass;
do_a_see_b_send_(_, _, Total) when Total < 0 ->
    pass;
do_a_see_b_send_([?undefined|Tail], GetEnterAgents, Total) ->
    do_a_see_b_send_(Tail, GetEnterAgents, Total);
do_a_see_b_send_([APlayerIdx|Tail], GetEnterAgents, Total) ->
    AAgent = ?get_agent(APlayerIdx),
    NTotal = 
    case APlayerIdx > 0 andalso is_record(AAgent, agent) of
        true ->
            case GetEnterAgents(APlayerIdx) of
                {[], []} ->
                    Total;
                EnterAgents ->
                    Pkg = scene_sproto:pkg_msg(?MSG_SCENE_ENTER_VIEW, EnterAgents),
                    spawn(fun() -> ?send_to_client(AAgent#agent.pid, Pkg) end),
                    % case AAgent#agent.socket of
                    %     robot_socket ->
                    %         ?send_to_client(AAgent#agent.pid, Pkg);
                    %     Socket ->
                    %         gen_tcp:send(Socket, Pkg)
                    % end,
                    Total -1
            end;
        _ ->
            Total
    end,
    do_a_see_b_send_(Tail, GetEnterAgents, NTotal).

a_see_b(AIdsList, BIdsList) ->
    GetEnterAgents = fun(AIdx) ->
        % lists:foldl(
        %     fun
        %         (?undefined, Acc) ->
        %             Acc;
        %         (BPlayerIdx, {FP, FM, Count}) when > 50 ->
        %             {FP, FM, Count};
        %         (BPlayerIdx, {FP, FM, Count}) when BPlayerIdx =/= AIdx andalso BPlayerIdx > 0 ->
        %             case ?get_agent(BPlayerIdx) of
        %                 FA when is_record(FA, agent) ->
        %                     case FA#agent.type =/= ?agent_ob of
        %                         true ->
        %                             {[scene_agent:get_view_info(FA) | FP], FM, Count + 1};
        %                         _ ->
        %                             {FP, FM, Count}
        %                     end;
        %                 _ ->
        %                     {FP, FM, Count}
        %             end;
        %         (BPlayerIdx, {FP, FM, Count}) when BPlayerIdx =/= AIdx andalso BPlayerIdx < 0 ->
        %             case ?get_agent(BPlayerIdx) of
        %                 FA when is_record(FA, agent) ->
        %                     {FP, [scene_agent:get_monster_view_info(FA) | FM], Count};
        %                 _ ->
        %                     {FP, FM, Count}
        %             end;
        %         (_, Acc) ->
        %             Acc
        %     end,
        %     {[], [], 0},
        %     BIdsList)
        do_a_see_b_data(AIdx, BIdsList)
    end,

    % lists:foreach(
    %     fun
    %         (?undefined) -> ret:ok();
    %         (APlayerIdx) ->
    %             AAgent = ?get_agent(APlayerIdx),
    %             case APlayerIdx > 0 andalso is_record(AAgent, agent) of
    %                 true ->
    %                     case GetEnterAgents(APlayerIdx) of
    %                         {[], []} ->
    %                             ret:ok();
    %                         EnterAgents ->
    %                             Pkg = scene_sproto:pkg_msg(?MSG_SCENE_ENTER_VIEW, EnterAgents),
    %                             ?send_to_client(AAgent#agent.pid, Pkg)
    %                     end;
    %                 _ ->
    %                     ret:ok()
    %             end
    %     end,
    %     AIdsList
    % ).

    % lists:foldl(
    %     fun
    %         (?undefined, Total) ->
    %             Total;
    %         (_, Total) when Total > 50 ->
    %             Total;
    %         (APlayerIdx, Total) ->
    %             AAgent = ?get_agent(APlayerIdx),
    %             case APlayerIdx > 0 andalso is_record(AAgent, agent) of
    %                 true ->
    %                     case GetEnterAgents(APlayerIdx) of
    %                         {[], []} ->
    %                             Total;
    %                         EnterAgents ->
    %                             Pkg = scene_sproto:pkg_msg(?MSG_SCENE_ENTER_VIEW, EnterAgents),
    %                             ?send_to_client(AAgent#agent.pid, Pkg),
    %                             Total+1
    %                     end;
    %                 _ ->
    %                     Total
    %             end
    % end,
    % 0,
    % AIdsList).
    do_a_see_b_send(AIdsList, GetEnterAgents).

    % ViewData = 
    % lists:foldl(
    %     fun
    %     (?undefined, Acc) ->
    %         Acc;
    %     (Idx, {PlayerData, MonsterData}) when Idx > 0 ->
    %         case ?get_agent(Idx) of
    %             FA when is_record(FA, agent) ->
    %                 case FA#agent.type =/= ?agent_ob of
    %                     true ->
    %                         {[scene_agent:get_view_info(FA) | PlayerData], MonsterData};
    %                     _ ->
    %                         {PlayerData, MonsterData}
    %                 end;
    %             _ ->
    %                 {PlayerData, MonsterData}
    %         end;
    %     (Idx, {PlayerData, MonsterData}) when Idx < 0 ->
    %         case ?get_agent(Idx) of
    %             FA when is_record(FA, agent) ->
    %                 {PlayerData, [scene_agent:get_monster_view_info(FA) | MonsterData]};
    %             _ ->
    %                 {PlayerData, MonsterData}
    %         end;
    %     (_, Acc) ->
    %         Acc
    % end,
    % {[],[]},
    % AIdsList),

    % if
    %     ViewData =:= {[],[]} ->
    %         ret:ok();
    %     true ->
    %         lists:foreach(
    %             fun
    %                 (?undefined) -> 
    %                     ret:ok();
    %                 (APlayerIdx) ->
    %                     AAgent = ?get_agent(APlayerIdx),
    %                     case APlayerIdx > 0 andalso is_record(AAgent, agent) of
    %                         true ->
    %                             Pkg = scene_sproto:pkg_msg(?MSG_SCENE_ENTER_VIEW, ViewData),
    %                             spawn(fun() ->?send_to_client(AAgent#agent.pid, Pkg) end);
    %                         _ ->
    %                             ret:ok()
    %                     end
    %             end,
    %         BIdsList)
    % end.

a_unseen_b(AIdsList, BIdsList) ->
    {ExitAgent, BIdx} = 
    case BIdsList of
        [ID] ->
            {<<ID:16/signed>>, ID};
        _ ->
            {
                lists:foldl(
                    fun
                        (?undefined, Acc) -> Acc;
                        (BPlayerIdx, Acc) -> <<Acc/binary, BPlayerIdx:16/signed>>
                    end,
                    <<>>,
                    BIdsList
                ),
                0
            }
    end,
    if
        ExitAgent =/= <<>> ->
            Pkg = scene_sproto:pkg_msg(?MSG_SCENE_LEAVE_VIEW, {ExitAgent}),
            lists:foreach(
                fun
                    (?undefined) -> ret:ok();
                    (APlayerIdx) ->
                        if
                            APlayerIdx > 0 andalso APlayerIdx =/= BIdx ->
                                case ?get_agent(APlayerIdx) of
                                    ?undefined ->
                                        ?NODE_ERROR_LOG("Error Agent ~p", [APlayerIdx]);
                                    AAgent ->
                                        % ?INFO_LOG("----------- ?MSG_SCENE_LEAVE_VIEW ~p",[{AAgent#agent.idx}]),
                                        ?send_to_client(AAgent#agent.pid, Pkg)
                                end;
                            true ->
                                ret:ok()
                        end
                end,
                AIdsList
            );
        true ->
            ret:ok()
    end.


% is_near(A, B) ->
%     login_sort:is_near(A, B).

get_near_players(AIdx) ->
    ObserverList = scene_player:get_all_player_idx(),
    case ?get_agent(AIdx) of
        #agent{show_player_count = ACount} ->
            % Num = min(ACount, ?MAX_SCENE_LIMIT),
            lists:sublist([Idx || Idx <- ObserverList, Idx =/= AIdx], 1, 20);
        _ ->
            []
    end.
    % case ?get_agent(AIdx) of
    %     #agent{show_player_count = ACount} = APlayer ->
    %         ObserverList1 =
    %             lists:foldl(
    %                 fun
    %                     (?undefined, Acc) ->
    %                         Acc;
    %                     (BIdx, Acc) when BIdx > 0 andalso BIdx =/= AIdx ->
    %                         case ?get_agent(BIdx) of
    %                             FA when is_record(FA, agent) ->
    %                                 case is_near(APlayer, FA) of
    %                                     ok ->
    %                                         [BIdx | Acc];
    %                                     _ ->
    %                                         Acc
    %                                 end;
    %                             _ ->
    %                                 Acc
    %                         end;

    %                     (_, Acc) ->
    %                         Acc
    %                 end,
    %                 [],
    %                 ObserverList
    %             ),
    %         Num = erlang:min(ACount, ?MAX_SCENE_LIMIT),
    %         ObserverList2 = lists:sublist(ObserverList1, 1, Num),
    %         ObserverList2;
    %     _ ->
    %         []
    % end.

get_near_players_info(AIdx) ->
    PlayerList = get_near_players(AIdx),
    PlayerList1 =
        lists:foldl(
            fun
                (BIdx, Acc) when is_number(BIdx) ->
                    FA = ?get_agent(BIdx),
                    [scene_agent:get_view_info(FA) | Acc];

                (_, Acc) ->
                    Acc
            end,
            [],
            PlayerList
        ),
    PlayerList1.

get_near_monsters_info(AIdx) ->
    ObserverList = scene_player:get_all_monster_idx(),
    case ?get_agent(AIdx) of
        #agent{} ->
            lists:foldl(
                fun
                    (?undefined, Acc) ->
                        Acc;

                    (BIdx, Acc) when BIdx < 0 andalso BIdx =/= AIdx ->
                        case ?get_agent(BIdx) of
                            FA when is_record(FA, agent) ->
                                [scene_agent:get_monster_view_info(FA) | Acc];
                            _ ->
                                Acc
                        end;

                    (_, Acc) ->
                        Acc
                end,
                [],
                ObserverList
            );

        _ ->
            []
    end.



reset_view_agent(Idx) ->
    case ?get_agent(Idx) of
        #agent{pid = Pid} ->
            NearPlayers = get_near_players_info(Idx),
            NearMonsters = get_near_monsters_info(Idx),
            Pkg = scene_sproto:pkg_msg(?MSG_SCENE_RESET_VIEW, {NearPlayers, NearMonsters}),
            ?send_to_client(Pid, Pkg);

        _ ->
            pass
    end,
    ok.

