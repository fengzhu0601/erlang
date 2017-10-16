%%%-------------------------------------------------------------------
%%% @author yujian
%%% @doc 天空之城公共数据
%%%-------------------------------------------------------------------
-module(sky_service).
-behaviour(gen_server).

-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-include_lib("pangzi/include/pangzi.hrl").

-include("inc.hrl").
-include("player.hrl").

-include("sky_struct.hrl").
-include("main_ins_struct.hrl").
-include("rank.hrl").
-include("scene_monster_def.hrl").
-include("timer_manager.hrl").
-export([start_link/0
    , lookup_cfg/1
    , do_open/2, is_open/0, is_box_use/0, get_box_level/0, get_monster_level/0, get_end_time/0
    , add_player/8, select_player/0
    , add_box_kill_info/2, get_box_info/1
]).

load_db_table_meta() ->
    [
        #db_table_meta{name = ?sky_ins_service,
            fields = ?record_fields(?sky_ins_service),
            shrink_size = 30,
            flush_interval = 10}
    ].

-record(state, {is_open = 0,           %功能是否开放 0未开放 1开放
    monster_level = 0,     %怪物难度阶段
    monster_this_level = 1,%怪物该难度阶段下的怪物等级
    is_box_use = 0,        %宝箱是否已经刷新到场景
    box_add_id = hd(?SKY_INS_BOX_MONSTER_IDS),        %宝箱目前Bid
    box_level = 0,         %宝箱目前刷新阶段
    end_time = 0}).        %结束时间

do_open(start, _) -> gen_server:call(?MODULE, {open});
do_open(stop, _) ->
    gen_server:cast(?MODULE, {close}).

is_open() ->
    %case timer_manager:is_open(?timer_sky_service) of
    %    ?FALSE -> ?FALSE;
    %    _ -> ?TRUE
    %end.
    ?FALSE.

get_box_level() ->
    gen_server:call(?MODULE, {get_box_level}).

is_box_use() ->
    gen_server:call(?MODULE, {is_box_use}).

get_monster_level() ->
    gen_server:call(?MODULE, {get_monster_level}).

get_end_time() ->
    gen_server:call(?MODULE, {get_end_time}).

add_player(PdId, PdPid, PdLv, PdCareer, PdPower, PdCamp, SceneId, IsMatch) ->
    gen_server:call(?MODULE, {add_player, PdId, PdPid, PdCareer, PdLv, PdPower, PdCamp, SceneId, IsMatch}).

select_player() ->
    Lv = get(?pd_level),
    SelfCamp = get(?pd_camp_self_camp),
    Match = [{#sky_ins_player_info{player_id = '$1', player_pid = '_',
        player_level = '$2', player_power = '_', player_camp = '$3',
        scene_id = '$4', is_match = '$5'},
        [{'andalso', {'=:=', '$5', 1},
            {'andalso', {'>=', {'-', {const, Lv}, 5}, '$2'},
                {'andalso', {'=<', {'+', {const, Lv}, 5}, '$2'},
                    {'=/=', '$3', {const, SelfCamp}}}}}],
        [{{'$1', '$4'}}]}],

    case ets:match(?sky_ins_player_info, Match, 1) of
        '$end_of_table' ->
            Power = get(?pd_combat_power),
            Match1 = [{#sky_ins_player_info{player_id = '_', player_pid = '$1',
                player_level = '_', player_power = '$2', player_camp = '$3',
                scene_id = '$4', is_match = '$5'},
                [{'andalso', {'=:=', '$5', 1},
                    {'andalso', {'>=', {'-', {const, Power}, 5000}, '$2'},
                        {'andalso', {'=<', {'+', {const, Power}, 5000}, '$2'},
                            {'=/=', '$3', {const, SelfCamp}}}}}],
                [{{'$1', '$4'}}]}],
            ets:match(?sky_ins_player_info, Match1, 1)
    end.

