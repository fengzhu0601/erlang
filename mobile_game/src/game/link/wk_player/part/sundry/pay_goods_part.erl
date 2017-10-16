%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%% 处理玩家杂项的请求
%%% @end
%%% Created : 26. 六月 2015 上午2:51
%%%-------------------------------------------------------------------
-module(pay_goods_part).
-author("clark").

%% API
% -export([
%     %sync_vip_data/0,
%     first_pay/0
%     %give_diamond_card/2
% ]).

% -include("inc.hrl").
% -include_lib("common/include/inc.hrl").
% -include("player.hrl").
% -include("handle_client.hrl").
% -include("load_pay_order.hrl").
% -include("load_vip_right.hrl").
% -include("item_bucket.hrl").
% -include("day_reset.hrl").
% -include("load_pay_prize.hrl").
% -include("payment.hrl").
% -include("item_new.hrl").
% -include("system_log.hrl").

% -define(DAY_TIMES, 30 * 3600 * 24).


% %% 日重置
% on_day_reset(_SelfId) ->
    %% 公会日刷新
%     util:set_pd_field(?pd_guild_boss_donate, 0),

%     %% 卡VIP
%     CurTime = com_time:now(),
%     {CurDay, _} = calendar:seconds_to_daystime(CurTime),
%     %% 0级VIP日期限制天期会永远是30天
%     CurCardVip = get(?pd_card_vip),
%     if
%         CurCardVip =:= 0 ->
%             put(?pd_card_vip_end_tm, CurTime + ?DAY_TIMES);
%         true ->
%             ok
%     end,
%     %% 过期卡VIP掉级
%     CardVipEndTm = get(?pd_card_vip_end_tm),
% %%    ?ERROR_LOG("CardVipEnd ~p ~p ", [CardVipEndTm,CurTime]),
%     if
%         CurTime > CardVipEndTm ->
%             put(?pd_card_vip, 0);
%         true ->
%             ok
%     end,
%     %% 卡VIP每日返回
%     GiveTm = get(?pd_card_vip_give_tm),
%     EndTm = get(?pd_card_vip_end_tm),
% %%     ?ERROR_LOG("on_day_reset vip1 ~p ", [{CurTime, GiveTm, EndTm}]),
%     {GiveDay, _} = calendar:seconds_to_daystime(GiveTm),
%     {EndDay, _} = calendar:seconds_to_daystime(EndTm),
% %%    ?ERROR_LOG("on_day_reset vip ~p ", [{CurDay, GiveDay, EndDay}]),
%     Coditions = [
%         player_util:fun_is_more_and_no_negative(EndDay, CurDay),
%         player_util:fun_is_more_and_no_negative(CurDay, GiveDay + 1)
%     ],
% %%    ?ERROR_LOG("Coditions ~p ", [util:can(Coditions)]),
%     case util:can(Coditions) of
%         true ->
%             NewCardVip = get(?pd_card_vip),
% %%            ?ERROR_LOG("give number: ~p ", [load_pay_order:get_day_return_diamond(NewCardVip) ]),
%             case load_pay_order:get_day_return_diamond(NewCardVip) of
%                 0 -> ok;
%                 CardDiamond ->
%                     game_res:try_give_ex([{?PL_DIAMOND, CardDiamond}], ?FLOW_REASON_VIP_PRIZE)
%             end;
%         _ ->
%             ok
%     end,
    % ok.


% handle_client({Pack, Arg}) ->
%     handle_client(Pack, Arg).



