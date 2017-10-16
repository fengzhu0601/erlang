%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 28. 十二月 2015 下午3:18
%%%-------------------------------------------------------------------
-module(load_arena_cfg).
-author("clark").

%% API
-export
([
    add_arena_cent/2,
    sub_arena_cent/2,
    decompose/1,
    get_arena_cfg_turn_times/1,
    get_arena_p2e_rank_prize/1
]).



-include_lib("config/include/config.hrl").
-include("inc.hrl").
-include("player.hrl").
-include("rank.hrl").
-include("arena_struct.hrl").
-include("achievement.hrl").
-include("load_spirit_attr.hrl").
-include("system_log.hrl").


-define(NUM_POS, 1000000).

get_total_cent(ALev, NaCent) ->
    ALev*(?NUM_POS) + NaCent.


decompose(TotalCent) ->
    ALev = TotalCent/(?NUM_POS),
    NaCent = TotalCent - ALev*(?NUM_POS),
    {ALev, NaCent}.


%% 减少竞技积分
sub_arena_cent(ArenaInfo, SubACent) when SubACent < 0 ->
    ArenaInfo;
sub_arena_cent(ArenaInfo, 0) ->
    ArenaInfo;
sub_arena_cent(ArenaInfo = #arena_info{id = Id, arena_lev = ALev, arena_cent = ACent}, SubACent) ->
    NACent = erlang:max(ACent - SubACent, 0),
    NALev = ALev - 1,
    case lookup_arena_cfg(ALev - 1) of
        ?none -> %% min level
            ranking_lib:update(?ranking_arena, Id, get_total_cent(ALev, NACent)),
            ArenaInfo#arena_info{arena_cent = NACent};
        #arena_cfg{up_cent = UpCent, attr_award = AttrAward} ->
            if
                NACent >= UpCent ->
                    ranking_lib:update(?ranking_arena, Id, get_total_cent(ALev, NACent)),
                    ArenaInfo#arena_info{arena_cent = NACent};
                ?true -> %% downLevel
                    %% 添加竞技场段位属性
                    attr_new:begin_sync_attr(),
                    #arena_cfg{attr_award = OAttrAward} = lookup_arena_cfg(ALev),
                    Attrold = attr:sats_2_attr(OAttrAward),
                    Attrnew = attr:sats_2_attr(AttrAward),
                    attr_new:player_sub_attr(Attrold),
                    attr_new:player_add_attr(Attrnew),
                    attr_new:end_sync_attr(),

                    NAI = ArenaInfo#arena_info{arena_lev = NALev, arena_cent = UpCent},
                    sub_arena_cent(NAI, UpCent - NACent)
            end
    end.

%% 添加竞技积分
add_arena_cent(ArenaInfo, AddACent) when AddACent < 0 ->
    ArenaInfo;
add_arena_cent(ArenaInfo, 0) ->
    ArenaInfo;
add_arena_cent(ArenaInfo = #arena_info{id = Id, arena_lev = ALev, high_arena_lev = HALev, arena_cent = ACent}, AddACent) ->
    NACent = ACent + AddACent,
    case lookup_arena_cfg(ALev) of
        ?none -> %% max level
            ArenaInfo;
        #arena_cfg{up_cent = UpCent, honour_award = Honour, attr_award = OAttrAward} ->
            if
                NACent < UpCent ->
                    %% 积分不够升级
                    ranking_lib:update(?ranking_arena, Id, get_total_cent(ALev, NACent)),
                    ArenaInfo#arena_info{arena_cent = NACent};
                ?true ->
                    %% 积分够升级
                    NALev = ALev + 1,
                    %% 历史最高等级
                    NHALev = max(NALev, HALev),
                    achievement_mng:do_ac(?baiyingaoshou),
                    NAI = ArenaInfo#arena_info{arena_lev = NALev, high_arena_lev = NHALev, arena_cent = UpCent},
                    case lookup_arena_cfg(NALev) of
                        ?none ->
                            ranking_lib:update(?ranking_arena, Id, get_total_cent(ALev, UpCent)),
                            ArenaInfo#arena_info{arena_cent = UpCent};
                        #arena_cfg{attr_award = AttrAward} ->
                            %% 添加竞技场段位属性
                            attr_new:begin_sync_attr(),
                            Attrold = attr:sats_2_attr(OAttrAward),
                            Attrnew = attr:sats_2_attr(AttrAward),
                            attr_new:player_sub_attr(Attrold),
                            attr_new:player_add_attr(Attrnew),
                            attr_new:end_sync_attr(),
                            case NHALev > HALev of
                                ?true when Honour > 0 ->
                                    game_res:try_give_ex([{?PL_HONOUR, Honour}], ?FLOW_REASON_ARENA);
                                _ ->
                                    ignore
                            end,
                            add_arena_cent(NAI, NACent - UpCent)
                    end
            end
    end.

get_arena_p2e_rank_prize(Rank) ->
    get_arena_p2e_rank_prize(Rank, 1).

get_arena_p2e_rank_prize(Rank, Index) ->
    case lookup_challeng_reward_cfg(Index) of
        #challeng_reward_cfg{min_ranking = Min, max_ranking = Max, rewardld = Award} ->
            if
                Rank >= Min andalso Rank < Max orelse Max =:= 0 ->
                    Award;
                true ->
                    get_arena_p2e_rank_prize(Rank, Index + 1)
            end;
        _ ->
            0
    end.

%% lookup_arena_cfg(Lev).
load_config_meta() ->
    [
        #config_meta{
            record = #arena_cfg{},
            fields = ?record_fields(arena_cfg),
            file = "arena.txt",
            keypos = #arena_cfg.id,
            verify = fun verify/1
        },
        #config_meta{
            record = #arena_shop_cfg{},
            fields = ?record_fields(arena_shop_cfg),
            file = "arena_shop.txt",
            keypos = #arena_shop_cfg.id,
            verify = fun verify/1
        },
        #config_meta
        {
            record = #challeng_reward_cfg{},
            fields = ?record_fields(challeng_reward_cfg),
            file = "arena_challeng_reward.txt",
            keypos = #challeng_reward_cfg.id,
            verify = fun verify/1
        },
        #config_meta{
            record = #arena_p2e_rank_prize_cfg{},
            fields = ?record_fields(arena_p2e_rank_prize_cfg),
            file = "arena_p2e_rank_prize.txt",
            keypos = #arena_p2e_rank_prize_cfg.id,
            all = [#arena_p2e_rank_prize_cfg.id],
            verify = fun verify/1
        }
    ].

