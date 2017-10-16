%%%-------------------------------------------------------------------
%%% @author fengzhu
%%% @copyright (C) 2016, <COMPANY>
%%% @doc 场景传送门
%%%
%%% @end
%%% Created : 05. 一月 2016 下午4:17
%%%-------------------------------------------------------------------
-module(load_cfg_scene_portal).
-author("fengzhu").

%% API
-export([
  get_portal_position/1
]).

-include_lib("config/include/config.hrl").
-include("inc.hrl").
-include("load_cfg_scene_portal.hrl").


load_config_meta() ->
  [
    #config_meta{record = #portal_cfg{},
      fields = record_info(fields, portal_cfg),
      file = "generated_door.txt",
      keypos = #portal_cfg.id,
      verify = fun verify/1

    }
  ].

verify(#portal_cfg{id = Id, src_scene_id = Sid, src_x = Sx, src_y = Sy, src_r = Sr, src_l = Sl, dst_scene_id = Did, dst_x = Dx, dst_y = Dy, level_limit = LL}) ->
  ?check(load_cfg_scene:is_exist_scene_cfg(Sid), "door.txt [~p] src_scene_id ~p 没有找到", [Id, Sid]),
  ?check(load_cfg_scene:is_exist_scene_cfg(Did), "door.txt [~p] dst_scene_id ~p 没有找到", [Id, Did]),

  Smap = load_cfg_scene:get_map_id(Sid),
  ?check(scene_map:map_is_walkable(Smap, {Sx, Sy}), "door.txt [~p] map:~p src_x, src_y ~p 不可行走", [Id, Smap, {Sx, Sy}]),

  Dmap = load_cfg_scene:get_map_id(Did),
  ?check(scene_map:map_is_walkable(Dmap, {Dx, Dy}), "door.txt [~p] scene_id:~p map:~p dst_x, dst_y ~p 不可行走", [Id, Did, Dmap, {Dx, Dy}]),
  ?check(com_util:is_valid_uint16(Sr), "door.txt [~w] src_r ~w 错误", [Id, Sr]),
  ?check(com_util:is_valid_uint16(Sl), "door.txt [~w] src_l ~w 错误", [Id, Sl]),

  ?check(LL > 0, "door.txt [~p] level_limit ~p must > 0", [Id, LL]),

  ok.


get_portal_position(DoorId) ->
  case lookup_portal_cfg(DoorId) of
    ?none ->
      ?none;
    #portal_cfg{src_scene_id = Sid, src_x = Sx, src_y = Sy, src_r = Sr, src_l = Sl, dst_scene_id = Did, dst_x = Dx, dst_y = Dy} ->
      {Sid, Sx, Sy, Sr, Sl, Did, Dx, Dy}
  end.
