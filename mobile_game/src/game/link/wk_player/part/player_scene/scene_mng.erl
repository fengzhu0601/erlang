%%%-------------------------------------------------------------------
%%% @author zl
%%% @doc 
%%% 
%%% @end
%%%-------------------------------------------------------------------

-module(scene_mng).

-include_lib("stdlib/include/ms_transform.hrl").

-include("scene.hrl").
-include("player.hrl").
-include("player_mod.hrl").
-include("handle_client.hrl").

-include("scene_agent.hrl").
-include("safe_ets.hrl").
-include("npc_struct.hrl").
-include("main_ins_struct.hrl").
-include("cost.hrl").
-include("load_cfg_scene.hrl").
-include("load_cfg_card.hrl").
-include("load_cfg_skill.hrl").
-include("load_vip_right.hrl").
-include("team.hrl").
-include("room_system.hrl").
-include("achievement.hrl").

-export
([
    enter_scene_request/1
    , enter_scene_request/3
    , enter_scene_request/4
    , enter_pseduo_scene/3
    , leave_scene/0
    , door_transport/1
    , get_save_point/0
    , send_msg/1
    , send_msg_pet/1
    , is_stand_npc_side/1
    , is_nearby_scene_point/3
    , lookup_player_scene_id_if_online/1
    , clear_add_hp_mp/4 %% 不要改变名字
    , scene_broadcast_effect/2
    , enter_arena_on_time/3
    , load_enter_scene_progress/1
    , load_leave_scene_progress/1
    , save_point_if_should/3
    , enter_scene/3
]).

-define(ENTER_SCENE_TIMEOUT, 3000).
-define(LEAVE_SCENE_TIMEOUT, 3000).

-define(SCENE_MOD, scene_player).
-define(SCENE_SINGLE_INSTANCE, scene_single_instance).
-define(SCENE_BOSS_INSTANCE, scene_boss_instance).
-define(SCENE_FAMILY_TASK, scene_family_task).
-define(pd_enter_arena_ontime, pd_enter_arena_ontime).

create_mod_data(_) -> ok.

load_mod_data(_) -> ok.

init_client() -> ok.

view_data(Acc) -> Acc.

online() -> ok.

offline(_) -> ok.

save_data(_) -> ok.

handle_frame(_) -> ok.

-define(online_player_scene_ets, online_player_scene_ets).

create_safe_ets() ->
    [
        safe_ets:new(?online_player_scene_ets, [?named_table, ?public, {?read_concurrency, ?true}, {?write_concurrency, ?true}])
    ].


-spec lookup_player_scene_id_if_online(player_id()) -> offline | scene_id().
lookup_player_scene_id_if_online(PlayerId) ->
    case ets:lookup(?online_player_scene_ets, PlayerId) of
        [] -> offline;
        [{_, SceneId}] -> SceneId;
        _E -> ?ERROR_LOG("no match ~p", [_E]), offline
    end.

handle_client({Pack, Arg}) ->
    handle_client(Pack, Arg).

%% 设置屏幕大小
handle_client(?MSG_SCENE_RESIZE_VIEW, {Rx, Ry}) ->
    ?ifdo
    (
        {get(?pd_vx), get(?pd_vy)} =/= {Rx, Ry},
        put(?pd_vx, Rx),
        put(?pd_vy, Ry),
        send_msg({?resize_view_msg, get(?pd_idx), Rx, Ry})
    );


handle_client(?MSG_SCENE_PLAYER_ENTER_REQUEST, {SceneCfgId}) ->
    %% just can enter normal scene
    %?DEBUG_LOG("SceneCfgId--------------------------:~p",[SceneCfgId]),
    enter_scene_request(SceneCfgId);

handle_client(?MSG_SCENE_PLAYER_ENTER, {}) ->
    case player_room_part:is_enter_action() of
        true ->
            player_room_part:end_enter_room_by_client();
        _ ->
            case erase(?pd_entering_scene) of
                ?undefined ->
                    ?ERROR_LOG("player ~p bad enter scene req not entering scene", [?pname()]);
                {SceneId, X, Y} ->
                    enter_scene(SceneId, X, Y);
                {SceneId, X, Y, Dir} ->
                    enter_scene(SceneId, X, Y, Dir);
                _ ->
                    ?ERROR_LOG("player ~p not entering scene", [?pname()])
            end
    end;

