%%%-------------------------------------------------------------------
%%% @author fengzhu
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 31. 八月 2016 下午4:07
%%%-------------------------------------------------------------------
-author("fengzhu").

-record(bounty_task, {
    task_id = 0,        %% 任务Id
    bounty_type = 0,    %% 任务类型
    task_status = 0,    %% 任务状态,2:已完成，1：可完成，0：未完成
    max_count = 0,
    cur_count = 0
}).

-record(bounty_liveness_prize, {
    id = 0,             %% 序号
    liveness = 0,       %% 活跃度
    prizeId = 0,        %% 奖励Id
    status = 0          %% 状态，0不可领取 1可领取 2已领取
}).

-define(BOUNTY_TASK_STATUS_0, 0).  %% 未完成
-define(BOUNTY_TASK_STATUS_1, 1).  %% 可完成

-define(LIVENESS_PRIZE_STATUS_0, 0).    %% 0不可领取
-define(LIVENESS_PRIZE_STATUS_1, 1).    %% 1可领取
-define(LIVENESS_PRIZE_STATUS_2, 2).    %% 2已领取

%% 返回码
%% 完成赏金任务
-define(REPLY_MSG_BOUNTY_COMPLETE_OK, 0).    %% 可完成赏金任务
-define(REPLY_MSG_BOUNTY_COMPLETE_1, 1).     %% 没有接取该赏金任务
-define(REPLY_MSG_BOUNTY_COMPLETE_2, 2).     %% 该赏金任务已经完成
-define(REPLY_MSG_BOUNTY_COMPLETE_3, 3).     %% 该赏金任务未完成
-define(REPLY_MSG_BOUNTY_COMPLETE_255, 255). %% 完成赏金任务失败

%% 刷新赏金任务
-define(REPLY_MSG_BOUNTY_REFRESH_OK, 0).     %% 刷新赏金任务成功
-define(REPLY_MSG_BOUNTY_REFRESH_1, 1).      %% 达到最大刷新次数
-define(REPLY_MSG_BOUNTY_REFRESH_2, 2).      %% 刷新任务消耗不足
-define(REPLY_MSG_BOUNTY_REFRESH_255, 255).  %% 刷新赏金任务失败

%% 领取活跃度奖励
-define(REPLY_MSG_BOUNTY_PRIZE_OK, 0).      %% 领取活跃度奖励成功
-define(REPLY_MSG_BOUNTY_PRIZE_1, 1).       %% 活跃度奖励不可领取
-define(REPLY_MSG_BOUNTY_PRIZE_2, 2).       %% 活跃度奖励已领取
-define(REPLY_MSG_BOUNTY_PRIZE_255, 255).   %% 活跃度奖励领取失败

%% 玩家赏金任务表,保存到数据库
-define(player_bounty_tab, player_bounty_tab).
-record(player_bounty_tab,
{
    id = 0,                     %% 玩家ID int
    is_opened = 0,              %% 玩家主动打开过
    bounty_task = [],           %% 当前所拥有的任务 #bounty_task{}
    liveness = 0,               %% 玩家当前的活跃度
    bounty_liveness_prize = []  %% 玩家当前的活跃度奖励 #bounty_liveness_prize{}
}).

%% -define(bounty_task_hecheng_zise_equip,6).
%% -define(bounty_task_hecheng_gem, 9).

%% 赏金任务类型
-define(BOUNTY_TASK_NORMAL_ROOM, 1).            %% 挑战普通副本
-define(BOUNTY_TASK_HARD_ROOM, 2).              %% 挑战困难副本
-define(BOUNTY_TASK_EMENG_ROOM, 3).             %% 挑战噩梦副本
-define(BOUNTY_TASK_KILL_MONSTER, 4).           %% 击杀怪物
-define(BOUNTY_TASK_QIANGHUA_EQUIP, 5).         %% 装备强化
-define(BOUNTY_TASK_JICHENG_EQUIP, 6).          %% 装备继承
-define(BOUNTY_TASK_HECHENG_EQUIP, 7).          %% 装备合成
-define(BOUNTY_TASK_DAKONG_EQUIP, 8).           %% 装备打孔
-define(BOUNTY_TASK_XIANGQIAN_EQUIP, 9).        %% 装备镶嵌
-define(BOUNTY_TASK_FENJIE_EQUIP, 10).          %% 装备分解
-define(BOUNTY_TASK_CUIQU_EQUIP, 11).           %% 装备萃取
-define(BOUNTY_TASK_FUMO_EQUIP, 12).            %% 装备附魔
-define(BOUNTY_TASK_SHENGJI_GEM, 13).           %% 升级宝石

