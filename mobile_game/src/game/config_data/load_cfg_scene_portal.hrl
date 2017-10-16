%%%-------------------------------------------------------------------
%%% @author fengzhu
%%% @copyright (C) 2016, <COMPANY>
%%% @doc 场景传送门
%%%
%%% @end
%%% Created : 05. 一月 2016 下午4:16
%%%-------------------------------------------------------------------
-author("fengzhu").

%% 传送门
-record(portal_cfg, {id,
  src_scene_id,
  src_x,
  src_y,
  src_r,
  src_l,
  dst_scene_id,
  dst_x,
  dst_y,
  level_limit
}).