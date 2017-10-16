%%%-------------------------------------------------------------------
%%% @author clark
%%% @doc
%%% 封装otp进程创建操作(匿名进程做不了监控进程)
%%% @end
%%%-------------------------------------------------------------------
-module(otp_util).
-author("clark").

%% ------------------------------------------------------------------
%% Internal Function Definitions
%% ------------------------------------------------------------------
-export
([
    start_link/2                        %% 创建进程
    , start_link/3                      %% 创建进程
    , start_child/2                     %% 创建匿名子进程(参数优先级高于根结点配置)
    , start_child/3                     %% 创建指定子进程(参数优先级高于根结点配置)
    , link_declaration/5                %% 匿名子进程声明
    , link_declaration/6                %% 指定子进程声明
    , com_sup_link_declaration/3        %% 匿名子进程声明
    , com_wk_link_declaration/2         %% 指定子进程声明
    , wk_link_declaration/3             %% 指定子进程名字的进程声明
]).

%%　子进程回调
-export
([
    callback_starting/1
    , callback_starting/2
]).

-export
([
    self_exit/0
]).


-define(SUP,        supervisor).
-define(WK,         worker).
-define(ANONYM,     anonym).


%% ===================================================================
%% start link
%% ===================================================================
%% 创建进程( 成功则回调init([_RootArgs, _RunArgs]) )
start_link(Mod, RunArgs) ->
    start_link(Mod, Mod, RunArgs).
start_link(ProgressName, Mod, RunArgs) ->
    CfgArgs = [],
    InitArgs = [ CfgArgs, RunArgs ],
    supervisor:start_link({local, ProgressName}, Mod, InitArgs).

%% 创建子进程
start_child(RootProgressName, RunArgs) ->
    supervisor:start_child(RootProgressName, [{?ANONYM, RunArgs}]).
start_child(RootProgressName, ProgressName, RunArgs) ->
    supervisor:start_child(RootProgressName, [{ProgressName, RunArgs}]).

%% 子进程声明(Type会被用于验证init的返回值)
link_declaration(Mod, RootArgs, Type, ResetType, WaitTime) ->
    {
        Mod,
        {otp_util, callback_starting, [{Type, Mod, ?ANONYM, RootArgs}]},
        ResetType, WaitTime, Type, [Mod]
    }.
link_declaration(ProgressName, Mod, RootArgs, Type, ResetType, WaitTime) ->
    {
        ProgressName,
        {otp_util, callback_starting, [{Type, Mod, ProgressName, RootArgs}]},
        ResetType, WaitTime, Type, [Mod]
    }.

com_sup_link_declaration(ProgressName, Mod, RootArgs) ->
    link_declaration(ProgressName, Mod, RootArgs, supervisor, permanent, 5000).

com_wk_link_declaration(Mod, RootArgs) ->
    link_declaration(Mod, RootArgs, worker, temporary, 5000).

wk_link_declaration(ProgressName, Mod, RootArgs) ->
    link_declaration(ProgressName, Mod, RootArgs, worker, temporary, 5000).

%% ===================================================================
%% callbacks
%% ===================================================================
%% 通过根结点配置创建匿名子监控进程
callback_starting({supervisor, Mod, ?ANONYM, ArgsFromCfg}) ->
    supervisor:start_link(Mod, [ArgsFromCfg, []]);
%% 通过根结点配置创建指定子监控进程
callback_starting({supervisor, Mod, ProgressNameFromCfg, ArgsFromCfg}) ->
    supervisor:start_link({local, ProgressNameFromCfg}, Mod, [ArgsFromCfg, []]);
%% 通过根结点配置创建匿名子工作进程
callback_starting({worker, Mod, ?ANONYM, ArgsFromCfg}) ->
    gen_server:start_link(Mod, [ArgsFromCfg, []], []);
%% 通过根结点配置创建指定子工作进程
callback_starting({worker, Mod, ProgressNameFromCfg, ArgsFromCfg}) ->
    gen_server:start_link({local, ProgressNameFromCfg}, Mod, [ArgsFromCfg, []], []);
callback_starting(_RootArgs) ->
    {error, error_args}.

%% 通过用户创建匿名子进程
callback_starting({supervisor, Mod, _, ArgsFromCfg}, {?ANONYM, ArgsFromRun}) ->
    supervisor:start_link(Mod, [ArgsFromCfg, ArgsFromRun]);
%% 通过用户创建指定子进程
callback_starting({supervisor, Mod, _, ArgsFromCfg}, {ProgressNameFromRun, ArgsFromRun}) ->
    supervisor:start_link({local, ProgressNameFromRun}, Mod, [ArgsFromCfg, ArgsFromRun]);
%% 通过用户创建匿名子进程
callback_starting({worker, Mod, _, ArgsFromCfg}, {?ANONYM, ArgsFromRun}) ->
    gen_server:start_link(Mod, [ArgsFromCfg, ArgsFromRun], []);
%% 通过用户创建指定子进程
callback_starting({worker, Mod, _, ArgsFromCfg}, {ProgressNameFromRun, ArgsFromRun}) ->
    gen_server:start_link({local, ProgressNameFromRun}, Mod, [ArgsFromCfg, ArgsFromRun], []);
callback_starting(_RootArgs, _RunArgs) ->
    {error, error_args}.


self_exit() ->
    erlang:exit(normal).