-define(BOUNTY_TASK_HEISHI, 14).                %% 黑市
-define(BOUNTY_TASK_SHENGJI_LONGWEN, 15).       %% 升级龙纹
-define(BOUNTY_TASK_SHENGJI_CROWN, 16).         %% 升级皇冠
-define(BOUNTY_TASK_SHENGJI_PET, 17).           %% 升级宠物
-define(BOUNTY_TASK_FUHUA_PET, 18).             %% 孵化宠物
-define(BOUNTY_TASK_SHENGJI_RIDE, 19).          %% 升级坐骑
-define(BOUNTY_TASK_FEED_SHOUHUN, 20).          %% 喂食兽魂
-define(BOUNTY_TASK_FUMO_SHOUHUN, 21).          %% 抚摸兽魂
-define(BOUNTY_TASK_SHENGJI_SHOUHUN, 22).       %% 升级兽魂
-define(BOUNTY_TASK_SHENGJI_GUILD_KEJI, 23).    %% 升级公会科技
-define(BOUNTY_TASK_SHENGJI_GUILD_DATING, 24).  %% 升级公会大厅
-define(BOUNTY_TASK_SHENGJI_GUILD_JINENG, 25).  %% 升级公会技能
-define(BOUNTY_TASK_ARENA_P2E, 26).             %% 单人竞技
-define(BOUNTY_TASK_ARENA_M_P2P, 27).           %% 多人竞技
-define(BOUNTY_TASK_ARENA_P2P, 28).             %% 竞技场匹配

-define(BOUNTY_TASK_PASS_7_STAR, 29).           %% 7星通关
-define(BOUNTY_TASK_PASS_8_STAR, 30).           %% 8星通关
-define(BOUNTY_TASK_PASS_9_STAR, 31).           %% 9星通关
-define(BOUNTY_TASK_LIANJIN, 32).               %% 炼金
-define(BOUNTY_TASK_BUY_SP, 33).                %% 购买体力
-define(BOUNTY_TASK_SHAPESHIFT, 34).            %% 卡牌变身
-define(BOUNTY_TASK_GET_9_STAR, 35).            %% 通关获得9银星
-define(BOUNTY_TASK_GET_8_STAR, 36).            %% 通关获得8银星
-define(BOUNTY_TASK_GET_7_STAR, 37).            %% 通关获得7银星
-define(BOUNTY_TASK_GET_6_STAR, 38).            %% 通关获得6银星
-define(BOUNTY_TASK_GET_5_STAR, 39).            %% 通关获得5银星
-define(BOUNTY_TASK_ARENA_CHOUJIANG, 40).       %% 竞技场抽奖
-define(BOUNTY_TASK_JIANDING_EQUIP, 41).        %% 装备鉴定
-define(BOUNTY_TASK_HECHENG_GEM, 42).           %% 宝石合成
-define(BOUNTY_TASK_SHOP_BUY, 43).              %% 商店购买
-define(BOUNTY_TASK_SHOP_SELL, 44).             %% 商店出售
-define(BOUNTY_TASK_XILIAN, 45).                %% 洗练
-define(BOUNTY_TASK_GEM2, 46).                  %% 合成2级宝石
-define(BOUNTY_TASK_GEM3, 47).                  %% 合成3级宝石
-define(BOUNTY_TASK_GEM4, 48).                  %% 合成4级宝石
-define(BOUNTY_TASK_GEM5, 49).                  %% 合成5级宝石
-define(BOUNTY_TASK_GEM6, 50).                  %% 合成6级宝石
-define(BOUNTY_TASK_GEM7, 51).                  %% 合成7级宝石
-define(BOUNTY_TASK_GEM8, 52).                  %% 合成8级宝石
-define(BOUNTY_TASK_GEM9, 53).                  %% 合成9级宝石
-define(BOUNTY_TASK_GEM10, 54).                 %% 合成10级宝石

