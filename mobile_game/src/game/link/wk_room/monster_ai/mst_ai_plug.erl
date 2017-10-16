%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 21. 四月 2016 下午3:49
%%%-------------------------------------------------------------------
-module(mst_ai_plug).
-author("clark").

%% API
-export
([
    move/1,
%%     ai_air_stay_time/2,
    skill_segment/1,
    is_near_player_x/1,
    is_near_player_y/1,
    move_to_near_player/0,
    is_pass/1,
    move_out_near_player/0,
    turn_to_near_player/0,
    is_move_over/0,
    is_cd/1,
    is_near_born_x/1,
    move_to_born_x/0,
    move_rand/0,
    get_dir_to_agent/2,
    is_born_near_player_x/1
]).



-include("skill_struct.hrl").
-include("mst_ai_sys.hrl").
-include("inc.hrl").
-include("scene_agent.hrl").

-define(pd_ai_release_skill_time(Idx, SkillId), {pd_ai_release_skill_time, Idx, SkillId}).

-define(pd_ai_air_stay_time(Idx), {pd_ai_air_stay_time, Idx}).

% true 表示可以可以动作，false不能做任何的东西
%% is_air_stay_time(Idx) ->
%%     Now = com_time:timestamp_msec(),
%%     case get(?pd_ai_air_stay_time(Idx)) of
%%         ?undefined ->
%%             true;
%%         T ->
%%             if
%%                 Now - T >= 0 ->
%%                     true;
%%
%%                 true ->
%%                     ?INFO_LOG("========= is_air_stay_time ========="),
%%                     false
%%             end
%%     end.

move({MoveX, MoveY}) ->
    Idx = get_cur_idx(),
    case ?get_agent(Idx) of
        A when is_record(A, agent) ->
%%             ?INFO_LOG("move ~p", [{MoveX, MoveY}]),
            pl_util:move(A, {MoveX, MoveY});
        _ ->
            pass
    end,
    ok.

%% ai_air_stay_time(Idx, Time) ->
%%     Now = com_time:timestamp_msec(),
%%     put(?pd_ai_air_stay_time(Idx), Now + Time),
%%     ok.

%% 走向最近玩家
move_to_near_player() ->
    Idx = get_cur_idx(),
    case ?get_agent(Idx) of
        A when is_record(A, agent) ->
            X = A#agent.x,
            Y = A#agent.y,
            case room_system:get_near_pos_player({X, Y}) of
                #agent{x = PlayerX, y = PlayerY} ->
                    RandX = com_util:random(2, 3),
                    RandY = com_util:random(-1, 1),
                    case get_dir_to_agent(X, PlayerX) of
                        ?D_L -> move({PlayerX - X + RandX, PlayerY - Y + RandY});
                        _ -> move({PlayerX - X - RandX, PlayerY - Y + RandY})
                    end;

                _ ->
                    pass
            end;

        _ ->
            pass
    end,
    ok.

%% 走离最近玩家
move_out_near_player() ->
    Idx = get_cur_idx(),
    case ?get_agent(Idx) of
        A when is_record(A, agent) ->
            X = A#agent.x,
            Y = A#agent.y,
            case room_system:get_near_pos_player({X, Y}) of
                #agent{x = PlayerX} ->
                    RandX = com_util:random(3, 6),
                    RandY = com_util:random(-5, 5),
                    case get_dir_to_agent(X, PlayerX) of
                        ?D_L -> move({RandX, RandY});
                        _ -> move({-RandX, RandY})
                    end;

                _ ->
                    pass
            end;

        _ ->
            pass
    end,
    ok.

skill_segment(SkillSegmentId) when is_atom(SkillSegmentId) ->
%%     ?INFO_LOG("SkillSegmentId ~p", [SkillSegmentId]),
    Idx = get_cur_idx(),
    case mst_ai_sys:get_ai_field_by_cfg(Idx, SkillSegmentId) of
        nil -> pass;
        {Segment, Skill} -> skill_segment({Segment, Skill})
    end;

