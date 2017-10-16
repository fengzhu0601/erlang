%%%-------------------------------------------------------------------
%%% @author hank
%%% @copyright (C) 2016, <SANTI>
%%% @doc  支付系统
%%%
%%% @end
%%% Created : 18. Apr 2016 10:18 AM
%%%-------------------------------------------------------------------
-module(payment_system).
-author("hank").


-include("inc.hrl").
-include("player.hrl").
-include("payment.hrl").

-define(QQ_PAY_BALANCE_URL, "http://115.159.144.222/get_qq_balance_m.php").

-define(QQ_PAY_URL, "http://115.159.144.222/qq_pay_m.php").

%% API
-export([
    create_payment/3,
    lookup_payment/1,
    update_payment/1,
    qq_pay_m/13,
    check_qq_pay/11]).

%
create_payment(PlayerId, PayNum, RefId) ->
    Record = #payment_tab{
    billno = create_payment_id(erlang:get(?pd_server_id),gen_id:next_id(payment_tab)),
    pay_num = PayNum,
    player_id = PlayerId,
    refId = RefId,
    time = com_time:now(),
    status = -2},
    dbcache:insert_new(payment_tab, Record),
    %?INFO_LOG("add record:~p", [Record]),
    Record.

create_payment_id(ServerId, GenId) ->
    ServerId * 10000000 + GenId.


% 返回是一个list
lookup_payment(Billno) ->
    dbcache:lookup(payment_tab, Billno).

update_payment(Payment) ->
    dbcache:update(payment_tab, Payment).


%% 扣除qq费用
qq_pay_m(PlayerId, PayNum, RefId,Appid, AppKey, Token, PayToken,Openid, Pf, PfKey, Zoneid,CountType, Record) ->
    %%    Appid = "100703379",
    %%    AppKey = "4578e54fb3a1bd18e0681bc1c734514e",
    %%    AccessToken = "977B5EA1393844F3F7D718394BEFF3FF",
    %%    Openid = "0436D81315D5A58138FC861CEEB51CA8",
    %%    Pf = "0436D81315D5A58138FC861CEEB51CA8",
    %%    PfKey = "0436D81315D5A58138FC861CEEB51CA8",
    %%    Zoneid = "1",
    %%    Ts = com_time:timestamp_sec(),

    Payment = create_payment(PlayerId, PayNum, RefId),

    Billno = Payment#payment_tab.billno,

    AccountType = 
    if
        CountType =:= 2 ->
            "wx";
        true -> 
            "qq"
    end,

    put(pd_pay_account_type,AccountType),

    Order = 
    if
        Record =:= 1 ->
            player_data_db:push_payment_order(Billno, PayNum, ?PAYMENT_ORDER_STATE_FAILURE);
        true -> 
            ok
    end,

    {Payret, Paycode, Paymsg} = check_qq_pay(Billno, PayNum, Appid, AppKey, Token, PayToken,Openid, Pf, PfKey, Zoneid,AccountType),

    % ret 0 suc
    % ret 1018 token校验失败
    % ret 1002215 订单存在
    % ret 1004 余额不足

    if
        Payret =:= 0 ->
            if
                Record =:= 1 ->
                    player_data_db:update_order(Order, ?PAYMENT_ORDER_STATE_SUCCESS);
                true ->
                    player_data_db:push_payment_order(Billno, PayNum, ?PAYMENT_ORDER_STATE_SUCCESS)
            end;
        true ->
            if
                Record =:= 1 ->
                    payment_confirm:send_payment_confirm(PlayerId,{Billno, PayNum, Appid, AppKey, Token, PayToken,Openid, Pf, PfKey, Zoneid,AccountType, 60}), % 60次 一次间隔20秒
                    player_data_db:update_order(Order, ?PAYMENT_ORDER_STATE_COST_ERROR);
                true ->
                    ok
            end
    end,

    NPayment = Payment#payment_tab{pay_ret = Payret,pay_code = Paycode, pay_msg = Paymsg, status = Payret},

    update_payment(NPayment),

    ?INFO_LOG("update payment:~p", [NPayment]),

    NPayment.

check_qq_pay(Billno, PayNum, Appid, AppKey, Token, PayToken,Openid, Pf, PfKey, Zoneid,AccountType) ->

    #{id := ServerId, logsrv_node_name := _LogSrvNodeName} = global_data:get_server_info(),
    CostPayNum = round(PayNum / 10),

    Para = "?appkey=" ++ AppKey ++ "&appid="
        ++ Appid ++ "&token=" ++ Token ++ "&amt=" ++ integer_to_list(CostPayNum) ++
        "&pay_token=" ++ PayToken ++ "&openid=" ++ Openid ++ "&pf="
        ++ Pf ++ "&pfkey=" ++ PfKey ++ "&zoneid=" ++ Zoneid ++ "&billno=" ++ integer_to_list(Billno)
        ++ "&account=" ++ AccountType ++ "&serverid=" ++ integer_to_list(ServerId),

    BALANCE_URL = ?QQ_PAY_BALANCE_URL ++ Para,

    BRet = auth_qq:http_get(BALANCE_URL),

    ?INFO_LOG("url:~p,ret:~p,", [BALANCE_URL, rfc4627:decode(BRet)]),

    URL = ?QQ_PAY_URL ++ Para,

    Ret = auth_qq:http_get(URL),
    ?INFO_LOG("url:~p ", [URL]),
    Result =
        case rfc4627:decode(Ret) of
            {ok, Json, _} -> Json;
            _ ->
                {ok, Json2, _} = rfc4627:decode(<<"{}">>),
                Json2
        end,


    Payret = get_json_field(Result, "ret", -1),
    Paycode = get_json_field(Result, "err_code", ""),
    Paymsg = get_json_field(Result, "msg", ""),

    ?INFO_LOG("pay json:~p", [Payret]),
    {Payret, Paycode, Paymsg}.


get_json_field(Json, Field, Def) ->
    case rfc4627:get_field(Json, Field) of
        {ok, Value} ->
            Value;
        _ -> 
            Def
    end.