%% (change lan)
% handle_client(?MSG_SCENE_ADD_HP_MP, {ButtonId}) ->
%     %% check cd
%     ?DEBUG_LOG("~p", [{com_time:now(), get(?pd_attr_add_hp_mp_cd), ?ADD_HP_MP_CD}]),
%     ?ifdo(com_time:now() - get(?pd_attr_add_hp_mp_cd) < ?ADD_HP_MP_CD, ?return_err(?cd_limit)),
%     ?DEBUG_LOG(":~p", [{get(?pd_scene_id), load_cfg_scene:get_config_id(get(?pd_scene_id)), load_cfg_main_ins:get_add_hp_mp_info(load_cfg_scene:get_config_id(get(?pd_scene_id)))}]),
%     {InsId, Difficulty, InsType} = load_cfg_main_ins:get_add_hp_mp_info(load_cfg_scene:get_config_id(get(?pd_scene_id))),
%     {Min, Max, List} = misc_cfg:get_add_hp_mp_cfg({InsType, Difficulty}),
%     ?DEBUG_LOG("~p", [{Min, Max, List}]),
%     case get(?pd_add_hp_mp_info) of
%         {_Count, {NInsId, NDifficulty}} when InsId =/= NInsId;Difficulty =/= NDifficulty ->
%             %%?err(?not_in_ins);
%             add_hp_mp(ButtonId); %% BUG
%         {Count, _} when Count =< Min -> %% free
%             add_hp_mp(ButtonId);
%         {Count, _} -> %% pay
%             NCount = min(Max, Count),
%             case lists:keyfind(NCount, 1, List) of %%
%                 {_, CostId} ->
%                     case cost:lookup_cost_cfg(CostId) of
%                         ?none -> {error, not_found_cost};
%                         #cost_cfg{goods = GoodsList} ->
%                             GoodsList1 = cost:do_cost_tp(GoodsList),
%                             case game_res:can_del(GoodsList1) of
%                                 ok ->
%                                     game_res:del(GoodsList1),
%                                     add_hp_mp(ButtonId);
%                                 _ -> ?err(?cost_not_enough)
%                             end
%                     end;
%                 _ ->
%                     ?err(?none_cfg)
%             end;
%         _ ->
%             ?err(?not_in_ins)
%     end;
handle_client(?MSG_SCENE_ADD_HP_MP, {_ButtonId}) ->
    team_scene_add_hp();

handle_client(?MSG_SCENE_PLAYER_MOVE, {Idx, X, Y, H, MoveVector}) ->
    %?DEBUG_LOG("player move -------------------:~p",[{Idx, X, Y, H, MoveVector}]),
    case is_check_ok(Idx) of
        true ->
            send_msg({?move_msg, Idx, X, Y, H, MoveVector});
        _ ->
            ?ERROR_LOG("move_msg error with idx:~p, not master:~p", [Idx, get(?pd_id)])
    end;

handle_client(?MSG_SCENE_PLAYER_MOVE_STOP, {Idx, X, Y, H}) ->
    case is_check_ok(Idx) of
        true ->
            send_msg({?move_stop_msg, Idx, {X, Y, H}});
        _ ->
            % ?ERROR_LOG("move_stop_msg error with idx:~p, not master:~p", [Idx, get(?pd_id)])
            pass
    end;

handle_client(?MSG_SCENE_JUMP, {Idx, Direct, X, Y, H}) ->
    case is_check_ok(Idx) of
        true ->
            send_msg({?jump_msg, Idx, Direct, X, Y, H});
        _ ->
            ?ERROR_LOG("move_jump_msg error with idx:~p, not master:~p", [Idx, get(?pd_id)])
    end;

handle_client(?MSG_SCENE_RELEASE_SKILL, {Idx, SkillId, SkillDuanId, D, X, Y, H}) ->
    case is_check_ok(Idx) of
        true ->
            case load_cfg_crown:is_anger_skill(SkillDuanId) of
                ?true ->
                    achievement_mng:do_ac(?jinengdashi);
                _ ->
                    pass
            end,
            send_msg({?release_skill_msg, Idx, SkillId, SkillDuanId, D, X, Y, H});
            % case Idx =:= get(?pd_idx) of
            %     true -> %% player release skill
            %         skill_mng:release_skill(SkillId, SkillDuanId, D, X, Y, H);
            %     _ ->    %% monster release skill
            %         send_msg({?release_skill_msg, Idx, SkillId, SkillDuanId, D, X, Y, H})
            % end;
        _ ->
            ?ERROR_LOG("release_skill_msg error with idx:~p, not master:~p", [Idx, get(?pd_id)])
    end;

handle_client(?MSG_SCENE_PICKUP_DROP_ITEMS, {DropId}) ->
    send_msg({?msg_pickup_drop_item, get(?pd_idx), DropId});

handle_client(?MSG_SCENE_DOOR_TRANSPORT, {DoorId}) ->
    door_transport(DoorId);

handle_client(?MSG_SCENE_PLAYER_SWITCH_MOVE_MODE, {Idx, Mode}) ->
    case scene_def:is_valid_move_type(Mode) of
        ?true ->
            send_msg({?switch_move_mode_msg, Idx, Mode});
        ?false ->
            {error, {<<"invalid move type">>, Mode}}
    end;

handle_client(?MSG_SCENE_RELEASE_SKILL_END, {Idx, SkillId, SkillDuanId, _X, _Y, _Z}) ->
    send_msg({release_skill_end, Idx, SkillId, SkillDuanId});

