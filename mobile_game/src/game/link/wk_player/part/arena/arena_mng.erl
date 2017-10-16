%%-----------------------------------
%% @Module  : arena_mng
%% @Author  : Holtom
%% @Email   : 
%% @Created : 2016.7.22
%% @Description: 竞技场模块
%%-----------------------------------
-module(arena_mng).

-export([
    get_arena_info/0,
    % get_turn_award_info/0,
    % arena_turn_award/0,
    arena_rank_info/1,
    my_arena_rank_info/0,
    restore_arena_attr/0,
    arena_shop_buy/1
]).

-include("inc.hrl").
-include("player.hrl").
-include("player_mod.hrl").
-include("arena.hrl").
-include("arena_struct.hrl").
-include("rank.hrl").
-include("achievement.hrl").
-include("day_reset.hrl").
-include("week_reset.hrl").
-include("month_reset.hrl").
-include("scene_def.hrl").
-include("arena_mng_reply.hrl").
-include_lib("pangzi/include/pangzi.hrl").
-include("../part/wonderful_activity/bounty_struct.hrl").
-include("system_log.hrl").

% -define(pd_arena_turn0_of_times, pd_arena_turn0_of_times). %% 用来记录竞技场抽奖连续未抽到的次数
% -define(TURN_AWARD_ALL_STAR, 8).

create_mod_data(_SelfId) ->
    ok.

load_mod_data(PlayerId) ->
    case dbcache:lookup(?player_arena_tab, PlayerId) of
        [#arena_info{}] ->
            ignore;
        _ ->
        	Name = get(?pd_name),
        	Career = get(?pd_career),
        	Tab = #arena_info{id = PlayerId, name = Name, career = Career},
        	dbcache:insert_new(?player_arena_tab, Tab)
    end,
    attr_new:set(?pd_arena_rank_snapshoot, arena_server:init_player_p2e_arena_rank(PlayerId)),
    ok.

init_client() ->
    ignore.

view_data(Msg) ->
    Msg.

handle_frame(_) -> ok.

online() ->
	ok.

offline(_) ->
	arena_util:stop(),
    ok.

save_data(_) ->
	ok.

load_db_table_meta() ->
    [
        #db_table_meta{
            name = ?player_arena_tab,
            fields = ?record_fields(arena_info),
            record_name = arena_info,
            load_all = true,
            shrink_size = 1,
            flush_interval = 4
        }
    ].

