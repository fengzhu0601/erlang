%%%-------------------------------------------------------------------
%%% @author fengzhu
%%% @copyright (C) 2015, <COMPANY>
%%% @doc 成就系统
%%%
%%% @end
%%% Created : 31. 十二月 2015 下午3:59
%%%-------------------------------------------------------------------
-author("fengzhu").

-define(AC_DOING, 1).

-record(achievement_cfg,
{
    id,
    type,
    event = 0,
    event_goal = 0,
    max_value,
    reward,
    title
}).

-record(ac,
{
    id,
    star = 0,
    current_value = 0,
    event_goal,
    max_value,
    status = ?AC_DOING,
    is_get_prize_star = 0
}).