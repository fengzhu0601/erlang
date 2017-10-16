%%%-------------------------------------------------------------------
%%% @author zl
%%% @doc  主线副本
%%%
%%% @end
%%%-------------------------------------------------------------------

-module(main_instance_mng).



-include("inc.hrl").
-include("game.hrl").
-include("scene.hrl").
-include("player.hrl").
-include("item.hrl").
-include("load_item.hrl").
-include("item_new.hrl").
-include("player_mod.hrl").
-include("handle_client.hrl").
-include("main_ins_struct.hrl").
-include("main_ins_mng_reply.hrl").
-include("achievement.hrl").
-include("load_cfg_main_ins.hrl").
-include("load_phase_ac.hrl").
-include("day_reset.hrl").
-include("../abyss/abyss_struct.hrl").
-include("load_career_attr.hrl").
-include("system_log.hrl").
-include("../../../wk_open_server_happy/open_server_happy.hrl").

-export([
    get_today_play_times/1,
    ins_complete/3,
    ins_random_complete/3,
    ins_new_wizard/3,
    get_current_instance_doing/0,
    is_enough_jinxing/1,
    is_enough_yinxing/1,
    get_jin_and_yin_xing/0,
    flush_main_instance_rank/2,
    do_chapter_prize/2,
    get_first_nine_star_pass_prize_and_set_statue/3,
    test/3,
    test/4,
    get_challenge_times/1,
    add_challenge_times/1,
    push_challenge_info_by_id/1,
    get_max_challenge_times/1,
    leave_main_instance_clear_data/0,
    init_open_card_data/1,
    get_all_pass_room/0,
    sync_clean_room_list/0,
    get_exp_by_sp/0,
    get_gold_by_sp/0,
    get_open_card_item_list/0,
    get_clean_room_open_card_prize_by_times/2
]).

-define(pd_main_ins_challenge, pd_main_ins_challenge).
-define(RAND_COST_NUM, 1).
-define(SEVEN_PASS, 9).

get_open_card_item_list() ->
    List = attr_new:get(?main_open_card_prize_list, []),
    NewList =
    lists:foldl(fun({ItemList, _Q}, L) ->
        ItemList ++ L
    end,
    [],
    List),
    NewList.


init_open_card_data(SceneCfgId) ->
    put(?main_open_card_count, 0),
    put(?main_open_card_prize_list, load_cfg_main_ins:get_main_card_prize(SceneCfgId)).

leave_main_instance_clear_data() ->
    erase(?main_instance_id_ing),
    erase(?main_open_card_count),
    erase(?main_open_card_prize_list).

get_main_ins_challenge() ->
    get(?pd_main_ins_challenge).
%%    case get(?pd_main_ins_challenge) of
%%        0 -> gb_trees:empty();
%%        Tree -> Tree
%%    end.
%%

on_day_reset(_) ->
    Challenge = get_main_ins_challenge(),
    KeyList = gb_trees:keys(Challenge),
    lists:foreach(
        fun(Id) ->
            case gb_trees:lookup(Id, get_main_ins_challenge()) of
                ?none ->
                    ok;
                {?value, #main_ins_challenge{challenge_times = ChallengeTimes, max_challenge_times = MaxChallengeTimes}} ->
                    RemainChallengeTimes = erlang:max(0,MaxChallengeTimes - ChallengeTimes),
                    BaseChallengeTimes = load_cfg_main_ins:get_main_instance_battle_num(Id),
                    if
                        RemainChallengeTimes > BaseChallengeTimes ->
                            put(?pd_main_ins_challenge,
                                gb_trees:update(
                                    Id,
                                    #main_ins_challenge{
                                        id = Id,
                                        challenge_times = 0,
                                        buy_challenge_times = 0,
                                        max_challenge_times = RemainChallengeTimes
                                    },
                                    get_main_ins_challenge()
                                ));
                        true ->
                            put(?pd_main_ins_challenge,
                                gb_trees:update(
                                    Id,
                                    #main_ins_challenge{
                                        id = Id,
                                        challenge_times = 0,
                                        buy_challenge_times = 0,
                                        max_challenge_times = BaseChallengeTimes
                                    },
                                    get_main_ins_challenge()
                                ))
                    end
            end
        end,
        KeyList
    ),
    %% 推送挑战信息
    init_challenge_info(),
    ok.



get_jin_and_yin_xing() ->
    {get(?pd_main_ins_jinxing),
    get(?pd_main_ins_yinxing)}.

is_enough_jinxing(N) ->
    JinXing = get(?pd_main_ins_jinxing),
    if
        JinXing >= N ->
            put(?pd_main_ins_jinxing, JinXing -N),
            true;
        true ->
            false
    end.
is_enough_yinxing(N) ->
    YinXing = get(?pd_main_ins_yinxing),
    if
        YinXing >= N ->
            put(?pd_main_ins_yinxing, YinXing -N),
            true;
        true ->
            false
    end.


handle_client({Pack, Arg}) ->
    handle_client(Pack, Arg).