verify(#arena_cfg{id = Id, up_cent = UpCent, daily_award = DailyItemL, trun_award = TrunAward
    , p2e_win = {P2eWin, P2eWinTpL}, p2e_loss = {P2eLoss, P2eLossTpL}, p2p_win = {P2pWin, P2pWinTpL}
    , p2p_loss = {P2pLoss, P2pLossTpL}, multi_p2p_win = {MP2pWin, MP2pWinTpL}
    , multi_p2p_loss = {MP2pLoss, MP2pLossTpL}, kill_ratio = KillRatio, attr_award = AttrL, honour_award = Honour
}) ->
    ?check(com_util:is_valid_uint8(Id), "arena.txt [~w] 竞技等级(id)无效！", [Id]),
    ?check(com_util:is_valid_uint32(UpCent), "arena.txt [~w] 竞技升级积分(up_cent)~w无效！", [Id, UpCent]),

    lists:foreach(fun({ItemBid, Num}) ->
        ?check(load_item:is_exist_item_attr_cfg(ItemBid), "arena.txt [~w] 竞技每日物品奖励(daily_award) ItemBid:~w 无效", [Id, ItemBid]),
        ?check(com_util:is_valid_uint16(Num), "arena.txt [~w] 竞技每日物品奖励(daily_award) Num:~w 无效", [Id, Num])
    end, DailyItemL),
    ?check(com_util:is_valid_uint16(Honour), "arena.txt [~w] 竞技(honour_award)~w无效！", [Id, Honour]),


    check_trun_award(Id, TrunAward),
    ?check(check_result_award(P2eWinTpL), "arena.txt [~w] 竞技非即时胜利积分中的物品奖励(p2e_win)~w无效！", [Id, P2eWinTpL]),
    ?check(check_result_award(P2eLossTpL), "arena.txt [~w] 竞技非即时失败积分中的物品奖励(p2e_loss)~w无效！", [Id, P2eLossTpL]),
    ?check(check_result_award(P2pWinTpL), "arena.txt [~w] 竞技即时胜利积分中的物品奖励(p2p_win)~w无效！", [Id, P2pWinTpL]),
    ?check(check_result_award(P2pLossTpL), "arena.txt [~w] 竞技即时失败积分中的物品奖励(p2p_loss)~w无效！", [Id, P2pLossTpL]),
    ?check(check_result_award(MP2pWinTpL), "arena.txt [~w] 竞技多人即时胜利积分中的物品奖励(multi_p2p_win)~w无效！", [Id, MP2pWinTpL]),
    ?check(check_result_award(MP2pLossTpL), "arena.txt [~w] 竞技多人即时失败积分中的物品奖励(multi_p2p_loss)~w无效！", [Id, MP2pLossTpL]),

    ?check(com_util:is_valid_uint16(P2eWin), "arena.txt [~w] 竞技非即时胜利积分(p2e_win)~w无效！", [Id, P2eWin]),
    ?check(com_util:is_valid_uint16(P2eLoss), "arena.txt [~w] 竞技非即时失败积分(p2e_loss)~w无效！", [Id, P2eLoss]),
    ?check(com_util:is_valid_uint16(P2pWin), "arena.txt [~w] 竞技即时胜利积分(p2p_win)~w无效！", [Id, P2pWin]),
    ?check(com_util:is_valid_uint16(P2pLoss), "arena.txt [~w] 竞技即时失败积分(p2p_loss)~w无效！", [Id, P2pLoss]),
    ?check(com_util:is_valid_uint16(MP2pWin), "arena.txt [~w] 竞技多人即时胜利积分(multi_p2p_win)~w无效！", [Id, MP2pWin]),
    ?check(com_util:is_valid_uint16(MP2pLoss), "arena.txt [~w] 竞技多人即时失败积分(multi_p2p_loss)~w无效！", [Id, MP2pLoss]),
    ?check(com_util:is_valid_uint8(KillRatio), "arena.txt [~w] 竞技多人即时死亡系数(kill_ratio)~w无效！", [Id, KillRatio]),
    lists:foreach(fun({AttrCode, AttrVal}) ->
        ?check(game_def:is_valid_sat(AttrCode), "arena.txt [~w] 竞技段位属性(attr_award) AttrCode:~w 无效", [Id, AttrCode]),
        ?check(com_util:is_valid_uint16(AttrVal), "arena.txt [~w] 竞技段位属性(attr_award) AttrVal:~w 无效", [Id, AttrVal])
    end, AttrL);

