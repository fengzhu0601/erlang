%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 08. 七月 2015 上午11:48
%%%-------------------------------------------------------------------
-author("clark").


%% 速度定义多少地图格子每10秒 ms/pix
%% 地图是32X32
%% 随度  -> 多少毫秒移动一格
%% v = 300
%% g/ms =  10 * 1000 / 300
%%

%% sat attr
%% -define(PL_ATTR_HP          , 11). 最大血量
%% -define(PL_ATTR_MP          , 12). 最大蓝量
%% -define(PL_ATTR_SP          , 13). 体力
%% -define(PL_ATTR_NP          , 14). 能量
%% -define(PL_ATTR_STRENGTH    , 15). 力量
%% -define(PL_ATTR_INTELLECT   , 16). 智力
%% -define(PL_ATTR_NIMBLE      , 17). 敏捷
%% -define(PL_ATTR_STRONG      , 18). 体质
%% -define(PL_ATTR_ATK         , 19). 攻击
%% -define(PL_ATTR_DEF         , 20). 防御
%% -define(PL_ATTR_CRIT        , 21). 暴击
%% -define(PL_ATTR_BLOCK       , 22). 格挡
%% -define(PL_ATTR_PLIABLE     , 23). 柔韧
%% -define(PL_ATTR_PURE_ATK    , 24). 无视防御伤害
%% -define(PL_ATTR_BREAK_DEF   , 25). 破甲
%% -define(PL_ATTR_ATK_DEEP    , 26). 伤害加深
%% -define(PL_ATTR_ATK_FREE    , 27). 伤害减免
%% -define(PL_ATTR_ATK_SPEED   , 28). 攻击速度
%% -define(PL_ATTR_PRECISE     , 29). 精确
%% -define(PL_ATTR_THUNDER_ATK , 30). 雷公
%% -define(PL_ATTR_THUNDER_DEF , 31). 雷放
%% -define(PL_ATTR_FIRE_ATK    , 32). 火攻
%% -define(PL_ATTR_FIRE_DEF    , 33). 火访
%% -define(PL_ATTR_ICE_ATK     , 34). 冰攻
%% -define(PL_ATTR_ICE_DEF     , 35). 冰防
%% -define(PL_ATTR_MOVE_SPEED  , 36). 移动速度
%% -define(PL_ATTR_RUN_SPEED   , 37). 跑步速度
%% -define(PL_ATTR_SUCK_BLOOD  , 38). 吸血
%% -define(PL_ATTR_REVERSE     , 39). 反伤

%% 战力评分系数
-define(PF_BLOCK, 1).       %% 格挡
-define(PF_PRECISE, 1).     %% 精确
-define(PF_CRIT, 1).        %% 暴击等级
-define(PF_PLIABLE, 1).     %% 韧性等级
-define(PF_ATK, 1).         %% 攻击
-define(PF_DEF, 1).         %% 防御
-define(PF_ATK_SPEED, 5).   %% 攻击速度
-define(PF_HP, 0.1).        %% 生命
-define(PF_BREAK_DEF, 1).   %% 破甲
-define(PF_ICE_ATK, 1).     %% 冰攻
-define(PF_FIRE_ATK, 1).    %% 火攻
-define(PF_THUNDER_ATK, 1).   %% 雷攻
-define(PF_ICE_DEF, 0).       %% 冰防
-define(PF_FIRE_DEF, 0).      %% 火防
-define(PF_THUNDER_DEF, 0).   %% 雷防
-define(PF_INTELLECT_DEF, 3). %% 智力






%% 属性列表
-record(attr,
{
    id = 0,
    hp = 0,
    mp = 0,
    sp = 0,                         %% 废弃可以删除
    np = 0,                          %% 能量
    strength = 0,                   %% 力量
    intellect = 0,                    %% 智力
    nimble = 0,                     %% 敏捷
    strong = 0,                      %% 体质
    atk = 0,                        %% 攻击
    def = 0,                        %% 防御
    crit = 0,                       %% 暴击等级
    block = 0,                      %% 格挡
    pliable = 0,                     %% 韧性等级
    pure_atk = 0,                     %% 无视防御伤害
    break_def = 0,                    %% 破甲
    atk_deep = 0,                     %% 伤害加深
    atk_free = 0,                     %% 伤害减免
    atk_speed = 0,                    %% 攻击速度
    precise = 0,                      %% 精确
    thunder_atk = 0,                %% 雷攻
    thunder_def = 0,                %% 雷防
    fire_atk = 0,                   %% 火攻
    fire_def = 0,                   %% 火防
    ice_atk = 0,                    %% 冰攻
    ice_def = 0,                    %% 冰防
    move_speed = 0,                   %% 移动速度
    run_speed = 0,                    %% 跑步速度
    suck_blood = 0,                   %% 吸血
    reverse = 0,                       %% 反伤
    bati = 0                           %% 霸体
}).



%% 随机属性配置
-record(random_sats_cfg,
{
    id
    , min_num = 0        %% 鉴定属性最小值
    , max_num = 0        %% 鉴定属性最大值
    , sats = []            %% 基础属性 [{AttrCode, Per, Min, Max}]
}).