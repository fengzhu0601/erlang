%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 07. 四月 2016 上午5:55
%%%-------------------------------------------------------------------
-module(rm_user_evt).
-author("clark").

%% API
-export
([
    send_evt/1
    , is_pass/1
]).


-include("inc.hrl").
-include("porsche_gearbox.hrl").



send_evt({Dt, Evt}) ->
    porsche_gearbox:send_user_evt({Dt, Evt}).

is_pass(Rand) ->
    SR = com_util:random(1,100),
    if
        Rand =< SR -> true;
        true -> false
    end.