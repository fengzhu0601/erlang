%%%-------------------------------------------------------------------
%%% @author fengzhu
%%% @copyright (C) 2016, <COMPANY>
%%% @doc 天空之城大副本
%%%
%%% @end
%%% Created : 05. 一月 2016 上午10:50
%%%-------------------------------------------------------------------
-author("fengzhu").

%% 排名奖励表
-record(sky_rank_cfg, {
  id = 0,
  rank = 0,
  monster_prize = 0,
  box_prize = 0,
  warrior_prize = 0
}).

%% 场景随机概率表
-record(sky_scene_random_cfg, {
  scene_id,
  enter_per
}).

-define(sky_rank_cfg, sky_rank_cfg).                %排名奖励表
-define(sky_scene_random_cfg, sky_scene_random_cfg). %场景随机权重表