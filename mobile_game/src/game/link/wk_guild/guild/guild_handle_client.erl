%%%-------------------------------------------------------------------
%%% @author 余健
%%% @doc 玩家公会功能收发协议
%%%
%%% @end
%%%-------------------------------------------------------------------
-module(guild_handle_client).

-include("inc.hrl").
-include("player.hrl").
-include("handle_client.hrl").



-include("achievement.hrl").

-include("item.hrl"). %消耗道具和货币调用item表的数据
-include("item_bucket.hrl").

-include("load_cfg_guild.hrl").
-include("load_phase_ac.hrl").
-include("load_cfg_guild_saint.hrl").

-include("guild_define.hrl").
-include("rank.hrl").
-include("../../wk_player/part/wonderful_activity/bounty_struct.hrl").
-include("system_log.hrl").
-include("../../wk_open_server_happy/open_server_happy.hrl").

-define(REQ_GUILD_OK, 0).

-export
([
    handle_msg/2
]).



handle_client({?MSG_GUILD_DATA_LIST, {PageStart, PageEnd}}) ->
    handle_client(?MSG_GUILD_DATA_LIST, {PageStart, PageEnd});
handle_client({Pack, Arg}) ->
    case task_open_fun:is_open(?OPEN_GUILD) of
        ?false -> ?return_err(?ERR_GUILD_NOT_JOIN);
        ?true -> handle_client(Pack, Arg)
    end.

handle_client(?MSG_GUILD_DATA_LIST, {PageStart, PageEnd}) ->
    %?DEBUG_LOG("MSG_GUILD_DATA_LIST----------------------------"),

    ?ifdo(com_ets:table_size(?guild_tab) =:= 0,
        ?player_send(guild_sproto:pkg_msg(?MSG_GUILD_DATA_LIST, {[]}))),

    ?ifdo(PageStart =< 0 orelse PageEnd >= ?GUILD_MAX_NUM orelse PageStart >= PageEnd orelse ((PageEnd - PageStart) > ?PageMaxNum),
        ?return_err(?ERR_GUILD_PROTO_ARG_ERROR)),

    ?player_send(guild_sproto:pkg_msg(?MSG_GUILD_DATA_LIST,
        {guild_service:select_guildList(PageStart, PageEnd)}));

