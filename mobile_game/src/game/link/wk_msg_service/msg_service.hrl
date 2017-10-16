%%%-------------------------------------------------------------------
%%% @author hank
%%% @copyright (C) 2016, <SANTI>
%%% @doc
%%%
%%% @end
%%% Created : 31. Mar 2016 10:37 AM
%%%-------------------------------------------------------------------
-author("hank").

-define(offline_msg_tab, offline_msg_tab).


%%-record(offline_msg,{
%%  module,  % 调用的模块
%%  function, % 调用的函数
%%  argument % 调用的参数
%%}).

-record(offline_msg_tab,
{
    playerId,
    msg_list = [] % [{mod,Module,From_Module,{Function, Argument}} | ... ].
}).

