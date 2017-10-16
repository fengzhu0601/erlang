%%% coding:utf-8
%%%-------------------------------------------------------------------
%%% @author zlb
%%% @doc 好友礼包公共进程
%%%
%%% @end
%%%-------------------------------------------------------------------


-module(friend_gift_svr).
-behaviour(gen_server).

-include_lib("pangzi/include/pangzi.hrl").

-include("inc.hrl").
-include("friend.hrl").
-include("friend_struct.hrl").

-export([start_link/0]).
-export
([
    init/1,
    handle_call/3,
    handle_cast/2,
    handle_info/2,
    terminate/2,
    code_change/3
]).

-export
([
    apply_add_friend/2, rep_apply_add_friend/2
    , rob_gift/3
    , ask_for_gift_apply/2, rep_ask_for_gift_apply/3
    , send_gift_apply/2, rep_send_gift_apply/2
    , set_rob_stat/2
    , zore_reset/0
    , update_gift_quality/3, update_gift_quantity/3
    , init_friend_gifts/1
    ,init_friend_gifts/4
    , del_friend/2
    , get_rand_mean_list/2
]).

-record(state, {
}).

%% 初始化好友礼物
init_friend_gifts(FC = #friend_common{gift_qua = GiftQua}) ->
    #{gift_qua := GiftQuas, send_gift_max := SMax} = misc_cfg:get_friend_cfg(),

    {_, PrizeTps} = lists:keyfind(GiftQua, 1, GiftQuas),
    STypes = init_friend_gifts(PrizeTps, SMax, SMax, []),
    FC#friend_common{send_gift_type = STypes}.

init_friend_gifts(_PrizeTps, 0, 0,_Ret) ->
    [];
init_friend_gifts(PrizeTps, 1, _SMax, Ret) ->
    NewPrizeTps =
        lists:foldl(
            fun({Atom,Val},Acc) ->
                [{Atom, max(1,Val)} | Acc]
            end,
            [],
            PrizeTps
        ),
    [NewPrizeTps | Ret];
init_friend_gifts(PrizeTps, NSMax, SMax, Ret) ->
    {Tps, NPrizeTps} =
    lists:foldl(fun({Atom, Val}, {TmpTps, TmpPrizeTps}) ->
            %% 仿微信红包
            SubVal = com_util:random(1, Val div NSMax * 2),
            NVal = Val - SubVal,
            NTmpPrizeTps = lists:keyreplace(Atom, 1, TmpPrizeTps, {Atom, NVal}),
            {[{Atom, SubVal} | TmpTps], NTmpPrizeTps}
        end,
    {[], PrizeTps},
    PrizeTps),
    init_friend_gifts(NPrizeTps, NSMax - 1, SMax, [Tps | Ret]).


update_gift_qua(_OQua, FC = #friend_common{send_gift_type = []}) -> FC;
update_gift_qua(OQua, FC = #friend_common{gift_qua = NQua, send_gift_type = STypes}) ->
    #{gift_qua := GiftQuas} = misc_cfg:get_friend_cfg(),
    STypesLen = length(STypes),
    {_, OPrizeTps} = lists:keyfind(OQua, 1, GiftQuas),
    {_, NPrizeTps} = lists:keyfind(NQua, 1, GiftQuas),
    STypesTmp = lists:append(STypes),
    PrizeTpsRate = lists:foldl(fun({Atom, Val}, AccIn) ->
        AddVal = com_lists:keyfind_all_and_sum(Atom, 1, 2, STypesTmp),
        [{Atom, AddVal, Val} | AccIn]
    end, [], OPrizeTps),
    NPrizeTps1 = lists:foldl(fun({Atom, Val}, AccIn) ->
        case lists:keyfind(Atom, 1, PrizeTpsRate) of
            {_, CVal, MVal} ->
                [{Atom, Val * CVal div MVal} | AccIn];
            _ ->
                AccIn
        end
    end, [], NPrizeTps),
    NSTypes = init_friend_gifts(NPrizeTps1, STypesLen, STypesLen, []),
    ?debug_log_friend("STypes ~w----PrizeTpsRate ~w ------------NSTypes ~w ------NPrizeTps ~w", [STypes, PrizeTpsRate, NSTypes, NPrizeTps]),
    FC#friend_common{send_gift_type = NSTypes}.




%% 申请添加好友
%% @spec apply_add_friend(MyId, ApplyedId) -> {ok, DelIdsTp} | {error, Reason}
apply_add_friend(MyId, ApplyedId) ->
    gen_server:call(?MODULE, {apply_add_friend, MyId, ApplyedId}).

%% 回复申请添加好友
%% @spec rep_apply_add_friend(MyId, ApplyId) -> ok | {error, Reason}
rep_apply_add_friend(MyId, ApplyId) ->
    gen_server:call(?MODULE, {rep_apply_add_friend, MyId, ApplyId}).

%% @spec rob_gift(SourId, DestId, GiftQua) ->  {ok, PrizeId} | {error, Reason}
rob_gift(SourId, DestId, GiftQua) ->  %%  抢红包
    gen_server:call(?MODULE, {rob_gift, SourId, DestId, GiftQua}).


%% @spec ask_for_gift_apply(MyId, ApplyedId) ->  {ok, DelIdsTp} | {error, Reason}
ask_for_gift_apply(MyId, ApplyedId) ->    %% 索取红包
    gen_server:call(?MODULE, {ask_for_gift_apply, MyId, ApplyedId}).

%% @spec rep_ask_for_gift_apply(MyId, ApplyId, IsAgree) ->  {ok, PrizeId, GiftQua} | {error, Reason}
rep_ask_for_gift_apply(MyId, ApplyId, IsAgree) ->    %% 回复索取红包
    gen_server:call(?MODULE, {rep_ask_for_gift_apply, MyId, ApplyId, IsAgree}).

%% @spec send_gift_apply(MyId, RecvId) ->  {ok, GiftQua} | {error, Reason}
send_gift_apply(MyId, RecvId) ->    %% 赠送礼包
    gen_server:call(?MODULE, {send_gift_apply, MyId, RecvId}).


%% @spec rep_send_gift_apply(MyId, SendId) ->  {ok, ItemTpL} | {error, Reason}
rep_send_gift_apply(MyId, SendId) ->    %% 回复赠送礼包
    gen_server:call(?MODULE, {rep_send_gift_apply, MyId, SendId}).

%% @spec set_rob_stat(PlayerId, Stat) -> ok
set_rob_stat(PlayerId, Stat) ->  % 修改被抢红包状态
    ?MODULE ! {set_rob_stat, PlayerId, Stat}, ok.

%% @spec del_friend(SelfId, PlayerId) -> ok
del_friend(SelfId, PlayerId) ->  % 删除好友
    ?MODULE ! {del_friend, SelfId, PlayerId}, ok.
%%  更新好友礼包品质
update_gift_quality(Id, Qua, NQua) ->
    case gen_server:call(?MODULE, {update_gift_quality, Id, Qua, NQua}) of
        ok ->
            friend_mng:send_my_info(),
            ok;
        {error, Reason} -> {error, Reason}
    end.
%%  更新好友礼包数量 
update_gift_quantity(Id, Qua, Num) ->
    case gen_server:call(?MODULE, {update_gift_quantity, Id, Qua, Num}) of
        ok ->
            friend_mng:send_my_info(),
            ok;
        {error, Reason} -> {error, Reason}
    end.

zore_reset() ->  %% 每天晚上12点重置变量
    ?MODULE ! zore_reset.


%%----------------------------------------------------
load_db_table_meta() ->
    [
        #db_table_meta{
            name = ?player_friend_common
            , fields = record_info(fields, friend_common)
            , record_name = friend_common
            , load_all = true
            , shrink_size = 1
            , flush_interval = 3
        }
    ].

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
    M2 = com_time:get_seconds_to_next_day(),
    erlang:send_after(M2 * 1000, self(), zore_reset),
    {ok, #state{}}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling call messages
%%
%% @end
%%--------------------------------------------------------------------
-spec(handle_call(Request :: term(), From :: {pid(), Tag :: term()}, State :: #state{}) ->
    {reply, Reply :: term(), NewState :: #state{}} |
    {reply, Reply :: term(), NewState :: #state{}, timeout() | hibernate} |
    {noreply, NewState :: #state{}} |
    {noreply, NewState :: #state{}, timeout() | hibernate} |
    {stop, Reason :: term(), Reply :: term(), NewState :: #state{}} |
    {stop, Reason :: term(), NewState :: #state{}}).


handle_call({apply_add_friend, MyId, ApplyedId}, _From, State) -> %% 申请添加好友
    %% MyId的申请玩家好友Id列表
    MFC =
        #friend_common
        {
            send_friend_ids = MSFIdL
        } = friend_mng:lookup_fc(MyId),

    %% ApplyedId的接受到的申请好友ID列表
    FC =
        #friend_common
        {
            send_gift_applys = SGAL,
            req_gift_applys = RGAL ,
            recv_friend_applys = FAL
        } = friend_mng:lookup_fc(ApplyedId),
    ?debug_log_friend("SendId ~w, SendApplyL ~w, RecvId ~w, RecvApplyL ~w", [MyId, MSFIdL, ApplyedId, FAL]),
    IsApply = lists:member(MyId, FAL),
    MIsApply = lists:member(ApplyedId, MSFIdL),
    Reply = if
                IsApply -> {error, already_apply};
                MIsApply -> {error, already_apply};
                ?true ->
                    {NFC, DelIdsTp} = add_apply(FC, {SGAL, RGAL, [MyId | FAL]}),
                    update_fc(NFC),
                    update_fc(MFC#friend_common{send_friend_ids = [ApplyedId | MSFIdL]}),
                    {ok, DelIdsTp}
            end,
    {reply, Reply, State};

handle_call({rep_apply_add_friend, MyId, ApplyId}, _From, State) -> %% 回复添加好友
    FC = #friend_common{send_friend_ids = SFIdL, recv_friend_applys = FAL} = friend_mng:lookup_fc(MyId),
    AFC = #friend_common{send_friend_ids = ASFIdL, recv_friend_applys = AFAL} = friend_mng:lookup_fc(ApplyId),
    ?debug_log_friend("SendId ~w, SendApplyL ~w, RecvId ~w, RecvApplyL ~w", [ApplyId, SFIdL, MyId, FAL]),
    IsIn = lists:member(ApplyId, FAL),
    Reply = if
                not IsIn -> {error, apply_timeout};
                ?true ->
                    ok
            end,
    %% 彼此的都要删掉，不要残留
    NFAL = lists:delete(ApplyId, FAL),
    NSFIdL = lists:delete(ApplyId, SFIdL),
    NAFAL = lists:delete(MyId, AFAL),
    NASFIdL = lists:delete(MyId, ASFIdL),

    ?debug_log_friend("SendId ~w, SendApplyL ~w, RecvId ~w, RecvApplyL ~w", [ApplyId, NSFIdL, MyId, NFAL]),
    update_fc(AFC#friend_common{send_friend_ids = NASFIdL, recv_friend_applys = NAFAL}),
    update_fc(FC#friend_common{send_friend_ids = NSFIdL, recv_friend_applys = NFAL}),
    {reply, Reply, State};
handle_call({rob_gift, SourId, DestId, GiftQua}, _From, State) -> %% 发红包
    Ret = send_gift(SourId, DestId, GiftQua),
    {reply, Ret, State};

handle_call({update_gift_quality, Id, Qua, NQua}, _From, State) -> % 更新红包品质
    Ret = case friend_mng:lookup_fc(Id) of
              FC = #friend_common{gift_qua = Qua} ->
                  FC1 = FC#friend_common{gift_qua = NQua},
                  FC2 = update_gift_qua(Qua, FC1),
                  update_fc(FC2),
                  ok;
              _ ->
                  {error, gift_qua_not_match}
          end,
    {reply, Ret, State};
handle_call({update_gift_quantity, Id, Qua, Num}, _From, State) -> %% 更新红包数量
    Ret = case friend_mng:lookup_fc(Id) of
              FC = #friend_common{gift_qua = Qua} ->
                  #{send_gift_max:= SendMax
                  } = misc_cfg:get_friend_cfg(),
                  FC1 = init_friend_gifts(FC),
                  NNum = max(0, SendMax - Num),
                  update_fc(FC1#friend_common{send_count = NNum}),
                  ok;
              _ ->
                  {error, gift_qua_not_match}
          end,
    {reply, Ret, State};

handle_call({ask_for_gift_apply, MyId, AskedId}, _From, State) -> %%申请索取红包
    SFC = #friend_common{send_count = Send, send_player_ids = SendIds
        , send_gift_applys = SGAL, recv_friend_applys = FAL
        , req_gift_applys = RGAL, gift_qua = GiftQua
    } = friend_mng:lookup_fc(AskedId),

    MFC = #friend_common{recv_count = Recv, recv_player_ids = RecvIds
        , send_req_ids = SRIdL
    } = friend_mng:lookup_fc(MyId),

    #{send_gift_max:= SendMax, recv_gift_max:= RecvMax
    } = misc_cfg:get_friend_cfg(),

    IsSended = lists:member(MyId, SendIds),
    IsRecved = lists:member(AskedId, RecvIds),
    IsApplyed = lists:keymember(MyId, 1, RGAL),
    MIsApplyed = lists:member(AskedId, SRIdL),

    Ret = if
              Send >= SendMax -> {error, send_max};
              Recv >= RecvMax -> {error, recv_max};
              IsSended -> {error, already_get};
              IsRecved -> {error, already_get};
              IsApplyed -> {error, already_apply};
              MIsApplyed -> {error, already_apply};
              ?true ->
                  {NSFC, DelIdsTp} = add_apply(SFC, {SGAL, [{MyId, GiftQua} | RGAL], FAL}),
                  update_fc(NSFC),
                  update_fc(MFC#friend_common{send_req_ids = [AskedId | SRIdL]}),
                  {ok, DelIdsTp}
          end,
    {reply, Ret, State};

handle_call({rep_ask_for_gift_apply, MyId, ApplyId, IsAgree}, _From, State) -> %% 回复申请索取红包
    #friend_common{req_gift_applys = ReqGiftAL} = friend_mng:lookup_fc(MyId),
    %AF  #friend_common{send_req_ids= SRIdL} = friend_mng:lookup_fc(ApplyId),
    Ret = case lists:keyfind(ApplyId, 1, ReqGiftAL) of
              {_, GiftQua} when IsAgree =:= ?TRUE ->
                  case send_gift(MyId, ApplyId, GiftQua) of
                      {ok, PrizeItemTp} ->
                          %update_fc(AFC#friend_common{send_req_ids = lists:delete(MyId, SRIdL)}),
                          {ok, PrizeItemTp, GiftQua};
                      {error, Err} -> {error, Err}
                  end;
              {_, GiftQua} ->
                  %update_fc(AFC#friend_common{send_req_ids = lists:delete(MyId, SRIdL)}),
                  {ok, ?undefined, GiftQua};
              ?false ->
                  {error, apply_timeout}
          end,
    NReqGiftAL = lists:keydelete(ApplyId, 1, ReqGiftAL),
    SFC = friend_mng:lookup_fc(MyId),
    update_fc(SFC#friend_common{req_gift_applys = NReqGiftAL}),
    ASFC = #friend_common{send_req_ids = SRIdL} = friend_mng:lookup_fc(ApplyId),
    update_fc(ASFC#friend_common{send_req_ids = lists:delete(MyId, SRIdL)}),
    {reply, Ret, State};


handle_call({send_gift_apply, MyId, RecvId}, _From, State) -> %% 赠送红包申请
    #friend_common{
        send_gift_applys = SGAL, req_gift_applys = RGAL
        , recv_friend_applys = FAL} = friend_mng:lookup_fc(RecvId),
    #friend_common{gift_qua = GiftQua} = friend_mng:lookup_fc(MyId),
    IsSended = lists:keymember(MyId, 1, SGAL),
    Ret = if
              IsSended -> {error, already_get};
              ?true ->
                  case send_gift(MyId, RecvId, GiftQua) of
                      {ok, PrizeItemTp} ->
                          RFC = friend_mng:lookup_fc(RecvId),
                          {NRFC, DelIdsTp} = add_apply(RFC, {[{MyId, PrizeItemTp} | SGAL], RGAL, FAL}),
                          update_fc(NRFC),
                          world:send_to_player(RecvId, ?mod_msg(friend_mng, {send_gift_apply, MyId, PrizeItemTp, DelIdsTp})),
                          {ok, GiftQua};
                      {error, Err} -> {error, Err}
                  end
          end,
    {reply, Ret, State};


handle_call({rep_send_gift_apply, MyId, SendId}, _From, State) -> %% 接受赠送红包申请
    MFC = #friend_common{send_gift_applys = SendGiftAL} = friend_mng:lookup_fc(MyId),
    Ret = case lists:keyfind(SendId, 1, SendGiftAL) of
              {_, ItemTpL} ->
                  {ok, ItemTpL};
              _ ->
                  {error, apply_timeout}
          end,
    NSendGiftAL = lists:keydelete(SendId, 1, SendGiftAL),
    NMFC = MFC#friend_common{send_gift_applys = NSendGiftAL},
    update_fc(NMFC),
    {reply, Ret, State};

handle_call(_Request, _From, State) ->
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

handle_info({del_friend, SelfId, PlayerId}, State) -> %% 设置抢红包模式
    FC = #friend_common{send_player_ids = SFIL} = friend_mng:lookup_fc(SelfId),
    update_fc(FC#friend_common{send_player_ids = lists:delete(PlayerId, SFIL)}),
    PFC = #friend_common{recv_friend_applys = RFL} = friend_mng:lookup_fc(PlayerId),
    update_fc(PFC#friend_common{recv_friend_applys = lists:keydelete(SelfId, 1, RFL)}),
    {noreply, State};

handle_info({set_rob_stat, PlayerId, Stat}, State) -> %% 设置抢红包模式
    NStat = case Stat of
                ?TRUE -> ?TRUE;
                _ -> ?FALSE
            end,
    FC = friend_mng:lookup_fc(PlayerId),
    update_fc(FC#friend_common{open_rob = NStat}),
    world:send_to_player_if_online(PlayerId, ?mod_msg(friend_mng, {set_rob_stat, NStat})),
    {noreply, State};

handle_info(zore_reset, State) ->  %% 12点重置信息
    ?DEBUG_LOG("zore_reset------------------------"),
    L = ets:tab2list(?player_friend_common),
    lists:foreach(fun(FC = #friend_common{id = Id}) ->
        dbcache:update(?player_friend_common, reset_friend_common(FC)),
        world:send_to_player_if_online(Id, ?mod_msg(friend_mng, zore_reset))
    end, L),
    M2 = com_time:get_seconds_to_next_day(),
    erlang:send_after(M2 * 1000, self(), zore_reset),
    {noreply, State};

handle_info(_Info, State) ->
    ?ERROR_LOG("~w recv unknow msg ~w", [?MODULE, _Info]),
    {noreply, State}.

%% 每天晚上12点重置变量
reset_friend_common(#friend_common{id = Id, gift_qua = GiftQua, open_rob = ORobGift,send_gift_type = SendGiftType}) ->
    #friend_common{id = Id, gift_qua = GiftQua, open_rob = ORobGift, send_gift_type = SendGiftType}.
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




%%----------------------------------------------------
%% 私有方法
update_fc(FC) ->
    dbcache:update(?player_friend_common, FC).


add_apply(FC, ApplyTp = {SGAL, RGAL, FAL}) ->
    #{apply_max := ApplyMax} = misc_cfg:get_friend_cfg(),
    SGALen = length(SGAL),
    RGALen = length(RGAL),
    FALen = length(FAL),
    {{EndNSGAL, EndNRGAL, EndNFAL}, DelIdsTp} = if
                                                    ApplyMax =< SGALen ->
                                                        {NSGAL, DelSGAL} = lists:split(ApplyMax, SGAL),
                                                        DelSGAIdL = [Id || {Id, _} <- DelSGAL],
                                                        DelRGAIdL = [Id || {Id, _} <- RGAL],
                                                        {{NSGAL, [], []}, {DelSGAIdL, DelRGAIdL, FAL}};
                                                    ApplyMax =< SGALen + RGALen ->
                                                        {NRGAL, DelRGAL} = lists:split(ApplyMax - SGALen, RGAL),
                                                        DelRGAIdL = [Id || {Id, _} <- DelRGAL],
                                                        {{SGAL, NRGAL, []}, {[], DelRGAIdL, FAL}};
                                                    ApplyMax =< SGALen + RGALen + FALen ->
                                                        {NFAL, DelFAL} = lists:split(ApplyMax - SGALen - RGALen, FAL),
                                                        {{SGAL, RGAL, NFAL}, {[], [], DelFAL}};
                                                    ?true ->
                                                        {ApplyTp, {[], [], []}}
                                                end,
    {
        FC#friend_common{send_gift_applys = EndNSGAL
            , req_gift_applys = EndNRGAL, recv_friend_applys = EndNFAL
        }, DelIdsTp
    }.


send_gift(SourId, DestId, _GiftQua) ->
    %% 发送方礼包
    SFC = #friend_common{send_count = Send, send_player_ids = SendIds
        , send_gift_type = STypes} = friend_mng:lookup_fc(SourId),

    %% 接受方礼包
    DFC = #friend_common{recv_count = Recv, recv_player_ids = RecvIds
    } = friend_mng:lookup_fc(DestId),

    #{send_gift_max:= SendMax, recv_gift_max:= RecvMax
        , gift_qua:= _GiftQuas} = misc_cfg:get_friend_cfg(),


    IsSended = lists:member(DestId, SendIds),
    IsRecved = lists:member(SourId, RecvIds),


    if
        STypes =:= [] -> {error, type_use_up};
        Send >= SendMax -> {error, send_max};
        Recv >= RecvMax -> {error, recv_max};
        IsSended -> {error, already_get};
        IsRecved -> {error, already_get};
        ?true ->
            PrizeItemTp = com_util:rand(STypes),

            update_fc(SFC#friend_common{send_count = Send + 1, send_gift_type = lists:delete(PrizeItemTp, STypes)
                , send_player_ids = [DestId | SendIds]}
            ),
            world:send_to_player_if_online(SourId,
                ?to_client_msg(friend_sproto:pkg_msg(?MSG_FRIEND_ADD_GIFT_APPLY, {?T_SEND_GIFT_APPLY, DestId}))
            ),
            update_fc(DFC#friend_common{recv_count = Recv + 1, recv_player_ids = [SourId | SendIds]}),
            world:send_to_player_if_online(DestId,
                ?to_client_msg(friend_sproto:pkg_msg(?MSG_FRIEND_ADD_GIFT_APPLY, {?T_RECV_GIFT_APPLY, SourId}))
            ),
            {ok, PrizeItemTp}
    end.

get_rand_mean_list(PrizeTps, SMax) ->
    lists:foldl(
        fun({Atom, Val}, Acc) ->
            [{Atom, Val div SMax} | Acc]
        end,
        [],
        PrizeTps
    ).
