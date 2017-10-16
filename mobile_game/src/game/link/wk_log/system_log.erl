%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 23. 十月 2015 下午2:42
%%%-------------------------------------------------------------------
-module(system_log).
-author("clark").

%% API
-export
([
    info_create_role/1
    , info_role_login/1
    , info_role_levelup/1
    , info_task_start/1
    , info_role_logout/1
    , info_recharge_log/4
    , info_pay_log/1
    , info_finish_task/1
    , info_enter_copy/2
    , info_exit_copy/1
    , info_account_login/1
    , info_account_logout/1
    , info_finish_room/2
    , info_star_shop_pay/1
    , info_load_progress/1
    , info_longwen_levelup/5
    , info_free_give_diamond/3
    , info_get_item_log/6
    , info_use_item_log/6
    , info_item_trend_log/6
    , info_copy_die/1
    , info_mail_attach/4
    , info_delete_role/4
    , info_skill_levelup/7
    , info_role_offline/0
    , info_phase_achievement/1
    , info_get_mail/4
    , info_auction_sell_log/3
    , info_player_chat_log/2
    , info_auction_buy_log/6
    , info_player_arena_die_log/7
    , info_npc_buy_log/9
    , info_money_flow_log/6
    , info_player_vip_log/1
    , info_suit_log/2
    , info_ride_phase/3
    , info_pet_phase/3
    , info_online_count/1
]).

-include_lib("common/include/com_log.hrl").
-include_lib("pangzi/include/pangzi.hrl").
-include_lib("system_log.hrl").
-include_lib("player_def.hrl").
-include("event_server.hrl").
-include("player_mod.hrl").
-include_lib("kernel/include/file.hrl").

load_db_table_meta() ->
    [
        #db_table_meta{
            name = player_progress_tab,
            fields = record_info(fields, player_progress_tab),
            shrink_size = 20,
            flush_interval = 3
        }
    ].

