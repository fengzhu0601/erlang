%%% coding:utf-8
%%%-------------------------------------------------------------------
%%% @author zl
%%% @doc 场景进程和玩家进程的信息交互。
%%%
%%% @end
%%%-------------------------------------------------------------------

-module(scene_player).

-include("load_spirit_attr.hrl").
%%-include("buff.hrl").

-include("player.hrl").
-include("scene.hrl").
-include("scene_agent.hrl").
-include("scene_mod.hrl").
-include("game.hrl").
-include("buff_system.hrl").
-include("skill_struct.hrl").
-include("room_system.hrl").

-export
([
    die/2
    , get_idx_with_pid/1
    , get_idx_with_id/1
    , get_player_with_pid/1
    , is_nearby_point/3
    , is_nearby_point/4
    , kickout_scene/1 %% 剔除场景
    , kickout_all_players/0
    , foreach/1
    , get_all_player_ids/0
    , get_all_player_idx/0
    , get_all_monster_idx/0
    , get_all_unplayer_idx/0
    , get_all_pet_idx/0
    , add_buff/3
    , players_count/0
    , broadcast/1
    , push_idx/1
    , pop_idx/1
    , push_id/1
    , pop_id/1
    , link_player/1
    , unlink_player/1
    , get_all_player_ids_by_scene/1
    , is_notify_teammate/1
]).



-export
([
    handle_call/2
]).

%% cb from scene_aoi
-export
([
    move_step/1
]).

-define(LEFT_POS, 5).
-define(RIGHT_POS, 70).
-define(UP_POS, 13).
-define(DOWN_POS, 17).

