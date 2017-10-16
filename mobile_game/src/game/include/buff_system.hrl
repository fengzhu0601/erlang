%%%-------------------------------------------------------------------
%%% @author hank
%%% @copyright (C) 2016, <COMPANY>
%%% @doc  buff 定义
%%%
%%% @end
%%% Created : 04. Mar 2016 10:44 AM
%%%-------------------------------------------------------------------
-author("hank").


-define(PL_ATTR_HP, 11). %%最大血量
-define(PL_ATTR_MP, 12). %%最大蓝量
-define(PL_ATTR_SP, 13). %%体力
-define(PL_ATTR_NP, 14). %%能量
-define(PL_ATTR_STRENGTH, 15). %%力量
-define(PL_ATTR_INTELLECT, 16). %%智力
-define(PL_ATTR_NIMBLE, 17). %%敏捷
-define(PL_ATTR_STRONG, 18). %%体质
-define(PL_ATTR_ATK, 19). %%攻击
-define(PL_ATTR_DEF, 20). %%防御
-define(PL_ATTR_CRIT, 21). %%暴击
-define(PL_ATTR_BLOCK, 22). %%格挡
-define(PL_ATTR_PLIABLE, 23). %%柔韧
-define(PL_ATTR_PURE_ATK, 24). %%无视防御伤害
-define(PL_ATTR_BREAK_DEF, 25). %%破甲
-define(PL_ATTR_ATK_DEEP, 26). %%伤害加深
-define(PL_ATTR_ATK_FREE, 27). %%伤害减免
-define(PL_ATTR_ATK_SPEED, 28). %%攻击速度
-define(PL_ATTR_PRECISE, 29). %%精确
-define(PL_ATTR_THUNDER_ATK, 30). %%雷公
-define(PL_ATTR_THUNDER_DEF, 31). %%雷放
-define(PL_ATTR_FIRE_ATK, 32). %%火攻
-define(PL_ATTR_FIRE_DEF, 33). %%火访
-define(PL_ATTR_ICE_ATK, 34). %%冰攻
-define(PL_ATTR_ICE_DEF, 35). %%冰防
-define(PL_ATTR_MOVE_SPEED, 36). %%移动速度
-define(PL_ATTR_RUN_SPEED, 37).  %%跑步速度
-define(PL_ATTR_SUCK_BLOOD, 38). %% 吸血
-define(PL_ATTR_REVERSE, 39).	%% 反伤

-define(BUFF_DELAY_FEQ, 500).  % buff 效果频率

-define(BUFF_TYPE_WUDI, 1).  % buff 无敌状态
-define(BUFF_TYPE_BATI, 2).  % buff 霸体状态
-define(BUFF_TYPE_XUANYUN, 3).  % buff 眩晕态
-define(BUFF_TYPE_BINGDONG, 4).  % buff 冰冻状态
-define(BUFF_TYPE_MIANSHANG, 5).  % buff 免伤状态
-define(BUFF_TYPE_DINGSHEN, 6).  % buff 定身状态
-define(BUFF_TYPE_CHENMO, 7).  % buff 沉默状态
-define(BUFF_TYPE_ADDATTRS, 8).  % 加属性值
-define(BUFF_TYPE_ATTRS, 9).  % 改变属性 , 加血，加蓝
-define(BUFF_TYPE_MOVE, 10). % 改变速度
-define(BUFF_TYPE_HURT, 11). % 伤害buff
-define(BUFF_TYPE_RESETCD, 12). % 重置cd buff
-define(BUFF_TYPE_EMIT, 13). % buff 释放物
-define(BUFF_TYPE_PASSIVE, 14). % 被动效果 buff

-define(SPECIAL_SKILL_TYPE, 1).


-define(SKILL_MODIFY_TRIGGER_TYPE_0, 0). % 无类型
-define(SKILL_MODIFY_TRIGGER_TYPE_1, 1). % 技能释放 (实现)
-define(SKILL_MODIFY_TRIGGER_TYPE_2, 2). % 技能命中 (实现)
-define(SKILL_MODIFY_TRIGGER_TYPE_3, 3). % 技能打断 (实现)
-define(SKILL_MODIFY_TRIGGER_TYPE_4, 4). % 技能结束 (实现)
-define(SKILL_MODIFY_TRIGGER_TYPE_5, 5). % 杀死等级差
-define(SKILL_MODIFY_TRIGGER_TYPE_6, 6). % 被击中
-define(SKILL_MODIFY_TRIGGER_TYPE_7, 7). % 受击者血量百分比
-define(SKILL_MODIFY_TRIGGER_TYPE_8, 8). % 没有
-define(SKILL_MODIFY_TRIGGER_TYPE_9, 9). % 没有
-define(SKILL_MODIFY_TRIGGER_TYPE_10, 10). % 根据怪物类型触发
-define(SKILL_MODIFY_TRIGGER_TYPE_11, 11). % ....
-define(SKILL_MODIFY_TRIGGER_TYPE_12, 12). % .....
-define(SKILL_MODIFY_TRIGGER_TYPE_13, 13). % .....  (1-10触发生产buff)


-record(buff_stat, {
    apply_buffs = [],
    apply_skill_modifies = [],
    apply_mp = 0,
    apply_cancel_buffs = []
%%   , apply_emits_skills = []
}).

%%-define(buff_state_new(Idx, BuffState), undefined = erlang:put({buff_state, Idx}, BuffState)).
-define(get_buff_state(Idx), erlang:get({buff_state, Idx})).
-define(update_buff_state(Idx, BuffState), erlang:put({buff_state, Idx}, BuffState)).

-define(delete_buff_state(Idx), erlang:erase({buff_state, Idx})).


-define(pd_agent_attrs_sync, pd_agent_attrs_sync).

-record(buff_damage_callback, {
    attacker,
    defender,
    damage
}).
