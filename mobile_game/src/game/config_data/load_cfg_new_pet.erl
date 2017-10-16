-module(load_cfg_new_pet).

%% API
-export([
    get_passivity_skill/1,
    get_passivity_skill2/1,
    get_pet_talent_skill/1,
    get_attr_id_by_pet_level/1,
    get_pet_level/1,
    get_pet_initativeskill_level/1,
    get_pet_initativeskill_damage/1,
    get_pet_exp_by_level/1,
    is_can_advance/1,
    get_advance_data/1,
    get_open_skil_set/1,
    get_advance_cost_and_attrid/1,
    get_initiative_skill/1,
    get_pet_new_exp_by_id/1,
    get_skill_cost/1,
    get_pet_new_attr_id_and_ratio_by_setid/1,
    get_pet_new_attr_add_by_passivity_id/1,
    get_pet_new_attr_id_and_ratio_and_value_type_by_passivity_id/1,
    get_pet_new_overlap_by_pasivity_id/1,
    get_pet_new_attr_by_initativeskill_id/1,
    get_advance_attrid/1,
    get_all_skill_upgrade_cost_id/1,
    get_pet_new_offset_by_id/1,
    get_pet_halo_buff/1,
    get_pet_skill_modify/1
]).

-include_lib("config/include/config.hrl").
-include("inc.hrl").
-include("load_cfg_new_pet.hrl").
-include("load_item.hrl").


get_all_skill_upgrade_cost_id(SkillLevelId) ->
    do_get_all_skill_upgrade_cost_id(SkillLevelId, []).
do_get_all_skill_upgrade_cost_id(SkillLevelId, CostIdList) ->
    case lookup_pet_skill_level_new_cfg(SkillLevelId) of
        ?none ->
            CostIdList;
        #pet_skill_level_new_cfg{skill_level=1} ->
            CostIdList;
        #pet_skill_level_new_cfg{skill_cost=CostId} ->
            do_get_all_skill_upgrade_cost_id(SkillLevelId-1, [CostId|CostIdList])
    end.

get_passivity_skill(PetId) ->
    case lookup_pet_new_cfg(PetId) of
        #pet_new_cfg{passivity_skill_pool=Pool} when length(Pool) > 0 ->
            SkillList = util:get_val_by_weight(Pool, 1),
            {1,lists:nth(1, SkillList)};
        _ ->
            {1, 0}
    end.

get_passivity_skill2(PetId) ->
    case lookup_pet_new_cfg(PetId) of
        #pet_new_cfg{passivity_skill_pool=Pool} when length(Pool) > 0->
            %?DEBUG_LOG("PetId---:~p----Poll--:~p",[PetId, Pool]),
            SkillList = util:get_val_by_weight(Pool, 1),
            lists:nth(1, SkillList);
        _ ->
            ?none
    end.

get_pet_talent_skill(PetId) ->
    case lookup_pet_new_cfg(PetId) of
        #pet_new_cfg{talent_skill = TalentSkill} when is_integer(TalentSkill) ->
            TalentSkill;
        _ ->
            ?none
    end.

get_initiative_skill(PetId) ->
    #pet_new_cfg{initiative_skill=SkillId} = lookup_pet_new_cfg(PetId),
    SkillId.
       
get_pet_new_exp_by_id(PetId) ->
    case lookup_pet_new_cfg(PetId) of
        ?none ->
            0;
        #pet_new_cfg{pet_exp=Exp} ->
            Exp
    end.

get_pet_new_offset_by_id(PetId) ->
    case lookup_pet_new_cfg(PetId) of
        ?none ->
            {0,0,0};
        #pet_new_cfg{offset=Offset} ->
            Offset
    end.

get_attr_id_by_pet_level(PetId) ->
    case lookup_pet_upgrade_new_cfg(PetId) of
        ?none ->
            0;
        #pet_upgrade_new_cfg{level_attr_id=AttrId} ->
            AttrId
    end.

get_pet_level(PetLevelId) ->
    case lookup_pet_upgrade_new_cfg(PetLevelId) of
        ?none ->
            0;
        #pet_upgrade_new_cfg{level=Level} ->
            Level
    end.

get_pet_initativeskill_level(InitativeSkillLevel) ->
    case lookup_pet_skill_level_new_cfg(InitativeSkillLevel) of
        ?none ->
            0;
        #pet_skill_level_new_cfg{skill_level=Level} ->
            Level
    end.

