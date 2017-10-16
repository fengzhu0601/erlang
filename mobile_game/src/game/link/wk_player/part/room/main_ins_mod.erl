%%%-------------------------------------------------------------------
%%% @author yujian
%%% @doc 其他系统进入副本调用借口

%%%-------------------------------------------------------------------
-module(main_ins_mod).

-include("inc.hrl").
-include("player.hrl").
-include("scene.hrl").
-include("main_ins_struct.hrl").
-include("load_cfg_main_ins.hrl").
-include("../wonderful_activity/bounty_struct.hrl").
-include("system_log.hrl").

-export
([
    fight_start/2 , fight_start/3, handle_start/1, handle_start/2 %进入副本的调用函数
    , can_enter_ins/2  %是否可以进入副本
    , cost/3           %进入副本消耗
    , is_can_get_prize_from_room/0  %玩家能否从副本中获得奖励
    , is_enough_sp/1
    , get_instance_type/1
    , can_get_prize_from_room/1
    , can_clean_room_times/2
    , count_bounty_fight_room/1
]).

%% 打副本是否有非buff奖励的标志
%%-define(is_prize_for_room, '@is_prize_for_room@').

%% @doc 联网副本时的副本
fight_start(?MSG_MAIN_INSTANCE_SINGLE_START, Id) ->
    Cfg = load_cfg_main_ins:lookup_main_ins_cfg(Id),
    SceneId = scene:make_scene_id(?SC_TYPE_TEAM, team, Id, get(?pd_id)),
    %?DEBUG_LOG("Cfg----------------------:~p",[Cfg]),
    %?DEBUG_LOG("SceneId--------------------------:~p",[SceneId]),
    case can_enter_ins(SceneId, Cfg) of
        false ->
            ?ERROR_LOG("enter ins error:~w~n", [SceneId]),
            error;
        true ->
            ChallengeTimes = main_instance_mng:get_challenge_times(Id),
            MaxChallengeTimes = main_instance_mng:get_max_challenge_times(Id),
            if
                ChallengeTimes < MaxChallengeTimes ->
                    main_instance_mng:add_challenge_times(Id),
                    main_instance_mng:push_challenge_info_by_id(Id),

                    cost(Cfg#main_ins_cfg.sp_cost, Cfg#main_ins_cfg.cost, {Cfg#main_ins_cfg.type, Cfg#main_ins_cfg.sub_type}),

                    %% 统计赏金任务挑战副本
                    count_bounty_fight_room(Cfg#main_ins_cfg.sub_type),

                    Pid =
                        case Cfg#main_ins_cfg.is_monster_match_level of
                            ?TRUE ->
                                scene_sup:start_scene(SceneId, #run_arg{match_level = get(?pd_level), is_match = ?TRUE, start_scene_career = get(?pd_career)});
                            ?FALSE ->
                                scene_sup:start_scene(SceneId)
                        end,
                    ?if_(not is_pid(Pid), ?return_err(Pid)),

                    main_ins:insert_scene(SceneId),

                    ?debug_log_main_ins("enter singg ~p", [SceneId]),
                    case scene_mng:enter_scene_request(SceneId) of
                        approved ->
                            ?debug_log_main_ins("send enter_scene_request ok ~p", [SceneId]),
                            ok;
                        E ->
                            ?ERROR_LOG("enter_main_ins ~p ~p", [Id, E])
                    end;
                true ->
                    ?ERROR_LOG("挑战次数不够"),
                    ?return_err(?ERR_BUY_CHALLENGE_NOT_ENOUGH)
            end
    end;

%% @doc 单机副本
fight_start(?MSG_MAIN_INSTANCE_CLIENT_START, Id) ->
    handle_start(#fight_start{scene_id = Id,
        ins_state = ?ins_state_client,
        ins_type = ?T_INS_MAIN,
        call_back = {main_instance_mng, ins_complete, {}},
        next_scene_call = {main_ins, next_scene_id, {}},
        playerIdOrtermId = get(?pd_id)});

fight_start(course, SceneId) ->
    FightStart = #fight_start{scene_id = SceneId,
                ins_state = ?ins_state_client,
                ins_type = ?T_INS_COURSE,
                call_back = {course_mng, ins_complete, {}},
                playerIdOrtermId = get(?pd_id)},

    NewSceneId = scene:make_scene_id(?SC_TYPE_MAIN_INS, FightStart, SceneId, FightStart#fight_start.playerIdOrtermId),


    CurrentPid = get(?pd_scene_pid),
    ScenePid = load_cfg_scene:get_pid(NewSceneId),
    if
        CurrentPid =:= ScenePid ->
            scene_mng:leave_scene(),
            ScenePid ! {'@stop@', ?normal},
            tick_exit_pid(ScenePid, 0);
        true -> ok
    end,
    handle_start(FightStart),

    ok;


%% @doc 新手引导副本，只能进入一次
fight_start(enter_game_ins_task_id, SceneId) ->
    skill_mng:dress_skill(),
    handle_start(#fight_start{scene_id = SceneId,
        ins_state = ?ins_state_client,
        ins_type = ?T_INS_MAIN,
        call_back = {main_instance_mng, ins_new_wizard, {}},
        playerIdOrtermId = get(?pd_id)}).

fight_start(?MSG_MAIN_INSTANCE_RAND_START, Id, ItemUsePrizeId) ->
    case handle_start(#fight_start
        {
            scene_id = Id,
            ins_state = ?ins_state_client,
            ins_type = ?T_INS_SKY_RAND,
            call_back = {main_instance_mng, ins_random_complete, {ItemUsePrizeId}},
            next_scene_call = {main_ins, next_scene_id, {}},
            playerIdOrtermId = get(?pd_id)
        })
    of
        {ok, _NewSceneId} -> {ok, Id};
        error -> {error, ins_not_over}
    end.

handle_start(camp_mng, CFGId) ->
    ?INFO_LOG("camp_mng handle_start ~p", [CFGId]),
    handle_start(
        #fight_start
        {
            scene_id = CFGId,
            ins_state = ?ins_state_online,
            ins_type = ?T_INS_SHENMO,
            call_back = {camp_mng, {}, {}},
            next_scene_call = {load_cfg_main_ins, next_scene_id, {}},
            playerIdOrtermId = get(?pd_id),
            is_notice_enter_scene = ?TRUE,
            is_notice_kill_player = ?TRUE
        });

handle_start(camp_mng_client, CFGId) ->
    handle_start(
        #fight_start
        {
            scene_id = CFGId,
            ins_state = ?ins_state_client,
            ins_type = ?T_INS_SHENMO,
            call_back = {camp_mng, ins_complete, {}},
            next_scene_call = {load_cfg_main_ins, next_scene_id, {}},
            playerIdOrtermId = get(?pd_id),
            is_notice_enter_scene = ?TRUE,
            is_notice_kill_player = ?TRUE
        });

handle_start(daily_activity_mng, {fish_room, NewSceneId, SceneId}) ->
    case load_cfg_scene:get_pid(NewSceneId) of
        ?none ->
            handle_start(daily_activity_mng, {6, SceneId});
        _Pid ->
            case scene_mng:enter_scene_request(NewSceneId) of
                approved ->
                    put(?main_instance_id_ing, SceneId),

                    daily_activity_service:call_enter_fishing_room(NewSceneId, get(?pd_id)),

                    system_log:info_enter_copy(get(?pd_id), SceneId),
                    {ok, NewSceneId};
                E ->
                    ?ERROR_LOG("enter_ins error: ~p ~p", [SceneId, E]),
                    error
            end
    end;


handle_start(daily_activity_mng, {DailyType, Arg}) ->
    case DailyType of
        1 ->
            SceneId = Arg,
            handle_start(#fight_start{scene_id = SceneId, ins_state = ?ins_state_client, ins_type = ?T_INS_DAILY_1,
                next_scene_call = {},
                call_back = {daily_activity_mng, ins_complete, DailyType}, playerIdOrtermId = get(?pd_id)});
        2 ->
            {SceneId, TimeOut} = Arg,
            handle_start(#fight_start{scene_id = SceneId, ins_state = ?ins_state_client, ins_type = ?T_INS_DAILY_2,
                next_scene_call = {},
                call_back = {daily_activity_mng, ins_complete, DailyType}, playerIdOrtermId = get(?pd_id), ins_limit_time = TimeOut});
        4 ->
            SceneId = Arg,
            handle_start(#fight_start{scene_id = SceneId, ins_state = ?ins_state_client, ins_type = ?T_INS_DAILY_4,
                next_scene_call = {},
                call_back = {daily_activity_mng, ins_complete, DailyType}, playerIdOrtermId = get(?pd_id)});
        5 ->
            SceneId = Arg,
            handle_start(#fight_start{scene_id = SceneId, ins_state = ?ins_state_client, ins_type = ?T_INS_DAILY_5,
                next_scene_call = {},
                call_back = {daily_activity_mng, ins_complete, DailyType}, playerIdOrtermId = get(?pd_id)});
        6 ->
            SceneId = Arg,
            handle_start(#fight_start{scene_id = SceneId, ins_state = ?ins_state_client, ins_type = ?T_INS_DAILY_6,
                next_scene_call = {},
                call_back = {daily_activity_mng, ins_complete, DailyType}, playerIdOrtermId = get(?pd_id)});
        _E ->
            ?ERROR_LOG("known type:~p", [_E]),
            pass
    end;

