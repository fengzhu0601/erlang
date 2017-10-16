%%%-------------------------------------------------------------------
%%% @author zlb
%%% @doc 竞技场处理客户端请求模块
%%%
%%% @end
%%%-------------------------------------------------------------------

-module(arena_handle_client).

%% API
-export
([
    handle_msg/2 %倒計時消息回調
]).

-include("inc.hrl").
-include("player.hrl").
-include("arena.hrl").
-include("arena_struct.hrl").
-include("arena_mng_reply.hrl").
-include("handle_client.hrl").
-include("item_bucket.hrl").
-include("rank.hrl").

handle_client({Pack, Arg}) ->
    handle_client(Pack, Arg).

handle_client(?MSG_ARENA_MATCH, {ArenaType}) ->
    Ret = case arena_util:get_arena(ArenaType) of
        undefined   -> ret:error(unknown);
        Mod         -> Mod:start()
    end,
    ReplyNum = case Ret of
        ok                          -> ?REPLY_MSG_ARENA_MATCH_OK;
        {error, ready}              -> ?REPLY_MSG_ARENA_MATCH_1;
        {error, max_count}          -> ?REPLY_MSG_ARENA_MATCH_2;
        {error, p2p_outtime}        -> ?REPLY_MSG_ARENA_MATCH_3;
        {error, multi_p2p_outtime}  -> ?REPLY_MSG_ARENA_MATCH_4;
        _Err                        -> ?REPLY_MSG_ARENA_MATCH_255
    end,
    ?INFO_LOG("ReplyNum:~p, Ret:~p",[ReplyNum, Ret]),
    ?player_send(arena_sproto:pkg_msg(?MSG_ARENA_MATCH, {ReplyNum})),
    ok;

%% 取消匹配
handle_client(?MSG_ARENA_CANEL_MATCH, {}) ->
    PlayerId = get(?pd_id),
    case arena_util:stop() of
        ok ->
            ?player_send(team_sproto:pkg_msg(?MSG_TEAM_QUIT, {PlayerId})),
            ?player_send(arena_sproto:pkg_msg(?MSG_ARENA_CANEL_MATCH, {1}));
        _ ->
            ?player_send(arena_sproto:pkg_msg(?MSG_ARENA_CANEL_MATCH, {0}))
    end,
    ok;

%% 获取竞技场面板
handle_client(?MSG_ARENA_PANEL, {}) ->
    arena_mng:get_arena_info();

% %% 获取竞技场抽奖面板
% handle_client(?MSG_ARENA_TRUN_PANEL, {}) ->
%     arena_mng:get_turn_award_info();

% %% 竞技场抽奖 
% handle_client(?MSG_ARENA_TRUN, {}) ->
%     arena_mng:arena_turn_award();

%% 获取排行榜信息 
handle_client(?MSG_ARENA_RANK, {StartPos, Len}) ->
    {Size, _, Ranks} = ranking_lib:get_rank_order_page(StartPos, Len, ?ranking_arena),
    RankInfos = rank_infos(Ranks, 1, []),
    ?player_send(arena_sproto:pkg_msg(?MSG_ARENA_RANK, {Size, RankInfos})),
    ok;

handle_client(?MSG_ARENA_P2E_RANK, {StartPos, Len}) ->
    Ranks = arena_server:get_rank_page(StartPos, Len),
    Pkg = get_p2e_rank_info(Ranks, []),
    ?player_send(arena_sproto:pkg_msg(?MSG_ARENA_P2E_RANK, {Pkg})),
    ok;

%% 获取竞技场统计界面信息
handle_client(?MSG_ARENA_COUNT, {}) ->
    PlayerId = get(?pd_id),
    Msg = case dbcache:lookup(?player_arena_tab, PlayerId) of
        [
            #arena_info
            {
                p2e_win = EWin, p2e_loss = ELoss, p2p_win = PWin,
                p2p_loss = PLoss, p2p_kill = PKill, arena_lev = ALev,
                m_p2p_win = MPWin, m_p2p_loss = MPLoss, m_p2p_kill = MPKill, m_p2p_die = MPDie
            }
        ] ->
            #arena_cfg{kill_ratio = KillPer} = load_arena_cfg:lookup_arena_cfg(ALev),
            NMPKill = max(0, (MPKill - MPDie) * KillPer),
            {EWin, ELoss, PWin, PLoss, PKill, MPWin, MPLoss, NMPKill};
        _ ->
            erlang:make_tuple(8, 0)
    end,
    ?player_send(arena_sproto:pkg_msg(?MSG_ARENA_COUNT, Msg)),
    ok;

