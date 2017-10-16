%%%-------------------------------------------------------------------
%%% @author fengzhu
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 05. 一月 2016 下午1:35
%%%-------------------------------------------------------------------
-module(load_cfg_scene).
-author("fengzhu").

%% API
-export
([
    get_pid/1,   %根据场景id获取pid
    get_config_id/1, %获取场景配置id
    get_enter_pos_by_cfg/1,
    get_default_enter_point/1, %获取默认进入点
    get_default_scene_id/1,    %获取创建角色时进入的场景id
    get_map_id/1,              %获取map_id
    get_config_type/1,         %根据cfgid获取副本类型
    get_enter_level_limit/1,   %进入等级限制
    get_scene_type/1,          %获得场景类型
    is_valid_pk_mode/2,        %该场景是否时pk模式
    is_normal_scene/1,         %是否是城镇场景
    is_cost_mp/1,
    is_pet_fight/1
]).

-include_lib("config/include/config.hrl").
-include("inc.hrl").
-include("load_cfg_scene.hrl").
-include("scene.hrl").

load_config_meta() ->
    [
        #config_meta{record = #scene_cfg{},
        fields = record_info(fields, scene_cfg),
        file = "scene.txt",
        keypos = #scene_cfg.id,
        %%rewrite = fun change/1,
        verify = fun verify/1},

        #config_meta{record = #add_hp_mp_cfg{},
        fields = ?record_fields(add_hp_mp_cfg),
        file = "add_hp_mp.txt",
        keypos = #add_hp_mp_cfg.id,
        verify = fun verify/1}
    ].

