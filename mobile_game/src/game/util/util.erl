%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 28. 六月 2015 下午8:38
%%%-------------------------------------------------------------------
-module(util).
-author("clark").

%% API
-export
([
    nth/2,
    get_now_second/1,
    can/1,
    do/1,
    mod_can/2,
    mod_fun/2,
    get_days/0,
    get_days/1,
    lists_set_ex/3,
    lists_get_ex/2,
    list_from_for/3,
    list_from_for/2,
    set_branch_val/3,
    get_branch_val/3,
    list_add_list/2,
    set_binary/3,
    random_list_of_task_star/1,
    get_pd_field/2,
    set_pd_field/2,
    del_pd_field/1,
    ceil/1,
    floor/1,
    get_dasy_by_seconds/1,
    get_num_list/3,
    get_now_time/0,
    get_now_time/1,
    get_format_time/1,
    date_2_str/1,
    get_dasy_by_seconds_ex/1,
    ip_to_str/1,
    get_cur_ip/0,
    get_today_passed_seconds/0,
    list_2_len_binary/3,
    get_val_by_weight/2,
    is_on_list/2,
    get_field/3,
    set_field/3,
    del_field/2,
    bool_to_int/1,
    pkg_player_bin/3,
    is_in_this_time/2,
    is_in_same_week/2,
    node_send_to_client/2,
    get_the_YMD_of_day/0,
    get_the_YMD_of_day/1,
    list_multiply_coefficient/3,
    set_value/2,
    is_tag_on_list/2,
    prize_cumsum_by_num/2,
    get_index_of_list/2,
    get_ten_beishu/1,
    get_min/3,
    is_flush_rank_only_by_rankname/2
]).


-include_lib("common/include/com_log.hrl").
-include("game.hrl").

get_min(N1,N2,Default) ->
    N = erlang:max(N1, N2),
    erlang:min(N, Default).


get_ten_beishu(N) ->
    get_ten_beishu_(N div 10, []).
get_ten_beishu_(0, List) ->
    List;
get_ten_beishu_(N, List) ->
    get_ten_beishu_(N-1, [N*10|List]).

get_index_of_list([], _) ->
    0;
get_index_of_list(List, Tag) ->
    index_of_list(List, Tag, 1).
index_of_list([], _Tag, Index) ->
    Index;
index_of_list([H|T], Tag, Index) when is_tuple(H)->
    case element(1, H) of
        Tag ->
            Index;
        _ ->
            index_of_list(T, Tag, Index + 1)
    end;
index_of_list([Tag|_T], Tag, Index) ->
    Index;
index_of_list([_H|T], Tag, Index) ->
    index_of_list(T, Tag, Index+1).


prize_cumsum_by_num(PrizeId, Num) ->
    N = do_prize_cumsum_by_num(PrizeId, Num, []),
    cost:do_get_cost_item_list(N, []).
do_prize_cumsum_by_num(_P, 0, List) ->
    List;
do_prize_cumsum_by_num(PrizeId, Num, List) ->
    do_prize_cumsum_by_num(PrizeId, Num-1, list_add_list(prize:get_itemlist_by_prizeid(PrizeId), List)).



is_tag_on_list([], _) ->
    false;
is_tag_on_list([{Tag, _1} | _T], Tag) ->
    true;
is_tag_on_list([_|T], Tag) ->
    is_tag_on_list(T, Tag).

set_value(?undefined, Dv) ->
    Dv;
set_value(V, _) ->
    V.


list_multiply_coefficient([], _Coefficient, L) ->
    L;
list_multiply_coefficient([H|T], Coefficient, L) ->
    List =
    case H of
        {A, B, C} ->
            [{A, trunc(B*Coefficient), C}|L];
        {A, B} ->
            [{A, trunc(B*Coefficient)}|L];
        _ ->
            L
    end,
    list_multiply_coefficient(T, Coefficient, List).

pkg_player_bin(<<>> ,0, List) ->
    List;
pkg_player_bin(<<PlayerId:64, Res1/binary>>, Size, List) ->
    pkg_player_bin(Res1, Size - 1,[PlayerId | List]);
