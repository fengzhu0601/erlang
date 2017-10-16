%%%-------------------------------------------------------------------
%%% @author yujian
%%% @doc

%%%-------------------------------------------------------------------
-module(camp_handle_client).

-include("inc.hrl").
-include("player.hrl").
-include("handle_client.hrl").

-include("camp_struct.hrl").
-include("main_ins_struct.hrl").
-include("load_cfg_main_ins.hrl").
-include("system_log.hrl").

-export
([
    check_instance/4, %验证副本是否已经解锁
    handle_client/2
]).

handle_client({Pack, Arg}) ->
    case task_open_fun:is_open(?OPEN_CAMP) of
        ?false -> ?return_err(?ERR_NOT_OPEN_FUN);
        ?true -> handle_client(Pack, Arg)
    end.

%% @doc 推送敌方玩家入侵信息
handle_client(?MSG_ENEMY_PLAYERS_DATA, {InstanceId, Event}) ->
    put(?camp_open_panel, Event),
    IsPush = case get(?pd_camp_self_camp) of
                 ?CAMP_GOD -> true;
                 ?CAMP_MAGIC -> true;
                 {_, ?CAMP_GOD} -> true;
                 {_, ?CAMP_MAGIC} -> true;
                 _ -> false
             end,
    case IsPush of
        true ->
            case Event of
                1 ->
                    PlayerList = camp_service:get_instance_player(InstanceId),
                    Fun = fun({_Pid, PlayerId}) ->
                        [PlayerName, CombatPower] = player:lookup_info(PlayerId, [?pd_name, ?pd_combat_power]),
                        case dbcache:lookup(?player_camp_tab, PlayerId) of
                            [] ->
                                {PlayerId, PlayerName, CombatPower, 0, 0};
                            [CampTab] ->
                                CampId =
                                    case CampTab#player_camp_tab.self_camp of
                                        {_, _} -> ?CAMP_PERSON;
                                        Camp -> Camp
                                    end,
                                {PlayerId, PlayerName, CombatPower, CampId, CampTab#player_camp_tab.exploit, InstanceId}
                        end
                    end,
                    ?player_send(camp_sproto:pkg_msg(?MSG_ENEMY_PLAYERS_DATA, {lists:map(Fun, lists:sublist(PlayerList, 2))}));
                0 ->
                    ok
            end;
        false -> ok
    end;


%% @doc 推送敌方玩家入侵信息
handle_client(?PUSH_ENEMY_PLAYER_DATA, {InstanceId, PlayerId, CampId, Exploit}) ->
    case get(?camp_open_panel) of
        1 ->
            [PlayerName, CombatPower] = player:lookup_info(PlayerId, [?pd_name, ?pd_combat_power]),
            ?INFO_LOG("推送敌方玩家入侵信息 ~p", [{PlayerId, PlayerName, CombatPower, CampId, Exploit, InstanceId}]),
            ?player_send(camp_sproto:pkg_msg(?PUSH_ENEMY_PLAYER_DATA, {PlayerId, PlayerName, CombatPower, CampId, Exploit, InstanceId}));

        _ ->
            ok
    end;



%% @doc 拉取个人信息
handle_client(?GET_CAMP_PLAYER_DATA, {}) ->
    Info = camp_mng:get_camp_info(),
    ?player_send(camp_sproto:pkg_msg(?GET_CAMP_PLAYER_DATA, Info));

%% @doc 拉取神魔系统公共信息
handle_client(?GET_CAMP_DATA, {}) ->
    case camp_service:get_camp_info(get(?pd_camp_self_camp)) of
        {error, Other} -> ?return_err(Other);
        Res -> ?player_send(camp_sproto:pkg_msg(?GET_CAMP_DATA, Res))
    end;

%% @doc 拉取处于该副本的敌人玩家
handle_client(?GET_ENEMY_LIST, {InstanceId}) ->
    PlayerList = camp_service:get_instance_player(InstanceId),
    ?player_send(camp_sproto:pkg_msg(?GET_ENEMY_LIST, {get_player_list(PlayerList)}));

%% @doc 拉取排行榜信息
handle_client(?GET_RANKING_LIST, {Type, StartPos, Num}) ->
    RankInfo = camp_mng:select_rank(Type, StartPos, Num),
    ?INFO_LOG("GET_RANKING_LIST RankInfo ~p", [RankInfo]),
    ?player_send(camp_sproto:pkg_msg(?GET_RANKING_LIST, RankInfo));

%% @doc 拉取事件信息
handle_client(?GET_EVENT_LIST, {StartPos, Num}) ->
    case camp_service:is_fight() of
        true ->
            FunMap = fun({?EVENT_TYPE_KILL_BOSS, PlayerId, PlayerName, CampId, InstanceId, CampPoint}) ->
                {?EVENT_TYPE_KILL_BOSS, PlayerId, PlayerName, CampId, InstanceId, CampPoint, 0, <<>>};
                ({?EVENT_TYPE_KILL_PLAYER, PlayerId, PlayerName, CampId, InstanceId, CampPoint, ToPlayerId, ToPlayerName}) ->
                    {?EVENT_TYPE_KILL_PLAYER, PlayerId, PlayerName, CampId, InstanceId, CampPoint, ToPlayerId, ToPlayerName};
                (_) -> []
            end,
            {EventLen, EventList} = camp_service:select_event(StartPos, Num),
            ResEventList = lists:map(FunMap, EventList),
            {GodPoint, MagicPoint} = camp_service:get_point(),
            PrizeList = camp_mng:prize_list(get(?pd_camp_fight_instance)),
            Fun = fun(Key) ->
                case lists:keyfind(Key, 1, PrizeList) of
                    false -> 0;
                    {_, Num1} -> Num1
                end
            end,
            Money = Fun(?PL_MONEY),
            Diamond = Fun(?PL_DIAMOND),
            Res = {GodPoint, MagicPoint, Money, Diamond, EventLen, ResEventList},
            ?player_send(camp_sproto:pkg_msg(?GET_EVENT_LIST, Res));

        false ->
            ?player_send(camp_sproto:pkg_msg(?GET_EVENT_LIST, {0, 0, 0, 0, 0, []}))
    end;

%% @doc 选择人神魔
handle_client(?MSG_SELECT_CAMP, {CampId}) ->
    case camp_mng:join_camp(CampId) of
        {error, Other} -> ?return_err(Other);
        _ ->
            case camp_service:is_open() of
                true -> ok;
                false -> camp_service:open_fun(get(?pd_id), get(?pd_name))
            end,
            ?player_send(camp_sproto:pkg_msg(?MSG_SELECT_CAMP, {}))
    end;


%% @doc 每次活动人族选择阵营
handle_client(?MSG_HUMAN_SELECT_CAMP, {CampId}) ->
    ?INFO_LOG("MSG_HUMAN_SELECT_CAMP "),
    case camp_service:is_fight() of
        true -> ?return_err(?ERR_CAMP_IS_FIGHT);
        false ->
            case camp_mng:person_select_camp(CampId) of
                {error, Other} -> ?return_err(Other);
                _ -> ?player_send(camp_sproto:pkg_msg(?MSG_HUMAN_SELECT_CAMP, {}))
            end
    end;

%% @doc 个人试炼,0.验证次数 1.验证副本 进入副本
handle_client(?MSG_PLAYER_ENTER_INSTANCE, {InstanceId}) ->
%%     {GodCount, MagicCount} = get(?pd_camp_enter_count),
    {GodCount, MagicCount} = {20,20},
    {GodIns, MagicIns} = get(?pd_camp_open_instance),
    CampInsCFG = load_cfg_camp:lookup_cfg(?main_ins_cfg, InstanceId),
    {InsList, Count} =
        case CampInsCFG#main_ins_cfg.sub_type of %验证进入次数，在进入场景后减去次数
            ?CAMP_GOD ->
                ?ifdo(GodCount =:= 0, ?return_err(?ERR_CAMP_NO_ENOUGH_COUNT)),
                {GodIns, {GodCount - 1, MagicCount}};

            ?CAMP_MAGIC ->
                ?ifdo(MagicCount =:= 0, ?return_err(?ERR_CAMP_NO_ENOUGH_COUNT)),
                {MagicIns, {GodCount, MagicCount - 1}}
        end,
    case check_instance(InsList, CampInsCFG, get(?pd_camp_self_camp), 1) of %验证副本确认可以进入
        false ->
            ?return_err(?ERR_CAMP_CHECH_INSTANCE_ERROR);

        true ->
            case cost:cost(CampInsCFG#main_ins_cfg.cost, ?FLOW_REASON_CAMP) of
                ok ->
                    case main_ins_mod:handle_start(camp_mng, InstanceId) of
                        {ok, _} ->
                            put(?pd_camp_enter_count, Count),
                            put(?pd_camp_fight_type, 1);

                        error ->
                            error
                    end;

                {error, Other} ->
                    %% 发送错误码给前端
                    ?player_send(player_sproto:pkg_msg(?MSG_PLAYER_ERROR,
                        {?MSG_PLAYER_ENTER_INSTANCE,?ERR_COST_MONEY_FAIL,<<>>})),
                    ?return_err(Other)
            end
    end;

%% @doc 入侵, 0.验证次数 1.验证副本 进入副本
handle_client(?MSG_PLAYER_ENTER_ENEMY_INSTANCE, {InstanceId}) ->
    {GodCount, MagicCount} = get(?pd_camp_enter_count),
    {GodIns, MagicIns} = get(?pd_camp_open_instance),
    CampInsCFG = load_cfg_camp:lookup_cfg(?main_ins_cfg, InstanceId),

    {InsList, Count} = case CampInsCFG#main_ins_cfg.sub_type of %验证进入次数
                           ?CAMP_GOD ->
                               ?ifdo(GodCount =:= 0, ?return_err(?ERR_CAMP_NO_ENOUGH_COUNT)),
                               {GodIns, {GodCount - 1, MagicCount}};
                           ?CAMP_MAGIC ->
                               ?ifdo(MagicCount =:= 0, ?return_err(?ERR_CAMP_NO_ENOUGH_COUNT)),
                               {MagicIns, {GodCount, MagicCount - 1}}
                       end,

    case check_instance(InsList, CampInsCFG, get(?pd_camp_self_camp), 2) of %验证副本确认可以进入
        false ->
            ?return_err(?ERR_CAMP_CHECH_INSTANCE_ERROR);

        true ->
            case cost:camp_cost(CampInsCFG#main_ins_cfg.cost, load_cfg_camp:lookup_cfg(#camp_cfg.enter_enemy_instance_cost), ?FLOW_REASON_CAMP) of
                ok ->
                    case main_ins_mod:handle_start(camp_mng, InstanceId) of
                        {ok, _} ->
                            put(?pd_camp_enter_count, Count),
                            put(?pd_camp_fight_type, 2),
                            camp_service:add_instance_player(InstanceId, {self(), get(?pd_id)}, get(?pd_camp_self_camp));

                        error ->
                            error
                    end;

                {error, Other} ->
                    %% 发送错误码给前端
                    ?player_send(player_sproto:pkg_msg(?MSG_PLAYER_ERROR,
                        {?MSG_PLAYER_ENTER_ENEMY_INSTANCE,?ERR_COST_MONEY_FAIL,<<>>})),
                    ?return_err(Other)
            end
    end;

%% @doc 防守,0.不限次数 1.验证副本 进入副本
handle_client(?MSG_PLAYER_ENTER_INSTANCE_FIGHT_ENEMY_PLAYER, {InstanceId, FightPlayerId}) ->
    case ets:lookup(?service_camp_instance, InstanceId) of
        [] -> ?return_err(?ERR_CAMP_NO_FIGHT);
        [InsTab] ->
            case lists:keyfind(FightPlayerId, 2, InsTab#service_camp_instance.enemy_player_list) of
                false -> ?return_err(?ERR_CAMP_NO_FIGHT);
                {FightPlayerPid, FightPlayerId} ->
                    CampInsCFG = load_cfg_camp:lookup_cfg(?main_ins_cfg, InstanceId),
                    IsMyIns = case get(?pd_camp_self_camp) of
                                  {?CAMP_PERSON, ?CAMP_PERSON} -> false;
                                  0 -> false;
                                  {?CAMP_PERSON, Camp} -> CampInsCFG#main_ins_cfg.sub_type =:= Camp;
                                  Camp -> CampInsCFG#main_ins_cfg.sub_type =:= Camp
                              end,
                    case IsMyIns of
                        true ->
                            {GodIns, MagicIns} = get(?pd_camp_open_instance),
                            InsList = case CampInsCFG#main_ins_cfg.sub_type of
                                          ?CAMP_GOD -> GodIns;
                                          ?CAMP_MAGIC -> MagicIns
                                      end,
                            case check_instance(InsList, CampInsCFG, get(?pd_camp_self_camp), 1) of %验证副本确认可以进入
                                false ->
                                    ?return_err(?ERR_CAMP_CHECH_INSTANCE_ERROR);
                                true ->
                                    case cost:cost(CampInsCFG#main_ins_cfg.cost, ?FLOW_REASON_CAMP) of
                                        ok ->
                                            %% 记下入侵玩家的Pid
                                            put(?pd_camp_invade_player, {FightPlayerPid, FightPlayerId}),
                                            guard_camp(InstanceId, FightPlayerPid);
                                        {error, Other} -> ?return_err(Other)
                                    end
                            end;
                        false ->
                            ?return_err(?ERR_CAMP_GUARD_MY_INS)
                    end
            end
    end;

handle_client(_Msg, _Arg) ->
    ?INFO_LOG("camp handle_client ~p", [{_Msg, _Arg}]),
    ok.

get_player_list(PlayerList) ->
    FunMap = fun({_PlayerPid, PlayerId}) ->
        [PlayerName, PlayerLv, CombatPower, CareerId] = player:lookup_info(PlayerId, [?pd_name, ?pd_level, ?pd_combat_power, ?pd_career]),
        %TODO is_fight( PlayerId )
        {PlayerId, PlayerName, PlayerLv, CombatPower, CareerId}
    end,
    lists:map(FunMap, PlayerList).

check_instance(InsList, CampInsCFG, CampId, State) ->
    InsType = CampInsCFG#main_ins_cfg.sub_type,
    CheckInsType = case State of
                       1 -> case CampId of
                                {_, InsType} -> ok;
                                InsType -> ok;
                                {?CAMP_PERSON, ?CAMP_PERSON} -> ok;
                                _ -> error
                            end;
                       2 ->
                           case CampId of
                               {_, InsType} -> error;
                               InsType -> error;
                               {?CAMP_PERSON, ?CAMP_PERSON} -> ok;
                               _ when CampId =/= 0 -> ok;
                               _ -> error
                           end
                   end,
    case CheckInsType of
        ok ->
            case CampInsCFG#main_ins_cfg.pervious of
                0 -> CampInsCFG#main_ins_cfg.limit_level =< get(?pd_level);
                PerIns ->
                    case lists:member(PerIns, InsList) of %
                        true -> CampInsCFG#main_ins_cfg.limit_level =< get(?pd_level);
                        false -> false
                    end
            end;
        error -> false
    end.

guard_camp(InstanceId, FightPlayerPid) ->
    ?send_mod_msg(FightPlayerPid, camp_mng, {enter_instance, self(), InstanceId}).