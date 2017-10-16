%%%-------------------------------------------------------------------
%%% @author zl
%%% @doc 提供在线计时,和上线下都计时的功能, 所有消息,只能发给自己
%%% @end
%%%-------------------------------------------------------------------

-module(timer_eng).

-include_lib("common/include/inc.hrl").
-include_lib("pangzi/include/pangzi.hrl").

-include("inc.hrl").
-include("player.hrl").
-include("player_mod.hrl").

-define(player_timer_tab, player_timer_tab).


%% API for player process
-export([
    start_tmp_timer/3,
    start_tmp_timer/4, %% 下线时自动取消
    %start_online_timer/4, %% 只在上线时计时
    %start_cross_timer/4, %% 上下线都计时
    %start_timer/4,
    %start_timer/5,

    start_tmp_timer_mfa/2,
    %start_online_timer_mfa/3,
    %start_cross_timer_mfa/3,
    %start_timer_mfa/3,
    %start_timer_mfa/4,

    read_timer/1,
    get_state/1,
    cancel_timer/1,

    stop_timer/1, %% tmp timer 不能调用
    resume_timer/1

]).

%% call by eng
-export([
    get_next_time_out/0,
    handle_timeout/0
]).



-record(timer_tab, {id :: player_id(),           %% 用户ID
    run_mng, %% pd_timer_run_mng
    proc_mng, %% pd_proc_timer_mng       存的是已启动的在线定时器
    stop_mng, %% pd_timer_stop_mng
    offline_auto_stop_timers %% [{Key, RemainTime, Body}]
}).

%% pd_timer_run_mng 正在计时的定时器 gb_trees {Key, {TRef, Type, {Mod,Msg}}}
-define(pd_timer_run_mng, pd_timer_run_mng). %%
-define(mk_mod_timer_body(__Mod, __Msg), {__Mod, __Msg}).
-define(mk_mfa_timer_body(__MFA), {'@mfa@', __MFA}).

-define(TRef(__Value), (element(1, __Value))).

%% 存储 com_proc_timer 的返回值
-define(pd_proc_timer_mng, pd_proc_timer_mng).


%% 手动调用停止的计时器 pd_timer_stop_mng 正在计时的定时器 gb_trees {Key, {Remain, Type, Boay}}
-define(pd_timer_stop_mng, pd_timer_stop_mng).


%% offline_auto_stop_timers
-define(mk_off_auto_stop(__Key, __Remain, __Body), {__Key, __Remain, __Body}).

%% 定时器类型
-define(CROSS_TIMER, 1).
-define(ONLINE_TIMER, 2).
-define(TMP_TIMER, 3).
-define(HAND_TIMER, 4). %% 手动类型

%% @doc 所有的key,不管类型是否相同都不能重复
%% Mod 回调的模块, 会回调 Mod:handle_msg
%% @return 如果已经存在一个重复的Key, 新的会替代旧的, 返回 replace_old.
-spec start_tmp_timer(timeout(), atom(), term()) -> Key :: _.
start_tmp_timer(TimeMs, Mod, Msg) ->
    Key = make_ref(),
    start_timer2__(Key, TimeMs, ?TMP_TIMER, ?mk_mod_timer_body(Mod, Msg), start),
    Key.

-spec start_tmp_timer(term(), timeout(), atom(), term()) -> ok | replace_old.
start_tmp_timer(Key, TimeMs, Mod, Msg)
    when
    is_atom(Mod),
    is_integer(TimeMs),
    TimeMs > 0 ->
    start_timer__(Key, TimeMs, ?TMP_TIMER, ?mk_mod_timer_body(Mod, Msg), start).

%% INLINE
% -spec start_cross_timer(term(), timeout(), atom(), term()) -> ok | replace_old.
% start_cross_timer(Key, TimeMs, Mod, Msg)
%     when
%     is_atom(Mod),
%     is_integer(TimeMs), TimeMs > 0 ->
%     start_timer__(Key, TimeMs, ?CROSS_TIMER, ?mk_mod_timer_body(Mod, Msg), start).


% start_timer(Key, TimeMs, Mod, Msg) ->
%     start_timer(Key, TimeMs, Mod, Msg, start).

