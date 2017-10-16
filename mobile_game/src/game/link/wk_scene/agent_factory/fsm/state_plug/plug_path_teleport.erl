%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 10. 十一月 2015 下午2:55
%%%-------------------------------------------------------------------
-module(plug_path_teleport).
-author("clark").

%% API
-export([]).

-include("i_plug.hrl").
-include("skill_struct.hrl").
-include("load_spirit_attr.hrl").
-include("inc.hrl").
-include("scene.hrl").
-include("scene_agent.hrl").


on_event(_Agent, _Event) -> none.
can_start(#agent{}, _TPar) -> ret:ok().
start(#agent{} = Agent, TPar) -> restart(Agent, TPar).
restart(#agent{} = Agent, _TPar) -> Agent.

run(#agent{} = Agent, {SkillId, SkillDuanId}) ->
    %% 代表固定移动（动画固定）
    Agent1 = move_path_tgr:start(Agent, SkillId, SkillDuanId),
    Agent1;

run(#agent{idx = Idx} = Agent, {Reason, SyncX, SyncY}) ->
    #agent{x = CurX, y = CurY, h = CurH} = Agent1 = map_aoi:stop_if_moving(Agent),
    Agent2 =
        if
            CurX =/= SyncX orelse CurY =/= SyncY ->
                case room_map:is_walkable(Idx, SyncX, SyncY) of
                    true -> map_agent:set_position(Agent1, {SyncX, SyncY, CurH});
                    _ -> Agent1
                end;
            true ->
                Agent1
        end,
    case Reason of
        ?move_stop ->
            map_aoi:broadcast_except_main_client_if_monster(Agent2, scene_sproto:pkg_msg(?MSG_SCENE_MOVE_STOP, {Idx, SyncX, SyncY, CurH}));
        ?relive ->
            map_aoi:broadcast_view_me_agnets_and_me(Agent2, scene_sproto:pkg_msg(?MSG_SCENE_RELIVE, {Idx, SyncX, SyncY}));
        ?large_move ->
            map_aoi:broadcast_view_me_agnets_and_me(Agent2, scene_sproto:pkg_msg(?MSG_SCENE_LARGE_MOVE, {Idx, SyncX, SyncY}));
        ?skill_move ->
            ok;
        ?sync_position ->
            ok;
        _ ->
            ?ERROR_LOG("idx ~p large move bad reason ~p", [Idx, Reason])
    end,
    Agent2.

stop(#agent{} = Agent) ->
    Agent1 = move_path_tgr:stop(Agent),
    Agent1.

can_interrupt(#agent{} = _Agent, _StatePlugList) ->
    ret:ok().
