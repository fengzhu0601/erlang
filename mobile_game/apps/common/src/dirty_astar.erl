%%%------------------------------------------------------------------- 
%%% @author zl
%%% @doc A* search path. 脏操作,会写入进程字典
%%%
%%% @end
%%%-------------------------------------------------------------------

-module(dirty_astar).

-export([search/3]).

-define(make_info(S, G, H, PP), {S, G, H, PP}).
-define(point(P), {astart, P}).

-define(G_HV, 10).
-define(G_DN, 14).


h({X1, Y1}, {X2, Y2}) ->
    (abs(X1-X2) + abs(Y1-Y2)) * ?G_HV.
    %%math:pow((X1 - X2) * ?G_HV, 2.0) + math:pow((Y1 - Y2) * ?G_HV, 2.0).

-spec search(_, _, _) -> false | [{_,_}].
search(StrP, DstP, IsWalkableFn) ->
    %%?assert(?ptype() =/= scene),
    erlang:erase(), %% clean all pd
    StrH = h(StrP, DstP),
    put(?point(StrP), ?make_info(open, 0, StrH, start)),
    find_path(IsWalkableFn, gb_sets:insert({StrH, StrP}, gb_sets:empty()), DstP).

find_path(IsWalkableFn, FStore, Dst) ->
    case gb_sets:is_empty(FStore) of
        true ->
            false;
        false ->
            %% 使用链表还可以优化 order_list
            case gb_sets:take_smallest(FStore) of
                {{_, Dst}, _} ->
                    reconstruct_path(Dst, []);
                {{_, P}, NewFStore} ->
                    {Px, Py} =P,
                    {_, G, H, PP} = get(?point(P)),
                    %%io:format("~p insert close ~n", [P]),
                    put(?point(P), ?make_info(close, G, H, PP)),
                    F8=
                    check_neighbor(IsWalkableFn, {Px,Py-1}, ?G_HV+G, P, Dst,
                    check_neighbor(IsWalkableFn, {Px,Py+1}, ?G_HV+G, P, Dst,
                    check_neighbor(IsWalkableFn, {Px-1,Py}, ?G_HV+G, P, Dst,
                    check_neighbor(IsWalkableFn, {Px+1,Py}, ?G_HV+G, P, Dst,
                    check_neighbor(IsWalkableFn, {Px-1,Py-1}, ?G_DN+G, P, Dst,
                    check_neighbor(IsWalkableFn, {Px-1,Py+1}, ?G_DN+G, P, Dst,
                    check_neighbor(IsWalkableFn, {Px+1,Py-1}, ?G_DN+G, P, Dst,
                    check_neighbor(IsWalkableFn, {Px+1,Py+1}, ?G_DN+G, P, Dst, NewFStore)))))))), 
                    find_path(IsWalkableFn, F8, Dst)
            end
    end.

-spec check_neighbor(_,_,_,_,_, gb_sets:gb_sets()) -> gb_sets:gb_sets().
check_neighbor(IsWalkableFn, P, NewG, PP, E, FStore) ->
    case get(?point(P)) of
        undefined ->
            case IsWalkableFn(P) of
                true ->
                    H = h(P, E),
                    put(?point(P), ?make_info(open, NewG, H, PP)),
                    gb_sets:insert({NewG+H, P}, FStore);
                false ->
                    put(?point(P), block),
                    FStore
            end;
        block -> FStore;
        {open, G, H, _} ->
            if NewG < G ->
                   put(?point(P), ?make_info(open, NewG, H, PP)),
                   gb_sets:insert({NewG+H, P},
                                  gb_sets:delete({G+H, P}, FStore));
               true ->
                   FStore
            end;
        {close, _, _, _} -> FStore
    end.


reconstruct_path(P, Path) ->
    case get(?point(P)) of
        {_, _, _, start} ->
            [P | Path];
        {_, _, _, PP} ->
            reconstruct_path(PP, [P | Path])
    end.
