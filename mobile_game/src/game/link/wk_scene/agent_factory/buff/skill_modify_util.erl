%%%-------------------------------------------------------------------
%%% @author hank
%%% @copyright (C) 2016, <SANTI>
%%% @doc  处理技能释放的龙纹效果
%%%
%%% @end
%%% Created : 07. Apr 2016 2:55 PM
%%%-------------------------------------------------------------------
-module(skill_modify_util).
-author("hank").

%% API
-export([
    load_longwen_skill_modifies/0,
    get_skill_modify_effects/1,
    release_skill/2,
    be_hit/3,
    skill_break/4,
    release_skill_end/3,
    add_state_buff/2,
    init_pet_halo_buff/2,
    check_is_add_pet_halo_buff/3,
    add_crown_skill_modify_buff/1
]).

-include("player.hrl").
-include("inc.hrl").
-include("load_cfg_skill.hrl").
-include("load_cfg_buff.hrl").
-include("scene.hrl").
-include("scene_agent.hrl").
-include("buff_system.hrl").
-include("load_segments.hrl").
-include("load_cfg_halo.hrl").

-define(STAND_UP, 1).   %% 起身状态

%% 得到技能修改集id列表
load_longwen_skill_modifies() ->
    LongWensList = case gb_trees:values(get(?pd_longwens_mng)) of
        LongWens when is_list(LongWens) ->
            lists:foldl(
                fun({LWId, Lvl, DressFlag}, TempList) ->
                    case DressFlag of
                        1 ->
                            case load_cfg_skill:lookup_long_wen_cfg({LWId, Lvl}) of
                                Cfg when is_record(Cfg, long_wen_cfg) ->
                                    TempList ++ Cfg#long_wen_cfg.skill_modifications;
                                _ ->
                                    TempList
                            end;
                        _ ->
                            TempList
                    end
                end,
                [],
                LongWens
            );
        _ ->
            []
    end,
    CrownList = crown_new_mng:get_crown_skill_modify_id_list(),
    LongWensList ++ CrownList.

get_skill_modify_effects(ModifiesList) ->
    case is_list(ModifiesList) of
        true ->
            lists:foldl(
                fun(ModifyId, RetList) ->
                        case load_cfg_skill:lookup_skill_modify_cfg(ModifyId) of
                            #skill_modify_cfg{
                                type = Type, trigger_type = TriggerType, skill = SkillIdList, segment = Segment, cd = Msec,
                                prop_target_type = _Target, buff_target_type = BuffTarget, buff = Buff,  mp = Mp, anger = Anger
                            } ->
                                case TriggerType =:= 0 of
                                    true -> %% 无类型
                                        case Type of
                                            1 ->    %% 减cd
                                                [SkillId] = SkillIdList,
                                                case lists:keyfind(1, 1, RetList) of
                                                    {1, SkillCdList} ->
                                                        NewSkillCdList = SkillCdList ++ [{SkillId, -Msec}],
                                                        lists:keyreplace(1, 1, RetList, {1, NewSkillCdList});
                                                    _ ->
                                                        RetList ++ [{1, [{SkillId, -Msec}]}]
                                                end;
                                            3 ->    %% 千分比属性
                                                RetList;
                                            4 ->    %% buff(处理皇冠修改集，回蓝回血，无类型，type是4，没绑定技能和技能段，作用到自己，有buff)
                                                case is_list(SkillIdList) =:= false andalso is_list(Segment) =:= false andalso BuffTarget =:= 1 andalso is_integer(Buff) of
                                                    true ->
                                                        case lists:keyfind(4, 1, RetList) of
                                                            {4, BuffIdList} ->
                                                                NewList = BuffIdList ++ [Buff],
                                                                lists:keyreplace(4, 1, RetList, {4, NewList});
                                                            _ ->
                                                                RetList ++ [{4, [Buff]}]
                                                        end;
                                                    _ ->
                                                        RetList
                                                end;
                                            5 ->    %% 减少耗蓝
                                                case SkillIdList of
                                                    [SkillId] ->
                                                        case lists:keyfind(5, 1, RetList) of
                                                            {5, SkillMpList} ->
                                                                NewSkillMpList = SkillMpList ++ [{SkillId, -Mp}],
                                                                lists:keyreplace(5, 1, RetList, {5, NewSkillMpList});
                                                            _ ->
                                                                RetList ++ [{5, [{SkillId, -Mp}]}]
                                                        end;
                                                    _ ->
                                                        RetList
                                                end;
                                            7 ->    %% 增加怒气
                                                case is_list(SkillIdList) =:= false andalso is_list(Segment) =:= false of
                                                    true->
                                                        case lists:keyfind(7, 1, RetList) of
                                                            {7, SkillAngerList} ->
                                                                case lists:keyfind(all, 1, SkillAngerList) of
                                                                    {all, OldAnger} ->
                                                                        NewSkillAngerList = lists:keyreplace(all, 1, SkillAngerList, {all, OldAnger + Anger}),
                                                                        lists:keyreplace(7, 1, RetList, {7, NewSkillAngerList});
                                                                    _ ->
                                                                        SkillAngerList ++ [{all, Anger}]
                                                                end;
                                                            _ ->
                                                                RetList ++ [{7, [{all, Anger}]}]
                                                        end;
                                                    _ ->
                                                        [SkillId] = SkillIdList,
                                                        case lists:keyfind(7, 1, RetList) of
                                                            {7, SkillAngerList} ->
                                                                NewSkillAngerList = SkillAngerList ++ [{SkillId, Anger}],
                                                                lists:keyreplace(7, 1, RetList, {7, NewSkillAngerList});
                                                            _ ->
                                                                RetList ++ [{7, [{SkillId, Anger}]}]
                                                        end
                                                end;
                                            _ ->
                                                RetList
                                        end;
                                    _ ->
                                        RetList
                                end;
                            _ ->
                                RetList
                        end
                end,
                [],
                ModifiesList
            );
        _ ->
            []
    end.

