-module(com_util).

-export([fold/4,
         foldwhile/4,
         while_break/3,
         for/3,
         if_undefined_set/2,
         erlang_get/2,
         eval/1, eval/2,
         str2term/1,
         binary2term/1,
         atom_concat/1,
         safe_apply/3,
         random/2,
         rand/1
         ,rand_more/2
        ,random_more/2
         ,get_point_distance/2,
         origin_distance/1,
         origin_distance/2,
         sort_point_distance/2,
         gb_trees_fold/3,
         gb_trees_lookup/3,

         ceil/1,
         ceil/2,
         floor/1,
         rffi/1,
         decimal/2,
         decimal/3,
         power/2,
         uuid/0,
         probo_build/1,
         probo_range_build/1,
         probo_random/1,
         probo_random/2,
         random_probo/2,
         probo_build_single/1,
         probo_random_single/1,
         probo_random_single/2,

         integer_to_bool/1,
         bool_to_integer/1,
         asb_to_src/1,
         is_rect_intersection/4,
         is_rect_intersection2/4

         ,page/3

         %% config_check
         ,is_valid_cli_bool/1
         ,is_valid_uint_max/2
         ,is_valid_uint8/1
         ,is_valid_uint16/1
         ,is_valid_uint32/1
         ,is_valid_uint64/1
         ,is_valid_min_max/3
         ,random_list_of_task_star/1
        ]).

-include("com_log.hrl").
-include("com_define.hrl").

%% ====================================================================
%% API functions
%% ====================================================================

-compile({inline, if_undefined_set/2}).
%% @doc if parameter is undefined return defaulte value, else return param self.
-spec if_undefined_set(term(), term()) -> term().
if_undefined_set(undefined, Default) ->
    Default;
if_undefined_set(Parm, _Default) ->
    Parm.

%% 是否有效的客户端bool型
is_valid_cli_bool(N) ->
    N =:= ?TRUE orelse N =:= ?FALSE.

%% 是否有效的uint型，且小于等于Max的值
?INLINE(is_valid_uint_max,2).
is_valid_uint_max(Val, Max) ->
    Val >= 0 andalso Val =< Max.

%% 是否有效的uint8型
is_valid_uint8(Val) ->
    is_valid_uint_max(Val, ?MAX_UINT8).

%% 是否有效的uint16型
is_valid_uint16(Val) ->
    is_valid_uint_max(Val, ?MAX_UINT16).

%% 是否有效的uint32型
is_valid_uint32(Val) ->
    is_valid_uint_max(Val, ?MAX_UINT32).

%% 是否有效的uint64型
is_valid_uint64(Val) ->
    is_valid_uint_max(Val, ?MAX_UINT64).

%% 是否有效的int类型在且大于等于Min， 小于等于Max
is_valid_min_max(Val, Min, Max) ->
    Val >= Min andalso Val =< Max.


-compile({inline, erlang_get/2}).
%% @doc if V is undefined return defaulte value, else return get value.
-spec erlang_get(term(), term()) -> term().
erlang_get(K, DefaultV) ->
    com_util:if_undefined_set(erlang:get(K), DefaultV).


-spec for(integer(), integer(), fun((integer()) -> _)) -> no_return() .
for(Min, Max, F) when Min =< Max ->
    for__(Min, Max, F, nil).

for__(Max, Max, F, _) ->
    F(Max);
for__(Min, Max, F, _) ->
    for__(Min+1, Max, F, F(Min)).

-spec fold(integer(), integer(), Func, Acc) -> AccOut when
      Acc :: term(),
      AccOut :: term(),
      Func :: fun((_,_) -> Acc).
fold(Max, Max, F, Acc) ->
    F(Max, Acc);
fold(Min, Max, F, Acc) when Min < Max ->
    fold(Min+1, Max, F, F(Min, Acc)).


