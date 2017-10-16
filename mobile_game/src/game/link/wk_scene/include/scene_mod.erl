%%%-------------------------------------------------------------------
%%% @author zl
%%% @doc 场景模块behaviour
%%%
%%% @end
%%%-------------------------------------------------------------------

-module(scene_mod).


%% @doc 初始化模块
-callback init(scene:scene_cfg()) -> no_return().

%% @doc scene 进程结束时调用化
-callback uninit(scene:scene_cfg()) -> no_return().

%% @doc 处理其他进程的同步调用
%%-callback handle_call(From::_, Msg :: any()) -> Replay :: any().

%% @doc 处理异步消息
-callback handle_msg(Msg :: any()) -> no_return().

%% @doc 处理定时器超时.
-callback handle_timer(TRef :: _, Msg :: any()) -> no_return().

%% player enter secne
%% player leave secne
