%%%-------------------------------------------------------------------
%%% @author fengzhu
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 05. 一月 2016 上午11:50
%%%-------------------------------------------------------------------
-module(load_cfg_monster_group).
-author("fengzhu").

%% API
-export([
  random_monster/1
  , random_monster_attr_type/1
]).

-include_lib("config/include/config.hrl").
-include("inc.hrl").
-include("load_cfg_monster_group.hrl").

load_config_meta() ->
  [
    #config_meta{record = #monster_group_cfg{},
      fields = ?record_fields(monster_group_cfg),
      file = "monster_group.txt",
      keypos = #monster_group_cfg.id,
      verify = fun verify/1}
    ,

    #config_meta{record = #scene_monster_cfg{},
      fields = ?record_fields(scene_monster_cfg),
      file = {"monster", ".txt"},
      keypos = #scene_monster_cfg.id,
      verify = fun verify/2}
    ,

    #config_meta{record = #monster_mtype_cfg{},
      fields = ?record_fields(monster_mtype_cfg),
      file = "monster_type.txt",
      keypos = [#monster_mtype_cfg.mtype, #monster_mtype_cfg.level],
      all = [#monster_mtype_cfg.mtype, #monster_mtype_cfg.level],
      verify = fun verify_type/1}
  ].

verify_type(#monster_mtype_cfg{mtype = T, level = Level, attr_id = AttrId} = _R) ->
  ?check(?is_pos_integer(T), "monster_type.txt type:[~p] invailed", [T, _R]),
  ?check(?is_pos_integer(T), "monster_type.txt level:[~p] invailed", [Level, _R]),
  ?check(load_spirit_attr:is_exist_attr(AttrId), "monster_type.txt type:[~p] attr_id ~p not exist", [{T, Level}, AttrId]),

  ok.

verify(#monster_group_cfg{id = Id, monsters = ML, types = Types}) ->
  ?check(is_list(ML) andalso ML =/= [], "monster_group.txt [~p] monsters ~p 无效", [Id, ML]),
%%     [?check(scene_monster:is_exist_monster_cfg(MId), "monster_group.txt [~p] monster ~p 不存在", [Id, MId])
%%             || MId <- ML],
%%
%%     [?check(scene_monster:is_exist_monster_cfg(MId), "monster_group.txt [~p] monster ~p 不存在", [Id, MId])
%%             || MId <- ML],

  %%AllTypes = lookup_all_monster_type_cfg(#monster_mtype_cfg.type),
  %%?check(is_list(AllTypes) andalso AllTypes =/= [], "monster_type.txt all type is ~p", [AllTypes]),

  [?check(is_list(Types) andalso Types =/= [], "monster_type.txt [~p] types:~p invalide", [Id, Types])],
  %% 1 is player.level
  [?check(is_exist_monster_mtype_cfg({Type, 1}), "monster_type.txt type:~p invalide", [Type]) || Type <- Types],

  ok;
verify(_R) ->
  ?ERROR_LOG("monster_group.txt ~p 配置　错误格式", [_R]),
  exit(bad).

verify(FileId, #scene_monster_cfg{id = Id, group_id = Gid, x = _X, y = _Y, direction = Dir}) ->
  % case scene:get_map_id(FileId) of
  %     ?none ->
  %       ?DEBUG_LOG("FileId, Id, mapid--------:~p",[{FileId, Id, scene:get_map_id(FileId)}]);
  %     _ ->
  %       pass
  % end,
  ?check(is_exist_monster_group_cfg(Gid), "scene_monster_cfg file[~p] id[~p] group_id ~p not find", [FileId, Id, Gid]),
  %% todo ......
  %?check(scene_map:map_is_walkable(scene:get_map_id(FileId), X, Y), "scene_monster_cfg file[~p] id[~p] point~p not valkable", [FileId, Id, {X,Y}]),
  ?check(Dir =:= ?D_L orelse Dir =:= ?D_R, "scene_monster_cfg file[~p] id[~p] dir ~p invailed", [FileId, Id, Dir]),
  ok.

%% -> MonsterId
random_monster(GroupId) ->
  com_lists:random_element(
    lookup_monster_group_cfg(GroupId, #monster_group_cfg.monsters)).

random_monster_attr_type(GroupId) ->
  com_lists:random_element(
    lookup_monster_group_cfg(GroupId, #monster_group_cfg.types)).