handle_client(?MSG_SCENE_BREAK_SKILL, {Idx, BreakerId, SkillId, SkillDuanId, _X, _Y, _Z}) ->
    send_msg({skill_break, Idx, BreakerId, SkillId, SkillDuanId});

handle_client(?MSG_SCENE_MONSTER_AGENT_SYNC, {MAId, X, Y, Z}) ->
    send_msg({scene_monster_agent_sync, get(?pd_idx), MAId, X, Y, Z});

handle_client(?MSG_SCENE_AGENT_BE_HIT, {AgentHitIdx, SkillId, SkillDuanId, Dir, ReleaseX, ReleaseY, ReleaseH, AgentBeHitIdxList}) ->
    send_msg({agent_be_hit, AgentHitIdx, SkillId, SkillDuanId, Dir, ReleaseX, ReleaseY, ReleaseH, AgentBeHitIdxList});

handle_client(?MSG_SCENE_RELEASE_EMITS, {Idx, EmitsId, X, Y, H, Dir, DelayTime, SkillId, SkillDuanId}) ->
    send_msg({release_emits_msg, Idx, EmitsId, X, Y, H, Dir, DelayTime, SkillId, SkillDuanId});

handle_client(?MSG_SCENE_EMITS_DIE, {Idx}) ->
    send_msg({emits_die_msg, Idx});

handle_client(?MSG_SCENE_NAVIGATION, {Idx, RobotId, Type, RetId, NpcId, PointList}) ->
    case world:get_player_pid(RobotId) of
        Pid when is_pid(Pid) ->
            ?send_mod_msg(Pid, robot_new, {navigation, Idx, Type, RetId, NpcId, PointList});
        _ ->
            ignore
    end;

handle_client(?MSG_SCENE_AGENT_STATE_CHANGE, {Idx, State}) ->
    send_msg({agent_state_change, Idx, State});

handle_client(Cmd, Msg) ->
    scene_client_mng:handle_client(Cmd, Msg).

handle_msg(_, {kickout_scene, SceneId, Idx, Hp}) ->
    ?INFO_LOG("player had kickout_cenen ~p ", [SceneId]),
    kickout_scene(SceneId, Idx, Hp);

handle_msg(FromMod, Msg) ->
    ?ERROR_LOG("~p recv a unknown msg ~p from ~p", [?pname(), Msg, FromMod]).

send_msg({?msg_relive, _Idx, ?RELIVE_PLACE_RELIVE}) ->
    todo;
send_msg(Msg) ->
    case get(?pd_scene_pid) of
        Pid when is_pid(Pid) ->
            %?debug_log_scene("send to senec"),
            Pid ! ?scene_mod_msg(?SCENE_MOD, Msg);
        _ ->
%%             ?ERROR_LOG("player ~ts can not send to scene pid ~w=======~w", [?pname(), get(?pd_scene_pid), Msg])
            ok
    end.

send_msg_pet(Msg) ->
    case get(?pd_scene_pid) of
        Pid when is_pid(Pid) ->
            Pid ! ?scene_mod_msg(scene_pet, Msg);
        _ ->
            ?ERROR_LOG("pet ~p can not send to scene pid ~p", [pet_mng:get_cur_fight_pet(), get(?pd_scene_pid)])
    end.

enter_pseduo_scene(SceneId, X, Y) when is_integer(SceneId) ->
    enter_scene_request({SceneId, ?scene_pseduo}, X, Y).

-spec check_can_enter_scene(scene_id()) -> ok | {error, _}.
check_can_enter_scene(SceneId) ->
    Level = get(?pd_level),
    case load_cfg_scene:get_enter_level_limit(SceneId) of
        ?none ->
            ?err(?none_cfg);
        L when Level >= L ->
            case load_cfg_scene:get_pid(SceneId) of
                ?none ->
                    ok;
                _Pid ->
                    ok %% TODO call scene proc check
            end;
        W ->
            ?DEBUG_LOG("Level:~p, W:~p, SceneId:~p", [Level, W, SceneId]),
            ?err(?level_limit)
    end.

enter_scene(SceneId, X, Y) ->
    enter_scene(SceneId, X, Y, ?D_R).
enter_scene(SceneId, X, Y, Dir) ->
    erlang:put(?pd_entering_scene, SceneId),
    case check_can_enter_scene(SceneId) of
        ok ->
            case get(?pd_scene_id) of
                ?undefined ->
                    do_enter_scene(SceneId, X, Y, Dir);
                _ ->
                    leave_scene(),
                    do_enter_scene(SceneId, X, Y, Dir)
            end;
        E ->
            ?player_send_err(?MSG_SCENE_PLAYER_ENTER_REQUEST, ?ERR_ENTER_SCENE_REQUEST_DISAPPROVED),
            E
    end.

leave_scene() ->
    %% 玩家离开场景后将 加血CD重置
