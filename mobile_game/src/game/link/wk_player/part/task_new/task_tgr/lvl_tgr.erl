%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 21. 七月 2015 上午10:39
%%%-------------------------------------------------------------------
-module(lvl_tgr).
-author("clark").


-include("task_tgr.hrl").
-include("player_def.hrl").

reset(_TgrDBID) -> ok.

start(_TgrDBID) -> ok.
stop(_TgrDBID) -> ok.
do(_TgrDBID) -> ok.


can(TgrDBID) ->
    Limit_lvl = task_system:get_tgr_config_data(TgrDBID),
    CurLvL = attr_new:get(?pd_level),
    if
        Limit_lvl =< CurLvL ->
            true;
        true ->
            false
    end.
 can_accept(TgrDBID) ->
	Limit_lvl = task_system:get_tgr_config_data(TgrDBID),
    CurLvL = attr_new:get(?pd_level),
    if
        Limit_lvl =< CurLvL ->
            true;
        true ->
            false
    end.