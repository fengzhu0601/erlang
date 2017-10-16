%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 14. 九月 2015 上午5:32
%%%-------------------------------------------------------------------
-module(move_h_tgr).
-author("clark").

%% API
-export(
[
    start/4
    , stop/1
    , start_jump/4
    , start_freely_fall/1
    , is_run/1
]).

-export(
[
    handle_timer/2
]).


-include("inc.hrl").
-include("scene.hrl").
-include("scene_agent.hrl").


%% 匀速运动
start(#agent{move_vec = MV} = Agent, VariableH, Speed, Idx) ->
    MV1 = start(MV, VariableH, Speed, Idx),
    Agent#agent{move_vec = MV1};
start(MV, 0, _Speed, _Idx) -> MV;
start(MV, VariableH, Speed, Idx) ->
    stop(MV),
    MV#move_vec
    {
        h_timer = scene_eng:start_timer(?next_step_time(Speed), ?MODULE, {move_step_h, Idx}),
        h_speed = {?uniform_move, Speed},
        h_vec = VariableH
    }.

%% 匀减速运动
start_jump(#agent{move_vec = MV} = Agent, VariableH, Idx, JumpTm) ->
    MV1 = start_jump(MV, VariableH, Idx, JumpTm),
    Agent#agent{move_vec = MV1};
start_jump(MV, 0, _, _) -> MV;
start_jump(MV, VariableH, Idx, JumpTm) ->
    stop(MV),
%%    ?INFO_LOG("delay: ~p", [{freely_fall_speed:get(VariableH) + JumpTm}]),
    MV#move_vec
    {
        h_timer = scene_eng:start_timer(freely_fall_speed:get(VariableH) + JumpTm, ?MODULE, {move_step_h, Idx}),
        h_vec = VariableH,
        h_speed = {gravity_move, VariableH}
    }.


%% 开始下落
start_freely_fall(#agent{h = 0} = A) -> A;
start_freely_fall(#agent{idx = Idx, h = H, move_vec = _MV} = A) ->
    % ?assert(H > 0),
    case _MV#move_vec.h_speed of
        {?gravity_move, _} when _MV#move_vec.h_vec < 0 ->
            A;
        _ ->
            stop(_MV),
            MV = _MV#move_vec
            {
                h_timer = scene_eng:start_timer
                (
                    freely_fall_speed:get(1) + _MV#move_vec.hug_time,
                    ?MODULE,
                    {move_step_h, Idx}
                ),
                h_speed = {gravity_move, H},
                hug_time = 0,
                h_vec = - H
            },

            %% ?INFO_LOG("idx~p start fall h:~p now~p ", [Idx, H, com_time:timestamp_msec()]),
            NewAgent = A#agent{move_vec = MV},
            ?update_agent(Idx, NewAgent),
            NewAgent
    end.

stop(#agent{move_vec = MV} = Agent) ->
    MV1 = stop(MV),
    Agent#agent{move_vec = MV1};
stop(MV) ->
    scene_eng:cancel_timer(MV#move_vec.h_timer),
    MV#move_vec{h_timer = ?none}.

is_run(#agent{move_vec = MV} = _Agent) -> is_run(MV);
is_run(MV) -> scene_eng:is_wait_timer(MV#move_vec.h_timer).

%% ----------------------
%% private
%% ----------------------
handle_timer(_Ref, {move_step_h, Idx}) ->
    case ?get_agent(Idx) of
        #agent{} -> move_step_h(Idx, _Ref);
        _ -> ok
    end;

handle_timer(_Ref, {jump_hang_timeout, Idx}) ->
    start_freely_fall(?get_agent(Idx));

handle_timer(_Ref, Msg) ->
    ?ERROR_LOG("unknown msg ~p", [Msg]).


-spec move_step_h(_, _) -> no_return().
move_step_h(Idx, _Ref) ->
    #agent{h = _H, move_vec = _MV} = _A = ?get_agent(Idx),
    _VariableH = _MV#move_vec.h_vec,
    %% TODO

    HangTime = if
                   _VariableH > 0 ->
                       VariableH = _VariableH - 1,
                       H = _H + 1,
                       1;
                   true ->
                       VariableH = _VariableH + 1,
                       H = _H - 1,
                       0
               end,
    % ?Assert2(H >= 0, "oldh ~p h ~p VariableH:~p", [_H, H, _VariableH]),
%%    ?DEBUG_LOG("move_step_h ~p",[{_VariableH,_H,_MV}]),
    case VariableH of
        _ when H =:= 0 ->
            %%落地
            %% TODO 是否倒地
            fall_down(_A);

        0 when HangTime =:= 0 -> %% 到达顶点并且不需要滞空
            %% 开始下落
            %% 最后这一个还要有一个延迟78~0 的延迟
            start_freely_fall(_A#agent{h = H, move_vec = _MV#move_vec{h_vec = 0, h_timer = ?none}});

        0 -> %% HangTime =/=0
            %% 滞空
            ?assert(HangTime =/= 0 andalso H =/= 0),
            ?update_agent(Idx, _A#agent{h = H,
                move_vec = _MV#move_vec{h_vec = 0,
                    h_timer = scene_eng:start_timer(HangTime, ?MODULE, {jump_hang_timeout, Idx})
                }});

        _ when VariableH > 0 ->  %% 移动中
            case _MV#move_vec.h_speed of
                {?gravity_move, _OldVh} ->
                    ?update_agent(Idx, _A#agent
                    {
                        h = H,
                        move_vec = _MV#move_vec
                        {
                            h_vec = VariableH,
                            h_timer = scene_eng:start_timer(freely_fall_speed:get(VariableH), ?MODULE, {move_step_h, Idx})
                        }
                    });
                {?uniform_move, Speed} ->
                    ?update_agent(Idx, _A#agent
                    {
                        h = H,
                        move_vec = _MV#move_vec
                        {
                            h_vec = VariableH,
                            h_timer = scene_eng:start_timer(?next_step_time(Speed), ?MODULE, {move_step_h, Idx})
                        }
                    });
                _ -> pass
            end;

        _ when VariableH < 0 ->
            case _MV#move_vec.h_speed of
                {?gravity_move, FallH} -> %%下落时自由加速自由落体
                    T = freely_fall_speed:get(FallH - H + 1),
                    ?update_agent(Idx, _A#agent{h = H,
                        move_vec = _MV#move_vec{h_vec = VariableH,
                            h_timer = scene_eng:start_timer(T, ?MODULE, {move_step_h, Idx})}
                    });
                {?uniform_move, Speed} ->
%%                     ?INFO_LOG("h unifrom move h~p VariableH:~p ", [H, VariableH]),
                    ?update_agent(Idx, _A#agent{h = H,
                        move_vec = _MV#move_vec{h_vec = VariableH,
                            h_timer = scene_eng:start_timer(?next_step_time(Speed), ?MODULE, {move_step_h, Idx})}
                    });
                _ -> pass
            end
    end,

    debug:show_svr_pos(_A).

%% ---------------------------------
%% 落地
fall_down(#agent{idx = Idx, move_vec = _MV} = _A) ->
%%     ?INFO_LOG("idx ~p fall_down x_speed:~p ", [Idx, _MV#move_vec.cfg_speed]),
    MV =
        move_x_tgr:stop(
            move_y_tgr:stop
            (
                _MV#move_vec
                {
                    h_vec = 0,
                    h_timer = ?none,
                    x_speed = _MV#move_vec.cfg_speed,
                    y_speed = _MV#move_vec.cfg_speed
                }
            )),

    debug:show_svr_pos(_A),

    A = _A#agent{h = 0, move_vec = MV},
    if
        Idx < 0 -> %% 倒地起身
            A2 = A#agent{stiff_state = ?ss_down_ground_stiff},
            scene_eng:start_timer(350, scene_monster, {down_up, Idx}),
            ?update_agent(Idx, A2),
            A2;
        true ->
            ?update_agent(Idx, A),
            A
    end.
