%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 24. 七月 2015 下午6:03
%%%-------------------------------------------------------------------
-author("clark").


-record(equip_qiang_hua_new_cfg,
{
    id = 0,                         %% 强化id （装备类型*1000 + 强化等级）
    cost = 0,                       %% 花费id
    attr = 0,                        %% 强化等级对应的属性
    extra_attr = 0,                   %% 强化等级对应额外奖励属性
    failed_down = [{1, 100}]          %% 降级配置及概率
}).

%% id是根据角色、装备的部位、抢花等级计算出来
-record(equip_part_qiang_hua_cfg,
{
    id,
    part,
    role_id,
    qh_level,
    attr,
    extra_attr,                  %% 强化等级对应额外奖励属性
    failed_down = [{1, 100}],    %% 降级配置及概率
    cost,
    improve_effect               %% 强化等级对应的特效
}).

-record(equip_ji_cheng_new_cfg,
{
    id = 0,                         %% 装备类型*1000+装备等级
    cost = 0,                        %% 花费id
    odds = []
}).

-record(equip_he_cheng_new_cfg,
{
    id = 0,                        %% 装备类型*1000+装备等级
    cost = 0                        %% 花费id
}).

%% 鉴定消耗配置表
-record(equip_jianding_new_cfg,
{
    id = 0,                         %% 品质
    cost = 0                        %% 鉴定消耗
}).

%% 套装属性表
-record(equip_suit_combine_new_cfg,
{
    id = 0,                         %% 套装
    attr = []                       %% 套装属性[{{Lev, Count}, Attr}]
}).

%% 鉴定装备时确定的属性
-record(equip_output_new_cfg,
{
    id = 0                  %% 装备bid
    , is_jd = 1                %% 是否需要鉴定
    , suit_per = []          %% 是否套装的概率 [{SuitId, Per}]
    , gem_slot_num = []       %% 可镶嵌槽数 [{Num, Per}]

    , base_attr = []         %% 基础属性 [{AttrCode, AttrVal}]
    , jd_attr_min_num = 0   %% 鉴定属性最小值
    , jd_attr_max_num = 0   %% 鉴定属性最大值
    , jd_attr = []           %% 基础属性 [{AttrCode, Per, Min, Max}]
    , buf_attr_num = []
    , buf_attr = []
    , enhancements = []     %% 装备的附魔属性列表，根据配置权值获取附魔id
}).

%% 装备
-record(equip_rand_attr_ret,
{
    suit_id = 0,
    gem_slots_tuple = {},
    is_jd = 0,
    jd_attr = {},
    base_attr = 0,
    quality = 0
}).


%% 装备改造
-record(equip_change_cfg,
{
    id,                     %% id
    gem_slot_num,           %% 宝石槽[{Num, Per}]Per是百分比
    jd_attr_num,             %% 鉴定属性条数
    buf_attr_num
}).

%% 装备改造
-record(equip_org_cfg,
{
    bid
    ,type
    ,lev
    ,quality
    ,overlap
    ,job
    ,use_type
    ,use_effect
    ,cant_hecheng
    ,cant_qhjch
    ,cant_sell
    ,is_bind
    ,resolve                        %% 是否可以提炼
    ,val
    ,client_icon
    ,client_mode_icon
    ,client_asset_type
    ,client_soldier_avatar_modifiers
    ,client_magican_avatar_modifiers
    ,client_paladin_avatar_modifiers
    ,client_avatar_priority
    ,improve_effect
    ,gem_effect
    ,client_pet_skill_id
    ,client_pet_id
    ,client_desc
}).

%% 装备提炼（把装备兑换成其他的物品）
-record(epurate_cfg,
{
    id,                             %% 此id为装备的最低使用等级
    num,                            %% 兑换物品的数量区间
    quality = [],                   %% 根据装备的品质来随机选择生成物品
    enhance_level = [],             %% 根据装备的强化等级来随机生成物品
    cost                            %% 装备提炼的消耗id
}).

%% 装备附魔萃取
-record(equip_enhancement_cfg,
{
    id,                             %% 附魔公式id
    enhancements_item,              %% 附魔卷轴id
    quality,                        %% 品质
    buff,                           %% 属性
    part = [],                      %% 可附魔部位的装备列表
    enhancements_cost,              %% 附魔消耗id(从cost.txt表中查找)
    leach_cost,                     %% 萃取消耗（同上）
    enchant_stones                  %% 附魔石id
}).

%% 装备附魔的三种配置类型
-define(equip_fumo_cfg_type_min_max, 1).   %% 配置方式{配置类型,{附加属性id,{附加属性的最小值,附加属性的最大值}}}
-define(equip_fumo_cfg_type_per_mill, 2).  %% 配置方式{配置类型,{附加属性id,{千分比的最小值,千分比的最大值}}}
-define(equip_fumo_cfg_type_buff, 3).      %% 配置方式{配置类型,配置的buffID}
%% 注：装备的附魔属性按照上面三种类型进行保存，在装备信息同步的时候发送到客户端
%% 保存类型例如:
%% 附魔属性列表[{type:1,AttrId:属性id,AttrVal:属性值},{type:2, AttrId:属性id,AttrVal:属性千分比},{type:3,AttrId:0,AttrVal:buffId}]
%%

-define(equip_suit_quality, 5).     %% 套装品质

-define(cfg_attr_key_dt, 8).