%% 释放时触发
release_skill(?undefined, _) -> ok;
release_skill(#agent{idx = _Idx, skill_modifies = SkillModifies} = Agent, SkillDuanId) ->
    %% 技能段给自身触发的buff列表
    SkillDuanSelfBuff = case load_segments:lookup_segments_cfg(SkillDuanId) of
        #segments_cfg{buffs = BuffList} when is_list(BuffList) ->
            [{Tar, BuffId} || {Tar, BuffId} <- BuffList, Tar =:= 1];
        _ ->
            []
    end,
    %% 修改集给自身触发的buff列表
    ModifySelfBuff = case is_list(SkillModifies) of
        true ->
            lists:foldl(
                fun(ModifyId, RetList) ->
                        case load_cfg_skill:lookup_skill_modify_cfg(ModifyId) of
                            #skill_modify_cfg{
                                type = Type, trigger_type = TriggerType, segment = SegmentList,
                                prop_target_type = _Target, svr_prop = _SvrProp, coef_prop = _CoefProp,
                                mp = _Mp, buff = Buff, buff_target_type = BuffTarget
                            } ->
                                case is_list(SegmentList) andalso lists:member(SkillDuanId, SegmentList) andalso TriggerType =:= 1 of
                                    true -> %% 释放时触发
                                        case Type of    %% (cd=1, prop1(固定值）=2,prop2(千分比)=3，buff=4,5减少耗蓝,基础伤害6，怒气7，技能百分比8)
                                            4 ->    %% buff
                                                case BuffTarget of
                                                    1 ->    %% 目标：攻击者
                                                        [{1, Buff}] ++ RetList;
                                                    5 ->    %% 目标：宠物主人
                                                        [{1, Buff}] ++ RetList;
                                                    _ ->
                                                        RetList
                                                end;
                                            _ ->
                                                RetList
                                        end;
                                    _ ->
                                        RetList
                                end;
                            _ ->
                                RetList
                        end
                end,
                [],
                SkillModifies
            );
        _ ->
            []
    end,
    % ?DEBUG_LOG("release skill segment buff:~p, release modify buff:~p", [SkillDuanSelfBuff, ModifySelfBuff]),
    BuffCfgList = [{TarIndex, load_cfg_buff:lookup_buff_cfg(Id)} || {TarIndex, Id} <- SkillDuanSelfBuff ++ ModifySelfBuff],
    buff_system:release(Agent, Agent, BuffCfgList, {0}).

be_hit(?undefined, _, _) -> ok;
be_hit(_, _, []) -> ok;
be_hit(AAgent, SkillDuanId, [{_, 0} | ResAgent]) ->
    be_hit(AAgent, SkillDuanId, ResAgent);
be_hit(#agent{idx = _AIdx, skill_modifies = SkillModifies} = AAgent, SkillDuanId, [{BAgent, Damage}| ResAgent]) ->
    case BAgent of
        #agent{idx = _BIdx} ->
            %% 技能段触发的buff列表
            SkillDuanEnemyBuff = case load_segments:lookup_segments_cfg(SkillDuanId) of
                #segments_cfg{buffs = BuffList} when is_list(BuffList) ->
                    lists:map(
                        fun({Tar, BuffId}) -> 
                                case Tar of
                                    0 ->
                                        {2, BuffId};
                                    _ ->
                                        {1, BuffId}
                                end
                        end,
                        BuffList
                    );
                _ ->
                    []
            end,
            %% 修改集触发的buff列表
            ModifyEnemyBuff = case is_list(SkillModifies) of
                true ->
                    lists:foldl(
                        fun(ModifyId, RetList) ->
                                case load_cfg_skill:lookup_skill_modify_cfg(ModifyId) of
                                    #skill_modify_cfg{
                                        type = Type, trigger_type = TriggerType, segment = SegmentList,
                                        prop_target_type = _Target, svr_prop = _SvrProp, coef_prop = _CoefProp,
                                        mp = _Mp, buff = Buff, buff_target_type = BuffTarget
                                    } ->
                                        case is_list(SegmentList) andalso lists:member(SkillDuanId, SegmentList) andalso TriggerType =:= 2 of
                                            true -> %% 命中时触发
                                                case Type of    %% (cd=1, prop1(固定值）=2,prop2(千分比)=3，buff=4,5减少耗蓝,基础伤害6，怒气7，技能百分比8)
                                                    4 ->    %% buff
                                                        case BuffTarget of
                                                            2 ->    %% 目标：受击者
                                                                [{2, Buff}] ++ RetList;
                                                            _ ->
                                                                [{1, Buff}] ++ RetList
                                                        end;
                                                    _ ->
                                                        RetList
                                                end;
                                            _ ->
                                                RetList
                                        end;
                                    _ ->
                                        RetList
                                end
                        end,
                        [],
                        SkillModifies
                    );
                _ ->
                    []
            end,
            % ?DEBUG_LOG("be hit skill segment buff:~p, be hit modify buff:~p", [SkillDuanEnemyBuff, ModifyEnemyBuff]),
            BuffCfgList = [{TarIndex, load_cfg_buff:lookup_buff_cfg(Id)} || {TarIndex, Id} <- SkillDuanEnemyBuff ++ ModifyEnemyBuff],
            buff_system:release(AAgent, BAgent, BuffCfgList, {Damage});
        _ ->
            ok
    end,
    be_hit(AAgent, SkillDuanId, ResAgent).

skill_break(?undefined, _, _, _) -> ok;
skill_break(_, ?undefined, _, _) -> ok;
skill_break(#agent{skill_modifies = SkillModifies} = Agent, Breaker, _SkillId, SkillDuanId) ->
    ModifyBuff = case is_list(SkillModifies) of
        true ->
            lists:foldl(
                fun(ModifyId, RetList) ->
                        case load_cfg_skill:lookup_skill_modify_cfg(ModifyId) of
                            #skill_modify_cfg{
                                type = Type, trigger_type = TriggerType, segment = SegmentList,
                                buff_target_type = BuffTarget, buff = Buff
                            } ->
                                case is_list(SegmentList) andalso lists:member(SkillDuanId, SegmentList) andalso TriggerType =:= 3 of
                                    true -> %% 技能被打断时触发
                                        case Type of
                                            4 ->
                                                [{BuffTarget, Buff}] ++ RetList;
                                            _ ->
                                                RetList
                                        end;
                                    _ ->
                                        RetList
                                end;
                            _ ->
                                RetList
                        end
                end,
                [],
                SkillModifies
            );
        _ ->
            []
    end,
    % ?DEBUG_LOG("skill break modify buff:~p", [ModifyBuff]),
    BuffCfgList = [{TarIndex, load_cfg_buff:lookup_buff_cfg(Id)} || {TarIndex, Id} <- ModifyBuff],
    buff_system:release(Breaker, Agent, BuffCfgList, {0}).

release_skill_end(?undefined, _, _) -> ok;
release_skill_end(#agent{idx = _AIdx, skill_modifies = SkillModifies} = Agent, _EndSkillId, EndSkillDuanId) ->
    ModifyBuff = case is_list(SkillModifies) of
        true ->
            lists:foldl(
                fun(ModifyId, RetList) ->
                        case load_cfg_skill:lookup_skill_modify_cfg(ModifyId) of
                            #skill_modify_cfg{
                                type = Type, trigger_type = TriggerType, segment = SegmentList,
                                buff_target_type = _BuffTarget, buff = Buff
                            } ->
                                case is_list(SegmentList) andalso lists:member(EndSkillDuanId, SegmentList) andalso TriggerType =:= 4 of
                                    true -> %% 技能结束时触发
                                        case Type of    %% (cd=1, prop1(固定值）=2,prop2(千分比)=3，buff=4,5减少耗蓝,基础伤害6，怒气7，技能百分比8)
                                            4 ->
                                                [{1, Buff}] ++ RetList;
                                            _ ->
                                                RetList
                                        end;
                                    _ ->
                                        RetList
                                end;
                            _ ->
                                RetList
                        end
                end,
                [],
                SkillModifies              
            );
        _ ->
            []
    end,
    % ?DEBUG_LOG("skill end modify buff:~p", [ModifyBuff]),
    BuffCfgList = [{TarIndex, load_cfg_buff:lookup_buff_cfg(Id)} || {TarIndex, Id} <- ModifyBuff],
    buff_system:release(Agent, Agent, BuffCfgList, {0}).

add_state_buff(?undefined, _) -> ok;
add_state_buff(Agent, State) ->
    case State of
        ?STAND_UP ->
            BuffId = 10000000,
            buff_system:release(Agent, Agent, [{1, load_cfg_buff:lookup_buff_cfg(BuffId)}], {0});
        _ ->
            pass
    end.

init_pet_halo_buff(_, ?undefined) -> ok;
init_pet_halo_buff(PetId, Agent) ->
    case load_cfg_new_pet:get_pet_talent_skill(PetId) of
        TalentSkill when is_integer(TalentSkill) ->
            case load_cfg_new_pet:get_pet_halo_buff(TalentSkill) of
                BuffId when is_integer(BuffId) ->
                    buff_system:release(Agent, Agent, [{1, load_cfg_buff:lookup_buff_cfg(BuffId)}], {0});
                _ ->
                    pass
            end;
        _ ->
            pass
    end.

check_is_add_pet_halo_buff(PlayerIdxList, PetIdxList, Time) ->
    lists:foreach(
        fun(Idx) ->
                case ?get_agent(Idx) of
                    #agent{x = X, y = Y} = Agent ->
                        HaloList = lists:foldl(
                            fun(PetIdx, TempList) ->
                                    case ?get_agent(PetIdx) of
                                        #agent{x = PetX, y = PetY, type = ?agent_pet, buff_states = BuffStates} = PetAgent ->
                                            [{HaloId, _, EndTime}] = BuffStates,
                                            case load_cfg_halo:lookup_halo_cfg(HaloId) of
                                                #halo_cfg{id = Id, type = Type, radius = Radius, target = Target, buff_id = BuffId} ->
                                                    case EndTime >= com_time:now() andalso math:pow(((PetX - X) * (PetX - X) + (PetY - Y) * (PetY - Y)), 0.5) =< Radius / ?GRID_PIX andalso (Target =:= 1 orelse Target =:= 3) of
                                                        true ->
                                                            case lists:keyfind(Type, 2, TempList) of
                                                                {OldId, _, _, _} ->
                                                                    case Id > OldId of
                                                                        true -> lists:keyreplace(OldId, #halo_cfg.id, TempList, {Id, Type, BuffId, PetAgent});
                                                                        _ -> TempList
                                                                    end;
                                                                _ ->
                                                                    TempList ++ [{Id, Type, BuffId, PetAgent}]
                                                            end;
                                                        _ ->
                                                            TempList
                                                    end;
                                                _ ->
                                                    TempList
                                            end;
                                        _ ->
                                            TempList
                                    end
                            end,
                            [],
                            PetIdxList
                        ),
                        [buff_system:release(AAgent, Agent, [{2, load_cfg_buff:lookup_buff_cfg(ReleaseBuffId)}], {time, Time}) || {_, _, ReleaseBuffId, AAgent} <- HaloList];
                    _ ->
                        ignore
                end
        end,
        PlayerIdxList
    ).

add_crown_skill_modify_buff(#agent{idx = _Idx, skill_modifies_effects = EffList} = Agent) ->
    CrownSkillModifyBuffList = case lists:keyfind(4, 1, EffList) of
        {4, BuffList} -> BuffList;
        _ -> []
    end,
    BuffCfgList = [{1, load_cfg_buff:lookup_buff_cfg(Id)} || Id <- CrownSkillModifyBuffList],
    buff_system:release(Agent, Agent, BuffCfgList, {0}).
