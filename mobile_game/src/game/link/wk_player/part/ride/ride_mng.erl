%%%-------------------------------------------------------------------
%%% @author fengzhu
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%         坐骑系统
%%% @end
%%% Created : 10. 五月 2016 下午5:54
%%%-------------------------------------------------------------------
-module(ride_mng).
-author("fengzhu").

-include_lib("pangzi/include/pangzi.hrl").
-include("inc.hrl").

-include("ride.hrl").
-include("game.hrl").
-include("player.hrl").
-include("handle_client.hrl").
-include("ride_def.hrl").
-include("load_cfg_ride.hrl").
-include("player_mod.hrl").
-include("load_spirit_attr.hrl").
-include("../wonderful_activity/bounty_struct.hrl").
-include("system_log.hrl").
-include("day_reset.hrl").
-include("rank.hrl").
-include("../../../wk_open_server_happy/open_server_happy.hrl").
-include("achievement.hrl").

%% API
-export([
    create_ride/1
    , init_ride/1
    , restore_ride_attr/0
    , getoff_normal_ride_for_shapeshift/0
    , geton_ride_for_scene/0
    , getoff_ride_for_scene/0
    , geton_ride/1
    , getoff_ride/1
    , del_ride_speed/1
    , add_ride_speed/1
    , reset_ride_soul_change_count/0
    , test/1
    , test/2
    , test_activate_ride/2
    , test_uplevel/1
    , test_advance/1
    , test_print/1
    , test_feed/1
    , test_change/1
]).

-define(player_ride_tab, player_rides).
-define(player_ride_soul_tab, player_ride_soul).


-define(FirstRide, 1).  %% 坐骑系统开放送的坐骑Id
-define(FirstRideSoul, 1). %% 兽魂初始化id


-define(ADVANCE_LEVEL, 10).%%每10级进阶!

-define(OPEN_RIDE_FLAG, 400).    %% 坐骑系统的开关值

%%-define(Happy_attenuation_time, 60 * 1000).    %% 愉悦值衰减间隔时间,1小时60 * 60 * 1000
-define(Happy_attenuation_time, misc_cfg:get_beast_soul_happy_reduce_interview_misc() * 1000).
-define(Happy_Reduce_Value, misc_cfg:get_beast_soul_happy_reduce_value_misc()).

-define(happy_timerref, happy_timerref).    %% 愉悦值定时器
-define(outcd_timerref, outcd_timerref).    %% 兽魂转化CD计时器

-define(happy_time_remain, '@happy_time_remain@').  %% 愉悦值计时剩余时间
-define(happy_time_begin, '@happy_time_begin@').    %% 愉悦值定时器启动时间

-define(outcd_begin, '@outcd_begin@').   %% 吞吐CD计时
-define(ride_begin_level, 0).    %% 坐骑的初始等级

-define(SoulMaxLv, 100).

%% 创建坐骑
create_ride(RideId) ->
    %% 已经拥有某个坐骑就不能再拥有了
    case get_ride(RideId) of
        ?false ->
            Ride = init_ride(RideId),
            Rides = get(?pd_all_rides),
            put(?pd_all_rides, [Ride | Rides]),
            %% 更新坐骑战力排行榜
            update_ride_ranking_list(),
            %%更新坐骑列表
            ?player_send(ride_sproto:pkg_msg(?MSG_RIDE_LIST, {[ride2ride_info(TRide) || TRide <- Rides]}));
        _ ->
            %% 已经拥有该坐骑
            {?error, ride_already_owned}
    end.

%% 创建兽魂
create_ride_soul() ->
    #ride_soul_attr_cfg{
        level = Level, attr = Attr, form_id = FormId, out_pirce = OutPrice
    } = load_cfg_ride:lookup_ride_soul_attr_cfg(?FirstRideSoul),
    RideSoul =
        #ride_soul
        {
            id = ?FirstRideSoul,
            formId = FormId,
            level = Level,
            exp = 0,
            grade = 0,
            attr = Attr,
            out_price = OutPrice,
            out_cd = 0,
            out_num = 0, %% 已经喷吐的次数
            happy = 0
        },
    put(?pd_ride_soul, RideSoul),
    attr_new:set(?pd_ride_soul_data, RideSoul),

    %%tool:do_send_after(?Happy_attenuation_time,  %%1小时
    %%    ?mod_msg(?MODULE, {happy_down}),
    %%    ?happy_timerref),
    %%put(?happy_time_begin, util:get_now_second(0)),
    ?player_send(ride_sproto:pkg_msg(?MSG_RIDE_SOUL_DATA, {ride_soul2ride_soul_info(RideSoul)})),
    ok.

init_ride(RideCfgId) ->
    #ride_attr_cfg{
        form_id = FormId, level = Level, cost_id = CostId, evolve_attr = EvolveAttr
    } = load_cfg_ride:lookup_ride_attr_cfg({RideCfgId, ?ride_begin_level}),
    Rideid = gen_id:next_id(ride_id_tab),
    #ride_form_cfg{speed = Speed} = load_cfg_ride:lookup_ride_form_cfg(FormId),
    #ride
    {
        id = Rideid,                    % 坐骑唯一Id
        cfgid = RideCfgId,              % 坐骑配置Id
        formId = FormId,                % 坐骑形象Id
        status = ?RIDE_STATUS_UNRIDE,   % 坐骑状态
        level  = Level,                 % 坐骑等级
        speed = Speed,                  % 坐骑移动速度
        attr = EvolveAttr,              % 当前属性
        cost = CostId                   % 材料消耗
    }.

load_db_table_meta() ->
    [
        #db_table_meta{
            name = ?player_ride_tab,                %% 创建的表
            fields = ?record_fields(player_rides),  %% 对应的表结构
            shrink_size = 1,
            flush_interval = 2
        },

        #db_table_meta{
            name = ?player_ride_soul_tab,
            fields = ?record_fields(player_ride_soul),
            shrink_size = 1,
            flush_interval = 2
        }
    ].

%% 玩家第一次登陆是调用
create_mod_data(PlayerID) ->
    create_ride_data(PlayerID),
    create_ride_soul_data(PlayerID).

