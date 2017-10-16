%%%-------------------------------------------------------------------
%%% @author zl
%%% @doc
%%%
%%% @end
%%%-------------------------------------------------------------------

-module(scene_eng).

-behaviour(gen_server).
%% gen_server callbacks
-export([init/1,
    handle_call/3,
    handle_cast/2,
    handle_info/2,
    terminate/2,
    code_change/3
]).

%% Module Interface
-export([start_link/1]).

%% API
-export
([
    start_timer/3
    , is_wait_timer/1
    , cancel_timer/1
    , terminate_scene/1 %% 结束场景进程
    , shrink_idx/3
    , show_info/1
    , get_login_num/0
    , scene_msg_cast/2
    , get_timer/1   % 根据ref获取timer的参数
]).

-include_lib("common/include/inc.hrl").
-include("scene.hrl").
-include("scene_agent.hrl").
-include("load_cfg_scene.hrl").
-include("evt_util.hrl").


-define(pd_timer_mng, pd_timer_mng).

%% @doc Starts the server
start_link({Cfg, IsRealMon}) ->
    gen_server:start_link(?MODULE, {Cfg, IsRealMon},
        [
            {debug, []},
            {spawn_opt,
                [{priority, high}] % max, high, normal, low
            }
        ]);
start_link(Cfg) ->
    gen_server:start_link(?MODULE, Cfg,
        [
            {debug, []},
            {spawn_opt,
                [{priority, high}] % max, high, normal, low
            }
        ]).

terminate_scene(Reason) ->
    self() ! {'@stop@', Reason}.

show_info(PidList) when is_list(PidList) ->
    erlang:list_to_pid(PidList) ! process_info.

%% INLINE
start_timer(Time, Mod, Msg) ->
    case room_system:is_in_room_pd() of
        true ->
            timer_server:start(Time, {room_system, on_scene_handle_timer, [{Mod,Msg}]});

        false ->
            {Ref, Mng_2} = com_proc_timer:start_timer(Time, {Mod, Msg}, get(?pd_timer_mng)),
            put(?pd_timer_mng, Mng_2),
            Ref
    end.


%% INLINE
get_next_time_out() ->
    com_proc_timer:next_timeout(get(?pd_timer_mng)).

is_wait_timer(?none) ->
    false;
is_wait_timer(Ref) ->
    case room_system:is_in_room_pd() of
        true -> timer_server:is_wait_timer(Ref);
        false -> com_proc_timer:is_member(Ref, get(?pd_timer_mng))
    end.
    
get_timer(?none) -> ok;
get_timer({Timeout, _} = Ref) ->
    Mng = get(?pd_timer_mng),
    case gb_trees:lookup(Timeout, Mng) of
        ?none ->
            none;
        {?value, [{Ref, Msg}]} ->
            {Ref, Msg};
        {?value, [{_OtherRef, _Msg}]} ->
            none;
        {?value, TimerList} ->
            lists:keyfind(Ref, 1, TimerList)
    end;
get_timer(Ref) ->
    case room_system:is_in_room_pd() of
        true ->
            case timer_server:get_timer_mfa(Ref) of
                {room_system, on_scene_handle_timer, [{_,Msg}]} -> Msg;
                _ -> ok
            end;

        false ->
            ?ERROR_LOG("error get_timer ~p", [Ref])
    end.


%% INLINE
-spec cancel_timer(_) -> no_return().

cancel_timer(?none) -> ok;
cancel_timer(Ref) ->
    case room_system:is_in_room_pd() of
        true ->
            timer_server:stop(Ref);

        false ->
            case catch com_proc_timer:cancel_timer(Ref, get(?pd_timer_mng)) of
                {'EXIT', _E} ->
                    ?ERROR_LOG("cancel_timer timer ~p crash ~p", [Ref, _E]);
                Mng_2 ->
                    put(?pd_timer_mng, Mng_2)
            end
    end.


shrink_idx(Idx, FreeIdxSets, Inc) ->
    case gb_sets:is_member(Idx, FreeIdxSets) of
        true ->
            shrink_idx(Idx + Inc, gb_sets:delete(Idx, FreeIdxSets), Inc);
        _ ->
            {Idx, FreeIdxSets}
    end.


