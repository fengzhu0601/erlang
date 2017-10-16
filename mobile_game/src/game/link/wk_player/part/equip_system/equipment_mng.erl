%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 29. 七月 2015 下午5:59
%%%-------------------------------------------------------------------
-module(equipment_mng).
-author("clark").

%% API
-export([get_equip_goods_by_id/1]).

-include_lib("pangzi/include/pangzi.hrl").
-include("player_mod.hrl").
-include("inc.hrl").
-include("handle_client.hrl").
-include("equip_mng_reply.hrl").
-include("player.hrl").
-include("achievement.hrl").
-include("load_phase_ac.hrl").
-include("equip.hrl").
-include("item_bucket_def.hrl").
-include("../wonderful_activity/bounty_struct.hrl").
-include("item_new.hrl").
-include("../../../wk_open_server_happy/open_server_happy.hrl").

get_equip_goods_by_id(PlayerId) ->
    case dbcache:lookup(?player_equip_goods_tab, PlayerId) of
        [] ->
            [];
        [#player_equip_goods_tab{qianghu_list = QHList}] ->
            QHList
    end.


%%----------------------------------------------------
handle_client({Pack, Arg}) ->
    handle_client(Pack, Arg).

%% 穿装备
handle_client(?MSG_EQUIP_DRESS, {ToEquipPos, GoodsID}) ->
    case api:is_take_equip() andalso task_mng_new:is_doing_task(40002) of
        true ->
            system_log:info_load_progress(12);
        _ ->
            pass
    end,
    attr_new:begin_sync_attr(),
    Ret = equip_system:try_take_on_equip(GoodsID, ToEquipPos),
    attr_new:end_sync_attr(),
    ReplyNum =
        case Ret of
            ok ->
%%                ?INFO_LOG("gem_num ret:~p", [api:gem_num_full()]),
                case api:gem_num_full() of
                    ?TRUE ->
                        achievement_mng:do_ac(?yishenshenzhuang);
                    _ ->
                        pass
                end,
                api:send_color_equip_count(),
                open_server_happy_mng:sync_task(?TAKE_ON_PURPLE_EQUIP_COUNT, api:get_color_equip_count(?equip_purple)),
                open_server_happy_mng:sync_task(?TAKE_ON_ORANGE_EQUIP_COUNT, api:get_color_equip_count(?equip_orange)),
                open_server_happy_mng:sync_task(?TAKE_ON_SUIT_EQUIP_COUNT, api:get_suit_count()),
                ?REPLY_MSG_EQUIP_DRESS_OK;                                %% ok
            {error, not_jd} -> ?REPLY_MSG_EQUIP_DRESS_1;                     %% 装备未鉴定，不能穿着
            {error, cant_put_on_eqm} -> ?REPLY_MSG_EQUIP_DRESS_3;            %% 所要穿着装备的类型错误
            _ -> ?REPLY_MSG_EQUIP_DRESS_255                                 %% 穿着装备失败，请重试。重试失败请联系GM
        end,
    ?player_send(equip_sproto:pkg_msg(?MSG_EQUIP_DRESS, {ReplyNum})),
    EquipBin = equip_system:get_takeon_equips_list(),
    get(?pd_scene_pid) ! ?scene_mod_msg(scene_player, {update_agent_info, self(), get(?pd_career), 1, EquipBin});


%% 脱装备
handle_client(?MSG_EQUIP_UNDRESS, {GoodsID}) ->
    attr_new:begin_sync_attr(),
    Ret = equip_system:try_take_off_equip(GoodsID),
    attr_new:end_sync_attr(),
    ReplyNum =
        case Ret of
            ok ->
                api:send_color_equip_count(),
                open_server_happy_mng:sync_task(?TAKE_ON_PURPLE_EQUIP_COUNT, api:get_color_equip_count(?equip_purple)),
                open_server_happy_mng:sync_task(?TAKE_ON_ORANGE_EQUIP_COUNT, api:get_color_equip_count(?equip_orange)),
                open_server_happy_mng:sync_task(?TAKE_ON_SUIT_EQUIP_COUNT, api:get_suit_count()),
                ?REPLY_MSG_EQUIP_UNDRESS_OK;                              %% ok
            {error, bag_bucket_full} -> ?REPLY_MSG_EQUIP_UNDRESS_1;          %% 背包满，无法脱装备
            {error, not_found_eqm} -> ?REPLY_MSG_EQUIP_UNDRESS_2;            %% 无法找到要脱的装备
            _ -> ?REPLY_MSG_EQUIP_UNDRESS_255                               %% 脱装备失败，请重试。重试失败请联系GM
        end,
    ?player_send(equip_sproto:pkg_msg(?MSG_EQUIP_UNDRESS, {ReplyNum})),
    EquipBin = equip_system:get_takeon_equips_list(),
    get(?pd_scene_pid) ! ?scene_mod_msg(scene_player, {update_agent_info, self(), get(?pd_career), 1, EquipBin});


%% 鉴定装备
%%handle_client(?MSG_EQUIP_JIANDING, {GoodsID}) ->
%%    attr_new:begin_sync_attr(),
%%    Ret = equip_system:try_jianding(GoodsID),
%%    attr_new:end_sync_attr(),
%%    ReplyNum =
%%        case Ret of
%%            ok -> ?REPLY_MSG_EQUIP_JIANDING_OK;                             %% ok
%%            {error, diamond_not_enough} -> ?REPLY_MSG_EQUIP_JIANDING_1;      %% 鉴定装备失败，钻石不足
%%            {error, cost_not_enough} -> ?REPLY_MSG_EQUIP_UNDRESS_2;          %% 鉴定装备失败，金钱不足
%%            {error, already_jd} -> ?REPLY_MSG_EQUIP_JIANDING_3;              %% 装备已鉴定，莫扯蛋
%%            _ -> ?REPLY_MSG_EQUIP_JIANDING_255                              %% 脱装备失败，请重试。重试失败请联系GM
%%        end,
%%    ?player_send(equip_sproto:pkg_msg(?MSG_EQUIP_JIANDING, {ReplyNum}));

%% 鉴定装备
%%handle_client(?MSG_EQUIP_JIANDING_ALL, {}) ->
%%    attr_new:begin_sync_attr(),
%%    equip_system:try_all_jianding(),
%%    attr_new:end_sync_attr(),
%%    ?player_send(equip_sproto:pkg_msg(?MSG_EQUIP_JIANDING_ALL, {?REPLY_MSG_EQUIP_JIANDING_OK}));

%% 镶嵌宝石(可以直接在装备栏或者背包栏镶嵌)
handle_client(?MSG_EQUIP_EMBED_GEM, {BucketType, GoodsID, SlotIndex, GemId}) ->
    attr_new:begin_sync_attr(),
    Ret = equip_system:try_embed_gem(BucketType, GoodsID, SlotIndex, GemId),
    attr_new:end_sync_attr(),
    achievement_mng:do_ac(?xiangqiandaren),
    ReplyNum =
        case Ret of
            ok ->
                case api:gem_num_full() of
                    ?TRUE ->
                        achievement_mng:do_ac(?yishenshenzhuang);
                    _ ->
                        pass
                end,
                bounty_mng:do_bounty_task(?BOUNTY_TASK_XIANGQIAN_EQUIP, 1),
                daily_task_tgr:do_daily_task({?ev_equ_xiangqian, 0}, 1),
                event_eng:post(?ev_equ_xiangqian, {?ev_equ_xiangqian, 0}, 1),
                ?REPLY_MSG_EQUIP_EMBED_GEM_OK;                            %% ok
            {error, diamond_not_enough} -> ?REPLY_MSG_EQUIP_EMBED_GEM_1;     %% 鉴定装备失败，钻石不足
            {error, cost_not_enough} -> ?REPLY_MSG_EQUIP_EMBED_GEM_3;        %% 鉴定装备失败，金钱不足
            {error, has_same_type_gem} -> ?REPLY_MSG_EQUIP_EMBED_GEM_4;      %% 镶嵌宝石失败,不能镶嵌同类型宝石
            {error, gem_post_not_enough} -> ?REPLY_MSG_EQUIP_EMBED_GEM_2;    %% 镶嵌宝石失败，宝石孔位不足
            _ -> ?REPLY_MSG_EQUIP_EMBED_GEM_255                             %% 镶嵌宝石失败，请重试。重试失败，请联系GM
        end,
    ?player_send(equip_sproto:pkg_msg(?MSG_EQUIP_EMBED_GEM, {ReplyNum}));


%% 摘除宝石
handle_client(?MSG_EQUIP_UNEMBED_GEM, {BucketType, GoodsID, SlotIndex}) ->
    attr_new:begin_sync_attr(),
    Ret = equip_system:try_unembed_gem(BucketType, GoodsID, SlotIndex),
    attr_new:end_sync_attr(),
    ReplyNum =
        case Ret of
            ok -> ?REPLY_MSG_EQUIP_UNEMBED_GEM_OK;                          %% ok
            {error, bucket_full} -> ?REPLY_MSG_EQUIP_UNEMBED_GEM_1;          %% 摘除宝石失败，背包已满
            _ -> ?REPLY_MSG_EQUIP_UNEMBED_GEM_255                           %% 摘除宝石失败，请重试。重试失败，请联系GM
        end,
    ?player_send(equip_sproto:pkg_msg(?MSG_EQUIP_UNEMBED_GEM, {ReplyNum}));


%% 摘除所有宝石
handle_client(?MSG_EQUIP_UNEMBED_ALL_GEM, {BucketType, GoodsID}) ->
    attr_new:begin_sync_attr(),
    Ret = equip_system:try_unembed_all_gem(BucketType, GoodsID),
    attr_new:end_sync_attr(),
    ReplyNum =
        case Ret of
            ok -> ?REPLY_MSG_EQUIP_UNEMBED_ALL_GEM_OK;                       %% ok
            {error, bucket_full} -> ?REPLY_MSG_EQUIP_EMBED_GEM_1;            %% 摘除宝石失败，背包已满
            _ -> ?REPLY_MSG_EQUIP_UNEMBED_ALL_GEM_255                        %% 摘除宝石失败，请重试。重试失败，请联系GM
        end,
    ?player_send(equip_sproto:pkg_msg(?MSG_EQUIP_UNEMBED_ALL_GEM, {ReplyNum}));


%% 强化
%%handle_client(?MSG_EQUIP_QIANG_HUA, {BucketType, GoodsID, IsDownLevelFree}) ->
%%    attr_new:begin_sync_attr(),
%%    Ret = equip_system:try_qiang_hua(BucketType, GoodsID, IsDownLevelFree),
%%    attr_new:end_sync_attr(),
%%    achievement_mng:do_ac(?qianghuazhixing),
%%    event_eng:post(?ev_equ_qiang_hua, {?ev_equ_qiang_hua, 0}, 1),
%%    daily_task_tgr:do_daily_task({?ev_equ_qiang_hua, 0}, 1),
%%    ReplyNum =
%%        case Ret of
%%            ok ->
%%                bounty_mng:do_bounty_task(?BOUNTY_TASK_QIANGHUA_EQUIP, 1),
%%                %event_eng:post(?ev_equ_qiang_hua, {?ev_equ_qiang_hua, 0}, 1),
%%                %daily_task_tgr:do_daily_task({?ev_equ_qiang_hua, 0}, 1),
%%                phase_achievement_mng:do_pc(?PHASE_AC_EQUIP_QIANGHUA, 10, api:get_equip_qhlvl_count()),
%%                ?REPLY_MSG_EQUIP_QIANG_HUA_OK;                            %% ok
%%            {error, not_jian_ding} -> ?REPLY_MSG_EQUIP_QIANG_HUA_1;          %% 强化失败，未鉴定
%%            {error, max_qiang_hua} -> ?REPLY_MSG_EQUIP_QIANG_HUA_2;          %% 达到最大强化等级
%%            {error, cost_not_enough} -> ?REPLY_MSG_EQUIP_QIANG_HUA_3;        %% 金钱不足
%%            {error, cant_qiang_hua} -> ?REPLY_MSG_EQUIP_QIANG_HUA_4;         %% 装备不可强化
%%            _ -> ?REPLY_MSG_EQUIP_QIANG_HUA_255                             %% 强化失败，请重试。重试失败请联系GM
%%        end,
%%    if
%%        ReplyNum =:= ?REPLY_MSG_EQUIP_QIANG_HUA_OK ->
%%            achievement_mng:do_ac(?qianghuadaren);
%%        true ->
%%            achievement_mng:do_ac(?qianghuayizhi)
%%    end,
%%%%    notice_system:send_qianghua_level(BucketType, GoodsID, ReplyNum),
%%    ?player_send(equip_sproto:pkg_msg(?MSG_EQUIP_QIANG_HUA, {ReplyNum}));

%% 装备合成功能已经取消
%% 合成(宝石必须全部拿下才可，切宝石槽位会在三个装备中随机。随机jd属性其他的不管。基础属性为主装备。
%%handle_client(?MSG_EQUIP_HE_CHENG, {Type, BucketType, GoodsID, ItemId1, ItemId2, LockAttrList}) ->
%%%%    ?INFO_LOG("Type = ~p, LockAttrList = ~p", [Type, LockAttrList]),
%%    attr_new:begin_sync_attr(),
%%    Ret = equip_system:try_he_cheng(Type, BucketType, GoodsID, ItemId1, ItemId2, LockAttrList),
%%    attr_new:end_sync_attr(),
%%    achievement_mng:do_ac(?hechenggaoshou),
%%    ReplyNum =
%%        case Ret of
%%            ok ->
%%                bounty_mng:do_bounty_task(?BOUNTY_TASK_HECHENG_EQUIP, 1),
%%                daily_task_tgr:do_daily_task({?ev_equ_he_cheng, 0}, 1),
%%                event_eng:post(?ev_equ_he_cheng,{?ev_equ_he_cheng, 0},1),
%%                api:send_color_equip_count(),
%%                api:send_he_cheng_equip_count(),
%%                ?REPLY_MSG_EQUIP_HE_CHENG_OK;                             %% ok
%%            {error, cost_not_enough} -> ?REPLY_MSG_EQUIP_HE_CHENG_1;         %% 合成装备金钱不足
%%            {error, he_cheng_check_error} -> ?REPLY_MSG_EQUIP_HE_CHENG_2;    %% 非法操作，合成失败
%%            {error, cant_he_cheng} -> ?REPLY_MSG_EQUIP_HE_CHENG_3;           %% 装备不可合成
%%            {error, lock_attr_more} -> ?REPLY_MSG_EQUIP_HE_CHENG_4;         %% 合成时锁定的属性条数超过玩家最大允许条数
%%            _ -> ?REPLY_MSG_EQUIP_HE_CHENG_255                              %% 合成失败，请重试。重试失败请联系GM
%%        end,
%%    ?player_send(equip_sproto:pkg_msg(?MSG_EQUIP_HE_CHENG, {ReplyNum}));
%%
%%
%%%% 继承
%%handle_client(?MSG_EQUIP_JI_CHENG, {BucketType1, GoodsID, BucketType2, ItemId}) ->
%%    attr_new:begin_sync_attr(),
%%    Ret = equip_system:try_ji_cheng(BucketType1, GoodsID, BucketType2, ItemId),
%%    attr_new:end_sync_attr(),
%%    ReplyNum =
%%        case Ret of
%%            ok ->
%%                bounty_mng:do_bounty_task(?BOUNTY_TASK_JICHENG_EQUIP, 1),
%%                daily_task_tgr:do_daily_task({?ev_equ_ji_cheng, 0}, 1),
%%                event_eng:post(?ev_equ_ji_cheng,{?ev_equ_ji_cheng, 0}, 1),
%%                phase_achievement_mng:do_pc(?PHASE_AC_EQUIP_JICHENG, 1),
%%                ?REPLY_MSG_EQUIP_JI_CHENG_OK;                                     %% ok
%%            {error, bucket_full} -> ?REPLY_MSG_EQUIP_JI_CHENG_1;                     %% 继承装备失败，背包已满
%%            {error, diamond_not_enough} -> ?REPLY_MSG_EQUIP_JI_CHENG_2;              %% 继承装备失败，钻石不足
%%            {error, cost_not_enough} -> ?REPLY_MSG_EQUIP_JI_CHENG_3;                 %% 继承装备失败，金钱不足
%%            {error, ji_cheng_need_bigger_qh_lev} -> ?REPLY_MSG_EQUIP_JI_CHENG_4;     %% 继承装备失败，只能继承强化等级更高的装备哦
%%            {error, ji_cheng_need_same_type} -> ?REPLY_MSG_EQUIP_JI_CHENG_5;         %% 装备继承失败，装备不可继承
%%            _ -> ?REPLY_MSG_EQUIP_JI_CHENG_255                                      %% 继承装备失败，请重试。重试失败，请联系GM
%%        end,
%%    ?player_send(equip_sproto:pkg_msg(?MSG_EQUIP_JI_CHENG, {ReplyNum}));

%% 打孔
handle_client(?MSG_EQUIP_SLOT, {BucketType, GoodsId, SlotNum, CostItemBid}) ->
    attr_new:begin_sync_attr(),
    Ret = equip_system:equip_slot(BucketType, GoodsId, SlotNum, CostItemBid),
    attr_new:end_sync_attr(),
    ReplyNum =
        case Ret of
            ok ->
                bounty_mng:do_bounty_task(?BOUNTY_TASK_DAKONG_EQUIP, 1),
                ?REPLY_MSG_EQUIP_SLOT_OK;
            {error,punch_type_error} -> ?REPLY_MSG_EQUIP_SLOT_PUNCH_TYPE_ERR;
            {error, cant_slot} -> ?REPLY_MSG_EQUIP_CANT_SLOT;
            {error, max_slot} -> ?REPLY_MSG_EQUIP_MAX_SLOT;
            {error, cost_not_enough} -> ?REPLY_MSG_EQUIP_COST_NOT_ENOUGH;
            {error, slot_0} -> ?REPLY_MSG_EQUIP_SLOT_LITTLE_1;
            _ -> ?REPLY_MSG_EQUIP_SLOT_255
        end,
    ?player_send(equip_sproto:pkg_msg(?MSG_EQUIP_SLOT, {ReplyNum}));


%% 单件装备分解
handle_client(?MSG_EQUIP_EXCHANGE, {ItemId}) ->
%%    ?INFO_LOG("zhuangbei tilian ------------- itemId:~p", [ItemId]),
    {Ret, ItemList} = equip_system:equip_exchange(ItemId),
    achievement_mng:do_ac2(?chaijieshengshou, 0, 1),
    NewItemList = item_goods:merge_goods(ItemList),
    ReplyNum =
        case Ret of
            ok ->
                ?REPLY_MSG_EQUIP_EXCHANGE_OK;
            {error, equip_can_not_exchange} -> ?REPLY_MSG_EQUIP_EXCHANGE_1;
            {error, bag_not_enough} -> ?REPLY_MSG_EQUIP_EXCHANGE_2;
            {error, cost_not_enough} -> ?REPLY_MSG_EQUIP_EXCHANGE_3;
            _ -> ?REPLY_MSG_EQUIP_EXCHANGE_255
        end,
%%    ?INFO_LOG("zhuangbei tilian return-------------ItemList:~p", [ItemList]),
%%    ?INFO_LOG("zhuangbei tilian return-------------ReplyNum:~p", [ReplyNum]),
    ?player_send(equip_sproto:pkg_msg(?MSG_EQUIP_EXCHANGE, {NewItemList, ReplyNum}));

%% 装备一键分解
handle_client(?MSG_EQUIP_ONE_KEY_EXCHANGE, {QuaList}) ->
    QuaList1 = [X || {X} <- QuaList],
    achievement_mng:do_ac2(?chaijieshengshou, 0, length(QuaList1)),
%%    ?INFO_LOG("zhuangbei onekey tilian ------------- itemId:~p", [QuaList1]),
    {Ret, ItemList} = equip_system:equip_one_key_exchange(QuaList1),
    NewItemList = item_goods:merge_goods(ItemList),
    ReplyNum =
        case Ret of
            ok -> ?REPLY_MSG_ONE_KEY_EQUIP_EXCHANGE_OK;
            {error, no_list} -> ?REPLY_MSG_ONE_KEY_EQUIP_EXCHANGE_1;
            {error, bag_not_enough} -> ?REPLY_MSG_ONE_KEY_EQUIP_EXCHANGE_2;
            {error, cost_not_enough} -> ?REPLY_MSG_ONE_KEY_EQUIP_EXCHANGE_3;
            _ -> ?REPLY_MSG_ONE_KEY_EQUIP_EXCHANGE_255
        end,
%%    ?INFO_LOG("zhuangbei onekey tilian return-------------ItemList:~p", [ItemList]),
%%    ?INFO_LOG("zhuangbei onekey tilian return-------------ReplyNum:~p", [ReplyNum]),
    ?player_send(equip_sproto:pkg_msg(?MSG_EQUIP_ONE_KEY_EXCHANGE, {NewItemList, ReplyNum}));


%% 装备附魔{附魔id, 背包类型， 被附魔装备id, 附魔类型}
handle_client(?MSG_EQUIP_IMBUE_WEAPON, {FumoId, BucketType, ItemId, FumoType, ServerFumoId}) ->
%%    ?INFO_LOG("FumoId = ~p, BucketType = ~p, ItemId = ~p, FumoType = ~p", [FumoId, BucketType, ItemId, FumoType]),
    attr_new:begin_sync_attr(),
    Ret = equip_system:equip_fumo(FumoId, BucketType, ItemId, FumoType, ServerFumoId),
    attr_new:end_sync_attr(),
    achievement_mng:do_ac(?fumozhuanjia),
    ReplyNum =
        case Ret of
            ok ->
                bounty_mng:do_bounty_task(?BOUNTY_TASK_FUMO_EQUIP, 1),
                ?REPLY_MSG_EQUIP_IMBUE_WEAPON_OK;
            {error, not_find_fumo_mode} -> ?REPLY_MSG_EQUIP_IMBUE_WEAPON_1;
            {error, fumo_not_activate} -> ?REPLY_MSG_EQUIP_IMBUE_WEAPON_2;
            {error, equip_already_fumo} -> ?REPLY_MSG_EQUIP_IMBUE_WEAPON_3;
            {error, type_error} -> ?REPLY_MSG_EQUIP_IMBUE_WEAPON_4;
            {error, cost_not_enough} -> ?REPLY_MSG_EQUIP_IMBUE_WEAPON_5;
            {error, not_jd} -> ?REPLY_MSG_EQUIP_IMBUE_WEAPON_6;
            _ -> ?REPLY_MSG_EQUIP_IMBUE_WEAPON_255
        end,
%%    ?INFO_LOG("ReplyNum = ~p", [ReplyNum]),
    ?player_send(equip_sproto:pkg_msg(?MSG_EQUIP_IMBUE_WEAPON, {ReplyNum}));

%% 装备萃取
handle_client(?MSG_EQUIP_CUI_QU, {BucketType, ItemId}) ->
%%    ?INFO_LOG("BucketType = ~p, ItemId = ~p", [BucketType, ItemId]),
    attr_new:begin_sync_attr(),
    Ret = equip_system:equip_cuiqu(BucketType, ItemId),
    attr_new:end_sync_attr(),
    achievement_mng:do_ac(?cuiqudashi),

    ReplyNum =
        case Ret of
            ok ->
                bounty_mng:do_bounty_task(?BOUNTY_TASK_CUIQU_EQUIP, 1),
                ?REPLY_MSG_EQUIP_CUI_QU_OK;
            {error, cost_not_enough} -> ?REPLY_MSG_EQUIP_CUI_QU_1;
            {error, not_fumo} -> ?REPLY_MSG_EQUIP_CUI_QU_2;
            {error, have_gem} -> ?REPLY_MSG_EQUIP_CUI_QU_3;
            _ -> ?REPLY_MSG_EQUIP_CUI_QU_255
        end,
%%    ?INFO_LOG("ReplyNum = ~p", [ReplyNum]),
    ?player_send(equip_sproto:pkg_msg(?MSG_EQUIP_CUI_QU, {ReplyNum}));

%% 激活附魔公式
handle_client(?MSG_EQUIP_ACTIVATE_FUMO_MODE, {FumoModeId}) ->
%%    ?INFO_LOG("FumoModeId = ~p", [FumoModeId]),
    % attr_new:begin_sync_attr(),
    % Ret = equip_system:activate_fumo_state(FumoModeId),
    % attr_new:end_sync_attr(),
    % ReplyNum =
    %     case Ret of
    %         ok ->
    %             %% 激活成功时同步附魔公式数据
    %             equip_system:sync_fumo_mode_list(),
    %             ?REPLY_MSG_EQUIP_FUMO_STATE_ACTIVATE_OK;
    %         {error, cost_not_enough} -> ?REPLY_MSG_EQUIP_FUMO_STATE_ACTIVATE_1;
    %         {error, already_use} -> ?REPLY_MSG_EQUIP_FUMO_STATE_ACTIVATE_2;
    %         _ ->?REPLY_MSG_EQUIP_FUMO_STATE_ACTIVATE_255
    %     end,
%%    ?INFO_LOG("FumoModeId = ~p, ReplyNum = ~p", [FumoModeId, ReplyNum]),
    ?player_send(equip_sproto:pkg_msg(?MSG_EQUIP_ACTIVATE_FUMO_MODE, {2}));   %% 去掉这个-由军

%% 装备史诗孔位打孔
handle_client(?MSG_EQUIP_EPIC_SLOT, {BucketType, GoodsId, CostItemBid}) ->
    attr_new:begin_sync_attr(),
    Ret = equip_system:equip_epic_slot(BucketType, GoodsId, CostItemBid),
    attr_new:end_sync_attr(),
    ReplyNum =
        case Ret of
            ok -> ?REPLY_MSG_EQUIP_SLOT_OK;
            {error,punch_type_error} -> ?REPLY_MSG_EQUIP_SLOT_PUNCH_TYPE_ERR;
            {error, cant_slot} -> ?REPLY_MSG_EQUIP_CANT_SLOT;
            {error, cost_not_enough} -> ?REPLY_MSG_EQUIP_COST_NOT_ENOUGH;
            {error, slot_0} -> ?REPLY_MSG_EQUIP_SLOT_LITTLE_1;
            _ -> ?REPLY_MSG_EQUIP_SLOT_255
        end,
    ?player_send(equip_sproto:pkg_msg(?MSG_EQUIP_EPIC_SLOT, {ReplyNum}));

%% 镶嵌史诗宝石
handle_client(?MSG_EQUIP_EPIC_EMBED_GEM, {BucketType, GoodsId, GemId}) ->
    attr_new:begin_sync_attr(),
    Ret = equip_system:try_embed_epic_gem(BucketType, GoodsId, GemId),
    attr_new:end_sync_attr(),
    ReplyNum =
        case Ret of
            ok ->
                case api:gem_num_full() of
                    ?TRUE ->
                        achievement_mng:do_ac(?yishenshenzhuang);
                    _ ->
                        pass
                end,
                bounty_mng:do_bounty_task(?BOUNTY_TASK_XIANGQIAN_EQUIP, 1),
                daily_task_tgr:do_daily_task({?ev_equ_xiangqian, 0}, 1),
                event_eng:post(?ev_equ_xiangqian, {?ev_equ_xiangqian, 0}, 1),
                ?REPLY_MSG_EQUIP_EMBED_GEM_OK;                            %% ok
            {error, diamond_not_enough} -> ?REPLY_MSG_EQUIP_EMBED_GEM_1;     %% 镶嵌宝石失败，钻石不足
            {error, cost_not_enough} -> ?REPLY_MSG_EQUIP_EMBED_GEM_3;        %% 镶嵌宝石失败，金钱不足
            {error, has_same_type_gem} -> ?REPLY_MSG_EQUIP_EMBED_GEM_4;      %% 镶嵌宝石失败,不能镶嵌同类型宝石
            {error, gem_post_not_enough} -> ?REPLY_MSG_EQUIP_EMBED_GEM_2;    %% 镶嵌宝石失败，宝石孔位不足
            _ -> ?REPLY_MSG_EQUIP_EMBED_GEM_255                             %% 镶嵌宝石失败，请重试。重试失败，请联系GM
        end,
    ?player_send(equip_sproto:pkg_msg(?MSG_EQUIP_EPIC_EMBED_GEM, {ReplyNum}));

%% 摘除史诗宝石
handle_client(?MSG_EQUIP_EPIC_UNEMBED_GEM, {BucketType, GoodsId}) ->
    attr_new:begin_sync_attr(),
    Ret = equip_system:try_unembed_epic_gem(BucketType, GoodsId),
    attr_new:end_sync_attr(),
    ReplyNum =
        case Ret of
            ok -> ?REPLY_MSG_EQUIP_UNEMBED_GEM_OK;
            {error, full_bucket} -> ?REPLY_MSG_EQUIP_UNEMBED_GEM_1;
            {error, no_gem} -> ?REPLY_MSG_EQUIP_UNEMBED_GEM_2;
            {error, no_epic_solt} -> ?REPLY_MSG_EQUIP_UNEMBED_GEM_3;
            _ -> ?REPLY_MSG_EQUIP_UNEMBED_GEM_255
        end,
    ?player_send(equip_sproto:pkg_msg(?MSG_EQUIP_EPIC_UNEMBED_GEM, {ReplyNum}));

%% 强化部位
handle_client(?MSG_PART_QIANGHUA, {Type, UsCount}) ->
%%    ?INFO_LOG("Type = ~p, UseCount = ~p", [Type, UsCount]),
    attr_new:begin_sync_attr(),
    {Ret, ReType, ReLevel} = equip_system:part_qiang_hua(Type, UsCount),
    attr_new:end_sync_attr(),
    achievement_mng:do_ac(?qianghuazhixing),

    event_eng:post(?ev_equ_qiang_hua, {?ev_equ_qiang_hua, 0}, 1),
    daily_task_tgr:do_daily_task({?ev_equ_qiang_hua, 0}, 1),
    ReplyNum =
        case Ret of
            ok ->
                phase_achievement_mng:do_pc(?PHASE_AC_EQUIP_QIANGHUA, 10, api:get_equip_qhlvl_count()), 
                open_server_happy_mng:sync_task(?QIANGHUA_PART_LEVEL, ReLevel),
                ?REPLY_MSG_EQUIP_PART_QIANG_HUA_OK;
            {error, qh_failed} -> ?REPLY_MSG_EQUIP_PART_QIANG_HUA_1;
            {error, cost_not_enough} -> ?REPLY_MSG_EQUIP_PART_QIANG_HUA_2;
            {error, max_level} -> ?REPLY_MSG_EQUIP_PART_QIANG_HUA_3;
            {error, not_find_type} -> ?REPLY_MSG_EQUIP_PART_QIANG_HUA_4;
            {error, not_find_cfg} -> ?REPLY_MSG_EQUIP_PART_QIANG_HUA_5;
            _ -> ?REPLY_MSG_EQUIP_PART_QIANG_HUA_255
        end,
    if
        ReplyNum =:= ?REPLY_MSG_EQUIP_PART_QIANG_HUA_OK ->
            achievement_mng:do_ac(?qianghuadaren);
        true ->
            achievement_mng:do_ac(?qianghuayizhi)
    end,
    ?player_send(equip_sproto:pkg_msg(?MSG_PART_QIANGHUA, {ReplyNum, ReType, ReLevel}));




%% 装备洗炼
handle_client(?MSG_EQUIP_XILIAN, {ItemId, BucketType, LockAttrList}) ->
%%    ?INFO_LOG("ItemId: ~p, BucketType:~p, LockAttrList:~p", [ItemId, BucketType, LockAttrList]),
    attr_new:begin_sync_attr(),
    Ret = equip_system:equip_xilian(ItemId, BucketType, LockAttrList),
    attr_new:end_sync_attr(),
    achievement_mng:do_ac(?hechenggaoshou),
    daily_task_tgr:do_daily_task({?ev_equ_he_cheng, 0}, 1),
    event_eng:post(?ev_equ_he_cheng,{?ev_equ_he_cheng, 0},1),
    ReplyNum =
        case Ret of
            ok ->
                open_server_happy_mng:sync_task(?XILIAN_EQUIP, 1),
                ?REPLY_MSG_EQUIP_XILIAN_OK;
            {error, cant_xilian} -> ?REPLY_MSG_EQUIP_XILIAN_1;
            {error, cost_not_enough} -> ?REPLY_MSG_EQUIP_XILIAN_2;
            _ -> ?REPLY_MSG_EQUIP_XILIAN_255
        end,
%%    ?INFO_LOG("xilian replyNum:~p", [ReplyNum]),
    ?player_send(equip_sproto:pkg_msg(?MSG_EQUIP_XILIAN, {ReplyNum}));


handle_client(_Mod, _Msg) -> ok.

%% -----------------------------------------------------------
%% 创建数据表把装备和物品的信息保存在这里的数据表中
load_db_table_meta() ->
    [
        #db_table_meta
        {
            name = ?player_equip_goods_tab,
            fields = ?record_fields(?player_equip_goods_tab),
            shrink_size = 1,
            flush_interval = 3
        }
    ].

load_mod_data(PlayerId) ->
    case dbcache:load_data(?player_equip_goods_tab, PlayerId) of
        [] ->
            ?INFO_LOG("player ~p not find player_equip_goods_tab mode ~p", [PlayerId, ?MODULE]),
            create_mod_data(PlayerId),
            load_mod_data(PlayerId);
        [#player_equip_goods_tab{equip_bucket = EquipBucket, goods_bucket = GoodsBucket,
            depot_bucket = DepotBucket, qianghu_list = QHList}] ->
            ?pd_new(?pd_equip_bucket, EquipBucket),
            ?pd_new(?pd_goods_bucket, GoodsBucket),
            ?pd_new(?pd_depot_bucket, DepotBucket),
            ?pd_new(?pd_part_qiang_hua_list, QHList)
    end,
    ok.

init_client() ->
    ok.

online() -> ok.

view_data(Acc) -> Acc.

offline(PlayerId) ->
    save_data(PlayerId),
    ok.

save_data(PlayerId) ->
    EquipGoodsTable =
        #player_equip_goods_tab
        {
            id = PlayerId,
            equip_bucket = get(?pd_equip_bucket),
            goods_bucket = get(?pd_goods_bucket),
            depot_bucket = get(?pd_depot_bucket),
            qianghu_list = get(?pd_part_qiang_hua_list)
        },
    dbcache:update(?player_equip_goods_tab, EquipGoodsTable),
    ok.

handle_frame(_) -> todo.

handle_msg(_FromMod, _Msg) ->
    {error, unknown_msg}.

create_mod_data(PlayerId) ->
    EquipGoodsTable =
        #player_equip_goods_tab
        {
            id = PlayerId,
            equip_bucket = time_bucket:new_bucket(attr_new:create_uid(), ?pd_equip_bucket, ?pd_equip_bucket_temp, ?BUCKET_TYPE_EQM, 10),
            goods_bucket = time_bucket:new_bucket(attr_new:create_uid(), ?pd_goods_bucket, ?pd_goods_bucket_temp, ?BUCKET_TYPE_BAG, 16),
            depot_bucket = time_bucket:new_bucket(attr_new:create_uid(), ?pd_depot_bucket, ?pd_depot_bucket_temp, ?BUCKET_TYPE_DEPOT, 16),
            qianghu_list = [{Type - 100, 0} || Type <- ?all_equips_type]
        },
    case dbcache:insert_new(?player_equip_goods_tab, EquipGoodsTable) of
        ?true ->
            ok;
        ?false ->
            ?ERROR_LOG("player ~p create new player_equip_goods_table error mode ~p", [PlayerId, ?MODULE])
    end,
    ok.






