%%%-------------------------------------------------------------------
%%% @author lan
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 05. 九月 2016 上午11:16
%%%-------------------------------------------------------------------
-author("lan").


-define(player_open_server_2_tab, player_open_server_2_tab).
-record(player_open_server_2_tab,
{
	id,
	type_task,		%% 任务类型对应的任务列表type, [{TaskId1,FinishNum},.]
	prize_state_list,			%% 任务表的领奖状态	[{TasdId, IsFinish, IsGetPrize}, {任务id, 是否完成, 是否领奖}]
	is_get_prize = 0,		%% 玩家是否领过奖，用来统计开服狂欢的领奖参与率
	is_record_on_day_task_state = 0,	%% 完成当日任务的记录状态
	is_record_all_task_state = 0,		%% 完成全部任务的记录状态
	today_pay_money = 0,					%% 当天充值数量
	today_is_pay_money = 0,				%% 今天是否充值
	pay_day_count = 0					%% 连续充值天数
%%	chongzhi_task,		%% 充值任务状态
%%	fuben_star_task		%% 副本星的状态
}).


%%-define(pd_day_server_happy_task_list, pd_day_server_happy_task_list).	%% 开服狂欢的任务列表
-define(pd_type_server_happy_task_list, pd_type_server_happy_task_list).	%% 开服狂欢的类型对应的任务列表
-define(pd_server_happy_get_prize_state, pd_server_happy_get_prize_state).	%% 任务的领奖状态
-define(pd_server_happy_is_get_prize, pd_server_happy_is_get_prize).	%% 玩家是否参与过领奖
-define(pd_server_happy_is_record_on_day_task_state, pd_server_happy_is_record_on_day_task_state).
-define(pd_server_happy_is_record_all_task_state, pd_server_happy_is_record_all_task_state).
-define(pd_player_pay_money, pd_player_pay_money).			%% 记录玩家当天的充值钱数

-define(pd_server_happy_chongzhi_task, pd_server_happy_chongzhi_task).
-define(pd_server_happy_fuben_star_task, pd_server_happy_fuben_star_task).
-define(pd_server_happy_today_is_pay, pd_server_happy_today_is_pay).
-define(pd_server_happy_pay_day_count, pd_server_happy_pay_day_count). %% 连续充值天数

-define(server_happy_activity_day, 7).		%% 活动开启天数

%% 开服狂欢配置类型定义
-define(USE_LIANJINSHOU_COUNT, 1).		%% 使用炼金手的次数
-define(SHOP_TILI_COUNT, 2).			%% 购买体力次数
-define(LEVEL_UP,  3).					%% 达到的等级
-define(ZHANLI_VAL, 4).					%% 战力值达到
-define(BAG_GRID_OPEN_COUNT, 5).		%% 背包格子开启数量
-define(DEPOT_GRID_OPEN_COUNT, 6).		%% 仓库格子开启数量
-define(SHOP_COUNT, 7).					%% 在商店购买次数
-define(STAT_SHOP_COUNT, 8).			%% 在星商店购买次数
-define(BLACK_SHOP_COUNT, 9).			%% 在黑市购买次数
-define(HAVE_FRIEND_COUNT, 10).			%% 拥有好友数量
-define(NINE_START_FUBEN_CROSS_COUNT, 11).		%% 9星副本通关次数
-define(IS_CROSS_FUBEN, 12).				%% 通关副本
-define(CROSS_HARD_FUBEN_COUNT, 20).	%% 通关困难副本次数
-define(CROSS_EMENG_FUBEN_COUNT, 21).	%% 通关噩梦副本次数
-define(GUARD_MERMAN_COUNT,  22).		%% 守卫人鱼活动次数
-define(GUARD_SANGNI_COUNT, 23).		%% 守卫桑尼号次数
-define(CHALLENGE_GUAIWU_GONGHENG_COUNT, 24).	%% 挑战怪物攻城次数
-define(CHALLENGE_SHIKONG_LIEFENG_COUNT, 25).	%%	挑战时空裂缝次数
-define(GUESS_SHIKONG_LIEFENG_BOSS_SEC_COUNT, 26).	%% 成功竞猜时空裂缝boss出场顺序次数
-define(ABYSS_ACHIEVE_LAYER, 27).				%% 虚空深渊达到层数
-define(UPDATE_LONGWEN_COUNT, 28).				%% 升级龙纹次数
-define(UPDATE_CROWN_COUNT, 29).				%% 升级皇冠次数
-define(USE_CROWN_SKILL_COUNT, 30).				%% 使用皇冠技能次数
-define(HATCH_PET_COUNT, 31).			%% 孵化宠物次数
-define(UPDATE_PET_COUNT, 32).			%% 升级宠物次数
-define(PET_GONGMING_UPDATE_POWER, 33). 	%% 宠物共鸣提升战斗力
-define(UPDATE_RIDE_COUNT, 34).				%% 升级坐骑次数
-define(FEED_SHOUHUN_COUNT, 35).			%% 喂食兽魂次数
-define(UPDATE_SHOUHUN_COUNT, 36).			%% 升级兽魂次数
-define(UPDATE_SHOUHUN_CRIT_COUNT, 37).		%% 升级兽魂暴击次数
-define(UPDATE_GUILD_BUILD_COUNT, 38).		%% 升级公会建筑次数
-define(GUILD_BOSS_XIANJI_COUNT, 39).		%% 公会boss献祭次数
-define(ZHANZHENG_XUEYUAN_STUDY_COUNT, 40). 	%% 战争学院训练次数
-define(ZHANZHENG_XUEYUAN_BOSS_COUNT, 41).		%% 战争学院挑战boss次数
-define(ARENA_RANK, 42).					%% 竞技场排名在x名内
-define(ARENA_COUNT, 43).					%% 竞技场单人竞技次数
-define(ARENA_DAN, 44).						%% 竞技场达到的段位
-define(ARENA_RAND_CHALLENG_COUNT, 45).		%% 竞技场随机挑战次数
-define(ARENA_CHALLENG_MULTI_P2P_COUNT, 46).	%% 竞技场多人模式挑战次数
-define(ARENA_DRAW_PRIZE_COUNT, 47).		%% 竞技场抽奖次数
-define(REACH_ACHIEVEMENT_COUNT, 48).		%% 达成成就数量
-define(FINISH_SEVEN_STAR_TASK_COUNT, 49).		%% 完成7星每日任务数量
-define(TAKE_ON_PURPLE_EQUIP_COUNT, 50).		%% 装备紫色装备的数量
-define(TAKE_ON_ORANGE_EQUIP_COUNT, 51).		%% 装备橙色装备的数量
-define(TAKE_ON_SUIT_EQUIP_COUNT,  52).			%% 装备套装的数量
-define(QIANGHUA_PART_LEVEL, 53).				%% 部位强化至x级
-define(HECHENG_PURPLE_UP_EQUIP_COUNT, 54).		%% 合成紫色以上品质装备的次数
-define(RESOLVE_EQUIP_NUM, 55).					%% 分解装备的数量
-define(CUIQU_EQUIP_NUM, 56).					%% 萃取装备的数量
-define(EQUIP_FUMO_COUNT, 57).					%% 装备附魔的次数
-define(HECHENG_2_LEVEL_GEM, 58).				%% 合成颗2级以上宝石的次数
-define(UPDATE_SHISHI_GEM_LEVEL, 59).			%% 升级史诗宝石至X级
-define(XILIAN_EQUIP, 60).						%% 洗炼装备
-define(GUILD_JUANXIAN, 61).					%% 公会捐献
-define(SHANGJIN_TASK, 62).						%% 达成赏金任务個數
-define(FINISH_5_STAR_UP_TASK, 63).				%% 完成5星以上每日任务数量