%%    put(?pd_attr_add_hp_mp_cd, util:get_pd_field(?pd_attr_add_hp_mp_cd,0) - 30),
    put(?pd_attr_add_hp_mp_cd, 0),
    case player_room_part:is_in_room() of
        true ->
            player_room_part:leave_scene();
        _ ->
            scene_client_mng:reset_drop(),
            case load_cfg_scene:get_scene_type(get(?pd_scene_id)) of
                ?SC_TYPE_PSEDUO ->
                    erase(?pd_scene_id),
                    erase(?pd_x),
                    erase(?pd_y),
                    erase(?pd_idx);
                _ ->
                    SceneId = get(?pd_scene_id),
                    case load_cfg_scene:get_pid(SceneId) of
                        ?none ->
                            ?ERROR_LOG("leave can not get scene pid, scene_id:~p", [SceneId]);
                        ScenePid ->
                            Idx = get(?pd_idx),
                            ?Assert(Idx =/= ?undefined, "leave scence can not find idx"),
                            try 
                                gen_server:call(
                                ScenePid,
                                {
                                    mod, ?SCENE_MOD,
                                    {
                                        ?leave_scene_msg,
                                        Idx
                                    }
                                },
                                ?LEAVE_SCENE_TIMEOUT
                            )
                            of
                                {ok, Hp, X, Y} ->
                                    %% 离开主场景,玩家去掉坐骑速度，如果有坐骑的话
                                    attr_new:begin_sync_attr(),
                                    case load_cfg_scene:get_scene_type(get(?pd_scene_id)) of
                                        ?SC_TYPE_NORMAL ->
                                            ride_mng:getoff_ride_for_scene(),
                                            mount_tgr:getoff_tgr_ride_for_scene();
                                        _ ->
                                            ok
                                    end,
                                    attr_new:end_sync_attr(),
                                    %% 判断是否是钓鱼房
                                    case daily_activity_service:is_fishing_room(get(?pd_scene_id)) of
                                        ?true ->
                                            daily_activity_service:call_leave_fishing_room(get(?pd_scene_id), get(?pd_id));
                                        _ ->
                                            pass
                                    end,
                                    save_point_if_should(SceneId, X, Y),
                                    put(?pd_hp, Hp),
                                    erase(?pd_scene_id),
                                    erase(?pd_x),
                                    erase(?pd_y),
                                    PdIdx = erase(?pd_idx),
                                    pet_new_mng:pet_new_leave_scene(ScenePid, PdIdx);
                                    %pet_mng:pet_leave_scene(ScenePid, PdIdx);
                                ok ->
                                    ?ERROR_LOG("player ~p leave scene error ~p", [?pname(), {SceneId, get(?pd_x), get(?pd_y)}]);
                                {error, Why} ->
                                    ?ERROR_LOG("player ~p leave scene error ~p", [?pname(), {SceneId, Why}])
                            catch
                                E:_W ->
                                    ?ERROR_LOG("leave_scene E------------------:~p",[E])
                            end
                    end
            end,
            ets:delete(?online_player_scene_ets, get(?pd_id))
    end.


-spec is_stand_npc_side(integer()) -> boolean().
is_stand_npc_side(none) ->
    true;
is_stand_npc_side(Npc) ->
    case npc:lookup_npc_cfg(Npc) of
        ?none ->
            ?ERROR_LOG("can not get npc ~p can not courrent", [Npc]),
            false;
        #npc_cfg{scene_id = NpcSid, x = NpcX, y = NpcY} ->
            is_nearby_scene_point(NpcSid, NpcX, NpcY)
    end.

%% @doc check player is nearby in scene point
is_nearby_scene_point(Sid, X, Y) ->
    is_nearby_scene_point(Sid, X, Y, 8, 8).
is_nearby_scene_point(_Sid, _X, _Y, _R, _L) ->
    true.
    % SceneId = get(?pd_scene_id),
    % case load_cfg_scene:get_config_id(SceneId) of
    %     Sid ->
    %         ?assert(get(?pd_scene_pid) =:= load_cfg_scene:get_pid(get(?pd_scene_id))),
    %         case scene:get_agent_point(get(?pd_scene_pid), get(?pd_idx)) of
    %             ?none ->
    %                 ?ERROR_LOG("can not get player point in scenen ~p", [Sid]),
    %                 false;
    %             {Mx, My} ->
    %                 case L > 0 of
    %                     ?true ->
    %                         ?debug_log_scene("Mx ~w, X ~w, My ~w, Y ~w R ~w, L ~w", [Mx, X, My, Y, R, L]),
    %                         (erlang:abs(Mx - X) < R) andalso (erlang:abs(My - Y) < L);
    %                     _ ->
    %                         TmpX = erlang:abs(Mx - X),
    %                         TmpY = erlang:abs(My - Y),
    %                         ?debug_log_scene("Mx ~w, X ~w, My ~w, Y ~w R ~w", [Mx, X, My, Y, R]),
    %                         TmpX * TmpX + TmpY * TmpY =< R * R
    %                 end
    %         end;
    %     _N ->
    %         ?ERROR_LOG("player not same scene ~p sid ~p", [get(?pd_scene_id), Sid]),
    %         false
    % end.



