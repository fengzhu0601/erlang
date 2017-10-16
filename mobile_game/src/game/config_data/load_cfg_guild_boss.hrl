%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 27. 六月 2015 下午6:32
%%%-------------------------------------------------------------------
-author("clark").



%% 公会杂项表
-record(society_misc_cfg,
{
    id = 0,
    data = nil
}).


%% 公会boss表
-record(guild_boss_cfg,
{
    id = 0,
    monsterid = 0,
    guild_prize = 0,
    kill_prize = 0,
    first_kill_prize = 0,
    exp = 0,
    advance_consume = 0,
    advance_monster = [],
    levelup_time = [],
    challenge_time = 0,
    immo_exp = 0
}).


%% 公会boss sort prize表
-record(guild_boss_sort_prize_cfg,
{
    id = 0,
    bossid = 0,
    rank_num = 0,
    prize = 0
}).


