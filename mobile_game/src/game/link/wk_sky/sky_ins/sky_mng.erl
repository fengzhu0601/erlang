%%%-------------------------------------------------------------------
%%% @author yujian
%%% @doc 天空之城大副本
%%%-------------------------------------------------------------------
-module(sky_mng).

-include_lib("pangzi/include/pangzi.hrl").
% -include_lib("config/include/config.hrl").

-include("inc.hrl").
-include("player.hrl").
-include("player_mod.hrl").
-include("main_ins_struct.hrl").
-include("system_log.hrl").
-include("sky_struct.hrl").
-include("rank.hrl").
-include("scene.hrl").
-include("load_cfg_sky.hrl").
-include("load_cfg_main_ins.hrl").

-export
([
    ins_complete/3
    , enter_scene/1
    , random_scene_id/2
    , prize/3
    , lookup_cfg/2
]).

load_db_table_meta() ->
    [
        #db_table_meta{name = ?player_sky_ins_tab,
            fields = ?record_fields(?player_sky_ins_tab),
            shrink_size = 30,
            flush_interval = 10}
    ].


create_mod_data(_SelfId) -> ok.

load_mod_data(PlayerId) ->
    case dbcache:lookup(?player_sky_ins_tab, PlayerId) of
        [] -> put(?pd_sky_ins_tab, 0);
        [Tab] -> put(?pd_sky_ins_tab, Tab)
    end.

init_client() -> ok.

view_data(Acc) -> Acc.

