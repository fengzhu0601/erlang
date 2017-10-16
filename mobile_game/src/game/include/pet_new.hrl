%%@doc 玩家宠物表
-define(player_pets_tab, player_pets_tab).
-record(player_pets_tab, {
    id,
    pet_list = [],%%拥有的所有宠物#pet{}
    shangzhen_list = {0, [{1,0},{2,0},{3,0},{4,0}]}, %%1敏捷，2力量，3智力，4体质
    shangzhen_attr_list = [],
    fight_pet = 0%%出战的宠物#pet.id
}).


-record(pet_new, {
    id = 0,
    pet_id,
    status = 0,
    cur_exp = 0,
    save_exp = 0,
    pet_race,
    pet_level,
    pet_advance=0,
    attr_new,
    attr_old=0,
    initiative_skill=[],
    advance_data = [],
    fengyin_data=[],
    passivity_skill = []
}).


-define(pd_pet_list, pd_pet_list).
-define(pd_pet_fight, pd_pet_fight).
-define(pd_pet_shangzhen_list, pd_pet_shangzhen_list).
-define(pd_pet_shangzhen_attr_list, pd_pet_shangzhen_attr_list).

-define(PET_NEW_STATUS_INIT, 0).%%未初始化
-define(PET_NEW_STATUS_ALIVE, 3).%%休息中
-define(PET_NEW_STATUS_SHANGZHEN, 2).%% shangzhen
-define(PET_NEW_STATUS_FIGHT, 1).%%战斗中
-define(PET_NEW_STATUS_SEAL, 4).%%封印中

-define(ABS_TYPE, 1).
-define(BAIFENBI_TYPE, 2).