get_pet_initativeskill_damage(InitativeSkillLevel) ->
    case lookup_pet_skill_level_new_cfg(InitativeSkillLevel) of
        ?none ->
            0;
        #pet_skill_level_new_cfg{damage=Damage} ->
            Damage
    end.

get_pet_exp_by_level(100) ->
    ?none;
get_pet_exp_by_level(Level) ->
    case lookup_pet_exp_new_cfg(Level) of
        ?none ->
            ?none;
        #pet_exp_new_cfg{exp=Exp} ->
            Exp
    end.

get_advance_data(PetLevelId) ->
    case lookup_pet_upgrade_new_cfg(PetLevelId) of
        #pet_upgrade_new_cfg{advance=Advance} when Advance > 0 andalso is_integer(Advance)->
            {Advance, PetLevelId};
        _ ->
            ?none
    end.

get_open_skil_set(PetLevelId) ->
    case lookup_pet_upgrade_new_cfg(PetLevelId) of
        #pet_upgrade_new_cfg{skill_set=Set} when Set > 0 andalso is_integer(Set)->
            Set;
        _ ->
            ?none
    end.

get_advance_cost_and_attrid(PetLevelId) ->
    case lookup_pet_upgrade_new_cfg(PetLevelId) of
        ?none ->
            ?false;
        #pet_upgrade_new_cfg{advance_cost=Cost,advance_attr_id=AttrId} ->
            {Cost, AttrId}
    end.

get_advance_attrid(PetLevelId) ->
    case lookup_pet_upgrade_new_cfg(PetLevelId) of
        ?none ->
            0;
        #pet_upgrade_new_cfg{advance_attr_id=AttrId} ->
            AttrId
    end.

get_skill_cost(SkillLevelId) ->
    case lookup_pet_skill_level_new_cfg(SkillLevelId) of
        ?none ->
            1;
        #pet_skill_level_new_cfg{skill_cost=Cost} ->
            Cost
    end.

get_pet_new_attr_id_and_ratio_by_setid(SetId) ->
    case lookup_pet_set_new_cfg(SetId) of
        ?none ->
            ?none;
        #pet_set_new_cfg{attr_id=AttrId, ratio=Ratio} ->
            {AttrId, Ratio}
    end.

get_pet_new_attr_add_by_passivity_id(SkillId) ->
    case lookup_pet_skill_new_cfg(SkillId) of
        #pet_skill_new_cfg{attr_add=A} when is_integer(A) ->
            A;
        _ ->
            ?none
    end.

get_pet_new_attr_by_initativeskill_id(SkillId) ->
    case lookup_pet_skill_new_cfg(SkillId) of
        #pet_skill_new_cfg{attr=A} when is_tuple(A) ->
            A;
        _ ->
            ?none
    end.

get_pet_new_attr_id_and_ratio_and_value_type_by_passivity_id(PassivitySkillId) ->
    case lookup_pet_skill_new_cfg(PassivitySkillId) of
        #pet_skill_new_cfg{value_type=Type, attr_passive=A} when is_tuple(A) ->
            {Type, A};
        _ ->
            ?none
    end.


get_pet_new_overlap_by_pasivity_id(PassivitySkillId) ->
    case lookup_pet_skill_new_cfg(PassivitySkillId) of
        #pet_skill_new_cfg{overlap=Overlap} when is_integer(Overlap) ->
            Overlap;
        _ ->
            ?none
    end.

get_pet_halo_buff(SkillId) ->
    case lookup_pet_skill_new_cfg(SkillId) of
        #pet_skill_new_cfg{buff = Buff} when is_integer(Buff) ->
            Buff;
        _ ->
            ?none
    end.

get_pet_skill_modify(PetId) ->
    case get_initiative_skill(PetId) of
        SkillId when is_integer(SkillId) ->
            case lookup_pet_skill_new_cfg(SkillId) of
                #pet_skill_new_cfg{skill_modify = SkillModify} -> SkillModify;
                _ -> []
            end;
        _ ->
            []
    end.

is_can_advance(PetLevelId) ->
    case lookup_pet_upgrade_new_cfg(PetLevelId) of
        ?none ->
            ?false;
        #pet_upgrade_new_cfg{level=Level} ->
            case Level rem 10 of
                0 ->
                    ?true;
                _ ->
                    ?false
            end
    end.


