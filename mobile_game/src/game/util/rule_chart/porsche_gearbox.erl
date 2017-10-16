%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%% 变速箱
%%% @end
%%% Created : 06. 四月 2016 下午12:34
%%%-------------------------------------------------------------------
-module(porsche_gearbox).
-author("clark").

%% API
-export
([
    init/3
    , init/4
    , uninit/1
    , set_state/2
    , set_state/3
    , evt_any/3
    , evt_can/3
    , evt_do/3
    , get_cur_porschekey/0
    , get_cur_evtargs/0
    , send_user_evt/1
    , get_cur_state/1
    , add_func_times/1
    , get_cur_funckey/0
    , is_over_times/0
    , get_cur_func_data/1
    , set_cur_func_data/2
]).

-export
([
    on_set_state/1,
    on_time/3
]).


-include("inc.hrl").
-include("load_rule_chart.hrl").
-include("porsche_gearbox.hrl").


-define(gearbox_temp,   '@gearbox_temp@').
-define(funckey_temp,   '@gearbox_funckey_temp@').
-define(over_times,     '@gearbox_over_times@').



-record(rule_evt_data,
{
    used_times      = 0,
    limit_times     = -1,
    user_data       = []
}).


-record(gearbox_data,
{
    cfg_data=[],                                                %% 配置表内容
    cur_id = 0,                                                 %% 档位
    gear_callback = fun porsche_gearbox:default_callback/1,     %% 变挡回调
    state_callback = nil
}).


init(PorscheKey, Chart, Callback) ->
    init(PorscheKey, Chart, Callback, 1).
