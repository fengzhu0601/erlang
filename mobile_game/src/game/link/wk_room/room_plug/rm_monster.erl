%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 08. 四月 2016 下午12:32
%%%-------------------------------------------------------------------
-module(rm_monster).
-author("clark").

%% API
-export
([
    create_monsters/1
    , create_rand_monsters/1
    , test/1
    , change_ai/1
]).


-include("inc.hrl").
-include("scene_agent.hrl").


-define(make_room_obj_flag, room_obj_flag).


%% put({monster_flag, A#agent.idx}, Flag),
%% put({monster_agent_idx, Flag}, A#agent.idx)

create_monsters(MonsterList) ->
    lists:foreach(
        fun({MonsterId, X, Y, _Z, Dir, Flag}) ->
                case scene_monster:new_monster(MonsterId, X, Y, Dir) of
                    MonsterAgent when is_record(MonsterAgent, agent) ->
                        A = scene_monster:monster_enter_scene(MonsterAgent),
                        scene_monster:bind_room_flag(A#agent.idx, Flag);
                    _ ->
                        pass
                end
        end,
        MonsterList
    ).

create_rand_monsters(MonsterList) ->
    lists:foreach(
        fun({MonsterId, X, Y, R, Dir, Flag}) ->
                X1 = com_util:random(X-R,X+R),
                Y1 = com_util:random(Y-R,Y+R),
                case scene_monster:new_monster(MonsterId, X1, Y1, Dir) of
                    MonsterAgent when is_record(MonsterAgent, agent) ->
                        A = scene_monster:monster_enter_scene(MonsterAgent),
                        scene_monster:bind_room_flag(A#agent.idx, Flag);
                    _ ->
                        pass
                end
        end,
        MonsterList
    ).

change_ai({Flag, CfgSign}) ->
    List = room_system:get_room_monsters(Flag),
    lists:foreach(
        fun(Idx) ->
                mst_ai_sys:change_ai(Idx, CfgSign)
        end,
        List
    ),
    ok.



test(Flag) ->
    Idx = erlang:get({monster_agent, Flag}),
    A = ?get_agent(Idx),
    ?INFO_LOG("Flag ~p", [{Flag, A#agent.idx}]),
    MovePlug = pl_fsm:build_plug(?pl_moving),
    PlugList = [{MovePlug, {A#agent.x, A#agent.y, A#agent.h, 5, 0}}],
    pl_fsm:set_state(A, PlugList),

    ok.

