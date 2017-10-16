%%%-------------------------------------------------------------------
%%% @author fengzhu
%%% @copyright (C) 2016, <COMPANY>
%%% @doc 天空之城大副本
%%%
%%% @end
%%% Created : 05. 一月 2016 上午10:50
%%%-------------------------------------------------------------------
-module(load_cfg_sky).
-author("fengzhu").

%% API
-export([
  lookup_cfg/2,
  lookup_cfg/3
]).

-include_lib("config/include/config.hrl").
-include("inc.hrl").
-include("load_cfg_sky.hrl").
-include("main_ins_struct.hrl").
-include("load_cfg_main_ins.hrl").

load_config_meta() ->
  [
    #config_meta{record = #sky_rank_cfg{},
      fields = ?record_fields(?sky_rank_cfg),
      file = "sky_rank.txt",
      keypos = #sky_rank_cfg.id,
      verify = fun verify_sky_rank_cfg/1},

    #config_meta{record = #sky_scene_random_cfg{},
      fields = ?record_fields(?sky_scene_random_cfg),
      file = "sky_scene_random.txt",
      keypos = #sky_scene_random_cfg.scene_id,
      verify = fun verify_sky_scene_random_cfg/1}

  ].

verify_sky_rank_cfg(#sky_rank_cfg{id = Id, rank = Rank, monster_prize = Prize1, box_prize = Prize2, warrior_prize = Prize3}) ->
  ?check(is_integer(Id), "sky_rank.txt id[~w] 无效! ", [Id]),
  ?check(is_integer(Rank), "sky_rank.txt id[~w] 无效! ", [Id]),
  ?check(prize:is_exist_prize_cfg(Prize1) orelse Prize1 =:= 0, "sky_rank.txt id[~w] 无效! ", [Id]),
  ?check(prize:is_exist_prize_cfg(Prize2) orelse Prize2 =:= 0, "sky_rank.txt id[~w] 无效! ", [Id]),
  ?check(prize:is_exist_prize_cfg(Prize3) orelse Prize3 =:= 0, "sky_rank.txt id[~w] 无效! ", [Id]).

verify_sky_scene_random_cfg(#sky_scene_random_cfg{scene_id = SceneId, enter_per = Per}) ->
  ?check(load_cfg_scene:is_exist_scene_cfg(SceneId), "sky_scene_random.txt id[~w] 无效! ", [SceneId]),
  ?check(is_integer(Per), "sky_scene_random.txt id[~w] 无效! ", [SceneId]).

lookup_cfg(all, Type) ->
  Fun = fun(Id) ->
    MainCFG = load_cfg_main_ins:lookup_main_ins_cfg(Id),
    MainCFG#main_ins_cfg.sub_type =:= Type
        end,
  IdList = load_cfg_main_ins:lookup_group_main_ins_cfg(#main_ins_cfg.type, ?T_INS_SKY_MIGONG),
  lists:filter(Fun, IdList).

lookup_cfg(?sky_rank_cfg, Key, Index) ->
    case lookup_sky_rank_cfg(Key, Index) of
        ?none ->
            0;
        D ->
            D
    end.