init(PorscheKey, Chart, Callback, StateId) ->
    StateCallBack =
        fun(#rule_set_state{gearbox_id=EvtPorscheKey, to_id = Id}) ->
            if
                EvtPorscheKey == PorscheKey ->
                    on_set_state(#rule_set_state{gearbox_id=PorscheKey, to_id = Id});

                true ->
                    pass
            end
        end,
    evt_util:sub(#rule_set_state{}, StateCallBack),
    util:set_pd_field
    (
        PorscheKey,
        #gearbox_data
        {
            cfg_data=Chart,
            gear_callback = Callback,
            state_callback = StateCallBack
        }
    ),
    set_state(PorscheKey, StateId),
    ok.

uninit(PorscheKey) ->
    case util:get_pd_field(PorscheKey, nil) of
        #gearbox_data{state_callback=StateCallBack} ->
            on_set_state(#rule_set_state{gearbox_id=PorscheKey, to_id = 0}),
            evt_util:unsub(#rule_set_state{}, StateCallBack),
            util:del_pd_field(PorscheKey);

        _ ->
            pass
    end,

    ok.

%% 换档,下一帧生效
set_state(PorscheKey, Id) ->
    evt_util:send(#rule_set_state{gearbox_id=PorscheKey, to_id = Id}).

set_state(PorscheKey, Id, Dt) ->
    timer_server:start(Dt, {porsche_gearbox, set_state, [PorscheKey, Id]}).


%% 换档生效
on_set_state(#rule_set_state{gearbox_id=PorscheKey, to_id = Id}) ->
    Gearbox = util:get_pd_field(PorscheKey, #gearbox_data{}),
    CurId = Gearbox#gearbox_data.cur_id,
    States = Gearbox#gearbox_data.cfg_data,

    case lists:keyfind(CurId, #rule_porsche_state.state_id, States) of
        false ->
            pass;

        ExitNode ->
            %% 相关退出操作
            evt_util:call(#rule_exit_state{gearbox_id=PorscheKey, from_id=CurId}),
            unsub_node(PorscheKey, ExitNode)
    end,
    %% 空档
    Gearbox1 = Gearbox#gearbox_data{cur_id=0},
    util:set_pd_field(PorscheKey, Gearbox1),

    %% 升档
    if
        Id =/= 0 ->
            case lists:keyfind(Id, #rule_porsche_state.state_id, States) of
                false ->
                    pass;

                EnterNode ->
                    %% 升档
                    Gearbox2 = Gearbox1#gearbox_data{cur_id=Id},
                    util:set_pd_field(PorscheKey, Gearbox2),
                    %% 相关进入操作
                    sub_node(PorscheKey, EnterNode),
                    evt_util:call(#rule_enter_state{gearbox_id=PorscheKey, to_id=Id})
            end;

        true ->
            pass
    end,

    ok.


get_cur_state(PorscheKey) ->
    Gearbox = util:get_pd_field(PorscheKey, #gearbox_data{cur_id=0}),
    Gearbox#gearbox_data.cur_id.



%% 注册结点
sub_node(PorscheKey, #rule_porsche_state{state_id = StateId, evt_list = Evts}) ->
    Gearbox = util:get_pd_field(PorscheKey, #gearbox_data{}),
    UserCallback = Gearbox#gearbox_data.gear_callback,
    if
        nil =/= UserCallback ->
            %% 初始化计数
            lists:foreach
            (
                fun
                    (#rule_porsche_event{key = EvtKey, times=Times}) ->
                        FunKey = make_room_callback_id(PorscheKey, StateId, EvtKey),
                        util:set_pd_field(FunKey, #rule_evt_data{limit_times=Times})
                end,
                Evts
            ),

            %% 事件回调
            EvtTypeList = get_evt_type_list(Evts),
            lists:foreach
            (
                fun
                    ({_,ErlangEvt}) ->
                        OnGearBoxEvt =
                            fun(EvtPar) ->
                                case get_evt_callback_list(EvtPar, Evts, PorscheKey, StateId) of
                                    [] ->
                                        pass;

                                    ActiveList ->
                                        foreace_evt(PorscheKey, StateId, ActiveList, EvtPar, UserCallback)
                                end,
                                ok
                            end,
                        evt_util:sub(ErlangEvt, PorscheKey, OnGearBoxEvt)
                end,
                EvtTypeList
            );

        true ->
            ok
    end,
    ok.


%% 注销结点
unsub_node(PorscheKey, #rule_porsche_state{state_id = StateId, evt_list = Evts}) ->
    Gearbox = util:get_pd_field(PorscheKey, #gearbox_data{}),
    UserCallback = Gearbox#gearbox_data.gear_callback,
    if
        nil =/= UserCallback ->
            lists:foreach
            (
                fun
                    (#rule_porsche_event{key = EvtKey}) ->
                        FunKey = make_room_callback_id(PorscheKey, StateId, EvtKey),
                        util:del_pd_field(FunKey)
                end,
                Evts
            ),

            EvtTypeList = get_evt_type_list(Evts),
            lists:foreach
            (
                fun
                    ({_,ErlangEvt}) -> evt_util:unsub(ErlangEvt, PorscheKey)
                end,
                EvtTypeList
            );

        true ->
            ok
    end,
    ok.

add_func_times(FunKey) ->
    FunData = util:get_pd_field(FunKey, #rule_evt_data{}),
%%     ?INFO_LOG("add_func_times ~p", [FunData]),
    UsedTimes = FunData#rule_evt_data.used_times + 1,
    util:set_pd_field(FunKey, FunData#rule_evt_data{used_times=UsedTimes}).


get_cur_func_data(Key) ->
    case get_cur_funckey() of
        nil ->
            nil;

        FunKey ->
            List = get_func_data(FunKey),
            case lists:keyfind(Key, 1, List) of
                false -> nil;
                {_, Val} -> Val
            end
    end.

set_cur_func_data(Key, Val) ->
    case get_cur_funckey() of
        nil ->
            nil;

        FunKey ->
            List = get_func_data(FunKey),
            List1 = lists:keystore(Key, 1, List, {Key,Val}),
            set_func_data(FunKey, List1)
    end.

get_func_data(FunKey) ->
    FunData = util:get_pd_field(FunKey, #rule_evt_data{}),
    FunData#rule_evt_data.user_data.

set_func_data(FunKey, Data) ->
    FunData = util:get_pd_field(FunKey, #rule_evt_data{}),
    util:set_pd_field(FunKey, FunData#rule_evt_data{user_data=Data}).

get_evt_type_list(Evts) ->
    lists:foldl
    (
        fun
            (#rule_porsche_event{evt_id=EvtId}, Acc) ->
                ErlangEvt = trans_evt(EvtId),
                EvtType = erlang:element(1, ErlangEvt),
                Acc1 = lists:keystore(EvtType, 1, Acc, {EvtType, ErlangEvt}),
                Acc1
        end,
        [],
        Evts
    ).

get_evt_callback_list(EvtPar, Evts, PorscheKey, StateId) ->
    lists:foldl
    (
        fun
            (#rule_porsche_event{evt_id=EvtId} = Item, Acc) ->
                case EvtPar of
                    #rule_set_state{} -> Acc;
                    #rule_user_evt{gearbox_id=PorscheKey, state_id=StateId, evt_id=EvtId} -> [Item|Acc];
                    #rule_user_evt{} -> Acc;
                    #rule_enter_state{gearbox_id=PorscheKey, to_id = StateId} -> [Item|Acc];
                    #rule_enter_state{} -> Acc;
                    #rule_exit_state{gearbox_id=PorscheKey, from_id = StateId} -> [Item|Acc];
                    #rule_exit_state{} -> Acc;
                    _ -> [Item|Acc]
                end
        end,
        [],
        Evts
    ).

foreace_evt(PorscheKey, StateId, Evts, EvtPar, UserCallback) ->
    util:set_pd_field(?gearbox_temp, {PorscheKey,EvtPar}),
    evt_util:call( #rule_callback_begine{gearbox_id=PorscheKey, evt=EvtPar} ),

    EvtParType = erlang:element(1, EvtPar),
    lists:foreach
    (
        fun
            (#rule_porsche_event{key = EvtKey, evt_id=EvtId,  can=Can, true=TrueDo, false=FalseDo}) ->
                ErlangEvt = trans_evt(EvtId),
                ErlangEvtType = erlang:element(1, ErlangEvt),
                if
                    ErlangEvtType == EvtParType ->

                        FunKey = make_room_callback_id(PorscheKey, StateId, EvtKey),
                        FunData = util:get_pd_field(FunKey, #rule_evt_data{}),
                        LimitTimes = FunData#rule_evt_data.limit_times,
                        UsedTimes = FunData#rule_evt_data.used_times + 1,
                        util:set_pd_field(?funckey_temp, FunKey),
                        if
                            LimitTimes =< 0 ->
                                util:set_pd_field(?over_times, false),
                                UserCallback({Can, TrueDo, FalseDo});

                            UsedTimes < LimitTimes ->
                                util:set_pd_field(?over_times, false),
                                UserCallback({Can, TrueDo, FalseDo});

                            UsedTimes == LimitTimes ->
                                util:set_pd_field(?over_times, true),
                                UserCallback({Can, TrueDo, FalseDo});

                            true ->
                                pass
                        end,
                        ok;

                    true ->
                        pass
                end
        end,
        Evts
    ),

    evt_util:call( #rule_callback_end{gearbox_id=PorscheKey, evt=EvtPar} ),
    util:del_pd_field(?gearbox_temp),
    ok.

make_room_callback_id(PorscheKey, StateId, EvtId) ->
    {PorscheKey, StateId, EvtId}.

%% 条件
evt_can([], _Tab, _IsDebug) -> true;
evt_can([#rule_porsche_can{func=Can,par=Par}|Tail], Tab, IsDebug) ->
    case lists:keyfind(Can, 1, Tab) of
        false ->
%%             ?ERROR_LOG("porsche_gearbox:evt_can error item ~p", [Can]),
            evt_can(Tail, Tab, IsDebug);

        {_, Callback} ->
            if
                IsDebug -> ?INFO_LOG("evt_can mod:~p args:~p", [Callback, Par]);
                true -> pass
            end,
            Par1 = case Par of
                       nil -> [];
                       _ -> Par
                   end,
            case erlang:apply(Callback, Par1) of
                true -> evt_can(Tail, Tab, IsDebug);
                _ -> false
            end
    end.

evt_any([], _Tab, _IsDebug) -> false;
evt_any([#rule_porsche_can{func=Can,par=Par}|Tail], Tab, IsDebug) ->
    case lists:keyfind(Can, 1, Tab) of
        false ->
            evt_any(Tail, Tab, IsDebug);

        {_, Callback} ->
            if
                IsDebug -> ?INFO_LOG("evt_any mod:~p args:~p", [Callback, Par]);
                true -> pass
            end,
            Par1 = case Par of
                       nil -> [];
                       _ -> Par
                   end,
            case erlang:apply(Callback, Par1) of
                true -> true;
                _ -> evt_any(Tail, Tab, IsDebug)
            end
    end.


%% 动作
evt_do([], _Tab, _IsDebug) -> ok;
evt_do([#rule_porsche_do{func=Do,par=Par}|Tail], Tab, IsDebug) ->
    case lists:keyfind(Do, 1, Tab) of
        false ->
            evt_do(Tail, Tab, IsDebug);

        {_, Callback} ->
            if
                IsDebug -> ?INFO_LOG("evt_can mod:~p args:~p", [Callback, Par]);
                true -> pass
            end,
            Par1 = case Par of
                       nil -> [];
                       _ -> Par
                   end,
            erlang:apply(Callback, Par1),
            evt_do(Tail, Tab, IsDebug)
    end;
evt_do(_, _Tab, _IsDebug) -> ok.

get_cur_porschekey() ->
    case util:get_pd_field(?gearbox_temp, nil) of
        nil -> nil;
        {Key, _} -> Key
    end.

get_cur_evtargs() ->
    case util:get_pd_field(?gearbox_temp, nil) of
        nil -> nil;
        {_, Evtargs} -> Evtargs
    end.

get_cur_funckey() ->
    util:get_pd_field(?funckey_temp, nil).

is_over_times() ->
    util:get_pd_field(?over_times, true).

default_callback({_IsOverTime, _Can, _Do}) ->
    ok.


trans_evt(EvtId) ->
    case lists:keyfind(EvtId, 1, ?rule_cfg_evt) of
        false -> #rule_user_evt{};
        {_, #rule_enter_state{}} -> #rule_enter_state{};
        {_, #rule_exit_state{}} -> #rule_exit_state{};
        {_, ErlangEvtSrc} -> ErlangEvtSrc
    end.

send_user_evt({Dt, Evt}) ->
    case porsche_gearbox:get_cur_porschekey() of
        nil ->
            ?ERROR_LOG("error use!");

        PorscheKey ->
            StateId = porsche_gearbox:get_cur_state(PorscheKey),
            if
                Dt > 0 -> timer_server:start(Dt, {porsche_gearbox, on_time, [PorscheKey, Evt, StateId]});
                true ->
%%                     ?INFO_LOG("PorscheKey sent_evt ~p", [{PorscheKey, StateId, Evt}]),
                    evt_util:send(#rule_user_evt{gearbox_id=PorscheKey, evt_id=Evt, state_id=StateId})
            end
    end.


on_time(PorscheKey, Evt, StateId) ->
    evt_util:send(#rule_user_evt{gearbox_id=PorscheKey, state_id=StateId, evt_id=Evt}).


