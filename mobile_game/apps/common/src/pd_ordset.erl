%%%-------------------------------------------------------------------
%%% @author zl
%%% @doc 一个基于进程字典的order set 使用 ordsets实现
%%%
%%% @end
%%%-------------------------------------------------------------------

-module(pd_ordset).


-compile({no_auto_import, [erase/1, size/1]}).

-export([new/1, new_from_list/2,
         is_empty/1, is_exist/1, is_element/2,
         size/1, clear/1, count/2,
         erase/1,
         add_element_rb/2, add_element_rs/2, add_element/2,
         del_element_rb/2, del_element_rs/2, del_element/2,
         to_list/1, foreach/2, fold/3]).

                                                %-export([performance/0]).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% API
                                                %new(Key).
                                                %new_from_list(Key,List).
                                                %erase(Key)

                                                %is_exist(Key).
                                                %is_empty(Key).
                                                %is_element(Key, E).

                                                %size(Key)
                                                %clear(Key) -> 返回原先的数据
                                                %count(Key, V) -> 返回个数

                                                %add_element_b(Key, V). -> 返回是否插入成功
                                                %del_element_b(Key, V) -> 返回是否删除成功 （即原来是否有这个元素)
                                                %add_element_r(Key, V). -> 返回插入后的元素 list
                                                %del_element_r(Key, V) ->  返回删除后的元素 list

                                                % to_list(Key)
                                                %foreach(Key, Fun)
                                                %fold(Key, Fun, Acc0)
                                                %filter() TODO
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% @doc create a set.
-spec new(Key::term()) -> undefined.
new(Key) ->
    undefined = erlang:put(Key, ordsets:new()).

%% @doc create a set from the elements in List.
-spec new_from_list(Key::term(), [term()]) -> undefined.
new_from_list(Key, List) ->
    undefined = erlang:put(Key, ordsets:from_list(List)).

%% @doc erase a set contains return elements as a list.
-spec erase(Key::term()) -> undefined | list().
erase(Key) ->
    case erlang:get(Key) of
        undefined ->
            undefined;
        Sets ->
            erlang:erase(Key),
            ordsets:to_list(Sets)
    end.


%% @doc checks the key container is exist.
-spec is_exist(Key::term()) -> boolean().
is_exist(Key) ->
    undefined =/= erlang:get(Key).

%% @doc checks the key container is empty, the container must exist.
-spec is_empty(Key::term()) -> boolean().
is_empty(Key) ->
    case get(Key) of
        undefined ->
            erlang:error({key_not_exist, Key});
        Sets ->
            is_empty__(ordsets:to_list(Sets))
    end.

%% @doc checks element is an element of key container.
-spec is_element(Key::term(), Element::term()) -> boolean().
is_element(Key, Element) ->
    ordsets:is_element(Element, erlang:get(Key)).


%% @doc return the number of elements
-spec size(Key::term()) -> non_neg_integer().
size(Key) ->
    ordsets:size(erlang:get(Key)).

%% @doc clear the contents, return contents
-spec clear(Key::term()) -> list().
clear(Key) ->
    List = to_list(Key),
    erlang:put(Key, ordsets:new()),
    List.

%% @doc return the elements of set as a list
-spec to_list(Key::term()) -> list().
to_list(Key) ->
    ordsets:to_list(erlang:get(Key)).

%% @doc returns the number of elements equal specific Element
-spec count(Key::term(), Element::term()) -> 0 | 1.
count(Key, Element) ->
    case is_element(Key, Element) of
        true -> 1;
        false -> 0
    end.

%% @doc insert a element to sets, return is insert successed.
-spec add_element_rb(Key::term(), Element::term()) -> boolean().
add_element_rb(Key, Element) ->
    case is_element(Key, Element) of
        true ->
            false;
        false ->
            NewS = ordsets:add_element(Element, erlang:get(Key)),
            erlang:put(Key, NewS),
            true
    end.

%% @doc same as add_element_rb but return elements
-spec add_element_rs(Key::term(), Element::term()) -> ordsets:ordset().
add_element_rs(Key, Element) ->
    NewS = ordsets:add_element(Element, erlang:get(Key)),
    erlang:put(Key, NewS),
    NewS.

-compile({inline, [add_element/2]}).
%% @doc same as add_element_rb return ok.
-spec add_element(Key::term(), Element::term()) -> ok.
add_element(Key, Element) ->
    _ = erlang:put(Key, ordsets:add_element(Element, erlang:get(Key))),
    ok.

%% @doc delete a element from sets, return is delete successed.
-spec del_element_rb(Key::term(), Element::term())  -> boolean().
del_element_rb(Key, Element) ->
    case is_element(Key, Element) of
        false ->
            false;
        true ->
            NewS = ordsets:del_element(Element, erlang:get(Key)),
            erlang:put(Key, NewS),
            true
    end.


%% @doc same as del_element_rb but return elements
-spec del_element_rs(Key::term(), Element::term()) -> ordsets:ordset().
del_element_rs(Key, Element) ->
    case is_element(Key, Element) of
        false ->
            erlang:get(Key);
        true ->
            NewS = ordsets:del_element(Element, erlang:get(Key)),
            erlang:put(Key, NewS),
            NewS
    end.

