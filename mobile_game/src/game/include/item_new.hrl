%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 31. 七月 2015 上午4:47
%%%-------------------------------------------------------------------
-author("clark").



-record(item_new,
{
    id = 0
    , bid = 0
    , pos = 0
    , type = 0
    , quantity = 1       %% 数量
    , bind = 0           %% 是否有绑定属性(0:没有 1:装备后绑定)
    , field = []
}).




-define(prop_list,
    [
        10,     %% ?pd_money
        11,     %% ?pd_diamond
        21      %% ?pd_exp
    ]).




%% ---------------------------------------------------------------
%% key -----------------------------------------------------------
%% ---------------------------------------------------------------
%% goods

%% -------------------
%% equip
-define(item_equip_quality, 2001).              %% 装备的品质
-define(item_equip_is_jd, 2002).                %% 是否已鉴定
-define(item_equip_suit_id, 2003).              %% 套装id (0为非套装)
-define(item_equip_qianghua_lev, 2004).         %% 强化等级
-define(item_equip_power, 2005).                %% 装备评分
-define(item_equip_igem_slot, 2006).            %% 宝石数据
-define(item_equip_base_prop, 2007).            %% 基本属性
-define(item_equip_extra_prop_list, 2008).      %% 附加属性[{AttrId, AttrVal, Per, Min, Max}]
-define(item_equip_take_state, 2009).           %% 是否穿着
-define(item_equip_attr_state, 2010).           %% 装备的数值状态 0 未计算过的数值 1计算过的数值
-define(item_equip_qh_prop_id, 2011).           %% 强化基本属性
-define(item_equip_extra_qh_prop_id, 2012).     %% 强化附加属性
-define(item_equip_buf_list, 2013).             %% buf附加属性( <-> skill_modif )
-define(item_equip_fumo_mode_message, 2014).    %% 装备的附魔公式(0为未附魔)
-define(item_equip_fumo_attr_list, 2015).       %% 装备的附魔属性列表

%%装备的扩展属性列表，Id设置小于100
-define(item_equip_epic_gem_slot, 16).        %% 史诗宝石孔是否打孔
-define(item_equip_epic_gem, 17).             %% 史诗宝石镶嵌Id
-define(item_equip_epic_gem_exp, 18).         %% 史诗宝石经验

%% 史诗宝石
-define(item_epic_gem_exp, 1).                  %% 史诗宝石的经验



%% -define(EQM_ATTR_QH,       101).             %% 强化基本属性
%% -define(EQM_ATTR_QH_EXT,   102).             %% 强化附加奖励属性
%% -------------------
%% UseSign
-define(item_use_data, 3001).                   %% 使用数据




%% ---------------------------------------------------------------
%% val -----------------------------------------------------------
%% ---------------------------------------------------------------
%% type
-define(val_item_main_type_goods, 10).        %% 物品类型
-define(val_item_main_type_equip, 11).        %% 装备类型


%% 物品类型
-define(val_item_type_assets, 0).         %% 资产类
-define(val_item_type_gem, 1).         %% 宝石
-define(val_item_type_use, 2).         %% 特殊物品
-define(val_item_type_gift, 3).         %% 礼包
-define(val_item_type_crown_debris, 4).         %% 皇冠碎片
-define(val_item_type_pet_skill, 5).         %% 宠物技能书
-define(val_item_type_pet_egg, 6).         %% 宠物蛋
-define(val_item_type_card, 7).         %% 卡牌
-define(val_item_type_friend_gift, 8).         %% 好友礼包提升
-define(val_item_type_rand_ins, 9).         %% 时间碎片
-define(val_item_type_flower, 10).        %% 鲜花
-define(val_item_type_treasure_map, 11).        %% 藏宝图
-define(val_item_type_room_buf, 12).        %% 藏宝图
-define(val_item_main_type_slot, 13).         %% 打孔器
-define(val_item_type_fumo_scroll_debris, 14).   %% 附魔卷轴碎片
-define(val_item_type_fumo_scroll,  15).    %% 附魔公式卷轴
-define(val_item_type_fumo_stone, 16).    %% 附魔石道具
-define(val_item_type_suit_chip, 17).       %% 套装碎片(套裝碎片)




%% 装备类型 (装备类型必须大于100,因为物品类型小于100)
-define(val_item_type_helmet, 101).       % 头盔
-define(val_item_type_clothes, 102).       % 衣服
-define(val_item_type_sash, 103).       % 腰带
-define(val_item_type_pants, 104).       % 裤子
-define(val_item_type_shoes, 105).       % 鞋子
-define(val_item_type_fashion, 106).       % 时装
-define(val_item_type_ring, 107).       % 戒指
-define(val_item_type_badge, 108).       % 徽章
-define(val_item_type_horcrux, 109).       % 魂器
-define(val_item_type_weapon, 110).       % 武器

%% 所有的装备类型
-define(all_equips_type, [
    ?val_item_type_helmet,
    ?val_item_type_clothes,
    ?val_item_type_sash,
    ?val_item_type_pants,
    ?val_item_type_shoes,
    ?val_item_type_fashion,
    ?val_item_type_ring,
    ?val_item_type_badge,
    ?val_item_type_horcrux,
    ?val_item_type_weapon
]).

