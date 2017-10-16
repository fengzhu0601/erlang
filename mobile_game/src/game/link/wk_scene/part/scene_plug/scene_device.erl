%%%-------------------------------------------------------------------
%%% @author zl
%%% @doc 场景机关设备
%%%
%%% @end
%%%-------------------------------------------------------------------

-module(scene_device).

%-include_lib("config/include/config.hrl").

-include("inc.hrl").
-include("scene.hrl").
-include("scene_agent.hrl").
-include("scene_mod.hrl").
-include("load_cfg_scene.hrl").
-include("load_cfg_scene_device.hrl").

%% TODO destory cancel timer
%% 

%%-record(scene_device_cfg, {scene_id
%%    , id
%%    , position %%{X,Y}
%%    , range %% 防守范围{X, Y}
%%    , interval %%释放间隔
%%    , hit_times = ?none %% 自身受伤害次数
%%    , skill_id %% 技能id
%%    , release_times = ?infinity %% 释放的次数
%%    , release_delay = 0 %% msec
%%    , hit_per %% 伤害半分比
%%}).

%% 机关实例
-record(device, {id %% scene_device_cfg.id
    , hit_times
    , remain_times
    , timer = ?none
}).

new_device(#scene_device_cfg{id = Id, hit_times = Hit, release_times = Rt}) ->
    #device{id = Id, hit_times = Hit, remain_times = Rt}.

-define(WATCH_TIME, 2000). %%查看敌人时间间隔
%% watch_enemy -> has_enemy -> release_skill -> interval -> watch_enemy
%%             -> not_enemy -> watch_enemy

-define(pd_device_mng, pd_device_mng). %% gb_trees {CfgKey, #device{}}

init(#scene_cfg{id = Id}) ->
    DeviceList = load_cfg_scene_device:lookup_group_scene_device_cfg(#scene_device_cfg.scene_id, Id),

    ?DEBUG_LOG("all DeviceList ~p", [DeviceList]),

    ?pd_new(?pd_device_mng, gb_trees:empty()),

    lists:foreach(fun(CfgKey) ->
        Cfg = load_cfg_scene_device:lookup_scene_device_cfg(CfgKey),
        watch_enemy(new_device(Cfg), ?WATCH_TIME)
    end,
        DeviceList),

    ok.

uninit(_) -> ok.



handle_msg(Msg) ->
    ?ERROR_LOG("unknown msg ~p", [Msg]).

watch_enemy(#device{id = Id} = Dev, Time) ->
    %% assert(Dev#device.timer not setting
    Timer =
        scene_eng:start_timer(Time,
            ?MODULE,
            {watch_enemy, {get(?pd_cfg_id), Id}}),
    mng_update_device(Dev#device{timer = Timer}).

mng_update_device(Dev) ->
    put(?pd_device_mng,
        gb_trees:enter({get(?pd_cfg_id), Dev#device.id}, Dev, get(?pd_device_mng))).

%% TODO
is_enemy(A) ->
    A#agent.idx > 0.


release_skill(Cfg) ->
    CfgKey = load_cfg_scene_device:cfg_key(Cfg),
    case gb_trees:lookup(CfgKey, get(?pd_device_mng)) of
        ?none ->
            ?ERROR_LOG("device ~p release skill but not exist", [CfgKey]);
        {?value, Dev} ->
            scene_fight:device_release_skill(Dev#device.id,
                Cfg#scene_device_cfg.position,
                Cfg#scene_device_cfg.skill_id),

            case Dev#device.remain_times of
                ?infinity ->
                    ok;
                1 ->
                    mng_update_device(Dev#device{remain_times = 0});
                N ->
                    watch_enemy(Dev#device{remain_times = N - 1},
                        load_cfg_scene_device:lookup_scene_device_cfg(CfgKey, #scene_device_cfg.interval * 1000))
            end
    end.



handle_timer(_, {watch_enemy, CfgKey}) ->
    #scene_device_cfg{release_delay = ReleaceDelay,
        position = {Ox, Oy},
        range = {Rx, Ry}} = Cfg = load_cfg_scene_device:lookup_scene_device_cfg(CfgKey),

    %% TODO hack
    case map_observers:in_range_agents_fold(fun(A, Acc) ->
        case is_enemy(A) of
            ?true -> [A | Acc];
            ?false -> Acc
        end
    end,
        {Ox - Rx, Ox + Rx},
        {Oy - Rx, Oy + Ry},
        [])
    of
        [] -> %% not find enemy
            ?debug_log_scene_device("device ~p not find enemy", [CfgKey]),
            {?value, Dev} = gb_trees:lookup(CfgKey, get(?pd_device_mng)),
            watch_enemy(Dev, ?WATCH_TIME);
        _EnemyList when ReleaceDelay =:= 0 ->
            release_skill(Cfg);
        _EnemyList ->
            scene_eng:start_timer(ReleaceDelay, ?MODULE, {release_skill, CfgKey})
    end,
    ok;



handle_timer(_, {release_skill, CfgKey}) ->
    release_skill(load_cfg_scene_device:lookup_scene_device_cfg(CfgKey)),
    ok;

handle_timer(_, Msg) ->
    ?ERROR_LOG("unknown msg ~p", [Msg]).

%%%% TODO auto gen
%%cfg_key(#scene_device_cfg{scene_id = SId, id = Id}) ->
%%    {SId, Id}.


%%load_config_meta() ->
%%    [
%%        #config_meta{record = #scene_device_cfg{},
%%            fields = ?record_fields(scene_device_cfg),
%%            keypos = [#scene_device_cfg.scene_id, #scene_device_cfg.id],
%%            file = "scene_device.txt", %%file = {"scene_device", ".txt"},
%%            groups = [#scene_device_cfg.scene_id],
%%            verify = fun verify/1}
%%    ].
%%
%%verify(#scene_device_cfg{scene_id = SId, id = Id, position = Pos,
%%    skill_id = _SkillId,
%%    hit_times = _Hit,
%%    release_times = ReleaseTimes,
%%    hit_per = _HitPer,
%%    interval = Interval} = Cfg) ->
%%    CfgKey = cfg_key(Cfg),
%%    ?check(scene:is_exist_scene_cfg(SId), "scene_devic.txt [~p] scene_id ~p 没有找到对应场景", [CfgKey, SId]),
%%    MapId = scene:get_map_id(SId),
%%    ?check(scene_map:is_walkable(MapId, Pos), "scene_device.txt [~p] positon ~p 不可行走", [CfgKey, Pos]),
%%
%%    ?check(?is_pos_integer(Id), "scene_device.txt [~p]　id 无效", [CfgKey]),
%%    ?check(?is_pos_integer(Interval), "scene_device.txt [~p] interval ~p无效", [CfgKey, Interval]),
%%    ?check(ReleaseTimes =:= ?infinity orelse ?is_pos_integer(ReleaseTimes), "scene_device.txt [~p] release_times ~p 无效", [CfgKey, ReleaseTimes]),
%%
%%    ok.
