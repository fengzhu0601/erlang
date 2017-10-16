%%% @author zl
%%% @doc 一个托管ets 的进程
%%%
%%% @end
%%%-------------------------------------------------------------------

-module(safe_ets).
-behaviour(gen_server).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-export([start_link/0]).

-define(no_safe_ets_behavior, 1).
-include("safe_ets.hrl").

-include_lib("common/include/com_log.hrl").
-include_lib("common/include/com_define.hrl").

%% @doc config_lib behaviour 需要实现的就口，返会config_meta
-callback create_safe_ets() -> [{Name :: atom(), Opt :: list()}].

%%API
-export([new/2,
    new/3
]).
new(Name, Opt) ->
    {Name, Opt}.

new(Name, Opt, InitFn)
    when is_function(InitFn, 0) ->
    {Name, Opt, InitFn}.


%% @doc Starts the server
start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).


init([]) ->
    com_process:init_name(<<"safe_ets">>),
    com_process:init_type(?MODULE),
    Modules =
        com_module:get_all_behaviour_mod("./ebin", ?safe_ets_behavior),
    %?DEBUG_LOG("config modules ~p ", [Modules]),

    EtsList = load_ets(Modules),
    ?INFO_LOG("~p process started", [?pname()]),
    create_ets(EtsList),
    gen_id:init(),
    load_task_progress:init_task_remap(),
    load_simple_task:init_simple_task_remap(),
    load_task_open_fun:init_open_task_ets(),
    {ok, <<"safe_ets">>}.


load_ets(Modules) ->
    lists:foldl(fun(Mod, T) ->
        Mod:create_safe_ets() ++ T
    end,
        [],
        Modules).


create_ets(EtsList) ->
    lists:foreach(fun({Name, Opt}) ->
        Name = ets:new(Name, Opt);
        ({Name, Opt, InitFn}) ->
            Name = ets:new(Name, Opt),
            InitFn()
    end,
        EtsList).

handle_call(_Request, _From, State) ->
    ?ERROR_LOG("unknown msg ~p", [_Request]),
    {reply, ok, State}.

handle_cast(_Msg, State) ->
    ?ERROR_LOG("unknown msg ~p", [_Msg]),
    {noreply, State}.

handle_info(_Msg, State) ->
    ?ERROR_LOG("unknown msg ~p", [_Msg]),
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.



%%=======================================================================
%% Internal functions
%%=======================================================================
%%is_exist_ets(Name) ->
%%lists:member(Name, ets:all()).