% handle_client(Mod, Msg) ->
%     ?ERROR_LOG("no known msg Mod:~p Msg:~p", [Mod, Msg]).
%% 订单
%% 凭人民币 1：10 加钻石(凭钻石升级VIP) 加绑定钻石
% handle_client(?MSG_PAY_CS, {Index}) ->
%     Cfg = load_pay_order:lookup_pay_order_cfg(Index),
%     ?DEBUG_LOG("vip config-----:~p, level------:~p", [Cfg, Index]),
%     case Cfg of
%         #pay_order_cfg{
%             id = _Id,
%             pay_rmb = PayRmb,
%             give_vip = GiveVip,
%             give_card_vip = GiveCardVip,
%             give_diamond = GiveDiamond,
%             give_bind_diamond = GiveBindDiamond,
%             give_day_bind_diamond = _GiveDayBindDiamond,
%             limit_day = _LimitDay,
%             state_id = StateId,
%             order_type = _OrderType} ->
%             %% 是否已关闭请求
%             StateVal = 
%             if
%                StateId =:= 0 ->
%                    0;
%                true ->
%                    attr_new:get_sink_state(StateId)
%             end,
%             %?INFO_LOG("payrmb:~p", [_PayRmb]),
%             case StateVal of
%                 0 ->
%                     %% 日志
%                     player_data_db:pushback_order(PayRmb, 1),
%                     %% 有状态ID的关闭的关闭请求
%                     first_pay(), % 首冲
%                     if
%                         StateId =/= 0 ->
%                             attr_new:set_sink_state(StateId, 1);
%                         true ->
%                             ok
%                     end,
%                     %% 永久VIP
%                     CurVip = get(?pd_vip),
%                     if
%                         CurVip < GiveVip ->
%                             put(?pd_vip, GiveVip);
%                         true ->
%                             ok
%                     end,
%                     %% 卡VIP
%                     CurCardVip = get(?pd_card_vip),
%                     CurVipEndTm = get(?pd_card_vip_end_tm),
%                     if
%                         CurCardVip < GiveCardVip ->
%                             %% 低级则升级
%                             %% 0级VIP的限制天期会永远是30天,其它等级则用多少剩多少
%                             put(?pd_card_vip, GiveCardVip);
%                         CurCardVip == GiveCardVip andalso CurCardVip =/= 0 ->
%                             %% 同级则加时限
%                             TCurTime = com_time:now(),
%                             %% 开始时间 = max（结束时间， 当前时间）
%                             StartTm = erlang:max(TCurTime, CurVipEndTm),
%                             %?ERROR_LOG("player ~p can not find data ~p mode", [TCurTime, CurVipEndTm]),
%                             put(?pd_card_vip_end_tm, StartTm + ?DAY_TIMES);
%                         true ->
%                             ok
%                     end,
%                     %% 充钻石
%                     OldData = attr_new:get(?pd_diamond),
%                     game_res:try_give_ex([{?PL_DIAMOND, GiveBindDiamond, [pay]}], ?FLOW_REASON_RECHARGE),
%                     game_res:try_give_ex([{?PL_DIAMOND, GiveDiamond, [pay]}], ?FLOW_REASON_RECHARGE),
%                     NewData = attr_new:get(?pd_diamond),
%                     %% 累计充值
%                     recharge_reward_mng:update_recharge(GiveDiamond),

%                     system_log:info_recharge_log(NewData, OldData, 1000, "bendi",""),
%                     ?ifdo(GiveVip > 0, system_log:info_player_vip_log(GiveVip)),
%                     %game_res:try_give_ex([{?PL_DIAMOND, GiveBindDiamond}]),
%                     sync_vip_data(),
%                     ?player_send(vip_sproto:pkg_msg(?MSG_PAY_CS, {}));
%                 _ ->
%                     ?return_err(?ERR_PAY_LIMIT)
%             end;
%         _ ->
%             ?return_err(?ERR_ERROR_ORDER_ID)
%     end,
%     ok;

% handle_client(?MSG_QQ_PAY_CS, {Index, OpendId,Token, PayToken, AppKey, AppId, Pf, PfKey, ZoneId, CountType, Record}) ->
%     Cfg = load_pay_order:lookup_pay_order_cfg(Index),
%     case Cfg of
%         #pay_order_cfg{
%             id = _Id,
%             pay_rmb = PayRmb,
%             give_vip = GiveVip,
%             give_card_vip = GiveCardVip,
%             give_diamond = GiveDiamond,
%             give_bind_diamond = GiveBindDiamond,
%             give_day_bind_diamond = _GiveDayBindDiamond,
%             limit_day = _LimitDay,
%             state_id = StateId,
%             state_num = StateNum,
%             order_type = _OrderType} ->
%             %% 是否已关闭请求

%             StateVal = 
%             if
%                StateId =:= 0 ->
%                    0;
%                true ->
%                    if
%                        StateNum =:= 0 ->
%                            attr_new:get_sink_state(StateId);
%                        true ->
%                            Num = player_payment:lookup_player_payment(get(?pd_id), StateId, 0),
%                            if
%                                StateNum - Num > 0 ->
%                                    0;
%                                true ->
%                                    1
%                            end
%                    end
%             end,
%             case StateVal of
%                 0 ->

