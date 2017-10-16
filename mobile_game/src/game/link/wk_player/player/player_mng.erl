%%%-------------------------------------------------------------------
%%% @author zl
%%% @doc
%%%
%%% @end
%%%-------------------------------------------------------------------

-module(player_mng).

-include("inc.hrl").
-include("player.hrl").
-include("scene.hrl").
-include("player_mod.hrl").
-include("rank.hrl").
-include("player_data_db.hrl").
-include("day_reset.hrl").
-include("load_spirit_attr.hrl").
-include("payment.hrl").
-include("team.hrl").
-include("system_log.hrl").
-include("achievement.hrl").
-export
([
    add_sp_offline/0,
    bless_add_buff_after/2,
    task_mount_after/1,
    add_offline_hourly_sp/0,
    start_sp_timer/1
    %%,push_share_game_state/0
]).

%% direct
create_mod_data(_SelfId) -> ok.
load_mod_data(_PlayerId) -> ok.


init_client() -> ok.

view_data(Pkg) -> Pkg.

-define(SP_TICK_TIME, element(3, misc_cfg:get_misc_cfg(sp_info))).
-define(TICK_ADD_SP, element(2, misc_cfg:get_misc_cfg(sp_info))).   %% 隔多少秒增加多少体力
-define(SAVE_DATA_TICK, 10).
-define(SAVE_PLAYER_DATA_TO_MYSQL, 300 + (random:uniform(60))).
%-define(SAVE_PLAYER_DATA_TO_MYSQL, 3).


-define(save_player_data_to_mysql, save_player_data_to_mysql).
-define(savedata_to_mysql_timerref, savedata_to_mysql_timerref).
-define(savedata_to_mnesia_timerref, savedata_to_mnesia_timerref).
-define(back_strength_timerref, back_strength_timerref).
-define(save_data_tick, save_data_tick).


-define(add_buff_after, add_buff_after).
-define(add_buff_after_timerref, add_buff_after_timerref).

-define(task_mount_after, task_mount_after).
-define(task_mount_after_timerref, task_mount_after_timerref).

-define( hourly_add_sp, hourly_add_sp ).
-define( lunch_notice, lunch_notice).
-define( dinner_notice, dinner_notice).
-define( HOURLY_SP, 50).
-define( START_TIME,calendar:datetime_to_gregorian_seconds({{1970, 1, 1}, {0, 0, 0}}) ).

-define(CANCEL_SENDAFTER_LIST,
    [
        ?savedata_to_mysql_timerref,
        ?savedata_to_mnesia_timerref,
        ?back_strength_timerref,
        hourly_add_sp_lunch_start_timerref_12,
        hourly_add_sp_dinner_start_timerref_18,
        hourly_add_sp_lunch_over_timerref_12,
        hourly_add_sp_dinner_over_timerref_18
    ]).

bless_add_buff_after(Time, BuffId) ->
    tool:do_send_after(Time,
        ?mod_msg(?MODULE, {?add_buff_after, BuffId}),
        ?add_buff_after_timerref).


task_mount_after(Time) ->
    tool:do_send_after(Time,
        ?mod_msg(?MODULE, ?task_mount_after),
        ?task_mount_after_timerref).

%% 整点加体力
start_hourly_timer() ->
    %% 从现在到当天12点和18点的秒数
    {_, Time} = calendar:local_time(),
    {{LunchStart,LunchEnd,_LunchSp},{DinnerStart,DinnerEnd,_DinnerSp}} = misc_cfg:get_sp_time(),
    Time12 = calendar:time_to_seconds(LunchStart) - calendar:time_to_seconds(Time),
    Time18 = calendar:time_to_seconds(DinnerStart) - calendar:time_to_seconds(Time),
    Time12Over = calendar:time_to_seconds(LunchEnd) - calendar:time_to_seconds(Time),
    Time18Over = calendar:time_to_seconds(DinnerEnd) - calendar:time_to_seconds(Time),
    if
        Time12 >= 0 ->
            tool:do_send_after(Time12 * 1000,
                ?mod_msg(?MODULE, {hourly_add_sp_lunch_start}),
                hourly_add_sp_lunch_start_timerref_12
            );
        true ->
            pass
    end,
    if
        Time18 >= 0 ->
            tool:do_send_after(Time18 * 1000,
                ?mod_msg(?MODULE, {hourly_add_sp_dinner_start}),
                hourly_add_sp_dinner_start_timerref_18
            );
        true ->
            pass
    end,
    if
        Time12Over >= 0 ->
            tool:do_send_after(Time12Over * 1000,
                ?mod_msg(?MODULE, {hourly_add_sp_lunch_over}),
                hourly_add_sp_lunch_over_timerref_12
            );
        true ->
            pass
    end,
    if
        Time18Over >= 0 ->
            tool:do_send_after(Time18Over * 1000,
                ?mod_msg(?MODULE, {hourly_add_sp_dinner_over}),
                hourly_add_sp_dinner_over_timerref_18
            );
        true ->
            pass
    end.

