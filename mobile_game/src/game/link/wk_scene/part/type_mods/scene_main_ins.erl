%%%-------------------------------------------------------------------
%%% @author zl
%%% @doc
%%%      主线副本
%%%      scene_mod
%%%      player_plugin
%%%
%%%
%%% @end
%%%-------------------------------------------------------------------

-module(scene_main_ins).

-include("inc.hrl").
-include("scene.hrl").
-include("scene_type_mod.hrl").
-include("scene_player_plugin.hrl").

-include("scene_agent.hrl").
-include("scene_monster.hrl").

-include("main_ins_struct.hrl").
-include("item_new.hrl").
-include("load_cfg_scene.hrl").
-include("load_cfg_main_ins.hrl").

-define(pd_ins_data, pd_ins_data). %传入下一个场景的数据
-define(ins_limit_time, ins_limit_time). %副本限制时间
-define(pd_single_ins_over_timer, pd_single_over_timer).

-define(pd_client_sumbit,  pd_client_sumbit). %客户端提交{副本开始时间,死亡次数,杀怪数量,杀boss数量}

-define(pd_run_arg, pd_run_arg). %run_arg参数
-define(pd_scene_is_last_scene, pd_scene_is_last_scene). %是否是最后一层
-define(pd_scene_kill_monster, pd_scene_kill_monster). %一层副本中的杀怪信息

type_id() -> ?SC_TYPE_MAIN_INS.

