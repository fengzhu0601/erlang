%%%-------------------------------------------------------------------
%%% @author zl
%%% @doc 一个使用gb_sets 最为容器的进程字典set
%%%
%%% @end
%%%-------------------------------------------------------------------

-module(pd_gb_sets).

-compile({no_auto_import, [erase/1, size/1]}).

-export([new/1, new_from_list/2, new_from_ordset/2,
         is_empty/1, is_element/2,
         size/1, clear/1, count/2,
         erase/1,
         add_element_rb/2, add_element_rs/2,
         add_new_element/2,
         del_element_rb/2, del_element_rs/2,
         del_element/2,
         to_list/1, foreach/2, fold/3]).

                                                %-export([performance/0]).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% API
                                                %new(Key).
                                                %new_from_list(Key,List).
                                                %erase(Key)

                                                %is_empty(Key).
                                                %is_element(Key, E).

                                                %size(Key)
                                                %clear(Key) -> 返回原先的数据
                                                %count(Key, V) -> 返回个数

                                                %add_element_b(Key, V). -> 返回是否插入成功
                                                %del_element_b(Key, V) -> 返回是否删除成功 （即原来是否有这个元素)
                                                %add_element_r(Key, V). -> 返回插入后的元素 list
                                                %del_element_r(Key, V) ->  返回删除后的元素 list

                                                %to_list(Key)
                                                %foreach(Key, Fun)
                                                %fold(Key, Fun, Acc0)
                                                %filter() TODO
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% @doc create a set.
-spec new(Key::term()) -> ok.
new(Key) ->
    case erlang:get(Key) of
        undefined ->
            erlang:put(Key, gb_sets:new())
    end,
    ok.

%% @doc create a set from the elements in List.
-spec new_from_list(Key::term(), [term()]) -> ok.
new_from_list(Key, List) ->
    case erlang:get(Key) of
        undefined ->
            erlang:put(Key, gb_sets:from_list(List))
    end,
    ok.

-spec new_from_ordset(Key::term(), [term()]) -> ok.
new_from_ordset(Key, List) ->
    case erlang:get(Key) of
        undefined ->
            erlang:put(Key, gb_sets:from_ordset(List))
    end,
    ok.

%% @doc erase a set contains return elements as a list.
-spec erase(Key::term()) -> undefined | list().
erase(Key) ->
    case erlang:get(Key) of
        undefined ->
            undefined;
        Sets ->
            erlang:erase(Key),
            gb_sets:to_list(Sets)
    end.



%% @doc checks the key container is empty, the container must exist.
-spec is_empty(Key::term()) -> boolean().
is_empty(Key) ->
    case get(Key) of
        undefined ->
            erlang:error({key_not_exist, Key});
        Sets ->
            gb_sets:is_empty(Sets)
    end.

%% @doc checks element is an element of key container.
-spec is_element(Key::term(), Element::term()) -> boolean().
is_element(Key, Element) ->
    gb_sets:is_element(Element, erlang:get(Key)).


%% @doc return the number of elements
-spec size(Key::term()) -> non_neg_integer().
size(Key) ->
    gb_sets:size(erlang:get(Key)).

%% @doc clear the contents, return contents
-spec clear(Key::term()) -> list().
clear(Key) ->
    List = to_list(Key),
    erlang:put(Key, gb_sets:new()),
    List.

%% @doc return the elements of set as a list
-spec to_list(Key::term()) -> list().
to_list(Key) ->
    gb_sets:to_list(erlang:get(Key)).

%% @doc returns the number of elements equal specific Element
-spec count(Key::term(), Element::term()) -> 0 | 1.
count(Key, Element) ->
    case is_element(Key, Element) of
        true -> 1;
        false -> 0
    end.

%% @doc like gb_sets:insert/2 Assumes that Element is not present in Set1.
%% return old set.
-spec add_new_element(Key::term(), Element::term()) -> gb_sets:set().
add_new_element(Key, Element) ->
    erlang:put(Key,gb_sets:insert(Element, erlang:get(Key))).

%% @doc insert a element to sets, return is insert successed.
-spec add_element_rb(Key::term(), Element::term()) -> boolean().
add_element_rb(Key, Element) ->
    case is_element(Key, Element) of
        true ->
            false;
        false ->
            NewS = gb_sets:insert(Element, erlang:get(Key)),
            erlang:put(Key, NewS),
            true
    end.

%% @doc same as add_element_rb but return elements
-spec add_element_rs(Key::term(), Element::term()) -> gb_sets:set().
add_element_rs(Key, Element) ->
    case is_element(Key, Element) of
        true ->
            erlang:get(Key);
        false ->
            NewS = gb_sets:insert(Element, erlang:get(Key)),
            erlang:put(Key, NewS),
            NewS
    end.