pkg_player_bin(_A, _B, _C) ->
    [].


bool_to_int(Bool) ->
    case Bool of
        ?true ->
            1;
        ?false ->
            0
    end.

ip_to_str({A, B, C, D}) ->
    lists:concat([A, ".", B, ".", C, ".", D]).

get_now_time() ->
    {{DY, DM, DD}, {H, M, S}} = calendar:local_time(),
    integer_to_list(DY) ++ "-" ++ append_to_string(DM) ++ "-" ++ append_to_string(DD) ++ " " ++ append_to_string(H)
        ++ ":" ++ append_to_string(M) ++ ":" ++ append_to_string(S).
% lists:concat([DY, "-", DM, "-", DD, " ", H, ":", M, ":", S]).

get_now_time(Date) ->
    {{DY,DM,DD}, {H,M,S}} = Date,
    integer_to_list(DY) ++ "-" ++ append_to_string(DM) ++ "-" ++ append_to_string(DD) ++ " " ++ append_to_string(H)
        ++ ":" ++ append_to_string(M) ++ ":" ++ append_to_string(S).
% lists:concat([DY, "-", DM, "-", DD, " ", H, ":", M, ":", S]).

get_format_time(TimeStamp) ->
    case TimeStamp =:= 0 orelse TimeStamp =:= undefined of
        true ->
            0;
        _ ->
            {{DY, DM, DD}, {H, M, S}} = calendar:gregorian_seconds_to_datetime(TimeStamp + 8 * 60 * 60 +
                calendar:datetime_to_gregorian_seconds({{1970, 1, 1}, {0, 0, 0}})),
            integer_to_list(DY) ++ "-" ++ append_to_string(DM) ++ "-" ++ append_to_string(DD) ++ " " ++ append_to_string(H)
                ++ ":" ++ append_to_string(M) ++ ":" ++ append_to_string(S)
    % lists:concat([DY, "-", DM, "-", DD, " ", H, ":", M, ":", S])
    end.


date_2_str(undefined) -> "";
date_2_str(Date) ->
    {{DY,DM,DD}, {H,M,S}} = Date,
    integer_to_list(DY) ++ "-" ++ append_to_string(DM) ++ "-" ++ append_to_string(DD) ++ " " ++ append_to_string(H)
        ++ ":" ++ append_to_string(M) ++ ":" ++ append_to_string(S).
% lists:concat([DY, "-", DM, "-", DD, " ", H, ":", M, ":", S]).

append_to_string(Num) ->
    case Num < 10 of
        true ->
            "0" ++ integer_to_list(Num);
        _ ->
            integer_to_list(Num)
    end.

get_num_list(RetList, _M, _M) -> RetList;
get_num_list(RetList, Min, Max) -> get_num_list( [Min|RetList], Min+1, Max).

%% 向上取整
ceil(N) ->
    T = trunc(N),
    case N == T of
        true  -> T;
        false -> 1 + T
    end.
%% 向下取整
floor(X) ->
    T = trunc(X),
    case (X < T) of
        true -> T - 1;
        _ -> T
    end.

nth(_N, []) -> none;
nth(1, [H|_]) -> H;
nth(N, [_|T]) -> nth(N-1, T).

get_dasy_by_seconds( Second ) ->
    M = util:ceil(Second/1000000),
    {{CY, CM, CD},{_H,_M,_S}} = calendar:now_to_datetime({M, Second-M*1000000, 0}),
    get_days({CY, CM, CD}).

get_dasy_by_seconds_ex( Second ) ->
    M = util:ceil(Second/1000000),
    {{CY, CM, CD},{_H,_M,_S}} = calendar:now_to_datetime({M, Second-M*1000000, 0}),
    {{CY, CM, CD},{_H,_M,_S}}.


get_now_second(Second) ->
    {MegaSecs, Secs, _} = erlang:now(),
    MegaSecs * 1000000 + Secs + Second.



%% 获得天数(有问题，待整改)
get_days() ->
    {CY, CM, CD} = virtual_time:date(),
    calendar:date_to_gregorian_days(CY, CM, CD).

