-module(scene_sup).

-behaviour(supervisor).


%% API
-export([start_link/0,
    start_scene/1,
    start_scene/2,
    start_client_scene/3
]).

%% Supervisor callbacks
-export([init/1]).

%% Helper macro for declaring children of supervisor
-define(CHILD(I, Type), {I, {I, start_link, []}, transient, 5000, Type, [I]}).

-include("inc.hrl").
-include("scene.hrl").
-include("load_cfg_scene.hrl").

start_client_scene(SceneId, IsRealMon, ExArg) ->
    case load_cfg_scene:get_pid(SceneId) of
        ?none ->
            case load_cfg_scene:lookup_scene_cfg(load_cfg_scene:get_config_id(SceneId)) of
                ?none ->
                    ?err(?none_cfg);
                Cfg ->
                    case supervisor:start_child(?MODULE, [{Cfg#scene_cfg{id = SceneId, run_arg = ExArg}, IsRealMon}]) of
                        {ok, Pid} ->
                            Pid;
                        Err ->
                            ?err(Err)
                    end
            end;
        Pid ->
            ?WARN_LOG("scene ~p already started", [SceneId]),
            Pid
    end.


start_scene(SceneId) ->
    start_scene(SceneId, #run_arg{}).

%% @doc 可以传递一个参数
-spec start_scene(scene_id(), any()) -> Pid :: pid()| {error, _}.
start_scene(SceneId, ExArg) ->
    case load_cfg_scene:get_pid(SceneId) of
        ?none ->
            case load_cfg_scene:lookup_scene_cfg(load_cfg_scene:get_config_id(SceneId)) of
                ?none ->
                    ?err(?none_cfg);
                Cfg ->
                    case supervisor:start_child(?MODULE, [Cfg#scene_cfg{id = SceneId, run_arg = ExArg}]) of
                        {ok, Pid} -> Pid;
                        Err -> ?err(Err)
                    end
            end;
        Pid ->
            ?WARN_LOG("scene ~p already started", [SceneId]),
            Pid
    end.


start_link() ->
    {ok, _Pid} = Result = supervisor:start_link({local, ?MODULE}, ?MODULE, []),
    com_prog:create(scene_group),
    lists:foreach(
        fun(CfgId) ->
                Cfg = load_cfg_scene:lookup_scene_cfg(CfgId),
                case supervisor:start_child(?MODULE, [Cfg]) of
                    {ok, _} -> ok;
                    Err -> ?ERROR_LOG("Err start scenee ~p ~p", [CfgId, Err])
                end
        end,
        global_data:get_normal_scenes()
    ),
    Result.

%% ===================================================================
%% Supervisor callbacks
%% ===================================================================
init([]) ->
    {ok, {{simple_one_for_one, 100, 10}, [?CHILD(scene_eng, worker)]}}.
