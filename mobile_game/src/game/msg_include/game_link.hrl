%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 17. 一月 2016 下午5:20
%%%-------------------------------------------------------------------
-author("clark").


%% 在线人数
-define(game_server_count, server_count).
-record(game_server_count,
{
    server_id       = 0,
    player_count    = 0
}).