%% 获得天数(有问题，待整改)
get_days({CY, CM, CD}) ->
    calendar:date_to_gregorian_days(CY, CM, CD).


can([]) -> true;
can([Func | TailList]) ->
    case Func() of
        true ->
            can(TailList);
        {false, Reason} ->
            {false, Reason};
        _ ->
            false
    end.

%% can_par(Func, []) -> true;
%% can_par(Func, [Par | TailList]) ->
%%     case Func(Par) of
%%         true ->
%%             can(TailList);
%%         {false, Reason} ->
%%             {false, Reason};
%%         _ ->
%%             false
%%     end.


do([]) -> ok;
do([Func | TailList]) ->
    Func(),
    do(TailList).


mod_can([], _Fun) -> true;
mod_can([{Mod, Pars} | TailList], Fun) ->
    case Mod:Fun(Pars) of
        true ->
            mod_can(TailList, Fun);
        {false, Reason} ->
            {false, Reason};
        _ ->
            false
    end.


mod_fun([], _Fun) -> ok;
mod_fun([{Mod, Pars} | TailList], Fun) ->
%%     ?INFO_LOG("mod_fun ~p",[{Mod, Fun, Pars, TailList}]),
    Mod:Fun(Pars),
    mod_fun(TailList, Fun).


list_from_for(_Max, _Max, _Callback) -> [];
list_from_for(I, Max, Callback) ->
    [Callback(I) | list_from_for(I + 1, Max, Callback)].

do_list_from_for([], _Callback, List2) ->
    List2;
do_list_from_for([Key | TailList], Callback, List2) ->
    case Callback(Key) of
        nil ->
            do_list_from_for(TailList, Callback, List2);
        Val ->
            do_list_from_for(TailList, Callback, [Val | List2])
    end.
list_from_for(List, Callback) ->
    %?DEBUG_LOG("List----------------------:~p",[List]),
    List2 = do_list_from_for(List, Callback, []),
    %?DEBUG_LOG("List2----------------------:~p",[List2]),
    lists:reverse(List2).

%% 查找
lists_get_ex(List, Key) ->
%%     ?INFO_LOG("lists_get_ex ~p",[{List, Key}]),
    case lists:keyfind(Key, 1, List) of
        {_, Val} ->
            Val;
        _ ->
            false
    end.


%% 设置（空值则插入）
lists_set_ex(List, Key, Val) ->
    CurVal = lists_get_ex(List, Key),
    case CurVal of
        false ->
            NewList = [{Key, Val} | List],
            NewList;
        _ ->
            lists:keyreplace(Key, 1, List, {Key, Val})
    end.



