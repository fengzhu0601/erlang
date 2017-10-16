%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 16. 十月 2015 下午5:47
%%%-------------------------------------------------------------------
-author("clark").



%% 玩家日志表
-record(arena_log_tab,
{
    name,
    carrer,
    is_accord,
    time,
    ret,
    self_ret_rank,
    self_ret_honor
}).

-record(player_arena_log_tab,
{
    id,
    log
}).


