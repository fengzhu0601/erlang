%%%-------------------------------------------------------------------
%%% @author zl
%%% @doc
%%%      默认AI
%%%      a FSM AI 
%%%      所有的状态都要处理　event_start, event_leave
%%%      
%%%      执行event_start 时传入的A还是旧的状态,可以用于检查允许从哪些
%%%      　　　状态转换到当前状态
%%%      
%%%      执行 event_leave 必须返回一个agent()
%%%
%%%      TODO register event
%%%           stop ai/ resume ai
%%%           
%%%           加入一个僵直状态
%%% @end
%%%-------------------------------------------------------------------

-module(monster_ai_default).

-include("inc.hrl").
-include("skill_struct.hrl").
-include("load_spirit_attr.hrl").

-include("scene.hrl").
-include("scene_agent.hrl").
-include("scene_monster.hrl").
-include("monster_ai.hrl").

-export([
    st_stand/3
    , st_stroll/3
    , st_stroll_wait/3
    , st_back/3
    , st_chase/3
    , st_fight/3
    , st_reaction/3
]).

%% cb
-export([handle_timer/2]).


-define(RELEASE_SKILL_RANGE, 3).


action(Event, A) ->
    action(Event, nil, A).

action(Event, EventArg, A) ->
    ?debug_log_monster_ai("~p ~p ~p", [A#agent.idx, A#agent.state, Event]),
    ?MODULE:(A#agent.state)(Event, EventArg, A).


st_stand(?event_start, _, A) ->
    ?assert(?undefined =:= ?get_m_enemy(A#agent.idx)),
    %%?assert(A#agent.state =/= ?st_stand),
    ?update_agent(A#agent.idx, A#agent{state = ?st_stand});  %% do nothing
st_stand(?event_leave, _, A) ->
    A;
st_stand(?event_has_enemy, _, A) ->
    has_enemy(A);
st_stand(?event_beat_back_stiff_end, _, A) ->
    has_enemy(A);
st_stand(?event_stiff_end, _, A) ->
    ?change_st(?st_reaction, 800, A, <<"event_stiff_end">>);
st_stand(_Event, _Arg, _A) ->
    ?ERROR_LOG("idx ~p unknow event ~p arg ~p st ~p", [_A#agent.idx, _Event, _Arg, _A#agent.state]).

%% 等待5秒开始移动
st_stroll_wait(?event_start = _Event, nil, #agent{idx = Idx, id = Id, state = _St} = A) ->
    ?assert(?undefined =:= ?get_m_enemy(A#agent.idx)),
    %%?assert(St =:= ?st_stroll orelse St = ),
    %%?assert(undefined =:= scene_monster:del_m_enemy(Idx)),
    case check_has_enemy(A) of
        ?none ->
            %%?assert(?none =:= A#agent.move),
            Cfg = erlang:get(?pd_monster_cfg(Id)),

            case Cfg#monster_cfg.stroll_range of
                0 ->
                    ?change_st(?st_stand, nil, A, <<"stroll_range is 0">>);
                _ ->
                    Ref = scene_eng:start_timer((?random(3) + 1) * 1000, ?MODULE, {?event_stroll_wait_timeout, Idx}),
                    ?update_agent(Idx, A#agent{state_timer = Ref, state = ?st_stroll_wait})
            end;
        {idx, EIdx} ->
            NewA = A#agent{state = ?st_stroll_wait},
            ?update_agent(Idx, NewA),
            has_enemy(NewA, EIdx);
        EA ->
            ?debug_log_monster_ai("idx ~p check_has_enemy find enemy ~p", [A#agent.idx, EA#agent.idx]),
            put(?pd_m_enemy(Idx), EA#agent.idx),
            fight_or_chase_or_back(A#agent{state_timer = ?none, state = ?st_stroll_wait}, EA, <<"check has enemy">>)
    end;
st_stroll_wait(?event_start = _Event, Time, #agent{idx = Idx} = A) ->
    Ref = scene_eng:start_timer(Time, ?MODULE, {?event_stroll_wait_timeout, Idx}),
    ?update_agent(Idx, A#agent{state_timer = Ref, state = ?st_stroll_wait});
st_stroll_wait(?event_leave, _, A) ->
    case A#agent.state_timer of
        ?none ->
            A;
        TRef ->
            scene_agent:cancel_state_timer(TRef),
            ?assert(not scene_eng:is_wait_timer(TRef)),
            A#agent{state_timer = ?none}
    end;
st_stroll_wait(?event_has_enemy, _, A) ->
    has_enemy(A);
st_stroll_wait(?event_stiff_end, _, A) ->
    ?change_st(?st_reaction, 800, A, <<"event_stiff_end">>);
st_stroll_wait(?event_beat_back_stiff_end, _, A) ->
    ?change_st(?st_reaction, 800, A, <<"event_stiff_end">>);
st_stroll_wait(?event_stroll_wait_timeout, nil, A) ->
    %% TODO 可以据需保持wait, 但是要 check_has_enemy 会更好看的

    case A#agent.stiff_state of
        ?ss_stiff ->
            ?debug_log_monster_ai("idx ~p event_stroll_wait_timeout but in ss_stiff wait stiff over", [A#agent.idx]),
            ok; %% 等待stiif_timer 结束
        ?ss_beat_back_stiff ->
            ?debug_log_monster_ai("idx ~p event_stroll_wait_timeout but in ss_beat_back_stiff wait stiff over", [A#agent.idx]),
            ok; %% 等待stiif_timer 结束
        _ ->
            case check_has_enemy(A) of
                ?none ->
                    ?change_st(?st_stroll, nil, A#agent{state_timer = ?none}, <<"timeout and not find enemy">>);
                {idx, EIdx} ->
                    has_enemy(A#agent{state_timer = ?none}, EIdx);
                EA ->
                    ?debug_log_monster_ai("idx ~p check_has_enemy find enemy ~p", [A#agent.idx, EA#agent.idx]),
                    scene_monster:set_m_enemy(A#agent.idx, EA#agent.idx),
                    fight_or_chase_or_back(A#agent{state_timer = ?none}, EA, <<"check has enemy">>)
            end
    end;
%%st_stroll_wait(?event_release_skill, {SkillId, D}, A) -> 
%%?change_st(?st_fight, {SkillId, D}, A, <<"event_release_skill">>);

st_stroll_wait(?event_release_skill_over, _, A) ->
    A;
st_stroll_wait(_Event, _Arg, _A) ->
    ?ERROR_LOG("idx ~p unknow event ~p arg ~p st ~p", [_A#agent.idx, _Event, _Arg, _A#agent.state]).


st_stroll(?event_start, _, #agent{idx = Idx} = A) ->
    ?assert(A#agent.state =/= ?st_stroll),
    ?assert(?undefined =:= ?get_m_enemy(A#agent.idx)),
    ?Assert(Idx < 0, "bad idx"),
    ?assert(A#agent.h =:= 0),


    %%StrollSpeed = Cfg#monster_cfg.speed,

    %%case scene_map:direct_path(X, Y, DestX, DestY, [], StrollRange) of
    %%{[], _,_} ->
    %%?debug_log_monster_ai("can not find path ~p ~p", [{X,Y}, {DestX, DestY}]),
    %%%%st_stroll_wait(?event_start, nil,
    %%?change_st(?st_stroll_wait, nil, A, <<"can not find path ">>);
    %%{Steps,_,_} ->
    %%%%scene_aoi:move_with_path_and_notify(A#agent{speed=StrollSpeed, state=?st_stroll}, Steps)
    %%end;

    MoveVec = random_stroll_move_vec(A),
    ?debug_log_monster_ai("idx ~p stroll move vecter ~p", [Idx, MoveVec]),

    ?debug_log_monster_ai("xxxxx"),
    {X1, Y1, _H1} = MoveVec,
    pl_util:move(A, {X1, Y1});

st_stroll(?event_leave, nil, A) ->
    map_aoi:stop_if_moving(A);
st_stroll(?event_move_step, _, _A) ->
    %%?debug_log_monster_ai("monster move step p ~p", [{_A#agent.x, _A#agent.y}]),
    ok;
st_stroll(?event_move_over, _, A) ->
    case ?get_m_enemy(A#agent.idx) of %% TODO why there has enemy ??
        ?undefined ->
            %%?debug_log_monster_ai("idx ~p stroll move over check_has_enemy", [A#agent.idx]),
            case check_has_enemy(A) of
                ?none ->
                    ?change_st(?st_stroll_wait, nil, A, <<"move over and not find enemy">>);
                {idx, EIdx} ->
                    has_enemy(A, EIdx);
                EA ->
                    ?debug_log_monster_ai("idx ~p check_has_enemy find enemy ~p", [A#agent.idx, EA#agent.idx]),
                    scene_monster:set_m_enemy(A#agent.idx, EA#agent.idx),
                    fight_or_chase_or_back(A#agent{state_timer = ?none}, EA, <<"check has enemy">>)
            end;
        EIdx ->
            has_enemy(A, EIdx)
    end;
st_stroll(?event_stiff_end, _, A) ->
    ?change_st(?st_reaction, 800, A, <<"event_stiff_end">>);
st_stroll(?event_beat_back_stiff_end, _, A) ->
    ?change_st(?st_reaction, 800, A, <<"event_stiff_end">>);
st_stroll(?event_has_enemy, _, A) ->
    has_enemy(A);

st_stroll(_Event, _Arg, _A) ->
    ?ERROR_LOG("idx ~p unknow event ~p arg ~p st ~p", [_A#agent.idx, _Event, _Arg, _A#agent.state]).


st_fight(?event_start, {SkillId, D}, A) ->
    %%?assert(A#agent.state =/= ?st_fight),
    ?assert(A#agent.state_timer =:= ?none),
    monster_skill_mng:release_skill(A#agent.idx, SkillId),
    ?update_agent(A#agent.idx, A#agent{state = ?st_fight}),
    scene_fight:release_skill(A#agent{state = ?st_fight}, SkillId, D, A#agent.x, A#agent.y, A#agent.h);
st_fight(?event_leave, _, A) ->
    A;
st_fight(?event_release_skill_over, _SkillId, A) ->
    case A#agent.stiff_state of
        ?ss_stiff ->
            ok; %% 等待stiif_timer 结束
        ?ss_beat_back_stiff ->
            ok; %% 等待stiif_timer 结束
        _ ->
            ?change_st(?st_reaction, 0, A#agent{state_timer = ?none}, <<"skill release_over">>)
    end;
st_fight(?event_stiff_end, _, A) ->
    ?change_st(?st_reaction, 800, A#agent{state_timer = ?none}, <<"event_stiff_end">>);
st_fight(?event_beat_back_stiff_end, _, A) ->
    ?change_st(?st_reaction, 800, A#agent{state_timer = ?none}, <<"event_beat_back_stiff_end">>);
st_fight(?event_release_skill, {SkillId, D}, A) ->
    ?assert(A#agent.state_timer =:= ?none),
    monster_skill_mng:release_skill(A#agent.idx, SkillId),
    scene_fight:release_skill(A, SkillId, D, A#agent.x, A#agent.y, A#agent.h);
st_fight(_Event, _Arg, _A) ->
    ?WARN_LOG("idx ~p unknow event ~p arg ~p st ~p", [_A#agent.idx, _Event, _Arg, _A#agent.state]).


st_chase(?event_start, {MoveVec, _MCfg}, A) ->
    %%?assert(A#agent.state =/= ?st_chase), %% 可以是追击
    ?assert(A#agent.stiff_state =/= ?ss_stiff),
    %% XXX BUG 
    ?assert(A#agent.stiff_state =/= ?ss_beat_back_stiff),

    %% TODO speed change
    %%scene_aoi:move_with_path_and_notify(A#agent{state=?st_chase}, Steps);
    %%
    ?debug_log_monster_ai("xxxxx"),
    {X1, Y1, _H1} = MoveVec,
    pl_util:move(A, {X1, Y1});


st_chase(?event_leave, _, A) ->
    %% TODO speed
    %%scene_aoi:stop_if_moving_and_notify(A#agent{speed=A#agent.attr#attr.move_speed});
    map_aoi:stop_if_moving_and_notify(A);

st_chase(?event_has_enemy, _, A) ->
    has_enemy(A);

st_chase(?event_move_step, nil, #agent{idx = Idx, x = X, y = Y} = A) ->
    case ?get_agent(get(?pd_m_enemy(Idx))) of
        ?undefined ->
            ?change_st(?st_back, nil, A, <<"can not find enemy">>);
        #agent{state = ?st_die} ->
            ?change_st(?st_back, nil, A, <<"enemy die">>);
        #agent{x = Ex, y = Ey} ->
            %% TODO  调动频率很快,缓存, lookup_monster_cfg
            Cfg = get(?pd_monster_cfg(A#agent.id)),
            %%{BornX, BornY, _} =
            case get(?pd_monster_born(A#agent.pid)) of
                {BornX, BornY, _} -> ok;
                undefined ->
                    ?ERROR_LOG("monster ~p can not find monster_cfg ~p", [Idx, {A#agent.pid, A#agent.id}]),
                    BornX = X,
                    BornY = Y
            end,
            case is_out_range({X, Y}, {BornX, BornY}, Cfg#monster_cfg.back_range) of
                true ->
                    ?change_st(?st_back, nil, A, <<"is_out_back_range">>);
                false ->
                    %% XXX 优化性能消耗太大
                    %% 只有和敌人y 方向相差+- 3 格才判断是否可以攻击
                    %%if Y =:= Ey ->
                    case monster_skill_mng:get_releaseable_skill(Idx, {X, Y}, {Ex, Ey}) of %% 横板
                        ?none ->
                            ?WARN_LOG("monster idx ~p skill all in cd", [Idx]),
                            ?change_st(?st_back, nil, A, <<"not have readyed skill">>);

                        {not_in_range, Xv, Yv} ->
                            %%%% TODO 如果目标位置没变,就不需要做什么
                            ?debug_log_scene_monster("out of range ~p", [{Xv, Yv}]),
                            pl_util:move(A, {Xv, Yv});
                        {ok, SkillId} ->
                            ?change_st(?st_fight, {SkillId, get_point_dict(X, Y, Ex, Ey, A#agent.d)}, A, <<"chase to fight">>)
                    end
            %%true ->
            %%Xv = b_dir_a(Ex, X),

            %%?DEBUG_LOG("xxxxx"),
            %%scene_aoi:move_with_vector_and_notify(A, {Xv, Ey-Y, 0})
            end
    end;
st_chase(?event_stiff_end, _, A) ->
    ?assert(A#agent.state_timer =:= ?none andalso A#agent.stiff_state =:= ?none),
    ?change_st(?st_reaction, 800, A, <<"event_stiff_end">>);

st_chase(?event_beat_back_stiff_end, _, A) ->
    ?assert(A#agent.state_timer =:= ?none andalso A#agent.stiff_state =:= ?none),
    ?change_st(?st_reaction, 800, A, <<"event_beat_back_stiff_end">>);

st_chase(?event_move_over, nil, A) ->
    has_enemy(A);
st_chase(_Event, _Arg, _A) ->
    ?ERROR_LOG("idx ~p unknow event ~p arg ~p st ~p", [_A#agent.idx, _Event, _Arg, _A#agent.state]).


st_back(?event_start, _, #agent{idx = Idx, id = _Id, pid = Index, x = X, y = Y} = A) ->
    ?assert(Idx < 0),

    scene_monster:del_m_enemy(Idx),
    ?assert(?undefined =:= get(?pd_m_enemy(Idx))),

    %%MCfg = get(?pd_monster_cfg(Id)),

    %% full hp
    %%?debug_log_scene_monster("full hp monster"),
    %%case MCfg#monster_cfg.type of
    %%?MT_NORMAL ->
    %%A=scene_monster:full_hp(_A);
    %%_ ->
    %%A=_A
    %%end,

    case get(?pd_monster_born(Index)) of
        {DestX, DestY, _} ->
            ?debug_log_monster_ai("xxxxx"),
            pl_util:move(A, {DestX - X, DestY - Y});
        _ ->
            ?change_st(?st_stroll_wait, 1500, A#agent{state = ?st_back}, <<"on born point">>) %% beay loop check_has_enemy
    end;
st_back(?event_leave, _, A) ->
    map_aoi:stop_if_moving(A);
st_back(?event_move_step, _, _A) ->
    ok;
st_back(?event_move_over, _Arg, A) -> %% back to bron point
    ?change_st(?st_stroll_wait, nil, A, <<"move over">>);
st_back(?event_stiff_end, _, A) ->
    fight_or_chase_or_back(A, <<"event_stiff_end">>);
st_back(?event_beat_back_stiff_end, _, A) ->
    fight_or_chase_or_back(A, <<"event_beat_back_stiff_end">>);

st_back(?event_has_enemy, _, A) ->
    has_enemy(A);
st_back(_Event, _Arg, _A) ->
    ?ERROR_LOG("idx ~p unknow event ~p arg ~p st ~p", [_A#agent.idx, _Event, _Arg, _A#agent.state]).


st_reaction(?event_start, Daily, A) ->
    ?assert(A#agent.state =/= ?st_reaction),
    ?Assert2(A#agent.state_timer =:= ?none, "idx ~p St ~p", [A#agent.idx, A#agent.state_timer]),
    ?debug_log_monster_ai("xxxxxxxxx daily ~p", [Daily]),
    case Daily of
        0 -> %% stiff_end, 立即攻击
            fight_or_chase_or_back(A#agent{state = ?st_reaction}, <<"timeout ">>);
        _ ->
            Ref = scene_eng:start_timer(Daily, ?MODULE, {?event_reaction_timeout, A#agent.idx}),
            ?update_agent(A#agent.idx, A#agent{state = ?st_reaction, state_timer = Ref})
    end;
st_reaction(?event_leave, _, A) ->
    scene_eng:cancel_timer(A#agent.state_timer),
    A#agent{state_timer = ?none};
st_reaction(?event_reaction_timeout, _, A) ->
    ?assert(A#agent.idx < 0),
    case A#agent.stiff_state of
        ?ss_stiff ->
            ?debug_log_monster_ai("idx ~p event_reaction_timeout but in ss_stiff wait stiff over", [A#agent.idx]),
            ok; %% 等待stiif_timer 结束
        ?ss_beat_back_stiff ->
            ?debug_log_monster_ai("idx ~p event_reaction_timeout but in ss_beat_back_stiff wait stiff over", [A#agent.idx]),
            ok; %% 等待stiif_timer 结束
        _ ->
            %% BUG h not =/ 0
            fight_or_chase_or_back(A#agent{state_timer = ?none}, <<"timeout ">>)
    end;

st_reaction(?event_stiff_end, _, A) ->
    ?assert(A#agent.stiff_state =:= ?none),
    fight_or_chase_or_back(A, <<"event_stiff_end">>);

st_reaction(?event_beat_back_stiff_end, _, A) ->
    ?assert(A#agent.stiff_state =:= ?none),
    fight_or_chase_or_back(A, <<"event_beat_back_stiff_end">>);

st_reaction(?event_release_skill_over, _, A) ->
    case A#agent.stiff_state of
        ?ss_stiff ->
            ok;
        _ ->
            fight_or_chase_or_back(A, <<"render_time_out">>)
    end;

st_reaction(?event_has_enemy, _, A) ->
    has_enemy(A);
st_reaction(_Event, _Arg, _A) ->
    ?ERROR_LOG("idx ~p unknow event ~p arg ~p st ~p", [_A#agent.idx, _Event, _Arg, _A#agent.state]).


fight_or_chase_or_back(#agent{idx = Idx} = A, _DebugMsg) ->
    case get(?pd_m_enemy(Idx)) of
        ?undefined ->
            ?change_st(?st_back, nil, A, _DebugMsg);
        EIdx ->
            case ?get_agent(EIdx) of %% HACK
                ?undefined ->
                    ?change_st(?st_back, nil, A, _DebugMsg);
                #agent{state = ?st_die} ->
                    ?change_st(?st_back, nil, A, {_DebugMsg, <<" enemy die">>});
                EA ->
                    fight_or_chase_or_back(A, EA, _DebugMsg)
            end
    end.

fight_or_chase_or_back(#agent{idx = Idx, id = Id, x = X, y = Y, h = _H} = A, #agent{x = Ex, y = Ey} = Enemy, _DebugMsg) ->
    ?assert(Enemy#agent.state =/= ?st_die),

    if _H =/= 0 ->
        ?WARN_LOG("idx ~p move h not 0 ~p mv~p", [Idx, _H, A#agent.move_vec]);
        true ->
            ok
    end,

    %%?assert(A#agent.h =:= 0),

    MCfg = get(?pd_monster_cfg(Id)),

    %%Dist = com_util:get_point_distance({X,Y}, {Ex,Ey}),
    Dist = abs(X - Ex),
    if Dist > MCfg#monster_cfg.chase_range ->
        ?change_st(?st_back, nil, A, {_DebugMsg, <<" leave chase range">>});
        true ->
            case monster_skill_mng:get_releaseable_skill(Idx, {X, Y}, {Ex, Ey}) of
                ?none ->
                    ?debug_log_monster_ai("monster ~p get skill empty", [Idx]),
                    ?change_st(?st_back, nil, A, {_DebugMsg, <<"not have readyed skill">>});

                {not_in_range, Xv, Yv} ->
                    ?assert(A#agent.stiff_state =/= ?ss_stiff),
                    ?debug_log_scene_monster("out of range ~p", [{Xv, Yv}]),
                    ?change_st(?st_chase, {{Xv, Yv, 0}, MCfg}, A, <<"release skill not in range">>);

            %%{ok, _SkillId, {RRangeMin, RRangeMax}} when Ey =/= Y -> %% 要保持在y上位置相同
            %%%%TODO hight
            %%Xv = b_dir_a(Ex, X, RRangeMin, RRangeMax),
            %%?assert(A#agent.stiff_state =/= ?ss_stiff),
            %%?change_st(?st_chase, {{Xv, Ey-Y, 0}, MCfg}, A, <<"y =/= enemy y">>);
                {ok, SkillId} ->
                    if A#agent.state =/= ?st_fight ->
                        ?change_st(?st_fight,
                            {SkillId, get_point_dict(X, 0, Ex, 0, A#agent.d)},
                            A,
                            <<"has enemy">>);
                        true ->
                            st_fight(?event_release_skill,
                                {SkillId, get_point_dict(X, 0, Ex, 0, A#agent.d)},
                                map_aoi:stop_if_moving(A))
                    end
            end
    end.



%% state_timer timeout
handle_timer(_Ref, {Event, Idx}) ->
    #agent{state = St} = A = ?get_agent(Idx),
    ?debug_log_monster_ai("~p ~p ~p", [Idx, St, Event]),
    ?MODULE:St(Event, nil, A);
handle_timer(_Ref, {Event, Arg, Idx}) ->
    #agent{state = St} = A = ?get_agent(Idx),
    ?debug_log_monster_ai("~p ~p ~p", [Idx, St, Event]),
    ?MODULE:St(Event, Arg, A);
handle_timer(_Ref, Msg) ->
    ?ERROR_LOG("unknown msg ~p", [Msg]).


%%random_spell([F|_]=SpellList) ->
%%R = ?random(100),
%%{SpellId, _} =
%%com_lists:take_member(fun({_S, E}) ->
%%E >= R
%%end,
%%F,
%%SpellList),
%%SpellId.

%% A -> B
get_point_dict(Ox, Oy, Dx, Dy, D) ->
    case {Ox - Dx, Oy - Dy} of
        {0, 0} -> D;
        {0, Y} -> if Y > 0 -> ?D_U;
                      true -> ?D_D
                  end;
        {X, 0} -> if X > 0 -> ?D_L;
                      true -> ?D_R
                  end;

        {X, Y} ->
            if X > 0 ->
                if Y > 0 ->
                    ?D_LU;
                    true ->
                        ?D_LD
                end;
                true -> % X < 0
                    if Y > 0 ->
                        ?D_RU;
                        true ->
                            ?D_RD
                    end
            end
    end.

%%test_get_point_dict() ->
%%?assertEqual(?D_L, get_point_dict(1,2, 1,2, ?D_L)),
%%?assertEqual(?D_LD, get_point_dict(2,2, 1,4, ?D_L)),
%%?assertEqual(?D_LD, get_point_dict(4,2, 1,4, ?D_L)),
%%?assertEqual(?D_LU, get_point_dict(12,23, 1,4, ?D_L)),
%%?assertEqual(?D_R, get_point_dict(1,4, 13,4, ?D_L)),
%%?assertEqual(?D_RU, get_point_dict(10,5, 11,4, ?D_L)),
%%?assertEqual(?D_RD, get_point_dict(13,2, 31,4, ?D_L)),
%%?assertEqual(?D_U, get_point_dict(1,20, 1,4, ?D_L)),
%%?assertEqual(?D_L, get_point_dict(10,20, 1,20, ?D_L)),
%%ok.

is_out_range(P1, P2, Dist) ->
    com_util:get_point_distance(P1, P2) > Dist.


%% 主动寻找敌人
-spec check_has_enemy(#agent{}) -> Enemy :: ?none  |{idx, _Idx :: _} | #agent{}.
check_has_enemy(#agent{idx = _Idx, rx = _GR} = _A) -> ?none.


has_enemy(A, EIdx) ->
    scene_monster:set_m_enemy(A#agent.idx, EIdx),
    has_enemy(A).

has_enemy(#agent{idx = Idx} = A) ->
    case A#agent.stiff_state of
        ?ss_stiff ->
            erase(?pd_m_enemy(Idx));
        ?ss_beat_back_stiff ->
            erase(?pd_m_enemy(Idx));
        _ ->
            case get(?pd_m_enemy(Idx)) of
                ?undefined ->
                    ?WARN_LOG("idx ~p can not find enemy", [A#agent.idx]);
                EnemyIdx ->
                    case ?get_agent(EnemyIdx) of
                        ?undefined ->
                            erase(?pd_m_enemy(A#agent.idx));
                        #agent{state = ?st_die} -> %% TODO use is_can_attack repeate
                            erase(?pd_m_enemy(A#agent.idx));
                    %%check_has_enemy(A);
                        EA ->
                            fight_or_chase_or_back(A, EA, <<"has_enemy">>)
                    end
            end
    end.


random_stroll_move_vec(#agent{id = Id, pid = Index, x = X, y = Y} = _A) ->
    Cfg = erlang:get(?pd_monster_cfg(Id)),
    StrollRange = Cfg#monster_cfg.stroll_range,
    ?assert(StrollRange =/= 0),
    random_stroll_move_vec__(?get_monster_bron(Index), StrollRange, X, Y).

random_stroll_move_vec__({BornX, BornY, _} = Boron, StrollRange, X, Y) ->
    StrollRange2 = StrollRange * 2,
    case {BornX + random:uniform(StrollRange2) - StrollRange,
        BornY + random:uniform(StrollRange2) - StrollRange}
    of
        {X, Y} -> %% not move try again
            random_stroll_move_vec__(Boron, StrollRange, X, Y);
        {Nx, Ny} ->
            case scene_map:is_walkable({Nx, Ny}) of
                true ->
                    {Nx - X, Ny - Y, 0};
                false ->
                    random_stroll_move_vec__(Boron, StrollRange, X, Y)
            end
    end.

%% 
%% b_dir_a(Ex, X) ->
%%     if Ex < X -> min(Ex - X + ?RELEASE_SKILL_RANGE, 0);
%%         true -> max(Ex - X - ?RELEASE_SKILL_RANGE, 0)
%%     end.

