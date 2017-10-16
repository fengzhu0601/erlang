%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 28. 十一月 2015 上午1:36
%%%-------------------------------------------------------------------
-module(plug_wait_for_moving).
-author("clark").

%% API
-export([]).



-include("i_plug.hrl").
-include("skill_struct.hrl").
-include("load_spirit_attr.hrl").
-include("inc.hrl").
-include("scene.hrl").
-include("scene_agent.hrl").
-include("../pl_fsm.hrl").


start(#agent{} = Agent, TPar) -> restart(Agent, TPar).
restart(#agent{} = Agent, _TPar) -> Agent.
can_start(#agent{}, _TPar) -> ret:ok().
run(#agent{} = Agent, _TPar) -> Agent.


stop(#agent{move_vec = MV} = Agent) ->
    MV1 = move_xy_tgr:stop(MV),
    Agent#agent{move_vec = MV1}.

can_interrupt(#agent{} = _Agent, _StatePlugList) ->
    %% 空中时不许
    ret:ok().


get_move_info(Agent) ->
    MV = Agent#agent.move_vec,
    if
        MV =/= ?none ->
            {
                Agent#agent.idx,
                Agent#agent.x,
                Agent#agent.y,
                Agent#agent.h,
                {
                    MV#move_vec.x_vec,
                    MV#move_vec.y_vec,
                    MV#move_vec.h_vec
                },
                {
                    MV#move_vec.x_speed,
                    MV#move_vec.y_speed,
                    200
                }
            };
        true ->
            {
                Agent#agent.idx,
                Agent#agent.x,
                Agent#agent.y,
                Agent#agent.h,
                {
                    0,
                    0,
                    0
                },
                {
                    0,
                    0,
                    0
                }
            }
    end.

on_event(#agent{idx = Idx, type = Type, pl_be_freedown = IsFreedown} = Agent, {?fsm_evt_move, SyncX, SyncY, SyncH, Vx, Vy}) ->
    case room_map:is_walkable(Idx, SyncX+Vx, SyncY+Vy) of
        false ->
            case Type of
                ?agent_skill_obj ->
                    dead_tgr:start(Agent,5);
                _ ->
                    Agent
            end;
        _ ->
            Agent0 = map_agent:set_position(Agent, {SyncX, SyncY, SyncH}),
            Agent1 = move_tgr_util:stop_all_move_tgr(Agent0),
            Agent2 = move_xy_tgr:start(Agent1, Vx, Vy, Idx),
            Agent3 =
                case IsFreedown of
                    true -> move_h_tgr:start_freely_fall(Agent2);
                    _ -> Agent2
                end,
            ?update_agent(Idx, Agent3),
            Msg = scene_sproto:pkg_msg(?MSG_SCENE_MOVE, get_move_info(Agent3)),
            map_aoi:broadcast_view_me_agnets_and_me(Agent3, Msg),
            Agent3
    end,
    ok;
on_event(_Agent, _Event) -> none.