-module(scene_event_callback).
-export([
        %% CanFunc
        is_player_in_x/1,
        is_all_player_in_x/1,
        is_monster_die/1,
        is_monsters_flush_ok/0,
        is_all_monster_die/0,
        is_player_got_task/1,
        is_player_item_enough/1,

        %% DoFunc
        set_timer/1,
        set_state/1,
        lock_area/1,
        can_do_lock_area/0,
        create_monsters/1,
        monster_speaking/1,
        show_animation/1,
        onset_trap/1,
        monsters_flush_ok/0,
        kill_all_monsters/0,
        active_transport_door/1,
        fuben_complete/0,

        %% HandleFunc
        handle_event/1,
        handle_timer/2
    ]).

-include("player.hrl").
-include("inc.hrl").
-include("scene.hrl").
-include("scene_agent.hrl").
-include("scene_event.hrl").
-include("team.hrl").

%% ========================================================================
%% CanFunc -> true | false
%% ========================================================================
is_player_in_x(X) ->
    PlayerList = scene_player:get_all_player_ids(),
    lists:any(
        fun(PlayerId) ->
                PlayerIdx = get(?player_idx(PlayerId)),
                Agent = ?get_agent(PlayerIdx),
                is_record(Agent, agent) andalso Agent#agent.x >= X
        end,
        PlayerList
    ).

is_all_player_in_x(X) ->
    PlayerList = scene_player:get_all_player_ids(),
    lists:all(
        fun(PlayerId) ->
            PlayerIdx = get(?player_idx(PlayerId)),
            Agent = ?get_agent(PlayerIdx),
            is_record(Agent, agent) andalso Agent#agent.x >= X
        end,
        PlayerList
    ).

is_monster_die(MonsterFlag) ->
    List = room_system:get_room_monsters(MonsterFlag),
    lists:all(
        fun(Idx) ->
                not erlang:is_record(?get_agent(Idx), agent)
        end,
        List
    ).

is_monsters_flush_ok() ->
    get(pd_is_monsters_flush_ok).

is_all_monster_die() ->
    case scene_player:get_all_monster_idx() of
        [] ->
            true;
        _ ->
            false
    end.

