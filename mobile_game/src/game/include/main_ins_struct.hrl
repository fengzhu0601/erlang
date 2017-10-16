-include_lib("common/include/com_define.hrl").

-define(main_instance_id_ing, main_instance_id_ing).
-define(current_pata_instance_id, current_pata_instance_id).
-define(maining_instance_lianji_count, maining_instance_lianji_count).
-define(maining_instance_shouji_count, maining_instance_shouji_count).

-define(main_open_card_count, main_open_card_count).
-define(main_open_card_prize_list, main_open_card_prize_list).

%%-record(main_ins_cfg, {
%%    id %% scene_id
%%    , ins_id
%%    , chapter_id = 0 %该副本属于那个章节
%%    , type = 1   %1主线副本，2自由副本、3神魔、4虚空、5日常活动、6天空之城随机本、7天空之城迷宫）任务和主线副本挂钩
%%    , sub_type = 0  %子类型(主线/自由[1简单、2普通、3困难]、神魔[1神、2魔]、虚空深渊[1简单、2恶梦]、日常活动[1、2、3]、天空之城随机[1永恒碎片、2时空碎片]、天空之城迷宫[1、2]
%%    , pervious = 0   %% 前置副本
%%    , sp_cost = 0    %%体力消耗
%%    , cost = 1
%%    , limit_level = 0  %% 解锁等级
%%    , pass_prize = 0 %% 每次通关奖励
%%    , max_members = 3 %% 最大成员
%%    , limit_pervious
%%    , stars
%%    , star_level_rewards
%%    , next = none %% 下一个场景
%%    , is_monster_match_level = ?FALSE %% 怪物属性、掉落物品、结算奖励是否匹配玩家等级
%%    , has_boss = 0 %是否是boss房间
%%    %%,random_prize%% 随机奖励
%%    %%,power_limit=0 %% 建议的战力
%%}).

%%-record(main_prize_cfg, {
%%    id,             %id
%%    ins_id,         %副本ID
%%    match_level,    %匹配等级
%%    pass_prize      %奖励
%%}).


-record(main_ins, {
    id,
    pass_time = exit(need_pass_time), %% sec
    lianjicount = 0,
    shoujicount = 0,
    relivenum = 0,
    star = 0,
    fenshu = 0,
    first_nine_star_pass = 0,
    today_passed_times = 0 %% 当天通关的次数
}).

-define(main_chapter_prize, main_chapter_prize).
-record(main_chapter_prize, {
    id, %% {playerid, chapter id,sub}
    goal_value={0,0,0},
    current_value=0,
    ins_list=[],
    is_get={0,0,0}
}).
-define(main_chapter_prize_status, main_chapter_prize_status).
-define(pd_main_chapter_prize_statue_list, pd_main_chapter_prize_statue_list).

-record(main_chapter_prize_status, {
    id,
    isget_list=[] %% {{chapter_id,sub}, {0,0,0}}
}).


% -record(room, {id %% team_instance() | integer()
%     , is_allow_midway_join%% 是否满员开始
%     , cfg_id
%     %%,combat_power_limit %% 最小战力
%     , members = [] %% [#member_info{}] %% 包含master的info
% }).


% -record(member_info, {id
%     , name
%     , level
%     , combar_power
%     , career
%     , max_hp
% }).


%%-record(fight_start, {
%%    scene_id = 0,              %副本表第一个场景
%%    fight_state = ?ins_fighting,%0离开副本  1战斗成功 2战斗未开始，战斗中 3战斗失败
%%    ins_state = 0,             %副本状态：0.单机副本  1.联网副本
%%    ins_type = 0,              %副本类型，1主线副本 2自由副本 3神魔 4虚空 6天空之城随机 7天空之城迷宫  8日常活动
%%    call_back = {},            %回调函数 M:F(fight_state::战斗状态, ins_info::副本信息, Arg)
%%    next_scene_call = {},      %is_client 由客户端发送  获取下一个副本场景ID回调函数, 该函数存在与场景进程，所以函数实现不能使用玩家进程字典
%%    playerIdOrtermId = 0,      %playerId or plyaerIdList
%%    ins_limit_time = 0,        %副本场景限制时间秒数，目前只支持一个场景
%%    is_notice_enter_scene = ?FALSE,  %进入场景和退出场景是否发送消息
%%    is_notice_kill_player = ?FALSE,  %杀死玩家是否发送消息
%%    is_notice_kill_monster = ?FALSE  %杀死怪物发送消息
%%}).

-define(player_main_ins_rank, main_ins_rank).

-record(main_ins_rank, {
    scene_id,
    rank_list = [] %% [{PlayerId, FenShu}]
}).

-define(player_main_ins_tab, player_main_ins_tab).
-define(player_main_ins_coin, player_main_ins_coin).
%-define(pd_main_ins_jinxing, pd_main_ins_jinxing).
%-define(pd_main_ins_yinxing, pd_main_ins_yinxing).
-record(player_main_ins_tab, {
    id,
    star_coin = 0,
    %jinxing = 0,
    %yinxing = 0,  
    mng
}).

%% 玩家副本挑战表
-define(player_main_ins_challenge_tab, player_main_ins_challenge_tab).

-record(player_main_ins_challenge_tab,
{
    id = 0,
    challenge_tree = gb_trees:empty()
}).

%% 玩家副本挑战结构
-record(main_ins_challenge,
{
    id,
    challenge_times = 0,        %% 挑战次数
    buy_challenge_times = 0,    %% 购买挑战次数
    max_challenge_times = 0     %% 最大可挑战次数

}).
