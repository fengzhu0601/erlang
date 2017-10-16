%%% coding:utf-8
%%%-------------------------------------------------------------------
%%% @author zl
%%% @doc 场景实例 场景基础辅助函数
%%%-------------------------------------------------------------------

-module(scene).

%-include_lib("config/include/config.hrl").

-include("inc.hrl").

-include("scene.hrl").
-include("scene_agent.hrl").
-include("scene_mod.hrl").
-include("load_cfg_scene.hrl").

-export([handle_call/2]).


%% API
-export
([
    all_scene/0, %获取所有场景id
%%    get_pid/1,   %根据场景id获取pid
%%    get_config_id/1, %获取场景配置id
%%    get_default_enter_point/1, %获取默认进入点
%%    get_default_scene_id/1,    %获取创建角色时进入的场景id
%%    get_map_id/1,              %获取map_id
%%    get_config_type/1,         %根据cfgid获取副本类型
%%    get_enter_level_limit/1,   %进入等级限制
%%    get_scene_type/1,          %获得场景类型
    get_agent_point/2,         %得到一个场景中指定idx 的当前位置
    get_all_players/1,         %该场景所有玩家
%%    is_valid_pk_mode/2,        %该场景是否时pk模式
%%    is_normal_scene/1,         %是否是城镇场景
%%     broadcast_msg/2,           %向某个场景发送消息

    make_scene_id/2,           %生成场景唯一标识
    make_scene_id/4,           %生成场景唯一标识

    create_monster/4,          %在场景生成某个怪物
    debug_create_monster/3,
    dict_to_s/1,               %方向
    reverse_dict/1,            %反方向

    agents_fold/2,
    get_dict/2,
    get_dict/4,
    get_b_of_a_dict/5,

    %% scene process API
    broadcast_msg__/1,

    random_walkable_point/0,

    get_nearby_monster/2


    %%test_dict2/0,
]).


%% @doc 构造不同类型的场景id
make_scene_id(?SC_TYPE_NORMAL, CfgId) ->
    CfgId.
make_scene_id(?SC_TYPE_MAIN_INS, SubType, CfgId, PlayerIdOrTeamId) ->
    {
        CfgId,
        game_def:scene_type_id_to_a(?SC_TYPE_MAIN_INS),
        {SubType, PlayerIdOrTeamId}
    };
make_scene_id(?SC_TYPE_ARENA, SubType, CfgId, PlayerIdOrTeamInfo) ->
    {
        CfgId,
        game_def:scene_type_id_to_a(?SC_TYPE_ARENA),
        {SubType, PlayerIdOrTeamInfo}
    };
make_scene_id(?SC_TYPE_TEAM, SubType, CfgId, PlayerIdOrTeamInfo) ->
    {
        CfgId,
        game_def:scene_type_id_to_a(?SC_TYPE_TEAM),
        {SubType, PlayerIdOrTeamInfo}
    }.


