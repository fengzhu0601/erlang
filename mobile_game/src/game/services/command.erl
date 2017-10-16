%% coding: utf-8
-module(command).
%%-on_load(on_load/0).

%%% @doc
%%% 所有需要导出的命令函数必须写一个 以 _checkcmd 为后缀的检查函数,
%%% 用了检查函数来检查命令的参数是否正确.
%%%
%%%

-include_lib("config/include/config.hrl").
-include_lib("common/include/com_log.hrl").


-include("inc.hrl").

-record(command_cfg, {
    id,
    mfa
}).

-export([exec/1]).

%%on_load() ->
%%%TODO cmd mode
%%ok.

exec(none) -> ok;
exec(CmdId) when is_integer(CmdId) ->
    case lookup_command_cfg(CmdId) of
        ?none ->
            ?ERROR_LOG("exec cmd ~p but can not find", [CmdId]);
        #command_cfg{mfa = {M, F, A}} ->
            ?DEBUG_LOG("player ~p exec cmd ~p", [?pname(), {M, F, A}]),
            erlang:apply(M, F, A)
    %com_util:safe_apply(M,F,A)
    end;

exec(CmdList) when is_list(CmdList) ->
    [exec(CmdId) || CmdId <- CmdList],
    ok.


load_config_meta() ->
    [
        #config_meta{record = #command_cfg{},
            fields = record_info(fields, command_cfg),
            file = "command.txt",
            keypos = #command_cfg.id,
            verify = fun verify/1}
    ].


%% TODO
verify(#command_cfg{id = Id, mfa = {M, F, A}}) ->
    {module, M} = code:ensure_loaded(M),

    N = length(A),
    ?check(erlang:function_exported(M, F, N), "command[~p]方法没有找到! ~p~n", [Id, {M, F, A}]),
    case N of
        0 ->
            ok;
        _ ->
            CheckFun = list_to_existing_atom(atom_to_list(F) ++ "_checkcmd"),

            ?check(erlang:function_exported(M, CheckFun, N + 1),
                "command对应的的check方法没有找到! ~p~n", [{Id, {M, F, A}}]),
            apply(M, CheckFun, [Id | A])
    end,
    ok;

verify(_R) ->
    ?ERROR_LOG("command 配置 ~p 错误格式", [_R]),
    exit(bad).
