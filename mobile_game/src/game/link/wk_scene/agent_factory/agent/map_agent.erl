%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 12. 九月 2015 下午5:15
%%%-------------------------------------------------------------------
-module(map_agent).
-author("clark").

%% API
-export(
[
    create/1
    , delete/1
    , set_position/2
    , set_position/3
    , set_position/4
    , move_step/1
    , on_agent_die/2
    , set_releasing_skill/3
    , try_break_releasing_skill/2
    , resize_view/3
    , change_speed/2
    , get_cur_mp/1
    , get_cur_hp/1
    , on_check_relaxation/1
]).

-include("inc.hrl").
-include("scene.hrl").
-include("scene_agent.hrl").
-include("skill_struct.hrl").
-include("load_spirit_attr.hrl").
-include("porsche_event.hrl").


-define(MSCE_MP, 1000).
-define(CHECK_DT, 100).

create(#agent{idx = Idx, x = X, y = Y, rx = Rx, ry = Ry} = A) ->
    Xrange = map_observers:get_range(X, Rx, get(?pd_map_width)),
    Yrange = map_observers:get_range(Y, Ry, get(?pd_map_height)),
    VBs = map_observers:view_blocks_new(Xrange, Yrange),

    map_observers:view_blocks_insert(Idx, VBs),
    PBlockId = map_block:get_p_block_id(X, Y),
    map_block:p_block_insert(Idx, PBlockId),
    map_point:p_point_insert(Idx, {X, Y}),

    NewA = A#agent{
        born_x = X,
        born_y = Y,
        view_blocks = VBs,
        p_block_id = PBlockId,
        login_num = scene_eng:get_login_num()
    },
    ?agent_new(Idx, NewA),
    case Idx > 0 of
        true ->
            %login_sort:enter(Idx),
            case erlang:get(?pd_scene_count) of
                undefined -> erlang:put(?pd_scene_count, 1);
                Num -> erlang:put(?pd_scene_count, Num+1)
            end;
        _ ->
            ignore
    end,
    case load_cfg_scene:is_normal_scene(get(?pd_scene_id)) of
        ?true ->
            map_aoi:broadcast_create(NewA);
        _ ->
            map_aoi:broadcast_all_create(NewA)
    end,

    FA =
        if
            Idx < 0 ->
                %% 多人副本此定时器才会生效
                NewA#agent{ relaxation_check_timer = timer_server:start( ?CHECK_DT, {map_agent, on_check_relaxation,[Idx]}) };
            true ->
                NewA
        end,
    ?update_agent(Idx, FA),
    FA.

stop_timer
(
    #agent
    {
        idx = Idx,
        skill_time = SKL_TimeRef,
        attack_time = ATK_TimeRef,
        stiff_time = STF_TimeRef,
        bullet_attack_timer = BLT_TimeRef
    } = Agent
) ->
    if
        SKL_TimeRef =/= ?none -> scene_eng:cancel_timer(SKL_TimeRef);
        true -> ok
    end,
    if
        ATK_TimeRef =/= ?none -> scene_eng:cancel_timer(ATK_TimeRef);
        true -> ok
    end,
    if
        STF_TimeRef =/= ?none -> scene_eng:cancel_timer(STF_TimeRef);
        true -> ok
    end,
    if
        BLT_TimeRef =/= ?none -> scene_eng:cancel_timer(BLT_TimeRef);
        true -> ok
    end,
    Agent1 = Agent#agent
    {
        skill_time = ?none,
        attack_time = ?none,
        stiff_time = ?none,
        bullet_attack_timer = ?none
    },
    ?update_agent(Idx, Agent1),
    Agent1.

