%%% @doc pg2 like process group
%%% 每个group 一个process 只能注册一次
%%% 一个process 可以注册多个group
%%%
-module(com_prog).
-behaviour(gen_server).

-include("com_log.hrl").
-include("com_define.hrl").
-include("eunit_ext.hrl").
-include_lib("stdlib/include/ms_transform.hrl").

%% API
-export([is_member/2]).
-export([get_member/2, del_member/2]).
-export([get_members/1]).
-export([which_groups/0]).
-export([start_link/0]).
-export([is_exist_group/1]).
-export([create/1, delete/1, join_sync/2, leave_sync/1, foreach/2]).
-export([join_sync/3, leave_sync/2, sync_node_pids/1]).
-export([monitor_center_svr_info/1]).

%% gen_server callbacks
-export([init/1,handle_call/3,handle_cast/2,handle_info/2,terminate/2,code_change/3]).


-define(TAB, ?MODULE). %% {group, Name}

%% @doc Starts the server
start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).


%%=======================================================================
%% Internal functions
%%=======================================================================
sync_node_pids(GameNodePid) ->
    ?MODULE ! {sync_gamenode, GameNodePid}.


-type name() :: atom().

-compile({inline, [is_exist_group/1]}).
-spec is_exist_group(Name :: name()) -> boolean().
is_exist_group(Name) ->
    ets:member(?TAB, Name).

-spec create(Name :: name()) -> 'ok'.
create(Name) ->
    case is_exist_group(Name) of
        false ->
            gen_server:call(?MODULE, {create, Name}),
            ok;
        true ->
            ok
    end.

-spec delete(Name :: name()) -> 'ok'.

delete(Name) ->
    case is_exist_group(Name) of
        false ->
            ?WARN_LOG("~p group not exist",[Name]),
            ok;
        true ->
            gen_server:call(?MODULE, {delete, Name}),
            ok
    end.

%% @doc join_sync self to group
%% one key just can join once.
-spec join_sync(Name, Key :: term()) -> 'ok' | {'error', {'no_such_group', Name}}
                                            when Name :: name().

join_sync(Name, Key) ->
    case is_exist_group(Name) of
        false ->
            {error, {no_such_group, Name}};
        true ->
            gen_server:call(?MODULE, {join, Name, Key, erlang:self()})
    end.

join_sync(Name, Key, Pid) ->
    case is_exist_group(Name) of
        false ->
            {error, {no_such_group, Name}};
        true ->
            gen_server:call(?MODULE, {join, Name, Key, Pid})
    end.


-spec leave_sync(Name) -> 'ok' | {'error', {'no_such_group', Name}}
                              when Name :: name().

leave_sync(Name) ->
    case is_exist_group(Name) of
        false ->
            {error, {no_such_group, Name}};
        true ->
            gen_server:call(?MODULE, {leave, Name, erlang:self()})
    end.
leave_sync(Name, Pid) ->
    case is_exist_group(Name) of
        false ->
            {error, {no_such_group, Name}};
        true ->
            gen_server:call(?MODULE, {leave, Name, Pid})
    end.

monitor_center_svr_info(List) ->
    gen_server:cast(?MODULE, {monitor_center_svr_info, List}).

-spec is_member(name(), term()) -> boolean().
is_member(Group, Key) ->
    case is_exist_group(Group) of
        false ->
            ?false;
        true ->
            ets:member(Group, Key)
    end.

-compile({inline, [get_member/2]}).
-spec get_member(term(), term()) -> pid() | none.
get_member(Name, Key) ->
    case ets:lookup(Name, Key) of
        [] -> none;
        [{_, Pid}] -> Pid

    end.

del_member( Name, Key ) ->
    case ets:delete(Name, Key) of
        [] -> none;
        [{_, Pid}] -> Pid
    end.

-spec get_members(Name) -> [{Key::term(), pid()}] | {'error', {'no_such_group', Name}}
                               when Name :: name().

get_members(Name) ->
    case is_exist_group(Name) of
        ?true ->
            ets:tab2list(Name);
        ?false ->
            {error, {no_such_group, Name}}
    end.

-compile({inline, [which_groups/0]}).
-spec which_groups() -> [Name :: name()].
which_groups() ->
    [N || [N] <- ets:select(com_prog, [{{'$1',group},[],[['$1']]}])].
%%%
%%% Callback functions from gen_server
%%%

%% pd echo group  :: gb_tree({Pid, {Key, Ref}})
-define(pd_group(Name), {pd_group, Name}).

init([]) ->
    com_process:init_name(<<"com_prog">>),
    com_process:init_type(?MODULE),
    ?TAB = ets:new(?TAB, [?protected, ?named_table]),
    ?INFO_LOG("~p Staring.. ", [?pname()]),
    {ok, <<"com_prog">>}.