%% @doc same as del_element_rb but return ok
-spec del_element(Key::term(), Element::term()) -> ok.
del_element(Key, Element) ->
    _ =erlang:put(Key, ordsets:del_element(Element, erlang:get(Key))),
    ok.


%% @doc like lists:foreach
-spec foreach(Key::term(), Fun) -> ok when
      Fun :: fun((Elem ::term()) -> term()).
foreach(Key, Fun) ->
    lists:foreach(Fun, to_list(Key)).

%% @doc like ordsetsfold
-spec fold(Key::term(), Fun, Acc0) -> Acc1 when
      Fun :: fun((E :: term(), AccIn) -> AccOut),
      Acc0 :: T,
      Acc1 :: T,
      AccIn :: T,
      AccOut :: T.
fold(Key, Fun, Acc0) ->
    ordsets:fold(Fun, Acc0, erlang:get(Key)).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Internel funcs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-spec is_empty__(ItemList::list()) -> boolean().
is_empty__([]) ->
    true;
is_empty__(_List) ->
    false.














%%%%%% TEST unit
-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").
new_test() ->
    Key = k1,
    ?assertEqual(ok, new(Key)),
    ?assertEqual(ordsets:new(), erlang:get(Key)),
    ?assertError({case_clause, _}, new(Key)),
    erase(Key),
    ok.

new_from_list_test() ->
    Key = k2,
    ?assertEqual(ok, new_from_list(Key, [1,2,3,4])),
    ?assertEqual(ordsets:from_list([1,2,3,4]), erlang:get(Key)),
    ?assertNotEqual(ordsets:from_list([1,2,3,4,5]), erlang:get(Key)),
    ?assertError({case_clause, _}, new(Key)),
    erase(Key),
    ok.


erase_test() ->
    ?assertEqual(undefined, erase(k3)),

    ?assertEqual(ok, new(k1)),
    ?assertEqual([], erase(k1)),

    ?assertEqual(ok, new_from_list(k2, [1,2,3,4])),
    ?assertEqual(ordsets:to_list(ordsets:from_list([1,2,3,4])), erase(k2)),
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
    ?assertEqual(ordsets:to_list(ordsets:from_list(lists:seq(1,4))), clear(k2)),
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

    ?assertEqual(ordsets:from_list(lists:seq(1,4)), erlang:get(k1)),

    [?assert(del_element_rb(k1, K)) || K <- lists:seq(1,4)],
    [?assertNot(del_element_rb(k1, K)) || K <- lists:seq(1,4)],

    ?assertEqual(0, size(k1)),
    ?assert(is_empty(k1)),
    erase(k1),
    ok.

add_element_rs_test() ->
    new(k1),
    ?assertEqual(ordsets:from_list([1]), add_element_rs(k1, 1)),
    ?assertEqual(ordsets:from_list([1,2]), add_element_rs(k1, 2)),
    ?assertEqual(ordsets:from_list([1,2,3]), add_element_rs(k1, 3)),
    ?assertEqual(ordsets:from_list([1,2,3,4]), add_element_rs(k1, 4)),

    ?assertEqual(ordsets:from_list([1,2,3]), del_element_rs(k1, 4)),
    ?assertEqual(ordsets:from_list([1,2]), del_element_rs(k1, 3)),
    ?assertEqual(ordsets:from_list([1]), del_element_rs(k1, 2)),
    ?assertEqual(ordsets:from_list([]), del_element_rs(k1, 1)),
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


%% performance
performance() ->
    create(),
    delete(),

    add_ele(),
    del_ele(),

    ok.

                                                %T=1000000, %% 100W
-define(T, 100000).

                                                %1000W/s
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

                                                %1000W/s
delete() ->
    S = erlang:now(),
    for(1,?T, fun(X) -> erase(X) end),
    E = erlang:now(),
    io:format("del~p times star:~p~n", [?T, S]),
    io:format("del~p times over:~p~n", [?T, E]),
    ok.

                                                %1k/s 随着数量加大会迅速降低速度！！！！！
                                                %操作和具体list内容，和顺序有关,如果顺序刚好相反，非常慢 1k/s
                                                %如果顺序相同，瞬间ok
add_ele() ->
    S = erlang:now(),
    new(k1),
    for(1,?T, fun(X) -> add_element_rb(k1, X) end),
    E = erlang:now(),
    io:format("add_eles~p times star:~p~n", [?T, S]),
    io:format("add_eles~p times over:~p~n", [?T, E]),
    ok.

                                                %8W/s 随着数量加大会迅速降低速度！！！！！
del_ele() ->
    S = erlang:now(),
    for(1,?T, fun(X) -> del_element_rb(k1, X) end),
    E = erlang:now(),
    erase(k1),
    io:format("del_eles~p times star:~p~n", [?T, S]),
    io:format("del_eles~p times over:~p~n", [?T, E]),
    ok.

-endif.