handle_msg(_FromMod, {finish_arena, PlayerInfo, ArenaType, IsWin, Kill, Die}) ->
    case get(pd_is_send_prize) of   %% 是否已经结算
        true ->
            pass;
        _ ->
            achievement_mng:do_ac(?pkshilian),
            PlayerId = get(?pd_id),
            case dbcache:lookup(?player_arena_tab, PlayerId) of
                [AI = #arena_info{arena_lev = ALev}] ->
                    ACfg = #arena_cfg{} = load_arena_cfg:lookup_arena_cfg(ALev),
                    Mod = arena_util:get_arena(ArenaType),
                    {NAI, _Cent, AwardTpL} = Mod:over_match({{PlayerInfo, ArenaType, IsWin, Kill, Die}, AI, ACfg}),
                    %% 发荣誉
                    NewAwardTpL = case ArenaType of
                        ?ARENA_TYPE_P2E -> %% 人机模式
                            AwardTpL;
                        ?ARENA_TYPE_P2P -> %% 单人模式
                            AwardTpL;
                        ?ARENA_TYPE_MULTI_P2P ->  %% 多人模式
                            prize:double_items(6000, AwardTpL);
                        _ -> 
                            AwardTpL
                    end,
                    game_res:try_give_ex(NewAwardTpL, ?S_MAIL_ARENA_RESULT, ?FLOW_REASON_ARENA),
                    dbcache:update(?player_arena_tab, NAI),
                    api:is_first_arena(),
                    attr_new:set(?pd_is_first_arena, 1),
                    api:is_first_arena(),
                    %% 如果玩家死亡，记录死亡日志
                    % case ArenaType =:= ?ARENA_TYPE_MULTI_P2P of
                    %     true ->
                    %         ok;
                    %     _ ->
                    %         if
                    %             Die =:= 1 ->
                    %                 %% 玩家竞技场死亡日志
                    %                 KillerId =
                    %                     case ArenaType =:= ?ARENA_TYPE_P2E of
                    %                         true ->
                    %                             erlang:get(opponentId);
                    %                         _ ->
                    %                             element(2, PlayerInfo)
                    %                     end,
                    %                 ?INFO_LOG("==========KIllerID:~p",[KillerId]),
                    %                 case player:lookup_info(KillerId, [?pd_name,?pd_career,?pd_level,?pd_honour]) of
                    %                     [KillerName, KillerCareer, KillerLevel, KillerHonour] ->
                    %                         KillerRank =
                    %                             case dbcache:lookup(?player_arena_tab, KillerId) of
                    %                                 [#arena_info{arena_lev = Lev}] ->
                    %                                     Lev;
                    %                                 _E ->
                    %                                     0
                    %                             end,
                    %                         %% 这个场景id有问题
                    %                         RoomId = player:lookup_info(PlayerId, ?pd_scene_id),
                    %                         system_log:info_player_arena_die_log(KillerId,KillerName,KillerCareer,KillerLevel, RoomId, KillerRank, KillerHonour),
                    %                         ok;
                    %                     _ ->
                    %                         pass
                    %                 end;
                    %             true ->
                    %                 ok
                    %         end
                    % end,
                    ok;
                _E ->
                    pass
            end,
            erlang:put(pd_is_send_prize, true)
    end;
handle_msg(_FromMod, {finish_compete, IsWin}) ->
    case get(pd_is_send_prize) of   %% 是否已经结算
        true ->
            pass;
        _ ->
            ?player_send(main_instance_sproto:pkg_msg(?MSG_MAIN_INSTANCE_TEAM_DISSOLVE, {})),
            ?player_send(arena_sproto:pkg_msg(?MSG_ARENA_DUEL_CLEARING, {IsWin})),
            erlang:put(pd_is_send_prize, true)
    end;
handle_msg(_FromMod, {update_arena_p2e_rank, Rank}) ->
    attr_new:set(?pd_arena_rank_snapshoot, Rank);
handle_msg(_FromMod, {push_log, Log}) ->
    Pkg = {2, [Log]},
    ?player_send(arena_sproto:pkg_msg(?MSG_ARENA_GET_CHALLENGE_LOG_CSC, Pkg));
handle_msg(_FromMod, {p2p_start, SceneId, {X, Y}, Dir, Party}) ->
    arena_p2p:start_match({SceneId, X, Y, Dir, Party});
handle_msg(_FromMod, {p2p_start, SceneId, ScenePid, {X, Y}, Dir, Party}) ->
    com_prog:join_sync(?scene_group, SceneId, ScenePid),
    arena_p2p:start_match({SceneId, X, Y, Dir, Party});
handle_msg(_FromMod, {p2p_multi_start, SceneId, {X, Y}, Dir, Party}) ->
    arena_m_p2p:start_match({SceneId, X, Y, Dir, Party});
handle_msg(_FromMod, {p2p_multi_start, SceneId, ScenePid, {X, Y}, Dir, Party}) ->
    com_prog:join_sync(?scene_group, SceneId, ScenePid),
    arena_m_p2p:start_match({SceneId, X, Y, Dir, Party});
handle_msg(_FromMod, {compete_start, SceneId, {X, Y}, Dir, Party}) ->
    arena_compete:start_match({SceneId, X, Y, Dir, Party});
handle_msg(_FromMod, {info_player_arena_die_log, {_KillerId, _KillerName, _KillerCareer, _KillerLevel, _KillerHonour, _KillerRank}}) ->
    % %% 这个场景id有问题
    % RoomId = player:lookup_info(attr_new:get(?pd_id), ?pd_scene_id),
    % system_log:info_player_arena_die_log(KillerId, KillerName, KillerCareer, KillerLevel, RoomId, KillerRank, KillerHonour),
    ok;
handle_msg(_FromMod, {stop_scene, ScenePid}) ->
    com_prog:leave_sync(?scene_group, ScenePid);
handle_msg(FromMod, Msg) ->
    ?ERROR_LOG("~p recv a unknown msg ~p from ~p", [?pname(), Msg, FromMod]).

on_day_reset(SelfId) ->
    attr_new:begin_sync_attr(),
    erlang:put(?pd_buy_challenged_count, 0),
    erlang:put(?pd_challenged_count, 0),
    attr_new:end_sync_attr(),
    case dbcache:lookup(?player_arena_tab, SelfId) of
        [Tab] ->
            dbcache:update(?player_arena_tab, Tab#arena_info{flush_times = 0});
        _ ->
            pass
    end.

on_week_reset(_SelfId) -> ok.
% on_week_reset(SelfId) ->
%     case dbcache:lookup(?player_arena_tab, SelfId) of
%         [Tab = #arena_info{arena_lev = ALev}] ->
%             {AwardState, TrunState} = init_trun_award(ALev),
%             NewTab = Tab#arena_info{award_state = AwardState, trun_state = TrunState},
%             dbcache:update(?player_arena_tab, NewTab);
%         _ ->
%             ?ERROR_LOG("can not find player arena_info, player_id = ~p", [SelfId]),
%             pass
%     end.

on_month_reset(SelfId) ->
    case dbcache:lookup(?player_arena_tab, SelfId) of
        [Tab = #arena_info{}] ->
            NewTab = Tab#arena_info{
                arena_lev = 1,
                arena_cent = 0,
                p2e_win = 0,
                p2e_loss = 0,
                p2p_win = 0,
                p2p_loss = 0,
                p2p_kill = 0,
                m_p2p_win = 0,
                m_p2p_loss = 0,
                m_p2p_kill = 0,
                m_p2p_die = 0
            },
            dbcache:update(?player_arena_tab, NewTab);
        _ ->
            ?ERROR_LOG("can not find player arena_info, player_id = ~p", [SelfId]),
            pass
    end. 

get_arena_info() ->
    IsFirstP2e = attr_new:get(?pd_is_first_p2e_arena, 0),
    IsFirstNum = case IsFirstP2e =:= 0 of
        true -> 1;
        _ -> 0
    end,
    PlayerId = get(?pd_id),
    Msg = case dbcache:lookup(?player_arena_tab, PlayerId) of
        [#arena_info{arena_lev = Lev, arena_cent = Cent}] ->
            Index = case ranking_lib:get_rank_order(?ranking_arena, PlayerId) of
                {TmpIndex, _} -> TmpIndex;
                _ -> 0
            end,
            {Lev, Cent, Index, IsFirstNum};
        _ ->
            {1, 0, 0, IsFirstNum}
    end,
    ?player_send(arena_sproto:pkg_msg(?MSG_ARENA_PANEL, Msg)).

% get_turn_award_info() ->
%     PlayerId = get(?pd_id),
%     Msg = case dbcache:lookup(?player_arena_tab, PlayerId) of
%         [#arena_info{award_state = AS, trun_state = TS}] ->
%             {tuple_to_list(TS), AS};
%         _ ->
%             {[], []}
%     end,
%     ?player_send(arena_sproto:pkg_msg(?MSG_ARENA_TRUN_PANEL, Msg)).

% arena_turn_award() ->
%     PlayerId = get(?pd_id),
%     Msg = case dbcache:lookup(?player_arena_tab, PlayerId) of
%         [Tab = #arena_info{award_state = AS, trun_state = TS, arena_lev = ArenaLevel}]->
%             StarNum = count_star(0, TS),
%             case StarNum < ?TURN_AWARD_ALL_STAR of
%                 true ->
%                     CostTuple = misc_cfg:get_arena_glory_cost(),
%                     CostNum = element(StarNum + 1, CostTuple),
%                     case game_res:can_del([{?PL_HONOUR, CostNum}]) of
%                         ok ->
%                             game_res:set_res_reasion(<<"竞技场抽奖">>),
%                             game_res:del([{?PL_HONOUR, CostNum}], ?FLOW_REASON_ARENA_TURN_AWARD),
%                             NoAwardTimes = attr_new:get(?pd_arena_turn0_of_times, 0),
%                             BaodiList = load_arena_cfg:get_arena_cfg_turn_times(ArenaLevel),
%                             Pos = case lists:keyfind(StarNum + 1, 1, BaodiList) of
%                                 {_, LimitTimes} when LimitTimes =/= 0 ->
%                                     case NoAwardTimes + 1 >= LimitTimes of
%                                         true ->
%                                             {_, RetList} = lists:foldl(
%                                                 fun(Val, {Index, List}) ->
%                                                         case Val =:= 1 of
%                                                             true -> {Index + 1, [Index | List]};
%                                                             _ -> {Index + 1, List}
%                                                         end
%                                                 end,
%                                                 {1, []},
%                                                 tuple_to_list(TS)
%                                             ),
%                                             [RandomVal] = com_util:rand_more(RetList, 1),
%                                             RandomVal;
%                                         _ ->
%                                             com_util:random(1, ?TURN_AWARD_ALL_STAR)
%                                     end;
%                                 _ ->
%                                     com_util:random(1, ?TURN_AWARD_ALL_STAR)
%                             end,
%                             %% 开始抽奖
%                             case element(Pos, TS) of
%                                 ?TRUE ->
%                                     NTS = setelement(Pos, TS, ?FALSE),
%                                     NStarNum = StarNum + 1,
%                                     {ItemBid, ItemNum, ?FALSE} = lists:nth(NStarNum, AS),
%                                     AsTp = erlang:list_to_tuple(AS),
%                                     NAS =  tuple_to_list(setelement(NStarNum, AsTp, {ItemBid, ItemNum, ?TRUE})),
%                                     NewTab = Tab#arena_info{award_state = NAS, trun_state = NTS},
%                                     case game_res:can_give([{ItemBid, ItemNum}], ?S_MAIL_ARENA_TRUN) of
%                                         ok ->
%                                             bounty_mng:do_bounty_task(?BOUNTY_TASK_ARENA_CHOUJIANG, 1),
%                                             game_res:give([{ItemBid, ItemNum}], ?S_MAIL_ARENA_TRUN, ?FLOW_REASON_ARENA_TURN_AWARD),
%                                             dbcache:update(?player_arena_tab, NewTab),
%                                             attr_new:set(?pd_arena_turn0_of_times, 0),
%                                             {?REPLY_MSG_ARENA_TRUN_OK, Pos};
%                                         _ ->
%                                             {?REPLY_MSG_ARENA_TRUN_255, 0}
%                                     end;
%                                 _ ->
%                                     attr_new:set(?pd_arena_turn0_of_times, NoAwardTimes + 1),
%                                     {?REPLY_MSG_ARENA_TRUN_OK, Pos}
%                             end;
%                         _ ->
%                             {?REPLY_MSG_ARENA_TRUN_1, 0}
%                     end;
%                 _ ->
%                     {?REPLY_MSG_ARENA_TRUN_255, 0}
%             end;
%         _E ->
%             {?REPLY_MSG_ARENA_TRUN_255, 0}
%     end,
%     ?player_send(arena_sproto:pkg_msg(?MSG_ARENA_TRUN, Msg)).

arena_rank_info({Id, Index}) ->
    {NLev, NCent, NName, NPLev, NCar, NPower} = case dbcache:lookup(?player_arena_tab, Id) of
        [#arena_info{arena_lev = Lev, name = Name, career = Car, arena_cent = Cent}] ->
            [PLev, Power] = player:lookup_info(Id, [?pd_level, ?pd_combat_power]),
            {Lev, Cent, Name, PLev, Car, Power};
        _E ->
            {0, 0, <<>>, 0, 1, 0}
    end,
    {Index, NLev, NCent, Id, NName, NPLev, NCar, NPower}.

my_arena_rank_info() ->
    case dbcache:lookup(?player_arena_tab, get(?pd_id)) of
        [#arena_info{arena_lev = Lev, arena_cent = Cent}] ->
            {Lev, Cent};
        _ -> {0, 0}
    end.

%%还原人物身上的段位属性
restore_arena_attr() ->
    ALev =
        case dbcache:lookup(?player_arena_tab, get(?pd_id)) of
            [#arena_info{arena_lev = Lev}] ->
                Lev;
            _E ->
                0
        end,
    case load_arena_cfg:lookup_arena_cfg(ALev) of
        #arena_cfg{attr_award = AttrAward} ->
            Attr = attr:sats_2_attr(AttrAward),
            attr_new:player_add_attr(Attr);

        _ ->
            pass
    end.

arena_shop_buy(Index) ->
    case load_arena_cfg:lookup_arena_shop_cfg(Index) of
        #arena_shop_cfg{item = ItemBid, num = Num, price = Price} ->
            case {game_res:can_del([{?PL_HONOUR, Price}]), game_res:can_give([{ItemBid, Num}], ?S_MAIL_ARENA_TRUN)} of
                {ok, ok} ->
                    bounty_mng:do_bounty_task(?BOUNTY_TASK_ARENA_CHOUJIANG, 1),
                    game_res:del([{?PL_HONOUR, Price}], ?FLOW_REASON_ARENA_SHOP),
                    game_res:give([{ItemBid, Num}], ?S_MAIL_ARENA_TRUN, ?FLOW_REASON_ARENA_SHOP),
                    ?player_send(arena_sproto:pkg_msg(?MSG_ARENA_SHOP_BUY, {0}));
                _ ->
                    ?player_send(arena_sproto:pkg_msg(?MSG_ARENA_SHOP_BUY, {1}))
            end;
        _ ->
            ?ERROR_LOG("can not find index int arena_shop.txt, index = ~p", [Index]),
            ?player_send(arena_sproto:pkg_msg(?MSG_ARENA_SHOP_BUY, {2}))
    end.

%% ===========================================================================
%% private
%% ===========================================================================
% init_trun_award(Lev) ->
%     #arena_cfg{trun_award = TrunAward} = load_arena_cfg:lookup_arena_cfg(Lev),
%     AwardState = do_init_trun_award(tuple_to_list(TrunAward), []),
%     TrunState = erlang:make_tuple(8, ?TRUE),
%     {AwardState, TrunState}.

% do_init_trun_award([], AwardStateL) -> lists:reverse(AwardStateL);
% do_init_trun_award([H | T], AwardStateL) ->
%     {ItemBid, ItemNum} = com_util:rand(H),
%     do_init_trun_award(T, [{ItemBid, ItemNum, ?FALSE} | AwardStateL]).

% count_star(StarNum, Tp) when is_tuple(Tp) ->
%     StarL = tuple_to_list(Tp),
%     count_star(StarNum, StarL);
% count_star(StarNum, []) ->
%     StarNum;
% count_star(StarNum, [H | T]) ->
%     NStarNum = case H of
%         ?FALSE -> StarNum + 1;
%         _ -> StarNum
%     end,
%     count_star(NStarNum, T).
