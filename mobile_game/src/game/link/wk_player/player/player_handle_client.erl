%%%-------------------------------------------------------------------
%%% @author zl
%%% @doc
%%%
%%% @end
%%%-------------------------------------------------------------------

-module(player_handle_client).

-include("inc.hrl").
-include("player.hrl").
-include("handle_client.hrl").
-include("item_bucket.hrl").
-include("player_data_db.hrl").
-include("load_vip_right.hrl").
-include("scene.hrl").
-include("game.hrl").
-include("../part/wonderful_activity/bounty_struct.hrl").
-include("../../wk_open_server_happy/open_server_happy.hrl").
-include("system_log.hrl").
-include("arena_struct.hrl").

handle_client({Pack, Arg}) ->
    handle_client(Pack, Arg).

%% 登陆
% handle_client(?MSG_PLAYER_LOGIN,
%     {
%         PlatformPlayerName,
%         PassWorld,
%         PlatformId,
%         ServerId,
%         Vx, Vy
%         ,MachineMac
%         ,MachineId
%         ,MachineStyle
%         ,MachineInfo
%     }) ->
%     info_log:push({"MSG_PLAYER_LOGIN",MachineMac, MachineId, MachineStyle, MachineInfo}),
%     ?DEBUG_LOG("login-----------------------------------"),
%     attr_new:set(?pd_machine_mac, MachineMac),
%     attr_new:set(?pd_machine_id, MachineId),
%     attr_new:set(?pd_machine_style, MachineStyle),
%     attr_new:set(?pd_machine_info, MachineInfo),
%     account:login(PlatformPlayerName, PassWorld,PlatformId, ServerId, Vx, Vy);

handle_client(?MSG_PLAYER_JOIN_GAME, {Index, Vx, Vy}) ->
    % ?DEBUG_LOG("MSG_PLAYER_JOIN_GAME----------------:~p", [{Index}]),
    account:login_player(Index, Vx, Vy);


handle_client(?MSG_PLAYER_ACCOUNT_LOGIN,
        {
            PlatformPlayerName,
            PassWorld,
            PlatformId,
            ServerId,
            MachineMac,
            MachineId,
            MachineStyle,
            MachineInfo
        }) ->
    % ?DEBUG_LOG("MSG_PLAYER_ACCOUNT_LOGIN-----------------------------------"),
    attr_new:set(?pd_machine_mac, MachineMac),
    attr_new:set(?pd_machine_id, MachineId),
    attr_new:set(?pd_machine_style, MachineStyle),
    attr_new:set(?pd_machine_info, MachineInfo),
    account:login_account(PlatformPlayerName, PassWorld, PlatformId, ServerId);


handle_client(?MSG_PLAYER_QQ_AUTH_LOGIN,
        {
            Openid,
            AccessToken,
            PlatformId,
            ServerId,
            MachineMac,
            MachineId,
            MachineStyle,
            MachineInfo
        }) ->
    ?DEBUG_LOG("MSG_PLAYER_QQ_AUTH_LOGIN-----------------------------------"),
    attr_new:set(?pd_machine_mac, MachineMac),
    attr_new:set(?pd_machine_id, MachineId),
    attr_new:set(?pd_machine_style, MachineStyle),
    attr_new:set(?pd_machine_info, MachineInfo),
    % Openid, AccessToken
    case auth_qq:auth2(Openid, AccessToken) of
        ok ->
            account:login_account(Openid, <<"123456">>, PlatformId, ServerId);
        _ ->
            ?player_send_err(?MSG_PLAYER_QQ_AUTH_LOGIN, ?ERR_AUTH_MESSAGE)
    end;
%%    account:login_account(PlatformId, ServerId);


%% 创建角色
handle_client(?MSG_PLAYER_CREATE_ROLE, {Index, Career, Name}) ->
    % ?DEBUG_LOG("create_role ----------------------:~p", [{Index, Career}]),
    account:create_role(Index, Career, Name);

handle_client(?MSG_PLAYER_DELETE, {Index}) ->
    % ?DEBUG_LOG("Index--------------------:~p", [Index]),
    account:delete_role(Index);