%                     Payment = payment_system:qq_pay_m(get(?pd_id),
%                         PayRmb,% 扣费
%                         Index,
%                         binary_to_list(AppId), binary_to_list(AppKey),
%                         binary_to_list(Token), binary_to_list(PayToken),
%                         binary_to_list(OpendId), binary_to_list(Pf),
%                         binary_to_list(PfKey), binary_to_list(ZoneId),
%                         CountType,
%                         Record),

%                     PayRet = Payment#payment_tab.pay_ret,

%                     if
%                         PayRet =:= 0 ->
%                             ok;
%                         PayRet =:= 1004 ->
%                             ?return_err(?ERR_PAY_NOT_ENOUGH);
%                         PayRet =:= 1018 ->
%                             ?return_err(?ERR_QQ_PAY_TOKEN);
%                         PayRet =:= 1002215 ->
%                             ?return_err(?ERR_QQ_PAY_HAS_ORDER);
%                         true ->
%                             ?return_err(?ERR_QQ_PAY_FAILURE)
%                     end,

%                     give_diamond_card(Payment#payment_tab.billno, StateId, StateNum, GiveVip, GiveCardVip, GiveDiamond, GiveBindDiamond),
                    
%                     NPayment = Payment#payment_tab{diamond_flag = 1},

%                     payment_system:update_payment(NPayment),
%                     ?player_send(vip_sproto:pkg_msg(?MSG_QQ_PAY_CS, {}));
%                 _ ->
%                     ?return_err(?ERR_PAY_LIMIT)
%             end;
%         _ ->
%             ?return_err(?ERR_ERROR_ORDER_ID)
%     end,
%     ok;

%% 请求领取奖励
% handle_client(?MSG_VIP_REWARD_CS, {VipLevel}) ->
%     ?DEBUG_LOG("handle_client ~p ", [VipLevel]),
%     Vip = attr_new:get_vip_lvl(),
%     if
%         Vip >= VipLevel ->
%             Cfg = load_vip_right:lookup_vip_right_cfg(VipLevel),
%             case Cfg of
%                 #vip_right_cfg{vip_prize_id = PrizeId, state_id = StateID} ->
%                     StateVal = attr_new:get_sink_state(StateID),
%                     if
%                         StateVal =< 0 ->
%                             prize:prize(PrizeId, ?FLOW_REASON_VIP_PRIZE),
%                             attr_new:set_sink_state(StateID, 1),
%                             ?player_send(vip_sproto:pkg_msg(?MSG_VIP_REWARD_CS, {}));
%                         true ->
%                             ?return_err(?ERR_ERROR_GIVE)
%                     end;
%                 _ ->
%                     ?return_err(?ERR_ERROR_GIVE)
%             end;
%         true ->
%             ?return_err(?ERR_ERROR_GIVE)
%     end;


% %% 请求订单记录
% handle_client(?MSG_GET_RECORDS_CS, {}) ->
%     ?player_send(vip_sproto:pkg_msg(?MSG_GET_RECORDS_CS, {player_data_db:get_pay_order_list()}));


% %% 请求删除订单
% handle_client(?MSG_DELETE_RECORD_CS, {Index}) ->
%     player_data_db:del_pay_order_list(Index),
%     ?player_send(vip_sproto:pkg_msg(?MSG_DELETE_RECORD_CS, {})).


% %% 下发VIP相关数据
% sync_vip_data() ->
%     TVip = get(?pd_vip),
%     TCardVip = get(?pd_card_vip),
%     TDiamond = get(?pd_diamond),
%     TBindDiamond = 0,
%     TCardVipEndTm = get(?pd_card_vip_end_tm),
%     ?player_send(vip_sproto:pkg_msg(?MSG_VIP_INFO_SC, {TVip, TCardVip, TDiamond, TBindDiamond, TCardVipEndTm})).

-define(FIRST_PAY_ID, 1).



% give_diamond_card(Index, Billno) ->
%     Cfg = load_pay_order:lookup_pay_order_cfg(Index),
%     case Cfg of
%         #pay_order_cfg{
%             id = _Id,
%             pay_rmb = _PayRmb,
%             give_vip = GiveVip,
%             give_card_vip = GiveCardVip,
%             give_diamond = GiveDiamond,
%             give_bind_diamond = GiveBindDiamond,
%             give_day_bind_diamond = _GiveDayBindDiamond,
%             limit_day = _LimitDay,
%             state_id = StateId,
%             state_num = StateNum,
%             order_type = _OrderType} ->