%% @doc 开始一个计时器,不会自动消失,
% -spec start_timer(_, _, _, _, start | stop) -> _.
% start_timer(Key, TimeMs, Mod, Msg, State)
%     when State =:= start; State =:= stop ->
%     start_timer__(Key, TimeMs, ?HAND_TIMER, ?mk_mod_timer_body(Mod, Msg), State).


% -spec start_online_timer(term(), timeout(), atom(), term()) -> ok | replace_old.
% start_online_timer(Key, TimeMs, Mod, Msg)
%     when
%     is_atom(Mod),
%     is_integer(TimeMs), TimeMs > 0 ->
%     start_timer__(Key, TimeMs, ?ONLINE_TIMER, ?mk_mod_timer_body(Mod, Msg), start).

% -spec start_timer_mfa(any(), _, {_, _, _}) -> ok | replace_old.
% start_timer_mfa(Key, TimeMs, MFA) ->
%     start_timer_mfa(Key, TimeMs, MFA, start).

% start_timer_mfa(Key, TimeMs, MFA, State) ->
%     start_timer__(Key, TimeMs, ?TMP_TIMER, ?mk_mfa_timer_body(MFA), State).

start_tmp_timer_mfa(TimeMs, {_, _, _} = MFA) ->
    Key = make_ref(),
    start_timer2__(Key, TimeMs, ?TMP_TIMER, ?mk_mfa_timer_body(MFA), start),
    Key.


% -spec start_online_timer_mfa(_, _, {_, _, _}) -> _.
% start_online_timer_mfa(Key, TimeMs, MFA) ->
%     start_timer__(Key, TimeMs, ?ONLINE, ?mk_mfa_timer_body(MFA), start).

% start_cross_timer_mfa(Key, TimeMs, MFA) ->
%     start_timer__(Key, TimeMs, ?CROSS_TIMER, ?mk_mfa_timer_body(MFA), start).


%%INLINE
start_timer__(Key, Time, Type, Body, State) ->
    Ret =
        case gb_trees:lookup(Key, get(?pd_timer_run_mng)) of
            ?none ->
                ok;
            {?value, Value} ->
                %% delete old one
                put(?pd_proc_timer_mng, com_proc_timer:cancel_timer(?TRef(Value), get(?pd_proc_timer_mng))),
                put(?pd_timer_run_mng, gb_trees:delete(Key, get(?pd_timer_run_mng))),
                replace_old
        end,

    start_timer2__(Key, Time, Type, Body, State),
    Ret.

-spec start_timer2__(_, _, _, _, _) -> no_return().
start_timer2__(Key, Time, Type, Body, State) ->
    case State of
        start ->
            {TRef, ProcMng} = com_proc_timer:start_timer(Time, Key, get(?pd_proc_timer_mng)),
            put(?pd_proc_timer_mng, ProcMng),
            put(?pd_timer_run_mng, gb_trees:insert(Key, {TRef, Type, Body}, get(?pd_timer_run_mng)));
        stop ->
            case gb_trees:lookup(Key, get(?pd_timer_stop_mng)) of
                ?none ->
                    put(?pd_timer_stop_mng,
                        gb_trees:insert(Key, {Time, Type, Body}, get(?pd_timer_stop_mng)));
                {?value, {_T, Type, Body}} ->
                    put(?pd_timer_stop_mng,
                        gb_trees:update(Key, {Time, Type, Body}, get(?pd_timer_stop_mng)))
            end
    end.


%% @doc 得到一个timer的状态 
-spec get_state(_) -> start | stop |none.
get_state(Key) ->
    case gb_trees:is_defined(Key, get(?pd_timer_run_mng)) of
        ?true ->
            start;
        ?false ->
            case gb_trees:is_defined(Key, get(?pd_timer_stop_mng)) of
                ?true ->
                    stop;
                ?false ->
                    none
            end
    end.

%% @doc 返回剩余时间Ms.
-spec read_timer(_) -> integer() | none.
read_timer(Key) ->
    case gb_trees:lookup(Key, get(?pd_timer_run_mng)) of
        {?value, Value} ->
            com_proc_timer:read_timer(?TRef(Value));
        ?none ->
            case gb_trees:lookup(Key, get(?pd_timer_stop_mng)) of
                ?none ->
                    ?none;
                {?value, {Remain, _, _}} ->
                    Remain
            end
    end.

