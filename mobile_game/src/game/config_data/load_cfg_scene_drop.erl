%%%-------------------------------------------------------------------
%%% @author fengzhu
%%% @copyright (C) 2016, <COMPANY>
%%% @doc 场景掉落
%%%
%%% @end
%%% Created : 05. 一月 2016 下午4:22
%%%-------------------------------------------------------------------
-module(load_cfg_scene_drop).
-author("fengzhu").

%% API
-export([]).

-include_lib("config/include/config.hrl").
-include("inc.hrl").
-include("load_cfg_scene_drop.hrl").

load_config_meta() ->
  [
    #config_meta{record = #scene_drop_cfg{},
      fields = record_info(fields, scene_drop_cfg),
      file = "scene_drop.txt",
      keypos = #scene_drop_cfg.id,
      verify = fun verify/1},

    #config_meta{record = #scene_tag_cfg{},
      fields = record_info(fields, scene_tag_cfg),
      file = "scene_lvl_drop.txt",
      keypos = [#scene_tag_cfg.scene_id, #scene_tag_cfg.match_level],
      verify = fun scene_tag_verify/1}
  ].

verify(#scene_drop_cfg{id = Id, items = Items, exp = Exp}) ->
  ?check(is_list(Items), "scene_drop_cfg [~p] 无效 items ~p", [Id, Items]),
  lists:foreach(fun({Race, ItemId, ItemCount}) ->
    ?check(Race > 0 andalso Race =< 100, "scene_drop_cfg [~p] 无效 items race ~p", [Id, Race]),
    ?check(player_def:is_valid_special_item_id(ItemId) orelse
      load_item:is_exist_item_attr_cfg(ItemId)
      , "scene_drop_cfg [~p] items id ~p 没有找到", [Id, ItemId]),
    ?check(ItemCount > 0, "scene_drop_cfg [~p] 无效 items dropCount ~p", [Id, ItemCount])
                end,
    Items),
  ?check(Exp =:= ?none orelse Exp > 0, "scene_drop_cfg [~p] exp 无效 必须 >0 ~p", [Id, Exp]),
  ok.

scene_tag_verify(#scene_tag_cfg{id = Id, scene_id = SceneId, match_level = Level, tag_list = TagList}) ->
  ?check(is_integer(Id), "scene_lvl_drop [~p] 无效 id ~p", [Id, Id]),
  ?check(load_cfg_scene:is_exist_scene_cfg(SceneId), "scene_lvl_drop.txt [~p] 没有找到对应 scene_id", [SceneId]),
  ?check(is_integer(Level), "scene_lvl_drop.txt [~p] 没有找到对应 match_level ", [Level]),
  ?check(is_list(TagList), "scene_lvl_drop.txt [~p] tag_list:~p 验证失败! ", [Id, TagList]).