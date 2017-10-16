%%%-------------------------------------------------------------------
%%% @author wcg
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 04. 三月 2015 下午6:09
%%%-------------------------------------------------------------------
-author("wcg").
-define(ADVANCE_LEVEL, 10).%%每10级送个进阶的升级机会!

-define(PET_QUALITY_BLUE, 1).%%蓝
-define(PET_QUALITY_PURPLE, 2).%%紫
-define(PET_QUALITY_ORANGE, 3).%%橙

-define(PET_STATUS_INIT, 0).%%未初始化
-define(PET_STATUS_ALIVE, 1).%%休息中
-define(PET_STATUS_FIGHT, 3).%%战斗中
-define(PET_STATUS_SEAL, 4).%%封印中

-define(PET_ADVANCE_FLAG_TRUE, 1).%%可進階狀態
-define(PET_ADVANCE_FLAG_FALSE, 0).%%不可進階狀態

-define(PET_SKILL_TYPE_INITIATIVE, 1).%%主动技能
-define(PET_SKILL_TYPE_PASSIVITY, 2).%%被动技能
-define(PET_SKILL_TYPE_EXCLUSIVE, 3).%%天赋技能

-define(PET_INITIATIVE_MAX_SLOT, 3).
-define(PET_PASSIVITY_MAX_SLOT, 6).

-define(TREASURE_REWARD_PET_EXP_ID, 25).   %寻宝宠物奖励， 1表示增加经验值
-define(TREASURE_REWARD_PET_TACIT_ID, 42). %寻宝宠物奖励， 2表示默契值奖励

-define(DEFAULT_PERCENT_MIN_AND_MAX, 100). %计算百分比概率时默认最大值100
-define(DEFAULT_PERCENT_PER_MILLE, 1000). %计算千分比概率时默认最大值1000

-define(PET_MAX_TACIT_VALUE, 100). %默契度增加的属性需要除以100

%%宠物配置表
%%-record(pet_cfg, {
%%    id,
%%    name,
%%    quality,
%%    facade = 0,
%%    tacit_value = 0,
%%    exclusive_skill = [],
%%    hatch_cost = 1,
%%    seal_cost = 0,
%%    jd_attr_min_num,
%%    jd_attr_max_num,
%%    jd_attr
%%}).

%%-record(pet_level_cfg, {
%%    id,
%%    level,
%%    need_exp,
%%    attr
%%}).
%%
%%-record(pet_quality_ratio_cfg, {
%%    quality = 0,
%%    max_level,
%%    initialtive_open,
%%    initialtive_max,
%%    passivity_open,
%%    passivity_max
%%}).
%%
%%-record(pet_advance_cfg, {
%%    id = 0,
%%    pet_id = 0,
%%    level = 0,
%%    cost,
%%    mini_slots = 0,
%%    attr_basic_add,
%%    tacit_value_add,
%%    min_num,
%%    max_num,
%%    attr_prize,
%%    facade_prize
%%}).
%%
%%-record(pet_advance_prop_cfg, {
%%    diff_value,
%%    per
%%}).
%%
%%-record(pet_skill_level_cfg, {
%%    id,
%%    next_id,
%%    level,
%%    buff_id,
%%    skill_id,
%%    type,
%%    study_cost,
%%    uplevel_cost,
%%    forget_cost
%%}).
%%
%%-record(pet_treasure_cfg, {
%%    id = 0,
%%    weight = 0,
%%    type = 0,
%%    need_time = 0,
%%    cost = 0,
%%    reward = 0
%%}).
%%
%%-record(pet_skill_pos_open_cfg, {
%%    id = 0,
%%    type = 0,
%%    pos = 0,
%%    cost = 0
%%}).
%%宠物
-record(pet_exclusive_upgade_cfg, {}).

-record(pet_facade_cfg, {id = 0}).

%%技能结构:s1-sn为技能id 为0:开启；-1:未开启；-2:无效；>0所在技能id
-define(PET_SKILL_STATE_OPEN, 0).
-define(PET_SKILL_STATE_NOT_OPEN, -1).
-define(PET_SKILL_STATE_VOID, -2).

-define(GLOBAL_TYPE_SEAL(__WHO), {seal, __WHO}).

-record(pet,
{
    id = 0,
    name = 0,
    cfgid = 0,
    status = 0,
    tacit_value = 0,
    have_advance_count = 0, %目前拥有的进阶次数
    done_advance_count = 0, %目前已经进阶过的次数，该字段值不能大于进阶最大值
    advance_seccuss_count = 0, %进阶获得额外属性次数
    quality = 0,
    facade = 0,
    level = 0,
    exp = 0,
    from = 0,
    attr = 0,
    attr_old,
    exclusive_skill,
    initiative_skill,
    passivity_skill
}).

-define(pet_global_tab, player_pet_egg_tab).
-record(player_pet_egg_tab,
{
    pet_id = 0, %宠物id，目前所有玩家的宠物id都是全局自增长的
    pet_info
}). %宠物信息


-record(pet_treasure,
{
    id = 0,
    treasureid = 0,
    createtime = 0,
    finishtime = 0,
    timer_ref
}).

-record(pet_treasure_log,
{
    name,
    treasureid = 0,
    prize_info = [],
    createtime = 0,
    finishtime = 0
}).

%%@doc 玩家宠物表
-record(player_pets,
{
    id = 0,%%玩家ID int
    %nextid=1,%%孵化下一只宠物的ID
    pets = [],%%拥有的所有宠物#pet{}
    treasure_pets = [],%%活动中的宠物 #pet_treasure{}
    treasure_log_pets = [],%%宠物的活动日志 #pet_treasure_log{}
    fight_pet = 0%%出战的宠物#pet.id
}).
