%%% coding:utf-8
%%%-------------------------------------------------------------------
%%% @author zl
%%% @doc 操作 lists 的一些工具函数
%%%
%%% @end
%%%-------------------------------------------------------------------

-module(com_lists).
-export([
          match_value/4
         ,sum/1
         ,sum/2
         ,keyfind_all_and_sum/4
         ,extract_member/3
         ,get_member/3
         ,drop/2
         ,take/2
         ,take_member/3
         ,keyfind_all/3
         ,t2_merage/3
         ,is_element/2
         ,all/2
         ,drop_repeat_element/1
         ,pack_list/2
         ,split_with_length/2
         ,shuffle/1
         ,break/3
         ,break_foldl/3
         ,while_break/3
         ,delete_nth/2
         ,pages/3  %% 分页
         ,mkeysort/2 %% 多主键排序，可支持正反排序
         ,rkeysort/2 %% 逆序排序
         ,sort_desc/1
         ,random_element/1 %%
        ]).

-include("inc.hrl").


%% @doc 获取List元素上KeyN位等于Key的这个元素的RetN位的值 返回notmatch | element(RetN,Ele)值
match_value(Key,KeyN,[Ele|List], RetN) when is_tuple(Ele),tuple_size(Ele)>=KeyN ->
    case tuple_size(Ele) >= RetN andalso element(KeyN,Ele)=:= Key of
        ?true -> element(RetN,Ele);
        ?false-> match_value(Key,KeyN,List,RetN)
    end;
match_value(_Key,_KeyN,_List,_RetN) ->
    notmatch.


%% @doc random get an element of list
-spec random_element([any()])  -> any().
random_element(List) ->
    lists:nth(rand:uniform(erlang:length(List)),List).

sum(Fun, List) ->
    sum(lists:map(Fun,List)).
sum(List) ->
    lists:sum(List).

keyfind_all_and_sum(Key, N, SumPos, TpL) ->
    keyfind_all_and_sum(Key, N, SumPos, TpL, 0).
keyfind_all_and_sum(_Key, _N, _SumPos, [], Sum) ->  Sum;
keyfind_all_and_sum(Key, N, SumPos, [TP|T], Sum) -> 
    Sum2 = case element(N, TP) of
    Key -> element(SumPos, TP) + Sum;
    _ -> Sum
    end,
    keyfind_all_and_sum(Key, N, SumPos, T, Sum2).

%% @doc like lists:sort/1 but sort by desc.
sort_desc(List) ->
    lists:sort(fun(A,B) ->
                       A >= B
               end,
               List).

%% @doc delete the nth element, return delete element and remain list.
%% 4
-spec delete_nth(Index::pos_integer(), List::list()) -> {E::_, Reamin::list()}.
delete_nth(Index, List) when Index > 0->
    delete_nth(Index, 1, [], List).

delete_nth(Index, Index, Head, [E|Tail]) ->
    {E, lists:reverse(Head) ++ Tail};
delete_nth(Index, Nth, Head, [E|Tail]) ->
    delete_nth(Index, Nth+1, [E | Head], Tail).


%% @doc shuffle list.
shuffle(L)
  when is_list(L) ->
    List1 = [{rand:uniform(), X} || X <- L],
    List2 = lists:keysort(1, List1),
    [E || {_, E} <- List2].

%% @doc split a list with n element. [1,2,3,4,5] -> [[1,2],[3,4],[5]]]
%% STYLE 不应该使用有这种东西
split_with_length(List, N) ->
    split_with_length__(List, N, {0,[]}, []).

split_with_length__([], _N, {_M, SubL}, Other) ->
    lists:reverse([lists:reverse(SubL) | Other]);
split_with_length__([H | List], N, {N, SubL}, Other) ->
    split_with_length__(List, N, {1, [H]}, [lists:reverse(SubL) | Other]);
split_with_length__([H | List], N, {M, SubL}, Other) ->
    split_with_length__(List, N, {M+1, [H | SubL]}, Other).


%% @doc get list member if not exist, return defalut.
-spec get_member(Elem::term(), List::list(), Default::term()) -> term().
get_member(Elem, List, Default) ->
    case lists:member(Elem, List) of
        true -> Elem;
        false -> Default
    end.


%% @doc return list is all pred return false element in lists1.
-spec drop(Pred, List1::list()) -> List2::list() when
      Pred :: fun((term()) -> boolean()).
drop(Pred, List) ->
    lists:foldr(
      fun(E, AccIn) ->
              case Pred(E) of
                  true -> AccIn;
                  false -> [E | AccIn]
              end
      end,
      [],
      List).

