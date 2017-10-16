%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 18. 九月 2015 下午2:30
%%%-------------------------------------------------------------------
-module(damage).
-author("clark").

%% API
-export
([
    create_damange_bag/4,
    is_block_attack/3,
    % attack_hit/6,
    get_def_rate/1
]).

-include("inc.hrl").
-include("skill_struct.hrl").
-include("load_spirit_attr.hrl").
-include("scene.hrl").
-include("scene_agent.hrl").
-include("scene_monster.hrl").
-include("load_battle_coef.hrl").
-include("porsche_event.hrl").
-include("lua_evt.hrl").


create_damange_bag
(
    #agent{},
    #agent{
        hp=0
    }=Defender,
    _SkillId,
    _SkillCfg
) ->
    Defender;
create_damange_bag
(
    #agent{
        fidx = FIdx,
        type = AgentType
    } = Attacker,
    #agent{
        idx=OIdx, hp=OHp, hudun_hp=HudunHp, x=Ox, y=Oy, h=Oh, level=OLevel,
        state=_State, stiff_state=_StiffSt, attr=OAttr
    } = Defender,
    SkillId,
    Skill
) ->
    RealAttacker = case AgentType of
        ?agent_skill_obj ->
            case ?get_agent(FIdx) of
                #agent{} = RA -> RA;
                _ -> Attacker
            end;
        _ ->
            Attacker
    end,
    #agent{idx = Idx, pid = _Pid, id = Id, level = Level, attr = Attr} = RealAttacker,
    %% 等级压制系数
    LevRate = (get_lvl_rate1() + Level) / (get_lvl_rate2() + OLevel),
    {HitType, Damage} = attack_hit(LevRate, Idx, Attr, OIdx, OAttr, SkillId, Skill, AgentType),
    {Defender1, NewHp} = case HudunHp - Damage >= 0 of
        true ->
            {Defender#agent{hudun_hp = HudunHp - Damage}, OHp};
        _ ->
            NewDefender = case HudunHp =/= 0 of
                true -> buff_plug_hudun:remove_buff(Defender);
                _ -> Defender
            end,
            ResDamage = Damage - HudunHp,
            ResHp = erlang:max(0, OHp - ResDamage),
            {NewDefender#agent{hudun_hp = 0, hp = ResHp}, ResHp}
    end,
    ?update_agent(OIdx, Defender1),
    Pkg = <<OIdx:16, Ox:16, Oy:16, Oh:16, 0, 0, HitType, Damage:32, NewHp:32, 0:32, 0:32>>,
    erlang:put(?scene_hit_box_ret, Pkg),
    evt_util:send(#damaged_bag{attacker=Attacker, defender=Defender1, damage = Damage}),
    mst_ai_lua:on_ai_evt(Defender1#agent.idx, ?LUA_EVT_HIT, [Skill#skill_cfg.id, Defender1#agent.hp]),
    case get(pd_scene_players_damage_list) of
        List when is_list(List) ->
            case Idx > 0 andalso OIdx < 0 of
                true ->
                    case lists:keyfind(Idx, 1, List) of
                        {Idx, _, OldDamage} ->
                            NewList = lists:keyreplace(Idx, 1, List, {Idx, Id, OldDamage + Damage}),
                            put(pd_scene_players_damage_list, NewList);
                        _ ->
                            put(pd_scene_players_damage_list, [{Idx, Id, Damage} | List])
                    end;
                _ ->
                    pass
            end;
        _ ->
            pass
    end,
    if
        Defender1#agent.hp =< 0 -> evt_util:send(#monster_die{killer=Attacker, die=Defender1});
        true -> pass
    end,
    Defender1.

%% 等级压制系数
get_lvl_rate1() ->
    %% 等级压制系数 = MAXlv^（1/1.3）
    math:pow
    (
        misc_cfg:get_max_lev(),
        load_battle_coef:get_coef(?lv_suppress, 1)/load_battle_coef:get_coef(?lv_suppress, 2)
    ).
get_lvl_rate2() ->
    %% 等级压制系数 = MAXlv^（1/1.3）
    math:pow
    (
        misc_cfg:get_max_lev(),
        load_battle_coef:get_coef(?lv_suppress, 3)/load_battle_coef:get_coef(?lv_suppress, 4)
    ).

attack_hit(LevRate, AIdx, AAttr, BIdx, BAttr, SkillId, Skill, AgentType) ->
    case damage:is_block_attack(LevRate, AAttr, BAttr) of
        true ->
            {?ATT_BLOCK, 0};
        _ ->
            case AgentType of
                ?agent_pet ->
                    pet_new_mng:get_pet_new_damage(BAttr);
                _ ->
                    %% 防御值
                    DefV = max(0, BAttr#attr.def - AAttr#attr.break_def),
                    %% 防御率
                    DefRate = min(1, math:pow(DefV, load_battle_coef:get_coef(?def_rate, 1)) / load_battle_coef:get_coef(?def_rate, 2)),
                    {Damage, LastRate} = case load_cfg_skill:get_skill_type(SkillId) of
                        0 ->    %% 普通攻击
                            get_normal_damage(AIdx, AAttr, BIdx, BAttr, DefRate, Skill);
                        1 ->    %% 技能攻击
                            get_skill_damage(AIdx, AAttr, BIdx, BAttr, DefRate, Skill);
                        _O ->
                            ?ERROR_LOG("can not get skill type, skill_id:~p, Ret:~p", [Skill, _O]),
                            {0, 1}
                    end,
                    FinalDamage = max(0, Damage * (1 + AAttr#attr.atk_deep) * (1 - BAttr#attr.atk_free) + AAttr#attr.pure_atk),
                    case is_crit_attack(LevRate, AAttr, BAttr) of
                        ?false ->
                            {?ATT_NORMAL, round(FinalDamage * LastRate)};
                        ?true ->
                            %% 暴击倍率
                            CritMRate = math:pow(AAttr#attr.crit, load_battle_coef:get_coef(?crit_prob, 1)) / load_battle_coef:get_coef(?crit_prob, 2),
                            %% 韧性倍率
                            PliableMRate = math:pow(BAttr#attr.precise, load_battle_coef:get_coef(?pliable_prob, 1)) / load_battle_coef:get_coef(?pliable_prob, 2),
                            {?ATT_CRIT, round(FinalDamage * (2 + CritMRate) / (1 + PliableMRate) * LastRate)}
                    end
            end
    end.

%% 普通伤害 = Z * K * A * 攻击 * (冰属性攻击百分比 * (1 - 冰防) + 火属性攻击百分比 * (1 - 火防) + 雷属性攻击百分比 * (1 - 雷防) + 无属性攻击百分比 * (1 - 防御率)) + 基础伤害
get_normal_damage(AIdx, AAttr, BIdx, BAttr, DefRate, Skill) ->
    {Z, K1, K2, A, LastRate} = case AIdx > 0 andalso BIdx > 0 of
        true -> %% pvp
            {
                load_battle_coef:get_coef(?pvp_normal_damage, 1),
                load_battle_coef:get_coef(?pvp_normal_damage, 2),
                load_battle_coef:get_coef(?pvp_normal_damage, 3),
                load_battle_coef:get_coef(?pvp_normal_damage, 4),
                load_battle_coef:get_coef(?pvp_last_rate, 1)
            };
        _ ->    %% pve
            {
                load_battle_coef:get_coef(?pve_normal_damage, 1),
                load_battle_coef:get_coef(?pve_normal_damage, 2),
                load_battle_coef:get_coef(?pve_normal_damage, 3),
                load_battle_coef:get_coef(?pve_normal_damage, 4),
                load_battle_coef:get_coef(?pve_last_rate, 1)
            }
    end,
    SkillBiasDamage = get_skill_bias_damage(BAttr, DefRate, Skill),
    HeadVal = Z * (K1 + random:uniform() * (K2 - K1)) * A,
    NormalDamage = case is_number(Skill#skill_cfg.base_hit) of
        true ->
            trunc(HeadVal * AAttr#attr.atk * SkillBiasDamage + Skill#skill_cfg.base_hit);
        _ ->
            trunc(HeadVal * AAttr#attr.atk * SkillBiasDamage)
    end,
    case is_number(Skill#skill_cfg.m) of
        true ->
            {NormalDamage * Skill#skill_cfg.m, LastRate};
        _ ->
            {NormalDamage, LastRate}
    end.

%% 技能伤害 = Z * K * A * 攻击 + (1 + 技能系数) * (变量系数 * 职业主属性的值) * (冰属性攻击百分比 * (1 - 冰防) + 火属性攻击百分比 * (1 - 火防) + 雷属性攻击百分比 * (1 - 雷防) + 无属性攻击百分比 * (1 - 防御率)) + 基础伤害
get_skill_damage(AIdx, AAttr, BIdx, BAttr, DefRate, Skill) ->
    {Z, K1, K2, A, Val, LastRate} = case AIdx > 0 andalso BIdx > 0 of
        true -> %% pvp
            {
                load_battle_coef:get_coef(?pvp_skill_damage, 1),
                load_battle_coef:get_coef(?pvp_skill_damage, 2),
                load_battle_coef:get_coef(?pvp_skill_damage, 3),
                load_battle_coef:get_coef(?pvp_skill_damage, 4),
                load_battle_coef:get_coef(?pvp_skill_damage, 5),
                load_battle_coef:get_coef(?pvp_last_rate, 1)
            };
        _ ->    %% pve
            {
                load_battle_coef:get_coef(?pve_skill_damage, 1),
                load_battle_coef:get_coef(?pve_skill_damage, 2),
                load_battle_coef:get_coef(?pve_skill_damage, 3),
                load_battle_coef:get_coef(?pve_skill_damage, 4),
                load_battle_coef:get_coef(?pve_skill_damage, 5),
                load_battle_coef:get_coef(?pve_last_rate, 1)
            }
    end,
    SkillBiasDamage = get_skill_bias_damage(BAttr, DefRate, Skill),
    HeadVal = Z * (K1 + random:uniform() * (K2 - K1)) * A,
    AttrTypeVal = case Skill#skill_cfg.attr_type of
        ?S_STRENGTH ->
            AAttr#attr.strength;
        ?S_INTELLECT ->
            AAttr#attr.intellect;
        ?S_NIMBLE ->
            AAttr#attr.nimble;
        ?S_STRONG ->
            AAttr#attr.strong
    end,
    SkillDamage = case is_number(Skill#skill_cfg.base_hit) of
        true ->
            trunc(HeadVal * AAttr#attr.atk + Val * (1 + Skill#skill_cfg.skill_coe) * (Skill#skill_cfg.var_coe * AttrTypeVal) * SkillBiasDamage + Skill#skill_cfg.base_hit);
        _ ->
            trunc(HeadVal * AAttr#attr.atk + Val * (1 + Skill#skill_cfg.skill_coe) * (Skill#skill_cfg.var_coe * AttrTypeVal) * SkillBiasDamage)
    end,
    case is_number(Skill#skill_cfg.m) of
        true ->
            {SkillDamage * Skill#skill_cfg.m, LastRate};
        _ ->
            {SkillDamage, LastRate}
    end.

%% 属性偏向伤害
get_skill_bias_damage(BAttr, DefRate, Skill) ->
    case Skill#skill_cfg.skill_bias of
        List when is_list(List) ->
            lists:foldl(
                fun({ProKey, ProVal}, TempVal) ->
                        case ProKey of
                            0 ->
                                ProVal / 100 * (1 - DefRate) + TempVal;
                            1 ->
                                ProVal / 100 * (1 - BAttr#attr.ice_def / 100) + TempVal;
                            2 ->
                                ProVal / 100 * (1 - BAttr#attr.fire_def / 100) + TempVal;
                            3 ->
                                ProVal / 100 * (1 - BAttr#attr.thunder_def / 100) + TempVal;
                            _ ->
                                TempVal
                        end
                end,
                0,
                List
            );
        _ ->
            (1 - DefRate)
    end.

%% 计算是否格挡
is_block_attack(LevRate, AAttr, BAttr) ->
    %% 招架率 =
    BlockRate =  math:pow(BAttr#attr.block, load_battle_coef:get_coef(?guard, 1)) / load_battle_coef:get_coef(?guard, 2),
    %% 精准率
    PreciseRate = math:pow(AAttr#attr.precise, load_battle_coef:get_coef(?guard, 1)) / load_battle_coef:get_coef(?precise, 2),
    %% 最终招架概率 = (0.1+ )
    FinalBlockPercentage = max(0, (load_battle_coef:get_coef(?final_guard, 1) + BlockRate - PreciseRate) /  LevRate),
    Random = random:uniform(),
    %% 1 is 100
    Random =< FinalBlockPercentage.

is_crit_attack(LevRate, AAttr, BAttr) ->
    %% 暴击概率
    CritRate = math:pow(AAttr#attr.crit, load_battle_coef:get_coef(?crit_rate, 1)) / load_battle_coef:get_coef(?crit_rate, 2),

    %% 韧性概率
    PliableRate = math:pow(BAttr#attr.precise, load_battle_coef:get_coef(?pliable_rate, 1)) / load_battle_coef:get_coef(?pliable_rate, 1),

    FinalCritPercentage = (load_battle_coef:get_coef(?crit_fact_prob, 1) + CritRate - PliableRate) * LevRate,

    random:uniform() =< FinalCritPercentage.

get_def_rate(DefValue) ->
    math:pow(DefValue, load_battle_coef:get_coef(?def_rate, 1)) / load_battle_coef:get_coef(?def_rate, 2).
