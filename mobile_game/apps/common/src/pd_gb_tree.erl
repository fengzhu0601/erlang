%%%-------------------------------------------------------------------
%%% @author zl
%%% @doc 在进程字典中使用 gb_trees 的包装函数
%%%
%%% @end
%%%-------------------------------------------------------------------

-module(pd_gb_tree).

-compile({no_auto_import, [erase/1, size/1]}).

-export([new/1, new_from_list/2, new_from_orddict/2,
         is_empty/1, is_key/2,
         size/1, clear/1, count/2,
         erase/1,
         insert/3,
         enter/3,
         update/3,
         update_counter/3,
         %%update_element/3,
         delete/1,
         delete/2,
         delete_any/2,
         keys/1,
         values/1,
         value/2,
         value/3,
         to_list/1, foreach/2, fold/3, map/2]).


%%-----------------------------------------------------
%%% API
%%new(Key).
%%new_from_list(Key,List).
%%erase(Key)

%%is_empty(Key).
%%is_key(Key, E).
%%keys

%%size(Key)
%%clear(Key) -> 返回原先的数据
%%count(Key, V) -> 返回个数

%% value(Key, K) -> V
%% values/3


%%enter(Key, K, V)
%%update(Key,K,NewV)
%%update_element(Key,K,NewV)
%%update_counter

%%delete(Key, K)

%%to_list(Key)
%%foreach(Key, Fun)
%%fold(Key, Fun, Acc0)
%%filter() TODO
%%-----------------------------------------------------


-compile({inline, [new/1]}).
%% @doc create a set.
-spec new(Key::term()) -> ok.
new(Key) ->
    case erlang:get(Key) of
        undefined ->
            erlang:put(Key, gb_trees:empty())
    end,
    ok.

-compile({inline, [new_from_list/2]}).
%% @doc create a set from the elements in List.
-spec new_from_list(Key::term(), [{K, V}]) -> ok when
      K :: term(), V :: term().
new_from_list(Key, List) ->
    case erlang:get(Key) of
        undefined ->
            Ord = orddict:from_list(List),
            erlang:put(Key, gb_trees:from_orddict(Ord))
    end,
    ok.

-compile({inline, [new_from_orddict/2]}).
-spec new_from_orddict(Key::term(), orddict:orddict()) -> ok.
new_from_orddict(Key, ODict) ->
    case erlang:get(Key) of
        undefined ->
            erlang:put(Key, gb_trees:from_orddict(ODict))
    end,
    ok.

-compile({inline, [erase/1]}).
%% @doc erase a set contains return elements as a list.
-spec erase(Key::term()) -> undefined | [{K, V}] when
      K::term(), V::term().
erase(Key) ->
    case erlang:get(Key) of
        undefined ->
            undefined;
        Sets ->
            erlang:erase(Key),
            gb_trees:to_list(Sets)
    end.



-compile({inline, [is_empty/1]}).
%% @doc checks the key container is empty, the container must exist.
-spec is_empty(Key::term()) -> boolean().
is_empty(Key) ->
    case get(Key) of
        undefined ->
            erlang:error({key_not_exist, Key});
        Sets ->
            gb_trees:is_empty(Sets)
    end.

-compile({inline, [is_key/2]}).
%% @doc wrap gb_trees:is_defined
-spec is_key(Key::term(), K::term()) -> boolean().
is_key(Key, K) ->
    gb_trees:is_defined(K, erlang:get(Key)).


-compile({inline, [size/1]}).
%% @doc return the number of elements
-spec size(Key::term()) -> non_neg_integer().
size(Key) ->
    gb_trees:size(erlang:get(Key)).

-compile({inline, [clear/1]}).
%% @doc clear the contents, return contents
-spec clear(Key::term()) -> [{term(), term()}].
clear(Key) ->
    List = to_list(Key),
    erlang:put(Key, gb_trees:empty()),
    List.

-compile({inline, [to_list/1]}).
%% @doc return the elements of set as a list
-spec to_list(Key::term()) ->  [{term(), term()}].
to_list(Key) ->
    gb_trees:to_list(erlang:get(Key)).

-compile({inline, [count/2]}).
%% @doc returns the number of elements equal specific K
-spec count(Key::term(), K::term()) -> 0 | 1.
count(Key, K) ->
    case is_key(Key, K) of
        true -> 1;
        false -> 0
    end.

