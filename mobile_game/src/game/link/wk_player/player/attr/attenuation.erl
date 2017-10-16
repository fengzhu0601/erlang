%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 30. 十一月 2015 下午9:28
%%%-------------------------------------------------------------------
-module(attenuation).
-author("clark").

%% API
-export(
[
    self_add/0
    , get_attenuation_pro/0
    , clear_attenuation_data/0
]).


-include("inc.hrl").
-include("player.hrl").
-include("player_data_db.hrl").
-include_lib("common/include/com_log.hrl").
-include("load_spirit_attr.hrl").
-include("item_bucket.hrl").



self_add() ->
    Cur = attr_new:get(?pd_room_prize_count, 0),
    attr_new:set(?pd_room_prize_count, Cur+1).


get_attenuation_pro() ->
    case attr_new:get(?pd_is_in_room, false) of
        false ->                                                          %% 不在副本中获得奖励时用时间来做
            MaxTime = misc_cfg:max_room_time_count(),
            DayOnlineTime = attr_new:get_online_time_onday(),
%%            ?INFO_LOG("DayOnlineTime = ~p", [DayOnlineTime]),
            if
                DayOnlineTime > ?SECONDS_PER_DAY ->                       %% 判断当玩家在线时间超过最大秒数时重置在线时间
                    clear_attenuation_data(),
                    1;
                DayOnlineTime >= MaxTime andalso DayOnlineTime < 2*MaxTime ->
%%                    misc_cfg:prize_attenuation_per_time() / 100;
%%                    ?INFO_LOG("1 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"),
                    (2*MaxTime - DayOnlineTime)/(2*MaxTime);
                DayOnlineTime >= 2*MaxTime ->
%%                    ?INFO_LOG("2 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"),
                    0;
                true ->
%%                    ?INFO_LOG("3 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"),
                    1
            end;
        true ->                                                             %% 在副本中获得奖励时候用次数来做限制
            MaxCount = misc_cfg:max_room_pass_count(),
            Cur = attr_new:get(?pd_room_prize_count, 0),
            if
                Cur >= MaxCount andalso Cur < 2*MaxCount->
%%                            misc_cfg:prize_attenuation_per_count() / 100;
%%                    ?INFO_LOG("4 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"),
                    (2*MaxCount - Cur)/(2*MaxCount);
                Cur >= 2*MaxCount ->
%%                    ?INFO_LOG("5 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"),
                    0;
                true ->
%%                    ?INFO_LOG("6 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"),
                    1
            end
    end.

%% 把增益相关数据清零
clear_attenuation_data() ->
    erlang:put(?pd_player_scene_time_count, 0),
    erlang:put(?pd_player_scene_second_this_time, util:get_now_second(0)).