init(Cfg) ->
    case get(?pd_scene_id) of
        {_, ?scene_main_ins, {SceneFightStart=#fight_start{}, _}} ->
            put(?ins_limit_time, virtual_time:now()),
            case Cfg#scene_cfg.run_arg of
                #run_arg{match_level = Level, is_match = ?TRUE} ->
                    scene_monster:set_init_attr_fn_match_level(Level, 1);
                _ ->
                    case SceneFightStart#fight_start.ins_type of
                        ?T_INS_SKY_MIGONG ->
                            MonsterAddLevel = sky_service:get_monster_level(),
                            %?DEBUG_LOG("MonsterAddLevel-=--------------:~p",[MonsterAddLevel]),
                            scene_monster:set_init_attr_fn_match_level(MonsterAddLevel, 1),
                            case sky_service:is_box_use() of
                                0 ->
                                    ok;
                                MonsterBid ->
                                    %?DEBUG_LOG("MonsterBid---------------------:~p",[MonsterBid]),
                                    scene_monster:set_init_monster_list([{MonsterBid, 4, 16, 7}])
                            end;
                        _ ->
                            ok
                    end
            end;
        {_, ?scene_main_ins, {_SceneFightStart, _}} ->
            case Cfg#scene_cfg.run_arg of
                #run_arg{match_level = Level, is_match = ?TRUE} ->
                    scene_monster:set_init_attr_fn_match_level(Level, 1);
                _ ->
                    ok
            end
    end,
    put( ?pd_run_arg, Cfg#scene_cfg.run_arg ),
    undefined = scene_player_plugin:set_player_plugin(?MODULE),

    ?pd_new(?pd_ins_data, {com_time:now(),0,0,0}),
    case is_client_main_instance(get(?pd_scene_id)) of
        ?true ->
            ?pd_new(?pd_client_sumbit, ?false);
        _ ->
            pass
    end,
    start_waiting_timer().

uninit(_) ->
    main_ins:remove_scene(get(?pd_scene_id)).

handle_msg({init_room_data, {StartTime, DieCount, KillMonsterCount, KillBossCount}, IsLastScene}) ->
    put(?pd_ins_data, {StartTime, DieCount, KillMonsterCount, KillBossCount}),
    put(?pd_scene_is_last_scene, IsLastScene);

handle_msg({player_die}) ->
    {StartTime, DieCount, KillMonsterCount, KillBossCount} = get(?pd_ins_data),
    put(?pd_ins_data, {StartTime, DieCount+1, KillMonsterCount, KillBossCount});

handle_msg({del_monsters, PlayerPid, PdKey, MonsterBid, IsKillSelf}) ->
    KillCount = get(PdKey),
    NewKillCount = ?if_else(KillCount =:= undefined, 1, KillCount + 1),
    put(PdKey, NewKillCount),
    {_, _, {SceneFightStart, _}} = get(?pd_scene_id),
    case SceneFightStart of
        #fight_start{call_back = {daily_activity_mng, _, Type}} ->
            if
                Type =:= 2 ->
                    case get(?pd_scene_kill_monster) of
                        ?undefined -> put(?pd_scene_kill_monster, [{MonsterBid, 1}]);
                        KillMonster ->
                            case lists:keyfind(MonsterBid, 1, KillMonster) of
                                false -> put(?pd_scene_kill_monster, [{MonsterBid,1} | KillMonster]);
                                {MonsterBid, Num} -> put(?pd_scene_kill_monster, lists:keyreplace(MonsterBid, 1, KillMonster, {MonsterBid, Num + 1}))
                            end
                    end;
                Type =:= 4 andalso IsKillSelf =/= 1 ->
                    case get(?pd_scene_kill_monster) of
                        ?undefined -> put(?pd_scene_kill_monster, [{MonsterBid, 1}]);
                        KillMonster ->
                            case lists:keyfind(MonsterBid, 1, KillMonster) of
                                false -> put(?pd_scene_kill_monster, [{MonsterBid,1} | KillMonster]);
                                {MonsterBid, Num} -> put(?pd_scene_kill_monster, lists:keyreplace(MonsterBid, 1, KillMonster, {MonsterBid, Num + 1}))
                            end
                    end;
                Type =:= 5 ->
                    case get(?pd_scene_kill_monster) of
                        ?undefined -> put(?pd_scene_kill_monster, [{MonsterBid, 1}]);
                        KillMonster ->
                            case lists:keyfind(MonsterBid, 1, KillMonster) of
                                false -> put(?pd_scene_kill_monster, [{MonsterBid,1} | KillMonster]);
                                {MonsterBid, Num} -> put(?pd_scene_kill_monster, lists:keyreplace(MonsterBid, 1, KillMonster, {MonsterBid, Num + 1}))
                            end
                    end;
                true ->
                    pass
            end,
            case get(last_send_time) of
                undefined ->
                    ?send_to_client(PlayerPid, daily_activity_mng:send_cur_point(Type, get(?pd_scene_kill_monster))),
                    put(last_send_time, com_time:now());
                LastTime ->
                    case com_time:now() - LastTime >= 1 of
                        true ->
                            ?send_to_client(PlayerPid, daily_activity_mng:send_cur_point(Type, get(?pd_scene_kill_monster))),
                            put(last_send_time, com_time:now());
                        _ ->
                            ignore
                    end
            end;
        _ ->
            case get(?pd_scene_kill_monster) of
                ?undefined -> put(?pd_scene_kill_monster, [{MonsterBid, 1}]);
                KillMonster ->
                    case lists:keyfind(MonsterBid, 1, KillMonster) of
                        false -> put(?pd_scene_kill_monster, [{MonsterBid,1} | KillMonster]);
                        {MonsterBid, Num} -> put(?pd_scene_kill_monster, lists:keyreplace(MonsterBid, 1, KillMonster, {MonsterBid, Num + 1}))
                    end
            end
    end;

handle_msg({start_next_scene_id, _PlayerId,  _Idx, PlayerPid, NextSceneId, IsLastScene}) ->
    start_next_scene( PlayerPid, NextSceneId, IsLastScene );

%% 客户端提交
handle_msg({client_sumbit, _PlayerId, _PlayerPid,
    {IsInsComplete, WaveNum, MaxDoubleHit, ShoujiCount, PassTime, ReliveNum, AbyssPercent, AbyssScore, MonsterBidList }}) ->
    % ?DEBUG_LOG("MaxDoubleHit-------------ShoujiCount------------:~p",[{MaxDoubleHit, ShoujiCount}]),
    % ?INFO_LOG("AbyssPercent-------------AbyssScore------------:~p",[{AbyssPercent, AbyssScore}]),
    case get(?pd_client_sumbit) of
        ?false ->
            put(?pd_client_sumbit, ?true),
            {_, ?scene_main_ins, {SceneFightStart, _}} = get(?pd_scene_id),
            {_StartTime, DieCount1, KillMonsterCount, KillBossCount} = get(?pd_ins_data),
            ThisSceneKillMonster = kill_min_monster_count(),
            ThisSceneKillBoss = kill_boss_monster_count(),
            case IsInsComplete of
                ?ins_complete ->
                    %% 虚空深渊
                    case SceneFightStart#fight_start.ins_type of
                        ?T_INS_XUKONG ->
                            % ?INFO_LOG(" ===================虚空深渊结算================= "),
                            complete_ins(SceneFightStart#fight_start{fight_state = IsInsComplete},
                                {get(?pd_scene_kill_monster), WaveNum, MaxDoubleHit},
                                {PassTime, ReliveNum, DieCount1, KillMonsterCount, KillBossCount, ShoujiCount,AbyssPercent, AbyssScore, MonsterBidList});
                        _ ->
                            case is_boss_room(SceneFightStart, ThisSceneKillBoss+ThisSceneKillMonster) of
                                ?TRUE ->
                                    % ?DEBUG_LOG("3---------------------------------"),
                                    %FinalLianJi = main_ins:get_main_ins_lianji({?maining_instance_lianji_count,PlayerId}, MaxDoubleHit),
                                    %FinalShouJI = main_ins:get_main_ins_data({?maining_instance_shouji_count,PlayerId}) + ShoujiCount,
                                    %?DEBUG_LOG("FinalLianJi, FinalShouJI-------------:~p",[{FinalLianJi, FinalShouJI}]),
                                    complete_ins(SceneFightStart,
                                        {get(?pd_scene_kill_monster), WaveNum, MaxDoubleHit},
                                        {PassTime, ReliveNum, DieCount1, KillMonsterCount, KillBossCount, ShoujiCount,AbyssPercent, AbyssScore, MonsterBidList});
                                ?FALSE ->
                                    %main_ins:update_main_ins_lianji({?maining_instance_lianji_count,PlayerId}, MaxDoubleHit),
                                    %main_ins:update_main_ins_data({?maining_instance_shouji_count,PlayerId}, ShoujiCount),
                                    ok
                            end
                    end;

                InsState ->  %% ins_leave||ins_fail 中途离开副本||副本失败
                    %?DEBUG_LOG("InsState:~p", [InsState]),
                    % ?INFO_LOG(" ===================中途离开副本================= "),
                    %% 虚空深渊
                    case SceneFightStart#fight_start.ins_type of
                        ?T_INS_XUKONG ->
                            % ?INFO_LOG(" ===================虚空深渊结算================= "),
                            complete_ins( SceneFightStart#fight_start{fight_state = IsInsComplete},
                                {get(?pd_scene_kill_monster), WaveNum, MaxDoubleHit},
                                {PassTime, ReliveNum, DieCount1, KillMonsterCount, KillBossCount, ShoujiCount,AbyssPercent, AbyssScore, MonsterBidList});
                        _ ->
                            scene_player:broadcast(?mod_msg(main_instance_mng,
                                {ins_complete, SceneFightStart#fight_start{fight_state = InsState}, get(?pd_scene_kill_monster),
                                    WaveNum, MaxDoubleHit, DieCount1, KillMonsterCount + kill_min_monster_count(),
                                    KillBossCount + kill_boss_monster_count(), get(?pd_scene_id), PassTime, ReliveNum, ShoujiCount,AbyssPercent,AbyssScore, MonsterBidList}))
                    end
            end;
        _ ->
            pass
    end;

handle_msg({is_client_sumbit}) ->
    put(?pd_client_sumbit, ?false);

handle_msg(Msg) ->
    ?ERROR_LOG("unknown msg ~p", [Msg]).


%% 是否是boss房间
is_boss_room(SceneFightStart, KillMonsterNum) ->
    case {SceneFightStart#fight_start.ins_type, KillMonsterNum} of
        {?T_INS_DAILY_1, _} -> ?TRUE;
        {?T_INS_DAILY_2, _} -> ?TRUE;
        {?T_INS_DAILY_3, KillMonsterList} ->
            case KillMonsterList of
                0 -> ?TRUE;
                _ ->
                    {daily_activity_mng, next_scene_id, {_DailyType, [_SceneId1,_SceneId2,_SceneId3,SceneId4]}} = SceneFightStart#fight_start.next_scene_call,
                    ThisSceneId = get(?pd_cfg_id),
                    if
                        ThisSceneId =:=  SceneId4-> ?TRUE;
                        true -> ?FALSE
                    end

            end;
        {?T_INS_DAILY_4, _} -> ?TRUE;
        {?T_INS_DAILY_5, _} -> ?TRUE;
        {?T_INS_XUKONG, _} ->
            case load_cfg_main_ins:is_boss_room(get(?pd_cfg_id)) of
                ?TRUE ->
                    ?TRUE;
                _ ->
                    ?FALSE
            end;
        {?T_INS_COURSE, _} -> ?TRUE;
        {?T_INS_SKY_RAND, _} ->
            case load_cfg_main_ins:is_boss_room(get(?pd_cfg_id)) of
                ?TRUE ->
                    ?TRUE;
                _ ->
                    ?FALSE
            end;
        _ ->
            case get(?pd_scene_is_last_scene) of
                ?TRUE ->
                    % ?DEBUG_LOG("3------------------------------"),
                    load_cfg_main_ins:is_boss_room(get(?pd_cfg_id));
                _ ->
                    % ?DEBUG_LOG("4---------------------------"),
                    ?FALSE
            end
    end.

%% 计算副本完成
complete_ins(SceneFightStart, {KillMonsterList, WaveNum, MaxDoubleHit},
    {PassTime, ReliveNum, DieCount1, KillMonsterCount, KillBossCount, ShoujiCount, MonsterBidList}) ->
    % ?DEBUG_LOG("scene_main_ins   complete_ins-----------------------------"),
    % Now = com_time:now(),
    % {KillMonster, Wave, DoubleHit, KillMonsterNum, KillBossNum} =
    %     case SceneFightStart#fight_start.ins_limit_time of
    %         0 ->
    %             {KillMonsterList, WaveNum, MaxDoubleHit, KillMonsterCount + kill_min_monster_count(), KillBossCount + kill_boss_monster_count()};
    %         Time ->
    %             DiffTime = ((Now - get(?ins_limit_time)) - Time),
    %             if
    %                 DiffTime =< 10 -> %有时效的副本误差不能超过3秒
    %                     {KillMonsterList, WaveNum, MaxDoubleHit, KillMonsterCount + kill_min_monster_count(), KillBossCount + kill_boss_monster_count()};
    %                 true -> {[], 0, 0, 0, 0}
    %             end
    %     end,
    % scene_player:broadcast(?mod_msg(main_instance_mng, {
    %     ins_complete,
    %     SceneFightStart#fight_start{fight_state = ?ins_complete},
    %     KillMonster,
    %     Wave,
    %     DoubleHit,
    %     DieCount1,
    %     KillMonsterNum,
    %     KillBossNum,
    %     get(?pd_scene_id),
    %     PassTime,
    %     ShoujiCount, MonsterBidList})),
    % ?INFO_LOG("scene_mian_ins:===NO====AbyssPercentAbyssScore"),
    scene_player:broadcast(?mod_msg(main_instance_mng, {
        ins_complete,
        SceneFightStart#fight_start{fight_state = ?ins_complete},
        KillMonsterList,
        WaveNum,
        MaxDoubleHit,
        DieCount1,
        KillMonsterCount + kill_min_monster_count(),
        KillBossCount + kill_boss_monster_count(),
        get(?pd_scene_id),
        PassTime,
        ReliveNum,
        ShoujiCount,
        MonsterBidList})
    ),
    instance_complete;

complete_ins(SceneFightStart, {KillMonsterList, WaveNum, MaxDoubleHit},
    {PassTime, ReliveNum, DieCount1, KillMonsterCount, KillBossCount, ShoujiCount, AbyssPercent, AbyssScore, MonsterBidList}) ->
    % Now = com_time:now(),
    % {KillMonster, Wave, DoubleHit, KillMonsterNum, KillBossNum} =
    %     case SceneFightStart#fight_start.ins_limit_time of
    %         0 ->
    %             {KillMonsterList, WaveNum, MaxDoubleHit, KillMonsterCount + kill_min_monster_count(), KillBossCount + kill_boss_monster_count()};
    %         Time ->
    %             DiffTime = ((Now - get(?ins_limit_time)) - Time),
    %             if
    %                 DiffTime =< 3 -> %有时效的副本误差不能超过3秒
    %                     {KillMonsterList, WaveNum, MaxDoubleHit, KillMonsterCount + kill_min_monster_count(), KillBossCount + kill_boss_monster_count()};
    %                 true -> {[], 0, 0, 0, 0}
    %             end
    %     end,
    % ?INFO_LOG("scene_mian_ins:=======AbyssPercent:~p, AbyssScore:~p",[AbyssPercent, AbyssScore]),
    NewSceneFightStart = case SceneFightStart#fight_start.ins_type of
        ?T_INS_XUKONG ->
            SceneFightStart;
        _ ->
            SceneFightStart#fight_start{fight_state = ?ins_complete}
    end,
    scene_player:broadcast(?mod_msg(main_instance_mng, {
        ins_complete,
        NewSceneFightStart,
        KillMonsterList,
        WaveNum,
        MaxDoubleHit,
        DieCount1,
        KillMonsterCount + kill_min_monster_count(),
        KillBossCount + kill_boss_monster_count(),
        get(?pd_scene_id),
        PassTime,
        ReliveNum,
        ShoujiCount,
        AbyssPercent,
        AbyssScore,
        MonsterBidList})
    ),
    instance_complete.

start_next_scene( PlayerPid, NextSceneId, IsLastScene ) ->
    {_, ?scene_main_ins, {FightStart=#fight_start{}, _}} = get(?pd_scene_id),
    NextMakeScene = scene:make_scene_id(?SC_TYPE_MAIN_INS, FightStart, NextSceneId, FightStart#fight_start.playerIdOrtermId),
    CFG = load_cfg_main_ins:lookup_main_ins_cfg(NextSceneId),
    case main_ins_mod:can_enter_ins( NextMakeScene, CFG ) of
        true ->
            main_ins:remove_scene(get(?pd_scene_id)),
            RunArg = get(?pd_run_arg),
            case scene_sup:start_client_scene(NextMakeScene, ?false, RunArg) of
                {error, W} ->
                    ?ERROR_LOG("start next scene ~p", [W]);
                Pid ->
                    main_ins:insert_scene(NextMakeScene),
                    {StartTime, DieCount1, KillMonsterCount, KillBossCount} = get(?pd_ins_data),
                    Pid ! ?scene_mod_msg(?MODULE,
                        {
                            init_room_data,
                            {
                                StartTime,
                                DieCount1 + deal_count(),
                                KillMonsterCount + kill_min_monster_count(),
                                KillBossCount + kill_boss_monster_count()
                            },
                            IsLastScene
                        }),
                    PlayerPid ! ?mod_msg(main_instance_mng, {start_next_scene, NextMakeScene})
            end;
        false ->
            scene_eng:terminate_scene(normal)
    end.

handle_timer(_, over) ->
    case scene_player:players_count() of
        1  -> scene_eng:terminate_scene(normal);
        _C -> ok
    end;

handle_timer(_, Msg) ->
    ?ERROR_LOG("unknown msg ~p", [Msg]).

is_client_main_instance(SceneId) ->
    case SceneId of
        {_, ?scene_main_ins, {#fight_start{ins_state = ?ins_state_client}, _}} ->
            ?true;
        _ ->
            ?false
    end.

player_enter_scene(Agent) ->
    SceneId = get(?pd_scene_id),
    % ?DEBUG_LOG("SceneId:~p", [SceneId]),
    case SceneId of
        {_, _, {#fight_start{call_back={Mod, _Fun, Arg}, is_notice_enter_scene = ?TRUE}, _}} ->
            Agent#agent.pid ! ?mod_msg(Mod, {player_enter_scene, {get(?pd_cfg_id), Arg}});
        {_, _, {#fight_start{call_back={Mod, ins_new_wizard, _Arg}}, _}} ->
            Agent#agent.pid ! ?mod_msg(Mod, {player_enter_scene, ins_new_wizard});
        _ ->
            ok
    end,
    cancel_waiting_timer().

player_leave_scene(_Agent) ->
    case get(?pd_scene_id) of
        {_, _, {#fight_start{call_back={Mod, _Fun, Arg}, is_notice_enter_scene = ?TRUE}, _}} ->
            _Agent#agent.pid ! ?mod_msg(Mod, {player_leave_scene, {get(?pd_cfg_id), Arg}});
        {SceneCfgId, _, {#fight_start{call_back={Mod, ins_new_wizard, _Arg}}, _}} ->
            SceneList = misc_cfg:get_misc_cfg(enter_game_ins_task_id),
            case lists:last(SceneList) of
                SceneCfgId ->
                    _Agent#agent.pid ! ?mod_msg(Mod, {player_leave_scene, ins_new_wizard});
                _ ->
                    ignore
            end;
        _ ->
            ignore
    end,
    case scene_player:players_count() of
        1 ->
            scene_eng:terminate_scene(normal);
        _C ->
            ?debug_log_main_ins("player ~p leave remain player count ~p", [_Agent#agent.idx, _C])
    end.

player_die(_, _) -> ok.

statistics_kill_count(_AliveAgent, DeadAgent) when DeadAgent#agent.idx > 0 ->
    ignore;

statistics_kill_count(_AliveAgent, DeadAgent) ->
    PdKey =
        case scene_monster:lookup_monster_cfg(DeadAgent#agent.id, #monster_cfg.type) of
            ?MT_BOOS -> ?pd_kill_boss_monster_count;
            _ -> ?pd_kill_normal_monster_count
        end,
    KillCount = get(PdKey),
    NewKillCount = ?if_else(KillCount =:= undefined, 1, KillCount + 1),
    put(PdKey, NewKillCount).

kill_boss_monster_count() ->
    KillCount = get(?pd_kill_boss_monster_count),
    ?if_else(KillCount=:= undefined, 0, KillCount).

kill_min_monster_count() ->
    KillCount = get(?pd_kill_normal_monster_count),
    ?if_else(KillCount=:= undefined, 0, KillCount).

%% TODO
deal_count() ->
    0.

kill_event(_Self, DealAgent) when DealAgent#agent.idx > 0 ->
    ignore;
kill_event(Self, DealAgent) ->
    case scene_monster:lookup_monster_cfg(DealAgent#agent.id, #monster_cfg.type) of
        ?MT_BOOS->
            ?send_mod_msg(Self#agent.pid, player_mng, {?ev_kill_boss, 0, 1}),
            ?send_mod_msg(Self#agent.pid, player_mng, {?ev_kill_monster, 0, 1}),
            ?send_mod_msg(Self#agent.pid, player_mng, {?ev_kill_monster_by_bid, DealAgent#agent.id, 1});
        _ ->
            ?send_mod_msg(Self#agent.pid, player_mng, {?ev_kill_monster, 0, 1}),
            ?send_mod_msg(Self#agent.pid, player_mng, {?ev_kill_monster_by_bid, DealAgent#agent.id, 1})
    end.

player_kill_agent(Self, DealAgent) ->
    % ?DEBUG_LOG("Self---------------------:~p",[Self]),
    % ?DEBUG_LOG("DealAgent------------------------:~p",[DealAgent]),
    {_, ?scene_main_ins, {SceneFightStart, _}} = get(?pd_scene_id),
    % ?DEBUG_LOG("SceneFightStart---------------------:~p",[SceneFightStart]),
    if
        (DealAgent#agent.idx > 0) andalso (SceneFightStart#fight_start.is_notice_kill_player =:=?TRUE)->
            {Mod, _Fun, _Arg} = SceneFightStart#fight_start.call_back,
            Self#agent.pid ! ?mod_msg(Mod, {player_kill_player, {get(?pd_cfg_id), {DealAgent#agent.pid, DealAgent#agent.id}}});
        (DealAgent#agent.idx < 0) andalso (SceneFightStart#fight_start.is_notice_kill_monster =:=?TRUE)->
            {Mod, _Fun, _Arg} = SceneFightStart#fight_start.call_back,
            Self#agent.pid ! ?mod_msg(Mod, {player_kill_monster, {get(?pd_cfg_id), {DealAgent#agent.pid, DealAgent#agent.id}}});
        true ->
            ok
    end,

    case is_client_main_instance(get(?pd_scene_id)) of
        ?false ->
            Count = scene_monster:monsters_count(),
            statistics_kill_count(Self, DealAgent),
            kill_event(Self, DealAgent),
            if
                Count =:= 0 -> %% compelete
                    {StartTime, DieCount1, KillMonsterCount, KillBossCount} = get(?pd_ins_data),
                    case load_cfg_main_ins:lookup_next_scene_id(SceneFightStart, get(?pd_cfg_id)) of
                        complete ->
                            case SceneFightStart of
                                'team' ->
                                    main_ins_team_mod ! {complete, get(?pd_scene_id), DieCount1 + deal_count(),
                                        KillMonsterCount + kill_min_monster_count(), KillBossCount + kill_boss_monster_count(), com_time:now() - StartTime};
                                #fight_start{call_back = {Mod1, _Fun1, Arg1}} ->
                                    Self#agent.pid ! ?mod_msg(Mod1, {complete, {get(?pd_cfg_id), Arg1}})
                            end,
                            instance_complete;

                        NextSceneId ->
                            % ?DEBUG_LOG("NextSceneId------------------------------:~p",[NextSceneId]),
                            %scene_player:broadcast(?to_client_msg(main_instance_sproto:pkg_msg(?MSG_MAIN_INSTANCE_LAYER_COMPLETE, {}))),
                            %scene_player:broadcast(?to_client_msg(main_instance_sproto:pkg_msg(?MSG_MAIN_INSTANCE_DOOR_ACTIVE, {}))),

                            % ?DEBUG_LOG("send is ------------------------------------------ok"),


                            %% create next scene
                            main_ins:remove_scene(get(?pd_scene_id)),
                            case scene_sup:start_scene(NextSceneId) of
                                {error, W} ->
                                    ?ERROR_LOG("start next scene ~p", [W]);

                                Pid ->
                                    NextCfgId = erlang:element(1, NextSceneId),
                                    main_ins:insert_scene(NextSceneId),
                                    Pid ! ?scene_mod_msg(?MODULE, {init_room_data, {StartTime, DieCount1 + deal_count(), KillMonsterCount + kill_min_monster_count(), KillBossCount + kill_boss_monster_count()},0}),
                                    Pkg =
                                        {
                                            init_room_data,
                                            {
                                                StartTime,
                                                DieCount1 + deal_count(),
                                                KillMonsterCount + kill_min_monster_count(),
                                                KillBossCount + kill_boss_monster_count()
                                            },
                                            0
                                        },
                                    Pid ! ?scene_mod_msg(?MODULE, Pkg),


                                    _PlayerPid = Self#agent.pid,
                                    scene_player:broadcast( ?to_client_msg( main_instance_sproto:pkg_msg(?MSG_MAIN_INSTANCE_LAYER_COMPLETE, {}) ) ),
                                    scene_player:broadcast( ?to_client_msg( main_instance_sproto:pkg_msg(?MSG_MAIN_INSTANCE_DOOR_ACTIVE, {0, 0, NextCfgId}) ) )
                            end
                    end;

                true ->
                    ?debug_log_main_ins("remain ~p monsters", [Count])
            end;
        _ -> ignore
    end.

cancel_waiting_timer() ->
    case get(?pd_single_ins_over_timer) of
        ?undefined -> ok;
        Ref -> scene_eng:cancel_timer(Ref)
    end.

-define(WATING_TIME, (5 * ?SECONDS_PER_MINUTE * 1000)).
start_waiting_timer() ->
    undefined= put(?pd_single_ins_over_timer, scene_eng:start_timer(?WATING_TIME, ?MODULE, over)).
