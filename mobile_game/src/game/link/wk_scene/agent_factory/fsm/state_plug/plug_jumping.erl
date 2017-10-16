%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%% 起跳
%%% @end
%%% Created : 10. 十一月 2015 上午11:11
%%%-------------------------------------------------------------------
-module(plug_jumping).
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

run(#agent{idx = _Idx, x = X, y = Y, h = H} = Agent, {Dir}) ->
    run(Agent, {Dir, X, Y, H});
run(#agent{idx = Idx, x=X, y=Y} = Agent, {Dir, SyncX0, SyncY0, SyncH}) ->
    {SyncX, SyncY} = case room_map:is_walkable(Idx, SyncX0, SyncY0) of
        true -> {SyncX0, SyncY0};
        false -> {X, Y}
    end,
    Agent0 = map_agent:set_position(Agent, {SyncX, SyncY, SyncH}, Dir, false),
    Agent1 = move_tgr_util:stop_all_move_tgr(Agent0),
    Agent2 = move_h_tgr:start_jump(Agent1, ?JUMP_HIGHT, Idx, 0),
    MV = Agent2#agent.move_vec,
    Agent3 = case Dir of
        ?D_L ->
            Agent2#agent{d = Dir, move_vec = move_x_tgr:start(MV#move_vec{x_speed = ?DEFALUT_FLY_MOVE_SPEED}, -?KEEP_MOVEING, Idx)};
        ?D_R ->
            Agent2#agent{d = Dir, move_vec = move_x_tgr:start(MV#move_vec{x_speed = ?DEFALUT_FLY_MOVE_SPEED}, ?KEEP_MOVEING, Idx)};
        ?D_U ->
            Agent2#agent{d = Dir, move_vec = move_y_tgr:start(MV#move_vec{y_speed = ?DEFALUT_FLY_MOVE_SPEED}, ?KEEP_MOVEING, Idx)};
        ?D_D ->
            Agent2#agent{d = Dir, move_vec = move_y_tgr:start(MV#move_vec{y_speed = ?DEFALUT_FLY_MOVE_SPEED}, -?KEEP_MOVEING, Idx)};
        _ ->
            Agent2#agent{d = Dir, move_vec = MV}
    end,
    ?update_agent(Idx, Agent3),
    map_aoi:broadcast_view_me_agnets(Agent3, scene_sproto:pkg_msg(?MSG_SCENE_JUMP, {Idx, Dir, SyncX, SyncY, SyncH})),
    Agent3.

stop(#agent{} = Agent) ->
    Agent1 = move_h_tgr:start_freely_fall(Agent),
    Agent1.

can_interrupt(#agent{} = _Agent, _StatePlugList) ->
    %% 空中时不许
    ret:ok().