handle_client(?MSG_PLAYER_RESET_PLAYER_NAME, {Name}) ->
    Cost = misc_cfg:get_alter_name(),
    case game_res:can_del(Cost) of
        ok ->
            game_res:del(Cost, ?FLOW_REASON_RESET_NAME),
            put(?pd_name, Name),
            put(?pd_name_pkg, <<?pkg_sstr(Name)>>),
            Data = ?recrod_get_pd(?player_tab),
            dbcache:update(?player_tab, Data),
            ?player_send(player_sproto:pkg_msg(?MSG_PLAYER_RESET_PLAYER_NAME, {0}));
        _ ->
            ?player_send(player_sproto:pkg_msg(?MSG_PLAYER_RESET_PLAYER_NAME, {1}))
    end;



%% 获取客户端私有数据
handle_client(?MSG_PLAYER_CLIENT_DATA_GET = Mid, {Type}) ->
    case orddict:find(Type, get(?pd_client_data)) of
        error ->
            ?debug_log_player("type ~p not data", [type]),
            ?player_send(player_sproto:pkg_msg(Mid, {Type, <<>>}));
        {ok, Data} ->
            ?player_send(player_sproto:pkg_msg(Mid, {Type, Data}))
    end;

%% 修改客户端私有数据
handle_client(?MSG_PLAYER_CLIENT_DATA_POST, {Type, Data}) ->
    if erlang:byte_size(Data) =< 1024 ->
        erlang:put(?pd_client_data,
            orddict:store(Type, Data,
                get(?pd_client_data)));
        true ->
            ?ERROR_LOG("player ~p bad ~p client data call", [?pname(), Type])
    end;

%% 打印
handle_client(?MSG_PLAYER_ECHO = Mid, {Msg}) ->
    ?player_send(player_sproto:pkg_msg(Mid, {Msg}));

%% 获得服务器时间
handle_client(?MSG_PLAYER_GET_SERVER_TIME = Mid, <<>>) ->
    ?player_send(player_sproto:pkg_msg(Mid, {com_time:timestamp_msec()}));

%% 追随某人
handle_client(?MSG_PLAYER_NAME_TO_ID, {Name}) ->
    {PlayerId, PlayerName} = case platfrom:get_player_id_by_name(Name) of
                                 Id when is_integer(Id) -> {Id, Name};
                                 _ -> {0, <<>>}
                             end,
    ?player_send(player_sproto:pkg_msg(?MSG_PLAYER_NAME_TO_ID, {PlayerId, PlayerName}));

