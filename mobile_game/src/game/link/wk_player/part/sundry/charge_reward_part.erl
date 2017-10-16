%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 31. 七月 2015 下午8:55
%%%-------------------------------------------------------------------
-module(charge_reward_part).
-author("clark").

%% API
% -export([give_growup_prize/2]).

% -include("inc.hrl").
% -include_lib("common/include/inc.hrl").
% -include("player.hrl").
% -include("handle_client.hrl").
% -include("load_pay_prize.hrl").
% -include("load_day_login_prize.hrl").
% -include("player_data_db.hrl").
% -include("item_bucket.hrl").
% -include("day_reset.hrl").
% -include("payment.hrl").
% -include("system_log.hrl").

% %% 日重置
% on_day_reset(_SelfId) ->
%     %% 下发消费奖励
%     load_pay_prize:init_day_cost_prize_state(),
%     put(?pd_day_total_consume, 0),
%     DayTotalConsume = 0,
%     TotalConsume = get(?pd_total_consume),
%     ?player_send(charge_reward_sproto:pkg_msg(?MSG_CHARGE_INFO_SC, {DayTotalConsume, TotalConsume})),
%     ok.


% handle_client({Pack, Arg}) ->
%     handle_client(Pack, Arg).

% %% 请求领取奖励
% handle_client(?MSG_CHARGE_REWARD_CS, {Index}) ->
%     Cfg = load_pay_prize:lookup_pay_prize_cfg(Index),
%     case Cfg of
%         #pay_prize_cfg{state_id = StateId,
%             type = RecordType,
%             first_prize = FirstPriz,
%             grow_up_price = _GrowUpPrice,
%             grow_up_prize = GrowUpPrize,
%             grow_up_lvl = GrowUpLvl,
%             day_cost = DayCost,
%             day_prize = DayPrize,
%             total_cost = TotalCost,
%             total_prize = TotalPrize
%         } ->
%             ?ERROR_LOG("?MSG_CHARGE_REWARD_CS 1 ~p ", [[StateId]]),
%             StateVal = attr_new:get_sink_state(StateId),
%             case RecordType of
%                 1 ->
%                     %% 首冲(SDK回调)
%                     TotalConsume = get(?pd_total_consume),
%                     if
%                         StateVal =< 0 andalso TotalConsume > 0 ->
%                             attr_new:set_sink_state(StateId, 1),
%                             prize:prize(FirstPriz, ?FLOW_REASON_RECHARGE),
%                             ?player_send(charge_reward_sproto:pkg_msg(?MSG_CHARGE_REWARD_CS, {}));
%                         true ->
%                             ?return_err(?ERR_ERROR_GIVE)
%                     end;
%                 2 ->
%                     %% 成长基金购买(SDK回调)
%                     if
%                         StateVal =< 0 ->
%                             attr_new:set_sink_state(StateId, 1),
%                             %% 奖励ID去给金钱或者物品
%                             prize:prize(GrowUpPrize, ?FLOW_REASON_RECHARGE),
%                             ?player_send(charge_reward_sproto:pkg_msg(?MSG_CHARGE_REWARD_CS, {}));
%                         true ->
%                             ?return_err(?ERR_ERROR_GIVE)
%                     end;
%                 3 ->
%                     %% 成长基金奖励(prize表ID）（客户端请求）
%                     Level = get(?pd_level),
%                     if
%                         StateVal =< 0 andalso Level >= GrowUpLvl ->
%                             attr_new:set_sink_state(StateId, 1),
%                             prize:prize(GrowUpPrize, ?FLOW_REASON_RECHARGE),
%                             ?player_send(charge_reward_sproto:pkg_msg(?MSG_CHARGE_REWARD_CS, {}));
%                         true ->
%                             ?return_err(?ERR_ERROR_GIVE)
%                     end;
%                 4 ->
%                     %% 每日消费（客户端请求）
%                     DayTotalConsume = get(?pd_day_total_consume),
%                     if
%                         StateVal =< 0 andalso DayTotalConsume >= DayCost ->
%                             attr_new:set_sink_state(StateId, 1),
%                             prize:prize(DayPrize, ?FLOW_REASON_RECHARGE),
%                             ?player_send(charge_reward_sproto:pkg_msg(?MSG_CHARGE_REWARD_CS, {}));
%                         true ->
%                             ?return_err(?ERR_ERROR_GIVE)
%                     end;
%                 5 ->
%                     %% 累计消费（客户端请求）
%                     TotalConsume = get(?pd_total_consume),
%                     if
%                         StateVal =< 0 andalso TotalConsume >= TotalCost ->
%                             attr_new:set_sink_state(StateId, 1),
%                             prize:prize(TotalPrize, ?FLOW_REASON_RECHARGE),
%                             ?player_send(charge_reward_sproto:pkg_msg(?MSG_CHARGE_REWARD_CS, {}));
%                         true ->
%                             ?return_err(?ERR_ERROR_GIVE)
%                     end;
%                 _ ->
%                     ?return_err(?ERR_ERROR_GIVE)
%             end;
%         _ ->
%             ?return_err(?ERR_ERROR_ORDER_ID)
%     end;


% % 充值处理
% handle_client(?MSG_CHARGE_REWARD_QQ_CS, {Index, OpendId,
%     Token, PayToken, AppKey, AppId, Pf, PfKey, ZoneId
%     , CountType, Record}) ->
%     Cfg = load_pay_prize:lookup_pay_prize_cfg(Index),
%     case Cfg of
%         #pay_prize_cfg{state_id = StateId,
%             type = RecordType,
%             first_prize = _FirstPriz,
%             grow_up_price = GrowUpPrice,
%             grow_up_prize = GrowUpPrize,
%             grow_up_lvl = _GrowUpLvl,
%             day_cost = _DayCost,
%             day_prize = _DayPrize,
%             total_cost = _TotalCost,
%             total_prize = _TotalPrize
%         } ->
%             ?ERROR_LOG("?MSG_CHARGE_REWARD_CS 1 ~p ", [[StateId]]),
%             StateVal = attr_new:get_sink_state(StateId),
%             case RecordType of
%                 2 ->
%                     %% 成长基金购买(SDK回调)
%                     if
%                         StateVal =< 0 ->
%                             Payment = payment_system:qq_pay_m(get(?pd_id),
%                                 GrowUpPrice,% 扣费1
%                                 -Index,   % 成长基金id是负
%                                 binary_to_list(AppId), binary_to_list(AppKey),
%                                 binary_to_list(Token), binary_to_list(PayToken),
%                                 binary_to_list(OpendId), binary_to_list(Pf),
%                                 binary_to_list(PfKey), binary_to_list(ZoneId),
%                                 CountType,
%                                 Record),