%% player
-define(change_st(__NextSt, __A, __DebugMsg),
    (fun(FA) ->
        ?INFO_LOG("[st_change] idx ~p [~p -> ~p] ~p", [FA#agent.idx, FA#agent.state, __NextSt, __DebugMsg]),
        FA#agent{state = __NextSt}
    end)(__A)).


% is_player_on_cur_scene(PlayerId) ->
%     case get(?player_idx(PlayerId)) of
%         ?undefined ->
%             ?false;
%         Idx ->
%             %?DEBUG_LOG("Idx---------------------------------------------------------------:~p",[Idx]),
%             case ?get_agent(Idx) of
%                 ?undefined ->
%                     map_agent:delete(Idx),
%                     erase(?player_idx(PlayerId)),
%                     ?false;
%                 OldAgent ->
%                     %?DEBUG_LOG("OldAgent------------------------------------------------------:~p",[OldAgent]),
%                     OldAgent
%             end
%     end.



get_idx_with_id(PlayerId) ->
    get(?player_idx(PlayerId)).


is_nearby_point(PlayerId, X, Y) ->
    is_nearby_point(PlayerId, X, Y, 5).
is_nearby_point(PlayerId, X, Y, Distance) ->
    case get(?player_idx(PlayerId)) of
        ?undefined ->
            ?ERROR_LOG("can not find player ~p", [PlayerId]),
            false;
        Idx ->
            case ?get_agent(Idx) of
                ?undefined ->
                    ?assert(false), %% can not ocur
                    false;
                #agent{x = Ox, y = Oy} ->
                    ?debug_log_scene_player("Ox, Oy ~p", [{Ox, Oy}]),
                    com_util:get_point_distance({X, Y}, {Ox, Oy}) < Distance
            end
    end.


-spec get_idx_with_pid(pid()) -> {ok, pid()} | _.
get_idx_with_pid(Pid) ->
    com_util:while_break(0,
        get(?pd_player_max_id),
        fun(Idx) ->
            case ?get_agent(Idx) of
                #agent{pid = Pid} ->
                    {break, {ok, Idx}};
                _ ->
                    ok
            end
        end).


-spec get_player_with_pid(pid()) -> {ok, idx()} | _.
get_player_with_pid(Pid) ->
    com_util:while_break(0, get(?pd_player_max_id),
        fun(Idx) ->
            case ?get_agent(Idx) of
                #agent{pid = Pid} ->
                    {break, {ok, Idx}};
                _ -> ok
            end
        end).

get_playerId_with_idx(Idx) ->
    case ?get_agent(Idx) of
        #agent{id = Id} -> Id;
        _ -> ok
    end.

move_step(#agent{x = _X, y = _Y}) ->
    nonused.

init(_) ->
    ?pd_new(?pd_player_max_id, 0),
    ?pd_new(?pd_player_free_id, gb_sets:empty()),
    ok.

uninit(_) ->
    %% TODO kickout
    ok.


-define(scene_cur_players_idx, scene_cur_players_idx).
-define(scene_cur_players_id, scene_cur_players_id).

%% 进场景
handle_call
(
    {_FromPid, _Tag},
    {
        ?enter_scene_msg,
        #enter_room_args
        {
            x                           = X,                                                %% 坐标
            y                           = Y,                                                %% 坐标
            dir                         = Dir,                                              %% 方向
            player_id                   = PlayerId,                                         %% 玩家ID
            machine_screen_w            = Rx,                                               %% 屏宽
            machine_screen_h            = Ry,                                               %% 屏长
            hp                          = Hp,                                               %% HP
            mp                          = Mp,                                               %% MP
            attr                        = Attr,                                             %% 属性
            lvl                         = Level,                                            %% 等级
            shape_data                  = ViewInfo,                                         %% 外形数据
            equip_shape_data            = Efts,                                             %% 装备外形数据
            shapeshift_data             = CardId,                                           %% 外形数据
            ride_data                   = RideId,                                           %% 坐骑数据
            near_limit                  = ViewPlayerCount,                                  %% 周边限制人数
            skill_modify                = SkillModifies,                                    %% 技能修改集
            team_id                     = TeamId,                                           %% 队伍ID
            party                       = Party,                                            %% 阵营
            from_pid                    = FromPid
        }
    }
) ->
    % EnterPoint_ = {X, Y},
    % case is_player_on_cur_scene(PlayerId) of
    %     ?false ->
    %         ?Assert(Rx >= 0 andalso Ry >= 0, "xxxx"),
    %         {X, Y} = if
    %                      EnterPoint_ =:= ?DEFAULT_ENTER_POINT -> get(?pd_cfg_enter);
    %                      true -> EnterPoint_
    %                  end,
    %         %?DEBUG_LOG("XY---------------------------------------:~p",[{X,Y}]),
    %         % ?assert(scene_map:is_walkable({X, Y})),
    %         ?assert(Attr#attr.move_speed > 0),
    link_player(FromPid),
    Agent = scene_agent_factory:build_player(
        #agent{
            id = PlayerId,
            pid = FromPid,
            type = ?agent_player,
            x = X,
            y = Y,
            d = Dir,
            rx = Rx,
            ry = Ry,
            level = Level,
            hp = Hp,
            mp = Mp,
            attr = Attr,
            max_hp = Attr#attr.hp,
            max_mp = Attr#attr.mp,
            enter_view_info = ViewInfo,
            eft_list = Efts,
            cardId = CardId,
            rideId = RideId,
            show_player_count = ViewPlayerCount,
            skill_modifies = SkillModifies,
            skill_modifies_effects = skill_modify_util:get_skill_modify_effects(SkillModifies),
            party = Party
        },
        TeamId
    ),
    push_idx(Agent#agent.idx),
    %push_id(PlayerId),
    {ok, Agent, {X, Y}};
    %     OldAgent ->
    %         %?DEBUG_LOG("OldAgent-----------------------------:~p",[OldAgent]),
    %         {ok, OldAgent, {OldAgent#agent.x, OldAgent#agent.y}}
    % end;

%% 退场景
handle_call
(
    {Pid, _Tag},
    {
        ?leave_scene_msg,
        Idx
    }
) ->
    Agent = ?get_agent(Idx),
    case Agent of
        #agent{id = PlayerId, hp = Hp, x = X, y = Y} = A ->
            pop_idx(Idx),
            %pop_id(PlayerId),
            scene_player_plugin:leave_scene(A),
            scene_agent:leave_scene(A), %% this will be remove the agnet
            unlink_player(Pid),

            %move_debug_tgr:stop(Agent),
            erase(?player_idx(PlayerId)),
            {
                ok,
                Hp,
                X, Y
            };

        undefined ->
            ?INFO_LOG("idx ~p leave scene but not find", [Idx]),
            ret:error(leave_scene_msg)
    end;

handle_call(_, _Msg) ->
    ?err(unknown_msg).


%% 当前位置并向相关地点移动
handle_msg({?move_msg, Idx, SyncX, SyncY, SyncH, {Vx, Vy, _Vh} = _MoveVector}) ->
    pl_util:move(?get_agent(Idx), {SyncX, SyncY, SyncH, Vx, Vy});

handle_msg({robot_random_move_msg, Idx}) ->
    case ?get_agent(Idx) of
        #agent{x = X, y = Y} ->
            {Vx, Vy, _Vz} = get_random_move_vec(X, Y, 0),
            pl_util:move(?get_agent(Idx), {X, Y, 0, Vx, Vy});
        _ ->
            ignore
    end;

handle_msg({continue_move_msg, Idx, PointList}) ->
    case ?get_agent(Idx) of
        #agent{x = SyncX, y = SyncY, h = SyncZ} ->
            lists:foldl(
                fun({TX, TY, TZ}, {X, Y, Z, DelayTime}) ->
                        scene_eng:start_timer(DelayTime, ?MODULE, {continue_move_msg, Idx, X, Y, Z, {TX - X, TY - Y, TZ - Z}}),
                        NewDelayTime = case TX =/= X andalso TY =/= Y of
                            true ->
                                trunc((abs(TX - X) + abs(TY - Y)) / 2) * ?next_45_angle_step_time(150) + DelayTime + 150;
                            _ ->
                                (abs(TX - X) + abs(TY - Y)) * ?next_step_time(150) + DelayTime + 150
                        end,
                        {TX, TY, TZ, NewDelayTime}
                end,
                {SyncX, SyncY, SyncZ, 0},
                PointList
            );
        _ ->
            ignore
    end;

%% 瞬移
handle_msg({large_move, Idx, SyncX, SyncY}) ->
    pl_util:teleport(?get_agent(Idx), {?large_move, SyncX, SyncY});

%% 变速
handle_msg({?switch_move_mode_msg, Idx, Mode}) ->
    case ?get_agent(Idx) of
        ?undefined -> ?ERROR_LOG("can not find idx ~p", [Idx]);
        #agent{} = A -> map_agent:change_speed(A, Mode)
    end;

%% 同步位置且朝指定方向跳跃
handle_msg({?jump_msg, Idx, JumpD, SyncX, SyncY, SyncH}) ->
    % CM = buff_system:is_buff_inter_move(?get_agent(Idx)),
    if
        JumpD == ?D_NONE;JumpD =:= ?D_L;JumpD =:= ?D_R;JumpD =:= ?D_U ->
            pl_util:jump(?get_agent(Idx), {JumpD, SyncX, SyncY, SyncH});
        true ->
            ?ERROR_LOG("jump bad dir ~p", [JumpD])
    end;

%% 瞬移
handle_msg({?move_stop_msg, Idx, {SyncX, SyncY, _SyncH}}) ->
    pl_util:teleport(?get_agent(Idx), {?move_stop, SyncX, SyncY});

%% 瞬移
handle_msg({?skill_move_msg, Idx, SyncX, SyncY}) when Idx > 0 ->
    pl_util:teleport(?get_agent(Idx), {?skill_move_msg, SyncX, SyncY});


%% 刷新属性
handle_msg({?msg_update_attr, Idx, Attr}) ->
    case ?get_agent(Idx) of
        ?undefined -> ok;
        A ->
            ?update_agent(Idx, A#agent
            {
                attr = Attr,
                max_hp = Attr#attr.hp,
                max_mp = Attr#attr.mp
            })
    end;


%% 刷新属性
handle_msg({?msg_update_equip_efts, Idx, Efts}) ->
    case ?get_agent(Idx) of
        ?undefined ->
            ok;
        A ->
            A1 = A#agent
            {
                eft_list = Efts
            },
            map_aoi:broadcast_view_me_agnets(A, scene_sproto:pkg_msg(?MSG_SCENE_EFFECT_UPDATE, {Idx, Efts})),
            ?update_agent(Idx, A1)
    end;

%% 刷新变身卡牌属性
handle_msg({?msg_update_shapeshift_data, Idx, CardId, Career}) ->
    case ?get_agent(Idx) of
        ?undefined ->
            ok;
        A ->
            A1 = A#agent
            {
                cardId = CardId %%变身卡牌的ID
            },
            map_aoi:broadcast_view_me_agnets(A, scene_sproto:pkg_msg(?MSG_SCENE_SHAPESHIFT_UPDATE, {Idx, Career, CardId})),
            ?update_agent(Idx, A1)
    end;

%% 刷新坐骑
handle_msg({?msg_update_ride_data, Idx, RideId}) ->
    case ?get_agent(Idx) of
        ?undefined ->
            ok;
        A ->
            A1 = A#agent
            {
                rideId = RideId
            },
            % ?INFO_LOG("========msg_update_mount_data============="),
            map_aoi:broadcast_view_me_agnets(A, scene_sproto:pkg_msg(?MSG_SCENE_RIDE_UPDATE, {Idx, RideId})),
            % ?INFO_LOG("========msg_update_mount_data============="),
            ?update_agent(Idx, A1)
    end;

%% 重置视野
handle_msg({?resize_view_msg, Idx, Rx, Ry}) when Idx > 0, Rx > 0, Ry > 0 ->
    map_agent:resize_view(Idx, Rx, Ry);

%% 施放技能
handle_msg({?release_skill_msg, Idx, SkillId, SkillDuanId, Dir, SyncX, SyncY, SyncH}) ->
    case cost_if_can_release(?get_agent(Idx), SkillId, SkillDuanId) of
        ok ->
            skill_modify_util:release_skill(?get_agent(Idx), SkillDuanId),
            pl_util:play_skill(?get_agent(Idx), {SkillId, SkillDuanId, Dir, SyncX, SyncY, SyncH});
        {error, Reason} ->
            ?ERROR_LOG("release skill error, reason:~p", [Reason]);
        _ ->
            ignore
    end;

% handle_msg({?release_buff_msg, Idx, SkillId}) ->
%     buff_system:apply_buff_end(?get_agent(Idx), SkillId);
handle_msg({release_skill_end, Idx, SkillId, SkillDuanId}) ->
    skill_modify_util:release_skill_end(?get_agent(Idx), SkillId, SkillDuanId);

% handle_msg({?release_buff_msg, Idx, BreakerId, SkillId}) ->
%     buff_system:apply_buff_break(?get_agent(Idx), ?get_agent(BreakerId), SkillId);
handle_msg({skill_break, Idx, BreakerId, SkillId, SkillDuanId}) ->
    skill_modify_util:skill_break(?get_agent(Idx), ?get_agent(BreakerId), SkillId, SkillDuanId);

handle_msg({scene_monster_agent_sync, Idx, MAId, X, Y, Z}) ->
    MId = util:get_pd_field(master_contrl, 0),
    ?ifdo(MId =:= 0 orelse ?get_agent(Idx) =:= undefined, put(master_contrl, Idx)),
    NId = util:get_pd_field(master_contrl, 0),
%%    ?DEBUG_LOG("sync ---- ~p",[{NId,MAId,X, Y, Z}]),
    ?ifdo(NId =:= Idx,
        (begin
             case ?get_agent(MAId) of
                 #agent{} = A ->
%%                     ?DEBUG_LOG("sync postion:~p",[{MAId,X, Y, Z}]),
                     sync_position_if_need(A, X, Y, Z);
%%                     map_agent:set_position(A, {X, Y, Z});
                 _ -> pass
             end
         end)
    ),
    ok;
%%    buff_system:apply_buff_end(?get_agent(Idx), X, Y, Z);

handle_msg({?msg_update_view_data, Idx, Type, V, ViewInfo}) ->
    case ?get_agent(Idx) of
        ?undefined ->
            ?INFO_LOG("update_view_data idx ~p but can not find", [Idx]);
        _A ->
            A = change_data(Type, _A, V),
            ?if_else(ViewInfo =/= nil,
                ?update_agent(Idx, A#agent{enter_view_info = ViewInfo}),
                ?update_agent(Idx, A)),
            map_aoi:broadcast_view_me_agnets_and_me(A, scene_sproto:pkg_msg(?MSG_SCENE_AGENT_DATA_CHANGE, {Idx, Type, V}))
    end;

handle_msg({?msg_full_hp_mp, Idx}) ->
    case ?get_agent(Idx) of
        ?undefined ->
            ?ERROR_LOG("add player hp but can not find");
        #agent{state = ?st_die} -> ok;
        #agent{max_hp = FullHp} = A ->
            ?update_agent(Idx, A#agent{hp = FullHp}),
            map_aoi:broadcast_view_me_agnets_and_me(A,
                scene_sproto:pkg_msg(?MSG_SCENE_AGENT_DATA_CHANGE,
                    {Idx,
                        ?PL_HP,
                        FullHp}))
    end;

handle_msg({relive, Idx, ReliveType}) when Idx > 0 ->
%%     ?INFO_LOG("Idx = ~p",[Idx]),
    case ?get_agent(Idx) of
        ?undefined ->
            ?WARN_LOG("relive idx ~p but can not find", [Idx]);
        #agent{state = ?st_die, x = X, y = Y, hp = Hp, max_hp = MaxHp} = A ->
            ?assertEqual(Hp, 0),
            ?assertEqual(A#agent.stiff_state, ?none),
            ?assertEqual(A#agent.state_timer, ?none),
            case ReliveType of
                ?ORIGINAL_PLACE_RELIVE ->
                    A1 = ?change_st(?none, A#agent{hp = MaxHp, h = 0}, <<"relive">>),
                    ?update_agent(Idx, A1),
                    map_aoi:broadcast_view_me_agnets_and_me(A1, scene_sproto:pkg_msg(?MSG_SCENE_RELIVE, {Idx, X, Y}));
                ?RELIVE_PLACE_RELIVE ->
                    %% 改成这样
                    %% Point = get_relive_poin(A) 这个函数需要实现
                    %% relive_to_relive_point(A, Point)
                    relive_to_relive_point(A#agent{state = ?none})
            end;
        _A ->
            ?ERROR_LOG("bad relive ~p", [_A])
    end;

handle_msg({scene_relive, Idx}) when Idx > 0 ->
    % ?INFO_LOG("Idx = ~p", [Idx]),
    case ?get_agent(Idx) of
        ?undefined ->
            ?WARN_LOG("relive idx ~p but can not find", [Idx]);
        #agent{x = X, y = Y} = A ->
            % ?INFO_LOG("areana_relive"),
            A1 = A#agent{hp = A#agent.max_hp, mp = A#agent.max_mp, state = ?none},
            ?update_agent(Idx, A1),
            is_notify_teammate(A1),
            map_aoi:broadcast_view_me_agnets_and_me(A1, scene_sproto:pkg_msg(?MSG_SCENE_RELIVE, {Idx, X, Y}));
        _A ->
            ?ERROR_LOG("bad relive ~p", [_A])
    end;

handle_msg({arena_relive, Idx}) when Idx > 0 ->
    case ?get_agent(Idx) of
        ?undefined ->
            ?WARN_LOG("relive idx ~p but can not find", [Idx]);
        #agent{born_x = X, born_y = Y} = A ->
            A1 = A#agent{x = X, y = Y, hp = A#agent.max_hp, mp = A#agent.max_mp, state = ?none},
            ?update_agent(Idx, A1),
            map_aoi:broadcast_view_me_agnets_and_me(A1, scene_sproto:pkg_msg(?MSG_SCENE_RELIVE, {Idx, X, Y}));
        _A ->
            ?ERROR_LOG("bad relive ~p", [_A])
    end;

handle_msg({arena_relive, Idx, {_X, _Y}}) when Idx > 0 ->
    case ?get_agent(Idx) of
        ?undefined ->
            ?WARN_LOG("relive idx ~p but can not find", [Idx]);
        #agent{born_x = BornX, born_y = BornY} = A ->
            % ?INFO_LOG("areana_relive"),
            A1 = A#agent{x = BornX, y = BornY, hp = A#agent.max_hp, mp = A#agent.max_mp, state = ?none},
            ?update_agent(Idx, A1),
            map_aoi:broadcast_view_me_agnets_and_me(A1, scene_sproto:pkg_msg(?MSG_SCENE_RELIVE, {Idx, BornX, BornY}));
        _A ->
            ?ERROR_LOG("bad relive ~p", [_A])
    end;

handle_msg({?msg_pickup_drop_item, Idx, DropId}) when Idx > 0 ->
    case ?get_agent(Idx) of
        ?undefined ->
            ?ERROR_LOG("scene ~p can not find idx ~p", [?pname(), Idx]);
        A ->
            {_PkMode, PlayerId, _TeamId, _FamilyId} = A#agent.pk_info,
            % ?INFO_LOG("========================pk_info:~p", [A#agent.pk_info]),
%%            scene_drop:pick_item(DropId, PlayerId, {A#agent.x, A#agent.y})
            scene_drop:pick_item(DropId, PlayerId)
    end;

%% player process was checked Pkmode
handle_msg({set_pk_mode, Idx, PkMode}) when Idx > 0 ->
    case ?get_agent(Idx) of
        ?undefined ->
            ?ERROR_LOG("can not find player idx ~p", [Idx]);
        A ->
            ?update_agent(Idx, A#agent{pk_info = ?pk_info_set_pk_mode(PkMode, A#agent.pk_info)})
    end;




handle_msg(close_horde) ->
    kickout_all_players();

handle_msg({this_scene_player_effects, EffectId}) ->
    broadcast(?to_client_msg(scene_sproto:pkg_msg(?MSG_SCENE_PLAY_EFFECTS, {EffectId, <<>>})));


handle_msg({update_agent_info, PlayerPid, Career, Type, Arg}) ->
    GetObserverPkg =
        fun
            (#agent{idx = Idx}, TypePar) ->
                case TypePar of
                    1 ->
                        EquBidBin = Arg,
                        <<?MSG_SCENE_AGENT_UPDATE_EQU:16, Idx:16, Career, EquBidBin/binary>>;
                    2 ->
                        TitleId = Arg,
                        <<?MSG_SCENE_AGENT_UPDATE_TITLE:16, Idx:16, TitleId:16>>;
                    3 ->
                        case Arg of
                            0 ->
                                <<?MSG_SCENE_AGENT_UPDATE_GUILD:16, Idx:16, 0>>;
                            {GuildName, BorderId, TotemId} ->
                                <<?MSG_SCENE_AGENT_UPDATE_GUILD:16, Idx:16, (byte_size(GuildName)):8, GuildName/binary, BorderId, TotemId>>
                        end
                end
        end,
    GetMyPkg =
        fun
            (Agent, TypePar) ->
                case TypePar of
                    1 ->
                        EquBidBin = Arg,
                        <<Id:64, NameLen, Name:NameLen/binary, Info:16, TitleId:16, GuildNameLen, Other1/binary>> = Agent#agent.enter_view_info,
                        case GuildNameLen of
                            0 ->
                                <<Id:64, NameLen, Name:NameLen/binary, Info:16, TitleId:16, GuildNameLen, EquBidBin/binary>>;
                            GuildNameLen ->
                                <<GuildName:GuildNameLen/binary, Border, Totem, _Other2/binary>> = Other1,
                                <<Id:64, NameLen, Name:NameLen/binary, Info:16, TitleId:16, GuildNameLen, GuildName/binary, Border, Totem, EquBidBin/binary>>
                        end;
                    2 ->
                        TitleId = Arg,
                        <<Id:64, NameLen, Name:NameLen/binary, Info:16, _OldTitleId:16, Other1/binary>> = Agent#agent.enter_view_info,
                        <<Id:64, NameLen, Name:NameLen/binary, Info:16, TitleId:16, Other1/binary>>;
                    3 ->
                        case Arg of
                            0 ->
                                <<Id:64, NameLen, Name:NameLen/binary, Info:16, TitleId:16, GuildNameLen, Other1/binary>> = Agent#agent.enter_view_info,
                                <<_GuildName:GuildNameLen/binary, _Border, _Totem, _Other2/binary>> = Other1,
                                <<Id:64, NameLen, Name:NameLen/binary, Info:16, TitleId:16, 0, _Other2/binary>>;

                            {GuildName, BorderId, TotemId} ->
                                <<Id:64, NameLen, Name:NameLen/binary, Info:16, TitleId:16, 0, Other1/binary>> = Agent#agent.enter_view_info,
                                <<Id:64, NameLen, Name:NameLen/binary, Info:16, TitleId:16, (byte_size(GuildName)):8, GuildName/binary, BorderId, TotemId, Other1/binary>>
                        end
                end
        end,
%%     ?INFO_LOG("update_agent_info ~p",[PlayerPid]),
    case get_idx_with_pid(PlayerPid) of
        ok -> ok;
        {ok, Idx} ->
            Agent = ?get_agent(Idx),
            map_aoi:broadcast_view_me_agnets(Agent, GetObserverPkg(Agent, Type)),
            ?update_agent(Idx, Agent#agent{enter_view_info = GetMyPkg(Agent, Type)})
    end;


%% 同步场景人数
handle_msg({sync_near_player_limit, Idx, PlayerCount}) ->
    Agent = ?get_agent(Idx),
    ?update_agent(Idx, Agent#agent{show_player_count = PlayerCount}),
    map_aoi:reset_view_agent(Idx);

handle_msg({agent_be_hit, AgentHitIdx, SkillId, SkillDuanId, Dir, ReleaseX, ReleaseY, ReleaseZ, AgentBeHitIdxList}) ->
    map_hit:be_hit(?get_agent(AgentHitIdx), SkillId, SkillDuanId, Dir, ReleaseX, ReleaseY, ReleaseZ, AgentBeHitIdxList);

handle_msg({release_emits_msg, Idx, EmitsId, X, Y, H, Dir, DelayTime, SkillId, SkillDuanId}) ->
    pl_util:play_emits(Idx, {EmitsId, X, Y, H, Dir, DelayTime}, SkillId, SkillDuanId);

handle_msg({emits_die_msg, Idx}) ->
    map_agent:delete(Idx);

handle_msg({build_robot, RobotAgent}) ->
    NewAgent = scene_agent_factory:build_player(RobotAgent),
    push_idx(NewAgent#agent.idx),
    push_id(NewAgent#agent.id);

handle_msg({agent_state_change, Idx, State}) ->
    case Idx > 0 of
        true -> skill_modify_util:add_state_buff(?get_agent(Idx), State);
        _ -> pass
    end;

handle_msg(Msg) ->
    ?ERROR_LOG("unknown msg ~p", [Msg]).

handle_timer(_Ref, {player_relive_timeout, Idx, Id}) ->
    case ?get_agent(Idx) of
        ?undefined -> ok;
        #agent{idx = Idx, id = Id, state = ?st_die} = A ->
%%             ?INFO_LOG("player_relive_timeout relive timeout"),
            relive_to_relive_point(A);
        _ ->
            ?INFO_LOG("player_relive_timeout tiemout player already liveed")
    end;

handle_timer(_Ref, {continue_move_msg, Idx, SyncX, SyncY, SyncH, {Vx, Vy, _Vz}}) ->
    pl_util:move(?get_agent(Idx), {SyncX, SyncY, SyncH, Vx, Vy});

handle_timer(_Ref, Msg) ->
    ?ERROR_LOG("unknown msg ~p", [Msg]).

relive_to_relive_point(#agent{idx = Idx, max_hp = MaxHp} = A) ->
    ?assert(A#agent.idx > 0),
    ?assert(A#agent.state =:= ?st_die),
    case get(?pd_cfg_relive) of
        {X, Y} ->
            A1 = A#agent{state = ?none, hp = MaxHp, h = 0},
            ?update_agent(Idx, A1),
            pl_util:teleport(?get_agent(Idx), {?relive, X, Y});

        {SceneId, X, Y} ->
            ?send_mod_msg(A#agent.pid, player_mng, {?msg_relive, SceneId, X, Y})
    end,
    ok.

die(#agent{state = ?st_die}, _) -> pass;
die(#agent{idx = Idx, pid = Pid, id = Id, hp = _Hp} = _Killed, Killer) ->
    % ?assert(Idx > 0),
    % ?assertEqual(_Hp, 0),
    Killed = map_aoi:stop_if_moving(_Killed),
    scene_player_plugin:die(Killed, Killer),
    scene_agent:cancel_state_timer(Killed#agent.state_timer),
    ?update_agent(Idx, ?change_st(?st_die, Killed#agent{stiff_state = ?none, state_timer = ?none}, <<"die">>)),
    case Killer of
        #agent{idx = KIdx, pid = KPid, id = KId} ->
            ?ifdo
            (
                KIdx > 0,
                ?send_mod_msg(KPid, player_mng, {?msg_kill_player, Id})
            ),
            ?send_mod_msg
            (
                Pid,
                player_mng,
                {?msg_killed_by_agent, KIdx, KId}
            );
        ?killer_device ->
            ?send_mod_msg
            (
                Pid,
                player_mng,
                {?msg_killed_by_device}
            );
        _ ->
            ?ERROR_LOG("killed by unknown killer ~p", [Killer])
    end,
    % ?assert(0 =:= Killed#agent.hp),
    % scene_eng:start_timer(300000, ?MODULE, {player_relive_timeout, Idx, Id}),
    ok.



link_player(PlayerPid) ->
    erlang:link(PlayerPid),
    ok.

unlink_player(Pid) ->
    erlang:unlink(Pid),
    receive
        {'EXIT', Pid, _} -> ok
    after
        0 -> ok
    end.



-spec foreach(FunAgent :: fun((#agent{}) -> _)) -> _.
%% foreach(Fn) ->
%%     com_util:for(0,
%%         get(?pd_player_max_id),
%%         fun(Idx) ->
%%             case ?get_agent(Idx) of
%%                 ?undefined -> ok;
%%                 A -> Fn(A)
%%             end
%%         end).
foreach(Fn) ->
    List = util:get_pd_field(?scene_cur_players_idx, []),
    lists:foreach
    (
        fun(Idx) ->
            case ?get_agent(Idx) of
                ?undefined -> ok;
                A -> Fn(A)
            end
        end,
        List
    ).


%% 得到本场景内所有玩家的id
get_all_player_ids() ->
    util:get_pd_field(?scene_cur_players_id, []).

%% 得到指定场景内所有玩家的id(主城有效)
get_all_player_ids_by_scene(SceneId) ->
    lists:foldl(fun({PlayerId, Scene}, Acc) ->
        if
            Scene =:= SceneId ->
                [PlayerId|Acc];
            true ->
                Acc
        end
    end,
    [],
    ets:tab2list(online_player_scene_ets)).

%% 得到本场景内所有玩家的idx
get_all_player_idx() ->
    util:get_pd_field(?scene_cur_players_idx, []).

%% get_all_player_ids() ->
%%     com_util:fold(0,
%%         get(?pd_player_max_id),
%%         fun(Idx, Acc) ->
%%             case ?get_agent(Idx) of
%%                 ?undefined -> Acc;
%%                 A -> [A#agent.id | Acc]
%%             end
%%         end,
%%         []).

%% 获得所有怪物idx(只限怪物)
get_all_monster_idx() ->
    com_util:fold(
        get(?pd_monster_max_id),
        0,
        fun(Idx, Acc) ->
            case ?get_agent(Idx) of
                Agent when is_record(Agent, agent) andalso Agent#agent.type =:= ?agent_monster ->
                    [Idx | Acc];
                _ ->
                    Acc
            end
        end,
        []
    ).

%% 获得所有宠物idx
get_all_pet_idx() ->
    com_util:fold(
        get(?pd_monster_max_id),
        0,
        fun(Idx, Acc) ->
            case ?get_agent(Idx) of
                Agent when is_record(Agent, agent) andalso Agent#agent.type =:= ?agent_pet ->
                    [Idx | Acc];
                _ ->
                    Acc
            end
        end,
        []
    ).

%% 获得所有非玩家(小于0)的agent的idx
get_all_unplayer_idx() ->
    com_util:fold(
        get(?pd_monster_max_id),
        0,
        fun(Idx, Acc) ->
            case ?get_agent(Idx) of
                Agent when is_record(Agent, agent) ->
                    [Idx | Acc];
                _ ->
                    Acc
            end
        end,
        []
    ).

%% broadcast(Msg) ->
%%     com_util:for(0,
%%         get(?pd_player_max_id),
%%         fun(Idx) ->
%%             case ?get_agent(Idx) of
%%                 ?undefined -> ok;
%%                 A -> A#agent.pid ! Msg
%%             end
%%         end).


broadcast(Msg) ->
    List = util:get_pd_field(?scene_cur_players_idx, []),
    lists:foreach
    (
        fun(Idx) ->
            case ?get_agent(Idx) of
                ?undefined -> ok;
                A -> A#agent.pid ! Msg
            end
        end,
        List
    ).


kickout_scene(Idx) when is_integer(Idx) ->
    ?assert(Idx > 0),
    case ?get_agent(Idx) of
        ?undefined ->
            ok;
        A ->
            kickout_scene(A)
    end;
kickout_scene(#agent{idx = Idx, pid = Pid, id = PlayerId, hp = Hp} = A) ->
    scene_player_plugin:leave_scene(A),
    scene_agent:leave_scene(A),
    unlink_player(Pid),
    erase(?player_idx(PlayerId)),
    Pid ! ?mod_msg(scene_mng, {kickout_scene, get(?pd_scene_id), Idx, Hp}).


kickout_all_players() ->
    foreach(fun kickout_scene/1).


add_buff([], _A, _ReleaseA) ->
    ok;
add_buff(BuffList, A, _ReleaseA) ->
    ?send_mod_msg(A#agent.pid, buff_mng, {add_buff, BuffList}).


%% TODO  not use for each time
players_count() ->
    case erlang:get(?pd_scene_count) of
        undefined -> 0;
        Num -> Num
    end.

%%     com_util:fold
%%     (
%%         0,
%%         get(?pd_player_max_id),
%%         fun(Idx, Acc) ->
%%             case ?get_agent(Idx) of
%%                 ?undefined -> Acc;
%%                 _A -> Acc + 1
%%             end
%%         end,
%%         0
%%     ).


%% 同步前端位置
%% TODO 后台也是用重力加速度,而不是匀速
%% TODO 使用时间戳,如果延迟太大就不需要同步了
-spec sync_position_if_need(_, _, _, _) -> #agent{}.
sync_position_if_need(#agent{x = X, y = Y, h = H} = _A, X, Y, H) ->
    _A;
sync_position_if_need(#agent{idx = Idx, x = X, y = Y} = _A, CX, CY, CH) ->
    ?assert(scene_map:is_walkable(CX, CY)),

    ?ifdo(abs(X - CX) >= 5 orelse abs(Y - CY) >= 5,
        ?ERROR_LOG("idx ~p sync positon offset big  ~p ~p", [Idx, {X, Y}, {CX, CY}])),

    A =
        if
            {X, Y} =/= {CX, CY} ->
                pl_util:teleport(?get_agent(Idx), {?sync_position, CX, CY});
            true ->
                _A
        end,

    A1 = A#agent{h = CH},
    ?update_agent(Idx, A1),
    A1.

change_data(?PL_HP, A, Value) -> A#agent{hp = Value};
change_data(?PL_MP, A, Value) -> A#agent{mp = Value};
change_data(_Type, A, _) -> A.

push_idx(Idx) ->
    List = util:get_pd_field(?scene_cur_players_idx, []),
    List1 = [Idx | List],
    util:set_pd_field(?scene_cur_players_idx, List1).


pop_idx(Idx) ->
    List = util:get_pd_field(?scene_cur_players_idx, []),
    List1 = lists:delete(Idx, List),
    util:set_pd_field(?scene_cur_players_idx, List1).

push_id(Id) ->
    List = util:get_pd_field(?scene_cur_players_id, []),
    List1 = [Id | List],
    util:set_pd_field(?scene_cur_players_id, List1).


pop_id(Id) ->
    List = util:get_pd_field(?scene_cur_players_id, []),
    List1 = lists:delete(Id, List),
    util:set_pd_field(?scene_cur_players_id, List1).

is_notify_teammate(Agent) ->
    case Agent#agent.idx > 0 of
        true ->
            Hp = Agent#agent.hp,
            ?send_mod_msg(Agent#agent.pid, player_mng, {is_notify_teammate, Hp});
        _ ->
            ignore
    end.

cost_if_can_release(?undefined, _, _) -> {error, not_agent};
cost_if_can_release(#agent{idx = Idx}, _, _) when Idx < 0 -> ok;
cost_if_can_release(#agent{idx = Idx, level = Lev, pid = Pid, anger_value = AngerValue, max_anger_value = MaxAngerValue, mp = Mp, skill_modifies_effects = ModifiesEffectList} = Agent, SkillId, SkillDuanId) ->
    CdList = case lists:keyfind(1, 1, ModifiesEffectList) of
        {1, List1} ->
            List1;
        _ ->
            []
    end,
    MpList = case lists:keyfind(5, 1, ModifiesEffectList) of
        {5, List2} ->
            List2;
        _ ->
            []
    end,
    AngerList = case lists:keyfind(7, 1, ModifiesEffectList) of
        {7, List3} ->
            List3;
        _ ->
            []
    end,
    {Ret, NewAgent} = case load_cfg_crown:is_anger_skill(SkillDuanId) of
        true -> %% 皇冠技能
            case AngerValue >= MaxAngerValue of
                true ->
                    ?send_to_client(Pid, crown_new_sproto:pkg_msg(?MSG_CROWN_NEW_ANGER_CHANGE, {0})),
                    {ok, Agent#agent{anger_value = 0}};
                _ ->
                    {{error, anger_value_not_enough}, Agent}
            end;
        _ ->
            Now = com_time:timestamp_msec(),
            Cd = load_cfg_skill:lookup_skill_cfg(SkillDuanId, #skill_cfg.cd),
            NewCd = case lists:keyfind(SkillId, 1, CdList) of
                {SkillId, Msec} ->
                    Cd - Msec;
                _ ->
                    Cd
            end,
            NewCostMp = case load_cfg_skill:lookup_skill_cfg(SkillDuanId, #skill_cfg.cost_mp) of
                CostMp when is_integer(CostMp) ->
                    [A, B, C] = misc_cfg:get_skill_mp_cost(),
                    RealCost = case Lev >= A of
                        true -> trunc(CostMp * math:log(max(0, Lev - A + B)) / math:log(C));
                        _ -> CostMp
                    end,
                    case lists:keyfind(SkillId, 1, MpList) of
                        {SkillId, ReduceMp} ->
                            max(0, RealCost - ReduceMp);
                        _ ->
                            RealCost
                    end;
                _ ->
                    0
            end,
            NewGainAnger = case load_cfg_skill:lookup_skill_cfg(SkillDuanId, #skill_cfg.gain_anger) of
                GainAnger when is_integer(GainAnger) ->
                    case load_cfg_skill:get_skill_type(SkillId) of
                        0 ->
                            GainAnger;
                        _ ->
                            AddAnger = case lists:keyfind(all, 1, AngerList) of
                                {all, Value1} -> GainAnger + Value1;
                                _ -> GainAnger
                            end,
                            case lists:keyfind(SkillId, 1, AngerList) of
                                {SkillId, Value2} ->
                                    AddAnger + Value2;
                                _ ->
                                    AddAnger
                            end
                    end;
                _ ->
                    0
            end,
            case get(pd_agent_skill_info) of
                AgentSkillInfo when is_list(AgentSkillInfo) ->
                    case lists:keyfind(SkillDuanId, 1, AgentSkillInfo) of
                        {SkillDuanId, LastTime} ->
                            % NewSkillInfo = lists:keyreplace(SkillDuanId, 1, AgentSkillInfo, {SkillDuanId, Now}),
                            % put(pd_agent_skill_info, NewSkillInfo),
                            % ?send_to_client(Pid, scene_sproto:pkg_msg(?MSG_SCENE_AGENT_DATA_CHANGE, {Idx, ?PL_MP, Mp - NewCostMp})),
                            % NewAnger = min(MaxAngerValue, AngerValue + NewGainAnger),
                            % ?send_to_client(Pid, crown_new_sproto:pkg_msg(?MSG_CROWN_NEW_ANGER_CHANGE, {NewAnger})),
                            % {ok, Agent#agent{mp = max(0, Mp - NewCostMp), anger_value = NewAnger}};
                            case Now - LastTime >= NewCd - 1000 of     %% 做个1s的延时
                                true -> %% 冷却时间过了
                                    case Mp >= NewCostMp - 11 of
                                        true -> %% 蓝量够
                                            NewSkillInfo = lists:keyreplace(SkillDuanId, 1, AgentSkillInfo, {SkillDuanId, Now}),
                                            put(pd_agent_skill_info, NewSkillInfo),
                                            ?send_to_client(Pid, scene_sproto:pkg_msg(?MSG_SCENE_AGENT_DATA_CHANGE, {Idx, ?PL_MP, Mp - NewCostMp})),
                                            NewAnger = min(MaxAngerValue, AngerValue + NewGainAnger),
                                            ?send_to_client(Pid, crown_new_sproto:pkg_msg(?MSG_CROWN_NEW_ANGER_CHANGE, {NewAnger})),
                                            {ok, Agent#agent{mp = max(0, Mp - NewCostMp), anger_value = NewAnger}};
                                        _ ->
                                            ?ERROR_LOG("SkillDuanId:~p, Mp:~p, NewCostMp:~p", [SkillDuanId, Mp, NewCostMp]),
                                            {{error, mp_not_enough}, Agent}
                                    end;
                                _ ->
                                    ?ERROR_LOG("SkillDuanId:~p, Now:~p, LastTime:~p, NewCd:~p", [SkillDuanId, Now, LastTime, NewCd]),
                                    {{error, cd_not_enough}, Agent}
                            end;
                        _ ->
                            % NewSkillInfo = [{SkillDuanId, Now}] ++ AgentSkillInfo,
                            % put(pd_agent_skill_info, NewSkillInfo),
                            % ?send_to_client(Pid, scene_sproto:pkg_msg(?MSG_SCENE_AGENT_DATA_CHANGE, {Idx, ?PL_MP, Mp - NewCostMp})),
                            % NewAnger = min(MaxAngerValue, AngerValue + NewGainAnger),
                            % ?send_to_client(Pid, crown_new_sproto:pkg_msg(?MSG_CROWN_NEW_ANGER_CHANGE, {NewAnger})),
                            % {ok, Agent#agent{mp = max(0, Mp - NewCostMp), anger_value = NewAnger}}
                            case Mp >= NewCostMp - 11 of
                                true ->
                                    NewSkillInfo = [{SkillDuanId, Now}] ++ AgentSkillInfo,
                                    put(pd_agent_skill_info, NewSkillInfo),
                                    ?send_to_client(Pid, scene_sproto:pkg_msg(?MSG_SCENE_AGENT_DATA_CHANGE, {Idx, ?PL_MP, Mp - NewCostMp})),
                                    NewAnger = min(MaxAngerValue, AngerValue + NewGainAnger),
                                    ?send_to_client(Pid, crown_new_sproto:pkg_msg(?MSG_CROWN_NEW_ANGER_CHANGE, {NewAnger})),
                                    {ok, Agent#agent{mp = max(0, Mp - NewCostMp), anger_value = NewAnger}};
                                _ ->
                                    ?ERROR_LOG("SkillDuanId:~p, Mp:~p, NewCostMp:~p", [SkillDuanId, Mp, NewCostMp]),
                                    {{error, mp_not_enough}, Agent}
                            end
                    end;
                _ ->
                    % put(pd_agent_skill_info, [{SkillDuanId, Now}]),
                    % ?DEBUG_LOG("Mp:~p, NewCostMp:~p", [Mp, NewCostMp]),
                    % ?send_to_client(Pid, scene_sproto:pkg_msg(?MSG_SCENE_AGENT_DATA_CHANGE, {Idx, ?PL_MP, Mp - NewCostMp})),
                    % NewAnger = min(MaxAngerValue, AngerValue + NewGainAnger),
                    % ?send_to_client(Pid, crown_new_sproto:pkg_msg(?MSG_CROWN_NEW_ANGER_CHANGE, {NewAnger})),
                    % {ok, Agent#agent{mp = max(0, Mp - NewCostMp), anger_value = NewAnger}}
                    case Mp >= NewCostMp - 11 of
                        true ->
                            put(pd_agent_skill_info, [{SkillDuanId, Now}]),
                            ?send_to_client(Pid, scene_sproto:pkg_msg(?MSG_SCENE_AGENT_DATA_CHANGE, {Idx, ?PL_MP, Mp - NewCostMp})),
                            NewAnger = min(MaxAngerValue, AngerValue + NewGainAnger),
                            ?send_to_client(Pid, crown_new_sproto:pkg_msg(?MSG_CROWN_NEW_ANGER_CHANGE, {NewAnger})),
                            {ok, Agent#agent{mp = max(0, Mp - NewCostMp), anger_value = NewAnger}};
                        _ ->
                            ?ERROR_LOG("SkillDuanId:~p, Mp:~p, NewCostMp:~p", [SkillDuanId, Mp, NewCostMp]),
                            {{error, mp_not_enough}, Agent}
                    end
            end
    end,
    ?update_agent(Idx, NewAgent),
    Ret.

get_random_move_vec(X, Y, _Z) ->
    {TX, TY} = case get_random_dir() of
        1 ->    %%  上
            Dis = case Y =< ?UP_POS of
                true -> 0;
                _ -> random:uniform(Y - ?UP_POS)
            end,
            {X, Y - Dis};
        2 ->    %% 右上
            Dis = case X >= ?RIGHT_POS orelse Y =< ?UP_POS of
                true -> 0;
                _ -> random:uniform(min(?RIGHT_POS - X, Y - ?UP_POS))
            end,
            {X + Dis, Y - Dis};
        3 ->    %% 右
            Dis = case X >= ?RIGHT_POS of
                true -> 0;
                _ -> random:uniform(?RIGHT_POS - X)
            end,
            {X + Dis, Y};
        4 ->    %% 右下
            Dis = case X >= ?RIGHT_POS orelse Y >= ?DOWN_POS of
                true -> 0;
                _ -> random:uniform(min(?RIGHT_POS - X, ?DOWN_POS - Y))
            end,
            {X + Dis, Y + Dis};
        5 ->    %% 下
            Dis = case Y >= ?UP_POS of
                true -> 0;
                _ -> random:uniform(?UP_POS - Y)
            end,
            {X, Y + Dis};
        6 ->    %% 左下
            Dis = case X =< ?LEFT_POS orelse Y >= ?DOWN_POS of
                true -> 0;
                _ -> random:uniform(min(X - ?LEFT_POS, ?DOWN_POS - Y))
            end,
            {X - Dis, Y + Dis};
        7 ->    %% 左
            Dis = case X =< ?LEFT_POS of
                true -> 0;
                _ -> random:uniform(X - ?LEFT_POS)
            end,
            {X - Dis, Y};
        8 ->    %% 左上
            Dis = case X =< ?LEFT_POS orelse Y =< ?UP_POS of
                true -> 0;
                _ -> random:uniform(min(X - ?LEFT_POS, Y - ?UP_POS))
            end,
            {X - Dis, Y - Dis};
        _ ->
            {X, Y}
    end,
    {TX - X, TY - Y, 0}.

get_random_dir() ->
    com_util:random(1, 8).
