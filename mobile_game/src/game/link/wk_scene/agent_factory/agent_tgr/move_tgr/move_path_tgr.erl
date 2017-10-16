%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 17. 九月 2015 下午2:16
%%%-------------------------------------------------------------------
-module(move_path_tgr).
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

%% 技能动画移动
start(?undefined, _, _) ->
    ok;
start(#agent{move_vec = MV} = A, SkillId, SKillDuanId) ->
    stop(MV),
    on_path_move(A, SkillId, SKillDuanId, 1).



stop(#agent{move_vec = MV} = Agent) ->
    MV1 = stop(MV),
    Agent#agent{move_vec = MV1};
stop(MV) ->
    if
        MV#move_vec.skill_move_timer =/= ?none -> scene_eng:cancel_timer(MV#move_vec.skill_move_timer);
        true -> ok
    end,
    ?assert(not scene_eng:is_wait_timer(MV#move_vec.skill_move_timer)),
    MV#move_vec{skill_move_timer = ?none}.

is_run(#agent{move_vec = MV}) -> is_run(MV);
is_run(MV) -> scene_eng:is_wait_timer(MV#move_vec.skill_move_timer).


handle_timer(_Ref, {skill_move, Idx, SkillId, SKillDuanId, Index}) ->
    on_path_move(?get_agent(Idx), SkillId, SKillDuanId, Index);

handle_timer(_Ref, Msg) ->
    ?ERROR_LOG("unknown msg ~p", [Msg]).




on_path_move(#agent{idx = Idx, x = Ox, h = Oh, y = Oy, d = D, move_vec = MV} = A, SkillId, SKillDuanId, Index) ->
    case load_cfg_skill:get_skill_move_point(SkillId, Index) of
        ?none -> A;
%%        [{1085,{0,0,0}},{30,{1,0,0}},{36,{1,0,0}},{40,{1,0,0}},{43,{1,0,0}},{48,{1,0,0}},{53,{1,0,0}},{65,{1,0,0}},{0,{1,0,0}}]
        {Delay, {Xv, Yv, Hv}} ->
            {X, Y} = move_util:move_offset(D, Ox, Oy, Xv, Yv),
            NH = max(0, Oh + Hv),
            NewPoint = {X, Y, NH},
            AR =
                case room_map:is_walkable(Idx, NewPoint) of
                    ?false ->
                        A#agent{move_vec = MV#move_vec{reason = none, skill_move_timer = ?none}};
                    ?true ->
                        A1 = map_agent:set_position(A, NewPoint, A#agent.d, false),
                        ?DEBUG_LOG("move xv,yv:~p", [{NewPoint, SkillId}]),
                        ?ifdo(
                            A#agent.idx > 0,
                            (begin
                                 AttackPlug = pl_fsm:build_plug(?pl_attack),
%%                             ?DEBUG_LOG("attack pos:~p",[{Idx,A#agent.x, A#agent.y, A#agent.h}]),
                                 PlugList = [{AttackPlug, {SkillId, SKillDuanId, A1#agent.d, A1#agent.x, A1#agent.y, A1#agent.h}}],
                                 pl_fsm:set_state(A1, PlugList)
                             end)

                        ),
%%                        pl_util:play_skill(A1, SkillId),
                        case Delay of
                            0 ->
                                %%无动画时的重力下落
                                if
                                    NH > 0 ->
                                        move_h_tgr:start_freely_fall(A1);
                                    true ->
                                        A1
                                end;
                            _ ->
                                TimerRef = scene_eng:start_timer(Delay, ?MODULE, {skill_move, Idx, SkillId, SKillDuanId, Index + 1}),
                                A1#agent{move_vec = MV#move_vec{reason = ?mst_skill_move, skill_move_timer = TimerRef}}
                        end
                end,
            ?update_agent(Idx, AR),
            AR;
        _ ->
            ?ERROR_LOG("move_skill_tgr:start")
    end.