%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 23. 十一月 2015 下午9:42
%%%-------------------------------------------------------------------
-author("clark").



%% 职业属性
-record(battle_coef_cfg,
{
    id          %% ID
    , coef      %% 系数
    , coef1     %% 系数1
    , coef2     %% 系数2
    , coef3     %% 系数3
    , coef4     %% 系数4
    , coef5		%% 系数5
}).


-define(lv_suppress,        1).     %% 等级压制系数
-define(guard,              2).     %% 招架率
-define(precise,            3).     %% 精准率
-define(final_guard,        4).     %% 最终招架率
-define(crit_rate,          5).     %% 暴击率
-define(crit_prob,          6).     %% 暴击倍率
-define(pliable_rate,       7).     %% 韧性率
-define(pliable_prob,       8).     %% 韧性倍率
-define(crit_fact_prob,     9).     %% 实际暴击概率
-define(crit_damage,        10).    %% 暴击伤害
-define(pve_normal_damage,  11).    %% pve普通伤害
-define(pvp_normal_damage,  12).    %% pvp普通伤害
-define(pve_skill_damage,	13).	%% pve技能伤害
-define(pvp_skill_damage,   14).    %% pvp技能伤害
-define(def_rate,           15).    %% 防御率
-define(pvp_last_rate,      17).    %% pvp最终伤害系数
-define(pve_last_rate,      18).    %% pve最终伤害系数