%% 扫荡
handle_client(?MSG_MAIN_INSTANCE_CLEAN, {Id, N}) ->
    %?DEBUG_LOG("Id-----:~p------------N-----:~p",[Id, N]),
    case gb_trees:lookup(Id, get(?pd_main_ins_mng)) of
        ?none ->
            ?player_send(player_sproto:pkg_msg(?MSG_PLAYER_ERROR, {?MSG_MAIN_INSTANCE_CLEAN, ?ERR_CLEAN_MAIN_INS_PASS, <<>>})),
            ?err({<<"can not find mian ins">>, Id});

        {?value, #main_ins{today_passed_times = T, star = AllStar} = S} ->
            VipLevel = attr_new:get_vip_lvl(),
            ChapterId = load_cfg_main_ins:get_main_ins_chapterid(Id),
            %% 扫荡特权，vip可以无视7星通关条件
            %case load_vip_right:can_clean_main_ins(VipLevel) of
            case load_vip_new:is_saodang_by_vip_level(VipLevel) of
                ?false ->
                    %?DEBUG_LOG("1----------------------------------"),
                    if
                    %% 7星通关
                        AllStar >= ?SEVEN_PASS ->
                            case main_ins_mod:can_get_prize_from_room(Id) of
                                ?true ->
                                    %?DEBUG_LOG("2-----------------------------"),
                                    daily_task_tgr:do_daily_task({?ev_main_ins_pass, Id}, 1),
                                    event_eng:post(?ev_nine_star_pass_ins, {?ev_nine_star_pass_ins, ChapterId}, 1),
                                    clean_room(Id, T, S, N);
                                _ ->
                                    %?DEBUG_LOG("3---------------------------------------"),
                                    ?return_err(?ERR_MAX_COUNT)
                            end;

                    %% 非7星通关
                        true ->
                            %?DEBUG_LOG("4---------------------------------------"),
                            ?player_send(player_sproto:pkg_msg(?MSG_PLAYER_ERROR, {?MSG_MAIN_INSTANCE_CLEAN, ?ERR_CLEAN_MAIN_INS_SEVEN_STAR_PASS, <<>>}))
                    end;

                ?true ->
                    case main_ins_mod:can_get_prize_from_room(Id) of
                        ?true ->
                            event_eng:post(?ev_nine_star_pass_ins, {?ev_nine_star_pass_ins, ChapterId}, 1),
                            clean_room(Id, T, S, N);
                        _ ->
                            ?return_err(?ERR_MAX_COUNT)
                    end
            end
    end;

%% 一键扫荡10次
handle_client(?MSG_MAIN_INSTANCE_CLEAN_TIMES, {Id, Times, N}) ->
    case gb_trees:lookup(Id, get(?pd_main_ins_mng)) of
        ?none ->
            ?player_send(player_sproto:pkg_msg(?MSG_PLAYER_ERROR, {?MSG_MAIN_INSTANCE_CLEAN, ?ERR_CLEAN_MAIN_INS_PASS, <<>>})),
            ?err({<<"can not find mian ins">>, Id});

        {?value, #main_ins{today_passed_times = T, star = AllStar} = S} ->
            VipLevel = attr_new:get_vip_lvl(),
            ChapterId = load_cfg_main_ins:get_main_ins_chapterid(Id),
            %% 扫荡特权，vip可以无视7星通关条件
            case load_vip_new:is_yijian_saodang_by_vip_level(VipLevel) of
                ?false ->
                    if
                    %% 7星通关
                        AllStar >= ?SEVEN_PASS ->
                            case main_ins_mod:can_clean_room_times(Id, Times) of
                                ?true ->
                                    daily_task_tgr:do_daily_task({?ev_main_ins_pass, Id}, 1),
                                    event_eng:post(?ev_nine_star_pass_ins, {?ev_nine_star_pass_ins, ChapterId}, 1),
                                    clean_room_times(Id, T, S, Times, N);
                                ?false ->
                                    ?return_err(?ERR_MAX_COUNT)
                            end;

                    %% 非7星通关
                        true ->
                            ?player_send(player_sproto:pkg_msg(?MSG_PLAYER_ERROR, {?MSG_MAIN_INSTANCE_CLEAN_TIMES, ?ERR_CLEAN_MAIN_INS_SEVEN_STAR_PASS, <<>>}))
                    end;

                ?true ->
                    case main_ins_mod:can_clean_room_times(Id, Times) of
                        ?true ->
                            event_eng:post(?ev_nine_star_pass_ins, {?ev_nine_star_pass_ins, ChapterId}, 1),
                            clean_room_times(Id, T, S, Times, N);
                        ?false ->
%%                            ?INFO_LOG("==============挑战次数不够==========="),
                            ?return_err(?ERR_MAX_COUNT)
                   end
           end
   end;

%% 联网副本
handle_client(?MSG_MAIN_INSTANCE_SINGLE_START, {Id}) ->
    ?INFO_LOG("联网副本"),
    main_ins_mod:fight_start(?MSG_MAIN_INSTANCE_SINGLE_START, Id);

%% 前端副本
handle_client(?MSG_MAIN_INSTANCE_CLIENT_START, {Id}) ->
    main_ins_mod:fight_start(?MSG_MAIN_INSTANCE_CLIENT_START, Id);

%% 组队副本
handle_client(?MSG_MAIN_INSTANCE_TEAM_CREATE, {ConfigId, IsAllMidwayJoin}) ->
    main_ins_team_mod:handle_create_room(ConfigId, IsAllMidwayJoin);

%% 开始副本
handle_client(?MSG_MAIN_INSTANCE_TEAM_START, {}) ->
    main_ins_team_mod:handle_start();

%% 快速加入,优先加入已经开始的
handle_client(?MSG_MAIN_INSTANCE_TEAM_QUICK_JOIN, {ConfigId}) ->
    main_ins_team_mod:handle_quick_join(ConfigId);

%%　主动离开队伍
handle_client(?MSG_MAIN_INSTANCE_TEAM_LEAVE, {}) ->
    main_ins_team_mod:handle_leave_team(get(?pd_id));

%% 踢出队友只能是等待的时候
handle_client(?MSG_MAIN_INSTANCE_TEAM_KICKOUT, {MemberId}) ->
    main_ins_team_mod:handle_kickout(MemberId);

%% 解散
handle_client(?MSG_MAIN_INSTANCE_TEAM_DISSOLVE, {}) ->
    main_ins_team_mod:handle_dissolve();

%% 进入下一个场景
handle_client(?MSG_MAIN_INSTANCE_ENTER_NEXT, {}) ->
    CurrentSceneId = get(?pd_scene_id),
    case load_cfg_scene:get_scene_type(CurrentSceneId) of
        ?SC_TYPE_MAIN_INS ->
            {_, _, FightType} = CurrentSceneId,
            case main_ins:get_scene_id(FightType) of
                ?none ->
                    ?ERROR_LOG("can not find next scene id ~p", [get(?pd_id)]);
                CurrentSceneId ->
                    ?ERROR_LOG("alreay in scene");
                SceneId ->
                    _R = scene_mng:enter_scene_request(SceneId)
            end;
        St ->
            ?ERROR_LOG("not main scene ~p", [St])
    end;

%% 进入随机副本
handle_client(?MSG_MAIN_INSTANCE_RAND_START, {ItemBid}) ->
    ?DEBUG_LOG("ItemBid-----------------------:~p", [ItemBid]),
    {TItemBid, CostNum} = misc_cfg:get_misc_cfg(sky_rand_cost),
    NCostNum = case ItemBid =:= TItemBid of
                   ?true -> CostNum;
                   _ -> ?RAND_COST_NUM
               end,
    Ret = case game_res:try_del([{ItemBid, NCostNum}], ?FLOW_REASON_ENTER_FUBEN) of
              ok ->
                  case load_item:lookup_item_attr_cfg(ItemBid) of
                      #item_attr_cfg{use_effect = [{ins_rand, PrizeId, InsId}]} when is_integer(InsId) ->
                          main_ins_mod:fight_start(?MSG_MAIN_INSTANCE_RAND_START, InsId, PrizeId);
                      #item_attr_cfg{use_effect = [{ins_rand, PrizeId, InsIdInfos}]} when is_list(InsIdInfos) ->
                          InsId = com_util:probo_random(InsIdInfos, 1000),
                          main_ins_mod:fight_start(?MSG_MAIN_INSTANCE_RAND_START, InsId, PrizeId);
                      _ -> {error, not_cfg}
                  end;
              _Other ->
                  {error, cost_not_enough}
          end,
    {ReplyNum, CliInsId} = case Ret of
                               {ok, Id} ->
                                   {?REPLY_MSG_MAIN_INSTANCE_RAND_START_OK, Id};
                               {error, Reason} ->
                                   ErrReplyNum = if
                                                     Reason =:= not_found_item ->
                                                         ?REPLY_MSG_MAIN_INSTANCE_RAND_START_1;
                                                     Reason =:= cost_not_enough ->
                                                         ?REPLY_MSG_MAIN_INSTANCE_RAND_START_2;
                                                     ?true ->
                                                         ?REPLY_MSG_MAIN_INSTANCE_RAND_START_255
                                                 end,
                                   {ErrReplyNum, 0}
                           end,
    ?player_send(main_instance_sproto:pkg_msg(?MSG_MAIN_INSTANCE_RAND_START, {ReplyNum, CliInsId}));


handle_client(?MSG_INSTANCE_ENTER_NEXT_LAYER, {TagSceneId, IsLastScene}) ->
    SceneType = case get(?pd_scene_id) of
        {SceneId, ?scene_main_ins, _} ->
            system_log:info_finish_room(SceneId, [{6, 0}, {2, 0}, {3, 0}]),
            ?scene_main_ins;
        {_, Type, _} ->
            Type;
        Id when is_integer(Id) ->
            room_system;
        W ->
            ?ERROR_LOG("unknown type:~p", [W]),
            ignore
    end,
    case get(?pd_scene_pid) of
        Pid when is_pid(Pid) ->
            Pid ! ?scene_mod_msg(SceneType, {start_next_scene_id, get(?pd_id), get(?pd_idx), self(), TagSceneId, IsLastScene});
        _ ->
            ok
    end;

handle_client(?MSG_MAIN_INSTANCE_RANK_INFO, {FubenId, Index, Count}) ->
    %?DEBUG_LOG("main instance rank info ----------:~p",[{FubenId, Index, Count}]),
    get_instance_rank_data(FubenId, Index, Count);

handle_client(?MSG_MAIN_INSTANCE_SHOP, {GoodsId, Count}) ->
    %?DEBUG_LOG("GoodsId , Count-------------:~p",[{GoodsId, Count}]),
    case load_cfg_main_ins:get_main_shop_price(GoodsId) of
        ?none ->
            %?DEBUG_LOG("is none----------------------"),
            ?return_err(?ERR_MAIN_SHOP_NOT_GOODS);
        Prize ->
            Coin = get(?player_main_ins_coin),
            NewCoin = Coin - Prize * Count,
            %?DEBUG_LOG("Coin---NewCOin------prize------------:~p",[{Coin, NewCoin, Prize}]),
            if
                NewCoin >= 0 ->
                    put(?player_main_ins_coin, NewCoin),
                    game_res:try_give_ex([{GoodsId, Count}], ?FLOW_REASON_FUBEN_SHOP),
                    system_log:info_star_shop_pay({Coin, NewCoin, Prize * Count, GoodsId, Count}),
                    ?player_send(main_instance_sproto:pkg_msg(?MSG_MAIN_INSTANCE_SHOP, {}));
                true ->
                    %?DEBUG_LOG("main shop false ----------------------------"),
                    ?return_err(?ERR_MAIN_INS_START_NOT_ENOUGH)
            end
    end;

handle_client(?MSG_MAIN_INSTANCE_CHAPTER_STAR_PRIZE, {ChapterId, Sub, Index}) ->
    get_prize_by_chapter({ChapterId, Sub}, Index, {get(?pd_id), ChapterId, Sub});

handle_client(?MSG_MAIN_INSTANCE_BUY_CHALLENGE_TIMES, {Id, Num}) ->
    Challenge = get_main_ins_challenge(),
    #main_ins_cfg{battle_num = BattleNum} = load_cfg_main_ins:lookup_main_ins_cfg(Id),
    %% 购买挑战次数对应vip表
    VipLevel = get(?pd_vip),
    CostList =
        case load_cfg_main_ins:get_ins_type_and_sub_type(Id) of
            {?T_INS_MAIN, 1} ->
                load_vip_new:get_reset_instance_times_of_normal_by_vip_level(VipLevel);
            {?T_INS_MAIN, 2} ->
                load_vip_new:get_reset_instance_times_of_difficulty_by_vip_level(VipLevel);
            {?T_INS_MAIN, 3} ->
                load_vip_new:get_reset_instance_times_of_many_people_by_vip_level(VipLevel);
            _ ->
                ?return_err(?ERR_BUY_CHALLENGE_NOT_MAIN_INS)
        end,
    BuyBattleUpnum = length(CostList),

    case gb_trees:lookup(Id, Challenge) of
        ?none ->
            %% 判断购买次数够不够
            if
                Num > BuyBattleUpnum ->
                    ?return_err(?ERR_BUY_CHALLENGE_NOT_ENOUGH);
                true ->
                    %% 判断钻石够不够
                    CostNum = get_battle_cost(0, Num, CostList),
                    case game_res:try_del([{?PL_DIAMOND, CostNum}], ?FLOW_REASON_BUY_FUBEN_TIMES) of
                        ok ->
                            put(?pd_main_ins_challenge,
                                gb_trees:insert(
                                    Id,
                                    #main_ins_challenge{
                                        id = Id,
                                        challenge_times = 0,                             %% 挑战次数
                                        buy_challenge_times = Num,                       %% 购买挑战次数
                                        max_challenge_times = BattleNum + Num   %% 最大可挑战次数
                                    },
                                    Challenge
                                )
                            ),
                            ?player_send(main_instance_sproto:pkg_msg(?MSG_MAIN_INSTANCE_BUY_CHALLENGE_TIMES, {Id, Num, BattleNum + Num}));
                        {error, _Other} ->
                            ?return_err(?ERR_COST_DIAMOND_FAIL)
                    end
            end;

        {?value, #main_ins_challenge{challenge_times = ChallengeTimes,
            buy_challenge_times = BuyChallengeTimes, max_challenge_times = MaxChallengeTimes}} ->
            %% 判断购买次数够不够
            if
                Num > BuyBattleUpnum - BuyChallengeTimes ->
                    ?return_err(?ERR_BUY_CHALLENGE_NOT_ENOUGH);
                true ->
                    %% 判断钻石够不够
                    CostNum = get_battle_cost(BuyChallengeTimes, Num, CostList),
                    case game_res:try_del([{?PL_DIAMOND, CostNum}], ?FLOW_REASON_BUY_FUBEN_TIMES) of
                        ok ->
                            NewMaxChallengeTimes = MaxChallengeTimes + Num,
                            RemainChallengeTimes = erlang:max(0,NewMaxChallengeTimes - ChallengeTimes),
                            put(?pd_main_ins_challenge,
                                gb_trees:update(
                                    Id,
                                    #main_ins_challenge{
                                        id = Id,
                                        challenge_times = ChallengeTimes,
                                        buy_challenge_times = BuyChallengeTimes + Num,
                                        max_challenge_times = NewMaxChallengeTimes
                                    },
                                    Challenge
                                )),
                            ?player_send(main_instance_sproto:pkg_msg(?MSG_MAIN_INSTANCE_BUY_CHALLENGE_TIMES, {Id, BuyChallengeTimes + Num, RemainChallengeTimes}));
                        {error, _Other} ->
                            ?return_err(?ERR_COST_DIAMOND_FAIL)
                    end
            end
    end;

