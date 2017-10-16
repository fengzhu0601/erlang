%%%-------------------------------------------------------------------
%%% @author fengzhu
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 05. 一月 2016 下午12:15
%%%-------------------------------------------------------------------
-author("fengzhu").

-record(monster_show_cfg, {id,
  daily %% 毫秒
}).

-record(monster_show_group_cfg,
{
  id,
  shows %% [monster_show_cfg.id]
}).