%% @doc delete a element from sets, return is delete successed.
-spec del_element_rb(Key::term(), Element::term())  -> boolean().
del_element_rb(Key, Element) ->
    case is_element(Key, Element) of
        false ->
            false;
        true ->
            NewS = gb_sets:delete(Element, erlang:get(Key)),
            erlang:put(Key, NewS),
            true
    end.


%% @doc same as del_element_rb but return elements
-spec del_element_rs(Key::term(), Element::term()) -> gb_sets:set().
del_element_rs(Key, Element) ->
    case is_element(Key, Element) of
        false ->
            erlang:get(Key);
        true ->
            NewS = gb_sets:delete(Element, erlang:get(Key)),
            erlang:put(Key, NewS),
            NewS
    end.

del_element(Key, Element) ->
    erlang:put(Key,
               gb_sets:delete(Element, erlang:get(Key))).

%% @doc wrap foreach
-spec foreach(Key::term(), Fun) -> ok when
      Fun :: fun((Elem ::term()) -> term()).
foreach(Key, Fun) ->
    lists:foreach(Fun, to_list(Key)).

%% @doc wrap fold
-spec fold(Key::term(), Fun, Acc0) -> Acc1 when
      Fun :: fun((E :: term(), AccIn) -> AccOut),
      Acc0 :: T,
      Acc1 :: T,
      AccIn :: T,
      AccOut :: T.
fold(Key, Fun, Acc0) ->
    gb_sets:fold(Fun, Acc0, erlang:get(Key)).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Internel funcs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


                                                %-define(TEST,1).
-ifdef(TEST).
%%%%%% TEST unit
-include_lib("eunit/include/eunit.hrl").
new_test() ->
    Key = k1,
    ?assertEqual(ok, new(Key)),
    ?assertEqual(gb_sets:new(), erlang:get(Key)),
    ?assertError({case_clause, _}, new(Key)),
    erase(Key),
    ok.

new_from_list_test() ->
    Key = k2,
    ?assertEqual(ok, new_from_list(Key, [1,2,3,4])),
    ?assertEqual(gb_sets:from_list([1,2,3,4]), erlang:get(Key)),
    ?assertNotEqual(gb_sets:from_list([1,2,3,4,5]), erlang:get(Key)),
    ?assertError({case_clause, _}, new(Key)),
    erase(Key),
    ok.


erase_test() ->
    ?assertEqual(undefined, erase(k3)),

    ?assertEqual(ok, new(k1)),
    ?assertEqual([], erase(k1)),

    ?assertEqual(ok, new_from_list(k2, [1,2,3,4])),
    ?assertEqual(gb_sets:to_list(gb_sets:from_list([1,2,3,4])), erase(k2)),
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


is_element_test() ->
    ?assertError({key_not_exist, k1}, is_empty(k1)),
    ?assertEqual(ok, new_from_list(k1, lists:seq(1,4))),
    [?assert(is_element(k1, K)) || K <- lists:seq(1,4)],
    [?assertNot(is_element(k1, K)) || K <- lists:seq(5,8)],
    ?assertNot(is_element(k1,0)),
    erase(k1),
    ok.


size_test() ->
    new(k1),
    ?assertEqual(0, size(k1)),
    ?assertNotEqual(1, size(k1)),

    ?assertEqual(ok, new_from_list(k2, lists:seq(1,4))),
    ?assertEqual(4, size(k2)),
    ?assertNotEqual(1, size(k2)),

    erase(k1),
    erase(k2),
    ok.

clear_test() ->
    new(k1),
    ?assertEqual([], clear(k1)),
    ?assert(is_empty(k1)),
    ?assert(is_exist(k1)),

    ?assertEqual(ok, new_from_list(k2, lists:seq(1,4))),
    ?assertEqual(gb_sets:to_list(gb_sets:from_list(lists:seq(1,4))), clear(k2)),
    ?assert(is_empty(k2)),
    ?assert(is_exist(k2)),

    erase(k1),
    erase(k2),
    ok.

count_test() ->
    new(k1),
    ?assertEqual(0, count(k1,1)),
    ?assertEqual(0, count(k1,2)),

    ?assertEqual(ok, new_from_list(k2, lists:seq(1,4))),
    [?assertEqual(1, count(k2, K)) || K <- lists:seq(1,4)],
    [?assertEqual(0, count(k2, K)) || K <- lists:seq(5,9)],

    erase(k1),
    erase(k2),
    ok.

add_element_rb_test() ->
    new(k1),
    [?assert(add_element_rb(k1, K)) || K <- lists:seq(1,4)],
    [?assertNot(add_element_rb(k1, K)) || K <- lists:seq(1,4)],
    [?assert(is_element(k1, K)) || K <- lists:seq(1,4)],

    ?assert(gb_sets:is_subset(gb_sets:from_list(lists:seq(1,4)), erlang:get(k1))),

    [?assert(del_element_rb(k1, K)) || K <- lists:seq(1,4)],
    [?assertNot(del_element_rb(k1, K)) || K <- lists:seq(1,4)],

    ?assertEqual(gb_sets:from_list([1,2,3,4]), gb_sets:from_list([3,2,4,1])),
    ?assertEqual(0, size(k1)),
    ?assert(is_empty(k1)),
    erase(k1),
    ok.