%% 设置分支数据并返回整个新结构体
%% case:  set_branch_val(my_tuple, [#my_test.b, {#my_test_sub.m, 6, #my_test_sub{}}, #my_test_sub.n], 99),
set_branch_val(_Root, [], Val) -> Val;
set_branch_val(Root, [Key | TailList], Val) when erlang:is_list(Root) ->
    case Key of
        {ListID, KeyID, DefaultVal} ->
            case lists:keyfind(KeyID, ListID, Root) of
                false ->
                    NewItem = set_branch_val(DefaultVal, TailList, Val),
                    case NewItem of
                        nil -> Root;
                        _ -> [NewItem | Root]
                    end;
                Item ->
                    NewItem = set_branch_val(Item, TailList, Val),
                    case NewItem of
                        nil -> lists:keydelete(KeyID, ListID, Root);
                        _ -> lists:keyreplace(KeyID, ListID, Root, NewItem)
                    end
            end;
        _ -> {error, unknown_type}
    end;
set_branch_val(Root, [Key | TailList], Val) when erlang:is_tuple(Root) ->
    Item = element(Key, Root),
    NewItem = set_branch_val(Item, TailList, Val),
    case NewItem of
        nil ->
            ?ERROR_LOG("failed in set_branch_val ~p ", [{[Key | TailList]}]),
            Root;
        _ -> setelement(Key, Root, NewItem)
    end.

%% case:
%% set_branch_val(X, [#my_test.b, {#my_test_sub.m, 6, #my_test_sub{}}, #my_test_sub.n], 99),
%%{
%%    [
%%        #bucket_interface.goods_list,
%%        {#bucket_sink_interface.id, GoodsID, #item_new{}}
%%        #item_new.quantity
%%    ],
%%    5
%%}.
%% -record(my_test_sub,
%% {
%%     m = 1,
%%     n = 2
%% }).
%% -record(my_test,
%% {
%%     a = 1,
%%     b = [],
%%     c = 0
%% }).
%% test() ->
%%     X = #my_test{ b = [#my_test_sub{m=7,n=8}, #my_test_sub{m=6,n=5}], c = #my_test_sub{}},
%%     ?INFO_LOG("test X ~p", [X]),
%% %%     NewX = set_branch_val(X, [#my_test.a], 50),
%% %%     NewX = set_branch_val(X, [#my_test.b, {#my_test_sub.m, 6, #my_test_sub{}}, #my_test_sub.n], 99),
%%     NewX = set_branch_val(X, [#my_test.c, #my_test_sub.n], [5555]),
%%     ?INFO_LOG("test NewX ~p", [NewX]).

%%     R = load_vip_right:lookup_vip_right_cfg(0),
%%     ?DEBUG_LOG_COLOR(?color_yellow,"init_client load_vip_right ~p ~p ~p",[self(), get(?pd_id), R]),

get_branch_val(Root, [], _Default) -> Root;
get_branch_val(Root, [Key | TailList], Default) when erlang:is_list(Root) ->
    case Key of
        {ListID, KeyID, _} ->
            case lists:keyfind(KeyID, ListID, Root) of
                false -> Default; %% 查找中断也返回默认值
                Item -> get_branch_val(Item, TailList, Default)
            end;
        _ -> {error, unknown_type}
    end;
get_branch_val(Root, [Key | TailList], Default) when erlang:is_tuple(Root) ->
    Item = element(Key, Root),
    get_branch_val(Item, TailList, Default).

list_add_list(L1, L2) when is_list(L1) andalso is_list(L2) ->
    lists_add_list_(L1, L2).

lists_add_list_([H | T], Acc) ->
    lists_add_list_(T, [H | Acc]);
lists_add_list_([], Acc) ->
    Acc.


set_binary(Data, {Pos, Lenght}, Val) ->
    Size = byte_size(Data) * 8,
    Left =
    if
        Pos =< 1 -> 
            0;
        Pos > Size -> 
            Size;
        true -> 
            Pos - 1
    end,
    Right = Left + 1 + Lenght,
    Lenght1 =
    if
        Right > Size -> 
            (Size - Left);
        true -> 
            Lenght
    end,
    RithLeng = (Size - Left - Lenght1),
    <<X:Left, _Y:Lenght1, Z:RithLeng>> = Data,
    <<X:Left, Val:Lenght1, Z:RithLeng>>.


random_list_of_task_star(List) when is_list(List), length(List) > 0 ->
    R = random:uniform(lists:sum(List)),
    random_list_(R, 1, List, 1).
random_list_(_, _, [], Index) ->
    Index - 1;
random_list_(R, Min, [Max | T], Index) ->
    if
        R >= Min, R =< Max ->
            Index;
        true ->
            random_list_(R, Max, T, Index + 1)
    end.

get_pd_field(Key, DefaultVal) ->
    case erlang:get(Key) of
        undefined -> DefaultVal;
        nil -> DefaultVal;
        Val -> Val
    end.

set_pd_field(Key, Val) ->
    erlang:put(Key, Val).

del_pd_field(Key) ->
    erlang:erase(Key).

get_cur_ip() ->
    {ok, IfList} = inet:getifaddrs(),
%%     ?INFO_LOG("get_cur_ip ~p",[IfList]),
    case lists:keyfind("eth0", 1, IfList) of
        false -> undefined;
        {_, ItemPars} ->
%%             ?INFO_LOG("get_cur_ip1 ~p",[ItemPars]),
            case lists:keyfind(addr, 1, ItemPars) of
                false -> undefined;
                {_, Addr} -> {ok, Addr}
            end
    end.

%%获得今天所经过的秒数
get_today_passed_seconds() ->
    {{_DY, _DM, _DD}, {H, M, S}} = calendar:local_time(),
    TodayPassedSeconds = (H * 60 * 60) + (M * 60) + S,
    TodayPassedSeconds.


list_2_len_binary(List, Item2BinaryFun, CountSize) ->
    {Num, ListBinary} =
        lists:foldl
        (
            fun
                (Item, {Count, PreBinary}) ->
                    ItemBinary = Item2BinaryFun( Item ),
                    {Count+1, <<PreBinary/binary, ItemBinary/binary >>}
            end,
            {0, <<>>},
            List
        ),
    <<Num:CountSize, ListBinary/binary>>.

get_val_by_weight([], _Num) ->
    [];
get_val_by_weight(List, Num) when Num > length(List) ->
    ?ERROR_LOG("Num bigger than length of List, List:~p, Num:~p", [List, Num]),
    get_val_by_weight(List, length(List));
get_val_by_weight(List, Num) ->
    get_val_by_weight(List, 0, Num, []).

get_val_by_weight(_, Max, Max, RetList) -> RetList;
get_val_by_weight(List, Min, Max, RetList) ->
    {NewWeight, NewList} =
        lists:foldl(fun({Id, Weight}, {TotalWeight, IdList}) ->
            {Weight + TotalWeight, [{Id, TotalWeight, TotalWeight + Weight} | IdList]}
                    end,
            {0, []},
            List),
    RandomNum = random:uniform(NewWeight),
    [{NewId, _WeightLow, _WeightHigh}] =
        lists:filter(fun({_Id, Low, High}) ->
            RandomNum > Low andalso RandomNum =< High
                     end,
            NewList),
    get_val_by_weight(lists:keydelete(NewId, 1, List), Min + 1, Max, [NewId | RetList]).


is_on_list(Index, List) ->
    case lists:keyfind(Index, 1, List) of
        false ->
            {I, _} = lists:nth(1, List), 
            I;
        _ ->
            Index
    end.

get_field(List, Key, Default) ->
    case lists:keyfind(Key, 1, List) of
        {Key, Val} -> Val;
        _ -> Default
    end.

set_field(List, Key, Val) ->
    lists:keystore(Key, 1, List, {Key,Val}).

del_field(List, Key) ->
    lists:keydelete(Key, 1, List).

%% 判断某一天是否在该时间的范围内
is_in_this_time(TimeSec, Team) when is_tuple(Team)->
    case Team of
        {{week, _WeekDay}, StartTime, EndTime} ->
            TimeSec >= StartTime andalso TimeSec =< EndTime;
        _ -> 0
    end.

%% 判断两个日期是否是同一周
is_in_same_week(Day1, Day2) ->
    SunDay1 = get_the_weekend_of_day(Day1),
    SunDay2 = get_the_weekend_of_day(Day2),
    if
        SunDay1 =:= SunDay2 ->
            true;
        true ->
            false
    end.

%% 获得某一日期所在周的周日
get_the_weekend_of_day({Y, M, D}) ->
    Week = calendar:day_of_the_week({Y, M, D}),
    SunDay = 7 - Week,
    {Y , M, D+SunDay}.

%% 获得今天的签到奖励Id年月日
get_the_YMD_of_day() ->
    LocalTime = erlang:localtime(),
    {{_Year,_Month,Day},_} = LocalTime,
    get_the_YMD_of_day(Day).

get_the_YMD_of_day(Day) ->
    LocalTime = erlang:localtime(),
    {{Year,Month,_},_} = LocalTime,
    Year * 10000 + Month * 100 + Day.




node_send_to_client(Pid, Msg) ->
    Pid ! {?send_to_client, Msg}.

%% 前10名刷新排行榜
is_flush_rank_only_by_rankname(RankName, Id) ->
    {Order, _} = ranking_lib:get_rank_order(RankName, Id),
    if
        Order =< 10 ->
            ranking_lib:flush_rank_only_by_rankname(RankName);
        true ->
            pass
    end.

