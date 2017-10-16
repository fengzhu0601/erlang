-include_lib("common/include/com_define.hrl").

%%----------------------------------------------------

-define(EQM_MAX_PUT, 10).  %% 穿着装备的最大数

-define(EQM_NON_SUIT, 0).  %% 无套装id

-define(EQM_NIL_GEM_SLOT, 0). %% 装备的空宝石槽

-define(EQM_POWER2VAL(Power), max(1, Power)). %% 通过装备站立获取已鉴定装备的价格
%%----------------------------------------------------
%% 装备附加属性类型
%% 无法从配置文件中获取，需要推送客户端部分
-define(EQM_ATTR_JD, 1).  %% 鉴定属性
-define(EQM_ATTR_FM, 2).  %% 鉴定属性
%% 可以从配置文件中获取，不需要推送客户端部分
-define(EQM_ATTR_QH, 101).  %% 强化基本属性
-define(EQM_ATTR_QH_EXT, 102).  %% 强化附加奖励属性
-define(EQM_ATTR_GEM, 103).  %% 宝石属性


%% 动态装备附加属性类型(无法送配置文件中获取，需要推送客户端部分
-define(EQM_ATTR_VARYS, [
    ?EQM_ATTR_JD
]
).

-define(suit_num(Num),
    if
        Num >= ?SUIT_MAX_NUM -> ?SUIT_MAX_NUM;
        Num >= 4 -> 4;
        Num >= 2 -> 2;
        true -> 0
    end
). %% 获取套装有效件数

-define(SUIT_MAX_NUM, 6).

%% 数据库保存的装备列表
-define(player_equip_goods_tab, player_equip_goods_tab).
-record(player_equip_goods_tab,
{
    id,
    equip_bucket,       %% 玩家已经装备的装备
    goods_bucket,       %% 玩家背包里面的物品
    depot_bucket,       %% 玩家仓库里面的物品
    qianghu_list        %% 装备部位的强化列表
}).