%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 29. 十二月 2015 下午2:12
%%%-------------------------------------------------------------------
-module(arena_p2e).
-author("clark").

%% API
-export([
    get_p2e_arena_info/0,
    get_p2e_opponents_info/1,
    get_challenge_prize/0,
    buy_challenge_count/1,
    send_opponent_info/1,
    get_opponent_info/2,
    sync_challeng_log/1
]).

-include("i_arena.hrl").
-include("arena.hrl").
-include("inc.hrl").
-include("player.hrl").
-include("arena_struct.hrl").
-include("achievement.hrl").
-include("load_phase_ac.hrl").
-include("load_db_misc.hrl").
-include("item_bucket.hrl").
-include("rank.hrl").
-include("../../wonderful_activity/bounty_struct.hrl").
-include("system_log.hrl").
-include("../../wk_open_server_happy/open_server_happy.hrl").
-include("load_spirit_attr.hrl").

%% =====================================================================
%% CALLBACK FUNC
%% =====================================================================
start() -> ok.

stop() ->
    ok.

start_match({SceneId, ScenePid, X, Y}) ->
    case scene_mng:enter_scene_request(SceneId, X, Y) of
        approved ->
            limit_value_eng:inc_daily_value(?day_arena_p2e_count),
            %% 参与竞技场人机模式次数
            bounty_mng:do_bounty_task(?BOUNTY_TASK_ARENA_P2E, 1),
            phase_achievement_mng:do_pc(?PHASE_AC_ARENA_RENJI, 1),
            erlang:put(pd_is_send_prize, false),
            ok;
        _E ->
            ScenePid ! {'@stop@', normal},
            ?ERROR_LOG("enter p2e arena fail ~w", [_E]),
            ok
    end.

