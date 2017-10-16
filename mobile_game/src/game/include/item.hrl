%% 物品结构
-record(item, {
    %%----------------------------------------------------
    %% 公共部分
    id = 0            %% 物品id
    , ver = 0            %% 物品版本号（用于升级
    , bid = 0            %% 物品bid
    , type = 0           %% 物品类型（冗余，后端用
    , pos = 0            %% 物品在包裹中的位置
    , quality = 0        %% 物品品质(装备的品质是按照属性条数确认的
    , quantity = 1       %% 数量
    , bind = 1           %% 是否绑定 0否 1是
    , ex = []
    %%----------------------------------------------------
    %% 装备部分
    , cli_is_jd = 0      %% 是否已鉴定
    , suit_id = 0        %% 套装id （0为非套装
    , qianghua_lev = 0   %% 强化等级
    , base_attr = []     %% 基本属性 Attr = [{AttrCode, AttrVal}] AttrCode属性代号:详情常见game.hrl中属性部分,AttrVal属性值 fomat: [{1,{attr,0,0,0 ...}}]
    , extra_attr = []    %% 附加属性[{ModeCode, Attr}, {ModeCode, Attr, AttrPer}] ModeCode:各个模块的代号详见equip.hrl Attr常见base_attr对应说明 fomat: [{1,{attr,0,0,0 ...}}]
    %% 只有EQM_ATTR_JD鉴定属性的附加属性为三项，其他的ModeCode为两项
    , gem_slot = {}      %% 宝石数据（宝石孔的数量是随机的 fomat: {0,0,0})
    , power = 0          %% 装备评分
}
).
%%----------------------------------------------------
%% 物品额外属性的key
-define(item_ex_pet_attr, item_ex_pet_attr).        %% 封印宠物蛋
-define(item_ex_buried_map, item_ex_buried_map).    %% 藏宝图


-define(item_ex_pet_attr_key_petid, 1).
-define(item_ex_buried_map_key, 2).

%%----------------------------------------------------
%% 物品使用类型
-define(ITEM_USE_TYPE_CANT, 0).   %% 不能使用
-define(ITEM_USE_TYPE_CAN, 1).   %% 可以使用
-define(ITEM_USE_TYPE_ALL, [
    ?ITEM_USE_TYPE_CANT
    , ?ITEM_USE_TYPE_CAN
]
).



%%----------------------------------------------------
%% 物品品质
-define(ITEM_QLY_WHI, 1).   %% 白
-define(ITEM_QLY_BLUE, 2).   %% 蓝
-define(ITEM_QLY_PUR, 3).   %% 紫
-define(ITEM_QLY_ORG, 4).   %% 橙
-define(ITEM_QLY_GRE, 5).   %% 绿（套装

%% 所有物品品质
-define(ITEM_QLY_ALL, [
    ?ITEM_QLY_WHI
    , ?ITEM_QLY_BLUE
    , ?ITEM_QLY_PUR
    , ?ITEM_QLY_ORG
    , ?ITEM_QLY_GRE
]
).

%%----------------------------------------------------
%% 物品类型
%% 目前装备类型定义为int16故范围在0-65535之前，装备部分占用1000以上部分

-define(ITEM_TYPE_ASSETS, 0).  %% 资产类物品
-define(ITEM_TYPE_GEM, 1).  %% 宝石类物品
-define(ITEM_TYPE_USE, 2).  %% 消耗类物品
-define(ITEM_TYPE_GIFT, 3).  %% 直接可以使用的物品类型（礼包、烟花）
-define(ITEM_TYPE_CROWN_GEM, 4).  %% 皇冠宝石碎片（禁止产出，消耗）
-define(ITEM_TYPE_PETSKILL, 5).  %宠物技能书
-define(ITEM_TYPE_PET_EGG, 6).  %% 宠物蛋
-define(ITEM_TYPE_CARD, 7).  %% 卡牌类
-define(ITEM_TYPE_FRIEND_GIFT, 8).  %% 好友礼包消耗
-define(ITEM_TYPE_RAND_INS, 9).  %% 开启随机副本类物品
-define(ITEM_TYPE_FOLLOW, 10). %% 赠送的玫瑰花
-define(ITEM_TYPE_TREASURE_MAP, 11).
-define(ITEM_TYPE_BUFF, 12).    %% Buff物品
%% 装备部分的类型
%% TODO: 有待继续添加
%%----------------------------------------------------
%% 装备类型
-define(ITEM_TYPE_HELMET, 101). % 头盔
-define(ITEM_TYPE_CLOTHES, 102). % 衣服
-define(ITEM_TYPE_SASH, 103). % 腰带
-define(ITEM_TYPE_PANTS, 104). % 裤子
-define(ITEM_TYPE_SHOES, 105). % 鞋子
-define(ITEM_TYPE_FASHION, 106). % 时装
-define(ITEM_TYPE_RING, 107). % 戒指
-define(ITEM_TYPE_BADGE, 108). % 徽章
-define(ITEM_TYPE_HORCRUX, 109). % 魂器
-define(ITEM_TYPE_WEAPON, 110). % 武器




%% 所有的装备类型（装备类型在此添加
-define(ITEM_TYPE_EQM_ALL,
    [
        ?ITEM_TYPE_HELMET
        , ?ITEM_TYPE_CLOTHES
        , ?ITEM_TYPE_SASH
        , ?ITEM_TYPE_PANTS
        , ?ITEM_TYPE_SHOES
        , ?ITEM_TYPE_RING
        , ?ITEM_TYPE_BADGE
        , ?ITEM_TYPE_FASHION
        , ?ITEM_TYPE_HORCRUX
        , ?ITEM_TYPE_WEAPON
    ]
).
%% 所有物品类型（非装备类型在此添加
-define(ITEM_TYPE_ALL,
    [
        ?ITEM_TYPE_ASSETS
        , ?ITEM_TYPE_GEM
        , ?ITEM_TYPE_USE
        , ?ITEM_TYPE_GIFT
        , ?ITEM_TYPE_PETSKILL
        , ?ITEM_TYPE_CROWN_GEM
        , ?ITEM_TYPE_PET_EGG
        , ?ITEM_TYPE_CARD
        , ?ITEM_TYPE_FRIEND_GIFT
        , ?ITEM_TYPE_RAND_INS
        , ?ITEM_TYPE_FOLLOW
        , ?ITEM_TYPE_TREASURE_MAP
    ] ++ ?ITEM_TYPE_EQM_ALL
).






