-module(com_record).

%% ====================================================================
%% API functions
%% ====================================================================
-export([
    map/2,
    get_name/1,
    foreach/2,
    foldl/3,
    foldl2/4,
    foldl_index/4,
    merge/3,
    merge/4,
    any/2,
    any/3,
    tuple_merge/3,
    put_pd_fields/2,
    get_pd_fields/2,
    update_old_data/3
]).


-spec any(Pred, T) -> boolean() when
      Pred :: fun((Elem::term() ) -> boolean()),
      T :: tuple().

%% @doc like lists:any/1
any(Pred, Tuple) ->
    any(Pred, Tuple, 2).

any(_, {}, _) -> false;
any(Pred, Tuple, Begin) -> 
    S = tuple_size(Tuple),
    if S < Begin ->
           false;
       true  ->
           any__(Pred, Tuple, Begin, S)
    end.

any__(Pred, Tuple, M, M) ->
    Pred(element(M, Tuple));
any__(Pred, Tuple, N, M) ->
    case Pred(element(M, Tuple)) of
        true ->
            true;
        _ ->
            any__(Pred, Tuple, N+1, M)
    end.




%% @doc record map
-spec map(Func, Record) -> Record2 when
      Record :: Tuple,
      Record2 :: Tuple,
      Func :: fun((term()) -> term()),
      Tuple :: tuple().
map(Func, Record) ->
    [Name| List] = erlang:tuple_to_list(Record),
    List2 = lists:map(Func, List),
    erlang:list_to_tuple([Name | List2]).

-compile({inline, [get_name/1]}).
%% @doc get record name.
-spec get_name(tuple()) -> atom().
get_name(Record) ->
    erlang:element(1, Record).


%% @doc foreach element not include name.
-spec foreach(Fun, Record) -> ok when
      Fun :: fun((term()) -> _),
      Record :: tuple().
foreach(Fun, Record)
  when is_function(Fun, 1),
       is_tuple(Record) ->
    com_util:for(2,
                 erlang:tuple_size(Record),
                 fun(Index) -> Fun(element(Index, Record)) end);
%% fun/2 (index, E)
foreach(Fun, Record)
  when is_function(Fun, 2),
       is_tuple(Record) ->
    com_util:for(2,
                 erlang:tuple_size(Record),
                 fun(Index) -> Fun(Index, element(Index, Record)) end);
foreach(Fun,Record) ->
    io:format("foreach Fun ~p Record ~p~n",[Fun, Record]).


%% @doc foldl element not include name.
-spec foldl(Fun, Acc0, Record) -> Acc1 when
      Fun :: fun((term(), AccIn) -> AccOut),
      Acc0 :: term(),
      Acc1 :: term(),
      AccIn :: term(),
      AccOut :: term(),
      Record :: tuple().

%% @doc not aceess record name.
foldl(Func, Acc, Record) when is_function(Func,2) ->
    case erlang:tuple_size(Record) of
        1 -> Acc;
        M ->
            foldl_(Func, Acc, Record, 2, M)
    end.

foldl2(Func, Acc, Record, Begin)
  when is_function(Func, 2) ->
    case erlang:tuple_size(Record) of
        S when S < Begin -> Acc;
        S ->
            foldl_(Func, Acc, Record, Begin, S)
    end.


foldl_(Func, Acc, Record, N, N) ->
    Func(erlang:element(N, Record), Acc);
foldl_(Func, Acc, Record, N, M) ->
    foldl_(Func,
           Func(erlang:element(N, Record), Acc),
           Record, N+1, M).

%% @doc same foldl2 but fun take 3 arg
foldl_index(Func, Acc, Record, Begin) ->
    case erlang:tuple_size(Record) of
        S when S < Begin -> Acc;
        S ->
            foldl_index_(Func, Acc, Record, Begin, S)
    end.

%% @doc merge two same type record with func
%% two record must same type.
%%  Fun argument is record elements
%% @usage
%%  merage(fun(A,B) -> A + B end, {aa, 1,1,1} , {aa, 3,3,3})
%%  -> {aa, 4,4,4}
-spec merge(Fun, Record1, Record2) -> RecordOut when
      Fun :: fun((A, B) -> T),
      Record1 :: RecordOut,
      Record2 :: RecordOut,
      RecordOut :: tuple(),
      A :: term(),
      B :: term(),
      T :: term().

