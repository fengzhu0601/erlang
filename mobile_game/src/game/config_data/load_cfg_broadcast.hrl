%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 06. 六月 2016 下午5:54
%%%-------------------------------------------------------------------
-author("clark").


-record(broadcast_chat_cfg,
{
    id = 0,
    type,
    function_event = []
}).


-record(broadcast_condition_cfg,
{
    id = 0,
    condition_type,
    condition_event
}).


-record(broadcast_des_cfg,
{
    id,
    des
}).

%% 要发送的公告信息的id 该配置id来自于配置表broadcast.txt, broadcast_des.txt , broadcast_condition.txt
