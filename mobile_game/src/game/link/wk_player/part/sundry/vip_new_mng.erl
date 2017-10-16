-module(vip_new_mng).

-include_lib("pangzi/include/pangzi.hrl").


-include("inc.hrl").
-include("player.hrl").
-include("player_mod.hrl").
-include("handle_client.hrl").
-include("day_reset.hrl").
-include("system_log.hrl").
-include("vip_new.hrl").
-include("load_vip_new_cfg.hrl").
-include("payment.hrl").
-include("item_bucket.hrl").
-include("../../wk_open_server_happy/open_server_happy.hrl").


-export([
    up_vip_level/1,
    do_grow_jijin/1,
    do_vip_cost/1,
    qq_pay_send_prize/1,
    do_cost_total_rmb/2
]).


-define(give_first_pay_diamond, give_first_pay_diamond).
-define(give_first_pay_diamond_timerref, give_first_pay_diamond_timerref).


do_cost_total_rmb(PayId, Type) ->
    C = 
    case Type of
        1 ->
            load_pay_order:get_pay_rmb_by_payid(PayId);
        2 ->
            PayId
    end,
    OldC = attr_new:get(?pd_vip_cost_total_rmb, 0),
    NewC = OldC + C,
    %% NewC新的充值钱数单位分
    %% open_server_happy_mng:player_pay_money_count(C),
    CfgRmb = load_pay_order:get_pay_rmb_by_payid(1), %% 1 shouchong
    if
        NewC >= CfgRmb ->
            %?DEBUG_LOG("NewC----------------------:~p",[{NewC, CfgRmb}]),
            VipBuyStatusList = get(?pd_vip_buy_status),
            case lists:keyfind(1, 1, VipBuyStatusList) of
                ?false ->
                    qq_pay_send_prize(1),
                    ?player_send(vip_new_sproto:pkg_msg(?MSG_VIP_NEW_PAY_PRIZE_STATUS, {1}));
                _ ->
                    pass
            end;
        true ->
            pass
    end,
    put(?pd_vip_cost_total_rmb, NewC).


on_day_reset(_) ->
    put(?pd_vip_gift_every_day, 0),
    VipBuyStatusList = get(?pd_vip_buy_status),
    put(?pd_vip_buy_status, lists:keydelete(5, 1, VipBuyStatusList)),   %% tili
    %?DEBUG_LOG("vip_buy_status----------------------:~p",[get(?pd_vip_buy_status)]),
    MonthCard = get(?pd_vip_month_card),
    NowTime = com_time:now(),
    if
        MonthCard > NowTime ->
            put(?pd_vip_is_get_month_card_prize, 1);
        true ->
            pass
    end,
    case get(?pd_vip_yongjiu_card) of
        1 ->
            put(?pd_vip_is_get_yongjiu_card_prize, 1);
        _ ->
            pass
    end,

    % EveryDayCostList = {0, load_pay_prize:init_every_day_cost_list()},
    % put(?pd_vip_every_day_cost, EveryDayCostList),
    send_day_cost_prize(),
    %send_day_and_sum_cost(),
    init_client(),
    ok.

