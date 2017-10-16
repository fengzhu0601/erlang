%%%-------------------------------------------------------------------
%%% @author fengzhu
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 05. 一月 2016 上午11:50
%%%-------------------------------------------------------------------
-author("fengzhu").

-record(monster_group_cfg, {
  id,
  monsters, %%[monsterId]
  types %%[monster_type.type]
}).

-record(scene_monster_cfg, {
  id,
  group_id,
  x, %% 出生点
  y,
  direction %% 方向
}).

%% 防御／进攻，这种类型
-record(monster_mtype_cfg, {
  mtype,
  level, %% player level
  attr_id
}).