online() ->
    %?DEBUG_LOG("online-----------------------------------"),
    start_frame_timer(),
    tool:do_send_after(?MICOSEC_PER_SECONDS * ?SAVE_DATA_TICK,
        ?mod_msg(?MODULE, ?save_data_tick),
        ?savedata_to_mnesia_timerref),
    tool:do_send_after(?MICOSEC_PER_SECONDS * ?SAVE_PLAYER_DATA_TO_MYSQL,
        ?mod_msg(?MODULE, ?save_player_data_to_mysql),
        ?savedata_to_mysql_timerref),
    start_hourly_timer(),
    timer_trigger_server:pack_activity(),
    double_prize_server:pack_double_prize_activity(),
    ?ifdo(player:is_daliy_first_online() =:= ?false, put(?pd_sp_buy_count, 0)),

    HourlySpStatus = get_in_hourly_sp_time_status(),
    ?player_send(player_sproto:pkg_msg(?MSG_PLAYER_PUSH_HOURLY_SP_STATUS, {HourlySpStatus})),
    ok.

offline(PlayerId) ->
    RemainTime = tool:get_remain_of_timer(?back_strength_timerref),
    RRemainTime =
        case erlang:is_integer(RemainTime) of
            true ->
                RemainTime;
            _ ->
                0
        end,

    erlang:put(?pd_last_logout_time, com_time:now()),

    NewRemainTime = RRemainTime div 1000,
    util:set_pd_field(?pd_remain_sp_time, NewRemainTime),
    LastOnlineTotalTime = attr_new:get(?pd_online_total_time, 0),
    op_player:update_player_data(PlayerId,
        get(?pd_name),
        get(?pd_exp), get(?pd_level),
        attr_new:get_vip_lvl(), get(?pd_combat_power),
        get(?pd_money), get(?pd_diamond)),
    attr_new:set(?pd_online_total_time, LastOnlineTotalTime + player:get_online_passed_time()),

    tool:cancel_sendafter(?CANCEL_SENDAFTER_LIST),
    ok.

save_data(_PlayerId) ->
    %% TODO 重新计算
    ok.

on_day_reset(_Player) ->
%%    ?DEBUG_LOG("sp buy count rest"),
    Val = attr_new:get(?pd_sp_buy_count, 0),
    attr_new:begin_sync_attr(),
    attr_new:set(?pd_sp_buy_count, -Val),
    attr_new:end_sync_attr(),
    util:set_pd_field(?pd_hourly_sp_lunch, 0),
    util:set_pd_field(?pd_hourly_sp_dinner, 0),
    %% util:set_pd_field(?pd_share_game_status, 0),
    %% util:set_pd_field(?pd_prize_share_game_status, 0),
    %% push_share_game_state(),

    start_hourly_timer(),
