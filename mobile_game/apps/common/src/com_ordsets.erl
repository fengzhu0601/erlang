%%%-------------------------------------------------------------------
%%% @author zl
%%% @doc
%%%
%%% @end
%%%-------------------------------------------------------------------

-module(com_ordsets).

-export([osn/2]).

%% 比较两个ordsets 返回 {O S N}
%%  O + S = Set1
%%  S + N = Set1
-spec osn(Ordset1::ordsets:ordset(_), Ordset2::ordsets:ordset(_)) -> {OSet, SSet, NSet} when
      OSet :: ordsets:ordset(_),
      SSet :: ordsets:ordset(_),
      NSet :: ordsets:ordset(_).
osn(Set1, Set2) ->
    osn__(Set1, Set2, {[], [], []}).

osn__([E1|Es1], [E2|_]=Set2, {O,S,N})  when E1 < E2 ->
    osn__(Es1, Set2, {[E1 |O], S, N});
osn__([E1|_]=Set1, [E2|Es2], {O,S,N})  when E1 > E2 ->
    osn__(Set1, Es2, {O, S, [E2 |N]});
osn__([E|Es1], [E|Es2], {O,S,N}) ->
    osn__(Es1, Es2, {O, [E|S], N});
osn__([], Set2, {O,S,N}) ->
    {lists:reverse(O), lists:reverse(S), lists:reverse(N) ++ Set2};
osn__(Set1, [], {O,S,N}) ->
    {lists:reverse(O) ++ Set1, lists:reverse(S), lists:reverse(N)};
osn__([], [], {O,S,N}) ->
    {lists:reverse(O), lists:reverse(S), lists:reverse(N)}.
