%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc    1.完成任务时触发，2.某个任务是否已经完成
%%%
%%% @end
%%% Created : 23. 七月 2015 上午1:38
%%%-------------------------------------------------------------------
-module(task_handle_client).
-include("inc.hrl").
-include("player.hrl").
-include("handle_client.hrl").

-include("load_vip_right.hrl").

handle_client({Pack, Arg}) -> handle_client(Pack, Arg).

handle_client(?MSG_TASK_ACCEPT, {TaskType, TaskProId}) ->
    task_system:accept(TaskType, TaskProId);


handle_client(?MSG_TASK_SUBMIT, {TaskType, TaskProId}) ->
    task_system:submit({TaskType, TaskProId});

handle_client(_Msg, _Arg) ->
    ok.