create_mod_data(PlayerId) ->
    case dbcache:insert_new(player_progress_tab, #player_progress_tab{player_id = PlayerId}) of
        true ->
            ok;
        _ ->
            ?ERROR_LOG("create mod data false : player_progress_tab ~p already exists", [PlayerId])
    end.

load_mod_data(PlayerId) ->
    case dbcache:load_data(player_progress_tab, PlayerId) of
        [] ->
            create_mod_data(PlayerId),
            load_mod_data(PlayerId);
        [#player_progress_tab{iprogress_list = List}] ->
            put(pd_iprogress_list, List)
    end.

init_client() -> ok.

view_data(_) -> ok.

handle_frame(_) -> ok.

handle_msg(_, _) -> ok.

online() -> ok.

offline(_) -> ok.

save_data(PlayerId) ->
    Tab = #player_progress_tab{
        player_id = PlayerId,
        iprogress_list = get(pd_iprogress_list)
    },
    dbcache:update(player_progress_tab, Tab).

info_account_login(CreateTime) ->
    Date = calendar:local_time(),
    Log = #account_login_log
    {
        iEventId = get_event_id(?ACCOUNT_ENTER_LOG_EVT, Date, 0, 0, 0),
        dtEventTime = util:get_now_time(Date),
        iWorldId = erlang:get(?pd_server_id),
        iUin = erlang:get(?pd_user_id_log),
        vClientIp = attr_new:get(?pd_account_ip, 0),
        dtCreateTime = util:get_format_time(CreateTime),
        iLoginWay = attr_new:get(?pd_platform_id),
        vDeviceMac = attr_new:get(?pd_machine_mac, ""),
        vDeviceId = attr_new:get(?pd_machine_id, ""),
        vDeviceStyle = attr_new:get(?pd_machine_style, ""),
        vDeviceInfo = attr_new:get(?pd_machine_info, "")
    },
    route_write_log(Date, Log),
    ok.

info_create_role(PlayerId) ->
    Date = calendar:local_time(),
    Log = #create_role_log
    {
        iEventId = get_event_id(?CREATE_ROLE_EVT, Date, 0, 0, 0),
        iUin = erlang:get(?pd_user_id_log),
        dtEventTime = util:get_now_time(Date),
        iWorldId = erlang:get(?pd_server_id),
        vClientIp = attr_new:get(?pd_account_ip, 0),
        iRoleId = PlayerId,
        vRoleName = erlang:get(?pd_name),
        iJobId = attr_new:get(?pd_career),
        iLoginWay = attr_new:get(?pd_platform_id),
        vDeviceMac = attr_new:get(?pd_machine_mac, ""),
        vDeviceId = attr_new:get(?pd_machine_id, ""),
        vDeviceStyle = attr_new:get(?pd_machine_style, "")
    },
    route_write_log(Date, Log),
    ok.

info_role_login(PlayerId) ->
    Date = calendar:local_time(),
    Log = #role_login_log
    {
        iEventId = get_event_id(?ROLE_ENTER_LOG_EVT, Date, 0, 0, 0),
        iUin = erlang:get(?pd_user_id_log),
        dtEventTime = util:get_now_time(Date),
        iWorldId = erlang:get(?pd_server_id),
        vClientIp = attr_new:get(?pd_account_ip, 0),
        iRoleId = PlayerId,
        vRoleName = erlang:get(?pd_name),
        iRoleLevel = attr_new:get(?pd_level),
        iMoney = attr_new:get(?pd_diamond),
        dtCreateTime = util:get_format_time(get(pd_create_time)),
        iLoginWay = attr_new:get(?pd_platform_id),
        iRoleVipLevel = attr_new:get_vip_lvl(),
        iXP = attr_new:get(?pd_exp),
        iOnlineTotalTime = attr_new:get(?pd_online_total_time, 0),
        iRoleGoldcount = 0,     %% TODO
        iRoleExpendGold = 0,    %% TODO
        vMac = attr_new:get(?pd_machine_mac, ""),
        vDeviceId = attr_new:get(?pd_machine_id, ""),
        vDeviceStyle = attr_new:get(?pd_machine_style, ""),
        vDeviceInfo = attr_new:get(?pd_machine_info, "")
    },
    route_write_log(Date, Log),
    ok.

info_role_logout(RoleId) ->
    Date = calendar:local_time(),
    Log = #role_logout_log
    {
        iEventId = get_event_id(?ROLE_EXIT_LOG_EVT, Date, 0, 0, 0),
        iUin = erlang:get(?pd_user_id_log),
        dtEventTime = util:get_now_time(Date),
        iWorldId = erlang:get(?pd_server_id),
        vClientIp = attr_new:get(?pd_account_ip, 0),
        iOnlineTime = player:get_online_passed_time(),
        iOnlineTotalTime = attr_new:get(?pd_online_total_time, 0),
        iRoleId = RoleId,
        vRoleName = erlang:get(?pd_name),
        iRoleLevel = attr_new:get(?pd_level),
        iMoney = attr_new:get(?pd_diamond),
        iLoginWay = attr_new:get(?pd_platform_id),
        iRoleVipLevel = attr_new:get_vip_lvl(),
        iRoleGoldcount = 0,     %% TODO
        iRoleExpendGold = 0,    %% TODO
        vDeviceMac = attr_new:get(?pd_machine_mac, ""),
        vDeviceId = attr_new:get(?pd_machine_id, "")
    },
    route_write_log(Date, Log),
    ok.

info_account_logout(RoleId) ->
    Date = calendar:local_time(),
    Log = #account_logout_log
    {
        iEventId = get_event_id(?ACCOUNT_EXIT_LOG_EVT, Date, 0, 0, 0),
        iWorldId = erlang:get(?pd_server_id),
        iUin = erlang:get(?pd_user_id_log),
        dtEventTime = util:get_now_time(Date),
        iRoleId = RoleId,
        vRoleName = erlang:get(?pd_name),
        dtLoginTime = util:get_format_time(erlang:get(?pd_last_online_time)),
        vClientIp = attr_new:get(?pd_account_ip, 0),
        iOnlineTime = player:get_online_passed_time(),
        vDeviceMac = attr_new:get(?pd_machine_mac, ""),
        vDeviceId = attr_new:get(?pd_machine_id, ""),
        vDeviceStyle = attr_new:get(?pd_machine_style, ""),
        vDeviceInfo = attr_new:get(?pd_machine_info, "")
    },
    route_write_log(Date, Log),
    ok.

info_role_levelup(Level) ->
    Date = calendar:local_time(),
    Log = #role_level_up_log
    {
        iEventId = get_event_id(?ROLE_LEVEL_UP_EVT, Date, 0, 0, 0),
        iUin = erlang:get(?pd_user_id_log),
        dtEventTime = util:get_now_time(Date),
        iWorldId = erlang:get(?pd_server_id),
        iRoleId = attr_new:get(?pd_id),
        vRoleName = attr_new:get(?pd_name),
        iJobId = attr_new:get(?pd_career),
        iRoleLevel = Level,
        vUpLevelReason = 0,
        iXP = attr_new:get(?pd_exp),
        vDeviceMac = attr_new:get(?pd_machine_mac, ""),
        vDeviceId = attr_new:get(?pd_machine_id, ""),
        vDeviceInfo = attr_new:get(?pd_machine_info, ""),
        vDeviceStyle = attr_new:get(?pd_machine_style, "")
    },
    route_write_log(Date, Log),
    ok.

info_task_start(TaskId) ->
    Date = calendar:local_time(),
    Log = #task_start_log
    {
        iEventId = get_event_id(?TASK_START_LOG_EVT, Date, 0, 0, 0),
        iUin = erlang:get(?pd_user_id_log),
        dtEventTime = util:get_now_time(Date),
        iWorldId = erlang:get(?pd_server_id),
        iRoleId = attr_new:get(?pd_id),
        vRoleName = attr_new:get(?pd_name),
        iJobId = attr_new:get(?pd_career),
        iRoleLevel = attr_new:get(?pd_level),
        iTaskId = TaskId
    },
    route_write_log(Date, Log),
    ok.

info_finish_task(TaskId) ->
    Date = calendar:local_time(),
    Log = #task_finish_log
    {
        iEventId = get_event_id(?TASK_FINISH_LOG_EVT, Date, 0, 0, 0),
        iUin = erlang:get(?pd_user_id_log),
        dtEventTime = util:get_now_time(Date),
        iWorldId = erlang:get(?pd_server_id),
        iRoleId = attr_new:get(?pd_id),
        vRoleName = attr_new:get(?pd_name),
        iJobId = attr_new:get(?pd_career),
        iRoleLevel = attr_new:get(?pd_level),
        iTaskId = TaskId
    },
    route_write_log(Date, Log),
    ok.

%% arg = (充值后钻石，充值前钻石，充值流水号，充值渠道)
info_recharge_log(NewData, OldData, ITopupProtal, ITopuoWay) ->
    Date = calendar:local_time(),
    Log = #topup_log
    {
        iEventId = get_event_id(?TOPUP_LOG_EVT, Date, 0, 0, 0),
        dtEventTime = util:get_now_time(Date),
        iWorldId = erlang:get(?pd_server_id),
        iUin = erlang:get(?pd_user_id_log),
        iRoleId = attr_new:get(?pd_id),
        vRoleName = attr_new:get(?pd_name),
        vArriveAccount = erlang:get(?pd_user_id_log),
        vClientIp = attr_new:get(?pd_account_ip, 0),
        iTopupProtal = ITopupProtal,
        iPayBefore = OldData,
        iPayDelta = NewData - OldData,
        iPayAfter = NewData,
        iLoginWay = attr_new:get(?pd_platform_id),
        iTopuoWay = ITopuoWay,
        vPayAccount = erlang:get(?pd_user_id_log)
    },
    route_write_log(Date, Log),
    ok.

info_pay_log(Cost) ->
    Date = calendar:local_time(),
    Log = #pay_log
    {
        iEventId = get_event_id(?PAY_LOG_EVT, Date, 0, 0, 0),
        dtEventTime = util:get_now_time(Date),
        iWorldId = erlang:get(?pd_server_id),
        iRoleId = attr_new:get(?pd_id),
        vRoleName = attr_new:get(?pd_name),
        iUin = erlang:get(?pd_user_id_log),
        dtPayTime = util:get_now_time(Date),
        vClientIp = attr_new:get(?pd_account_ip, 0),
        vPayType = 0,
        iCost = Cost,
        iPayAfterGold = attr_new:get(?pd_diamond),
        iLoginWay = attr_new:get(?pd_platform_id),
        vDealType = 0,
        iGoldPay = 0,
        ibuyProtal = 0,
        vPayReason = 0
    },
    route_write_log(Date, Log),
    ok.

info_enter_copy(RoleId, RoomId) ->
    Date = calendar:local_time(),
    Log = #enter_copy_log
    {
        iEventId = get_event_id(?ENTER_COPY_LOG_EVT, Date, 0, 0, 0),
        dtEventTime = util:get_now_time(Date),
        iWorldId = erlang:get(?pd_server_id),
        iRoleId = RoleId,
        vRoleName = attr_new:get(?pd_name),
        iUin = erlang:get(?pd_user_id_log),
        iJobId = attr_new:get(?pd_career),
        iRoleLevel = attr_new:get(?pd_level),
        iAfterGoldNum = attr_new:get(?pd_diamond),
        iCopyId = RoomId
    },
    route_write_log(Date, Log),
    ok.

info_exit_copy(RoomId) ->
    Date = calendar:local_time(),
    Log = #exit_copy_log
    {
        iEventId = get_event_id(?EXIT_COPY_LOG_EVT, Date, 0, 0, 0),
        dtEventTime = util:get_now_time(Date),
        iWorldId = erlang:get(?pd_server_id),
        iCopyId = RoomId,
        iUin = erlang:get(?pd_user_id_log),
        iRoleId = attr_new:get(?pd_id),
        vRoleName = attr_new:get(?pd_name),
        iJobId = attr_new:get(?pd_career),
        iRoleLevel = attr_new:get(?pd_level),
        iExitGoldNum = attr_new:get(?pd_diamond)
    },
    route_write_log(Date, Log),
    ok.
info_finish_room(_, []) ->
    pass;
info_finish_room(InsId, StarList) -> %% todo
    [{6, ComboStar}, {2, BeatenStar}, {3, PassTimeStar}] = StarList,
    Date = calendar:local_time(),
    Log = #finish_copy_log
    {
        iEventId = get_event_id(?FINISH_COPY_LOG_EVT, Date, 0, 0, 0),
        dtEventTime = util:get_now_time(Date),
        iWorldId = erlang:get(?pd_server_id),
        iUin = erlang:get(?pd_user_id_log),
        iRoleId = attr_new:get(?pd_id),
        vRoleName = attr_new:get(?pd_name),
        iJobId = attr_new:get(?pd_career),
        iRoleLevel = attr_new:get(?pd_level),
        iCopyId = InsId,
        iMaxComboStarLv = ComboStar,
        iMinBeatenStarLv = BeatenStar,
        iPassTimeStarLv = PassTimeStar
    },
    route_write_log(Date, Log),
    ok.

info_star_shop_pay({StarLvBefore, StarLvAfter, Cost, GoodsId, Num}) ->
    Date = calendar:local_time(),
    Log = #star_shop_pay_log
    {
        iEventId = get_event_id(?STAR_SHOP_PAY_LOG_EVT, Date, 0, 0, 0),
        dtEventTime = util:get_now_time(Date),
        iWorldId = erlang:get(?pd_server_id),
        iUin = erlang:get(?pd_user_id_log),
        iRoleId = attr_new:get(?pd_id),
        vRoleName = attr_new:get(?pd_name),
        iJobId = attr_new:get(?pd_career),
        iRoleLevel = attr_new:get(?pd_level),
        iStarLvBefore = StarLvBefore,
        iStarLvAfter = StarLvAfter,
        iStarLvCost = Cost,
        iGoodsId = GoodsId,
        iGoodsNum = Num,
        vDeviceMac = attr_new:get(?pd_machine_mac, ""),
        vDeviceId = attr_new:get(?pd_machine_id, ""),
        vDeviceInfo = attr_new:get(?pd_machine_info, ""),
        vDeviceStyle = attr_new:get(?pd_machine_style, "")
    },
    route_write_log(Date, Log),
    ok.

info_longwen_levelup(LongwenLevelBefore, LongwenLevelAfter, LongwenId, MoneyBefore, MoneyCost) ->
    Date = calendar:local_time(),
    Log = #longwen_levelup_log
    {
        iEventId = get_event_id(?LONGWEN_LEVELUP_EVT, Date, 0, 0, 0),
        iWorldId = erlang:get(?pd_server_id),
        iUin = erlang:get(?pd_user_id_log),
        iRoleId = attr_new:get(?pd_id),
        vRoleName = attr_new:get(?pd_name),
        iJobId = attr_new:get(?pd_career),
        iRoleLevel = attr_new:get(?pd_level),

        iLongwenLevelBefore = LongwenLevelBefore,
        iLongwenLevelAfter = LongwenLevelAfter,
        iLongwenIdBefore = LongwenId,
        iLongwenIdAfter = LongwenId,
        iMoneyBefore = MoneyBefore,
        iMoneyCost = MoneyCost,
        iMoneyAfter = (MoneyBefore - MoneyCost),

        vDeviceMac = attr_new:get(?pd_machine_mac, ""),
        vDeviceId = attr_new:get(?pd_machine_id, ""),
        vDeviceInfo = attr_new:get(?pd_machine_info, ""),
        vDeviceStyle = attr_new:get(?pd_machine_style, "")
    },
    route_write_log(Date, Log),
    ok.

info_free_give_diamond(DiamondAfter, AddDiamond, Comment) ->
    Date = calendar:local_time(),
    Log = #free_give_diamond_log
    {
        iEventId = get_event_id(?GET_SYSTEM_DIAMOND_EVT, Date, 0, 0, 0),
        iWorldId = erlang:get(?pd_server_id),
        iUin = erlang:get(?pd_user_id_log),
        iRoleId = attr_new:get(?pd_id),
        vRoleName = attr_new:get(?pd_name),
        iJobId = attr_new:get(?pd_career),
        iRoleLevel = attr_new:get(?pd_level),

        iDiamondBefore = (DiamondAfter - AddDiamond),
        iDiamond = AddDiamond,
        iDiamondAfter = DiamondAfter,
        iComment = Comment,
        iIP = attr_new:get(?pd_account_ip, 0),
        vDeviceMac = attr_new:get(?pd_machine_mac, ""),
        vDeviceId = attr_new:get(?pd_machine_id, ""),
        vDeviceInfo = attr_new:get(?pd_machine_info, ""),
        vDeviceStyle = attr_new:get(?pd_machine_style, "")
    },
    route_write_log(Date, Log),
    ok.

info_get_item_log(ItemId, ItemType, ItemNumBefore, ItemNum, ItemUID, Reason) ->
    Date = calendar:local_time(),
    Log = #get_item_log
    {
        iEventId = get_event_id(?GET_ITEM_EVT, Date, 0, 0, 0),
        iWorldId = erlang:get(?pd_server_id),
        iUin = erlang:get(?pd_user_id_log),
        iRoleId = attr_new:get(?pd_id),
        vRoleName = attr_new:get(?pd_name),
        iJobId = attr_new:get(?pd_career),
        iRoleLevel = attr_new:get(?pd_level),

        iItemId = ItemId,
        iItemType = ItemType,
        iItemNumBefore = ItemNumBefore,
        iItemNumAfter = (ItemNumBefore + ItemNum),
        iItemNum = ItemNum,
        iItemUID = ItemUID,
        iReason = Reason,

        vDeviceMac = attr_new:get(?pd_machine_mac, ""),
        vDeviceId = attr_new:get(?pd_machine_id, ""),
        vDeviceInfo = attr_new:get(?pd_machine_info, ""),
        vDeviceStyle = attr_new:get(?pd_machine_style, "")
    },
    route_write_log(Date, Log),
    ok.

info_use_item_log(ItemId, ItemType, ItemNumBefore, ItemNum, ItemUID, Reason) ->
    Date = calendar:local_time(),
    Log = #use_item_log
    {
        iEventId = get_event_id(?USE_ITEM_EVT, Date, 0, 0, 0),
        iWorldId = erlang:get(?pd_server_id),
        iUin = erlang:get(?pd_user_id_log),
        iRoleId = attr_new:get(?pd_id),
        vRoleName = attr_new:get(?pd_name),
        iJobId = attr_new:get(?pd_career),
        iRoleLevel = attr_new:get(?pd_level),

        iItemId = ItemId,
        iItemType = ItemType,
        iUseItemBefore = ItemNumBefore,
        iUseItemAfter = (ItemNumBefore - ItemNum),
        iUseItemNum = ItemNum,
        iItemUID = ItemUID,
        iReason = Reason,

        vDeviceMac = attr_new:get(?pd_machine_mac, ""),
        vDeviceId = attr_new:get(?pd_machine_id, ""),
        vDeviceInfo = attr_new:get(?pd_machine_info, ""),
        vDeviceStyle = attr_new:get(?pd_machine_style, "")
    },
    route_write_log(Date, Log),
    ok.

info_item_trend_log(ItemType, ItemNum, ItemNumBefore, ItemNumAfter, ItemUID, Reason) ->
    Date = calendar:local_time(),
    Log = #item_trend_log
    {
        iEventId = get_event_id(?ITEM_FLOW_EVT, Date, 0, 0, 0),
        iWorldId = erlang:get(?pd_server_id),
        iUin = erlang:get(?pd_user_id_log),
        iRoleId = attr_new:get(?pd_id),
        vRoleName = attr_new:get(?pd_name),
        iJobId = attr_new:get(?pd_career),
        iRoleLevel = attr_new:get(?pd_level),

        iItemType = ItemType,
        iItemNum = ItemNum,
        iItemNumBefore = ItemNumBefore,
        iItemNumAfter = ItemNumAfter,
        iItemUID = ItemUID,
        trendId = 0,
        iReason = Reason,

        vDeviceMac = attr_new:get(?pd_machine_mac, ""),
        vDeviceId = attr_new:get(?pd_machine_id, ""),
        vDeviceInfo = attr_new:get(?pd_machine_info, ""),
        vDeviceStyle = attr_new:get(?pd_machine_style, "")
    },
    route_write_log(Date, Log),
    ok.


info_load_progress(Iprogress) ->
    case lists:member(Iprogress, ?INIT_LIST) of
        true ->
            do_progress_log(Iprogress);
        _ ->
            check_list(1, Iprogress)
    end.

info_delete_role(Id, Name, Career, Lev) ->
    Date = calendar:local_time(),
    Log = #delete_role_log
    {
        iEventId = get_event_id(?DELETE_ROLE_EVT, Date, 0, 0, 0),
        iWorldId = erlang:get(?pd_server_id),
        iUin = erlang:get(?pd_user_id_log),
        vClientIp = attr_new:get(?pd_account_ip, 0),
        iRoleId = Id,
        vRoleName = Name,
        iJobId = Career,
        iRoleLevel = Lev,
        vDeviceMac = attr_new:get(?pd_machine_mac, ""),
        vDeviceID = attr_new:get(?pd_machine_id, ""),
        vDeviceInfo = attr_new:get(?pd_machine_info, ""),
        vDeviceMes = attr_new:get(?pd_machine_style, "")
    },
    route_write_log(Date, Log),
    ok.

info_skill_levelup(IskillIdBefore, IskillIdAfter, ISkillLevelBefore, ISkillLevelAfter, IMoneyBefore, IMoneyCost, IMoneyAfter) ->
    Date = calendar:local_time(),
    Log = #skill_levelup_log
    {
        iEventId = get_event_id(?SKILL_LEVELUP_EVT, Date, 0, 0, 0),
        iWorldId = erlang:get(?pd_server_id),
        iUin = erlang:get(?pd_user_id_log),
        iRoleId = attr_new:get(?pd_id),
        vRoleName = attr_new:get(?pd_name),
        iJobId = attr_new:get(?pd_career),
        iRoleLevel = attr_new:get(?pd_level),
        iRoleExp = attr_new:get(?pd_exp),
        iSkillIdBefore = IskillIdBefore,
        iSkillIdAfter = IskillIdAfter,
        iSkillLevelBefore = ISkillLevelBefore,
        iSkillLevelAfter = ISkillLevelAfter,
        iMoneyBefore = IMoneyBefore,
        iMoneyCost = IMoneyCost,
        iMoneyAfter = IMoneyAfter,
        vDeviceMac = attr_new:get(?pd_machine_mac, ""),
        vDeviceID = attr_new:get(?pd_machine_id, ""),
        vDeviceInfo = attr_new:get(?pd_machine_info, ""),
        vDeviceMes = attr_new:get(?pd_machine_style, "")
    },
    route_write_log(Date, Log),
    ok.

info_role_offline() ->
    Date = calendar:local_time(),
    Log = #role_offline_log
    {
        iEventId = get_event_id(?OFF_LINE_EVT, Date, 0, 0, 0),
        iWorldId = erlang:get(?pd_server_id),
        iUin = erlang:get(?pd_user_id_log),
        iRoleId = attr_new:get(?pd_id),
        vRoleName = attr_new:get(?pd_name),
        vClientIp = attr_new:get(?pd_account_ip, 0),
        port = attr_new:get(?pd_account_port, 0),
        offlineType = 1,
        vDeviceMac = attr_new:get(?pd_machine_mac, ""),
        vDeviceID = attr_new:get(?pd_machine_id, "")
    },
    route_write_log(Date, Log),
    ok.

info_phase_achievement(PhaseLevel) ->
    Date = calendar:local_time(),
    Log = #player_phase_achievement_log
    {
        iEventId = get_event_id(?PHASE_ACHIEVEMENT, Date, 0, 0, 0),
        iWorldId = erlang:get(?pd_server_id),
        iUin = erlang:get(?pd_user_id_log),
        iRoleId = attr_new:get(?pd_id),
        vRoleName = attr_new:get(?pd_name),
        iJobId = attr_new:get(?pd_career),
        iRoleLevel = attr_new:get(?pd_level),
        iPhaseId = PhaseLevel,
        vDeviceMac = attr_new:get(?pd_machine_mac, ""),
        vDeviceID = attr_new:get(?pd_machine_id, ""),
        vDeviceInfo = attr_new:get(?pd_machine_info, ""),
        vDeviceMes = attr_new:get(?pd_machine_style, "")
    },
    route_write_log(Date, Log),
    ok.

info_get_mail(SendMailPlayerId, CurrentTime, VmailName, VmailContent) ->
    Date = calendar:local_time(),
    Log = #player_get_mail_log
    {
        iEventId = get_event_id(?GET_MAIL_EVT, Date, 0, 0, 0),
        iWorldId = erlang:get(?pd_server_id),
        iUin = erlang:get(?pd_user_id_log),
        dtGetTime = CurrentTime,
        iRoleId = attr_new:get(?pd_id),
        vRoleName = attr_new:get(?pd_name),
        iRoleLevel = attr_new:get(?pd_level),
        iSendRoleId = SendMailPlayerId, 
        vMailName = VmailName,
        vMailContent = VmailContent,
        vDeviceMac = attr_new:get(?pd_machine_mac, ""),
        vDeviceID = attr_new:get(?pd_machine_id, ""),
        vDeviceInfo = attr_new:get(?pd_machine_info, ""),
        vDeviceMes = attr_new:get(?pd_machine_style, "")
    },
    route_write_log(Date, Log),
    ok.

check_list(A, B) ->
    case A =< B of
        true ->
            List = ?INIT_LIST ++ get(pd_iprogress_list),
            case lists:member(A, List) of
                true ->
                    ignore,
                    check_list(A + 1, B);
                _ ->
                    do_progress_log(A),
                    check_list(A + 1, B)
            end;
        _ ->
            ignore
    end.

do_progress_log(Iprogress) ->
    Date = calendar:local_time(),
    Log = #load_progress_log
    {
        iEventId = get_event_id(?LOAD_PROGRESS, Date, 0, 0, 0),
        dtEventTime = util:get_now_time(Date),
        iWorldId = erlang:get(?pd_server_id),
        iUin = erlang:get(?pd_user_id_log),
        iRoleId = attr_new:get(?pd_id),
        vRoleName = attr_new:get(?pd_name),
        iRoleLevel = case attr_new:get(?pd_level) of
            undefined -> 0;
            E -> E
        end,
        iPower = case get(?pd_combat_power) of
            undefined -> 0;
            E -> E
        end,
        iProgress = Iprogress
    },
    route_write_log(Date, Log),
    List = get(pd_iprogress_list),
    put(pd_iprogress_list, [Iprogress | List]),
    ok.

info_copy_die(CopyId) ->
    Date = calendar:local_time(),
    Log = #player_copy_die_log
    {
        iEventId = get_event_id(?PLAYER_FUBEN_DIE_EVT, Date, 0, 0, 0),
        iWorldId = erlang:get(?pd_server_id),
        iUin = erlang:get(?pd_user_id_log),
        dtDieTime = util:get_now_time(Date),
        iRoleId = attr_new:get(?pd_id),
        vRoleName = attr_new:get(?pd_name),
        iJobId = attr_new:get(?pd_career),
        iRoleLevel = attr_new:get(?pd_level),
        iCopyId = CopyId,
        vMac = attr_new:get(?pd_machine_mac, ""),
        vDeviceId = attr_new:get(?pd_machine_id, ""),
        vDeviceInfo = attr_new:get(?pd_machine_style, ""),
        vDeviceMac = attr_new:get(?pd_machine_info, "")
    },
    route_write_log(Date, Log),
    ok.

info_mail_attach(SendRoleId, MailName, ItemId, ItemCount) ->
    Date = calendar:local_time(),
    Log = #player_get_mail_attach_log
    {
        iEventId = get_event_id(?GET_MAIL_ATTACH_EVT, Date, 0, 0, 0),
        iWorldId = erlang:get(?pd_server_id),
        iUin = erlang:get(?pd_user_id_log),
        dtGetTime = util:get_now_time(Date),
        iRoleId = attr_new:get(?pd_id),
        vRoleName = attr_new:get(?pd_name),
        iRoleLevel = attr_new:get(?pd_level),
        iSendRoleId = SendRoleId,
        vMailName = MailName,
        iItemId = ItemId,
        iItemCount = ItemCount,
        vMac = attr_new:get(?pd_machine_mac, ""),
        vDeviceId = attr_new:get(?pd_machine_id, ""),
        vDeviceInfo = attr_new:get(?pd_machine_style, ""),
        vDeviceMac = attr_new:get(?pd_machine_info, "")
    },
    route_write_log(Date, Log),
    ok.

%% 拍卖行寄售日志
info_auction_sell_log(GoodsId, GoodsType, Price) ->
    Date = calendar:local_time(),
    Log = #auction_sell_log
    {
        iEventId = get_event_id(?AUCTION_SELL_EVT, Date, 0, 0, 0),
        iWorldId = erlang:get(?pd_server_id),
        iUin = erlang:get(?pd_user_id_log),
        dtSellTime = util:get_now_time(Date),
        iRoleId = attr_new:get(?pd_id),
        vRoleName = get(?pd_name),
        iJobId = get(?pd_career),
        iRoleLevel = get(?pd_level),
        iGoodsId = GoodsId,
        iType = GoodsType,
        iPrice = Price,
        vDeviceMac = attr_new:get(?pd_machine_mac, ""),
        vDeviceId = attr_new:get(?pd_machine_id, ""),
        vDeviceInfo = attr_new:get(?pd_machine_info, ""),
        vDeviceMes = attr_new:get(?pd_machine_style, "")
    },
    route_write_log(Date, Log),
    ok.

%% 拍卖行购买日志
info_auction_buy_log(MoneyBefore, MoneyAfter, GoodsId, Count, Price, SellerId) ->
    Date = calendar:local_time(),
    Log = #auction_buy_log
    {
        iEventId = get_event_id(?AUCTION_BUY_EVT, Date, 0, 0, 0),
        iWorldId = erlang:get(?pd_server_id),
        iUin = erlang:get(?pd_user_id_log),
        dtBuyTime = util:get_now_time(Date),
        iRoleId = attr_new:get(?pd_id),
        vRoleName = get(?pd_name),
        iJobId = get(?pd_career),
        iRoleLevel = get(?pd_level),
        iMoneyBefore = MoneyBefore,
        iMoneyAfter = MoneyAfter,
        iGoodsId = GoodsId,
        iCount = Count,
        iPrice = Price,
        iSellerId = SellerId,
        vDeviceMac = attr_new:get(?pd_machine_mac, ""),
        vDeviceId = attr_new:get(?pd_machine_id, ""),
        vDeviceInfo = attr_new:get(?pd_machine_info, ""),
        vDeviceMes = attr_new:get(?pd_machine_style, "")
    },
    route_write_log(Date, Log),
    ok.

%% 玩家聊天日志
info_player_chat_log(Channel, Content) ->
    Date = calendar:local_time(),
    Log = #player_chat_log
    {
        iEventId = get_event_id(?PLAYRE_CHAT_EVT, Date, 0, 0, 0),
        iUin = erlang:get(?pd_server_id),
        dtChatTime = util:get_now_time(Date),
        iRoleId = get(?pd_id),
        vRoleName = get(?pd_name),
        iRoleLevel = get(?pd_level),
        vAddressIP = attr_new:get(?pd_account_ip, 0),
        iChannel = Channel,
        iContent = Content,
        vDeviceMac = attr_new:get(?pd_machine_mac, ""),
        vDeviceId = attr_new:get(?pd_machine_id, ""),
        vDeviceInfo = attr_new:get(?pd_machine_info, ""),
        vDeviceMes = attr_new:get(?pd_machine_style, "")
    },
    route_write_log(Date, Log),
    ok.

%% 玩家竞技场死亡日志
info_player_arena_die_log(KillerId,KillerName,KillerCareer,KillerLevel, RoomId, KillerRank, KillerHonour) ->
    Date = calendar:local_time(),
    Log = #player_arena_die_log
    {
        iEventId = get_event_id(?PLAYER_ARENA_DIE_EVT, Date, 0, 0, 0),
        iWorldId = erlang:get(?pd_server_id),
        iUin = erlang:get(?pd_user_id_log),
        dtDieTime = util:get_now_time(Date),
        iRoleId = attr_new:get(?pd_id),
        vRoleName = erlang:get(?pd_name),
        iJobId = attr_new:get(?pd_career),
        iRoleLevel = attr_new:get(?pd_level),
        iKillerId = KillerId,
        vKillerName = KillerName,
        iKillerJobId = KillerCareer,
        iKillerLevel = KillerLevel,
        iCopyId = RoomId,
        iKillerRank = KillerRank,
        iKillerHonour = KillerHonour,
        iRoleRank = erlang:get(?pd_arena_attr_id), %% 竞技段位
        iRoleHonour = erlang:get(?pd_honour),
        vDeviceMac = attr_new:get(?pd_machine_mac, ""),
        vDeviceId = attr_new:get(?pd_machine_id, ""),
        vDeviceInfo = attr_new:get(?pd_machine_info, ""),
        vDeviceMes = attr_new:get(?pd_machine_style, "")
    },
%%    ?INFO_LOG("Date:~p, ========Log:~p",[Date,Log]),
    route_write_log(Date, Log),
    ok.

%% 从NPC处购买日志
info_npc_buy_log(MoneyBefore, MoneyAfter, NPCId, NPCName, ItemPay, ItemId, ItemType, BuyItemCount, GetItemCount) ->
    Date = calendar:local_time(),
    Log = #npc_buy_log
    {
        iEventId = get_event_id(?NPC_BUY_EVT, Date, 0, 0, 0),
        iWorldId = erlang:get(?pd_server_id),
        iUin = erlang:get(?pd_user_id_log),
        dtDealTime = util:get_now_time(Date),
        iRoleId = attr_new:get(?pd_id),
        vRoleName = erlang:get(?pd_name),
        iJobId = attr_new:get(?pd_career),
        iRoleLevel = attr_new:get(?pd_level),
        iMoneyBefore = MoneyBefore,
        iMoneyAfter = MoneyAfter,
        iNPCId = NPCId,
        vNPCName = NPCName,
        iItemPay = ItemPay,
        iItemId = ItemId,
        iItemType = ItemType,
        iBuyItemCount = BuyItemCount,
        iGetItemCount = GetItemCount,
        vDeviceMac = attr_new:get(?pd_machine_mac, ""),
        vDeviceId = attr_new:get(?pd_machine_id, ""),
        vDeviceInfo = attr_new:get(?pd_machine_info, ""),
        vDeviceMes = attr_new:get(?pd_machine_style, "")
    },
%%    ?INFO_LOG("Date:~p, ========Log:~p",[Date,Log]),
    route_write_log(Date, Log),
    ok.

%% 金钱流动日志
info_money_flow_log(MoneyBefore, MoneyAfter, MoneyCount, MoneyType, FlowId, FlowReason) ->
    Date = calendar:local_time(),
    Log = #money_flow_log
    {
        iEventId = get_event_id(?MONEY_FLOW_EVT, Date, 0, 0, 0),
        iWorldId = erlang:get(?pd_server_id),
        iUin = erlang:get(?pd_user_id_log),
        dtMoneyFlowTime = util:get_now_time(Date),
        iRoleId = attr_new:get(?pd_id),
        vRoleName = erlang:get(?pd_name),
        iJobId = attr_new:get(?pd_career),
        iRoleLevel = attr_new:get(?pd_level),
        iMoneyBefore = MoneyBefore,
        iMoneyAfter = MoneyAfter,
        iMoneyCount = MoneyCount,
        iMoneyType = MoneyType,
        iFlowId = FlowId,
        vFlowReason = FlowReason,
        vDeviceMac = attr_new:get(?pd_machine_mac, ""),
        vDeviceId = attr_new:get(?pd_machine_id, ""),
        vDeviceInfo = attr_new:get(?pd_machine_info, ""),
        vDeviceMes = attr_new:get(?pd_machine_style, "")
    },
%%    ?INFO_LOG("=============================================="),
%%    ?INFO_LOG("Date:~p, ========Log:~p",[Date,Log]),
    route_write_log(Date, Log),
    ok.

%% 购买vip日志
info_player_vip_log(VipLevel) ->
    Date = calendar:local_time(),
    Log = #player_vip_log
    {
        iEventId = get_event_id(?PLAYER_VIP_EVT, Date, 0, 0, 0),
        iWorldId = erlang:get(?pd_server_id),
        dtEventTime = util:get_now_time(Date),
        iUin = erlang:get(?pd_user_id_log),
        iRoleId = attr_new:get(?pd_id),
        vRoleName = erlang:get(?pd_name),
        iVipLevel = VipLevel,
        vMac = attr_new:get(?pd_machine_mac, ""),
        vDeviceId = attr_new:get(?pd_machine_id, ""),
        vDeviceInfo = attr_new:get(?pd_machine_info, ""),
        vDeviceMes = attr_new:get(?pd_machine_style, "")
    },
%%    ?INFO_LOG("=============================================="),
%%    ?INFO_LOG("Date:~p, ========Log:~p",[Date,Log]),
    route_write_log(Date, Log),
    ok.
%% 玩家套装日志
info_suit_log(SuitId, SuitLevel) ->
    Date = calendar:local_time(),
    Log = #player_suit_log
    {
        iEventId = get_event_id(?PLAYER_SUIT_EVT, Date, 0, 0, 0),
        iWorldId = erlang:get(?pd_server_id),
        dtEventTime = util:get_now_time(Date),
        iUin = erlang:get(?pd_user_id_log),
        iRoleId = attr_new:get(?pd_id),
        vRoleName = erlang:get(?pd_name),
        iSuitId = SuitId,
        iSuitLevel = SuitLevel,
        vMac = attr_new:get(?pd_machine_mac, ""),
        vDeviceId = attr_new:get(?pd_machine_id, ""),
        vDeviceInfo = attr_new:get(?pd_machine_info, ""),
        vDeviceMes = attr_new:get(?pd_machine_style, "")
    },
    % ?INFO_LOG("=============================================="),
    % ?INFO_LOG("Date:~p, ========Log:~p",[Date,Log]),
    route_write_log(Date, Log),
    ok.

%% 坐骑进阶日志
info_ride_phase(RideId, LevBefore, LevAfter) ->
    Date = calendar:local_time(),
    Log = #ride_phase_log
    {
        iEventId = get_event_id(?RIDE_PHASE_EVT, Date, 0, 0, 0),
        iWorldId = erlang:get(?pd_server_id),
        dtEventTime = util:get_now_time(Date),
        iUin = erlang:get(?pd_user_id_log),
        iRoleId = attr_new:get(?pd_id),
        vRoleName = erlang:get(?pd_name),
        iRoleLevel = attr_new:get(?pd_level),
        iPower = get(?pd_combat_power),
        iRideId = RideId,
        iRideLevBefore = LevBefore,
        iRideLevAfter = LevAfter
    },
    % ?INFO_LOG("=============================================="),
    % ?INFO_LOG("Date:~p, ========Log:~p",[Date,Log]),
    route_write_log(Date, Log),
    ok.

%% 宠物进阶日志
info_pet_phase(PetId, LevBefore, LevAfter) ->
    Date = calendar:local_time(),
    Log = #pet_phase_log
    {
        iEventId = get_event_id(?PET_PHASE_EVT, Date, 0, 0, 0),
        iWorldId = erlang:get(?pd_server_id),
        dtEventTime = util:get_now_time(Date),
        iUin = erlang:get(?pd_user_id_log),
        iRoleId = attr_new:get(?pd_id),
        vRoleName = erlang:get(?pd_name),
        iRoleLevel = attr_new:get(?pd_level),
        iPower = get(?pd_combat_power),
        iPetId = PetId,
        iPetLevBefore = LevBefore,
        iPetLevAfter = LevAfter
    },
    % ?INFO_LOG("=============================================="),
    % ?INFO_LOG("Date:~p, ========Log:~p",[Date,Log]),
    route_write_log(Date, Log),
    ok.

%% 在线人数日志 (每五分钟记录一次)
info_online_count(Count) ->
    Date = calendar:local_time(),
    #{platform_id := _PlatformId, id := ServerId} = global_data:get_server_info(),
    Log = #online_count{
        dtEventTime = util:get_now_time(Date),
        iEventId = get_event_id(?ONLINE_COUNT_EVT, Date, 0, 0, 0),
        iWorldId = ServerId,
        iAccountCount = Count
    },
    % ?INFO_LOG("=============================================="),
    % ?INFO_LOG("Date:~p, ========Log:~p",[Date,Log]),
    route_write_log(Date, Log, system_log),
    ok.

get_event_id(EventId, Date, MapId, MapX, MapY) ->
    {{DY, DM, DD}, {H, M, S}} = Date,
    EventId ++ integer_to_list(DY) ++ append_to_string(DM) ++ append_to_string(DD) ++ append_to_string(H) ++
        append_to_string(M) ++ append_to_string(S) ++ integer_to_list(MapId) ++ integer_to_list(MapX) ++ integer_to_list(MapY).

append_to_string(Num) ->
    case Num < 10 of
        true ->
            "0" ++ integer_to_list(Num);
        _ ->
            integer_to_list(Num)
    end.

route_write_log(Date, Log) ->
    case robot_new:is_robot(get(?pd_id)) orelse erlang:get(?pd_user_id_log) =:= undefined of
        true ->
            pass;
        _ ->
            #{id := ServerId, logsrv_node_name := LogSrvNodeName} = global_data:get_server_info(),
            rpc:cast(LogSrvNodeName, log_center_server, do_log, [{ServerId, Date, Log}])
    end.

route_write_log(Date, Log, system_log) ->
    #{id := ServerId, logsrv_node_name := LogSrvNodeName} = global_data:get_server_info(),
    rpc:cast(LogSrvNodeName, log_center_server, do_log, [{ServerId, Date, Log}]).