pack_list(List, WeiShu) ->
    {Totals, Bin} = lists:foldl(fun(Num, {Total, Binary}) ->
                        {Total+1, <<Num:WeiShu, Binary/bytes>>}
                end, {0, <<>>}, List),
    {Totals, Bin}.

%% @doc return list is all pred return true element in lists1.
-spec take(Pred, List1::list()) -> List2::list() when
      Pred :: fun((term()) -> boolean()).
take(Pred, List) ->
    lists:foldr(
      fun(E, AccIn) ->
              case Pred(E) of
                  true -> [E | AccIn];
                  false -> AccIn
              end
      end,
      [],

      List).

%% @doc take the first Pred return true member. can not return scend arg.
-spec take_member(Pred, term(), List1::list()) -> term() when
      Pred :: fun((term()) -> boolean()).
take_member(_Pred, Sec, [])  ->
    Sec;
take_member(Pred, Sec, [E|List]) ->
    case Pred(E) of
        true -> E;
        false ->
            take_member(Pred, Sec, List)
    end.

extract_member(Key, KeyIndex, List) ->
    extract_tmp(Key, KeyIndex, List, []).

extract_tmp(Key, KeyIndex, [Ele|SrcL], RemainL) ->
    case element(KeyIndex, Ele) == Key of
        ?true ->
            {Ele, lists:reverse(RemainL)++SrcL};
        ?false->
            extract_tmp(Key, KeyIndex, SrcL, [Ele|RemainL])
    end;
extract_tmp(_Key, _KeyIndex, [], _RemainL) ->
    empty.


%% @doc foreach element
%% @doc if Fun(Ele) return `{break, NewDefault}'or break the while_while will be back NewDefault or Default
%% @doc if Fun(Ele) return `{continue, NewDefault}'or continue the while_while will be continue NewDefault or Default
break(Fun, Default,[Ele|List]) ->
    case Fun(Ele) of
        {break,R} -> R;
        break -> Default;
        {continue,R} ->
            break(Fun, R, List);
        continue ->
            break(Fun, Default, List);
        NotSupp->
            throw({?MODULE,break,fun_return_not_support, NotSupp})
    end;
break(_Fun, Default, []) ->
    Default.

%% @doc foreach element
%% @doc if Fun(Ele,Default) return `{break, NewDefault}'or break the while_while will be back NewDefault or Default
%% @doc if Fun(Ele,Default) return `{continue, NewDefault}'or continue the while_while will be continue NewDefault or Default
break_foldl(Fun, Default, [Ele|List]) ->
    case Fun(Ele, Default) of
        {break,R} -> R;
        break -> Default;
        {continue,R} ->
            break_foldl(Fun, R, List);
        continue ->
            break_foldl(Fun, Default, List);
        NotSupp->
            throw({?MODULE,break_foldl,fun_return_not_support, NotSupp})
    end;
break_foldl(_Fun,Default, []) ->
    Default.

