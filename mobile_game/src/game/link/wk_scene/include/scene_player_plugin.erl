%%%-------------------------------------------------------------------
%%% @author zl
%%% @doc 场景玩家插件behavior
%%%
%%% @end
%%%-------------------------------------------------------------------

-module(scene_player_plugin).

-include("inc.hrl").
-include("scene.hrl").
-include("scene_agent.hrl").


%% API
-export([set_player_plugin/1,
    del_player_plugin/0]).


%% used by cb
-export([enter_scene/1,
    leave_scene/1,
    die/2,
    kill_agent/2
]).



%% TODO after before
%% @doc 玩家进入场景完成视野初始化,返回给player process之前回调
%%      这是player 的agent已经存在
-callback player_enter_scene(#agent{}) -> _.

%% @doc 玩家主動離開場景時調用，此時玩家已經不在場景中
-callback player_leave_scene(#agent{}) -> _.

%% @doc 玩家死亡时回调
-callback player_die(Self :: #agent{}, Killer :: #agent{}) -> _.

%% @doc 杀死一个agent时调用, 这是被杀死的agent已经是死亡状态,或者已经离开场景
-callback player_kill_agent(Self :: #agent{}, Killee :: #agent{}) -> _.


%% @doc 设置玩家场景插件
%% 返回原来的 plugin
set_player_plugin(PluginName) when is_atom(PluginName) ->
    put(?pd_player_plugin, PluginName).

del_player_plugin() ->
    erase(?pd_player_plugin).


enter_scene(A) ->
    case get(?pd_player_plugin) of
        ?undefined -> ok;
        Plugin -> Plugin:player_enter_scene(A)
    end.

leave_scene(A) ->
    case get(?pd_player_plugin) of
        ?undefined ->
            ok;
        Plugin ->
            Plugin:player_leave_scene(A)
    end.

die(Self, Killer) ->
    case get(?pd_player_plugin) of
        ?undefined -> ok;
        Plugin -> Plugin:player_die(Self, Killer)
    end.

kill_agent(Self, Killee) ->
    case get(?pd_player_plugin) of
        ?undefined -> ok;
        Plugin -> Plugin:player_kill_agent(Self, Killee)
    end.


