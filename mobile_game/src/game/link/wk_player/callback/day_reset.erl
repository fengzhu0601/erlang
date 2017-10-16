%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 04. 七月 2015 下午3:07
%%%-------------------------------------------------------------------
-module(day_reset).
-include("type.hrl").


%% API
-export([
    callback_list/0
]).




%% @doc 日重置。
-callback on_day_reset(SelfId :: player_id()) -> _.



callback_list() ->
    [
        %charge_reward_part,
        friend_mng,
        login_prize_part,
        %pay_goods_part,
        daily_activity_mng,
        guild_mng,
        abyss_mng,
        player_mng,
        limit_value_eng,
        alchemy_mng,
        arena_mng,
        skill_mng,
        task_system,
        main_ins_util,
        course_mng,
        main_star_shop_mng,
        ride_mng,
        main_instance_mng,
        vip_new_mng,
        open_server_happy_mng,
        server_login_prize_mng,
        impact_ranking_list_handle_client,
        guild_mining_mng,
        bounty_mng
    ].