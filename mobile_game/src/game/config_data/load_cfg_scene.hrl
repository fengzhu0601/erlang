%%%-------------------------------------------------------------------
%%% @author fengzhu
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 05. 一月 2016 下午1:34
%%%-------------------------------------------------------------------
-author("fengzhu").

-include("game.hrl").
-include("type.hrl").

-record(scene_cfg, {
  id,
  type :: ?SC_TYPE_NORMAL | ?SC_TYPE_MAIN_INS,
  node = local, %%  unused 跨服使用
  map_source,     %% binary filename
  modes = [?PK_PEACE], %% 第一个为默认模式,
  parties = [], %% 该场景不可以攻击的阵营()
  enter :: map_point(), %% 进入点
  relive :: map_point() | {SceneId :: integer(), map_point()}, %% 复活点
  level_limit = 0, %% 进入场景的最小等级
  is_cost_mp = 1,
  commands = [],
  run_arg = nil, %% 用于运行时传递参数，配置不用
  tag_list = [],  %% 掉落列表
  is_pet_fight = 1,
  is_communal_server = 0
}).

%% 加hp/mp配置record
-record(add_hp_mp_cfg, {
  id
  , type
  , buff_id = 0
}).
