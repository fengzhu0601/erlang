%%%-------------------------------------------------------------------
%%% @author zl
%%% @doc 提供一些ets 没有的函数
%%%
%%% @end
%%%-------------------------------------------------------------------

-module(com_ets).
-export([
    foreach/2,
    is_empty/1,
    keys/1,
    keys/2,
    to_list/1,
    table_size/1,
    table_memory/1,
    show_memory_info/0
]).

-include_lib("stdlib/include/ms_transform.hrl").
%% dsl-dsl-dsl-dsl-dsl-dsl-dsl
%% @doc get all objects keys.
-spec keys(atom()) -> [term()].
keys(Table) ->
    ets:safe_fixtable(Table, true),
    keys__(Table,[], ets:first(Table)).
keys__(Table, Keys,'$end_of_table') ->
    ets:safe_fixtable(Table, false),
    Keys;
keys__(Table, Keys, Key) ->
    keys__(Table, [Key | Keys],  ets:next(Table, Key)).


%% 比keys/1 块
keys(Tab, Fs) ->
    Kpos = ets:info(Tab, keypos),
    T = erlang:make_tuple(Fs, '_'),
    T2 = erlang:setelement(Kpos,T, '$1'),
    ets:select(Tab, [{T2, [], ['$1']}]).


%% @doc like call func with each table Object.
-spec foreach(Func, Tab) -> ok when
      Func :: fun((tuple()) -> ok),
      Tab :: ets:tab().

foreach(F, T) ->
    ets:safe_fixtable(T, true),
    First = ets:first(T),
    try
        foreach__(F, First, T)
    after
        ets:safe_fixtable(T, false)
    end.

-compile({inlien, [is_empty/1]}).
%% @doc return tab is empty. XXX first/1 is better?
-spec is_empty(TableName :: atom()) -> boolean().
is_empty(T) ->
    0 =:= ets:info(T, size).

-compile({inlien, [to_list/1]}).
-spec to_list(TableName:: atom()) -> [term()].
to_list(Tab) ->
    ets:select(Tab, ets:fun2ms(fun(Rom) -> Rom end)).

%% @doc return table objects count.
table_size(Tab) ->
    ets:info(Tab, size).

table_memory(Tab) ->
    case ets:info(Tab, memory) of
        undefined ->
            undefined;
        N ->
            erlang:system_info(wordsize) * N
    end.

%% show max use memory ets
show_memory_info() ->
    io:format("========Tid=========================Memory-Used(B)=======\n"),
    lists:foreach(fun({Tid, Memory}) when Memory > 1048576 ->
                          io:format("~-38w ~B ~5B(MB)\n", [Tid, Memory, Memory div 1048576]);
                     ({Tid, Memory}) when Memory > 1024 ->
                          io:format("~-38w ~B ~5B(KB)\n", [Tid, Memory, Memory div 1024]);
                     ({Tid, Memory}) ->
                          io:format("~-38w ~B\n", [Tid, Memory]) end,
                  lists:reverse(
                    lists:keysort(2,[{T, ets:info(T, memory)} || T <- ets:all()]))).


%%======================================================================
%% Internel Func
%%======================================================================

foreach__(_F, '$end_of_table', _T) ->
    ok;
foreach__(F, K, T) ->
    [Row] = ets:lookup(T, K),
    F(Row),
    foreach__(F, ets:next(T, K), T).
