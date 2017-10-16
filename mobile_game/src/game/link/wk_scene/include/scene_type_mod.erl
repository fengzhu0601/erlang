%%%-------------------------------------------------------------------
%%% @author zl
%%% @doc 场景玩法层用于实现不同的玩法(对应场景类型)
%%%       每个场景只有一种scenen_type_mod
%%%
%%%
%%% @end
%%%-------------------------------------------------------------------

-module(scene_type_mod).

-include("game_def.hrl"). %% scene_type_id

-callback type_id() -> scene_type_id().

%% @doc 初始化模块 会在所有scene_mod 初始化完成后调用
-callback init(scene:scene_cfg()) -> no_return().

%% @doc scene 进程结束时调用化,
-callback uninit(scene:scene_cfg()) -> no_return().

%% @doc 处理异步消息
-callback handle_msg(Msg :: any()) -> no_return().

%% @doc 处理定时器超时.
-callback handle_timer(TRef :: _, Msg :: any()) -> no_return().