verify(#scene_cfg{id = SceneId, type = Type, map_source = MapId, modes = Modes, enter = _Enter, relive = _Relive, level_limit = LevelLimit} = Cfg) ->
    ?check(?is_pos_integer(SceneId) andalso com_util:is_valid_uint16(SceneId), "scene_cfg[~p] 场景id 无效", [SceneId]),
    ?check(LevelLimit > 0, "scene_cfg[~p] level_limit ~p 无效", [SceneId, LevelLimit]),

    %%  ?check(scene_map:is_exist_map_cfg(MapId), "scene_cfg[~p] 没有找到map [~p]", [SceneId, MapId]),
    ?check(load_cfg_scene_map:is_exist_map_cfg(MapId), "scene_cfg[~p] 没有找到map [~p]", [SceneId, MapId]),

    %Node = R#scene.node,/
    %case Node of
    %local ->
    %R2 = R;
    %_ ->
    %utils:assert(SceneId > 0, "远程节点场景id必须大于0! ~p~n", [SceneId]),
    %RemoteNote = application:get_env(remote_node),
    %utils:assert(RemoteNote =/= undefined, "scene中存在非本地节点场景，但没有配置远程节点! ~p~n", [SceneId]),
    %R2 = R#scene{node=RemoteNote}
    %end,

    ?check(erlang:is_list(Modes), "scene_cfg[~p] modes 格式错误不是list~p", [SceneId, Modes]),

    %%?check(lists:all(fun(T) -> T end,
    %%[lists:member(M, ?ALL_PK_MODES) || M <- Modes]),
    %%"scene_cfg[~p] modes 存在无效配置", [SceneId]),

    %%    {RliveSceneId, RP={_, _}} ->
    %%        MapId2 = scene:lookup_scene_cfg(RliveSceneId, #scene_cfg.map_source),
    %%        ?check(MapId2 =/= none andalso scene_map:map_is_walkable(MapId, RP),
    %%               "scene_cfg[~p] relive 不可行走~p", [SceneId, Relive]);
    %%    {_, _} ->
    %%        ?check(scene_map:map_is_walkable(MapId, Relive),
    %%               "scene_cfg[~p] relive 不可行走~p", [SceneId, Relive]);
    %%    _ ->
    %%        ?ERROR_LOG("scene_cfg[~p] relive 配置格式错误~p", [SceneId, Relive]),
    %%        erlang:exit(bad_cfg)
    %%end,

    %% monster group
    %%lists:foreach(fun({MonsterId, MonsterX, MonsterY, Dir}) ->
    %%                      ?check(scene_monster:is_exist_monster_cfg(MonsterId),
    %%                             "scene_cfg[~p] monsert ~p 不能找到配置", [SceneId, MonsterId]),
    %%                      ?check(scene_map:map_is_walkable(MapId, MonsterX, MonsterY),
    %%                             "scene_cfg[~p] monsert ~p 出生位置不可行走", [SceneId, {MonsterId, MonsterX, MonsterY}]),
    %%                      ?check(?is_vaild_dir(Dir),
    %%                             "scene_cfg[~p] monsert ~p dir 出生方向无效", [SceneId, {MonsterId, MonsterX, MonsterY}, Dir]);
    %%                 (X) ->
    %%                      ?check(?false, "scene_cfg[~p] monster bad arg ~p", [X])
    %%              end,
    %%              Cfg#scene_cfg.monsters),
    case Type of
        ?SC_TYPE_NORMAL ->
            ?check(Cfg#scene_cfg.commands =:= [], "scene_cfg[~p] commands 不能配置命令，只有副本类型的场景才可以", [SceneId]),

            %% 把所有的normal scene 插入 ets
            global_data:add_normal_scene(SceneId),
            ok;
        ?SC_TYPE_MAIN_INS -> ok;
        ?SC_TYPE_ARENA -> ok;
        _ -> ?ERROR_LOG("scene_cfg[~p] type 字段无效~p", [SceneId, Type])
    end,

    EnterLevelLimit = Cfg#scene_cfg.level_limit,
    ?check(is_integer(EnterLevelLimit) andalso EnterLevelLimit >= 0, "scene.txt [~p] level_limit ~p 无效格式 必须 >= 0", [SceneId, EnterLevelLimit]),

    ok;

verify(#add_hp_mp_cfg{id = ButtonId, type = Type, buff_id = _BuffId} = _Cfg) ->
    if
        Type =:= ?ADD_TYPE_HP_MP_TYPE ->
            ignore;
        ?true ->
            %% TODO: 当类型为？ADD_TYPE_BUFF_TYPE 需要校验buff时候存在
            %%?check(Type =:= ?ADD_TYPE_BUFF_TYPE andalso  buff:is_exist_buff_cfg(BuffId), "add_hp_mp.txt [~w] buff_id ~w 不存在 ", [ButtonId, BuffId]),
            ?check(Type =:= ?ADD_TYPE_BUFF_TYPE, "add_hp_mp.txt [~w] 的类型[~w]错误 ", [ButtonId, Type])

    end,
    ?check(com_util:is_valid_uint8(ButtonId), "add_hp_mp.txt [~w] 的Id超过范围", [ButtonId]),
    ok.

is_cost_mp(SceneId) ->
    case lookup_scene_cfg(get_config_id(SceneId)) of
        ?none -> 
            false;
        #scene_cfg{is_cost_mp = 0} ->
            false;
        _ ->
            true
    end.        

get_scene_type(SceneId) ->
    case SceneId of
        _ when is_integer(SceneId) -> ?SC_TYPE_NORMAL;
            % {_Cfg, _Type, Data} ->
            %   main_ins_mod:get_instance_type(element(1, Data));
        {_CfgId, Type} -> game_def:scene_type_id_to_i(Type);
        {_CfgId, Type, _} -> game_def:scene_type_id_to_i(Type);
        _ -> {error, unknown_scene_type}
    end.

%% @doc get scene pid | none.
get_pid(SceneId) ->
    com_prog:get_member(?scene_group, SceneId).

get_default_scene_id(Nation) ->
    T3 = misc_cfg:get_default_scene_id(),
    erlang:element(Nation, T3).

get_enter_pos_by_cfg(CfgId) ->
    lookup_scene_cfg(CfgId, #scene_cfg.enter).

get_default_enter_point(SceneIdOrId) ->
    lookup_scene_cfg(get_config_id(SceneIdOrId), #scene_cfg.enter).

get_map_id(CfgId) ->
    lookup_scene_cfg(CfgId, #scene_cfg.map_source).

get_config_type(CfgId) ->
    lookup_scene_cfg(CfgId, #scene_cfg.type).


%% scene id  主场景id 和　cfg_id 相同
-spec get_config_id(scene_id()) -> scene_cfg_id().
get_config_id(Id) when is_integer(Id) -> Id;
get_config_id(Id) when is_tuple(Id) -> element(1, Id);
get_config_id(Id) -> ?ERROR_LOG("invalied scene id ~p", [Id]), Id.

is_normal_scene(SceneId) when is_integer(SceneId)->
    lookup_scene_cfg(SceneId, #scene_cfg.type) =:= ?SC_TYPE_NORMAL;
is_normal_scene(SceneId) ->
    lookup_scene_cfg(get_config_id(SceneId), #scene_cfg.type) =:= ?SC_TYPE_NORMAL.

is_valid_pk_mode(SceneId, Mode) ->
    case lookup_scene_cfg(get_config_id(SceneId)) of
        ?none -> false;
        #scene_cfg{modes = Modes} ->
        lists:member(Mode, Modes)
    end.

get_enter_level_limit(SceneId) ->
    lookup_scene_cfg(get_config_id(SceneId), #scene_cfg.level_limit).

is_pet_fight(SceneId) ->
    lookup_scene_cfg(get_config_id(SceneId), #scene_cfg.is_pet_fight).