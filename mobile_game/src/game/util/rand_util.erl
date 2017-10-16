%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 26. 十月 2015 下午6:36
%%%-------------------------------------------------------------------
-module(rand_util).
-author("clark").

%% API
-export
([
    get_random_list/2
    ,test/1
]).

-include("inc.hrl").

get_random_list_sum(SrcList) ->
    SumPre =
        lists:foldl
        (
            fun({_ID, Pre}, Acc) ->
                Acc + Pre
            end,
            0,
            SrcList
        ),
    SumPre.
get_random_list(NeedNum, SrcList) ->
    get_random_list(NeedNum, get_random_list_sum(SrcList), SrcList).
get_random_list(_NeedNum, _SumPre, []) -> [];
get_random_list(0, _SumPre, _SrcList) -> [];
get_random_list(NeedNum, SumPre, SrcList) ->
    {ID, SrcList1} = get_one_of_random_list(SumPre, SrcList),
    LeftList = get_random_list(NeedNum-1, get_random_list_sum(SrcList1), SrcList1),
    [ID | LeftList].


get_one_of_random_list(SumPre, SrcList) ->
    PreLine = com_util:random(0, SumPre),
    {_, ID1, RR} =
        lists:foldl
        (
            fun
                ({ID, Pre}, {Sum, PreID, RList}) ->
                    Sum1 = Sum + Pre,
                    if
                        PreLine >= Sum andalso PreLine < Sum1 ->
                            {Sum1, ID, RList};
                        true ->
                            {Sum1, PreID, [{ID,Pre}|RList]}
                    end
            end,
            {0, 0, []},
            SrcList
        ),
    {ID1, RR}.


test(0) -> ok;
test(Count) ->
    XX = [{1,20},{2,20},{3,30},{4,40}],
    XX1 = get_random_list(1, XX),
    ?INFO_LOG("test ret ~p~n", [{Count, XX1}]),
    test(Count-1).