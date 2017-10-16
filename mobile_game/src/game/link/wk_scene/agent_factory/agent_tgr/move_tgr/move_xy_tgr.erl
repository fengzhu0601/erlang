%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 14. 九月 2015 上午5:27
%%%-------------------------------------------------------------------
-module(move_xy_tgr).
-author("clark").

%% API
-export(
[
    start/4
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
-include("scene_event.hrl").
-include("porsche_event.hrl").

start(#agent{move_vec = MV} = Agent, Vx, Vy, Idx) ->
    MV1 = start(MV, Vx, Vy, Idx),
    Agent#agent{move_vec = MV1};
start(MV, Vx, Vy, Idx) ->
    stop(MV),
    if
        Vx =/= 0 andalso Vy =/= 0 ->
            Tm = ?next_45_angle_step_time(MV#move_vec.x_speed),
            MV#move_vec
            {
                x_timer = scene_eng:start_timer(Tm, ?MODULE, {move_step_xy, Idx, ?LINE}),
                x_vec = Vx,
                y_vec = Vy
            };

        Vx =/= 0 orelse Vy =/= 0 -> %% L,R,T,D
            MV#move_vec
            {
                x_timer = scene_eng:start_timer(?next_step_time(MV#move_vec.x_speed), ?MODULE, {move_step_xy, Idx, ?LINE}),
                x_vec = Vx,
                y_vec = Vy
            };

        true -> %% both == 0
            MV#move_vec
            {
                x_timer = ?none,
                x_vec = 0,
                y_vec = 0
            }
    end.

stop(#agent{move_vec = MV}) ->
    stop(MV);
stop(MV = #move_vec{}) ->
%%     ?INFO_LOG("move_xy_tgr stop"),
    MV1 = move_x_tgr:stop(MV),
    MV2 = move_y_tgr:stop(MV1),
    MV2.

is_run(#agent{move_vec = MV}) ->
    is_run(MV);
is_run(MV) ->
    move_x_tgr:is_run(MV)
        orelse move_x_tgr:is_run(MV).




%% ----------------------
%% private
%% ----------------------
handle_timer(_Ref, {move_step_xy, Idx, _LINE}) ->
%%     ?INFO_LOG("------------- move_step_xy idx ~p x_timer  ~p timeout", [Idx, _Ref]),
    ?assert(not scene_eng:is_wait_timer(_Ref)),
    move_step_xy(Idx, _Ref, _LINE);

handle_timer(_Ref, Msg) ->
    ?ERROR_LOG("unknown msg ~p", [Msg]).


move_step_xy(Idx, _Ref, _LINE) ->
    _A = ?get_agent(Idx),
    case _A of
        #agent{x = Ox, y = Oy, h = Oh, d = Od, move_vec = OrigMV} ->
            OrigRef = OrigMV#move_vec.x_timer,
            if
                OrigRef =/= ?none -> scene_eng:cancel_timer(OrigRef);
                true -> ok
            end,
            {Dx, IncX, MVx} = move_util:get_move_vec_to_next_x(OrigMV),
            {_Dy, IncY, MV} = move_util:get_move_vec_to_next_y(MVx), 
            NewPoint = {Ox + IncX, Oy + IncY, Oh},
            D = if
                Dx =:= ?D_NONE -> Od;
                true -> Dx
            end,
            case room_map:is_walkable(Idx, NewPoint) of
                ?false ->
                    A = map_aoi:stop_if_moving_and_notify(_A#agent{move_vec = MV}),
                    evt_util:send(#agent_move_over{idx=Idx}),
                    A;
                ?true ->
                    A = map_agent:set_position(_A#agent{move_vec = MV}, NewPoint, D),
                    ?assert(A#agent.move_vec =:= MV),
                    case move_util:is_move_over(MV) of
                        true ->
                            evt_util:send(#agent_move_over{idx=Idx}),
                            A;
                        false ->
                            MV1 = case MV#move_vec.x_vec =/= 0 andalso MV#move_vec.y_vec =/= 0 of
                                true ->
                                    MV#move_vec{x_timer = scene_eng:start_timer(?next_45_angle_step_time(MV#move_vec.x_speed), ?MODULE, {move_step_xy, Idx, ?LINE})};
                                _ ->
                                    MV#move_vec{x_timer = scene_eng:start_timer(?next_step_time(MV#move_vec.x_speed), ?MODULE, {move_step_xy, Idx, ?LINE})}
                            end,
                            A1 = A#agent{move_vec = MV1},
                            ?update_agent(Idx, A1),
                            %% cb
                            evt_util:send(#player_move{}),
                            % self() ! {event, ?PLAYER_MOVEING},
                            map_agent:move_step(A1)
                    end
            end;
        _ ->
            ?ERROR_LOG("unmatch idx ~p ", [Idx])
    end.
