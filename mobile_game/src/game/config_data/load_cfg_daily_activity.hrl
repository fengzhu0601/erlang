%%%-------------------------------------------------------------------
%%% @author fengzhu
%%% @copyright (C) 2016, <COMPANY>
%%% @doc 日常活动
%%%
%%% @end
%%% Created : 04. 一月 2016 下午1:59
%%%-------------------------------------------------------------------
-author("fengzhu").

-define(DailyType_1, 1).
-define(DailyType_2, 2).
-define(DailyType_3, 3).
-define(DailyType_4, 4).
-define(DailyType_5, 5).
-define(DailyType_6, 6).

% -record(wave_cfg,
% {
%   	wave = 0,
%   	prize_id = 0
% }).

% -record(daily_2_exp_cfg,
% {
%   	monster_level,
%   	monster_exp
% }).

% -record(daily_activity_cfg,
% {
%   	open_fun = 0,
%   	ex_prize = 0,
%   	daily_2_max_monsters = 0,
%   	point_power = 0,
%   	exp_power = 0
% }).

-record(daily_activity_1_prize_cfg, {
    id,
	lev_min,
	lev_max,
	exp_prize_list,
    sweep_prize
}).

-record(daily_activity_2_prize_cfg, {
	id,
	lev_min,
	lev_max,
	point_longjing,
    sweep_prize
}).

-record(daily_activity_3_prize_cfg, {
    id,
    lev_min,
    lev_max,
    complete_prize,
    guess_prize,
    sweep_prize
}).

-record(daily_activity_4_prize_cfg, {
    id,
    lev_min,
    lev_max,
    point_money,
    sweep_prize
}).

-record(daily_activity_5_prize_cfg, {
    id,
    lev_min,
    lev_max,
    point_star,
    sweep_prize
}).

-record(weekly_activity_rank_prize_cfg, {
    id,
    activity_id,
    rank_num,
    prize
}).