%%    put(?pd_sp_buy_count, 0),
%%    Fields = [{?pd_sp_buy_count, 0}],
%%    Root = player_prop_zip_key:get_zip_keys_data_ex(#zip_keys_data{}, Fields),
%%    ?DEBUG_LOG("send message:~p",[Root]),
%%    {[_Data1, Data]} = player_prop_zip_key:get_final_ret(Root),
%%    ?DEBUG_LOG("send message:~p",[Data]),
%%    Msg = player_sproto:pkg_msg(?MSG_PLAYER_FIELD_CHANGE, {[Data]}),
%%    ?DEBUG_LOG("send message:~p",[Msg]),
%%    ?player_send(Msg),
    ok.

%% handle_frame(?frame_zero_clock) ->
%%     put(?pd_sp_buy_count, 0);

handle_frame(?frame_update_rank) ->
    %?DEBUG_LOG("update --------------- rank"),

    Id = get(?pd_id),
    %%Level = get(?pd_level),
    ZhanLi = get(?pd_combat_power),
    %FScore = friend_mng:get_friend_score(Id),

    % case get(?pd_career) of
    %     ?C_ZS -> ranking_lib:update(?ranking_career_1_power, Id, ZhanLi);
    %     ?C_FS -> ranking_lib:update(?ranking_career_2_power, Id, ZhanLi);
    %     ?C_SS -> ranking_lib:update(?ranking_career_3_power, Id, ZhanLi);
    %     ?C_QS -> ranking_lib:update(?ranking_career_4_power, Id, ZhanLi);
    %     _ -> ok
    % end,
    %ranking_lib:update(?ranking_zhanli, Id, ZhanLi);
    rank_mng:listen_power(Id, ZhanLi),
    rank_mng:listen_lev(Id, get(?pd_level)),
    %rank_mng:listen_friend_score(Id, FScore),
    ok;

handle_frame({?frame_levelup, _OldLevel}) ->
    Level = get(?pd_level),
    task_open_fun:level_trigger_1(Level),
    ok;

%% TODO
handle_frame(_) ->
    player_base_data:save_data(get(?pd_id)),
    ok.


handle_msg(_FromMod, {?msg_killed_by_agent, KIdx, _KId}) ->
    event_eng:post(?ev_died, killed),
    if
        KIdx < 0 ->
            %?DEBUG_LOG("achievement_mng-----------------------------"),
            achievement_mng:do_ac(?sierhousheng);
        true ->
            pass 
    end,
    % %% @doc 人物在战斗中死亡，如果宠物在战斗状态减少该宠物默契度
    % try pet_mng:player_die() of
    %     _ -> ok
    % catch
    %     _Catch:_Why -> ok
    % end,
    % buff_mng:remove_all_buffs_when_die(),
    erlang:put(?pd_is_die, true),
    is_notify_teammate(0),
    ?debug_log_player("player ~p die ~p", [?pname(), _KId]);

handle_msg(_FromMod, {?msg_killed_by_device}) ->
    event_eng:post(?ev_died, killed),
    %%buff_mng:remove_all_buffs_when_die(),
    erlang:put(?pd_is_die, true),
    ?debug_log_player("player ~p die by device", [?pname()]);

handle_msg(_FromMod, {?msg_kill_player, _KilledPlayerId}) ->
    todo;

handle_msg(_FromMod, {team_fuben_kill_monster, MonsterId}) ->
    daily_task_tgr:do_daily_task({?ev_kill_monster, 0}, 1),
    daily_task_tgr:do_daily_task({?ev_kill_monster, MonsterId}, 1);

%% handle_msg(_FromMod, {?msg_kill_monster, KilledMonsterCfgId}) ->
%%     event_eng:post(?ev_kill_monster, KilledMonsterCfgId);

handle_msg(_FromMod, {?ev_kill_monster, KilledMonsterCfgId, Count}) ->
    ?debug_log_player("killmonser ~p", [KilledMonsterCfgId]),
    event_eng:post(?ev_kill_monster, {?ev_kill_monster, KilledMonsterCfgId}, Count);

handle_msg(_FromMod, {?ev_kill_monster_by_bid, Key, Count}) ->
    event_eng:post(?ev_kill_monster_by_bid, {?ev_kill_monster_by_bid, Key}, Count);

handle_msg(_FromMod, {?ev_kill_boss, Key, Count}) ->
    event_eng:post(?ev_kill_boss, {?ev_kill_boss, Key}, Count);

handle_msg(_FromMod, {?msg_relive, _SceneId, _X, _Y}) ->
    todo;

handle_msg(_FromMod, {?msg_game_frame, Frame}) ->
    [Mod:handle_frame(Frame) || Mod <- ?all_player_eng_mods()],
    [Mod:handle_frame(Frame) || Mod <- ?all_player_logic_mods()],
    start_frame_timer(Frame),
    ok;


handle_msg(_FromMod, {?msg_kill_monster_add_exp, Exp}) ->
    ?debug_log_player("kill mon add exp ~w", [Exp]),
    player:add_exp(Exp);
%%     event_eng:post(?ev_kill_monster_exp_addition, Exp);

handle_msg(_FromMod, {?msg_add_item, ItemList, Reason}) ->
    game_res:try_give_ex(ItemList, Reason);

handle_msg(_FromMod, {cmd_set_level, Lev}) ->
    gm_mng:set_lev(Lev);

handle_msg(_FromMod, {cmd_set_money, Money}) ->
    gm_mng:add_res([{?PL_MONEY, Money}]);

handle_msg(_FromMod, {cmd_add_something, ItemBid, ItemCount}) ->
    gm_mng:add_res([{ItemBid, ItemCount}]);

%奖励物品组ID的消息
% handle_msg(_FromMod, {?msg_add_prize, PrizeId}) ->
%     prize:prize(PrizeId);


handle_msg(_, {?msg_kickout, FromPid}) ->
    ?INFO_LOG("revice msg_kickout ~p", [self()]),
    ?player_send(player_sproto:pkg_msg(?MSG_PLAYER_OFFLINE_INFO, {?OFFLINE_KICKOUT_MSG})),
    gen_tcp:close(get(?pd_socket)),
    account:uninit(?TRUE),
    FromPid ! ?offline_ok,
    {'@offline@', ?msg_kickout};


%% TODO
%%handle_msg(?MODULE, {?game_frame, F}) ->
%%[Mod:handle_frame(F) || Mod <- ?all_player_mods()],
%%start_frame_timer(F);

handle_msg(_, {?add_buff_after, BuffId}) ->
    ?DEBUG_LOG("add_buff_after-----------------------------:~p",[BuffId]),
    blessing_tgr:update_task_bless_buff(BuffId),
    equip_buf:take_off_buf2(BuffId);

handle_msg(_, ?task_mount_after) ->
    case get(?pd_task_mount_time) of
        ?undefined ->
            pass;
        {MountId, _} ->
            put(?pd_task_mount_time, {0,0}),
            ride_mng:getoff_ride(MountId),
            ?player_send(player_sproto:pkg_msg(?MSG_PlAYER_RIDE, {0}))
    end;

handle_msg(_, {hourly_add_sp_lunch_start}) ->
    ?player_send(player_sproto:pkg_msg(?MSG_PLAYER_PUSH_HOURLY_SP_STATUS, {0}));

handle_msg(_, {hourly_add_sp_dinner_start}) ->
    ?player_send(player_sproto:pkg_msg(?MSG_PLAYER_PUSH_HOURLY_SP_STATUS, {0}));

handle_msg(_, {hourly_add_sp_lunch_over}) ->
    ?player_send(player_sproto:pkg_msg(?MSG_PLAYER_PUSH_HOURLY_SP_STATUS, {2}));

handle_msg(_, {hourly_add_sp_dinner_over}) ->
    ?player_send(player_sproto:pkg_msg(?MSG_PLAYER_PUSH_HOURLY_SP_STATUS, {2}));

handle_msg(_, ?pd_sp) ->
    sp_timer();

handle_msg(_, ?save_data_tick) ->
    player_mods_manager:save_data(get(?pd_id)),
    tool:do_send_after(?MICOSEC_PER_SECONDS * ?SAVE_DATA_TICK,
        ?mod_msg(?MODULE, ?save_data_tick),
        ?savedata_to_mnesia_timerref);

handle_msg(_, ?save_player_data_to_mysql) ->
    %?DEBUG_LOG("save_player_data_to_mysql---------------------------------------"),
    op_player:update_player_data(get(?pd_id),
        get(?pd_name),
        get(?pd_exp), get(?pd_level),
        attr_new:get_vip_lvl(), get(?pd_combat_power),
        get(?pd_money), get(?pd_diamond)),
    tool:do_send_after(?MICOSEC_PER_SECONDS * ?SAVE_PLAYER_DATA_TO_MYSQL,
        ?mod_msg(?MODULE, ?save_player_data_to_mysql),
        ?savedata_to_mysql_timerref);

handle_msg(_, {update_order, {Billno, Index, State}}) ->
    if
        State =:= ?PAYMENT_ORDER_STATE_SUCCESS ->
            if
                Index > 0 ->
                    %pay_goods_part:give_diamond_card(Index, Billno);
                    vip_new_mng:do_cost_total_rmb(Index, 1),
                    vip_new_mng:qq_pay_send_prize(Index);
                true ->
                    %charge_reward_part:give_growup_prize(abs(Index), Billno)
                    pass
            end;
        true -> 
            ok
    end,
    player_data_db:update_order_by_id(Billno, State);

handle_msg(_, {is_notify_teammate, Hp}) ->
    is_notify_teammate(Hp);

handle_msg(F, Msg) ->
    ?ERROR_LOG("unknow msg ~p ~p", [F, Msg]).

is_notify_teammate(Hp) ->
    PlayerId = get(?pd_id),
    case team_server:get_team_info(PlayerId, ?TEAM_TYPE_MAIN_INS) of
        {ok, TeamInfo} ->
            Members = TeamInfo#team_info.members,
            MapHp = attr_new:get_attr_item(?pd_attr_max_hp),
            Msg = main_instance_sproto:pkg_msg(?MSG_MAIN_INSTANCE_MEMBERS_INFO, {PlayerId, Hp, MapHp, get(?pd_level)}),
            main_ins_team_mod:members_notify(Members, ?to_client_msg(Msg));
        _ ->
            case team_svr:get_team_info_by_player(PlayerId) of
                T when T =/= ?none ->
                    MapHp = attr_new:get_attr_item(?pd_attr_max_hp),
                    Msg = main_instance_sproto:pkg_msg(?MSG_MAIN_INSTANCE_MEMBERS_INFO, {PlayerId, Hp, MapHp, get(?pd_level)}),
                    gongcheng_mng:notice_members(T, ?to_client_msg(Msg));
                _E ->
                    ignore
            end
    end.

%%%% TODO send to timer proces
start_frame_timer() ->
    %% AllF = [?frame_flush_data, ?frame_update_rank],
    AllF = [?frame_update_rank],
    [start_frame_timer(F) || F <- AllF],
    ok.

start_frame_timer(?frame_update_rank = F) ->
    ?send_after_self(1000 * 30, ?mod_msg(player_mng, {?msg_game_frame, F}));

%%start_frame_timer(?frame_flush_data=F) ->
%%    ?send_after_self(3000, ?mod_msg(player_mng, {?msg_game_frame, F}));

start_frame_timer(F) ->
    ?ERROR_LOG("unknown frame ~p", [F]).


%% 体力计时器, 每隔30分钟回复1sp，上限大于等于200点
sp_timer() ->
    SP = attr_new:get(?pd_sp),

    %% 体力上线根据玩家VIP
    Vip = get(?pd_vip),
    SpMaxNum = load_vip_new:get_sp_limit_by_vip_level(Vip),
    AddSp = ?TICK_ADD_SP,
    if
        SP >= SpMaxNum ->
            ok;
        true ->
            if
                (SP + AddSp) >= SpMaxNum ->
                    attr_new:begin_sync_attr(),
                    attr_new:set(?pd_sp, (attr_new:get(?pd_sp) * (-1))),
                    attr_new:set(?pd_sp, SpMaxNum),
                    attr_new:end_sync_attr();
                true ->
                    player:add_value(?pd_sp, ?TICK_ADD_SP)
            end
    end,

    % timer_eng:start_tmp_timer(?pd_sp, ?MICOSEC_PER_SECONDS * (?pd_sp_tick_time), ?MODULE, {?pd_sp}).

    TimeStamp = ?SP_TICK_TIME + com_time:now(),
    ?player_send(player_sproto:pkg_msg(?MSG_PLAYER_SP_REFRESH_TIME, {TimeStamp})),
        tool:do_send_after(?MICOSEC_PER_SECONDS * ?SP_TICK_TIME,
            ?mod_msg(?MODULE, ?pd_sp),
            ?back_strength_timerref).

%% 玩家离线增加体力 @fengzhu
add_sp_offline() ->
    case erlang:get(?pd_last_logout_time) of
        0 ->
            ?INFO_LOG("第一次定时器"),
            start_sp_timer(?SP_TICK_TIME);
        OfflineTime ->
            NowTime = util:get_now_second(0),
            DTime = NowTime - OfflineTime + util:get_pd_field(?pd_remain_sp_time, 0),

            %% 修改服务器时间后可能Time < 0
            Time =
                if
                    DTime < 0 ->
                        0;
                    true ->
                        DTime
                end,
            TickTime = ?SP_TICK_TIME,
            TickAddSp = ?TICK_ADD_SP,
            Num = Time div TickTime,
            RemainTime = Time rem TickTime,
            try_add_sp(Num * TickAddSp),
            start_sp_timer(RemainTime)
    end.

try_add_sp(SP) ->
    attr_new:begin_sync_attr(),
    %% 玩家原来的体力值
    SP_Old = attr_new:get(?pd_sp),

    %% 玩家下线恢复后的体力值
    attr_new:set(?pd_sp, SP),
    SP_New = attr_new:get(?pd_sp),
    %% %% 体力上线根据玩家等级设置,
    %% SpMaxNum = ?pd_sp_max_num,
    %% 现在自然回复体力上限根据玩家vip来设置
    Vip = get(?pd_vip),
    SpMaxNum = load_vip_new:get_sp_limit_by_vip_level(Vip),
    if
        SP_Old >= SpMaxNum ->           % 玩家体力原来大于最大体力
            attr_new:set(?pd_sp, (attr_new:get(?pd_sp) * (-1))),
            attr_new:set(?pd_sp, SP_Old),
            %% erlang:put(?pd_sp, SP_Old),
            ok;
        SP_New >= SpMaxNum ->           % 玩家下线恢复体力后不能大于最大体力
            attr_new:set(?pd_sp, (attr_new:get(?pd_sp) * (-1))),
            attr_new:set(?pd_sp, SpMaxNum),
            %% erlang:put(?pd_sp, SpMaxNum),
            ok;
        true ->
            ok
    end,
    attr_new:end_sync_attr().

%% 玩家增加离线整点获得的体力
add_offline_hourly_sp() ->
    case erlang:get(?pd_last_logout_time) of
        0 ->
            ok;
        OfflineTime ->
            Offtime = com_time:timestamp_msec2now(OfflineTime * 1000),
            {{OffY,OffM,OffD},{OffH, OffMin, OffS}} = calendar:now_to_local_time(Offtime),
            %% 离线时间转换成日期
            {{Y,M,D},{H,Min,S}} = calendar:local_time(),
            {Day, _} = calendar:time_difference({{OffY,OffM,OffD},{OffH, OffMin, OffS}}, {{Y,M,D},{H,Min,S}}),

            %% 判断是否是同一天
            AddSp =
                case com_time:is_same_day({{OffY,OffM,OffD},{OffH, OffMin, OffS}}, {{Y,M,D},{H,Min,S}}) of
                    true ->
                        get_sp_thisday({OffH, OffMin, OffS}, {H,Min,S}) * ?HOURLY_SP;
                    _ ->
                        (get_sp_by_offline({OffH,OffMin,OffS}) + get_sp_by_online({H,Min,S}) + Day*2) * ?HOURLY_SP
                end,
            try_add_sp(AddSp)
            %% attr_new:begin_sync_attr(),
            %% attr_new:set(?pd_sp, AddSp),
            %% attr_new:end_sync_attr()
    end.

get_sp_by_offline({H, _Min, _S}) ->
    if
        H =< 12 ->
            2;
        H =< 18 ->
            1;
        true ->
            0
    end.

get_sp_by_online({H, _Min, _S}) ->
    if
        H >= 18 ->
            2;
        H >= 12 ->
            1;
        true ->
            0
    end.

get_sp_thisday({Hoff,_,_},{Hon,_,_}) when Hoff =< Hon ->
    if
        Hoff =< 12 ->
            if
                Hon =< 12 ->
                    0;
                Hon =< 18 ->
                    1;
                true ->
                    2
            end;
        Hoff =< 18 ->
            if
                Hon =< 18 ->
                    0;
                true ->
                    1
            end;
        true ->
            0
    end;

get_sp_thisday({_Hoff,_,_},{_Hon,_,_}) ->
    0.

%% 开启体力定时器
start_sp_timer(RemainTime) ->
    TimeStamp = RemainTime + com_time:now(),
    ?player_send(player_sproto:pkg_msg(?MSG_PLAYER_SP_REFRESH_TIME, {TimeStamp})),
    tool:do_send_after(?MICOSEC_PER_SECONDS * RemainTime,
        ?mod_msg(?MODULE, ?pd_sp),
        ?back_strength_timerref).

%% push_share_game_state() ->
%%     ?player_send(player_sproto:pkg_msg(?MSG_PLAYER_PUSH_SHARE_GAME,
%%         {util:get_pd_field(?pd_share_game_status, 0), util:get_pd_field(?pd_prize_share_game_status, 0)})).

get_in_hourly_sp_time_status() ->
    {{LunchStart,LunchEnd,_LunchSp},{DinnerStart,DinnerEnd,_DinnerSp}} = misc_cfg:get_sp_time(),
    {_, CurTime} = calendar:local_time(),
    if
        CurTime >= LunchStart andalso CurTime =< LunchEnd ->
            case util:get_pd_field(?pd_hourly_sp_lunch, 0) of
                0 ->
                    0;
                _ ->
                    1
            end;
        CurTime >= DinnerStart andalso CurTime =< DinnerEnd ->
            case util:get_pd_field(?pd_hourly_sp_dinner, 0) of
                0 ->
                    0;
                _ ->
                    1
            end;
        true ->
            2
    end.