handle_client(?MSG_GUILD_MEMBER_LIST, {}) ->
    GuildId = get(?pd_guild_id),

    ?ifdo(?is_not_join_guild(),
        ?return_err(?ERR_GUILD_NOT_JOIN)),

    [#guild_player_association_tab{player_list = PlayerList}] = dbcache:lookup(?guild_player_association_tab, GuildId),
    %?DEBUG_LOG("MSG_GUILD_MEMBER_LIST------------:~p-------PlayerList---:~p---PlayerId---:~p",[GuildId, PlayerList, get(?pd_id)]),
    MemberList = guild_member_list(GuildId, lists:delete(get(?pd_id), PlayerList)),
    ?player_send(guild_sproto:pkg_msg(?MSG_GUILD_MEMBER_LIST, {MemberList}));

%% 分页获取公会事件信息
handle_client(?MSG_GUILD_EVENT_LIST, {PageStart, PageEnd}) ->
    GuildId = get(?pd_guild_id),
    %?DEBUG_LOG("MSG_GUILD_EVENT_LIST----------------------------:~p",[GuildId]),
    ?ifdo(?is_not_join_guild(),
        ?return_err(?ERR_GUILD_NOT_JOIN)),

    ?ifdo(PageStart =< 0 orelse PageEnd >= ?EVENT_MAX_NUM orelse PageStart >= PageEnd orelse ((PageEnd - PageStart) > ?PageMaxNum),
        ?return_err(?ERR_GUILD_PROTO_ARG_ERROR)),

    [#guild_event_tab{event_list = EventList}] = dbcache:lookup(?guild_event_tab, GuildId),
    EventSubList = lists:sublist(EventList, PageStart, (PageEnd - PageStart + 1)),
    FunMap = fun({TypeId, Content, Time}) ->
        case Content of
            {PlayerId, PlayerName} -> {TypeId, Time, PlayerId, PlayerName, 0};
            {Arg1, Arg2, Arg3} -> {TypeId, Time, Arg1, Arg2, Arg3}
        end
    end,
    EventResList =
        case EventSubList of
            [] -> [];
            EventSubList -> lists:map(FunMap, EventSubList)
        end,
    ?player_send(guild_sproto:pkg_msg(?MSG_GUILD_EVENT_LIST, {EventResList}));

%% 获取公会信息
handle_client(?MSG_GUILD_INFO, {}) ->
    GuildId = get(?pd_guild_id),
    %?DEBUG_LOG("MSG_GUILD_INFO----------------------------:~p",[GuildId]),

    ?ifdo(?is_not_join_guild(),?return_err(?ERR_GUILD_NOT_JOIN)),

    {{TotemId, BorderId, GuildName, GuildId},
        {GuildRank, GuildLv, GuildExp, MasterName, MasterId, TotlePlayer, Notice, NoticeUpdateTime}} = guild_service:select_guild_info(GuildId),

    [#guild_buildings_tab{building_list = BuildingsData}] = dbcache:lookup(?guild_buildings_tab, GuildId),
    PlayerDailyTaskCount = get(?pd_guild_daily_task_count),
    Fun = fun({BuildingType, BuildingLv, BuildingExp}) ->
        case lists:keyfind(BuildingType, 1, PlayerDailyTaskCount) of
            false -> {BuildingType, 0, BuildingLv, BuildingExp};
            {_, BuildingDailyTaskCount} -> {BuildingType, BuildingDailyTaskCount, BuildingLv, BuildingExp}
        end
    end,
    BuildingInfoList = lists:map(Fun, BuildingsData),

    GuildInfo = {TotemId, BorderId, GuildLv, GuildName, MasterName, MasterId, TotlePlayer,
        GuildId, GuildRank, Notice, NoticeUpdateTime,
        GuildExp, get(?pd_guild_position),
        get(?pd_guild_lv), get(?pd_guild_exp), get(?pd_guild_totle_contribution), BuildingInfoList, get(?pd_guild_tech_items)},
    guild_mng:push_guild_saint_list(),
    ?player_send(guild_sproto:pkg_msg(?MSG_GUILD_INFO, GuildInfo));

%% 获取公会申请人列表
handle_client(?MSG_GUILD_APPLY_LIST, {}) ->
    GuildId = get(?pd_guild_id),
    ?ifdo(?is_not_join_guild(),
        ?return_err(?ERR_GUILD_NOT_JOIN)),

    case guild_service:ets_lookup(GuildId, #player_apply_tab.guild_id) of
        [] ->
            ?player_send(guild_sproto:pkg_msg(?MSG_GUILD_APPLY_LIST, {[]}));

        PlayerIdList ->
            FunMap = fun(PlayerId) ->
                [CareerId, PlayerLv, PlayerName, CombatPower] =
                    player:lookup_info(PlayerId, [?pd_career, ?pd_level, ?pd_name, ?pd_combat_power]),
                IsOnline = ?if_else(world:is_player_online(PlayerId), ?IS_ONLINE, ?IS_OFFLINE),
                {PlayerId, CareerId, PlayerLv, PlayerName, CombatPower, IsOnline}
            end,
%%            ?INFO_LOG("Guild apply List: ~p  ++++++++++++++++++++", [PlayerIdList]),
            ?player_send(guild_sproto:pkg_msg(?MSG_GUILD_APPLY_LIST, {lists:map(FunMap, PlayerIdList)}))
    end;

%% 创建公会
handle_client(?MSG_GUILD_CREATE, {GuildNameBin, TotemId, BorderId}) ->
    ?ifdo(?is_join_guild(),
        ?return_err(?ERR_GUILD_HAS_GUILD)),

    ?ifdo(GuildNameBin =:= <<>> orelse com_string:utf_length(GuildNameBin) > ?GUILD_NAME_MAX_SIZE,
        ?return_err(?ERR_GUILD_INVALID_GUILDNAME)),

    case create_guild(GuildNameBin, TotemId, BorderId) of
        {error, ErrCode} ->
            ?return_err(ErrCode);
        ok ->
            achievement_mng:do_ac(?gonghuishouling),
            ?player_send(guild_sproto:pkg_msg(?MSG_GUILD_CREATE, {}))
    end;

%% 修改公告
%% handle_client(?MSG_GUILD_UPDATE_NOTICE, {NoticeBin}) ->
%%     GuildId = get(?pd_guild_id),
%% %%     RecordId = guild_boss:get_guild_boss_recordid(),
%% %%     Ret = guild_boss:can_action(?GUILD_BOSS_DONATE, {RecordId}),
%% %%     guild_boss:action(?GUILD_BOSS_DONATE, {RecordId}),
%% %%     ?INFO_LOG("MSG_GUILD_UPDATE_NOTICE ~p", [Ret]),
%%
%% %%     RecordId = guild_boss:get_guild_boss_recordid(),
%% %%     Ret = guild_boss:can_action(?GUILD_BOSS_PHASE, {RecordId}),
%% %%     guild_boss:action(?GUILD_BOSS_PHASE, {RecordId}),
%% %%     ?INFO_LOG("MSG_GUILD_UPDATE_NOTICE ~p", [Ret]),
%%
%%     RecordId = guild_boss:get_guild_boss_recordid(),
%%     Ret = guild_boss:can_action(?GUILD_BOSS_CALL, {RecordId}),
%%     guild_boss:action(?GUILD_BOSS_CALL, {RecordId}),
%%     ?INFO_LOG("MSG_GUILD_UPDATE_NOTICE ~p", [Ret]),
%%
%%
%% %%     guild_boss:broadcast_mes(GuildId, "已召唤BOSS"),
%% %%     world:broadcast(?to_client_msg(chat_sproto:pkg_msg(?MSG_CHAT_SYSTEM, {list_to_binary("123")}))),
%%
%% %%     guild_boss:action(?GUILD_BOSS_DONATE),
%% %%     Ret = guild_boss:get_boss_info(),
%% %%     ?INFO_LOG("MSG_GUILD_SEARCH ~p ", [Ret]),
%% %%     guild_boss:action(?GUILD_BOSS_DONATE),
%% %%     guild_boss:action(?GUILD_BOSS_PHASE),
%% %%     #guild_boss{field = List} = guild_boss:action(?GUILD_BOSS_CALL),
%% %%     ?INFO_LOG("MSG_GUILD_SEARCH ~p 2 ", [List]),
%% %%     guild_boss:sync_boss_info(),
%% %%     util:get_pd_field(?pd_guild_boss_donate, 3),
%%     gen_server:call
%%     (
%%         guild_service,
%%         {
%%             guild_boss,
%%             #guild_boss_reset
%%             {
%%                 guild_id = GuildId
%%             }
%%         }
%%     ),
%%
%%     ?player_send(guild_sproto:pkg_msg(?MSG_GUILD_UPDATE_NOTICE, {}));

handle_client(?MSG_GUILD_UPDATE_NOTICE, {NoticeBin}) ->
    GuildId = get(?pd_guild_id),
    ?ifdo(?is_not_join_guild(),
        ?return_err(?ERR_GUILD_NOT_JOIN)),

    ?ifdo(is_have_permission(?GUILD_UPDATE_NOTICE) =:= ?false,
        ?return_err(?ERR_GUILD_NOT_PERMISSION)),

    ?ifdo(com_string:utf_length(NoticeBin) > ?GUILD_NOTICE_MAX_SIZE,
        ?return_err({?ERR_GUILD_INVALID_NOTICE})),

    NowTimer = com_time:now(),
    [GuildTab] = guild_service:lookup_tab(?guild_tab, GuildId),
    guild_service:update_guild_data_to_ets(?guild_tab, GuildTab#guild_tab{notice = NoticeBin, notice_update_time = NowTimer}),
    ?player_send(guild_sproto:pkg_msg(?MSG_GUILD_UPDATE_NOTICE, {}));

%% 职位变更
handle_client(?MSG_GUILD_POSITION, {SetPlayerId, ToPositionId}) ->
    GuildId = get(?pd_guild_id),
%%    ?INFO_LOG("guild id:~p,~p",[GuildId,(get(?pd_guild_id) =:= 0) orelse (get(?pd_guild_id) =:= ?undefined)]),
    ?ifdo(?is_not_join_guild(),
        ?return_err(?ERR_GUILD_NOT_JOIN)),

    ToPlayerId = if
                     SetPlayerId =:= 0 -> get(?pd_id);
                     true -> SetPlayerId
                 end,

%%    ?INFO_LOG("playerid: ~p , position:~p", [ToPlayerId,((ToPlayerId =:= get(?pd_id)) and (get(?pd_guild_position) =:= ?GUILD_MASTER_POSITIONID))]),
    ?ifdo((ToPlayerId =:= get(?pd_id)) and (get(?pd_guild_position) =:= ?GUILD_MASTER_POSITIONID),
        ?return_err(?ERR_GUILD_MASTER_CONNOT_CHANGE_POSITION)),

    case set_player_position(ToPlayerId, GuildId, ToPositionId) of
        ok ->
            ?player_send(guild_sproto:pkg_msg(?MSG_GUILD_POSITION, {SetPlayerId, ToPositionId}));
        {error, ErrCode} ->
            ?return_err(ErrCode)
    end;

%% 剔除公会
handle_client(?MSG_GUILD_PLAYERDEL, {ToPlayerId}) ->
    GuildId = get(?pd_guild_id),
    ?DEBUG_LOG("MSG_GUILD_PLAYERDEL----------------------:~p",[ToPlayerId]),
    ?ifdo(?is_not_join_guild(),?return_err(?ERR_GUILD_NOT_JOIN)),
    State = 
    case dbcache:lookup(?player_guild_member, ToPlayerId) of
        [] -> 
            {error, ?ERR_GUILD_OTHER_PLAYER_NOT_JOIN_GUILD};
        [#player_guild_member{player_position = ?GUILD_MASTER_POSITIONID}] -> %会长
            {error, ?ERR_GUILD_MASTER_CONNOT_QUIT};
        [ToGuildMemberTab] ->
            ToPlayerPosition = ToGuildMemberTab#player_guild_member.player_position,
            ToGuildId = ToGuildMemberTab#player_guild_member.guild_id,
            GuildId = get(?pd_guild_id),
            ?ifdo(GuildId /= ToGuildId, ?return_err(?ERR_GUILD_NOT_IN_SAMEGUILD)),
            if
                ToPlayerPosition =:= ?GUILD_VICE_MASTER_POSTION -> %副会长只能被会长剔除
                    case is_have_permission(?GUILD_REMOVE_VICE_MATER) of
                        ?false -> 
                            {error, ?ERR_GUILD_NOT_PERMISSION};
                        ?true -> 
                            remove_player(ToPlayerId, ToGuildId)
                    end;
                ToPlayerPosition =:= ?GUILD_MEMBER_POSTION ->
                    case is_have_permission(?GUILD_REMOVE_MEMBER) of
                        ?false -> 
                            {error, ?ERR_GUILD_NOT_PERMISSION};
                        ?true -> 
                            remove_player(ToPlayerId, ToGuildId)
                    end;
                true ->
                    {error, ?ERR_GUILD_NO_THIS_POSITION}
            end
    end,
    case State of
        ok ->
            ?player_send(guild_sproto:pkg_msg(?MSG_GUILD_PLAYERDEL, {ToPlayerId}));
        {error, ErrCode} -> 
            ?return_err(ErrCode)
    end;

%% 同意/拒绝单人玩家入会
handle_client(?MSG_GUILD_ROLE_APPLY, {Type, ToPlayerId}) ->
    GuildId = get(?pd_guild_id),
    ?ifdo(?is_not_join_guild(),
        ?return_err(?ERR_GUILD_NOT_JOIN)),
    ?ifdo(is_have_permission(?GUILD_APPLY_AGREE_OR_REFUSED) =:= ?false,
        ?return_err(?ERR_GUILD_NOT_PERMISSION)),
    State = case Type of
                1 -> %%同意该玩家入会
                    clear_add_other_apply(ToPlayerId, GuildId),                            %% 清除该玩家加入其它公会的申请
                    case batch_apply_player([ToPlayerId], GuildId) of
                        {{error, Other}, _} -> {error, Other};
                        [] -> ok;
                        [PlayerId] ->
                            MemberList = guild_member_list(GuildId, [PlayerId]),
                            guild_mng:push_guild_member_join(GuildId, MemberList),
                            guild_service:delete_apply_player(clear_player_apply_info, ToPlayerId),
                            ok
                    end;
                2 -> %%拒绝该玩家入会
                    guild_service:delete_apply_player(ToPlayerId, GuildId), ok
            end,

    case State of
        ok ->
            ?player_send(guild_sproto:pkg_msg(?MSG_GUILD_ROLE_APPLY, {Type}));
        {error, ErrCode} -> ?return_err(ErrCode)
    end,
    guild_boss:sync_guild_apply(GuildId);

%% 同意/拒绝多人玩家入会
handle_client(?MSG_GUILD_ROLES_APPLY, {Type}) ->
    GuildId = get(?pd_guild_id),
    ?ifdo(?is_not_join_guild(),?return_err(?ERR_GUILD_NOT_JOIN)),

    ?ifdo(is_have_permission(?GUILD_APPLY_AGREE_OR_REFUSED) =:= ?false,?return_err(?ERR_GUILD_NOT_PERMISSION)),

    case Type of
        1 -> %%同意玩家入会
            case guild_service:ets_lookup(GuildId, #player_apply_tab.guild_id) of
                [] -> 
                    ok;
                PlayerList ->
                    lists:foreach(fun(PlayerId) -> 
                        clear_add_other_apply(PlayerId, GuildId) 
                    end, 
                    PlayerList),    %% 清除玩家的其他公会申请

                    JoinPlayerList = 
                    case batch_apply_player(PlayerList, GuildId) of
                        {{error, _Other}, NewPlayerList} -> 
                            NewPlayerList;
                        [] -> 
                            [];
                        NewPlayerList ->
                            NewPlayerList
                    end,
                    case JoinPlayerList of
                        [] -> 
                            ok;
                        JoinPlayerList ->
                            MemberList = guild_member_list(GuildId, JoinPlayerList),
                            guild_mng:push_guild_member_join(GuildId, MemberList),
                            [guild_service:delete_apply_player(clear_player_apply_info, PlayerId) || PlayerId <- JoinPlayerList]
                    end
            end;
        2 -> %%清空该公会申请入会列表
            ok
    end,
    guild_service:delete_apply_player(clear, GuildId),% 不管加了多少人，清空该公会申请列表
    guild_boss:sync_guild_apply(GuildId),
    ?player_send(guild_sproto:pkg_msg(?MSG_GUILD_ROLES_APPLY, {Type}));

%% 升级建筑
handle_client(?MSG_GUILD_BUILDING_ADDEXP, {BuildingTypeId, CostType}) ->
    ?ifdo(?is_not_join_guild(),
        ?return_err(?ERR_GUILD_NOT_JOIN)),

    CountList = get(?pd_guild_daily_task_count),

    % ?INFO_LOG("task_count,~p",[{CountList,BuildingTypeId}]),

    Count = case lists:keyfind(BuildingTypeId, 1, CountList) of
                false -> 0;
                {BuildingTypeId, Num} -> Num
            end,
    ?ifdo(Count =:= 0,
        ?return_err(?ERR_GUILD_DAILY_NUMBER_FINISHED)),

    GuildId = get(?pd_guild_id),
    BuildingTypeList = load_cfg_guild:lookup_cfg(?guild_buildings_cfg, #guild_buildings_cfg.building_type_id),
    case lists:member(BuildingTypeId, BuildingTypeList) of
        false -> ?return_err(?ERR_GUILD_NO_THISBUILDINGID);
        true ->
            [#guild_buildings_tab{building_list = Buildings}] = guild_service:lookup_tab(?guild_buildings_tab, GuildId),
            BuildingList = case lists:keyfind(BuildingTypeId, 1, Buildings) of
                               false -> [{BuildingTypeId, ?PLAYER_GUILD_DEFAULT_LV, 0} | Buildings];
                               _BuildingInfo -> Buildings
                           end,
            {{NewBuildingList, ReturnClientData}, {AssetType, CoinCost, BuildAddExp}} = guild_service:build_add_exp(BuildingTypeId, BuildingList, CostType),
            case BuildingTypeId of
                1 ->
                    OldGuildLv =
                        case lists:keyfind(BuildingTypeId, 1, BuildingList) of
                            {BuildingTypeId, GuildLv1, _} ->
                                GuildLv1;
                            _ ->
                                ?PLAYER_GUILD_DEFAULT_LV
                        end,
                    NewGuildLv =
                        case lists:keyfind(BuildingTypeId, 1, NewBuildingList) of
                            {BuildingTypeId, GuildLv2, _} ->
                                GuildLv2;
                            _ ->
                                ?PLAYER_GUILD_DEFAULT_LV
                        end,
                    notice_system:send_guild_level_up_notice(OldGuildLv, NewGuildLv);
                _ ->
                    pass
            end,
            case game_res:try_del([{AssetType, CoinCost}], ?FLOW_REASON_GUILD) of
                {error, diamond_not_enough} -> ?return_err(?ERR_GUILD_CREATE_DIAMOND_LESS_THAN);
                {error, cost_not_enough} -> ?return_err(?ERR_GUILD_CREATE_GOLD_LESS_THAN);
                {error, _Other} -> ?return_err(?ERR_GUILD_COST_FAIL);
                ok ->
                    guild_service:build_update_exp(GuildId, NewBuildingList, BuildAddExp),
                    %% RoleLv = get(?pd_guild_lv),
                    %% {MaxLv, MaxExpCFG, ExpCFG} = load_cfg_guild:lookup_cfg(?guild_member_lvup_cfg, RoleLv),

                    %% {PlayerNewLv, PlayerNewExp} = guild_service:addexp(MaxExpCFG, ExpCFG, MaxLv, RoleLv, (get(?pd_guild_exp) + BuildAddExp)),
                    %% put(?pd_guild_lv, PlayerNewLv),
%%                  %%   notice_system:send_guild_level_up_notice(RoleLv, PlayerNewLv),
                    %% put(?pd_guild_exp, PlayerNewExp),
                    put(?pd_guild_totle_contribution, get(?pd_guild_totle_contribution) + BuildAddExp),
                    put(?pd_guild_daily_task_count, lists:keystore(BuildingTypeId, 1, CountList, {BuildingTypeId, Count - 1})),

                    ?INFO_LOG("contribution:~p", [get(?pd_guild_totle_contribution)]),
                    {PlayerLv, PlayerExp} = guild_mng:get_guild_player_lv_and_exp_by_contribution(get(?pd_guild_totle_contribution)),
                    ?INFO_LOG("Lv:~p,exp:~p", [PlayerLv,PlayerExp]),
                    put(?pd_guild_lv, PlayerLv),
                    put(?pd_guild_exp, PlayerExp),
                    guild_mng:push_role_data(),
                    ?player_send(guild_sproto:pkg_msg(?MSG_GUILD_BUILDING_ADDEXP, ReturnClientData)),
                    if
                        BuildingTypeId =:= 1 ->
                            bounty_mng:do_bounty_task(?BOUNTY_TASK_SHENGJI_GUILD_DATING, 1);
                        BuildingTypeId =:= 2 ->
                            bounty_mng:do_bounty_task(?BOUNTY_TASK_SHENGJI_GUILD_KEJI, 1),
                            phase_achievement_mng:do_pc(?PHASE_AC_GONGHUI_UPGRADE, 1);
                        true -> ok
                    end,
                    open_server_happy_mng:sync_task(?UPDATE_GUILD_BUILD_COUNT, 1)
            end
    end;

%% 退会
handle_client(?MSG_GUILD_OUT, {}) ->
    GuildId = get(?pd_guild_id),
    %?DEBUG_LOG("MSG_GUILD_OUTGuildId-------------------------------:~p",[GuildId]),
    ?ifdo(?is_not_join_guild(),?return_err(?ERR_GUILD_NOT_JOIN)),

    ?ifdo(get(?pd_guild_position) =:= ?GUILD_MASTER_POSITIONID,?return_err(?ERR_GUILD_MASTER_CONNOT_QUIT)),

    player_exit(get(?pd_id), GuildId),

    ?player_send(guild_sproto:pkg_msg(?MSG_GUILD_OUT, {}));

%% 申请入会
handle_client(?MSG_GUILD_APPLY, {GuildId}) ->
%%    ?INFO_LOG("Guild apply GuildId = ~p  ++++++++++++", [GuildId]),
    ?ifdo(?is_join_guild(),
        ?return_err(?ERR_GUILD_HAS_GUILD)),

    PlayerId = get(?pd_id),
    ?ifdo(guild_service:is_ets_match(PlayerId, GuildId),
        ?return_err(?ERR_GUILD_HASALREADY_APPLY)),

    guild_service:ets_add(#player_apply_tab{player_id = PlayerId, guild_id = GuildId}),
    ?player_send(guild_sproto:pkg_msg(?MSG_GUILD_APPLY, {GuildId}));

%% 搜索公会
handle_client(?MSG_GUILD_SEARCH, {GuildId}) ->
    case guild_service:select_guild(GuildId) of
        [] -> ?return_err(?ERR_GUILD_FIND_GUILD_IS_NULL);
        Info -> ?player_send(guild_sproto:pkg_msg(?MSG_GUILD_SEARCH, Info))
    end;

%% 公会商店购买物品
handle_client(?MSG_GUILD_BUY_ITEM, {Shopid, ItemBuyNum}) ->
    ?ifdo(?is_not_join_guild(),
        ?return_err(?ERR_GUILD_NOT_JOIN)),

    case load_cfg_guild:lookup_cfg(?guild_shop_cfg, Shopid) of
        #guild_shop_cfg{item_bid = ItemBid, money_type = MoneyType, price = Price, buy_condition = BuyConditionList} ->
            VerifyCondition = case BuyConditionList of
                                  [] -> ?true;
                                  BuyConditionList ->
                                      FunBool = fun({BuyConditionId, BuyConditionNum}) ->
                                          case lists:keyfind(BuyConditionId, 1, ?GUILD_SHOP_BUY_CONDITION) of
                                              ?false -> ?false;
                                              {BuyConditionId, Value} -> Value >= BuyConditionNum
                                          end
                                      end,
                                      lists:all(FunBool, BuyConditionList)
                              end,
            case VerifyCondition of
                ?true ->
                    case shop_mng:buy(ItemBid, MoneyType, Price, ItemBuyNum) of
                        {error, Other} -> ?return_err(Other);
                        {ok, _OK} -> ?player_send(guild_sproto:pkg_msg(?MSG_GUILD_BUY_ITEM, {}))
                    end;
                ?false -> ?return_err(?ERR_GUILD_VERIFY_CONDITION_ERROR)
            end;
        _Other -> ?return_err(?ERR_GUILD_NO_GUILD_SHOP_CFG)
    end;

%% 科技等级提升
handle_client(?MSG_GUILD_TECH_LVUP, {TechId, CostType}) ->
    ?ifdo(?is_not_join_guild(),
        ?return_err(?ERR_GUILD_NOT_JOIN)),

    TechTypeList = load_cfg_guild:lookup_cfg(?guild_tech_cfg, #guild_tech_cfg.tech_type_id),
    case lists:member(TechId, TechTypeList) of
        false -> ?return_err(?ERR_GUILD_NO_THIS_TECH_BUILDINGID);
        true ->
            TechItemList = get(?pd_guild_tech_items),
            {TechItems, {TechId, TechLv}} = case lists:keyfind(TechId, 1, TechItemList) of
                                                false ->
                                                    {[{TechId, ?PLAYER_GUILD_TECH_DEFAULT_LV} | TechItemList], {TechId, ?PLAYER_GUILD_TECH_DEFAULT_LV}};
                                                TechInfo -> {TechItemList, TechInfo}
                                            end,
            {MaxLv, _Reward, ConditionList, UpdateCost} = load_cfg_guild:lookup_cfg(?guild_tech_cfg, {TechId, TechLv}),
            ?ifdo(MaxLv =:= TechLv,
                ?return_err(?ERR_GUILD_TECH_LV_MAX)),

            VerifyCondition = case ConditionList of
                                  [] -> ?true;
                                  ConditionList ->
                                      FunBool = fun({BuyConditionId, BuyConditionNum}) ->
                                          case lists:keyfind(BuyConditionId, 1, ?GUILD_TECH_BUILDINGS_LVUP_CONDITION) of
                                              ?false -> ?false;
                                              {BuyConditionId, Value} -> Value >= BuyConditionNum
                                          end
                                      end,
                                      lists:all(FunBool, ConditionList)
                              end,

            case VerifyCondition of
                ?true -> %验证成功，消耗货币，等级提升，属性提升
                    Assets = case CostType of
                                 2 -> lists:keyfind(?PL_DIAMOND, 1, UpdateCost);
                                 1 -> lists:keyfind(?PL_MONEY, 1, UpdateCost);
                                 _ -> ?return_err(?ERR_GUILD_TYPE_IS_ERROR)
                             end,
                    case game_res:try_del([Assets], ?FLOW_REASON_GUILD) of
                        {error, diamond_not_enough} -> ?return_err(?ERR_GUILD_CREATE_DIAMOND_LESS_THAN);
                        {error, cost_not_enough} -> ?return_err(?ERR_GUILD_CREATE_GOLD_LESS_THAN);
                        {error, _Other} -> ?return_err(?ERR_GUILD_COST_FAIL);
                        ok ->
                            put(?pd_guild_tech_items, lists:keyreplace(TechId, 1, TechItems, {TechId, TechLv + 1})),
                            guild_mng:add_tech_attr(TechId, TechLv + 1),
                            phase_achievement_mng:do_pc(?PHASE_AC_GONGHUI_ONE_LEVEL, TechLv + 1),
                            bounty_mng:do_bounty_task(?BOUNTY_TASK_SHENGJI_GUILD_JINENG, 1),
                            event_eng:post(?ev_guild_tech_level, {?ev_guild_tech_level, TechId}, 1),
                            ?player_send(guild_sproto:pkg_msg(?MSG_GUILD_TECH_LVUP, {TechId}))
                    end;

                ?false ->
                    ?return_err(?ERR_GUILD_TECH_VERIFY_CONDITION_FAIL)
            end
    end;



%% 获得公会BOSS信息
handle_client(?MSG_GUILD_BOSS_INFO, {}) ->
    guild_boss:sync_boss_info(),
    ok;



%% 公会boss献祭
handle_client(?MSG_GUILD_BOSS_DONATE, {_Id}) ->
    RecordId = guild_boss:get_guild_boss_recordid(),
    if
        _Id =/= RecordId ->
            case guild_boss:get_boss_info() of
                #guild_boss{field = TmpList} ->
                    Id = util:get_field(TmpList, ?GUILD_BOSS_KEY_BOSS_RECORD_ID, 0),
                    Exp = util:get_field(TmpList, ?GUILD_BOSS_KEY_BOSS_EXP, 0),
                    Donate = util:get_pd_field(?pd_guild_boss_donate, 0),
                    MsgBag = guild_sproto:pkg_msg(?MSG_GUILD_BOSS_DONATE, {Id, Exp, Donate, 1}),
                    ?player_send(MsgBag);

                _ ->
                    MsgBag = guild_sproto:pkg_msg(?MSG_GUILD_BOSS_DONATE, {0, 0, 0, 2}),
                    ?player_send(MsgBag)
            end;

        true ->
            case guild_boss:can_action(?GUILD_BOSS_DONATE, {RecordId}) of
                ok ->
                    GuildId = get(?pd_guild_id),
                    ImmoExp = load_cfg_guild_boss:get_monster_immo_exp(RecordId),
                    case gen_server:call
                    (
                        guild_service,
                        {
                            guild_boss,
                            #guild_boss_donate
                            {
                                guild_id = GuildId,
                                donate_val = ImmoExp
                            }
                        }
                    )
                    of
                        {ok, #guild_boss{field = List}} ->
                            guild_boss:action(?GUILD_BOSS_DONATE, {RecordId}),
                            Id = util:get_field(List, ?GUILD_BOSS_KEY_BOSS_RECORD_ID, 0),
                            Exp = util:get_field(List, ?GUILD_BOSS_KEY_BOSS_EXP, 0),
                            Donate = util:get_pd_field(?pd_guild_boss_donate, 0),
                            MsgBag = guild_sproto:pkg_msg(?MSG_GUILD_BOSS_DONATE, {Id, Exp, Donate, ?REQ_GUILD_OK}),
                            ?player_send(MsgBag);

                        _ ->
                            MsgBag = guild_sproto:pkg_msg(?MSG_GUILD_BOSS_DONATE, {0, 0, 0, 2}),
                            ?player_send(MsgBag)
                    end;

                _ ->
                    #guild_boss{field = TmpList} = guild_boss:get_boss_info(),
                    Id = util:get_field(TmpList, ?GUILD_BOSS_KEY_BOSS_RECORD_ID, 0),
                    Exp = util:get_field(TmpList, ?GUILD_BOSS_KEY_BOSS_EXP, 0),
                    Donate = util:get_pd_field(?pd_guild_boss_donate, 0),
                    MsgBag = guild_sproto:pkg_msg(?MSG_GUILD_BOSS_DONATE, {Id, Exp, Donate, 1}),
                    ?player_send(MsgBag)
            end
    end,
    ok;


%% 公会boss进阶
handle_client(?MSG_GUILD_BOSS_PHASE, {_Id}) ->
    RecordId = guild_boss:get_guild_boss_recordid(),
    if
        _Id =/= RecordId ->
            MsgBag = guild_sproto:pkg_msg(?MSG_GUILD_BOSS_PHASE, {RecordId, 1}),
            ?player_send(MsgBag);

        true ->
            case guild_boss:can_action(?GUILD_BOSS_PHASE, {RecordId}) of
                ok ->
                    GuildId = get(?pd_guild_id),
                    case gen_server:call
                    (
                        guild_service,
                        {
                            guild_boss,
                            #guild_boss_phase
                            {
                                guild_id = GuildId
                            }
                        }
                    )
                    of
                        {ok, #guild_boss{field = List}} ->
                            ?INFO_LOG("GUILD_BOSS_PHASE ~p", [RecordId]),
                            guild_boss:action(?GUILD_BOSS_PHASE, {RecordId}),
                            Id = util:get_field(List, ?GUILD_BOSS_KEY_BOSS_RECORD_ID, 0),
                            MsgBag = guild_sproto:pkg_msg(?MSG_GUILD_BOSS_PHASE, {Id, ?REQ_GUILD_OK}),
                            ?player_send(MsgBag);

                        {error, is_fighting} ->
                            MsgBag = guild_sproto:pkg_msg(?MSG_GUILD_BOSS_PHASE, {0, 2}),
                            ?player_send(MsgBag);

                        _ ->
                            MsgBag = guild_sproto:pkg_msg(?MSG_GUILD_BOSS_PHASE, {0, 1}),
                            ?player_send(MsgBag)
                    end;



                _ ->
                    MsgBag = guild_sproto:pkg_msg(?MSG_GUILD_BOSS_PHASE, {0, 1}),
                    ?player_send(MsgBag)
            end
    end,
    ok;

%% 公会boss召唤
handle_client(?MSG_GUILD_BOSS_CALL, {_Id}) ->
    RecordId = guild_boss:get_guild_boss_recordid(),
    if
        _Id =/= RecordId ->
            ?INFO_LOG("MSG_GUILD_BOSS_CALL 1"),
            #guild_boss{field = TmpList} = guild_boss:get_boss_info(),
            call_ret(TmpList, 1);

        true ->
            case guild_boss:can_action(?GUILD_BOSS_CALL, {RecordId}) of
                ok ->
                    GuildId = get(?pd_guild_id),
                    case gen_server:call
                    (
                        guild_service,
                        {
                            guild_boss,
                            #guild_boss_call
                            {
                                guild_id = GuildId
                            }
                        }
                    )
                    of
                        {ok, #guild_boss{field = List}} ->
                            ?INFO_LOG("MSG_GUILD_BOSS_CALL 2"),
                            guild_boss:action(?GUILD_BOSS_CALL, {RecordId}),
                            call_ret(List, ?REQ_GUILD_OK);

                        _E ->
                            ?INFO_LOG("MSG_GUILD_BOSS_CALL 3"),
                            #guild_boss{field = TmpList} = guild_boss:get_boss_info(),
                            call_ret(TmpList, 1)
                    end;

                _ ->
                    ?INFO_LOG("MSG_GUILD_BOSS_CALL 4"),
                    #guild_boss{field = TmpList} = guild_boss:get_boss_info(),
                    call_ret(TmpList, 1)
            end
    end,
    ok;

%% 公会BOSS伤害值
handle_client(?MSG_GUILD_BOSS_DAMAGE, {Id, Damage}) ->
    case guild_boss:can_action(?GUILD_BOSS_DAMAGE, {Damage}) of
        ok ->
            GuildId = get(?pd_guild_id),
            case gen_server:call
            (
                guild_service,
                {
                    guild_boss,
                    #guild_boss_damage
                    {
                        guild_id = GuildId,
                        damage = Damage,
                        record_id = Id,
                        killer_id = get(?pd_id)
                    }
                }
            )
            of
                {ok, #guild_boss{}} ->
                    guild_boss:action(?GUILD_BOSS_DAMAGE, {Damage}),
                    guild_boss:sync_boss_hp(true);

                _ ->
                    error
            end;



        _ ->
            MsgBag = guild_sproto:pkg_msg(?MSG_GUILD_BOSS_CALL, {0, 0, ?ERR_GUILD_UNKNOWN}),
            ?player_send(MsgBag)
    end,
    ok;

%% 公会boss挑战 10011
handle_client(?MSG_GUILD_BOSS_CHALLENGE, {_Id}) ->
    SceneCfgId = 50001,
    case guild_boss:get_boss_info() of
        #guild_boss{field = List} ->
            Dt = util:get_field(List, ?GUILD_BOSS_KEY_BOSS_OVER_TIME_DT, 0),
            if
                Dt > 0 ->
                    Id = util:get_field(List, ?GUILD_BOSS_KEY_BOSS_RECORD_ID, 0),
                    Hp = util:get_field(List, ?GUILD_BOSS_KEY_BOSS_HP, 0),
                    Challage = util:get_pd_field(?pd_guild_boss_challage, 0),
                    util:set_pd_field(?pd_guild_boss_challage, Challage+1),
                    main_ins_mod:fight_start(?MSG_MAIN_INSTANCE_CLIENT_START, SceneCfgId),
                    guild_boss:start_self_guild_boss_fight(),
                    MsgBag = guild_sproto:pkg_msg(?MSG_GUILD_BOSS_CHALLENGE, {Id, Hp, 0}),
                    ?player_send(MsgBag);

                true ->
                    #guild_boss{field = TmpList} = guild_boss:get_boss_info(),
                    Id = util:get_field(TmpList, ?GUILD_BOSS_KEY_BOSS_RECORD_ID, 0),
                    Hp = util:get_field(TmpList, ?GUILD_BOSS_KEY_BOSS_HP, 0),
                    MsgBag = guild_sproto:pkg_msg(?MSG_GUILD_BOSS_CHALLENGE, {Id, Hp, 1}),
                    ?player_send(MsgBag)
            end;


        _ ->
            #guild_boss{field = TmpList} = guild_boss:get_boss_info(),
            Id = util:get_field(TmpList, ?GUILD_BOSS_KEY_BOSS_RECORD_ID, 0),
            Hp = util:get_field(TmpList, ?GUILD_BOSS_KEY_BOSS_HP, 0),
            MsgBag = guild_sproto:pkg_msg(?MSG_GUILD_BOSS_CHALLENGE, {Id, Hp, 1}),
            ?player_send(MsgBag)
    end,
    ok;

%% 公会boss买活
handle_client(?MSG_GUILD_BOSS_BUY_REVIVE, {}) ->
    RecordId = guild_boss:get_guild_boss_recordid(),
    case guild_boss:can_action(?GUILD_BOSS_REVIVE, {RecordId}) of
        ok ->
            guild_boss:action(?GUILD_BOSS_REVIVE, {RecordId}),
            MsgBag = guild_sproto:pkg_msg(?MSG_GUILD_BOSS_BUY_REVIVE, {0}),
            ?player_send(MsgBag);

        _ ->
            MsgBag = guild_sproto:pkg_msg(?MSG_GUILD_BOSS_BUY_REVIVE, {1}),
            ?player_send(MsgBag)
    end,
    ok;

%% 公会圣物交流
handle_client(?MSG_GUILD_SAINT_EXCHANGE, {SaintId}) ->
    %% ?ifdo(?is_not_join_guild(),?return_err(?ERR_GUILD_NOT_JOIN)),
    GuildSaintList = get(?pd_guild_saint_list),
    PlayerGuildLv = get(?pd_guild_lv),
    Ret =
        case lists:keyfind(SaintId, 1, GuildSaintList) of
            {SaintId, Status} ->
                case Status of
                    0 ->
                        #guild_saint_cfg{prize = PrizeList} = load_cfg_guild_saint:lookup_guild_saint_cfg({PlayerGuildLv, SaintId}),
                        case game_res:try_give_ex(PrizeList,?S_MAIL_GUILD_SAINT, ?FLOW_REASON_GUILD_SAINT) of
                            {error, Other} ->
                                {error, Other};
                            _ ->
                                NewGuildSaintList = lists:keyreplace(SaintId, 1, GuildSaintList, {SaintId, 1}),
                                put(?pd_guild_saint_list, NewGuildSaintList),
                                guild_mng:push_guild_saint_list(),
                                {ok, PrizeList}
                        end;
                    _ ->
                        {error, getted}
                end;
            _ ->
                {error, no_open}
        end,
    case Ret of
        {error, no_open} ->
            ?return_err(?ERR_GUILD_SAINT_NO_OPEN);
        {error, getted} ->
            ?return_err(?ERR_GUILD_SAINT_GETTED);
        {error, _Other} ->
            ?return_err(?ERR_GUILD_UNKNOWN);
        {ok, L} ->
            ?player_send(guild_sproto:pkg_msg(?MSG_GUILD_SAINT_EXCHANGE, {L}))
    end;

%% 公会圣物一键交流
handle_client(?MSG_GUILD_SAINT_EXCHANGE_ALL, {}) ->
    %% ?ifdo(?is_not_join_guild(),?return_err(?ERR_GUILD_NOT_JOIN)),
    GuildSaintList = get(?pd_guild_saint_list),
    PlayerGuildLv = get(?pd_guild_lv),
    {NewGuildSaintList, NewPrizeList} =
        lists:foldl(
            fun({SaintId, Status},{SaintList, PrizeList}) ->
                case Status of
                    0 ->
                        #guild_saint_cfg{prize = Prize} = load_cfg_guild_saint:lookup_guild_saint_cfg({PlayerGuildLv, SaintId}),
                        RandPer = com_util:random(0, 1000),
                        MiscSaint = misc_cfg:get_guild_saint_pro(),
                        {_,Per,_} = lists:keyfind(SaintId, 1, MiscSaint),
                        NewPrize =
                            if
                                RandPer > Per ->
                                    lists:foldl(
                                        fun({GoodId, Count},Acc) ->
                                            [{GoodId, Count + 1} | Acc]
                                        end,
                                        [],
                                        Prize
                                    );
                                true ->
                                    Prize
                            end,
                        {[{SaintId,1} | SaintList], PrizeList ++ NewPrize};
                    _ ->
                        {[{SaintId,1} | SaintList], PrizeList}
                end
            end,
            {[],[]},
            GuildSaintList
        ),
    NewPrizeList1 = item_goods:merge_goods(NewPrizeList),
    CostList = misc_cfg:get_guild_saint_touch(),
    Ret =
        case game_res:try_del(CostList,?FLOW_REASON_GUILD_SAINT) of
            ok ->
                case game_res:try_give_ex(NewPrizeList1,?S_MAIL_GUILD_SAINT, ?FLOW_REASON_GUILD_SAINT) of
                    {error, Other} ->
                        {error, Other};
                    _ ->
                        put(?pd_guild_saint_list, NewGuildSaintList),
                        guild_mng:push_guild_saint_list(),
                        {ok, NewPrizeList1}
                end;
            _ ->
                {error, money_not_enough}
        end,
    case Ret of
        {error, money_not_enough} ->
            ?return_err(?ERR_COST_NOT_ENOUGH);
        {error, _Other} ->
            ?return_err(?ERR_GUILD_UNKNOWN);
        {ok, L} ->
            ?player_send(guild_sproto:pkg_msg(?MSG_GUILD_SAINT_EXCHANGE_ALL, {L}))
    end;


handle_client(_MSG, _) ->
    {error, unknown_msg}.

call_ret(TmpList, Ret) ->
    Id = util:get_field(TmpList, ?GUILD_BOSS_KEY_BOSS_RECORD_ID, 0),
    BossDt = util:get_field(TmpList, ?GUILD_BOSS_KEY_BOSS_OVER_TIME_DT, 0),
    BossEndTime = util:get_field(TmpList, ?GUILD_BOSS_KEY_CALL_TIME, 0),
    BossEndTime1 = BossEndTime + BossDt,
    ?INFO_LOG("call_ret ~p", [{BossEndTime, BossDt, BossEndTime1}]),
    CallCount = util:get_field(TmpList, ?GUILD_BOSS_KEY_CALL_COUNT, 0),
    MsgBag = guild_sproto:pkg_msg(?MSG_GUILD_BOSS_CALL, {Id, BossEndTime1, CallCount, Ret}),
    ?player_send(MsgBag),
    notice_system:send_call_guild_boss_notice(Id, Ret).        %% 根据召唤结果选择是否发送公会消息


handle_msg(_, {sync_guild_boss}) ->
    ?INFO_LOG("-------------- sync_guild_boss --------------"),
    guild_boss:sync_boss_info();

handle_msg(_, {shuijingzhongjiezhe}) ->
    achievement_mng:do_ac(?shuijingzhongjiezhe);


handle_msg(FromMod, Msg) ->
    ?ERROR_LOG("~p recv a unknown msg ~p from ~p", [?pname(), Msg, FromMod]).


-spec create_guild(binary(), integer(), integer()) -> ok | {error, Other} when Other :: integer().
create_guild(GuildNameBin, TotemId, BorderId) ->
    guild_service:delete_apply_player(clear_player_apply_info, get(?pd_id)),
    [{create_guild_need_diamond, CreateDiamond},
        {create_guild_need_items, CreateItems}] = misc_cfg:get_misc_cfg(guild_info), %判断创建公会条件

    PdDiamond = get(?pd_diamond),

    if
        (PdDiamond < CreateDiamond) orelse PdDiamond =:= ?undefined -> {error, ?ERR_GUILD_CREATE_DIAMOND_LESS_THAN};
        true ->
            ItemBool = %判断创建公会的物品是否充足
            if
                CreateItems == [] ->
                    true;
                true -> game_res:can_del(CreateItems) =:= ok
            end,
            case ItemBool of
                true ->
                    NowTimer = com_time:now(),

                    GuildTab = #guild_tab{guild_name = GuildNameBin, master_id = get(?pd_id),
                        notice_update_time = NowTimer, totem_id = TotemId,
                        border_id = BorderId, create_time = NowTimer},

                    case guild_service:insert_tab(?guild_tab, GuildTab) of
                        true ->
                            case game_res:try_del([{?PL_DIAMOND, CreateDiamond} | CreateItems], ?FLOW_REASON_GUILD) of
                                {error, diamond_not_enough} -> ?return_err(?ERR_GUILD_CREATE_DIAMOND_LESS_THAN);
                                {error, cost_not_enough} -> ?return_err(?ERR_GUILD_CREATE_GOLD_LESS_THAN);
                                {error, _Other} -> ?return_err(?ERR_GUILD_COST_FAIL);
                                ok ->
                                    ServerInfo = global_data:get_server_info(),
                                    ServerId = case maps:find(id, ServerInfo) of
                                                   {ok, Id} when is_integer(Id) -> Id;
                                                   _ -> 0
                                               end,
                                    GenId = gen_id:next_id(?guild_id_tab),
                                    GuildId = (ServerId * 10000) + (1000 + GenId),
                                    guild_service:guild_data_init(GuildId, GenId, GuildNameBin),
                                    guild_service:guild_totle_num(GuildId, (+ 1)),
                                    event_eng:post(?ev_guild_create, {?ev_guild_create, 0}, 1),
                                    create_guild_player_info(get(?pd_id), GuildId, ?GUILD_MASTER_POSITIONID)
                            end;
                        false ->
                            {error, ?ERR_GUILD_CREATE_NAME_REPEAT}
                    end;
                false ->
                    {error, ?ERR_GUILD_CREATE_ITEM_LESS_THAN}
            end
    end.

%% @doc 玩家加入公会,初始化。会长加入||会员加入
-spec create_guild_player_info(integer(), integer(), integer()) -> ok.
create_guild_player_info(PlayerId, GuildId, PositionId) ->
    util:set_pd_field(?pd_guild_boss_donate, 0),
    NowTimer = com_time:now(),

    ExpUpCount = [{I, ?DEFAULT_GUILD_LV, 0} || I <- load_cfg_guild:lookup_cfg(?guild_buildings_cfg, #guild_buildings_cfg.building_type_id)],
    TotleCount = load_cfg_guild:lookup_cfg(?guild_buildings_cfg, ExpUpCount),
    GuildMemberTab = 
    #player_guild_member{
        player_id = PlayerId,
        guild_id = GuildId,
        player_position = PositionId,
        join_time = NowTimer,
        lv = ?PLAYER_GUILD_DEFAULT_LV,
        daily_task_count = []
    }, %% daily_task_count = TotleCount remove

    [#guild_player_association_tab{player_list = GuildMemberList}] = guild_service:lookup_tab(?guild_player_association_tab, GuildId),

    FinalGuildMemberList =
    case lists:member(PlayerId, GuildMemberList) of
        true ->
            GuildMemberList;
        false ->
            [PlayerId | GuildMemberList]
    end,

    %?DEBUG_LOG("GuildId----:~p---FinalGuildMemberList-------------------------:~p",[GuildId, FinalGuildMemberList]),

    TechsCFG = load_cfg_guild:lookup_cfg(?guild_tech_cfg, #guild_tech_cfg.tech_type_id),
    TechItems = [{I, ?PLAYER_GUILD_TECH_DEFAULT_LV} || I <- TechsCFG],
    GuildTechsTab = #player_guild_tech_buildings{player_id = PlayerId, guild_id = GuildId, tech_items = TechItems},

    guild_service:update_guild_data_to_ets(?player_guild_member, GuildMemberTab),
    guild_service:update_guild_data_to_ets(?guild_player_association_tab, #guild_player_association_tab{guild_id = GuildId,player_list = FinalGuildMemberList}),
    guild_service:update_guild_data_to_ets(?player_guild_tech_buildings, GuildTechsTab),

    case dbcache:load_data(player_guild_count, PlayerId) of
        [] -> guild_service:update_guild_data_to_ets(player_guild_count, #player_guild_count{player_id = PlayerId,
            daily_task_count = TotleCount});
        [_GuildCount] -> ok
    end,

    case PositionId of
        ?GUILD_MASTER_POSITIONID -> %会长加入公会,更新本进程公会信息
            guild_mng:load_guild_data(),
            guild_service:add_member_online(),
            guild_mng:reset_guild_daily_task_count(),
            %% 加入公会重置场景进程玩家agent
            get(?pd_scene_pid) ! ?scene_mod_msg(scene_player, {update_agent_info, self(), get(?pd_career), 3, guild_mng:get_guild_info()}),
            phase_achievement_mng:do_pc(?PHASE_AC_GONGHUI_JOIN, 1),
            ok;
%%             put(?pd_society_bufs, [1,2,3,4,5]),
%%             ?player_send(player_sproto:pkg_msg(?MSG_PLAYER_SYNC_SOCIETY_BUFS, {[1,2,3,4,5]}));

        _ -> %其他人加入,更新该玩家进程公会信息
            msg_service:send_msg(PlayerId, ?mod_msg(guild_mng, {?join_guild}))
    end.

-spec is_have_permission(integer()) -> boolean().
is_have_permission(PermissionId) ->
    PermissionIds =
        case get(?pd_guild_position) of
            ?GUILD_MASTER_POSITIONID ->
                ?GUILD_MASTER_PERMISSION;
            ?GUILD_VICE_MASTER_POSTION ->
                ?GUILD_VICE_MASTER_PERMISSION;
            ?GUILD_MEMBER_POSTION ->
                ?GUILD_MEMBER_PERMISSION
        end,
    lists:member(PermissionId, PermissionIds).

-spec set_player_position(integer(), integer(), integer()) -> ok | {error, Other} when Other :: integer().
set_player_position(OtherPlayerId, GuildId, ToPositionId) ->
    PlayerGuildPosition = get(?pd_guild_position),
    if
        (ToPositionId =:= ?GUILD_MASTER_POSITIONID) and (PlayerGuildPosition =:= ?GUILD_MASTER_POSITIONID) -> %会长转让
            case store_player_position(OtherPlayerId, GuildId, ToPositionId) of
                {error, Other} -> {error, Other};
                ok ->
                    put(?pd_guild_position, ?GUILD_MEMBER_POSTION),
                    guild_service:update_guild_data_to_ets(?player_guild_member,
                        #player_guild_member{player_id = get(?pd_id), guild_id = get(?pd_guild_id),
                            player_position = ?GUILD_MEMBER_POSTION, join_time = get(?pd_join_guild_time),
                            totle_exp = get(?pd_guild_totle_contribution), lv = get(?pd_guild_lv),
                            exp = get(?pd_guild_exp), daily_task_count = get(?pd_guild_daily_task_count)}),
                    [GuildTab] = guild_service:lookup_tab(?guild_tab, GuildId),
                    guild_service:update_guild_data_to_ets(?guild_tab, GuildTab#guild_tab{master_id = OtherPlayerId}),
%%                    guild_mng:push_role_data(),%会长职位发生变化，推送职位信息给会长
                    guild_mng:push_guild_master_change(GuildId),
                    ok
            end;
        (ToPositionId =:= ?GUILD_VICE_MASTER_POSTION) and (PlayerGuildPosition =:= ?GUILD_MASTER_POSITIONID) -> %任职副会长
            PlayerList = guild_service:lookup_tab(?player_guild_member, GuildId),
            FunFoldl = fun(PlayerId, Num) ->
                [#player_guild_member{player_position = PlayerPosition}] = dbcache:lookup(?player_guild_member, PlayerId),
                if
                    PlayerPosition =:= ?GUILD_VICE_MASTER_POSTION -> Num + 1;
                    true -> Num
                end
            end,
            PositionNum = lists:foldl(FunFoldl, 0, PlayerList),
            if
                (?GUILD_VICE_MASTER_MAX_NUM > PositionNum) ->
                    store_player_position(OtherPlayerId, GuildId, ToPositionId);
                true ->
                    {error, ?ERR_GUILD_NOT_ENOUGH_POSITION_NUM}
            end;
        (ToPositionId =:= ?GUILD_MEMBER_POSTION) and (PlayerGuildPosition =:= ?GUILD_MEMBER_POSTION) ->
            {error, ?ERR_GUILD_NOT_PERMISSION};
        (ToPositionId =:= ?GUILD_MEMBER_POSTION) ->
            store_player_position(OtherPlayerId, GuildId, ToPositionId);
        true ->
            {error, ?ERR_GUILD_THIS_POSITION_IS_NULL}
    end.

-spec store_player_position(integer(), integer(), integer()) -> ok | {error, Other} when Other :: integer().
store_player_position(OtherPlayerId, GuildId, ToPositionId) ->
%%    ?INFO_LOG("playerId:~p,guildId:~p,positionId:~p",[OtherPlayerId, GuildId, ToPositionId]),
    case dbcache:lookup(?player_guild_member, OtherPlayerId) of
        [] ->
            {error, ?ERR_GUILD_OTHER_PLAYER_NOT_JOIN_GUILD};
        [PlayerGuildInfo] ->
            if
                PlayerGuildInfo#player_guild_member.guild_id =:= GuildId -> %更新对方的权限信息
                    world:send_to_player_if_online(OtherPlayerId, ?mod_msg(guild_mng, {?position_change, ToPositionId})),
                    guild_service:update_guild_data_to_ets(?player_guild_member, PlayerGuildInfo#player_guild_member{player_position = ToPositionId}),
                    OtherPlayerName = player:lookup_info(OtherPlayerId, ?pd_name),
                    guild_mng:push_guild_member_position(GuildId, {OtherPlayerId, OtherPlayerName, ToPositionId}),
                    guild_service:add_event(?GUILD_EVENT_TYPE_POSITION, GuildId, {OtherPlayerId, OtherPlayerName, ToPositionId}),
                    ok;
                true ->
                    {error, ?ERR_GUILD_PLAYER_NOT_IN_THIS_GULD}
            end
    end.

%% @doc 移除成员
-spec remove_player(integer(), integer()) -> ok.
remove_player(ToPlayerId, GuildId) ->
    guild_mining_server:delete_player(GuildId, ToPlayerId),
    delete_player(ToPlayerId, GuildId),
    ToPlayerName = player:lookup_info(ToPlayerId, ?pd_name),
    guild_mng:push_guild_member_quit(GuildId, {ToPlayerId, ToPlayerName}, "remove"),
    guild_service:update_guild_data_to_ets(player_guild_is_join_guild, #player_guild_is_join_guild{player_id = ToPlayerId, quit_guild_times = virtual_time:now()}),
    world:send_to_player_if_online(ToPlayerId, ?mod_msg(guild_mng, {?quit_guild})),
    ok.

%% @doc 成员退出
-spec player_exit(integer(), integer()) -> ok.
player_exit(PlayerId, GuildId) ->
    guild_mining_server:delete_player(GuildId, PlayerId),
    delete_player(PlayerId, GuildId),
    guild_service:del_member_online(),
    put(?pd_guild_id, 0),
    guild_mng:del_tech_attr(),
    guild_mng:push_guild_member_quit(GuildId, {get(?pd_id), get(?pd_name)}, "quit"),
    put(pd_guild_quit_guild_time, virtual_time:now()),
    %% 离开公会重置场景进程玩家agent
    case get(?pd_scene_pid) of
        Pid when is_pid(Pid) -> 
            Pid ! ?scene_mod_msg(scene_player, {update_agent_info, self(), get(?pd_career), 3, 0});
        _ -> 
            error
    end,
    ok.

-spec delete_player(integer(), integer()) -> ok.
delete_player(PlayerId, GuildId) ->
    %?DEBUG_LOG("PlayerId-----:~p-----GuildId-----:~p",[PlayerId, GuildId]),
    dbcache:delete(?player_guild_member, PlayerId),
    dbcache:delete(?player_guild_tech_buildings, PlayerId),
    guild_service:guild_totle_num(GuildId, -1),
    [GuildPlayerAssociationTab] = guild_service:lookup_tab(?guild_player_association_tab, GuildId),
    GuildPlayerList = GuildPlayerAssociationTab#guild_player_association_tab.player_list,
    %?DEBUG_LOG("olddata=--------------------------:~p",[get(guild_player_association_tab)]),
    %?DEBUG_LOG("new data--------------------------:~p",[GuildPlayerAssociationTab#guild_player_association_tab{player_list = lists:delete(PlayerId, GuildPlayerList)}]),
    guild_service:update_guild_data_to_ets(?guild_player_association_tab,GuildPlayerAssociationTab#guild_player_association_tab{player_list = lists:delete(PlayerId, GuildPlayerList)}),
    ok.

%% @doc 批量入会
-spec batch_apply_player(List, integer()) -> {error, Other} | ok when List :: [integer()], Other :: integer().
batch_apply_player(ToPlayerList, GuildId) -> 
    batch_apply_player(ToPlayerList, GuildId, []).

batch_apply_player([], _GuildId, PlayerList) -> 
    PlayerList;
batch_apply_player([ToPlayerId | ToPlayers], GuildId, PlayerList) ->
    State = 
    case dbcache:lookup(?player_guild_member, ToPlayerId) of
        [] ->
            case guild_service:guild_totle_num(GuildId, (+ 1)) of
                {error, Other} -> 
                    {error, Other};
                ok ->
                    create_guild_player_info(ToPlayerId, GuildId, ?GUILD_MEMBER_POSTION),
                    ok
            end;
        [#player_guild_member{}] ->
            {error, ?ERR_GUILD_HAS_GUILD}
    end,
    case State of
        {error, ?ERR_GUILD_MAX_NUM} -> 
            {{error, ?ERR_GUILD_MAX_NUM}, PlayerList};
        {error, ?ERR_GUILD_HAS_GUILD} ->
            case ToPlayers of
                [] -> 
                    {{error, ?ERR_GUILD_HAS_GUILD}, PlayerList};
                _ -> 
                    batch_apply_player(ToPlayers, GuildId, PlayerList)
            end;
        {error, _Other} -> 
            batch_apply_player(ToPlayers, GuildId, PlayerList);
        ok -> 
            batch_apply_player(ToPlayers, GuildId, [ToPlayerId | PlayerList])
    end.

guild_member_list(_GuildId, PlayerList) ->
    lists:foldl
    (
        fun(PlayerId, Acc) ->
            case dbcache:lookup(?player_guild_member, PlayerId) of
                [#player_guild_member{player_position = PositionId, totle_exp = TotleExp}] ->
                    [PlayerLv, CareerId, PlayerName, CombatPower] = player:lookup_info(PlayerId, [?pd_level, ?pd_career, ?pd_name, ?pd_combat_power]),
                    IsOnline = ?if_else(world:is_player_online(PlayerId), ?IS_ONLINE, ?IS_OFFLINE),
                    IsFriend = friend_mng:apply_friend_state(PlayerId),
                    Acc1 = [{PlayerId, PlayerLv, CareerId, PlayerName, PositionId, CombatPower, TotleExp, IsFriend, IsOnline} | Acc],
                    Acc1;
                _ ->
                    Acc
            end
        end,
        [],
        PlayerList
    ).

%% 清除该玩家的其他公会申请并同步到客户端
clear_add_other_apply(PlayerId, GuildId) ->
    AllApplyList = ets:tab2list(?player_apply_tab),
    lists:foreach(fun(ApplyMsg) ->
            case ApplyMsg of
                {?player_apply_tab, PlayerId, GuildId} ->
                    pass;
                {?player_apply_tab, PlayerId, GuildId1} ->
                    MsgBag = guild_sproto:pkg_msg(?MSG_GUILD_APPLY_UPDATE, {0}),
                    MasterList = guild_boss:get_guild_master(GuildId1, ?GUILD_MASTER_POSITIONID),
                    [ world:send_to_player_if_online(I, {?send_to_client, MsgBag}) || I <- MasterList],
                    ViceMasterList = guild_boss:get_guild_master(GuildId1, ?GUILD_VICE_MASTER_POSTION),
                    [ world:send_to_player_if_online(I1, {?send_to_client, MsgBag}) || I1 <- ViceMasterList],
                    pass;
                _ ->
                    pass
            end
    end,
    AllApplyList).