door_transport(DoorId) ->
    case load_cfg_scene_portal:get_portal_position(DoorId) of
        ?none ->
            ?ERROR_LOG("player ~p can not find doorid ~p", [?pname(), DoorId]);
        {SrcSid, SrcX, SrcY, SrcR, SrcL, DstSid, DstX, DstY} ->
            case is_nearby_scene_point(SrcSid, SrcX, SrcY, SrcR, SrcL) of
                true when SrcSid =:= DstSid ->
                    large_move(DstX, DstY);
                true ->
                    enter_scene_request(DstSid, DstX, DstY);
                false ->
                    ?ERROR_LOG("player ~p transport door ~p but not in nearby", [?pname(), DoorId])
            end
    end.


large_move(DstX, DstY) ->
    get(?pd_scene_pid) ! ?scene_mod_msg(?SCENE_MOD, {large_move, get(?pd_idx), DstX, DstY}).


%% @private
save_point_if_should(SceneId, X, Y) ->
    case load_cfg_scene:get_scene_type(SceneId) of
        ?SC_TYPE_NORMAL ->
            ?debug_log_scene("save scene ~p", [{SceneId, X, Y}]),
            put(?pd_save_scene_id, SceneId),
            put(?pd_save_x, X),
            put(?pd_save_y, Y);
        _ ->
            ok
    end.

-spec get_save_point() -> {_, _, _}.
get_save_point() ->
    L = [get(?pd_save_scene_id), get(?pd_save_x), get(?pd_save_y)],
    case lists:all(fun(N) -> N =/= ?undefined end, L) andalso load_cfg_scene:is_normal_scene(get(?pd_save_scene_id)) of
        true ->
            list_to_tuple(L);
        _ ->
            SceneId = load_cfg_scene:get_default_scene_id(get(?pd_career)),
            SceneCfgId = load_cfg_scene:get_config_id(SceneId),
            {X, Y} = load_cfg_scene:get_default_enter_point(SceneCfgId),
            put(?pd_save_scene_id, SceneId),
            put(?pd_save_x, X),
            put(?pd_save_y, Y),
            {SceneId, X, Y}
    end.


-spec enter_scene_request(scene_id()) -> approved | disapproved.
enter_scene_request(SceneId) ->
    case load_cfg_scene:get_default_enter_point(SceneId) of
        {X, Y} ->
            %?DEBUG_LOG("enter_scene_request--------------------:~p",[{X, Y}]),
            enter_scene_request(SceneId, X, Y);
        _ ->
            ?ERROR_LOG("can not get scene ~p default enter point", [SceneId]),
            ?player_send_err(?MSG_SCENE_PLAYER_ENTER_REQUEST,
                ?ERR_ENTER_SCENE_REQUEST_DISAPPROVED,
                <<SceneId:16>>),
            disapproved
    end.

-spec enter_scene_request(_, _, _) -> approved | disapproved.
enter_scene_request(SceneId, X, Y) ->
    enter_scene_request(SceneId, X, Y, ?D_R).
enter_scene_request(SceneId, X, Y, Dir) ->
    %?DEBUG_LOG("enter_scene_request ~p", [{SceneId, X, Y, Dir}]),
    CfgId = load_cfg_scene:get_config_id(SceneId),
    CurrentPid = get(?pd_scene_pid),
    CurrentId = get(?pd_scene_id),
    ScenePid = load_cfg_scene:get_pid(SceneId),

    ?if_(CurrentPid =:= ScenePid, ?ERROR_LOG("enter_scene_request cfg ~p is already in", [CfgId])),
    case check_can_enter_scene(SceneId) of
        ok ->
            case is_need_full_hp_scene(SceneId, CurrentId) of
                ?true ->
                    player:set_full_hp();
                _ ->
                    ignore
            end,
            save_point_if_should(erlang:get(?pd_scene_id), 0, 0),
            put(?pd_entering_scene, {SceneId, X, Y, Dir}),
            %?DEBUG_LOG("enter_scene_request ~p 111", [{CfgId, X, Y, Dir}]),
            ?player_send(scene_sproto:pkg_msg(?MSG_SCENE_PLAYER_ENTER_REQUEST, {CfgId, X, Y, Dir, 0})),
            approved;

        _E ->
            ?ERROR_LOG("can not get scene ~p default enter point ~p ~p", [SceneId, _E, erlang:get(?pd_id)]),
            ?player_send_err(?MSG_SCENE_PLAYER_ENTER_REQUEST,
                ?ERR_ENTER_SCENE_REQUEST_DISAPPROVED,
                <<SceneId:16>>),
            disapproved
    end.

