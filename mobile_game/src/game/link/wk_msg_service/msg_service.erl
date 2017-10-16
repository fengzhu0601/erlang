%%%-------------------------------------------------------------------
%%% @author hank
%%% @copyright (C) 2016, <SANTI>
%%% @doc  消息发送模块，在线直接转发, 处理不在线的保存数据，上线时处理
%%%
%%% @end
%%% Created : 31. Mar 2016 10:25 AM
%%%-------------------------------------------------------------------
-module(msg_service).
-author("hank").

-include("inc.hrl").
-include("rank.hrl").
-include_lib("pangzi/include/pangzi.hrl").

-include("msg_service.hrl").
-include("player.hrl").
-include("load_course.hrl").


-behaviour(gen_server).
-export
([
    start_link/0, init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3
]).

%% API
-export([
    send_msg/2,
    player_online/0,
    broadcast_chat/2,
    on_broadcast_tm/1
%%  get_offline_msgs/1,
%%  clear_offline_msgs/1
]).


% 角色登陆在线时调用
player_online() ->
    PlayerId = get(?pd_id),
    gen_server:cast(?MODULE, {send_player_msg, PlayerId}).
%%  lists:foreach
%%  (
%%    fun
%%      (Msg) ->
%%%%                ?INFO_LOG("send offline message ~p", [{Pid, Msg}]),
%%        Pid ! Msg,
%%        pop_last_msg(PlayerId)
%%    end,
%%    MsgList
%%  ),
%%  msg_service:clear_offline_msgs(PlayerId),
%%  ok.

send_msg(PlayerId, Msg) ->
    case world:get_player_pid(PlayerId) of
        ?none ->
            send_offline_msg(PlayerId, Msg);
        Pid ->
            Pid ! Msg
    end.

%%get_offline_msgs(PlayerId) ->
%%  lists:reverse(gen_server:call(?MODULE, {get_offline_msgs, PlayerId})).

%%clear_offline_msgs(PlayerId) ->
%%  gen_server:call(?MODULE, {clear_offline_msgs, PlayerId}).


% Internal method
send_offline_msg(PlayerId, Msg) -> % 添加用户 offline 调用 M,F 是用户进程的模块函数 A 是调用参数
    gen_server:call(?MODULE, {send_offline_msg, PlayerId, Msg}).

%%% 删除最后一个Msg
%%pop_last_msg(PlayerId) ->
%%  gen_server:call(?MODULE, {pop_last_msg, PlayerId}).

%% DB struct

load_db_table_meta() ->
    [
        #db_table_meta{name = ?offline_msg_tab,
            fields = ?record_fields(?offline_msg_tab),
            shrink_size = 1,
            flush_interval = 5}
    ].


-record(state, {}).

%%====================================================================
%% API
%%====================================================================
%%--------------------------------------------------------------------
%% Function: start_link() -> {ok,Pid} | ignore | {error,Error}
%% Description: Starts the server
%%--------------------------------------------------------------------
start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

%%====================================================================
%% gen_server callbacks
%%====================================================================

%%--------------------------------------------------------------------
%% Function: init(Args) -> {ok, State} |
%%                         {ok, State, Timeout} |
%%                         ignore               |
%%                         {stop, Reason}
%% Description: Initiates the server
%%--------------------------------------------------------------------
init([]) ->
    {ok, #state{}}.

%%--------------------------------------------------------------------
%% Function: %% handle_call(Request, From, State) -> {reply, Reply, State} |
%%                                      {reply, Reply, State, Timeout} |
%%                                      {noreply, State} |
%%                                      {noreply, State, Timeout} |
%%                                      {stop, Reason, Reply, State} |
%%                                      {stop, Reason, State}
%% Description: Handling call messages
%%--------------------------------------------------------------------

handle_call({get_offline_msgs, PlayerId}, _From, State) ->
    List = get(PlayerId, []),
    {reply, List, State, get_next_timeout()};

handle_call({clear_offline_msgs, PlayerId}, _From, State) ->
    set(PlayerId, []),
    {reply, ok, State, get_next_timeout()};

handle_call({pop_last_msg, PlayerId}, _From, State) ->
    OList = get(PlayerId, []),
    NList = lists:droplast(OList),
    set(PlayerId, NList),
    {reply, ok, State, get_next_timeout()};

handle_call({send_offline_msg, PlayerId, Msg}, _From, State) ->
    OList = get(PlayerId, []),
    NList = [Msg | OList],
    set(PlayerId, NList),
    {reply, ok, State, get_next_timeout()};

handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State, get_next_timeout()}.

