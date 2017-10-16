-record(equip_qiang_hua_cfg, {id = 0,                %% 强化id （装备类型*1000 + 强化等级）
    cost = 0,              %% 花费id
    attr = 0,               %% 强化等级对应的属性
    extra_attr = 0,         %% 强化等级对应额外奖励属性
    failed_down = [{1, 100}] %% 降级配置及概率
}).

-record(equip_ji_cheng_cfg, {id = 0    %% 装备类型*1000+装备等级
    , cost = 0 %% 花费id
}).

-record(equip_he_cheng_cfg, {id = 0    %% 装备类型*1000+装备等级
    , cost = 0  %% 花费id
}).
%% 鉴定消耗配置表
-record(equip_jianding_cfg, {id = 0    %% 品质
    , cost = 0 %% 鉴定消耗
}).

%% 套装属性表 
-record(equip_suit_combine_cfg, {id = 0,   %% 套装 
    attr = []  %% 套装属性[{{Lev, Count}, Attr}]
}).



%% 鉴定装备时确定的属性
-record(equip_output_cfg, {
    id = 0            %% 装备bid
    , is_jd = 1          %% 是否需要鉴定
    , suit_per = []    %% 是否套装的概率 [{SuitId, Per}]
    , gem_slot_num = [] %% 可镶嵌槽数 [{Num, Per}]

    , base_attr = []         %% 基础属性 [{AttrCode, AttrVal}]
    , jd_attr_min_num = 0   %% 鉴定属性最小值
    , jd_attr_max_num = 0   %% 鉴定属性最大值
    , jd_attr = []           %% 基础属性 [{AttrCode, Per, Min, Max}]

}).