%% @doc cancel any timer return by functions of this module.
%% @return 如果不存在Key, 返回not_exist.
%% INLINE
-spec cancel_timer(term()) -> ok | not_exist.
cancel_timer(Key) ->
    case cancel_timer__(Key, ?pd_timer_run_mng) of
        ok -> ok;
        not_exist ->
            cancel_timer__(Key, ?pd_timer_stop_mng)
    end.

cancel_timer__(Key, Pd) ->
    case gb_trees:lookup(Key, get(Pd)) of
        ?none ->
            not_exist;
        {?value, Value} ->
            put(?pd_proc_timer_mng,
                com_proc_timer:cancel_timer(?TRef(Value), get(?pd_proc_timer_mng))),
            put(Pd, gb_trees:delete(Key, get(Pd))),
            ok
    end.

%% @doc 暂停一个定时器, 如果已经被暂停返回  {error, alreay_stoped}
%%      不存在返回 {error, not_exist} 
-spec stop_timer(term()) -> ok | {error, alreay_stoped} | {error, not_exist}.
stop_timer(Key) ->
    RunMng = get(?pd_timer_run_mng),
    StopMng = get(?pd_timer_stop_mng),
    case gb_trees:lookup(Key, RunMng) of
        ?none ->
            case gb_trees:is_defined(Key, StopMng) of
                ?true ->
                    ?err(alreay_stoped);
                ?false ->
                    ?err(not_exist)
            end;
        {?value, {TRef, Type, Body}} ->
            Remain =
                case com_proc_timer:read_timer(TRef) of
                    _R when _R =< 0 ->
                        ?ERROR_LOG("stop timer ~p Remain time ~p <0 ~p", [Key, _R, Body]),
                        100;%% ms
                    _R -> _R
                end,
            put(?pd_proc_timer_mng,
                com_proc_timer:cancel_timer(TRef, get(?pd_proc_timer_mng))),
            put(?pd_timer_run_mng, gb_trees:delete(Key, RunMng)),
            put(?pd_timer_stop_mng, gb_trees:insert(Key, {Remain, Type, Body}, StopMng)),
            Remain
    end.


%% @doc 恢复一个调用stop_timer 暂停的计时器
-spec resume_timer(term()) -> {ok, RemainMs :: _} | {error, not_exist} | {error, already_running}.
resume_timer(Key) ->
    RunMng = get(?pd_timer_run_mng),
    StopMng = get(?pd_timer_stop_mng),
    case gb_trees:lookup(Key, StopMng) of
        ?none ->
            case gb_trees:is_defined(Key, RunMng) of
                ?true ->
                    ?err(already_running);
                ?false ->
                    ?err(not_exist)
            end;
        {?value, {Remain, Type, Body}} ->
            put(?pd_timer_stop_mng, gb_trees:delete(Key, StopMng)),
            {TRef, ProcMng} = com_proc_timer:start_timer(Remain, Key, get(?pd_proc_timer_mng)),
            put(?pd_proc_timer_mng, ProcMng),
            put(?pd_timer_run_mng, gb_trees:insert(Key, {TRef, Type, Body}, RunMng)),
            {ok, Remain}
    end.


%% INLINE获取下一个触发超时的时间戳
get_next_time_out() ->
    case get(?pd_proc_timer_mng) of
        ?undefined ->
            ?infinity;
        Mng ->
            com_proc_timer:next_timeout(Mng)
    end.


-spec handle_timeout() -> NextTimeOut :: _.
handle_timeout() ->
    handle_timeout(com_time:timestamp_msec()),
    com_proc_timer:next_timeout(get(?pd_proc_timer_mng)).

%% 
handle_timeout(NowMsec) ->
    case com_proc_timer:take_next_timeout_timer(get(?pd_proc_timer_mng)) of
        ?none ->
            %% 过于频繁
            %% ok meaby timeout is too large
            %?ERROR_LOG("take smallset none next_timeout ~p size~p", [com_proc_timer:next_timeout(get(?pd_proc_timer_mng)), gb_trees:size(get(?pd_proc_timer_mng))]);
            pass;
        {_TRef, Key, NewProc} ->
            put(?pd_proc_timer_mng, NewProc),
            case gb_trees:lookup(Key, get(?pd_timer_run_mng)) of
                ?none ->
                    ?ERROR_LOG("timer out ~p but can not find in run mng", [Key]);

                {?value, {_TRef, _, Body}} ->
                    put(?pd_timer_run_mng, gb_trees:delete(Key, get(?pd_timer_run_mng))),

                    case Body of
                        {'@mfa@', {M, F, A}} ->
                            com_util:safe_apply(M, F, A);
                        {Mod, Msg} -> %% mod_msg
                            Mod:handle_msg(?MODULE, Msg);
                        _R ->
                            ?ERROR_LOG("unknow timer ~p ~p", [Key, _R])
                    end,
                    handle_timeout(NowMsec)
            end
    end.



