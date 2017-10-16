%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 19. 十月 2015 下午2:53
%%%-------------------------------------------------------------------
-author("clark").


-define(RANK_P2E_PRIZE_DAY_DT, 3).                    %% 三天






-define(misc_begin, 1).
-define(misc_server_start_time, 1).
-define(misc_arena_pre_over_tm, 2).
-define(misc_arena_pre_rank_data, 3).
-define(misc_ranking, 4).
-define(misc_ranking_arena, 5).
-define(misc_server_res_key, 6).
-define(misc_player_email, 7).
-define(misc_scene_view_max, 8).
-define(misc_guild_boss_reset_tm, 9).
-define(misc_auction_close_time, 10).
-define(misc_abyss_prize_time, 11).
-define(misc_bounty_open_times, 12).    %% 赏金任务被打开的次数
-define(misc_free_refresh_times, 13).   %% 赏金任务免费刷新次数
-define(misc_pay_refresh_times, 14).    %% 赏金任务付费刷新次数
-define(misc_bounty_is_over, 15).       %% 赏金任务活动开关 0开启,1关闭
-define(misc_open_server_board_count, 16).
-define(misc_open_server_get_prize_player_count, 17).  %% 记录开服狂欢的领奖人数
-define(misc_sp_lunch_status, 18).
-define(misc_sp_dinner_status, 19).
-define(misc_power_ranking_list_prize, 20).
-define(misc_pet_ranking_list_prize, 21).
-define(misc_suit_ranking_list_prize, 22).
-define(misc_ride_ranking_list_prize, 23).
-define(misc_abyss_ranking_list_prize, 24).
-define(misc_guild_ranking_list_prize, 25).
-define(misc_first_kill_guild_boss, 26).
-define(misc_open_server_finish_all_task_on_day_count, 27).
-define(misc_open_server_finish_all_task_count, 28).
-define(misc_bounty_rank_liveness, 29).             %% 赏金任务前10名活跃度
-define(misc_bounty_liveness_get, 30).              %% 赏金任务活跃度领取
-define(misc_bounty_opened_num, 31).                %% 打开过赏金任务的人数
-define(misc_end, 31).



-record(g_misc_tab,
{
    id,
    val = []
}).
