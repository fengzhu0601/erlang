%%%-------------------------------------------------------------------
%%% @author fengzhu
%%% @copyright (C) 2016, <COMPANY>
%%% @doc 场景机关设备
%%%
%%% @end
%%% Created : 05. 一月 2016 下午4:01
%%%-------------------------------------------------------------------
-module(load_cfg_scene_device).
-author("fengzhu").

%% API
-export([]).

-include_lib("config/include/config.hrl").
-include("inc.hrl").
-include("load_cfg_scene_device.hrl").

load_config_meta() ->
  [
    #config_meta{record = #scene_device_cfg{},
      fields = ?record_fields(scene_device_cfg),
      keypos = [#scene_device_cfg.scene_id, #scene_device_cfg.id],
      file = "scene_device.txt", %%file = {"scene_device", ".txt"},
      groups = [#scene_device_cfg.scene_id],
      verify = fun verify/1}
  ].

verify(#scene_device_cfg{scene_id = SId, id = Id, position = Pos,
  skill_id = _SkillId,
  hit_times = _Hit,
  release_times = ReleaseTimes,
  hit_per = _HitPer,
  interval = Interval} = Cfg) ->
  CfgKey = cfg_key(Cfg),
  ?check(load_cfg_scene:is_exist_scene_cfg(SId), "scene_devic.txt [~p] scene_id ~p 没有找到对应场景", [CfgKey, SId]),
  MapId = load_cfg_scene:get_map_id(SId),
  ?check(scene_map:is_walkable(MapId, Pos), "scene_device.txt [~p] positon ~p 不可行走", [CfgKey, Pos]),

  ?check(?is_pos_integer(Id), "scene_device.txt [~p]　id 无效", [CfgKey]),
  ?check(?is_pos_integer(Interval), "scene_device.txt [~p] interval ~p无效", [CfgKey, Interval]),
  ?check(ReleaseTimes =:= ?infinity orelse ?is_pos_integer(ReleaseTimes), "scene_device.txt [~p] release_times ~p 无效", [CfgKey, ReleaseTimes]),

  ok.

%% TODO auto gen
cfg_key(#scene_device_cfg{scene_id = SId, id = Id}) ->
  {SId, Id}.
