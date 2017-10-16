%%%-------------------------------------------------------------------
%%% @author fengzhu
%%% @copyright (C) 2016, <COMPANY>
%%% @doc 神魔系统
%%%
%%% @end
%%% Created : 05. 一月 2016 上午11:20
%%%-------------------------------------------------------------------
-module(load_cfg_camp).
-author("fengzhu").

%% API
-export([
  lookup_cfg/1
  , lookup_cfg/2
]).

-include_lib("config/include/config.hrl").
-include("inc.hrl").
-include("load_cfg_camp.hrl").

-include("camp_struct.hrl").
-include("main_ins_struct.hrl").
-include("load_cfg_main_ins.hrl").

load_config_meta() ->
  [
    #config_meta{record = #camp_ins_cfg{},
      fields = ?record_fields(?camp_ins_cfg),
      file = "shenmo_war.txt",
      keypos = #camp_ins_cfg.scene_id,
      verify = fun verify_camp_ins/1}
  ].

verify_camp_ins(#camp_ins_cfg{scene_id = SceneId, war_prize = Prize1, inbreak_prize = Prize2, guard_prize = Prize3}) ->
  ?check(load_cfg_scene:is_exist_scene_cfg(SceneId), "camp_ins.txt id[~w] 无效! ", [SceneId]),
  ?check(prize:is_exist_prize_cfg(Prize1) orelse Prize1 =:= 0, "camp_ins.txt id[~w] 无效! ", [SceneId]),
  ?check(is_integer(Prize2), "camp_ins.txt id[~w] 无效! ", [SceneId]),
  ?check(is_integer(Prize3), "camp_ins.txt id[~w] 无效! ", [SceneId]).

lookup_cfg(Index) ->
  CampMisc = misc_cfg:get_misc_cfg(camp_info),
  case lists:nth(Index - 1, CampMisc) of
    {enter_count, Count} -> Count;
    {refresh_time, Time} -> Time;
    Other -> Other
  end.

lookup_cfg(?main_ins_cfg, all) ->
  load_cfg_main_ins:lookup_group_main_ins_cfg(#main_ins_cfg.type, ?T_INS_SHENMO);

lookup_cfg(?main_ins_cfg, Key) ->
  load_cfg_main_ins:lookup_main_ins_cfg(Key);

lookup_cfg(?camp_ins_cfg, Key) ->
  lookup_camp_ins_cfg(Key).