%%get_scene_type(SceneId) ->
%%    case SceneId of
%%        _ when is_integer(SceneId) -> ?SC_TYPE_NORMAL;
%%        {_CfgId, Type} -> game_def:scene_type_id_to_i(Type);
%%        {_CfgId, Type, _} -> game_def:scene_type_id_to_i(Type);
%%        _ -> {error, unknown_scene_type}
%%    end.
%%
%%%% @doc get scene pid | none.
%%get_pid(SceneId) ->
%%    com_prog:get_member(?scene_group, SceneId).
%%
%%get_default_scene_id(Nation) ->
%%    T3 = misc_cfg:get_default_scene_id(),
%%    erlang:element(Nation, T3).
%%
%%get_default_enter_point(SceneIdOrId) ->
%%    lookup_scene_cfg(get_config_id(SceneIdOrId), #scene_cfg.enter).
%%
%%get_map_id(CfgId) ->
%%    lookup_scene_cfg(CfgId, #scene_cfg.map_source).
%%
%%get_config_type(CfgId) ->
%%    lookup_scene_cfg(CfgId, #scene_cfg.type).
%%
%%
%%%% scene id  主场景id 和　cfg_id 相同
%%-spec get_config_id(scene_id()) -> scene_cfg_id().
%%get_config_id(Id) when is_integer(Id) -> Id;
%%get_config_id(Id) when is_tuple(Id) -> element(1, Id);
%%get_config_id(Id) -> ?ERROR_LOG("invalied scene id ~p", [Id]), Id.
%% broadcast_msg(ScenePid, Msg) when is_pid(ScenePid) ->
%%     case erlang:is_process_alive(ScenePid) of
%%         ?false -> ?none;
%%         ?true ->
%%             gen_server:call(ScenePid, ?scene_mod_msg(?MODULE, {broadcast, Msg}))
%%     end.


%% @doc 得到一个场景中所有玩家的id
-spec get_all_players(scene_id()) -> [player_id()].
get_all_players(ScenePid) when is_pid(ScenePid) ->
    case erlang:is_process_alive(ScenePid) of
        ?false -> [];
        ?true ->
            try
                gen_server:call(ScenePid, ?scene_mod_msg(?MODULE, get_all_players), 1000) 
            of
                {ok, PlayerList} ->
                    PlayerList;
                _E ->
                    ?ERROR_LOG("call get_all_players error ~p", [_E]),
                    []
            catch 
                _E:_W ->
                    []
            end
    end;
get_all_players(SceneId) ->
    case load_cfg_scene:get_pid(SceneId) of
        ?none -> [];
        Pid ->
            get_all_players(Pid)
    end.


%% @doc 得到一个场景中指定idx 的当前位置
%% none  | point()
get_agent_point(ScenePid, Idx) when is_pid(ScenePid) ->
    case erlang:is_process_alive(ScenePid) of
        ?false ->
            ?none;
        ?true ->
            gen_server:call(ScenePid, ?scene_mod_msg(?MODULE, {get_idx_point, Idx}))
    end;
get_agent_point(SceneId, Idx) ->
    case load_cfg_scene:get_pid(SceneId) of
        ?none ->
            ?none;
        Pid ->
            get_agent_point(Pid, Idx)
    end.


%%is_normal_scene(SceneId) ->
%%    lookup_scene_cfg(get_config_id(SceneId), #scene_cfg.type) =:= ?SC_TYPE_NORMAL.
%%
%%is_valid_pk_mode(SceneId, Mode) ->
%%    case lookup_scene_cfg(get_config_id(SceneId)) of
%%        ?none -> false;
%%        #scene_cfg{modes = Modes} ->
%%            lists:member(Mode, Modes)
%%    end.
%%
%%get_enter_level_limit(SceneId) ->
%%    lookup_scene_cfg(get_config_id(SceneId), #scene_cfg.level_limit).



all_scene() ->
    com_prog:get_members(?scene_group).


%% @doc create some monster
%% [{monsterCfgId, BronPoint}]
create_monster(SceneId, MonsterCfgId, X, Y) ->
    case load_cfg_scene:get_pid(SceneId) of
        ?none -> error;
        Pid ->
            %%TODO:怪物朝向
            Pid ! ?scene_mod_msg(scene_monster, {create_monster, [{MonsterCfgId, X, Y, ?D_U}]})
    end.

%获取附近的怪物
get_nearby_monster(SceneId, Idx) ->
    ScenePid = load_cfg_scene:get_pid(SceneId),
    case erlang:is_process_alive(ScenePid) of
        ?false ->
            ?none;
        ?true ->
            ScenePid ! ?scene_mod_msg(scene, {near_monster_toml, ScenePid, Idx})
    end.


%% @doc 测试
debug_create_monster(SceneId, MonsterCfgId, Count) ->
    case load_cfg_scene:get_pid(SceneId) of
        ?none -> error;
        Pid ->
            Pid ! ?scene_mod_msg(scene_monster, {debug_create_monster, MonsterCfgId, Count})
    end.


handle_call(_From, {get_idx_point, Idx}) ->
    case ?get_agent(Idx) of
        ?undefined ->
            ?none;
        #agent{x = X, y = Y} ->
            ?debug_log_scene("get idx point ~p", [{X, Y}]),
            {X, Y}
    end;

handle_call(_From, get_all_players) ->
    {ok, scene_player:get_all_player_ids()};

handle_call(_From, Msg) ->
    ?ERROR_LOG("unknown msg ~p", [Msg]).

handle_msg({broadcast, Msg}) ->
    broadcast_msg__(Msg);

handle_msg({near_monster_toml, ScenePid, Idx}) ->
    case ?get_agent(Idx) of
        ?undefined ->
            ?none;
        A ->
            ScenePid ! ?scene_mod_msg(scene_monster, {near_monster_toml, A})
    end;

handle_msg(Msg) ->
    ?ERROR_LOG("~p recive unknown msg~p", [?pname(), Msg]).

handle_timer(_Ref, _Msg) ->
    ?ERROR_LOG("recv a unknow timer msg~p", [_Msg]),
    ok.

%% send msg to all players
broadcast_msg__(Msg) ->
    players_fold(
        fun(A, _) ->
            ?debug_log_scene("send to client,Data =~p", [Msg]),
            A#agent.pid ! Msg
        end).

%% @spec handle_cast(Msg, State) -> {noreply, State} |
init(#scene_cfg{id = SceneId} = Cfg) ->
%%     ?INFO_LOG("scene init"),
    ?pd_new(?pd_scene_id, SceneId),
    ?pd_new(?pd_cfg_id, load_cfg_scene:get_config_id(SceneId)),

    ?pd_new(?pd_cfg_type, Cfg#scene_cfg.type),

    ?pd_new(?pd_cfg_node, Cfg#scene_cfg.node),
    ?pd_new(?pd_cfg_pk_modes, Cfg#scene_cfg.modes),

    ?pd_new(?pd_cfg_enter, Cfg#scene_cfg.enter),
    ?pd_new(?pd_cfg_relive, Cfg#scene_cfg.relive),
    ?pd_new(?pd_cfg_commands, Cfg#scene_cfg.commands),

    TypeMod = game_def:scene_type_id_to_a(Cfg#scene_cfg.type),

    ?pd_new(?pd_type_mod, TypeMod),

    ok.


uninit(_) ->
    %% TODO tickout player
    ok.



%%load_config_meta() ->
%%    [
%%        #config_meta{record = #scene_cfg{},
%%            fields = record_info(fields, scene_cfg),
%%            file = "scene.txt",
%%            keypos = #scene_cfg.id,
%%            %%rewrite = fun change/1,
%%            verify = fun verify/1},
%%
%%        #config_meta{record = #add_hp_mp_cfg{},
%%            fields = ?record_fields(add_hp_mp_cfg),
%%            file = "add_hp_mp.txt",
%%            keypos = #add_hp_mp_cfg.id,
%%            verify = fun verify/1}
%%    ].

%% TODO
%%utils:assert(exist(?HERO_BORN_SCENE), "初始场景没有找到! ~p~n", [?HERO_BORN_SCENE]),
%%utils:assert(is_permanent(?HERO_BORN_SCENE), "初始场景必须为永久场景! ~p~n", [?HERO_BORN_SCENE]),
%%utils:assert(exist(?JAIL_SCENE_ID), "监狱场景没有找到! ~p~n", [?JAIL_SCENE_ID]),

%%{ok, Path} = application:get_env(config_file_path),
%%Path1 = Path++ "monster/",
%%Ids = com_ets:keys(scene_cfg),

%% rewrite map_source
%%lists:foldl(fun(Id, MAcc) ->
%%                    File= Path1 ++ integer_to_list(Id) ++ ".txt",
%%                    _Cfg = lookup_scene_cfg(Id),
%%                    Cfg= _Cfg#scene_cfg{map_source=scene_map:rewrite_map_id(_Cfg#scene_cfg.map_source)},

%%                    case file:read_file(File) of
%%                        {error, enoent} ->
%%                            %%?debug_log_scene("can not find scene ~p monster cfg ~p", [Id, File]),
%%                            [Cfg | MAcc];
%%                        {error, R} ->
%%                            ?WARN_LOG("can not find scene monster file ~p error:~p",[File, R]),
%%                            exit(bad);
%%                        {ok, <<>> } ->
%%                            ?ERROR_LOG("read scene ~p monster file is emmpty ~p", [Id, File]),
%%                            [Cfg | MAcc];
%%                        {ok, Binary} ->
%%                            [_Hd1,_Hd2|Tail] = binary:split(Binary, [<<$\n>>, <<$\r,$\n>>], [global, trim]),
%%                            Monsters=
%%                            lists:foldl(fun(<<>>, Acc) ->
%%                                                Acc;
%%                                           (Line, Acc) ->
%%                                                case binary:split(Line, <<$\t>>, [global, trim]) of
%%                                                    [MonsterId, X, Y, Dirc] ->
%%                                                        [{ binary_to_integer(MonsterId),
%%                                                           binary_to_integer(X),
%%                                                           binary_to_integer(Y),
%%                                                           binary_to_integer(Dirc)
%%                                                         }|Acc];
%%                                                    _E ->
%%                                                        ?ERROR_LOG("bad match monster ~p", [_E]),
%%                                                        exit(error)
%%                                                end
%%                                        end,
%%                                        [],
%%                                        Tail),
%%                            ?assert(is_list(Monsters)),
%%                            [Cfg#scene_cfg{monsters=Monsters} | MAcc]
%%                    end
%%            end,
%%            [],
%%            Ids).


%%verify(#scene_cfg{id = SceneId, type = Type, map_source = MapId, modes = Modes, enter = _Enter, relive = _Relive, level_limit = LevelLimit} = Cfg) ->
%%    ?check(?is_pos_integer(SceneId) andalso com_util:is_valid_uint16(SceneId), "scene_cfg[~p] 场景id 无效", [SceneId]),
%%    ?check(LevelLimit > 0, "scene_cfg[~p] level_limit ~p 无效", [SceneId, LevelLimit]),
%%
%%    ?check(scene_map:is_exist_map_cfg(MapId), "scene_cfg[~p] 没有找到map [~p]", [SceneId, MapId]),
%%
%%    %Node = R#scene.node,/
%%    %case Node of
%%    %local ->
%%    %R2 = R;
%%    %_ ->
%%    %utils:assert(SceneId > 0, "远程节点场景id必须大于0! ~p~n", [SceneId]),
%%    %RemoteNote = application:get_env(remote_node),
%%    %utils:assert(RemoteNote =/= undefined, "scene中存在非本地节点场景，但没有配置远程节点! ~p~n", [SceneId]),
%%    %R2 = R#scene{node=RemoteNote}
%%    %end,
%%
%%    ?check(erlang:is_list(Modes), "scene_cfg[~p] modes 格式错误不是list~p", [SceneId, Modes]),
%%
%%    %%?check(lists:all(fun(T) -> T end,
%%    %%[lists:member(M, ?ALL_PK_MODES) || M <- Modes]),
%%    %%"scene_cfg[~p] modes 存在无效配置", [SceneId]),
%%
%%    %%    {RliveSceneId, RP={_, _}} ->
%%    %%        MapId2 = scene:lookup_scene_cfg(RliveSceneId, #scene_cfg.map_source),
%%    %%        ?check(MapId2 =/= none andalso scene_map:map_is_walkable(MapId, RP),
%%    %%               "scene_cfg[~p] relive 不可行走~p", [SceneId, Relive]);
%%    %%    {_, _} ->
%%    %%        ?check(scene_map:map_is_walkable(MapId, Relive),
%%    %%               "scene_cfg[~p] relive 不可行走~p", [SceneId, Relive]);
%%    %%    _ ->
%%    %%        ?ERROR_LOG("scene_cfg[~p] relive 配置格式错误~p", [SceneId, Relive]),
%%    %%        erlang:exit(bad_cfg)
%%    %%end,
%%
%%    %% monster group
%%    %%lists:foreach(fun({MonsterId, MonsterX, MonsterY, Dir}) ->
%%    %%                      ?check(scene_monster:is_exist_monster_cfg(MonsterId),
%%    %%                             "scene_cfg[~p] monsert ~p 不能找到配置", [SceneId, MonsterId]),
%%    %%                      ?check(scene_map:map_is_walkable(MapId, MonsterX, MonsterY),
%%    %%                             "scene_cfg[~p] monsert ~p 出生位置不可行走", [SceneId, {MonsterId, MonsterX, MonsterY}]),
%%    %%                      ?check(?is_vaild_dir(Dir),
%%    %%                             "scene_cfg[~p] monsert ~p dir 出生方向无效", [SceneId, {MonsterId, MonsterX, MonsterY}, Dir]);
%%    %%                 (X) ->
%%    %%                      ?check(?false, "scene_cfg[~p] monster bad arg ~p", [X])
%%    %%              end,
%%    %%              Cfg#scene_cfg.monsters),
%%    case Type of
%%        ?SC_TYPE_NORMAL ->
%%            ?check(Cfg#scene_cfg.commands =:= [], "scene_cfg[~p] commands 不能配置命令，只有副本类型的场景才可以", [SceneId]),
%%
%%            %% 把所有的normal scene 插入 ets
%%            global_data:add_normal_scene(SceneId),
%%            ok;
%%        ?SC_TYPE_MAIN_INS -> ok;
%%        ?SC_TYPE_ARENA -> ok;
%%        _ -> ?ERROR_LOG("scene_cfg[~p] type 字段无效~p", [SceneId, Type])
%%    end,
%%
%%    EnterLevelLimit = Cfg#scene_cfg.level_limit,
%%    ?check(is_integer(EnterLevelLimit) andalso EnterLevelLimit >= 0, "scene.txt [~p] level_limit ~p 无效格式 必须 >= 0", [SceneId, EnterLevelLimit]),
%%
%%    ok;
%%
%%verify(#add_hp_mp_cfg{id = ButtonId, type = Type, buff_id = _BuffId} = _Cfg) ->
%%    if
%%        Type =:= ?ADD_TYPE_HP_MP_TYPE ->
%%            ignore;
%%        ?true ->
%%            %% TODO: 当类型为？ADD_TYPE_BUFF_TYPE 需要校验buff时候存在
%%            %%?check(Type =:= ?ADD_TYPE_BUFF_TYPE andalso  buff:is_exist_buff_cfg(BuffId), "add_hp_mp.txt [~w] buff_id ~w 不存在 ", [ButtonId, BuffId]),
%%            ?check(Type =:= ?ADD_TYPE_BUFF_TYPE, "add_hp_mp.txt [~w] 的类型[~w]错误 ", [ButtonId, Type])
%%
%%    end,
%%    ?check(com_util:is_valid_uint8(ButtonId), "add_hp_mp.txt [~w] 的Id超过范围", [ButtonId]),
%%    ok.






dict_to_s(?D_NONE) -> <<"D_NONE">>;
dict_to_s(?D_U) -> <<"D_U">>;
dict_to_s(?D_D) -> <<"D_D">>;
dict_to_s(?D_L) -> <<"D_L">>;
dict_to_s(?D_R) -> <<"D_R">>;
dict_to_s(?D_LD) -> <<"D_LD">>;
dict_to_s(?D_LU) -> <<"D_LU">>;
dict_to_s(?D_RD) -> <<"D_RD">>;
dict_to_s(?D_RU) -> <<"D_RU">>;
dict_to_s(_) -> <<"bad dict">>.

reverse_dict(?D_U) -> ?D_D;
reverse_dict(?D_D) -> ?D_U;
reverse_dict(?D_L) -> ?D_R;
reverse_dict(?D_R) -> ?D_L;
reverse_dict(?D_LD) -> ?D_RU;
reverse_dict(?D_LU) -> ?D_RD;
reverse_dict(?D_RD) -> ?D_LU;
reverse_dict(?D_RU) -> ?D_LD.

%% INLINE Op -> P P 在Ｏｐ的哪边
get_dict({Ox, Oy}, {X, Y}) ->
    get_dict(Ox, Oy, X, Y).
get_dict(Ox, Oy, X, Y) ->
    case {X - Ox, Y - Oy} of
        {0, 0} -> ?D_NONE;
        {0, -1} -> ?D_U;
        {0, 1} -> ?D_D;
        {-1, 0} -> ?D_L;
        {-1, 1} -> ?D_LD;
        {-1, -1} -> ?D_LU;
        {1, 0} -> ?D_R;
        {1, 1} -> ?D_RD;
        {1, -1} -> ?D_RU;
        N -> N
    end.

%% Ｂ在Ａ的哪边
get_b_of_a_dict(Ax, Ay, Bx, By, D) ->
    case {Bx - Ax, By - Ay} of
        {0, 0} -> D;
        {0, Y} when Y < 0 -> ?D_U;
        {0, Y} when Y > 0 -> ?D_D;
        {X, 0} when X > 0 -> ?D_R;
        {X, 0} when X < 0 -> ?D_L;
        {X, Y} when X < 0, Y > 0 -> ?D_LD;
        {X, Y} when X < 0, Y < 0 -> ?D_LU;
        {X, Y} when X > 0, Y > 0 -> ?D_RD;
        {X, Y} when X > 0, Y < 0 -> ?D_RU
    end.



agents_fold(F, Acc) ->
    com_util:fold(get(?pd_monster_max_id),
        get(?pd_player_max_id),
        fun(Idx, _Acc) ->
            case ?get_agent(Idx) of
                ?undefined -> _Acc;
                A -> F(A, _Acc)
            end
        end,
        Acc).




%% @doc 得到一个随机的可行走点
%% -> {X,Y}
random_walkable_point() ->
    Width = get(?pd_map_width),
    Hight = get(?pd_map_height),

    case com_util:while_break(1, 10,
        fun(_) ->
            X = random:uniform(Width - 1),
            Y = random:uniform(Hight - 1),
            case scene_map:is_walkable(X, Y) of
                true -> {break, {X, Y}};
                false -> ok
            end
        end)
    of
        ok -> % not find return enter point
            get(?pd_cfg_enter);
        P -> P
    end.




players_fold(Fun) ->
    com_util:fold(0,
        get(?pd_player_max_id),
        fun(Idx, _Acc) ->
            case ?get_agent(Idx) of
                ?undefined -> _Acc;
                A ->
                    Fun(A, _Acc)
            end
        end,
        nil).




%% @doc 区域伤害,用于大炮,等特殊攻击
%% Fu/2(Agent, Acc)
%%area_agents_foreach(Fn, A, {Ox,Oy}, Radius) ->
%%%% TODO 裁剪为圆形
%%W=get(?pd_map_width),
%%H=get(?pd_map_height),

%%lists:foreach(fun(Point) ->
%%case scene_aoi:get_p_point(Point) of
%%?undefined -> ok;
%%Sets ->
%%gb_sets:fold(fun(Idx, _) ->
%%case ?get_agent(Idx) of
%%?undefined -> ok;
%%A ->
%%Fn(A)
%%end
%%end,
%%nil,
%%Sets)
%%end
%%end,
%%[{X,Y} || X <- lists:seq(Ox-Radius, Ox+Radius), X < W, X >=0,
%%Y <- lists:seq(Oy-Radius, Oy+Radius), Y < H, Y >=0]).




%%get_scene_time_limit(SceneId) ->
%%case lookup_scene_cfg(SceneId,#scene_cfg.limit) of
%%Time when Time >0 ->
%%Time * 60;
%%_->
%%0
%%end.

%%test_dict2() ->
%%?assertEqual(get_dict2(1, 1, 1, 1, nil), nil),
%%?assertEqual(get_dict2(1, 1, 2, 1, nil), ?D_L),
%%?assertEqual(get_dict2(1, 1, 0, 1, nil), ?D_R),
%%?assertEqual(get_dict2(1, 1, 1, 100, nil), ?D_D),
%%?assertEqual(get_dict2(1, 93, 1, 1, nil), ?D_U),
%%?assertEqual(get_dict2(21, 33, 1, 1, nil), ?D_LU),
%%?assertEqual(get_dict2(1, 10, 2, 20, nil), ?D_RD),
%%?assertEqual(get_dict2(100, 23, 1, 99, nil), ?D_LD),
%%?assertEqual(get_dict2(10, 32, 1, 100, nil), ?D_LD),
%%?assertEqual(get_dict2(10, 10, 30, 1, nil), ?D_RU),
%%ok.
