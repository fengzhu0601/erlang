%%%-------------------------------------------------------------------
%%% @author fengzhu
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 31. 十二月 2015 下午3:31
%%%-------------------------------------------------------------------
-author("fengzhu").

-define(global_title_type, 0). %全局称号的类型type
-define(rank_title_type, 1).   %排行榜冲榜称号的类型type
-record(title_cfg,
{
  id = 0,
  type = 0,
  title_server_name = 0,
  level = 0,
  attr_id = 0
}).