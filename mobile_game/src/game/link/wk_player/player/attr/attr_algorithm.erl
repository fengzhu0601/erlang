%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 11. 七月 2015 下午3:28
%%%-------------------------------------------------------------------
-module(attr_algorithm).
-author("clark").

%% API
-export
([
    integer_limit_add/4
    , integer_limit_set/4
    , integer_no_limit_add/2
    , integer_limit_add_ex/4
    , lists_no_limit_set/2
    , list_2_tuple/3
    , tuple_2_list/2
    , add/2
    , sum/2
    , get/2
]).


-include("inc.hrl").
-include("game.hrl").
-include("player.hrl").
-include("item_bucket.hrl").
-include("type.hrl").

get(Val, Default) ->
    case Val of
        undefined -> Default;
        _ -> Val
    end.

%% 有限制增量运算
integer_limit_add(Key, AddVal, MinVal, MaxVal) ->
    IsCan =
        if
            erlang:is_integer(AddVal) ->
                true;
            true ->
                false
        end,
    case IsCan of
        true ->
            OldVal = get(Key),
            TempVal =
                case OldVal of
                    ?undefined ->
                        AddVal;
                    _ ->
                        OldVal + AddVal
                end,
            TempMinVal = max(TempVal, MinVal),
            TempMaxVal = min(TempMinVal, MaxVal),
            put(Key, TempMaxVal),
            TempMaxVal;
        _ ->
            ?ERROR_LOG("integer_limit_add ~p", [{Key, AddVal}]),
            %?return_err(?ERR_SET_ATTR)
            false
    end.




%% 有限制增量运算
integer_limit_add_ex(Key, AddVal, MinVal, Key_for_MaxVal) ->
    IsCan =
        if
            erlang:is_integer(AddVal) ->
                true;
            true ->
                false
        end,
    case IsCan of
        true ->
            OldVal = get(Key),
            TempVal =
                case OldVal of
                    ?undefined ->
                        AddVal;
                    _ ->
                        OldVal + AddVal
                end,
            TempMinVal = max(TempVal, MinVal),
            MaxVal = get(Key_for_MaxVal),
            TempMaxVal = min(TempMinVal, MaxVal),
            put(Key, TempMaxVal),
            TempMaxVal;
        _ ->
            ?ERROR_LOG("integer_limit_add_ex ~p", [{Key, AddVal}]),
            %?return_err(?ERR_SET_ATTR)
            false
    end.



%% 有限制赋值运算
integer_limit_set(Key, NewVal, MinVal, MaxVal) ->
    IsCan =
        if
            erlang:is_integer(NewVal) ->
                true;
            true ->
                false
        end,
    case IsCan of
        true ->
            TempMinVal = max(NewVal, MinVal),
            TempMaxVal = min(TempMinVal, MaxVal),
            put(Key, TempMaxVal),
            TempMaxVal;
        _ ->
            ?ERROR_LOG("integer_limit_set ~p", [{Key, NewVal}]),
            %?return_err(?ERR_SET_ATTR)
            false
    end.


%% 无限制增量运算
integer_no_limit_add(Key, NewVal) ->
    IsCan =
        if
            erlang:is_integer(NewVal) ->
                true;
            true ->
                false
        end,
    case IsCan of
        true ->
            put(Key, NewVal),
            NewVal;
        _ ->
            ?ERROR_LOG("integer_no_limit_add ~p", [{Key, NewVal}]),
            %?return_err(?ERR_SET_ATTR)
            false
    end.


lists_no_limit_set(Key, NewVal) ->
    IsCan =
        if
            erlang:is_list(NewVal) ->
                true;
            true ->
                false
        end,
    case IsCan of
        true ->
            put(Key, NewVal),
            NewVal;
        _ ->
            %?return_err(?ERR_SET_ATTR)
            ?ERROR_LOG("lists_no_limit_set ~p", [{Key, NewVal}]),
            false
    end.


list_2_tuple(ToRd, [], _MapFun) -> ToRd;
list_2_tuple(ToRd, [{Key, Val} | TailList], MapFun) ->
    case MapFun(Key) of
        {error, _} -> list_2_tuple(ToRd, TailList, MapFun);
        TupleKey ->
            TupleVal = erlang:element(TupleKey, ToRd),
            NewToRd = erlang:setelement(TupleKey, ToRd, TupleVal + Val),
            list_2_tuple(NewToRd, TailList, MapFun)
    end.


tuple_2_list(FromTuple, MapFun) ->
    com_record:foldl_index(
        fun(TupleKey, TupleVal, TmpAcc) ->
            case MapFun(TupleKey) of
                {error, _} -> TmpAcc;
                ListKey ->
                    if
                        TupleVal > 0 -> [{ListKey, TupleVal} | TmpAcc];
                        true -> TmpAcc
                    end
            end
        end,
        [],
        FromTuple,
        0).


add(AttrListL, AttrListR) when is_list(AttrListL), is_list(AttrListR) ->
    com_lists:t2_merage(fun(V1, V2) -> V1 + V2 end,
        AttrListL,
        AttrListR);
add(AttrL, AttrR) ->
    com_record:merge(fun(A, B) -> A + B end,
        AttrL,
        AttrR).

sum(TupleRet, TupleList) ->
    lists:foldl(
        fun(AttrItem, Acc) ->
            add(Acc, AttrItem)
        end,
        TupleRet,
        TupleList).