%% TODO auto gen
-define(ALL_SCENE_MODS,
    [
        scene
        , scene_map
        , scene_player
        , scene_drop
        , scene_monster
    ]).

init(Cfg = #scene_cfg{}) ->
    init({Cfg, ?true});


init({#scene_cfg{id = SceneId, type = _Type} = Cfg, _IsRealMon}) ->
    process_flag(trap_exit, true),
    PName = {scene, SceneId},
    % if
    %     SceneId =:= 105 ->
    %         erlang:send_after(1000, self(), messages);%% test dsl
    %     true ->
    %         pass
    % end,
    try
        com_process:init_name(PName),
        com_process:init_type(?PT_SCENE),
        random:seed(os:timestamp()),
        ?pd_new(?pd_timer_mng, com_proc_timer:new()),
        [
            begin
                Mod:init(Cfg)
            end
            || Mod <- ?ALL_SCENE_MODS
        ],
        %% type mod init
        (get(?pd_type_mod)):init(Cfg)
    of
        _ ->
            %%要放在最后，因为init如果报错是不会触发terminate的
            com_prog:join_sync(?scene_group, SceneId),
            {ok, PName, get_next_time_out()}
    catch
        _:R ->
            ?ERROR_LOG("init scene ~p crash ~p ~p", [SceneId, R, erlang:get_stacktrace()]),
            {stop, R}
    end.

handle_call({mod, Mod, Msg}, _From, State) ->
    % {_, MsgC} = erlang:process_info(self(), message_queue_len),
    % ?DEBUG_LOG("MsgC:~p", [MsgC]),
    try Mod:handle_call(_From, Msg) of
        Reply ->
            {reply, Reply, State, get_next_time_out()}
    catch
        _:W ->
            ?ERROR_LOG("call [~p] msg ~p crash ~p ~p", [Mod, Msg, W, erlang:get_stacktrace()]),
            {reply, {error, W}, State, get_next_time_out()}
    end;

% handle_call(get_scene_all_player, _From, State) ->
%     Reply = scene_player:get_all_player_ids(),
%     {reply, Reply, State};
handle_call(Request, _From, State) ->
    ?ERROR_LOG("~p recive unknown msg~p", [?pname(), Request]),
    {reply, ok, State, get_next_time_out()}.

handle_cast({'scene_msg_cast', M, F, A}, State) ->
    M:F(A),
    {noreply, State, get_next_time_out()};

handle_cast(_Msg, State) ->
    ?ERROR_LOG("~p recive unknown msg~p", [?pname(), _Msg]),
    {noreply, State, get_next_time_out()}.

handle_info(#evt_util{} = Evt, State) ->
    evt_util:call(Evt),
    {noreply, State, get_next_time_out()};

handle_info({event, Event}, State) ->
    scene_event_callback:handle_event(Event),
    {noreply, State, get_next_time_out()};

% handle_info(messages, State) ->
%     Ms = erlang:process_info(self(), messages),
%     io:format("scene_eng Ms-----------:~p~n",[Ms]),
%     erlang:send_after(30000, self(), messages),
%     {noreply, State};   

handle_info(timeout, State) ->
    % SceneId = get(?pd_scene_id),
    % if
    %     SceneId =:= 105 ->
    %         ?DEBUG_LOG("scene_eng timeout------------------------");
    %     true ->
    %         pass
    % end,
    handle_timer__(),
    {noreply, State, get_next_time_out()};

handle_info({mod, Mod, Msg}, State) ->
    % ?ENV_develop
    % (
    %     _Tbegin = com_time:timestamp_msec()
    % ),

    case catch Mod:handle_msg(Msg) of
        {'EXIT', W} ->
            ?ERROR_LOG("handle mod msg ~p ~p ~p", [Mod, Msg, W]);
        {error, R} ->
            ?ERROR_LOG("handle mod msg ~p ~p ~p ", [Mod, Msg, R]);
        _ ->
            ok
    end,

    % ?ENV_develop
    % (
    %     _ExpenseTime = com_time:timestamp_msec() - _Tbegin,
    %     ?if_(_ExpenseTime > 30, ?NODE_INFO_LOG("handle mod msg ~p expensed ~p mesc", [{Mod, Msg}, _ExpenseTime]))
    % ),

    {noreply, State, get_next_time_out()};

handle_info(process_info, State) ->
    ?DEBUG_LOG("player count: ~p~n"
    "monster count: ~p~n",
        [get(?pd_player_max_id),
            get(?pd_monster_max_id)
        ]),
    com_process:info(),
    {noreply, State, get_next_time_out()};

handle_info({'EXIT', Pid, _Reason}, State) ->
    ?DEBUG_LOG("player ~p exit max idx ~p, reason:~p", [Pid, get(?pd_player_max_id), _Reason]),
    case scene_player:get_player_with_pid(Pid) of
        {ok, Idx} ->
            case ?del_agent(Idx) of
                undefined ->
                    ?NODE_ERROR_LOG("idx ~p leave scene but not find", [Idx]),
                    ok;
                A ->
                    scene_agent:leave_scene(A),
                    ?DEBUG_LOG("clean EXIT idx ~p key~p ", [Idx, erlang:get_keys(Idx)])
            end;
        _ ->
            ?NODE_ERROR_LOG("pid EXIT but can not find idx ~p", [Pid])
    end,
    {noreply, State, get_next_time_out()};

% handle_info(test, State) ->
%     ?DEBUG_LOG("test-----------------------"),
%     {noreply, State, get_next_time_out()};


handle_info({'@stop@', Reason}, State) ->
    scene_player:kickout_all_players(),
    {stop, Reason, State};

handle_info(Msg, State) ->
    ?ERROR_LOG("~p recive unknown msg~p", [?pname(), Msg]),
    {noreply, State, get_next_time_out()}.

%% @spec terminate(Reason, State) -> no_return()
%%       Reason = normal | shutdown | {shutdown, term()} | term()
terminate(Reason, _State) ->
    {_, MsgC} = erlang:process_info(self(), message_queue_len),
    case Reason of
        ?normal ->
            pass;
        ?shutdown ->
            ?ERROR_LOG("error, scene process terminate with ~p", [Reason]),
            ?NODE_INFO_LOG("~p process terminate message_queue_len: ~p.", [?pname(), MsgC]);
        _ ->
            ?ERROR_LOG("error, scene process terminate with ~p", [Reason]),
            ?NODE_ERROR_LOG("~p process Crash with Reason ~p ", [?pname(), Reason])
    end,


    (get(?pd_type_mod)):uninit(nil),
    com_prog:leave_sync(?scene_group),
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.


handle_timer__() ->
    case com_proc_timer:take_next_timeout_timer(get(?pd_timer_mng)) of
        ?none ->
            ?none;
        {TRef, {Mod, Msg}, NewProc} ->
            put(?pd_timer_mng, NewProc),
            % ?ENV_develop(
            %     _Tbegin = com_time:timestamp_msec()
            % ),
            %?DEBUG_LOG("Mod-----------------:~p-------Msg------:~p",[Mod, Msg]),
            case catch Mod:handle_timer(TRef, Msg) of
                {'EXIT', E} ->
                    ?ERROR_LOG("handle timer ~p mod ~p msg ~p ~p", [TRef, Mod, Msg, E]);
                _ -> ok
            end,

            % ?ENV_develop
            % (
            %     _ExpenseTime = com_time:timestamp_msec() - _Tbegin,
            %     ?if_(_ExpenseTime > 35, ?NODE_INFO_LOG("handle timer ~p expensed ~p mesc", [{Mod, Msg}, _ExpenseTime]))
            % ),
            handle_timer__()
    end.


get_login_num() ->
    case erlang:get("scene_login_num") of
        undefined ->
            erlang:put("scene_login_num", 1),
            1;
        Num ->
            if
                Num < 999999999 ->
                    erlang:put("scene_login_num", Num+1),
                    Num;
                true ->
                    erlang:put("scene_login_num", 1),
                    1
            end
    end.

scene_msg_cast(ScenePid, {M, F, A}) ->
    gen_server:cast(ScenePid, {'scene_msg_cast', M, F, A}).