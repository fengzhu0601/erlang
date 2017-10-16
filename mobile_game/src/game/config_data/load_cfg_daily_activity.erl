%%%-------------------------------------------------------------------
%%% @author fengzhu
%%% @copyright (C) 2016, <COMPANY>
%%% @doc 日常活动
%%%
%%% @end
%%% Created : 04. 一月 2016 下午2:00
%%%-------------------------------------------------------------------
-module(load_cfg_daily_activity).
-author("fengzhu").

-include_lib("config/include/config.hrl").
-include("inc.hrl").
-include("load_cfg_daily_activity.hrl").

load_config_meta() ->
    [
        % #config_meta{
        %     record = #wave_cfg{},
        %     fields = ?record_fields(wave_cfg),
        %     file = "guard_mermaid.txt",
        %     keypos = #wave_cfg.wave,
        %     verify = fun verify_wave_cfg/1
        % },

        % #config_meta{
        %     record = #daily_2_exp_cfg{},
        %     fields = ?record_fields(daily_2_exp_cfg),
        %     file = "nissan_trial.txt",
        %     keypos = #daily_2_exp_cfg.monster_level,
        %     verify = fun verify_daily_2_cfg/1
        % },

        #config_meta{
            record = #daily_activity_1_prize_cfg{},
            fields = ?record_fields(daily_activity_1_prize_cfg),
            file = "daily_activity_1_prize.txt",
            keypos = #daily_activity_1_prize_cfg.id,
            all = [#daily_activity_1_prize_cfg.id],
            verify = fun verify_daily_activity_1_prize_cfg/1
        },

        #config_meta{
            record = #daily_activity_2_prize_cfg{},
            fields = ?record_fields(daily_activity_2_prize_cfg),
            file = "daily_activity_2_prize.txt",
            keypos = #daily_activity_2_prize_cfg.id,
            all = [#daily_activity_2_prize_cfg.id],
            verify = fun verify_daily_activity_2_prize_cfg/1
        },

        #config_meta{
            record = #daily_activity_3_prize_cfg{},
            fields = ?record_fields(daily_activity_3_prize_cfg),
            file = "daily_activity_3_prize.txt",
            keypos = #daily_activity_3_prize_cfg.id,
            all = [#daily_activity_3_prize_cfg.id],
            verify = fun verify_daily_activity_3_prize_cfg/1
        },

        #config_meta{
            record = #daily_activity_4_prize_cfg{},
            fields = ?record_fields(daily_activity_4_prize_cfg),
            file = "daily_activity_4_prize.txt",
            keypos = #daily_activity_4_prize_cfg.id,
            all = [#daily_activity_4_prize_cfg.id],
            verify = fun verify_daily_activity_4_prize_cfg/1
        },

        #config_meta{
            record = #daily_activity_5_prize_cfg{},
            fields = ?record_fields(daily_activity_5_prize_cfg),
            file = "daily_activity_5_prize.txt",
            keypos = #daily_activity_5_prize_cfg.id,
            all = [#daily_activity_5_prize_cfg.id],
            verify = fun verify_daily_activity_5_prize_cfg/1
        },

        #config_meta{
            record = #weekly_activity_rank_prize_cfg{},
            fields = ?record_fields(weekly_activity_rank_prize_cfg),
            file = "weekly_activity_rank_prize.txt",
            keypos = #weekly_activity_rank_prize_cfg.id,
            all = [#weekly_activity_rank_prize_cfg.id],
            verify = fun verify_weekly_activity_prize_cfg/1
        }
    ].

% verify_wave_cfg(#wave_cfg{wave = Wave, prize_id = PrizeId}) ->
%   ?check(is_integer(Wave), "guard_mermaid.txt wave[~w] 无效! ", [Wave]),
%   ?check(prize:is_exist_prize_cfg(PrizeId) orelse PrizeId =:= 0, "guard_mermaid.txt wave[~w] 无效! ", [Wave]).

% verify_daily_2_cfg(#daily_2_exp_cfg{monster_level = Level, monster_exp = Exp}) ->
%   ?check(is_integer(Level), "nissan_trial.txt monster_level[~w] 无效! ", [Level]),
%   ?check(is_integer(Exp), "nissan_trial.txt monster_exp[~w] 无效! ", [Exp]).


verify_daily_activity_1_prize_cfg(_) -> ok.

verify_daily_activity_2_prize_cfg(_) -> ok.

verify_daily_activity_3_prize_cfg(_) -> ok.

verify_daily_activity_4_prize_cfg(_) -> ok.

verify_daily_activity_5_prize_cfg(_) -> ok.

verify_weekly_activity_prize_cfg(_) -> ok.
