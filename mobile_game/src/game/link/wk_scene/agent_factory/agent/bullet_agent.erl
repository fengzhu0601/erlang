%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 23. 九月 2015 下午3:48
%%%-------------------------------------------------------------------
-module(bullet_agent).
-author("clark").

%% API
-export(
[
    build/6
    , buile_new/6
    , move_grid/3
]).



-include("inc.hrl").
-include("skill_struct.hrl").
-include("load_spirit_attr.hrl").
-include("scene_agent.hrl").
-include("load_scene_monster.hrl").
-include("load_cfg_emits.hrl").

%% 产生子弹
build
(
    #agent
    {
        id = _FId,
        idx = FIdx,
        pid = FPid,
        x = FX, y = FY, h = FH
    } = _FAgent,
    #monster_new_cfg
    {
        id = MonsterBid,
        attr = MonsterAttr
    } = _MonsterCfg,
    #skill_release_obj_cfg
    {
        speed = Speed,
        born_point = {BornX, BornY, BornH}
    } = _BuildCfg,
    Dir,
    Box,
    FromSkill
) ->
    MonsterIdx = -1*scene_agent:take_player_idx() - 10000,
    put(?monster_idx(FIdx), MonsterIdx),
%%     ?INFO_LOG("MonsterBid ~p",[MonsterBid]),

    %% ------------------ info ---------------
    Attr = load_spirit_attr:lookup_attr(MonsterAttr),
    ObjX =
        if
            Dir =:= ?D_R ->
                max(0, FX + BornX);
            true ->
                max(0, FX - BornX)
        end,
    ObjY = FY + BornY,
    ObjH = max(0, FH + BornH),
    Rx = 1,
    Ry = 1,
    ObjAgent =
        #agent
        {
            id = MonsterBid,
            pid = FPid,
            fidx = FIdx,
            idx = MonsterIdx,
            type = ?agent_skill_obj,
            d = Dir,
            x = ObjX,
            y = ObjY,
            h = ObjH,
            pl_be_freedown = false,
            is_unbeatable = ?true,
            rx = Rx,
            ry = Ry,
            hp = 1,
            max_hp = 1,
            attr = Attr,
            level = 1,
            pk_info = ?make_monster_pk_info(-1),
            enter_view_info = <<?MT_SKILL_OBJ, MonsterBid:32, FIdx:16>>,
            move_vec = move_util:create_move_vector(erlang:make_tuple(4, Speed)),
            pl_bullet_box = Box,
            pl_from_skill = FromSkill
        },
    ObjAgent1 = map_agent:create(ObjAgent),
    ObjAgent1.

buile_new(
    #agent{
        idx = FIdx,
        pid = FPid,
        attr = Attr,
        party = Party,
        skill_modifies = SkillModifies
    },
    MonsterBid,
    #skill_release_obj_cfg
    {
        speed = Speed,
        born_point = {BornX, BornY, BornH}
    } = _BuildCfg,
    Dir,
    Box,
    FromSkill
) ->
    MonsterIdx = -1 * scene_agent:take_player_idx() - 10000,
    put(?monster_idx(FIdx), MonsterIdx),
    Rx = 1,
    Ry = 1,
    ObjAgent = #agent{
        id = MonsterBid,
        pid = FPid,
        fidx = FIdx,
        idx = MonsterIdx,
        type = ?agent_skill_obj,
        d = Dir,
        x = BornX,
        y = BornY,
        h = BornH,
        pl_be_freedown = false,
        is_unbeatable = ?true,
        rx = Rx,
        ry = Ry,
        hp = 1,
        max_hp = 1,
        attr = Attr,
        level = 1,
        pk_info = ?make_monster_pk_info(-1),
        enter_view_info = <<?MT_SKILL_OBJ, MonsterBid:32, FIdx:16>>,
        move_vec = move_util:create_move_vector(erlang:make_tuple(4, Speed)),
        pl_bullet_box = Box,
        pl_from_skill = FromSkill,
        skill_modifies = SkillModifies,
        party = Party,      %% 阵营与释放者一样
        ai_flag = 0         %% 没有ai
    },
    ObjAgent1 = map_agent:create(ObjAgent),
    ObjAgent1.

%% 技能移动
move_grid(#agent{idx = _Idx, x = Ox, y = Oy, h = Oh} = Agent, Skill, D) ->
    CurMV = Agent#agent.move_vec,
    NextGrid = load_cfg_skill:get_next_grid(Skill, D, {Ox, Oy, Oh}),
    case NextGrid of
        {error, _} -> Agent;
        {_ToX, _ToY, ToH} ->
            case room_map:is_walkable(_Idx, NextGrid) of
                true ->
                    if
                        ToH =/= 0 andalso ToH =< 0 -> %% 瞬移落地 ，重置x,速度
                            %%pap_fsm:set_state(Agent#agent{state=?none, move_vec=MV}, ?st_new_move, {?mst_skill_move,NextGrid}, "scene_fight:405");

                            ?assert(CurMV#move_vec.cfg_speed > 0),
                            MV = CurMV#move_vec
                            {
                                x_speed = CurMV#move_vec.cfg_speed,
                                y_speed = CurMV#move_vec.cfg_speed
                            },
%%                             fsm:set_state(Agent#agent{state = ?none, move_vec = MV}, ?st_new_move, {?mst_skill_move, NextGrid}, "scene_fight:405");
                            Agent#agent{state = ?none, move_vec = MV};
                        true ->
%%                             fsm:set_state(Agent#agent{state = ?none}, ?st_new_move, {?mst_skill_move, NextGrid}, "scene_fight:407")
                            Agent#agent{state = ?none}
                    end;
                false ->
                    ?ERROR_LOG("can not mveo grid is_walkable ~p", [NextGrid]),
                    Agent
            end
    end.