is_need_full_hp_scene({_, ?scene_arena, _}, {_, ?scene_normal, _}) -> ?true;
is_need_full_hp_scene({_, ?scene_normal, _}, {_, ?scene_arena, _}) -> ?true;
is_need_full_hp_scene({_, ?scene_main_ins, _}, _) -> ?true;
is_need_full_hp_scene(_, _) -> ?false.

% add_hp_mp(ButtonId) ->
%     Now = com_time:now(),
%     {Count, InsInfo} = get(?pd_add_hp_mp_info),
%     case load_cfg_scene:lookup_add_hp_mp_cfg(ButtonId) of
%         #add_hp_mp_cfg{type = ?ADD_TYPE_HP_MP_TYPE} -> %% 直接加满hp和mp
%             put(?pd_attr_add_hp_mp_cd, Now),
%             put(?pd_add_hp_mp_info, {Count + 1, InsInfo}),
%             player:set_full_mp(),
%             player:set_full_hp(),

%             ?player_send(scene_sproto:pkg_msg(?MSG_SCENE_ADD_HP_MP, {})),
%             ok;
%         #add_hp_mp_cfg{type = ?ADD_TYPE_BUFF_TYPE, buff_id = _BuffId} -> %% 使用buff加
%             %% TODO:添加对应的buff_id
%             put(?pd_attr_add_hp_mp_cd, Now),
%             put(?pd_add_hp_mp_info, {Count + 1, InsInfo}),
%             ?player_send(scene_sproto:pkg_msg(?MSG_SCENE_ADD_HP_MP, {})),
%             ok;
%         _E ->
%             ?ERROR_LOG("add_hp_mp error, ButtionCfg ~w", [_E]),
%             ?err(?none_cfg)
%     end.


init_add_hp_mp(SceneId) ->
    case load_cfg_main_ins:get_add_hp_mp_info(load_cfg_scene:get_config_id(SceneId)) of
        {InsId, Difficulty, _} ->
            case get(?pd_add_hp_mp_info) of
                {_, InsInfo} when InsInfo =:= {InsId, Difficulty} ->
                    ignore;
                _ ->
                    put(?pd_attr_add_hp_mp_cd, 0),
                    put(?pd_add_hp_mp_info, {0, {InsId, Difficulty}}),
                    ok
            end;
        _ ->
            ignore
    end.

clear_add_hp_mp(_Key, _Arg, _Data, _PostArg) ->
    put(?pd_attr_add_hp_mp_cd, 0),
    put(?pd_add_hp_mp_info, {0, {0, 0}}),
    ok.

scene_broadcast_effect(BroadcastType, EffectId) ->
    case BroadcastType of
        1 ->
            Pid = get(?pd_scene_pid),
            if
                is_pid(Pid) -> Pid ! ?scene_mod_msg(scene_player, {this_scene_player_effects, EffectId});
                true -> ok
            end;

        2 -> %所有城镇场景
            FunMap = fun(SceneId) ->
                Pid = load_cfg_scene:get_pid(SceneId),
                if
                    is_pid(Pid) -> Pid ! ?scene_mod_msg(scene_player, {this_scene_player_effects, EffectId});
                    true -> ok
                end
                     end,
            lists:map(FunMap, global_data:get_normal_scenes());

        3 -> %所有场景，（城镇和副本）
            world:broadcast(?to_client_msg(scene_sproto:pkg_msg(?MSG_SCENE_PLAY_EFFECTS, {EffectId, <<>>})))
    end.


