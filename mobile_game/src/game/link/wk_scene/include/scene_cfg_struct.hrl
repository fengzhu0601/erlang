-include("game.hrl").
-include("type.hrl").

%%-record(scene_cfg, {
%%    id,
%%    type :: ?SC_TYPE_NORMAL | ?SC_TYPE_MAIN_INS,
%%    node = local, %%  unused 跨服使用
%%    map_source,     %% binary filename
%%    modes = [?PK_PEACE], %% 第一个为默认模式,
%%    parties = [], %% 该场景不可以攻击的阵营()
%%    enter :: map_point(), %% 进入点
%%    relive :: map_point() | {SceneId :: integer(), map_point()}, %% 复活点
%%    level_limit = 0, %% 进入场景的最小等级
%%    commands = [],
%%    run_arg = nil, %% 用于运行时传递参数，配置不用
%%    tag_list = []  %% 掉落列表
%%}).

%%%% @doc 单机副本掉落表，根据玩家等级匹配掉落
%%-record(scene_tag_cfg, {
%%    id = 0,
%%    scene_id = 0,     %%场景ID
%%    match_level = 0,  %%是否匹配等级
%%    tag_list = []     %%掉落列表
%%}).

-record(run_arg, {
    match_level = 0,
    is_match = 0,        %%是否匹配同等级怪物
    start_scene_career = 0,
    other = 0
}).

%%%% 加hp/mp配置record
%%-record(add_hp_mp_cfg, {
%%    id
%%    , type
%%    , buff_id = 0
%%}).