is_player_got_task(TaskId) ->
    PlayerList = scene_player:get_all_player_ids(),
    lists:any(
        fun(PlayerId) ->
                PlayerIdx = get(?player_idx(PlayerId)),
                case ?get_agent(PlayerIdx) of
                    Agent when is_record(Agent, agent) ->
                        player_eng:player_msg_call(Agent#agent.pid, {task_mng_new, is_doing_task, TaskId});
                    _ ->
                        false
                end
        end,
        PlayerList
    ).

is_player_item_enough(ItemList) ->
    PlayerList = scene_player:get_all_player_ids(),
    lists:any(
        fun(PlayerId) ->
                PlayerIdx = get(?player_idx(PlayerId)),
                case ?get_agent(PlayerIdx) of
                    Agent when is_record(Agent, agent) ->
                        case player_eng:player_msg_call(Agent#agent.pid, {game_res, can_del, ItemList}) of
                            ok -> true;
                            _ -> false
                        end;
                    _ ->
                        false
                end
        end,
        PlayerList
    ).

%% ========================================================================
%% DoFunc
%% ========================================================================
set_timer({MS, EventId}) ->
    scene_eng:start_timer(MS, ?MODULE, {send_event, EventId}).

set_state(State) ->
    put(pd_state, State).

% lock_area({Index, {X1, X2}}) ->
%     room_map:add_monster_wall(X1),
%     room_map:add_monster_wall(X2),
%     PlayerList = scene_player:get_all_player_ids(),
%     lists:foreach(
%         fun(PlayerId) ->
%                 PlayerIdx = get(?player_idx(PlayerId)),
%                 Agent = ?get_agent(PlayerIdx),
%                 case is_record(Agent, agent) andalso Agent#agent.x > X1 of
%                     true ->
%                         Agent#agent.pid ! ?to_client_msg(scene_sproto:pkg_msg(?MSG_SCENE_SEND_LOCK_AREA, {X1, X2})),
%                         put({pd_self_lock_area_index, Agent#agent.idx}, Index),
%                         AllLockAreaList = get(pd_all_lock_area_list),
%                         case lists:keyfind(Index, 1, AllLockAreaList) of
%                             true ->
%                                 ignore;
%                             _ ->
%                                 put(pd_all_lock_area_list, AllLockAreaList ++ [{Index, {X1, X2}}])
%                         end;
%                     _ ->
%                         ignore
%                 end
%         end,
%         PlayerList
%     ).
lock_area({Index, {X1, X2}}) ->
    PlayerList = scene_player:get_all_player_idx(),
    Ret = case lists:all(
        fun(Idx) ->
                Agent = ?get_agent(Idx),
                is_record(Agent, agent) andalso Agent#agent.x > X1
        end,
        PlayerList
    ) of
        true ->
            scene_player:broadcast(?to_client_msg(scene_sproto:pkg_msg(?MSG_SCENE_SEND_LOCK_AREA, {X1, X2})));
        _ ->
            AllLockAreaList = get(pd_all_lock_area_list),
            put(pd_all_lock_area_list, AllLockAreaList ++ [{Index, {X1, X2}}])
    end, 
    Ret.

% can_do_lock_area() ->
%     PlayerList = scene_player:get_all_player_ids(),
%     lists:foreach(
%         fun(PlayerId) ->
%                 PlayerIdx = get(?player_idx(PlayerId)),
%                 Agent = ?get_agent(PlayerIdx),
%                 case is_record(Agent, agent) of
%                     true ->
%                         SelfLockAreaIndex = get({pd_self_lock_area_index, Agent#agent.idx}),
%                         AllLockAreaList = get(pd_all_lock_area_list),
%                         CheckList = [{Index, {X1, X2}} || {Index, {X1, X2}} <- AllLockAreaList, X1 + 10 < Agent#agent.x],
%                         case is_list(CheckList) andalso CheckList =/= [] of
%                             true ->
%                                 {Index, {XL, XR}} = lists:max(CheckList),
%                                 case Index > SelfLockAreaIndex of
%                                     true ->
%                                         Agent#agent.pid ! ?to_client_msg(scene_sproto:pkg_msg(?MSG_SCENE_SEND_LOCK_AREA, {XL, XR})),
%                                         put({pd_self_lock_area_index, Agent#agent.idx}, Index);
%                                     _ ->
%                                         ignore
%                                 end;
%                             _ ->
%                                 ignore
%                         end;
%                     _ ->
%                         ignore
%                 end
%         end,
%         PlayerList
%     ).
can_do_lock_area() ->
    PlayerList = scene_player:get_all_player_idx(),
    AllLockAreaList = get(pd_all_lock_area_list),
    RetList = lists:foldl(
        fun({Index, {X1, X2}}, TempList) ->
                case lists:all(
                    fun(Idx) ->
                            Agent = ?get_agent(Idx),
                            is_record(Agent, agent) andalso Agent#agent.x > X1 + 5
                    end,
                    PlayerList
                ) of
                    true ->
                        [{Index, {X1, X2}}] ++ TempList;
                    _ ->
                        TempList
                end
        end,
        [],
        AllLockAreaList
    ),
    case RetList =/= [] of
        true ->
            {Index, {XL, XR}} = lists:max(RetList),
            scene_player:broadcast(?to_client_msg(scene_sproto:pkg_msg(?MSG_SCENE_SEND_LOCK_AREA, {XL, XR}))),
            put(pd_all_lock_area_list, lists:delete({Index, {XL, XR}}, AllLockAreaList));
        _ ->
            ignore
    end.

create_monsters(MonsterList) ->
    lists:foreach(
        fun({MonsterId, X, Y, _Z, Dir, Flag}) ->
                case scene_monster:new_monster(MonsterId, X, Y, Dir) of
                    MonsterAgent when is_record(MonsterAgent, agent) ->
                        A = scene_monster:monster_enter_scene(MonsterAgent),
                        scene_monster:bind_room_flag(A#agent.idx, Flag);
                    _ ->
                        pass
                end
        end,
        MonsterList
    ).

monster_speaking({Flag, TalksId}) ->
    List = room_system:get_room_monsters(Flag),
    lists:foreach
    (
        fun
            (Idx) ->
                case ?get_agent(Idx) of
                    MonsterAgent = #agent{} ->
                        scene_player:broadcast(?to_client_msg(scene_sproto:pkg_msg(?MSG_SCENE_SEND_TALKS_ID, {MonsterAgent#agent.idx, TalksId})));
                    _ ->
                        pass
                end
        end,
        List
    ).

show_animation(AnimationId) ->
    ?INFO_LOG("AnimationId:~p", [AnimationId]),
    ok.

onset_trap(_A) ->
    % TODO
    ok.

monsters_flush_ok() ->
    put(pd_is_monsters_flush_ok, true),
    ok.

kill_all_monsters() ->
    case scene_player:get_all_monster_idx() of
        MonsterList when is_list(MonsterList) ->
            lists:foreach(
                fun(Idx) ->
                        case ?get_agent(Idx) of
                            MonsterAgent when is_record(MonsterAgent, agent) ->
                                mst_ai_sys:uninit(Idx),
                                map_aoi:broadcast_view_me_agnets_and_me(MonsterAgent, scene_sproto:pkg_msg(?MSG_SCENE_AGENT_DIE, {Idx})),
                                scene_monster:die(MonsterAgent);
                            _ ->
                                ignore
                        end
                end,
                MonsterList
            );
        _ ->
            ignore
    end.

active_transport_door(DoorId) ->
    put(pd_transport_door, DoorId),
    scene_player:broadcast(?to_client_msg(main_instance_sproto:pkg_msg(?MSG_MAIN_INSTANCE_TRANSPORT_DOOR_ACTIVE, {DoorId}))),
    ok.

fuben_complete() ->
    TeamId = get(pd_team_id),
    put(pd_is_fuben_complete, true),
    {PassTime, SceneIdList} = case team_server:get_team_info_by_team_id(TeamId, ?TEAM_TYPE_MAIN_INS) of
        {ok, TeamInfo} when is_record(TeamInfo, team_info) ->
            {com_time:now() - TeamInfo#team_info.start_time, TeamInfo#team_info.scene_id_list};
        _ ->
            {0, []}
    end,
    lists:foreach(
        fun(SceneId) ->
                case room_system:get_room_pid_by_cfg(SceneId, TeamId, get(is_match_level)) of
                    Pid when is_pid(Pid) ->
                        Pid ! ?scene_mod_msg(room_system, {fuben_complete_msg, PassTime});
                    _ ->
                        pass
                end
        end,
        SceneIdList
    ),
    put(pd_pass_time, PassTime),
    main_ins_team_mod:fuben_complete(TeamId),
    ok.

%% ========================================================================
%% HandleFunc
%% ========================================================================
handle_event(Event) ->
    ProcessList = get(pd_process_list),
    State = get(pd_state),
    case is_list(ProcessList) of
        true ->
            %% 获取当前状态下所有的事件列表
            case lists:keyfind(State, 1, ProcessList) of
                {State, EventList} ->
                    %% 获取当前所触发的事件列表{EventId, Times, CanFuncList, DoFuncList}
                    {StartList, ResList} = lists:foldl(
                        fun({EventId, _, _, _} = Tuple, {Ret1, Ret2}) ->
                                case Event =:= EventId of
                                    true ->
                                        {Ret1 ++ [Tuple], Ret2};
                                    _ ->
                                        {Ret1, Ret2 ++ [Tuple]}
                                end
                        end,
                        {[], []},
                        EventList
                    ),
                    NewStartList = lists:foldl(
                        fun
                            ({EventId, Times, CanFuncList, DoFuncList}, Ret) ->
                                case lists:all(
                                    fun({CF, CA}) ->
                                            ?MODULE:CF(CA)
                                    end,
                                    CanFuncList
                                ) of
                                    true ->
                                        [?MODULE:DF(DA) || {DF, DA} <- DoFuncList],
                                        if
                                            Times > 1 ->
                                                Ret ++ [{EventId, Times - 1, CanFuncList, DoFuncList}];
                                            Times =:= 1 ->
                                                Ret;
                                            true ->
                                                Ret ++ [{EventId, 0, CanFuncList, DoFuncList}]
                                        end;
                                    _ ->
                                        Ret ++ [{EventId, Times, CanFuncList, DoFuncList}]
                                end
                        end,
                        [],
                        StartList
                    ),
                    NewEventList = NewStartList ++ ResList,
                    NewProcessList = lists:keyreplace(State, 1, ProcessList, {State, NewEventList}),
                    put(pd_process_list, NewProcessList);
                _ ->
                    ignore
            end;
        _ ->
            ignore
    end.

handle_timer(_Ref, {send_event, EventId}) ->
    self() ! {event, EventId}.

%% ========================================================================
%% PrivateFunc
%% ========================================================================
