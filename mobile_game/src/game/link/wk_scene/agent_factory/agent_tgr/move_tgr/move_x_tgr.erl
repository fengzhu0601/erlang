%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 14. 九月 2015 上午5:09
%%%-------------------------------------------------------------------
-module(move_x_tgr).
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
-include("porsche_event.hrl").




-define(min_x_speed, 60).

start(#agent{move_vec = MV} = Agent, VariableX, Idx) ->
    MV1 = start(MV, VariableX, Idx),
    Agent#agent{move_vec = MV1};
start(#move_vec{x_speed = CurXSpeed} = MV, VariableX, Idx) ->
    ?assert(?is_pos_integer(CurXSpeed)),
    MV1 = stop(MV),
    if
        VariableX =:= 0 ->
            MV1#move_vec{x_timer = ?none, x_vec = 0};

        true ->
            XSpeed =
                if
                    CurXSpeed =< ?min_x_speed -> ?min_x_speed;
                    true -> CurXSpeed
                end,
            Tref = scene_eng:start_timer(?next_step_time(XSpeed), ?MODULE, {move_step_x, Idx, ?LINE}),
            MV1#move_vec{x_timer = Tref, x_speed = XSpeed, x_vec = VariableX}
    end.

stop(#agent{move_vec = MV} = Agent) ->
    MV1 = stop(MV),
    Agent#agent{move_vec = MV1};
stop(MV = #move_vec{}) ->
%%     ?INFO_LOG("stop x tgr"),
    if
        MV#move_vec.x_timer =/= ?none -> scene_eng:cancel_timer(MV#move_vec.x_timer);
        true -> ok
    end,
    ?assert(not scene_eng:is_wait_timer(MV#move_vec.x_timer)),
    MV#move_vec{x_timer = ?none}.


is_run(#agent{move_vec = MV}) ->
    is_run(MV);
is_run(MV) ->
    scene_eng:is_wait_timer(MV#move_vec.x_timer).


%% ----------------------
%% private
%% ----------------------


handle_timer(_Ref, {move_step_x, Idx, _LINE}) ->
%%     ?INFO_LOG("move_step_x idx ~p x_timer  ~p timeout", [Idx, _Ref]),
    ?assert(not scene_eng:is_wait_timer(_Ref)),
    move_step_x(Idx, _Ref, _LINE);

handle_timer(_Ref, Msg) ->
    ?ERROR_LOG("unknown msg ~p", [Msg]).


move_step_x(Idx, _Ref, _LINE) ->
    _A = ?get_agent(Idx),

    case _A of
        #agent{x = Ox, y = Oy, h = Oh, move_vec = _MV} ->
            {NewD, NewInc, NewMV} = move_util:get_move_vec_to_next_x(_MV),
            NewPoint = {Ox + NewInc, Oy, Oh},

%%            ?INFO_LOG("move ======= ~p",[{NewPoint,NewD}]),

            case room_map:is_walkable(Idx, NewPoint) of
                ?false ->
                    A = map_aoi:stop_if_moving_and_notify(_A#agent{move_vec = NewMV}),
%%                     fsm:fire_state_over_evt(A, ?st_new_move);
                    evt_util:send(#agent_move_over{idx = Idx}),
                    A;

                ?true ->
                    A = map_agent:set_position(_A#agent{move_vec = NewMV}, NewPoint, NewD),
                    ?assert(A#agent.move_vec =:= NewMV),

                    case move_util:is_move_over(NewMV) of
                        true ->
%%                             fsm:fire_state_over_evt(A, ?st_new_move);
%%                             ?INFO_LOG("agent_move_over ~p", [Idx]),
                            evt_util:send(#agent_move_over{idx = Idx}),
                            A;

                        false ->
                            if
                                NewMV#move_vec.x_vec =/= 0 ->
                                    %% start move timer
                                    MV1 = NewMV#move_vec
                                    {
                                        x_timer = scene_eng:start_timer
                                        (
                                            ?next_step_time(NewMV#move_vec.x_speed),
                                            ?MODULE,
                                            {move_step_x, Idx, ?LINE}
                                        )
                                    },
                                    A1 = A#agent{move_vec = MV1},
                                    ?update_agent(Idx, A1);
                                true ->
                                    A1 = A
                            end,

                            %% cb
                            map_agent:move_step(A1)
                    end
            end;
        % #agent{move_vec = _MV} -> %% TODO fix bug
        %     ?ERROR_LOG("idx ~p timer line not match ~p ~p ~p", [Idx, _LINE, _Ref, _MV#move_vec.x_timer]);
        _ ->
            ?ERROR_LOG("unmatch idx ~p ", [Idx])
    end.