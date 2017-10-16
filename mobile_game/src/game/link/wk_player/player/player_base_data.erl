%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%% 玩家基础数据（会给多个模块用的玩家数据放于这里）
%%% @end
%%% Created : 26. 六月 2015 上午2:51
%%%-------------------------------------------------------------------
-module(player_base_data).
-author("clark").

%% API
-export([
    create_mod_data/3,
    get_attr/1,
    init_attr_global_image/1,
    update_equip_global_image/1,
    update_attr_global_image/1,
    get_net_dial_prize/1,
    change_old_attr/1,
    on_time/0
]).



-include("inc.hrl").
-include_lib("common/include/inc.hrl").
-include("player.hrl").
-include("player_mod.hrl").
-include("player_data_db.hrl").
-include_lib("common/include/com_log.hrl").
-include("item_bucket.hrl").
-include("load_spirit_attr.hrl").
-include("achievement.hrl").
-include("payment.hrl").
-include("arena.hrl").
-include("team.hrl").

-define(player_base_data_timer, player_base_data_timer).
% -define(pd_player_base_data_count_down_time, pd_player_base_data_count_down_time).
-define(player_base_data_reset, player_base_data_reset).
-define(RESET_PLAYER_DATA_TIME, 5000).
-define(pd_player_init_power, pd_player_init_power).



view_data(Acc) -> Acc.

online() ->
    msg_service:player_online().

handle_frame(_Frame) -> ok.

handle_msg(_FromMod, {?player_base_data_reset}) ->
    on_time();

handle_msg(_FromMod, {test_guild_boss}) ->
    guild_boss:sync_boss_hp();

handle_msg(_FromMod, _Msg) -> ok.


%% 玩家首次登陆回调时， 创建角色字段表
create_mod_data(SelfId) ->
    Name = get(?pd_name),
    Career = get(?pd_career),
    create_mod_data(SelfId, Name, Career).