-define(PET_JING_JIE, 64).						%% 宠物进阶
%%-define(FINISH_SHANGJIN_TASK_COUNT, 65).		%% 完成赏金任务个数
-define(CHONGZHI_MONEY_NUM, 66).				%% 充值金额数量
-define(FUHUA_PET_QUALITY, 67).					%% 孵化宠物品质
-define(ACTIVATE_PET_GONGMING_ATTR, 68).		%% 激活共鸣属性条数
-define(STORE_BUY_COUNT, 69).					%% 商城购买次数
-define(HECHENG_3_LEVEL_GEM, 70).				%% 合成3级以上宝石次数
-define(HECHENG_4_LEVEL_GEM, 71).				%% 合成4级以上宝石次数
% 72
-define(CROSS_FUBEN_GET_STAR_COUNT, 72).		%% 通关副本获取星星的数量
% 73
-define(PAY_MONEY_LIST, 73).					%% 连续充值天数后的充值金额



%% 坐骑id
-define(caoyuan_horse, 1).			%% 草原战马id


%% 固定数量的达成，比如穿7件紫色装备、穿几件套装等
-define(count_reach_list,
[
	?TAKE_ON_PURPLE_EQUIP_COUNT,
	?TAKE_ON_ORANGE_EQUIP_COUNT,
	?TAKE_ON_SUIT_EQUIP_COUNT,
	?ACTIVATE_PET_GONGMING_ATTR,
	?CHONGZHI_MONEY_NUM,
	?PET_JING_JIE
]).

%% 直接达成不需要累加的人任务列表(加到这里就变成1了)
-define(task_finish_one_ok_list,
[
	?LEVEL_UP,
	?ZHANLI_VAL,
	?BAG_GRID_OPEN_COUNT,
	?DEPOT_GRID_OPEN_COUNT,
	?IS_CROSS_FUBEN,
	?ABYSS_ACHIEVE_LAYER,
	?PET_GONGMING_UPDATE_POWER,
	?ARENA_RANK,
	?ARENA_DAN,
	?QIANGHUA_PART_LEVEL,
	?FUHUA_PET_QUALITY,
	?UPDATE_RIDE_COUNT
]).

%% 副本奖励星状态列表

%% 需要按照排名达成的任务
-define(rank_task_one_ok_list,
[
	?ARENA_RANK
]).

%% 玩家身上最多能穿的装备数量
-define(player_all_equip_count, 7).
%% 一套套装的总数量
-define(a_suit_equip_count, 6).

%% 领取任务返回码
-define(GET_SERVER_HAPPY_PRIZE_OK, 0).				%% 获取奖励成功
-define(GET_PRIZE_ERROR_OF_DAY, 1).		%% 领去任务天数不正确
-define(GET_PRIZE_ERROR_OF_GET, 2).		%% 该任务已经被领奖了
-define(GET_PRIZE_ERROR_OF_NOFINE, 3).	%% 没有找到该奖励信息


-define(init_get_prize_state, 0).		%% 初始化领奖的状态
-define(get_prize_state, 1).			%% 已经领奖的状态

-define(task_not_finish, 0).			%% 任务没有完成
-define(task_is_finished, 1). 			%% 任务已经完成