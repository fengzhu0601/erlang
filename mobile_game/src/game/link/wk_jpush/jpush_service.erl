%%%-------------------------------------------------------------------
%%% @author fengzhu
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 14. 九月 2016 下午4:20
%%%-------------------------------------------------------------------
-module(jpush_service).
-author("fengzhu").

-behaviour(gen_server).

-include("player.hrl").
-include("inc.hrl").
-include("game.hrl").
-include("player_data_db.hrl").
-include("load_db_misc.hrl").

%% API
-export([start_link/0]).

%% gen_server callbacks
-export([init/1,
    handle_call/3,
    handle_cast/2,
    handle_info/2,
    terminate/2,
    code_change/3]).

-define(SERVER, ?MODULE).

-define(sp_last_refresh_tm, sp_last_refresh_tm).
-define(reset_sp_push, reset_sp_push).
-define(player_hourly_sp_timer, player_hourly_sp_timer).    %% 定时器


-define( hourly_add_sp, hourly_add_sp ).
-define( hourly_add_sp_timerref_12, hourly_add_sp_timerref_12 ).
-define( hourly_add_sp_timerref_18, hourly_add_sp_timerref_18 ).
-define( lunch_notice, lunch_notice).
-define( dinner_notice, dinner_notice).

-define(MSG1, "午餐时间到了,给您送上大量体力,大量的经验等待着您.").
-define(MSG2, "晚餐时间到了,给您送上大量体力,大量的经验等待着您.").

-record(state, {}).

%%%===================================================================
%%% API
%%%===================================================================

%%--------------------------------------------------------------------
%% @doc
%% Starts the server
%%
%% @end
%%--------------------------------------------------------------------
start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

init([]) ->
    ets:new(fengzhu,[named_table, public]),
    init_sp_push_status(),
    on_time(),
    {ok, #state{}}.

handle_call(_Request, _From, State) ->
    {reply, ok, State}.

handle_cast(_Request, State) ->
    {noreply, State}.

handle_info({?hourly_add_sp, Notice, _Num}, State) ->
    %% try_add_sp(Num),
    send_jpush_msg(Notice),
    {noreply, State};
handle_info(?reset_sp_push, State) ->
    on_time(),
    {noreply, State};
handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

send_jpush_msg(Notice) ->
    case Notice of
        ?lunch_notice ->
            jpush_http:jpush_send_msg(?MSG1),
            load_db_misc:set(?misc_sp_lunch_status, 1),
            ok;
        ?dinner_notice ->
            jpush_http:jpush_send_msg(?MSG2),
            load_db_misc:set(?misc_sp_dinner_status, 1),
            ok;
        _ ->
            pass
    end.


%% 隔天重置
on_time() ->
    try_date_reset(),
    reset_hourly_sp(),
    erlang:send_after(3000, self(), ?reset_sp_push).

%% 尝试重置数据
try_date_reset() ->
    RecordTime = get(?sp_last_refresh_tm),
    {RY, RM, RD} = case RecordTime of
        {X, Y, Z} ->
            {X, Y, Z};
        undefined ->
            {TempY, TempM, TempD} = virtual_time:date(),
            put(?sp_last_refresh_tm, {TempY, TempM, TempD}),
            {TempY, TempM, TempD}
    end,
    RecordDay = util:get_days({RY, RM, RD}),
    {CY, CM, CD} = virtual_time:date(),
    CurDay = util:get_days({CY, CM, CD}),
    if
        CurDay > RecordDay ->
            %% 日刷新
            load_db_misc:set(?misc_sp_lunch_status, 0),
            load_db_misc:set(?misc_sp_dinner_status, 0),
            %% 刷新记录
            put(?sp_last_refresh_tm, {CY, CM, CD});
        true ->
            false
    end.

reset_hourly_sp() ->
    start_hourly_timer(),
    ok.

%% 整点加体力
start_hourly_timer() ->
    %% 从现在到当天12点和18点的秒数
    {_, Time} = calendar:local_time(),
    Time12 = calendar:time_to_seconds(Time) - calendar:time_to_seconds({12, 0, 0}),
    Time18 = calendar:time_to_seconds(Time) - calendar:time_to_seconds({18, 0, 0}),

    case load_db_misc:get(?misc_sp_lunch_status, 0) of
        0 ->
            if
                Time12 >= 0 ->
                    send_jpush_msg(?lunch_notice);
                true ->
                    pass
            end,
            ok;
        _ ->
            pass
    end,

    case load_db_misc:get(?misc_sp_dinner_status, 0) of
        0 ->
            if
                Time18 >= 0 ->
                    send_jpush_msg(?dinner_notice);
                true ->
                    pass
            end,
            ok;
        _ ->
            pass
    end.

init_sp_push_status() ->
    {_, {H,_,_}} = calendar:local_time(),
    if
        H > 18 ->
            load_db_misc:set(?misc_sp_lunch_status, 1),
            load_db_misc:set(?misc_sp_dinner_status, 1);
        H > 12 ->
            load_db_misc:set(?misc_sp_lunch_status, 1);
        true ->
            pass
    end.


%% %% 离线玩家增加体力
%% add_sp_to_offline_player(Num) ->
%%     OfflinePlayerList = world:get_all_offline_player(),
%%     lists:foreach(
%%         fun(PlayerId) ->
%%             player:direct_update_player_data(player_tab, PlayerId, #player_tab.sp, Num )
%%         end,
%%         OfflinePlayerList
%%     ).
