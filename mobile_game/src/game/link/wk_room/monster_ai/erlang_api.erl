-module(erlang_api).


-include("lua_evt.hrl").

-export
([
    install/1
    , lua_ret_to_erlang_ret/2
    , on_monster_evt/1
]).

-import(luerl_lib, [lua_error/2,badarg_error/3]).	%Shorten this


-include("mst_ai_sys.hrl").
-include("inc.hrl").
-include("scene.hrl").
-include("scene_agent.hrl").


install(St) ->
    {Tab,St1} = luerl_emul:alloc_table(table(), St),
    St2 = luerl_emul:set_global_key(<<"erlang_api">>, Tab, St1),
    {_, St3} = luerl:dofile("./lua/main.lua", St2),
    St3.


table() ->
    [
        {<<"print">>,                   {function, fun print/2}},
        {<<"loadfile">>,                {function, fun loadfile/2}},
        {<<"update_stack">>,            {function, fun update_stack/2}},
        {<<"check_hp_rank">>,           {function, fun check_hp_rank/2}},
        {<<"add_buf">>,                 {function, fun add_buf/2}},
        {<<"add_player_buf">>,          {function, fun add_player_buf/2}},
        {<<"set_map_data">>,            {function, fun set_map_data/2}},
        {<<"call_monsters">>,           {function, fun call_monsters/2}},
        {<<"do_move_instance">>,        {function, fun do_move_instance/2}},
        {<<"get_player_behine_pos">>,   {function, fun get_player_behine_pos/2}},
        {<<"get_player_front_pos">>,    {function, fun get_player_front_pos/2}},
        {<<"run_away">>,                {function, fun run_away/2}},
        {<<"do_cast_skill">>,           {function, fun do_cast_skill/2}}
    ].


print(As, St) ->
    % io:format("erlang_api: ~p ~n", [As]),
    {[1], St}.


loadfile(As, St) ->
    [Path] = As,
    Path1 = binary:bin_to_list(Path),
    % io:format("loadfile: ~p ~n", [{Path1, 1}]),
    try luerl:dofile(Path1, St) of
        {Ret, St1} ->
            {Ret, St1}
    catch
        _E:R -> {error, R} % {error, {E, R}} ? <- todo: decide
    end.


lua_ret_to_erlang_ret(Data, St) ->
    luerl:decode_list(Data, St).


update_stack(As, St) ->
%%     io:format("update_stack ~n"),
    mst_ai_lua:update_stack(St),
    {As, St}.



check_hp_rank(As, St) ->
    [Idx, Min, Max] = As,
    Ret = check_near_player_hp(trunc(Idx), trunc(Min), trunc(Max)),
    % io:format("check_hp_rank ~p", [{Min, Max, Ret}]),
    {[Ret], St}.

do_move_instance(As, St) ->
%%    mst_ai_plug:teleport(Pos),
    % io:format("do_move_instance ~p", [As]),
    [Idx, X, Y] = As,
    teleport(trunc(Idx), {trunc(X), trunc(Y)}),
    {[0], St}.

add_player_buf(As, St) ->
    % io:format("add_player_buf ~n"),
%%     [MonsterId, Num, Time, BufId] = As,
    {[1], St}.

add_buf(As, St) ->
    % [1.0431e6,1.0,0.0,50014.0]
    % io:format("add_buf ~p", [As]),
%%     [MonsterId, Num, Time, BufId] = As,
    {[1], St}.

set_map_data(As, St) ->
%%     io:format("set_map_data ~p~n", [As]),
%%     [MonsterId, Num, Time, BufId] = As,
    %% AI不应设置地图的行走点
    {[1], St}.


on_monster_evt(Idx) ->
%%     io:format("on_monster_evt ~p~n", [Idx]),
    mst_ai_lua:on_ai_evt(Idx, ?LUA_EVT_MONSTER, [0]),
    ok.

call_monsters(As, St) ->
    [Idx] = As,
    Idx1 = trunc(Idx),
    timer_server:start(200, {?MODULE, on_monster_evt, [Idx1]}),
%%     io:format("call_monsters ~p~n", [Idx1]),
    {[1], St}.



