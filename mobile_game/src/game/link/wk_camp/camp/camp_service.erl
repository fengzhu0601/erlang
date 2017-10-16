%%%-------------------------------------------------------------------
%%% @author yujian
%%% @doc 神魔系统，公共信息
%%%-------------------------------------------------------------------
-module(camp_service).
-behaviour(gen_server).

-include_lib("pangzi/include/pangzi.hrl").
%%-include_lib("config/include/config.hrl").
-include("inc.hrl").
-include("player.hrl").

-include("camp_struct.hrl").
-include("main_ins_struct.hrl").

-include("load_cfg_camp.hrl").
-include("load_cfg_main_ins.hrl").

-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-export
([
    start_link/0
    , open_fun/2, open_fun/0                        % 神魔功能开启
    , add_camp_point/2, add_event/1                 % 添加战绩值 添加事件信息
    , add_instance_player/3, del_instance_player/3
    , get_camp_info/1                               % 获取公共数据
    , get_instance_player/1                         % 获取某个副本的入侵玩家列表
    , select_event/2                                % 获取事件信息
    , lookup/2, lookup/3
    , is_open/0, is_fight/0, get_end_time/0, get_point/0
    , player_priv_refresh_time/0                    % 获取玩家进入次数上一次刷新时间
]).

-record(state,
{
    is_open = 0,            % 是否功能开放
    is_fight = 0,           % 是否处于战斗状态
    god_camp_point = 0,     % 神族战绩点
    magic_camp_point = 0,   % 魔族战绩点
    end_time = 0            % 倒计时结束时间
}).



load_db_table_meta() ->
    [
        #db_table_meta
        {
            name = ?service_camp_tab,
            fields = ?record_fields(?service_camp_tab),
            shrink_size = 30,
            flush_interval = 10
        }
    ].

open_fun() ->
    gen_server:call(?MODULE, {open_fun, {get(?pd_id), get(?pd_name)}}).

open_fun(PlayerId, PlayerName) ->
    gen_server:call(?MODULE, {open_fun, {PlayerId, PlayerName}}).

%% 增加战绩点
add_camp_point(CampId, Point) ->
    gen_server:call(?MODULE, {add_camp_point, CampId, Point}).

add_event(Event) ->
    gen_server:cast(?MODULE, {add_event, Event}).

%% 入侵，入侵者信息插入表中
add_instance_player(InstanceId, {PlayerPid, PlayerId}, CampId) ->
    case CampId of
        0 -> ok;
        {?CAMP_PERSON, ?CAMP_PERSON} -> ok;
        {_, CammpId1} ->
            gen_server:cast(?MODULE, {add_instance_player, {InstanceId, {PlayerPid, PlayerId}}}),
            world:broadcast(?mod_msg(camp_mng, {enemy_enter_instance, InstanceId, get(?pd_id), CammpId1, get(?pd_camp_exploit)}));
        CampId ->
            gen_server:cast(?MODULE, {add_instance_player, {InstanceId, {PlayerPid, PlayerId}}}),
            world:broadcast(?mod_msg(camp_mng, {enemy_enter_instance, InstanceId, get(?pd_id), CampId, get(?pd_camp_exploit)}))
    end.

%% 入侵完成或者失败，从表中删除
del_instance_player(InstanceId, PlayerId, CampId) ->
    case CampId of
        0 -> ok;
        {?CAMP_PERSON, ?CAMP_PERSON} -> ok;
        _ -> gen_server:cast(?MODULE, {del_instance_player, {InstanceId, PlayerId}})
    end.

get_camp_info(SelfCampId) ->
    EndTime = get_end_time(),
    {GodPoint, MagicPoint} = get_point(),
    case is_open() of
        false -> {error, ?ERR_CAMP_NOT_OPEN};
        true ->
            Fun = fun(SceneId, Data) ->
                #main_ins_cfg{ins_id = InsId, sub_type = CampId} = load_cfg_main_ins:lookup_main_ins_cfg(SceneId),
                IsMyIns = case SelfCampId of
                              {_, CampId} -> ok;
                              CampId -> ok;
                              {?CAMP_PERSON, ?CAMP_PERSON} -> error;
                              _ -> error
                          end,
                case IsMyIns of
                    ok ->
                        Ins = case get_instance_player(InsId) of
                                  [] -> {InsId, 0};
                                  _ -> {InsId, 1}
                              end,
                        case lists:keyfind(InsId, 1, Data) of
                            false -> [Ins | Data];
                            _ -> Data
                        end;
                    error -> Data
                end
            end,
            InsState = lists:foldl(Fun, [], load_cfg_camp:lookup_cfg(?main_ins_cfg, all)),
            case is_fight() of
                true -> {1, EndTime, GodPoint, MagicPoint, lists:reverse(InsState)};
                false -> {0, EndTime, 0, 0, lists:reverse(InsState)}
            end
    end.

