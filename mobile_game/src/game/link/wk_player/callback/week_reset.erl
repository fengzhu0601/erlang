%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 04. 七月 2015 下午3:07
%%%-------------------------------------------------------------------

-module(week_reset).
-include("type.hrl").


%% API
-export([callback_list/0]).




%% @doc 周重置。
-callback on_week_reset(SelfId :: player_id()) -> _.




callback_list() -> [arena_mng].

