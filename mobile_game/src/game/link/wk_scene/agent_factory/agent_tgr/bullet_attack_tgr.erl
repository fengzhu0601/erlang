%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 13. 十一月 2015 下午6:33
%%%-------------------------------------------------------------------
-module(bullet_attack_tgr).
-author("clark").

%% API
-export(
[
    start/2
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





start(#agent{idx = Idx} = Agent, {DelayTm, {SX, SY, SH}, SkillId, SkillDuanId, InterDt, EndTime}) ->
    ?INFO_LOG("bullet_attack skill ~p",[SkillId]),
    Agent1 = stop(Agent),
    Agent2 =
        case DelayTm of
            0 ->
                attack(Idx, {SX, SY, SH}, SkillId, SkillDuanId, InterDt, EndTime);
            Other ->
                Tref = scene_eng:start_timer(Other, ?MODULE, {attack_frame, Idx, {SX, SY, SH}, SkillId, SkillDuanId, InterDt, EndTime}),
                Agent1#agent{bullet_attack_timer = Tref}
        end,
    ?update_agent(Idx, Agent2),
    Agent2.



stop(#agent{idx = Idx, bullet_attack_timer = TimerRef} = Agent) ->
    if
        TimerRef =/= ?none -> scene_eng:cancel_timer(TimerRef);
        true -> ok
    end,
    ?assert(not scene_eng:is_wait_timer(TimerRef)),
    Agent1 = Agent#agent{bullet_attack_timer = ?none},
    ?update_agent(Idx, Agent1),
    Agent1.

is_run(#agent{bullet_attack_timer = TimerRef}) ->
    scene_eng:is_wait_timer(TimerRef).




%% ----------------------
%% private
%% ----------------------
handle_timer(_Ref, {attack_frame, Idx, {SX, SY, SH}, SkillId, SkillDuanId, InterDt, EndTime}) ->
    attack(Idx, {SX, SY, SH}, SkillId, SkillDuanId, InterDt, EndTime);

handle_timer(_Ref, Msg) ->
    ?ERROR_LOG("unknown msg ~p", [Msg]).


attack(#agent{idx = Idx, d = Dir, x = X, y = Y, h = H} = Agent, {SX, SY, SH}, SkillId, SkillDuanId, InterDt, EndTime) ->
    %% 移动
    NX = round(SX*InterDt),
    NY = round(SY*InterDt),
    Agent0 = pl_util:move(Agent, {NX, NY}),
    NewPoint = {X+NX, Y+NY, H},
    {X2, Y2, H2} =
        case room_map:is_walkable(Idx, NewPoint) of
            ?false -> {X, Y, H};
            _ ->{X+NX, Y+NY, H}
        end,
    Agent1 = pl_util:play_skill(Agent0#agent{x = X2, y = Y2, h = H2}, {SkillId, SkillDuanId, Dir}),
    CurTm = com_time:timestamp_msec(),
    if
        CurTm >= EndTime ->
            map_agent:delete(Idx);
        true ->
            Tref = scene_eng:start_timer(InterDt, ?MODULE, {attack_frame, Idx, {SX, SY, SH}, SkillId, SkillDuanId, InterDt, EndTime}),
            Agent2 = Agent1#agent{bullet_attack_timer = Tref},
            ?update_agent(Idx, Agent2)
    end,
    ok;

attack(Idx, {SX, SY, SH}, SkillId, SkillDuanId, InterDt, EndTime) ->
    case ?get_agent(Idx) of
        ?undefined ->
            ok;
        #agent{} = Agent ->
            attack(Agent, {SX, SY, SH}, SkillId, SkillDuanId, InterDt, EndTime)
    end.