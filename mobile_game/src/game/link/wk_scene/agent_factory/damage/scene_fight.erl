%%%-------------------------------------------------------------------
%%% @author zl
%%% @doc 战斗模块
%%%
%%% @end
%%%-------------------------------------------------------------------

-module(scene_fight).

-include("inc.hrl").
-include("skill_struct.hrl").
-include("load_spirit_attr.hrl").

-include("scene.hrl").
-include("scene_agent.hrl").
-include("scene_monster.hrl").

-export(
[
    release_skill/6
    , cancle_releasing_skill/1
    , device_release_skill/4
]).

%% cb
-export([handle_timer/2]).



%% 战斗相关
%% update A
release_skill(#agent{idx = Idx, x = X, y = Y, h = H} = _A, SkillId, D, Dx, Dy, _Dh) ->
    %%?ifdo(Idx=:= 1, ?debug_log_scene("idx :~p release_skill view_me_agents :~p", [Idx, A#agent.view_me_agents])),

    ?assert(room_map:is_walkable(Idx, Dx, Dy)),

    A = map_aoi:stop_moving_and_sync_position(_A#agent{d = D}, {Dx, Dy, _Dh}),

    Skill = load_cfg_skill:lookup_skill_cfg(SkillId),
    %%?debug_log_scene("release_skill Idx ~p SkillId~p", [Idx, SkillId]),

    Msg = scene_sproto:pkg_msg(?MSG_SCENE_RELEASE_SKILL, {Idx, SkillId, D, X, Y, H}),
    ?ifdo(Idx > 0, ?send_to_client(A#agent.pid, Msg)),
    map_aoi:broadcast_view_me_agnets(A, Msg),

    A_1 = A,

    %%NA = fsm:set_state(A_1, ?st_new_play_skill, {nil, {SkillId, 1}}, "scene_fight:405"),
    NA = A_1,

    case Skill#skill_cfg.delay of
        ?none ->
            skill_start(NA, Skill, D);
        Delay ->
            Timer = scene_eng:start_timer(Delay, ?MODULE, {skill_start, Idx, SkillId, D}),
            map_agent:set_releasing_skill(Idx, Skill#skill_cfg.breaked_pri, Timer)
    end.



%% 技能的stiff
start_stiff_hard_time(#agent{idx = OIdx} = Attacker, Skill, StartT) ->
    ?assert(Attacker#agent.stiff_state =/= ?ss_ba_ti),

    %% TODO
    %%StiffType = Skill#skill_cfg.launch_type,
    case Skill#skill_cfg.hard_time of
        0 ->
            ?update_agent(OIdx, Attacker);
    %%_StiffTime when StiffType =:= 0 andalso OIdx >0 -> %% player not in stiff
    %%?update_agent(OIdx, Attacker);
        StiffTime ->
            NewStiffEndTime = StiffTime + StartT,
            case Attacker#agent.stiff_state of
                ?ss_stiff ->
                    {?ss_stiff, TRef, OldStiffEndTime} = Attacker#agent.state_timer,
                    if
                        OldStiffEndTime >= NewStiffEndTime -> %% 没有超过超时时间
                            ?update_agent(OIdx, Attacker);
                        true ->
                            %% 更新超时时间
                            ?debug_log_scene("idx ~p in ~p ", [OIdx, Attacker#agent.state_timer]),
                            scene_eng:cancel_timer(TRef),
                            NTRef = scene_eng:start_timer(StiffTime, ?MODULE, {stiff_end, Attacker#agent.idx}),
                            ?update_agent(OIdx, Attacker#agent{state_timer = {?ss_stiff, NTRef, NewStiffEndTime}})
                    end;
                _ -> %% 设置　ss_stiff
                    %% 已经过时间
                    PssT = com_time:timestamp_msec() - StartT,
                    ?WARN_LOG("passed stiff time ~p hard_time ~p", [PssT, StiffTime]),
                    if
                        PssT > StiffTime ->
                            if
                                OIdx > 0 ->
                                    %% change_st
                                    ?debug_log_scene_player("change_st none Psst > StiffTime"),
                                    ?update_agent(OIdx, Attacker#agent{state_timer = ?none, state = ?none});
                                true ->
                                    %% 离开stiff 状态
                                    %% XXX
                                    scene_monster:stiff_end(Attacker#agent{state_timer = ?none, ?change_stiff_st(?none)})
                            end;
                        true ->
                            %% XXX start_timer is none ??
                            scene_agent:cancel_state_timer(Attacker#agent.state_timer),
                            NTRef = scene_eng:start_timer(StiffTime - PssT, ?MODULE, {stiff_end, OIdx}),

                            ?debug_log_scene("idx ~p in stiff_st ~p ", [OIdx, Attacker#agent.state_timer]),
                            map_aoi:stop_if_moving_and_notify(Attacker#agent{?change_stiff_st(?ss_stiff),
                                state_timer = {?ss_stiff, NTRef, NewStiffEndTime}})
                    end
            end
    end.

cancle_releasing_skill(Idx) ->
    case erlang:erase({?releaseing_skill, Idx}) of
        ?undefined -> ok;
        {_, Timer} -> scene_eng:cancel_timer(Timer)
    end.


%% 场景机关施放技能
%% TODO party, 现在是只攻击player
device_release_skill(DeviceId, DevicePos, HitPer, SkillId) ->
    ?debug_log_scene("device release_skill Id ~p SkillId~p", [DeviceId, SkillId]),

    map_aoi:broadcast_view_block_agnets(map_block:get_p_block_id(DevicePos), scene_sproto:pkg_msg(?MSG_SCENE_DEVICE_RELEASE_SKILL, {DeviceId})),

    Skill = load_cfg_skill:lookup_skill_cfg(SkillId),
    case Skill#skill_cfg.delay of
        ?none ->
            Skill = load_cfg_skill:lookup_skill_cfg(SkillId),
            device_skill_start(DeviceId, DevicePos, HitPer, Skill);
        Delay ->
            scene_eng:start_timer(Delay, ?MODULE, {device_skill_start, DeviceId, DevicePos, HitPer, SkillId})
    end.





-define(MAX_LEVEL, 100).
%-define(LEVEL_COE, (math:pow(?MAX_LEVEL, 1/1.3))).
-define(LEVEL_COE, (math:pow(misc_cfg:get_max_lev(), 1 / 1.3))).

%% 计算是否格挡
is_block_attack(LevRate, AAttr, BAttr) ->
    %% 招架率 =
    BlockRate = math:sqrt(BAttr#attr.block) / 100,

    %% 精准率
    PreciseRate = math:sqrt(AAttr#attr.precise) / 100,

    %% 最终招架概率 = (0.1+ )
    FinalBlockPercentage = max(0, (0.1 + BlockRate - PreciseRate) / LevRate),
    ?debug_log_scene_fight("final black v ~p", [FinalBlockPercentage]),

    %% 1 is 100
    random:uniform() =< FinalBlockPercentage.





get_forth_vector(?D_L, RushRange) -> -RushRange;
get_forth_vector(?D_R, RushRange) -> RushRange.



opposite_dirc(?D_U) -> ?D_D;
opposite_dirc(?D_D) -> ?D_U;
opposite_dirc(?D_L) -> ?D_R;
opposite_dirc(?D_R) -> ?D_L;
opposite_dirc(?D_LU) -> ?D_RD;
opposite_dirc(?D_RU) -> ?D_LD;
opposite_dirc(?D_LD) -> ?D_RU;
opposite_dirc(?D_RD) -> ?D_LU;
opposite_dirc(N) -> N.




%% TODO compiler to beam


device_is_can_attack(FA) ->
    FA#agent.idx > 0.

device_attack(_DeviceId,
    #agent{idx = OIdx, max_hp = FullHp, hp = OHp, x = Ox, y = Oy, h = Oh, level = _OLevel, state = _State, stiff_state = StiffSt, attr = _OAttr} = Attacker,
    HitPer, Skill) ->

    IsBaTi = if StiffSt =:= ?ss_ba_ti -> ?TRUE;
                 true -> ?FALSE end,

    IsBreakedSkill =
        if IsBaTi ->
            ?FALSE;
            ?true ->
                map_agent:try_break_releasing_skill(OIdx, Skill#skill_cfg.break_pri)
        end,

    HitPoint = round(HitPer * FullHp / 100),
    case erlang:max(0, OHp - HitPoint) of
        0 ->
            {Attacker#agent{hp = 0},
                <<
                OIdx:16,
                Ox:16,
                Oy:16,
                Oh:16,
                IsBaTi,
                IsBreakedSkill,
                HitPoint:32,
                0:32
                >>};
        NewHp ->
            <<
            OIdx:16,
            Ox:16,
            Oy:16,
            Oh:16,
            IsBaTi,
            IsBreakedSkill,
            HitPoint:32,
            NewHp:32
            >>
    end.

%% device first release skill hit
device_skill_start(_DeviceId, {_Ox, _Oy}, _HitPer, #skill_cfg{id = _SkillId, release_range = _SRange} = _Skill) ->
    %%%% TODO 不执行重复, link
    ok.


%% first release skill hit
skill_start(_A, SkillCfg, D) ->
    A = bullet_agent:move_grid(_A, SkillCfg, D),
    X = A#agent.x,
    Y = A#agent.y,
    H = A#agent.h,
    Idx = A#agent.idx,


    %%?debug_log_scene("skill ~p skill_start", [skill#skill_cfg.id]),

    %% hit_area 返回后A的 view 和 view 么 可能会被改变
    map_hit:hit_area(A, SkillCfg),
    scene_agent_factory:try_build_bullet(A, SkillCfg, D),

    %% TODO save this timer
    ?ifdo(Idx < 0,
        scene_eng:start_timer(SkillCfg#skill_cfg.render_time + 500, scene_monster, {?skill_release_finished, SkillCfg#skill_cfg.id, Idx})),

    %% repeat hit
    case SkillCfg#skill_cfg.hit_repeat_time of
        0 -> ok;
        N ->
            scene_eng:start_timer(SkillCfg#skill_cfg.hit_repeat_interval, ?MODULE, {skill_repeat_hit, {1, N}, Idx, D, SkillCfg, X, Y, H})
    end,

    %% 释放完技能下落
    move_h_tgr:start_freely_fall(?get_agent(Idx)),

    %%?debug_log_scene("skill_start over"),
    ok.

handle_timer(_Ref, {skill_start, Idx, SkillId, D}) ->
    cancle_releasing_skill(Idx),

    %% TODO 有可能idx 已经换人了
    case ?get_agent(Idx) of
        ?undefined -> ok;
        A ->
            Skill = load_cfg_skill:lookup_skill_cfg(SkillId),
            skill_start(A, Skill, D)
    end;

handle_timer(_Ref, {hit_box, Idx, D, Box, SkillId}) ->
    case ?get_agent(Idx) of
        ?undefined ->
            ok;
        A ->
            SkillCfg = load_cfg_skill:lookup_skill_cfg(SkillId),
            map_hit:hit_box(A, D, Box, SkillCfg)
    end;

handle_timer(_Ref, {device_skill_start, DeviceId, DevicePos, HitPer, SkillId}) ->
    Skill = load_cfg_skill:lookup_skill_cfg(SkillId),
    device_skill_start(DeviceId, DevicePos, HitPer, Skill);


handle_timer(_Ref, {link_skill_release, Idx, LSkillId, D}) ->
    case ?get_agent(Idx) of
        ?undefined ->
            ?debug_log_scene("link_skill_release can not find ~p idx ", [Idx]),
            ok;
        A ->
            ?debug_log_scene("link_skill_release id ~p idx ~p", [Idx, LSkillId]),
            release_skill(A, LSkillId, D, A#agent.x, A#agent.y, A#agent.h)
    end;


handle_timer(_Ref, {release_skill_obj, Idx, SkillId, D, Cfg}) ->
    case ?get_agent(Idx) of
        ?undefined -> ok;
        A ->
            SkillCfg = load_cfg_skill:lookup_skill_cfg(SkillId),
            scene_agent_factory:build_bullet(A, SkillCfg, D, Cfg)
    end;


handle_timer(_Ref, {stiff_end, Idx}) ->
    ?debug_log_scene("idx  ~p out stiff st ~p", [Idx, _Ref]),
    case ?get_agent(Idx) of
        #agent{idx = Idx, stiff_state = ?ss_stiff} = A when Idx > 0 ->
            ?update_agent(Idx, A#agent{?change_stiff_st(?none), state_timer = ?none});
        #agent{idx = Idx, stiff_state = ?ss_stiff} = A when Idx < 0 ->
            scene_monster:stiff_end(A#agent{?change_stiff_st(?none), state_timer = ?none});
        ?undefined ->
            ?ERROR_LOG("idx ~p stiff_end undefine agent ", [Idx]);
        A ->
            ?ERROR_LOG("idx ~p stiff_end but state not stiff_end ~p ", [Idx, A#agent.state])
    end,
    ok;

handle_timer(_Ref, {ba_ti_end, Idx}) ->
    ?debug_log_scene_ss("idx ~p ba_ti_end ~p", [Idx, _Ref]),
    case ?get_agent(Idx) of
        ?undefined -> ok;
        #agent{idx = Idx, stiff_state = ?ss_ba_ti} = A ->
            %% TEST
            Cfg = erlang:get(?pd_monster_cfg(A#agent.id)),
            if Cfg#monster_cfg.ba_ti =:= ?TRUE ->
                ?ERROR_LOG("not can set ba_ti_end is permanent ba_ti"),
                ?update_agent(Idx, A#agent{state_timer = ?none});
                true ->
                    ?update_agent(Idx, A#agent{?change_stiff_st(?none), state_timer = ?none})
            end;
        #agent{idx = Idx, stiff_state = N} = _A ->
            ?ERROR_LOG("idx ~p ba_ti_end, but stiff_state not ba_ti ~p", [Idx, N])
    end;


handle_timer(_Ref, {skill_repeat_hit, {C, N}, Idx, FirstD, SkillCfg, FirstX, FirstY, FirstH}) ->
    case ?get_agent(Idx) of
        ?undefined -> ok;
        A ->
            case A#agent.state of
                ?st_die -> ok;
                _ ->
                    _ReleasePoint =
                        case SkillCfg#skill_cfg.hit_repeat_is_follow of
                            ?TRUE -> {A#agent.x, A#agent.y, A#agent.h};
                            ?FALSE -> {FirstX, FirstY, FirstH}
                        end,

%%                     map_hit:hit_area(ReleasePoint, A, SkillCfg, FirstD),
                    %%?debug_log_scene_fight("repeat hit ~p ~p", [Idx, skill]),
                    ?ifdo(C + 1 =< N,
                        scene_eng:start_timer(SkillCfg#skill_cfg.hit_repeat_interval,
                            ?MODULE,
                            {skill_repeat_hit, {C + 1, N}, Idx, FirstD, SkillCfg, FirstX, FirstY, FirstH}))
            end
    end,
    ok;


handle_timer(_Ref, _Msg) ->
    ?ERROR_LOG("recv a unknow timer msg~p", [_Msg]),
    ok.




