%%% coding:utf-8
%%%-------------------------------------------------------------------
%%% @author zl
%%% @doc 进程相关的一些函数
%%%
%%% @end
%%%-------------------------------------------------------------------

-module(com_process).
-export([init_name/1
         ,init_type/1
         ,get_name/0
         ,get_type/0
         ,info/0
         ,show_info/0
         ,show_info/1
         ,crash_report/2
        ]).

-include("com_log.hrl").
-include("com_define.hrl").
-define(process_name, process_name).
-define(process_type, process_type).

%% @doc set a process human readable name.
init_name(Name) ->
    undefined =:= erlang:put(?process_name, Name).

%% @doc set a process type.
init_type(Type) ->
    undefined =:= erlang:put(?process_type, Type).

get_name() ->
    case erlang:get(?process_name) of
        undefined ->
            <<"undefined">>;
        Name ->
            Name
    end.

get_type() ->
    erlang:get(?process_type).

%% @doc 得到调用栈j

info() ->
    [
     erlang:process_info(self(), message_queue_len),
     erlang:process_info(self(), memory),
     erlang:process_info(self(), total_heap_size),
     erlang:process_info(self(), heap_size),
     erlang:process_info(self(), stack_size)
    ].

%% @doc process value gread than Maxvalue show it.
show_info() ->
    show_info("").
show_info(Str) ->
    Info=info(),
    ?INFO_LOG("~p process info: msg_queue_len:~p mem:~p(KB) total_heap_size:~p(KB)"
              "heap_size:~p(KB), stack_size:~p(KB)~n~ts",
              [
               get_name(),
               proplists:get_value(message_queue_len, Info),
               proplists:get_value(memory,Info) div 1024,
               proplists:get_value(total_heap_size,Info) div 1024,
               proplists:get_value(heap_size,Info) div 1024,
               proplists:get_value(stack_size,Info) div 1024,
               Str
              ]).


%% @doc proc_lib:crash_report
%% print OPT style crash report.
crash_report(exit, normal)       -> ok;
crash_report(exit, shutdown)     -> ok;
crash_report(exit, {shutdown,_}) -> ok;
crash_report(Class, Reason) ->
    OwnReport = my_info(Class, Reason),
    LinkReport = linked_info(self()),
    Rep = [OwnReport,LinkReport],
    error_logger:error_report(crash_report, Rep).

my_info(Class, Reason) ->
    [{pid, self()},
     get_process_info(self(), registered_name),         
     {error_info, {Class,Reason,erlang:get_stacktrace()}}, 
     get_process_info(self(), messages),
     get_process_info(self(), links),
     get_process_info(self(), dictionary),
     get_process_info(self(), trap_exit),
     get_process_info(self(), status),
     get_process_info(self(), heap_size),
     get_process_info(self(), stack_size),
     get_process_info(self(), reductions)
    ].



linked_info(Pid) ->
  make_neighbour_reports1(neighbours(Pid)).
  
make_neighbour_reports1([P|Ps]) ->
  ReportBody = make_neighbour_report(P),
  %%
  %%  Process P might have been deleted.
  %%
  case lists:member(undefined, ReportBody) of
    true ->
      make_neighbour_reports1(Ps);
    false ->
      [{neighbour, ReportBody}|make_neighbour_reports1(Ps)]
  end;
make_neighbour_reports1([]) ->
  [].
  
make_neighbour_report(Pid) ->
  [{pid, Pid},
   get_process_info(Pid, registered_name),          
   get_process_info(Pid, current_function),
   get_process_info(Pid, messages),
   get_process_info(Pid, links),
   get_process_info(Pid, trap_exit),
   get_process_info(Pid, status),
   get_process_info(Pid, heap_size),
   get_process_info(Pid, stack_size),
   get_process_info(Pid, reductions)
  ].


%%  neighbours(Pid) = list of Pids
%%
%%  Get the neighbours of Pid. A neighbour is a process which is 
%%  linked to Pid and does not trap exit; or a neigbour of a 
%%  neighbour etc.
%% 
%%  A breadth-first search is performed.

-spec neighbours(pid()) -> [pid()].

neighbours(Pid) ->
    {_, Visited} = visit(adjacents(Pid), {max_neighbours(), [Pid]}),
    lists:delete(Pid, Visited).

max_neighbours() -> 15.

%%
%% visit(Ps, {N, Vs}) = {N0, V0s}
%%
%% A breadth-first search of neighbours.
%%    Ps   processes,
%%    Vs   visited processes,
%%    N    max number to visit.
%%   
visit([P|Ps], {N, Vs} = NVs) when N > 0 ->
  case lists:member(P, Vs) of
    false -> visit(adjacents(P), visit(Ps, {N-1, [P|Vs]}));
    true  -> visit(Ps, NVs)
  end;
visit(_, {_N, _Vs} = NVs) ->
  NVs.

%%
%% adjacents(Pid) = AdjacencyList
%% 
-spec adjacents(pid()) -> [pid()].

adjacents(Pid) ->
  case catch proc_info(Pid, links) of
    {links, Links} -> no_trap(Links);
    _              -> []
  end.
  
no_trap([P|Ps]) ->
  case catch proc_info(P, trap_exit) of
    {trap_exit, false} -> [P|no_trap(Ps)];
    _                  -> no_trap(Ps)
  end;
no_trap([]) ->
  [].
 
get_process_info(Pid, Tag) ->
 translate_process_info(Tag, catch proc_info(Pid, Tag)).

translate_process_info(registered_name, []) ->
  {registered_name, []};
translate_process_info(_ , {'EXIT', _}) ->
  undefined;
translate_process_info(_, Result) ->
  Result.


proc_info(Pid,Item) when node(Pid) =:= node() ->
    process_info(Pid,Item);
proc_info(Pid,Item) ->
    case lists:member(node(Pid),nodes()) of
	true ->
	    check(rpc:call(node(Pid), erlang, process_info, [Pid, Item]));
	_ ->
	    hidden
    end.


check({badrpc,nodedown}) -> undefined;
check({badrpc,Error})    -> Error;
check(Res)               -> Res.