skill_segment({Segment, Skill}) ->
%%     ?INFO_LOG("skill_segment Segment, Skill ~p", [{Segment, Skill}]),
    Idx = get_cur_idx(),
    case ?get_agent(Idx) of
        A = #agent{x = X, y = Y} ->
            case room_system:get_near_pos_player({X, Y}) of
                #agent{x = PlayerX} ->
                    Now = com_time:timestamp_msec(),
                    Cd = load_cfg_skill:lookup_skill_cfg(Segment, #skill_cfg.cd),
                    IsCdPassed =
                        case get(?pd_ai_release_skill_time(Idx, Segment)) of
                            ?undefined ->
                                true;
                            T ->
                                Now - T >= Cd
                        end,

                    if
                        IsCdPassed =:= ?false ->
                            pass;

                        true ->
                            put(?pd_ai_release_skill_time(Idx, Segment), Now),
                            % buff_system:apply_init(A, Skill),
                            AttackPlug = pl_fsm:build_plug(?pl_attack),
%%                             ?DEBUG_LOG("attack pos:~p",[{Idx,A#agent.x, A#agent.y, A#agent.h}]),
                            PlugList = [{AttackPlug, {Skill, Segment, get_dir_to_agent(A#agent.x, PlayerX), A#agent.x, A#agent.y, A#agent.h}}],
                            pl_fsm:set_state(A, PlugList)
                    end;

                _ ->
                    pass
            end;
        _ ->
            pass
    end,
    ok.


get_dir_to_agent(SelfX, ObjX) ->
    if
        SelfX > ObjX -> ?D_L;
        true -> ?D_R
    end.

turn_to_near_player() ->
    Idx = get_cur_idx(),
    case ?get_agent(Idx) of
        #agent{x = X, y = Y} ->
            case room_system:get_near_pos_player({X, Y}) of
                #agent{x = PlayerX} ->
                    case get_dir_to_agent(X, PlayerX) of
                        ?D_L -> move({-1, 0});
                        _ -> move({1, 0})
                    end;

                _E ->
                    false
            end;

        _E1 ->
            false
    end.

is_near_born_x({MinR, MaxR}) when is_atom(MaxR) ->
    Idx = get_cur_idx(),
    case mst_ai_sys:get_ai_field_by_cfg(Idx, MaxR) of
        nil -> false;
        MaxR1 -> is_near_born_x({MinR, MaxR1})
    end;
is_near_born_x({MinR, MaxR}) ->
%%     ?INFO_LOG("is_near_born_x 1 ~p", [{MinR, MaxR}]),
    Idx = get_cur_idx(),
    case ?get_agent(Idx) of
        #agent{x = X, born_x = BX} ->
            if
                X >= (BX + MinR) andalso X =< (BX + MaxR) -> true;
                X >= (BX - MaxR) andalso X =< (BX - MinR) -> true;
                true -> false
            end;

        _E1 ->
            false
    end.

move_to_born_x() ->
    Idx = get_cur_idx(),
    case ?get_agent(Idx) of
        A when is_record(A, agent) ->

            X = A#agent.x,
            Y = A#agent.y,
            BornX = A#agent.born_x,
            BornY = A#agent.born_y,
%%             ?INFO_LOG("move_to_born_x ~p", [{BornX - X, BornY - Y}]),
            move({BornX - X, BornY - Y});

        _ ->
            pass
    end,
    ok.


move_rand() ->
    Idx = get_cur_idx(),
    case ?get_agent(Idx) of
        A when is_record(A, agent) ->
%%             ?INFO_LOG("move_rand"),
            RandX = com_util:random(-5, 5),
            move({RandX, 0});

        _ ->
            pass
    end,
    ok.

is_born_near_player_x({MinR, MaxR}) when is_atom(MaxR) ->
    Idx = get_cur_idx(),
    case mst_ai_sys:get_ai_field_by_cfg(Idx, MaxR) of
        nil -> false;
        MaxR1 -> is_born_near_player_x({MinR, MaxR1})
    end;

is_born_near_player_x({MinR, MaxR}) ->
    Idx = get_cur_idx(),
    case ?get_agent(Idx) of
        #agent{born_x = X, born_y = Y} ->
            case room_system:get_near_pos_player({X, Y}) of
                #agent{x = PlayerX} ->
                    if
                        X >= (PlayerX + MinR) andalso X =< (PlayerX + MaxR) ->
%%                             ?INFO_LOG("is_born_near_player_x true ~p", [{PlayerX, X, MinR, MaxR}]),
                            true;
                        X >= (PlayerX - MaxR) andalso X =< (PlayerX - MinR) ->
%%                             ?INFO_LOG("is_born_near_player_x true ~p", [{PlayerX, X, MinR, MaxR}]),
                            true;
                        true ->
                            false
                    end;

                _E ->
                    false
            end;

        _E1 ->
            false
    end.



is_near_player_x({MinR, MaxR}) when is_atom(MaxR) ->
    Idx = get_cur_idx(),
    case mst_ai_sys:get_ai_field_by_cfg(Idx, MaxR) of
        nil -> false;
        MaxR1 ->
%%             ?INFO_LOG("is_near_player_x MaxR1 ~p", [MaxR1]),
            is_near_player_x({MinR, MaxR1})
    end;



is_near_player_x({MinR, MaxR}) ->
%%     ?INFO_LOG("is_near_player_x 1 ~p", [{MinR, MaxR}]),
    Idx = get_cur_idx(),
    case ?get_agent(Idx) of
        #agent{x = X, y = Y} ->
            case room_system:get_near_pos_player({X, Y}) of
                #agent{x = PlayerX} ->
                    if
                        X >= (PlayerX + MinR) andalso X =< (PlayerX + MaxR) -> true;
                        X >= (PlayerX - MaxR) andalso X =< (PlayerX - MinR) -> true;
                        true -> false
                    end;

                _E ->
                    false
            end;

        _E1 ->
            false
    end.

is_near_player_y({MinR, MaxR}) ->
    Idx = get_cur_idx(),
    case ?get_agent(Idx) of
        #agent{x = X, y = Y} ->
            case room_system:get_near_pos_player({X, Y}) of
                #agent{y = PlayerY} ->
                    if
                        Y >= (PlayerY + MinR) andalso Y =< (PlayerY + MaxR) -> true;
                        Y >= (PlayerY - MaxR) andalso Y =< (PlayerY - MinR) -> true;
                        true -> false
                    end;

                _E ->
                    false
            end;

        _E1 ->
            false
    end.

is_pass(Rand) ->
    CurRand = com_util:random(1, 100),
    if
        Rand =< CurRand -> true;
        true -> false
    end.


get_cur_idx() ->
    {_, IdxSrc} = porsche_gearbox:get_cur_porschekey(),
    if
        IdxSrc == nil -> 0;
        true -> IdxSrc
    end.


is_move_over() ->
    Idx = get_cur_idx(),
    case ?get_agent(Idx) of
        #agent{move_vec = MV} ->
            move_util:is_move_over(MV);

        _ ->
            false
    end.

is_cd(Dt) ->
    case porsche_gearbox:get_cur_func_data(?FUNC_DATA_CD) of
        nil ->
            porsche_gearbox:set_cur_func_data(?FUNC_DATA_CD, com_time:timestamp_msec()),
            true;

        OldTime ->
            NewTime = com_time:timestamp_msec(),
            CurDt = NewTime - OldTime,
            if
                CurDt >= Dt ->
                    porsche_gearbox:set_cur_func_data(?FUNC_DATA_CD, NewTime),
                    true;

                true ->
                    false
            end
    end.





