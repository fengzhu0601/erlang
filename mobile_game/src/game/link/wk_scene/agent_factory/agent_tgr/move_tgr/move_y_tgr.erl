%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 14. 九月 2015 上午5:20
%%%-------------------------------------------------------------------
-module(move_y_tgr).
-author("clark").

%% API
-export(
[
    start/3
    , stop/1
    , is_run/1
]).

-export(
[
    handle_timer/2
]).


-include("inc.hrl").
-include("scene.hrl").
-include("scene_agent.hrl").


start(#agent{move_vec = MV} = Agent, VariableY, Idx) ->
    MV1 = start(MV, VariableY, Idx),
    Agent#agent{move_vec = MV1};
start(MV, Vy, Idx) ->
    ?assert(MV#move_vec.y_speed /= 0),

    scene_eng:cancel_timer(MV#move_vec.y_timer),
    ?assert(not scene_eng:is_wait_timer(MV#move_vec.y_timer)),

    if
        Vy =:= 0 ->
            MV#move_vec{y_timer = ?none, y_vec = 0};

        true ->
            MV#move_vec
            {
                y_timer = scene_eng:start_timer(?next_step_time(MV#move_vec.y_speed), ?MODULE, {move_step_y, Idx}),
                y_vec = Vy
            }
    end.

stop(#agent{move_vec = MV} = Agent) ->
    MV1 = stop(MV),
    Agent#agent{move_vec = MV1};
stop(MV = #move_vec{}) ->
    if
        MV#move_vec.y_timer =/= ?none -> scene_eng:cancel_timer(MV#move_vec.y_timer);
        true -> ok
    end,
    ?assert(not scene_eng:is_wait_timer(MV#move_vec.y_timer)),
    MV#move_vec{y_timer = ?none}.


is_run(#agent{move_vec = MV}) ->
    is_run(MV);
is_run(MV) ->
    scene_eng:is_wait_timer(MV#move_vec.y_timer).



%% ----------------------
%% private
%% ----------------------

handle_timer(_Ref, {move_step_y, Idx}) ->
%%     ?INFO_LOG("move_step_y idx ~p x_timer  ~p timeout", [Idx, _Ref]),
    move_step_y(Idx, _Ref);

handle_timer(_Ref, Msg) ->
    ?ERROR_LOG("unknown msg ~p", [Msg]).


move_step_y(Idx, _Ref) ->
    _A = ?get_agent(Idx),
    case _A of
        #agent{x = Ox, y = Oy, h = Oh, move_vec = _MV} ->
            {D, Inc, MV} = move_util:get_move_vec_to_next_y(_MV),
            NewPoint = {Ox, Oy + Inc, Oh},

            case room_map:is_walkable(Idx, NewPoint) of
                ?false ->
%%                     ?ERROR_LOG("idx move point ~p nonwalkable ~p", [Idx, NewPoint]),
                    A = map_aoi:stop_if_moving_and_notify(_A#agent{move_vec = MV}),
%%                     fsm:fire_state_over_evt(A, ?st_new_move);
                    A;

                ?true ->
                    A = map_agent:set_position(_A#agent{move_vec = MV}, NewPoint, D),

                    case move_util:is_move_over(MV) of
                        true ->
%%                             fsm:fire_state_over_evt(A, ?st_new_move);
                            A;
                        false ->
                            if MV#move_vec.y_vec =/= 0 ->
                                MV1 = MV#move_vec{y_timer =
                                scene_eng:start_timer(?next_step_time(MV#move_vec.y_speed),
                                    ?MODULE,
                                    {move_step_y, Idx})},
                                A1 = A#agent{move_vec = MV1},
                                ?update_agent(Idx, A1);
                                true ->
                                    A1 = A
                            end,

                            %% cb
                            if Idx > 0 -> scene_player:move_step(A1);
                                true -> scene_monster:move_step(A1)
                            end
                    end
            end;
        % #agent{move_vec = _MV} -> %% TODO fix bug
        %     ?ERROR_LOG("timer line not match ~p ~p", [_Ref, _MV#move_vec.y_timer]);
        _ ->
            ?ERROR_LOG("unmatch idx ~p ", [Idx])
    end.