%                             PayRet = Payment#payment_tab.pay_ret,

%                             if
%                                 PayRet =:= 0 ->
%                                     ok;
%                                 PayRet =:= 1004 ->
%                                     ?return_err(?ERR_PAY_NOT_ENOUGH);
%                                 PayRet =:= 1018 ->
%                                     ?return_err(?ERR_QQ_PAY_TOKEN);
%                                 PayRet =:= 1002215 ->
%                                     ?return_err(?ERR_QQ_PAY_HAS_ORDER);
%                                 true ->
%                                     ?return_err(?ERR_QQ_PAY_FAILURE)
%                             end,

%                             give_growup_prize({StateId, GrowUpPrize}),

%                             NPayment = Payment#payment_tab{diamond_flag = 1},

%                             payment_system:update_payment(NPayment),

%                             ?player_send(charge_reward_sproto:pkg_msg(?MSG_CHARGE_REWARD_CS, {}));
%                         true ->
%                             ?return_err(?ERR_PAY_LIMIT)
%                     end;
%                 _ ->
%                     ?return_err(?ERR_ERROR_GIVE)
%             end;
%         _ ->
%             ?return_err(?ERR_ERROR_ORDER_ID)
%     end.

% give_growup_prize(Index, BillNo) ->
%     Cfg = load_pay_prize:lookup_pay_prize_cfg(Index),
%     case Cfg of
%         #pay_prize_cfg{state_id = StateId,
%             type = _RecordType,
%             first_prize = _RecordTypeFirstPriz,
%             grow_up_price = _GrowUpPrice,
%             grow_up_prize = GrowUpPrize,
%             grow_up_lvl = _GrowUpLvl,
%             day_cost = _DayCost,
%             day_prize = _DayPrize,
%             total_cost = _TotalCost,
%             total_prize = _TotalPrize
%         } ->

%             [Payment] = payment_system:lookup_payment(BillNo),
%             give_growup_prize({StateId, GrowUpPrize}),
%             NPayment = Payment#payment_tab{diamond_flag = 1},
%             payment_system:update_payment(NPayment);
%         _ ->
%             ok
%     end,
%     ok.

% give_growup_prize({StateId, GrowUpPrize}) ->
%     pay_goods_part:first_pay(), % 首冲

%     attr_new:set_sink_state(StateId, 1),
%     %% 奖励ID去给金钱或者物品
%     prize:prize(GrowUpPrize, ?FLOW_REASON_RECHARGE),
%     ok.

