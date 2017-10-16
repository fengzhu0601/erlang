%%%-------------------------------------------------------------------
%%% @author yujian
%%% @doc 虚空深渊系统
%%%-------------------------------------------------------------------
-module(abyss_mng).

-include_lib("pangzi/include/pangzi.hrl").

-include("inc.hrl").
-include("player.hrl").
-include("player_mod.hrl").
-include("abyss_struct.hrl").
-include("handle_client.hrl").
-include("rank.hrl").
-include("main_ins_struct.hrl").
-include("load_vip_right.hrl").
-include("day_reset.hrl").
-include("load_cfg_main_ins.hrl").
-include("scene.hrl").
-include("system_log.hrl").
-include("achievement.hrl").

-export([ins_complete/3]).

-export
([
    lookup_cfg/1
    , lookup_cfg/2
    , test/1
    , test/2
    , send_prize_email/0
]).

load_db_table_meta() ->
    [
        #db_table_meta{name = ?player_abyss_tab,
            fields = ?record_fields(?player_abyss_tab),
            shrink_size = 10,
            flush_interval = 10},

        #db_table_meta{name = ?player_abyss_prize_info_tab,
            fields = ?record_fields(?player_abyss_prize_info_tab),
            shrink_size = 10,
            flush_interval = 10}
    ].