%% 装备品质
-define(equip_blue, 2).             %% 蓝装备
-define(equip_purple, 3).            %% 紫装备
-define(equip_orange, 4).           %% 橙装备
-define(equip_green, 5).            %% 绿装备

-define(suit_quality, 5).           %% 套装品质

-define(max_gem_slot_count, 5).          %% 装备可打的最大宝石孔数量
-define(slot_cost_rate_id, 2036).        %% 装备打孔中消耗的转换id
-define(epic_slot_cost_rate_id, 2039).   %% 装备史诗打孔中消耗的转换id

-define(EQUIP_FUMO_STATE_INIT,  0).            %% 装备附魔公式的初始化状态
-define(EQUIP_FUMO_STATE_USE, 1).               %% 激活状态下的附魔公式

%% -----------------------------
-define(MONEY_BID, 10).
-define(DIAMOND_BID, 11).
-define(FRAGMENT_BID, 12).
-define(JINXING, 13).
-define(YINXING, 14).
-define(GUILD_CONTRIBUTION, 16).
-define(LEVEL_BID, 20).
-define(EXP_BID, 21).
-define(HP_BID, 22).
-define(LONGWENS_BID, 23).
-define(HONOUR_BID, 24).
-define(PEARL_BID, 25).
-define(LONG_WEN_BID, 26).
-define(YUANSU_MOLI, 27).
-define(GUANGAN_MOLI, 28).
-define(MINGYUN_MOLI, 29).
-define(COMBAT_POWER_BID, 30).
-define(MP_BID, 31).
-define(PET_TACIT_BID, 41).
-define(SP_BID, 104).
-define(SP_COUNT_BID, 105).



%%皇冠碎片(皇冠改版后暂时没有添加碎片的功能)
-define(CROWM_DEBRIS_LVL1_BID, 4301).
-define(CROWM_DEBRIS_LVL2_BID, 4302).
-define(CROWM_DEBRIS_LVL3_BID, 4303).
-define(CROWM_DEBRIS_LVL4_BID, 4304).
-define(CROWM_DEBRIS_LVL5_BID, 4305).
-define(CROWM_DEBRIS_LVL6_BID, 4306).
-define(CROWM_DEBRIS_LVL7_BID, 4307).
-define(CROWM_DEBRIS_LVL8_BID, 4308).
-define(CROWM_DEBRIS_LVL9_BID, 4309).
-define(CROWM_DEBRIS_LVL10_BID, 4310).


%% 资产类
-define(ASSET,
    [
        {?MONEY_BID,                    ?pd_money},
        {?DIAMOND_BID,                  ?pd_diamond},
        {?FRAGMENT_BID,                 ?pd_fragment},
        {?LEVEL_BID,                    ?pd_level},
        {?EXP_BID,                      ?pd_exp},
        {?HP_BID,                       ?pd_hp},
        {?LONGWENS_BID,                 ?pd_longwens},
        {?HONOUR_BID,                   ?pd_honour},
        {?PEARL_BID,                    ?pd_pearl},
        {?LONG_WEN_BID,                 ?pd_long_wen},
        {?COMBAT_POWER_BID,             ?pd_combat_power},
        {?MP_BID,                       ?pd_mp},
        {?PET_TACIT_BID,                ?PET_TACIT_BID},
        {?SP_BID,                       ?pd_sp},
        {?SP_COUNT_BID,                 ?pd_sp_buy_count},

        {?PL_MONEY,                     ?pd_money},
        {?PL_DIAMOND,                   ?pd_diamond},
        {?PL_FRAGMENT,                  ?pd_fragment},
        {?PL_LEVEL,                     ?pd_level},
        {?PL_EXP,                       ?pd_exp},
        {?PL_HP,                        ?pd_hp},
        {?PL_LONGWENS,                  ?pd_longwens},
        {?PL_HONOUR,                    ?pd_honour},
        {?PL_PEARL,                     ?pd_pearl},
        {?PL_LONG_WEN,                  ?pd_long_wen},
        {?PL_COMBAT_POWER,              ?pd_combat_power},
        {?PL_MP,                        ?pd_mp},
        {?PL_PET_TACIT,                 ?PET_TACIT_BID},
        {?PL_SP,                        ?pd_sp},
        {?PL_SP_COUNT,                  ?pd_sp_buy_count},
        {?JINXING,                      ?pd_main_ins_jinxing},
        {?YINXING,                      ?pd_main_ins_yinxing},
        {?GUILD_CONTRIBUTION,           ?pd_guild_contribution},
        {?YUANSU_MOLI,                  ?pd_crown_yuansu_moli},
        {?GUANGAN_MOLI,                 ?pd_crown_guangan_moli},
        {?MINGYUN_MOLI,                 ?pd_crown_mingyun_moli},

        {?CROWM_DEBRIS_LVL1_BID,        0},
        {?CROWM_DEBRIS_LVL2_BID,        0},
        {?CROWM_DEBRIS_LVL3_BID,        0},
        {?CROWM_DEBRIS_LVL4_BID,        0},
        {?CROWM_DEBRIS_LVL5_BID,        0},
        {?CROWM_DEBRIS_LVL6_BID,        0},
        {?CROWM_DEBRIS_LVL7_BID,        0},
        {?CROWM_DEBRIS_LVL8_BID,        0},
        {?CROWM_DEBRIS_LVL9_BID,        0},
        {?CROWM_DEBRIS_LVL10_BID,       0}
    ]).