send_day_cost_prize() ->
    DayCostPayIdList = load_pay_prize:get_pay_id_by_type(4),
    PrizeStatusList = get(?pd_vip_prize_status_list),
    lists:foreach(fun(PayPrizeId) ->
        case lists:keyfind(PayPrizeId, 1, PrizeStatusList) of
            {_, S} when S =:= 1 orelse S =:= 2 ->
                case load_pay_prize:get_cfg_by_pay_prize_id(PayPrizeId) of
                    {Type, FirstPrizeId, GrowJiJinPrizeId, DayCostPrizeId, SumCostPrizeId} when Type >= 1 andalso Type =< 5->
                        FinalPrizeId = 
                        case Type of
                            1 ->%% 首冲(SDK回调)
                                FirstPrizeId;
                            2 ->%% 成长基金购买(SDK回调)
                                GrowJiJinPrizeId;
                            3 ->%% 成长基金奖励(prize表ID）（客户端请求）
                                GrowJiJinPrizeId;
                            4 ->%% 每日消费（客户端请求）
                                DayCostPrizeId;
                            5 ->%% 累计消费（客户端请求）
                                SumCostPrizeId
                        end,
                        MailSys = 
                        case PayPrizeId of
                            13 ->
                                ?S_MAIL_VIP_DAY_COST_1;
                            14 ->
                                ?S_MAIL_VIP_DAY_COST_2;
                            15 ->
                                ?S_MAIL_VIP_DAY_COST_3;
                            _ ->
                                ?S_MAIL_VIP_DAY_COST_1
                        end,
                        prize:prize_mail(FinalPrizeId, MailSys, ?FLOW_REASON_RECHARGE),
                        del_pay_prize_status(PayPrizeId);
                    ?none ->
                        pass
                end;
            _ ->
                pass
        end
    end,
    DayCostPayIdList),
    EveryDayCostList = {0, load_pay_prize:init_every_day_cost_list()},
    put(?pd_vip_every_day_cost, EveryDayCostList).




qq_pay_send_prize(PayId) ->
    VipBuyStatusList = get(?pd_vip_buy_status),
    case load_pay_order:get_state_num(PayId) of
        ?none ->
            pass;
        0 -> %% 无限购买
            if
                PayId =:= 2 ->  %% 月卡
                    buy_month_card(PayId);
                true ->
                    chongzhi_fan_diamond(PayId)
            end,
            ?player_send(vip_new_sproto:pkg_msg(?MSG_VIP_NEW_QQ_PAY_CS, {get(?pd_vip), 1}));
        1 -> %% 只能购买一次
            if
                PayId =:= 3 ->%% 永久卡
                    chongzhi_fan_diamond(PayId),
                    put(?pd_vip_yongjiu_card, 1),
                    put(?pd_vip_buy_status, [{PayId, 0}|VipBuyStatusList]),
                    put(?pd_vip_is_get_yongjiu_card_prize, 1),
                    ?player_send(vip_new_sproto:pkg_msg(?MSG_VIP_NEW_QQ_PAY_CS, {get(?pd_vip), 0}));
                true -> 
                    if
                        PayId =:= 1; PayId =:= 4 ->
                            case load_pay_order:get_pay_prize_id(PayId) of
                                ?none ->
                                    pass;
                                PayPrizeId ->
                                    set_pay_prize_status(PayPrizeId, 1),
                                    do_grow_jijin_of_buy()
                            end;
                        true ->
                            pass
                    end,
                    chongzhi_fan_diamond(PayId),
                    put(?pd_vip_buy_status, [{PayId, 0}|VipBuyStatusList]),
                    ?player_send(vip_new_sproto:pkg_msg(?MSG_VIP_NEW_QQ_PAY_CS, {get(?pd_vip), 0}))
            end;
        2 ->
            %% add tili
            case lists:keyfind(PayId, 1, VipBuyStatusList) of
                0 ->
                    pass;
                _ ->
                    player:add_value(?pd_sp, 200),
                    chongzhi_fan_diamond(PayId),
                    put(?pd_vip_buy_status, [{PayId, 0}|VipBuyStatusList]),
                    ?player_send(vip_new_sproto:pkg_msg(?MSG_VIP_NEW_QQ_PAY_CS, {get(?pd_vip), 0}))
            end
    end.



update_total_value(Count) when is_integer(Count) andalso Count > 0 ->
    up_vip_level(Count);
update_total_value(_C) ->
    pass.

set_vip_gift_one_prize_status(VipLevel) ->
    VipGiftOneList = get(?pd_vip_gift_one),
    NewVipGiftOneList = 
    case lists:keyfind(VipLevel, 1, VipGiftOneList) of
        {_, 0} ->
            lists:keyreplace(VipLevel, 1, VipGiftOneList, {VipLevel, 1});
        _ ->
            VipGiftOneList
    end,
    put(?pd_vip_gift_one, NewVipGiftOneList).

up_vip_level(Count) ->
    recharge_reward_mng:update_recharge(Count),
    open_server_happy_mng:player_pay_money_count(Count*10),
    %?DEBUG_LOG("up_vip_level--------------------------------:~p",[Count]),
    CurVipLevel = get(?pd_vip),
    %?DEBUG_LOG("CurVipLevel--------------------:~p",[CurVipLevel]),
    TotalValue = get(?pd_vip_value) + Count,
    put(?pd_vip_value, TotalValue),
    up_vip_level_(TotalValue, CurVipLevel+1).
   
up_vip_level_(TotalValue, NextVipLevel) ->
    case load_vip_new:get_vip_level_need_up_num(NextVipLevel) of
        ?none ->
            pass;
        NeedCount when TotalValue >= NeedCount ->
            put(?pd_vip, NextVipLevel),
            set_vip_gift_one_prize_status(NextVipLevel),
            up_vip_level_(TotalValue, NextVipLevel+1);
        _ ->
            pass
    end.


% update_vip_use_data(VipLevel, Bool) ->
%     %?DEBUG_LOG("VipLevel-------------------:~p",[VipLevel]),
%     %?DEBUG_LOG("VipUseData----------------------:~p",[VipUseData]),
%     NewVipUseData = 
%     case load_vip_new:get_vip_cfg_by_vip_level(VipLevel) of
%         ?none ->
%             [];
%         Cfg ->
%             case attr_new:get(?pd_vip_use_data,[]) of
%                 [] ->
%                     init_vip_use_data(VipLevel);
%                 VipUseData ->
%                     %?DEBUG_LOG("VipUseData----------------------:~p",[VipUseData]),
%                     lists:foldl(fun({Key, CurV, GoalV}, L) ->
%                         NewCurV = 
%                         if
%                             Bool =:= ?true ->
%                                 0;
%                             true ->
%                                 CurV 
%                         end,
%                         [{Key, NewCurV, length(element(Key, Cfg))} |L]
%                     end,
%                     [],
%                     VipUseData)
%             end
%     end,
%     %?DEBUG_LOG("NewVipUseData-------------------:~p",[NewVipUseData]),
%     put(?pd_vip_use_data, NewVipUseData).

init_vip_use_data(CurVipLevel) ->
    case load_vip_new:get_vip_cfg_by_vip_level(CurVipLevel) of
        ?none ->
            [];
        _Cfg ->
            % [
            %     {#vip_cfg.buy_sp, 0, length(Cfg#vip_cfg.buy_sp)},
            %     {#vip_cfg.zuan_to_jin, 0, length(Cfg#vip_cfg.zuan_to_jin)},
            %     {#vip_cfg.buy_arena, 0, length(Cfg#vip_cfg.buy_arena)},
            %     {#vip_cfg.reset_instance_times_of_difficulty, 0, length(Cfg#vip_cfg.reset_instance_times_of_difficulty)},
            %     {#vip_cfg.reset_instance_times_of_many_people, 0, length(Cfg#vip_cfg.reset_instance_times_of_many_people)},
            %     {#vip_cfg.daily_activity_1, 0, length(Cfg#vip_cfg.daily_activity_1)},
            %     {#vip_cfg.daily_activity_2, 0, length(Cfg#vip_cfg.daily_activity_2)},
            %     {#vip_cfg.daily_activity_3, 0, length(Cfg#vip_cfg.daily_activity_3)},
            %     {#vip_cfg.course_times, 0, length(Cfg#vip_cfg.course_times)},
            %     {#vip_cfg.guild_mobai_times, 0, length(Cfg#vip_cfg.guild_mobai_times)},
            %     {#vip_cfg.pata_times, 0, length(Cfg#vip_cfg.pata_times)}
            % ]
            []
    end.

every_day_give_diamond(PayId) ->
    {_ChongZhiDiamond, _GiveDiamond, EveryDayGiveDiamond} = load_pay_order:get_diamond_by_payid(PayId),
    game_res:try_give_ex([{?PL_DIAMOND, EveryDayGiveDiamond, [pay]}], ?FLOW_REASON_RECHARGE).


chizhi_add_diamond(ChongZhiDiamond, GiveDiamond) ->
    ?DEBUG_LOG("ChongZhiDiamond:~p, GiveDiamond:~p", [ChongZhiDiamond, GiveDiamond]),
    OldData = attr_new:get(?pd_diamond),
    game_res:try_give_ex([{?PL_DIAMOND, ChongZhiDiamond, [pay]}], ?FLOW_REASON_RECHARGE),
    game_res:try_give_ex([{?PL_DIAMOND, GiveDiamond, [pay]}], ?FLOW_REASON_RECHARGE),
    %% 累计充值
    update_total_value(ChongZhiDiamond),
    system_log:info_recharge_log(OldData + ChongZhiDiamond, OldData, 1000, "bendi").
    % ?ifdo(GiveVip > 0, system_log:info_player_vip_log(GiveVip)),


buy_month_card(PayId) ->    
    chongzhi_fan_diamond(PayId),
    Time = load_pay_order:get_limit_day_by_payid(PayId) * ?SECONDS_PER_DAY,
    NewTime = 
    case get(?pd_vip_month_card) of
        0 ->
            Time + com_time:now();
        T ->
            T + Time
    end,
    put(?pd_vip_is_get_month_card_prize, 1),
    put(?pd_vip_month_card, NewTime).%% todo 更新定时器的时间

chongzhi_fan_diamond(PayId) ->
    {ChongZhiDiamond, GiveDiamond, _EveryDayGiveDiamond} = load_pay_order:get_diamond_by_payid(PayId),
    _PayRmb = load_pay_order:get_diamond_by_payid(PayId),
    %?DEBUG_LOG("PayId---:~p-----ChongZhiD----:~p----GiveD---:~p",[PayId, ChongZhiDiamond, GiveDiamond]),
    chizhi_add_diamond(ChongZhiDiamond, GiveDiamond).

del_pay_prize_status(PayPrizeId) ->
    PrizeStatusList = get(?pd_vip_prize_status_list),
    case lists:keyfind(PayPrizeId, 1, PrizeStatusList) of
        ?false ->
            pass;
        _ ->
            put(?pd_vip_prize_status_list, lists:keydelete(PayPrizeId, 1, PrizeStatusList))
    end.

set_pay_prize_status(PayPrizeId, Status) ->
    PrizeStatusList = get(?pd_vip_prize_status_list),
    NewPrizeStatusList =
    case lists:keyfind(PayPrizeId, 1, PrizeStatusList) of
        ?false ->
            [{PayPrizeId, 1} | PrizeStatusList];
        {_, 1} when Status =:= 2->
            lists:keyreplace(PayPrizeId, 1, PrizeStatusList, {PayPrizeId, 2});
        _ ->
            PrizeStatusList
    end,
    put(?pd_vip_prize_status_list, NewPrizeStatusList).

send_day_and_sum_cost() ->
    {DayCostNum, _EveryDayCostList} = get(?pd_vip_every_day_cost),
    {SumCostNum, _SumCostList} = get(?pd_vip_sum_cost),
    ?player_send(vip_new_sproto:pkg_msg(?MSG_VIP_NEW_SEND_COST, {DayCostNum, SumCostNum})).


do_grow_jijin(PlayerLevel) ->
    GrowJiJinList = get(?pd_vip_grow_jijin_list),
    case lists:keyfind(PlayerLevel, 1, GrowJiJinList) of
        ?false ->
            pass;
        {_, PayPrizeId} ->
            PrizeStatusList = get(?pd_vip_prize_status_list),
            case lists:keyfind(2, 1, PrizeStatusList) of
                {_, S} when S =:= 1 orelse S =:= 2 ->
                    set_pay_prize_status(PayPrizeId, 1);
                _ ->
                    pass
            end
    end.

do_grow_jijin_of_buy() ->
    PlayerList = util:get_ten_beishu(get(?pd_level)),
    [do_grow_jijin(PlayerLevel) || PlayerLevel <- PlayerList].

do_vip_cost(Count) ->
    do_every_day_cost(Count),
    case do_sum_cost(Count) of
        ok ->
            send_day_and_sum_cost();
        _ ->
            pass
    end.


do_every_day_cost(Count) ->
    %?DEBUG_LOG("do_every_day_cost--------------------:~p",[Count]),
    {DayCostNum, EveryDayCostList} = get(?pd_vip_every_day_cost),
    %?DEBUG_LOG("EveryDayCostList--------------------:~p",[EveryDayCostList]),
    if
        EveryDayCostList =:= [] ->
            pass;
        true ->
            NewDayCostNum = DayCostNum + Count,
            {PayPrizeIdList, NewEveryDayCostList} =
            lists:foldl(fun({GoldN, PayPrizeId}, {L1,L2}) ->
                if
                    NewDayCostNum >= GoldN ->
                        {[PayPrizeId|L1], lists:delete(GoldN, L2)};
                    true ->
                        {L1, L2}
                end
            end,
            {[],EveryDayCostList},
            EveryDayCostList),
            %?DEBUG_LOG("NewDayCostNum------:~p------NewEveryDayCostList---:~p",[NewDayCostNum, NewEveryDayCostList]),
            %?DEBUG_LOG("PayPrizeIdList===----------------------------:~p",[PayPrizeIdList]),
            put(?pd_vip_every_day_cost, {NewDayCostNum, NewEveryDayCostList}),
            [set_pay_prize_status(PayPrizeId, 1) || PayPrizeId <- PayPrizeIdList],
            ok
    end.

do_sum_cost(Count) ->
    {SumCostNum, SumCostList} = get(?pd_vip_sum_cost),
    if
        SumCostNum =:= [] ->
            pass;
        true ->
            NewSumCostNum = SumCostNum + Count,
            {PayPrizeIdList, NewSumCostList} =
            lists:foldl(fun({GoldN, PayPrizeId}, {L1,L2}) ->
                if
                    NewSumCostNum >= GoldN ->
                        {[PayPrizeId|L1], lists:delete(GoldN, L2)};
                    true ->
                        {L1, L2}
                end
            end,
            {[],SumCostList},
            SumCostList),
            put(?pd_vip_sum_cost, {NewSumCostNum, NewSumCostList}),
            [set_pay_prize_status(PayPrizeId, 1) || PayPrizeId <- PayPrizeIdList],
            ok
    end.
    

handle_client({Pack, Arg}) ->
    handle_client(Pack, Arg).

handle_client(?MSG_VIP_NEW_ONE_BUY, {VipLevel}) ->
    VipBuyGiftOneList = get(?pd_vip_buy_gift_one),
    %?DEBUG_LOG("MSG_VIP_NEW_ONE_BUY---------:~p-----VipBuyGiftOneList----:~p",[VipLevel, VipBuyGiftOneList]),
    DiamondCount = load_vip_new:get_vip_buy_gift_cost_by_vip_level(VipLevel),
    case game_res:can_del([{?PL_DIAMOND, DiamondCount}]) of
        ok ->
            case lists:keyfind(VipLevel, 1, VipBuyGiftOneList) of
                ?false ->
                    ?return_err(?ERR_LOOKUP_LVL_PRIZE_CFG);
                {_, 0} ->
                    PrizeId = load_vip_new:get_vip_buy_prize_by_viplevel(VipLevel),
                    case prize:prize(PrizeId, ?FLOW_REASON_VIP_PRIZE) of
                        {error, _O} ->
                            ?return_err(?ERR_ERROR_GIVE);
                        _ ->
                            game_res:del([{?PL_DIAMOND, DiamondCount}], ?FLOW_REASON_RECHARGE),
                            put(?pd_vip_buy_gift_one, lists:keyreplace(VipLevel, 1, VipBuyGiftOneList, {VipLevel, 1})),
                            %prize:prize(PrizeId, ?FLOW_REASON_VIP_PRIZE),
                            ?player_send(vip_new_sproto:pkg_msg(?MSG_VIP_NEW_ONE_BUY, {}))
                    end;
                {_, 1} ->
                    ?return_err(?ERR_VIP_BUYED)
            end;
        {error, _O} ->
            ?return_err(?ERR_VIP_BUYED)
    end;


handle_client(?MSG_VIP_NEW_GET_PRIZE, {1, VipLevel}) ->
    %?DEBUG_LOG("MSG_VIP_NEW_GET_PRIZE------------------:~p",[VipLevel]),
    VipGiftOneList = get(?pd_vip_gift_one),
    %?DEBUG_LOG("VipGiftOneList-----------------------:~p",[VipGiftOneList]),
    case lists:keyfind(VipLevel, 1, VipGiftOneList) of
        ?false ->
            ?return_err(?ERR_LOOKUP_LVL_PRIZE_CFG);
        {_, 1} ->
            PrizeId = load_vip_new:get_vip_gift_prize_by_viplevel(VipLevel),
            case prize:prize(PrizeId, ?FLOW_REASON_VIP_PRIZE) of
                {error, _O} ->
                    ?return_err(?ERR_ERROR_GIVE);
                _ ->
                    put(?pd_vip_gift_one, lists:keyreplace(VipLevel, 1, VipGiftOneList, {VipLevel, 2})),
                    %prize:prize(PrizeId, ?FLOW_REASON_VIP_PRIZE),
                    %?DEBUG_LOG("------------------------------------------------"),
                    ?player_send(vip_new_sproto:pkg_msg(?MSG_VIP_NEW_GET_PRIZE, {}))
            end;
        {_, S} when S =:= 0; S =:= 2 ->
            ?return_err(?ERR_ERROR_GIVE)
    end;

handle_client(?MSG_VIP_NEW_GET_PRIZE, {2, VipLevel}) ->
    case get(?pd_vip_gift_every_day) of
        0 ->
            PrizeId = load_vip_new:get_vip_day_gift_prize_by_viplevel(VipLevel),
            case prize:prize(PrizeId, ?FLOW_REASON_VIP_PRIZE) of
                {error, _O} ->
                    ?return_err(?ERR_ERROR_GIVE);
                _ ->
                    put(?pd_vip_gift_every_day, 1),
                    %prize:prize(PrizeId, ?FLOW_REASON_VIP_PRIZE),
                    ?player_send(vip_new_sproto:pkg_msg(?MSG_VIP_NEW_GET_PRIZE, {}))
            end;
        1 ->
            ?return_err(?ERR_ERROR_GIVE)
    end;


handle_client(?MSG_VIP_NEW_LOCAL_BUY, {PayId}) ->
    VipBuyStatusList = get(?pd_vip_buy_status),
    case load_pay_order:get_state_num(PayId) of
        ?none ->
            ?return_err(?ERR_LOOKUP_LVL_PRIZE_CFG);
        0 -> %% 无限购买
            if
                PayId =:= 2 ->  %% 月卡
                    buy_month_card(PayId);
                true ->
                    chongzhi_fan_diamond(PayId)
            end,
            ?player_send(vip_new_sproto:pkg_msg(?MSG_VIP_NEW_LOCAL_BUY, {get(?pd_vip), 1}));
        1 -> %% 只能购买一次
            if
                PayId =:= 3 ->%% 永久卡
                    case lists:keyfind(PayId, 1, VipBuyStatusList) of
                        ?false ->
                            chongzhi_fan_diamond(PayId),
                            put(?pd_vip_yongjiu_card, 1),
                            put(?pd_vip_buy_status, [{PayId, 0}|VipBuyStatusList]),
                            put(?pd_vip_is_get_yongjiu_card_prize, 1),
                            ?player_send(vip_new_sproto:pkg_msg(?MSG_VIP_NEW_LOCAL_BUY, {get(?pd_vip), 0}));
                        _ ->
                            ?return_err(?ERR_ERROR_GIVE)
                    end;
                true -> 
                    case lists:keyfind(PayId, 1, VipBuyStatusList) of
                        ?false ->
                            if
                                PayId =:= 1; PayId =:= 4 ->
                                    case load_pay_order:get_pay_prize_id(PayId) of
                                        ?none ->
                                            pass;
                                        PayPrizeId ->
                                            set_pay_prize_status(PayPrizeId, 1),
                                            do_grow_jijin_of_buy()
                                    end;
                                true ->
                                    pass
                            end,
                            chongzhi_fan_diamond(PayId),
                            put(?pd_vip_buy_status, [{PayId, 0}|VipBuyStatusList]),
                            ?player_send(vip_new_sproto:pkg_msg(?MSG_VIP_NEW_LOCAL_BUY, {get(?pd_vip), 0}));
                        _ ->
                            ?return_err(?ERR_ERROR_GIVE)
                    end
            end;
        2 ->
            %% add tili
            case lists:keyfind(PayId, 1, VipBuyStatusList) of
                0 ->
                    ?return_err(?ERR_ERROR_GIVE);
                _ ->
                    player:add_value(?pd_sp, 200),
                    chongzhi_fan_diamond(PayId),
                    put(?pd_vip_buy_status, [{PayId, 0}|VipBuyStatusList]),
                    ?player_send(vip_new_sproto:pkg_msg(?MSG_VIP_NEW_LOCAL_BUY, {get(?pd_vip), 0}))
            end
    end;

handle_client(?MSG_VIP_NEW_GET_PAY_PRIZE, {PayPrizeId}) ->
    PrizeStatusList = get(?pd_vip_prize_status_list),
    %?DEBUG_LOG("PayPrizeId--------------------:~p",[PayPrizeId]),
    %?DEBUG_LOG("PrizeStatusList-----------------------:~p",[PrizeStatusList]),
    case lists:keyfind(PayPrizeId, 1, PrizeStatusList) of
        {_, 1} ->
            case load_pay_prize:get_cfg_by_pay_prize_id(PayPrizeId) of
                {Type, FirstPrizeId, GrowJiJinPrizeId, DayCostPrizeId, SumCostPrizeId} when Type >= 1 andalso Type =< 5->
                    FinalPrizeId = 
                    case Type of
                        1 ->%% 首冲(SDK回调)
                            FirstPrizeId;
                        2 ->%% 成长基金购买(SDK回调)
                            GrowJiJinPrizeId;
                        3 ->%% 成长基金奖励(prize表ID）（客户端请求）
                            GrowJiJinPrizeId;
                        4 ->%% 每日消费（客户端请求）
                            DayCostPrizeId;
                        5 ->%% 累计消费（客户端请求）
                            SumCostPrizeId
                    end,
                    case prize:prize(FinalPrizeId, ?FLOW_REASON_VIP_PRIZE) of
                        {error, _O} ->
                            ?return_err(?ERR_ERROR_GIVE);
                        _ ->
                            set_pay_prize_status(PayPrizeId, 2),
                            deal_first_pay_prize(PayPrizeId),
                            ?player_send(vip_new_sproto:pkg_msg(?MSG_VIP_NEW_GET_PAY_PRIZE, {}))
                    end;
                ?none ->
                    ?return_err(?ERR_LOOKUP_LVL_PRIZE_CFG)
            end;
        _ ->
            ?return_err(?ERR_ERROR_GIVE)
    end;

handle_client(?MSG_VIP_NEW_SEND_PRIZE_MONTH_YONGJIU_CARD, {2}) ->
    case get(?pd_vip_is_get_month_card_prize) of
        1 ->
            put(?pd_vip_is_get_month_card_prize, 2),
            every_day_give_diamond(2),
            ?player_send(vip_new_sproto:pkg_msg(?MSG_VIP_NEW_SEND_PRIZE_MONTH_YONGJIU_CARD, {}));
        _ ->
            ?return_err(?ERR_ERROR_GIVE)
    end;

handle_client(?MSG_VIP_NEW_SEND_PRIZE_MONTH_YONGJIU_CARD, {3}) ->
    case get(?pd_vip_is_get_yongjiu_card_prize) of
        1 ->
            put(?pd_vip_is_get_yongjiu_card_prize, 2),
            every_day_give_diamond(3),
            ?player_send(vip_new_sproto:pkg_msg(?MSG_VIP_NEW_SEND_PRIZE_MONTH_YONGJIU_CARD, {}));
        _ ->
            ?return_err(?ERR_ERROR_GIVE)
    end;

handle_client(?MSG_VIP_NEW_QQ_PAY_CS, {PayId, OpendId,Token, PayToken, AppKey, AppId, Pf, PfKey, ZoneId, CountType, Record}) ->
    VipBuyStatusList = get(?pd_vip_buy_status),
    IsCan=
    case load_pay_order:get_state_num(PayId) of
        ?none ->
            ?ERR_ERROR_ORDER_ID;
        0 -> %% 无限购买
            {?true, 1};
        1 -> %% 只能购买一次
            if
                PayId =:= 3 ->%% 永久卡
                    case lists:keyfind(PayId, 1, VipBuyStatusList) of
                        ?false ->
                            {?true,0};
                        _ ->
                            ?ERR_PAY_LIMIT
                    end;
                true -> 
                    case lists:keyfind(PayId, 1, VipBuyStatusList) of
                        ?false ->
                            {?true,0};
                        _ ->
                            ?ERR_PAY_LIMIT
                    end
            end;
        2 ->
            %% add tili
            case lists:keyfind(PayId, 1, VipBuyStatusList) of
                0 ->
                    ?ERR_ERROR_ORDER_ID;
                _ ->
                   {?true,0}
            end
    end,
    case IsCan of
        {?true,IsBuy} ->
            PayRmb = load_pay_order:get_pay_rmb_by_payid(PayId),
            qq_pay(PayRmb, PayId, OpendId, Token, PayToken, AppKey, AppId, Pf, PfKey, ZoneId, CountType,Record, IsBuy);
        Err ->
            ?return_err(Err)
    end;

handle_client(Mod, Msg) ->
    ?ERROR_LOG("no known msg Mod:~p Msg:~p", [Mod, Msg]).

handle_msg(_, ?give_first_pay_diamond) ->
    {ItemId, _Time, DiamondList} = misc_cfg:get_vip_deal_first_pay(),
    put(?pd_vip_first_pay_time, 0),
    game_res:try_give_ex([DiamondList], ?FLOW_REASON_RECHARGE),
    game_res:del([{ItemId, 1}], ?FLOW_REASON_USE_ITEM),
    ?player_send(vip_new_sproto:pkg_msg(?MSG_VIP_NEW_FIRST_PAY_TIME, {ItemId, 0}));

handle_msg(FromMod, Msg) ->
    ?ERROR_LOG("~p recv a unknown msg ~p from ~p", [?pname(), Msg, FromMod]).




deal_first_pay_prize(1) ->
    {ItemId, Time, D} = misc_cfg:get_vip_deal_first_pay(),
    NewTime = com_time:now() + Time,
    put(?pd_vip_first_pay_time, NewTime),
    tool:do_send_after(Time * ?MICOSEC_PER_SECONDS, ?mod_msg(?MODULE, ?give_first_pay_diamond),
    ?give_first_pay_diamond_timerref ),
    ?player_send(vip_new_sproto:pkg_msg(?MSG_VIP_NEW_FIRST_PAY_TIME, {ItemId, NewTime}));
deal_first_pay_prize(_P) ->
    pass.


qq_pay(PayRmb, PayId, OpendId, Token, PayToken, AppKey, AppId, Pf, PfKey, ZoneId, CountType,Record, IsBuy)->
    Payment = payment_system:qq_pay_m(get(?pd_id),
        PayRmb,% 扣费
        PayId,
        binary_to_list(AppId), binary_to_list(AppKey),
        binary_to_list(Token), binary_to_list(PayToken),
        binary_to_list(OpendId), binary_to_list(Pf),
        binary_to_list(PfKey), binary_to_list(ZoneId),
        CountType,
        Record),

    PayRet = Payment#payment_tab.pay_ret,

    if
        PayRet =:= 0 ->
            qq_pay_send_prize(PayId),
            do_cost_total_rmb(PayRmb, 2);
        PayRet =:= 1004 ->
            ?return_err(?ERR_PAY_NOT_ENOUGH);
        PayRet =:= 1018 ->
            ?return_err(?ERR_QQ_PAY_TOKEN);
        PayRet =:= 1002215 ->
            ?return_err(?ERR_QQ_PAY_HAS_ORDER);
        true ->
            ?return_err(?ERR_QQ_PAY_FAILURE)
    end.

    
    %NPayment = Payment#payment_tab{diamond_flag = 1},

    %payment_system:update_payment(NPayment).


create_mod_data(SelfId) ->
    VipUseData = init_vip_use_data(get(?pd_vip)),
    VipGiftOneList = load_vip_new:get_vip_gift_one_list(),
    VipBuyOneList = load_vip_new:get_vip_buy_one_list(),
    GrowJiJinList = load_pay_prize:init_grow_jijin(),
    EveryDayCostList = {0, load_pay_prize:init_every_day_cost_list()},
    SumCostList = {0, load_pay_prize:init_total_cost_list()},
    % ?DEBUG_LOG("EveryDayCostList--------------------------:~p",[EveryDayCostList]),
    case dbcache:insert_new(?player_vip_new_tab, #player_vip_new_tab{id = SelfId,
                    grow_jijin_list = GrowJiJinList,
                    vip_use_data = VipUseData,
                    vip_gift_one=VipGiftOneList, vip_buy_gift_one=VipBuyOneList,
                    every_day_cost_list=EveryDayCostList, sum_cost_list=SumCostList}) of
        true -> 
            ok;
        false ->
            ?ERROR_LOG("create ~p module ~p data is already_exist", [SelfId, ?MODULE])
    end.


load_mod_data(PlayerId) ->
    case dbcache:load_data(?player_vip_new_tab, PlayerId) of
        [] ->
            create_mod_data(PlayerId),
            load_mod_data(PlayerId);
        [#player_vip_new_tab{vip_value = VipValue, month_card=Mcard, yongjiu_card=YjCard, 
                            grow_jijin_card = Gjjc, grow_jijin_list = Gjjl, vip_use_data=Data, 
                            vip_buy_status=VipBuyStatusList, vip_gift_one=VipGiftOneList,
                            vip_buy_gift_one=VipBuyGiftOneList,vip_gift_every_day=Vged,
                            every_day_cost_list=Edcl, sum_cost_list=Scl, prize_status_list=Psl,
                            is_get_month_card_prize=IsGetMcp, is_get_yongjiu_card_prize=IsGetYcp,
                            cost_total_rmb=Rmb}] ->
            ?pd_new(?pd_vip_value, VipValue),
            ?pd_new(?pd_vip_month_card, Mcard),
            ?pd_new(?pd_vip_yongjiu_card, YjCard),
            ?pd_new(?pd_vip_grow_jijin_card, Gjjc),
            ?pd_new(?pd_vip_grow_jijin_list, Gjjl),
            ?pd_new(?pd_vip_use_data, Data),
            ?pd_new(?pd_vip_buy_status, VipBuyStatusList),
            ?pd_new(?pd_vip_gift_one, VipGiftOneList),
            ?pd_new(?pd_vip_buy_gift_one, VipBuyGiftOneList),
            ?pd_new(?pd_vip_gift_every_day, Vged),
            ?pd_new(?pd_vip_every_day_cost, Edcl),
            ?pd_new(?pd_vip_sum_cost, Scl),
            ?pd_new(?pd_vip_prize_status_list, Psl),
            ?pd_new(?pd_vip_is_get_month_card_prize, IsGetMcp),
            ?pd_new(?pd_vip_is_get_yongjiu_card_prize, IsGetYcp),
            ?pd_new(?pd_vip_cost_total_rmb, Rmb)
    end,
    ok.


init_client() ->
    VipLevel = get(?pd_vip),
    YongJinCard = get(?pd_vip_yongjiu_card),
    TotalValue = get(?pd_vip_value),
    CardEndTime = get(?pd_vip_month_card),
    VipBuyStatusList = get(?pd_vip_buy_status),
    VipGiftOneList = get(?pd_vip_gift_one),
    VipBuyGiftOneList = get(?pd_vip_buy_gift_one),
    Vged = get(?pd_vip_gift_every_day),
    PrizeStatusList = get(?pd_vip_prize_status_list),
    IsGetMcp = get(?pd_vip_is_get_month_card_prize),
    IsGetYcp = get(?pd_vip_is_get_yongjiu_card_prize),
    %?DEBUG_LOG("VipBuyStatusList-----------:~p",[VipBuyStatusList]),
    %?DEBUG_LOG("VipGiftOneList-----------:~p",[VipGiftOneList]),
    %?DEBUG_LOG("VipBuyGiftOneList-----------:~p",[VipBuyGiftOneList]),
    %?DEBUG_LOG("PrizeStatusList-----------:~p",[PrizeStatusList]),
    send_day_and_sum_cost(),
    ?player_send(vip_new_sproto:pkg_msg(?MSG_VIP_NEW_INFO, {
            VipLevel, YongJinCard, 
            TotalValue, CardEndTime, 
            VipBuyStatusList, VipGiftOneList,
            VipBuyGiftOneList, PrizeStatusList, Vged,
            IsGetMcp, IsGetYcp})).

view_data(Acc) -> Acc.

online() ->
    %on_day_reset(0), %% test
    {ItemId, _Time, DiamondList} = misc_cfg:get_vip_deal_first_pay(),
    BagBucket = game_res:get_bucket(?BUCKET_TYPE_BAG),      
    ReStoneNum = goods_bucket:count_item_size(BagBucket, 0, ItemId),
    VipFristPayT = get(?pd_vip_first_pay_time),
    NewT = VipFristPayT - com_time:now(),
    %?DEBUG_LOG("NewT------:~p--------VipFirstPayT------:~p",[NewT, VipFristPayT]),
    if
        VipFristPayT =:= 0 ->
            if
                ReStoneNum > 0 ->
                    game_res:del([{ItemId, 1}], ?FLOW_REASON_USE_ITEM);
                true ->
                    pass
            end;
        NewT < 0 ->
            %?DEBUG_LOG("NewT--------------------------------"),
            put(?pd_vip_first_pay_time, 0),
            game_res:try_give_ex([DiamondList], ?FLOW_REASON_RECHARGE),
            if
                ReStoneNum > 0 ->
                    game_res:del([{ItemId, 1}], ?FLOW_REASON_USE_ITEM);
                true ->
                    pass
            end,
            ?player_send(vip_new_sproto:pkg_msg(?MSG_VIP_NEW_FIRST_PAY_TIME, {ItemId, 0}));
        NewT > 0 ->  
            tool:do_send_after(NewT * ?MICOSEC_PER_SECONDS, ?mod_msg(?MODULE, ?give_first_pay_diamond),
            ?give_first_pay_diamond_timerref ),
            ?player_send(vip_new_sproto:pkg_msg(?MSG_VIP_NEW_FIRST_PAY_TIME, {ItemId, VipFristPayT}));
        true ->
           pass
    end.

offline(_PlayerId) ->
    ok.

handle_frame(_) -> ok.

save_data(PlayerId) ->
    dbcache:update(?player_vip_new_tab,
        #player_vip_new_tab{
            id = PlayerId,
            vip_level = get(?pd_vip),
            vip_value = get(?pd_vip_value),
            month_card = get(?pd_vip_month_card),
            yongjiu_card = get(?pd_vip_yongjiu_card),
            grow_jijin_card = get(?pd_vip_grow_jijin_card),
            grow_jijin_list = get(?pd_vip_grow_jijin_list),
            vip_use_data = get(?pd_vip_use_data),
            vip_buy_status = get(?pd_vip_buy_status),
            vip_gift_one = get(?pd_vip_gift_one),
            vip_buy_gift_one = get(?pd_vip_buy_gift_one),
            vip_gift_every_day = get(?pd_vip_gift_every_day),
            every_day_cost_list = get(?pd_vip_every_day_cost),
            sum_cost_list = get(?pd_vip_sum_cost),
            prize_status_list = get(?pd_vip_prize_status_list),
            is_get_month_card_prize = get(?pd_vip_is_get_month_card_prize),
            is_get_yongjiu_card_prize = get(?pd_vip_is_get_yongjiu_card_prize),
            cost_total_rmb = get(?pd_vip_cost_total_rmb)
        }).

load_db_table_meta() ->
    [
        #db_table_meta{
            name = ?player_vip_new_tab,
            fields = ?record_fields(player_vip_new_tab),
            shrink_size = 5,
            flush_interval = 1
        }
    ].