create_mod_abyss_data(SelfId) ->
    case dbcache:insert_new(?player_abyss_tab, #player_abyss_tab{player_id = SelfId}) of
        ?true -> ok;
        ?false ->
            ?ERROR_LOG("player ~p create new player_abyss_tab not alread exists ", [SelfId])
    end,
    ok.

create_mod_abyss_prize_data(SelfId) ->
    case dbcache:insert_new(?player_abyss_prize_info_tab, #player_abyss_prize_info_tab{player_id = SelfId}) of
        ?true -> ok;
        ?false ->
            ?ERROR_LOG("player ~p create new player_abyss_prize_info_tab not alread exists ", [SelfId])
    end,
    ok.


create_mod_data(SelfId) ->
    create_mod_abyss_data(SelfId),
    create_mod_abyss_prize_data(SelfId),
    ok.

load_mod_abyss_data(PlayerId) ->
    case dbcache:load_data(?player_abyss_tab, PlayerId) of
        [] ->
            ?ERROR_LOG("player ~p can not find player_abyss_tab mode", [PlayerId]),
            create_mod_abyss_data(PlayerId),
            load_mod_abyss_data(PlayerId);
        [PlayerAbyssTab] ->
            %% ?INFO_LOG("============PlayerAbyssTab:~p",[PlayerAbyssTab]),
            TabEleSize = erlang:size(PlayerAbyssTab),
            %% ?INFO_LOG("============TabEleSize:~p",[TabEleSize]),
            %% 新加字段后兼容老的数据表
            NewAbyssTab =
                if
                    TabEleSize < erlang:size(#player_abyss_tab{}) ->
                        PlayerAbyssTab#player_abyss_tab{
                            max_easy_layer = PlayerAbyssTab#player_abyss_tab.easy_layer,
                            max_hard_layer = PlayerAbyssTab#player_abyss_tab.hard_layer,
                            hard_score = 0,
                            max_score = 0
                        };
                    true ->
                        #player_abyss_tab{
                            max_easy_layer = MaxEasyLayer,
                            max_hard_layer = MaxHardLayer,
                            max_score = MaxScore,
                            hard_score = HardScore
                        } = PlayerAbyssTab,
                        NewMaxEasyLayer =
                            case MaxEasyLayer of
                                ?undefined ->
                                    PlayerAbyssTab#player_abyss_tab.easy_layer;
                                0 ->
                                    PlayerAbyssTab#player_abyss_tab.easy_layer;
                                _ ->
                                    MaxEasyLayer
                            end,
                        NewMaxHardLayer =
                            case MaxHardLayer of
                                ?undefined ->
                                    PlayerAbyssTab#player_abyss_tab.hard_layer;
                                0 ->
                                    PlayerAbyssTab#player_abyss_tab.hard_layer;
                                _ ->
                                    MaxHardLayer
                            end,
                        NewMaxScore =
                            case MaxScore of
                                ?undefined ->
                                    0;
                                _ ->
                                    MaxScore
                            end,
                        NewHardScore =
                            case HardScore of
                                ?undefined ->
                                    0;
                                _ ->
                                    HardScore
                            end,
                        PlayerAbyssTab#player_abyss_tab{max_easy_layer = NewMaxEasyLayer, max_hard_layer = NewMaxHardLayer, max_score = NewMaxScore, hard_score = NewHardScore}
                end,
            dbcache:update(?player_abyss_tab, NewAbyssTab),
            %% dbcache:update(?player_abyss_tab, PlayerAbyssTab),
            put(?pd_abyss_tab, NewAbyssTab)
    end.

load_mod_abyss_prize_data(PlayerId) ->
    case dbcache:load_data(?player_abyss_prize_info_tab, PlayerId) of
        [] ->
            ?ERROR_LOG("player ~p can not find player_abyss_prize_info_tab mode", [PlayerId]),
            create_mod_abyss_prize_data(PlayerId),
            load_mod_abyss_prize_data(PlayerId);
        [PlayerAbyssPrizeTab] ->
            %?INFO_LOG("==========================load_db_data \n"),
            %?INFO_LOG("PlayerAbyssPrizeTab:~p", [PlayerAbyssPrizeTab]),
            dbcache:update(?player_abyss_prize_info_tab, PlayerAbyssPrizeTab),
            put(?abyss_prize_info, PlayerAbyssPrizeTab)
    end.

%% 初始化玩家神魔数据表
load_mod_data(PlayerId) ->
    load_mod_abyss_data(PlayerId),
    load_mod_abyss_prize_data(PlayerId).


init_client() ->
    put(?already_in_abyss,?false),
    ok.

view_data(Acc) -> Acc.

on_day_reset(_Player) ->
    reset_update(),
    handle_client(?GET_SELECT_ABYSS_INFO, {}).


handle_frame(Frame) -> ?err({unknown_frame, Frame}).

handle_msg(_FromMod, {player_enter_scene, {_InsId, _CallArg}}) ->
    put(?abyss_fight_state, 1);

handle_msg(_FromMod, {player_leave_scene, {_InsId, _CallArg}}) ->
    case get(?abyss_fight_state) of
        1 ->
            add_daily_count();
        2 -> ok
    end;

%% 测试
handle_msg(_FromMod, {test_abyss_info}) ->
    handle_client(?GET_SELECT_ABYSS_INFO, {}),
    ok;
handle_msg(_FromMod, {auto_fight,Diff}) ->
    %% handle_client(?MSG_ABYSS_NEW_AUTO_FIGHT, {Diff}),
    handle_client(?MSG_ABYSS_NEW_AUTO_FIGHT,{Diff}),
    ok;

handle_msg(_FromMod, Msg) -> ?err({unknown_msg, Msg}).

%% @doc 完成副本
ins_complete(InsState, {MainInsCFG, _KillMonster, _WaveNum, _DieCount, _KillMinMonsterCount,
    _KillBossMonsterCount, PrizeId, _MaxDoubleHit, _ShoujiCount, PassTime, _ReliveNum, AbyssPercent, AbyssScore, _MonsterBidList}, _CallArg) ->
    achievement_mng:do_ac(?fanxingmantian),
    ?INFO_LOG("InsState:~p",[InsState]),
    case InsState of
        %% 通关
        ?ins_complete ->
            case erlang:erase(abyss_player_die) of
                %% 角色死亡时
                ?false ->
                    ?INFO_LOG("=================玩家死亡结算=============="),
                    put(?abyss_fight_state, 1),
                    AbyssPrizeInfo = erlang:get(?abyss_prize_info),
                    #player_abyss_prize_info_tab{abyss_score = Abyss_Score, prizeList = PrizeList} = AbyssPrizeInfo,

                    NewPrizeList = zip_prize_list(PrizeList),
                    NewPrizeList2 = prize:double_items(4000, NewPrizeList),

                    if
                        NewPrizeList2 =/= [] ->
                            achievement_mng:do_ac(?xukonglingzhu);
                        true ->
                            pass 
                    end,

                    CurNewScore = Abyss_Score + AbyssScore,         %% 结算积分
                    PlayerAbyssTab = get(?pd_abyss_tab),
                    case get(?abyss_fight_layer) of
                        {Diff, Layer} ->
                            OldScore = get_abyss_integral(Diff),
                            NewScore = OldScore + AbyssScore,       %% 简单积分
                            case Diff of
                                ?pd_abyss_fight_easy ->
                                    NewMaxScore = max((NewScore + PlayerAbyssTab#player_abyss_tab.hard_score), PlayerAbyssTab#player_abyss_tab.max_score), %% 积分
                                    NewMaxEasyLayer = max(Layer -1, PlayerAbyssTab#player_abyss_tab.max_easy_layer),

                                    ranking_lib:update(?ranking_abyss, get(?pd_id),
                                        {
                                            NewMaxScore,
                                            PlayerAbyssTab#player_abyss_tab.max_hard_layer + NewMaxEasyLayer,%%{困难层 +　简单层}
                                            NewMaxEasyLayer,
                                            PlayerAbyssTab#player_abyss_tab.max_hard_layer%%困难层
                                        }),
                                    util:is_flush_rank_only_by_rankname(?ranking_abyss, get(?pd_id)),
%%                                    ranking_lib:flush_rank_only_by_rankname(?ranking_abyss),
                                    {MyIndex, _FScore} = ranking_lib:get_rank_order(?ranking_abyss, get(?pd_id), {0, 0}),

                                    put(?pd_abyss_tab, PlayerAbyssTab#player_abyss_tab{
                                        score = NewScore,
                                        max_score = NewMaxScore,
                                        rankIndex = MyIndex,
                                        max_easy_layer = NewMaxEasyLayer
                                    });
                                ?pd_abyss_fight_hard ->
                                    NewMaxScore = max((NewScore + PlayerAbyssTab#player_abyss_tab.score), PlayerAbyssTab#player_abyss_tab.max_score), %% 积分
                                    NewMaxHardLayer = max(Layer -1, PlayerAbyssTab#player_abyss_tab.max_hard_layer),

                                    ranking_lib:update(?ranking_abyss, get(?pd_id),
                                        {
                                            NewMaxScore,
                                            NewMaxHardLayer + PlayerAbyssTab#player_abyss_tab.max_easy_layer,
                                            PlayerAbyssTab#player_abyss_tab.max_easy_layer,
                                            NewMaxHardLayer
                                        }),
%%                                    ranking_lib:flush_rank_only_by_rankname(?ranking_abyss),
                                    util:is_flush_rank_only_by_rankname(?ranking_abyss, get(?pd_id)),
                                    {MyIndex, _FScore} = ranking_lib:get_rank_order(?ranking_abyss, get(?pd_id), {0, 0}),

                                    put(?pd_abyss_tab, PlayerAbyssTab#player_abyss_tab{
                                        hard_score = NewScore,
                                        max_score = NewMaxScore,
                                        rankIndex = MyIndex,
                                        max_hard_layer = NewMaxHardLayer
                                    });
                                _ ->
                                    pass
                            end,
                            ?player_send(abyss_sproto:pkg_msg(?MSG_ABYSS_COMPLETE, {CurNewScore, CurNewScore, NewScore, NewPrizeList2}));
                        _ ->
                            pass
                    end,
                    game_res:try_give_ex(NewPrizeList2, ?S_MAIL_INSTANCE, ?FLOW_REASON_ABYSS),
                    %% 结算时重置本次战斗的积分和奖励列表
                    erlang:put(?abyss_prize_info, AbyssPrizeInfo#player_abyss_prize_info_tab{abyss_score = 0, prizeList = [], is_in_abyss = ?false}),
                    dbcache:update(?player_abyss_prize_info_tab, get(?abyss_prize_info)),
                    put(?already_in_abyss,?false);
                _ ->
                    case get(?abyss_fight_layer) of
                        {Diff, Layer} ->
                            put(?abyss_fight_state, 2),
                            %% 验证衰减度
                            NewAbyssPercent = verify_abyss_decay(PassTime, AbyssPercent),

                            {ok, PrizeInfo} = prize:get_prize(PrizeId),
                            AbyssPrizeInfo = erlang:get(?abyss_prize_info),
                            #player_abyss_prize_info_tab{abyss_score = Abyss_Score, prizeList = PrizeList} = AbyssPrizeInfo,
                            %%  ?INFO_LOG("衰减前：PrizeList:~p, PrizeInfo:~p",[PrizeList, PrizeInfo]),
                            %% 根据衰减度设置奖励
                            PrizeInfoPercent = get_prize_by_percent(NewAbyssPercent, PrizeInfo),

                            NewPrizeList = item_goods:merge_goods(PrizeList ++ PrizeInfoPercent),
                            %%  ?INFO_LOG("衰减后：NewPrizeList:~p, PrizeInfoPercent:~p",[NewPrizeList, PrizeInfoPercent]),

                            %% Vip加成积分
                            VipLevel = attr_new:get_vip_lvl(),
                           % AbyssIntegral = load_vip_right:get_abyss_integral_by_vip(VipLevel),
                            AbyssIntegral = load_vip_new:get_vip_pata_integral_by_vip_level(VipLevel),
                            VipScore = AbyssScore * AbyssIntegral div 100,
                            %% 之前的积分
                            OldScore = get_abyss_integral(Diff),
                            %% ?INFO_LOG("OldScore:~p, AbyssScore:~p",[OldScore, AbyssScore]),
                            NewScore = OldScore + AbyssScore + VipScore,
                            %% ?INFO_LOG("NewScore:~p",[NewScore]),
                            CurNewScore = Abyss_Score + AbyssScore + VipScore,
                            erlang:put(?abyss_prize_info, AbyssPrizeInfo#player_abyss_prize_info_tab{abyss_score = CurNewScore, prizeList = NewPrizeList, is_in_abyss = ?true}),
                            %?INFO_LOG("NewPrizeList:~p, CurNewScore:~p",[NewPrizeList, CurNewScore]),

                            PlayerAbyssTab = get(?pd_abyss_tab),
                            if
                                Diff =:= ?pd_abyss_fight_easy ->
                                    NewMaxScore = max(NewScore + PlayerAbyssTab#player_abyss_tab.hard_score, PlayerAbyssTab#player_abyss_tab.max_score),
                                    NewMaxEasyLayer = max(Layer, PlayerAbyssTab#player_abyss_tab.max_easy_layer),
                                    ranking_lib:update(?ranking_abyss, get(?pd_id),
                                        {
                                            NewMaxScore,
                                            PlayerAbyssTab#player_abyss_tab.max_hard_layer + NewMaxEasyLayer,
                                            NewMaxEasyLayer,
                                            PlayerAbyssTab#player_abyss_tab.max_hard_layer
                                        }),
                                    {MyIndex, _FScore} = ranking_lib:get_rank_order(?ranking_abyss, get(?pd_id), {0, 0}),
                                    put(?pd_abyss_tab, PlayerAbyssTab#player_abyss_tab{
                                        max_easy_layer = NewMaxEasyLayer,
                                        easy_layer = Layer,
                                        auto_easy_layer = Layer,
                                        score = NewScore,
                                        max_score = NewMaxScore,
                                        rankIndex = MyIndex
                                    });
                                Diff =:= ?pd_abyss_fight_hard ->
                                    NewMaxScore = max(NewScore + PlayerAbyssTab#player_abyss_tab.score, PlayerAbyssTab#player_abyss_tab.max_score),
                                    NewMaxHardLayer = max(Layer, PlayerAbyssTab#player_abyss_tab.max_hard_layer),
                                    ranking_lib:update(?ranking_abyss, get(?pd_id),
                                        {
                                            NewMaxScore,
                                            NewMaxHardLayer + PlayerAbyssTab#player_abyss_tab.max_easy_layer,
                                            PlayerAbyssTab#player_abyss_tab.max_easy_layer,
                                            NewMaxHardLayer
                                        }),
                                    {MyIndex, _FScore} = ranking_lib:get_rank_order(?ranking_abyss, get(?pd_id), {0, 0}),
                                    put(?pd_abyss_tab, PlayerAbyssTab#player_abyss_tab{
                                        max_hard_layer = NewMaxHardLayer,
                                        hard_layer = Layer,
                                        auto_hard_layer = Layer,
                                        hard_score = NewScore,
                                        max_score = NewMaxScore,
                                        rankIndex = MyIndex
                                    })
                            end,
                            %% 自动进入下个场景不算结算
                            Pid = get(?pd_scene_pid),
                            {_PdSceneId, SceneMode, _Other} = get(?pd_scene_id),
                            Pid ! ?scene_mod_msg(SceneMode, {is_client_sumbit}),
                            dbcache:update(?player_abyss_prize_info_tab, get(?abyss_prize_info)),
                            %% ?INFO_LOG("msg:~p", [{MainInsCFG#main_ins_cfg.id, NewAbyssPercent, PrizeInfoPercent}]),
                            ?player_send(abyss_sproto:pkg_msg(?PUSH_ABYSS_PRIZE, {MainInsCFG#main_ins_cfg.id, NewAbyssPercent, PrizeInfoPercent}));
                        _ -> ok
                    end
            end;

        _ ->
            ?INFO_LOG("=================玩家中途退出结算=============="),
            put(?abyss_fight_state, 1),
            AbyssPrizeInfo = erlang:get(?abyss_prize_info),
            #player_abyss_prize_info_tab{abyss_score = Abyss_Score, prizeList = PrizeList} = AbyssPrizeInfo,

            NewPrizeList = zip_prize_list(PrizeList),
            NewPrizeList2 = prize:double_items(4000, NewPrizeList),
            if
                NewPrizeList2 =/= [] ->
                    achievement_mng:do_ac(?xukonglingzhu);
                true ->
                    pass 
            end,
            CurNewScore = Abyss_Score + AbyssScore,
            %% ?INFO_LOG("Abyss_Score:~p,PrizeList:~p",[Abyss_Score,PrizeList]),
            %% ?INFO_LOG("OldScore:~p,NewScore:~p,CurNewScore:~p",[Abyss_Score,PrizeList,CurNewScore]),

            PlayerAbyssTab = get(?pd_abyss_tab),
            case get(?abyss_fight_layer) of
                {Diff, Layer} ->
                    OldScore = get_abyss_integral(Diff),
                    NewScore = OldScore + AbyssScore,       %% 简单积分
                    if
                        Diff =:= ?pd_abyss_fight_easy ->
                            NewMaxScore = max(NewScore + PlayerAbyssTab#player_abyss_tab.hard_score, PlayerAbyssTab#player_abyss_tab.max_score),
                            NewMaxEasyLayer = max(Layer -1, PlayerAbyssTab#player_abyss_tab.max_easy_layer),
                            ranking_lib:update(?ranking_abyss, get(?pd_id),
                                {
                                    NewMaxScore,
                                    PlayerAbyssTab#player_abyss_tab.max_hard_layer + NewMaxEasyLayer,
                                    NewMaxEasyLayer,
                                    PlayerAbyssTab#player_abyss_tab.max_hard_layer
                                }),
%%                            ranking_lib:flush_rank_only_by_rankname(?ranking_abyss),
                            util:is_flush_rank_only_by_rankname(?ranking_abyss, get(?pd_id)),
                            {MyIndex, _FScore} = ranking_lib:get_rank_order(?ranking_abyss, get(?pd_id), {0, 0}),
                            put(?pd_abyss_tab, PlayerAbyssTab#player_abyss_tab{
                                score = NewScore,
                                max_score = NewMaxScore,
                                rankIndex = MyIndex,
                                max_easy_layer = NewMaxEasyLayer
                            });
                        Diff =:= ?pd_abyss_fight_hard ->
                            NewMaxScore = max(NewScore + PlayerAbyssTab#player_abyss_tab.score, PlayerAbyssTab#player_abyss_tab.max_score),
                            NewMaxHardLayer = max(Layer -1, PlayerAbyssTab#player_abyss_tab.max_hard_layer),
                            ranking_lib:update(?ranking_abyss, get(?pd_id),
                                {
                                    NewMaxScore,
                                    NewMaxHardLayer + PlayerAbyssTab#player_abyss_tab.max_easy_layer,
                                    PlayerAbyssTab#player_abyss_tab.max_easy_layer,
                                    NewMaxHardLayer
                                }),
%%                            ranking_lib:flush_rank_only_by_rankname(?ranking_abyss),
                            util:is_flush_rank_only_by_rankname(?ranking_abyss, get(?pd_id)),
                            {MyIndex, _FScore} = ranking_lib:get_rank_order(?ranking_abyss, get(?pd_id), {0, 0}),
                            put(?pd_abyss_tab, PlayerAbyssTab#player_abyss_tab{
                                hard_score = NewScore,
                                max_score = NewMaxScore,
                                rankIndex = MyIndex,
                                max_hard_layer = NewMaxHardLayer
                            })
                    end,
                    ?player_send(abyss_sproto:pkg_msg(?MSG_ABYSS_COMPLETE, {CurNewScore, CurNewScore, NewScore, NewPrizeList2}));
                _ ->
                    ok
            end,
            game_res:try_give_ex(NewPrizeList2, ?S_MAIL_INSTANCE, ?FLOW_REASON_ABYSS),
            %% ?INFO_LOG("玩家中途退出结算NewPrizeList:~p", [NewPrizeList]),
            %% ?INFO_LOG("CurNewScore, CurNewScore, NewScore:~p",[{CurNewScore, CurNewScore, NewScore}]),
            %% mail_mng:send_sysmail(attr_new:get(?pd_id), MailInfo, [{Bid, Num} | TailList]),

            %% 结算时重置本次战斗的积分和奖励列表
            erlang:put(?abyss_prize_info, AbyssPrizeInfo#player_abyss_prize_info_tab{abyss_score = 0, prizeList = [], is_in_abyss = ?false}),
            put(?already_in_abyss,?false),
            dbcache:update(?player_abyss_prize_info_tab, get(?abyss_prize_info))
    end;

%% main_instance_mng的调用有变动，这里新增一个接口
ins_complete(?ins_complete, {MainInsCFG, _KillMonster, _WaveNum, _DieCount, _KillMinMonsterCount,
                              _KillBossMonsterCount, PrizeId, _MaxDoubleHit, _ShoujiCount, _PassTime, _MonsterBidList}, _CallArg) ->
    ins_complete(?ins_complete, {MainInsCFG, _KillMonster, _WaveNum, _DieCount, _KillMinMonsterCount, _KillBossMonsterCount, _PassTime, PrizeId}, _CallArg);

ins_complete(_InsState, _, _CallArg) ->
    ok.

%% 根据衰减度设置奖励
get_prize_by_percent(AbyssPercent, PrizeInfo) ->
    %% ?INFO_LOG("PrizeInfo:~p",[PrizeInfo]),
    NewPrizeInfo =
        lists:foldl(
        fun({Id, Count}, Acc) ->
            NewCount = trunc(Count * AbyssPercent div 100),
            Result =
                if
                    NewCount < 1 ->
                        1;
                    true ->
                        NewCount
                end,
            [{Id, Result} | Acc]
        end,
        [],
        PrizeInfo),
    NewPrizeInfo.

%% 验证衰减度,PassTime是不能是累加的
verify_abyss_decay(PassTime, AbyssPercent) ->
    %?INFO_LOG("PassTime:~p, AbyssPercent:~p",[PassTime, AbyssPercent]),
    %% {开始衰减时间， 每秒衰减多少， 总共衰减多少}
    {BeganSec,DecayPer,_} = misc_cfg:get_abyss_reward_decay(),
    if
        %% 无衰减
        PassTime =< BeganSec ->
            AbyssPercent ;

        true ->
            DecayTime = PassTime - BeganSec,
            DecayPercent = trunc(100 - DecayTime * DecayPer),
            %?INFO_LOG("DecayTime:~p, DecayPercent:~p",[DecayTime, DecayPercent]),
            if
                DecayPercent - AbyssPercent >= 5 ->
                    ?INFO_LOG("衰减度误差大于5"),
                    DecayPercent;
                true ->
                    AbyssPercent
            end
    end.

online() ->
    ?ifdo(player:is_daliy_first_online() =:= ?false,
        reset_update()).

offline(_SelfId) ->
    ok.

save_data(_SelfId) ->
    case get(?pd_abyss_tab) of
        0 -> ok;
        PlayerAbyssTab -> dbcache:update(?player_abyss_tab, PlayerAbyssTab)
    end,
    case get(?abyss_prize_info) of
        #player_abyss_prize_info_tab{} ->
            dbcache:update(?player_abyss_prize_info_tab, get(?abyss_prize_info));
        _ ->
            ok
    end.

handle_client({?GET_SELECT_ABYSS_INFO, {}}) -> handle_client(?GET_SELECT_ABYSS_INFO, {});
handle_client({Pack, Arg}) ->
    case task_open_fun:is_open(?OPEN_ABYSS) of
        ?false -> ?return_err(?ERR_NOT_OPEN_FUN);
        ?true -> handle_client(Pack, Arg)
    end.

handle_client(?GET_SELECT_ABYSS_INFO, {}) ->
    case get(?pd_abyss_tab) of
        0 -> ?return_err(?ERR_ABYSS_NOT_OPEN);
        PlayerAbyssTab ->
            PlayerAbyssTab = get(?pd_abyss_tab),
            Info =
                {
                    PlayerAbyssTab#player_abyss_tab.max_easy_layer,
                    PlayerAbyssTab#player_abyss_tab.max_hard_layer,
                    PlayerAbyssTab#player_abyss_tab.easy_layer,
                    PlayerAbyssTab#player_abyss_tab.hard_layer,
                    PlayerAbyssTab#player_abyss_tab.auto_easy_layer,
                    PlayerAbyssTab#player_abyss_tab.auto_hard_layer,
                    PlayerAbyssTab#player_abyss_tab.daily_count,
                    PlayerAbyssTab#player_abyss_tab.buy_fight_count,
                    PlayerAbyssTab#player_abyss_tab.daily_reset,
                    PlayerAbyssTab#player_abyss_tab.buy_daily_reset,
                    PlayerAbyssTab#player_abyss_tab.score,
                    PlayerAbyssTab#player_abyss_tab.hard_score,
                    PlayerAbyssTab#player_abyss_tab.rankIndex
                },
            ?player_send(abyss_sproto:pkg_msg(?GET_SELECT_ABYSS_INFO, Info))
    end;

%% %% @doc 自动爬塔
%% handle_client(?MSG_ABYSS_AUTO_FIGHT, {Diff}) ->
%%     case get(?pd_abyss_tab) of
%%         0 -> ?return_err(?ERR_ABYSS_NOT_OPEN);
%%
%%         PlayerAbyssTab ->
%%             Layer = case Diff of
%%                         ?pd_abyss_fight_easy -> PlayerAbyssTab#player_abyss_tab.auto_easy_layer + 1;
%%                         ?pd_abyss_fight_hard -> PlayerAbyssTab#player_abyss_tab.auto_hard_layer + 1
%%                     end,
%%
%%             %% 手动爬塔的层数必须要大于自动爬塔层数才有奖励
%%             Fun =
%%                 fun(DBLayer) ->
%%                     if
%%                         DBLayer >= Layer ->
%%                             prize(Diff, Layer);
%%                         true ->
%%                             %% ?INFO_LOG("DBLayer:~p, Layer:~p",[DBLayer,Layer]),
%%                             {error, ?ERR_ABYSS_AUTO_MAX_LAYER}
%%                     end
%%                 end,
%%
%%             case Diff of
%%                 ?pd_abyss_fight_easy ->
%%                     case Fun(PlayerAbyssTab#player_abyss_tab.easy_layer) of
%%                         ok ->
%%                             Score = get_abyss_integral(Diff, Layer),
%%                             #player_abyss_tab{score = OldScore} = get(?pd_abyss_tab),
%%                             NewScore = Score + OldScore,
%%                             put(?pd_abyss_tab, PlayerAbyssTab#player_abyss_tab{auto_easy_layer = Layer, score = NewScore});
%%                         {error, Other} ->
%%                             ?return_err(Other)
%%                     end;
%%                 ?pd_abyss_fight_hard ->
%%                     case Fun(PlayerAbyssTab#player_abyss_tab.hard_layer) of
%%                         ok ->
%%                             Score = get_abyss_integral(Diff, Layer),
%%                             #player_abyss_tab{score = OldScore} = get(?pd_abyss_tab),
%%                             NewScore = Score + OldScore,
%%                             put(?pd_abyss_tab, PlayerAbyssTab#player_abyss_tab{auto_hard_layer = Layer, score = NewScore});
%%                         {error, Other} ->
%%                             ?return_err(Other)
%%                     end
%%             end
%%     end;

%% @doc 每次扫荡5层
handle_client(?MSG_ABYSS_NEW_AUTO_FIGHT, {Diff}) ->
    case get(?pd_abyss_tab) of
        0 -> ?return_err(?ERR_ABYSS_NOT_OPEN);
        PlayerAbyssTab ->
            Layer = case Diff of
                        ?pd_abyss_fight_easy -> PlayerAbyssTab#player_abyss_tab.auto_easy_layer + 1;
                        ?pd_abyss_fight_hard -> PlayerAbyssTab#player_abyss_tab.auto_hard_layer + 1
                    end,
            case Diff of
                ?pd_abyss_fight_easy ->
                    MaxEasyLayer = get_5_times_layer(PlayerAbyssTab#player_abyss_tab.max_easy_layer),
                    case can_clean_layer(Layer, MaxEasyLayer, []) of
                        {error, Err} ->
                            ?return_err(Err);
                        LayerList  ->
                            Size = length(LayerList),
                            CostPercent = load_vip_new:get_vip_pata_zhekou_by_vip_level(attr_new:get_vip_lvl()),
                            CostList = misc_cfg:get_pata_cost(),
                            case cost:cost_times(CostList, Size, CostPercent, ?FLOW_REASON_ABYSS) of
                                {error, _Reason} ->
                                    ?return_err(?ERR_ABYSS_COST_FAIL);
                                _ ->
                                    MaxLayer = lists:max(LayerList),
                                    PrizeList = get_prize(Diff, LayerList),
                                    ?player_send(abyss_sproto:pkg_msg(?MSG_ABYSS_NEW_AUTO_FIGHT, {PrizeList})),
                                    Score = get_abyss_integral(Diff, LayerList),
                                    #player_abyss_tab{score = OldScore} = get(?pd_abyss_tab),
                                    NewScore = Score + OldScore,
                                    put(?pd_abyss_tab, PlayerAbyssTab#player_abyss_tab{
                                        auto_easy_layer = MaxLayer,
                                        easy_layer = MaxLayer,
                                        score = NewScore,
                                        max_score = max(NewScore + PlayerAbyssTab#player_abyss_tab.hard_score, PlayerAbyssTab#player_abyss_tab.max_score)
                                    })
                            end
                    end;
                ?pd_abyss_fight_hard ->
                    MaxHardLayer = get_5_times_layer(PlayerAbyssTab#player_abyss_tab.max_hard_layer),
                    case can_clean_layer(Layer, MaxHardLayer, []) of
                        {error, Err} ->
                            ?return_err(Err);
                        LayerList  ->
                            Size = length(LayerList),
                            CostPercent = load_vip_new:get_vip_pata_zhekou_by_vip_level(attr_new:get_vip_lvl()),
                            CostList = misc_cfg:get_pata_cost(),
                            case cost:cost_times(CostList, Size, CostPercent, ?FLOW_REASON_ABYSS) of
                                {error, _Reason} ->
                                    ?return_err(?ERR_ABYSS_COST_FAIL);
                                _ ->
                                    MaxLayer = lists:max(LayerList),
                                    PrizeList = get_prize(Diff, LayerList),
                                    ?player_send(abyss_sproto:pkg_msg(?MSG_ABYSS_NEW_AUTO_FIGHT, {PrizeList})),
                                    Score = get_abyss_integral(Diff, LayerList),
                                    #player_abyss_tab{hard_score = OldScore} = get(?pd_abyss_tab),
                                    NewScore = Score + OldScore,
                                    put(?pd_abyss_tab, PlayerAbyssTab#player_abyss_tab{
                                        auto_hard_layer = MaxLayer,
                                        hard_layer = MaxLayer,
                                        hard_score = NewScore,
                                        max_score = max(NewScore+PlayerAbyssTab#player_abyss_tab.score, PlayerAbyssTab#player_abyss_tab.max_score)
                                    })
                            end
                    end
            end
    end;

%% 重置虚空深渊的次数
handle_client(?MSG_ABYSS_RESET_COUNT, {Diff}) ->
    case get(?pd_abyss_tab) of
        0 ->
            ?return_err(?ERR_ABYSS_NOT_OPEN);

        PlayerAbyssTab ->
            {_, L1} = lookup_cfg(reset_cost),
            FreeCount = load_vip_new:get_vip_new_free_times(L1),
            if
                PlayerAbyssTab#player_abyss_tab.daily_reset < (FreeCount + PlayerAbyssTab#player_abyss_tab.buy_daily_reset) ->
                    reset(PlayerAbyssTab, Diff);
                true ->
                    ?return_err(?ERR_ABYSS_MAX_COUNT)
            end
    end;

handle_client(?MSG_ABYSS_FIGHT, {Diff}) ->
    case get(?pd_abyss_tab) of
        0 ->
            ?return_err(?ERR_ABYSS_NOT_OPEN);

        PlayerAbyssTab ->
            Layer = case Diff of
                        ?pd_abyss_fight_easy -> PlayerAbyssTab#player_abyss_tab.easy_layer + 1;
                        ?pd_abyss_fight_hard ->
                            MustEasyLayer = lookup_cfg(open_limit),
                            if
                                PlayerAbyssTab#player_abyss_tab.max_easy_layer >= MustEasyLayer ->
                                    PlayerAbyssTab#player_abyss_tab.hard_layer + 1;
                                true ->
                                    ?return_err(?ERR_ABYSS_EASY_LAYER_NOT_ENOUGH)
                            end
                    end,

            case lookup_cfg(Diff, Layer) of
                none -> ?return_err(?ERR_ABYSS_MAX_ENTER_LAYER);
                [] -> ?return_err(?ERR_ABYSS_MAX_ENTER_LAYER);
                AbyssInsCFG ->
                    %% 挑战解锁等级必须=<角色等级
                    case AbyssInsCFG#main_ins_cfg.limit_level =< get(?pd_level) of
                        true ->
                            {_FightCount, FightList} = lookup_cfg(fight_cost),
                            case FightList of
                                [-1] ->
                                    fight(AbyssInsCFG, Diff, Layer);
                                _ ->
                                    FreeCount = load_vip_new:get_vip_new_free_times(FightList),
                                    if
                                        PlayerAbyssTab#player_abyss_tab.daily_count < FreeCount + PlayerAbyssTab#player_abyss_tab.buy_fight_count ->
                                            fight(AbyssInsCFG, Diff, Layer);
                                        true ->
                                            ?return_err(?ERR_ABYSS_MAX_COUNT)
                                    end
                            end;
                        _ ->
                            ?return_err(?ERR_ABYSS_LIMIT_LEVEL)
                    end
            end
    end;

handle_client(?MSG_ABYSS_BUY_FIGHT_COUNT, {Count}) ->
    case get(?pd_abyss_tab) of
        0 -> ?return_err(?ERR_ABYSS_NOT_OPEN);
        PlayerAbyssTab ->
            CanBuyCount = buy_pata_enter_times(),
            BuyFightCount = PlayerAbyssTab#player_abyss_tab.buy_fight_count,
            if
                BuyFightCount + Count > CanBuyCount ->
                    ?player_send(abyss_sproto:pkg_msg(?MSG_ABYSS_BUY_FIGHT_COUNT, {1})),
                    ?return_err(?ERR_ABYSS_MAX_COUNT);
                true ->
                    {_,L1} = lookup_cfg(fight_cost),
                    CostDiamondNum = get_battle_cost(Count, BuyFightCount + 1, L1),
                    case game_res:try_del([{?PL_DIAMOND, CostDiamondNum}], ?FLOW_REASON_ABYSS) of
                        ok ->
                            ?player_send(abyss_sproto:pkg_msg(?MSG_ABYSS_BUY_FIGHT_COUNT, {0})),
                            put(?pd_abyss_tab,
                                PlayerAbyssTab#player_abyss_tab{
                                    buy_fight_count = BuyFightCount + Count
                                });
                        {error, _Other} ->
                            ?player_send(abyss_sproto:pkg_msg(?MSG_ABYSS_BUY_FIGHT_COUNT, {1})),
                            ?return_err(?ERR_ABYSS_COST_FAIL)
                    end
            end
    end;

handle_client(?MSG_ABYSS_BUY_RESET_COUNT, {Count}) ->
    case get(?pd_abyss_tab) of
        0 -> ?return_err(?ERR_ABYSS_NOT_OPEN);
        PlayerAbyssTab ->
            CanBuyCount = buy_pata_reset_times(),
            BuyResetCount = PlayerAbyssTab#player_abyss_tab.buy_daily_reset,
            if
                BuyResetCount + Count > CanBuyCount ->
                    ?player_send(abyss_sproto:pkg_msg(?MSG_ABYSS_BUY_RESET_COUNT, {1})),
                    ?return_err(?ERR_ABYSS_MAX_COUNT);
                true ->
                    {_,L2} = lookup_cfg(reset_cost),
                    CostDiamondNum = get_battle_cost(Count, BuyResetCount + 1, L2),
                    case game_res:try_del([{?PL_DIAMOND, CostDiamondNum}], ?FLOW_REASON_ABYSS) of
                        ok ->
                            ?player_send(abyss_sproto:pkg_msg(?MSG_ABYSS_BUY_RESET_COUNT, {0})),
                            put(?pd_abyss_tab,
                                PlayerAbyssTab#player_abyss_tab{
                                    buy_daily_reset = BuyResetCount + Count
                                });
                        {error, _Other} ->
                            ?player_send(abyss_sproto:pkg_msg(?MSG_ABYSS_BUY_RESET_COUNT, {1})),
                            ?return_err(?ERR_ABYSS_COST_FAIL)
                    end
            end
    end;

handle_client(_Msg, _Arg) ->
    ok.

%% prize(Diff, Layer) ->
%%     case lookup_cfg(Diff, Layer) of
%%         none ->
%%             {error, ?ERR_ABYSS_NO_THIS_LAYER};
%%
%%         #main_ins_cfg{ins_id = InsId, is_monster_match_level = IsMatch, pass_prize = PrizeId, abyss_integral = Score} ->
%%             case main_ins:get_pass_prize(InsId, IsMatch, PrizeId) of
%%                 0 ->
%%                     {error, ?ERR_ABYSS_NO_THIS_LAYER};
%%
%%                 PassPrizeId ->
%%                     %% ?INFO_LOG("abyss_integral:~p", [Score]),
%%                     DropListRes = main_ins_util:calculate_drop_prize([InsId], get(?pd_level)),
%%                     game_res:set_res_reasion(<<"爬塔">>),
%%                     game_res:try_give_ex(DropListRes, ?S_MAIL_ABYSS_PRIZE, ?FLOW_REASON_ABYSS),
%%
%%                     PrizeInfo = prize:prize_mail(PassPrizeId, ?S_MAIL_ABYSS_PRIZE, ?FLOW_REASON_ABYSS),
%%                     %% ?INFO_LOG("DropListRes:~p",[DropListRes]),
%%                     %% ?INFO_LOG("PrizeInfo:~p",[PrizeInfo]),
%%                     ?player_send(abyss_sproto:pkg_msg(?MSG_ABYSS_AUTO_FIGHT, {Score, DropListRes ++ PrizeInfo}))
%%             end
%%     end.

get_prize(Diff, Layer) when is_list(Layer) ->
    lists:foldl(
        fun(L ,Acc) ->
            Prize = get_prize(Diff, L),
            case Prize of
                {error, Err} ->
                    ?return_err(Err);
                Prize ->
                    [Prize | Acc]
            end
        end,
        [],
        Layer
    );
get_prize(Diff, Layer) ->
    case lookup_cfg(Diff, Layer) of
        none ->
            {error, ?ERR_ABYSS_NO_THIS_LAYER};
        #main_ins_cfg{ins_id = InsId, is_monster_match_level = IsMatch, pass_prize = PrizeId, abyss_integral = Score} ->
            case main_ins:get_pass_prize(InsId, IsMatch, PrizeId) of
                0 ->
                    {error, ?ERR_ABYSS_NO_THIS_LAYER};
                PassPrizeId ->
                    DropListRes = main_ins_util:calculate_drop_prize([InsId], get(?pd_level)),
                    game_res:set_res_reasion(<<"爬塔">>),
                    game_res:try_give_ex(DropListRes, ?S_MAIL_ABYSS_PRIZE, ?FLOW_REASON_ABYSS),

                    PrizeInfo = prize:prize_mail(PassPrizeId, ?S_MAIL_ABYSS_PRIZE, ?FLOW_REASON_ABYSS),
                    {Layer, Score, DropListRes ++ PrizeInfo}
            end
    end.


%% 获得某一层的扫荡积分
get_abyss_integral(Diff, Layer) when is_list(Layer) ->
    lists:foldl(
        fun(L, Acc) ->
            case get_abyss_integral(Diff, L) of
                {error, Err} ->
                    ?return_err(Err);
                Score ->
                    Acc + Score
            end
        end,
        0,
        Layer
    );
get_abyss_integral(Diff, Layer) ->
    case lookup_cfg(Diff, Layer) of
        none ->
            {error, ?ERR_ABYSS_NO_THIS_LAYER};
        #main_ins_cfg{abyss_integral = Score} ->
           Score
    end.

%% get_abyss_integral() ->
%%     #player_abyss_tab{score = OldScore} = get(?pd_abyss_tab),
%%     OldScore.

get_abyss_integral(Diff) ->
    case Diff of
        ?pd_abyss_fight_easy ->
            #player_abyss_tab{score = EasyScore} = get(?pd_abyss_tab),
            EasyScore;
        ?pd_abyss_fight_hard ->
            #player_abyss_tab{hard_score = HardScore} = get(?pd_abyss_tab),
            HardScore
    end.

reset(PlayerAbyssTab, Diff) ->
    NewTab = case Diff of
                 ?pd_abyss_fight_easy ->
                     PlayerAbyssTab#player_abyss_tab{auto_easy_layer = 0, easy_layer = 0, score = 0};
                 ?pd_abyss_fight_hard ->
                     PlayerAbyssTab#player_abyss_tab{auto_hard_layer = 0, hard_layer = 0, hard_score = 0}
             end,
    put(?pd_abyss_tab, NewTab#player_abyss_tab{
        daily_reset = PlayerAbyssTab#player_abyss_tab.daily_reset + 1
    }),
    ?player_send(abyss_sproto:pkg_msg(?MSG_ABYSS_RESET_COUNT, {1})).

fight(AbyssInsCFG, Diff, Layer) ->
    case main_ins_mod:handle_start(abyss_mng, {AbyssInsCFG, AbyssInsCFG#main_ins_cfg.is_monster_match_level}) of
        ok ->
            %% 进入战斗设置状态
            ?INFO_LOG("===============fight====================="),
            AbyssPrizeInfo = erlang:get(?abyss_prize_info),
            erlang:put(?abyss_prize_info, AbyssPrizeInfo#player_abyss_prize_info_tab{is_in_abyss = ?true}),

            put(?abyss_fight_layer, {Diff, Layer}),
            put(?already_in_abyss,?true),
            ?player_send(abyss_sproto:pkg_msg(?MSG_ABYSS_FIGHT, {}));
        error ->
            ?return_err(?ERR_ABYSS_ENTER_SCENE_FIAL)
    end.

reset_update() ->
    case get(?pd_abyss_tab) of
        0 -> 0;
        PlayerAbyssTab -> put(?pd_abyss_tab, PlayerAbyssTab#player_abyss_tab{daily_reset = 0, daily_count = 0, buy_fight_count = 0, buy_daily_reset = 0})
    end.

%% 副本难度，层数
lookup_cfg(Diff, Layer) ->
    %%groups = [#main_ins_cfg.type, #main_ins_cfg.chapter_id],(4,10)
    AbyssIdList = load_cfg_main_ins:lookup_group_main_ins_cfg(#main_ins_cfg.type, ?T_INS_XUKONG),

    FunFoldl = fun(Id, {Index, Data}) ->
        AbyssCFG = load_cfg_main_ins:lookup_main_ins_cfg(Id),
        case AbyssCFG#main_ins_cfg.sub_type of
            Diff ->
                if
                    Layer =:= (Index + 1) ->
                        {Index + 1, AbyssCFG};
                    true ->
                        {Index + 1, Data}
                end;
            _ ->
                {Index, Data}
        end
    end,

    case lists:foldl(FunFoldl, {0, []}, AbyssIdList) of
        {_Layer, AbyssTab} ->
            AbyssTab;
        _ ->
            ?none
    end.

%% 根据Vip等级得到{进入次数,重置次数}
lookup_cfg(count) ->
    Vip = attr_new:get_vip_lvl(),
    %VipCFG = load_vip_right:lookup_vip_right_cfg(Vip),
    % {length(VipCFG#vip_right_cfg.abyss_enter),
    %     length(VipCFG#vip_right_cfg.abyss_reset)};
    {L1,L2} = load_vip_new:get_vip_pata_enter_times_and_reset_times_by_vip_level(Vip),
    {length(L1), length(L2)};

%% {进入次数，进入消耗列表}
lookup_cfg(fight_cost) ->
    Vip = attr_new:get_vip_lvl(),
    %VipCFG = load_vip_right:lookup_vip_right_cfg(Vip),
    %{length(VipCFG#vip_right_cfg.abyss_enter), VipCFG#vip_right_cfg.abyss_enter};
    {L1,_L2} = load_vip_new:get_vip_pata_enter_times_and_reset_times_by_vip_level(Vip),
    {length(L1), L1};

%% {重置次数， 重置消耗列表}
lookup_cfg(reset_cost) ->
    Vip = attr_new:get_vip_lvl(),
    %VipCFG = load_vip_right:lookup_vip_right_cfg(Vip),
    %{length(VipCFG#vip_right_cfg.abyss_reset), VipCFG#vip_right_cfg.abyss_reset};
    {_L1,L2} = load_vip_new:get_vip_pata_enter_times_and_reset_times_by_vip_level(Vip),
    {length(L2), L2};

%% 简单层要比困难层多3层
lookup_cfg(open_limit) ->
    element(1, misc_cfg:get_misc_cfg(viod_abyss_info)).

send_prize_email() ->
    %?INFO_LOG("=============send_prize_email===================="),
    %?DEBUG_LOG("abyss_prize_info:~p", [get(?abyss_prize_info)]),

    AbyssPrizeInfo = erlang:get(?abyss_prize_info),

    #player_abyss_prize_info_tab{prizeList = PrizeList, is_in_abyss = IsInAbyss} = case AbyssPrizeInfo of
        ?undefined ->
            #player_abyss_prize_info_tab{player_id = get(?pd_id),abyss_score = 0, prizeList = [], is_in_abyss = ?false};
        AbyssPrizeInfo ->
            AbyssPrizeInfo
    end,
    case IsInAbyss of
        ?false ->
            ok;
        ?true ->
            %% 挑战次数
            add_daily_count(),
            case PrizeList of
                [] ->
                    ?INFO_LOG("玩家:~p", [PrizeList]),
                    ok;
                _ ->

                    NewPrizeList = zip_prize_list(PrizeList),
                    mail_mng:send_sysmail(attr_new:get(?pd_id), ?S_MAIL_ABYSS_LEAVE_PRIZE, NewPrizeList),
                    ?INFO_LOG("玩家:~p", [PrizeList])
            end
    end,

    %% 重置本次战斗的积分和奖励列表
    erlang:put(?abyss_prize_info, AbyssPrizeInfo#player_abyss_prize_info_tab{abyss_score = 0, prizeList = [], is_in_abyss = ?false}),
    ok.

%% 增加挑战次数
add_daily_count() ->
    AbyssTab = get(?pd_abyss_tab),
    %% {FightCount, _ResetCount} = lookup_cfg(count),

    {FightCount, FightList} = lookup_cfg(fight_cost),
    %%  ?INFO_LOG("FightCount:~p", [FightCount]),
    %%  ?INFO_LOG("Daily_count:~p", [AbyssTab#player_abyss_tab.daily_count]),
    case FightList of
        [-1] ->
            put(?pd_abyss_tab, AbyssTab#player_abyss_tab{daily_count = AbyssTab#player_abyss_tab.daily_count + 1}),
            dbcache:update(?player_abyss_tab, get(?pd_abyss_tab));
        _ ->
            if
                AbyssTab#player_abyss_tab.daily_count < FightCount ->
                    put(?pd_abyss_tab, AbyssTab#player_abyss_tab{daily_count = AbyssTab#player_abyss_tab.daily_count + 1}),
                    dbcache:update(?player_abyss_tab, get(?pd_abyss_tab));
                true ->
                    ?return_err(?ERR_ABYSS_MAX_COUNT)
            end
    end.

%% 合并奖励列表
zip_prize_list(List)->
    lists:foldl(
        fun({Key, Value}, TempList) ->
            case lists:keyfind(Key, 1, TempList) of
                {Key, V} ->
                    NewValue = Value + V,
                    lists:keyreplace(Key, 1, TempList,{Key, NewValue});
                _ ->
                    lists:append([{Key, Value}],TempList)
            end
        end,
        [],
        List
    ).


%% 测试神魔系统
test(PlayerId) ->
    world:send_to_player(PlayerId, ?mod_msg(abyss_mng, {test_abyss_info})).

test(PlayerId, Diff) ->
    world:send_to_player(PlayerId, ?mod_msg(abyss_mng, {auto_fight,Diff})).

get_5_times_layer(Layer) ->
    N = Layer div 5,
    N * 5.

%% 每次能扫荡到的层数
can_clean_layer(Layer, MaxLayer, LayerList) when (Layer rem 5 =:= 0 andalso MaxLayer >= Layer) ->
    [Layer | LayerList];
can_clean_layer(Layer, MaxLayer, LayerList) when (MaxLayer >= Layer) ->
    NewLayerList = [Layer | LayerList],
    can_clean_layer(Layer + 1, MaxLayer, NewLayerList);
can_clean_layer(_Layer, _MaxLayer, _LayerList) ->
    {error, ?ERR_ABYSS_AUTO_MAX_LAYER}.

buy_pata_enter_times() ->
    Vip = attr_new:get_vip_lvl(),
    {L1,_L2} = load_vip_new:get_vip_pata_enter_times_and_reset_times_by_vip_level(Vip),
    FreeTimes = load_vip_new:get_vip_new_free_times(L1),
    length(L1) - FreeTimes.

buy_pata_reset_times() ->
    Vip = attr_new:get_vip_lvl(),
    {_L1,L2} = load_vip_new:get_vip_pata_enter_times_and_reset_times_by_vip_level(Vip),
    FreeTimes = load_vip_new:get_vip_new_free_times(L2),
    length(L2) - FreeTimes.


get_battle_cost(Count, Num, List) ->
    PayList = load_vip_new:get_vip_new_pay_list(List),
    SubList = lists:sublist(PayList, Num, Count),
    ?INFO_LOG("SubList:~p", [SubList]),
    lists:sum(SubList).
