%%%-------------------------------------------------------------------
%%% @author hank
%%% @copyright (C) 2016, <SANTI>
%%% @doc  处理延迟支付调用
%%%
%%% @end
%%% Created : 23. Apr 2016 3:48 PM
%%%-------------------------------------------------------------------
-module(payment_confirm).
-author("hank").

%% API
-include("inc.hrl").
-include("rank.hrl").
-include_lib("pangzi/include/pangzi.hrl").

-include("player.hrl").
-include("payment.hrl").
-include("load_course.hrl").


-behaviour(gen_server).
-export([start_link/0, init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

%% API
-export([
    send_payment_confirm/2
]).


%  method
send_payment_confirm(PlayerId, Data) -> % 添加用户 offline 调用 M,F 是用户进程的模块函数 A 是调用参数
    gen_server:call(?MODULE, {send_payment_confirm, PlayerId, Data}).

%% DB struct

-record(payment_confirm_tab, {
    playerId,
    confirm_list = [] % [{mod,Module,From_Module,{Function, Argument}} | ... ].
}).

-define(PAYMENT_TIMEOUT_INVOKE, 20000). % 20 sec

load_db_table_meta() ->
    [
        #db_table_meta{name = payment_confirm_tab,
            fields = ?record_fields(payment_confirm_tab),
            shrink_size = 1,
            flush_interval = 0}
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
    erlang:send_after(?PAYMENT_TIMEOUT_INVOKE, self(), loop_interval_event),
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
%
handle_call({send_payment_confirm, PlayerId, Data}, _From, State) ->
    OList = get_payment_confirm(PlayerId, []),
    NList = [Data | OList],
    set_payment_confirm(PlayerId, NList),
    {reply, NList, State};

handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.

%%--------------------------------------------------------------------
%% Function: handle_cast(Msg, State) -> {noreply, State} |
%%                                      {noreply, State, Timeout} |
%%                                      {stop, Reason, State}
%% Description: Handling cast messages
%%--------------------------------------------------------------------

handle_cast(_Msg, State) ->
    {noreply, State}.

%%--------------------------------------------------------------------
%% Function: handle_info(Info, State) -> {noreply, State} |
%%                                       {noreply, State, Timeout} |
%%                                       {stop, Reason, State}
%% Description: Handling all non call/cast messages
%%--------------------------------------------------------------------
handle_info(loop_interval_event, State) ->
    do_loop_interval_event(),
    erlang:send_after(?PAYMENT_TIMEOUT_INVOKE, self(), loop_interval_event),
    {noreply, State};

handle_info(_Info, State) ->
    {noreply, State}.

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

do_loop_interval_event() ->
    AllList = get_all_data(),
    lists:foreach(fun(#payment_confirm_tab{playerId = PlayerId, confirm_list = MyList}) ->
            lists:foreach(fun({Billno, PayNum, Appid, AppKey, Token, PayToken,Openid, Pf, PfKey, Zoneid,AccountType, InvokeTime}) ->
                    {Payret, Paycode, Paymsg} = payment_system:check_qq_pay(Billno, PayNum, Appid, AppKey, Token, PayToken,Openid, Pf, PfKey, Zoneid,AccountType),
                    if
                        Payret =:= 0 ->
                            del_payment_confirm(PlayerId, Billno),
                            [Payment] = payment_system:lookup_payment(Billno),
                            NPayment = Payment#payment_tab{pay_ret = Payret,pay_code = Paycode, pay_msg = Paymsg, status = Payret},
                            Index = Payment#payment_tab.refId,
                            payment_system:update_payment(NPayment),
                            msg_service:send_msg(PlayerId, ?mod_msg(player_mng, {update_order, {Billno, Index, ?PAYMENT_ORDER_STATE_SUCCESS}})),
                            ok;
                        true ->
                            if
                                InvokeTime =< 0 ->
                                    del_payment_confirm(PlayerId, Billno),
                                    [Payment] = payment_system:lookup_payment(Billno),
                                    NPayment = Payment#payment_tab{pay_ret = Payret,pay_code = Paycode, pay_msg = Paymsg, status = Payret},
                                    Index = Payment#payment_tab.refId,
                                    payment_system:update_payment(NPayment),
                                    msg_service:send_msg(PlayerId, ?mod_msg(player_mng, {update_order, {Billno, Index, ?PAYMENT_ORDER_STATE_EXCEPTION}}));
                                true ->
                                    update_payment_confirm(PlayerId, Billno,{Billno, PayNum, Appid, AppKey, Token, PayToken,Openid, Pf, PfKey, Zoneid,AccountType, InvokeTime - 1})
                            end,

                            ok
                    end,
                    ok
                end,
                MyList),
            ok
        end,
        AllList
    ).


get_all_data() ->
    mnesia:dirty_select(payment_confirm_tab, [{'$1', [], ['$1']}]).

update_payment_confirm(PlayerId, Billno, Data) ->
    case dbcache:load_data(payment_confirm_tab, PlayerId) of
        [] -> 
            ok;
        [#payment_confirm_tab{confirm_list = MyList}] ->
            NMyList = lists:keyreplace(Billno, 1, MyList, Data),
            dbcache:update(payment_confirm_tab,#payment_confirm_tab{playerId = PlayerId, confirm_list = NMyList})
    end,
    ok.

del_payment_confirm(PlayerId, Billno) ->
    case dbcache:load_data(payment_confirm_tab, PlayerId) of
        [] -> 
            ok;
        [#payment_confirm_tab{confirm_list = MyList}] ->
            NMyList = lists:keydelete(Billno, 1, MyList),
            dbcache:update(payment_confirm_tab, #payment_confirm_tab{playerId = PlayerId, confirm_list = NMyList})
    end,
    ok.


get_payment_confirm(Key, Def) ->
    case dbcache:load_data(payment_confirm_tab, Key) of
        [] -> Def;
        [#payment_confirm_tab{confirm_list = Val}] ->
            case Val of
                undefined -> Def;
                [] -> Def;
                _ -> Val
            end
    end.

set_payment_confirm(PlayerId, MsgList) ->
    dbcache:update(payment_confirm_tab, #payment_confirm_tab{playerId = PlayerId, confirm_list = MsgList}).