%% 查看某人
handle_client(?MSG_PLAYER_LOOKUP_PLAYER_ATTR, {PlayerId}) ->
    case arena_server:is_arena_robot(PlayerId) of
        true ->
            case dbcache:lookup(?arena_robot_tab, PlayerId) of
                [#arena_robot_tab{name = Name, career = Career, lev = Lev, attr = Attr}] ->
                    Pkg = {PlayerId, Name, Career, Lev, attr_new:get_combat_power(Attr), ?r2t(Attr), [], []},
                    ?player_send(player_sproto:pkg_msg(?MSG_PLAYER_LOOKUP_PLAYER_ATTR, Pkg));
                _ ->
                    ignore
            end;
        _ ->
            case player:lookup_info(PlayerId, [?pd_name, ?pd_career, ?pd_level, ?pd_attr, ?pd_equip, ?pd_combat_power]) of
                [Name, Career, Level, Attr, ?none, Power] ->
                    EquipPkg = [],
                    AttrPkg = ?r2t(Attr),
                    Pkg = {PlayerId, Name, Career, Level, Power, AttrPkg, EquipPkg, []},
                    ?player_send(player_sproto:pkg_msg(?MSG_PLAYER_LOOKUP_PLAYER_ATTR, Pkg));
                [Name, Career, Level, Attr, EquipList, Power] ->
                    EquipPkg = EquipList,
                    AttrPkg = ?r2t(player_base_data:change_old_attr(Attr)),
                    QHList = equipment_mng:get_equip_goods_by_id(PlayerId),
                    Pkg = {PlayerId, Name, Career, Level, Power, AttrPkg, EquipPkg, QHList},
                    ?player_send(player_sproto:pkg_msg(?MSG_PLAYER_LOOKUP_PLAYER_ATTR, Pkg));
                _ ->
                    ?INFO_LOG("error handle_client 4 ~p", [{PlayerId}]),
                    ignore
            end
    end;

handle_client(?MSG_PLAYER_SYS_TIME, {}) ->
    % ?DEBUG_LOG("MSG_PLAYER_SYS_TIME------------------------"),
    ok;

handle_client(?MSG_PLAYER_COST_DIAMOND_BUY_SP, {Count}) ->
    %VipCFG = load_vip_right:lookup_vip_right_cfg(attr_new:get_vip_lvl()),
    %BuyLen = length(VipCFG#vip_right_cfg.vip_buy_sp),
    List = load_vip_new:get_vip_sp_by_vip_level(attr_new:get_vip_lvl()),
    BuyLen = length(List),
    BuyCount = get(?pd_sp_buy_count),
    AddSp = element(1, misc_cfg:get_misc_cfg(sp_info)) * Count,
    CurSp = attr_new:get(?pd_sp),
    BuySpLimit = misc_cfg:get_buy_sp_limit(),
    Reply =
    if
        AddSp + CurSp > BuySpLimit ->
            %% ?INFO_LOG("11111:~p", [{AddSp, CurSp, BuySpLimit}]),
            error;
        BuyCount + Count > BuyLen ->
            %% ?INFO_LOG("22222:~p", [{BuyCount, Count, BuyLen}]),
            error;
        true ->
            %% CostDiamondNum = lists:nth(BuyCount + 1, List),
            CostDiamondNum = get_cost_diamond_by_count(BuyCount + 1, BuyCount + Count , List, 0),
            %% ?INFO_LOG("CostDiamondNum:~p", [CostDiamondNum]),
            case game_res:try_del([{?PL_DIAMOND, CostDiamondNum}], ?FLOW_REASON_BUY_SP) of
                ok ->
                    bounty_mng:do_bounty_task(?BOUNTY_TASK_BUY_SP, Count),
                    open_server_happy_mng:sync_task(?SHOP_TILI_COUNT, Count),
                    player:add_value(?pd_sp, AddSp),
                    player:add_value(?pd_sp_buy_count, Count);
                {error, _Other} -> error
            end
    end,
    case Reply of
        error -> 
            ?player_send(player_sproto:pkg_msg(?MSG_PLAYER_COST_DIAMOND_BUY_SP, {1}));
        _ -> 
            ?player_send(player_sproto:pkg_msg(?MSG_PLAYER_COST_DIAMOND_BUY_SP, {0}))
    end;

handle_client(?MSG_SHOW_NEAR_PLAYER_SET, {PlayerCount}) ->
    PlayerCount1 = my_ets:get(misc_scene_view_max, 20),
    PlayerCount2 = erlang:min(PlayerCount1, PlayerCount),
    erlang:put(?pd_is_near_player_count_set, PlayerCount2),
    ?player_send(player_sproto:pkg_msg(?MSG_SHOW_NEAR_PLAYER_SET, {PlayerCount2})),
    get(?pd_scene_pid) ! ?scene_mod_msg(scene_player, {sync_near_player_limit, get(?pd_idx), PlayerCount2});

handle_client(?MSG_PLAYER_PING, {}) ->
    ok;
%%    %?DEBUG_LOG("MSG_PLAYER_PING------------------------------"),
%%    ?player_send(player_sproto:pkg_msg(?MSG_PLAYER_PING, {}));

handle_client(?MSG_PLAYER_UNDRESS_SHAPESHIFT, {}) ->
    shapeshift_mng:stop_shapeshift_effect();

handle_client(?MSG_PLAYER_DO_SURVEY_NOTIFY, {}) ->
    case attr_new:get(?pd_is_do_survey, 0) of
        1 ->
            ?player_send(player_sproto:pkg_msg(?MSG_PLAYER_DO_SURVEY_NOTIFY, {1}));
        _ ->
            PrizeId = misc_cfg:get_survey_prize(),
            {ok, PrizeList} = prize:get_prize(PrizeId),
            mail_mng:send_sysmail(get(?pd_id), ?S_MAIL_DO_SURVEY_PRIZE, PrizeList),
            ?player_send(player_sproto:pkg_msg(?MSG_PLAYER_DO_SURVEY_NOTIFY, {1})),
            attr_new:set(?pd_is_do_survey, 1)
    end;

handle_client(?MSG_PLAYER_RECONNECTION, {
    PlatformPlayerName,
    _PlatformId,
    _ServerId,
    _MachineMac,
    _MachineId,
    _MachineStyle,
    _MachineInfo,
    Index, _Vx, _Vy
}) ->
    [AccountTab] = dbcache:lookup(?account_tab, PlatformPlayerName),
    {_, PlayerId} = lists:keyfind(Index, 1, AccountTab#account_tab.player_id),
    case world:get_player_pid(PlayerId) of
        Pid when is_pid(Pid) ->
            Socket = get(?pd_socket),
            case gen_tcp:controlling_process(Socket, Pid) of
                ok ->
                    ?player_send(player_sproto:pkg_msg(?MSG_PLAYER_RECONNECTION, {1})),
                    ok;
                _ ->
                    ?player_send(player_sproto:pkg_msg(?MSG_PLAYER_RECONNECTION, {0}))
                    % put(pd_is_send_msg, false),
                    % attr_new:set(?pd_machine_mac, MachineMac),
                    % attr_new:set(?pd_machine_id, MachineId),
                    % attr_new:set(?pd_machine_style, MachineStyle),
                    % attr_new:set(?pd_machine_info, MachineInfo),
                    % account:auto_login_account(PlatformPlayerName, PlatformId, ServerId),
                    % account:login_player(Index, Vx, Vy),
                    % put(pd_is_send_msg, true)
            end;
        _ ->
            ?player_send(player_sproto:pkg_msg(?MSG_PLAYER_RECONNECTION, {0}))
            % put(pd_is_send_msg, false),
            % attr_new:set(?pd_machine_mac, MachineMac),
            % attr_new:set(?pd_machine_id, MachineId),
            % attr_new:set(?pd_machine_style, MachineStyle),
            % attr_new:set(?pd_machine_info, MachineInfo),
            % account:auto_login_account(PlatformPlayerName, PlatformId, ServerId),
            % account:login_player(Index, Vx, Vy),
            % put(pd_is_send_msg, true)
    end;
    % ?player_send(player_sproto:pkg_msg(?MSG_PLAYER_RECONNECTION, {1}));

handle_client(?MSG_VERSION, _Msg) ->
    ok;

handle_client(?MSG_PLAYER_CD_KEY, {CdKey}) ->
    CdKeyTypeList =
        case util:get_pd_field(?pd_cd_key_type_list, []) of
            0 ->
                [];
            TypeList ->
                TypeList
        end,
    NewCdKey = erlang:list_to_binary(string:to_upper(binary:bin_to_list(CdKey))),
    case op_player:get_cd_key_prize(NewCdKey, CdKeyTypeList) of
        {error, no_found} ->
            ?player_send(player_sproto:pkg_msg(?MSG_PLAYER_CD_KEY, {1}));
        {error, no_times} ->
            ?player_send(player_sproto:pkg_msg(?MSG_PLAYER_CD_KEY, {2}));
        {error, already_type} ->
            ?player_send(player_sproto:pkg_msg(?MSG_PLAYER_CD_KEY, {3}));
        {ok,PrizeId,Type} ->
            {ok, PrizeList} = prize:get_prize(PrizeId),
            case Type of
                101 ->  %%微信关注
                    mail_mng:send_sysmail(get(?pd_id), ?S_MAIL_ATTENTION_WECHAT, PrizeList);
                _ ->
                    mail_mng:send_sysmail(get(?pd_id), ?S_MAIL_CD_KEY, PrizeList)
            end,
            util:set_pd_field(?pd_cd_key_type_list, [Type | CdKeyTypeList]),
            ?player_send(player_sproto:pkg_msg(?MSG_PLAYER_CD_KEY, {0}));
        _ ->
            ?player_send(player_sproto:pkg_msg(?MSG_PLAYER_CD_KEY, {255}))
    end;

handle_client(?MSG_PLAYER_ADD_HOURLY_SP, {}) ->
    {{LunchStart,LunchEnd,LunchSp},{DinnerStart,DinnerEnd,DinnerSp}} = misc_cfg:get_sp_time(),
    {_, CurTime} = calendar:local_time(),
    Ret =
        if
            CurTime >= LunchStart andalso CurTime =< LunchEnd ->
                case util:get_pd_field(?pd_hourly_sp_lunch, 0) of
                    0 ->
                        {ok, lunch};
                    _ ->
                        {error, already_get}
                end;
            CurTime >= DinnerStart andalso CurTime =< DinnerEnd ->
                case util:get_pd_field(?pd_hourly_sp_dinner, 0) of
                    0 ->
                        {ok, dinner};
                    _ ->
                        {error, already_get}
                end;
            true ->
                {error, not_in_time}
        end,
    case Ret of
        {error, not_in_time} ->
            ?player_send(player_sproto:pkg_msg(?MSG_PLAYER_ADD_HOURLY_SP, {2})); %% 不在领取时间范围内
        {error, already_get} ->
            ?player_send(player_sproto:pkg_msg(?MSG_PLAYER_ADD_HOURLY_SP, {1})); %% 已领取体力
        {ok, lunch} ->
            player:add_value(?pd_sp, LunchSp),
            util:set_pd_field(?pd_hourly_sp_lunch, 1),
            ?player_send(player_sproto:pkg_msg(?MSG_PLAYER_ADD_HOURLY_SP, {0})),
            ?player_send(player_sproto:pkg_msg(?MSG_PLAYER_PUSH_HOURLY_SP_STATUS, {1}));
        {ok, dinner} ->
            player:add_value(?pd_sp, DinnerSp),
            util:set_pd_field(?pd_hourly_sp_dinner, 1),
            ?player_send(player_sproto:pkg_msg(?MSG_PLAYER_ADD_HOURLY_SP, {0})),
            ?player_send(player_sproto:pkg_msg(?MSG_PLAYER_PUSH_HOURLY_SP_STATUS, {1}))
    end;

handle_client(?MSG_PLAYER_PROGRESS_NOTICE, {ProgressId}) ->
    case is_integer(ProgressId) andalso ProgressId > 0 of
        true  -> ?DEBUG_LOG("11111111111111"), system_log:info_load_progress(ProgressId);
        _ -> pass
    end;

handle_client(?MSG_PLAYER_GET_SHARE_GAME_PRIZE, {ShareType}) ->
    Reply =
        case ShareType of
            ?SHARE_GAME -> %% 分享
                util:set_pd_field(?pd_share_game_status, 1),
                player_mng:push_share_game_state(),
                ?REPLY_SHARE_GAME_OK;
            ?PRIZE_SHARE_GAME ->
                case util:get_pd_field(?pd_share_game_status, 0) of
                    0 ->    %% 未分享
                        ?REPLY_SHARE_GAME_1;
                    _ ->
                        case util:get_pd_field(?pd_prize_share_game_status, 0) of
                            0 ->
                                PrizeId = misc_cfg:get_share_prize(),
                                {ok, PrizeList} = prize:get_prize(PrizeId),
                                mail_mng:send_sysmail(get(?pd_id), ?S_MAIL_SHARE_GAME, PrizeList),
                                %% 设置领奖状态
                                util:set_pd_field(?pd_prize_share_game_status, 1),
                                player_mng:push_share_game_state(),
                                ?REPLY_SHARE_GAME_OK;
                            _ ->
                                ?REPLY_SHARE_GAME_2
                        end
                end;
            _ ->
                ?REPLY_SHARE_GAME_255
        end,
    ?player_send(player_sproto:pkg_msg(?MSG_PLAYER_GET_SHARE_GAME_PRIZE, {Reply}));

handle_client(_Mod, _Msg) ->
    ?err("unkonu msg").

get_cost_diamond_by_count(BuyCount, BuyCount, List, AllCost) ->
    CostDiamondNum = lists:nth(BuyCount, List),
    AllCost + CostDiamondNum;
get_cost_diamond_by_count(BuyCount, CanBuyCount, List, AllCost) when BuyCount < CanBuyCount ->
    CostDiamondNum = lists:nth(BuyCount, List),
    get_cost_diamond_by_count(BuyCount + 1, CanBuyCount, List, AllCost + CostDiamondNum);
get_cost_diamond_by_count(BuyCount, CanBuyCount, _List, _AllCost) ->
    ?ERROR_LOG("BuyCount:~p > CanBuyCount:~p", [BuyCount, CanBuyCount]),
    error.


