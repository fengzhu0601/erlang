%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 24. 五月 2016 下午2:31
%%%-------------------------------------------------------------------
-author("clark").

-include("guild_struct.hrl").
-include("guild_def.hrl").
-include("guild_cfg.hrl").


-define(GUILD_BOSS_KEY_BOSS_RECORD_ID,      1).     %% 当前BOSS的配表ID
-define(GUILD_BOSS_KEY_BOSS_EXP,            2).     %% BOSS进阶的经验值
-define(GUILD_BOSS_KEY_BOSS_HP,             3).     %% BOSS的HP
-define(GUILD_BOSS_KEY_BOSS_OVER_TIME_DT,   4).     %% BOSS召唤的结束时间段
-define(GUILD_BOSS_KEY_DAMAGE_TOTAL,        5).     %% 伤害记录
-define(GUILD_BOSS_KEY_DAMAGE_RANK,         6).     %% 伤害排行
-define(GUILD_BOSS_KEY_CALL_TIME,           7).     %% 召唤时的时间
-define(GUILD_BOSS_KEY_CALL_COUNT,          8).     %% 召唤
-define(GUILD_BOSS_KEY_KILLER,              9).     %% 击杀者
-define(GUILD_BOSS_KEY_BOARDCAST,           10).    %% 公会BOSS提示计数
-define(GUILD_BOSS_KEY_BE_KILLED,           11).    %% 公会BOSS被击杀    %% 0刚召唤出来, 1被击杀了

-define(guild_boss_damage_rank_tab, guild_boss_damage_rank_tab).

-define(guild_boss_tab, guild_boss).
-record(guild_boss,
{
    guild_id = 0,           %% 公会ID
    field =                 %% 公会字段
    [
        {?GUILD_BOSS_KEY_BOSS_RECORD_ID, 1101},
        {?GUILD_BOSS_KEY_BOSS_EXP, 0},
        {?GUILD_BOSS_KEY_BOSS_HP, 0},
        {?GUILD_BOSS_KEY_BOSS_OVER_TIME_DT, 0},
        {?GUILD_BOSS_KEY_DAMAGE_TOTAL, []},
        {?GUILD_BOSS_KEY_DAMAGE_RANK, []},
        {?GUILD_BOSS_KEY_CALL_TIME, 0},
        {?GUILD_BOSS_KEY_CALL_COUNT, 0},
        {?GUILD_BOSS_KEY_BOARDCAST, 0},
        {?GUILD_BOSS_KEY_BE_KILLED, 0}
    ]
}).



-define(GUILD_VICE_MASTER_MAX_NUM, 2).  %副会长个数
-define(GUILD_NAME_MAX_SIZE, 12).       %公会名称长度最大值
-define(GUILD_NOTICE_MAX_SIZE, 70).     %公会公告长度最大值
-define(IS_ONLINE, 1).                  %在线
-define(IS_OFFLINE, 0).                 %不在线
-define(is_not_join_guild(), (get(?pd_guild_id) =:= 0) orelse (get(?pd_guild_id) =:= ?undefined)).
-define(is_join_guild(), (get(?pd_guild_id) =/= 0) and (get(?pd_guild_id) =/= ?undefined)).
-define(PLAYER_GUILD_DEFAULT_LV, 1).      %玩家公会数据初始化时，公会等级默认等级
-define(PLAYER_GUILD_TECH_DEFAULT_LV, 0). %玩家公会数据初始化时，玩家科技默认等级

%%公会商店购买限制
-define(GUILD_SHOP_BUY_CONDITION, [{1, get(?pd_guild_lv)},
    {2, get(?pd_guild_totle_contribution)},
    {3, guild_service:get_guild_lv()},
    {4, load_cfg_guild:lookup_cfg(?guild_member_lvup_cfg, get(?pd_guild_lv), "member_lv")}]).

%%科技升级限制条件
-define(GUILD_TECH_BUILDINGS_LVUP_CONDITION, [{1, guild_service:get_guild_lv()}, {2, get(?pd_guild_lv)}]).
-define(PageSize, 12). %定义分页功能中一页的数量
-define(PageMaxNum, 40). %开始和终止的最大公会数量
-define(GUILD_MAX_NUM, 1000). %公会排行最大个数
-define(EVENT_MAX_NUM, 100).







%%会长权限
-define(GUILD_MASTER_PERMISSION,
    [
        ?GUILD_APPLY_AGREE_OR_REFUSED,
        ?GUILD_REMOVE_MEMBER,
        ?GUILD_REMOVE_VICE_MATER,
        ?GUILD_APPOINT_OR_REMOVE_POSITION,
        ?GUILD_MASTER_TRANSFER,
        ?GUILD_QUIT,
        ?GUILD_VIEW_APPLY_LIST,
        ?GUILD_UPDATE_NOTICE
    ]).

%%副会长权限
-define(GUILD_VICE_MASTER_PERMISSION,
    [
        ?GUILD_APPLY_AGREE_OR_REFUSED,
        ?GUILD_REMOVE_MEMBER,
        ?GUILD_VIEW_APPLY_LIST,
        ?GUILD_QUIT
    ]).

%%成员权限
-define(GUILD_MEMBER_PERMISSION,
    [
        ?GUILD_QUIT
    ]).


%% 献祭
-record(guild_boss_donate,
{
    guild_id = 0,
    donate_val = 0
}).

%% 进阶
-record(guild_boss_phase,
{
    guild_id = 0,
    record_id = 0
}).

%% 召唤
-record(guild_boss_call,
{
    guild_id = 0,
    record_id = 0
}).

%% 伤害
-record(guild_boss_damage,
{
    guild_id = 0,
    record_id = 0,
    damage = 0,
    killer_id = 0
}).


%% 重置公会BOSS
-record(guild_boss_reset,
{
    guild_id = 0
}).


