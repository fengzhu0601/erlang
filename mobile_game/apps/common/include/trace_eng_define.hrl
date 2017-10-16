%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 08. 一月 2016 下午5:57
%%%-------------------------------------------------------------------
-author("clark").


%% 结点打印功能
-define(trace_msg_trace_1, trace_1).
-record(trace_data_trace_1,
{
    server_id   = 0,
    time        = 0,
    file        = "",
    line        = 0,
    lvl         = 0,
    ip          = 0,
    context     = {}
}).
-record(trace_data_trace_1_ex,
{
    server_id   = 0,
    time        = 0,
    file        = "",
    line        = 0,
    lvl         = 0,
    f           = "",
    ip          = 0,
    m           = {}
}).