on_check_relaxation(Idx) ->
%%     ?INFO_LOG("on_check_relaxation ~p", [Idx]),
    case ?get_agent(Idx) of
        #agent{} = A ->
            case move_tgr_util:is_moving(A) of
                true -> pass;
                _ -> evt_util:send( #agent_move_over{idx=Idx} )
            end,
            case move_tgr_util:is_relaxation(A) of
                true ->
%%                     ?INFO_LOG("agent_relaxation ~p", [Idx]),
                    evt_util:send( #agent_relaxation{idx=Idx} );

                _ ->
                    pass
            end,
            A1 = A#agent{ relaxation_check_timer = timer_server:start( ?CHECK_DT, {map_agent, on_check_relaxation, [Idx]}) },
            ?update_agent(Idx, A1);

        _Other ->
            pass
    end,
    ok.


delete(#agent{idx = Idx}) ->
    delete(Idx);
delete(Idx) ->
    case ?get_agent(Idx) of
        ?undefined ->
            ?NODE_ERROR_LOG("agent ~p already removed", [Idx]);
        #agent{x = X, y = Y, p_block_id = PBlockId, view_blocks = VBs} = A ->
            A0 = map_aoi:stop_if_moving(A),
            case A0#agent.relaxation_check_timer of
                nil -> pass;
                Ref -> timer_server:stop(Ref)
            end,
            A1 = A0#agent{relaxation_check_timer = nil},
            stop_timer(A1),
            map_point:p_point_remove(Idx, {X, Y}),
            map_block:p_block_remove(Idx, PBlockId),
            map_observers:view_blocks_remove(Idx, VBs),
            map_aoi:broadcast_delete(A),
            case A1#agent.relaxation_check_timer of
                nil -> pass;
                CheckRef -> timer_server:stop(CheckRef)
            end,
            case Idx > 0 of
                true ->
                    case erlang:get(?pd_scene_count) of
                        undefined -> erlang:put(?pd_scene_count, 0);
                        Num -> erlang:put(?pd_scene_count, Num-1)
                    end;
                _ ->
                    mst_ai_sys:uninit(Idx)
            end,
            %login_sort:exit(Idx),
            ?del_agent(Idx)
    end.

%% agent 移动
set_position(A, NewPoint) -> set_position(A, NewPoint, A#agent.d, true).
set_position(A, NewPoint, D) -> set_position(A, NewPoint, D, true).
set_position(#agent{idx = Idx, x = Cx, y = Cy, rx = Rx, ry = Ry, p_block_id = BlockId, view_blocks = OldVBs} = A, {X, Y, H0}, D, _IsSync) ->
    H = erlang:max(0, H0),
    A1 =
        if
            Cx =:= X andalso Cy =:= Y ->
                A#agent{h = H, d = D};

            ?true ->
                case room_map:is_walkable(Idx, {X, Y, H}) of
                    true ->
                        NewBlockId = map_block:get_p_block_id(X, Y),
                        Xrange = map_observers:get_range(X, Rx, get(?pd_map_width)),
                        Yrange = map_observers:get_range(Y, Ry, get(?pd_map_height)),
                        VBs = map_observers:view_blocks_new(Xrange, Yrange),
                        map_block:p_block_update(Idx, BlockId, NewBlockId),
                        map_observers:view_blocks_update(Idx, OldVBs, VBs),
                        NewA = A#agent{
                            x = X
                            , y = Y
                            , h = H
                            , d = D
                            , p_block_id = NewBlockId
                            , view_blocks = VBs
                        },
                        % map_aoi:broadcast_postion(NewA, {BlockId, OldVBs}, {BlockId, VBs}),
                        NewA;
                    _ ->
                        % ?INFO_LOG("set_position is_walkable false ~p", [{X, Y, H}]),
                        A
                end
        end,
    ?update_agent(Idx, A1),
    A1.


resize_view(Idx, Rx, Ry) ->
    ?assert(Idx > 0),
    case ?get_agent(Idx) of
        ?undefined ->
            ?ERROR_LOG("can not find idx ~p", [Idx]);
        #agent{pid = _Pid, x = X, y = Y, p_block_id = BlockId, view_blocks = _VBs, view_totle_player = _TotlePlayer} = _A ->
            Xrange = map_observers:get_range(X, Rx, get(?pd_map_width)),
            Yrange = map_observers:get_range(Y, Ry, get(?pd_map_height)),
            VBs = map_observers:view_blocks_new(Xrange, Yrange),
            map_observers:view_blocks_update(Idx, _VBs, VBs),
            A = _A#agent
            {
                rx = Rx
                , ry = Ry
                , view_blocks = VBs
            },
            ?update_agent(Idx, A),
            map_aoi:broadcast_postion(A, {BlockId, _VBs}, {BlockId, VBs})
    end.

change_speed(#agent{idx = Idx, move_vec = MV} = Agent, Mode) ->
    Speed =
        if
            Mode =:= ?MT_MOVE -> (Agent#agent.attr)#attr.move_speed;
            true -> (Agent#agent.attr)#attr.run_speed
        end,
    Current = MV#move_vec.x_speed,
    if
        Speed =:= Current -> Agent;
        true ->
            Agent1 = Agent#agent{move_vec = MV#move_vec{x_speed = Speed, y_speed = Speed}},
            ?update_agent(Idx, Agent1),
            map_aoi:broadcast_view_me_agnets(Agent1, scene_sproto:pkg_msg(?MSG_SCENE_PLAYER_SWITCH_MOVE_MODE, {Idx, Mode})),
            Agent1
    end.


get_cur_mp(#agent{idx = Idx, mp = Mp, max_mp = MaxMp, pre_recover_mp_tm = PreTm} = Agent) ->
    {Agent1, Mp2} =
        case PreTm of
            ?none ->
                {
                    Agent#agent{pre_recover_mp_tm = com_time:timestamp_msec()},
                    Mp
                };
            _ ->
%%                ?DEBUG_LOG("mec diff ~p",[(com_time:timestamp_msec() - PreTm)]),
                AddMp = trunc(round( (com_time:timestamp_msec() - PreTm) * 10/ (?MSCE_MP) )),
                Mp1 = min((Mp+AddMp), MaxMp),
                {
                    Agent#agent
                    {
                        mp = Mp1,
                        pre_recover_mp_tm = com_time:timestamp_msec()
                    },
                    Mp1
                }
        end,
    ?update_agent(Idx, Agent1),
    {Agent1, Mp2}.


get_cur_hp(#agent{idx = Idx, hp = Hp, max_hp = MaxHp, pre_recover_mp_tm = PreTm} = Agent) ->
    {Agent1, Hp2} =
        case PreTm of
            ?none ->
                {
                    Agent#agent{pre_recover_mp_tm = com_time:timestamp_msec()},
                    Hp
                };
            _ ->
                AddHp = trunc(round( (com_time:timestamp_msec() - PreTm)/ (?MSCE_MP) ) * 0.002),
                Hp1 = min((Hp+AddHp), MaxHp),
                {
                    Agent#agent
                    {
                        hp = Hp1,
                        pre_recover_mp_tm = com_time:timestamp_msec()
                    },
                    Hp1
                }
        end,
    ?update_agent(Idx, Agent1),
    {Agent1, Hp2}.


move_step(Agent) ->
    Idx = Agent#agent.idx,
    if
        Idx > 0 ->
            scene_player:move_step(Agent);
        true ->
            scene_monster:move_step(Agent)
    end.

%% agent 死亡回调
on_agent_die(#agent{idx = Idx} = Dead, ?undefined) ->
    case Idx < 0 of
        true ->
            scene_monster:die(Dead);
        _ ->
            ignore
    end;
on_agent_die(#agent{idx = Idx} = Dead, Killer) ->
    case get(?pd_agent_die_cb(Idx)) of
        ?undefined ->
            ok;
        CbList ->
            [Cb(Dead, Killer) || Cb <- CbList]
    end,
    if
        Idx > 0 ->
            scene_player:die(Dead, Killer);
        true ->
            scene_monster:die(Dead, Killer)
    end,

    if
        Killer#agent.idx > 0 ->
            scene_player_plugin:kill_agent(Killer, Dead);
        true ->
            ok
    end,
    ok.


%% 设置施法技能和打断优先级
set_releasing_skill(Idx, BreakedPriority, Timer) ->
    erlang:put({?releaseing_skill, Idx}, {BreakedPriority, Timer}).

%% 打断施法
try_break_releasing_skill(Idx, BreakPriority) ->
    case erlang:get({?releaseing_skill, Idx}) of
        {BreakedPRI, Timer} when BreakedPRI < BreakPriority ->
            SkillId = erlang:erase({?releaseing_skill, Idx}),
            scene_eng:cancel_timer(Timer),
            ?if_(Idx < 0, scene_monster:break_releasing_skill(Idx, SkillId)),
            ?TRUE;
        _ ->
            ?FALSE
    end.