handle_client(?MSG_MAIN_INSTANCE_OPEN_CARD, {}) ->
    List = misc_cfg:get_main_ins_open_card_cost(),
    Size = length(List),
    UseedCount = attr_new:get(?main_open_card_count, 0) + 1,
    if
        UseedCount > Size ->
            ?return_err(?ERR_MAX_COUNT);
        true ->
            CostNum = lists:nth(UseedCount, List),
            case game_res:can_del([{?PL_DIAMOND, CostNum}]) of
                ok ->
                    Id = get_current_instance_doing(),
                    OpenCardPrizeList = attr_new:get(?main_open_card_prize_list, load_cfg_main_ins:get_main_card_prize(Id)),
                    if
                        OpenCardPrizeList =:= [] ->
                            pass;
                        true ->
                            %?DEBUG_LOG("OpenCardPrizeList------------------:~p",[OpenCardPrizeList]),
                            game_res:del([{?PL_DIAMOND, CostNum}], ?FLOW_REASON_FUBEN_TURN_CARD),
                            %?DEBUG_LOG("id---------------------------------------:~p",[Id]),
                            [ItemList] = util:get_val_by_weight(OpenCardPrizeList, 1),
                            prize:send_prize_of_itemlist(ItemList, ?S_MAIL_MAIN_OPEN_CARD_PRIZE, ?FLOW_REASON_FUBEN_TURN_CARD),
                            put(?main_open_card_count, UseedCount),
                            put(?main_open_card_prize_list, lists:keydelete(ItemList, 1, OpenCardPrizeList)),
                            ?player_send(main_instance_sproto:pkg_msg(?MSG_MAIN_INSTANCE_OPEN_CARD, {ItemList}))
                    end;
                {error, _O} ->
                    ?return_err(?ERR_COST_DIAMOND_FAIL)
            end
    end;

handle_client(Mod, Msg) ->
    ?ERROR_LOG("no known msg Mod:~p Msg:~p", [Mod, Msg]).


get_clean_room_open_card_prize_by_times(Id, N) ->
    OpenCardPrizeList = load_cfg_main_ins:get_main_card_prize_pool(Id),
    PrizeIdList = util:get_val_by_weight(OpenCardPrizeList, N),
    PrizeList =
        lists:foldl(
            fun(PrizeId, Acc) ->
                {ok, PrizeList} = prize:get_prize(PrizeId),
                Acc ++ PrizeList
            end,
            [],
            PrizeIdList
        ),
    PrizeList.

get_clean_room_open_card_cost_by_times(N) ->
    List = misc_cfg:get_main_ins_open_card_cost(),
    CostNum = lists:sum(lists:sublist(List, N)),
    CostNum.

flush_main_instance_rank(FubenId, FenShu) ->
    PlayerId = get(?pd_id),
    NewData = [{PlayerId, FenShu}],
    {NewRankList, _OldNewRankList} =
    case dbcache:lookup(?player_main_ins_rank, FubenId) of
        [] ->
            %?DEBUG_LOG("is not data------------------------"),
            {NewData,NewData};
        [#main_ins_rank{rank_list = RankList}] ->
            Size = length(RankList),
            RankList2 = 
            if
                Size >= 100 ->
                    {P, D} = lists:nth(100, RankList),
                    if
                        FenShu > D ->
                            lists:keydelete(P, 1, RankList) ++ NewData;
                        true ->
                            RankList
                    end;
                true ->
                    case lists:keyfind(PlayerId, 1, RankList) of
                        ?false ->
                            RankList ++ NewData;
                        {_, OldFenshu} ->
                            lists:keyreplace(PlayerId, 1, RankList, {PlayerId, erlang:max(FenShu, OldFenshu)})
                    end
            end,
            %L = lists:keysort(2, RankList2),
            {RankList2, RankList}
    end,
    %?DEBUG_LOG("NewRankList------------------------:~p",[NewRankList]),
    main_instance_rank_server ! {add_m_ins_id, FubenId},
    
    {No1PlayerId, No1F} = lists:nth(1, NewRankList),
    if
        FenShu >= No1F ->
            dbcache:update(?player_main_ins_rank,
            #main_ins_rank{
                scene_id = FubenId,
                rank_list = NewData ++ lists:keydelete(PlayerId, 1, NewRankList)
            }), 
            {get_main_instance_rank_top1_data(PlayerId, FenShu), 1};
        true ->
            dbcache:update(?player_main_ins_rank,
            #main_ins_rank{
                scene_id = FubenId,
                rank_list = NewRankList
            }), 
            {get_main_instance_rank_top1_data(No1PlayerId, No1F), util:get_index_of_list(NewRankList, PlayerId)}
    end.

get_main_instance_rank_top1_data(PlayerId, FenShu) ->
    case player:lookup_info(PlayerId, [?pd_career, ?pd_name]) of
        [?none] ->
            {0, <<>>, 0};
        [Car, Name] ->
            {FenShu, Name, Car}
    end.


get_instance_rank_data(FubenId, Index, Count) ->
    case dbcache:lookup(?player_main_ins_rank, FubenId) of
        [] ->
            %?DEBUG_LOG("is not data 2------------------------"),
            ?player_send(main_instance_sproto:pkg_msg(?MSG_MAIN_INSTANCE_RANK_INFO, {<<>>}));
        [#main_ins_rank{rank_list = RankList}] ->
            % L = lists:keysort(2, RankList),
            % L2 = lists:reverse(L),
            % L3 = lists:sublist(L2, Index, Index + Count),
            % NewBin =
            % lists:foldl(fun({PlayerId, FenShu}, Bin) ->
            %     case player:lookup_info(PlayerId, [?pd_name, ?pd_level, ?pd_career, ?pd_combat_power]) of
            %         ?none ->
            %             Bin;
            %         [Name, Level, Career, Combat] ->
            %             <<Bin/binary, PlayerId:64, (byte_size(Name)), Name/binary, Level, Career, Combat:32, FenShu:16>>
            %     end
            % end,
            % <<(length(L3))>>,
            % L3),
            % ?player_send(main_instance_sproto:pkg_msg(?MSG_MAIN_INSTANCE_RANK_INFO, {NewBin})),
            % dbcache:update(?player_main_ins_rank,
            %     #main_ins_rank{
            %     scene_id = FubenId,
            %     rank_list = L2
            % })
            L3 = lists:sublist(RankList, Index, Index + Count),
            NewBin =
            lists:foldl(fun({PlayerId, FenShu}, Bin) ->
                case player:lookup_info(PlayerId, [?pd_name, ?pd_level, ?pd_career, ?pd_combat_power]) of
                    ?none ->
                        Bin;
                    [Name, Level, Career, Combat] ->
                        <<Bin/binary, PlayerId:64, (byte_size(Name)), Name/binary, Level, Career, Combat:32, FenShu:16>>
                end
            end,
            <<(length(L3))>>,
            L3),
            ?player_send(main_instance_sproto:pkg_msg(?MSG_MAIN_INSTANCE_RANK_INFO, {NewBin}))
    end.




