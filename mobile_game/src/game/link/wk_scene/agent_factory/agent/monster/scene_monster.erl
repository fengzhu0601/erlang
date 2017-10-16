%%% coding:utf-8
%%%-------------------------------------------------------------------
%%% @author zl
%%% @doc 怪物
%%% 
%%%      随机显示
%%%
%%% @end
%%%-------------------------------------------------------------------

-module(scene_monster).

-include_lib("config/include/config.hrl").

-include("inc.hrl").
-include("skill_struct.hrl").
-include("load_spirit_attr.hrl").
-include("pet.hrl").
-include("scene.hrl").
-include("scene_agent.hrl").
-include("scene_mod.hrl").
-include("scene_monster.hrl").
-include("load_cfg_monster_group.hrl").
-include("buff_system.hrl").

%% API for scene
-export
([
    new_monster/4
    %%,new_monster/5
    , new_skill_obj/7
    , monster_enter_scene/1
    , monster_enter_scene/3
    , leave_scene/1
    , die/2
    , die/1

    , take_monster_idx/0 %% 获得下一个怪物的idx
    , monsters_count/0 %% 返回场景中怪物的数量
    , add_hp/2
    , del_hp/2
    , full_hp/1

    , get_spirit/2
    , add_spirit/3
    , del_spirit/3

    , get_spirit_by_sat/2

    , add_spirit_by_sat/3
    , del_spirit_by_sat/3

    , set_m_enemy/2
    , del_m_enemy/1

    , under_attack/2
    , stiff_end/1
    , break_releasing_skill/2

    , set_init_monster_list/1

    , set_init_attr_fn_match_level/2
    , bind_room_flag/2
]).

%% cb from scene_aoi
-export(
[
    ai_action/2
    , ai_action/3
    , move_step/1
]).

-define(pd_init_monster_list, '$init_monster_list$').
-define(pd_init_monster_attr_fn, '$init_monster_attr_fn$').

-spec set_init_monster_list([{MonsterId :: _, X :: _, Y :: _, Dir :: _}]) -> no_return().
set_init_monster_list(MonsterList) ->
    ?pd_new(?pd_init_monster_list, MonsterList).