add_element_rs_test() ->
    new(k1),
    ?assertEqual(gb_sets:new(), gb_sets:difference(gb_sets:from_list([1]), add_element_rs(k1, 1))),
    ?assertEqual(gb_sets:new(), gb_sets:difference(gb_sets:from_list([1,2]), add_element_rs(k1, 2))),
    ?assertEqual(gb_sets:new(), gb_sets:difference(gb_sets:from_list([1,2,3]), add_element_rs(k1, 3))),
    ?assertEqual(gb_sets:new(), gb_sets:difference(gb_sets:from_list([1,2,3,4]), add_element_rs(k1, 4))),

    ?assertEqual(gb_sets:new(), gb_sets:difference(gb_sets:from_list([1,2,3]), del_element_rs(k1, 4))),
    ?assertEqual(gb_sets:new(), gb_sets:difference(gb_sets:from_list([1,2]), del_element_rs(k1, 3))),
    ?assertEqual(gb_sets:new(), gb_sets:difference(gb_sets:from_list([1]), del_element_rs(k1, 2))),
    ?assertEqual(gb_sets:new(), gb_sets:difference(gb_sets:from_list([]), del_element_rs(k1, 1))),
    ?assert(is_empty(k1)),

    erase(k1),
    ok.

to_list_test() ->
    new(k1),
    [add_element_rb(k1, K) || K <- lists:seq(1,4)],
    ?assert(is_list(to_list(k1))),
    erase(k1),
    ok.

foreach_test() ->
    new_from_list(k1, lists:seq(1,9)),
    foreach(k1, fun(X) -> new(X) end),
    [?assert(is_exist(X)) || X <- lists:seq(1,9)],
    foreach(k1, fun(X) -> erase(X) end),
    erase(k1),
    ok.


fold_test() ->
    new_from_list(k1, lists:seq(1,9)),
    L = fold(k1, fun(X, AccIn) -> [X+1 | AccIn] end, []),
    [?assert(X>=2) || X <-L],
    [?assert(X=<10) || X <-L],
    erase(k1),
    ok.

-ifdef(ee).
-endif.

%% performance
performance() ->
                                                %create(),
                                                %delete(),

    add_ele(),
                                                %loop(),
                                                %del_ele(),

    ok.

                                                %T=1000000, %% 100W

-define(T, 1000000).
%% 100W 空 gb_sets 2661 3454B =2,4M

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


%% C++ unordered_set 100W/3s insert

                                                %del1000000 times star:{1377,858438,968566}
                                                %del1000000 times over:{1377,858439,811084}
                                                %500W/s
delete() ->
    S = erlang:now(),
    for(1,?T, fun(X) -> erase(X) end),
    E = erlang:now(),
    io:format("del~p times star:~p~n", [?T, S]),
    io:format("del~p times over:~p~n", [?T, E]),
    ok.

                                                %add_eles1000000 times star:{1377,921590,310235}
                                                %add_eles1000000 times over:{1377,921597,381503}
                                                %15W/s  性能稳定随着数量加速O ln
                                                %
                                                %add_new_element 100W 5s
                                                %add_eles1000000 times star:{1383,705010,218065}
                                                %add_eles1000000 times over:{1383,705015,694148}
add_ele() ->
    S = erlang:now(),
    new(k1),
    for(1,?T, fun(X) -> add_element_rb(k1, X) end),
                                                %for(1,?T, fun(X) -> add_new_element(k1, X) end),
    E = erlang:now(),
    io:format("add_eles~p times star:~p~n", [?T, S]),
    io:format("add_eles~p times over:~p~n", [?T, E]),
    erlang:erase(k1),
    ok.

%% 1000W/s 因为都到处为list，所以速度都ok和length有关
                                                %loop_eles1000000 times star:{1377,922142,676196}
                                                %loop_eles1000000 times over:{1377,922142,737707}
loop() ->
    S = erlang:now(),
    foreach(k1, fun(_) -> ok end),
    E = erlang:now(),
    io:format("loop_eles~p times star:~p~n", [?T, S]),
    io:format("loop_eles~p times over:~p~n", [?T, E]),
    ok.

                                                %500W/s
del_ele() ->
    S = erlang:now(),
    for(1,?T, fun(X) -> del_element_rb(k1, X) end),
    E = erlang:now(),
    erase(k1),
    io:format("del_eles~p times star:~p~n", [?T, S]),
    io:format("del_eles~p times over:~p~n", [?T, E]),
    ok.

-endif.