%             [Payment] = payment_system:lookup_payment(Billno),

%             give_diamond_card(Billno, StateId, StateNum, GiveVip
%                 , GiveCardVip, GiveDiamond, GiveBindDiamond),
%             NPayment = Payment#payment_tab{diamond_flag = 1},

%             payment_system:update_payment(NPayment);
%         _ ->
%             ok
%     end,
%     ok.

%% 钻石卡的处理
% give_diamond_card(Billno, StateId, StateNum, GiveVip
%         , GiveCardVip, GiveDiamond, GiveBindDiamond) ->
%     first_pay(), % 首冲
%     %% 日志 移到 充值内部
%     %% 有状态ID的关闭的关闭请求
%     if
%         StateId =/= 0 ->
%             if
%                 StateNum =:= 0 ->
%                     attr_new:set_sink_state(StateId, 1);
%                 true ->
%                     Num1 = player_payment:lookup_player_payment(get(?pd_id), StateId, 0),
%                     ?ifdo(Num1 + 1 >= StateNum, attr_new:get_sink_state(StateId)),
%                     player_payment:set_player_payment(get(?pd_id), StateId, Num1 + 1)
%             end;
% %%                            attr_new:set_sink_state(StateId, 1);
%         true ->
%             ok
%     end,
%     %% 永久VIP
%     CurVip = get(?pd_vip),
%     if
%         CurVip < GiveVip ->
%             put(?pd_vip, GiveVip);
%         true ->
%             ok
%     end,
%     %% 卡VIP
%     CurCardVip = get(?pd_card_vip),
%     CurVipEndTm = get(?pd_card_vip_end_tm),
%     if
%         CurCardVip < GiveCardVip ->
%             %% 低级则升级
%             %% 0级VIP的限制天期会永远是30天,其它等级则用多少剩多少
%             put(?pd_card_vip, GiveCardVip);
%         CurCardVip == GiveCardVip andalso CurCardVip =/= 0 ->
%             %% 同级则加时限
%             TCurTime = com_time:now(),
%             %% 开始时间 = max（结束时间， 当前时间）
%             StartTm = erlang:max(TCurTime, CurVipEndTm),
%             ?ERROR_LOG("player ~p can not find data ~p mode", [TCurTime, CurVipEndTm]),
%             put(?pd_card_vip_end_tm, StartTm + ?DAY_TIMES);
%         true ->
%             ok
%     end,
%     %% 充钻石
%     AccoutType = case get(pd_pay_account_type) of
%                      undefined -> "qq";
%                      AT -> AT
%                  end,
%     OldData = attr_new:get(?pd_diamond),
%     game_res:try_give_ex([{?PL_DIAMOND, GiveDiamond, [pay]}], ?FLOW_REASON_DIAMOND_CARD),
%     game_res:try_give_ex([{?PL_DIAMOND, GiveBindDiamond, [pay]}], ?FLOW_REASON_DIAMOND_CARD),
%     NewData = attr_new:get(?pd_diamond),
%     SGiveVip = case GiveVip of
%                    0 -> "";
%                    _ -> "VIP" ++ integer_to_list(GiveVip)
%                end,
%     system_log:info_recharge_log(NewData, OldData, Billno, AccoutType, SGiveVip),
%     ?ifdo(GiveVip > 0, system_log:info_player_vip_log(GiveVip)),
%     sync_vip_data(),
%     ok.

%% 首冲礼包奖励发放
% first_pay() ->
%     Cfg = load_pay_prize:lookup_pay_prize_cfg(?FIRST_PAY_ID),
%     case Cfg of
%         #pay_prize_cfg{state_id = StateId,type = RecordType,first_prize = FirstPriz} ->
%             StateVal = attr_new:get_sink_state(StateId),
%             case RecordType of
%                 1 ->
%                     if
%                         StateVal =< 0 ->
%                             attr_new:set_sink_state(StateId, 1),
%                             prize:prize_mail(FirstPriz, ?S_MAIL_FIRST_PAY_PRIZE, ?FLOW_REASON_RECHARGE);
%                         true ->
%                             ok
%                     end;
%                 true ->
%                     ok
%             end;
%         _ ->
%             pass
%     end.