create_ride_data(PlayerID) ->
    dbcache:insert_new(?player_ride_tab, #player_rides{id = PlayerID, rides = [], riding = 0}).
create_ride_soul_data(PlayerID) ->
    dbcache:insert_new(?player_ride_soul_tab, #player_ride_soul{id = PlayerID, ride_soul_info = [] }).

load_mod_data(PlayerId) ->
    load_ride_data(PlayerId),
    load_ride_soul_data(PlayerId).



load_ride_data(PlayerId) ->
    case dbcache:load_data(?player_ride_tab, PlayerId) of
        [] ->
            ?ERROR_LOG("player ~p can not player_mount_tab  mode", [PlayerId]),
            create_ride_data(PlayerId),
            load_ride_data(PlayerId);
        [#player_rides{rides = Rides, riding = Ride}] ->
            ?pd_new(?pd_riding, Ride),
            ?pd_new(?pd_all_rides, Rides)
    end.
load_ride_soul_data(PlayerId) ->
    case dbcache:load_data(?player_ride_soul_tab, PlayerId) of
        [] ->
            ?ERROR_LOG("player ~p can not player_ride_soul_tab  mode", [PlayerId]),
            create_ride_soul_data(PlayerId),
            load_ride_soul_data(PlayerId);
        [#player_ride_soul{ride_soul_info = RideSoulInfo}] ->
            ?pd_new(?pd_ride_soul, RideSoulInfo)
    end.

init_client() ->
    %% 上线恢复坐骑形态
    case get(?pd_riding) of
        0 ->
            no_riding;
            %% {?error, no_riding};
        RidingId ->
            ?player_send(player_sproto:pkg_msg(?MSG_PlAYER_RIDE, {RidingId})),
            scene_mng:send_msg({?msg_update_ride_data, get(?pd_idx), RidingId}),
            ?player_send(ride_sproto:pkg_msg(?MSG_RIDE_TORIDE, {RidingId}))
    end,
    attr_new:set(?pd_riding_data, get(?pd_riding)),
    ok.

%% 记录玩家所有坐骑，玩家当前的坐骑
save_data(_SelfId) ->
    PlayerRide =
        #player_rides{
            id = _SelfId,
            rides = get(?pd_all_rides),
            riding = get(?pd_riding)
        },
    dbcache:update(?player_ride_tab, PlayerRide),

    PlayerRideSoul =
        #player_ride_soul
        {
            id = _SelfId,
            ride_soul_info = get(?pd_ride_soul)
        },
    attr_new:set(?pd_ride_soul_data, get(?pd_ride_soul)),
    dbcache:update(?player_ride_soul_tab, PlayerRideSoul),
    ok.

handle_msg(_FromMod, {open_ride}) ->
    handle_client(?MSG_RIDE_LIST, {}),
    ok;

handle_msg(_FromMod, {msg_uplevel}) ->
    handle_client(?MSG_RIDE_UPLEVEL, {}),
    ok;

handle_msg(_FromMod, {msg_advance}) ->
    handle_client(?MSG_RIDE_ADVANCE, {}),
    ok;

handle_msg(_FromMod, {msg_print}) ->
    print_ridesoul(),
    ok;

handle_msg(_FromMod, {msg_feed}) ->
    handle_client(?MSG_RIDE_FEED, {}),
    ok;

handle_msg(_FromMod, {msg_change}) ->
    handle_client(?MSG_RIDE_CHANGE, {}),
    ok;

handle_msg(_, {msg_player_ride, RideId}) ->
    handle_client(?MSG_RIDE_TORIDE, {RideId}),
    ok;

handle_msg(_, {msg_activate_ride, RideId}) ->
    handle_client(?MSG_RIDE_ACTIVATE, {RideId}),
    ok;

handle_msg(_, {happy_down}) ->
    happy_timer();

handle_msg(_, {set_out_cd}) ->
    set_out_cd();

handle_msg(_, _) ->
    ok.
handle_frame(_) -> ok.

online() ->
    init_ride_data(),
    mount_tgr:online_give_task_mount().


offline(_SelfId) ->
    save_data(_SelfId),

    NowTime = com_time:now(),
    case get(?happy_time_begin) of
        undefined ->
            ok;
        _ ->
            RemainTime = NowTime - get(?happy_time_begin),
            util:set_pd_field(?pd_ride_soul_happy_time_remain, RemainTime)
    end,
    %%    RemainTime = NowTime - get(?happy_time_begin),
    %%%%    put(?happy_time_remain, RemainTime),
    %%    my_ets:set(?happy_time_remain, RemainTime),
    %%    ?INFO_LOG("===NowTime:~p==================",[NowTime]),
    %%    ?INFO_LOG("===RemainTime:~p==================",[my_ets:get(?happy_time_remain, 0)]),
    %%    ?INFO_LOG("===happy_time_begin:~p==================",[get(?happy_time_begin)]),

    case get(?outcd_begin) of
        undefined ->
            ok;
        0 ->
            ok;
        T ->
            set_out_cd(NowTime - T)
    end,

    tool:cancel_sendafter([?happy_timerref, ?outcd_timerref]),


    ok.

view_data(Acc) ->
    Acc.

init_ride_data() ->
    case util:get_pd_field(?pd_ride_soul, []) of
        [] ->
            ok;
        RideSoul ->
            %% 设置愉悦值更新时间
            OfflineTime =  erlang:get(?pd_last_logout_time),
            RemainTime = util:get_pd_field(?pd_ride_soul_happy_time_remain, 0),
            NowTime = com_time:now(),
            %% ?INFO_LOG("===OfflineTime:~p,RemainTime:~p,NowTime:~p==================",[OfflineTime,RemainTime,NowTime]),
            DTime = NowTime - OfflineTime + RemainTime,
            %% ?INFO_LOG("===Dtime:~p==================",[DTime]),
            %% ?INFO_LOG("===new Now time:~p==================",[com_time:now()]),
            %% 服务器改时间防止剩余时间是负数
            NewDTime =
                if
                    DTime < 0->
                        0;
                    true ->
                        DTime
                end,
            Num = (NewDTime * 1000) div (?Happy_attenuation_time),
            %% ?INFO_LOG("===Num:~p==================",[Num]),
            NewRemainTime = (NewDTime * 1000) rem (?Happy_attenuation_time),
            %% ?INFO_LOG("===NewRemainTime:~p==================",[NewRemainTime]),

            tool:do_send_after(NewRemainTime,
                ?mod_msg(?MODULE, {happy_down}),
                ?happy_timerref),
            put(?happy_time_begin, com_time:now()),

            %% 设置吞吐CD时间
            #ride_soul{out_cd = Outcd} = RideSoul,
            Pass_Time = NowTime - OfflineTime,
            %% ?INFO_LOG("===OfflineTime:~p,Pass_Time:~p,NowTime:~p==================",[OfflineTime,Pass_Time,NowTime]),
            %%  ?INFO_LOG("===Outcd:~p==================",[Outcd]),
            if
                Pass_Time >= Outcd ->
                    NewRideSoul = RideSoul#ride_soul{out_cd = 0},
                    put(?pd_ride_soul, NewRideSoul),
                    put(?outcd_begin, 0),
                    ok;
                true ->
                    Remain_time = Outcd - Pass_Time,
                    %%  ?INFO_LOG("===Remain_time:~p==================",[Remain_time]),
                    NewRideSoul = RideSoul#ride_soul{out_cd = Remain_time},
                    put(?pd_ride_soul, NewRideSoul),

                    tool:do_send_after(Remain_time * 1000,
                        ?mod_msg(?MODULE, {set_out_cd}),
                        ?outcd_timerref),
                    put(?outcd_begin, com_time:now())
            end,
            sub_happy_value(Num)
    end.


handle_client({Pack, Arg}) ->
    case task_open_fun:is_open(?OPEN_RIDE) of
        ?false -> ?return_err(?ERR_NOT_OPEN_FUN);
        ?true ->
            first_open_ride_system(),
            handle_client(Pack, Arg)
    end.

%% 坐骑列表
handle_client(?MSG_RIDE_LIST, {}) ->
    Rides = get(?pd_all_rides),
    ?player_send(ride_sproto:pkg_msg(?MSG_RIDE_LIST, {[ride2ride_info(Ride) || Ride <- Rides]}));

%% 坐骑信息
handle_client(?MSG_RIDE_DATA, {RideId}) ->
    case get_ride(RideId) of
        ?false ->
            ?return_err(?ERR_RIDE_NO_THIS_RIDE);
        Ride ->
            ?player_send(ride_sproto:pkg_msg(?MSG_RIDE_DATA, {ride2ride_info(Ride)}))
    end;

%% 坐骑激活
handle_client(?MSG_RIDE_ACTIVATE, {RideId}) ->
    %%    CostList = cost:get_cost(Ride#ride.cost), %% 消耗列表

    case load_cfg_ride:lookup_ride_attr_cfg({RideId, ?ride_begin_level}) of
        none ->
            ?return_err(?ERR_RIDE_NO_THIS_RIDE);
        #ride_attr_cfg{cost_id = CostId} ->
            case cost:cost(CostId, ?FLOW_REASON_RIDE_ACTIVATE) of
                {error, _Reason} ->
                    % ?INFO_LOG("======reason:~p,~p=========",[_Reason,CostId]),
                    ?return_err(?ERR_RIDE_NO_ENOUGH);
                _ ->
                    create_ride(RideId),
                    %% 增加坐骑属性到人物角色身上
                    attr_new:begin_sync_attr(),
                    add_ride_attr(RideId, ?ride_begin_level),
                    attr_new:end_sync_attr(),

                    ?player_send(ride_sproto:pkg_msg(?MSG_RIDE_ACTIVATE, {RideId}))
            end
    end;

%% 坐骑进化
handle_client(?MSG_RIDE_EVOLVE, {RideId}) ->
    Ride = get_ride(RideId),
    #ride{level = Level} = Ride,
    %%    #ride_attr_cfg{cost_id = CostId} = load_cfg_ride:lookup_ride_attr_cfg({RideId, Level}),
    case load_cfg_ride:lookup_ride_attr_cfg({RideId, Level + 1}) of
        #ride_attr_cfg{cost_id = CostId}   ->
            case cost:cost(CostId, ?FLOW_REASON_RIDE_PHASE) of
                {error, _Reason} ->
                    % ?INFO_LOG("======reason:~p,~p=========",[_Reason,CostId]),
                    ?return_err(?ERR_RIDE_NO_ENOUGH);
                _ ->
                    NewRide = Ride#ride{level = Level+1},
                    open_server_happy_mng:ride_levelup(RideId, Level+1),
                    update_ride(NewRide),
                    %% ?INFO_LOG("=================NewRide:~p",[NewRide]),

                    %% 更新坐骑战力排行榜
                    update_ride_ranking_list(),
                    achievement_mng:do_ac(?shenjizuoqi),

                    %%进化后更新角色属性
                    attr_new:begin_sync_attr(),
                    del_ride_attr(RideId,Level),
                    add_ride_attr(RideId,Level+1),
                    attr_new:end_sync_attr(),

                    %% 坐骑进阶日志
                    system_log:info_ride_phase(RideId, Level, Level+1),

                    bounty_mng:do_bounty_task(?BOUNTY_TASK_SHENGJI_RIDE, 1),
                    ?player_send(ride_sproto:pkg_msg(?MSG_RIDE_EVOLVE, {RideId,Level+1})),
                    ok
            end;
        _ ->
            ?return_err(?ERR_RIDE_EVOLVE_MAX)
    end;

handle_client(?MSG_RIDE_SOUL_DATA, {}) ->
    RideSoul = get(?pd_ride_soul),
    NowTime = com_time:now(),
    NewRideSoul =
        case get(?outcd_begin) of
            undefined ->
                RideSoul;
            0 ->
                RideSoul;
            T ->
                put(?outcd_begin, com_time:now()),
                set_out_cd(NowTime - T)
        end,
    % ?INFO_LOG("=============================OUT_CD:~p",[NewRideSoul#ride_soul.out_cd]),
    ?player_send(ride_sproto:pkg_msg(?MSG_RIDE_SOUL_DATA, {ride_soul2ride_soul_info(NewRideSoul)})),
    ok;

%% 兽魂升级
handle_client(?MSG_RIDE_UPLEVEL, {}) ->
    RideSoul = get(?pd_ride_soul),
    PlayerLevel = get(?pd_level),
    Ride_soul_id = RideSoul#ride_soul.id,
    Ride_soul_level = RideSoul#ride_soul.level,
    if
        %% 兽魂等级不能大于玩家等级
        RideSoul#ride_soul.level >= PlayerLevel ->
            % ?INFO_LOG("======reason:~p,~p=========",[RideSoul#ride_soul.level, PlayerLevel]),
            ?return_err(?ERR_RIDE_LEVELMAX);
        true ->
            #ride_soul_attr_cfg{get_exp = {UplevelCost, EXP}, grade = Grade, exp = MaxExp} = load_cfg_ride:lookup_ride_soul_attr_cfg(Ride_soul_id),
            %% 每10级才能进阶
            % ?INFO_LOG("======uplevel:~p,~p=========",[(Ride_soul_level div ?ADVANCE_LEVEL), Grade]),
            if
                %%玩家每10级要进阶后才能升级
                (Ride_soul_level div ?ADVANCE_LEVEL) > Grade ->
                    % ?INFO_LOG("======reason:~p,~p=========",[(Ride_soul_level div ?ADVANCE_LEVEL), Grade]),
                    ?return_err(?ERR_RIDE_ADVANCE_LEVEL);
                ?true ->
                    case cost:cost(UplevelCost, ?FLOW_REASON_RIDE_UPLEVEL) of
                        {error, _Reason} ->
                            % ?INFO_LOG("======reason:~p,~p,~p=========",[_Reason,Ride_soul_id,UplevelCost]),
                            ?return_err(?ERR_RIDE_NO_ENOUGH);
                        _ ->
                            bounty_mng:do_bounty_task(?BOUNTY_TASK_SHENGJI_SHOUHUN, 1),
                            open_server_happy_mng:sync_task(?UPDATE_SHOUHUN_COUNT, 1),
                            %% 暴击几率
                            EndExp = ride_soul_add_level(RideSoul, EXP),

                            %% 经验满了升级
                            NewRideSoul = ride_soul_level_up(RideSoul, Ride_soul_id, EndExp, MaxExp),

                            %% 更新坐骑战力排行榜
                            update_ride_ranking_list(),
                            put(?pd_ride_soul, NewRideSoul),
                            #ride_soul{exp = RetExp, level = RetLevel} = NewRideSoul,
                            %% ?INFO_LOG("======22222222=========RideSoul:~p",[NewRideSoul]),
                            ?player_send(ride_sproto:pkg_msg(?MSG_RIDE_UPLEVEL, {RetExp,RetLevel}))
                    end
            end
    end;

handle_client(?MSG_RIDE_UPLEVEL_NEW, {ItemCount}) ->
    {Level, Exp, DoubleCount, UseCount} = ride_soul_uplevel(ItemCount, 0, 0),
    %% 更新坐骑战力排行榜
    update_ride_ranking_list(),
    ?player_send(ride_sproto:pkg_msg(?MSG_RIDE_UPLEVEL_NEW, {Exp, Level, DoubleCount, UseCount}));

%% 兽魂突破
handle_client(?MSG_RIDE_ADVANCE, {}) ->
    RideSoul = get(?pd_ride_soul),
    %%    ?INFO_LOG("=====111111111111==========RideSoul:~p",[RideSoul]),
    PlayerLevel = get(?pd_level),
    #ride_soul{id = Ride_soul_id, level = Ride_soul_level, grade = Grade} = RideSoul,
    #ride_soul_attr_cfg{grade_cost = GradeCost} = load_cfg_ride:lookup_ride_soul_attr_cfg(Ride_soul_id),
    %%    ?INFO_LOG("======xxxxxxxxxxxxxx,grade:~p,~p=========",[(Ride_soul_level div ?ADVANCE_LEVEL), Grade]),
    if
        Ride_soul_level rem ?ADVANCE_LEVEL > 0->
            % ?INFO_LOG("======reason:~p=========",[RideSoul#ride_soul.level]),
            ?return_err(?ERR_RIDE_LEVEL_ENOUGH);
        Ride_soul_level > PlayerLevel ->
            %% ?INFO_LOG("======reason:~p,~p=========",[RideSoul#ride_soul.level, PlayerLevel]),
            ?return_err(?ERR_RIDE_LEVELMAX);
        (Ride_soul_level div ?ADVANCE_LEVEL) < Grade ->
            %% ?INFO_LOG("======reason:~p,~p=========",[(Ride_soul_level div ?ADVANCE_LEVEL), Grade]),
            ?return_err(?ERR_RIDE_ADVANCE_LEVEL);
        %% Ride_soul_exp < MaxExp ->
        %%     ?INFO_LOG("======reason:~p,~p=========",[Ride_soul_exp, MaxExp]),
        %%     ?return_err(?ERR_RIDE_EXP_NO_ENOUGH);
        true ->
            case cost:cost(GradeCost, ?FLOW_REASON_RIDE_ADVANCE) of
                {error, _Reason} ->
                    %% ?INFO_LOG("======reason:~p,~p=========",[_Reason,Ride_soul_id]),
                    ?return_err(?ERR_RIDE_NO_ENOUGH);
                _ ->
                    %%  #ride_soul_attr_cfg{id = Id, level = Lev, attr = Attr} = load_cfg_ride:lookup_ride_soul_attr_cfg(Ride_soul_id+1),
                    NewRideSoul = RideSoul#ride_soul{grade = Grade + 1},

                    %% 更新角色属性加成
                    attr_new:begin_sync_attr(),
                    #ride_soul_attr_cfg{grade_attr = AttrAward} = load_cfg_ride:lookup_ride_soul_attr_cfg(Ride_soul_id),
                    Attr = attr:sats_2_attr(AttrAward),
                    attr_new:player_add_attr(Attr),
                    attr_new:end_sync_attr(),

                    put(?pd_ride_soul, NewRideSoul),
                    %%  ?INFO_LOG("=====222222222222==========RideSoul:~p",[NewRideSoul]),

                    %% 更新坐骑战力排行榜
                    update_ride_ranking_list(),
                    ?player_send(ride_sproto:pkg_msg(?MSG_RIDE_ADVANCE, {NewRideSoul#ride_soul.grade}))
            end
    end;

%% 兽魂转化
handle_client(?MSG_RIDE_CHANGE, {}) ->
    %%  print_ridesoul(),
    RideSoul = get(?pd_ride_soul),
    #ride_soul{id = Id, out_cd = OutCd, out_num = OutNum, happy = Happy} = RideSoul,
    #ride_soul_attr_cfg{out_cd = MaxOutCd, out_pirce = PrizeId, out_num = MaxOutNum} = load_cfg_ride:lookup_ride_soul_attr_cfg(Id),
    if
        OutCd =< 0->    %%冷却时间是否已好
            if
                Happy >= 100 ->     %% 愉悦度是否已满
                    if
                        OutNum < MaxOutNum ->       %% 是否还有转化次数
                            bounty_mng:do_bounty_task(?BOUNTY_TASK_FUMO_SHOUHUN, 1),
                            PrizeList = prize:prize_mail(PrizeId, ?S_MAIL_RIDE_SOUL_PRIZE, ?FLOW_REASON_RIDE_CHANGE),

                            NewOutNum = OutNum + 1,
                            NewRideSoul = RideSoul#ride_soul{out_cd = MaxOutCd, out_num = NewOutNum},
                            put(?pd_ride_soul, NewRideSoul),
                            ?player_send(ride_sproto:pkg_msg(?MSG_RIDE_CHANGE, {PrizeList, MaxOutCd, NewOutNum})),

                            tool:do_send_after(MaxOutCd * 1000,  %%1小时
                                ?mod_msg(?MODULE, {set_out_cd}),
                                ?outcd_timerref),
                            put(?outcd_begin, com_time:now());
                            %%  print_ridesoul();
                        true ->
                            %% ?INFO_LOG("======reason:~p=========",[OutNum]),
                            ?return_err(?ERR_RIDE_CHANGE_NO_NUM)
                    end;
                true ->
                    %% ?INFO_LOG("======reason:~p=========",[Happy]),
                    ?return_err(?ERR_RIDE_HAPPY_ENOUGH)
            end;
        true ->
            %% ?INFO_LOG("======reason:~p=========",[OutCd]),
            ?return_err(?ERR_RIDE_CHANGE_NO_CD)
    end,

    ok;

%% %% 兽魂喂养
%% handle_client(?MSG_RIDE_FEED, {}) ->
%%     RideSoul = get(?pd_ride_soul),
%%     #ride_soul{id = Id, happy = Happy} = RideSoul,
%%     #ride_soul_attr_cfg{get_happy = GetHappy} = load_cfg_ride:lookup_ride_soul_attr_cfg(Id),
%%     {CostId, MinHappy, MaxHappy} = GetHappy,
%%     if
%%         Happy >= 100 ->
%%             %% ?INFO_LOG("======reason:~p=========",[Happy]),
%%             ?return_err(?ERR_RIDE_MAX_HAPPY);
%%         true ->
%%             case cost:cost(CostId, ?FLOW_REASON_RIDE_FEED) of
%%                 {error, _Reason} ->
%%                     %% {error, no_enough},
%%                     %% ?INFO_LOG("======reason:~p,~p=========",[_Reason,CostId]),
%%                     ?return_err(?ERR_RIDE_NO_ENOUGH);
%%                 _ ->
%%                     achievement_mng:do_ac(?dongwuhuoban),
%%                     bounty_mng:do_bounty_task(?BOUNTY_TASK_FEED_SHOUHUN, 1),
%%                     AddHappy = com_util:random(MinHappy, MaxHappy),
%%                     NewHappy =
%%                         if
%%                             Happy + AddHappy > 100 ->
%%                                 100;
%%                             ?true ->
%%                                 Happy + AddHappy
%%                         end,
%%                     NewRideSoul = RideSoul#ride_soul{happy = NewHappy},
%%                     put(?pd_ride_soul, NewRideSoul),
%%                     ?player_send(ride_sproto:pkg_msg(?MSG_RIDE_FEED, {NewHappy}))
%%             end
%%     end,
%%     ok;

handle_client(?MSG_RIDE_FEED_NEW, {ItemCount}) ->
    achievement_mng:do_ac(?dongwuhuoban),
    {Happy, UseCount} = ride_soul_feed(ItemCount,0),
    ?DEBUG_LOG("Ret:~p", [{Happy, UseCount}]),
    ?player_send(ride_sproto:pkg_msg(?MSG_RIDE_FEED_NEW, {Happy, UseCount}));

%% 坐骑乘骑,取消乘骑RideId为0
handle_client(?MSG_RIDE_TORIDE, {RideId}) ->
    case RideId of
        %% 下马
        0 ->
            %%减去移动属性
            case get(?pd_riding) of
                0 ->
                    ?ERROR_LOG("no rideing:~p", [RideId]),
                    ?return_err(?ERR_RIDE_NO_RIDING);
                RidingId ->
                    getoff_ride(RidingId),
                    attr_new:set(?pd_riding_data, 0),
                    put(?pd_riding, RideId),
                    ?player_send(player_sproto:pkg_msg(?MSG_PlAYER_RIDE, {0})),
                    scene_mng:send_msg({?msg_update_ride_data, get(?pd_idx), 0}),
                    ?player_send(ride_sproto:pkg_msg(?MSG_RIDE_TORIDE, {0}))
            end;
        %% 上马
        _ ->
            %% 必须拥有该坐骑才能骑乘
            case get_ride(RideId) of
                ?false ->
                    ?ERROR_LOG("no this ride:~p", [RideId]),
                    ?return_err(?ERR_RIDE_NO_THIS_RIDE);
                _ ->
                    %% 取消变身
                    shapeshift_mng:stop_shapeshift_effect(),
                    %%增加移动属性
                    geton_ride(RideId),
                    put(?pd_riding, RideId),
                    attr_new:set(?pd_riding_data, RideId),

                    ?player_send(player_sproto:pkg_msg(?MSG_PlAYER_RIDE, {RideId})),
                    scene_mng:send_msg({?msg_update_ride_data, get(?pd_idx), RideId}),
                    ?player_send(ride_sproto:pkg_msg(?MSG_RIDE_TORIDE, {RideId}))
            end
    end.

%% 非任务坐骑变身取消坐骑
getoff_normal_ride_for_shapeshift() ->
    %% ?return_err会终止执行函数
    case get(?pd_riding) of
        0 ->
            ok;
        RidingId ->
            ride_mng:getoff_ride(RidingId),
            handle_client(?MSG_RIDE_TORIDE, {0})
    end,
    ok.

geton_ride_for_scene() ->
    %%增加移动属性
    case get(?pd_riding) of
        0 ->
            ok;
            %% {?error, no_riding};
        RidingId ->
            geton_ride(RidingId)
    end,
    ok.

getoff_ride_for_scene() ->
    %%减去移动属性
    case get(?pd_riding) of
        0 ->
            ok;
            %% ?ERROR_LOG("no rideing");
            %% {?error, no_riding};
        RidingId ->
            getoff_ride(RidingId)
    end,
    ok.

geton_ride(RideId) ->
    case get(?pd_riding) of
        0 ->
            %%增加移动属性
            attr_new:begin_sync_attr(),
            add_ride_speed(RideId),
            attr_new:end_sync_attr(),
            ok;
        RidingId ->
            attr_new:begin_sync_attr(),
            del_ride_speed(RidingId),
            add_ride_speed(RideId),
            attr_new:end_sync_attr()
    end,
    ok.

getoff_ride(RidingId) ->
    attr_new:begin_sync_attr(),
    del_ride_speed(RidingId),
    attr_new:end_sync_attr().


%% 是否拥有某个坐骑
get_ride(RideId) ->
    Rides = get(?pd_all_rides),
    lists:keyfind(RideId, #ride.cfgid, Rides).

%%
ride2ride_info(Ride) ->
    {
        Ride#ride.cfgid,
        Ride#ride.level
    }.

ride_soul2ride_soul_info(RideSoul) ->
    {
        RideSoul#ride_soul.id,              %% 兽魂配置id
        RideSoul#ride_soul.exp,             %% 兽魂当前经验
        RideSoul#ride_soul.happy,           %% 兽魂当前愉悦度
        RideSoul#ride_soul.grade,           %% 突破等级
        RideSoul#ride_soul.out_cd,          %% 兽魂吐出奖励的cd
        RideSoul#ride_soul.out_num          %% 每天喷吐剩余次数
    }.

%% 上线后要恢复坐骑和兽魂属性
restore_ride_attr() ->
    Rides = get(?pd_all_rides),
    RideSoul = get(?pd_ride_soul),
    attr_new:begin_sync_attr(),
    lists:foreach(
        fun(Ride) ->
            #ride{cfgid = CfgId, level = Level} = Ride,
            add_ride_attr(CfgId, Level)
        end
        ,Rides),

    case RideSoul of
        [] ->
            ok;
        _ ->
            add_ride_soul_grade_attr(RideSoul#ride_soul.grade),
            add_ride_soul_attr(RideSoul#ride_soul.id)
    end,
    attr_new:end_sync_attr(),
    ok.

%% 操作玩家坐骑列表
update_ride(NewRide) ->
    Rides = get(?pd_all_rides),
    NewRides = lists:keyreplace(NewRide#ride.cfgid, #ride.cfgid, Rides, NewRide),
    put(?pd_all_rides, NewRides).

%% del_ride(RideId) ->
%%     Rides = get(?pd_all_rides),
%%     NewRides = lists:keydelete(RideId, #ride.id, Rides),
%%     put(?pd_all_rides, NewRides).
%%
%% add_ride(Ride) ->
%%     Rides = get(?pd_all_rides),
%%     put(?pd_all_rides, [Ride | Rides]).

%% 更新玩家的坐骑属性
add_ride_attr(RideId,Level) ->
    #ride_attr_cfg{evolve_attr = AttrAward} = load_cfg_ride:lookup_ride_attr_cfg({RideId,Level}),
    Attr = attr:sats_2_attr(AttrAward),
    attr_new:player_add_attr(Attr),
    ok.

del_ride_attr(RideId,Level) ->
    #ride_attr_cfg{evolve_attr = AttrAward} = load_cfg_ride:lookup_ride_attr_cfg({RideId,Level}),
    Attr = attr:sats_2_attr(AttrAward),
    attr_new:player_sub_attr(Attr),
    ok.

add_ride_speed(RideId) ->
    #ride_form_cfg{speed = AttrAward} = load_cfg_ride:lookup_ride_form_cfg(RideId),
    Attr = attr:sats_2_attr(AttrAward),
    attr_new:player_add_attr(Attr),
    ok.
del_ride_speed(RideId) ->
    #ride_form_cfg{speed = AttrAward} = load_cfg_ride:lookup_ride_form_cfg(RideId),
    Attr = attr:sats_2_attr(AttrAward),
    attr_new:player_sub_attr(Attr),
    ok.

%% [坐骑] --> [坐骑Id,战斗力]
get_ride_power_list() ->
    Rides = get(?pd_all_rides),
    lists:foldl
    (
        fun(Ride, Acc) ->
            #ride{id = Id, cfgid = CfgId, level = Level} = Ride,
            #ride_attr_cfg{evolve_attr = AttrAward} = load_cfg_ride:lookup_ride_attr_cfg({CfgId,Level}),
            Attr = attr:sats_2_attr(AttrAward),
            NewAttr = attr_new:get_oldversion_equip_attr(Attr),
            Power = attr_new:get_combat_power(NewAttr),
            [{Id, Power} | Acc]
        end,
        [],
        Rides
    ).

%% 获得单个战斗力最强的坐骑
get_the_best_ride() ->
    RideList = get_ride_power_list(),
    NewRideList = lists:keysort(2, RideList),
    case NewRideList of
        [] ->
            0;
        NewRideList ->
            {_Id, Power} = lists:last(NewRideList),
            Power
    end.

get_ride_soul_power() ->
    #ride_soul{attr = AttrAward} = get(?pd_ride_soul),
    Attr = attr:sats_2_attr(AttrAward),
    NewAttr = attr_new:get_oldversion_equip_attr(Attr),
    attr_new:get_combat_power(NewAttr).

%% 获得玩家所有坐骑的战斗力
get_all_rides_power() ->
    RideList = get_ride_power_list(),
    RidePowers = lists:foldl(
        fun({_Id,Power}, Acc) ->
            Power + Acc
        end,
        0,
        RideList
    ),
    RideSoulPowers = get_ride_soul_power(),
    RidePowers + RideSoulPowers.

update_ride_ranking_list() ->
    AllRidesPower = get_all_rides_power(),
    [Lev, Power] = player:lookup_info(get(?pd_id), [?pd_level, ?pd_combat_power]),
    ranking_lib:update( ?ranking_ride, get(?pd_id), { AllRidesPower, Lev, Power }),
    util:is_flush_rank_only_by_rankname(?ranking_ride, get(?pd_id)).
%%    ranking_lib:flush_rank_only_by_rankname(?ranking_ride).



%% 更新玩家的兽魂属性
add_ride_soul_attr(Id) ->
    #ride_soul_attr_cfg{attr = AttrAward} = load_cfg_ride:lookup_ride_soul_attr_cfg(Id),
    %% ?INFO_LOG("AttrAward:~p", [AttrAward]),
    Attr = attr:sats_2_attr(AttrAward),
    %% ?INFO_LOG("Attr:~p", [Attr]),
    attr_new:player_add_attr(Attr),
    ok.
del_ride_soul_attr(Id) ->
    #ride_soul_attr_cfg{attr = AttrAward} = load_cfg_ride:lookup_ride_soul_attr_cfg(Id),
    Attr = attr:sats_2_attr(AttrAward),
    attr_new:player_sub_attr(Attr),
    ok.

add_ride_soul_grade_attr(GradeId)->
    case load_cfg_ride:lookup_ride_soul_attr_cfg(GradeId * 10) of
        #ride_soul_attr_cfg{grade_attr = AttrAward} ->
            Attr = attr:sats_2_attr(AttrAward),
            attr_new:player_add_attr(Attr);
        _ ->
            pass
    end.




%% 升级暴击几率由愉悦值决定
getDoubleByHappy(Happy) ->
    Happy / 200 * 100.

%% 坐骑功能一开放就拥有1阶1级的坐骑,拥有一个兽魂
first_open_ride_system() ->
    %% 第一次开启坐骑系统
    case attr_new:get_sink_state(?OPEN_RIDE_FLAG) of
        ?FALSE ->
            create_ride_soul(),
            %% 激活第一个坐骑
            create_ride(?FirstRide),
            %Ride = getRideById(?FirstRide),
            %% 增加属性
            attr_new:begin_sync_attr(),
            add_ride_attr(?FirstRide,?ride_begin_level),
            add_ride_soul_attr(?FirstRideSoul),
            attr_new:end_sync_attr(),

            attr_new:set_sink_state(?OPEN_RIDE_FLAG, ?TRUE);
            %% ?INFO_LOG("=================first_open_ride_system====================");
        _ ->
            %% ?INFO_LOG("=================open_ride_system_already=================="),
            ?true
    end.

%% 每隔1小时愉悦值下降10点
happy_timer() ->
    NewHappy = sub_happy_value(1),
    ?player_send(ride_sproto:pkg_msg(?MSG_RIDE_HAPPY, {NewHappy})),
    tool:do_send_after((?Happy_attenuation_time), %%60 * 60 * 1000,  %%1小时
        ?mod_msg(?MODULE, {happy_down}),
        ?happy_timerref),
    put(?happy_time_begin, com_time:now()),
    ok.

set_out_cd() ->
    put(?outcd_begin, 0),
    RideSoul = get(?pd_ride_soul),
    NewRideSoul = RideSoul#ride_soul{out_cd = 0},
    put(?pd_ride_soul, NewRideSoul),
    %% todo 需要通知前端CD已好么?
    ok.

set_out_cd(CD) ->
    CD_to_Sec = CD,
    RideSoul = get(?pd_ride_soul),
    #ride_soul{out_cd = Outcd} = RideSoul,
    NewRideSoul = RideSoul#ride_soul{out_cd = Outcd - CD_to_Sec},
    put(?pd_ride_soul, NewRideSoul),
    NewRideSoul.


%% 愉悦值衰减多少次数
sub_happy_value(Num) ->
    RideSoul = get(?pd_ride_soul),
    Happy = RideSoul#ride_soul.happy,
    EndHappy = Happy - (?Happy_Reduce_Value) * Num,
    NewHappy =
        if
            EndHappy =< 0  ->
                0;
            true ->
                EndHappy
        end,

    NewRideSoul = RideSoul#ride_soul{happy = NewHappy},
    put(?pd_ride_soul, NewRideSoul),
    NewHappy.

%% 兽魂加经验
ride_soul_add_level(RideSoul, EXP) ->
    CurExp = RideSoul#ride_soul.exp,
    DoubleOdds = getDoubleByHappy(RideSoul#ride_soul.happy),
    R = random:uniform(100),
    if
        R =< DoubleOdds ->
            {CurExp + EXP * 2, 1};
        true ->
            {CurExp + EXP, 0}
    end.

%% 隔天重置兽魂的转化次数
on_day_reset(_Player) ->
    %% ?INFO_LOG("==============ride_mng:on_day_reset"),
    reset_ride_soul_change_count().

reset_ride_soul_change_count() ->
    RideSoul = get(?pd_ride_soul),
    case RideSoul of
        [] ->
            ok;
        _ ->
            NewRideSoul = RideSoul#ride_soul{out_num = 0},
            put(?pd_ride_soul, NewRideSoul)
    end.

%% 测试
test(PlayerId) ->
    world:send_to_player(PlayerId, ?mod_msg(ride_mng, {open_ride})).

test(PlayerId, RideId) ->
    world:send_to_player(PlayerId, ?mod_msg(ride_mng, {msg_player_ride, RideId})).

test_activate_ride(PlayerId, RideId) ->
    world:send_to_player(PlayerId, ?mod_msg(ride_mng, {msg_activate_ride, RideId})).

%MSG_RIDE_UPLEVEL

test_uplevel(PlayerId) ->
    world:send_to_player(PlayerId, ?mod_msg(ride_mng, {msg_uplevel})).

%MSG_RIDE_ADVANCE
test_advance(PlayerId) ->
    world:send_to_player(PlayerId, ?mod_msg(ride_mng, {msg_advance})).

test_print(PlayerId) ->
    world:send_to_player(PlayerId, ?mod_msg(ride_mng, {msg_print})).

test_feed(PlayerId) ->
    world:send_to_player(PlayerId, ?mod_msg(ride_mng, {msg_feed})).

%MSG_RIDE_CHANGE
test_change(PlayerId) ->
    world:send_to_player(PlayerId, ?mod_msg(ride_mng, {msg_change})).


print_ridesoul() ->
    RideSoul = get(?pd_ride_soul),
    ?INFO_LOG("
               兽魂id:~p,
               兽魂形象Id:~p
               兽魂等级:~p
               兽魂当前经验值:~p
               兽魂阶数:~p
               兽魂的属性:~p
               兽魂吃撑吐出奖励:~p
               兽魂吐出奖励的cd:~p
               每天喷吐次数:~p
               兽魂愉悦度:~p",[
        RideSoul#ride_soul.id,
        RideSoul#ride_soul.formId,
        RideSoul#ride_soul.level,
        RideSoul#ride_soul.exp,
        RideSoul#ride_soul.grade,
        RideSoul#ride_soul.attr,
        RideSoul#ride_soul.out_price,
        RideSoul#ride_soul.out_cd,
        RideSoul#ride_soul.out_num,
        RideSoul#ride_soul.happy
    ]),
    ok.

%% 兽魂升级
ride_soul_level_up(RideSoul, Ride_soul_id, EndExp, MaxExp) ->
    PlayerLevel = get(?pd_level),
    #ride_soul_attr_cfg{id = Id, level = Lev, attr = Attr, exp = NextMaxExp}
        = load_cfg_ride:lookup_ride_soul_attr_cfg(Ride_soul_id+1),

    if
        Lev > PlayerLevel ->
            RideSoul#ride_soul{exp = EndExp};
        true ->
            if
                EndExp < MaxExp ->
                    RideSoul#ride_soul{exp = EndExp};
                true ->
                    NExp = EndExp - MaxExp,
                    NRideSoul = RideSoul#ride_soul{id = Id, level = Lev, exp = NExp, attr = Attr},
                    %% 更新角色属性加成
                    attr_new:begin_sync_attr(),
                    del_ride_soul_attr(Ride_soul_id),
                    add_ride_soul_attr(Id),
                    attr_new:end_sync_attr(),
                    ride_soul_level_up(NRideSoul, Id, NExp, NextMaxExp)
            end
    end.

ride_soul_uplevel(ItemCount,DoubleCount,UseCount) ->
    RideSoul = get(?pd_ride_soul),
    PlayerLevel = get(?pd_level),
    Ride_soul_id = RideSoul#ride_soul.id,
    Ride_soul_level = RideSoul#ride_soul.level,
    Grade = RideSoul#ride_soul.grade,
    if
        %% 兽魂等级不能大于玩家等级
        RideSoul#ride_soul.level >= PlayerLevel ->
            {Ride_soul_level, RideSoul#ride_soul.exp, DoubleCount, UseCount};
        true ->
            #ride_soul_attr_cfg{get_exp = {UplevelCost, EXP}, exp = MaxExp} = load_cfg_ride:lookup_ride_soul_attr_cfg(Ride_soul_id),

            NexGradeLevel = get_new_grade_level(Grade),
            MaxSoulLevel = load_cfg_ride:get_max_soul_level(),
            if
                Ride_soul_level < MaxSoulLevel andalso Ride_soul_level < NexGradeLevel ->
                    CostList = cost:get_cost_list(UplevelCost),
                    {2041,UseItemCount} = lists:keyfind(2041,1,CostList),
                    if
                        ItemCount < UseItemCount ->
                            {Ride_soul_level, RideSoul#ride_soul.exp, DoubleCount, UseCount};
                        true ->
                            case cost:cost(UplevelCost, ?FLOW_REASON_RIDE_UPLEVEL) of
                                {error, _Reason} ->
                                    {Ride_soul_level, RideSoul#ride_soul.exp, DoubleCount, UseCount};
                                _ ->
                                    bounty_mng:do_bounty_task(?BOUNTY_TASK_SHENGJI_SHOUHUN, 1),
                                    open_server_happy_mng:sync_task(?UPDATE_SHOUHUN_COUNT, 1),
                                    %% 暴击几率
                                    {EndExp,Double} = ride_soul_add_level(RideSoul, EXP),

                                    %% 经验满了升级
                                    NewRideSoul = ride_soul_level_up(RideSoul, Ride_soul_id, EndExp, MaxExp),

                                    put(?pd_ride_soul, NewRideSoul),
                                    ride_soul_uplevel(ItemCount-UseItemCount, DoubleCount+Double, UseCount+1)
                            end
                    end;
                true ->
                    {Ride_soul_level, RideSoul#ride_soul.exp, DoubleCount, UseCount}
            end
    end.

ride_soul_feed(ItemCount,UseCount) ->
    RideSoul = get(?pd_ride_soul),
    #ride_soul{id = Id, happy = Happy} = RideSoul,
    #ride_soul_attr_cfg{get_happy = GetHappy} = load_cfg_ride:lookup_ride_soul_attr_cfg(Id),
    {CostId, MinHappy, MaxHappy} = GetHappy,
    if
        Happy >= 100 ->
            {100, UseCount};
        true ->
            CostList = cost:get_cost_list(CostId),
            {2043,UseItemCount} = lists:keyfind(2043,1,CostList),
            if
                ItemCount < UseItemCount ->
                    {Happy, UseCount};
                true ->
                    case cost:cost(CostId, ?FLOW_REASON_RIDE_FEED) of
                        {error, _Reason} ->
                            {Happy, UseCount};
                        _ ->
                            bounty_mng:do_bounty_task(?BOUNTY_TASK_FEED_SHOUHUN, 1),
                            AddHappy = com_util:random(MinHappy, MaxHappy),
                            NewHappy =
                                if
                                    Happy + AddHappy > 100 ->
                                        100;
                                    ?true ->
                                        Happy + AddHappy
                                end,
                            NewRideSoul = RideSoul#ride_soul{happy = NewHappy},
                            put(?pd_ride_soul, NewRideSoul),
                            ride_soul_feed(ItemCount-UseItemCount, UseCount+1)
                    end
            end
    end.

get_new_grade_level(Grade) ->
    MaxLevel = load_cfg_ride:get_max_soul_level(),
    if
        (Grade + 1)* 10 >= MaxLevel ->
            MaxLevel;
        true ->
            (Grade + 1)* 10
    end.


