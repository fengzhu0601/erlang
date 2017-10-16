%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 14. 九月 2015 上午5:10
%%%-------------------------------------------------------------------
-module(move_util).
-author("clark").

%% API
-export(
[
    move_offset/5
    , create_move_vector/1
    , get_move_vec_to_next_x/1
    , get_move_vec_to_next_y/1
    , is_move_over/1
]).


-include("inc.hrl").
-include("scene.hrl").
-include("scene_agent.hrl").

create_move_vector({XSpeed, YSpeed, HSpeed, BSpeed}) ->
%%     ?Assert2(is_integer(XSpeed), "xspeed ~p", [XSpeed]),
%%     ?Assert2(is_integer(YSpeed), "yspeed ~p", [YSpeed]),
    #move_vec
    {
        x_speed = XSpeed,
        y_speed = YSpeed,
        h_speed = HSpeed,
        cfg_speed = BSpeed,
        reason = ?none
    }.


move_offset(?D_L, Ox, Oy, X, Y) ->
    {Ox - X, Oy + Y};
move_offset(_, Ox, Oy, X, Y) ->
    {Ox + X, Oy + Y}.

get_move_vec_to_next_x(MV) ->
    Xv = MV#move_vec.x_vec,
    ?assert(not scene_eng:is_wait_timer(MV#move_vec.x_timer)),

    if
        abs(Xv) =:= ?KEEP_MOVEING ->
            ?if_else
            (
                Xv > 0,
                {?D_R, 1, MV#move_vec{x_timer = ?none}},
                {?D_L, -1, MV#move_vec{x_timer = ?none}}
            );
        Xv > 1 ->
            {?D_R, 1, MV#move_vec{x_vec = Xv - 1, x_timer = ?none}};
        Xv =:= 1 ->
            {?D_R, 1, MV#move_vec{x_vec = 0, x_timer = ?none}};
        Xv =:= -1 ->
            {?D_L, -1, MV#move_vec{x_vec = 0, x_timer = ?none}};
        Xv < -1 ->
            {?D_L, -1, MV#move_vec{x_vec = Xv + 1, x_timer = ?none}};
        true ->
            {?D_NONE, 0, MV}
    end.

get_move_vec_to_next_y(MV) ->
    Yv = MV#move_vec.y_vec,
    ?assert(not scene_eng:is_wait_timer(MV#move_vec.y_timer)),


    if abs(Yv) =:= ?KEEP_MOVEING ->
        ?if_else(Yv > 0,
            {?D_R, 1, MV#move_vec{y_timer = ?none}},
            {?D_L, -1, MV#move_vec{y_timer = ?none}});
        Yv > 1 ->
            {?D_U, 1, MV#move_vec{y_vec = Yv - 1, y_timer = ?none}};
        Yv =:= 1 ->
            {?D_U, 1, MV#move_vec{y_vec = 0, y_timer = ?none}};
        Yv =:= -1 ->
            {?D_D, -1, MV#move_vec{y_vec = 0, y_timer = ?none}};
        Yv < -1 ->
            {?D_D, -1, MV#move_vec{y_vec = Yv + 1, y_timer = ?none}};
        true ->
            {?D_NONE, 0, MV}
    end.


is_move_over(#move_vec{x_vec = 0, y_vec = 0, h_vec = 0}) ->
    true;
is_move_over(_) ->
    false.


