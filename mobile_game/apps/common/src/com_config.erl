-module(com_config).
-behaviour(gen_server).

%% @doc 一个通用的配置server

-export([start/1,
         stop/0,
         get_config/1]).

%% gen_server callbacks
-export([init/1,
         handle_call/3,
         handle_cast/2,
         handle_info/2,
         terminate/2,
         code_change/3
        ]).

-record(state, {config}).
%% TODO 使用prolists

%% Module Interface   {{{--------------------------------------
%%--------------------------------------------------------------------
%% @doc Starts the server load config file, the config file must is a prolist
%% File is config file name
-spec start(string()) -> {ok, Pid::pid()} | {error, Error::any()}.
start(File) ->
    gen_server:start({local, ?MODULE}, ?MODULE, [File], []).

stop() ->
    gen_server:call(?MODULE, stop).

%% get value -> undefined | Value
get_config(Key) ->
    gen_server:call(?MODULE, {get, Key}).

%% get key value if key not undefined return DefaultValue
                                                %get_config2(Key, DefaultValue) ->
                                                %gen_server:call(?MODULE, {get2, Key, DefaultValue}).

%%=======================================================================
%% gen_server callbacks  {{{------------------------------------------

%%--------------------------------------------------------------------
%% @private
%% @doc  Initializes the server
%%
%%
%% @spec init(Args) -> {ok, State}          |
%%                     {ok, State, Timeout} |
%%                     {ok, State, hibernate} |
%%                     ignore               |
%%                     {stop, Reason}
%% @end
init([File]) ->
    {ok, [Cfg]} = file:consult(File),
    {ok, #state{config=Cfg}}.

%%--------------------------------------------------------------------
%% @private
%% @doc  Handling call messages
%%
%% @spec handle_call(Request, From, State) ->
%%                                   {reply, Reply, State} |
%%                                   {reply, Reply, State, Timeout} |
%%                                   {reply, Reply, State, hibernate} |
%%                                   {noreply, State} |
%%                                   {noreply, State, Timeout} |
%%                                   {noreply, State, hibernate} |
%%                                   {stop, Reason, Reply, State} |
%%                                   {stop, Reason, State}
%% @end
handle_call({get, Key}, _From, #state{config=Cfg} = State) ->
    %% TODO use prolists
    Value = case lists:keyfind(Key, 1, Cfg) of
                false ->
                    undefined;
                {Key, V} ->
                    V
            end,
    {reply, Value, State};

handle_call({get2, Key, DefaultValue}, _From, #state{config=Cfg} = State) ->
    %% TODO use prolists
    Value = case lists:keyfind(Key, 1, Cfg) of
                false ->
                    DefaultValue;
                {Key, V} ->
                    V
            end,
    {reply, Value, State};

handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc Handling cast messages
%%
%% @spec handle_cast(Msg, State) -> {noreply, State} |
%%                                  {noreply, State, Timeout} |
%%                                  {noreply, State, hibernate} |
%%                                  {stop, Reason, State}
%% @end
handle_cast(_Msg, State) ->
    {noreply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc  Handling all non call/cast messages
%%
%% @spec handle_info(Info, State) -> {noreply, State} |
%%                                   {noreply, State, Timeout} |
%%                                   {noreply, State, hibernate} |
%%                                   {stop, Reason, State}
%%                   Info = timeout | term()
%% @end
handle_info(_Info, State) ->
    {noreply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc terminate callback
%%
%% @spec terminate(Reason, State) -> no_return()
%%       Reason = normal | shutdown | {shutdown, term()} | term()
%% @end
terminate(_Reason, _State) ->
    ok.

%%--------------------------------------------------------------------
%% @private
%% @doc Convert process state when code is changed
%%
%% @spec code_change(OldVsn, State, Extra) -> {ok, NewState}
%% @end
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% gen_server callbacks end }}}-----------------------------------------


%%=======================================================================
%%--------------------------------------------------------------------
%% Internal functions
%%--------------------------------------------------------------------
%%