-compile({inline, [count/2]}).
%% @doc wrap gb_trees:keys
-spec keys(Key::term()) -> [term()].
keys(Key) ->
    gb_trees:keys(get(Key)).

-compile({inline, [values/1]}).
%% @doc wrap gb_trees:values
-spec values(Key::term()) -> [term()].
values(Key) ->
    gb_trees:values(get(Key)).

-compile({inline, [insert/3]}).
insert(Key, K, V) ->
    erlang:put(Key, gb_trees:insert(K,V, get(Key))).

-compile({inline, [enter/3]}).
%% @doc insert a enter to map, if key is exist update the value.
%% return new tree
-spec enter(Key::term(), K::term(), V::term()) -> gb_trees:tree().
enter(Key, K,V) ->
    erlang:put(Key, gb_trees:enter(K,V, get(Key))).


-compile({inline, [update/3]}).
%% @doc wrap gb_trees:update/3, Assumes key is exits, more efficiency than enter.
-spec update(Key::term(), K::term(), V::term()) -> gb_trees:tree().
update(Key, K, NewV) ->
    erlang:put(Key, gb_trees:update(K, NewV, get(Key))).


%% @doc like ets:update_counter Assumes key is exits, return new value,
-spec update_counter(Key::term(), K::term(), Incr::integer()) -> integer();
                    (Key::term(), K::term(), {Pos::non_neg_integer(), Incr::integer()}) -> integer().
update_counter(Key, K, Incr) when is_integer(Incr)->
    NewV = value(Key, K) + Incr,
    _ = update(Key, K, NewV), %% dialyze bug
    NewV;

update_counter(Key, K, {Pos, Incr}) ->
    V = value(Key, K),
    NewV = erlang:setelement(Pos, V, erlang:element(Pos, V) + Incr),
    _ = update(Key, K, NewV), %% dialyze bug
    NewV.



%%% @doc like ets:update_element Assumes key is exits, return new value,
                                                %-spec update_element(Key::term(), K::term(), {Pos::non_neg_integer(), E::term()()}) -> term().
                                                %update_element(Key, K, {Pos, E})

-compile({inline, [delete/1]}).
delete(Key) ->
    erlang:erase(Key).

-compile({inline, [delete/2]}).
%% @doc delete a key-v pair, if key is exits, otherwise does nothing.
%% return new tree
-spec delete(Key::term(), K::term()) -> gb_trees:tree().
delete(Key, K) ->
    erlang:put(Key, gb_trees:delete(K, get(Key))).

-spec delete_any(Key::term(), K::term()) -> gb_trees:tree().
delete_any(Key, K) ->
    NTree = gb_trees:delete_any(K, get(Key)),
    erlang:put(Key, NTree),
    NTree.