create_mod_data(SelfId, Name, Career) ->
    Now = com_time:now(),
    % Name = erase(?pd_name),
    % Career = get(?pd_career),
    ?assertNotEqual(?undefined, Name),
    ?assertNotEqual(?undefined, Career),
    AttrId = load_career_attr:get_lev_attr_id(Career, 1),
    Attr = attr:amend(AttrId),
    Attr1 = attr_new:get_oldversion_attr(),
    InitPower = attr:get_combat_power(Attr1),
    put(?pd_player_init_power, InitPower),
    PlayerTab = #player_tab
    {
        id = SelfId,
        name = Name,
        career = Career,
        scene_id = load_cfg_scene:get_default_scene_id(Career),
        create_time = Now,
        last_login_time = Now,
        last_logout_time = Now,
        hp = Attr#attr.hp,
        mp = Attr#attr.mp,
%%        sp = element(2, misc_cfg:get_misc_cfg(sp_info))
        sp = Attr#attr.sp
    },
    %% 给模糊查询中添加数据源
    % esqlite_config:insert(player_tab, Name),
    case dbcache:insert_new(?player_tab, PlayerTab) of
        ?true ->
            dbcache:insert_new(?player_name_tab, #player_name_tab{name = Name, id = SelfId});
        ?false ->
            ?ERROR_LOG("player ~p create not alread exists ", [SelfId])
    end,
    %% player_attr_tab -------------------
    case dbcache:insert_new(?player_attr_tab, #player_attr_tab{id = SelfId, attr = Attr}) of
        ?true -> ok;
        ?false ->
            ?ERROR_LOG("player ~p create player_sprit_ta but alread exists ", [SelfId])
    end,
    %% player_client_data_tab -------------------
    case dbcache:insert_new(?player_client_data_tab, #player_client_data_tab{id = SelfId, data = orddict:new()}) of
        ?true -> ok;
        ?false ->
            ?ERROR_LOG("player ~p create player_client_data_tab but alread exists ", [SelfId])
    end,
    %% player_misc_tab -------------------
    Misc = #player_misc_tab{id = SelfId, val = player:init_misc(gb_trees:empty())},
    case dbcache:insert_new(?player_misc_tab, Misc) of
        ?true -> ok;
        ?false ->
            ?ERROR_LOG("player ~p create player_misc_tab but alread exists ", [SelfId])
    end,
    %% player_data_tab -------------------
    PlayerData = #player_data_tab{player_id = SelfId, field_data = []},
    case dbcache:insert_new(?player_data_tab, PlayerData) of
        ?true -> ok;
        _ ->
            ?ERROR_LOG("创建角色字段表失败 ~w ~w", [SelfId, PlayerData])
    end,
    PPayment = #player_payment_tab{id = SelfId, val = player:init_misc(gb_trees:empty())},
    case dbcache:insert_new(player_payment_tab, PPayment) of
        true -> ok;
        _ ->
            ?ERROR_LOG("player ~p create player_payment_tab but alread exists ", [SelfId])
    end.



init_equip_global_image(PlayerID) ->
    case dbcache:load_data(?player_equip_tab, PlayerID) of
        [] ->
            EqmBucket = game_res:get_bucket(?BUCKET_TYPE_EQM),
            %?DEBUG_LOG("EqmBucketQ---------:~p",[EqmBucket]),
            NewDBRecord = player_data_db:new_bucket_db_record(PlayerID, EqmBucket),
            dbcache:insert_new(?player_equip_tab, NewDBRecord);
        _ ->
            ret:ok()
    end.

init_attr_global_image(PlayerID) ->
    case dbcache:load_data(?player_attr_image_tab, PlayerID) of
        [] ->
            PlayerAttr = attr_new:get_oldversion_attr(),
            dbcache:insert_new(?player_attr_image_tab, #player_attr_image_tab{id = PlayerID, attr_new = PlayerAttr});
        _ ->
            ret:ok()
    end.


load_mod_data(SelfId) ->
    erlang:erase(?pd_name),
    erlang:erase(?pd_career),
%%     ?ERROR_LOG("player enter load_mod_data"),
    put(?pd_init_cliend_completed, 0),
    %% player_tab -------------------
    case dbcache:load_data(?player_tab, SelfId) of
        [] ->
            ?ERROR_LOG("player ~p can not find data ~p mode", [SelfId, ?MODULE]),
            exit({?err_load, "can not find data"});
        [P] ->
            ?recrod_put_pd(P, ?player_tab),
            ?pd_new(?pd_name_pkg, <<?pkg_sstr(P#player_tab.name)>>),
            ?pd_new(?pd_last_online_time, com_time:now()),
            ?pd_new(?pd_is_die, ?false),
            ?assert(?pd_last_logout_time =/= ?undefined),
            com_process:init_name(get(?pd_name)),
            com_process:init_type(?PT_PLAYER),
            ok
    end,
    %% player_attr_tab -------------------
    case dbcache:load_data(?player_attr_tab, SelfId) of
        [] ->
            ?ERROR_LOG("player_attr_tab ~p can not find data ~p mode", [SelfId, ?MODULE]),
            exit({?err_load, "can not find data"});
        [#player_attr_tab{attr = Attr}] ->
            NAttr = change_old_attr(Attr),
            ?pd_new(?pd_attr, NAttr),
            put(?pd_combat_power, attr:get_combat_power(NAttr))
    end,
    %% player_misc_tab -------------------
    case dbcache:load_data(?player_misc_tab, SelfId) of
        [] ->
            ?ERROR_LOG("player_misc_tab ~p can not find data ~p mode", [SelfId, ?MODULE]),
            exit({?err_load, "can not find data"});
        [#player_misc_tab{}] -> ok
    end,
    %% player_data_tab -------------------
    case dbcache:load_data(?player_data_tab, SelfId) of
        [] ->
            ?ERROR_LOG("加载角色字段表失败, 尝试修补 ~w ~w", [SelfId, ?MODULE]),
            create_mod_data(SelfId);
        [#player_data_tab{field_data = FieldData}]->
            %% 刷新基础属性
            attr_new:init(SelfId, FieldData),
            %% 刷新背包
            %Bucket1 = attr_new:get(?pd_goods_bucket),
            %attr_new:set(?pd_goods_bucket, Bucket1),
            %Bucket2 = attr_new:get(?pd_depot_bucket),
            %attr_new:set(?pd_depot_bucket, Bucket2),
            %Bucket3 = attr_new:get(?pd_equip_bucket),
            %attr_new:set(?pd_equip_bucket, Bucket3),
            % NewEquip = item_equip:build(100000001, []),
            % item_equip:take_on(NewEquip),
            ok
    end,
    %% client data -------------------
    ClientPriveData =
    case dbcache:lookup(?player_client_data_tab, SelfId) of
        [] ->
            NewData = orddict:new(),
            dbcache:insert_new(?player_client_data_tab, #player_client_data_tab{id = SelfId, data = NewData}),
            NewData;
        [#player_client_data_tab{data = CurData}] ->
            CurData
    end,
    put(?pd_client_data, ClientPriveData),
    ok.




%% 尝试做需要日，月重置数据
on_time() ->
    timer_eng:start_tmp_timer(?player_base_data_timer, ?RESET_PLAYER_DATA_TIME, ?MODULE, {?player_base_data_reset}),
    try_date_reset().


%% 保存角色字段数据
offline(RoleId) ->
    % scene_arena:player_leave_arean_scene(get(?pd_idx)),
    save_data(RoleId),
    system_log:info_role_logout(RoleId),
    system_log:info_account_logout(RoleId),

    case erlang:get(?pd_player_scene_time_count) of
        undefined ->
            erlang:put(?pd_player_scene_time_count, attr_new:get_online_time_this());
        0 ->
            erlang:put(?pd_player_scene_time_count, attr_new:get_online_time_this());
        RetS ->
            erlang:put(?pd_player_scene_time_count, RetS + attr_new:get_online_time_this())
    end,
    erlang:put(?pd_player_scene_second_this_time, 0),
    ok.

%% 给player_mng调用的奇怪接口
save_data(SelfId) ->
%%     ?INFO_LOG("save_data-------------------------------: ~p",[SelfId]),
    ?assertNotEqual(?undefined, get(?pd_career)),
    Data = ?recrod_get_pd(?player_tab),
%%     ?DEBUG_LOG("save_data-------------------------------: ~p",[{SelfId, Data}]),
    dbcache:update(?player_tab, Data),

    %% 这个保存的可以保留，因为现在查看别人属性，是通过查保存记录来实现的。
    %% 保存的可以保留，只是上线时的动态计算，不读保存值的即可。
    dbcache:update(?player_attr_tab, #player_attr_tab{id = SelfId, attr = get(?pd_attr)}),
    dbcache:update(?player_client_data_tab, #player_client_data_tab{id = SelfId, data = erlang:get(?pd_client_data)}),

    %% 装备镜像
    update_equip_global_image(SelfId),

    %% 属性镜像
    update_attr_global_image(SelfId),

    %% ?debug_log_player("player ~p offlien sparit ~p", [?pname(), get(?pd_sprite_stat)]),
    FieldData = attr_new:uninit(SelfId),
    dbcache:update(?player_data_tab, #player_data_tab
    {
        player_id = SelfId,
        field_data = FieldData
    }),

    %% 此处把玩家的特效列表保存到数据库中
    PlayerId = get(?pd_id),
    EftsList =
        case attr_new:get(?pd_player_efts_list, []) of
            0 ->
                [];
            ListRet ->
                ListRet
        end,
    List = attr_new:get(?pd_temp_equip_efts, []),
    EftsList1 = lists:keystore(PlayerId, 1, EftsList, {PlayerId, List}),
    put(?pd_player_efts_list, EftsList1),
    ok.


%% 初始化客户端
init_client() ->
    %% 初始化数据
    equip_system:restore_equip_system(),
    equip_system:restore_equip_fumo_state(),
    goods_system:restore_goods_system(),
    crown_new_mng:restore_crown(),%%还原人物身上的皇冠
    arena_mng:restore_arena_attr(),
    achievement_mng:do_ac2(?zuiqiangzhanli, 0, attr_new:get(?pd_player_init_power, 0)),
    %% 还原人物的坐骑属性和兽魂属性
    ride_mng:restore_ride_attr(),
    equip_system:restone_part_qiang_hua_attr(),
    %% 根据离线时间添加体力
    player_mng:add_sp_offline(),
    %% player_mng:add_offline_hourly_sp(),
    PlayerAttr = attr_new:get_oldversion_attr(),
    Val = attr_new:get_combat_power(PlayerAttr),
    attr_new:set(?pd_combat_power, Val),
    put(?pd_hp, 0), put(?pd_mp, 0),    %% 保存了原来的血量和蓝量，这里重置掉
    attr_new:set(?pd_hp, attr_new:get_attr_item(?pd_attr_max_hp)),
    attr_new:set(?pd_mp, attr_new:get_attr_item(?pd_attr_max_mp)),
    % attr_new:set(?pd_sp, attr_new:get_attr_item(?pd_attr_max_sp)),
    % ?INFO_LOG("pd_sp: ~p", [get(?pd_sp)]),
    % ?INFO_LOG("pd_attr_max_sp: ~p", [attr_new:get_attr_item(?pd_attr_max_sp)]),
    % attr_new:set(?pd_arena_opponent_order, 0),
    % ?DEBUG_LOG("jinxing--------------------:~p",[get(?pd_main_ins_yinxing)]),

    PlayerBin =
        player_sproto:pkg_msg(?MSG_PLAYER_INIT_CLIENT,
            {
                get(?pd_id),
                get(?pd_name),
                get(?pd_career),
                get(?pd_level),
                get(?pd_exp),
                get(?pd_fragment),
                get(?pd_longwens),
                get(?pd_money),
                get(?pd_diamond),
                get(?pd_honour),
                get(?pd_main_ins_jinxing),
                get(?pd_main_ins_yinxing),
                get(?pd_hp),
                get(?pd_mp),
                get(?pd_sp),
                get(?pd_sp_buy_count),
                ?r2t(PlayerAttr),
                get(?pd_combat_power),
                get(?pd_crown_yuansu_moli),
                get(?pd_crown_guangan_moli),
                get(?pd_crown_mingyun_moli)
            }),
    ?player_send(PlayerBin),
    %% 发送装备的部位强化信息
    equip_system:restone_part_qiang_hua_list(),
    pack_open_module_list(),
    %% 完成客户端初始化
    put(?pd_init_cliend_completed, 1),
    equip_system:sync_equip_efts(),
    equip_system:sync_skill_change_list(),

    %% 同步变身卡牌特效
    case attr_new:get(?pd_shapeshift_data, 0) of
        0 ->
            ok;
        _ ->
            goods_system:sync_shapeshift_data()
    end,

    %% 虚空深渊奖励补发
    abyss_mng:send_prize_email(),

    %% 初始化装备镜像
    init_equip_global_image(get(?pd_id)),

    %% 初始化属性镜像
    init_attr_global_image(get(?pd_id)),

    % arena_player:init(),
    impact_ranking_list_handle_client:send_suit_list_to_client(),

    %% 下发开关数据
    ?player_send(sinks_state_sproto:pkg_msg(?MSG_INIT_SINK_DATA_SC, {get(?pd_sinks_state)})),

    %% 下发转盘奖励数据
    DialPrize = get(?pd_dial_prize),
    DialPrizeList = get_net_dial_prize(DialPrize#dial_prize.dial_prize),
    DialTime = com_time:get_seconds_to_next_day() + com_time:now(),
    ?player_send(login_prize_sproto:pkg_msg(?MSG_ROLL_ITEM_DATA_SC, {DialTime, DialPrize#dial_prize.dial_count, DialPrizeList})),

    %% 下发登陆奖励数据
    LoginPrize = get(?pd_login_prize),
    %% ?player_send(login_prize_sproto:pkg_msg(?MSG_LOGIN_DAY_DATA_SC, {LoginPrize#login_prize.login_count, LoginPrize#login_prize.give_count})),
    ?player_send(login_prize_sproto:pkg_msg(?MSG_PUSH_SIGN_INFO, {com_time:day_of_the_month(), LoginPrize#login_prize_new.sign_info_list})),
    %% io:format("base_data:sign_info_list:~p", [LoginPrize#login_prize_new.sign_info_list]),

    main_instance_mng:sync_clean_room_list(),
    %% 下发VIP相关数据
    %% pay_goods_part:sync_vip_data(),
    %% 分享游戏
    %% player_mng:push_share_game_state(),

    %% 下发消费奖励
    %DayTotalConsume = get(?pd_day_total_consume),
    %TotalConsume = get(?pd_total_consume),
    %?player_send(charge_reward_sproto:pkg_msg(?MSG_CHARGE_INFO_SC, {DayTotalConsume, TotalConsume})),

    %% 公会buf
%%    ?player_send(player_sproto:pkg_msg(?MSG_PLAYER_SYNC_SOCIETY_BUFS, {get(?pd_society_bufs)})),

%%     ?INFO_LOG("g_misc pd_id ~p", [{get(?pd_id), load_db_misc:get(1, 7777)}]),
%%     info_log:player(get(?pd_id), get(?pd_name), [{1,1},{1,1},{1,1}]),
    impact_ranking_list_handle_client:push_rank_shop_buy_count(),

    put(?pd_player_scene_second_this_time, util:get_now_second(0)),
    RoomPro = attenuation:get_attenuation_pro(),
    ?player_send(player_sproto:pkg_msg(?MSG_PLAYER_EARNINGS_CHANGE, {erlang:round(RoomPro * 100)})), %%   把增益的更改发送到前端

    PlayerCountLimit = global_data:get(misc_scene_view_max, 20),
    case attr_new:get(?pd_is_near_player_count_set, 0) of
        0 ->
            erlang:put(?pd_is_near_player_count_set, PlayerCountLimit),
            ?player_send(player_sproto:pkg_msg(?MSG_SHOW_NEAR_PLAYER_SET, {PlayerCountLimit}));
        Count ->
            ?player_send(player_sproto:pkg_msg(?MSG_SHOW_NEAR_PLAYER_SET, {Count}))
    end,

    guild_boss:sync_self_apply(),

    IsDoSurvey = attr_new:get(?pd_is_do_survey, 0),
    ?player_send(player_sproto:pkg_msg(?MSG_PLAYER_DO_SURVEY_NOTIFY, {IsDoSurvey})),
    
    ok.
%on_time().

pack_open_module_list() ->
    List = my_ets:get(is_open_module, []),
    ?player_send(player_sproto:pkg_msg(?MSG_PLAYER_GM, {List})).

%% 尝试重置数据
try_date_reset() ->
    PlayerId = get(?pd_id),
    RecordTime = get(?pd_last_reflash_tm),
    {RY, RM, RD} = case RecordTime of
        {X, Y, Z} ->
            {X, Y, Z};
        undefined ->
            {TempY, TempM, TempD} = virtual_time:date(),
            put(?pd_last_reflash_tm, {TempY, TempM, TempD}),
            {TempY, TempM, TempD}
    end,
    RecordDay = util:get_days({RY, RM, RD}),
    LastWeekCounts = (RecordDay - 2) div 7,
    {CY, CM, CD} = virtual_time:date(),
    CurDay = util:get_days({CY, CM, CD}),
    CurWeekCounts = (CurDay - 2) div 7,
    if
        CurDay > RecordDay ->
            if
                RM =/= CM ->
                    %% 月刷新
                    [Mod:on_month_reset(PlayerId) || Mod <- month_reset:callback_list()];
                true ->
                    false
            end,
            if
                LastWeekCounts =/= CurWeekCounts ->
                    %% 周刷新 周一刷新
                    [Mod:on_week_reset(PlayerId) || Mod <- week_reset:callback_list()];
                true ->
                    false
            end,
            %% 日刷新
            [Mod:on_day_reset(PlayerId) || Mod <- day_reset:callback_list()],
            %% 刷新记录
            put(?pd_last_reflash_tm, {CY, CM, CD});
        true ->
            false
    end.


get_attr(#player_attr_tab{attr = Attr}) -> Attr.


%% 获得转盘数据的网络格式
get_net_dial_prize([]) -> [];
get_net_dial_prize([Head | TailList]) ->
    case Head of
        {_Id, Goods, Num, State} ->
            [{Goods, Num, State} | get_net_dial_prize(TailList)];
        _ ->
            []
    end.


update_equip_global_image(PlayerID) ->
    EqmBucket = game_res:get_bucket(?BUCKET_TYPE_EQM),
    NewDBRecord = player_data_db:new_bucket_db_record(PlayerID, EqmBucket),
    dbcache:update(?player_equip_tab, NewDBRecord).


update_attr_global_image(PlayerID) ->
    PlayerAttr = attr_new:get_oldversion_attr(),
    dbcache:update(?player_attr_image_tab, #player_attr_image_tab{id = PlayerID, attr_new = PlayerAttr}).

change_old_attr(#attr{} = Attr) ->
    Attr;
change_old_attr(Attr) when is_tuple(Attr) ->
    AttrList = tuple_to_list(Attr),
    {NAttr, _} =
        lists:foldl(
            fun(Val, {Acc, Index}) ->
                if
                    Index =:= 1 ->
                        {Acc, Index + 1};
                    true ->
                        OldVal = element(Index, Acc),
                        NAcc = setelement(Index, Acc, (OldVal + Val)),
                        {NAcc, Index + 1}
                end
            end,
            {#attr{}, 1},
            AttrList),
    NAttr;

change_old_attr(Attr) ->
    Attr.

