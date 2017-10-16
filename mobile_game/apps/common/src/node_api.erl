%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 09. 一月 2016 上午11:04
%%%-------------------------------------------------------------------
-module(node_api).
-author("clark").

%% API
-export
([
    cast/3
    , cast_ex/4
    , call/4
    , call/3
]).


-export
([
    on_cast/1
    , on_call/1
]).



cast(NodeName, ProcessName, Msg) ->
%%     io:format("-----------------------111 cast ~p~n",[{NodeName, ProcessName, Msg}]),
    rpc:cast(NodeName, ?MODULE, on_cast, [{ProcessName, Msg}]).

cast_ex(NodeName, ProcessName, MsgID, MsgData) ->
%%     io:format("-----------------------222 cast_ex ~p~n",[{NodeName, ProcessName, MsgID, MsgData}]),
    rpc:cast(NodeName, ?MODULE, on_cast, [{ProcessName, {MsgID, MsgData}}]).

call(NodeName, ProcessName, MsgID, MsgData) ->
    rpc:call(NodeName, ?MODULE, on_call, [{ProcessName, MsgID, MsgData}]).

call(NodeName, ProcessName, MsgData) ->
    rpc:call(NodeName, ?MODULE, on_call, [{ProcessName, MsgData}]).





on_cast({ProcessName, Msg}) ->
    % io:format("-----------------------node_api 1 on_cast ~p~n",[{ProcessName, Msg}]),
    ProcessName!Msg.





on_call({ProcessName, MsgID, MsgData}) ->
    Ret =
        gen_server:call
        (
            ProcessName,
            {
                MsgID,
                MsgData
            }
        ),
%%     io:format("on_call 1 ~p~n",[{ProcessName, MsgID}]),
    Ret;

on_call({ProcessName, MsgData}) ->
    Ret =
        gen_server:call
        (
            ProcessName,
            MsgData
        ),
%%     io:format("on_call 2 ~p~n",[Ret]),
    Ret.