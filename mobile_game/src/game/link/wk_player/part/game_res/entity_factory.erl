%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 11. 八月 2015 下午12:17
%%%-------------------------------------------------------------------
-module(entity_factory).
-author("clark").

%% API
-export(
[
    build/4,
    can_sub_prop/2,
    sub_prop/3
]).

-include("inc.hrl").
-include("item.hrl").
%% -include("player_def.hrl").
-include("item_new.hrl").
-include("load_item.hrl").
-include("item_bucket.hrl").
-include("player.hrl").
-include("achievement.hrl").


build(#item_new{} = Goods, _Num, _BuildParList, _Reason) -> Goods;
build(Bid, Num, BuildParList, Reason) ->
    Goods =
        case load_item:get_main_type(Bid) of
            ?val_item_main_type_goods ->
                GoodsType = load_item:get_type(Bid),
                case GoodsType of
                    ?val_item_type_assets -> add_prop(Bid, Num, Reason);
                    ?val_item_type_gem ->
                        case load_cfg_gem:is_epic_Gem(Bid) of
                            ?true ->
                                case BuildParList of
                                    [] ->
                                        item_goods:build_epic_gem(Bid, Num, 0);
                                    _ ->
                                        item_goods:build_epic_gem(Bid, Num, BuildParList)
                                end;
                            ?false ->
                                item_goods:build_gem(Bid, Num, BuildParList)
                        end;
                    ?val_item_type_use -> item_goods:build_use(Bid, Num, BuildParList);
                    ?val_item_main_type_slot -> item_goods:build_use(Bid, Num, BuildParList);
                    ?val_item_type_fumo_scroll_debris -> item_goods:build_use(Bid, Num, BuildParList);
                    ?val_item_type_fumo_scroll -> item_goods:build_use(Bid, Num, BuildParList);
                    ?val_item_type_fumo_stone -> item_goods:build_fumoshi(Bid, Num, BuildParList);
                    ?val_item_type_suit_chip -> item_goods:build_use(Bid, Num, BuildParList);
                    ?val_item_type_gift -> item_goods:build_gift(Bid, Num, BuildParList);
%%                    ?val_item_type_crown_debris ->
%%                        crown_mng:add_gem(Bid, Num),
%%                        ret:ok(0);
                    ?val_item_type_pet_skill -> item_goods:build_pet_skill(Bid, Num, BuildParList);
                    ?val_item_type_pet_egg -> item_goods:build_pet_egg(Bid, Num, BuildParList);
                    ?val_item_type_card -> item_goods:build_card(Bid, Num, BuildParList);
                    ?val_item_type_friend_gift -> item_goods:build_friend_gift(Bid, Num, BuildParList);
                    ?val_item_type_rand_ins -> item_goods:build_rand_ins(Bid, Num, BuildParList);
                    ?val_item_type_flower -> item_goods:build_flower(Bid, Num, BuildParList);
                    ?val_item_type_treasure_map -> item_goods:build_treasure_map(Bid, Num, BuildParList);
                    ?val_item_type_room_buf -> item_goods:build_use(Bid, Num, BuildParList);
                    _ ->
                        ret:error(unknown_type)
                end;
            ?val_item_main_type_equip ->
                item_equip:build(Bid, BuildParList);
            _ ->
                case add_prop(Bid, Num, Reason) of
                    {ok, Val} ->
                        {ok, Val};
                    _ ->
                        info_log:push({"failed in build entity unknown_bid_type",Bid}),
                        ret:error(unknown_bid_type)
                end
        end,
    case Goods of
        {error, _} ->
            info_log:push({"failed in build entity unknown_bid_type1",Bid}),
            ret:error(unknown_type);
        _ -> Goods
    end.

add_prop(Bid, Num0, Reason) ->
    RoomPro = attenuation:get_attenuation_pro(),
    Num = erlang:round(RoomPro * Num0),
    ?player_send(player_sproto:pkg_msg(?MSG_PLAYER_EARNINGS_CHANGE, {erlang:round(RoomPro*100)})), %%   把增益的更改发送到前端
    case Bid of
        ?MONEY_BID ->
            %% 消费金币记录
            MoneyBefore = attr_new:get(?pd_money,0),
            MoneyAfter = MoneyBefore + Num,
            achievement_mng:do_ac2(?jiacaiwanguan, 0, Num),
            MoneyType = ?MONEY_BID,
            FlowId = 1,
            case Num of
                0 -> pass;
                _ -> system_log:info_money_flow_log(MoneyBefore, MoneyAfter, Num, MoneyType, FlowId, Reason)
            end,
            Val = attr_new:set(?pd_money, Num),
            {ok, Val};
        ?DIAMOND_BID ->
            %% 消费钻石记录
            MoneyBefore = attr_new:get(?pd_diamond,0),
            MoneyAfter = MoneyBefore + Num,
            achievement_mng:do_ac2(?zuanshizhiwang, 0, Num),
            MoneyType = ?DIAMOND_BID,
            FlowId = 1,
            case Num of
                0 -> pass;
                _ -> system_log:info_money_flow_log(MoneyBefore, MoneyAfter, Num, MoneyType, FlowId, Reason)
            end,
            Val = attr_new:set(?pd_diamond, Num),
            {ok, Val};
        ?FRAGMENT_BID ->
            Val = attr_new:set(?pd_fragment, Num),
            {ok, Val};
        ?LEVEL_BID ->
            Val = attr_new:set(?pd_level, Num),
            {ok, Val};
        ?EXP_BID ->
            Val = attr_new:set_exp(Num),
            {ok, Val};
        ?HP_BID ->
            Val = attr_new:set(?pd_hp, Num),
            {ok, Val};
        ?LONGWENS_BID ->
            Val = attr_new:set(?pd_longwens, Num),
            {ok, Val};
        ?HONOUR_BID ->
            Val = attr_new:set(?pd_honour, Num),
            {ok, Val};
        ?PEARL_BID ->
            Val = attr_new:set(?pd_pearl, Num),
            {ok, Val};
        ?LONG_WEN_BID ->
            Val = attr_new:set(?pd_long_wen, Num),
            {ok, Val};
        ?COMBAT_POWER_BID ->
            Val = attr_new:set(?pd_combat_power, Num),
            {ok, Val};
        ?MP_BID ->
            Val = attr_new:set(?pd_mp, Num),
            {ok, Val};
        ?PET_TACIT_BID ->
            {ok, 0};
        ?SP_BID ->
            Val = attr_new:set(?pd_sp, Num),
            {ok, Val};
        ?SP_COUNT_BID ->
            Val = attr_new:set(?pd_sp_buy_count, Num),
            {ok, Val};
        ?JINXING ->
            Val = attr_new:set(?pd_main_ins_jinxing, Num),
            {ok, Val};
        ?YINXING ->
            achievement_mng:do_ac2(?fanxingmantian, 0, Num),
            Val = attr_new:set(?pd_main_ins_yinxing, Num),
            {ok, Val};
        ?YUANSU_MOLI ->
            Val = attr_new:set(?pd_crown_yuansu_moli, Num),
            {ok, Val};
        ?GUANGAN_MOLI ->
            Val = attr_new:set(?pd_crown_guangan_moli, Num),
            {ok, Val};
        ?MINGYUN_MOLI ->
            Val = attr_new:set(?pd_crown_mingyun_moli, Num),
            {ok, Val};

        ?GUILD_CONTRIBUTION ->
            Val = guild_boss:add_guild_contribution(Num),
            guild_mng:push_role_data(),
            {ok, Val};

        _ ->    
            ret:error(unknown_type)
    end.



can_sub_prop(Bid, Num) ->
    CurNum =
        case Bid of
            ?MONEY_BID -> attr_new:get(?pd_money, 0);
            ?DIAMOND_BID -> attr_new:get(?pd_diamond, 0);
            ?FRAGMENT_BID -> attr_new:get(?pd_fragment, 0);
            ?LEVEL_BID -> attr_new:get(?pd_level, 0);
            ?EXP_BID -> 0; %% 不应有减经验的需求
            ?HP_BID -> attr_new:get(?pd_hp, 0);
            ?LONGWENS_BID -> attr_new:get(?pd_longwens, 0);
            ?HONOUR_BID -> attr_new:get(?pd_honour, 0);
            ?PEARL_BID -> attr_new:get(?pd_pearl, 0);
            ?LONG_WEN_BID -> attr_new:get(?pd_long_wen, 0);
            ?COMBAT_POWER_BID -> attr_new:get(?pd_combat_power, 0);
            ?MP_BID -> attr_new:get(?pd_mp, 0);
            ?PET_TACIT_BID -> 0;
            ?SP_BID -> attr_new:get(?pd_sp, 0);
            ?SP_COUNT_BID -> attr_new:get(?pd_sp_buy_count, 0);
            ?JINXING -> attr_new:get(?pd_main_ins_jinxing, 0);
            ?YINXING -> attr_new:get(?pd_main_ins_yinxing, 0);
            ?YUANSU_MOLI -> attr_new:get(?pd_crown_yuansu_moli, 0);
            ?GUANGAN_MOLI -> attr_new:get(?pd_crown_guangan_moli, 0);
            ?MINGYUN_MOLI -> attr_new:get(?pd_crown_mingyun_moli, 0);

            % ?PL_MONEY -> attr_new:get(?pd_money, 0);
            % ?PL_DIAMOND -> attr_new:get(?pd_diamond, 0);
            % ?PL_FRAGMENT -> attr_new:get(?pd_fragment, 0);
            % ?PL_LEVEL -> attr_new:get(?pd_level, 0);
            % ?PL_HP -> attr_new:get(?pd_hp, 0);
            % ?PL_LONGWENS -> attr_new:get(?pd_longwens, 0);
            % ?PL_HONOUR -> attr_new:get(?pd_honour, 0);
            % ?PL_PEARL -> attr_new:get(?pd_pearl, 0);
            % ?PL_LONG_WEN -> attr_new:get(?pd_long_wen, 0);
            % ?PL_COMBAT_POWER -> attr_new:get(?pd_combat_power, 0);
            % ?PL_MP -> attr_new:get(?pd_mp, 0);
            % ?PL_SP -> attr_new:get(?pd_sp, 0);
            % ?PL_SP_COUNT -> attr_new:get(?pd_sp_buy_count, 0);
            _ -> 0
        end,
    if
        CurNum >= Num -> ret:ok();
        true -> ret:error(no_enough)
    end.

sub_prop(_, 0, _) -> ok;
sub_prop(Bid, Num, Reason) ->
    CurNum = -1 * Num,
    case Bid of
        ?MONEY_BID ->
            %% 消费金币记录
            MoneyBefore = attr_new:get(?pd_money,0),
            MoneyAfter = MoneyBefore - Num,
            MoneyCount = Num,
            MoneyType = ?MONEY_BID,
            FlowId = 0,
            system_log:info_money_flow_log(MoneyBefore, MoneyAfter, MoneyCount, MoneyType, FlowId, Reason),
            attr_new:set(?pd_money, CurNum);
        ?DIAMOND_BID ->
            %% 消费钻石记录
            MoneyBefore = attr_new:get(?pd_diamond,0),
            MoneyAfter = MoneyBefore - Num,
            MoneyCount = Num,
            MoneyType = ?DIAMOND_BID,
            FlowId = 0,
            system_log:info_money_flow_log(MoneyBefore, MoneyAfter, MoneyCount, MoneyType, FlowId, Reason),
            %% 消费砖石的时候记录，用于每日消费领奖
            %set_player_consume(Num),
            vip_new_mng:do_vip_cost(Num),
            attr_new:set(?pd_diamond, CurNum);
        ?FRAGMENT_BID -> attr_new:set(?pd_fragment, CurNum);
        ?LEVEL_BID -> attr_new:set(?pd_level, CurNum);
        ?HP_BID -> attr_new:set(?pd_hp, CurNum);
        ?LONGWENS_BID -> attr_new:set(?pd_longwens, CurNum);
        ?HONOUR_BID -> attr_new:set(?pd_honour, CurNum);
        ?PEARL_BID -> attr_new:set(?pd_pearl, CurNum);
        ?LONG_WEN_BID -> attr_new:set(?pd_long_wen, CurNum);
        ?COMBAT_POWER_BID -> attr_new:set(?pd_combat_power, CurNum);
        ?MP_BID -> attr_new:set(?pd_mp, CurNum);
        ?SP_BID -> attr_new:set(?pd_sp, CurNum);
        ?SP_COUNT_BID -> attr_new:set(?pd_sp_buy_count, CurNum);
        ?JINXING -> attr_new:set(?pd_main_ins_jinxing, CurNum);
        ?YINXING -> attr_new:set(?pd_main_ins_yinxing, CurNum);
        ?YUANSU_MOLI -> attr_new:set(?pd_crown_yuansu_moli, CurNum);
        ?GUANGAN_MOLI -> attr_new:set(?pd_crown_guangan_moli, CurNum);
        ?MINGYUN_MOLI -> attr_new:set(?pd_crown_mingyun_moli, CurNum);
        % ?PL_MONEY -> attr_new:set(?pd_money, CurNum);
        % ?PL_DIAMOND -> attr_new:set(?pd_diamond, CurNum);
        % ?PL_FRAGMENT -> attr_new:set(?pd_fragment, CurNum);
        % ?PL_LEVEL -> attr_new:set(?pd_level, CurNum);
        % ?PL_HP -> attr_new:set(?pd_hp, CurNum);
        % ?PL_LONGWENS -> attr_new:set(?pd_longwens, CurNum);
        % ?PL_HONOUR -> attr_new:set(?pd_honour, CurNum);
        % ?PL_PEARL -> attr_new:set(?pd_pearl, CurNum);
        % ?PL_LONG_WEN -> attr_new:set(?pd_long_wen, CurNum);
        % ?PL_COMBAT_POWER -> attr_new:set(?pd_combat_power, CurNum);
        % ?PL_MP -> attr_new:set(?pd_mp, CurNum);
        % ?PL_SP -> attr_new:set(?pd_sp, CurNum);
        % ?PL_SP_COUNT -> attr_new:set(?pd_sp_buy_count, CurNum);
        _ -> ret:error(unknown_type)
    end.

%% 消费砖石的时候记录，用于每日消费领奖
% set_player_consume(Num) ->
%     DayTotalConsume = get(?pd_day_total_consume) + Num,
%     TotalConsume = get(?pd_total_consume) + Num,
%     put(?pd_day_total_consume, DayTotalConsume),
%     put(?pd_total_consume, TotalConsume),
%     ?player_send(charge_reward_sproto:pkg_msg(?MSG_CHARGE_INFO_SC, {DayTotalConsume, TotalConsume})),
%     ok.