-compile({inline, [value/2]}).
%% @doc looksup K in Tree, if K is exits return Value, or return `none'
-spec value(Key::term(), K::term()) -> term() | none.
value(Key, K) ->
    case gb_trees:lookup(K, get(Key)) of
        none ->
            none;
        {value, V} ->
            V
    end.

-compile({inline, [value/3]}).
%% @doc like value/2 but if key not exits return default value
-spec value(Key::term(), K::term(), DefaultV::term()) -> term().
value(Key, K, DefaultV) ->
    case gb_trees:lookup(K, get(Key)) of
        none ->
            DefaultV;
        {value, V} ->
            V
    end.

-compile({inline, [map/2]}).
%% @doc wrap gb_trees:map/2
                                                %-spec map(Key::term(), Function) -> Tree2::gb_trees:tree() when
                                                %Function :: fun((K :: term(), V1 :: term()) -> V2 :: term()).
map(Key, Fun) ->
    gb_trees:map(Fun, get(Key)).


%% @doc foreach
-spec foreach(Key::term(), Fun) -> ok when
      Fun :: fun((K::term(), V::term()) -> term()).
foreach(Key, Fun) ->
    Iter = gb_trees:iterator(get(Key)),
    foreach__(Fun, Iter).

%% @doc wrap fold
-spec fold(Key::term(), Fun, Acc0) -> Acc1 when
      Fun :: fun((K::term(), V::term(),  AccIn) -> AccOut),
      Acc0 :: T,
      Acc1 :: T,
      AccIn :: T,
      AccOut :: T.
fold(Key, Fun, Acc0) ->
    Iter = gb_trees:iterator(get(Key)),
    fold__(Fun, Acc0, Iter).




%%%================================================
%%% Internel funcs
%%%================================================

                                                %-spec none
foreach__(Fun, Iter) ->
    case gb_trees:next(Iter) of
        none ->
            ok;
        {K, V, Iter2} ->
            Fun(K, V),
            foreach__(Fun, Iter2)
    end.

fold__(Fun, AccIn, Iter) ->
    case gb_trees:next(Iter) of
        none ->
            AccIn;
        {K, V, Iter2} ->
            AccOut = Fun(K, V, AccIn),
            fold__(Fun, AccOut, Iter2)
    end.

%%%%%% TEST unit
                                                %-define(TEST, 1).
-ifdef(TEST).

-include_lib("eunit/include/eunit.hrl").
new_test() ->
    Key = k1,
    ?assertEqual(ok, new(Key)),
    ?assertEqual(gb_trees:empty(), erlang:get(Key)),
    ?assertError({case_clause, _}, new(Key)),
    erase(Key),
    ok.

new_from_list_test() ->
    Key = k2,
    ?assertEqual(ok, new_from_list(Key, [{1,2},{3,4}])),
    ?assertEqual(2, size(k2)),
    ?assert(is_key(k2,1)),
    ?assertNot(is_key(k2,2)),
    ?assert(is_key(k2,3)),
    ?assertError({case_clause, _}, new(Key)),
    erase(Key),
    ok.

new_from_orddict_test() ->
    %% TODO
                                                %Key = k1,
                                                %?assertEqual(ok, new_from_orddict())
    ok.

erase_test() ->
    ?assertEqual(undefined, erase(k3)),
    ?assertEqual(ok, new(k1)),
    ?assertEqual([], erase(k1)),

    ?assertEqual(ok, new_from_list(k2, [{1,2},{3,4}])),
    ?assertEqual(lists:sort([{1,2},{3,4}]), lists:sort(erase(k2))),
    ok.

is_exist_test() ->
    new(k1),
    ?assert(is_exist(k1)),
    erase(k1),
    ?assertNot(is_exist(k1)),
    ?assertNot(is_exist(k2)),
    ok.

is_empty_test() ->
    ?assertError({key_not_exist, k1}, is_empty(k1)),
    new(k1),
    ?assert(is_empty(k1)),
    erase(k1),
    ok.


is_key_test() ->
    ?assertEqual(ok, new_from_list(k1, [{1,2},{3,4}])),
    ?assert(is_key(k1,1)),
    ?assert(is_key(k1,3)),
    ?assertNot(is_key(k1,2)),
    ?assertNot(is_key(k1,other)),
    erase(k1),
    ok.

size_test() ->
    new(k1),
    ?assertEqual(0, size(k1)),
    ?assertNotEqual(1, size(k1)),

    ?assertEqual(ok, new_from_list(k2, [{1,2},{3,4}])),
    ?assertEqual(2, size(k2)),
    ?assertNotEqual(1, size(k2)),

    erase(k1),
    erase(k2),
    ok.

clear_test() ->
    new(k1),
    ?assertEqual([], clear(k1)),
                                                %?assert(is_empty(k1)),
                                                %?assert(is_exist(k1)),

                                                %?assertEqual(ok, new_from_list(k2, [{1,2},{3,4}])),
                                                %clear(k2),
                                                %?assert(is_empty(k2)),
                                                %?assert(is_exist(k2)),

    erase(k1),
    erase(k2),
    ok.

value_test() ->
    ?assertEqual(ok, new_from_list(k1, [{1,2},{2,3},{3,4}])),
    ?assertEqual(2,value(k1,1)),
    ?assertEqual(3,value(k1,2)),
    ?assertEqual(4,value(k1,3)),
    ?assertEqual(2,value(k1,5,2)),
    ?assertEqual(3,value(k1,8,3)),
    ?assertEqual(a,value(k1,a,a)),
    erase(k1),
    ok.


count_test() ->
    new(k1),
    ?assertEqual(0, count(k1,1)),
    ?assertEqual(0, count(k1,2)),

    ?assertEqual(ok, new_from_list(k2, [{1,2},{2,3},{3,4}])),
    [?assertEqual(1, count(k2, K)) || K <- lists:seq(1,3)],
    [?assertEqual(0, count(k2, K)) || K <- lists:seq(5,9)],

    erase(k1),
    erase(k2),
    ok.


to_list_test() ->
    new(k1),
    ?assertEqual([], to_list(k1)),
    erase(k1),
    ok.

foreach_test() ->
    ?assertEqual(ok, new_from_list(k1, [{1,5},{2,6},{3,7}])),
    foreach(k1, fun(K,V) -> ?assertEqual(K+4, V) end),
    erase(k1),
    ok.


fold_test() ->
    ?assertEqual(ok, new_from_list(k1, [{1,5},{2,6},{3,7}])),
    L = fold(k1,
             fun(K, V,  AccIn) -> [K+V | AccIn] end,
             []),
    ?assertEqual(lists:sort(L), lists:sort([6,8,10])),

    erase(k1),
    ok.

keys_test() ->
    ?assertEqual(ok, new_from_list(k1, [{1,5},{2,6},{3,7}])),
    ?assertEqual(lists:sort([1,2,3]), lists:sort(keys(k1))),
    ?assertEqual(lists:sort([5,6,7]), lists:sort(values(k1))),
    erase(k1),
    ok.

enter_test() ->
    new(k1),
    [enter(k1, K,V) || {K, V} <- [{1,5},{2,6},{3,7}]],
    ?assertEqual(lists:sort([1,2,3]), lists:sort(keys(k1))),
    ?assertEqual(lists:sort([5,6,7]), lists:sort(values(k1))),
    [?assert(is_key(k1,K)) || K <- [1,2,3]],
    [?assert(is_key(k1,K)) || K <- [1,2,3]],
    [?assertEqual(1, count(k1, K)) || K <- lists:seq(1,3)],
    ?assertEqual(3, size(k1)),

    [delete(k1,K) || K <- [1,2,3]],
    ?assertEqual([], lists:sort(keys(k1))),
    ?assertEqual([], lists:sort(values(k1))),
    [?assertEqual(0, count(k1, K)) || K <- lists:seq(1,3)],

    erase(k1),
    ok.

update_test() ->
    new(k1),
    [enter(k1, K,V) || {K, V} <- [{a,1},{b,2},{c,3}]],
    ?assertEqual(11, update_counter(k1, a, 10)),
    ?assertEqual(12, update_counter(k1, b, 10)),
    ?assertEqual(13, update_counter(k1, c, 10)),
    ?assertEqual(11, value(k1, a)),
    ?assertEqual(12, value(k1, b)),
    ?assertEqual(13, value(k1, c)),
    update_counter(k1, c, 1),
    update_counter(k1, c, 1),
    update_counter(k1, c, 1),
    ?assertEqual(16, value(k1, c)),

    update(k1, a, {1,2}),
    ?assertEqual({1,2}, value(k1, a)),
    update(k1, a, 3),
    ?assertEqual(3, value(k1, a)),

    new(k2),
    enter(k2, a, {a,c,0}),
    ?assertEqual({a,c,0}, value(k2, a)),
    ?assertEqual({a,c,1}, update_counter(k2, a, {3,1})),
    ?assertEqual({a,c,0}, update_counter(k2, a, {3,-1})),

    erase(k2),
    erase(k1),
    ok.


%% performance
performance() ->
                                                %create(),
                                                %delete(),

                                                %add_ele(),
                                                %loop(),
                                                %del_ele(),

    ok.

                                                %T=1000000, %% 100W

-define(T, 1000000).
%% 100W 空 gb_trees 2661 3454B =2,4M

                                                %100W/s
create() ->
    S = erlang:now(),
                                                %create(1, ?T),
    for(1,?T, fun(X) -> new(X) end),
    E = erlang:now(),
    io:format("create ~p times star:~p~n", [?T, S]),
    io:format("create ~p times over:~p~n", [?T, E]),
    ok.


for(M, M,F) ->
    ok;

for(N, M,F) ->
    F(N),
    for(N+1, M,F).

-undef(TEST).
-endif. %% ifdef TEST