verify(#arena_shop_cfg{}) ->
    ok;

verify(#arena_p2e_rank_prize_cfg{prize = Prize}) ->
    ?check(is_tuple(Prize), "arena_p2e_rank_prize.txt 配置奖励无效 prize:~p", [Prize]),
    ok;

verify(#challeng_reward_cfg{}) ->
    ok;

verify(_R) ->
    ?ERROR_LOG("signin 配置　错误格式"),
    exit(bad).

check_trun_award(Lev, TrunAward) ->
    TrunL = erlang:tuple_to_list(TrunAward),
    Len = length(TrunL),
    ?check(8 == Len, "arena.txt [~w] (trun_award)转盘奖励长度不足 len[~w]:~w ", [Lev, Len, TrunL]),
    lists:foreach(fun(StarAward) ->
        ?check((StarAward /= [] andalso is_list(StarAward)), "arena.txt [~w] (trun_award)奖励~w无效 ", [Lev, StarAward]),
        lists:foreach(fun({ItemBid, Num}) ->
            ?check(load_item:is_exist_item_attr_cfg(ItemBid), "arena.txt [~w] (trun_award)转盘奖励物品~w不存在! ", [Lev, ItemBid]),
            ?check(com_util:is_valid_uint32(Num), "arena.txt [~w] (trun_award)转盘奖励物品数量~w无效! ", [Lev, Num])
        end, StarAward)
    end, TrunL).

check_result_award([]) -> ?true;
check_result_award([{ItemBid, Num} | AwardL]) ->
    IsItem = load_item:is_exist_item_attr_cfg(ItemBid),
    IsItemNum = com_util:is_valid_uint32(Num),
    if
        IsItem, IsItemNum -> check_result_award(AwardL);
        ?true -> ?false
    end.

%% Id为配置表中的竞技场等级,对应着等级名称
get_arena_cfg_turn_times(Id) ->
    case lookup_arena_cfg(Id) of
        #arena_cfg{turn_times = TrunTimes} ->
            TrunTimes;
        _ ->
            ret:error(unkown_Id)
    end.