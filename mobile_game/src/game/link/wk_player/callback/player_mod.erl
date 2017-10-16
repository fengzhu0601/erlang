%%% coding:utf-8
%%%-------------------------------------------------------------------
%%% @author zl
%%% @doc player 模块行为定义
%%%
%%% @end
%%%-------------------------------------------------------------------

-module(player_mod).

-include("type.hrl").


%% TODO player_mod_info




%% @doc 首次创建人物时候调用 不能调用其他模块的数据，只有 ?pd_name ?pd_job 这两个进程字典可用
-callback create_mod_data(SelfId :: player_id()) -> ok | {error, Why :: term()}.

%% @doc 加载本模块数据，这这里只能够加载自己模块的数据，不能操作其他模块
%% 也不能发消息.
-callback load_mod_data(SelfId :: player_id()) -> ok | {error, Why :: term()}.

%% @doc init_data 后调用
%% 需要发送给client 初始化数据
-callback init_client() -> no_return().

%% @doc 进入游戏后调用
-callback online() -> any().

%% @doc 进入场景时发送给其他玩家的信息
-callback view_data(Pkg) -> Pkg when Pkg :: binary().

%% @doc 处理游戏事件帧, 比如定时更新数据, 更新排行,等等
-callback handle_frame(Name :: term()) -> _.

%% @doc 处理游戏内部其他模块的msg.
-callback handle_msg(mod_id(), Msg :: term()) ->
    {error, _} |
    {'@offline@', Reason :: atom()} | _.

%% @doc 玩家下线时被调用。
-callback offline(SelfId :: player_id()) -> _.

%% @doc 数据回写到数据库
-callback save_data(SelfId :: player_id()) -> _.