handle_frame({?frame_levelup, _OldLevel}) ->
    {level, Level} = sky_service:lookup_cfg(#sky_ins_cfg.level_limit),
    Lv = get(?pd_level),
    if
        Level =< Lv ->
            put(?pd_sky_ins_tab, #player_sky_ins_tab{player_id = get(?pd_id)});
        true -> ok
    end;

handle_frame(Frame) -> ?err({unknown_frame, Frame}).

handle_msg(_FromMod, {activity_complete}) ->
    case get(?pd_sky_ins_tab) of
        0 -> ok;
        SkyInsTab -> prize(SkyInsTab, get(?pd_career), get(?pd_level))
    end;

handle_msg(_FromMod, {player_enter_scene, {_SceneId, _CallArg}}) ->
    {_, _, {FightStart, _}} = get(?pd_scene_id),
    sky_service:add_player(get(?pd_id), self(), get(?pd_career), get(?pd_level), get(?pd_combat_power), get(?pd_camp_self_camp), FightStart, 1),
    put(?pd_sky_ins_player_state, 1);

handle_msg(_FromMod, {player_leave_scene, {SceneId, _CallArg}}) ->
    sky_service:add_player(get(?pd_id), self(), get(?pd_career), get(?pd_level), get(?pd_combat_power), get(?pd_camp_self_camp), SceneId, 0),
    put(?pd_sky_ins_player_state, 0);

handle_msg(_FromMod, {player_kill_player, {_SceneId, {_EnemyPid, _EnemyPlayerId}}}) ->
    SkyInsTab = get(?pd_sky_ins_tab),
    KillCount = SkyInsTab#player_sky_ins_tab.kill_player,
    ranking_lib:update(?ranking_sky_ins_kill_player, get(?pd_id), KillCount + 1),
    ?player_send(sky_ins_sproto:pkg_msg(?PUSH_KILL_COUNT, {SkyInsTab#player_sky_ins_tab.kill_monster, KillCount + 1})),
    put(?pd_sky_ins_tab, SkyInsTab#player_sky_ins_tab{kill_player = KillCount + 1});

handle_msg(_FromMod, {player_kill_monster, {_SceneId, {_MonsterPid, MonsterId}}}) ->
    ?DEBUG_LOG("sky_mng   player_kill_monster------------------"),
    SkyInsTab = get(?pd_sky_ins_tab),
    case lists:member(MonsterId, ?SKY_INS_BOX_MONSTER_IDS) of
        false ->
            ?DEBUG_LOG("sky mng-------------------"),
            KillCount = SkyInsTab#player_sky_ins_tab.kill_monster,
            ranking_lib:update(?ranking_sky_ins_kill_monster, get(?pd_id), KillCount + 1),
            ?player_send(sky_ins_sproto:pkg_msg(?PUSH_KILL_COUNT, {KillCount + 1, SkyInsTab#player_sky_ins_tab.kill_player})),
            put(?pd_sky_ins_tab, SkyInsTab#player_sky_ins_tab{kill_monster = KillCount + 1});
        true ->
            ?DEBUG_LOG("add_box_kill_info------------------------------"),
            sky_service:add_box_kill_info(MonsterId, [])
    end;

handle_msg(_FromMod, {complete, {_SceneId, _CallArg}}) ->
    ok;

handle_msg(_FromMod, Msg) ->
    ?err({unknown_msg, Msg}).

%% @doc 上线判断是否刷新
online() ->
    case get(?pd_sky_ins_tab) of %是否选择种族
        0 -> ok;
        SkyInsTab ->
            Time = sky_service:get_end_time(),
            JoinTime = SkyInsTab#player_sky_ins_tab.join_time,
            %prize(SkyInsTab, get(?pd_career), get(?pd_level)),
            if
                JoinTime =/= Time ->
                    prize(SkyInsTab, get(?pd_career), get(?pd_level)),
                    put(?pd_sky_ins_tab, #player_sky_ins_tab{player_id = get(?pd_id)});
                true ->
                    ok
            end
    end.

offline(_SelfId) ->
    ok.

save_data(_SelfId) ->
    SkyInsTab = get(?pd_sky_ins_tab),
    ?ifdo(SkyInsTab =/= 0,
        update_data()).

update_data() ->
    case get(?pd_sky_ins_tab) of
        0 -> ok;
        Tab -> dbcache:update(?player_sky_ins_tab, Tab)
    end.

prize(SkyInsTab, PlayerCareer, PlayerLevel) ->
    case load_career_attr:get_lv_totle_exp(PlayerCareer, PlayerLevel) of
        none -> {error, ?ERR_MAX_LEVEL};
        LevelupExp ->
            PlayerId = get(?pd_id),
            KillClientMonster = SkyInsTab#player_sky_ins_tab.kill_client_monster,
            KillMonster = SkyInsTab#player_sky_ins_tab.kill_monster,
            KillPlayer = SkyInsTab#player_sky_ins_tab.kill_player,
            case {?EXP_PRIZE_CLIENT(LevelupExp, KillClientMonster), ?EXP_PRIZE_ONLINE(LevelupExp, KillPlayer, KillMonster)} of
                {0, 0} ->
                    case get(?pd_sky_ins_player_state) of
                        1 ->
                            ?player_send(sky_ins_sproto:pkg_msg(?PUSH_ACTIVITY_END, {0, 0, []})),
                            ?player_send(sky_ins_sproto:pkg_msg(?PUSH_ACTIVITY_END_PRIZE, {0, 0, 0, 0, 0, []}));
                        _ -> ok
                    end;
                {ClientGetExp, OnlineGetExp} -> %参加过本次活动 1.发送经验 2.发送邮件奖励
                    ?DEBUG_LOG("kill player rank ---------------------:~p",[ranking_lib:get_rank_order(?ranking_sky_ins_kill_player, PlayerId)]),
                    Fun = fun(out_rank, Index) ->
                            ?DEBUG_LOG("prize-------------------:~p", [lookup_cfg(?sky_rank_cfg, ?SKY_INS_DEFAULT_RANK_CFG, Index)]),
                            {0, lookup_cfg(?sky_rank_cfg, ?SKY_INS_DEFAULT_RANK_CFG, Index)};
                        ({0, 0}, Index) ->
                            ?DEBUG_LOG("prize2-------------------:~p", [lookup_cfg(?sky_rank_cfg, ?SKY_INS_DEFAULT_RANK_CFG, Index)]),
                            {0, lookup_cfg(?sky_rank_cfg, ?SKY_INS_DEFAULT_RANK_CFG, Index)};
                        ({Order, _KillCount}, Index) ->
                            ?DEBUG_LOG("prize-3------------------:~p", [lookup_cfg(?sky_rank_cfg, ?SKY_INS_DEFAULT_RANK_CFG, Index)]),
                            {Order, lookup_cfg(?sky_rank_cfg, Order, Index)}
                    end,
                    {MonsterRank, MonsterPrize} = Fun(ranking_lib:get_rank_order(?ranking_sky_ins_kill_monster, PlayerId), #sky_rank_cfg.monster_prize),
                    {WarriorRank, WarriorPrize} = Fun(ranking_lib:get_rank_order(?ranking_sky_ins_kill_player, PlayerId), #sky_rank_cfg.warrior_prize),
                    case ClientGetExp of
                        0 -> ok;
                        ClientGetExp ->
                            case get(?pd_sky_ins_player_state) of
                                1 ->
                                    ?player_send(sky_ins_sproto:pkg_msg(?PUSH_ACTIVITY_END, {KillClientMonster, ClientGetExp, []}));
                                _ ->
                                    mail_mng:send_sysmail(PlayerId, ?S_MAIL_SKY_INS_CLIENT, [], [{?PL_EXP, ClientGetExp}])
                            end
                    end,
                    case OnlineGetExp of
                        0 -> ok;
                        OnlineGetExp ->
                            case get(?pd_sky_ins_player_state) of
                                1 ->
                                    ?player_send(sky_ins_sproto:pkg_msg(?PUSH_ACTIVITY_END_PRIZE, {KillMonster, MonsterRank, KillPlayer, WarriorRank, OnlineGetExp, []}));
                                _ ->
                                    mail_mng:send_sysmail(PlayerId, ?S_MAIL_SKY_INS_ONLINE, [], [{?PL_EXP, OnlineGetExp}])
                            end
                    end,
                    ?DEBUG_LOG("MonsterRank-----:~p-----MonsterPrize-----:~p",[MonsterRank, MonsterPrize]),
                    prize:prize_mail(MonsterPrize, ?S_MAIL_SKY_INS_RANK_KILL_MONSTER, ?FLOW_REASON_SKY),
                    prize:prize_mail(WarriorPrize, ?S_MAIL_SKY_INS_RANK_KILL_PEOPLE, ?FLOW_REASON_SKY)
            end
    end,
    ok.

%% 1.怪物等级提升 2.宝箱提升
enter_scene(Type) ->
    case Type of
        1 ->
            SceneId = random_scene_id(Type),
            main_ins_mod:handle_start(sky_mng_client, {Type, SceneId}),
            SceneId;
        2 -> %1匹配敌对玩家 2.进入敌对玩家场景
            case get(?pd_camp_self_camp) of
                0 -> ?return_err(?ERR_CAMP_NOT_JOIN_CAMP);
                _ ->
                    FightStart = case sky_service:select_player() of
                                     '$end_of_table' ->
                                         SceneId = random_scene_id(Type),
                                         #fight_start{scene_id = SceneId,
                                             ins_state = ?ins_state_online,
                                             ins_type = ?T_INS_SKY_MIGONG,
                                             call_back = {?MODULE, {}, Type},
                                             next_scene_call = {?MODULE, random_scene_id, Type},
                                             is_notice_enter_scene = ?TRUE,
                                             is_notice_kill_player = ?TRUE,
                                             is_notice_kill_monster = ?TRUE,
                                             playerIdOrtermId = get(?pd_id)};
                                     [{_PlayerId, _SceneId}] ->
                                         sky_service:add_player(get(?pd_id), self(), get(?pd_level), get(?pd_combat_power), get(?pd_camp_self_camp), _SceneId, 0),
                                         [PlayerInfo] = ets:lookup(?sky_ins_player_info, _PlayerId),
                                         sky_service:add_player(_PlayerId, PlayerInfo#sky_ins_player_info.player_pid,
                                             PlayerInfo#sky_ins_player_info.player_level,
                                             PlayerInfo#sky_ins_player_info.player_power,
                                             PlayerInfo#sky_ins_player_info.player_camp, _SceneId, 0),
                                         {_, _, {SceneFightStart, _}} = _SceneId,
                                         SceneFightStart
                                 end,
                    main_ins_mod:handle_start(FightStart),
                    FightStart#fight_start.scene_id
            end
    end.

%% 单机副本回调函数
ins_complete(_, {_Id, _KillMonster, _WaveNum, _DieCount, KillMinMonsterCount, _KillBossMonsterCount,  MaxDoubleHit, ShoujiCount, _PassTime, _ReliveNum, _Prize, MonsterBidList}, _CallArg) ->
    ?DEBUG_LOG("sky mng ------------------------------"),
    SkyInsTab = get(?pd_sky_ins_tab),
    if
        KillMinMonsterCount =:= 0 -> ok;
        true ->
            KillCount = SkyInsTab#player_sky_ins_tab.kill_client_monster,
            EndTime = sky_service:get_end_time(),
            put(?pd_sky_ins_tab, SkyInsTab#player_sky_ins_tab{kill_client_monster = KillCount + KillMinMonsterCount, join_time = EndTime})
    end;

ins_complete(_InsState, {_Id, _KillMonster, _WaveNum, _DieCount, KillMinMonsterCount,
    _KillBossMonsterCount, _Prize, _MaxDoubleHit, _ShoujiCount, _PassTime, _MonsterBidList}, _CallArg) ->
    ins_complete(_InsState, {_Id, _KillMonster, _WaveNum, _DieCount, KillMinMonsterCount, _KillBossMonsterCount, _PassTime, _Prize}, _CallArg);

ins_complete(_InsState, _, _CallArg) ->
    ok.

random_scene_id(Type) ->
    random_scene_id(Type, nil).

random_scene_id(Type, _SceneCFGId) ->
    case sky_service:is_open() of
        ?FALSE -> ?none;
        ?TRUE ->
            FunFoldl = fun(SceneId, {RandomMaxNum, SceneRand}) ->
                case load_cfg_sky:lookup_sky_scene_random_cfg(SceneId) of
                    #sky_scene_random_cfg{scene_id = SceneId, enter_per = Per} ->
                        {RandomMaxNum + Per, [{SceneId, RandomMaxNum + Per} | SceneRand]};
                    _ ->
                        {RandomMaxNum, SceneRand}
                end
            end,
            {TotleRandNum, SceneRandList} = lists:foldl(FunFoldl, {0, []}, load_cfg_sky:lookup_cfg(all, Type)),
            SceneId = case com_util:random_probo(SceneRandList, TotleRandNum) of
                          [] -> com_util:rand(load_cfg_sky:lookup_cfg(all, Type));
                          Scene_id -> Scene_id
                      end,
            if
                SceneId =:= _SceneCFGId ->
                    com_util:rand(lists:delete(_SceneCFGId, load_cfg_sky:lookup_cfg(all, Type)));
                true ->
                    SceneId
            end
    end.

lookup_cfg(all, Type) ->
    Fun = fun(Id) ->
        MainCFG = main_ins:lookup_main_ins_cfg(Id),
        MainCFG#main_ins_cfg.sub_type =:= Type
    end,
    IdList = main_ins:lookup_group_main_ins_cfg(#main_ins_cfg.type, ?T_INS_SKY_MIGONG),
    lists:filter(Fun, IdList).

lookup_cfg(?sky_rank_cfg, Key, Index) ->
    load_cfg_sky:lookup_cfg(?sky_rank_cfg, Key, Index).
