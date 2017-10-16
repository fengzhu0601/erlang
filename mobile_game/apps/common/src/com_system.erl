%%%-------------------------------------------------------------------
%%% @author zl
%%% @doc
%%%
%%% @end
%%%-------------------------------------------------------------------

-module(com_system).

-export([etop_start_sort_by_mem/0
         ,etop_start_sort_by_reds/0
         ,etop_start_sort_by_msg/0
         
         ,start_cover/0
         ,cover_out/1


         ,xref_check/0
        ]).

etop_start_sort_by_reds() ->
    spawn(fun() -> etop:start([{output, text}, {lines, 15},{sort, reductions}]) end).
etop_start_sort_by_msg() ->
    spawn(fun() -> etop:start([{output, text}, {lines, 15}, {sort, msg_q}]) end).
etop_start_sort_by_mem() ->
    spawn(fun() -> etop:start([{output, text}, {lines, 15}, {sort, memory}]) end).


start_cover() ->
    cover:compile_beam_directory("ebin").

cover_out(Module) ->
    case cover:analyse_to_file(Module, [html]) of
        {ok, File} ->
            os:cmd("firefox " ++ File);
        E ->
            E
    end.

xref_check() ->
    xref:d("ebin").
