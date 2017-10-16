%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 16. 九月 2015 下午9:41
%%%-------------------------------------------------------------------
-module(move_tgr_util).
-author("clark").

%% API
-export(
[
    stop_all_move_tgr/1
    , is_moving/1
    , is_relaxation/1
]).


-include("inc.hrl").
-include("scene.hrl").
-include("scene_agent.hrl").

stop_all_move_tgr(#agent{move_vec = MV} = Agent) ->
    MV1 = stop_all_move_tgr(MV),
    Agent#agent{move_vec = MV1};
stop_all_move_tgr(MV) ->
    MV1 = move_xy_tgr:stop(MV),
    MV2 = move_h_tgr:stop(MV1),
    MV3 = move_path_tgr:stop(MV2),

    ?assert(not scene_eng:is_wait_timer(MV3#move_vec.x_timer)),
    ?assert(not scene_eng:is_wait_timer(MV3#move_vec.y_timer)),
    ?assert(not scene_eng:is_wait_timer(MV3#move_vec.h_timer)),
    ?assert(not scene_eng:is_wait_timer(MV3#move_vec.skill_move_timer)),


    MV4 =
        move_util:create_move_vector
        ({
            MV3#move_vec.x_speed,
            MV3#move_vec.y_speed,
            MV3#move_vec.h_speed,
            MV3#move_vec.cfg_speed
        }),

    MV4.


%% is_moving(#move_vec{reason = ?none} = MV) ->
%%     ?assert(not move_x_tgr:is_run(MV)),
%%     ?assert(not move_y_tgr:is_run(MV)),
%%     ?assert(not move_h_tgr:is_run(MV)),
%%     ?assert(not move_path_tgr:is_run(MV)),
%%     false;
is_moving(#agent{move_vec = MV}) ->
    is_moving(MV);
is_moving(undefine) ->
    false;
is_moving(MV) ->
    move_x_tgr:is_run(MV) orelse move_y_tgr:is_run(MV) orelse move_h_tgr:is_run(MV) orelse move_path_tgr:is_run(MV).


is_relaxation_1(#move_vec{} = MV) ->
    case is_moving(MV) of
        false ->
%%             ?INFO_LOG("is_moving false"),
            case scene_eng:is_wait_timer(MV#move_vec.skill_move_timer) of
                true -> false;
                _ -> true
            end;

        true ->
%%             ?INFO_LOG("is_moving true"),
            false
    end.
is_relaxation(#agent{move_vec = MV} = A) ->
    case is_relaxation_1(MV) of
        true ->
            case scene_eng:is_wait_timer(A#agent.segment_cartoon_time) of
                true -> false;
                false -> true
            end;
        false -> false
    end;
is_relaxation(_) ->
    false.