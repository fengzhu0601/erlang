%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 10. 四月 2016 上午4:22
%%%-------------------------------------------------------------------
-author("clark").


-include("porsche_event.hrl").


%% ------------------ evt ------------------
-define(rule_cfg_evt,
    [
        {10001,             #room_enter_room{}}
        , {10002,           #player_move{}}
        , {10003,           #monster_die{}}
        , {10004,           #player_die{}}
        , {10005,           #room_new_end{}}
        , {10006,           #rule_enter_state{}}
        , {10007,           #agent_move_over{}}
        , {10008,           #agent_relaxation{}}
        , {10009,           #damaged_bag{}}
        , {10010,           #skill_over{}}
    ]).


%% --------------------------------------------
%% -define(type_room_0402,
%%     [
%%         {10011,     auto},      %% 自动开自动关
%%         {10012,     auto},
%%         {82,        active}     %% 共享的
%%     ]).

%% must
-define(room_cfg_must,
    [
        {must_send_evt,         fun rm_user_evt:send_evt/1}
    ]).

%% can
-define(room_cfg_can,
    [
        {is_player_in_x,        fun scene_event_callback:is_player_in_x/1},
        {is_monsters_flush_ok,  fun scene_event_callback:is_monsters_flush_ok/0},
        {is_all_monster_die,    fun scene_event_callback:is_all_monster_die/0},
        {is_monster_die,        fun scene_event_callback:is_monster_die/1},
        {is_player_got_task,    fun scene_event_callback:is_player_got_task/1},
        {is_player_item_enough, fun scene_event_callback:is_player_item_enough/1},
        {is_all_player_in_x,    fun scene_event_callback:is_all_player_in_x/1}
    ]).

%% do
-define(room_cfg_do,
    [
        {set_event,             fun rm_user_evt:send_evt/1},
        {set_timer,             fun rm_user_evt:send_evt/1},
        {send_evt,              fun rm_user_evt:send_evt/1},
        {create_monsters,       fun rm_monster:create_monsters/1},
        {create_rand_monsters,  fun rm_monster:create_rand_monsters/1},
        {check_empty_room,      fun rm_system:check_empty_room/1},
        {lock_area,             fun scene_event_callback:lock_area/1},
        {can_do_lock_area,      fun scene_event_callback:can_do_lock_area/0},
        {monster_speaking,      fun scene_event_callback:monster_speaking/1},
        {show_animation,        fun scene_event_callback:show_animation/1},
        {onset_trap,            fun scene_event_callback:onset_trap/1},
        {active_transport_door, fun scene_event_callback:active_transport_door/1},
        {fuben_complete,        fun scene_event_callback:fuben_complete/0},
        {monsters_flush_ok,     fun scene_event_callback:monsters_flush_ok/0},
        {kill_all_monsters,      fun scene_event_callback:kill_all_monsters/0},
        {trace,                 fun rm_debug:trace/1},
        {set_state,             fun room_system:set_state/1},
        {change_ai,             fun rm_monster:change_ai/1}
%%         {test,                  fun rm_monster:test/1}
    ]).

%% done
-define(room_cfg_done,
    [
        {done_set_state,        fun room_system:set_state/1}
    ]).





%% -------------------- AI ---------------------
-define(ai_cfg_must,
    [
        {must_send_evt,         fun rm_user_evt:send_evt/1}
    ]).

%% can
-define(ai_cfg_mutex,
    [
        {is_mutex,              fun mst_ai_sys:is_mutex/1}
        , {is_mutex_auto_val,   fun mst_ai_sys:is_mutex_auto_evaluate/1}
    ]).




-define(ai_cfg_can,
    [
        {can_trace,             fun rm_debug:can_trace/1},
        {is_near_player_x,      fun mst_ai_plug:is_near_player_x/1},
        {is_near_player_y,      fun mst_ai_plug:is_near_player_y/1},
        {is_pass,               fun mst_ai_plug:is_pass/1},
        {is_move_over,          fun mst_ai_plug:is_move_over/0},
        {is_cd,                 fun mst_ai_plug:is_cd/1},
        {is_next_segment,       fun mst_ai_sys:is_next_segment/0},
        {is_near_born_x,        fun mst_ai_plug:is_near_born_x/1},
        {is_born_near_player_x, fun mst_ai_plug:is_born_near_player_x/1}
    ]).


%% do
-define(ai_cfg_do,
    [
        {trace,                 fun rm_debug:trace/1},
        {set_state,             fun mst_ai_sys:set_state/1},
        {send_evt,              fun rm_user_evt:send_evt/1},
        {move,                  fun mst_ai_plug:move/1},
        {skill_segment,         fun mst_ai_plug:skill_segment/1},
        {move_to_near_player,   fun mst_ai_plug:move_to_near_player/0},
        {move_out_near_player,  fun mst_ai_plug:move_out_near_player/0},
        {turn_to_near_player,   fun mst_ai_plug:turn_to_near_player/0},
        {recursion_ai,          fun mst_ai_sys:recursion_ai/1},
        {back_ai,               fun mst_ai_sys:back_ai/0},
        {play_next_segment,     fun mst_ai_sys:play_next_segment/0},
        {move_to_born_x,        fun mst_ai_plug:move_to_born_x/0},
        {move_rand,             fun mst_ai_plug:move_rand/0}
    ]).

%% done
-define(ai_cfg_done,
    [
        {done_back_ai,          fun mst_ai_sys:back_ai/0}
    ]).