handle_call({create, Name}, _From, S) ->
    case ets:member(?TAB, Name) of
        ?true ->
            ?WARN_LOG("alread create ~p grep", [Name]);
        ?false ->
            true = ets:insert_new(?TAB, {Name, group}),
            Name = ets:new(Name, [?protected, ?named_table, {?read_concurrency, ?true}]),
            pd_gb_tree:new(?pd_group(Name)),
            ?INFO_LOG("~p create ~p process group", [?pname(), Name])
    end,
    {reply, ok, S};

handle_call({join, Name, Key, Pid}, _From, S) ->
    ets:member(?TAB, Name) andalso join_group(Name, Key, Pid),
    {reply, ok, S};
handle_call({leave, Name, Pid}, _From, S) ->
    ets:member(?TAB, Name) andalso leave_group(Name, Pid),
    {reply, ok, S};
handle_call({delete, Name}, _From, S) ->
    ets:member(?TAB, Name) andalso delete_group(Name),
    {reply, ok, S};
handle_call(Msg, _From, S) ->
    ?ERROR_LOG("~p recv unknown msg ~p", [?pname(), Msg]),
    {noreply, S}.

handle_cast({monitor_center_svr_info, List}, S) ->
    lists:foreach(
        fun(Info) ->
                _Ref = erlang:monitor(process, Info)
        end,
        List
    ),
    {noreply, S};
handle_cast(_Msg, S) ->
    ?ERROR_LOG("~p recv unknown msg ~p", [?pname(), _Msg]),
    {noreply, S}.

handle_info({sync_gamenode, GameNodePid}, S) ->
    GroupList = ets:tab2list(com_prog),
    GroupList1 = [GroupName || {GroupName, _} <- GroupList],
    GpPids = lists:foldl(
        fun(GpName, Acc) ->
                PidList = ets:tab2list(GpName),
                [{GpName, PidList} | Acc]
        end,
        [],
        GroupList1
    ),
    center_node_link:sync_group_pid(GameNodePid, GpPids),
    {noreply, S};
handle_info({'DOWN', _MonitorRef, process, Pid, _Info}, S) ->
    case Pid of
        {team_server, _} ->
            my_ets:set(center_svr_node_info, {0, false});
        {arena_server, _} ->
            my_ets:set(center_svr_node_info, {0, false});
        _ ->
            [member_died(Group, Pid) || Group <- which_groups()]
    end,
    {noreply, S};
handle_info(_, S) ->
    {noreply, S}.


code_change(_OldVsn, State, _Extra) ->
    {ok, State}.
terminate(Reason, _S) ->
    true = ets:delete(?TAB),
    ?if_else(
        Reason =:= ?normal orelse Reason  =:= ?shutdown,
        ?INFO_LOG("~p Terminate with ~p", [?pname(), Reason]),
        ?ERROR_LOG("~p Creash with ~p", [?pname(), Reason])
    ),
    ok.


delete_group(Name) ->
    true = ets:delete(?TAB, Name),
    ets:delete(Name),
    [erlang:demonitor(Ref, [flush]) || {_Pid, {_Key, Ref}} <-  gb_trees:to_list(pd_gb_tree:delete(?pd_group(Name)))],
    ?INFO_LOG("~p delete ~p process group", [?pname(), Name]),
    ok.

%% {refId, Name, Key, Pid}
member_died(Group, Pid) ->
    case pd_gb_tree:value(?pd_group(Group), Pid) of
        ?none -> ok;
        {Key, _Ref} ->
            % ?DEBUG_LOG("member_dies~p key:~p",[Pid, Key]),
            pd_gb_tree:delete(?pd_group(Group), Pid),
            ets:delete(Group, Key)
    end,
    ok.


join_group(Name, Key, Pid) ->
    case pd_gb_tree:is_key(?pd_group(Name), Pid) of
        ?false ->
            Ref = erlang:monitor(process, Pid),
            pd_gb_tree:insert(?pd_group(Name), Pid, {Key, Ref}),
            case ets:insert_new(Name, {Key, Pid}) of
                true ->
                    ok;
                false ->
                    ?ERROR_LOG("Process ~p alreadly join group ~p",[Pid, Name])
            end;
        ?true ->
            pass
    end.

leave_group(Name, Pid) ->
    case pd_gb_tree:value(?pd_group(Name), Pid) of
        ?none ->
            % ?ERROR_LOG("grop ~p can not find ~p", [Name, Pid]);
            pass;
        {Key, Ref} ->
            true = erlang:demonitor(Ref, [flush]),
            pd_gb_tree:delete(?pd_group(Name), Pid),
            ets:delete(Name, Key)
    end.


foreach(Fun, Name) ->
    com_ets:foreach(Fun, Name).