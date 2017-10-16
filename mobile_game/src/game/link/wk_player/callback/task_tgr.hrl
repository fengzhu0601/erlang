%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 21. 七月 2015 上午10:30
%%%-------------------------------------------------------------------
-author("clark").
-behaviour(task_tgr).


-export([
    start/1
    , stop/1
    , can/1
    , can_accept/1
    , do/1
    , reset/1]).