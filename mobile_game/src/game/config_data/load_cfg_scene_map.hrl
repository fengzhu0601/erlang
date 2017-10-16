%%%-------------------------------------------------------------------
%%% @author fengzhu
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 05. 一月 2016 下午12:21
%%%-------------------------------------------------------------------
-author("fengzhu").

-record(map_cfg, {
  id,
  width :: neg_integer(),    %% block count
  height :: neg_integer(),
  unwalkable_points :: [],
  safe_points :: [map_point()] %% 不可伤害点,
}).