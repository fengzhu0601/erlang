%%宠物配置表
-record(pet_new_cfg,
{
    id,
    race,
    initiative_skill,
    talent_skill,
    passivity_skill_pool=[],
    pet_exp,
    offset
}).

-record(pet_upgrade_new_cfg,
{
    id,
    level,
    level_attr_id,
    advance_cost,
    advance,
    skill_set,
    advance_attr_id
}).

-record(pet_exp_new_cfg,
{
    level,
    exp
}).

-record(pet_skill_new_cfg,
{
    id,
    skill_type,
    race_limit,
    attr,
    buff,
    skill_id,
    passive_type,
    value_type,
    attr_passive=0,
    attr_add=0,
    crit=0,
    crit_damege=0,
    cd_passive=0,
    coin=0,
    double_item=0,
    overlap,
    skill_modify = []
}).

-record(pet_skill_level_new_cfg,{
    id, 
    skill_level,
    skill_cost,
    damage
}).

-record(pet_set_new_cfg, {
    set_id,
    attr_id,
    ratio
}).

-record(pet_race_skill_cfg, {
    id,
    race_id,
    quality,
    race_skill,
    ratio
}).