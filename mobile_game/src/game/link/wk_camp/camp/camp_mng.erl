%%%-------------------------------------------------------------------
%%% @author yujian
%%% @doc 神魔系统模块
%%%-------------------------------------------------------------------
-module(camp_mng).
-include_lib("pangzi/include/pangzi.hrl").

-include("inc.hrl").
-include("player.hrl").
-include("scene.hrl").

-include("player_mod.hrl").

-include("camp_struct.hrl").
-include("rank.hrl").
-include("main_ins_struct.hrl").

-include("load_cfg_camp.hrl").
-include("load_cfg_main_ins.hrl").
-include("system_log.hrl").

-export
([
    get_camp_info/0         % 获取玩家个人信息
    , add_rank/2            % 功勋值变化影响排序
    , select_rank/3         % 排行榜信息
    , join_camp/1           % 添加种族
    , person_select_camp/1  % 人族选择种族
    , handle_mcall/2
    , prize_list/1          % 计算战争奖励
    , ins_complete/3
]).

load_db_table_meta() ->
    [
        #db_table_meta{name = ?player_camp_tab,
            fields = ?record_fields(?player_camp_tab),
            shrink_size = 10,
            flush_interval = 10}
    ].

create_mod_data(SelfId) ->
    dbcache:insert_new(?player_camp_tab, #player_camp_tab{player_id = SelfId}).

load_mod_data(PlayerId) ->
    case dbcache:lookup(?player_camp_tab, PlayerId) of
        [] ->
            create_mod_data(PlayerId),
            load_mod_data(PlayerId);
        [PlayerCampTab] ->
            put(?pd_camp_enter_count, PlayerCampTab#player_camp_tab.enter_count),
            put(?pd_camp_exploit, PlayerCampTab#player_camp_tab.exploit),
            put(?pd_camp_open_instance, PlayerCampTab#player_camp_tab.open_instance),
            put(?pd_select_camp_time, PlayerCampTab#player_camp_tab.select_camp_time),
            EndTime = camp_service:get_end_time(),
            IsFight = camp_service:is_fight(),
            if
                (IsFight =:= true) andalso (EndTime =:= PlayerCampTab#player_camp_tab.fight_endtime) ->
                    put(?pd_camp_fight_instance, PlayerCampTab#player_camp_tab.fight_instance),
                    put(?pd_camp_fight_endtime, PlayerCampTab#player_camp_tab.fight_endtime);
                true ->
                    put(?pd_camp_fight_instance, []),
                    put(?pd_camp_fight_endtime, EndTime)
            end,

            {{Day1, Minite1, Second1}, {Day2, Minite2, Second2}} = load_cfg_camp:lookup_cfg(#camp_cfg.cycle_time),
            ThisWarStartTime = case IsFight of
                                   true ->
                                       EndTime - ((Day1 * 24 * 60) + (Minite1 * 60) + Second1 + (Day2 * 24 * 60) + (Minite2 * 60) + Second2);
                                   false ->
                                       EndTime - ((Day1 * 24 * 60) + (Minite1 * 60) + Second1)
                               end,
            if
                ThisWarStartTime > PlayerCampTab#player_camp_tab.select_camp_time ->
                    if
                        is_tuple(PlayerCampTab#player_camp_tab.self_camp) ->
                            put(?pd_camp_self_camp, {?CAMP_PERSON, ?CAMP_PERSON});
                        true -> put(?pd_camp_self_camp, PlayerCampTab#player_camp_tab.self_camp)
                    end;
                true ->
                    put(?pd_camp_self_camp, PlayerCampTab#player_camp_tab.self_camp)
            end
    end.

init_client() ->
    case get(?pd_camp_self_camp) of
        0 -> ?player_send(camp_sproto:pkg_msg(?PUSH_CAMP_ID, {0}));
        {_, CampId} -> ?player_send(camp_sproto:pkg_msg(?PUSH_CAMP_ID, {CampId}));
        CampId -> ?player_send(camp_sproto:pkg_msg(?PUSH_CAMP_ID, {CampId}))
    end.

view_data(Acc) -> Acc.

handle_frame({?frame_levelup, _OldLevel}) -> ok;

handle_frame(Frame) ->
    ?err({unknown_frame, Frame}).

handle_msg(_FromMod, {prize, Win}) ->
    SelfCampId = get(?pd_camp_self_camp),
    case SelfCampId of
        0 -> ok;
        {?CAMP_PERSON, ?CAMP_PERSON} -> ok;
        Win -> prize(win);
        {_, Win} ->
            prize(win),
            ?player_send(camp_sproto:pkg_msg(?PUSH_CAMP_ID, {?CAMP_PERSON})),
            put(?pd_camp_self_camp, {?CAMP_PERSON, ?CAMP_PERSON});
        _ ->
            case Win of
                ?tie -> prize(tie);
                ?none -> ok;
                _ -> prize(lose)
            end,
            case SelfCampId of
                {?CAMP_PERSON, _} ->
                    ?player_send(camp_sproto:pkg_msg(?PUSH_CAMP_ID, {?CAMP_PERSON})),
                    put(?pd_camp_self_camp, {?CAMP_PERSON, ?CAMP_PERSON});
                _ -> ok
            end
    end;

handle_msg(_FromMod, {?player_refresh_time}) ->
    Count = load_cfg_camp:lookup_cfg(#camp_cfg.enter_count),
    put(?pd_camp_enter_count, Count);

%% @doc 敌人入侵推送信息给玩家
handle_msg(_FromMod, {enemy_enter_instance, InstanceId, PlayerId, CampId, Exploit}) ->
    case get(?pd_camp_self_camp) of
        0 -> ok;
        {?CAMP_PERSON, ?CAMP_PERSON} -> ok;
        CampId -> ok;
        {_, CampId} -> ok;
        _ -> camp_handle_client:handle_client(?PUSH_ENEMY_PLAYER_DATA, {InstanceId, PlayerId, CampId, Exploit})
    end;

%% 进入场景
handle_msg(_FromMod, {player_enter_scene, {InstanceId, _CallArg}}) ->
    CampInsCFG = load_cfg_camp:lookup_cfg(?main_ins_cfg, InstanceId),
    if
        CampInsCFG#main_ins_cfg.next =:= ?none ->
            put(?pd_camp_fight_state, 2);
        true ->
            put(?pd_camp_fight_state, 0)
    end;

%% @doc 1.可以在任何地图中离开，而进入只能是第一场景,离开场景，删除入侵信息
handle_msg(_FromMod, {player_leave_scene, {InstanceId, _CallArg}}) ->
    ?INFO_LOG("id,leave: ~p", [get(?pd_id)]),
    %% 设置入侵玩家的状态
    case get(?pd_camp_invade_player) of
        {FightPlayerPid, _FightPlayerId} ->
            %% 玩家离开场景时，清除入侵玩家的记录
            put(?pd_camp_invade_player, {}),
            ?send_mod_msg(FightPlayerPid, ?MODULE, {set_camp_fight_state});
        _ ->
            ok
    end,

    ?INFO_LOG("pd_camp_fight_state leave: ~p", [get(?pd_camp_fight_state)]),
    CampInsCFG = load_cfg_camp:lookup_cfg(?main_ins_cfg, InstanceId),
    case load_cfg_scene:get_scene_type(get(?pd_scene_id)) of
        1 ->
            camp_service:del_instance_player(CampInsCFG#main_ins_cfg.ins_id, get(?pd_id), get(?pd_camp_self_camp));
        _ -> ok
    end;

%% 设置入侵玩家的状态
handle_msg(_FromMod, {set_camp_fight_state}) ->
    put(?pd_camp_fight_state, 0),
    ok;

% 杀死敌方，1增加功勋值(变更排行榜数据)，2增加神魔值，3加入事件
handle_msg(_FromMod, {player_kill_player, {SceneId, {EnemyPid, EnemyPlayerId}}}) ->
    ResDelExpolit = gen_server:call(EnemyPid, {mod, ?MODULE, enemy_del_exploit}),
    AllExploit = get(?pd_camp_exploit) + ResDelExpolit,
    put(?pd_camp_exploit, AllExploit),
    add_rank(get(?pd_camp_self_camp), AllExploit),

    SelfCampId = case get(?pd_camp_self_camp) of
                     {?CAMP_PERSON, Camp} -> Camp;
                     Camp -> Camp
                 end,
    case add_camp_point(player_kill_agent, SelfCampId) of
        false -> ok;
        FightValue ->
            PlayerName = player:lookup_info(EnemyPlayerId, ?pd_name),
            CampInsCFG = load_cfg_camp:lookup_cfg(?main_ins_cfg, SceneId),
            camp_service:add_event({?EVENT_TYPE_KILL_PLAYER, get(?pd_id), get(?pd_name), SelfCampId,
                CampInsCFG#main_ins_cfg.ins_id, FightValue, EnemyPlayerId, PlayerName})
    end;

%%0.副本解锁 1增加战绩点，2加入事件, 3.此副本解锁
handle_msg(_FromMod, {complete, {SceneId, _CallArg}}) ->
    CampInsCFG = load_cfg_camp:lookup_cfg(?main_ins_cfg, SceneId),
    ins_prize(SceneId, CampInsCFG),
    InsId = CampInsCFG#main_ins_cfg.ins_id,
    SelfCampId = case get(?pd_camp_self_camp) of
                     {?CAMP_PERSON, Camp} -> Camp;
                     Camp -> Camp
                 end,
    case get(?pd_camp_fight_type) of
        1 -> ok;
        2 ->
            case add_camp_point(complete_ins, SelfCampId, SceneId, 1) of
                false -> ok;
                FightValue ->
                    camp_service:add_event({?EVENT_TYPE_KILL_BOSS, get(?pd_id), get(?pd_name), SelfCampId, InsId, FightValue}),
                    put(?pd_camp_fight_instance, [SceneId | get(?pd_camp_fight_instance)]),
                    put(?pd_camp_fight_endtime, camp_service:get_end_time())
            end;
        3 ->
            case add_camp_point(complete_ins, SelfCampId, SceneId, 2) of
                false -> ok;
                FightValue ->
                    camp_service:add_event({?EVENT_TYPE_KILL_BOSS, get(?pd_id), get(?pd_name), SelfCampId, InsId, FightValue}),
                    put(?pd_camp_fight_instance, [SceneId | get(?pd_camp_fight_instance)]),
                    put(?pd_camp_fight_endtime, camp_service:get_end_time())
            end
    end;

%% @doc 守护自己种族副本，1判断是否已经被别人守护 2是否已经在boss房间
handle_msg(_FromMod, {enter_instance, FightPlayerPid, InstanceId}) ->
    case get(?pd_camp_fight_type) =:= 2 of
        true ->
            case get(?pd_camp_fight_state) =:= 0 of
                true ->
                    put(?pd_camp_fight_state, 1),
                    ?send_mod_msg(FightPlayerPid, ?MODULE, {enter_instance, {get(?pd_scene_id), InstanceId}});
                _ ->
                    ?send_to_client(FightPlayerPid, <<?MSG_PLAYER_ERROR:16, ?MSG_PLAYER_ENTER_INSTANCE_FIGHT_ENEMY_PLAYER:16, ?ERR_CAMP_NOT_INVADE:16>>)
            end;
        _ ->
            ?send_to_client(FightPlayerPid, <<?MSG_PLAYER_ERROR:16, ?MSG_PLAYER_ENTER_INSTANCE_FIGHT_ENEMY_PLAYER:16, ?ERR_CAMP_IS_IN_BOSS_ROOM:16>>)
    end;

handle_msg(_FromMod, {enter_instance, {SceneId, InstanceId}}) ->
    put(?pd_camp_fight_type, 3),
    enter_fight_scene(InstanceId, SceneId);

handle_msg(_FromMod, Msg) ->
    ?err({unknown_msg, Msg}).

%% @doc 上线判断是否刷新进入副本次数
online() ->
    case get(?pd_camp_self_camp) of %是否选择种族
        0 -> ok;
        _CampId ->
            Time = camp_service:player_priv_refresh_time(),
            LogOutTime = get(?pd_last_logout_time),
            if
                LogOutTime < Time ->
                    Count = load_cfg_camp:lookup_cfg(#camp_cfg.enter_count),
                    put(?pd_camp_enter_count, Count);
                true ->
                    ok
            end
    end.

offline(_SelfId) ->
    ok.

save_data(_SelfId) ->
    CampId = get(?pd_camp_self_camp),
    ?ifdo(CampId =/= 0,
        update_camp_data()).

handle_mcall(enemy_del_exploit, _From) ->
    EnemyExploit = get(?pd_camp_exploit),
    DelEnemyExpolit = com_util:ceil(load_cfg_camp:lookup_cfg(#camp_cfg.add_exploit) * EnemyExploit),
    ResDelEnemyExpolit = if
                             DelEnemyExpolit > 10 -> DelEnemyExpolit;
                             true -> 10
                         end,
    AllExploit = get(?pd_camp_exploit) - ResDelEnemyExpolit,
    if
        AllExploit =< 0 -> put(?pd_camp_exploit, 0);
        true -> put(?pd_camp_exploit, AllExploit)
    end,
    add_rank(get(?pd_camp_self_camp), get(?pd_camp_exploit)),
    ResDelEnemyExpolit.

%% @doc 完成副本
ins_complete(?ins_fail, _, _CallArg) -> ok;
ins_complete(?ins_complete, {MainInsCFG, _KillMonster, _WaveNum, _DieCount, _KillMonter, _KillBoss, _PassTime,_ReliveNum, PrizeId}, _CallArg) ->
    ins_prize(MainInsCFG#main_ins_cfg.id, MainInsCFG, PrizeId).

ins_prize(SceneId, CampInsCFG) ->
    #main_ins_cfg{ins_id = InsId, is_monster_match_level = IsMatch, pass_prize = PrizeId} = CampInsCFG,
    PassPrizeId = main_ins:get_pass_prize(InsId, IsMatch, PrizeId),
    ins_prize(SceneId, CampInsCFG, PassPrizeId).


ins_prize(SceneId, CampInsCFG, PrizeId) ->
    {God, Magic} = get(?pd_camp_open_instance),
    PrizeInfo = prize:prize_mail(PrizeId, ?S_MAIL_INSTANCE, ?FLOW_REASON_CAMP),
    ?player_send(camp_sproto:pkg_msg(?PUSH_CAMP_PRIZE, {SceneId, PrizeInfo})),
    InsId = CampInsCFG#main_ins_cfg.ins_id,
    OpenInstance = case CampInsCFG#main_ins_cfg.sub_type of
                       ?CAMP_GOD -> case lists:member(InsId, God) of
                                        true -> {God, Magic};
                                        false -> {[InsId | God], Magic}
                                    end;
                       ?CAMP_MAGIC -> case lists:member(InsId, Magic) of
                                          true -> {God, Magic};
                                          false -> {God, [InsId | Magic]}
                                      end
                   end,
    put(?pd_camp_open_instance, OpenInstance).

update_camp_data() ->
    dbcache:update(player_camp_tab, #player_camp_tab{player_id = get(?pd_id),
        self_camp = get(?pd_camp_self_camp),
        enter_count = get(?pd_camp_enter_count),
        exploit = get(?pd_camp_exploit),
        fight_instance = get(?pd_camp_fight_instance),
        fight_endtime = get(?pd_camp_fight_endtime),
        select_camp_time = get(?pd_select_camp_time),
        open_instance = get(?pd_camp_open_instance)}).

add_camp_point(player_kill_agent, CampId) ->
    case camp_service:is_fight() of
        true ->
            FightValue = load_cfg_camp:lookup_cfg(#camp_cfg.kill_camp_point),
            camp_service:add_camp_point(CampId, FightValue),
            FightValue;
        false -> false
    end.

%% @doc 1入侵 2防守
add_camp_point(complete_ins, CampId, SceneId, State) ->
    case camp_service:is_fight() of
        true ->
            CampInsTab = load_cfg_camp:lookup_cfg(?camp_ins_cfg, SceneId),
            FightValue = case State of
                             1 -> CampInsTab#camp_ins_cfg.inbreak_prize;
                             2 -> CampInsTab#camp_ins_cfg.guard_prize
                         end,
            camp_service:add_camp_point(CampId, FightValue),
            FightValue;
        false -> false
    end.

get_camp_info() ->
    {GodCount, MagicCount} = get(?pd_camp_enter_count),
    {GodIns, MagicIns} = get(?pd_camp_open_instance),
    FunChechIns = fun(CampInsCFG, InsList, Data) -> %判断副本是否已经解锁
        ChechIns = case CampInsCFG#main_ins_cfg.pervious of
                       0 -> CampInsCFG#main_ins_cfg.limit_level =< get(?pd_level);
                       PerIns ->
                           case lists:member(PerIns, InsList) of %
                               true -> CampInsCFG#main_ins_cfg.limit_level =< get(?pd_level);
                               false -> false
                           end
                   end,
        InsId = CampInsCFG#main_ins_cfg.ins_id,
        InsState = case ChechIns of
                       true -> {InsId, 1};
                       false -> {InsId, 0}
                   end,
        case lists:keyfind(InsId, 1, Data) of
            false -> [InsState | Data];
            _ -> Data
        end
    end,

    FunFoldl = fun(InsId, {Data1, Data2}) ->
        CampInsCFG = #main_ins_cfg{sub_type = CampId} = load_cfg_main_ins:lookup_main_ins_cfg(InsId),
        if
            CampId =:= ?CAMP_GOD ->
                {FunChechIns(CampInsCFG, GodIns, Data1), Data2};
            CampId =:= ?CAMP_MAGIC ->
                {Data1, FunChechIns(CampInsCFG, MagicIns, Data2)}
        end
    end,
    {GodInfo, MagicInfo} = lists:foldl(FunFoldl, {[], []}, load_cfg_camp:lookup_cfg(?main_ins_cfg, all)),
    RefreshTime = load_cfg_camp:lookup_cfg(#camp_cfg.refresh_time),
    NewCampId = case get(?pd_camp_self_camp) of
                    {_, CampId} -> CampId;
                    CampId -> CampId
                end,
    {NewCampId, GodCount, MagicCount, get(?pd_camp_exploit), 0, 0, get(?pd_career), lists:reverse(GodInfo), lists:reverse(MagicInfo), RefreshTime}.

add_rank(_CampId, _AllExploit) ->
    % PlayerId = get(?pd_id),
    % case CampId of
    %     ?CAMP_GOD ->
    %         ranking_lib:update(?ranking_camp, PlayerId, AllExploit),
    %         ranking_lib:update(?ranking_camp_god, PlayerId, AllExploit);
    %     ?CAMP_MAGIC ->
    %         ranking_lib:update(?ranking_camp, PlayerId, AllExploit),
    %         ranking_lib:update(?ranking_camp_magic, PlayerId, AllExploit);
    %     {?CAMP_PERSON, _} ->
    %         ranking_lib:update(?ranking_camp, PlayerId, AllExploit),
    %         ranking_lib:update(?ranking_camp_person, PlayerId, AllExploit)
    % end.
    ok.

select_rank(Type, StartPos, Num) ->
    NewType = case Type of
                  1 -> ?ranking_camp;           %% 总榜
                  2 -> ?ranking_camp_god;       %% 神榜
                  3 -> ?ranking_camp_magic;     %% 魔榜
                  4 -> ?ranking_camp_person     %% 人榜
              end,
    {AllSize, _StartPos, List} = ranking_lib:get_rank_order_page(StartPos, Num, NewType),
    {MyIndex, _MyLev} = ranking_lib:get_rank_order(NewType, get(?pd_id), {0, 0}),
    FunFoldl =
        fun({PlayerId, Exploit}, {Index, Data}) ->
            [PlayerName, PlayerLv, CareerId] = player:lookup_info(PlayerId, [?pd_name, ?pd_level, ?pd_career]),
            case dbcache:lookup(?player_camp_tab, PlayerId) of
                [] ->
                    {Index + 1, [{Index, PlayerId, PlayerName, PlayerLv, 0, 0, CareerId} | Data]};
                [PlayerCamp] ->
                    CampId = case PlayerCamp#player_camp_tab.self_camp of
                                 0 -> 0;
                                 {?CAMP_PERSON, _} -> ?CAMP_PERSON;
                                 Camp -> Camp
                             end,
                    {Index + 1, [{Index, PlayerId, PlayerName, PlayerLv, CampId, Exploit, CareerId} | Data]}
            end
        end,
    {_, RankList} = lists:foldl(FunFoldl, {StartPos, []}, List),
    NewCampId =
        case get(?pd_camp_self_camp) of
            {CampId, _} -> CampId;
            CampId -> CampId
        end,
    {
        MyIndex
        , get(?pd_id)
        , get(?pd_name)
        , get(?pd_level)
        , NewCampId,
        case get(?pd_camp_exploit) of
            ?undefined -> 0;
            Ex -> Ex
        end,
        get(?pd_career),
        AllSize,
        lists:reverse(RankList)
    }.



%% 加入阵营，初始化副本进入次数
join_camp(CampId) ->
    case get(?pd_camp_self_camp) of
        0 ->
            NewCampId = case CampId of
                            ?CAMP_GOD -> ?CAMP_GOD;
                            ?CAMP_PERSON -> {?CAMP_PERSON, ?CAMP_PERSON};
                            ?CAMP_MAGIC -> ?CAMP_MAGIC
                        end,
            Count = load_cfg_camp:lookup_cfg(#camp_cfg.enter_count),
            put(?pd_camp_enter_count, Count),
            put(?pd_camp_self_camp, NewCampId),
            ?player_send(camp_sproto:pkg_msg(?PUSH_CAMP_ID, {CampId}));
        _ ->
            {error, ?ERR_CAMP_HAVE_CAMP}
    end.

person_select_camp(CampId) ->
    case get(?pd_camp_self_camp) of
        {?CAMP_PERSON, ?CAMP_PERSON} ->
            NewCampId = case CampId of
                            ?CAMP_GOD -> ?CAMP_GOD;
                            ?CAMP_MAGIC -> ?CAMP_MAGIC
                        end,
            ?player_send(camp_sproto:pkg_msg(?PUSH_CAMP_ID, {NewCampId})),
            put(?pd_select_camp_time, com_time:now()),
            put(?pd_camp_self_camp, {?CAMP_PERSON, NewCampId});
        {?CAMP_PERSON, _} ->
            {error, ?ERR_CAMP_SELECT_CAMP};
        _ ->
            {error, ?ERR_CAMP_NOT_PERSION}
    end.

%% @doc 战争结束，战胜100%，战平50%，战败10%
prize(FightPrize) ->
    PrizeList = prize_list(get(?pd_camp_fight_instance)),
    case PrizeList of
        [] -> ok;
        PrizeList ->
            case FightPrize of
                win ->
                    mail_mng:send_sysmail(get(?pd_id), ?S_MAIL_CAMP_PRIZE_WIN, PrizeList);
                lose ->
                    FightFial = load_cfg_camp:lookup_cfg(#camp_cfg.fight_fail),
                    FunMap = fun({Key, Num}) -> {Key, com_util:ceil(Num * (FightFial / 100))} end,
                    mail_mng:send_sysmail(get(?pd_id), ?S_MAIL_CAMP_PRIZE_LOSE, lists:map(FunMap, PrizeList));
                tie ->
                    FightTie = load_cfg_camp:lookup_cfg(#camp_cfg.fight_tie),
                    FunMap = fun({Key, Num}) -> {Key, com_util:ceil(Num * (FightTie / 100))} end,
                    mail_mng:send_sysmail(get(?pd_id), ?S_MAIL_CAMP_PRIZE_TIE, lists:map(FunMap, PrizeList))
            end
    end.

prize_list([]) -> [];
prize_list(InstanceList) ->
    Fun = fun(InstanceId, Data) ->
        CampInsCFG = load_cfg_camp:lookup_cfg(?camp_ins_cfg, InstanceId),
        {ok, ItemList} = prize:get_prize(CampInsCFG#camp_ins_cfg.war_prize),
        prize_zip(Data, ItemList)
    end,
    lists:foldl(Fun, [], InstanceList).

prize_zip(Data, []) -> Data;
prize_zip(Data, [{Key, Num} | Asset]) ->
    case lists:keyfind(Key, 1, Data) of
        false -> prize_zip([{Key, Num} | Data], Asset);
        {Key, Count} -> prize_zip(lists:keyreplace(Key, 1, Data, {Key, Count + Num}), Asset)
    end.

enter_fight_scene(_CFGId, SceneId) ->
    ?ifdo(SceneId =:= get(?pd_scene_id),
        ?return_err(?ERR_CAMP_EXIT_IN_THIS_SCENE)),
    case scene_mng:enter_scene_request(SceneId) of
        approved -> ok;
        _E -> error
    end.
