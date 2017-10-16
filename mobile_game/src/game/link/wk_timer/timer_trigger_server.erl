-module(timer_trigger_server).

%% API


-export([start_link/0,init/1,handle_call/3, handle_cast/2, handle_info/2, code_change/3, terminate/2]).

-behaviour(gen_server).

-define(TEN_MINUTE, 10 * 60).

-include("inc.hrl").
-include("player.hrl").
-include("load_cfg_time_trigger.hrl").
-include("load_cfg_open_server_happy.hrl").

-export([
    pack_activity/0
]).

-define(activity_list, activity_list).



-define(current_activity_id, current_activity_id).


start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

init([]) ->
    ets:new(?activity_list, [public,set,named_table]),
    %ets:new(?activity_list, [public,set,named_table,{keypos, #activity_list.id}, {write_concurrency, true}, {read_concurrency, true}]),
    %ets:insert(?activity_list, #activity_list{id=1}),
    %% 如果在活动时间内才开启赏金任务活动
    open_bounty_server(),
    {_, Now} = calendar:now_to_local_time(os:timestamp()),
    init_execute(Now),
    {ok, none}.

is_start_activity(ActivityId) ->
    case ets:lookup(activity_time, ActivityId) of
        [] ->
            false;
        _ ->
            true
    end.

is_same_week(_, 0) ->
    true;
is_same_week(Day, Week) when is_integer(Week) andalso Week > 0  ->
    Day =:= Week.



%获取当前可执行的命令表
get_cur_can_run_commond_list(Time) ->
    CurWeekDay = com_time:day_of_the_week(),
    %?DEBUG_LOG("CurWeekDay------------------:~p",[CurWeekDay]),
    ets:foldl(fun({Id, Record}, Acc)-> 
        IsSameWeek = is_same_week(CurWeekDay, Record#time_trigger_cfg.week),
        %?DEBUG_LOG("IsSameWeek---------------------:~p",[IsSameWeek]),
        if
            Record#time_trigger_cfg.time == Time andalso IsSameWeek =:= true ->
                case Record#time_trigger_cfg.is_end of
                    undefined ->                     
                        Acc;
                    IsEnd when IsEnd =:= 1; IsEnd =:= 3 ->                               
                       [Record|Acc];
                    _ ->
                        Acc
                end;
            true ->
                Acc
        end
    end, 
    [], 
    time_trigger_cfg).


init_execute(Time) ->
    CanExecuteCfgList = get_cur_can_run_commond_list(Time),
    ?DEBUG_LOG("CanExecuteCfgList------------------------:~p",[CanExecuteCfgList]),
    lists:foreach(fun(Cfg)->
        NextId = Cfg#time_trigger_cfg.id+1,
        ClientActivityId = Cfg#time_trigger_cfg.activity_id,
        BroadcastId = Cfg#time_trigger_cfg.broadcast_id,
        case Cfg#time_trigger_cfg.is_end of
            1 ->
                BroadcastRule = Cfg#time_trigger_cfg.broadcast_rule,
                put(?current_activity_id, NextId),
                auto_notice(NextId, BroadcastRule, BroadcastId);
            3 ->
                put(?current_activity_id, NextId),
                ets:insert(?activity_list, {ClientActivityId, 0}),
                {M,F,A} = Cfg#time_trigger_cfg.command,
                erlang:apply(M,F,A),
                broadcast_activity_data(1, ClientActivityId, BroadcastId);
            _ ->
                pass
        end
    end,
    CanExecuteCfgList),
    find_next_timer().      %找下次触发的命令

execute(ActivityId) ->
    Cfg = load_cfg_time_trigger:lookup_time_trigger_cfg(ActivityId),
    %?DEBUG_LOG("ActivityId--------------------------------:~p",[Cfg]),
    NextId = Cfg#time_trigger_cfg.id+1,
    put(?current_activity_id, NextId),
    ClientActivityId = Cfg#time_trigger_cfg.activity_id,
    BroadcastId = Cfg#time_trigger_cfg.broadcast_id,
    CurWeekDay = com_time:day_of_the_week(),
    case is_same_week(CurWeekDay, Cfg#time_trigger_cfg.week) of
        true ->
            case Cfg#time_trigger_cfg.is_end of
                1 ->
                    BroadcastRule = Cfg#time_trigger_cfg.broadcast_rule,
                    auto_notice(NextId, BroadcastRule, BroadcastId);
                2 ->
                    broadcast_activity_data(2, ClientActivityId, BroadcastId);
                3 ->
                    {M,F,A} = Cfg#time_trigger_cfg.command,
                    broadcast_activity_data(3, ClientActivityId, BroadcastId), 
                    ets:insert(?activity_list, {ClientActivityId, 0}),
                    erlang:apply(M,F,A);
                4 ->
                    {M,F,A} = Cfg#time_trigger_cfg.command,
                    broadcast_activity_data(4, ClientActivityId, BroadcastId),
                    ets:delete(?activity_list, ClientActivityId),
                    erlang:apply(M,F,A);
                _ ->
                    pass
            end;
        _ ->
            pass
    end,
    find_next_timer().      %找下次触发的命令
    
auto_notice(_Id, {0, _}, _) ->
    ?DEBUG_LOG("not auto notice-----------------------------------------------------------");
auto_notice(Id, {Count, OneTime}, BroadcastId) ->
%%    TotalTime = load_cfg_time_trigger:get_interval_time_by_id(Id),
%%    ?DEBUG_LOG("TotalTime------------------------:~p---OneTime---:~p",[TotalTime, OneTime]),
    case load_cfg_time_trigger:lookup_time_trigger_cfg(Id) of
        ?none ->
            pass;
        #time_trigger_cfg{time = TimeCfg} ->
            TimeSecond = time_to_second(TimeCfg),
            case TimeSecond > util:get_today_passed_seconds() of
                true ->
                    SendSecond = TimeSecond - util:get_today_passed_seconds(),
                    SendMesList =
                        case lists:member(BroadcastId, [6,8]) of                  %% [6,8]是配置表broadcast.txt中的信息id,根据补充字段数量的不同
                            true ->
                                %[{6, 1, unicode:characters_to_binary("怪物攻城")}];
                                [];
                            _ ->
                                %[{6, 1, unicode:characters_to_binary("怪物攻城")},{10, 4, integer_to_binary(SendSecond)}];
                                [{10, 4, integer_to_binary(SendSecond)}]
                        end,
                    world:broadcast(?to_client_msg(chat_sproto:pkg_msg(?MSG_CHAT_SYSTEM_C, {BroadcastId, 0, SendMesList, [],[]})));
                _ ->
                    pass
            end,
            %world:broadcast(?to_client_msg(chat_sproto:pkg_msg(?MSG_CHAT_SYSTEM_B, {BroadcastId,TotalTime}))),
            erlang:send_after(OneTime*1000, self(), {auto_notice, Id, {Count-1, OneTime}, BroadcastId})
    end.




%% 注意当两个配置表中连续出现相同的时间，会出现死循环
do_send_after(Time, Id) when Time > 0 ->
    erlang:send_after(Time*1000, self(), {on_time, Id});
do_send_after(0, Id) ->
    self() ! {on_time, Id};
do_send_after(_, _Id) ->
    erase(?current_activity_id),
    find_next_timer().

find_next_timer() ->
    {_, Time} = calendar:now_to_local_time(os:timestamp()),
    case get(?current_activity_id) of
        undefined ->
            {NextInterval, NexTime, Id} = get_next_event_interval(Time),
            %?DEBUG_LOG("NextInterval-----:~p----NextTime---:~p---Id----:~p",[NextInterval, NexTime, Id]),
            do_send_after(NextInterval, Id);
        ActivityId ->
            DayIsWeek = com_time:day_of_the_week(),
            case load_cfg_time_trigger:lookup_time_trigger_cfg(ActivityId) of
                none ->
                    {NextInterval, NexTime, Id} = get_next_event_interval(Time),
                    do_send_after(NextInterval, Id);
                #time_trigger_cfg{time = T, week=Week} ->
                    case is_same_week(DayIsWeek, Week) of
                        true ->
                            NextInterval = calendar:time_to_seconds(T) - calendar:time_to_seconds(Time),
                            do_send_after(NextInterval, ActivityId);
                        _ ->
                            find_next_timer()
                    end
            end
    end.

get_next_event_interval(CurrentTime)->
    case find_next_event_time(CurrentTime) of
        {24,0,0} ->
            %?DEBUG_LOG("24.0.0----------------------------"),
            TimerTriggerCfg = load_cfg_time_trigger:lookup_time_trigger_cfg(1),
            {Hours, Minutes, Seconds} = T =  TimerTriggerCfg#time_trigger_cfg.time,
            if
                T < CurrentTime ->
                    %?DEBUG_LOG("1------------------------------------------"),
                    {com_time:get_seconds_to_next_day() + Hours*60*60 + Minutes * 60 + Seconds,T, 1};
                true ->
                    %?DEBUG_LOG("2-----------------------------------------"),
                    {calendar:time_to_seconds(T)-calendar:time_to_seconds(CurrentTime), T, 1}
            end;
        {NextEventTime, Id} ->
            %?DEBUG_LOG("NextEventTime---------------------------------------"),
            {calendar:time_to_seconds(NextEventTime) - calendar:time_to_seconds(CurrentTime), NextEventTime, Id}
    end.

find_next_event_time(CurrentTime) ->
    ets:foldl(fun({_Id,Record}, MinTime)->
        Time = Record#time_trigger_cfg.time,
        Week = Record#time_trigger_cfg.week,
        DayIsWeek = com_time:day_of_the_week(),
        case is_same_week(DayIsWeek, Week) of
            true ->
                if
                    Time > CurrentTime, Time < MinTime ->
                        {Time, Record#time_trigger_cfg.id};
                    true ->
                        MinTime
                end;
            _ ->
                MinTime
        end
    end,
    {24,0,0},
    time_trigger_cfg).




cancel_time_of_activity(Id) ->
    case get(Id) of
        undefined ->
            pass;
        T ->
            erlang:cancel_timer(T)
    end.

broadcast_activity_data(Status, ActivityId, BroadcastId) ->
%%    ?DEBUG_LOG("Status---:~p---ActivityId----:~p-----BroadCastId---:~p",[Status, ActivityId, BroadcastId]),
    case lists:member(BroadcastId, [6,8]) of                  %% [6,8]是配置表broadcast.txt中的信息id,根据补充字段数量的不同
        true ->
%%            SendMesList = [{6, 1, unicode:characters_to_binary("怪物攻城")}],
            SendMesList = [],
            world:broadcast(?to_client_msg(chat_sproto:pkg_msg(?MSG_CHAT_SYSTEM_C, {BroadcastId, 0, SendMesList, [], []})));
        _ ->
            pass
    end.
%%    world:broadcast(?to_client_msg(scene_sproto:pkg_msg(?MSG_SCENE_BROADCAST_ACTIVITY, {Status, ActivityId, BroadcastId}))).



pack_activity() ->
    List = ets:tab2list(?activity_list),
    Bin = 
    lists:foldl(fun({Id, _EndTime}, Acc)->
        <<Acc/binary, Id>>
    end,
    <<(length(List)):16>>,
    List),
    ?player_send(player_sproto:pkg_msg(?MSG_PLAYER_ACTIVITY_LIST, {Bin})).



handle_call(Msg, _, State) ->
    {noreply, State}.


handle_info({on_time, Id}, State) ->
    execute(Id),
    {noreply, State};

handle_info({auto_notice, Id, BroadcastRule, BroadcastId}, State) ->
    %?DEBUG_LOG("handle_info auto_notice-----------------------------------"),
    auto_notice(Id, BroadcastRule, BroadcastId),
    {noreply, State};



handle_info(Msg, State) ->
    {noreply, State}.

handle_cast(Msg, State) ->
    {noreply, State}.

code_change(_, _, State) ->
    {ok, State}.

terminate(Reason,State) ->
    ok.

time_to_second({Hour, Min, Sec}) ->
    Hour*3600 + Min*60 + Sec.


open_bounty_server() ->
    case load_cfg_open_server_happy:the_activity_is_over(?BOUNTY_TASK_ID) of
        ?true ->
            bounty_mng:start_bounty_activity();
        ?false ->
            pass
    end.
