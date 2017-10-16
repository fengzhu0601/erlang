%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 22. 九月 2015 下午2:58
%%%-------------------------------------------------------------------
-module(attack_area_tgr).
-author("clark").

%% API
-export
([
    start/2
    , stop/1
    , is_run/1
    , create_bullet_hit_area/2
]).

-export
([
    handle_timer/2
]).


-include("inc.hrl").
-include("scene.hrl").
-include("scene_agent.hrl").
-include("skill_struct.hrl").
-include("load_spirit_attr.hrl").
-include("porsche_event.hrl").


start(#agent{idx = Idx} = Agent, {SkillId, SkillDuanId}) ->
    Agent0 = stop(Agent),
    SkillCfg = load_cfg_skill:lookup_skill_cfg(SkillDuanId),
    case SkillCfg of
        ?none ->
            ?ERROR_LOG("error attack_area_tgr ~p", [SkillId]),
            Agent0;

        _ ->
            LongWens = [],
            Agent1a =
                case SkillCfg#skill_cfg.delay of
                    ?none ->
                        on_hit_frame(Agent0, SkillId, SkillCfg, 0, LongWens);
                    0 ->
                        on_hit_frame(Agent0, SkillId, SkillCfg, 0, LongWens);
                    Delay ->
                        TimeRef = scene_eng:start_timer(Delay, ?MODULE, {on_hit_frame, Idx, SkillId, SkillDuanId, 0, LongWens}),
                        set_skill_attack_pri(Idx, SkillCfg#skill_cfg.breaked_pri, TimeRef),
                        Agent0#agent{attack_time = TimeRef}
                end,

            CD = SkillCfg#skill_cfg.cd,
            Agent1b =
                if
                    CD > 0 ->
                        CdTimeRef = scene_eng:start_timer(CD, ?MODULE, {on_cartoon, Idx, SkillId}),
                        Agent1a#agent{segment_cartoon_time = CdTimeRef};

                    true ->
                        Agent1a
                end,

            ?update_agent(Idx, Agent1b),
            Agent1b
    end.



set_skill_attack_pri(Idx, Pri, TimeRef) ->
    erlang:put({?releaseing_skill, Idx}, {Pri, TimeRef}).


stop(#agent{idx = Idx} = Agent) ->
    case scene_eng:get_timer(Agent#agent.attack_time) of
        {_Ref, _Msg} ->
            ok;

        _ ->
            ok
    end,
    scene_eng:cancel_timer(Agent#agent.attack_time),
    if
        Agent#agent.segment_cartoon_time =/= ?none ->
            scene_eng:cancel_timer(Agent#agent.segment_cartoon_time);

        true ->
            pass
    end,
    Agent1 = Agent#agent{attack_time = ?none, segment_cartoon_time=?none},
    ?update_agent(Idx, Agent1),
    Agent1.


is_run(#agent{} = Agent) ->
    scene_eng:is_wait_timer(Agent#agent.attack_time).

handle_timer(_Ref, {on_hit_frame, Idx, SkillId, SkillDuanId, DoneNum, LongWens}) ->
    SkillCfg = load_cfg_skill:lookup_skill_cfg(SkillDuanId),
    case ?get_agent(Idx) of
        ?undefined -> ok;
        Agent -> on_hit_frame(Agent, SkillId, SkillCfg, DoneNum, LongWens)
    end;

handle_timer(_Ref, {on_hit_box, Idx, Dir, Box, SkillId, SkillDuanId}) ->
    SkillCfg = load_cfg_skill:lookup_skill_cfg(SkillDuanId),
    case ?get_agent(Idx) of
        ?undefined -> ok;
        Agent -> map_hit:hit_box(Agent, Dir, Box, SkillId, SkillCfg)
    end;

handle_timer(_Ref, {on_cartoon, Idx, SkillId}) ->
    case ?get_agent(Idx) of
        ?undefined ->
            ok;

        Agent ->
            Agent1 = Agent#agent{segment_cartoon_time = none},
            ?INFO_LOG("================ skill segment over ================"),
            evt_util:send(#skill_over{idx=Idx, segment=SkillId}),
            ?update_agent(Idx, Agent1)
    end;

handle_timer(_Ref, Msg) ->
    ?ERROR_LOG("unknown msg ~p", [Msg]).


on_hit_frame(#agent{idx = Idx} = Agent0, SkillId, SkillCfg, DoneNum, LongWens) ->
    %% 伤害碰撞
    create_hit_area(Agent0, SkillId, SkillCfg),
    %% 子弹
    scene_agent_factory:try_build_bullet(Agent0, SkillId, SkillCfg),
    %% ----------------
    DoneNum1 = DoneNum + 1,
    RepeatTime = SkillCfg#skill_cfg.hit_repeat_time,
    Agent = ?get_agent(Idx),
    Agent1 =
        if
            DoneNum1 < RepeatTime ->
                Delay = SkillCfg#skill_cfg.hit_repeat_interval,
                TimeRef = scene_eng:start_timer(Delay, ?MODULE, {on_hit_frame, Idx, SkillId, SkillCfg#skill_cfg.id, DoneNum1, LongWens}),
                Agent#agent{attack_time = TimeRef};

            true ->
                Agent
        end,
    ?update_agent(Idx, Agent1),
    Agent1.


%% 产生碰撞区
create_hit_area(#agent{idx = Idx, x = X, y = Y, h = H, d = Dir} = Agent, SkillId, Skill) ->
    lists:foreach
    (
        fun
            (Box) ->
                case element(1, Box) of
                    0 ->
                        map_hit:hit_box(Agent, Dir, Box, SkillId, Skill);
                    Delay ->
                        scene_eng:start_timer(Delay, attack_area_tgr, {on_hit_box, Idx, Dir, Box, SkillId, Skill#skill_cfg.id})
                end
        end,
        load_cfg_skill:get_hit_boxs(X, Y, H, Skill, Dir)
    ),
    ok.

create_bullet_hit_area
(
        #agent
        {
            fidx = FIdx,
            x = X, y = Y, h = H, d = Dir,
            pl_bullet_box = {DX, DY, DH}
        },
        {SkillId, SkillDuanId}
) ->
    case ?get_agent(FIdx) of
        ?undefined ->
            ok;

        #agent{x = _AX, y = _AY, h = _AH} = Attacker ->
%%             ?INFO_LOG("SkillId ~p",[SkillId]),
            SkillCfg = load_cfg_skill:lookup_skill_cfg(SkillDuanId),
%%             ?INFO_LOG("create_bullet_hit_area attack pos ~p",[{AX, AY, AH}]),
%%             ?INFO_LOG("create_bullet_hit_area bullet pos ~p",[{X, Y, H}]),
%%             ?INFO_LOG("create_bullet_hit_area bullet offset ~p",[{DX, DY, DH}]),
            HitBox = {0, X - DX, Y - DY, X + DX, Y + DY, H + DH, H - DH},
%%             ?INFO_LOG("create_bullet_hit_area bullet box ~p",[HitBox]),
            map_hit:hit_box(Attacker, Dir, HitBox, SkillId, SkillCfg)
    end,
    ok.