over_match({
    {
        [PlayerId1, PlayerId2], _ArenaType, IsWin, _Kill, _Die
    },
    AI = #arena_info
    {
        award_state = AwardState,
        best_rank = BestRank,
        p2e_win = P2eWin,
        p2e_loss = P2eLoss,
        flush_times = Times,
        challenge_list = ChallengeList
    },
    #arena_cfg
    {
        p2e_win = {EWinC, EWinCTpL},
        p2e_loss = {ELossC, ELossCTpL}
    }
}) ->
    OpponentId = case get(?pd_id) of
        PlayerId1 -> PlayerId2;
        _ -> PlayerId1
    end,
    attr_new:set(?pd_is_first_p2e_arena, 1),
    achievement_mng:do_ac(?pkrumen),
    {NewTab, Cent, List} = case IsWin of
        ?TRUE ->
            % NewEWinCTpL = prize:double_items(5000, EWinCTpL),
            case EWinCTpL of
                [{_Key, Honour}] -> put(?pd_get_honour, Honour);
                _ -> put(?pd_get_honour, 0)
            end,
            achievement_mng:do_ac(?dantiaozhiwang),
            achievement_mng:do_ac(?zuiqiangwangze),
            %% 参与竞技场匹配模式或团队模式的总胜利次数
            phase_achievement_mng:do_pc(?PHASE_AC_ARENA_WIN, 1),
            {load_arena_cfg:add_arena_cent(AI#arena_info{p2e_win = P2eWin + 1}, EWinC), EWinC, EWinCTpL};
        _ ->
            % NewELossCTpL = prize:double_items(5000, ELossCTpL),
            case ELossCTpL of
                [{_Key, Honour}] -> put(?pd_get_honour, Honour);
                _ -> put(?pd_get_honour, 0)
            end,
            P2eLAI = AI#arena_info{p2e_loss = P2eLoss + 1},
            {load_arena_cfg:sub_arena_cent(P2eLAI, ELossC), -ELossC, ELossCTpL}
    end,
    NewRank = update_rank(get(?pd_id), OpponentId, IsWin, AwardState, BestRank),
    NewList = case IsWin of
        ?TRUE ->
            OpponentList = get_p2e_challenge_list(),
            {RetList, NewChallengeList} = get_p2e_opponents_info_ex(OpponentList),
            ?player_send(arena_sproto:pkg_msg(?MSG_ARENA_SORE_PLAYERS_CSC, {RetList, Times})),
            NewChallengeList;
        _ ->
            ChallengeList
    end,
    %% 参与竞技场人机模式的排名达到的排名
    CurOrder = arena_server:get_rank_by_player_id(get(?pd_id)),
    if
        CurOrder =< 100 -> phase_achievement_mng:do_pc(?PHASE_AC_ARENA_RANK, 10001, CurOrder);
        true -> pass
    end,
    daily_task_tgr:do_daily_task({?ev_arena_pve_fight, 0},1),
    {NewTab#arena_info{best_rank = NewRank, challenge_list = NewList}, Cent, List}.

%% =====================================================================
%% API
%% =====================================================================
get_p2e_arena_info() ->
    FinishTime = arena_server:get_p2e_prize_finish_time(),
    Pkg = {
        attr_new:get(?pd_arena_rank_snapshoot, 1000),   %% 排名
        attr_new:get(?pd_honour, 0),                    %% 荣誉
        attr_new:get(?pd_arena_win_streak, 0),          %% 连胜数
        get_left_p2e_challenged_count(),                %% 挑战次数
        attr_new:get(?pd_buy_challenged_count, 0),      %% 购买次数
        can_get_prize(),                                %% 可否领奖(1可领奖 0不可领奖)
        FinishTime
    },
    ?player_send(arena_sproto:pkg_msg(?MSG_ARENA_PLAYER_INFO_CSC, {Pkg})).

%% 获得挑战清单
get_p2e_opponents_info(Type) ->
    PlayerId = get(?pd_id),
    case Type of
        0 ->    %% 打开
            case dbcache:lookup(?player_arena_tab, PlayerId) of
                [#arena_info{flush_times = Times, challenge_list = List} = Tab] ->
                    OpponentList = case length(List) < 3 orelse lists:member(PlayerId, [arena_server:get_player_id_by_rank(Rank) || Rank <- List]) of
                        true -> get_p2e_challenge_list();
                        _ -> List
                    end,
                    {RetList, ChallengeList} = get_p2e_opponents_info_ex(OpponentList),
                    ?player_send(arena_sproto:pkg_msg(?MSG_ARENA_SORE_PLAYERS_CSC, {RetList, Times})),
                    NewTab = Tab#arena_info{challenge_list = ChallengeList},
                    dbcache:update(?player_arena_tab, NewTab);
                _ ->
                    ?ERROR_LOG("can not find player arena info:player_arena_tab"),
                    pass
            end;
        _ ->    %% 刷新
            {FreeTimes, CostList} = misc_cfg:get_arena_flush_cost(),
            case dbcache:lookup(?player_arena_tab, PlayerId) of
                [#arena_info{flush_times = Times} = Tab] ->
                    case Times >= FreeTimes of
                        true ->
                            ?ERROR_LOG("max_flush_times"),
                            pass;
                        _ ->
                            Cost = case Times + 1 > length(CostList) of
                                true -> lists:last(CostList);
                                _ -> lists:nth(Times + 1, CostList)
                            end,
                            case game_res:can_del([{?PL_DIAMOND, Cost}]) of
                                ok ->
                                    game_res:del([{?PL_DIAMOND, Cost}], ?FLOW_REASON_ARENA),
                                    OpponentList = get_p2e_challenge_list(),
                                    {RetList, ChallengeList} = get_p2e_opponents_info_ex(OpponentList),
                                    ?player_send(arena_sproto:pkg_msg(?MSG_ARENA_SORE_PLAYERS_CSC, {RetList, Times + 1})),
                                    NewTab = Tab#arena_info{flush_times = Times + 1, challenge_list = ChallengeList},
                                    dbcache:update(?player_arena_tab, NewTab);
                                _ ->
                                    ?ERROR_LOG("cost not enough"),
                                    pass
                            end
                    end;
                _ ->
                    ?ERROR_LOG("can not find player arena info:player_arena_tab"),
                    pass
            end
    end.

get_challenge_prize() ->
    case can_get_prize() of
        1 ->
            attr_new:set(?pd_get_arena_prize_tm, com_time:now()),
            case get_pre_section_order(get(?pd_id)) of
                0 ->
                    ret:ok();
                RankOrder ->
                    PrizeId = load_arena_cfg:get_arena_p2e_rank_prize(RankOrder),
                    prize:prize_mail(PrizeId, ?S_MAIL_ARENA_TRUN, ?FLOW_REASON_ARENA),
                    Pkg = {RankOrder, PrizeId},
                    ?player_send(arena_sproto:pkg_msg(?MSG_ARENA_GET_CHALLENGE_PRIZE_CS, Pkg))
            end,
            get_p2e_arena_info();
        _ ->
            ret:ok()
    end.

%% 购买挑战次数
buy_challenge_count(BuyCount) ->
    VipLev = attr_new:get_vip_lvl(),
    L = load_vip_new:get_vip_arean_times_by_vip_level(VipLev),
    CanBuyTimes = load_vip_new:get_vip_new_pay_times(L),
    OldBuyTimes = attr_new:get(?pd_buy_challenged_count, 0),
    if
        (OldBuyTimes + BuyCount) > CanBuyTimes ->
           ?player_send(arena_sproto:pkg_msg(?MSG_ARENA_BUY_CHALLENGE_COUNT_CSC, {0, OldBuyTimes}));
        true ->
            PayList = load_vip_new:get_vip_new_pay_list(L),
            NewBuyTimes = OldBuyTimes + BuyCount,
            DiamondNum = lists:sum(lists:sublist(PayList, OldBuyTimes+1, BuyCount)),
            CostList = [{?PL_DIAMOND, DiamondNum}],
            case game_res:can_del(CostList) of
                ok ->
                    game_res:del(CostList, ?FLOW_REASON_COURSE),
                    put(?pd_buy_challenged_count, NewBuyTimes),
                    ?player_send(arena_sproto:pkg_msg(?MSG_ARENA_BUY_CHALLENGE_COUNT_CSC, {1, NewBuyTimes}));
                _ ->
                    ?player_send(arena_sproto:pkg_msg(?MSG_ARENA_BUY_CHALLENGE_COUNT_CSC, {0, OldBuyTimes}))
            end
    end.
    % case load_vip_new:get_vip_arean_times_by_vip_level(VipLev) of
    %     List when is_list(List) ->
    %         OldBuyTimes = attr_new:get(?pd_buy_challenged_count, 0),
    %         NewBuyTimes = OldBuyTimes + BuyCount,
    %         case NewBuyTimes < length(List) of
    %             true ->
    %                 Cost = lists:sum(lists:sublist(List, OldBuyTimes+1, BuyCount)),
    %                 CostList = [{?PL_DIAMOND, Cost}],
    %                 case game_res:can_del(CostList) of
    %                     {error, _Error} ->
    %                         ?player_send(arena_sproto:pkg_msg(?MSG_ARENA_BUY_CHALLENGE_COUNT_CSC, {0, OldBuyTimes}));
    %                     _ ->
    %                         game_res:set_res_reasion(<<"购买挑战次数">>),
    %                         game_res:del(CostList, ?FLOW_REASON_ARENA),
    %                         attr_new:set(?pd_buy_challenged_count, NewBuyTimes),
    %                         get_p2e_arena_info(),
    %                         ?player_send(arena_sproto:pkg_msg(?MSG_ARENA_BUY_CHALLENGE_COUNT_CSC, {1, OldBuyTimes + BuyCount}))
    %                 end;
    %             _ ->
    %                 ?DEBUG_LOG("buy times not enough:~p", [NewBuyTimes]),
    %                 pass
    %         end;
    %     _ ->
    %         ?DEBUG_LOG("can not find config with vip:~p", [VipLev]),
    %         pass
    % end.

%% 挑战对手
send_opponent_info(EmenyId) ->
    LeftCount = get_left_p2e_challenged_count(),
    case LeftCount > 0 of
        true ->
            ChallengeTimes = attr_new:get(?pd_challenged_count, 0),
            attr_new:set(?pd_challenged_count, ChallengeTimes + 1),
            case arena_server:is_arena_robot(EmenyId) of
                true ->
                    case dbcache:lookup(?arena_robot_tab, EmenyId) of
                        [#arena_robot_tab{attr = Attr, skills = Skills}] ->
                            Pkg = {1, 1, LeftCount, EmenyId, Attr#attr.hp, Attr#attr.mp, Attr#attr.sp, ?r2t(Attr), Skills, []},
                            ?player_send(arena_sproto:pkg_msg(?MSG_ARENA_CHALLENGE_PLAYER_CSC, Pkg));
                        _ ->
                            {error, can_not_get_enemy_attr}
                    end;
                _ ->
                    case player_data_db:lookup_attr(EmenyId, [?pd_hp, ?pd_mp, ?pd_sp, ?pd_attr], []) of
                        [] ->
                            {error, can_not_get_enemy_attr};
                        [Hp, Mp, Sp, Attr] ->
                            {Skills, _LongWen} = player_data_db:lookup_skills(EmenyId),
                            Pkg = {1, 1, LeftCount, EmenyId, Hp, Mp, Sp, ?r2t(Attr), Skills, []},
                            ?player_send(arena_sproto:pkg_msg(?MSG_ARENA_CHALLENGE_PLAYER_CSC, Pkg)),
                            ok
                    end
            end;
        _ ->
            {error, times_not_enough}
    end.

sync_challeng_log(PlayerID) ->
    LogList = arena_log_db:get_challeng_log(PlayerID),
    Fun = fun
            (_ThisFun, []) -> [];
            (_ThisFun, [{player_arena_log_tab, _ID, [{PlayerId,Name,Carrer,IsAcc,Time,IsVict,Rank,Honor}]}]) ->
                [{PlayerId,Name,Carrer,IsAcc,Time,IsVict,Rank,Honor}];
            (ThisFun, [{player_arena_log_tab, _ID, [Tuple, {PlayerId,Name,Carrer,IsAcc,Time,IsVict,Rank,Honor}]}]) ->
                [{PlayerId,Name,Carrer,IsAcc,Time,IsVict,Rank,Honor} | ThisFun(ThisFun, [Tuple])]
    end,
    LogList1 = Fun(Fun, LogList),
    ?player_send(arena_sproto:pkg_msg(?MSG_ARENA_GET_CHALLENGE_LOG_CSC, {1, LogList1})).

%% =====================================================================
%% PRIVATE
%% =====================================================================
get_left_p2e_challenged_count() ->
    attr_new:get(?pd_buy_challenged_count, 0) + ?ARENA_P2E_FREE_TIMES - attr_new:get(?pd_challenged_count, 0).

can_get_prize() ->
    case load_db_misc:get(?misc_arena_pre_over_tm, 0) of
        0 ->
            0;
        LastFinishTime ->
            case attr_new:get(?pd_get_arena_prize_tm, 0) of
                0 ->
                    case get_pre_section_order(get(?pd_id)) of
                        0 -> 0;
                        _ -> 1
                    end;
                LastGetPrizeTime ->
                    case LastFinishTime > LastGetPrizeTime of
                        true -> 1;
                        _ -> 0
                    end
            end
    end.

get_p2e_opponents_info_ex(OpponentList) ->
    OpsList = lists:foldl(
        fun(Order, Acc) ->
                case arena_server:get_player_id_by_rank(Order) of
                    0 ->
                        Acc;
                    PlayerId ->
                        case get_opponent_info(PlayerId, Order) of
                            ?none -> Acc;
                            Attr -> [Attr | Acc]
                        end
                end
        end,
        [],
        OpponentList
    ),
    case length(OpsList) < 3 of
        true ->
            NewList = get_p2e_challenge_list(),
            get_p2e_opponents_info_ex(NewList);
        _ ->
            {
                lists:sort(
                    fun({_,_,Rank1,_,_,_,_}, {_,_,Rank2,_,_,_,_}) ->
                            Rank1 > Rank2
                    end,
                    OpsList
                ),
                OpponentList
            }
    end.

%% 排名20000名以外玩家，前方玩家为[19700~自己排名-1],[19300~19699],[19001~19299]
%% 排名19000~19999玩家，前方玩家为[18700~自己排名-1],[18300~18699],[18001~18299]
%% 排名18000~18999玩家，前方玩家为[17700~自己排名-1],[17300~17699],[17001~17299]
%% 排名17000~17999玩家，前方玩家为[16700~自己排名-1],[16300~16699],[16001~16299]
%% 排名16000~16999玩家，前方玩家为[15700~自己排名-1],[15300~15699],[15001~15299]
%% 排名15000~15999玩家，前方玩家为[14700~自己排名-1],[14300~14699],[14001~14299]
%% 排名14000~14999玩家，前方玩家为[13700~自己排名-1],[13300~13699],[13001~13299]
%% 排名13000~13999玩家，前方玩家为[12700~自己排名-1],[12300~12699],[12001~12299]
%% 排名12000~12999玩家，前方玩家为[11700~自己排名-1],[11300~11699],[11001~11299]
%% 排名11000~11999玩家，前方玩家为[10700~自己排名-1],[10300~10699],[10001~10299]
%% 排名10000~10999玩家，前方玩家为[9700~自己排名-1],[9300~9699],[9001~9299]
%% 排名9000~9999玩家，前方玩家为[8700~自己排名-1],[8300~8699],[8001~8299]
%% 排名8000~8999玩家，前方玩家为[7700~自己排名-1],[7300~7699],[7001~7299]
%% 排名7000~7999玩家，前方玩家为[6700~自己排名-1],[6300~6699],[6001~6299]
%% 排名6000~6999玩家，前方玩家为[5700~自己排名-1],[5300~5699],[5001~5299]
%% 排名5000~5999玩家，前方玩家为[4700~自己排名-1],[4300~4699],[4001~4299]
%% 排名4000~4999玩家，前方玩家为[3700~自己排名-1],[3300~3699],[3001~3299]
%% 排名3000~3999玩家，前方玩家为[2700~自己排名-1],[2300~2699],[2001~2299]
%% 排名2000~2999玩家，前方玩家为[1700~自己排名-1],[1300~1699],[1001~1299]
%% 排名1000~1999玩家，前方玩家为[970~自己排名-1],[930~969],[901~929]
%% 排名900~999玩家，前方玩家为[870~自己排名-1],[830~869],[801~829]
%% 排名800~899玩家，前方玩家为[770~自己排名-1],[730~769],[701~729]
%% 排名700~799玩家，前方玩家为[670~自己排名-1],[630~669],[601~629]
%% 排名600~699玩家，前方玩家为[570~自己排名-1],[530~569],[501~529]
%% 排名500~599玩家，前方玩家为[470~自己排名-1],[430~469],[401~429]
%% 排名400~499玩家，前方玩家为[370~自己排名-1],[330~369],[301~329]
%% 排名300~399玩家，前方玩家为[270~自己排名-1],[230~269],[201~229]
%% 排名200~299玩家，前方玩家为[170~自己排名-1],[130~169],[101~129]
%% 排名100~199玩家，前方玩家为[97~自己排名-1],[93~96],[91~92]
%% 排名90~99玩家，前方玩家为[87~自己排名-1],[83~86],[81~82]
%% 排名80~89玩家，前方玩家为[77~自己排名-1],[73~76],[71~72]
%% 排名70~79玩家，前方玩家为[67~自己排名-1],[63~66],[61~62]
%% 排名60~69玩家，前方玩家为[57~自己排名-1],[53~56],[51~52]
%% 排名50~59玩家，前方玩家为[47~自己排名-1],[43~46],[41~42]
%% 排名40~49玩家，前方玩家为[37~自己排名-1],[33~36],[31~32]
%% 排名30~39玩家，前方玩家为[27~自己排名-1],[23~26],[21~22]
%% 排名20~29玩家，前方玩家为[17~自己排名-1],[13~16],[11~12]
%% 排名10~19玩家，前方玩家为[8~自己排名-1],[6~7],[4~5]
%% 排名5~9玩家，前方玩家为[4~自己排名-1],3,2
%% 排名4玩家，前方玩家为3,2,1
%% 排名3玩家，前方玩家为4,2,1
%% 排名2玩家，前方玩家为4,3,1
%% 排名1玩家，前方玩家为4,3,2
get_p2e_challenge_list() ->
    MyOrder = attr_new:get(?pd_arena_rank_snapshoot, 10000),
    if
        MyOrder >= 20000 ->
            [com_util:random(19001, 19299), com_util:random(19300, 19699), com_util:random(19700, MyOrder - 1)];
        MyOrder >= 19000 ->
            [com_util:random(18001, 18299), com_util:random(18300, 18699), com_util:random(18700, MyOrder - 1)];
        MyOrder >= 18000 ->
            [com_util:random(17001, 17299), com_util:random(17300, 17699), com_util:random(17700, MyOrder - 1)];
        MyOrder >= 17000 ->
            [com_util:random(16001, 16299), com_util:random(16300, 16699), com_util:random(16700, MyOrder - 1)];
        MyOrder >= 16000 ->
            [com_util:random(15001, 15299), com_util:random(15300, 15699), com_util:random(15700, MyOrder - 1)];
        MyOrder >= 15000 ->
            [com_util:random(14001, 14299), com_util:random(14300, 14699), com_util:random(14700, MyOrder - 1)];
        MyOrder >= 14000 ->
            [com_util:random(13001, 13299), com_util:random(13300, 13699), com_util:random(13700, MyOrder - 1)];
        MyOrder >= 13000 ->
            [com_util:random(12001, 12299), com_util:random(12300, 12699), com_util:random(12700, MyOrder - 1)];
        MyOrder >= 12000 ->
            [com_util:random(11001, 11299), com_util:random(11300, 11699), com_util:random(11700, MyOrder - 1)];
        MyOrder >= 11000 ->
            [com_util:random(10001, 10299), com_util:random(10300, 10699), com_util:random(10700, MyOrder - 1)];
        MyOrder >= 10000 ->
            [com_util:random(9001, 9299), com_util:random(9300, 9699), com_util:random(9700, MyOrder - 1)];
        MyOrder >= 9000 ->
            [com_util:random(8001, 8299), com_util:random(8300, 8699), com_util:random(8700, MyOrder - 1)];
        MyOrder >= 8000 ->
            [com_util:random(7001, 7299), com_util:random(7300, 7699), com_util:random(7700, MyOrder - 1)];
        MyOrder >= 7000 ->
            [com_util:random(6001, 6299), com_util:random(6300, 6699), com_util:random(6700, MyOrder - 1)];
        MyOrder >= 6000 ->
            [com_util:random(5001, 5299), com_util:random(5300, 5699), com_util:random(5700, MyOrder - 1)];
        MyOrder >= 5000 ->
            [com_util:random(4001, 4299), com_util:random(4300, 4699), com_util:random(4700, MyOrder - 1)];
        MyOrder >= 4000 ->
            [com_util:random(3001, 3299), com_util:random(3300, 3699), com_util:random(3700, MyOrder - 1)];
        MyOrder >= 3000 ->
            [com_util:random(2001, 2299), com_util:random(2300, 2699), com_util:random(2700, MyOrder - 1)];
        MyOrder >= 2000 ->
            [com_util:random(1001, 1299), com_util:random(1300, 1699), com_util:random(1700, MyOrder - 1)];
        MyOrder >= 1000 ->
            [com_util:random(901, 929), com_util:random(930, 969), com_util:random(970, MyOrder - 1)];
        MyOrder >= 900 ->
            [com_util:random(801, 829), com_util:random(830, 869), com_util:random(870, MyOrder - 1)];
        MyOrder >= 800 ->
            [com_util:random(701, 729), com_util:random(730, 769), com_util:random(770, MyOrder - 1)];
        MyOrder >= 700 ->
            [com_util:random(601, 629), com_util:random(630, 669), com_util:random(670, MyOrder - 1)];
        MyOrder >= 600 ->
            [com_util:random(501, 529), com_util:random(530, 569), com_util:random(570, MyOrder - 1)];
        MyOrder >= 500 ->
            [com_util:random(401, 429), com_util:random(430, 469), com_util:random(470, MyOrder - 1)];
        MyOrder >= 400 ->
            [com_util:random(301, 329), com_util:random(330, 369), com_util:random(370, MyOrder - 1)];
        MyOrder >= 300 ->
            [com_util:random(201, 229), com_util:random(230, 269), com_util:random(270, MyOrder - 1)];
        MyOrder >= 200 ->
            [com_util:random(101, 129), com_util:random(130, 169), com_util:random(170, MyOrder - 1)];
        MyOrder >= 100 ->
            [com_util:random(91, 92), com_util:random(93, 96), com_util:random(97, MyOrder - 1)];
        MyOrder >= 90 ->
            [com_util:random(81, 82), com_util:random(83, 86), com_util:random(87, MyOrder - 1)];
        MyOrder >= 80 ->
            [com_util:random(71, 72), com_util:random(73, 76), com_util:random(77, MyOrder - 1)];
        MyOrder >= 70 ->
            [com_util:random(61, 62), com_util:random(63, 66), com_util:random(67, MyOrder - 1)];
        MyOrder >= 60 ->
            [com_util:random(51, 52), com_util:random(53, 56), com_util:random(57, MyOrder - 1)];
        MyOrder >= 50 ->
            [com_util:random(41, 42), com_util:random(43, 46), com_util:random(47, MyOrder - 1)];
        MyOrder >= 40 ->
            [com_util:random(31, 32), com_util:random(33, 36), com_util:random(37, MyOrder - 1)];
        MyOrder >= 30 ->
            [com_util:random(21, 22), com_util:random(23, 26), com_util:random(27, MyOrder - 1)];
        MyOrder >= 20 ->
            [com_util:random(11, 12), com_util:random(13, 16), com_util:random(17, MyOrder - 1)];
        MyOrder >= 10 ->
            [com_util:random(4, 5), com_util:random(6, 7), com_util:random(8, MyOrder - 1)];
        MyOrder >= 5 ->
            [2, 3, com_util:random(4, MyOrder - 1)];
        MyOrder =:= 4 ->
            [1, 2, 3];
        MyOrder =:= 3 ->
            [1, 2, 4];
        MyOrder =:= 2 ->
            [1, 3, 4];
        MyOrder =:= 1 ->
            [2, 3, 4];
        true ->
            ?ERROR_LOG("error rank:~p", [MyOrder]),
            [10, 20, 30]
    end.

%% 获得对手显示数据
get_opponent_info(Id, Order) ->
    [Name, Power, Career, LvL, EquipL] = case arena_server:is_arena_robot(Id) of
        true ->
            case dbcache:lookup(?arena_robot_tab, Id) of
                [#arena_robot_tab{name = N, career = C, lev = L, attr = Attr}] ->
                    [N, attr_new:get_combat_power(Attr), C, L, []];
                _ ->
                    [?none, ?none, ?none, ?none, ?none]
            end;
        _ ->
            player:lookup_info(Id, [?pd_name, ?pd_combat_power, ?pd_career, ?pd_level, ?pd_equip])
    end,
    if
        Name == ?none -> ?none;
        Power == ?none -> ?none;
        Career == ?none -> ?none;
        LvL == ?none -> ?none;
        EquipL == ?none -> ?none;
        true -> {Id, Name, Order, Power, Career, LvL, EquipL}
    end.

%% 获得上一波的名次
get_pre_section_order(PlayerId) ->
    List = load_db_misc:get(?misc_arena_pre_rank_data, []),
    case lists:keyfind(PlayerId, 2, List) of
        {Rank, PlayerId} -> Rank;
        _ -> 0
    end.

update_rank(MyId, OpponentId, IsWin, _AwardState, BestRank) ->
    MyRank = arena_server:get_rank_by_player_id(MyId),
    OpponentRank = arena_server:get_rank_by_player_id(OpponentId),
    case IsWin of
        ?TRUE ->
            {NewMyRank, NewOppRank, DiamondNum} = case MyRank > OpponentRank of
                true ->
                    arena_server:update_arena_p2e_rank({MyRank, OpponentId}, {OpponentRank, MyId}),
                    attr_new:set(?pd_arena_rank_snapshoot, OpponentRank),
                    notify_update_p2e_rank(OpponentId, MyRank),
                    notice_system:send_arena_rank_change_notice(OpponentRank),
                    open_server_happy_mng:sync_task(?ARENA_RANK, OpponentRank),
                    Num = send_rank_prize(OpponentRank, BestRank),
                    % {NewList, Num} = send_rank_prize_new(OpponentRank, AwardState),
                    {OpponentRank, MyRank, Num};
                _ ->
                    {MyRank, OpponentRank, 0}
            end,
            Honour = get(?pd_get_honour),
            WinTimes = attr_new:get(?pd_arena_win_streak, 0),
            attr_new:set(?pd_arena_win_streak, WinTimes + 1),
            notice_system:send_arena_win_times_notice(WinTimes + 1),
            Pkg = {1, NewMyRank, Honour, WinTimes + 1, DiamondNum},
            ?player_send(arena_sproto:pkg_msg(?MSG_ARENA_COMPLETE_CHALLENGE_SC, Pkg)),
            %% 日志
            NowTime = util:get_now_second(0),
            push_log(OpponentId, MyId, 0, NowTime, 0, NewOppRank, 0),
            push_log(MyId, OpponentId, 1, NowTime, 1, NewMyRank, Honour),
            min(BestRank, NewMyRank);
        _ ->
            EnemyName = case arena_server:is_arena_robot(OpponentId) of
                true ->
                    [#arena_robot_tab{name = N}] = dbcache:lookup(?arena_robot_tab, OpponentId),
                    N;
                _ ->
                    [Name] = player:lookup_info(OpponentId, [?pd_name]),
                    Name
            end,
            notice_system:send_arena_shutdown_notice(EnemyName, attr_new:get(?pd_arena_win_streak, 0)),
            Honour = get(?pd_get_honour),
            attr_new:set(?pd_arena_win_streak, 0),
            Pkg = {0, MyRank, Honour, 0, 0},
            ?player_send(arena_sproto:pkg_msg(?MSG_ARENA_COMPLETE_CHALLENGE_SC, Pkg)),
            NowTime = util:get_now_second(0),
            push_log(OpponentId, MyId, 0, NowTime, 1, MyRank, 0),
            push_log(MyId, OpponentId, 1, NowTime, 0, OpponentRank, Honour),
            BestRank
    end.

notify_update_p2e_rank(PlayerId, Rank) ->
    world:send_to_player_if_online(PlayerId, ?mod_msg(arena_mng, {update_arena_p2e_rank, Rank})).

send_rank_prize(NewRank, OldRank) ->
    List = load_arena_cfg:lookup_all_arena_p2e_rank_prize_cfg(#arena_p2e_rank_prize_cfg.id),
    {NewIndex, OldIndex} = lists:foldl(
        fun(Id, {Index1, Index2}) ->
                #arena_p2e_rank_prize_cfg{rank = {Min, Max}} = load_arena_cfg:lookup_arena_p2e_rank_prize_cfg(Id),
                NewIndex1 = case NewRank >= Min andalso NewRank =< Max of
                    true -> Id;
                    _ -> Index1
                end,
                NewIndex2 = case OldRank >= Min andalso OldRank =< Max of
                    true -> Id;
                    _ -> Index2
                end,
                {NewIndex1, NewIndex2}
        end,
        {length(List) + 1, length(List) + 1},
        List
    ),
    case NewIndex < OldIndex of
        true ->
            send_all_rank_prize(NewIndex, OldIndex, 0);
        _ ->
            0
    end.

send_all_rank_prize(Max, Max, AllNum) ->
    game_res:try_give_ex([{?PL_DIAMOND, AllNum}], ?FLOW_REASON_ARENA),
    AllNum;
send_all_rank_prize(Min, Max, TempNum) ->
    #arena_p2e_rank_prize_cfg{prize = {_, Num}} = load_arena_cfg:lookup_arena_p2e_rank_prize_cfg(Min),
    send_all_rank_prize(Min + 1, Max, TempNum + Num).

% send_rank_prize_new(NewRank, AwardState) ->
%     List = load_arena_cfg:lookup_all_arena_p2e_rank_prize_cfg(#arena_p2e_rank_prize_cfg.id),
%     [CurId] = lists:filter(
%         fun(Id) ->
%                 #arena_p2e_rank_prize_cfg{rank = {Min, Max}} = load_arena_cfg:lookup_arena_p2e_rank_prize_cfg(Id),
%                 NewRank >= Min andalso NewRank =< Max
%         end,
%         List
%     ),
%     case lists:member(CurId, AwardState) of
%         true ->
%             {AwardState, 0};
%         _ ->
%             #arena_p2e_rank_prize_cfg{prize = {_, Num}} = load_arena_cfg:lookup_arena_p2e_rank_prize_cfg(CurId),
%             game_res:try_give_ex([{?PL_DIAMOND, Num}], ?FLOW_REASON_ARENA),
%             {[CurId | AwardState], Num}
%     end.

push_log(PlayerId, OpsId, IsAccord, Time, Ret, RankOrder, Honour) ->
    Log = create_challenge_log(OpsId, IsAccord, Time, Ret, RankOrder, Honour),
    arena_log_db:update_arena_log(PlayerId, Log),
    world:send_to_player_if_online(PlayerId, ?mod_msg(arena_mng, {push_log, Log})).

%% 产生日志
create_challenge_log(OpsId, IsAccord, Time, Ret, RankOrder, Honour) ->
    [Name, Career] = case arena_server:is_arena_robot(OpsId) of
        true ->
            [#arena_robot_tab{name = N, career = C}] = dbcache:lookup(?arena_robot_tab, OpsId),
            [N, C];
        _ ->
            player:lookup_info(OpsId, [?pd_name, ?pd_career])
    end,
    {OpsId, Name, Career, IsAccord, Time, Ret, RankOrder, Honour}.