create_mod_data(_SelfId) -> ok.

run_mng_new() -> gb_trees:empty().
stop_mng_new() -> gb_trees:empty().


load_mod_data(PlayerId) ->
    % ?DEBUG_LOG("timer_eng-----------------------------:~p",[PlayerId]),
    case dbcache:lookup(?player_timer_tab, PlayerId) of
        [] ->
            % ?DEBUG_LOG("pd_proc_timer_mng----------------------:~p",[get(?pd_proc_timer_mng)]),
            put(?pd_proc_timer_mng, gb_trees:empty()),
            put(?pd_timer_run_mng, run_mng_new()),
            put(?pd_timer_stop_mng, stop_mng_new());
        [#timer_tab{run_mng = RunMng, stop_mng = StopMng, proc_mng = ProcMng, offline_auto_stop_timers = AutoStopTimerList}] ->
            ?pd_new(?pd_proc_timer_mng, ProcMng),
            ?pd_new(?pd_timer_run_mng, RunMng),
            ?pd_new(?pd_timer_stop_mng, StopMng),

            %% auto resume
            lists:foreach(fun({Key, Remain, Body}) ->
                start_timer__(Key, Remain, ?ONLINE_TIMER, Body, start)
            end,
            AutoStopTimerList),
            dbcache:delete(?player_timer_tab, PlayerId)
    end,
    ok.

offline(_PlayerId) ->
    % OfflineAutoStopTimerList =
    % com_util:gb_trees_fold(
    %     fun
    %         (Key, {_, ?TMP_TIMER, _}, Acc) ->
    %             ?ifdo(cancel_timer(Key) =/= ok, ?ERROR_LOG("remove tmp timer ~p", [Key])),
    %             Acc;
    %         (Key, {TRef, ?ONLINE_TIMER, Body}, Acc) ->
    %             ?ifdo(cancel_timer(Key) =/= ok, ?ERROR_LOG("remove tmp timer ~p", [Key])),
    %             [?mk_off_auto_stop(Key, com_proc_timer:read_timer(TRef), Body) | Acc];
    %         (_, {_, ?CROSS_TIMER, _}, Acc) ->
    %             Acc;
    %         (_Key, _U, Acc) ->
    %             ?ERROR_LOG("unknow timer key~p body ~p", [_Key, _U]),
    %             Acc
    %     end,
    % [],
    % get(?pd_timer_run_mng)),
    % put(offline_auto_stop_timers, OfflineAutoStopTimerList),
    ok.

%% update remain time
%% auto stop online time and remove offline_auto_cancel timer
save_data(_PlayerId) ->
    %% erase can be find error
    % AutoStopTimers = case get(offline_auto_stop_timers) of
    %                      ?undefined -> [];
    %                      Timers -> Timers
    %                  end,
    % dbcache:update(?player_timer_tab, #timer_tab{id = PlayerId,
    %     run_mng = get(?pd_timer_run_mng),
    %     proc_mng = get(?pd_proc_timer_mng),
    %     stop_mng = get(?pd_timer_stop_mng),
    %     offline_auto_stop_timers = AutoStopTimers}),
    ok.



init_client() -> ok.
view_data(_) -> ok.

handle_frame(_) -> ok.

online() -> ok.


handle_msg(FromMod, Msg) ->
    ?ERROR_LOG("~p recv a unknown msg ~p from ~p", [?pname(), Msg, FromMod]).

load_db_table_meta() ->
    [
        #db_table_meta{
            name = ?player_timer_tab,
            fields = ?record_fields(timer_tab),
            record_name = timer_tab,
            shrink_size = 1,
            flush_interval = 3
        }
    ].
