%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 21. 七月 2015 上午10:30
%%%-------------------------------------------------------------------
-module(task_tgr).
-author("clark").



-include("inc.hrl").



-callback start(_TgrPar) -> true | false.
-callback stop(_TgrPar) -> any().
-callback can(_TgrPar) -> true | false.
-callback do(_TgrPar) -> any().