get_instance_player(InstanceId) ->
    case ets:lookup(?service_camp_instance, InstanceId) of
        [] -> [];
        [InstanceTab] ->
            InstanceTab#service_camp_instance.enemy_player_list
    end.

select_event(StartPos, Num) ->
    case lookup(?service_camp_tab, ?CAMP_SERVICE_ID) of
        [] -> {0, []};
        [ServiceCamp] ->
            EventList = ServiceCamp#service_camp_tab.event_list,
            {length(EventList), lists:sublist(EventList, StartPos, Num)}
    end.

is_open() ->
    gen_server:call(?MODULE, {is_open}) =:= 1.

is_fight() ->
    gen_server:call(?MODULE, {is_fight}) =:= 1.

get_end_time() ->
    gen_server:call(?MODULE, {get_end_time}).

get_point() ->
    gen_server:call(?MODULE, {get_point}).

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

init([]) ->
    put(?pd_timer_mng_for_camp, com_proc_timer:new()),
    ets_new(),

    NewState = case lookup(?service_camp_tab, ?CAMP_SERVICE_ID) of
                   [] ->
                       #state{is_open = 0};
                   [ServiceCamp] ->
                       Now = com_time:now(),
                       IsFight = ServiceCamp#service_camp_tab.is_fight,
                       %% @doc 计算玩家刷新次数倒计时,
                       PrivRefreshTime = player_refresh(load_cfg_camp:lookup_cfg(#camp_cfg.refresh_time), Now),

                       %% @doc 启动服务，计算神魔系统倒计时,服务器关机，冻结时间
                       EndTime = ServiceCamp#service_camp_tab.end_timestamp,
                       ServerDown = ServiceCamp#service_camp_tab.server_down_time,
                       CountDown = EndTime + (Now - ServerDown) - Now,
                       if
                           CountDown =< Now ->
                               {{Day1, Minite1, Second1}, _CycleTime2} = load_cfg_camp:lookup_cfg(#camp_cfg.cycle_time),
                               CountDown1 = (Day1 * 24 * 60) + (Minite1 * 60) + Second1,
                               dbcache:update(?service_camp_tab, #service_camp_tab{is_open = 1,
                                   is_fight = 0,
                                   end_timestamp = Now + CountDown1,
                                   server_down_time = 0,
                                   priv_refresh_time = PrivRefreshTime}),
                               start_timer(CountDown1, ?camp_activity),
                               #state{is_open = 1, is_fight = 0, god_camp_point = 0, magic_camp_point = 0, end_time = Now + CountDown1};
                           CountDown > Now ->
                               start_timer(CountDown - Now, ?camp_activity),
                               dbcache:update(?service_camp_tab, ServiceCamp#service_camp_tab{server_down_time = 0,
                                   priv_refresh_time = PrivRefreshTime}),
                               #state{is_open = 1, is_fight = IsFight, god_camp_point = ServiceCamp#service_camp_tab.god_camp_point,
                                   magic_camp_point = ServiceCamp#service_camp_tab.magic_camp_point, end_time = CountDown}
                       end
               end,
    {ok, NewState, 0}.

handle_call({open_fun, {PlayerId, PlayerName}}, _From, State) ->
    {Reply, NewState} = case State#state.is_open of
                            0 -> %%0在mng模块验证是否符合开启条件 1.开启活动 2.备战倒计时
                                world:broadcast(chat_mng:pack_chat_system(?Language(1, {PlayerId, PlayerName}))),
                                {{Day1, Minite1, Second1}, _CycleTime2} = load_cfg_camp:lookup_cfg(#camp_cfg.cycle_time),
                                CountDown = (Day1 * 24 * 60) + (Minite1 * 60) + Second1,
                                dbcache:update(?service_camp_tab, #service_camp_tab{is_open = 1,
                                    is_fight = 0,
                                    end_timestamp = com_time:now() + CountDown}),
                                start_timer(CountDown, ?camp_activity),
                                {ok, State#state{is_open = 1}};
                            1 -> {{error, ?ERR_CAMP_HAVE_OPEN}, State}
                        end,
    {reply, Reply, NewState, next_timer_out()};

handle_call({add_camp_point, CampId, Point}, _From, State) ->
    NewState = case State#state.is_fight of
                   0 -> State;
                   1 ->
                       case CampId of
                           ?CAMP_GOD -> State#state{god_camp_point = State#state.god_camp_point + Point};
                           ?CAMP_MAGIC -> State#state{magic_camp_point = State#state.magic_camp_point + Point};
                           _ -> State
                       end
               end,
    {reply, ok, NewState, next_timer_out()};

handle_call({is_open}, _From, State) ->
    {reply, State#state.is_open, State, next_timer_out()};

handle_call({is_fight}, _From, State) ->
    {reply, State#state.is_fight, State, next_timer_out()};

handle_call({get_end_time}, _From, State) ->
    {reply, State#state.end_time, State, next_timer_out()};

handle_call({get_point}, _From, State) ->
    {reply, {State#state.god_camp_point, State#state.magic_camp_point}, State, next_timer_out()};

handle_call(_Request, _From, State) ->
    {reply, ok, State, next_timer_out()}.

handle_cast({add_event, Event}, State) ->
    [ServiceCamp] = lookup(?service_camp_tab, ?CAMP_SERVICE_ID),
    EventList = ServiceCamp#service_camp_tab.event_list,
    if
        length(EventList) == ?CAMP_EVENT_MAX_LENGTH ->
            RObject = lists:reverse(tl(lists:reverse(EventList))),
            dbcache:update(?service_camp_tab,
                ServiceCamp#service_camp_tab{event_list = [Event | RObject]});
        true ->
            dbcache:update(?service_camp_tab,
                ServiceCamp#service_camp_tab{event_list = [Event | EventList]})
    end,
    {noreply, State, next_timer_out()};

handle_cast({add_instance_player, {InstanceId, {PlayerPid, PlayerId}}}, State) ->
    case ets:lookup(?service_camp_instance, InstanceId) of
        [] -> ets:insert(?service_camp_instance,
            #service_camp_instance{instance_id = InstanceId,
                enemy_player_list = [{PlayerPid, PlayerId}]});
        [ServiceCampInstance] ->
            EnemyPlayerList = ServiceCampInstance#service_camp_instance.enemy_player_list,
            PlayerList = case lists:keyfind(PlayerId, 2, EnemyPlayerList) of
                             false -> [{PlayerPid, PlayerId} | EnemyPlayerList];
                             _ -> lists:keyreplace(PlayerId, 2, EnemyPlayerList, {PlayerPid, PlayerId})
                         end,
            ets:insert(?service_camp_instance,
                #service_camp_instance{instance_id = InstanceId,
                    enemy_player_list = PlayerList})
    end,
    {noreply, State, next_timer_out()};

handle_cast({del_instance_player, {InstanceId, PlayerId}}, State) ->
    case ets:lookup(?service_camp_instance, InstanceId) of
        [] -> ok;
        [ServiceCampInstance] ->
            PlayerList = lists:keydelete(PlayerId, 2, ServiceCampInstance#service_camp_instance.enemy_player_list),
            ets:insert(?service_camp_instance,
                #service_camp_instance{instance_id = InstanceId,
                    enemy_player_list = PlayerList})
    end,
    {noreply, State, next_timer_out()};

handle_cast(_Msg, State) ->
    {noreply, State, next_timer_out()}.

handle_info(timeout, State) ->
    {TimerList, Mng_2} = com_proc_timer:take_timeout_timer(get(?pd_timer_mng_for_camp)),
    put(?pd_timer_mng_for_camp, Mng_2),
    Fun = fun({_TRef, Msg}, State1) ->
        case Msg of
            ?camp_activity ->
                camp_timer_countDown(State1, Msg);
            ?player_refresh_time ->
                camp_timer_countDown(State1, Msg)
        end
    end,
    State2 = lists:foldl(Fun, State, TimerList),
    {noreply, State2, next_timer_out()};

handle_info(_Msg, State) ->
    {noreply, State, next_timer_out()}.

terminate(_Reason, State) ->
    case lookup(?service_camp_tab, ?CAMP_SERVICE_ID) of
        [] -> [];
        [ServiceCamp] ->
            dbcache:update(?service_camp_tab, ServiceCamp#service_camp_tab{is_open = State#state.is_open,
                is_fight = State#state.is_fight,
                server_down_time = com_time:now(),
                god_camp_point = State#state.god_camp_point,
                magic_camp_point = State#state.magic_camp_point
            })
    end.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

ets_new() ->
    ets:new(?service_camp_instance, [?named_table, ?public, {keypos, #service_camp_instance.instance_id}, {?read_concurrency, ?true}, {?write_concurrency, ?true}]).

camp_timer_countDown(State, ?player_refresh_time) ->
    Now = com_time:now(),
    PrivRefreshTime = player_refresh(load_cfg_camp:lookup_cfg(#camp_cfg.refresh_time), Now),
    world:broadcast(?mod_msg(camp_mng, {?player_refresh_time})),
    [ServiceCamp] = lookup(?service_camp_tab, ?CAMP_SERVICE_ID),
    dbcache:update(?service_camp_tab, ServiceCamp#service_camp_tab{priv_refresh_time = PrivRefreshTime}),
    State;

camp_timer_countDown(State, ?camp_activity) ->
    {{Day1, Minite1, Second1}, {Day2, Minite2, Second2}} = load_cfg_camp:lookup_cfg(#camp_cfg.cycle_time),
    [ServiceCamp] = lookup(?service_camp_tab, ?CAMP_SERVICE_ID),
    case State#state.is_fight of
        0 -> %备战结束，进入战斗状态,刷新次数信息
            Count1 = (Day2 * 24 * 60) + (Minite2 * 60) + Second2,
            start_timer(Count1, ?camp_activity),
            EndTime = com_time:now() + Count1,
            dbcache:update(?service_camp_tab, ServiceCamp#service_camp_tab{end_timestamp = EndTime, is_fight = 1}),
            world:broadcast(?to_client_msg(camp_sproto:pkg_msg(?PUSH_TIME_TICK, {}))),
            State#state{is_fight = 1, end_time = EndTime};
        1 -> %战斗结束，进入备战状态
            Count2 = (Day1 * 24 * 60) + (Minite1 * 60) + Second1,
            start_timer(Count2, ?camp_activity),
            EndTime = com_time:now() + Count2,
            dbcache:update(?service_camp_tab, ServiceCamp#service_camp_tab{end_timestamp = EndTime, is_fight = 0}),
            if
                State#state.god_camp_point > State#state.magic_camp_point ->
                    prize(?god_win);
                State#state.god_camp_point =:= State#state.magic_camp_point andalso State#state.god_camp_point =/= 0 ->
                    prize(?tie);
                State#state.god_camp_point < State#state.magic_camp_point ->
                    prize(?magic_win);
                true -> prize(?none)
            end,

            world:broadcast(?to_client_msg(camp_sproto:pkg_msg(?PUSH_TIME_TICK, {}))),
            State#state{is_fight = 0, god_camp_point = 0, magic_camp_point = 0, end_time = EndTime}
    end.

%% 进入副本次数刷新,重置所有在线玩家的进入副本次数
player_refresh(RefreshTime, Now) ->
    NowZero = com_time:zero_clock_timestamp(),
    FunFilter = fun({Day, Minite, Second}) ->
        RefreshEveryTick = NowZero + (Day * 60 * 60) + (Minite * 60) + Second,
        Now < RefreshEveryTick
    end,
    case lists:filter(FunFilter, RefreshTime) of
        [] ->
            {MinHour, MinMin, MinSec} = lists:min(RefreshTime),
            CountDown = com_time:get_seconds_to_next_day(MinHour) + MinMin * 60 + MinSec,
            start_timer(CountDown, ?player_refresh_time),
            CountDown + com_time:now();
        List ->
            {Day1, Minite1, Second1} = hd(List),
            PrivRefreshTime = NowZero + (Day1 * 60 * 60) + (Minite1 * 60) + Second1,
            CountDown = PrivRefreshTime - Now,
            start_timer(CountDown, ?player_refresh_time),
            PrivRefreshTime
    end.

player_priv_refresh_time() ->
    RefreshTime = load_cfg_camp:lookup_cfg(#camp_cfg.refresh_time),
    NowZero = com_time:zero_clock_timestamp(),
    Now = com_time:now(),
    FunFilter = fun({Day, Minite, Second}) ->
        RefreshEveryTick = NowZero + (Day * 60 * 60) + (Minite * 60) + Second,
        Now >= RefreshEveryTick
    end,
    case lists:filter(FunFilter, RefreshTime) of
        [] ->
            {Day1, Minite1, Second1} = lists:last(RefreshTime),
            NowZero + (Day1 * 60 * 60) + (Minite1 * 60) + Second1 - 86400;
        List ->
            {Day1, Minite1, Second1} = lists:last(List),
            NowZero + (Day1 * 60 * 60) + (Minite1 * 60) + Second1
    end.


start_timer(TimeOut, Msg) ->
    {_Ref, NewMng} = com_proc_timer:start_timer(TimeOut * 1000, Msg, get(?pd_timer_mng_for_camp)),
    put(?pd_timer_mng_for_camp, NewMng).

next_timer_out() ->
    com_proc_timer:next_timeout(get(?pd_timer_mng_for_camp)).

prize(Win) ->
    world:broadcast(?mod_msg(camp_mng, {prize, Win})).

lookup(Tab, Key) ->
    dbcache:lookup(Tab, Key).

lookup(Tab, Key, Index) ->
    case dbcache:lookup(Tab, Key) of
        [] -> [];
        [TabInfo] -> element(Index, TabInfo)
    end.





