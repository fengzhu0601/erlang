%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 10. 十一月 2015 下午12:38
%%%-------------------------------------------------------------------
-module(plug_attack).
-author("clark").

%% API
-export([]).

-include("i_plug.hrl").
-include("skill_struct.hrl").
-include("load_spirit_attr.hrl").
-include("inc.hrl").
-include("scene.hrl").
-include("scene_agent.hrl").
-include("player.hrl").

on_event(_Agent, _Event) -> none.
can_start(#agent{idx = Idx, x = CurX, y = CurY}, {_SkillId, _SkillDuanId, _Dir, SyncX, SyncY, _SyncH}) ->
    if
        CurX =/= SyncX orelse CurY =/= SyncY ->
            case room_map:is_walkable(Idx, SyncX, SyncY) of
                ?true -> ret:ok();
                _ -> ret:error(error_stand_pos)
            end;
        true ->
            ret:ok()
    end.

start(#agent{} = Agent, TPar) ->
    restart(Agent, TPar).
restart(#agent{} = Agent, _TPar) ->
    Agent.

run(#agent{id = _PlayerId, type = Type, idx = Idx} = Agent, {SkillId, SkillDuanId, Dir, SyncX, SyncY, SyncH}) ->
    %% 攻击区(目前不做打断处理, 先暂时依据前端的判断)
    NewAgent = map_agent:set_position(Agent, {SyncX, SyncY, SyncH}, Dir, false),
    case Type of
        ?agent_skill_obj ->
            ret:ok();
        _ ->
            Msg = scene_sproto:pkg_msg(?MSG_SCENE_RELEASE_SKILL, {Idx, SkillId, SkillDuanId, Dir, SyncX, SyncY, SyncH}),
            map_aoi:broadcast_except_main_client_if_monster(NewAgent, Msg)
    end,
    NewAgent.


stop(#agent{} = Agent) ->
    Agent1 = attack_area_tgr:stop(Agent),
    Agent1#agent{pl_attack = #pl_attack_info{skill_id = 0}}.

can_interrupt(#agent{} = _Agent, _StatePlugList) ->
    ret:ok().