%% @doc like fold but is F return `{break, Acc}' the foldwhile will be return.
foldwhile(Max, Max, F, Acc) ->
    case F(Max, Acc) of
        {break, NewState} ->
            NewState;
        break ->
            Acc;
        NewState ->
            NewState
    end;
foldwhile(Min, Max, F, Acc) when Min < Max ->
    case F(Min, Acc) of
        {break, NewState} ->
            NewState;
        break ->
            Acc;
        NewState ->
            foldwhile(Min+1, Max, F, NewState)
    end.


while_break(Max, Max, F) ->
    case F(Max) of
        break -> ok;
        {break, N} -> N;
        _ -> ok
    end;
while_break(Min, Max, F) ->
    case F(Min) of
        break -> ok;
        {break, N} -> N;
        _ ->
            com_util:while_break(Min+1,Max, F)
    end.

%% -> random rang A~B
-spec random(integer(), integer()) -> integer().
random(A, B) ->
    {Min,Max} =
        if A > B -> {B,A};
           true -> {A,B}
        end,
    rand:uniform(Max-Min+1) + Min -1.

%%@spec rand_more(Tuplelist, Num) -> [undefined | tuple()]
%% TupleList = [tuple()]
%% Num = integer()
%%@doc 链表随机取出Num个不重复的数据
-spec rand_more(list(), integer()) -> list().
rand_more(List, Num) ->
    rand_more_f1(List, erlang:max(0, Num), []).
rand_more_f1(_, 0, Result) -> Result;
rand_more_f1(List, Num, Result) ->
    Tuple = rand(List),
    rand_more_f1(lists:delete(Tuple, List), Num-1, [Tuple|Result]).

-spec random_more({integer(), integer()}, [{tuple(), {integer(), integer()}}]) -> TupleList when TupleList :: [{tuple(), integer()}].
random_more({Min, Max}, ProboList) ->
    TotleProbo = lists:max([MaxProbo||{_Item, {_MinProbo, MaxProbo}} <- ProboList]),
    ROut = ?random(TotleProbo),
    FunFoldl = fun({ItemInfo, {_MinPro, MaxPro}}, {Out, Drop}) ->
        if
            ROut =< MaxPro -> {[{ItemInfo, MaxPro} | Out], Drop};
            true -> {Out, [{ItemInfo, MaxPro} | Drop]}
        end
    end,
    {OutL, DropL} = lists:foldl(FunFoldl, {[], []}, ProboList),
    OutLen = length(OutL),
    if OutLen - Min  < 0 ->
        lists:sublist(DropL, Min - OutLen) ++ OutL;
        OutLen - Max > 0 ->
            com_util:rand_more(OutL, Max);
        ?true -> OutL
    end.

%% @spec rand(List) -> Term
%% @doc  从链表中随机取出一个数据
rand([]) -> ?undefined;
rand([I]) -> I;
rand(List) -> 
    Idx = random(1, length(List)),
    lists:nth(Idx, List).


%% INLINE
get_point_distance({X1,Y1}, {X2,Y2}) ->
    round(math:sqrt(math:pow(X2 - X1, 2) + math:pow(Y2-Y1, 2))).

%% INLINE
origin_distance({X, Y}) ->
    origin_distance(X,Y).

origin_distance(X, Y) ->
    math:sqrt(math:pow(X, 2) + math:pow(Y, 2)).

sort_point_distance(O, Plist) ->
    lists:sort(fun(P1, P2) ->
                       get_point_distance(P1, O) <
                           get_point_distance(P2, O)
               end,
               Plist).


-spec gb_trees_fold(fun((Key,V, Acc) -> Acc1), AccIn, Tree) -> AccOut when
      Key :: term(),
      V :: term(),
      Tree :: gb_tress:gb_trees(),
      AccOut :: term(),
      AccIn :: term(),
      Acc :: term(),
      Acc1 :: term().

gb_trees_fold(Fun, AccIn, Tree) ->
    gb_trees_fold__(Fun, AccIn, gb_trees:iterator(Tree)).

gb_trees_fold__(Fun, Acc, Iter) ->
    case gb_trees:next(Iter) of
        none -> Acc;
        {K, V, Iter2} ->
            gb_trees_fold__(Fun, Fun(K, V, Acc), Iter2)
    end.

%% @doc 如果没有返回默认值
gb_trees_lookup(Key, Tree, Default) ->
    case gb_trees:lookup(Key, Tree) of
        ?none ->
            Default;
        {?value, V} ->
            V
    end.

%% @doc eval run-time evaluate of string exprission.
%% example
%%    {5, _} = eval("1+4"),
%%    {F,_} = eval("fun() -> ok end"),
%%    ok = F(),
%%    {aa, _} = eval("aa"),
%%    {{af,123}, _} = eval("{af, 123}"),
%%    {[1,2,3,4,5], _} = eval("lists:sort([3,4,1,2,5])"),
%%    % can not eval("-record(a, {id, age})"),
%%
-spec eval(string(), erl_eval:binding_struct()) -> {term(), erl_eval:binding_struct()}.
eval(Str) ->
    eval(Str, erl_eval:new_bindings()).
eval(Str, Binding) ->
    try
        {ok, Ts, _} = erl_scan:string(Str),
        T1 =
            case lists:reverse(Ts) of
                [{dot, _} | _ ] -> Ts; %% end with dot
                TsR -> lists:reverse([{dot, 1} | TsR])
            end,
        {ok, Exprt} = erl_parse:parse_exprs(T1),
        erl_eval:exprs(Exprt, Binding)
    of
        {value, Value, _NewBindings} ->
            {Value, _NewBindings}
    catch
        error:Why -> ?ERROR_LOG("eval(~p,~p) :~p", [Str, Binding,Why])
    end.


binary2term(V) when erlang:is_binary(V) ->
    str2term(erlang:binary_to_list(V));
binary2term(V) ->
    ?ERROR_LOG("bad arg ~p",[V]),
    erlang:throw(bad_arg).

str2term(Str) ->
    try
        {ok, Ts, _} = erl_scan:string(Str),
        T1 =
            case lists:reverse(Ts) of
                [{dot, _} | _ ] -> Ts; %% end with dot
                TsR -> lists:reverse([{dot, 1} | TsR])
            end,
        erl_parse:parse_term(T1)
    of
        {ok, Term} ->
            Term;
        {error, R} ->
            {error, R}
    catch
        _:R->
            {error, R}
    end.

%% @doc like lists:concat, e.g. atom_concat([aa,bb]) == aabb.
-spec atom_concat([atom()]) -> atom().
atom_concat(Atoms) when is_list(Atoms) ->
    erlang:list_to_atom(
      lists:concat([erlang:atom_to_list(Atom) || Atom <- Atoms])).


safe_apply(Mod, Func, Args)->
    try
        erlang:apply(Mod, Func, Args)
    catch
        E:R->
            ?ERROR_LOG("safe_apply ~p~n Reaon~p~n Stacktrace: ~p", [{Mod,Func,Args}, {E,R}, erlang:get_stacktrace()])
    end.

-spec uuid() -> list().
uuid() ->
    com_md5:md5(term_to_binary({erlang:make_ref(), os:timestamp()})).

%% TODO 抽出来为一个模块
%% {Id, probo} ++
%% ->  {totalProbo SortLsit}
%% [{12, R:32}, {323, R::443}]
%% 第二个元素为概率
probo_build(ProboList) when is_list(ProboList) ->
    {Total, L} =
    lists:foldl(fun(Elem, {Base, Acc}) ->
                    Random = element(2, Elem),
                    NRandom = Random +Base,
                    {NRandom , [setelement(2, Elem, NRandom)| Acc]}
                end,
                {0,[]},
                lists:keysort(2, ProboList)),
    {Total, lists:reverse(L)}.

-spec probo_range_build( [{tuple(), integer()}] ) -> [{tuple(), {integer(), integer()}}].
probo_range_build( ProboList ) when is_list(ProboList) ->
    lists:foldl(fun({Item, Probo}, {ThisProbo, Acc}) -> {ThisProbo+Probo, [{Item, {ThisProbo, ThisProbo+Probo-1}}|Acc]} end,
                {1, []},
                ProboList).

%% ProboList 是probo_build 的返回值的SortList
probo_random(ProboList) ->
    probo_random(ProboList, 100).
probo_random(ProboList, TotalProbo) 
 when is_list(ProboList) ->
    R = rand:uniform(TotalProbo),
    {N, _E}=
    com_lists:take_member(fun({_, Probo}) ->
                                  Probo >= R
                          end,
                          {1,1},
                          ProboList),
    N.

random_probo(ProboList, TotalProbo) when is_list(ProboList) ->
    R = rand:uniform(TotalProbo),
    lists:last([Data||{Data, Probo}<- ProboList, Probo>=R]).


%% ProboList只是单独的概率[Pro]
probo_build_single(ProboList) when is_list(ProboList) ->
    {Total, L} =
    lists:foldl(fun(Random, {Base, Acc}) ->
                    NRandom = Random + Base,
                    {NRandom, [NRandom|Acc]}
                end, {0, []}, ProboList),
    {Total, lists:reverse(L)}.

%% ProboList只是单独的概率[Pro]，返回概率对应的Index
probo_random_single(ProboList) ->
    probo_random_single(ProboList, 100).
probo_random_single(ProboList, TotalProbo) 
 when is_list(ProboList) ->
    R = rand:uniform(TotalProbo),
    do_probo_random_single(R, ProboList, 1).

do_probo_random_single(_, [], Index) -> Index;
do_probo_random_single(Random, [ Pro |ProTL], Index) ->
    if
        Random < Pro -> Index;
        ?true -> 
            do_probo_random_single(Random, ProTL, Index+1)
    end.

random_list_of_task_star(List) when is_list(List), length(List) > 0 ->
    R = rand:uniform(lists:sum(List)),
    random_list_(R, 1, List, 1).
random_list_(_, _, [], Index) ->
    Index;
random_list_(R, Min, [Max|T], Index) ->
    if
      R >= Min, R =< Max ->
        Index;
      true ->
        random_list_(R, Max, T, Index+1)
    end.


integer_to_bool(?FALSE) -> false;
integer_to_bool(_) -> true.

bool_to_integer(true) -> ?TRUE;
bool_to_integer(false) -> ?FALSE.

%% @doc 向上取整
ceil(N) when is_integer(N)->
    N;
ceil(N) ->
    T = trunc(N),
    case N == T of
        true  -> T;
        false -> 1 + T
    end.

ceil(Dividend, Divisor) ->
    (Dividend + Divisor - 1) div Divisor.

%% @doc 向下取整
floor(X) ->
    T = trunc(X),
    case (X < T) of
        true -> T - 1;
        _ -> T
    end.

%% @doc 四舍五进
rffi(X) ->
    T = ceil(X),
    T1= (1 - (T - X)) * 10,
    case T1  >= 5 of
        true -> T;
        false-> floor(X)
    end.

%% @doc 取小数点位数 eg. 1/3 2  -> 0.33(四舍五入法)
decimal(Value, Point) ->
    Power = power(10, Point),
    rffi(Value * Power) / Power.

%% @doc 乘方，X^Y
power(X, Y) ->
    power(1, X,Y).

power(Sun, _X, 0) ->
    Sun;
power(Sun, X, Y) ->
    power(Sun * X, X, Y - 1).

decimal(F, S, Point) ->
    case S =/= 0 of
        true ->
            decimal(F / S, Point);
        false->
            0
    end.

asb_to_src(Asb) ->
    erl_prettypr:format(erl_syntax:form_list(Asb)).

%% @doc 判断两个矩形是否相交
%% LeftTopA,RightDownA,
-spec is_rect_intersection(_, _, _, _) -> boolean().
is_rect_intersection({LxA, TyA}, {RxA,ByA}, {LxB, TyB}, {RxB, ByB}) ->
    %% 如果相交则相交区域构成矩形
    %% HACK native code
    InterLx = max(LxA, LxB),
    InterTy = max(TyA, TyB),
    InterRx = min(RxA, RxB),
    InterBy = min(ByA, ByB),
    InterLx =< InterRx andalso InterTy =< InterBy.

is_rect_intersection2({LxA, TyA}, {RxA,ByA}, {LxB, TyB}, {RxB, ByB}) ->
    %% 如果相交则相交区域构成矩形
    %% HACK native code
    InterLx = max(LxA, LxB),
    InterTy = max(TyA, TyB),
    InterRx = min(RxA, RxB),
    InterBy = min(ByA, ByB),
    {InterLx =< InterRx andalso InterTy =< InterBy, InterLx, InterRx}.
    
   
%% @spec page(Page, Size, L) -> {NPage, MaxPage, PageL}
%% @doc 分页
page(Page, Size, L) ->
    Len = length(L),
    MaxPage = ceil(Len / Size),
    NPage = min(Page, MaxPage),
    StartPos = (Page -1)*Size + 1,
    {NPage, MaxPage, lists:sublist(L, StartPos, Size)}.
    

-define(TEST,1).
-ifdef(TEST).
%%%%%% TEST unit
-include_lib("eunit/include/eunit.hrl").
atom_concat_test() ->
    ?assertEqual(ok, atom_concat([ok])),
    ?assertEqual(okaa, atom_concat([ok,aa])),
    ?assertEqual('EDFFEA', atom_concat(['ED', 'FF','EA'])),
    ok.

foldwhile_test() ->
    ?assertEqual([4,2], foldwhile(1,5,
                                  fun(Index, AccIn) ->
                                          case Index rem 2 of
                                              0 -> [Index | AccIn];
                                              _ -> AccIn
                                          end
                                  end,
                                  [])),

    ?assertEqual([6,4,2], foldwhile(1,10,
                                    fun(Index, {Num, AccIn }) ->
                                            if Num =:= 3 ->
                                                    {break, AccIn};
                                               true ->
                                                    case Index rem 2 of
                                                        0 -> {Num+1,[Index | AccIn]};
                                                        _ -> {Num,AccIn}
                                                    end
                                            end
                                    end,
                                    {0,[]})),
    ?assertEqual({3,[6,4,2]}, foldwhile(1,10,
                                        fun(Index, {Num, AccIn }) ->
                                                if Num =:= 3 ->
                                                        break;
                                                   true ->
                                                        case Index rem 2 of
                                                            0 -> {Num+1,[Index | AccIn]};
                                                            _ -> {Num,AccIn}
                                                        end
                                                end
                                        end,
                                        {0,[]})),
    ok.


-endif.
