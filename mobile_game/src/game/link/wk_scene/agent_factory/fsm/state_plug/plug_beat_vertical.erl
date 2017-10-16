%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 11. 十一月 2015 下午5:21
%%%-------------------------------------------------------------------
-module(plug_beat_vertical).
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

run(#agent{x = X, y = Y, h = H} = Agent, {Dir}) ->
    run(Agent, {Dir, X, Y, H},?JUMP_HIGHT);
run(#agent{x = X, y = Y, h = H} = Agent, {Dir,VH}) ->
    run(Agent, {Dir, X, Y, H},VH).

run(#agent{idx = Idx} = Agent, {Dir, SyncX, SyncY, SyncH},VH) ->
    ?assert(room_map:is_walkable(Idx, SyncX, SyncY)),
    Agent0 = map_agent:set_position(Agent, {SyncX, SyncY, SyncH}, Dir, false),
    Agent1 = move_tgr_util:stop_all_move_tgr(Agent0),
    Agent2 = move_h_tgr:start_jump(Agent1,VH, Idx, 0),
    MV = Agent2#agent.move_vec,
%%    ?DEBUG_LOG("move: ~p",[MV#move_vec{x_speed = ?DEFALUT_FLY_MOVE_SPEED+2}]),
    Agent3 = Agent2#agent{d = Dir, move_vec = MV},
%%        case Dir of
%%            ?D_L ->
%%                Agent2#agent{d = Dir, move_vec = move_x_tgr:start(MV#move_vec{x_speed = ?DEFALUT_FLY_MOVE_SPEED+2}, -?KEEP_MOVEING, Idx)};
%%            ?D_R ->
%%                Agent2#agent{d = Dir, move_vec = move_x_tgr:start(MV#move_vec{x_speed = ?DEFALUT_FLY_MOVE_SPEED+2}, ?KEEP_MOVEING, Idx)};
%%            ?D_U ->
%%                Agent2#agent{d = Dir, move_vec = move_y_tgr:start(MV#move_vec{y_speed = ?DEFALUT_FLY_MOVE_SPEED}, ?KEEP_MOVEING, Idx)};
%%            ?D_D ->
%%                Agent2#agent{d = Dir, move_vec = move_y_tgr:start(MV#move_vec{y_speed = ?DEFALUT_FLY_MOVE_SPEED}, -?KEEP_MOVEING, Idx)};
%%            _ ->
%%                Agent2#agent{d = Dir, move_vec = MV}
%%        end,
    ?update_agent(Idx, Agent3),
    map_aoi:broadcast_view_me_agnets(Agent3, scene_sproto:pkg_msg(?MSG_SCENE_JUMP, {Idx, Dir, SyncX, SyncY, SyncH})),
    Agent3.


stop(#agent{} = Agent) ->
    Agent1 = move_h_tgr:start_freely_fall(Agent),
    Agent1.

can_interrupt(#agent{h = H} = _Agent, StatePlugList) ->
    %% 空中时不许
    Ret = has_vertical(StatePlugList),
%%     ?INFO_LOG("vertical can_interrupt H ~p",[{H, Ret}]),
    if
        H >= 2 andalso Ret =/= ok ->
%%             ?INFO_LOG("vertical can_interrupt"),
            ret:error(vertical_cant_interrupt);
        true ->
            ret:ok()
    end.

has_vertical([]) ->
    ret:error(no);
has_vertical([{Plug, _TPar}|TailList]) ->
    if
        Plug =:= plug_beat_vertical ->
            ret:ok();
        true ->
            has_vertical(TailList)
    end.