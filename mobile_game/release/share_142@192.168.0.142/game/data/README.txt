配置文件说明

行走方向
-------------------------------------
-define(D_NONE ,0).
-define(D_U  ,1). 
-define(D_RU ,2). 
-define(D_R  ,3).
-define(D_RD ,4).
-define(D_D  ,5).
-define(D_LD ,6).
-define(D_L  ,7).
-define(D_LU ,8).

Map
---------------------
* 所有的地图文件在map 子文件夹下,
* 配置的内容为可行走点,也就是pass层
* 0为可行走,1为不可行走,
* 配置中还要有地图的长度和宽度配置,
* map文件的名字为map的Id

Goods
----------------------
特殊物品 goodsId,不在goods 表里面配置
-define(PL_MONEY, 10).
-define(PL_DIAMOND, 11).
-define(PL_EXP, 12).

%% 物品类型
-define(IT_OTHER, 0). %% 其他
-define(IT_EQUIP, 1). %% 装备
-define(IT_GEM, 2). %% 宝石

%% 职业
-define(JOB_ZS, 1). %%盾战士
-define(JOB_QS, 2). %%法师  
-define(JOB_FS, 3). %%弓箭手  
-define(JOB_SS, 4). %%圣骑士

%% 装备类型
-define(EQUIP_TYPE_WEAPON      , 1). % 武器
-define(EQUIP_TYPE_HELMET      , 2). % 头盔
-define(EQUIP_TYPE_CLOTHES     , 3). % 衣服
-define(EQUIP_TYPE_SASH        , 4). % 腰带
-define(EQUIP_TYPE_PANTS       , 5). % 裤子
-define(EQUIP_TYPE_SHOES       , 6). % 鞋子
-define(EQUIP_TYPE_RING        , 7). % 戒指
-define(EQUIP_TYPE_BADGE       , 8). % 徽章
  

%% sat attr
-define(PL_ATTR_HP          , 11). 最大血量
-define(PL_ATTR_MP          , 12). 最大蓝量
-define(PL_ATTR_SP          , 13). 体力
-define(PL_ATTR_NP          , 14). 能量
-define(PL_ATTR_STRENGTH    , 15). 力量
-define(PL_ATTR_INTELLECT   , 16). 智力
-define(PL_ATTR_NIMBLE      , 17). 敏捷
-define(PL_ATTR_STRONG      , 18). 体质
-define(PL_ATTR_ATK         , 19). 攻击
-define(PL_ATTR_DEF         , 20). 防御
-define(PL_ATTR_CRIT        , 21). 暴击
-define(PL_ATTR_BLOCK       , 22). 格挡
-define(PL_ATTR_PLIABLE     , 23). 柔韧
-define(PL_ATTR_PURE_ATK    , 24). 无视防御伤害
-define(PL_ATTR_BREAK_DEF   , 25). 破甲
-define(PL_ATTR_ATK_DEEP    , 26). 伤害加深
-define(PL_ATTR_ATK_FREE    , 27). 伤害减免
-define(PL_ATTR_ATK_SPEED   , 28). 攻击速度
-define(PL_ATTR_PRECISE     , 29). 精确
-define(PL_ATTR_THUNDER_ATK , 30). 雷公
-define(PL_ATTR_THUNDER_DEF , 31). 雷放
-define(PL_ATTR_FIRE_ATK    , 32). 火攻
-define(PL_ATTR_FIRE_DEF    , 33). 火访
-define(PL_ATTR_ICE_ATK     , 34). 冰攻
-define(PL_ATTR_ICE_DEF     , 35). 冰防
-define(PL_ATTR_MOVE_SPEED  , 36). 移动速度
-define(PL_ATTR_RUN_SPEED  , 37). 跑步速度
-define(PL_ATTR_SUCK_BLOOD  , 38). 吸血
-define(PL_ATTR_REVERSE  , 39). 反伤
38 吸血
39 反伤

%% Task Type
-define(TT_MAIN, 0).       %% 主线任务
-define(TT_BRANCH, 1).     %% 支线
-define(TT_DAILY, 2).      %% 日常


%% 技能主属性 
S_STRENGTH=1, %% 力量
S_INTELLECT=2, %% 智力
S_NIMBLE=3, %% 敏捷
S_STRONG=4, %% 特质


## 场景类型
enum scene_type_id 
{
    SC_TYPE_NORMAL        = 1 : sc_type_normal, ## 永久场景
    SC_TYPE_PSEDUO        = 2 : sc_type_pseduo, ## 副本场景伪场景
    SC_TYPE_MAIN_INS      = 3 : sc_type_main_ins, ## 副本场景
}
##注意事项##
所有前缀为generated_的表格不能手动进行修改

## crwon_gem
属性分为对应1,10,100
冰 = 1
火 = 10
雷 = 100

## 场景战斗模式
   PK_PEACE    = 1,  ##和平模式 默认
   PK_ALL      = 2,  ##全体模式
   PK_TEAM     = 3,  ##组队模式


### monster.script 配置指南
每个怪物都可以指定一组附加的行为,默认都是一次性的
指令语法:
每条指令有前置条件和执行动作组成
{PerCond, Action}

PerCond: 前置条件语法
{Var, Test, Value}

Var 有效值
---------------------------
* hp

Test 有效值
-------------------------
eq ##==
ne ##!=
le ##<=
lt ##<
ge ##>=
gt ##>
    
Value的有效值
-------------------------
一个数字
{max_per, Ingeter >0 < 100}


Action 有效值
-----------------------------
{release_skill, SkillId}


例子
100 号怪， 在血量少于30% 时是否111号技能
[{hp, lt, {max_per, 30}}, {release_skill, 111}]


职业主属性
--------------------------------------
S_STRENGTH=1,  ## 力量
S_INTELLECT=2, ## 智力
S_NIMBLE=3,    ## 敏捷
S_STRONG=4,    ## 特质