%% 根据玩家等级匹配, 匹配公式：默认属性id - 1 + 玩家等级, 再根据玩家人数计算属性倍数
set_init_attr_fn_match_level(Level, PlayerNum) ->
    set_init_attr_fn(
        fun(#monster_cfg{attr = DefaultAttrId} = _MonsterCfg) ->
            TempAttr = case load_spirit_attr:lookup_attr(DefaultAttrId - 1 + Level) of
                Attr when is_record(Attr, attr) ->
                    Attr;
                _ ->
                    ?ERROR_LOG("can not find attr cfg, attr_id:~p", [DefaultAttrId - 1 + Level]),
                    load_spirit_attr:lookup_attr(DefaultAttrId)
            end,
            AttrTimesList = misc_cfg:get_attr_times_by_player_num(),
            NewAttr = case lists:keyfind(PlayerNum, 1, AttrTimesList) of
                {PlayerNum, List} ->
                    get_new_attr(TempAttr, List);
                _ ->
                    TempAttr
            end,
            {Level, NewAttr}
        end
    ).

%% Fun(#monster_cfg{}) -> Attr
set_init_attr_fn(Fn) when is_function(Fn) ->
    ?pd_new(?pd_init_monster_attr_fn, Fn).

get_new_attr(Attr, List) ->
    #attr{
        id = Attr#attr.id,
        hp = case lists:keyfind(?PL_ATTR_HP, 1, List) of
            {_, Times} -> trunc(Attr#attr.hp * Times);
            _ -> Attr#attr.hp
        end,
        mp = case lists:keyfind(?PL_ATTR_MP, 1, List) of
            {_, Times} -> trunc(Attr#attr.mp * Times);
            _ -> Attr#attr.mp
        end,
        sp = case lists:keyfind(?PL_ATTR_SP, 1, List) of
            {_, Times} -> trunc(Attr#attr.sp * Times);
            _ -> Attr#attr.sp
        end,
        np = case lists:keyfind(?PL_ATTR_NP, 1, List) of
            {_, Times} -> trunc(Attr#attr.np * Times);
            _ -> Attr#attr.np
        end,
        strength = case lists:keyfind(?PL_ATTR_STRENGTH, 1, List) of
            {_, Times} -> trunc(Attr#attr.strength * Times);
            _ -> Attr#attr.strength
        end,
        intellect = case lists:keyfind(?PL_ATTR_INTELLECT, 1, List) of
            {_, Times} -> trunc(Attr#attr.intellect * Times);
            _ -> Attr#attr.intellect
        end,
        nimble = case lists:keyfind(?PL_ATTR_NIMBLE, 1, List) of
            {_, Times} -> trunc(Attr#attr.nimble * Times);
            _ -> Attr#attr.nimble
        end,
        strong = case lists:keyfind(?PL_ATTR_STRONG, 1, List) of
            {_, Times} -> trunc(Attr#attr.strong * Times);
            _ -> Attr#attr.strong
        end,
        atk = case lists:keyfind(?PL_ATTR_ATK, 1, List) of
            {_, Times} -> trunc(Attr#attr.atk * Times);
            _ -> Attr#attr.atk
        end,
        def = case lists:keyfind(?PL_ATTR_DEF, 1, List) of
            {_, Times} -> trunc(Attr#attr.def * Times);
            _ -> Attr#attr.def
        end,
        crit = case lists:keyfind(?PL_ATTR_CRIT, 1, List) of
            {_, Times} -> trunc(Attr#attr.crit * Times);
            _ -> Attr#attr.crit
        end,
        block = case lists:keyfind(?PL_ATTR_BLOCK, 1, List) of
            {_, Times} -> trunc(Attr#attr.block * Times);
            _ -> Attr#attr.block
        end,
        pliable = case lists:keyfind(?PL_ATTR_PLIABLE, 1, List) of
            {_, Times} -> trunc(Attr#attr.pliable * Times);
            _ -> Attr#attr.pliable
        end,
        pure_atk = case lists:keyfind(?PL_ATTR_PURE_ATK, 1, List) of
            {_, Times} -> trunc(Attr#attr.pure_atk * Times);
            _ -> Attr#attr.pure_atk
        end,
        break_def = case lists:keyfind(?PL_ATTR_BREAK_DEF, 1, List) of
            {_, Times} -> trunc(Attr#attr.break_def * Times);
            _ -> Attr#attr.break_def
        end,
        atk_deep = case lists:keyfind(?PL_ATTR_ATK_DEEP, 1, List) of
            {_, Times} -> trunc(Attr#attr.atk_deep * Times);
            _ -> Attr#attr.atk_deep
        end,
        atk_free = case lists:keyfind(?PL_ATTR_ATK_FREE, 1, List) of
            {_, Times} -> trunc(Attr#attr.atk_free * Times);
            _ -> Attr#attr.atk_free
        end,
        atk_speed = case lists:keyfind(?PL_ATTR_ATK_SPEED, 1, List) of
            {_, Times} -> trunc(Attr#attr.atk_speed * Times);
            _ -> Attr#attr.atk_speed
        end,
        precise = case lists:keyfind(?PL_ATTR_PRECISE, 1, List) of
            {_, Times} -> trunc(Attr#attr.precise * Times);
            _ -> Attr#attr.precise
        end,
        thunder_atk = case lists:keyfind(?PL_ATTR_THUNDER_ATK, 1, List) of
            {_, Times} -> trunc(Attr#attr.thunder_atk * Times);
            _ -> Attr#attr.thunder_atk
        end,
        thunder_def = case lists:keyfind(?PL_ATTR_THUNDER_DEF, 1, List) of
            {_, Times} -> trunc(Attr#attr.thunder_def * Times);
            _ -> Attr#attr.thunder_def
        end,
        fire_atk = case lists:keyfind(?PL_ATTR_FIRE_ATK, 1, List) of
            {_, Times} -> trunc(Attr#attr.fire_atk * Times);
            _ -> Attr#attr.fire_atk
        end,
        fire_def = case lists:keyfind(?PL_ATTR_FIRE_DEF, 1, List) of
            {_, Times} -> trunc(Attr#attr.fire_def * Times);
            _ -> Attr#attr.fire_def
        end,
        ice_atk = case lists:keyfind(?PL_ATTR_ICE_ATK, 1, List) of
            {_, Times} -> trunc(Attr#attr.ice_atk * Times);
            _ -> Attr#attr.ice_atk
        end,
        ice_def = case lists:keyfind(?PL_ATTR_ICE_DEF, 1, List) of
            {_, Times} -> trunc(Attr#attr.ice_def * Times);
            _ -> Attr#attr.ice_def
        end,
        move_speed = case lists:keyfind(?PL_ATTR_MOVE_SPEED, 1, List) of
            {_, Times} -> trunc(Attr#attr.move_speed * Times);
            _ -> Attr#attr.move_speed
        end,
        run_speed = case lists:keyfind(?PL_ATTR_RUN_SPEED, 1, List) of
            {_, Times} -> trunc(Attr#attr.run_speed * Times);
            _ -> Attr#attr.run_speed
        end,
        suck_blood = case lists:keyfind(?PL_ATTR_SUCK_BLOOD, 1, List) of
            {_, Times} -> trunc(Attr#attr.suck_blood * Times);
            _ -> Attr#attr.suck_blood
        end,
        reverse = case lists:keyfind(?PL_ATTR_REVERSE, 1, List) of
            {_, Times} -> trunc(Attr#attr.reverse * Times);
            _ -> Attr#attr.reverse
        end
    }.

init(_Cfg) ->
    erlang:put(?pd_monster_index, 1),
    erlang:put(?pd_monster_max_id, 0),
    erlang:put(?pd_monster_free_id, gb_sets:empty()),
    %% random monster from monster groups
    %% ?INFO_LOG("pd_cfg_id:~p", [get(?pd_cfg_id)]),
    %% case load_cfg_monster_group:lookup_file_scene_monster_cfg(get(?pd_cfg_id)) of
    %%     ?none ->
    %%         ?debug_log_scene_monster("needless init monster ~p", [get(?pd_scene_id)]),
    %%         ok;
    %%     KeyList ->
    %%         AllMonsterCfg = [load_cfg_monster_group:lookup_scene_monster_cfg(Id) || Id <- KeyList],
    %%         Groups = lists:usort([Cfg#scene_monster_cfg.group_id || Cfg <- AllMonsterCfg]),
    %%         Trees = gb_trees:from_orddict([{Gid, load_cfg_monster_group:random_monster(Gid)} || Gid <- Groups]),
    %%         MonsterList = [{gb_trees:get(Gid, Trees), X, Y, Dir} || #scene_monster_cfg{group_id = Gid, x = X, y = Y, direction = Dir} <- AllMonsterCfg],
    %%         % ?INFO_LOG("----------------------== scene_monster all monsters ~p", [MonsterList]),
    %%         init_monster(MonsterList),
    %%         ok
    %% end,
    %%%% create other monster
    case get(?pd_init_monster_list) of
        ?undefined -> ok;
        ML -> init_monster(ML)
    end,
    ok.


uninit(_) -> ok.


init_monster(MonsterList) when is_list(MonsterList) ->
    %% TODO
    lists:foreach(
        fun({MonsterId, X, Y, Dir}) ->
                ?Assert2(scene_map:is_walkable(X, Y), "monster id ~p point ~p", [MonsterId, {X, Y}]),
                case scene_monster:is_exist_monster_cfg(MonsterId) of
                    true ->
                        % ?INFO_LOG("init_monster ~p", [{MonsterId, X, Y, Dir}]),
                        case new_monster(MonsterId, X, Y, Dir) of
                            Monster when is_record(Monster, agent) ->
                                % ?INFO_LOG("init_monster ~p ok", [{MonsterId, X, Y, Dir}]),
                                ai_action( ?event_start, monster_enter_scene(Monster) );
                            _ ->
                                pass
                        end;
                    false ->
                        ?ERROR_LOG("can not find monster ~p cfg", [MonsterId])
                end
        end,
        MonsterList
    ).

%% @doc 生成一个技能释放物
new_skill_obj
(
    A, SkillId, D,
    #skill_release_obj_cfg{id = SkillObjId} = ObjCfg,
    X, Y, _H
) ->
    Idx = A#agent.idx,
    Cfg = load_cfg_monster_group:lookup_monster_cfg(ObjCfg#skill_release_obj_cfg.id),
    erlang:put(?pd_monster_cfg(SkillObjId), Cfg),
    _ObjAgnet =
        #agent
        {
            pid = Idx,
            id = SkillObjId,
            type = ?agent_skill_obj,
            d = D,
            h = _H,
            state = ?st_skill_obj,
            stiff_state = ?ss_ba_ti,
            is_unbeatable = ?true,
            x = X,
            y = Y,
            rx = 1, ry = 1,
            hp = 1,
            max_hp = 1,
            attr = load_spirit_attr:lookup_attr(Cfg#monster_cfg.attr),
            level = 1,
            pk_info =
            if
                Idx > 0 ->
                    ?make_monster_pk_info(Idx);  %% TODO 组队模式 {player, idx}
                true ->
                    ?make_monster_pk_info(-1)
            end,
            move_vec = move_util:create_move_vector(erlang:make_tuple(4, ObjCfg#skill_release_obj_cfg.speed)),
            enter_view_info = <<?MT_SKILL_OBJ, SkillObjId:32>>,
            ex = #m_ex
            {
                ai_mod = monster_ai_skill_obj,
                ai_data = SkillId
            }
        },
    ok.

%% @doc 生成一个新的 monster agent ,并没有进入场景
new_monster(MonsterId, X, Y, Dir) ->
    Index = util:get_pd_field(?pd_monster_index, 0) + 1,
    util:set_pd_field(?pd_monster_index, Index),
    ?pd_new(?pd_monster_born(Index), {X, Y, Dir}),
    ?pd_new(?pd_monster_die_count(Index), 0),
    new_monster(Index, MonsterId, X, Y, Dir).

new_monster(Index, MonsterId, X, Y, Dir) ->
    Cfg = case erlang:get(?pd_monster_cfg(MonsterId)) of
        ?undefined ->
            lookup_monster_cfg(MonsterId);
        _Cfg ->
            _Cfg
    end,
    case Cfg#monster_cfg.type of
        ?MT_CONVOY ->
            State = ?st_convoy,
            AI = monster_ai_convoy;
        _ ->
            State = if
                Cfg#monster_cfg.stroll_range =:= 0 andalso Cfg#monster_cfg.guard_range =:= 0 ->
                    ?st_stand;
                true ->
                    ?st_stroll_wait
            end,
            AI = monster_ai_default %% TODO check is exist
    end,
    case is_record(Cfg, monster_cfg) of
        true ->
            put(?pd_monster_cfg(MonsterId), Cfg),
            R = Cfg#monster_cfg.guard_range,
            {Level, Attr} = case get(?pd_init_monster_attr_fn) of
                ?undefined ->
                    {Cfg#monster_cfg.level,
                    load_spirit_attr:lookup_attr(Cfg#monster_cfg.attr)};
                Fn ->
                    Fn(Cfg)
            end,
            MaxHp = Attr#attr.hp,
            #agent{
                pid = Index,
                id = MonsterId,
                state = State,
                type = ?agent_monster,
                d = Dir,
                h = 0,
                % stiff_state = case Cfg#monster_cfg.ba_ti of
                %     ?TRUE ->
                %         ?ss_ba_ti;
                %     _ ->
                %         ?none
                % end,
                x = X,
                y = Y,
                rx = R, ry = R,
                hp = MaxHp,
                max_hp = MaxHp,
                attr = Attr,
                level = Level,
                pk_info = ?make_monster_pk_info(-1),
                move_vec = move_util:create_move_vector(erlang:make_tuple(4, Attr#attr.move_speed)),
                enter_view_info = <<(Cfg#monster_cfg.type), MonsterId:32>>,
                ex = #m_ex{ai_mod = AI}
            };
        _ ->
            ?ERROR_LOG("can not find monster cfg with monster_id = ~p", [MonsterId]),
            {error, can_not_find_monster_cfg}
    end.

%% monster idx < 0
take_monster_idx() ->
    % CurIdx = get(?pd_monster_max_id),
    % NewIdx = CurIdx - 1,
    % put(?pd_monster_max_id, NewIdx),
    % NewIdx.
    FreeIdxSets = get(?pd_monster_free_id),
    case gb_sets:is_empty(FreeIdxSets) of
        true ->
            Idx = get(?pd_monster_max_id) - 1,
            put(?pd_monster_max_id, Idx),
            Idx;
        _ ->
            {Idx, FreeIdxSets2} = gb_sets:take_largest(FreeIdxSets),
            put(?pd_monster_free_id, FreeIdxSets2),
            Idx
    end.


%% HACK quick
monsters_count() ->
    com_util:fold(get(?pd_monster_max_id) - 1, %% 0,-1 crash
        -1,
        fun(Idx, Count) ->
            case ?get_agent(Idx) of
                _Agent = #agent{type = ?agent_monster} ->
                    Count + 1;
                _E ->
                    Count
            end
        end,
        0).


%获取附近的怪物 副本专用
%%get_nearby_monster(PlayerId,X,Y,BeginIdx,Rx,Pid) ->
%%PlayerId,X,Y,Rx,
%%case ?get_agent(BeginIdx) of
%%?undefined ->
%%Have=0,
%%?send_to_client(Pid, << ?MSG_SCENE_NEARBY_MONSTER_POS,Have:8 >>);
%%A ->
%%MonsterX=A#agent.x,MonsterY=A#agent.y,
%%Have=1,
%%case erlang:is_process_alive(Pid) of
%%?false ->
%%NoHave=0,
%%?send_to_client(Pid, << ?MSG_SCENE_NEARBY_MONSTER_POS,NoHave:8 >>);
%%?true ->
%%?send_to_client(Pid, << ?MSG_SCENE_NEARBY_MONSTER_POS,Have:8,MonsterX:16,MonsterY:16>> )
%%end
%%end.


%% 复活 Or first enter
monster_enter_scene(A) ->
    monster_enter_scene(A, A#agent.x, A#agent.y).
monster_enter_scene(#agent{id = MonsterId} = _A, X, Y) ->
    %% 进入场景
    case (erlang:get(?pd_monster_cfg(MonsterId)))#monster_cfg.show_group of
        ?none ->
            monster_enter_scene__(_A, X, Y);
        ShowGroup ->
            {_ShowId, Daily} = load_cfg_monster_show:random_show_id(ShowGroup),
            scene_eng:start_timer(Daily, ?MODULE, {monster_enter_scene__, _A, X, Y})
    end.



monster_enter_scene__(#agent{pid = Index, id = Id} = _A, X, Y) ->
    Idx = take_monster_idx(),
    put(?monster_idx(Index), Idx),
    Cfg = get(?pd_monster_cfg(Id)),
    monster_skill_mng:init(Idx, Cfg),
    monster_script:init(Idx, Id),
    A = scene_agent_factory:build_agent(_A#agent{idx = Idx, x = X, y = Y, party = 10000, ai_flag = 1}),
    % map_aoi:broadcast_view_me_agnets(A, scene_agent:pkg_enter_view_msg(A)),
    ?update_agent(Idx, A),
    mst_ai_sys:init(Idx, Id),
    A.



%% 受到攻击
under_attack(MyIdx, AttackerIdx) ->
    ?debug_log_scene_monster("monster idx ~p under_attack", [MyIdx]),
    ?assert(MyIdx < 0),
    ?DEBUG_LOG("MyIdx under_attack ~p", [MyIdx]),
    case ?get_m_enemy(MyIdx) of
        ?undefined ->
            set_m_enemy(MyIdx, AttackerIdx),
            self() ! ?scene_mod_msg(?MODULE, {check_has_enemy, MyIdx});
        EIdx -> %% XXX
            case ?get_agent(EIdx) of
                ?undefined ->
                    set_m_enemy(MyIdx, AttackerIdx),
                    self() ! ?scene_mod_msg(?MODULE, {check_has_enemy, MyIdx});
                #agent{state = State} ->
                    if State =:= ?st_die ->
                        ok;
                        true ->
                            %%set_m_enemy(MyIdx, AttackerIdx),
                            self() ! ?scene_mod_msg(?MODULE, {check_has_enemy, MyIdx})
                    end
            end
    end.

stiff_end(A) ->
    ai_action(?event_stiff_end, nil, A).


die(A) ->
    ?assert(A#agent.idx < 0),

    #agent{x = _X, y = _Y, view_blocks = _VBs, p_block_id = _Bid, state_timer = __StTimer} = ?get_agent(A#agent.idx),

    %% TODO cancel __StTimer

    del_m_enemy(A#agent.idx),
    monster_skill_mng:uninit(A#agent.idx),
    monster_script:uninit(A#agent.idx),

    ?debug_log_scene_monster("monster ~p die", [A#agent.idx]),
    %% TEST
    #agent{x = X, y = Y, view_blocks = VBs, p_block_id = Bid} = A,
    ?ifdo({X, Y, VBs, Bid} =/= {_X, _Y, _VBs, _Bid},
        ?ERROR_LOG("die not same aoi~p ~p", [{X, Y, VBs, Bid}, {_X, _Y, _VBs, _Bid}])),

    scene_agent:leave_scene(?get_agent(A#agent.idx)).

leave_scene(#agent{idx = _Idx, pid = Index} = A) ->
    die(A),
    erase(?pd_monster_born(Index)),
    erase(?pd_monster_die_count(Index)),
    erase(?monster_idx(Index)),
    ok.


%% monster 死亡会自动离开场景
die(#agent{idx = Idx, pid = Index, id = Id, x = X, y = Y, hp = _Hp} = Killed, #agent{idx = KIdx, pid = KPid, pk_info = KInfo} = _Killer) ->
    % ?assert(Idx < 0),
    case KIdx > 0 of
        true -> ?send_mod_msg(KPid, player_mng, {team_fuben_kill_monster, Id});
        _ -> pass
    end,
    DieCount = get(?pd_monster_die_count(Index)),
    die(Killed),
    %% drop item
    #monster_cfg{type = Type, relive = {Times, Sec}, drop = DropId} = get(?pd_monster_cfg(Id)),
    KK = case ?pk_info_get_pk_mode(KInfo) of
             monster -> ?none;
             player_call -> {?pk_info_get_player_id(KInfo), ?pk_info_get_team_id(KInfo)};
             _ -> {?pk_info_get_player_id(KInfo), ?pk_info_get_team_id(KInfo)}
         end,
    case {DropId, KK} of
        {?none, _} -> ok;
        {DropId, ?none} -> ok;
        {DropId, {KPlayerId, 0}} ->
            scene_drop:drop_item(DropId, [KPlayerId], {X, Y});
        {DropId, {_KPlayerId, _KTeamId}} ->
            PickUpPlayerIdList = lists:foldl(
                fun(FPlayerId, Acc) ->
                    case get_agent_with_player_id(FPlayerId) of
                        ?none -> Acc;
                        #agent{x = Fx, y = Fy} ->
                            Dist = com_util:get_point_distance({Fx, Fy}, {X, Y}),
                            case Dist < 5 of
                                true ->
                                    [FPlayerId | Acc];
                                _ ->
                                    Acc
                            end
                    end
                end,
                [],
                []
            ), %% TODO
            %%team_mng:get_members_id(KTeamId)),
            scene_drop:drop_item(DropId, PickUpPlayerIdList, {X, Y})
    end,
    %% 根据类型执行, TODO 不要写死
    case Type of
        ?MT_NORMAL ->
            if
                Times =:= -1 orelse DieCount < Times ->
                    % -1是无限复活 {复活次数, 复活间隔秒}
                    put(?pd_monster_die_count(Index), DieCount + 1),
                    scene_eng:start_timer(Sec * 1000, ?MODULE, {monster_relive, Index, Id});
                true ->
                    ok
            end;
        ?MT_CONVOY ->
            ok;
        ?MT_SKILL_OBJ ->
            ok;
        ?MT_BOOS ->
            ok;
        _ ->
            ?ERROR_LOG("monster die unknow type ~p", [Type])
    end,
    ok.

%% -> ?none | agent()
get_agent_with_player_id(PlayerId) ->
    case get(?player_idx(PlayerId)) of
        ?undefined -> ?none;
        Idx ->
            case ?get_agent(Idx) of
                ?undefined -> ?none;
                A -> A
            end
    end.




handle_msg({check_has_enemy, Idx}) ->
    case ?get_agent(Idx) of
        ?undefined ->
            del_m_enemy(Idx);
        A ->
            ai_action(?event_has_enemy, nil, A)
    end;

handle_msg({create_monster, MonsterList}) ->
    init_monster(MonsterList),
    ok;

%获取附近的怪物来Ml
%%handle_msg({near_monster_toml,A}) ->
%%case A of
%%#agent{id=PlayerId,x=X, y=Y,rx=Rx,pid = Pid} ->
%%BeginIdx=-1,
%%get_nearby_monster(PlayerId,X,Y,BeginIdx,Rx,Pid);
%%_ ->
%%ok
%%end;

handle_msg({create_convoy_npc, TaskId, PlayerId, MonsterId, PathList}) ->
    case load_cfg_monster_group:is_exist_monster_cfg(MonsterId) of
        true ->
            [{_, {X, Y} = B, E} = _ThisScene | Other] = PathList,
            StepList = global_data:get_convoy_task_path(get(?pd_cfg_id), B, E),
            ?debug_log_scene_monster("create convoy npc id ~p taskid ~p", [PlayerId, TaskId]),
            case new_monster(MonsterId, X, Y, ?D_L) of
                A when is_record(A, agent) ->
                    ai_action(?event_start, {TaskId, PlayerId, StepList, Other}, monster_enter_scene(A#agent{pk_info = ?make_monster_pk_info(PlayerId)}));
                _ ->
                    pass
            end;
        false ->
            ?ERROR_LOG("can not find monster cfg ~p", [MonsterId])
    end;

handle_msg({debug_create_monster, MonsterCfgId, Count}) ->
    MonsterList = com_util:fold(
        1,
        Count,
        fun(_, Acc) ->
            {X, Y} = scene:random_walkable_point(),
            [{MonsterCfgId, X, Y, ?D_L} | Acc]
        end,
        []
    ),

    init_monster(MonsterList);

handle_msg(Msg) ->
    ?ERROR_LOG("unknown msg ~p", [Msg]).


handle_timer(_Ref, {monster_relive, Index, MonsterId}) ->
    case get(?pd_monster_born(Index)) of
        {X, Y, Dir} ->
            ?debug_log_scene_monster("monster ~p relive ~p", [Index, MonsterId]),
            ai_action(?event_start, monster_enter_scene(new_monster(MonsterId, X, Y, Dir)));
        E ->
            ?ERROR_LOG("monster ~p relive can not find born ~p", [Index, E])
    end;

handle_timer(_Ref, {leave_scene, Idx}) ->
    case ?get_agent(Idx) of
        ?undefined -> ok;
        A ->
            ?debug_log_scene_monster("monster leave scene ~p", [Idx]),
            leave_scene(A)
    end;

handle_timer(_Ref, {down_up, Idx}) ->
    case ?get_agent(Idx) of
        #agent{stiff_state = ?ss_down_ground_stiff} = A ->
            A;
%%             fsm:fire_state_over_evt(A, ?st_new_move);
        _ ->
            ok
    end;

handle_timer(_Ref, {?skill_release_finished, SkillId, Idx}) ->
    case ?get_agent(Idx) of
        #agent{h = 0} = A ->
            ?debug_log_scene_monster("idx ~p skill_release_finished", [SkillId]),
            ai_action(?event_release_skill_over, SkillId, A);
        _ -> %% 有可能还在空中
            %% TODO 落地时在action
            ok
    end;

handle_timer(_Ref, {monster_enter_scene__, A, X, Y}) ->
    monster_enter_scene__(A, X, Y);

handle_timer(_Ref, Msg) ->
    ?ERROR_LOG("unknown msg ~p", [Msg]).

get_spirit(A, FieldIndex) ->
    element(FieldIndex, A#agent.attr).

add_spirit(A, FieldIndex, AddValue) when AddValue > 0 ->
    New =
        A#agent{attr = attr:add(FieldIndex, AddValue, A#agent.attr)},
    ?update_agent(A#agent.idx, New),
    New.

%% 会出现负数
del_spirit(A, FieldIndex, DelValue) ->
    New =
        A#agent{attr = attr:sub(FieldIndex, DelValue, A#agent.attr)},
    ?update_agent(A#agent.idx, New),
    New.



get_spirit_by_sat(A, Sat) ->
    get_spirit(A, attr:sat_2_field_index(Sat)).

add_spirit_by_sat(A, Sat, AddV) ->
    add_spirit(A, attr:sat_2_field_index(Sat), AddV).

del_spirit_by_sat(A, Sat, DelV) ->
    del_spirit(A, attr:sat_2_field_index(Sat), DelV).


%% TODO
full_hp(#agent{idx = _Idx, max_hp = _Max} = _A) ->
    todo.
%%A = _A#agent{hp=Max},
%%?update_agent(Idx, A),
%%scene_aoi:broadcast_view_me_agnets_and_me(A, <<?MSG_SCENE_AGENT_DATA_CHANGE,
%%Idx:16,
%%?PL_HP,
%%Max:32>>),
%%A.

add_hp(_A, AddHp) ->
    ?assert(_A#agent.state =/= ?st_die),
    %% TODO notify
    A = _A#agent{hp = erlang:max(_A#agent.max_hp, _A#agent.hp + AddHp)},
    ?update_agent(A#agent.idx, A),
    A.

del_hp(_A, DelHp) ->
    ?assert(_A#agent.state =/= ?st_die),
    A = case _A#agent.hp of
            Hp when Hp =< DelHp ->
                _A#agent{hp = 1}; %% TODO die
            Hp ->
                _A#agent{hp = Hp - DelHp} %% TODO die
        end,
    %% TODO notify
    ?update_agent(A#agent.idx, A),
    A.

?INLINE(set_m_enemy, 2).
set_m_enemy(Idx, EIdx) ->
    put(?pd_m_enemy(Idx), EIdx).

?INLINE(del_m_enemy, 1).
del_m_enemy(Idx) ->
    erase(?pd_m_enemy(Idx)).


%% monster move cb
move_step(#agent{x = _X, y = _Y, move_vec = Move} = A) ->
    ?assert(A#agent.stiff_state =/= ?ss_stiff),
    ?if_(A#agent.stiff_state =/= ?ss_beat_back_stiff andalso
        Move#move_vec.reason =:= ?mst_move,
        ai_action(?event_move_step, nil, A)).

break_releasing_skill(Idx, SkillId) ->
    %%?debug_log_scene_monster("idx ~p break releaseing_skill ~p", [Idx, SkillId]),
    scene_eng:start_timer(800, ?MODULE, {?skill_release_finished, SkillId, Idx}).


?INLINE(ai_action, 2).
ai_action(Event, #agent{ex = Ex} = A) ->
    (Ex#m_ex.ai_mod):action(Event, A).

?INLINE(ai_action, 3).
ai_action(Event, EventArg, #agent{ex = Ex} = A) ->
    %%?debug_log_scene_monster("monster idx ~p action ~p ", [A#agent.idx, A#agent.state]),
    (Ex#m_ex.ai_mod):action(Event, EventArg, A).

bind_room_flag(Idx, Flag) ->
    case ?get_agent(Idx) of
        #agent{} = A ->
            A1 = A#agent{ room_obj_flag = Flag },
            ?update_agent(Idx, A1),
            ok;

        _ ->
            ?ERROR_LOG("error bind_room_flag"),
            error
    end.

-include("scene_monster_cfg.inl").