%% ----------------------
%% private
%% ----------------------
do_enter_scene(SceneId, X, Y, Dir) ->
    case load_cfg_scene:get_scene_type(SceneId) of
        ?SC_TYPE_PSEDUO ->
            %% 伪场景
            Idx = 1,
            put(?pd_scene_id, SceneId),
            put(?pd_x, X),
            put(?pd_y, Y),
            put(?pd_idx, Idx),
            put(?pd_scene_pid, ?scene_pseduo),
            ets:insert(?online_player_scene_ets, {get(?pd_id), SceneId}),
            ?player_send(scene_sproto:pkg_msg(?MSG_SCENE_PLAYER_ENTER, {Idx, 0})),
            ok;

        SceneType ->
            case SceneType of
                ?SC_TYPE_NORMAL ->
                    Hp = attr_new:get(?pd_hp, 0),
                    if
                        Hp =< 0 ->
                            player_log_service:add_crash_log(get(?pd_id), get(?pd_name), {hp_less_0}),
                            ?INFO_LOG("HP =< 0 "),
                            pass;
                        true ->
                            pass
                    end,
                    MaxHp1 = attr_new:get_attr_item(?pd_attr_max_hp),
                    attr_new:begin_sync_attr(),             %% 此处把血量设置成最大值用于判断角色主场景播放死亡动画是否是由血量引起的
                    put(?pd_hp, MaxHp1),
                    %% 进入主场景添加坐骑速度，如果有坐骑的话
                    ride_mng:geton_ride_for_scene(),
                    mount_tgr:geton_tgr_ride_for_scene(),
                    attr_new:end_sync_attr(),
                    pass;
                _ ->
                    pass
            end,
            % CurrentPid = get(?pd_scene_pid),
            case load_cfg_scene:get_pid(SceneId) of
                ?none ->
                    ?ERROR_LOG("can not get scene ~p pid", [SceneId]),
                    ?err(?none_cfg);
                % CurrentPid ->
                %     ?ERROR_LOG("alreay enter"),
                %     ?err(already_in);
                ScenePid ->
                    MaxHp = attr_new:get_attr_item(?pd_attr_max_hp),
                    MaxMp = attr_new:get_attr_item(?pd_attr_max_mp),
                    Party = case SceneType of
                        ?SC_TYPE_ARENA ->
                            get(pd_party);
                        _ ->
                            put(pd_party, 0),
                            0
                    end,
                    try
                    gen_server:call(ScenePid,
                        {
                            mod, ?SCENE_MOD,
                            {
                                ?enter_scene_msg,
                                #enter_room_args
                                {
                                    x                           = X,                                                %% 坐标
                                    y                           = Y,                                                %% 坐标
                                    dir                         = Dir,                                              %% 方向
                                    player_id                   = get(?pd_id),                                      %% 玩家ID
                                    machine_screen_w            = util:get_pd_field(?pd_vx, 30),                    %3 断线重连时, 这时会出现undefine, 待查
                                    machine_screen_h            = util:get_pd_field(?pd_vy, 20),                    %3 断线重连时, 这时会出现undefine, 待查
                                    hp                          = MaxHp,                                            %% HP
                                    mp                          = MaxMp,                                            %% MP
                                    attr                        = attr_new:get_oldversion_attr(),                   %% 属性
                                    lvl                         = get(?pd_level),                                   %% 等级
                                    shape_data                  = player:pack_view_data(),                          %% 外形数据
                                    equip_shape_data            = equip_system:get_equip_fast_efts(),               %% 装备外形数据
                                    shapeshift_data             = attr_new:get(?pd_shapeshift_data, 0),             %% 外形数据
                                    ride_data                   = attr_new:get(?pd_riding_data, 0),                 %% 坐骑数据
                                    near_limit                  = attr_new:get(?pd_is_near_player_count_set, 0),    %% 周边限制人数
                                    skill_modify                = skill_modify_util:load_longwen_skill_modifies(),  %% 技能修改集
                                    team_id                     = util:get_pd_field(?pd_team_id, 0),                %% 队伍ID
                                    party                       = Party,                                             %% 阵营
                                    from_pid                    = self()
                                }
                            }
                        })
                    of
                        {ok, Agent, {EnterX, EnterY}} ->
                            %% 同步场景数据
                            put(?pd_scene_id, SceneId),
                            put(?pd_scene_pid, ScenePid),
                            put(?pd_idx, Agent#agent.idx),
                            put(?pd_x, EnterX),
                            put(?pd_y, EnterY),
                            ets:insert(?online_player_scene_ets, {get(?pd_id), SceneId}),
                            scene_eng:scene_msg_cast(ScenePid, {scene_player_plugin, enter_scene, Agent}),
                            ?player_send(scene_sproto:pkg_msg(?MSG_SCENE_PLAYER_ENTER, {Agent#agent.idx, Party})),

                            %% 进场景后的后续操作
                            enter_scene_ok_do(SceneId, X, Y),
                            main_ins_util:ins_cost_times(SceneId),
                            case SceneType of
                                ?SC_TYPE_NORMAL ->
                                    erlang:put(?pd_is_in_room, false),
                                    pet_new_mng:pet_new_enter_scene(0, get(?pd_name_pkg), Agent#agent.idx, X, Y),
                                    gwgc_server:sent_gwgc_data_to_client(SceneId),
                                    DigList = load_dig_goods:get_dig_res(SceneId),
                                    ?player_send(scene_sproto:pkg_msg(?MSG_CREATE_DIG_RES_SC, {DigList}));

                                ?SC_TYPE_ARENA ->
                                    ?INFO_LOG("SceneType SC_TYPE_ARENA ~p", [?SC_TYPE_ARENA]),
                                    ok;

                                _ ->
                                    load_enter_scene_progress(SceneId),
                                    erlang:put(?pd_is_in_room, true),
                                    ok
                            end;

                        {error, Why} ->
                            ?ERROR_LOG("player ~p enter scene ~p error ~p", [?pname(), {SceneId, get(?pd_x), get(?pd_y)}, Why]),
                            {error, Why};
                        _E ->
                            ?ERROR_LOG("player ~p enter scene ~p unmatch ~p", [?pname(), {SceneId, get(?pd_x), get(?pd_y)}, _E]),
                            {error, unmatch}
                    catch
                        E:_W ->
                            ?ERROR_LOG("do_enter_scene E------------------:~p",[E])
                    end
            end
    end.

enter_scene_ok_do(SceneId, X, Y) ->
    % 变身buff的处理
    case attr_new:get(?pd_shapeshift_data, 0) of
        0 -> ok;
        CardID ->
            ?DEBUG_LOG("CardID:~p", [CardID]),
            Pidx = get(?pd_idx),
            case load_cfg_card:lookup_item_card_attr_cfg(CardID) of
                #item_card_attr_cfg{buffs = Buffs} ->
                    lists:foreach(
                        fun(BuffId) ->
                            ?DEBUG_LOG("BuffId:~p", [BuffId]),
                            EndTime = attr_new:get(?pd_shapeshift_end_time),
                            ?INFO_LOG("card buff id:~p", [BuffId]),
                            ?player_send(scene_sproto:pkg_msg(?MSG_SCENE_ADD_BUFF, {Pidx, BuffId, EndTime}))
                        end, Buffs);
                _ -> ok
            end
    end,

    init_add_hp_mp(SceneId),
    case SceneId of
        {AreaId, scene_arena, _} ->
            Ret = timer_server:start(5 * 1000, {?MODULE, enter_arena_on_time, [AreaId, X, Y]}),
            attr_new:set(?pd_enter_arena_ontime, Ret),
            ?player_send(scene_sproto:pkg_msg(?MSG_SCENE_AREA_STATE, {AreaId, X, Y, 0, 10, 4, 0}));
        _ -> pass
    end,
    %%player:set_full_hp(),
    %%player:set_full_mp(),
    %% 进场景后广播玩家的装备特效
    equip_system:sync_equip_efts(),
    ok.

enter_arena_on_time(AreaId, X, Y) ->
    case attr_new:get(?pd_enter_arena_ontime, nil) of
        nil -> ok;
        Ret ->
            timer_server:stop(Ret),
            attr_new:set(?pd_enter_arena_ontime, nil)
    end,
    ?player_send(scene_sproto:pkg_msg(?MSG_SCENE_AREA_STATE, {AreaId, X, Y, 0, 10, 4, 1})).


kickout_scene(SceneId, Idx, Hp) ->
    case get(?pd_scene_id) of
        SceneId ->
            case get(?pd_idx) of
                Idx ->
                    put(?pd_hp, Hp),
                    erase(?pd_scene_id),
                    erase(?pd_scene_pid),
                    erase(?pd_idx),
                    erase(?pd_x),
                    erase(?pd_y),
                    ets:delete(?online_player_scene_ets, get(?pd_id)),
                    {SId, Sx, Sy} = get_save_point(),
                    enter_scene_request(SId, Sx, Sy);
                _ ->
                    ?ERROR_LOG("idx not same de ~p ~p", [Idx, get(?pd_idx)])
            end;
        _ ->
            ?ERROR_LOG("scene not same de ~p ~p", [SceneId, get(?pd_scene_id)])
    end.

load_enter_scene_progress(SceneId) ->
    CfgId = load_cfg_scene:get_config_id(SceneId),
    LoadProgressData = misc_cfg:get_load_progress_data_enter_scene(),
    case lists:keyfind(CfgId, 1, LoadProgressData) of
        {_, LoadProgressId} ->
            system_log:info_load_progress(LoadProgressId);
        _ ->
            pass
    end.

load_leave_scene_progress(SceneId) ->
    CfgId = load_cfg_scene:get_config_id(SceneId),
    LoadProgressData = misc_cfg:get_load_progress_data_leave_scene(),
    case lists:keyfind(CfgId, 1, LoadProgressData) of
        {_, LoadProgressId} ->
            system_log:info_load_progress(LoadProgressId);
        _ ->
            pass
    end.

is_check_ok(Idx) ->
    case Idx =:= get(?pd_idx) of
        true ->
            ?true;
        _ ->
            case team_server:is_team_master(get(?pd_id), ?TEAM_TYPE_MAIN_INS) of
                ?true ->
                    ?true;
                _ ->
                    team_svr:is_leader()
            end
    end.

team_scene_add_hp() ->
    {CD} = ?ADD_HP_MP_CD,
    case com_time:now() - get(?pd_attr_add_hp_mp_cd) > CD of
        true ->
            case main_ins_util:ins_cost(add_hp) of
                ok ->
                    ?player_send(scene_sproto:pkg_msg(?MSG_SCENE_ADD_HP_MP, {}));
                {error, Reply} ->
                    ?return_err(Reply)
            end;
        _ ->
            ?return_err(?ERR_CD_LIMIT)
    end.

% get_add_hp_times()->
%     Vip = attr_new:get_vip_lvl(),
%     case load_vip_right:lookup_vip_right_cfg(Vip) of
%         Cfg when is_record(Cfg, vip_right_cfg) ->
%             Cfg#vip_right_cfg.add_hp_limit;
%         _ ->
%             [0]
%     end.
