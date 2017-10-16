%%%-------------------------------------------------------------------
%%% @author fengzhu
%%% @copyright (C) 2016, <COMPANY>
%%% @doc 场景掉落
%%%
%%% @end
%%% Created : 05. 一月 2016 下午4:22
%%%-------------------------------------------------------------------
-author("fengzhu").

-record(scene_drop_cfg, {id,
  items = [],
  exp = none %% 经验一般是怪物死亡时立即加上
}).

%% @doc 单机副本掉落表，根据玩家等级匹配掉落
-record(scene_tag_cfg, {
  id = 0,
  scene_id = 0,     %%场景ID
  match_level = 0,  %%是否匹配等级
  tag_list = []     %%掉落列表
}).