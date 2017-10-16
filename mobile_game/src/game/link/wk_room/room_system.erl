%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 05. 四月 2016 下午3:38
%%%-------------------------------------------------------------------
-module(room_system).
-author("clark").

%% API
-export
([
    build_room/1,
    release_room/0,
    get_room_pid_by_cfg/3,
    get_room_data/0,
    get_room_players/0,
    get_room_monsters/0,
    is_in_room_pd/0,
    set_state/1,
    get_near_pos_player/1,
    get_room_monsters/1,
    count_near_pos_player/1,
    count_near_pos_monster/1,
    get_gwgc_pid/2
]).

-export
([
    on_init_room/1
    , on_uninit_room/0
    , on_enter_room/2
    , on_exit_room/2
    , on_scene_handle_timer/1
    , gearbox_callback/1
    , handle_msg/1
    , handle_timer/2
]).



-include("room_system.hrl").
-include("scene.hrl").
-include("game.hrl").
-include("load_spirit_attr.hrl").
-include("player.hrl").
-include("scene_agent.hrl").
-include("load_cfg_scene.hrl").
-include("scene_event.hrl").
-include("../util/rule_chart/load_rule_chart.hrl").

-define(room_key,           '@room_key@').
-define(room_porsche,       '@room_porsche@').
-define(room_ex_type,       '@room_ex_type@').




-define(ALL_ROOM_MODS,
    [
        scene
        , scene_map
        , scene_player
        , scene_drop
    ]).

get_gwgc_pid(RoomCfgId, PlayerId) ->
    RoomKey =
        #net_room_cfg
        {
            type    = gwgc_type,
            id      = PlayerId,
            cfg_bid = RoomCfgId
        },
    case get_room_pid(RoomKey) of
        nil -> 
            build_room(RoomKey);
        Pid ->
            %Pid ! kill_pid,
            %build_room(RoomKey)
            Pid
    end.

%% 建造房间
build_room(RoomKey = #net_room_cfg{}) ->
    {ok, RoomPid} = otp_util:start_child(room_sup, [RoomKey]),
    RoomPid.

build_room(RoomKey, {IsMatch, Level, PlayerNum}) ->
    {ok, RoomPid} = otp_util:start_child(room_sup, [RoomKey, {IsMatch, Level, PlayerNum}]),
    RoomPid.

%% 获得房间进程号
get_room_pid_by_cfg(RoomCfgId, PlayerId, {IsMatch, Level, PlayerNum}) ->
    %% 不存在则创建
    RoomKey = #net_room_cfg{
        type    = ?net_room_player_type,
        id      = PlayerId,
        cfg_bid = RoomCfgId
    },
    case get_room_pid(RoomKey) of
        nil -> build_room(RoomKey, {IsMatch, Level, PlayerNum});
        Pid -> Pid
    end.

set_state({Dt, Id}) ->
    if
        Dt > 0 -> porsche_gearbox:set_state(?room_porsche, Id, Dt);
        true -> porsche_gearbox:set_state(?room_porsche, Id)
    end.



on_scene_handle_timer({Mod, Msg}) ->
    Mod:handle_timer(0, Msg).

