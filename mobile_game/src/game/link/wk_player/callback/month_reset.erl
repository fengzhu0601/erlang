%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 04. 七月 2015 下午3:07
%%%-------------------------------------------------------------------

-module(month_reset).
-include("type.hrl").


%% API
-export([callback_list/0]).




%% @doc 月重置。
-callback on_month_reset(SelfId :: player_id()) -> _.




callback_list() -> [login_prize_part, arena_mng].

