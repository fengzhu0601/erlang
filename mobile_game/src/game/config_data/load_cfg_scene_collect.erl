%%%-------------------------------------------------------------------
%%% @author fengzhu
%%% @copyright (C) 2016, <COMPANY>
%%% @doc 采集
%%%
%%% @end
%%% Created : 05. 一月 2016 下午4:11
%%%-------------------------------------------------------------------
-module(load_cfg_scene_collect).
-author("fengzhu").

%% API
-export([]).

-include_lib("config/include/config.hrl").
-include("inc.hrl").
-include("load_cfg_scene_collect.hrl").

load_config_meta() ->
  [
    #config_meta{record = #scene_collect_cfg{},
      fields = record_info(fields, scene_collect_cfg),
      file = "scene_collect.txt",
      keypos = #scene_collect_cfg.id,
      verify = fun collect_verify/1}
  ].

collect_verify(#scene_collect_cfg{id = Id, type = Type, scene_id = SId, item = ItemId, x = X, y = Y}) ->
  ?check(load_cfg_scene:is_exist_scene_cfg(SId), "scene_collect.txt [~p] scene_id ~p 没有找到", [Id, SId]),

  case Type of
    ?CT_TASK_COLLECT ->  %并不是真实物品
      ?check(not goods:is_exist_goods_cfg(ItemId), "scene_collect.txt [~p] 任务item ~p 和goods冲突", [Id, ItemId]);
    ?CT_ITEM_COLLECT ->
      ?check(goods:is_exist_goods_cfg(ItemId), "scene_collect.txt [~p] item ~p 没有找到", [Id, ItemId]);
    ?CT_ITEM_RESFIGHT ->
      ok;
    _ ->
      ok
  end,
  MapId = load_cfg_scene:get_map_id(SId),
  ?check(scene_map:is_walkable(MapId, {X, Y}), "scene_collect.txt [~p] item xy ~p 无可行走点", [Id, {X, Y}]),
  ok.