handle_start(daily_activity_mng, {DailyType, SceneId, CallBack}) ->
    handle_start(#fight_start{scene_id = SceneId, ins_state = ?ins_state_client, ins_type = ?T_INS_DAILY_3,
        next_scene_call = {daily_activity_mng, next_scene_id, {DailyType, CallBack}},
        call_back = {daily_activity_mng, ins_complete, DailyType}, playerIdOrtermId = get(?pd_id)});


handle_start(sky_mng_client, {Type, CFGId}) ->
    handle_start(#fight_start{scene_id = CFGId, ins_state = ?ins_state_client, ins_type = ?T_INS_SKY_MIGONG,
        call_back = {sky_mng, ins_complete, Type},
        next_scene_call = {sky_mng, random_scene_id, Type},
        playerIdOrtermId = get(?pd_id),
        is_notice_enter_scene = ?TRUE, is_notice_kill_player = ?TRUE});

handle_start(abyss_mng, {AbyssInsCFG, IsMatch}) ->
    CfgSceneId = AbyssInsCFG#main_ins_cfg.id,
    ?DEBUG_LOG("abyss_mng scene_id ---------------:~p", [CfgSceneId]),
    SceneId = scene:make_scene_id(?SC_TYPE_MAIN_INS,
        #fight_start{
            scene_id = CfgSceneId, ins_state = ?ins_state_client, ins_type = ?T_INS_XUKONG,
            call_back = {abyss_mng, ins_complete, {}},
            is_notice_enter_scene = ?TRUE
        },
        AbyssInsCFG#main_ins_cfg.id, get(?pd_id)),
    CurrentPid = get(?pd_scene_pid),
    ScenePid = load_cfg_scene:get_pid(SceneId),
    if
        CurrentPid =:= ScenePid ->
            scene_mng:leave_scene(),
            ScenePid ! {'@stop@', ?normal},
            tick_exit_pid(ScenePid, 0);
        true -> ok
    end,
    main_instance_mng:leave_main_instance_clear_data(),
    cost(AbyssInsCFG#main_ins_cfg.sp_cost, AbyssInsCFG#main_ins_cfg.cost, {AbyssInsCFG#main_ins_cfg.type, AbyssInsCFG#main_ins_cfg.sub_type}),

    case IsMatch of
        ?TRUE ->
            scene_sup:start_client_scene(SceneId, ?false, #run_arg{match_level = get(?pd_level), is_match = ?TRUE, start_scene_career = get(?pd_career)});
        ?FALSE ->
            scene_sup:start_client_scene(SceneId, ?false, #run_arg{match_level = get(?pd_level), start_scene_career = get(?pd_career)})
    end,
    case scene_mng:enter_scene_request(SceneId) of
        approved ->
            put(?current_pata_instance_id, CfgSceneId), 
            ok;
        _E -> error
    end.

handle_start(FightStart) ->
    SceneId = FightStart#fight_start.scene_id,
    Cfg = load_cfg_main_ins:lookup_main_ins_cfg(SceneId),

    NewSceneId = scene:make_scene_id(?SC_TYPE_MAIN_INS, FightStart, SceneId, FightStart#fight_start.playerIdOrtermId),
    %?DEBUG_LOG("NewSceneId----------------:~p",[NewSceneId]),

    case can_enter_ins(NewSceneId, Cfg) of
        ?false ->
            ?ERROR_LOG("enter ins error:~w~n", [FightStart]),
            error;
        ?true ->
            case Cfg#main_ins_cfg.type of
                ?T_INS_MAIN ->
                    case can_get_prize_from_room(SceneId) of
                        ?true ->
                            cost(Cfg#main_ins_cfg.sp_cost, Cfg#main_ins_cfg.cost, {Cfg#main_ins_cfg.type, Cfg#main_ins_cfg.sub_type}),
                            %% 统计赏金任务挑战副本
                            count_bounty_fight_room(Cfg#main_ins_cfg.sub_type),
                            main_instance_mng:add_challenge_times(SceneId),
                            main_instance_mng:push_challenge_info_by_id(SceneId),
                            attr_new:set(?pd_cost_sp, Cfg#main_ins_cfg.sp_cost),
                            attr_new:set(?pd_can_get_prize_from_room, true);
                        _ ->
                            ?return_err(?ERR_MAX_COUNT)
                    end;
                _ ->
                    cost(Cfg#main_ins_cfg.sp_cost, Cfg#main_ins_cfg.cost, {Cfg#main_ins_cfg.type, Cfg#main_ins_cfg.sub_type}),
                    pass
            end,
            %?DEBUG_LOG("ChallengeTimes--------:~p---------MaxChallengeTimes------:~p",[ChallengeTimes, MaxChallengeTimes]),
            Pid =
                case Cfg#main_ins_cfg.is_monster_match_level of
                    ?TRUE ->
                        case FightStart#fight_start.ins_state of
                            ?ins_state_client ->
                                scene_sup:start_client_scene(NewSceneId, ?false, #run_arg{match_level = get(?pd_level), is_match = ?TRUE,
                                    start_scene_career = get(?pd_career)});
                            _ ->
                                scene_sup:start_scene(NewSceneId, #run_arg{match_level = get(?pd_level), is_match = ?TRUE})
                        end;
                    ?FALSE ->
                        case FightStart#fight_start.ins_state of
                            ?ins_state_client ->
                                scene_sup:start_client_scene(NewSceneId, ?false, #run_arg{match_level = get(?pd_level),
                                    start_scene_career = get(?pd_career)});
                            _ ->
                                scene_sup:start_scene(NewSceneId)
                        end
                end,

            ?if_(not is_pid(Pid), ?return_err(Pid)),
            main_instance_mng:init_open_card_data(SceneId),
            main_ins:insert_scene(NewSceneId),
            case scene_mng:enter_scene_request(NewSceneId) of
                approved ->
                    case Cfg#main_ins_cfg.type of
                        ?T_INS_FREE ->
                            pass;
                        ?T_INS_COURSE ->
                            pass;
                        ?T_INS_SKY_RAND ->
                            pass;
                        ?T_INS_SKY_MIGONG ->
                            pass;
                        _ ->
                            achievement_mng:init_instance_ac(Cfg#main_ins_cfg.stars, [])
                    end,
                    %% 进入钓鱼副本，保存玩家
                    case FightStart#fight_start.ins_type of
                        ?T_INS_DAILY_6 ->
                            daily_activity_service:call_enter_fishing_room(NewSceneId, get(?pd_id));
                        _ ->
                            pass
                    end,
                    put(?main_instance_id_ing, SceneId),

                    system_log:info_enter_copy(get(?pd_id), SceneId),
                    {ok, NewSceneId};
                E ->
                    ?ERROR_LOG("enter_ins error: ~p ~p", [SceneId, E]),
                    error
            end

    end.

can_enter_ins(_MakeSceneId, ?none) -> ?false;
can_enter_ins(MakeSceneId, #main_ins_cfg{ins_id = InsId, type=_Type}) ->
    util:can
    ([
        fun() ->
            get(?pd_level) >= load_cfg_scene:get_enter_level_limit(MakeSceneId)
        end,

        fun() -> 
            MakeSceneId =/= get(?pd_scene_id)
        end,

        fun() ->
            case load_cfg_main_ins:lookup_main_ins_cfg(load_cfg_scene:get_config_id(MakeSceneId)) of
                #main_ins_cfg{ins_id = InsId} -> ?true;
                #main_ins_cfg{type = ?T_INS_PORTAL} -> ?true;
                _ -> ?false
            end
        end
    ]).

%% 进入副本消耗，1消耗costId 2.消耗次数
cost(SpCost, CostId, {_Type, _SubType}) ->
    PlayerSP = get(?pd_sp),
    if
        SpCost =:= 0 ->
            ok;
        (PlayerSP - SpCost) >= 0 ->
            player:cost_value_if_enough(?pd_sp, SpCost);
        true ->
            ?return_err(?ERR_SP_NOT_ENOUGHT)
    end,
    case CostId of
        1 ->
            ok;
        CostId ->
            case cost:cost(CostId, ?FLOW_REASON_ENTER_FUBEN) of
                {error, _Reason} ->
                    ?return_err(?ERR_COST_NOT_ENOUGH);
                _ ->
                    ok
            end
    end.

%% ins_complete() ->
%%     ok.


tick_exit_pid(_ScenePid, 10) -> ok;
tick_exit_pid(ScenePid, N) ->
    case erlang:is_process_alive(ScenePid) of
        true ->
            timer:sleep(100),
            tick_exit_pid(ScenePid, N + 1);
        false -> ok
    end.

%%玩家进副本，判断玩家体力是否足够
is_enough_sp(NeedSp) ->
    PlayerSP = get(?pd_sp),
    if
        (PlayerSP - NeedSp) >= 0 ->
            ?true;
        true ->
            ?false
    end.


is_can_get_prize_from_room() ->
    attr_new:get(?pd_can_get_prize_from_room, false).


get_instance_type(FightStart) ->
    #fight_start{ins_type = Type} = FightStart,
    Type.

can_get_prize_from_room(SceneId) ->
    Cfg = load_cfg_main_ins:lookup_main_ins_cfg(SceneId),
    ChallengeTimes = main_instance_mng:get_challenge_times(SceneId),
    MaxChallengeTimes = main_instance_mng:get_max_challenge_times(SceneId),
    PlayerSP = get(?pd_sp),
    % ?INFO_LOG("ChallengeTimes:~p, MaxChallengeTimes:~p", [ChallengeTimes, MaxChallengeTimes]),
    % ?INFO_LOG("is_enough_sp:~p", [PlayerSP - Cfg#main_ins_cfg.sp_cost]),
    if
        ChallengeTimes >= MaxChallengeTimes ->
            {?false, max_count};
        (PlayerSP - Cfg#main_ins_cfg.sp_cost) < 0 ->
            % ?return_err(?ERR_CLEAN_MAIN_INS_SP_ENOUGH),
            {?false, sp_not_enough};
        true ->
            ?true
    end.

can_clean_room_times(SceneId, Times) ->
    Cfg = load_cfg_main_ins:lookup_main_ins_cfg(SceneId),
    ChallengeTimes = main_instance_mng:get_challenge_times(SceneId),
    MaxChallengeTimes = main_instance_mng:get_max_challenge_times(SceneId),
    PlayerSP = get(?pd_sp),
    if
        (PlayerSP - Cfg#main_ins_cfg.sp_cost * Times) < 0 ->
            ?return_err(?ERR_CLEAN_MAIN_INS_SP_ENOUGH);
        (ChallengeTimes + Times) > MaxChallengeTimes ->
            ?false;
        true ->
            ?true
    end.


count_bounty_fight_room(RoomType) ->
    case RoomType of
        1 ->
            bounty_mng:do_bounty_task(?BOUNTY_TASK_NORMAL_ROOM, 1),
            ok;
        2 ->
            bounty_mng:do_bounty_task(?BOUNTY_TASK_HARD_ROOM, 1),
            ok;
        3 ->
            bounty_mng:do_bounty_task(?BOUNTY_TASK_EMENG_ROOM, 1),
            ok;
        _ ->
            pass
    end.

