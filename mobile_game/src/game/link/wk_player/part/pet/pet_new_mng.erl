-module(pet_new_mng).


-include_lib("pangzi/include/pangzi.hrl").

-include("inc.hrl").
-include("player.hrl").
-include("scene.hrl").
-include("load_spirit_attr.hrl").
-include("player_mod.hrl").
-include("load_item.hrl").
-include("item.hrl").
-include("item_new.hrl").
-include("item_bucket.hrl").
-include("handle_client.hrl").
-include("load_cfg_new_pet.hrl").
-include("pet_new.hrl").
-include("../wonderful_activity/bounty_struct.hrl").
-include("system_log.hrl").
-include("rank.hrl").
-include("../../wk_open_server_happy/open_server_happy.hrl").
-include("achievement.hrl").

-export([
    create_pet/3,
    add_pet_new_exp_if_fight/1,
    pet_new_enter_scene/5,
    pet_new_leave_scene/2,
    get_pet_new_damage/1,
    update_pet_ranking_list/0,
    auto_figth_of_first_pay/1,
    get_pet_id/0,
    get_the_pet_highest_advance/0
]).

-define(SHENGZHEN, 2).
-define(XIAZHEN, 3).

%% pet damage-------------------------------------------------------------------------start
get_pet_new_damage(BeiDaAttr) ->
    {AttType, Damage} = 
    case get(?fight_pet_new_on_scene) of
        ?undefined ->
            {?ATT_NORMAL, 0};
        PetNew ->
            AttrNew = PetNew#pet_new.attr_new,
            PetId = PetNew#pet_new.pet_id,
            InitiativeSkillList = PetNew#pet_new.initiative_skill,
            PassivitySkillList = PetNew#pet_new.passivity_skill,
            InitiativeSkillId = load_cfg_new_pet:get_initiative_skill(PetId),
            InitiativeSkillLevelId = get_pet_initativeskill(PetId, InitiativeSkillList),
            Type2ToData = get_passivityskill_data(PassivitySkillList, 2),
            NormalDamage = 
            case load_cfg_new_pet:get_pet_new_attr_by_initativeskill_id(InitiativeSkillId) of
                ?none ->
                    0;
                {BbId, Ratio} ->
                    NewRatio = Type2ToData + Ratio,
                    Rate = NewRatio / 1000,
                    Value = attr:get_attr_value_by_sats(BbId, AttrNew),
                    AddAttrValue = com_util:ceil(Value * Rate),
                    InitiativeSkillLevelIdDamage = load_cfg_new_pet:get_pet_initativeskill_damage(InitiativeSkillLevelId),
                    AddAttrValue + InitiativeSkillLevelIdDamage
            end,
            Type3ToData = get_passivityskill_data(PassivitySkillList, 3),
            RandomNum = random:uniform(1000),
            Type4ToData = get_passivityskill_data(PassivitySkillList, 4),
            if
                RandomNum =< Type3ToData -> %% 最终伤害=正常伤害*（2+暴击倍率加成）
                    {?ATT_CRIT,com_util:ceil(NormalDamage * (2 + Type4ToData / 1000))};
                true ->
                    {?ATT_NORMAL, NormalDamage}
            end
    end,
    DefValue = max(0, BeiDaAttr#attr.def),%% 防御
    DefRate = damage:get_def_rate(DefValue),
    AtkFree = BeiDaAttr#attr.atk_free,                     %% 伤害减免

    FinalDamage = round(Damage*(1.0-DefRate)*(1.0-AtkFree)),
    % ?DEBUG_LOG("FinalDamage-------------------------------------------:~p",[FinalDamage]),
    {AttType, FinalDamage}.


get_passivityskill_data(PassivitySkillList, Type) ->
    lists:foldl(fun({_, PassivitySkillId, _}, Acc) ->
        case load_cfg_new_pet:lookup_pet_skill_new_cfg(PassivitySkillId) of
            ?none ->
                Acc;
            #pet_skill_new_cfg{passive_type=Type, attr_add=AttrAdd, crit=Crit, crit_damege=CritDamage, coin=Coin, double_item=DoubleItem} ->
                if
                    Type =:= 2 ->
                        Acc + AttrAdd; %% Type == 2
                    Type =:= 3 ->
                        Acc + Crit;   %% Type == 3 %% 暴击概率
                    Type =:= 4 ->
                        Acc + CritDamage; %% Type == 4 暴击倍率
                    Type =:= 6 ->
                        Acc + Coin; %% Type == 6
                    Type =:= 7 ->
                        Acc + DoubleItem; %% Type == 7
                    true ->
                        Acc
                end;
            _ ->
                Acc
        end
    end,
    0,
    PassivitySkillList).
   


%% pet damage--------------------------------------------------------------------------end

%%  common --------------------------------------------------------------------------start


get_cur_fight_pet_new() ->
    Id = get(?pd_pet_fight),
    List = get(?pd_pet_list),
    case lists:keyfind(Id, #pet_new.id, List) of
        ?false ->
            ?false;
        _ ->
            Id
    end.

get_cur_fight_pew_new_cfg_id() ->
    Id = get(?pd_pet_fight),
    List = get(?pd_pet_list),
    case lists:keyfind(Id, #pet_new.id, List) of
        ?false ->
            0;
        PetNew ->
            PetNew#pet_new.pet_id
    end.

get_pet_new_by_petid(Id) ->
    lists:keyfind(Id, #pet_new.id, get(?pd_pet_list)).


update_pet_new(PetNew) ->
    List = get(?pd_pet_list),
    NewList = lists:keyreplace(PetNew#pet_new.id, #pet_new.id, List, PetNew),
    put(?pd_pet_list, NewList).

del_pet_new(PetNew) ->
    List = get(?pd_pet_list),
    NewList = lists:keydelete(PetNew#pet_new.id, #pet_new.id, List),
    put(?pd_pet_list, NewList).

update_pet_new_arr(PetNew, AttrId) ->
    %?DEBUG_LOG("AttrId----------------------:~p",[AttrId]),
    Attr = attr_new:get_attr_by_id(AttrId),
    %?DEBUG_LOG("Attr------------------------:~p",[Attr]),
    %?DEBUG_LOG("old attr----------------:~p",[PetNew#pet_new.attr_new]),
    NewAttr = attr:add(Attr, PetNew#pet_new.attr_new),
    %?DEBUG_LOG("NewAttr------------------------:~p",[NewAttr]),
    PetNew#pet_new{attr_new = NewAttr}.

get_pet_initativeskill(PetId, List) ->
    SkillId = load_cfg_new_pet:get_initiative_skill(PetId),
    case lists:keyfind(SkillId, 1, List) of
        ?false ->
            0;
        {_, SkillLevel} ->
            SkillLevel
    end.

get_passivity_skill_on_egg(List) ->
    case lists:keyfind(3,1,List) of
        ?false ->
            {1,0};
        {_, PassivitySkillId} ->
            {1,PassivitySkillId}
    end.

auto_figth_of_first_pay(ItemId) ->
    %?DEBUG_LOG("ItemId--------------------:~p",[ItemId]),
    if
        ItemId =:= 6101 ->
            PetId = load_item:get_petid_on_item_use_effect(6101),
            List = get(?pd_pet_list),
            %?DEBUG_LOG("List------------------:~p",[List]),
            case lists:keyfind(PetId, #pet_new.pet_id, List) of
                ?false ->
                    pass;
                PetNew ->
                    Id = PetNew#pet_new.id,
                    CurFightPet = get(?pd_pet_fight),
                    ?DEBUG_LOG("Id-------:~p----CurFightPet-----:~p",[Id, CurFightPet]),
                    if
                        CurFightPet =:= 0 ->
                            fight_pet_new(Id);
                        true ->
                            pass
                    end
            end;
        true ->
            pass
    end.


%%  common --------------------------------------------------------------------------end

%% 创建宠物 1.0级宠物 2.封印后的宠物（宠物信息保持封印前的状态）
%%  create and init pet data------------------------------------------------------start
create_pet(PetCfgId, GoodsId, ItemBasicInfo) ->
    %?DEBUG_LOG("PetCfgId-----:~p---GoodsId--:~p---ItemBasicInfo-----:~p",[PetCfgId, GoodsId,ItemBasicInfo]),
    {Index, PassivitySkillId} = get_passivity_skill_on_egg(ItemBasicInfo),
    FengYinData = {GoodsId, PassivitySkillId},
    #{limit_num:=PetCount} = misc_cfg:get_misc_cfg(pet_info),
    PlayerPetCount = length(get(?pd_pet_list)),
    if
        (PlayerPetCount + 1) > PetCount ->
            {?error, pet_max_count};
        true ->
            init_pet_new(PetCfgId, Index, PassivitySkillId, FengYinData)
    end.

init_pet_new(PetCfgId, Index, PassivitySkillId, FengYinData) ->
    case load_cfg_new_pet:lookup_pet_new_cfg(PetCfgId) of
        ?none ->
            pass;
        PetCfg ->
            InitiativeSkill = PetCfg#pet_new_cfg.initiative_skill,

            PetRace = PetCfg#pet_new_cfg.race,
            LevelAttr = load_cfg_new_pet:get_attr_id_by_pet_level(PetCfgId),
            InitAttr = attr:add(LevelAttr,attr:new()),
            {OldArrt, InitAttr2} =
            case PassivitySkillId of
                0 ->
                    {0, InitAttr};
                _ ->    
                    get_passivity_skill_attr_to_pet_new(PassivitySkillId, InitAttr)
            end,
            Id = gen_id:next_id(pet_id_tab),
            PetNew =
            #pet_new{
                id = Id,
                pet_id = PetCfgId,
                status = ?PET_NEW_STATUS_ALIVE,
                pet_race = PetRace,
                pet_level = PetCfgId,

                attr_new = InitAttr2#attr{id = 0},
                initiative_skill = [{InitiativeSkill, InitiativeSkill}],%% [{SkillId, SkillLevel}]
                fengyin_data = [FengYinData],
                passivity_skill = [{Index, PassivitySkillId, OldArrt}]
            },
            add_pet_new(PetNew),
            PetNewBin = pack_pet_new([PetNew]),
            %% 更新宠物排行榜
            update_pet_ranking_list(),
            ?player_send(pet_new_sproto:pkg_msg(?MSG_PET_NEW_UPDATE_AND_ADD, {PetNewBin}))
    end,
    ok.

add_pet_new(PetNew) when is_record(PetNew, pet_new)->
    achievement_mng:do_ac(?chongwudalianmeng),
    put(?pd_pet_list, [PetNew|get(?pd_pet_list)]);
add_pet_new(A) ->
    ?ERROR_LOG("error pet_new--------------------:~p",[A]).

pack_pet_new(PetList) when is_list(PetList)->
    lists:foldl(fun(PetNew, Acc) ->
        Id = PetNew#pet_new.id,
        PetId = PetNew#pet_new.pet_id,
        Level = load_cfg_new_pet:get_pet_level(PetNew#pet_new.pet_level),
        Advance = PetNew#pet_new.pet_advance,
        Status = PetNew#pet_new.status,
        %?DEBUG_LOG("Id------:~p-----Status---:~p",[Id, Status]),
        InitiativeSkillList = PetNew#pet_new.initiative_skill,
        InitiativeSkillLevelId = get_pet_initativeskill(PetId, InitiativeSkillList),
        InitiativeSkillLevel = load_cfg_new_pet:get_pet_initativeskill_level(InitiativeSkillLevelId),
        CurExp = PetNew#pet_new.cur_exp,
        PassivitySkillBin = pack_passivity_skill(PetNew#pet_new.passivity_skill),
        <<Acc/binary, Id:32, PetId:32,Level, Advance, Status, InitiativeSkillLevel, CurExp:64, PassivitySkillBin/binary>>
    end,
    <<(length(PetList))>>,
    PetList);
pack_pet_new(_ErrPetLIst) ->
    ?ERROR_LOG("_ErrPetLIst-------------------------:~p",[_ErrPetLIst]),
    <<>>.

pack_passivity_skill(List) ->
    lists:foldl(fun({Index, SkillId, _OldArrt}, Acc) ->
        <<Acc/binary, Index, SkillId:32>>
    end,
    <<(length(List))>>,
    List).
%%  create and init pet data------------------------------------------------------end


%% pet upgrade----------------------------------------------------------------------start
add_pet_new_exp_by_dan(Id, Exp) when Exp >= 0->
    add_pet_new_exp(Id, Exp).


add_pet_new_exp_if_fight(Exp) when is_integer(Exp) andalso Exp > 0->
    case get_cur_fight_pet_new() of
        ?false -> 
            pass;
        Id ->
            add_pet_new_exp(Id, Exp)
    end;
add_pet_new_exp_if_fight(List) when is_list(List) ->
    %?DEBUG_LOG("List----------------------:~p",[List]),
    case get_cur_fight_pet_new() of
        ?false -> 
            pass;
        Id ->
            case prize:get_item_count_of_type_on_prize_list(?PL_EXP, List) of
                ?none ->
                    pass;
                Exp ->
                    %?DEBUG_LOG("Exp----------------------:~p",[Exp]),
                    add_pet_new_exp(Id, Exp)
            end
    end;
add_pet_new_exp_if_fight(_ErrExp) ->
    % ?ERROR_LOG("ErrExp-------------------:~p",[ErrExp]).
    pass.

do_update_pet_new_attr_if_fight_status(CurPetNew, NextPetNew) ->
    CurPetLevelId = CurPetNew#pet_new.pet_level,
    NextPetLevelId = NextPetNew#pet_new.pet_level,
    if
        NextPetLevelId > CurPetLevelId ->
            update_pet_new_attr_if_fight_status(NextPetNew);
        true ->
            pass
    end.
    
add_pet_new_exp(Id, Exp) ->
    PetNew = get_pet_new_by_petid(Id),
    add_pet_new_exp_do(PetNew, Exp).

add_pet_new_exp_do(PetNew, Exp) ->
    PetNew2 = add_pet_new_exp_do2(PetNew, Exp),
    update_pet_new(PetNew2),
    do_update_pet_new_attr_if_fight_status(PetNew, PetNew2),
    %?DEBUG_LOG("PetNew2--------------------:~p",[PetNew2]),
    %% 更新宠物排行榜
    update_pet_ranking_list(),
    Level = load_cfg_new_pet:get_pet_level(PetNew2#pet_new.pet_level),
    ?player_send(pet_new_sproto:pkg_msg(?MSG_PET_NEW_UPGRADE, 
        {PetNew2#pet_new.id, Level,PetNew2#pet_new.cur_exp})).

add_pet_new_exp_do2(PetNew, AddExp) ->
    PetLevelId = PetNew#pet_new.pet_level,
    PetLevel = load_cfg_new_pet:get_pet_level(PetLevelId),
    PlayerLevel = get(?pd_level),
    case load_cfg_new_pet:get_pet_exp_by_level(PetLevel) of
        ?none ->
            PetNew#pet_new{cur_exp=load_cfg_new_pet:get_pet_exp_by_level(99)};
        GoalExp ->
            GoalLevel = PlayerLevel + 5,
            if
                PetLevel > GoalLevel ->
                    PetNew;
                PetLevel =:= PlayerLevel + 5 -> %% 
                    PetNew#pet_new{save_exp = PetNew#pet_new.save_exp + AddExp};
                true ->
                    AfterExp = PetNew#pet_new.cur_exp + AddExp + PetNew#pet_new.save_exp,
                    case GoalExp =< AfterExp of
                        ?true ->
                            NextExp = AfterExp - GoalExp,
                            FinalPetNew = upgrade_pet_new(PetNew, NextExp),
                            add_pet_new_exp_do2(FinalPetNew#pet_new{save_exp = 0}, 0);
                        ?false ->
                            PetNew#pet_new{cur_exp = AfterExp, save_exp = 0}
                end
            end
    end.







upgrade_pet_new(PetNew, NewExp) ->
    CurPetLevelId = PetNew#pet_new.pet_level,
    NextPetLevelId = CurPetLevelId + 1,
    DoAdvancePetNew = do_advance(PetNew, NextPetLevelId),
    DoOpenSkillSetPetNew = do_open_skill_set(DoAdvancePetNew, NextPetLevelId),
    DoAttrPetNew = do_attr(DoOpenSkillSetPetNew, CurPetLevelId, NextPetLevelId),
    FinalPetNew = DoAttrPetNew#pet_new{pet_level=NextPetLevelId, cur_exp=NewExp},
    FinalPetNew.

do_advance(PetNew, NextPetLevelId) ->
    OldAdvanceData = PetNew#pet_new.advance_data,
    case load_cfg_new_pet:is_can_advance(NextPetLevelId) of
        ?false ->
            PetNew;
        ?true ->
            case load_cfg_new_pet:get_advance_data(NextPetLevelId) of
                ?none ->
                    PetNew;
                {AdvanceLevel, _} = AdvanceData ->
                    NewAdvanceData = add_advance_data(OldAdvanceData, AdvanceLevel, AdvanceData),
                    PetNew#pet_new{advance_data=NewAdvanceData}
            end
    end.

do_open_skill_set(PetNew, NextPetLevelId) ->
    OldPassivitySkill = PetNew#pet_new.passivity_skill,
    case load_cfg_new_pet:get_open_skil_set(NextPetLevelId) of
        ?none ->
            PetNew;
        SetNum ->
            NewPassivitySkill = add_skill_set(OldPassivitySkill, SetNum),
            PetNew#pet_new{passivity_skill=NewPassivitySkill}
    end.

do_attr(PetNew, CurPetLevelId, NextPetLevelId) ->
    CurArrtId = load_cfg_new_pet:get_attr_id_by_pet_level(CurPetLevelId),
    NextAttrId = load_cfg_new_pet:get_attr_id_by_pet_level(NextPetLevelId),
    SubAttr = attr:sub(CurArrtId, PetNew#pet_new.attr_new),
    update_pet_new_arr(PetNew#pet_new{attr_new=SubAttr}, NextAttrId).

add_advance_data(OldAdvanceData, AdvanceLevel, AdvanceData) ->
    case lists:keyfind(AdvanceLevel, 1, OldAdvanceData) of
        ?false ->
            [AdvanceData|OldAdvanceData];
        _ ->
            OldAdvanceData
    end.

add_skill_set(OldPassivitySkill, SetNum) ->
    case lists:keyfind(SetNum, 1, OldPassivitySkill) of
        ?false ->
            [{SetNum, 0, 0}|OldPassivitySkill];
        _ ->
            OldPassivitySkill
    end.


%% pet upgrade------------------------------------------------------------------------end


%% pet advance----------------------------------------------------------------------start
auto_advance_pet_new(Id, Count) when Count > 0 ->
    case advance_pet_new(Id) of
        {FinalPetNew, Id, NextPetAdvance} ->
            if
                Count =:= 1 ->
                    update_pet_new_attr_if_fight_status(FinalPetNew),
                    ?player_send(pet_new_sproto:pkg_msg(?MSG_PET_NEW_ADVANCE, {Id, NextPetAdvance}));
                true ->
                    pass
            end,
            auto_advance_pet_new(Id, Count - 1);
        _ ->
            pass
    end;
auto_advance_pet_new(_, _) ->
    pass.

advance_pet_new(Id) ->
    case get_pet_new_by_petid(Id) of
        ?false ->
            ?return_err(?ERR_PET_NOT_EXIST);
        PetNew ->
            OldAdvanceData = PetNew#pet_new.advance_data,
            CurPetAdvance = PetNew#pet_new.pet_advance,
            NextPetAdvance = CurPetAdvance + 1,
            case lists:keyfind(NextPetAdvance, 1, OldAdvanceData) of
                ?false ->
                    ?return_err(?ERR_PET_CANT_ADVANCE);
                {_, NewPetLevelId} ->
                    case load_cfg_new_pet:get_advance_cost_and_attrid(NewPetLevelId) of
                        ?false ->
                            %?DEBUG_LOG("advance_pet_new---------------------------3"),
                            ?return_err(?ERR_PET_CANT_ADVANCE);
                        {CostId, AttrId} ->
                            case cost:cost(CostId, ?FLOW_REASON_PET_PHASE) of
                                ok ->
                                    achievement_mng:do_ac(?shenzhixushoushi),
                                    system_log:info_pet_phase(Id, CurPetAdvance, NextPetAdvance),
                                    notice_system:pet_jinjie_notice(PetNew#pet_new.pet_id, NextPetAdvance),
                                    %?DEBUG_LOG("advance_pet_new---------------------------4"),
                                    PetNew1 = do_advance_attr(CurPetAdvance, OldAdvanceData, PetNew),
                                    %NewdAdvanceData = del_advance_data(OldAdvanceData, NextPetAdvance),
                                    NewdAdvanceData = OldAdvanceData,
                                    PetNew2 = PetNew1#pet_new{pet_advance=NextPetAdvance, advance_data=NewdAdvanceData},
                                    FinalPetNew = update_pet_new_arr(PetNew2, AttrId),
                                    update_pet_new(FinalPetNew),
                                    %update_pet_new_attr_if_fight_status(FinalPetNew),
                                    %?player_send(pet_new_sproto:pkg_msg(?MSG_PET_NEW_ADVANCE, {Id, NextPetAdvance})),
                                    open_server_happy_mng:sync_task(?PET_JING_JIE, get_the_pet_highest_advance()),
                                    {FinalPetNew, Id, NextPetAdvance};
                                _ ->
                                    %?DEBUG_LOG("advance_pet_new---------------------------5"),
                                    ?return_err(?ERR_COST_NOT_ENOUGH)
                            end
                    end
            end
    end.

do_advance_attr(CurPetAdvance, OldAdvanceData, PetNew) ->
    if
        CurPetAdvance =:= 0 ->
            PetNew;
        true ->
            case lists:keyfind(CurPetAdvance -1, 1, OldAdvanceData) of
                ?false ->
                    PetNew;
                {_, PetLevelId} ->
                    SubAttrId = load_cfg_new_pet:get_advance_attrid(PetLevelId),
                    SubAttr = attr:sub(SubAttrId, PetNew#pet_new.attr_new),
                    PetNew#pet_new{attr_new=SubAttr}
            end
    end.

% del_advance_data(OldAdvanceData, AdvanceLevel) ->
%     case lists:keyfind(AdvanceLevel, 1, OldAdvanceData) of
%         ?false ->
%             OldAdvanceData;
%         _ ->
%             lists:keydelete(AdvanceLevel, 1, OldAdvanceData)
%     end.

get_all_advance_pet_cost_id(CurPetAdvance, OldAdvanceData) ->
    lists:foldl(fun({OldAdvance, PetLevelId}, CostIdList) ->
        if
            OldAdvance =< CurPetAdvance  ->
                case load_cfg_new_pet:lookup_pet_upgrade_new_cfg(PetLevelId) of
                    ?none ->
                        CostIdList;
                    #pet_upgrade_new_cfg{advance_cost=AdvanceCostId} ->
                        [AdvanceCostId|CostIdList]
                end;
            true ->
                CostIdList
        end
    end,
    [],
    OldAdvanceData).

return_advance_pet_cost(PetNew, CostPercent) ->
    OldAdvanceData = PetNew#pet_new.advance_data,
    CurPetAdvance = PetNew#pet_new.pet_advance,
    CostIdList = get_all_advance_pet_cost_id(CurPetAdvance, OldAdvanceData),
    cost:get_cost_item_list(CostIdList, CostPercent, 1000).

%% pet advance------------------------------------------------------------------------end



%% pet initiative_skill upgrade------------------------------------------------------------------------start
auto_upgrade_pet_initiative_skill(Id, Count) when Count > 0 ->
    case upgrade_pet_initiative_skill(Id) of
        {Id, NextSkillLevel} ->
            if
                Count =:= 1 ->
                    ?player_send(pet_new_sproto:pkg_msg(?MSG_PET_NEW_UPGRADE_SKILL, {Id, NextSkillLevel}));
                true ->
                    pass
            end,
            auto_upgrade_pet_initiative_skill(Id, Count - 1);
        _ ->
            pass
    end;
auto_upgrade_pet_initiative_skill(_, _) ->
    pass.

upgrade_pet_initiative_skill(Id) ->
    case get_pet_new_by_petid(Id) of
        ?false ->
            ?return_err(?ERR_PET_NOT_EXIST);
        PetNew ->
            PetId = PetNew#pet_new.pet_id,
            InitiativeSkillList = PetNew#pet_new.initiative_skill,
            SkillLevelId = get_pet_initativeskill(PetId, InitiativeSkillList),
            SkillLevel = load_cfg_new_pet:get_pet_initativeskill_level(SkillLevelId),
            if
                SkillLevel < 100 ->
                    CostId = load_cfg_new_pet:get_skill_cost(SkillLevelId),
                    case cost:cost(CostId, ?FLOW_REASON_PET_SKILL) of
                        ok ->
                            {NextSkillLevel,NewInitiativeSkillList} = update_pet_initativeskill(PetId, SkillLevel, InitiativeSkillList),
                            FinalPetNew = PetNew#pet_new{initiative_skill=NewInitiativeSkillList},
                            update_pet_new(FinalPetNew),
                            %?DEBUG_LOG("NextSkillLevel----:~p---NewInitiativeSkillList---:~p",[NextSkillLevel, NewInitiativeSkillList]),
                            %?player_send(pet_new_sproto:pkg_msg(?MSG_PET_NEW_UPGRADE_SKILL, {Id, NextSkillLevel}));
                            {Id, NextSkillLevel};
                        _ ->
                            ?return_err(?ERR_COST_NOT_ENOUGH)
                    end;
                true ->
                    ?return_err(?ERR_PET_MAX_LEVEL)
            end
    end.

update_pet_initativeskill(PetId, SkillLevel, List) ->
    SkillId = load_cfg_new_pet:get_initiative_skill(PetId),
    %?DEBUG_LOG("PetId--:~p--SkillLevel--:~p---List--:~p---SkillId--:~p",[PetId, SkillLevel, List, SkillId]),
    case lists:keyfind(SkillId, 1, List) of
        ?false ->
            {SkillLevel, List};
        {_, OldSkillLevel} ->
            {SkillLevel+1, lists:keyreplace(SkillId, 1, List, {SkillId, OldSkillLevel+1})}
    end.

return_upgrade_skill_pet_cost(PetNew, CostPercent) ->
    PetId = PetNew#pet_new.pet_id,
    InitiativeSkillList = PetNew#pet_new.initiative_skill,
    SkillLevelId = get_pet_initativeskill(PetId, InitiativeSkillList),   
    CostIdList = load_cfg_new_pet:get_all_skill_upgrade_cost_id(SkillLevelId),
    cost:get_cost_item_list(CostIdList, CostPercent, 1000).

%% pet initiative_skill upgrade--------------------------------------------------------------------------end


%% feng yin ---------------------------------------------------------------------------------------------start
fenyin_pet_new(Id) ->
    case get(?pd_pet_fight) of
        Id ->
            ?return_err(?ERR_PET_NOT_FENGYIN);
        _ ->
            case get_pet_new_by_petid(Id) of
                ?false ->
                    ?return_err(?ERR_PET_NOT_EXIST);
                PetNew ->
                    %CurExp = PetNew#pet_new.cur_exp,
                    %PetId = PetNew#pet_new.pet_id,
                    FengYinData = PetNew#pet_new.fengyin_data,
                    %?DEBUG_LOG("FengYinData--------------------------:~p",[FengYinData]),
                    CostList = [lists:nth(3, misc_cfg:get_pet_pool())],
                    BagBucket = game_res:get_bucket(?BUCKET_TYPE_BAG),      %%封印之石
                    Num = goods_bucket:count_item_size(BagBucket, 0, 2009),
                    R =
                    if
                        Num > 0 ->
                            game_res:del([{2009, 1}], ?FLOW_REASON_PET_FENGYIN),
                            ok;
                        true ->
                            case game_res:can_del(CostList) of
                                ok ->
                                    game_res:del(CostList, ?FLOW_REASON_PET_FENGYIN),
                                    ok;
                                _ ->
                                    error
                            end
                    end,
                    if
                        R =:= ok ->
                            %game_res:del(CostList, ?FLOW_REASON_PET_FENGYIN),
                            return_cost_data(PetNew, FengYinData),
                            del_pet_new(PetNew),
                            % ?DEBUG_LOGT_NEW_FENGYIN------------------------"),
                            ?player_send(pet_new_sproto:pkg_msg(?MSG_PET_NEW_FENGYIN, {}));
                        true ->
                            ?return_err(?ERR_COST_NOT_ENOUGH)
                    end
            end
    end.

return_cost_data(PetNew, FengYinData) ->
    TotalExp = do_total_exp(PetNew),
    %?DEBUG_LOG("TotalExp----------------------:~p",[TotalExp]),
    {Rate, L} = misc_cfg:get_pet_fengyin(),
    NewExp = erlang:round(TotalExp * (Rate/1000)),
    List = do_return_cost_data(L, NewExp, []),
    AdvanceCostList = return_advance_pet_cost(PetNew, Rate),
    %?DEBUG_LOG("AdvanceCostList---------:~p",[AdvanceCostList]),
    UpgradeSkillCostList = return_upgrade_skill_pet_cost(PetNew, Rate),
    %?DEBUG_LOG("UpgradeSkillCostList----------:~p",[UpgradeSkillCostList]),
    {ItemBid, PassivitySkill} = lists:nth(1, FengYinData),
    %?DEBUG_LOG("ItemBid------:~p-----PassivitySkill---:~p",[ItemBid, PassivitySkill]),
    NewItem = entity_factory:build(ItemBid, 1, [{3, PassivitySkill}], ?FLOW_REASON_PET_FENGYIN),
    %?DEBUG_LOG("NewItem--------------------------:~p",[NewItem]),
    game_res:try_give_ex([{NewItem}], ?FLOW_REASON_PET_FENGYIN),
    List2 = cost:do_get_cost_item_list(AdvanceCostList, List),
    FinalList = item_goods:merge_goods(cost:do_get_cost_item_list(UpgradeSkillCostList, List2)),
    %?DEBUG_LOG("FinalList--------------------:~p",[FinalList]),
    prize:send_prize_of_itemlist(FinalList, ?S_MAIL_PET_ADD_DAN, ?FLOW_REASON_PET_FENGYIN).

do_return_cost_data([], _, List) ->
    %?DEBUG_LOG("do_return_cost_data---------------------:~p",[List]),
    List;
do_return_cost_data([{Id, R}|T], TotalExp, List) ->
    %?DEBUG_LOG("TotalExp------------------------------:~p",[TotalExp]),
    %?DEBUG_LOG("Id---------------:~p--------------R--------------:~p",[Id, R]),
    Num = erlang:round(TotalExp div R),
    NewList = 
    if
        Num > 0 ->
            cut_dan(Id, Num, List);
        true ->
            List
    end,
    do_return_cost_data(T, TotalExp rem R, NewList).

cut_dan(_Id, 0, List) ->
    List;
cut_dan(Id, Num, List) ->
    cut_dan(Id, Num - 1, [{Id, 1}|List]).

do_total_exp(PetNew) ->
    PetLevelId = PetNew#pet_new.pet_level,
    CurExp = PetNew#pet_new.cur_exp,
    PetLevel = load_cfg_new_pet:get_pet_level(PetLevelId),
    %?DEBUG_LOG("PetLevel------------------------------:~p",[PetLevel]),
    %?DEBUG_LOG("CurExp--------------------------------:~p",[CurExp]),
    AllLevelExp = do_total_exp_(PetLevel, 0),
    %?DEBUG_LOG("AllLevelExp-------------------------:~p",[AllLevelExp]),
    AllLevelExp + CurExp.
do_total_exp_(PetLevel, Sum) ->
    case load_cfg_new_pet:get_pet_exp_by_level(PetLevel) of
        ?none ->
            Sum;
        GoalExp ->
            %?DEBUG_LOG("PetLevel----:~p------GoalExp-----:~p",[PetLevel, GoalExp]),
            do_total_exp_(PetLevel-1, Sum+GoalExp)
    end.

%% feng yin ---------------------------------------------------------------------------------------------end

%% passivity_skill  xiaoguo------------------------------------------------------------------------------start

get_passivity_skill_attr_to_pet_new(PassivitySkillId, Attr) ->
    NewAttr = 
    case load_cfg_new_pet:get_pet_new_attr_id_and_ratio_and_value_type_by_passivity_id(PassivitySkillId) of
        ?none ->
            0;
        {?ABS_TYPE, {BbId, Value}} ->
            attr:add_by_sat(BbId, Value, attr:new());
        {?BAIFENBI_TYPE, {BbId, Ratio}} ->
            Rate = Ratio / 100,
            Value = attr:get_attr_value_by_sats(BbId, Attr),
            AddAttr = attr:add_by_sat(BbId, Value, attr:new()),
            attr:ratio(Rate, AddAttr)
    end,
    {NewAttr, attr:add(NewAttr, Attr)}.

add_passivity_skill_attr_to_pet_new(PetNew, PassivitySkillId) ->
    AttrNew = PetNew#pet_new.attr_new,
    {FinalAddAttr, FinalAttr} = 
    case load_cfg_new_pet:get_pet_new_attr_id_and_ratio_and_value_type_by_passivity_id(PassivitySkillId) of
        ?none ->
            {0, AttrNew};
        {?ABS_TYPE, {BbId, Value}} ->
            A1 = attr:add_by_sat(BbId, Value, attr:new()),
            {A1, attr:add_by_sat(BbId, Value, AttrNew)};
        {?BAIFENBI_TYPE, {BbId, Ratio}} ->
            Rate = Ratio / 100,
            Value = attr:get_attr_value_by_sats(BbId, AttrNew),
            AddAttr = attr:add_by_sat(BbId, Value, attr:new()),
            AddAttr2 = attr:ratio(Rate, AddAttr),
            {AddAttr2, attr:add(AddAttr2, AttrNew)}
    end,
    {FinalAddAttr, PetNew#pet_new{attr_new = FinalAttr}}.

del_passivity_skill_attr_to_pet_new(PetNew, 0) ->
    PetNew;
del_passivity_skill_attr_to_pet_new(PetNew, OldArrt) ->
    AttrNew = PetNew#pet_new.attr_new,
    FinalAddAttr = attr:sub(AttrNew, OldArrt),
    %%?DEBUG_LOG("AttrNew---------:~p",[AttrNew]),
    %?DEBUG_LOG("OldArrt---------:~p",[OldArrt]),
    %?DEBUG_LOG("FinalAddAttr---------:~p",[FinalAddAttr]),
    PetNew#pet_new{attr_new = FinalAddAttr}.




%% passivity_skill xiaoguo-------------------------------------------------------------------------------end


%% xishou-----------------------------------------------------------------------------------------------start
xishou_pet_new(Id, Index, DanId) ->
    case get_pet_new_by_petid(Id) of
        ?false ->
            ?return_err(?ERR_PET_NOT_EXIST);
        PetNew ->
            %PetId = PetNew#pet_new.pet_id,
            Goods = goods_bucket:find_goods(game_res:get_bucket(?BUCKET_TYPE_BAG), by_id, {DanId}),
            {_Index, NewPassivitySkillId} = get_passivity_skill_on_egg(use_goods:get_item_ex(Goods)),
            case load_cfg_new_pet:get_pet_new_overlap_by_pasivity_id(NewPassivitySkillId) of
                ?none ->
                    ?return_err(?ERR_PET_NOT_PASSIVITYSKILL_ID);
                OverLap ->
                    %?DEBUG_LOG("NewPassivitySkillId-----:~p----OverLap---:~p",[NewPassivitySkillId, OverLap]),
                    do_xishou_pet_new(PetNew, Index, NewPassivitySkillId, OverLap, Goods, DanId)
            end
    end.

do_xishou_pet_new(PetNew, Index, NewPassivitySkillId, _OverLap, Goods, DanId) ->
    PassivitySkillList = PetNew#pet_new.passivity_skill,
    case lists:keyfind(Index, 1, PassivitySkillList) of
        {_, NewPassivitySkillId, _OldArrt} ->
            ?return_err(?ERR_PET_POS_REPEAT);
        {_, _OldPassivitySkillId, OldAttr} ->
            %case is_can_xishou(PassivitySkillList, OverLap) of
            %    ?false ->
            %        ?return_err(?ERR_PET_POS_REPEAT_OF_ATTR);
            %    ?true ->
                    game_res:try_del([{by_id, {DanId, 1}}], ?FLOW_REASON_PET_XISHOU),
                    PetNew2 = del_passivity_skill_attr_to_pet_new(PetNew, OldAttr),
                    {AddAt2, PetNew3} = add_passivity_skill_attr_to_pet_new(PetNew2, NewPassivitySkillId),
                    Nps2 = lists:keyreplace(Index, 1, PassivitySkillList, {Index, NewPassivitySkillId, AddAt2}),
                    FinalPetNew1 = PetNew3#pet_new{passivity_skill=Nps2},
                    FinalPetNew2 = is_update_fengyin_data(FinalPetNew1, Goods, NewPassivitySkillId),
                    update_pet_new(FinalPetNew2),
                    ?player_send(pet_new_sproto:pkg_msg(?MSG_PET_NEW_PASSIVITY_SKILL_INLAY, {}));
            %end;
        _ ->
            ?ERROR_LOG("do_xishou_pet_new---------------------------------")    
    end.
is_update_fengyin_data(PetNew, Goods, NewPassivitySkillId) ->
    FengYinData = PetNew#pet_new.fengyin_data,
    Size = length(FengYinData),
    if
        Size =:= 1 ->
            case lists:nth(1, FengYinData) of
                {_, 0} ->
                    PetNew#pet_new{fengyin_data=[{Goods, NewPassivitySkillId}]};
                _ ->
                    PetNew
            end;
        true ->
            PetNew         
    end.

% is_can_xishou([], _OverLap) ->
%     ?true;
% is_can_xishou([{_, 0, _}|_T], _OverLap) ->
%     ?true;
% is_can_xishou([{_, SkillId, _}|T], OverLap) ->
%     case load_cfg_new_pet:get_pet_new_overlap_by_pasivity_id(SkillId) of
%         ?none ->
%             ?false;
%         OverLap ->
%             ?false;
%         _ ->
%             is_can_xishou(T, OverLap)
%     end.

%% xishou------------------------------------------------------------------------------------------------end


%% shangzhen----------------------------------------------------------------------------------------start
pack_shangzhen_data(List) when is_list(List)->
    lists:foldl(fun({Index, Id}, Acc) ->
        <<Acc/binary, Index, Id:32>>
    end,
    <<(length(List))>>,
    List);
pack_shangzhen_data(ErrData) ->
    ?ERROR_LOG("ErrData------------------:~p",[ErrData]),
    <<>>.

do_shangzhen_pet_new(Id, Status, Index, {A, ShangZhenList}, Flag) ->
    case get_cur_fight_pet_new() of
        Id ->
            pass;
        _ -> 
            List = get(?pd_pet_list),
            case lists:keyfind(Id, #pet_new.id, List) of
                ?false ->
                    ?DEBUG_LOG("shangzhen_pet_new---------------------------1"),
                    ?return_err(?ERR_PET_NOT_EXIST);
                PetNew ->
                    FinalPetNew = PetNew#pet_new{status=Status},
                    update_pet_new(FinalPetNew),
                    NewId = get_shangzhen_status(Status, Id),
                    NewShangZhenList = lists:keyreplace(Index, 1, ShangZhenList, {Index, NewId}),
                    put(?pd_pet_shangzhen_list, {A, NewShangZhenList}),
                    add_pet_new_shangzhen_attr_to_player(FinalPetNew, Index, Status, Flag),
                    %% 更新宠物排行榜
                    update_pet_ranking_list(),
                    ok
            end
    end.

shangzhen_pet_new(_NewId, ?XIAZHEN, Index) ->
    {A, ShangZhenList} = get(?pd_pet_shangzhen_list),
    %?DEBUG_LOG("ShangZhenList------------------:~p",[ShangZhenList]),
    case lists:keyfind(Index, 1, ShangZhenList) of
        {_, OldNewId} when OldNewId > 0 ->
            do_shangzhen_pet_new(OldNewId, ?XIAZHEN, Index, {A, ShangZhenList}, 1);
        _A ->
            ?ERROR_LOG("shangzhen_pet_new -------_A----:~p",[_A]),
            ?return_err(?ERR_PET_NOT_XIAZHEN)
    end;
shangzhen_pet_new(NewId, ?SHENGZHEN, Index) ->
    {A, ShangZhenList} = get(?pd_pet_shangzhen_list),
    open_server_happy_mng:sync_task(?ACTIVATE_PET_GONGMING_ATTR, length(ShangZhenList)),
    %?DEBUG_LOG("ShangZhenList------------------:~p",[ShangZhenList]),
    case lists:keyfind(Index, 1, ShangZhenList) of
        ?false ->
            ?return_err(?ERR_PET_NOT_SHANGZHEN);
        {_, OldNewId} when OldNewId > 0 ->
            do_shangzhen_pet_new(OldNewId, ?XIAZHEN, Index, {A, ShangZhenList}, 0),
            do_shangzhen_pet_new(NewId, ?SHENGZHEN, Index, {A, ShangZhenList}, 1);
        {_, OldNewId} when OldNewId =:= 0 ->
            do_shangzhen_pet_new(NewId, ?SHENGZHEN, Index, {A, ShangZhenList}, 1)
    end.


get_shangzhen_status(Status, Id) ->
    if
        Status =:= ?SHENGZHEN ->
            Id;
        Status =:= ?XIAZHEN ->
            0;
        true ->
            0
    end.

add_pet_new_shangzhen_attr_to_player(PetNew, Index, ?SHENGZHEN, Flag) ->
    Attr = PetNew#pet_new.attr_new,
    ShangZhenAttrList = get(?pd_pet_shangzhen_attr_list),
    case lists:keyfind(Index, 1, ShangZhenAttrList) of
        ?false ->
            case load_cfg_new_pet:get_pet_new_attr_id_and_ratio_by_setid(Index) of
                ?none ->
                    pass;
                {BbId, Ratio} ->
                    Rate = Ratio / 1000,
                    Value = attr:get_attr_value_by_sats(BbId, Attr),
                    AddAttr = attr:add_by_sat(BbId, Value, attr:new()),
                    %?DEBUG_LOG("Index---:~p---BbId---:~p---Value---:~p",[Index, BbId, AddAttr]),
                    FinalAddAttr = attr:ratio(Rate, AddAttr),
                    add_pet_new_shangzhen_attr_list({Index, FinalAddAttr}, ShangZhenAttrList),
                    %?DEBUG_LOG("FinalAddAttr--------------------:~p",[FinalAddAttr]),
                    %player:add_attr_amend(FinalAddAttr),
                    if
                        Flag =:= 1 ->
                            player:add_attr_amend(FinalAddAttr);
                        Flag =:= 0 ->
                            player:add_attr_and_not_notify(FinalAddAttr)
                    end,
                    open_server_happy_mng:sync_task(?PET_GONGMING_UPDATE_POWER, get(?pd_power))
            end;
        _ ->
            ?DEBUG_LOG("1------------------------------------------------"),
            pass
    end;

add_pet_new_shangzhen_attr_to_player(_PetNew, Index, ?XIAZHEN, Flag) ->
    ShangZhenAttrList = get(?pd_pet_shangzhen_attr_list),
    %?DEBUG_LOG("ShangZhenAttrList---------------------------------:~p",[ShangZhenAttrList]),
    case lists:keyfind(Index, 1, ShangZhenAttrList) of
        ?false ->
            pass;
        {_, SubAttr} = D ->
            del_pet_new_shangzhen_attr_list(D, ShangZhenAttrList),
            %?DEBUG_LOG("ShangZhenAttrList2---------------------------:~p",[get(?pd_pet_shangzhen_attr_list)]),
            %player:sub_attr_amend(SubAttr)
            if
                Flag =:= 1 ->
                    player:sub_attr_amend(SubAttr);
                Flag =:= 0 ->
                    player:sub_attr_and_not_notify(SubAttr)
            end
    end,
    ok.

add_pet_new_shangzhen_attr_list(D,ShangZhenAttrList) ->
   put(?pd_pet_shangzhen_attr_list, [D|ShangZhenAttrList]). 


del_pet_new_shangzhen_attr_list(D,ShangZhenAttrList) ->
   put(?pd_pet_shangzhen_attr_list, lists:delete(D, ShangZhenAttrList)). 
    

%% shangzhen----------------------------------------------------------------------------------------end

%% fight pet new ----------------------------------------------------------------------------------start
fight_pet_new(Id) ->
    case get_pet_new_by_petid(Id) of
        ?false ->
            ?return_err(?ERR_PET_NOT_EXIST);
        PetNew ->
            put(?pd_pet_fight, Id),
            FinalPetNew = PetNew#pet_new{status = ?PET_NEW_STATUS_FIGHT},
            ?player_send(pet_new_sproto:pkg_msg(?MSG_PET_NEW_GAN, {Id, ?PET_NEW_STATUS_FIGHT})),
            pet_new_enter_scene(0, get(?pd_name_pkg), get(?pd_idx), get(?pd_x), get(?pd_y)),
            update_pet_new(FinalPetNew),
            update_pet_new_attr_if_fight_status(FinalPetNew)
    end.

cancel_fight_pet_new(Id, Flag) ->
    pet_new_leave_scene(get(?pd_scene_pid), get(?pd_idx)),
    put(?pd_pet_fight, 0),
    %?DEBUG_LOG("cancel_fight_pet_new------------------------:~p",[Id]),
    case get_pet_new_by_petid(Id) of
        ?false ->
            ?return_err(?ERR_PET_NOT_EXIST);
        PetNew ->
            del_pet_new_attr_to_player(PetNew, Flag),
            PetNew2 = PetNew#pet_new{status = ?PET_NEW_STATUS_ALIVE, attr_old=0},
            update_pet_new(PetNew2),
            %% OK 把宠物的属性加成到玩家身上的删掉
            %?DEBUG_LOG("cancel_fight_pet_new-------------------------------:~p",[PetNew2]),
            ?player_send(pet_new_sproto:pkg_msg(?MSG_PET_NEW_GAN, {Id, ?PET_NEW_STATUS_ALIVE}))
    end.
   
%% 玩家进入场景让宠物也进入场景
pet_new_enter_scene(_From, PlayerNamePkg, PlayerIdx, X, Y) ->
    case load_cfg_scene:is_pet_fight(get(?pd_scene_id)) of
        1 ->
            Pid = get(?pd_scene_pid),
            case get(?pd_pet_fight) of
                ?undefined ->
                    ok;
                0 ->
                    ok;
                FightPetId ->
                    %?DEBUG_LOG("pet_new_enter_scene----From,X,Y-----:~p",[{From, X, Y}]),
                    Pid ! {mod, scene_pet, {?enter_scene_msg, PlayerNamePkg, PlayerIdx, X, Y, get_pet_new_by_petid(FightPetId)}}
            end;
        _ ->
            ok
    end.

%% 玩家离开场景让宠物也离开场景
pet_new_leave_scene(LeaveScenePid, PlayerIdx) ->
    case get(?pd_pet_fight) of
        ?undefined ->
            ok;
        0 ->
            ok;
        _FightPetId ->
            LeaveScenePid ! {mod, scene_pet, {?leave_scene_msg, PlayerIdx}}
    end.

update_pet_new_attr_if_fight_status(PetNew) ->
    Status = PetNew#pet_new.status,
    PetId = PetNew#pet_new.id,
    if
        Status =:= ?PET_NEW_STATUS_FIGHT ->
            update_pet_new_attr_to_player(PetNew);
        Status =:= ?PET_NEW_STATUS_SHANGZHEN ->
            {A, ShangZhenList} = get(?pd_pet_shangzhen_list),
            case lists:keyfind(PetId, 2, ShangZhenList) of
                {Index, OldNewId} when OldNewId > 0 ->
                    %?DEBUG_LOG("PetId----:~p----Index--------:~p-------OlDNewId-------:~p",[PetId,Index, OldNewId]),
                    do_shangzhen_pet_new(OldNewId, ?XIAZHEN, Index, {A, ShangZhenList}, 0),
                    do_shangzhen_pet_new(PetId, ?SHENGZHEN, Index, {A, ShangZhenList}, 1);
                _A ->
                   pass
            end;
        true ->
            pass
    end.



%%更新玩家身上的宠物属性
update_pet_new_attr_to_player(PetNew) ->
    Rate = lists:nth(2, misc_cfg:get_pet_pool()) / 1000,
    AddRatioAttr = attr:ratio(Rate, PetNew#pet_new.attr_new),
    case PetNew#pet_new.attr_old of
        ?undefined ->
            ok;
        0 ->
            ok;
        SubOneAttr ->
            player:sub_attr_and_not_notify(SubOneAttr)
    end,
    %?DEBUG_LOG("Attr 1-----------------------------:~p",[PetNew#pet_new.attr_new]),
    %?DEBUG_LOG("Attr 2-----------------------------:~p",[AddRatioAttr]),
    NewAttr1 = AddRatioAttr#attr{move_speed = 0, run_speed = 0},
    update_pet_new(PetNew#pet_new{attr_old = NewAttr1}),
    %?DEBUG_LOG("NewAttr1 2-----------------------------:~p",[NewAttr1]),
    player:add_attr_amend(NewAttr1).

del_pet_new_attr_to_player(PetNew, Flag) ->
    Attr = PetNew#pet_new.attr_old,
    %?DEBUG_LOG("DEL attr----------------------------:~p",[Attr]),
    if
        Flag =:= 1 ->
            player:sub_attr_and_not_notify(Attr);
        Flag =:= 2 ->
            player:sub_attr_amend(Attr)
    end.
    %player:sub_attr_amend(Attr).



%% fight pet new ------------------------------------------------------------------------------------end

load_db_table_meta() ->
    [
        #db_table_meta{
            name = ?player_pets_tab,
            fields = ?record_fields(player_pets_tab),
            shrink_size = 1,
            flush_interval = 2
        }
    ].


create_mod_data(SelfId) ->
    dbcache:insert_new(?player_pets_tab, #player_pets_tab{id = SelfId}),
    ok.

load_mod_data(PlayerId) ->
    case dbcache:load_data(?player_pets_tab, PlayerId) of
        [] ->
            create_mod_data(PlayerId),
            load_mod_data(PlayerId);
        [#player_pets_tab{pet_list = List, fight_pet = FightPet, shangzhen_list=SzL, shangzhen_attr_list=Sal}] ->
            ?pd_new(?pd_pet_list, List),
            ?pd_new(?pd_pet_fight, FightPet),
            ?pd_new(?pd_pet_shangzhen_list, SzL),
            ?pd_new(?pd_pet_shangzhen_attr_list, Sal)
    end.

init_client() ->
    ?player_send(pet_new_sproto:pkg_msg(?MSG_PET_NEW_PET_LIST, {pack_pet_new(get(?pd_pet_list))})),
    {_, List} = get(?pd_pet_shangzhen_list),
    %?DEBUG_LOG("List------------------------:~p",[List]),
    ?player_send(pet_new_sproto:pkg_msg(?MSG_PET_NEW_SHANGZHEN_LIST, {pack_shangzhen_data(List)})).

view_data(_Acc) -> 
    PetId = get_cur_fight_pew_new_cfg_id(),
    %?DEBUG_LOG("view data PetId---------------------------------------:~p",[PetId]),
    <<PetId:32>>.

handle_frame(Frame) ->
    ?err({unknown_frame, Frame}).

handle_msg(_FromMod, Msg) ->
    ?err({unknown_msg, Msg}).

online() ->
    ok.

offline(_SelfId) ->
    ok.

save_data(SelfId) ->
    dbcache:update(?player_pets_tab, #player_pets_tab{id = SelfId,
    pet_list = get(?pd_pet_list),
    fight_pet = get(?pd_pet_fight),
    shangzhen_list = get(?pd_pet_shangzhen_list),
    shangzhen_attr_list = get(?pd_pet_shangzhen_attr_list)}).

handle_client({Pack, Arg}) -> 
    handle_client(Pack, Arg).

handle_client(?MSG_PET_NEW_UPGRADE, {Id, ItemId, Num}) ->
    %?DEBUG_LOG("Id----:~p----ItemId---:~p---Num---:~p",[Id, ItemId, Num]),
    %PetId = load_item:get_petid_on_item_use_effect(ItemId),
    %Exp = load_cfg_new_pet:get_pet_new_exp_by_id(PetId),
    Exp = load_item:get_pet_exp_on_item_use_effect(ItemId),
    %?DEBUG_LOG("Exp--------------------------------:~p",[Exp]),
    case game_res:can_del([{ItemId, Num}]) of
        ok ->
            bounty_mng:do_bounty_task(?BOUNTY_TASK_SHENGJI_PET, 1),
            open_server_happy_mng:sync_task(?UPDATE_PET_COUNT, 1),
            add_pet_new_exp_by_dan(Id, Exp * Num),
            game_res:del([{ItemId, Num}], ?FLOW_REASON_PET_UPGRADE);
        {error, _Other} ->
            ?DEBUG_LOG("-------------------------------------------------"),
            pass
    end;

handle_client(?MSG_PET_NEW_ADVANCE, {Id, Count}) ->
    %?DEBUG_LOG("advance --------------------:~p",[Id]),
    %advance_pet_new(Id);
    auto_advance_pet_new(Id, Count);

handle_client(?MSG_PET_NEW_UPGRADE_SKILL, {Id, Count}) ->
    %?DEBUG_LOG("upgrade skill -----------:~p",[Id]),
    %upgrade_pet_initiative_skill(Id);
    auto_upgrade_pet_initiative_skill(Id, Count);

handle_client(?MSG_PET_NEW_FENGYIN, {Id}) ->
    %?DEBUG_LOG("pengyin -------------------:~p",[Id]),
    fenyin_pet_new(Id);

handle_client(?MSG_PET_NEW_PASSIVITY_SKILL_INLAY, {Id, Index, DanId}) ->
    %?DEBUG_LOG("Id-------:~p----Index---:~p---DanId--:~p",[Id, Index, DanId]),
    xishou_pet_new(Id, Index, DanId);

handle_client(?MSG_PET_NEW_SHANGZHEN, {Id, Status, Index}) ->
    %?DEBUG_LOG("Id----:~p-----Index---:~p",[Id, Index]),
    case shangzhen_pet_new(Id, Status, Index) of
        ok ->
            ?player_send(pet_new_sproto:pkg_msg(?MSG_PET_NEW_SHANGZHEN, {}));
        _ ->
            pass
    end;


handle_client(?MSG_PET_NEW_GAN, {Id, 1}) ->
    %?DEBUG_LOG("gan id--------------------------1---:~p",[Id]),
    case get_pet_new_by_petid(Id) of
        ?false ->
            pass;
        _PetNew ->
            FightPetId = get(?pd_pet_fight),
            if
                FightPetId =:= Id ->
                    pass;
                FightPetId > 0 ->
                    cancel_fight_pet_new(FightPetId, 1),
                    fight_pet_new(Id);
                true ->
                    fight_pet_new(Id)
            end
    end;

handle_client(?MSG_PET_NEW_GAN, {Id, 3}) ->
    %?DEBUG_LOG("gan Id---------------------------3--:~p",[Id]),
    case get_pet_new_by_petid(Id) of
        ?false ->
            pass;
        _PetNew ->
            FightPetId = get(?pd_pet_fight),
            %?DEBUG_LOG("FightPetId------------------------:~p",[FightPetId]),
            if
                FightPetId =:= Id ->
                    cancel_fight_pet_new(FightPetId, 2);
                true ->
                    pass
            end
    end;


handle_client(_MSG, _) ->
    {error, unknown_msg}.

%% 获得玩家宠物战斗力列表
get_pet_power_list() ->
    PetList = util:get_pd_field(?pd_pet_list, []),
    lists:foldl
    (
        fun(PetNew, Acc) ->
            #pet_new{id = Id, pet_level=PetLev, attr_new = Attr} = PetNew,
            NewAttr = attr_new:get_oldversion_equip_attr(Attr),
            Power = attr_new:get_combat_power(NewAttr),
            [{Id, Power, PetLev} | Acc]
        end,
        [],
        PetList
    ).

%% 获得玩家最牛逼的宠物
get_the_best_pet() ->
    PetPowerList = get_pet_power_list(),
    NewPetList = lists:keysort(2, PetPowerList),
    case NewPetList of
        [] ->
            {0,0};
        NewPetList ->
            {_Id,Power,PetLev} = lists:last(NewPetList),
            {Power, PetLev}
    end.
%% 获得玩家宠物最高进阶等级
get_the_pet_highest_advance() ->
    PetList = util:get_pd_field(?pd_pet_list, []),
    PetAdvanceList=
        lists:foldl
        (
            fun(PetNew, Acc) ->
                #pet_new{pet_advance = PetAdvance} = PetNew,
                [PetAdvance | Acc]
            end,
            [],
            PetList
        ),
    lists:max(PetAdvanceList).


get_best_pet_power_and_gongming_power() ->
    ShangZhenAttrList = get(?pd_pet_shangzhen_attr_list),
    GongMingPower =
        lists:foldl(
            fun({_Index, FinalAddAttr}, Acc) ->
                NewAttr = attr_new:get_oldversion_equip_attr(FinalAddAttr),
                Power = attr_new:get_combat_power(NewAttr),
                Power+Acc
            end,
            0,
            ShangZhenAttrList
        ),
    {PetPower, _} = get_the_best_pet(),
    PetPower + GongMingPower.

%% 刷新宠物排行榜
update_pet_ranking_list() ->
%%    BestPet = get_the_best_pet(),
    PetAndGongMingPower = get_best_pet_power_and_gongming_power(),
    [Lev, Power] = player:lookup_info(get(?pd_id), [?pd_level, ?pd_combat_power]),
    ranking_lib:update( ?ranking_pet, get(?pd_id), {PetAndGongMingPower, Lev, Power}),
    util:is_flush_rank_only_by_rankname(?ranking_pet, get(?pd_id)).
%%    ranking_lib:flush_rank_only_by_rankname(?ranking_pet).

get_pet_id() ->
    PetPowerList = get_pet_power_list(),
    NewPetList = lists:keysort(2, PetPowerList),
    case NewPetList of
        [] ->
            0;
        NewPetList ->
            {Id,_Power,_PetLev} = lists:last(NewPetList),
            Id
    end.
