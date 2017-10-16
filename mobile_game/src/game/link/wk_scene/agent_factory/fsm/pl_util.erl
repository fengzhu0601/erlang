%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 11. 十一月 2015 上午8:48
%%%-------------------------------------------------------------------
-module(pl_util).
-author("clark").

%% API
-export
([
    move/2
    , teleport/2
    , jump/2
    , play_skill/2
    , attack/5
    , play_bullet_skill/3
    , is_dizzy/1
    , play_emits/4
]).

-export([handle_timer/2]).

-include("skill_struct.hrl").
-include("load_spirit_attr.hrl").
-include("inc.hrl").
-include("scene.hrl").
-include("scene_agent.hrl").
-include("load_cfg_emits.hrl").
-include("pl_fsm.hrl").

handle_timer(_, {play_emits, Idx, {EmitsId, X, Y, H, Dir, _DelayTime}, SkillId, SkillDuanId}) ->
    play_emits(Idx, {EmitsId, X, Y, H, Dir, 0}, SkillId, SkillDuanId).

move(?undefined, _TPar) ->
    ?ERROR_LOG("can not find idx");
move(#agent{x = SyncX, y = SyncY, h = SyncH} = Agent, {Vx, Vy}) ->
    move(Agent, {SyncX, SyncY, SyncH, Vx, Vy});
move(#agent{idx = Idx} = Agent, {SyncX, SyncY, SyncH, Vx, Vy}) ->
    EvtRet = pl_fsm:on_event(Agent, {?fsm_evt_move, SyncX, SyncY, SyncH, Vx, Vy}),
    if
        EvtRet =/= ok ->
            MovePlug = pl_fsm:build_plug(?pl_moving),
            PlugList = [{MovePlug, {SyncX, SyncY, SyncH, Vx, Vy}}],
            case pl_fsm:can_set_state(Agent, PlugList) of
                ok -> pl_fsm:set_state(Agent, PlugList);
                _ -> Agent
            end;
        true ->
            Agent11 = ?get_agent(Idx),
            Agent11
    end.

teleport(?undefined, _TPar) ->
    ?ERROR_LOG("can not find idx");
teleport(#agent{} = Agent, {Reason, SyncX, SyncY}) ->
    TeleportPlug = pl_fsm:build_plug(?pl_path_teleport),
    PlugList = [{TeleportPlug, {Reason, SyncX, SyncY}}],
    case pl_fsm:can_set_state(Agent, PlugList) of
        ok -> pl_fsm:set_state(Agent, PlugList);
        _ -> Agent
    end.

jump(?undefined, _TPar) ->
    ?ERROR_LOG("can not find idx");
jump(#agent{} = Agent, {Dir, MoveX, MoveY, MoveH}) ->
    JumpPlug = pl_fsm:build_plug(?pl_jumping),
    PlugList = [{JumpPlug, {Dir, MoveX, MoveY, MoveH}}],
    case pl_fsm:can_set_state(Agent, PlugList) of
        ok -> pl_fsm:set_state(Agent, PlugList);
        _ -> Agent
    end.

play_skill(?undefined, _TPar) ->
    ?ERROR_LOG("can not find idx");
play_skill(#agent{x = X, y = Y, h = H} = Agent, {SkillId, SkillDuanId, Dir}) ->
    play_skill(Agent, {SkillId, SkillDuanId, Dir, X, Y, H});
play_skill(#agent{type = ?agent_skill_obj} = Agent, {SkillId, SkillDuanId, _Dir, _SyncX, _SyncY, _SyncH}) ->
    %% 子弹类
    ?INFO_LOG("agent_skill_obj SkillId ~p", [SkillId]),
    AttackAreaPlug = pl_fsm:build_plug(?pl_bullet_attack_area),
    PlugList = [{AttackAreaPlug, {SkillId, SkillDuanId}}],
    case pl_fsm:can_set_state(Agent, PlugList) of
        ok -> pl_fsm:set_state(Agent, PlugList);
        _ -> Agent
    end;
play_skill(#agent{idx = _Idx} = Agent, {SkillId, SkillDuanId, Dir, SyncX, SyncY, SyncH}) ->
    SkillPlug = pl_fsm:build_plug(?pl_attack),
    PlugList = [{SkillPlug, {SkillId, SkillDuanId, Dir, SyncX, SyncY, SyncH}}],
    pl_fsm:set_state(Agent, PlugList).

play_emits(Idx, {EmitsId, X, Y, H, Dir, DelayTime}, SkillId, SkillDuanId) ->
    case ?get_agent(Idx) of
        ?undefined ->
            ignore;
        Agent ->
            case load_cfg_skill:lookup_skill_cfg(SkillDuanId) of
                SkillCfg when is_record(SkillCfg, skill_cfg) ->
                    case DelayTime of
                        0 ->
                            scene_agent_factory:try_build_bullet(Agent, SkillId, SkillCfg, {EmitsId, X, Y, H, Dir});
                        _ ->
                            scene_eng:start_timer(DelayTime, ?MODULE, {play_emits, Idx, {EmitsId, X, Y, H, Dir, DelayTime}, SkillId, SkillDuanId})
                    end;
                _ ->
                    ignore
            end
    end.

play_bullet_skill(
    #agent{d = Dir} = Agent, SkillId,
    {#emits_cfg{
        delay = DelayTm
        % todo 加速度未做
        , speed = [{SX, _, _}, {SY, _, _}, {SH, _, _}]
        , time = LifeTime
        , attack_interval = Dt
        , attack_skill = SkillDuanId
    }}
) ->
    MoveVec = move_util:create_move_vector({SX, SY, SH, SX}),
    Agent1 = Agent#agent{move_vec = MoveVec},
    EndTime = com_time:timestamp_msec() + LifeTime,
    SX1 = case Dir of
        ?D_R -> SX / 10000;
        _ -> -SX / 10000
    end,
    bullet_attack_tgr:start(Agent1, {DelayTm, {SX1, SY / 10000, SH / 10000}, SkillId, SkillDuanId, Dt, EndTime}),
    ok.

attack(?undefined, _Defender, _SkillId, _SkillCfg, _Dir) ->
    ?ERROR_LOG("can not find idx");
attack(_Attacker, ?undefined, _SkillId, _SkillCfg, _Dir) ->
    ?ERROR_LOG("can not find idx");
attack(_Attacker, #agent{is_unbeatable = ?true} = Defender, _SkillId, _SkillCfg, _Dir) ->
    Defender;
attack(Attacker, Defender, SkillId, SkillCfg, _Dir) ->
    Defender1 = damage:create_damange_bag(Attacker, Defender, SkillId, SkillCfg),
    scene_player:is_notify_teammate(Defender1),
    Defender1.

is_dizzy(Idx) ->
    case plug_dizzy:is_dizzy(Idx) of
        ok ->
            ok;

        _E ->
            case mst_ai_sys:is_ai_pause(Idx) of
                true -> ok;
                _ -> ret:error(no_dizz)
            end
    end.
