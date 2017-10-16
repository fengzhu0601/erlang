%%%-------------------------------------------------------------------
%%% @author fengzhu
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 05. 一月 2016 下午4:34
%%%-------------------------------------------------------------------
-author("fengzhu").




-record(main_ins_cfg,
{
    id %% scene_id
    , ins_id
    , chapter_id = 0 %该副本属于那个章节
    , type = 1   %1主线副本，2自由副本、3神魔、4虚空、5日常活动、6天空之城随机本、7天空之城迷宫）任务和主线副本挂钩
    , sub_type = 0  %子类型(主线/自由[1简单、2普通、3困难]、神魔[1神、2魔]、虚空深渊[1简单、2恶梦]、日常活动[1、2、3]、天空之城随机[1永恒碎片、2时空碎片]、天空之城迷宫[1、2]
    , pervious = 0   %% 前置副本
    , sp_cost = 0    %%体力消耗
    , battle_num = 0  %% 副本挑战次数
    , battle_cosnum = 1 %% 副本挑战次数消耗
    , buy_battle_upnum = 0 %% 挑战次数购买上限次数
    , buy_battle_cost       %% 挑战次数购买消耗(扣费类型，数组，每次购买到的次数)
    , sweep_cost            %% 扫荡副本消耗
    , cost = 1
    , relive_num = 0
    , relive_cost = []
    , limit_level = 0  %% 解锁等级
    , pass_prize = 0 %% 每次通关奖励
    , frist_starprize = 0
    , card_prize_pool = []%% 副本结算翻牌奖励
    , max_members = 3 %% 最大成员
    , limit_pervious
    , stars = []
    , star_level_rewards
    , next = none %% 下一个场景
    , is_monster_match_level = 0 %% 怪物属性、掉落物品、结算奖励是否匹配玩家等级
    , has_boss = 0 %是否是boss房间
    , abyss_integral = 0 %% 虚空深渊扫荡积分
    , guaiwu_gc_score = 0
    , guaiwu_gc_best_prize = 0
    %%,random_prize%% 随机奖励
    %%,power_limit=0 %% 建议的战力
}).

% -record(main_prize_cfg,
% {
%     id,             %id
%     ins_id,         %副本ID
%     match_level,    %匹配等级
%     pass_prize      %奖励
% }).

-record(main_ins_shop_cfg,
{
    id,
    price
}).

-record(main_chapter_star_prize_cfg,
{
    id,
    prize
}).

-record(fight_start,
{
    scene_id = 0,              %副本表第一个场景
    fight_state = 2,%0离开副本  1战斗成功 2战斗未开始，战斗中 3战斗失败
    ins_state = 0,             %副本状态：0.单机副本  1.联网副本
    ins_type = 0,              %副本类型，1主线副本 2自由副本 3神魔 4虚空 6天空之城随机 7天空之城迷宫  8日常活动
    call_back = {},            %回调函数 M:F(fight_state::战斗状态, ins_info::副本信息, Arg)
    next_scene_call = {},      %is_client 由客户端发送  获取下一个副本场景ID回调函数, 该函数存在与场景进程，所以函数实现不能使用玩家进程字典
    playerIdOrtermId = 0,      %playerId or plyaerIdList
    ins_limit_time = 0,        %副本场景限制时间秒数，目前只支持一个场景
    is_notice_enter_scene = 0,  %进入场景和退出场景是否发送消息
    is_notice_kill_player = 0,  %杀死玩家是否发送消息
    is_notice_kill_monster = 0  %杀死怪物发送消息
}).


