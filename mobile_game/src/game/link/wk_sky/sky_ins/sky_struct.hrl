-define(pd_sky_ins_timer, pd_sky_ins_timer).
-define(pd_sky_ins_player_state, pd_sky_ins_player_state). %0不在副本中 1在副本中, 2双方正在战斗


-define(player_sky_ins_tab, player_sky_ins_tab).   %存储玩家信息
-define(sky_ins_service, sky_ins_service).         %公共数据
-define(sky_ins_player_info, sky_ins_player_info). %存储正在活动副本中的玩家信息
-define(sky_ins_kill_box, sky_ins_kill_box).       %存储杀过的宝箱信息
-define(sky_ins_cfg, sky_ins_cfg).                  %杂项表
    %%-define(sky_rank_cfg, sky_rank_cfg).                %排名奖励表
    %%-define(sky_scene_random_cfg, sky_scene_random_cfg). %场景随机权重表

-define(sky_ins_service_key, 1). %公共数据表只有一条数据
-define(tick_sky_ins_activity_open, tick_sky_ins_activity_open).
-define(tick_sky_ins_box_level, tick_sky_ins_box_level).
-define(tick_sky_ins_monster_level, tick_sky_ins_monster_level).

-define(SKY_INS_DEFAULT_RANK_CFG, 101). %排名100以后的奖励ID
-define(SKY_INS_BOX_MONSTER_IDS, lists:seq(2, 30)). %宝箱怪物ID
-define(SKY_INS_DEFAULT_MONSTER_LV, 1).
%% 奖励经验
-define(EXP_PRIZE_CLIENT(LevelupExp, KillCount), round(KillCount / 10000 * LevelupExp)).
-define(EXP_PRIZE_ONLINE(LevelupExp, KillPlayerCount, KillMonsterCount), round((KillPlayerCount / 1000 + KillMonsterCount / 2000) * LevelupExp)).

-define(SKY_INS_SUM_TIME(Hour, Minit, Second), ((Hour * 60 * 60) + (Minit * 60) + Second)). %{时分秒}转化为秒数

%% 存储玩家击杀数量
-record(player_sky_ins_tab, {
    player_id = 0,
    kill_client_monster = 0, %单人副本杀怪数量
    kill_player = 0,   %击杀玩家
    kill_monster = 0,  %击杀怪物
    join_time = 0      %参加活动时间
}).

%% 公共数据，该功能是否开放、该功能结束时间
-record(sky_ins_service, {
    id = 1,
    is_open = 0,
    end_timestamp = 0
}).

%% 存储正在活动副本中的玩家信息
-record(sky_ins_player_info, {
    player_id = 0,
    player_pid = 0,
    player_career = 0,
    player_level = 0,
    player_power = 0,
    player_camp = 0,
    scene_id = 0,
    is_match = 0    %1在副本中可以匹配  0.不可以匹配(离开副本，正在双方战斗)
}).

%% 存储杀过的宝箱信息
-record(sky_ins_kill_box, {
    box_bid,
    player_career,
    player_id,
    player_name,
    player_level,
    box_drop
}).

%% 杂项表配置
-record(sky_ins_cfg, {
    level_limit = 0,
    open_time = 0,
    monster_change = 0,
    box_change = 0
}).

%%%% 排名奖励表
%%-record(sky_rank_cfg, {
%%    id = 0,
%%    rank = 0,
%%    monster_prize = 0,
%%    box_prize = 0,
%%    warrior_prize = 0
%%}).
%%
%%%% 场景随机概率表
%%-record(sky_scene_random_cfg, {
%%    scene_id,
%%    enter_per
%%}).