load_config_meta() ->
    [
    #config_meta{record = #pet_new_cfg{},
        fields = ?record_fields(pet_new_cfg),
        file = "pet_new.txt",
        keypos = #pet_new_cfg.id,
        verify = fun verify_pet_new_cfg/1
    },
    #config_meta{record = #pet_upgrade_new_cfg{},
        fields = ?record_fields(pet_upgrade_new_cfg),
        file = "pet_upgrade_new.txt",
        keypos = #pet_upgrade_new_cfg.id,
        verify = fun verify_pet_upgrade_new_cfg/1
    },
    #config_meta{record = #pet_exp_new_cfg{},
        fields = ?record_fields(pet_exp_new_cfg),
        file = "pet_exp_new.txt",
        keypos = #pet_exp_new_cfg.level,
        verify = fun verify_pet_exp_new_cfg/1
    },
    #config_meta{record = #pet_skill_level_new_cfg{},
        fields = ?record_fields(pet_skill_level_new_cfg),
        file = "pet_skill_level_new.txt",
        keypos = #pet_skill_level_new_cfg.id,
        verify = fun verify_pet_skill_level_new/1
    },
    #config_meta{record = #pet_skill_new_cfg{},
        fields = ?record_fields(pet_skill_new_cfg),
        file = "pet_skill_new.txt",
        keypos = #pet_skill_new_cfg.id,
        verify = fun verify_pet_skill_new_cfg/1
    },
    #config_meta{record = #pet_set_new_cfg{},
        fields = ?record_fields(pet_set_new_cfg),
        file = "pet_set_new.txt", 
        keypos = #pet_set_new_cfg.set_id,
        verify = fun verify_pet_set_new_cfg/1
    },
    #config_meta{record = #pet_race_skill_cfg{},
        fields = ?record_fields(pet_race_skill_cfg),
        file = "pet_race_skill.txt",
        keypos = #pet_race_skill_cfg.id,
        verify = fun verify_pet_race_skill_cfg/1
    }
    ].

verify_pet_new_cfg(#pet_new_cfg{id=Id,race=Race, initiative_skill=SkillId1, talent_skill=SkillId2,passivity_skill_pool=SkillPool,offset=Offset}) ->
    ?check(Race >= 1 andalso Race =< 4, "pet_new.txt中，id: [~p] race: [~p] 配置无效。", [Id, Race]),
    ?check(is_exist_pet_skill_new_cfg(SkillId1) orelse SkillId1 =:= undefined, "pet_new.txt中， id:  [~p] initiative_skill: [~p] 配置无效 ",[Id, SkillId1]),
    ?check(is_exist_pet_skill_new_cfg(SkillId2) orelse SkillId2 =:= undefined, "pet_new.txt中， id:  [~p] talent_skill: [~p] 配置无效 ",[Id, SkillId2]),
    lists:foreach(fun({SkillId3,_Per}) ->
        ?check(is_exist_pet_skill_new_cfg(SkillId3) orelse SkillId3 =:= 0, "pet_new.txt中， id:  [~p] passivity_skill_pool: [~p] 配置无效 ",[Id, SkillId3])
    end, 
    SkillPool),
    ?check(is_tuple(Offset), "pet_new.txt中，id: [~p] offset: [~p] 配置无效。", [Id, Offset]),
    ok.

verify_pet_upgrade_new_cfg(#pet_upgrade_new_cfg{id=Id, level_attr_id=AttrId, advance_cost=CostId, advance_attr_id=AttrId2}) ->
    ?check(load_spirit_attr:is_exist_attr(AttrId) orelse AttrId =:= undefined, "pet_upgrade_new.txt中， id:  [~p] level_attr_id: [~p] 配置无效 ",[Id, AttrId]),
    ?check(cost:is_exist_cost_cfg(CostId) orelse CostId =:= undefined, "pet_upgrade_new.txt中， id:  [~p] advance_cost: [~p] 配置无效 ",[Id, CostId]),
    ?check(load_spirit_attr:is_exist_attr(AttrId2) orelse AttrId2 =:= undefined, "pet_upgrade_new.txt中， id:  [~p] advance_attr_id: [~p] 配置无效 ",[Id, AttrId2]),
    ok.


verify_pet_skill_level_new(#pet_skill_level_new_cfg{id=Id, skill_cost=CostId}) ->
    ?check(cost:is_exist_cost_cfg(CostId) orelse CostId =:= undefined, "pet_skill_level_new.txt中， id:  [~p] skill_cost: [~p] 配置无效 ",[Id, CostId]),
    ok.

verify_pet_skill_new_cfg(#pet_skill_new_cfg{}) ->
    ok.
verify_pet_exp_new_cfg(_QualityCfg) ->
    ok.

verify_pet_set_new_cfg(_) ->
    ok.
verify_pet_race_skill_cfg(_) ->
    ok.