%% @doc foreach element if F return `{break, V}' the while_while will be 
%%     terminal loop and return V, if not break it will return the second parament.
while_break(_Fn, Default, []) ->
    Default;
while_break(Fn, Default, [E|O]) ->
    case Fn(E) of
        {break, V} ->
            V;
        _ ->
            while_break(Fn, Default, O)
    end.


%% @doc like keyfind but return all find -> list [tuple()]
%% NIF is greate
keyfind_all(Key, N, List) ->
    lists:foldr(fun(E, Acc) ->
                        if erlang:element(N, E) =:= Key ->
                                [E | Acc];
                           true -> Acc
                        end
                end,
                [],
                List).


%% @doc merge to tuple-2 list. like dict:merge + to_list but faster.
%% the fun is merge with two same key tuple element.
%% e.g.
%%  t2_merage(fun(A,B) -> A+B end,
%%            [{1,3}, {3,1}],
%%            [{1,5}, {6,2}]).
%%
%%
-spec t2_merage(fun((_,_) -> _), [{_,_}], [{_,_}]) -> [{_,_}].
t2_merage(Fun, List1, List2) when is_function(Fun,2)->
    t2_merage__(Fun, List1, List2, []).

t2_merage__(_Fun, [], R, Acc) ->
    R ++ Acc;
t2_merage__(_Fun, L, [], Acc) ->
    L ++ Acc;
t2_merage__(Fun, [{Key, LV}=L | Other], R, Acc) ->
    case lists:keyfind(Key, 1, R) of
        false ->
            t2_merage__(Fun, Other, R, [L | Acc]);
        {_, RV} ->
            t2_merage__(Fun, Other, lists:keydelete(Key, 1, R), [{Key, Fun(LV, RV)} | Acc])
    end.


%% @doc check E is list element.
-spec is_element(term(), list()) -> boolean().
is_element(_E, []) ->
    false;
is_element(E, [E | _]) ->
    true;
is_element(E, [_H | Tail]) ->
    is_element(E, Tail).

%% @doc check is list all of element is equal E.
-spec all(term(), list()) -> boolean().
all(_E, []) -> false;
all(E, List) ->
    all_(E, List).

all_(_E, []) -> true;
all_(E, [E|Tail]) ->
    all_(E, Tail);
all_(_E, _L) ->
    false.

                                                % O(N!)
drop_repeat_element(L) when is_list(L) ->
    R=
        lists:foldl(fun(E, Acc) ->
                            case is_element(E, Acc) of
                                true ->
                                    Acc;
                                false ->
                                    [E | Acc]
                            end
                    end,
                    [],
                    L),
    lists:reverse(R).

%% @spec pages(PageSize, PageNum, Datas)-> {NewPageNum, MaxPageNum, Page}
%% PageSize = PageNum = NewPageNum = MaxPageNum = integer()
%% PageSize 每页的大小  PageNum 请求页号  Datas数据列表 NewPageNum 返回页号  MaxPageNum 返回最大页号 Page 页内容
%% Datas = list()
%% @doc 分页
pages(_PageSize, _PageNum, [])->
    {0, 0, []};
pages(PageSize, PageNum, Datas)->
    MaxPageNum = com_util:ceil(length(Datas) / PageSize),
    PageNum1 = if
        PageNum > MaxPageNum orelse PageNum =< 0 ->
            MaxPageNum;
        true ->
            PageNum
    end,
    Start = (PageNum1-1) * PageSize + 1,
    Page = lists:sublist(Datas, Start, PageSize),
    {PageNum1, MaxPageNum, Page}.


%% 逆序排序
rkeysort(KeyPos, TupleList) ->
    lists:reverse(lists:keysort(KeyPos, TupleList)).


%% @spec mkeysort(KeyPoss::[int()], List::[tuple()]) -> [tuple()]
%% @doc 支持正反多键值排序
%% eg. list_util:mkeysort([{s,2},{r,1}], [{1,2,3}, {2, 1, 3}, {2, 2, 2}]).
%% [{2, 1, 3}, {2, 2, 2}, {1, 2, 3}]</pre>
mkeysort(_Keys, []) -> [];
mkeysort(_Keys, [F]) -> [F];
mkeysort([], TupleList) when is_list(TupleList) -> TupleList;
mkeysort([Key], TupleList) when is_list(TupleList) -> mkeysort2_fun3(Key, TupleList);
mkeysort([Key|Keys], TupleList) when is_list(TupleList) ->
    {_, Key2} = Key,
    [F|T] = mkeysort2_fun3(Key, TupleList),
    mkeysort_fun2(T, Key, Keys, element(Key2, F), [F], []). %% 分组
mkeysort_fun2([], _Key, Keys, _Val, Buff, Res) -> 
    NewBuff = mkeysort(Keys, Buff),
    Res ++ NewBuff;
mkeysort_fun2([F|T], Key, Keys, Val, Buff, Res) ->
    {_, Key2} = Key,
    case element(Key2, F) of
    Val -> mkeysort_fun2(T, Key, Keys, Val, [F|Buff], Res);  %% 同一组的放进buff
    Val2 -> 
        NewBuff = mkeysort(Keys, Buff),
        mkeysort_fun2(T, Key, Keys, Val2, [F], Res ++ NewBuff)
    end.

%% 分正反排序
mkeysort2_fun3({s,Key}, Tuplelist) ->
    lists:keysort(Key, Tuplelist);
mkeysort2_fun3({r,Key}, Tuplelist) ->
    lists:reverse(lists:keysort(Key, Tuplelist)).

                                                %-define(TEST,1).
-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").
all_test() ->
    ?assertEqual([{a,1}, {a,3}], keyfind_all(a, 1, [{a,1}, {b,2}, {c,3}, {a,3}, {o, 8}])),
    ?assertEqual([1,3,5], drop(fun(X) when X rem 2 =:= 0 ->
                                       true;
                                  (_) ->
                                       false
                               end,
                               [1,2,3,4,5,6])),
    ?assertEqual([33], drop(fun(X)
                                  when X =:= ok; X=:=err ->
                                    true;
                               (_) ->
                                    false
                            end,
                            [ok,33, err,err,err,ok])),
    ?assertEqual([ok, err,err,err,ok], take(fun(X)
                                                  when X =:= ok; X=:=err ->
                                                    true;
                                               (_) ->
                                                    false
                                            end,
                                            [ok,33, err,err,err,ok])),
    ?assertEqual([], take(fun(X)
                                when X rem 2 =:=0 ->
                                  true;
                             (_) ->
                                  false
                          end,
                          [1,3,5,7])),
    ok.

-endif.