do_die(As, St) ->
    [Idx] = As,
    % io:format("do_die ~p", [{Idx}]),
    {[0], St}.

do_die_pos(As, St) ->
    [Idx, Pos] = As,
    % io:format("do_die_pos ~p", [{Idx, Pos}]),
    {[0], St}.

run_away(As, St) ->
    [Idx] = As,
    runway_near_player(trunc(Idx)),
    % io:format("run_away ~p", [{Idx}]),
    {[0], St}.

do_cast_skill(As, St) ->
    % io:format("do_cast_skill ~p", [As]),
    [Idx, SkillId] = As,
    ai_release_skill(trunc(Idx), trunc(SkillId)),
    {[0], St}.

get_player_behine_pos(As, St) ->
    % io:format("get_player_behine_pos ~p", [As]),
    [Idx, Num] = As,
    {X, Y} = cal_player_x(trunc(Idx), -trunc(Num)),
    % io:format("get_player_behine_pos ~p", [{X, Y}]),
    {[X, Y], St}.

get_player_front_pos(As, St) ->
    [Idx, Num] = As,
    Ret = cal_player_x(trunc(Idx), trunc(Num)),
    % io:format("get_player_front_pos ~p", [Ret]),
    {[Ret], St}.


cal_player_x(Idx, Num) ->
    Ret = case ?get_agent(Idx) of
        A when is_record(A, agent) ->
            X = A#agent.x,
            Y = A#agent.y,
            case room_system:get_near_pos_player({X, Y}) of
                #agent{x = PX, y = _PY} ->
                    {PX + Num, Y};
                _ ->
                    {X, Y}
            end;
        _ ->
            {0, 0}
          end,
    Ret.

teleport(Idx, {MoveX, MoveY}) ->
    case ?get_agent(Idx) of
        A when is_record(A, agent) ->
%%             ?INFO_LOG("move ~p", [{MoveX, MoveY}]),
            pl_util:teleport(A, {?large_move, MoveX, MoveY});
        _ ->
            pass
    end,
    ok.

% 返回1 或者 0
check_near_player_hp(Idx, Min, Max) ->
    Ret = case ?get_agent(Idx) of
        A when is_record(A, agent) ->
            X = A#agent.x,
            Y = A#agent.y,
            case room_system:get_near_pos_player({X, Y}) of
                #agent{hp = Hp, max_hp = Mhp} ->
                    MinH = Mhp * Min / 100,
                    MaxH = Mhp * Max / 100,
                    if
                        MinH =< Hp andalso MaxH >= Hp ->
                            1;
                        true ->
                            0
                    end;
                _ ->
                    0
            end;
        _ ->
            0
    end,
    Ret.

runway_near_player(Idx) ->
    Ret = case ?get_agent(Idx) of
        A when is_record(A, agent) ->
            X = A#agent.x,
            Y = A#agent.y,
            case room_system:get_near_pos_player({X, Y}) of
                #agent{x = PlayerX} ->
                    RandX = com_util:random(3, 6),
                    RandY = com_util:random(-5, 5),
                    case mst_ai_plug:get_dir_to_agent(X, PlayerX) of
                        ?D_L -> pl_util:move(A, {RandX, RandY});
                        _ -> pl_util:move(A, {-RandX, RandY})
                    end;
                _ ->
                    pass
            end;
        _ ->
            0
    end,
    Ret.

ai_release_skill(Idx, SkillId) ->
    % ?DEBUG_LOG("release skill~p", [{Idx, SkillId}]),
    SkillSegId = load_cfg_skill:get_segments_by_skillid(SkillId, 1),
    case ?get_agent(Idx) of
        A when is_record(A, agent) ->
            X = A#agent.x,
            Y = A#agent.y,
            case room_system:get_near_pos_player({X, Y}) of
                #agent{x = PlayerX} ->
                    case mst_ai_plug:get_dir_to_agent(X, PlayerX) of
                        ?D_L -> pl_util:play_skill(A, {SkillSegId, ?D_L});
                        _ -> pl_util:play_skill(A, {SkillSegId, ?D_R})
                    end;
                _ ->
                    pl_util:play_skill(A, {SkillSegId, ?D_L})
            end;
        _ ->
            ok
    end.



