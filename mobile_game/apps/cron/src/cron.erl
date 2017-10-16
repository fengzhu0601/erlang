%%%-------------------------------------------------------------------
%%% @author zl
%%% @doc execute  M:F:A funtion like Unix cron.
%%%
%%% TODO MD5 check
%%% @end
%%%-------------------------------------------------------------------

-module(cron).

-behaviour(gen_server).
%% gen_server callbacks
-export([init/1,handle_call/3,handle_cast/2,handle_info/2,terminate/2,code_change/3]).

%% API
-export([reload_crontable/0,
         check_crontab/0,
         start_link/0
         %% info
        ]).

-include_lib("common/include/com_define.hrl").
-include_lib("common/include/com_log.hrl").

-record(cron_task, {id,
                    minute :: [integer()],
                    hour :: [integer()],
                    dom ::[integer()],
                    dow :: [integer()],
                    month ::[integer()],
                    fma %% {F,M,A}
                   }).

-record(state,
        {name,
         task,
         expire_times,
         timer
        }).

%% @doc Starts the server
start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

%% reload crontable
reload_crontable() ->
    ?MODULE ! {reload_config}.


%% @spec handle_cast(Msg, State) -> {noreply, State} |
init([]) ->
    com_process:init_name(<<"APPLICATION cron">>),
    com_process:init_type(?MODULE),

    State = load_task(),

    ?INFO_LOG("~p start ", [?pname()]),
    {ok, 
     State,
     com_proc_timer:next_timeout(State#state.timer)
    }.

%% @spec handle_cast(Msg, State) -> {noreply, State} |
handle_call(_Request, _From, State) ->
    ?ERROR_LOG("~p recive a unknow call msg ~p", [?pname(), _Request]),
    {reply, ok, State, com_proc_timer:next_timeout(State#state.timer)}.

%% @spec handle_cast(Msg, State) -> {noreply, State} |
%%                                  {noreply, State, Timeout} |
%%                                  {noreply, State, hibernate} |
%%                                  {stop, Reason, State}
handle_cast(_Msg, State) ->
    ?ERROR_LOG("~p recive a unknow cast msg ~p", [?pname(), _Msg]),
    {noreply, State, com_proc_timer:next_timeout(State#state.timer)}.

handle_info(reload, State) ->
    State = load_task(),
    ?INFO_LOG("~p reload config successed", [?pname()]),
    {noreply,
     State,
     com_proc_timer:next_timeout(State#state.timer)
    };

handle_info(timeout, #state{timer=TMng, task=CronTask}=State) ->
    {TimerList, Mng_2} = com_proc_timer:take_timeout_timer(TMng),

    lists:foreach(
      fun({_Ref, TaskId}) ->
              #cron_task{id=TaskId, fma={F,M,A}} = lists:keyfind(TaskId, 2, CronTask),
              Now = com_time:now(),
              ?INFO_LOG("~p exec cmd:~p, Time = ~p", [?pname(), TaskId, Now]),
              _=com_util:safe_apply(F,M,A)
      end,
      TimerList),
    {
     noreply,
     State#state{timer=Mng_2},
     com_proc_timer:next_timeout(TMng)
    };

handle_info(_Msg, State) ->
    ?ERROR_LOG("~p recive a unknow info msg ~p", [?pname(), _Msg]),
    {
     noreply,
     State,
     com_proc_timer:next_timeout(State#state.timer)
    }.

%% @spec terminate(Reason, State) -> no_return()
%%       Reason = normal | shutdown | {shutdown, term()} | term()
terminate(Reason, _State) ->
    case Reason of
        ?normal -> ok;
        ?shutdown -> ok;
        _ ->
          ?ERROR_LOG("~p Crash with:~p ", [?pname(), Reason])
    end,

    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.



%%=======================================================================
%% Internal functions
%%=======================================================================

%-type month()    :: 1..12.
%-type day()      :: 1..31.
%-type hour()     :: 0..23.
%-type minute()   :: 0..59.
%-type dow()      :: 1..7.
%-type dom()      :: 1..31.


check_crontab() ->
    {ok, CronTab} = application:get_env(crontab),
     ?DEBUG_LOG("CronTab ~p", [CronTab]),

    case file:consult(CronTab) of
        {error, Reason} ->
            ?ERROR_LOG("check_crontab error please check crontab\n~p", [Reason]),
            error;
        {ok, TaskList} ->
%%             ?DEBUG_LOG("TaskList:~p",[TaskList]),
            case lists:all(fun check_task/1, TaskList) of
                true -> TaskList;
                false -> error
            end
    end.

%%==========================================================
%% Interval funcs
%%==========================================================


%% ->[#cron_task{}]
load_crontab() ->
    case check_crontab() of
        error ->
            error;
        TaskList ->
            lists:map(
              fun({Id, Minute, Hour, Dom, Mon, Dow, MFA}) ->
                      #cron_task{id=Id,
                                 minute=value_to_list(minute,Minute),
                                 hour = value_to_list(hour,Hour),
                                 month= value_to_list(month,Mon),
                                 dom = if Dom =:= "*" ->
                                              if Dow =:= "*" -> value_to_list(dom,Dom);
                                                 true ->
                                                     []
                                              end;
                                          true ->
                                              value_to_list(dom,Dom)
                                       end,
                                 dow = if Dow =:= "*" ->
                                              if Dom =:= "*" -> value_to_list(dow,Dow);
                                                 true ->
                                                     []
                                              end;
                                          true ->
                                              value_to_list(dow,Dow)
                                       end,
                                 fma=MFA
                                }
              end,
              TaskList)
    end.


%% orddict value{ExpireTimeSec, [id]}
get_today_tasks(CronTasks) ->
    TodayCronTasks=
    com_lists:take(
      fun(#cron_task{month=Mons, dom=Doms, dow=Dows}) ->
              {{Y,Mon,Dom},_}=erlang:localtime(),
              Dow=calendar:day_of_the_week(Y,Mon,Dom),
              case {lists:member(Mon,Mons),
                    lists:member(Dom, Doms),
                    lists:member(Dow, Dows)}
              of
                  {true, true,_} ->
                      true;
                  {true, false, true} ->
                      true;
                  _ ->
                      false
              end
      end,
      CronTasks),
    %% minutes
    %% 活动启动的时间（从０点到现在的时间）。
    lists:foldl(
      fun(#cron_task{id=Id,minute=Minutes, hour=Hours}, AccIn ) ->
              [{((Hour * ?MINUTES_PER_HOUR) + Minute) * ?SECONDS_PER_MINUTE, Id}
               || Minute <- Minutes, Hour <- Hours] ++ AccIn
      end,
      [],
      TodayCronTasks).



%% -> boolean().
%%{id, minute, hour, dom, mon, dow, mfa}
check_task({_Id, Minute, Hour, Dom, Mon, Dow, MFA}=Cfg) ->
    lists:any(fun(true) ->
                      true;
                 (false) ->
                      ?ERROR_LOG("~p bad format ", [Cfg]),
                      false
              end,
              [
               check_minute(Minute),
               check_hour(Hour),
               check_dom(Dom),
               check_month(Mon),
               check_dow(Dow),
               check_MFA(MFA)
              ]).


value_to_list(_,Minute) when is_integer(Minute) ->
    [Minute];
value_to_list(_,{Begin, End}) when Begin =< End ->
    lists:seq(Begin, End);
value_to_list(minute,"*") ->
    lists:seq(0,59);
value_to_list(hour,"*") ->
    lists:seq(0,23);
value_to_list(dom,"*")  ->
    lists:seq(1,31);
value_to_list(dow,"*")  ->
    lists:seq(1,7);
value_to_list(month,"*") ->
    lists:seq(1,12);
value_to_list(_,List) when is_list(List) ->
    List;
value_to_list(_,_)  ->
    [100]. %% make bad

check_minute(V) ->
    lists:all(fun is_valid_minute/1, value_to_list(minute,V)).
check_hour(V) ->
    lists:all(fun is_valid_hour/1, value_to_list(hour,V)).
check_dom(V) ->
    lists:all(fun is_valid_dom/1, value_to_list(dom,V)).
check_month(V) ->
    lists:all(fun is_valid_month/1, value_to_list(month,V)).
check_dow(V) ->
    lists:all(fun is_valid_dow/1, value_to_list(dow,V)).

check_MFA({M,F,A}=MFA) ->
    N =erlang:length(A),
    case erlang:function_exported(M, F, N) of
        true -> true;
        false ->
            ?ERROR_LOG("~p not exported",[MFA]),
            false
    end.



is_valid_minute(V) ->
    V >= 0 andalso V =< 59.
is_valid_hour(V) ->
    V >= 0 andalso V =< 23.
%%day of month
is_valid_dom(V) ->
    V >= 1 andalso V =< 31.
%day of week
is_valid_dow(V) ->
    V >= 1 andalso V =< 7.
is_valid_month(V)->
    V >= 1 andalso V =< 12.

load_task() ->
    CronTasks=load_crontab(),
    ExpireTimes=get_today_tasks(CronTasks),
%%     ?DEBUG_LOG("init over: CronTasks:~w, ExpireTimes~w\n",[CronTasks,ExpireTimes]),
    Begin = com_time:today_passed_sec(),

    TMng =
    lists:foldl(fun({ExpireSec, TaskId}, Acc) ->
                        case ExpireSec - Begin of
                            N when N > 0 ->
                                {_, NAcc} = com_proc_timer:start_timer(N*1000, TaskId, Acc),
                                NAcc;
                            _ ->
                                Acc
                        end
                end,
                com_proc_timer:new(),
                ExpireTimes),
     #state{name=?MODULE, task=CronTasks, expire_times=ExpireTimes, timer=TMng}.