%%--------------------------------------------------------------------
%% Function: handle_cast(Msg, State) -> {noreply, State} |
%%                                      {noreply, State, Timeout} |
%%                                      {stop, Reason, State}
%% Description: Handling cast messages
%%--------------------------------------------------------------------

handle_cast({send_player_msg, PlayerId}, State) ->
    OList = get(PlayerId, []),
    set(PlayerId, []),
    lists:foreach(fun(Msg) ->
        send_msg(PlayerId, Msg)
    end,
    OList),
    {noreply, State, get_next_timeout()};

handle_cast(_Msg, State) ->
    {noreply, State, get_next_timeout()}.

%%--------------------------------------------------------------------
%% Function: handle_info(Info, State) -> {noreply, State} |
%%                                       {noreply, State, Timeout} |
%%                                       {stop, Reason, State}
%% Description: Handling all non call/cast messages
%%--------------------------------------------------------------------
handle_info({broadcast, NoticeId, TimeRet}, State) ->
    case load_cfg_broadcast:get_calltime(NoticeId, 1) of
        nil -> pass;
        Dt ->
            case TimeRet - Dt >= 0 of
                true ->
                    timer_server:start(TimeRet - Dt, {?MODULE, on_broadcast_tm, [{NoticeId, TimeRet, 1, send}]});
                _ ->
                    timer_server:start(0, {?MODULE, on_broadcast_tm, [{NoticeId, TimeRet, 1, no_send}]})
            end
    end,
    {noreply, State, get_next_timeout()};


handle_info(timeout, State) ->
    %TimeAxle = timer_server:get_timeaxle(),
    timer_server:handle_min_timeout(),
    {noreply, State, get_next_timeout()};

handle_info(_Info, State) ->
    {noreply, State, get_next_timeout()}.

%%--------------------------------------------------------------------
%% Function: terminate(Reason, State) -> void()
%% Description: This function is called by a gen_server when it is about to
%% terminate. It should be the opposite of Module:init/1 and do any necessary
%% cleaning up. When it returns, the gen_server terminates with Reason.
%% The return value is ignored.
%%--------------------------------------------------------------------
terminate(_Reason, _State) ->
    ok.

%%--------------------------------------------------------------------
%% Func: code_change(OldVsn, State, Extra) -> {ok, NewState}
%% Description: Convert process state when code is changed
%%--------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%--------------------------------------------------------------------
%%% Internal functions
%%--------------------------------------------------------------------


get(Key, Def) ->
    case dbcache:load_data(?offline_msg_tab, Key) of
        [] -> 
            Def;
        [#offline_msg_tab{msg_list = Val}] ->
            case Val of
                undefined -> 
                    Def;
                [] -> 
                    Def;
                _ -> 
                    Val
            end
    end.

set(PlayerId, MsgList) ->
    dbcache:update(?offline_msg_tab, #offline_msg_tab{playerId = PlayerId, msg_list = MsgList}).


broadcast_chat(NoticeId, TimeRet) ->
    ?INFO_LOG("NoticeId: ~p", [NoticeId]),
    ?MODULE ! {broadcast, NoticeId, TimeRet}.


get_next_timeout() ->
    %TimeAxle = timer_server:get_timeaxle(),
    Dt = timer_server:get_next_timeout_dt(),
    Dt.


on_broadcast_tm({NoticeId, TimeRet,  Num, SendRet}) ->
%%    chat_mng:send_msg(PlayerList, Id, TmpList),
    case load_cfg_broadcast:get_calltime(NoticeId, Num+1) of
        nil -> pass;
        Dt ->
            case TimeRet - Dt >= 0 of
                true ->
                    case SendRet of
                        send ->
                            notice_system:send_broadcast(NoticeId, Dt);
                        _ ->
                            pass
                    end,
                    timer_server:start(TimeRet - Dt, {?MODULE, on_broadcast_tm, [{NoticeId, TimeRet, Num+1, send}]});
                _ ->
                    timer_server:start(0, {?MODULE, on_broadcast_tm, [{NoticeId, TimeRet, Num+1, no_send}]})
            end
    end.