client_complete(_DieCount, _KillMinMonsterCount, _KillBossMonsterCount, PassTime, #main_ins_cfg{id = _Id, ins_id = InsId, sub_type = _Difficulty}, ItemUsePrizeId, PassPrizeId) ->
    %% @doc 道具使用奖励
    {ok, ItemTps} = prize:get_prize(ItemUsePrizeId),
    mail_mng:send_sysmail(get(?pd_id), ?S_MAIL_RAND_INSTANCE, ItemTps),

    %% 结算奖励
    attr_new:begin_room_prize(PassPrizeId),
    PrizeInfo = prize:prize_mail(PassPrizeId, ?S_MAIL_INSTANCE, ?FLOW_REASON_FUBEN_COMPLETE),
    attr_new:end_room_prize(InsId),

%%    ?INFO_LOG("===================== 结算奖励 ~p", [{InsId, PassTime, PrizeInfo}]),


    ?player_send(main_instance_sproto:pkg_msg(?MSG_MAIN_INSTANCE_COMPLETE,
        {InsId, PassTime, 0, 0, 0,0, 0,
            0,
            <<>>,
            0,
            0,
            0,
            PrizeInfo,
            [],
            [],
            [],
            [],
            [],
            []})),
    ok.

complete_instance(_DieCount, _KillMinMonsterCount, _KillBossMonsterCount, PassTime, ReliveNum,
        #main_ins_cfg{id = Id, ins_id = InsId, chapter_id = ChapterId, sub_type = Difficulty, stars= Stars}, Prize, MaxDoubleHit, ShoujiCount, AllStarList, TotalFenShu) ->
    ?DEBUG_LOG("Id-----InsId----ReliveNum:~p",[{Id, InsId, ReliveNum}]),
    %% Inc passed times
    AllStar = main_ins:get_total_star(AllStarList),
    MainMng = get(?pd_main_ins_mng),
    {F, Coin, TaskStarCount} =
        case gb_trees:lookup(Id, MainMng) of
            ?none -> %% first passed
                %?DEBUG_LOG("first pass main instance -----------------------"),
                put(?pd_main_ins_mng,
                    gb_trees:insert(
                        Id,
                        #main_ins{
                            id = Id,
                            pass_time = PassTime,
                            lianjicount = MaxDoubleHit,
                            shoujicount = ShoujiCount,
                            relivenum = ReliveNum,
                            star = AllStar,
                            fenshu = TotalFenShu,
                            today_passed_times = 1
                        },
                        MainMng
                    )),
                {TotalFenShu, AllStar, AllStar};
            {?value, #main_ins{pass_time = OldPassTime, lianjicount = LianjiCount, shoujicount = OldShoujiCount, relivenum = OldReliveNum, star = Star,
                fenshu = FenShu, first_nine_star_pass = Fnsp, today_passed_times = Today}} ->
                %?DEBUG_LOG("update main instance info ------------------------"),
                NewFenshu = erlang:max(FenShu, TotalFenShu),
                Pt = erlang:min(OldPassTime, PassTime),
                Lj = erlang:max(LianjiCount, MaxDoubleHit),
                Sj = erlang:min(OldShoujiCount, ShoujiCount),
                Rn = erlang:max(OldReliveNum, ReliveNum),
                AllStar2 = achievement_mng:get_total_star(Lj, Sj, Pt, Rn, Stars),
                FinalAllStar = lists:max([AllStar, AllStar2, Star]),
                put(?pd_main_ins_mng,
                    gb_trees:update(Id, #main_ins{
                        id = Id,
                        pass_time = Pt,
                        lianjicount = Lj,
                        shoujicount = Sj,
                        relivenum = Rn,
                        star = FinalAllStar,
                        fenshu = NewFenshu,
                        first_nine_star_pass = Fnsp,
                        today_passed_times = Today + 1
                    },
                        MainMng)),
                {NewFenshu, erlang:max(0, AllStar - Star), FinalAllStar}
        end,
    if
        TaskStarCount =:= 9  ->
            event_eng:post(?ev_nine_star_pass_ins, {?ev_nine_star_pass_ins, ChapterId}, 1);
        true ->
            pass
    end,
    if
        ChapterId =:= 1 -> %% is achievement need when chapterid==1
            achievement_mng:do_ac2(?xingjidaren, 0, Coin);
        true ->
            pass
    end,
    bounty_mng:pass_room_star(AllStar),
    {{No1F, No1Name, No1Job}, SelfRank} = flush_main_instance_rank(Id, F),
    %{No1F, No1Name, No1Job} = title_service:get_instance_rank_top1_data(Id),
    %?DEBUG_LOG("SelfRank----:------------~p",[SelfRank]),
    %?DEBUG_LOG("No1F-------:~p----No1Name----:~p------No1Job------:~p",[No1F, No1Name, No1Job]),
    NewCoin = get(?player_main_ins_coin) + Coin,
    do_chapter_prize({get(?pd_id), ChapterId, Difficulty}, Coin),
    put(?player_main_ins_coin, NewCoin),
    event_eng:post(?ev_main_ins_pass, {Id, InsId, Difficulty}),
    daily_task_tgr:do_daily_task({?ev_main_ins_pass, Id}, 1),
    open_server_happy_mng:sync_task(?IS_CROSS_FUBEN, Id),
    open_server_happy_mng:sync_task(?CROSS_FUBEN_GET_STAR_COUNT, Id, AllStar),

%%    ?INFO_LOG("can_get_prize_from_room:~p",[main_ins_mod:is_can_get_prize_from_room()]),
    %%离开副本时，如果玩家打的是无体力副本，就不发放副本结算奖励
    {CanGetPrize, FinalPrizeInfo, FinalLianJiPrize, FinalShouJiPrize, FinalPassTimePrize, FinalRelivePrize} =
    case main_ins_mod:is_can_get_prize_from_room() of
        ?true ->
            Exp = get_exp_by_sp(),
            Gold = get_gold_by_sp(),
            %% ?DEBUG_LOG("Exp:~p, Gold:~p", [Exp, Gold]),
            %CanGetPrize = 1,
            %% 副本通关奖励
            attr_new:begin_room_prize(Prize),
            {ok, ItemTpL} = prize:get_prize(Prize),
            PrizeList = item_goods:merge_goods(ItemTpL ++ [{?PL_EXP, Exp}] ++ [{?PL_MONEY, Gold}]),
            PrizeInfo1 = prize:double_items(1000, PrizeList),
            game_res:try_give_ex(PrizeInfo1, ?S_MAIL_INSTANCE, ?FLOW_REASON_FUBEN_COMPLETE),
            %PrizeInfo1 = prize:prize_mail(Prize, ?S_MAIL_INSTANCE, ?FLOW_REASON_FUBEN_COMPLETE),
%%            PrizeInfo1 = prize:prize_mail_2(1000, Prize, ?S_MAIL_INSTANCE, ?FLOW_REASON_FUBEN_COMPLETE), %% dsl
            pet_new_mng:add_pet_new_exp_if_fight(PrizeInfo1),
            %?DEBUG_LOG("PrizeInfo1-------------------:~p",[PrizeInfo1]),
            attr_new:end_room_prize(InsId),

            %% 副本星级奖励
            LianJIPrize1 = main_ins:send_main_ins_star_level_rewards(1000, Id, AllStarList, ?lianji),
            ShouJiPrize1 = main_ins:send_main_ins_star_level_rewards(1000, Id, AllStarList, ?shouji),
            PassTimePrize1 = main_ins:send_main_ins_star_level_rewards(1000, Id, AllStarList, ?passtime),
            RelivePrize1 = main_ins:send_main_ins_star_level_rewards(1000, Id, AllStarList, ?add_xue),

            YinXingCount = get_yinxing_count(ShouJiPrize1 ++ PassTimePrize1 ++ RelivePrize1),
            bounty_mng:count_get_yinxing(YinXingCount),

            {1, PrizeInfo1, LianJIPrize1, ShouJiPrize1, PassTimePrize1, RelivePrize1};
            %?DEBUG_LOG("LianJIPrize:~p, ShouJiPrize:~p, PassTimePrize:~p", [LianJIPrize, ShouJiPrize, PassTimePrize]);
        ?false ->
            %CanGetPrize = 0,
            attr_new:begin_room_prize(Prize),
            %PrizeInfo = [],
            attr_new:end_room_prize(InsId),
            %LianJIPrize = [],
            %ShouJiPrize = [],
            %PassTimePrize = [],
            {0, [], [], [], [], []}
    end,
    FirstStarPrizeInfo = get_first_nine_star_pass_prize_and_set_statue(Id, AllStar, ChapterId),
    %% ?DEBUG_LOG("FinalPrizeInfo:~p", [FinalPrizeInfo]),
    %?DEBUG_LOG("FirstStarPrizeInfo----------------------:~p",[FirstStarPrizeInfo]),
    %?DEBUG_LOG("f----------------------------------------------------------:~p",[F]),
    ?player_send(main_instance_sproto:pkg_msg(?MSG_MAIN_INSTANCE_COMPLETE,
        {Id, PassTime, MaxDoubleHit, ShoujiCount, ReliveNum, F, NewCoin,
            No1F,
            No1Name,
            No1Job, 
            SelfRank,
            CanGetPrize,
            FinalPrizeInfo,
            FirstStarPrizeInfo,
            FinalLianJiPrize,
            FinalShouJiPrize,
            FinalPassTimePrize,
            FinalRelivePrize,
            get_open_card_item_list()})),

    scene_mng:load_leave_scene_progress(get(?pd_scene_id)),

    sync_clean_room_list(),

    %% @doc 战斗结束，出战宠物增加默契度
    system_log:info_exit_copy(InsId),
    try pet_mng:main_instacne_complete() of
        _ -> ok
    catch
        _Catch:_Why -> ok
    end.

%% 主线副本
ins_complete(?ins_complete, {MainInsCFG, _KillMonster, _WaveNum, DieCount, KillMinMonsterCount, KillBossMonsterCount,
    PassTime, ReliveNum, PassPrizeId, MaxDoubleHit, ShoujiCount, AllStar, TotalFenShu, _MonsterBidList}, _CallArg) ->
    achievement_mng:do_ac(?fubengaoshou),
    complete_instance(DieCount, KillMinMonsterCount, KillBossMonsterCount,
        PassTime, ReliveNum, MainInsCFG, PassPrizeId, MaxDoubleHit, ShoujiCount, AllStar, TotalFenShu);