%% ------------------------------------------------
%% self
%% ------------------------------------------------
%% 关闭房间
release_room() ->
    evt_util:send(#room_delete_end{}),
    ok.

%% 获得房间数据
get_room_data() ->
    ok.

%% 获得房间人员
get_room_players() ->
    scene_player:get_all_player_idx().

get_room_monsters() ->
    scene_player:get_all_monster_idx().

get_room_monsters(Flag) ->
    List = scene_player:get_all_monster_idx(),
    lists:foldl
    (
        fun
            (Idx, Acc) ->
                case ?get_agent(Idx) of
                    #agent{room_obj_flag=Flag} -> [Idx | Acc];
                    _ -> Acc
                end
        end,
        [],
        List
    ).

count_near_pos_player({X, Y, Rx, Ry}) ->
    PlayerList = get_room_players(),
    lists:foldl
    (
        fun
            (Idx, Num) ->
                case ?get_agent(Idx) of
                    #agent{x=Px, y=Py} ->
                        Dx = erlang:abs(Px-X),
                        Dy = erlang:abs(Py-Y),
                        if
                            Dx =< Rx andalso Dy =< Ry -> Num+1;
                            true -> Num
                        end;

                    _ ->
                        Num
                end
        end,
        0,
        PlayerList
    ).


count_near_pos_monster({X, Y, Rx, Ry}) ->
    MonsterList = get_room_monsters(),
    lists:foldl
    (
        fun
            (Idx, Num) ->
                case ?get_agent(Idx) of
                    #agent{x=Px, y=Py} ->
                        Dx = erlang:abs(Px-X),
                        Dy = erlang:abs(Py-Y),
                        if
                            Dx =< Rx andalso Dy =< Ry -> Num+1;
                            true -> Num
                        end;

                    _ ->
                        Num
                end
        end,
        0,
        MonsterList
    ).

get_near_pos_player({X, Y}) ->
    PlayerList = get_room_players(),
    {AgentRet, _} =
        lists:foldl
        (
            fun
                (Idx, {Agent, Dt}) ->
                    case ?get_agent(Idx) of
                        #agent{x=Px, y=Py} = Player ->
                            PDt = (Px-X)*(Px-X) + (Py-Y)*(Py-Y),
                            if
                                PDt < Dt -> {Player, PDt};
                                true -> {Agent, Dt}
                            end;

                        _ ->
                            {Agent, Dt}
                    end
            end,
            {nil, 999999999},
            PlayerList
        ),
    AgentRet.

%% 是否房间进程
is_in_room_pd() ->
    case util:get_pd_field(?room_ex_type, 0) of
        0 -> false;
        1 -> true
    end.


%% ------------------------------------------------
%% callback
%% ------------------------------------------------
on_init_room([RoomKey]) ->
    on_init_room([RoomKey, {?FALSE, 0, 1}]);
on_init_room([RoomKey = #net_room_cfg{type = RoomType, id = Id, cfg_bid=RoomCfgId1}, {IsMatch, Level, PlayerNum}]) ->
    RoomCfgId = case RoomType of
        gwgc_type ->
            npc:get_npc_can_challenge(RoomCfgId1);
        _ ->
            RoomCfgId1
    end,
    ?DEBUG_LOG("RoomCfgId1------:~p------RoomCfgId----:~p",[RoomCfgId1, RoomCfgId]),
    mst_ai_lua:init(),
    case load_cfg_scene:lookup_scene_cfg(RoomCfgId) of
        ?none ->
            ret:error(nil_cfg);

        Cfg ->
            random:seed(os:timestamp()),
            [
                begin
                    Mod:init(Cfg)
                end
                || Mod <- ?ALL_ROOM_MODS
            ],

%%             PName = {scene, RoomCfgId},
%%             com_process:init_name(PName),
%%             com_process:init_type(?PT_SCENE),
            erlang:put(?pd_monster_index,   1),
            erlang:put(?pd_monster_max_id,  0),
            erlang:put(?pd_monster_free_id, gb_sets:empty()),
            erlang:put(?pd_monster_free_id, gb_sets:empty()),
            util:set_pd_field(?room_ex_type, 1),

            Charts = load_rule_chart:get_scene_states(RoomCfgId),
            NewCharts = add_default_fun(Charts),
            % ?DEBUG_LOG("NewCharts:~p", [NewCharts]),
            porsche_gearbox:init(?room_porsche, NewCharts, fun room_system:gearbox_callback/1),
            bind_room_pid(RoomKey),
            case IsMatch of
                ?TRUE ->
                    scene_monster:set_init_attr_fn_match_level(Level, PlayerNum);
                _ ->
                    pass
            end,
            erlang:put(is_match_level, {IsMatch, Level, PlayerNum}),
            erlang:put(pd_team_id, Id),
            erlang:put(pd_scene_type, RoomType),
            case RoomType of
                gwgc_type -> erlang:put(pd_ori_team_master, team_svr:get_leader_by_teamid(Id));
                _ -> pass
            end,
            erlang:put(pd_is_monsters_flush_ok, false),
            erlang:put(pd_is_fuben_complete, false),
            erlang:put(pd_all_lock_area_list, []),
            erlang:put(pd_scene_players_damage_list, []),
            rm_system:init_droplist_for_playerId(RoomCfgId),
            timer_server:start(10000, {rm_system, check_empty_room, [5]}),
            scene_eng:start_timer(1000, ?MODULE, {on_time_check}),

%%             if
%%                 RoomType =:= ?net_room_player_type ->
%%                     %% 自动副本有人退出会关闭
%% %%                     ?INFO_LOG("------------ evt_util:sub"),
%%                     % Close =
%%                     %     fun(_) ->
%%                     %         room_system:release_room()
%%                     %     end,
%%                     % evt_util:sub(#room_exit_room{}, Close),
%%                     ok;
%%                 true ->
%% %%                     ?INFO_LOG("RoomType ~p", [RoomType]),
%%                     pass
%%             end,

            evt_util:send(#room_new_end{}),
            ok
    end.







on_uninit_room() ->
    evt_util:call(#room_delete_start{}),
    unbind_room_pid(),
    mst_ai_lua:uninit(),
    ok.


on_enter_room
(
    #enter_room_args
    {
        x                           = ToX,                           %% 坐标
        y                           = ToY,                           %% 坐标
        dir                         = Dir,                           %% 方向
        player_id                   = PlayerId,                      %% 玩家ID
        type                        = Type,
        machine_screen_w            = Vw,                            %% 机器屏幕
        machine_screen_h            = Vh,                            %% 机器屏幕
        hp                          = Hp,                         %% HP
        mp                          = Mp,                         %% MP
        anger                       = Anger,                         %% 怒气值
        attr                        = Attr,                          %% 属性
        lvl                         = LvL,                           %% 等级
        shape_data                  = ShapeData,                     %% 外形数据
        equip_shape_data            = EquShapeData,                  %% 装备外形数据
        shapeshift_data             = SSData,                        %% 外形数据
        ride_data                   = RideData,                      %% 坐骑数据
        near_limit                  = NLimit,                        %% 周边限制人数
        skill_modify                = SkillModify,
        from_pid                    = FromPid
    },
    _FromPid
) ->
    case erlang:get(?player_idx(PlayerId)) of
        ?undefined ->
            {X, Y} =
            if
                {ToX, ToY} =:= ?DEFAULT_ENTER_POINT -> 
                    get(?pd_cfg_enter);
                true -> 
                    {ToX, ToY}
            end,
            ?assert(scene_map:is_walkable({X, Y})),
            ?assert(Attr#attr.move_speed > 0),
%%             scene_player:link_player(FromPid),
            Agent = scene_agent_factory:build_player
            (
                #agent{
                    id = PlayerId,
                    pid = FromPid,
                    type = Type,
                    x = X,
                    y = Y,
                    d = Dir,
                    rx = Vw,
                    ry = Vh,
                    level = LvL,
                    hp = Hp,
                    mp = Mp,
                    anger_value = Anger,
                    attr = Attr,
                    max_hp = Attr#attr.hp,
                    max_mp = Attr#attr.mp,
                    enter_view_info = ShapeData,
                    eft_list = EquShapeData,
                    cardId = SSData,
                    rideId = RideData,
                    show_player_count = NLimit,
                    skill_modifies = SkillModify,
                    skill_modifies_effects = skill_modify_util:get_skill_modify_effects(SkillModify),
                    party = 1
                }
            ),
            Idx = Agent#agent.idx,
            scene_player:push_idx(Idx),
            scene_player:push_id(PlayerId),
            ?send_to_client(FromPid, scene_sproto:pkg_msg(?MSG_SCENE_AGENT_DATA_CHANGE, {Idx, 22, Hp})),    %% 通知血量
            ?send_to_client(FromPid, scene_sproto:pkg_msg(?MSG_SCENE_AGENT_DATA_CHANGE, {Idx, 27, Mp})),    %% 通知蓝量
            ?send_to_client(FromPid, crown_new_sproto:pkg_msg(?MSG_CROWN_NEW_ANGER_CHANGE, {Anger})),           %% 通知怒气值
            skill_modify_util:add_crown_skill_modify_buff(Agent),
            case get(pd_transport_door) of
                DoorId when is_integer(DoorId) ->
                    ?send_to_client(FromPid, main_instance_sproto:pkg_msg(?MSG_MAIN_INSTANCE_TRANSPORT_DOOR_ACTIVE, {DoorId}));
                _ ->
                    ignore
            end,
            main_ins_team_mod:notify_members_idx(PlayerId, Idx),
            case scene_player:get_all_player_idx() of
                List when length(List) =:= 1 ->
                    TeamId = get(pd_team_id),
                    main_ins_team_mod:first_enter_is_master(PlayerId, TeamId, get(pd_scene_type));
                _W ->
                    ignore
            end,
            evt_util:call(#room_enter_room{player_idx = Idx}),
            {ok, Agent, {X, Y}};

        _Idx ->
            ?INFO_LOG("player ~p player_idx is exist roon ~p", [PlayerId, util:get_pd_field(?room_key, nil)]),
            ret:error(enter_scene_msg)
    end.

on_exit_room
(
    #exit_room_args
    {
        idx = Idx
    },
    _FromPid
) ->
    case ?get_agent(Idx) of
        #agent{idx = Idx, pid = _Pid, id = PlayerId, hp = Hp, x = X, y = Y} = Agent ->
            evt_util:call(#room_exit_room{player_idx = Idx}),

            scene_agent:leave_scene(Agent),
            scene_player:pop_idx(Idx),
            scene_player:pop_id(PlayerId),
%%             scene_player:unlink_player(Pid),
            erase(?player_idx(PlayerId)),
            {
                ok,
                Hp,
                X, Y
            };

        undefined ->
            info_log:push_error(["idx ~p leave scene but not find", Idx]),
            ret:error(enter_scene_msg)
    end.


handle_msg({start_next_scene_id, PlayerId, Idx, PlayerPid, NextSceneId, IsLastScene}) ->
    AgentInfo = case ?get_agent(Idx) of
        Agent when is_record(Agent, agent) ->
            {Agent#agent.hp, Agent#agent.mp, Agent#agent.anger_value};
        _ ->
            {0, 0, 0}
    end,
    start_next_scene(PlayerId, PlayerPid, NextSceneId, IsLastScene, AgentInfo);
handle_msg({team_fuben_complete, Id, Idx, PlayerPid, IsInsComplete, WaveNum, DoubleHit, ShouJi, PassTime, _ReliveNum, A}) ->
    case get(pd_is_fuben_complete) of
        true ->
            HpPercent = case ?get_agent(Idx) of
                Agent when is_record(Agent, agent) ->
                    case Agent#agent.hp =:= 0 of
                        true -> 0;
                        _ -> min(100, trunc((Agent#agent.hp / Agent#agent.max_hp) * 100))
                    end;
                _ ->
                    1
            end,
            NewPassTime = case abs(PassTime - get(pd_pass_time)) =< 20 of
                true -> PassTime;
                _ -> get(pd_pass_time)
            end,
            MaxPlayerId = case get(pd_scene_players_damage_list) of
                List when is_list(List) ->
                    case lists:last(lists:keysort(3, List)) of
                        {_, PlayerId, _} -> PlayerId;
                        _ -> Id
                    end;
                _ -> 
                    Id
            end,
            PlayerPid ! ?mod_msg(player_room_part, {team_complete, IsInsComplete, WaveNum, DoubleHit, ShouJi, NewPassTime, HpPercent, MaxPlayerId, A});
        _ ->
            ?ERROR_LOG("fuben not complete")
    end;
handle_msg({fuben_complete_msg, PassTime}) ->
    put(pd_is_fuben_complete, true),
    put(pd_pass_time, PassTime),
    ok;
handle_msg(Msg) ->
    ?err({unknown_msg, Msg}).

handle_timer(_, {on_time_check}) ->
    PlayerIdxList = scene_player:get_all_player_idx(),
    %% 定时回蓝回血
    lists:foreach(
        fun(Idx) ->
                case ?get_agent(Idx) of
                    #agent{hp = Hp, max_hp = MaxHp, mp = Mp, max_mp = MaxMp} = Agent ->
                        Agent1 = case Hp < MaxHp of
                            true ->
                                AddHp = trunc(max(MaxHp * 1 / 1000, 1)),
                                NewHp = min(Hp + AddHp, MaxHp),
                                Agent#agent{hp = NewHp};
                            _ ->
                                Agent
                        end,
                        Agent2 = case Mp < MaxMp of
                            true ->
                                AddMp = trunc(max(MaxMp * 10 / 1000, 1)),
                                NewMp = min(Mp + AddMp, MaxMp),
                                Agent1#agent{mp = NewMp};
                            _ ->
                                Agent1
                        end,
                        ?update_agent(Idx, Agent2);
                    _ ->
                        ignore
                end
        end,
        PlayerIdxList
    ),
    %% 检查是否有宠物光环buff
    PetIdxList = scene_player:get_all_pet_idx(),
    skill_modify_util:check_is_add_pet_halo_buff(PlayerIdxList, PetIdxList, com_time:now()),
    scene_eng:start_timer(1000, ?MODULE, {on_time_check});
handle_timer(_, Msg) ->
    ?ERROR_LOG("unknown msg ~p", [Msg]).

%% ------------------------------------------------
%% private
%% ------------------------------------------------
%% 绑定房间
bind_room_pid(RoomKey) ->
    erlang:put(?room_key, RoomKey),
    my_ets:set(RoomKey, self()).

%% 解绑房间
unbind_room_pid() ->
    case util:get_pd_field(?room_key, nil) of
        nil ->
            pass;

        RoomKey ->
            util:set_pd_field(?room_key, nil),
            my_ets:delete(RoomKey)
    end.

%% 获得房间进程号
get_room_pid(RoomKey) ->
    my_ets:get(RoomKey, nil).


gearbox_callback({Can, TrueDo, FalseDo}) ->
    %% must
    ok = porsche_gearbox:evt_do(TrueDo, ?room_cfg_must, false),

    %% 条件
    case porsche_gearbox:evt_can(Can, ?room_cfg_can, false) of
        true ->
            %% 动作
            ok = porsche_gearbox:evt_do(TrueDo, ?room_cfg_do, false),
            FunKey = porsche_gearbox:get_cur_funckey(),
            IsOverTime = porsche_gearbox:is_over_times(),
            if
                IsOverTime ->
                    ok = porsche_gearbox:evt_do(TrueDo, ?room_cfg_done, false),
                    porsche_gearbox:add_func_times(FunKey);

                true ->
                    pass
            end,
            ok;

        _ ->
            ok = porsche_gearbox:evt_do(FalseDo, ?room_cfg_do, false),
            ret:error(cant)
    end.

start_next_scene(_PlayerId, PlayerPid, NextSceneId, _IsLastScene, AgentInfo) ->
    TeamId = get(pd_team_id),
    MatchInfo = get(is_match_level),
    case room_system:get_room_pid_by_cfg(NextSceneId, TeamId, MatchInfo) of
        Pid when is_pid(Pid) ->
            main_ins_team_mod:insert_new_scene(TeamId, NextSceneId),
            PlayerPid ! ?mod_msg(player_room_part, {start_next_scene, Pid, NextSceneId, AgentInfo});
        _ ->
            ignore
    end.

add_default_fun(Charts) ->
    GetEvent =
        fun(ListCount) ->
            #rule_porsche_event
            {
                key = ListCount,
                evt_id = ?PLAYER_MOVEING,
                times = -1,
                can = [],
                true =
                [
                    #rule_porsche_do
                    {
                        key = 10001,
                        func = can_do_lock_area,
                        par = nil
                    }
                ],
                false = []
            }
        end,
    {ARet, _} =
        lists:foldl
        (
            fun(#rule_porsche_state{evt_list = EvtList} = Chart, {Ret, Count}) ->
                Item = GetEvent(Count),
                Ret1 = Ret ++ [Chart#rule_porsche_state{evt_list = EvtList ++ [Item]}],
                {Ret1, Count+1}
            end,
            {[], 10000},
            Charts
        ),
    ARet.
