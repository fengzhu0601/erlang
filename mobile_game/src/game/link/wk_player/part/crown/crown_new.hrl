%%%-------------------------------------------------------------------
%%% @author lan
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 05. 七月 2016 上午11:25
%%%-------------------------------------------------------------------
-author("lan").

-define(pd_crown_skill_list, pd_crown_skill_list).
-define(crown_anger_max_value, 200).


%% 玩家最多可以装备一条皇冠之星技能和其它皇冠技能一条；皇冠之星最多装备一条，其它技能最多装备一条
-define(YUANSU_ZHIGUAN, 1).             %% 元素之冠
-define(GUANAN_ZHIGUAN, 2).             %% 光暗之冠
-define(MINGYUN_ZHIGUAN, 3).            %% 命运之冠
-define(HUANGGUAN_ZHIXING, 4).          %% 皇冠之星

-define(SKILL_INIT_LEVEL, 1).           %% 技能的初始等级
-define(CROWN_SKILL_USE, 1).            %% 技能正在使用
-define(CROWN_SKILL_UNUSE, 0).          %% 技能没有使用

-define(CROWN_SKILL_TYPE_ACTIVE, 1).            %% 皇冠技能类型主动
-define(CROWN_SKILL_TYPE_PASSIVITY, 2).         %% 皇冠技能类型被动
-define(CROWN_SKILL_TYPE_STAR, 3).              %% 皇冠类型选择性被动（皇冠之星）

-define(CROWN_SKILL_MAX_LEVEL, 10).     %% 皇冠技能的最大等级

%% 把主动技能、被动技能、与皇冠之星保存到同一个列表中存储，在使用的时候在进行筛选
-define(player_crown_new_tab, player_crown_new_tab).
-record(player_crown_new_tab,
{
    id,
    anger = 0,
    skill_list = []      %% [{skillId, skillLevel, isUse}]
}).


%% 技能激活回复码
-define(REPLAY_MSG_SKILL_ACTIVATE_OK, 0).               %% 技能被成功激活
-define(REPLAY_MSG_SKILL_ACTIVATE_1, 1).                %% 已经装备此技能
-define(REPLAY_MSG_SKILL_ACTIVATE_2, 2).                %% 角色等级不够
-define(REPLAY_MSG_SKILL_ACTIVATE_3, 3).                %% 消耗不够
-define(REPLAY_MSG_SKILL_ACTIVATE_4, 4).                %% 配置的条件2不满足
-define(REPLAY_MSG_SKILL_ACTIVATE_5, 5).                %% 配置的条件3不满足
-define(REPLAY_MSG_SKILL_ACTIVATE_6, 6).                %% 配置的条件4不满足
-define(REPLAY_MSG_SKILL_ACTIVATE_255, 255).            %% 其它错误


%% 技能升级回复码
-define(REPLAY_MSG_SKILL_UPDATE_OK, 0).                 %% 技能被成功升级
-define(REPLAY_MSG_SKILL_UPDATE_1, 1).                  %% 已经达到最大等级
-define(REPLAY_MSG_SKILL_UPDATE_2, 2).                  %% 升级消耗不足
-define(REPLAY_MSG_SKILL_UPDATE_255, 255).              %% 其它错误


%% 装备皇冠技能回复码
-define(REPLAY_MSG_SKILL_DRESS_OK, 0).                  %% 装备皇冠技能成功
-define(REPLAY_MSG_SKILL_DRESS_1, 1).                  %% 该技能没有被激活
-define(REPLAY_MSG_SKILL_DRESS_255, 255).               %% 其它错误

%% 脱掉皇冠技能回复码
-define(REPLAY_MSG_SKILL_UNDRESS_OK, 0).                  %% 脱掉皇冠技能成功
-define(REPLAY_MSG_SKILL_UNDRESS_255, 255).               %% 其它错误


%% 装备皇冠之星回复码
-define(REPLAY_MSG_DRESS_CROWN_STAR_OK, 0).             %% 装备皇冠之星成功
-define(REPLAY_MSG_DRESS_CROWN_STAR_255, 255).               %% 其它错误

%% 脱掉皇冠之星技能回复码
-define(REPLAY_MSG_UNDRESS_CROWN_STAR_OK, 0).             %% 脱掉皇冠之星成功
-define(REPLAY_MSG_UNDRESS_CROWN_STAR_255, 255).               %% 其它错误