%% 副本中途退出
ins_complete(_InsState, {MainInsCFG, _KillMonster, _WaveNum, _DieCount, _KillMinMonsterCount, _KillBossMonsterCount,
    _PassTime, _ReliveNum, _PassPrizeId, _MaxDoubleHit, _ShoujiCount, _AllStar, _TotalFenShu, _MonsterBidList}, _CallArg) ->
    %?DEBUG_LOG("ins_complete--------------------------------------------------------2"),
    achievement_mng:do_ac(?wuweiqiangze),
    InsId = MainInsCFG#main_ins_cfg.ins_id,
    system_log:info_exit_copy(InsId),
    %leave_main_instance_clear_data(),
    %accomplishments_mng:ins_fail_reset_acc(),
    ok.

%% 天空之城-随机副本
ins_random_complete(?ins_complete, {MainInsCFG, _KillMonster, _WaveNum, DieCount, KillMinMonsterCount, KillBossMonsterCount, PassTime,
    _ReliveNum, PassPrizeId, _MaxDoubleHit, _ShoujiCount, _MonsterBidList}, {ItemUsePrizeId}) ->
    %?DEBUG_LOG("ins ins_random_complete -----------------------------------------"),
    InsId = MainInsCFG#main_ins_cfg.ins_id,
    system_log:info_finish_room(InsId, [{6, 0}, {2, 0}, {3, 0}]),
    client_complete(DieCount, KillMinMonsterCount, KillBossMonsterCount, PassTime, MainInsCFG, ItemUsePrizeId, PassPrizeId);
ins_random_complete(A, B, C) ->
    ?DEBUG_LOG("A--------------------------:~p", [A]),
    ?DEBUG_LOG("B--------------------------:~p", [B]),
    ?DEBUG_LOG("C--------------------------:~p", [C]),
    ok.

