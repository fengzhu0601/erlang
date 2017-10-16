%%%-------------------------------------------------------------------
%%% @author hank
%%% @copyright (C) 2016, <SANTI>
%%% @doc
%%%
%%% @end
%%% Created : 18. Apr 2016 10:23 AM
%%%-------------------------------------------------------------------
-author("hank").


-record(payment_tab,
{
    billno,
    pay_num,
    time,
    player_id,
    status = 0,         % 0 请求 1 操作成功
    diamond_flag = 0,   % 0 是没有给钻石 1 是已经给了

    refId = 0,          % 是支付那个配置id-> pay.txt 

    %调用返回消息
    pay_ret,
    pay_code,
    pay_msg
}).


%% 与角色相关的支付数据,
-record(player_payment_tab,
{
    id,
    val = gb_trees:empty()
}).

-define(PAYMENT_ORDER_STATE_SUCCESS, 1).   %% 成功订单
-define(PAYMENT_ORDER_STATE_FAILURE, 0).   
-define(PAYMENT_ORDER_STATE_PROCESS, 2).
-define(PAYMENT_ORDER_STATE_COST_ERROR, 3).%% 订单还没成功，延迟
-define(PAYMENT_ORDER_STATE_EXCEPTION, 4).%% 订单异常