%发起挑战
handle_client(?MSG_ARENA_DUEL, {MPlayerId}) ->
    %%TODO 判断玩家是否被加入黑名单
    SelfId = get(?pd_id),
    Name = get(?pd_name),
    PlayerName = case arena_server:is_arena_robot(MPlayerId) of
        true ->
            case dbcache:lookup(?arena_robot_tab, MPlayerId) of
                [#arena_robot_tab{name = N}] -> N;
                _ -> []
            end;
        _ ->
            player:lookup_info(MPlayerId, ?pd_name)
    end,
    SceneId = scene_mng:lookup_player_scene_id_if_online(MPlayerId),
    IsOnline = ?if_else(SceneId =:= offline, ?FALSE, ?TRUE),
    IsInRoom = api:player_is_in_normalRoom(MPlayerId),
    if
        SelfId =:= MPlayerId -> %判断玩家是否是自己
            ?player_send(arena_sproto:pkg_msg(?MSG_ARENA_DUEL_RET, {MPlayerId, PlayerName, ?REPLY_MSG_ARENA_COMPETE_2}));
        IsOnline =:= ?FALSE -> %判断玩家是否在线
            ?player_send(arena_sproto:pkg_msg(?MSG_ARENA_DUEL_RET, {MPlayerId, PlayerName, ?REPLY_MSG_ARENA_COMPETE_2}));
        IsInRoom =:= ?FALSE -> %玩家不在主场景
            ?player_send(arena_sproto:pkg_msg(?MSG_ARENA_DUEL_RET, {MPlayerId, PlayerName, ?REPLY_MSG_ARENA_COMPETE_2}));
        ?true ->
            %玩家收到邀请后，在他响应邀请前都不能再收到邀请。
            case my_ets:get(MPlayerId, 0) of
                0 ->
                    my_ets:set(MPlayerId,1),
                    world:send_to_player_if_online(MPlayerId, ?to_client_msg(arena_sproto:pkg_msg(?MSG_ARENA_RECEIVE_DUEL, {SelfId, Name})));
                1 ->
                    ?player_send(arena_sproto:pkg_msg(?MSG_ARENA_DUEL_RET,{MPlayerId, PlayerName, ?REPLY_MSG_ARENA_COMPETE_3}))
            end
    end,
    ok;

%接收到挑战
handle_client(?MSG_ARENA_RECEIVE_DUEL, {MPlayerId, IsAgree}) ->
    SelfId = get(?pd_id),
    Name = get(?pd_name),
    my_ets:delete(SelfId),
    Code = case IsAgree of
        0 ->
            ?REPLY_MSG_ARENA_COMPETE_OK;
        1 ->
            ?REPLY_MSG_ARENA_COMPETE_1
    end,
    case IsAgree of
        0 ->
            %玩家发起切磋后，在对方还未响应前马上进副本，这时PK要检查场景
            AIsInRoom = api:player_is_in_normalRoom(MPlayerId),
            BIsInRoom = api:player_is_in_normalRoom(SelfId),
            if
                AIsInRoom =:= ?FALSE orelse BIsInRoom =:= ?FALSE -> %玩家不在主场景
                    ?player_send(arena_sproto:pkg_msg(?MSG_ARENA_DUEL_RET,{SelfId, Name, ?REPLY_MSG_ARENA_COMPETE_2}));
                ?true ->
                    world:send_to_player_if_online(MPlayerId, ?to_client_msg(arena_sproto:pkg_msg(?MSG_ARENA_DUEL_RET, {SelfId, Name, Code}))),
                    ?player_send(arena_sproto:pkg_msg(?MSG_ARENA_DUEL_RET, {SelfId, Name, Code})),
                    arena_compete:start(MPlayerId)
            end;
        1 ->
            world:send_to_player_if_online(MPlayerId, ?to_client_msg(arena_sproto:pkg_msg(?MSG_ARENA_DUEL_RET,{SelfId, Name, Code})))
    end,
    ok;

% 竞技场商店购买
handle_client(?MSG_ARENA_SHOP_BUY, {Index}) ->
    arena_mng:arena_shop_buy(Index);

%% ==================================================================
%% P2E
%% ==================================================================
handle_client(?MSG_ARENA_PLAYER_INFO_CSC, {}) ->
    arena_p2e:get_p2e_arena_info(),
    ok;

handle_client(?MSG_ARENA_SORE_PLAYERS_CSC, {Type}) ->
    arena_p2e:get_p2e_opponents_info(Type),
    ok;

handle_client(?MSG_ARENA_CHALLENGE_PLAYER_CSC, {EmenyId}) ->
    PlayerId = get(?pd_id),
    ChallengeTimes = attr_new:get(?pd_challenged_count, 0),
    BuyTimes = attr_new:get(?pd_buy_challenged_count, 0),
    case ?ARENA_P2E_FREE_TIMES =:= 0 orelse ?ARENA_P2E_FREE_TIMES + BuyTimes > ChallengeTimes of
        true ->
            case arena_server:create_arena(?ARENA_TYPE_P2E, [PlayerId, EmenyId]) of
                {ok, SceneId, ScenePid} ->
                    case arena_p2e:send_opponent_info(EmenyId) of
                        ok ->
                            {_, {X, Y}, _, _} = misc_cfg:get_arena_single_p2e_scene(),
                            arena_p2e:start_match({SceneId, ScenePid, X, Y});
                        _Err ->
                            ScenePid ! {'@stop@', normal},
                            ?ERROR_LOG("challenged_faild:~p", [_Err])
                    end;
                _E ->
                    ?ERROR_LOG("create arena p2e scene fail ~w", [_E])
            end;
        _ ->
            ?ERROR_LOG("arena p2e times not enough!!! free_times:~p, buy_times:~p, challenge_times:~p", [?ARENA_P2E_FREE_TIMES, BuyTimes, ChallengeTimes]),
            pass
    end,
    ok;

handle_client(?MSG_ARENA_GET_CHALLENGE_PRIZE_CS, {}) ->
    arena_p2e:get_challenge_prize(),
    ok;

handle_client(?MSG_ARENA_GET_CHALLENGE_LOG_CSC, {}) ->
    arena_p2e:sync_challeng_log(get(?pd_id)),
    ok;

handle_client(?MSG_ARENA_BUY_CHALLENGE_COUNT_CSC, {BuyCount}) ->
    arena_p2e:buy_challenge_count(BuyCount),
    ok;

handle_client(_Mod, _Msg) ->
    ?ERROR_LOG("no known msg Mod:~p Msg:~p", [arena_sproto:to_s(_Mod), _Msg]).

%% %% 被动解锁
%% handle_msg(_FromMod, {challenged_ret, _PlayerID}) -> arena_player:on_ret(true);
handle_msg(_FromMod, _Msg) -> ok.

%% player_arena_tab和ranking_tab,
%% 用ranking_tab的段位积分显示
rank_infos([], _Index, Ret) ->
    lists:reverse(Ret);
%%rank_infos([{Id, _} | T], Index, Ret) ->
%%    rank_infos(T, Index + 1, [rank_info({Id, Index}) | Ret]);
rank_infos([{Id, Ranking} | T], Index, Ret) ->
    rank_infos(T, Index + 1, [rank_info({Id, Index, Ranking}) | Ret]).


rank_info({Id, Index}) ->
    {NLev, NName, NCar, NSrvId, NScore} = case dbcache:lookup(?player_arena_tab, Id) of
        [#arena_info{arena_lev = Lev, name = Name, career = Car, arena_cent = Score}] ->
            {Lev, Name, Car, 0, Score};
        _E ->
            {0, <<>>, 0, 0, 0}
    end,
    [Lvl, NPower1] = player:lookup_info(Id, [?pd_level, ?pd_combat_power]),
    {Index, NLev, Id, NName, NCar, NPower1, NSrvId, Lvl, NScore};
%%     {Index, NLev, Id, NName, NCar, NPower, NSrvId}.

rank_info({Id, Index, Ranking}) ->
    {NName, NCar, NSrvId} = case dbcache:lookup(?player_arena_tab, Id) of
        [#arena_info{name = Name, career = Car}] ->
            {Name, Car, 0};
        _E ->
            {<<>>, 0, 0}
    end,
    %% 用原始表的段位积分显示,不用个人表的
    NLev = Ranking div 1000000,
    NScore = Ranking rem 1000000,
    [Lvl, NPower1] = player:lookup_info(Id, [?pd_level, ?pd_combat_power]),
    {Index, NLev, Id, NName, NCar, NPower1, NSrvId, Lvl, NScore}.

get_p2e_rank_info([], Ret) -> lists:reverse(Ret);
get_p2e_rank_info([{Index, Id} | T], Ret) ->
    PersonData = case arena_server:is_arena_robot(Id) of
        true ->
            [#arena_robot_tab{name = N, career = C, lev = L, attr = A}] = dbcache:lookup(?arena_robot_tab, Id),
            {Index, Id, N, C, attr_new:get_combat_power(A), 0, L};
        _ ->
            [N, C, P, L] = player:lookup_info(Id, [?pd_name, ?pd_career, ?pd_combat_power, ?pd_level]),
            {Index, Id, N, C, P, 0, L}
    end,
    get_p2e_rank_info(T, [PersonData | Ret]).