merge(Fun, Record1, Record2) when is_function(Fun, 2) ->
    merge__(Fun, Record1, Record2, 2, {get_name(Record1)}).

merge(Fun, Record1, Record2, Begin) when is_function(Fun, 2) ->
    merge__(Fun, Record1, Record2, Begin, {get_name(Record1)}).

tuple_merge(Fun, T1, T2) ->
    merge__(Fun, T1, T2, 1, {}).

merge__(Fun, T1, T2, Begin, Acc) ->
    com_util:fold(Begin,
                  erlang:tuple_size(T1),
                  fun(Index,  RecordOut) ->
                          erlang:append_element(RecordOut,
                                                Fun(erlang:element(Index, T1),
                                                    erlang:element(Index, T2)))
                  end,
                  Acc
                 ).

update_old_data(Key, OldRecord, NewRecord) ->
    OldRsize = erlang:tuple_size(OldRecord),
    NewRsize = erlang:tuple_size(NewRecord),
    io:format("OldRecord-------------------:~p~n",[OldRecord]),
    io:format("OldRsize------------------:~p~n",[OldRsize]),
    io:format("NewRsize-----------------:~p~n",[NewRsize]),
    FinalRecord = 
    if
        OldRsize =/= NewRsize ->
            update_old_data_(2, NewRsize, OldRecord, NewRecord);
        true ->
            OldRecord
    end,
    io:format("FinalRecord-------------------------:~p~n",[FinalRecord]),
    put(Key, FinalRecord).
update_old_data_(MaxIndex, MaxIndex, _, NewRecord) ->
    NewRecord;
update_old_data_(Index, MaxIndex, OldRecord, NewRecord) ->
    update_old_data_(
        Index + 1,
        MaxIndex,
        OldRecord,
        setelement(Index, NewRecord, get_value_by_index(Index, OldRecord, NewRecord))
    ).


get_value_by_index(Index, Record, NewRecord) ->
    Size = erlang:tuple_size(Record),
    if
        Index > Size ->
            erlang:element(Index, NewRecord);
        true ->
            element(Index, Record) 
    end.


foldl_index_(Func, Acc, Record, N, N) ->
    Func(N, erlang:element(N, Record), Acc);
foldl_index_(Func, Acc, Record, N, M) ->
    foldl_index_(Func,
                 Func(N, erlang:element(N, Record), Acc),
                 Record, N+1, M).



%% HACK 最好的元转换
%% @doc 存入进程字典　每个filed 都会在前面加上pd_ 的前缀
%% 每个进程字典都只能是单次赋值
put_pd_fields(Record, FieldsName) when erlang:is_list(FieldsName), erlang:is_tuple(Record) ->
    lists:foldl(
        fun(FName, Index) ->
                erlang:put(erlang:list_to_atom("pd_" ++ erlang:atom_to_list(FName)), util:set_value(erlang:element(Index, Record), 0)),
                Index + 1
        end,
        2,
        FieldsName
    ).

%% @doc Record
-spec get_pd_fields(RecordName, [atom()]) -> RecordOut when
      RecordName :: atom(),
      RecordOut :: tuple().

get_pd_fields(RecordName, FieldsName)
  when erlang:is_list(FieldsName) ->
    lists:foldl(fun(FName, R) ->
                        erlang:append_element(R,
                                              erlang:get(erlang:list_to_atom("pd_" ++ erlang:atom_to_list(FName))))
                end,
                {RecordName},
                FieldsName).


%%%%%% TEST unit

                                                %-define(TEST, 1).
-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").

-record(tt, {id, name, age}).

pd_fields_test() ->
    R= #tt{id=32, name= <<"feof">>, age=[1,2,4]},
    put_pd_fields(R, record_info(fields, tt)),
    ?assertEqual(32, get(pd_id)),
    ?assertEqual(<<"feof">>, get(pd_name)),
    ?assertEqual([1,2,4], get(pd_age)),

    R2 = get_pd_fields(tt, record_info(fields, tt)),
    ?assertEqual(R2,  R),

    ok.

-endif.
