%%%-------------------------------------------------------------------
%%% @author fengzhu
%%% @copyright (C) 2016, <COMPANY>
%%% @doc 采集
%%%
%%% @end
%%% Created : 05. 一月 2016 下午4:11
%%%-------------------------------------------------------------------
-author("fengzhu").

-record(scene_collect_cfg,
{id,
  type = 1, % 1 任务采集 2 真实物品采集
  scene_id,
  direction,
  item,
  x,
  y
}).

-define(CT_TASK_COLLECT, 1). % 任务采集
-define(CT_ITEM_COLLECT, 2). % 真实物品采集
-define(CT_ITEM_RESFIGHT, 3). % 资源争夺战物品采集