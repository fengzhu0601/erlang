-module(lib_clock).
%%% @doc 时钟发生器
%%% 性能的主要消耗在发送信息的数量

%%%% API
%%-export([reg_self/1,
         %%unreg_self/0]).

%%%% start
%%-export([start_link/0]).
%%-export([worker_init/1]).

%%-include("eunit_ext.hrl").
%%-include("com_log.hrl").


%%-define(CLOCK_TICK, 10). %% 时钟间隔 毫秒
%%-define(CLOCK_TICK_MSG, 'CLOCK_TICK').


%%%% 修正过的Time
%%-define(get_interval(Time), Time div ?CLOCK_TICK * ?CLOCK_TICK).


%%%% @doc 注册时钟发生器,Time 以毫秒为准,精度在 +-CLOCK_TICK
%%%% 注册以后会以Time间隔发送  ?CLOCK_TICK_MSG
%%-spec reg_self(pos_integer()) -> true.
%%reg_self(Time)
  %%when is_integer(Time),
       %%Time >= ?CLOCK_TICK ->
    %%Interval = ?get_interval(Time),
    %%case ets:lookup(?MODULE, self()) of
        %%[] -> ok;
        %%[{_, OldWorkerPid}] ->
            %%OldWorkerPid ! {unregister, self()},
            %%ets:delete(?MODULE, self())
    %%end,
    %%case ets:lookup(?MODULE, Interval) of
        %%[] ->
            %%WorkerPid = erlang:spawn(?MODULE, worker_init, [Interval]),
            %%case ets:insert_new(?MODULE, {Interval, WorkerPid}) of
                %%false ->
                    %%erlang:exit(WorkerPid, normal),
                    %%reg_self(Time);
                %%true ->
                    %%WorkerPid ! {register, self()},
                    %%true = ets:insert_new(?MODULE, {self(), WorkerPid})
            %%end;
        %%[{Interval,WorkerPid}] ->
            %%WorkerPid!  {register, self()},
            %%true = ets:insert_new(?MODULE, {self(), WorkerPid})
    %%end.

%%%% @doc 注销时钟，如果一个process终结，会自动取消已经注册的时钟
%%-spec unreg_self() -> ok.
%%unreg_self() ->
    %%case ets:lookup(?MODULE, self()) of
        %%[] ->
            %%?ERROR_LOG("not find self");
        %%[{_,WorkerPid}] ->
            %%WorkerPid ! {unregister, self()},
            %%ets:delete(?MODULE, self())
    %%end,
    %%ok.


%%%% @doc start clock service.
%%start_link() ->
    %%case erlang:whereis(?MODULE) of
        %%undefined ->
            %%{ok, erlang:spawn_link(fun init/0)};
        %%_ ->
            %%?ERROR_LOG("~p is started", [?MODULE])
    %%end.

%%%% --------------------------------------------------------------------
%%%%% Internal functions
%%%% --------------------------------------------------------------------

%%-define(clock_tick, clock_tick).


%%init() ->
    %%erlang:register(?MODULE, self()),
                                                %%%{Pid, WorkerPid}
                                                %%%{Pid, Interval}
    %%?MODULE= ets:new(?MODULE, [named_table, public, {read_concurrency, true},{write_concurrency, true}]),
    %%loop().

%%loop() ->
    %%receive
        %%_Msg -> ?ERROR_LOG("unknow msg~p", [_Msg])
    %%after 1000 ->
            %%lists:foreach(fun({Pid, WorkerPid}) when is_pid(Pid) ->
                                  %%case erlang:is_process_alive(Pid) of
                                      %%true -> ok;
                                      %%false ->
                                          %%WorkerPid ! {unregister, Pid},
                                          %%ets:delete(?MODULE, Pid)
                                  %%end;
                             %%({_Inteval, _WorkerPid}) ->
                                  %%ok
                          %%end,
                          %%com_ets:to_list(?MODULE))
    %%end,
    %%loop().

%%worker_init(Time) ->
    %%erlang:send_after(Time, self(), ?clock_tick),
    %%worker_loop({Time,[]}).


%%worker_loop({Time, Pids}) ->
                                                %%%?DEBUG_LOG("pids:~p", [Pids]),
    %%worker_loop({Time,
                 %%receive
                     %%clock_tick ->
                         %%erlang:send_after(Time, self(), ?clock_tick),
                         %%case [begin Pid ! ?CLOCK_TICK_MSG, Pid end || Pid <- Pids] of
                             %%[] ->
                                 %%ets:delete(?MODULE, Time),
                                 %%erlang:exit(normal);
                             %%Pids ->
                                 %%Pids
                         %%end;
                     %%{register, Pid} ->
                         %%case lists:member(Pid, Pids) of
                             %%false ->
                                 %%[Pid | Pids];
                             %%true ->
                                 %%?ERROR_LOG("pid ~p already register clock", [Pid]),
                                 %%Pids
                         %%end;
                     %%{unregister, Pid} ->
                         %%lists:delete(Pid, Pids);
                     %%_Msg ->
                         %%?ERROR_LOG("unknow msg~p", [_Msg]),
                         %%Pids
                 %%end}).
