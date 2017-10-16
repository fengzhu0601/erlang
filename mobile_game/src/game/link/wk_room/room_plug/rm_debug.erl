%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 05. 四月 2016 下午4:20
%%%-------------------------------------------------------------------
-module(rm_debug).
-author("clark").

%% API
-export
([
    can_trace/1
    , trace/1
]).



-include("inc.hrl").

can_trace(Txt) ->
    ?INFO_LOG("rm_debug can ~p", [Txt]),
    true.

trace(Txt) ->
    ?INFO_LOG("rm_debug do ~p", [Txt]).