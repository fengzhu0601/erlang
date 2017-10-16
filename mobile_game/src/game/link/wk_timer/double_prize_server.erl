-module(double_prize_server).

%% API


-export([start_link/0,init/1,handle_call/3, handle_cast/2, handle_info/2, code_change/3, terminate/2]).

-behaviour(gen_server).

-define(TEN_MINUTE, 10 * 60).

-include("inc.hrl").
-include("player.hrl").
-include("load_double_prize_cfg.hrl").

-export([
    pack_double_prize_activity/0,
    is_double_prize/1
]).


-define(FUN, fun(A,B) -> A < B end).


-define(double_prize_data, double_prize_data).
-record(double_prize_data,{
    broadcast_list=[],      %% 广播列表。。
    ing_list=[]             %% 活动当中的广播
}).

-define(cur_double_prize_activity_list, cur_double_prize_activity_list).
-record(cur_double_prize_activity_list, {
    id=1,
    list=[]
}).


get_t(Id, CurWeekDay, Dpc) ->
    {_, H1,M1,S1,BroadcastId1} = lists:keyfind(CurWeekDay, 1, Dpc#double_prize_cfg.start_activity),
    {_, H2,M2,S2,BroadcastId2} = lists:keyfind(CurWeekDay, 1, Dpc#double_prize_cfg.yugao_activity),
    [{H1,M1,S1,Id,BroadcastId1,CurWeekDay, ?START_DP}, {H2,M2,S2,Id,BroadcastId2, CurWeekDay, ?YUGAO_DP}].


init_data2() ->
    CurWeekDay = com_time:day_of_the_week(),
    {_, Now} = calendar:now_to_local_time(os:timestamp()),
    L = 
    lists:foldl(fun({_, Dpc}, L) ->
        Id = Dpc#double_prize_cfg.id,
        EndActivityList = Dpc#double_prize_cfg.end_activity,
        case lists:keyfind(CurWeekDay, 1, EndActivityList) of
            {W, H, M ,S, BroadcastId} when {H,M,S} > Now->
                Cl = [{H, M, S, Id, BroadcastId, W, ?END_DP}] ++ get_t(Id, CurWeekDay, Dpc),
                Cl++L;
            _ ->
                L
        end
    end,
    [],
    ets:tab2list(double_prize_cfg)),
    SortL = lists:sort(?FUN, L),
    %?DEBUG_LOG("SortL-------------------:~p",[SortL]),
    {WaitList, CurList} =            
    lists:foldl(fun({H, M, S, _Id, _BroadcastId, _Week, Type} = A, {List1, List2}) ->
        if
            Type =:= ?YUGAO_DP ->
                if
                    Now >= {H, M, S} ->
                        {lists:delete(A, List1), List2};
                    true ->
                        {List1, List2}
                end;
            Type =:= ?START_DP ->
                if
                    Now >= {H, M, S} ->
                        {lists:delete(A, List1), [A|List2]};
                    true ->
                        {List1, List2}
                end;
            Type =:= ?END_DP ->
                {List1, List2} 
        end
    end,
    {SortL,[]},
    SortL),
    %?DEBUG_LOG("WaitList-----:~p-----CurList------:~p",[WaitList, CurList]),
    %?DEBUG_LOG("L------------------------:~p--Size------:~p",[SortL,length(L)]),
    {WaitList, CurList}.

-define(TIME, 100).

start_auto_notice([]) ->
    pass;
start_auto_notice([{_H, _M, _S, ActivityId, BroadcastId, _W, _T} = _A|T]) -> %% TODO
    %?DEBUG_LOG("Id----:~p----IngID------:~p",[ActivityId, BroadcastId]),
    case load_double_prize:get_double_prize_xun_huan_time(ActivityId) of
        ?none ->
            pass;
        IngidTime ->
            erlang:send_after(IngidTime * ?SECONDS_PER_MINUTE * 1000, self(), {notice, ActivityId, BroadcastId, IngidTime})
    end,
    start_auto_notice(T).


start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

init([]) ->
    ets:new(?cur_double_prize_activity_list, [public,set,named_table,{keypos, #cur_double_prize_activity_list.id}, {write_concurrency, true}, {read_concurrency, true}]),
    {WaitList, CurList} = init_data2(),
    ets:insert(?cur_double_prize_activity_list, #cur_double_prize_activity_list{id=1, list=CurList}),
    start_auto_notice(CurList),
    M2 = com_time:get_seconds_to_next_day(),
    %?DEBUG_LOG("M2----------------------1-----------:~p",[M2]),
    erlang:send_after(M2 * 1000, self(), reset_state),
    NewWaitList =
    case WaitList of
        [] ->
            [];
        [{H,M,S,_,_,_,_}=Head|Tail] ->
            %?DEBUG_LOG("Head----------------------:~p",[Head]),
            {_, Now} = calendar:now_to_local_time(os:timestamp()),
            T = calendar:time_to_seconds({H,M,S}) - calendar:time_to_seconds(Now),
            %?DEBUG_LOG("T-----------------------:~p",[T]),
            erlang:send_after(T*1000, self(), {notice, Head}),
            Tail
    end,
    {ok, #double_prize_data{broadcast_list=NewWaitList, ing_list=CurList}}.


is_double_prize(ActivityId) ->
    case ets:info(?cur_double_prize_activity_list) of
        ?undefined ->
            false;
        _ ->
            case ets:lookup(?cur_double_prize_activity_list, 1) of
                [] ->
                    false;
                [#cur_double_prize_activity_list{list=L}] ->
                    lists:keymember(ActivityId, 4, L)
            end
    end.

pack_double_prize_activity() ->
    %List = [{1000,com_time:now(), com_time:now() + 9000},{2000,com_time:now(), com_time:now() + 9000}],
    %?DEBUG_LOG("List-----------------------------:~p",[List]),
    List = 
    case ets:info(?cur_double_prize_activity_list) of
        ?undefined ->
            [];
        _ ->
            case ets:lookup(?cur_double_prize_activity_list, 1) of
                [] ->
                    [];
                [#cur_double_prize_activity_list{list=L}] ->
                    L
            end
    end,
    Bin = 
    lists:foldl(fun({H, M, S, Id, _BroadcastId, Week, _Type}, Acc)->
        case load_double_prize:get_double_prize_activity_end_time(Id, Week) of
            ?none ->
                Acc;
            {H2,M2,S2} ->
                StartTime = com_time:timestamp_sec({H,M,S}),
                EndTime = com_time:timestamp_sec({H2,M2,S2}),
                <<Acc/binary, Id:16, StartTime:64, EndTime:64>>
        end
    end,
    <<(length(List)):16>>,
    List), 
    ?player_send(scene_sproto:pkg_msg(?MSG_SCENE_DOUBLE_PRIZE_ACTIVITY, {Bin})).





handle_call(_Msg, _, State) ->
    {noreply, State}.

handle_info({notice, ActivityId, BroadcastId, IngidTime}, State) ->
    %?DEBUG_LOG("State---------------------------:~p",[State]),
    IngList = State#double_prize_data.ing_list,
    case lists:keyfind(ActivityId, 1, IngList) of
        ?false ->
            pass;
        _ ->
            notice_system:double_prize_broadcast(BroadcastId),
            erlang:send_after(IngidTime * ?SECONDS_PER_MINUTE * 1000, self(), {notice, ActivityId, BroadcastId, IngidTime})
    end,
    {noreply, State};

handle_info({notice, {_, _, _, _Id, BroadcastId, _Week, Type} = A}, State) ->
    BroadCastList = State#double_prize_data.broadcast_list,
    %?DEBUG_LOG("BroadCastList-----------------------111:~p",[BroadCastList]),
    IngList = State#double_prize_data.ing_list,
    NewIngList =
    if
        Type =:= ?YUGAO_DP ->
            notice_system:double_prize_broadcast(BroadcastId, 3600),
            lists:delete(A, IngList);
        Type =:= ?START_DP ->
            notice_system:double_prize_broadcast(BroadcastId),
            [A|IngList];
        Type =:= ?END_DP ->
            notice_system:double_prize_broadcast(BroadcastId),
            lists:delete(A, IngList)
    end,
    ets:insert(?cur_double_prize_activity_list, #cur_double_prize_activity_list{id=1, list=NewIngList}),
    NewBroadCastList =
    if
        BroadCastList =:= [] ->
            BroadCastList;
        true ->
            [{H,M, S,_,_,_,_}=Head|Tail] = BroadCastList,
            {_, Now} = calendar:now_to_local_time(os:timestamp()),
            T = calendar:time_to_seconds({H,M,S}) - calendar:time_to_seconds(Now),
            %?DEBUG_LOG("notice T --------------------------:~p",[T]),
            erlang:send_after(T*1000, self(), {notice, Head}),
            Tail
    end,
    {noreply, State#double_prize_data{broadcast_list=NewBroadCastList, ing_list=NewIngList}};

handle_info(reset_state, _State) ->
    ?DEBUG_LOG("reset_state-------------------------------"),
    {WaitList, CurList} = init_data2(),
    ets:insert(?cur_double_prize_activity_list, #cur_double_prize_activity_list{id=1, list=CurList}),
    M2 = com_time:get_seconds_to_next_day(),
    erlang:send_after(M2 * 1000, self(), reset_state),
    NewWaitList =
    case WaitList of
        [] ->
            [];
        [{H,M,S,_,_,_,_}=Head|Tail] ->
            {_, Now} = calendar:now_to_local_time(os:timestamp()),
            T = calendar:time_to_seconds({H,M,S}) - calendar:time_to_seconds(Now),
            erlang:send_after(T*1000, self(), {notice, Head}),
            Tail
    end,
    {noreply, #double_prize_data{broadcast_list=NewWaitList, ing_list=CurList}};

handle_info(_Msg, State) ->
    {noreply, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

code_change(_, _, State) ->
    {ok, State}.

terminate(_Reason,_State) ->
    ok.

