%%% coding:utf-8
%%%-------------------------------------------------------------------
%%% @author zlb
%%% @doc 卡牌大师服务
%%%
%%% @end
%%%-------------------------------------------------------------------

-module(card_svr).
-behaviour(gen_server).


%-include_lib("pangzi/include/pangzi.hrl").


-include("inc.hrl").
-include("card.hrl").

-define(LOOKUP_SIZE, 6).
-define(MAX_SIZE, 60).


-export([
    lookup_award_infos/0, lookup_award_infos/1
    , add_award_info/3
]
).
-export([start_link/0]).
-export([init/1,
    handle_call/3,
    handle_cast/2,
    handle_info/2,
    terminate/2,
    code_change/3
]
).

-record(state, {
    card_awards = []
}
).

%% 查询奖励公告
lookup_award_infos(Page) ->
    gen_server:call(?MODULE, {lookup_award_infos, Page}).

%% 查询奖励公告
lookup_award_infos() ->
    gen_server:call(?MODULE, lookup_award_infos).

%% 添加奖励公告
add_award_info(Id, Name, Awards) ->
    ?MODULE ! {add_award_info, Id, Name, Awards}.

%%--------------------------------------------------------------------
%% @doc Starts the server
%% @spec start_link() -> {ok, Pid} | ignore | {error, Error}
%% @end
start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Initializes the server
%%
%% @spec init(Args) -> {ok, State} |
%%                     {ok, State, Timeout} |
%%                     ignore |
%%                     {stop, Reason}
%% @end
%%--------------------------------------------------------------------
-spec(init(Args :: term()) ->
    {ok, State :: #state{}} | {ok, State :: #state{}, timeout() | hibernate} |
    {stop, Reason :: term()} | ignore).
init([]) ->
    {ok, #state{}}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling call messages
%%
%% @end
%%--------------------------------------------------------------------
-spec(handle_call(Request :: term(), From :: {pid(), Tag :: term()},
    State :: #state{}) ->
    {reply, Reply :: term(), NewState :: #state{}} |
    {reply, Reply :: term(), NewState :: #state{}, timeout() | hibernate} |
    {noreply, NewState :: #state{}} |
    {noreply, NewState :: #state{}, timeout() | hibernate} |
    {stop, Reason :: term(), Reply :: term(), NewState :: #state{}} |
    {stop, Reason :: term(), NewState :: #state{}}).

handle_call({lookup_award_infos, Page}, _From, State) ->
    {NPage, MaxPage, PageL} = com_util:page(max(1, Page), ?LOOKUP_SIZE, State#state.card_awards),
    {reply, {NPage, MaxPage, PageL}, State};
handle_call(lookup_award_infos, _From, State) ->
    {reply, State#state.card_awards, State};

handle_call(_Request, _From, State) ->
    ?ERROR_LOG("no known request Mod:~w Req:~w", [?MODULE, _Request]),
    {reply, ok, State}.



%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling cast messages
%%
%% @end
%%--------------------------------------------------------------------
-spec(handle_cast(Request :: term(), State :: #state{}) ->
    {noreply, NewState :: #state{}} |
    {noreply, NewState :: #state{}, timeout() | hibernate} |
    {stop, Reason :: term(), NewState :: #state{}}).
handle_cast(_Request, State) ->
    ?ERROR_LOG("no known request Mod:~w Req:~w", [?MODULE, _Request]),
    {noreply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling all non call/cast messages
%%
%% @spec handle_info(Info, State) -> {noreply, State} |
%%                                   {noreply, State, Timeout} |
%%                                   {stop, Reason, State}
%% @end
%%--------------------------------------------------------------------
-spec(handle_info(Info :: timeout | term(), State :: #state{}) ->
    {noreply, NewState :: #state{}} |
    {noreply, NewState :: #state{}, timeout() | hibernate} |
    {stop, Reason :: term(), NewState :: #state{}}).


handle_info({add_award_info, Id, Name, Awards}, State = #state{card_awards = AL}) ->
    Now = com_time:timestamp_sec(),
    NAL = lists:sublist([{Now, Id, Name, Awards} | AL], ?MAX_SIZE),
    {noreply, State#state{card_awards = NAL}};

handle_info(_Info, State) ->
    ?ERROR_LOG("no known msg Mod:~w Msg:~w", [?MODULE, _Info]),
    {noreply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% This function is called by a gen_server when it is about to
%% terminate. It should be the opposite of Module:init/1 and do any
%% necessary cleaning up. When it returns, the gen_server terminates
%% with Reason. The return value is ignored.
%%
%% @spec terminate(Reason, State) -> void()
%% @end
%%--------------------------------------------------------------------
-spec(terminate(Reason :: (normal | shutdown | {shutdown, term()} | term()),
    State :: #state{}) -> term()).
terminate(_Reason, _State) ->
    ok.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Convert process state when code is changed
%%
%% @spec code_change(OldVsn, State, Extra) -> {ok, NewState}
%% @end
%%--------------------------------------------------------------------
-spec(code_change(OldVsn :: term() | {down, term()}, State :: #state{},
    Extra :: term()) ->
    {ok, NewState :: #state{}} | {error, Reason :: term()}).
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.