ins_new_wizard(?ins_complete, {_MainInsCFG, _KillMonster, _WaveNum, _DieCount, _KillMinMonsterCount, _KillBossMonsterCount, _PassTime, _ReliveNum, _PassPrizeId, _, _, _, _, _}, _CallArg) ->
    system_log:info_finish_room(0, [{6, 0}, {2, 0}, {3, 0}]),
    % attr_new:begin_room_prize(PassPrizeId),
    % PrizeInfo = prize:prize_mail(PassPrizeId, ?S_MAIL_INSTANCE),
    % attr_new:end_room_prize(0),
    % ?INFO_LOG("============================ PrizeInfo ~p", [PrizeInfo]),
    skill_mng:reset_dress_skill();
    % ?player_send(main_instance_sproto:pkg_msg(?MSG_MAIN_INSTANCE_COMPLETE, {MainInsCFG#main_ins_cfg.id, PassTime, 0, 0, 0, 0, 0, <<>>, 0, PrizeInfo, [], [], [], []}));

ins_new_wizard(_InsState, _, _CallArg) ->
    %?DEBUG_LOG("ins_new_wizard----------------------------------------------2"),
    skill_mng:reset_dress_skill(),
    ok.


get_first_nine_star_pass_prize_and_set_statue(Id, AllStar, _ChapterId) ->
    %?DEBUG_LOG("Id----------:~p-----AllStar----:~p",[Id, AllStar]),
    MainMng = get(?pd_main_ins_mng),
    StartPrize = main_ins:get_frist_starprize(Id),
    %?DEBUG_LOG("StartPrize-----------------------:~p",[StartPrize]),
    case gb_trees:lookup(Id, MainMng) of
        {?value, #main_ins{first_nine_star_pass = 1}} ->
            %?DEBUG_LOG("1----------------------------------"),
            [];
        {?value, MainInsData} ->
            %?DEBUG_LOG("MainInsData----------------------:~p",[MainInsData]),
            if
                AllStar =:= 9 ->
                    NewMainInsData = MainInsData#main_ins{first_nine_star_pass = 1},
                    %?DEBUG_LOG("NewMainInsData----------------------:~p",[NewMainInsData]),
                    B = gb_trees:update(Id, NewMainInsData, MainMng),
                    put(?pd_main_ins_mng, B),
                    %put(?pd_main_ins_jinxing, get(?pd_main_ins_jinxing) + 9),
                    In = prize:prize_mail(StartPrize, ?S_MAIL_FIRST_NINE_STAR_PASS_PRIZE, ?FLOW_REASON_NINE_STAR_PRIZE),
                    % ?DEBUG_LOG("In-----------------------:~p",[In]),
                    In;
                true ->
                    []
            end
    end.


get_current_instance_doing() ->
    case get(?main_instance_id_ing) of
        ?undefined ->
            case get(?already_in_abyss) of
                ?false ->
                    erase(?current_pata_instance_id);
                _ ->
                    get(?current_pata_instance_id)
            end;
        Id ->
            Id
    end.

%% 完成副本,玩家进程回调函数
handle_msg(_, {InsAction, FightStart, KillMonster, WaveNum, MaxDoubleHit, DieCount, KillMinMonsterCount, KillBossMonsterCount, _SceneId, PassTime, ReliveNum, ShoujiCount, AbyssPercent, AbyssScore, MonsterBidList}) ->
    Id = get_current_instance_doing(),
    SID = load_cfg_scene:get_config_id(get(?pd_scene_id)),
    % ?DEBUG_LOG("END Id-----------------:~p", [SID]),
    {PassPrizeId, MainInsCFG} = main_ins:get_pass_prize(Id),
    % ?DEBUG_LOG("PassPrizeId:~p", [PassPrizeId]),
    attenuation:self_add(),         %% 每次离开副本后增加进入副本次数
    case InsAction of
        team_complete ->
            room_system:fuben_complete(PassTime, MainInsCFG, PassPrizeId, MaxDoubleHit, ShoujiCount, 0, 0);
        % complete_instance(DieCount, KillMinMonsterCount, KillBossMonsterCount,
        %                    PassTime, MainInsCFG, PassPrizeId, MaxDoubleHit, ShoujiCount, 0, 0);
        ins_complete ->
            case FightStart of
                #fight_start{fight_state = State, call_back = {main_instance_mng, ins_complete, Arg}} ->
                    achievement_mng:do_ac2(?lianjidashi, 0, MaxDoubleHit),
                    achievement_mng:do_ac2(?lianjigaoshou, {MainInsCFG#main_ins_cfg.id, MainInsCFG#main_ins_cfg.sub_type}, MaxDoubleHit),
                    {AllStar, TotalFenShu} =
                        case State of
                            ?ins_complete ->
                                FubenId = FightStart#fight_start.scene_id,
                                %?DEBUG_LOG("FubenId-----------------------:~p",[FubenId]),
                                B = load_cfg_scene:get_config_id(get(?pd_scene_id)),
                                % ?DEBUG_LOG("B-----------------------:~p",[B]),
                                #main_ins_cfg{chapter_id = ChapterId} = MainInsCFG,
                                {StarList, FenShu} = achievement_mng:complete_instance_ac({FubenId, ChapterId, KillMinMonsterCount, KillBossMonsterCount, PassTime, ReliveNum, MaxDoubleHit, ShoujiCount, DieCount}),
                                system_log:info_finish_room(B, StarList),
                                {StarList, FenShu};
                            _ ->
                                {0, 0}
                        end,
                    NChapterId = MainInsCFG#main_ins_cfg.sub_type,
                    %?DEBUG_LOG("--------------DIFFERENT ID:~p -----", [NChapterId]),
                    case NChapterId of
                        1 -> phase_achievement_mng:do_pc(?PHASE_AC_INSTANCE_CHAPER_1, SID, 1);
                        2 -> phase_achievement_mng:do_pc(?PHASE_AC_INSTANCE_CHAPER_2, SID, 1);
                        3 -> phase_achievement_mng:do_pc(?PHASE_AC_INSTANCE_CHAPER_3, SID, 1);
                        _ -> ok
                    end,

                    ins_complete(State,
                        {MainInsCFG, KillMonster, WaveNum, DieCount, KillMinMonsterCount,
                            KillBossMonsterCount, PassTime, ReliveNum, PassPrizeId, MaxDoubleHit, ShoujiCount,
                            AllStar, TotalFenShu, MonsterBidList},
                        Arg);
                #fight_start{fight_state = State, call_back = {Module, Fun, Arg}} ->
                    Module:Fun(State,
                        {MainInsCFG, KillMonster, WaveNum, DieCount, KillMinMonsterCount,
                            KillBossMonsterCount, PassPrizeId, MaxDoubleHit, ShoujiCount,
                            PassTime, ReliveNum, AbyssPercent, AbyssScore, MonsterBidList},
                        Arg);
                _ ->
                    ok
            end
    end;


%% 发放场景掉落
handle_msg(_, {client_scene_drop, DropTps}) ->
    case DropTps =/= [] of
        ?true ->
            lists:map(
                fun({Item, _ItemNum}) when is_record(Item, item_new) ->
                    game_res:set_res_reasion(<<"场景掉落">>),
                    game_res:try_give_ex([{Item}], ?S_MAIL_INSTANCE, ?FLOW_REASON_FUBEN_DROP);
                    ({Item, ItemNum}) ->
                        game_res:try_give_ex([{Item, ItemNum}], ?S_MAIL_INSTANCE, ?FLOW_REASON_FUBEN_DROP)
                end,
                DropTps);
        _ -> ignore
    end;

handle_msg(_, {start_next_scene, NextMakeScene}) ->
    %?INFO_LOG("NextMakeScene-=--------------------------:~p", [NextMakeScene]),
    case scene_mng:enter_scene_request(NextMakeScene) of
        approved ->
            {SceneId, SceneType, _} = NextMakeScene,
            case SceneType of
                ?scene_main_ins ->
                    system_log:info_enter_copy(get(?pd_id), SceneId);
                _ ->
                    ignore
            end,
            {ok, NextMakeScene};
        E ->
            ?ERROR_LOG("enter_ins error: ~p ~p", [NextMakeScene, E]),
            error
    end;

handle_msg(_, {player_enter_scene, ins_new_wizard}) ->
    erlang:put(?player_is_on_new_wizard, true),
    api:newbie_equip_open();

handle_msg(_, leave_scene) ->
    main_ins_team_mod:handle_leave_team();
handle_msg(_, {player_leave_scene, ins_new_wizard}) ->
    erlang:put(?player_is_on_new_wizard, false),
    api:newbie_equip_close();
handle_msg(_, {player_leave_scene, {main_instance_mng, _LeaveSceneId}}) ->
    main_ins_util:leave_main_instance();

handle_msg(_FromMod, {team_start, Args}) ->
    main_ins_team_mod:team_start(Args);

handle_msg(_FromMod, {test_clean, Id, N}) ->
    handle_client(?MSG_MAIN_INSTANCE_CLEAN, {Id, N});

handle_msg(_FromMod, {test_clean, Id, Times, N}) ->
    handle_client(?MSG_MAIN_INSTANCE_CLEAN_TIMES, {Id, Times, N});

handle_msg(FromMod, Msg) ->
    ?ERROR_LOG("~p recv a unknown msg ~p from ~p", [?pname(), Msg, FromMod]).

get_today_play_times(Id) ->
    case gb_trees:lookup(Id, get(?pd_main_ins_mng)) of
        ?none ->
            0;
        {?value, #main_ins{today_passed_times = Times}} ->
            Times
    end.



create_mod_data(SelfId) ->
    case dbcache:insert_new(?player_main_ins_tab, #player_main_ins_tab{id = SelfId, mng = new()}) of
        true ->
            create_chapter_prize(SelfId),
            ok;
        false ->
            ?ERROR_LOG("create ~p module ~p data is already_exist", [SelfId, ?MODULE])
    end,

    create_challenge_data(SelfId).

create_challenge_data(SelfId) ->
    dbcache:insert_new(?player_main_ins_challenge_tab,
        #player_main_ins_challenge_tab{id = SelfId, challenge_tree = gb_trees:empty()}).

load_challenge_data(PlayerId) ->
    case dbcache:load_data(?player_main_ins_challenge_tab, PlayerId) of
        [] ->
            create_challenge_data(PlayerId),
            load_challenge_data(PlayerId);
        [#player_main_ins_challenge_tab{challenge_tree = Challenge}] ->
            case Challenge of
                0 ->
                    ?pd_new(?pd_main_ins_challenge, gb_trees:empty());
                _ ->
                    ?pd_new(?pd_main_ins_challenge, Challenge)
            end
    end,
    ok.


load_mod_data(PlayerId) ->
    case dbcache:load_data(?player_main_ins_tab, PlayerId) of
        [] ->
            create_mod_data(PlayerId),
            load_mod_data(PlayerId);
        [#player_main_ins_tab{mng = Mng, star_coin = StarCoin}] ->
            put(?pd_main_ins_mng, Mng),
            put(?player_main_ins_coin, StarCoin)
            %?pd_new(?pd_main_ins_jinxing, JinXing, 0),
            %?pd_new(?pd_main_ins_yinxing, YinXing, 0)
    end,
    case dbcache:load_data(?main_chapter_prize_status, PlayerId) of
        [] ->
            create_chapter_prize(PlayerId),
            load_mod_data(PlayerId);
        [#main_chapter_prize_status{isget_list = List}] ->
            put(?pd_main_chapter_prize_statue_list, List)
    end,
    load_challenge_data(PlayerId),
    ok.


init_client() ->
    Mng = get(?pd_main_ins_mng),
    %?DEBUG_LOG("player_main_ins_coin-------------:~p",[get(?player_main_ins_coin)]),
    % {main_ins,10011,55,20,0,9,990,6}
    {Bin, _C} =
        com_util:gb_trees_fold(fun(Id, MainIns, {Acc, AllStar}) ->
            case MainIns of
                #main_ins{pass_time = PassTime, lianjicount = LianjiCount, shoujicount = ShoujiCount,
                    relivenum = ReliveNum,
                    fenshu = FenShu, star = Star} ->
                    {<<Acc/binary, Id:16, PassTime:32, LianjiCount:16, ShoujiCount:16, ReliveNum:16, FenShu:16>>, AllStar + Star};
                %{main_ins, A, B, C, D, E, F, G} ->
                %    NMng = get(?pd_main_ins_mng),
                %    put(?pd_main_ins_mng,
                %        gb_trees:update(
                %            Id,
                %            #main_ins{id = A,
                %                pass_time = B, %% sec
                %                lianjicount = C,
                %                shoujicount = D,
                %                star = E,
                %                fenshu = F,
                %                first_nine_star_pass = 0,
                %                today_passed_times = G},
                %            NMng
                %        )),
                %    {<<Acc/binary, Id:16, B:32, C:16, D:16, F:16>>, AllStar + E};
                _ ->
                    {Acc, AllStar}
            end
        %?DEBUG_LOG("main info-------------:~p",[{Id, PassTime, LianjiCount, ShoujiCount, FenShu, AllStar, Star}]),
                               end,
            {<<>>, 0},
            Mng),
    ChapterPrizeBin = pack_chapter_prize(),
    NewBin = <<(get(?player_main_ins_coin)):16, ChapterPrizeBin/binary, Bin/binary>>,
    %NewBin = <<(get(?player_main_ins_coin)):16, Bin/binary>>,
    ?player_send(main_instance_sproto:pkg_msg(?MSG_MAIN_INSTANCE_INFO, {NewBin})),

    %% 登陆时推送玩家副本挑战信息
    init_challenge_info(),

    ok.

view_data(Acc) -> Acc.

online() -> nonused.

offline(PlayerId) ->
    main_ins:del_main_ins_data({?maining_instance_lianji_count, PlayerId}),
    main_ins:del_main_ins_data({?maining_instance_shouji_count, PlayerId}),
    main_ins_team_mod:leave_team_if_wait(PlayerId),
    ok.

handle_frame(_) -> ok.

save_data(PlayerId) ->
    dbcache:update(?player_main_ins_tab,
        #player_main_ins_tab{
            id = PlayerId,
            star_coin = get(?player_main_ins_coin),
            %jinxing = get(?pd_main_ins_jinxing),
            %yinxing = get(?pd_main_ins_yinxing),
            mng = get(?pd_main_ins_mng)
        }),
    dbcache:update(?main_chapter_prize_status,
        #main_chapter_prize_status{
            id = PlayerId,
            isget_list = get(?pd_main_chapter_prize_statue_list)
        }),

    dbcache:update(?player_main_ins_challenge_tab,
        #player_main_ins_challenge_tab{
            id = PlayerId,
            challenge_tree = get_main_ins_challenge()
        }).


new() ->
    gb_trees:empty().

% pake(Mng) ->
%     com_util:gb_trees_fold(fun(_, #main_ins{id=Id, pass_time=PassTime, today_passed_times=Times}, Acc) ->
%                                    <<Acc/binary, Id:16, PassTime:32, Times>>
%                            end,
%                            <<>>,
%                            Mng).
pack_chapter_prize() ->
    L = get(?pd_main_chapter_prize_statue_list),
    if
        L =:= ?undefined; L =:= [] ->
            <<0>>;
        true ->
            lists:foldl(fun({{ChapterId, Sub}, Statue}, Acc) ->
                IsGetBin = pack_is_get(tuple_to_list(Statue)),
                <<Acc/binary, ChapterId:8, Sub:8, IsGetBin/binary>>
                        end,
                <<(length(L)):8>>,
                L)
    end.
pack_is_get(IsGetList) ->
    lists:foldl(fun(Statue, Acc) ->
        <<Acc/binary, Statue:8>>
                end,
        <<(length(IsGetList)):8>>,
        IsGetList).

-define(CITY_LIST, lists:seq(1, 10)).
-define(GOAL_VALUE, {18, 36, 54}).

-define(IS_GET, {0, 0, 0}).
init_main_chapter(PlayerId) ->
    lists:foldl(fun({Key, AcCfg}, {Data, IsGetList}) ->
        % ?DEBUG_LOG("AcCfg------------------:~p",[Key]),
        case is_integer(Key) of
            ?true ->
                ChapterId = AcCfg#main_ins_cfg.chapter_id,
                SubType = AcCfg#main_ins_cfg.sub_type,
                Id = {PlayerId, ChapterId, SubType},
                Id2 = {ChapterId, SubType},
                %?DEBUG_LOG("Id--------------------:~p",[Id]),
                case lists:member(ChapterId, ?CITY_LIST) of
                    ?false ->
                        {Data, IsGetList};
                    _ ->
                        case lists:keyfind(Id, 1, Data) of
                            ?false ->
                                {[{Id, [Key]} | Data], [{Id2, ?IS_GET} | IsGetList]};
                            {_, List} ->
                                NewTuple =
                                    case lists:keyfind(Key, 1, List) of
                                        ?false ->
                                            {Id, [Key | List]};
                                        _ ->
                                            {Id, List}
                                    end,
                                {lists:keyreplace(Id, 1, Data, NewTuple), IsGetList}
                        end
                end;
            ?false ->
                {Data, IsGetList}
        end
                end,
        {[], []},
        ets:tab2list(main_ins_cfg)).

create_chapter_prize(PlayerId) ->
    {List, ChapterIdPrizeStatue} = init_main_chapter(PlayerId),
    %?DEBUG_LOG("ChapterIdPrizeStatue------------------------:~p",[ChapterIdPrizeStatue]),
    case dbcache:insert_new(?main_chapter_prize_status, #main_chapter_prize_status{id = PlayerId, isget_list = ChapterIdPrizeStatue}) of
        true ->
            %?DEBUG_LOG("is ok ------------------------------------"), 
            ok;
        false ->
            ?ERROR_LOG("create ~p module ~p data is already_exist", [PlayerId, ?MODULE])
    end,
    %?DEBUG_LOG("List-------------------:~p",[List]),
    do_create_chapter_prize(List).

do_create_chapter_prize([]) ->
    pass;
do_create_chapter_prize([{Id, _L} | End]) ->
    case dbcache:insert_new(?main_chapter_prize, #main_chapter_prize{id = Id, goal_value = ?GOAL_VALUE}) of
        true ->
            %?DEBUG_LOG("is ok ------------------------------------"), 
            ok;
        false ->
            ?ERROR_LOG("create ~p module ~p data is already_exist", [Id, ?MODULE])
    end,
    do_create_chapter_prize(End).

do_chapter_prize(Id, Count) ->
    case dbcache:lookup(?main_chapter_prize, Id) of
        [] ->
            pass;
        [#main_chapter_prize{goal_value = GoalValue, current_value = CurrentValue, is_get = IsGet}] ->
            NewCurrent = CurrentValue + Count,
            Num = do_prize_by_goal(NewCurrent, tuple_to_list(GoalValue), 0),
            NewIsget = update_is_get_by_num(Num, IsGet),
            %?DEBUG_LOG("Id--------------:~p--------Count-------:~p",[Id, Count]),
            %?DEBUG_LOG("IsGet--------:~p-------NewIsget--------:~p",[IsGet, NewIsget]),
            dbcache:update(?main_chapter_prize,
                #main_chapter_prize{
                    id = Id,
                    current_value = NewCurrent,
                    is_get = NewIsget
                }),
            update_is_get_status(Id, NewIsget)
    end.

update_is_get_by_num(0, IsGet) ->
    IsGet;
update_is_get_by_num(Num, IsGet) ->
    case element(Num, IsGet) of
        C when C =/= 0 ->
            update_is_get_by_num(Num - 1, IsGet);
        _ ->
            update_is_get_by_num(Num - 1, setelement(Num, IsGet, 1))
    end.

do_prize_by_goal(_Value, [], Num) ->
    Num;
do_prize_by_goal(Value, [Goal | T], Num) ->
    if
        Value > Goal ->
            do_prize_by_goal(Value, T, Num + 1);
        Value =:= Goal ->
            Num + 1;
        true ->
            Num
    end.

get_prize_by_chapter(Id, Index, ChapterPrizeId) ->
    L = get(?pd_main_chapter_prize_statue_list),
    %?DEBUG_LOG("Id----:~p---Index---:~p ---L--------------------:~p",[Id, Index, L]),
    if
        L =:= ?undefined; L =:= [] ->
            pass;
        true ->
            case lists:keyfind(Id, 1, L) of
                ?false ->
                    pass;
                {_, IsGet} ->
                    %?DEBUG_LOG("Index--------:~p-----IsGet-----:~p",[Index, IsGet]),
                    Num = element(Index, IsGet),
                    if
                        Num =:= 1 ->
                            PrizeId = load_cfg_main_ins:get_main_chapter_prize(Id, Index),
                            prize:prize_mail(PrizeId, ?S_MAIL_MAIN_CHAPTER_PRIZE, ?FLOW_REASON_CHAPTER_PRIZE),
                            NewIsget = setelement(Index, IsGet, 2),
                            %?DEBUG_LOG("NewIsget------------------------:~p",[NewIsget]),
                            put(?pd_main_chapter_prize_statue_list, lists:keyreplace(Id, 1, L, {Id, NewIsget})),
                            ?player_send(main_instance_sproto:pkg_msg(?MSG_MAIN_INSTANCE_CHAPTER_STAR_PRIZE, {})),
                            dbcache:update(?main_chapter_prize,
                                #main_chapter_prize{
                                    id = ChapterPrizeId,
                                    is_get = NewIsget
                                });
                        Num =:= 2 ->
                            ?return_err(?ERR_CHAPTER_START_PRIZE_1);
                        Num =:= 0 ->
                            ?return_err(?ERR_CHAPTER_START_PRIZE_2)
                    end
            end
    end.


update_is_get_status({_, ChapterId, Sub}, NewIsget) ->
    Id = {ChapterId, Sub},
    L = get(?pd_main_chapter_prize_statue_list),
    if
        L =:= ?undefined; L =:= [] ->
            pass;
        true ->
            case lists:keyfind(Id, 1, L) of
                ?false ->
                    pass;
                _ ->
                    put(?pd_main_chapter_prize_statue_list, lists:keyreplace(Id, 1, L, {Id, NewIsget}))
            end
    end.

%% 测试扫荡功能
test(Id, N, PlayerId) ->
    world:send_to_player(PlayerId, ?mod_msg(main_instance_mng, {test_clean, Id, N})).

test(Id, Times, N, PlayerId) ->
    world:send_to_player(PlayerId, ?mod_msg(main_instance_mng, {test_clean, Id, Times, N})).


clean_room(Id, T, S, N) ->
    %% 扫荡要首先判断玩家是否有足够体力
    case main_ins_mod:can_get_prize_from_room(Id) of
        ?true ->
            %% 翻牌消耗
            CostNum = get_clean_room_open_card_cost_by_times(N),
            SweepCostId = load_cfg_main_ins:get_main_instance_sweep_cost(Id),
            CostList = cost:get_cost(SweepCostId),
            TotalCostList = CostList ++ [{?PL_DIAMOND, CostNum}],
            case cost:cost_times(TotalCostList, 1, ?FLOW_REASON_SAODANG) of
                {error, _Reason} ->
                    ?return_err(?ERR_MAIN_INS_SWEEP_NOT_ENOUGH);
                _ ->
                    AllPrizeList = clean_room_once(Id, T, S, N),
                    ?player_send(main_instance_sproto:pkg_msg(?MSG_MAIN_INSTANCE_CLEAN, {AllPrizeList}))
            end;

        _ ->
            ?player_send(player_sproto:pkg_msg(?MSG_PLAYER_ERROR, {?MSG_MAIN_INSTANCE_CLEAN, ?ERR_CLEAN_MAIN_INS_SP_ENOUGH, <<>>})),
            ok
    end.

clean_room_times(Id, T, S, Times, N) ->
    case main_ins_mod:can_clean_room_times(Id, Times) of
        ?true ->
            SweepCostId = load_cfg_main_ins:get_main_instance_sweep_cost(Id),
            CostList = cost:get_cost(SweepCostId),
            %% 翻牌消耗和奖励
            CostNum = get_clean_room_open_card_cost_by_times(N),
            TotalCostList = CostList ++ [{?PL_DIAMOND, CostNum}],
            case cost:cost_times(TotalCostList, Times, ?FLOW_REASON_SAODANG) of
                {error, _Reason} ->
                    ?return_err(?ERR_MAIN_INS_SWEEP_NOT_ENOUGH);
                _ ->
                    AllPrizeList = do_clean_room_times(Id, T, S, Times, N, []),
                    %% ?DEBUG_LOG("AllPrizeList:~p", [AllPrizeList]),
                    %% ?INFO_LOG("pkg_msg:~p", [main_instance_sproto:pkg_msg(?MSG_MAIN_INSTANCE_CLEAN_TIMES, {AllPrizeList})]),
                    ?player_send(main_instance_sproto:pkg_msg(?MSG_MAIN_INSTANCE_CLEAN_TIMES, {AllPrizeList}))
            end;
        ?false ->
            ?player_send(player_sproto:pkg_msg(?MSG_PLAYER_ERROR, {?MSG_MAIN_INSTANCE_CLEAN_TIMES, ?ERR_CLEAN_MAIN_INS_SP_ENOUGH, <<>>})),
            ok
    end.

clean_room_once(Id, T, S, N) ->
    %% 不用等级匹配，直接去读main_ins表
    {PassPrizeId, MainCFG} = main_ins:get_clean_pass_prize(Id),

    Exp = get_exp_by_sp(MainCFG#main_ins_cfg.sp_cost),
    Gold = get_gold_by_sp(MainCFG#main_ins_cfg.sp_cost),
    %% 增加挑战次数
    add_challenge_times(Id),
    push_challenge_info_by_id(Id),

    #main_ins_cfg{ins_id = InsId, sub_type = Difficulty} = MainCFG,
    event_eng:post(?ev_main_ins_pass, {Id, InsId, Difficulty}),
    daily_task_tgr:do_daily_task({?ev_main_ins_pass, Id}, 1),
    main_ins_mod:cost(MainCFG#main_ins_cfg.sp_cost, MainCFG#main_ins_cfg.cost, {MainCFG#main_ins_cfg.type, MainCFG#main_ins_cfg.sub_type}),
    put(?pd_main_ins_mng,
        gb_trees:update(Id, S#main_ins{today_passed_times = T + 1}, get(?pd_main_ins_mng))),

    attr_new:begin_room_prize(PassPrizeId),
    %% 扫荡不给掉落了
    %%DropListRes = main_ins_util:calculate_drop_prize(load_cfg_main_ins:get_all_scene_by_ins_id(Id, []), get(?pd_level)),
    %% 挑选非Buff的掉落物品发送到玩家
    %%{_BuffDropListRes, DisBuffDropListRes} = scene_client_mng:category_droplist(DropListRes),

    %% 副本星级奖励PrizeList
    #main_ins_cfg{chapter_id = ChapterId} = MainCFG,
    #main_ins{pass_time = PassTime, lianjicount = DoubleHit, shoujicount = ShouJi, relivenum = ReliveNum} = S,
    achievement_mng:init_instance_ac(MainCFG#main_ins_cfg.stars, []),
    {AllStarList, _} = achievement_mng:complete_instance_ac({Id, ChapterId, 0, 0, PassTime, ReliveNum, DoubleHit, ShouJi, 0}),
    LianJIPrize = main_ins:send_main_ins_star_level_rewards(1000, Id, AllStarList, ?lianji),
    ShouJiPrize = main_ins:send_main_ins_star_level_rewards(1000, Id, AllStarList, ?shouji),
    PassTimePrize = main_ins:send_main_ins_star_level_rewards(1000, Id, AllStarList, ?passtime),
    RelivePrize = main_ins:send_main_ins_star_level_rewards(1000, Id, AllStarList, ?relive_num),
    AddXuePrize = main_ins:send_main_ins_star_level_rewards(1000, Id, AllStarList, ?add_xue),

    %% 扫荡卡牌奖励列表
    OpenCardPrize = get_clean_room_open_card_prize_by_times(Id, N),
    %% 固定奖励
    {ok, ItemTpL} = prize:get_prize(PassPrizeId),
    PrizeList = item_goods:merge_goods(ItemTpL ++ [{?PL_EXP, Exp}] ++ [{?PL_MONEY, Gold}]),
    NewPrizeList = prize:double_items(1000, PrizeList),
    game_res:set_res_reasion(<<"扫荡">>),
    All_Prize_List = item_goods:merge_goods(NewPrizeList ++ OpenCardPrize),
    game_res:try_give_ex(All_Prize_List, ?S_MAIL_INSTANCE, ?FLOW_REASON_FUBEN_COMPLETE),

    pet_new_mng:add_pet_new_exp_if_fight(NewPrizeList),
    attr_new:end_room_prize(PassPrizeId),
    ReturnPrizeList =NewPrizeList ++ OpenCardPrize ++ LianJIPrize ++ ShouJiPrize ++ PassTimePrize ++ RelivePrize ++ AddXuePrize,
    NewReturnPrizeList = item_goods:merge_goods(ReturnPrizeList),
    NewReturnPrizeList.

do_clean_room_times(_Id, _T, _S, 0, _N, RetList) ->
    RetList;
do_clean_room_times(Id, T, S, Times, N, RetList) ->
    PrizeList = clean_room_once(Id, T, S, N),
    do_clean_room_times(Id, T, S, Times -1, N, [{PrizeList} | RetList]).
%% 增加挑战次数
add_challenge_times(Id) ->
    Challenge = get_main_ins_challenge(),

    case gb_trees:lookup(Id, Challenge) of
        ?none -> %% first passed
            put(?pd_main_ins_challenge,
                gb_trees:insert(
                    Id,
                    #main_ins_challenge{
                        id = Id,
                        challenge_times = 1,
                        buy_challenge_times = 0,
                        max_challenge_times = load_cfg_main_ins:get_main_instance_battle_num(Id)
                    },
                    Challenge
                ));
        {?value, #main_ins_challenge{challenge_times = ChallengeTimes,
            buy_challenge_times = BuyChallengeTimes,
            max_challenge_times = MaxChallengeTimes}} ->
            put(?pd_main_ins_challenge,
                gb_trees:update(
                    Id,
                    #main_ins_challenge{
                        id = Id,
                        challenge_times = ChallengeTimes + 1,
                        buy_challenge_times = BuyChallengeTimes,
                        max_challenge_times = MaxChallengeTimes
                    },
                    Challenge
                ))
    end.

%% 获得挑战次数
get_challenge_times(Id) ->
    Challenge = get_main_ins_challenge(),

    case gb_trees:lookup(Id, Challenge) of
        ?none ->
            0;
        {?value, #main_ins_challenge{challenge_times = ChallengeTimes}} ->
            ChallengeTimes
    end.
%% 获取最大挑战次数
get_max_challenge_times(Id) ->
    Challenge = get_main_ins_challenge(),

    case gb_trees:lookup(Id, Challenge) of
        ?none ->
            load_cfg_main_ins:get_main_instance_battle_num(Id);
        {?value, #main_ins_challenge{max_challenge_times = MaxChallengeTimes}} ->
            MaxChallengeTimes
    end.

%% 登陆时推送玩家副本挑战信息
init_challenge_info() ->
    Challenge = get_main_ins_challenge(),
%%    ?INFO_LOG("Challenge:~p",[Challenge]),
    {Bin, Length} =
        com_util:gb_trees_fold(
            fun(Id, ChallengeInfo, {Acc, Num}) ->
                case ChallengeInfo of
                    #main_ins_challenge{ challenge_times = ChallengeTimes,
                        buy_challenge_times = BuyChallengeTimes, max_challenge_times = MaxChallengeTimes} ->
                        RemainChallengeTimes = erlang:max(0, MaxChallengeTimes - ChallengeTimes),
%%                        ?INFO_LOG("Id:~p, BuyChallengeTimes:~p, RemainChallengeTimes:~p", [Id,BuyChallengeTimes,RemainChallengeTimes]),
                        {<<Acc/binary, Id:16, BuyChallengeTimes:16, RemainChallengeTimes:16>>, Num + 1};
                    _ ->
                        {Acc, Num}
                end
            end,
            {<<>>, 0},
            Challenge),
%%    ?INFO_LOG("Length:~p",[Length]),
    NewBin = <<Length:16, Bin/binary>>,
    ?player_send(main_instance_sproto:pkg_msg(?MSG_MAIN_INSTANCE_CHALLENGE_INFO, {NewBin})).

%% 推送某个副本的挑战信息
push_challenge_info_by_id(Id) ->
    Challenge = get_main_ins_challenge(),
    case gb_trees:lookup(Id, Challenge) of
        ?none ->
           % ?INFO_LOG("error, push_challenge_info_by_id:~p",[Id]),
            ok;
        {?value, #main_ins_challenge{challenge_times = ChallengeTimes,
            buy_challenge_times = BuyChallengeTimes, max_challenge_times = MaxChallengeTimes}} ->
            RemainChallengeTimes = erlang:max(0, MaxChallengeTimes - ChallengeTimes),
            Bin = <<1:16, Id:16, BuyChallengeTimes:16, RemainChallengeTimes:16>>,
            ?player_send(main_instance_sproto:pkg_msg(?MSG_MAIN_INSTANCE_CHALLENGE_INFO, {Bin}))
    end.

get_exp_by_sp() ->
    Career = get(?pd_career),
    Lev = get(?pd_level),
    #role_cfg{sp_exp = SpExp} = load_career_attr:lookup_role_cfg({Career, Lev}),
    CostSp = attr_new:get(?pd_cost_sp, 0),
    Exp = CostSp * SpExp,
    Exp.
%%    player:add_exp(Exp).
get_exp_by_sp(Sp) ->
    Career = get(?pd_career),
    Lev = get(?pd_level),
    #role_cfg{sp_exp = SpExp} = load_career_attr:lookup_role_cfg({Career, Lev}),
    Exp = Sp * SpExp,
    Exp.

get_gold_by_sp() ->
    Career = get(?pd_career),
    Lev = get(?pd_level),
    #role_cfg{sp_gold = SpGold} = load_career_attr:lookup_role_cfg({Career, Lev}),
    CostSp = attr_new:get(?pd_cost_sp, 0),
    Gold = CostSp * SpGold,
    Gold.
%%    game_res:try_give_ex([{?PL_MONEY, Gold}], ?FLOW_REASON_FUBEN_COMPLETE).
get_gold_by_sp(Sp) ->
    Career = get(?pd_career),
    Lev = get(?pd_level),
    #role_cfg{sp_gold = SpGold} = load_career_attr:lookup_role_cfg({Career, Lev}),
    Gold = Sp * SpGold,
    Gold.



get_all_pass_room() ->
    gb_trees:keys(get(?pd_main_ins_mng)).
   %%  com_util:gb_trees_fold(
   %%      fun(Id, MainIns, Acc) ->
   %%          case MainIns of
   %%              #main_ins{ star = Star } ->
   %%                  if
   %%                      Star >= 3 ->
   %%                          [Id | Acc];
   %%                      true ->
   %%                          Acc
   %%                  end;
   %%              _ ->
   %%                  Acc
   %%          end
   %%      end,
   %%      [],
   %%      get(?pd_main_ins_mng)
   %%  ).


sync_clean_room_list() ->
    ?player_send(main_instance_sproto:pkg_msg(?MSG_PUSH_ROOM_CLEAN_LIST, {get_all_pass_room()})).
    %% VipLevel = attr_new:get_vip_lvl(),
    %% case load_vip_right:can_clean_main_ins(VipLevel) of
    %%     ?FALSE ->
    %%         ?player_send(main_instance_sproto:pkg_msg(?MSG_PUSH_ROOM_CLEAN_LIST, {get(?pd_clean_room_list)}));
    %%     ?TRUE ->
    %%         ?player_send(main_instance_sproto:pkg_msg(?MSG_PUSH_ROOM_CLEAN_LIST, {get_all_pass_room()}))
    %% end.

get_yinxing_count(PrizeList) ->
    NewPrizeList = item_goods:merge_goods(PrizeList),
    YingXing = lists:keyfind(?YINXING, 1, NewPrizeList),
    case YingXing of
        ?false ->
            0;
        {?YINXING, Num} ->
            Num;
        _ ->
            0
    end.

get_battle_cost(Count, Num, List) ->
    SubList = lists:sublist(List, Count+1, Num),
    lists:sum(SubList).