add_box_kill_info(BoxBid, BoxDrop) ->
    ets:insert(?sky_ins_kill_box, #sky_ins_kill_box{box_bid = BoxBid, player_career = get(?pd_career), player_id = get(?pd_id), player_name = get(?pd_name), player_level = get(?pd_level), box_drop = BoxDrop}).

get_box_info(BoxBid) ->
    ets:lookup(?sky_ins_kill_box, BoxBid).

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

init([]) ->
    put(?pd_sky_ins_timer, com_proc_timer:new()),
    ets_new(),
    Now = com_time:now(),
    %IsOpen = timer_manager:is_open(?timer_sky_service),
    IsOpen = ?FALSE,
    NewState =
        case IsOpen of
            ?FALSE ->
                #state{is_open = 0, end_time = 86400 + Now};
            {?TRUE, STime, ETime} ->
                {box_change, {D1, M1, S1}, Level} = lookup_cfg(#sky_ins_cfg.box_change),
                BoxRefreshTime = ?SKY_INS_SUM_TIME(D1, M1, S1),
                BoxLevel = (Now - STime) div BoxRefreshTime,
                start_timer(BoxRefreshTime - (Now - STime) rem BoxRefreshTime, ?tick_sky_ins_box_level),

                {monster_change, {D2, M2, S2}, Level2} = lookup_cfg(#sky_ins_cfg.monster_change),
                MonsterRefreshTime = ?SKY_INS_SUM_TIME(D2, M2, S2),
                MonsterLevel = (Now - STime) div MonsterRefreshTime,
                start_timer(MonsterRefreshTime - (Now - STime) rem MonsterRefreshTime, ?tick_sky_ins_monster_level),

                dbcache:update(?sky_ins_service, #sky_ins_service{is_open = 1, end_timestamp = ETime}),

                MonsterThisLevel = ?SKY_INS_DEFAULT_MONSTER_LV + MonsterLevel * Level2,

                MonsterLevelState =
                    if
                        MonsterThisLevel > ?monster_max_level -> ?monster_max_level;
                        true -> MonsterThisLevel
                    end,
                #state{is_open = 1, box_level = BoxLevel, box_add_id = hd(?SKY_INS_BOX_MONSTER_IDS) + BoxLevel * Level, monster_level = MonsterLevel,
                    monster_this_level = MonsterLevelState, end_time = ETime}
        end,
    {ok, NewState, 0}.

handle_call({get_monster_level}, _From, State) ->
    MonsterLevel = State#state.monster_this_level,
    {reply, MonsterLevel, State, next_timer_out()};

handle_call({get_box_level}, _From, State) ->
    BoxLevel = State#state.box_level,
    {reply, BoxLevel, State, next_timer_out()};

handle_call({is_box_use}, _From, State) ->
    BoxBid = case State#state.is_box_use of
                 0 -> State#state.box_add_id;
                 1 -> 0
             end,
    {reply, BoxBid, State#state{is_box_use = 1}, next_timer_out()};

handle_call({add_player, PlayerId, PlayerPid, PlayerCareer, PlayerLv, PlayerPower, PlayerCamp, SceneId, IsMatch}, _From, State) ->
    ets:insert(?sky_ins_player_info, #sky_ins_player_info{player_id = PlayerId, player_pid = PlayerPid, player_career = PlayerCareer, player_level = PlayerLv, player_power = PlayerPower, player_camp = PlayerCamp, scene_id = SceneId, is_match = IsMatch}),
    {reply, ok, State, next_timer_out()};

handle_call({open}, _From, State) ->
    NewState = open(State),
    {reply, ok, NewState, next_timer_out()};

handle_call({get_end_time}, _From, State) ->
    EndTime = State#state.end_time,
    {reply, EndTime, State, next_timer_out()};

handle_call(_Request, _From, State) ->
    {reply, ok, State, next_timer_out()}.

handle_cast({close}, State) ->
    NewState = close(State),
    {noreply, NewState, next_timer_out()};

handle_cast(_Msg, State) ->
    {noreply, State, next_timer_out()}.

handle_info(timeout, State) ->
    {TimerList, Mng_2} = com_proc_timer:take_timeout_timer(get(?pd_sky_ins_timer)),
    put(?pd_sky_ins_timer, Mng_2),
    Fun = fun({_TRef, Msg}, State1) -> timer_count_down(State1, Msg) end,
    State2 = lists:foldl(Fun, State, TimerList),
    {noreply, State2, next_timer_out()};

handle_info(_Msg, State) ->
    {noreply, State, next_timer_out()}.

terminate(_Reason, State) ->
    case lookup(?sky_ins_service, ?sky_ins_service_key) of
        [] -> [];
        [SkyInsService] ->
            dbcache:update(?sky_ins_service, SkyInsService#sky_ins_service{is_open = State#state.is_open, end_timestamp = State#state.end_time})
    end.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

ets_new() ->
    ets:new(?sky_ins_player_info, [?named_table, ?public, {keypos, #sky_ins_player_info.player_id}, {?read_concurrency, ?true}, {?write_concurrency, ?true}]),
    ets:new(?sky_ins_kill_box, [?named_table, ?public, {keypos, #sky_ins_kill_box.box_bid}, {?read_concurrency, ?true}, {?write_concurrency, ?true}]).

start_timer(TimeOut, Msg) ->
    {_Ref, NewMng} = com_proc_timer:start_timer(TimeOut * 1000, Msg, get(?pd_sky_ins_timer)),
    put(?pd_sky_ins_timer, NewMng).

next_timer_out() ->
    com_proc_timer:next_timeout(get(?pd_sky_ins_timer)).

lookup_cfg(Index) ->
    lists:nth(Index - 1, misc_cfg:get_misc_cfg(sky_ins_info)).

lookup(Tab, Key) ->
    dbcache:lookup(Tab, Key).

open(State) ->
    ZeroTime = com_time:zero_clock_timestamp(),
    [_, {Day1, Minite1, Second1}] = lookup_cfg(#sky_ins_cfg.open_time),
    {box_change, {D1, M1, S1}, _} = lookup_cfg(#sky_ins_cfg.box_change),
    {monster_change, {D2, M2, S2}, _} = lookup_cfg(#sky_ins_cfg.monster_change),
    ETime = ZeroTime + ?SKY_INS_SUM_TIME(Day1, Minite1, Second1),
    start_timer(?SKY_INS_SUM_TIME(D1, M1, S1), ?tick_sky_ins_box_level),
    start_timer(?SKY_INS_SUM_TIME(D2, M2, S2), ?tick_sky_ins_monster_level),
    ranking_lib:reset_rank(?ranking_sky_ins_kill_monster),
    ranking_lib:reset_rank(?ranking_sky_ins_kill_player),
    ets:delete_all_objects(?sky_ins_kill_box),
    State#state{is_open = 1, end_time = ETime}.

close(_State) ->
    ranking_lib:flush_rank_by_rankname(?ranking_sky_ins_kill_player), %刷新排行榜，发放排行奖励
    ranking_lib:flush_rank_by_rankname(?ranking_sky_ins_kill_monster), %刷新排行榜，发放排行奖励
    timer:sleep(5000),%进程休眠5秒，等待排行榜刷新数据
    prize(),
    ets:delete_all_objects(?sky_ins_player_info),
    #state{is_open = 0, end_time = 86400 + virtual_time:now()}.
%%
%% timer_count_down(State, ?tick_sky_ins_activity_open) ->
%%     case State#state.is_open of
%%         1 -> %活动结束
%%             ZeroTime = com_time:zero_clock_timestamp(),
%%             [{Day1, Minite1, Second1}, _] = lookup_cfg(#sky_ins_cfg.open_time),
%%             STime = ZeroTime+?SKY_INS_SUM_TIME(Day1,Minite1,Second1),
%%             Now = com_time:now(),
%%             start_timer(86400+STime-Now, ?tick_sky_ins_activity_open),
%%             ranking_lib:flush_rank_(?ranking_sky_ins_kill_player), %刷新排行榜，发放排行奖励
%%             ranking_lib:flush_rank_(?ranking_sky_ins_kill_monster), %刷新排行榜，发放排行奖励
%%             timer:sleep(5000),%进程休眠5秒，等待排行榜刷新数据
%%             prize(),
%%             ets:delete_all_objects(?sky_ins_player_info),
%%             #state{end_time=86400+STime};
%%         0 ->
%%             ZeroTime = com_time:zero_clock_timestamp(),
%%             [_, {Day1, Minite1, Second1}] = lookup_cfg(#sky_ins_cfg.open_time),
%%             {box_change, {D1, M1, S1}, _} = lookup_cfg(#sky_ins_cfg.box_change),
%%             {monster_change, {D2, M2, S2}, _} = lookup_cfg(#sky_ins_cfg.monster_change),
%%             ETime = ZeroTime+ ?SKY_INS_SUM_TIME(Day1,Minite1,Second1),
%%             Now = com_time:now(),
%%             start_timer(ETime-Now, ?tick_sky_ins_activity_open),
%%             start_timer(?SKY_INS_SUM_TIME(D1,M1,S1), ?tick_sky_ins_box_level),
%%             start_timer(?SKY_INS_SUM_TIME(D2,M2,S2), ?tick_sky_ins_monster_level),
%%             ranking_lib:reset_rank(?ranking_sky_ins_kill_monster),
%%             ranking_lib:reset_rank(?ranking_sky_ins_kill_player),
%%             ets:delete_all_objects(?sky_ins_kill_box),
%%             State#state{is_open=1, end_time=ETime}
%%     end;

timer_count_down(State, ?tick_sky_ins_box_level) ->
    case State#state.is_open of
        0 -> State;
        1 ->
            BoxLevel = State#state.box_level,
            ZeroTime = com_time:zero_clock_timestamp(),
            [{Day1, Minite1, Second1}, _] = lookup_cfg(#sky_ins_cfg.open_time),
            STime = ZeroTime + ?SKY_INS_SUM_TIME(Day1, Minite1, Second1),
            Now = com_time:now(),
            {box_change, {D1, M1, S1}, Bid} = lookup_cfg(#sky_ins_cfg.box_change),
            BoxRefreshTime = ?SKY_INS_SUM_TIME(D1, M1, S1),
            start_timer(BoxRefreshTime - (Now - STime) rem BoxRefreshTime, ?tick_sky_ins_box_level),
            BoxThisBid = State#state.box_add_id + Bid,
            MaxBoxBid = lists:last(?SKY_INS_BOX_MONSTER_IDS),
            BoxLevelState =
                if
                    BoxThisBid > MaxBoxBid -> MaxBoxBid;
                    true -> BoxThisBid
                end,
            State#state{box_level = BoxLevel + 1, is_box_use = 0, box_add_id = BoxLevelState}
    end;

timer_count_down(State, ?tick_sky_ins_monster_level) ->
    case State#state.is_open of
        0 -> State;
        1 ->
            MonsterLevel = State#state.monster_level,
            ZeroTime = com_time:zero_clock_timestamp(),
            [{Day1, Minite1, Second1}, _] = lookup_cfg(#sky_ins_cfg.open_time),
            STime = ZeroTime + ?SKY_INS_SUM_TIME(Day1, Minite1, Second1),
            Now = com_time:now(),
            {monster_change, {D1, M1, S1}, Level} = lookup_cfg(#sky_ins_cfg.monster_change),
            MonsterRefreshTime = ?SKY_INS_SUM_TIME(D1, M1, S1),
            start_timer(MonsterRefreshTime - (Now - STime) rem MonsterRefreshTime, ?tick_sky_ins_monster_level),
            MonsterThisLevel = State#state.monster_this_level + Level,
            MonsterLevelState =
                if
                    MonsterThisLevel > ?monster_max_level -> ?monster_max_level;
                    true -> MonsterThisLevel
                end,
            State#state{monster_level = MonsterLevel + 1, monster_this_level = MonsterLevelState}
    end.

prize() ->
    world:broadcast(?mod_msg(sky_mng, {activity_complete})).