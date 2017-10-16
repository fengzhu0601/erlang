%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 28. 十一月 2015 下午3:45
%%%-------------------------------------------------------------------
-author("clark").





-record(segments_cfg,
{
    id = 0
    , action
    , repeat_count
    , target_type
    , buffs
    , can_break_by_enemy
    , attack_rigid_time
    , hit_rigid_time
    , beat_vector
    , direction_mode
    , beat_air_stay_time
    , shake
    , time
    , beat_back_time
    , back_rigid_time
    , attack_depth
    , emits
    , damage_coef
    , sounds
    , client_has_calc_hit_info
}).
