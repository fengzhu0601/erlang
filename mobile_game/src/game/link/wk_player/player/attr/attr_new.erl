%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 11. 七月 2015 下午3:28
%%%-------------------------------------------------------------------
-module(attr_new).


-export
([
    init/2
    , uninit/1
    , get/1
    , get/2
    , set/2
    , player_add_attr/1
    , player_sub_attr/1
    , player_add_attr_by_id/1
    , player_sub_attr_by_id/1
    , get_combat_power/1
    , get_vip_lvl/0
    , set_sink_state/2
    , get_sink_state/1
    , get_oldversion_attr/0
    , get_oldversion_attr/3
    , get_attr_item/1
    , begin_sync_attr/0
    , end_sync_attr/0
    , end_sync_attr/1
    , check_uid/1
    , create_uid/0
    , amend/1
    , list_2_attr/1
    , get_attr_by_id/1
    , show/0
    , show_attr/1
    , update_player_attr/0
    , begin_room_prize/1
    , end_room_prize/1
    , get_room_prize/0
    , is_room_prize/0
    , set_exp/1
    , player_add_attr_pre/1
    , player_sub_attr_pre/1
    , get_attr_item_pre/1
    , up_equip_prop_l2/1
    , get_oldversion_equip_attr/1
    , get_online_time_this/0
    , get_online_time_onday/0
    , list_2_attr_pre/2
    , get_all_attr_by_lv1_attr/1
    , get_sub_attr/2
]).





-include("inc.hrl").
-include("player.hrl").
-include("player_data_db.hrl").
-include_lib("common/include/com_log.hrl").
-include("load_spirit_attr.hrl").
-include("item_bucket.hrl").
-include("achievement.hrl").
-include("vip_new.hrl").


-define(MAX_LIMIT, 99999999).
-define(MAX_BIND_DIAMOND, 20000000).
-define(MAX_DIAMOND, 20000000).
-define(MAX_POWER, 1000).
-define(MIN_TIMESTAMP, 1437120247). %{{2015,7,17},{16,4,32}}
-define(MAX_TIMESTAMP, 4595328000). %{{2115, 8, 16}, {0,0,0}}
-define(MAX_UID, 131071).
-define(MAX_PD_ID, 32767).
-define(pd_attr_sync_in_attr_new, pd_attr_sync_in_attr_new).        %%控制同步的变量

%% 8 == (cfg_start_key_hp - attr_start_key_hp) == (11 - 3)
-define(cfg_attr_key_dt, 8).

%% 获取字段值
get(Key) -> erlang:get(Key).
get(Key, DefaultVal) ->
    case get_attr_item(Key) of
        undefined -> DefaultVal;
        Val -> Val
    end.


%% 设置字段值
set_exp(Val) ->
    player:add_value(?pd_exp, Val).



set(Key, Val) ->
    %?DEBUG_LOG("set Key Val--------------------------:~p",[Key]),
    OldData = attr_new:get(Key, 0),
    %NewData = do_set(Key, Val),  %% 先获得老数据，再加上新的数据
    case do_set(Key, Val) of
        false ->
            OldData;
        NewData ->
            %% 二级属性刷新（有可能引起递归改值问题）
            on_data_change(Key, OldData, NewData),
            up_prop_l2(),
            %% 同步客户端
            CurData = attr_new:get(Key),
            on_sync_data(Key, OldData, CurData),
            if
                CurData =/= OldData andalso Key =:= ?pd_vip -> 
                    player_mods_manager:vip_level_up(OldData);
                true -> 
                    ok
            end,
            CurData
    end.


%% 初始化值
init_fields(?pd_sinks_state) -> <<0:?sinks_state_len>>;
init_fields(?pd_dial_prize) -> login_prize_part:init_zhuan_pan_prize();
init_fields(?pd_last_reflash_tm) -> {2000, 1, 1};
init_fields(?pd_login_prize) -> login_prize_part:init_sign_prize();
init_fields(?pd_card_vip_give_tm) -> com_time:now();
init_fields(?pd_card_vip_end_tm) -> com_time:now();
init_fields(?pd_pay_orders) -> #pay_orders{};
init_fields(?pd_society_bufs) -> [];
init_fields(?pd_temp_field_list) -> [];
init_fields(?pd_attr_titles) -> [];
init_fields(?pd_temp_res_list) -> [];
init_fields(?pd_run_evts_tree) -> gb_trees:empty();
init_fields(?pd_vote_evts_tree) -> gb_trees:empty();
init_fields(?pd_task_progress_list) -> [];
init_fields(?pd_task_list) -> [];
init_fields(?pd_daily_task_list) -> [];
init_fields(?pd_daily_task_list_event_data) -> [];
init_fields(?pd_daily_event_to_task_list) -> [];
init_fields(?pd_daily_task_prize_list) -> load_richang_task:get_daily_baoxiang_prize();
init_fields(?pd_task_daily_free_flush_times) -> 0;
init_fields(?pd_task_daily_pay_flush_times) -> 0;
init_fields(?pd_task_daily_task_times) -> 0;
init_fields(?pd_task_is_open) -> task_system:get_newbie_guide_task_is_open();
init_fields(?pd_treasure_map_list) -> [];
init_fields(?pd_attr_dig_list) -> [];
init_fields(?pd_daily_task_collect_dig_list) -> [];
init_fields(?pd_main_instance_relive_times) -> main_ins_util:init_relive_times();
init_fields(?pd_main_ins_jinxing) -> 0;
init_fields(?pd_main_ins_yinxing) -> 0;
init_fields(?pd_system_item_id) -> 0;
init_fields(?pd_crown_yuansu_moli) -> 0;
init_fields(?pd_crown_guangan_moli) -> 0;
init_fields(?pd_crown_mingyun_moli) -> 0;
init_fields(?pd_task_bless_buff) -> [];
init_fields(?pd_task_mount_time) -> {0, 0};
init_fields(?pd_guild_mining_leave_time) -> guild_mining_mng:get_free_count();
%%init_fields(?pd_equip_bucket) ->
%%    time_bucket:new_bucket(create_uid(), ?pd_equip_bucket, ?pd_equip_bucket_temp, ?BUCKET_TYPE_EQM, 10);
%%init_fields(?pd_goods_bucket) ->
%%    time_bucket:new_bucket(create_uid(), ?pd_goods_bucket, ?pd_goods_bucket_temp, ?BUCKET_TYPE_BAG, 16);
%%init_fields(?pd_depot_bucket) ->
%%    time_bucket:new_bucket(create_uid(), ?pd_depot_bucket, ?pd_depot_bucket_temp, ?BUCKET_TYPE_DEPOT, 16);
init_fields(?pd_fight_attr_pre) ->
    #attr{};
init_fields(?pd_fight_attr_2lvl) ->
    #attr{};
init_fields(?pd_clean_room_list) -> [];
init_fields(?pd_bounty_task_free_refresh_count) -> 0;
init_fields(?pd_bounty_task_pay_refresh_count) -> 0;
init_fields(?pd_bounty_refresh_remain) -> 0;
init_fields(_Key) ->
    0.


%% 临时链表
do_set(?pd_temp_field_list, Val) ->
    attr_algorithm:lists_no_limit_set(?pd_temp_field_list, Val);                    %%  临时链表
do_set(?pd_task_progress_list, Val) ->
    attr_algorithm:lists_no_limit_set(?pd_task_progress_list, Val);                 %%  临时链表
do_set(?pd_task_list, Val) -> attr_algorithm:lists_no_limit_set(?pd_task_list, Val);                          %%  临时链表
do_set(?pd_temp_res_list, Val) ->
    attr_algorithm:lists_no_limit_set(?pd_temp_res_list, Val);                      %%  称号链表
do_set(?pd_attr_titles, Val) -> attr_algorithm:lists_no_limit_set(?pd_attr_titles, Val);                        %%  称号链表
do_set(?pd_treasure_map_list, Val) ->
    attr_algorithm:lists_no_limit_set(?pd_treasure_map_list, Val);                  %%  临时链表
do_set(?pd_attr_dig_list, Val) ->
    attr_algorithm:lists_no_limit_set(?pd_attr_dig_list, Val);                      %%  临时链表

%% 字段数据
do_set(?pd_longwens, Val) -> attr_algorithm:integer_limit_add(?pd_longwens, Val, 0, ?MAX_LIMIT);                %%  金币
do_set(?pd_long_wen, Val) -> attr_algorithm:integer_limit_add(?pd_long_wen, Val, 0, ?MAX_LIMIT);                %%  金币
do_set(?pd_money, Val) -> attr_algorithm:integer_limit_add(?pd_money, Val, 0, ?MAX_LIMIT);                %%  金币
do_set(?pd_diamond, Val) -> attr_algorithm:integer_limit_add(?pd_diamond, Val, 0, ?MAX_LIMIT);              %%  钻石
do_set(?pd_exp, _Val) ->
%%     ?INFO_LOG("do_set pd_exp"),
    ?assert(false); %%  历史问题 经验由set_exp(Val)处理
do_set(?pd_fragment, Val) -> attr_algorithm:integer_limit_add(?pd_fragment, Val, 0, ?MAX_LIMIT);             %%
do_set(?pd_hp, Val) -> attr_algorithm:integer_limit_add(?pd_hp, Val, 0, ?MAX_LIMIT);                   %%
do_set(?pd_honour, Val) -> attr_algorithm:integer_limit_add(?pd_honour, Val, 0, ?MAX_LIMIT);               %%
do_set(?pd_main_ins_jinxing, Val) -> attr_algorithm:integer_limit_add(?pd_main_ins_jinxing, Val, 0, ?MAX_LIMIT);
do_set(?pd_main_ins_yinxing, Val) -> attr_algorithm:integer_limit_add(?pd_main_ins_yinxing, Val, 0, ?MAX_LIMIT);
do_set(?pd_pearl, Val) -> attr_algorithm:integer_limit_add(?pd_pearl, Val, 0, ?MAX_LIMIT);                %%
do_set(?pd_mp, Val) -> attr_algorithm:integer_limit_add(?pd_mp, Val, 0, ?MAX_LIMIT);                   %%
do_set(?pd_sp, Val) -> attr_algorithm:integer_limit_add(?pd_sp, Val, 0, ?MAX_LIMIT);                   %%
do_set(?pd_sp_buy_count, Val) -> attr_algorithm:integer_limit_add(?pd_sp_buy_count, Val, 0, ?MAX_LIMIT);         %%
do_set(?pd_level, Val) ->
    MaxLvL = min(Val, misc_cfg:get_max_lev()),
    erlang:put(?pd_level, MaxLvL);


%% 字段数据
do_set(?pd_system_item_id, Val) ->
    attr_algorithm:integer_limit_set(?pd_system_item_id, Val, 0, ?MAX_LIMIT);       %%  当前称号
do_set(?pd_attr_cur_title, Val) ->
    attr_algorithm:integer_limit_set(?pd_attr_cur_title, Val, 0, ?MAX_LIMIT);       %%  当前称号

%% 战斗属性
do_set(?pd_attr_max_hp, Val) ->
    attr_algorithm:integer_limit_add(?pd_attr_max_hp, Val, 0, ?MAX_LIMIT);          %%  max_hp
do_set(?pd_attr_hp, Val) -> attr_algorithm:integer_limit_add_ex(?pd_attr_hp, Val, 0, ?pd_attr_max_hp);      %%  hp
do_set(?pd_attr_max_mp, Val) ->
    attr_algorithm:integer_limit_add(?pd_attr_max_mp, Val, 0, ?MAX_LIMIT);          %%  max_mp
do_set(?pd_attr_mp, Val) -> attr_algorithm:integer_limit_add_ex(?pd_attr_mp, Val, 0, ?pd_attr_max_mp);      %%  mp
do_set(?pd_attr_max_sp, Val) ->
    attr_algorithm:integer_limit_add(?pd_attr_max_sp, Val, 0, ?MAX_LIMIT);          %%  max_体力
do_set(?pd_attr_sp, Val) -> attr_algorithm:integer_limit_add_ex(?pd_attr_sp, Val, 0, ?pd_attr_max_sp);      %%  体力
do_set(?pd_attr_max_np, Val) ->
    attr_algorithm:integer_limit_add(?pd_attr_max_np, Val, 0, ?MAX_LIMIT);          %%  max_能量
do_set(?pd_attr_np, Val) -> attr_algorithm:integer_limit_add_ex(?pd_attr_np, Val, 0, ?pd_attr_max_np);      %%  能量
do_set(?pd_attr_strength, Val) -> attr_algorithm:integer_limit_add(?pd_attr_strength, Val, 0, ?MAX_LIMIT);        %%  力量
do_set(?pd_attr_intellect, Val) ->
    attr_algorithm:integer_limit_add(?pd_attr_intellect, Val, 0, ?MAX_LIMIT);       %%  智力
do_set(?pd_attr_nimble, Val) -> attr_algorithm:integer_limit_add(?pd_attr_nimble, Val, 0, ?MAX_LIMIT);          %%  敏捷
do_set(?pd_attr_strong, Val) -> attr_algorithm:integer_limit_add(?pd_attr_strong, Val, 0, ?MAX_LIMIT);          %%  体质
do_set(?pd_attr_atk, Val) -> attr_algorithm:integer_limit_add(?pd_attr_atk, Val, 0, ?MAX_LIMIT);             %%  攻击
do_set(?pd_attr_def, Val) -> attr_algorithm:integer_limit_add(?pd_attr_def, Val, 0, ?MAX_LIMIT);             %%  防御
do_set(?pd_attr_crit, Val) -> attr_algorithm:integer_limit_add(?pd_attr_crit, Val, 0, ?MAX_LIMIT);            %%  暴击等级
do_set(?pd_attr_crit_multi, Val) ->
    attr_algorithm:integer_limit_add(?pd_attr_crit_multi, Val, 0, ?MAX_LIMIT);      %%  暴击被率
do_set(?pd_attr_block, Val) -> attr_algorithm:integer_limit_add(?pd_attr_block, Val, 0, ?MAX_LIMIT);           %%  格挡
do_set(?pd_attr_pliable, Val) -> attr_algorithm:integer_limit_add(?pd_attr_pliable, Val, 0, ?MAX_LIMIT);         %%  柔韧
do_set(?pd_attr_pure_atk, Val) ->
    attr_algorithm:integer_limit_add(?pd_attr_pure_atk, Val, 0, ?MAX_LIMIT);        %%  无视防御伤害
do_set(?pd_attr_break_def, Val) ->
    attr_algorithm:integer_limit_add(?pd_attr_break_def, Val, 0, ?MAX_LIMIT);       %%  破甲
do_set(?pd_attr_atk_deep, Val) ->
    attr_algorithm:integer_limit_add(?pd_attr_atk_deep, Val, 0, ?MAX_LIMIT);        %%  伤害加深
do_set(?pd_attr_atk_free, Val) ->
    attr_algorithm:integer_limit_add(?pd_attr_atk_free, Val, 0, ?MAX_LIMIT);        %%  伤害减免
do_set(?pd_attr_atk_speed, Val) ->
    attr_algorithm:integer_limit_add(?pd_attr_atk_speed, Val, 0, ?MAX_LIMIT);       %%  攻击速度
do_set(?pd_attr_precise, Val) -> attr_algorithm:integer_limit_add(?pd_attr_precise, Val, 0, ?MAX_LIMIT);         %%  精确
do_set(?pd_attr_thunder_atk, Val) ->
    attr_algorithm:integer_limit_add(?pd_attr_thunder_atk, Val, 0, ?MAX_LIMIT);     %%  雷攻
do_set(?pd_attr_thunder_def, Val) ->
    attr_algorithm:integer_limit_add(?pd_attr_thunder_def, Val, 0, ?MAX_LIMIT);     %%  雷防
do_set(?pd_attr_fire_atk, Val) -> attr_algorithm:integer_limit_add(?pd_attr_fire_atk, Val, 0, ?MAX_LIMIT);        %%  火攻
do_set(?pd_attr_fire_def, Val) -> attr_algorithm:integer_limit_add(?pd_attr_fire_def, Val, 0, ?MAX_LIMIT);        %%  火防
do_set(?pd_attr_ice_atk, Val) -> attr_algorithm:integer_limit_add(?pd_attr_ice_atk, Val, 0, ?MAX_LIMIT);         %%  冰攻
do_set(?pd_attr_ice_def, Val) -> attr_algorithm:integer_limit_add(?pd_attr_ice_def, Val, 0, ?MAX_LIMIT);         %%  冰防
do_set(?pd_attr_move_speed, Val) ->
    attr_algorithm:integer_limit_add(?pd_attr_move_speed, Val, 0, ?MAX_LIMIT);      %%  移动速度
do_set(?pd_attr_run_speed, Val) ->
    attr_algorithm:integer_limit_add(?pd_attr_run_speed, Val, 0, ?MAX_LIMIT);       %%  跑步速度
do_set(?pd_attr_suck_blood, Val) ->
    attr_algorithm:integer_limit_add(?pd_attr_suck_blood, Val, 0, ?MAX_LIMIT);      %%  吸血
do_set(?pd_attr_reverse, Val) -> attr_algorithm:integer_limit_add(?pd_attr_reverse, Val, 0, ?MAX_LIMIT);       %%  反伤
do_set(?pd_attr_add_hp_times, Val) ->
    attr_algorithm:integer_limit_set(?pd_attr_add_hp_times, Val, 0, ?MAX_LIMIT);    %%  加血次数
do_set(?pd_attr_add_hp_mp_cd, Val) ->
    attr_algorithm:integer_limit_set(?pd_attr_add_hp_mp_cd, Val, ?MIN_TIMESTAMP, ?MAX_TIMESTAMP);%%  上次加血时间
do_set(?pd_attr_relive_times, Val) ->
    attr_algorithm:integer_limit_set(?pd_attr_relive_times, Val, 0, ?MAX_LIMIT);    %%  复活次数
do_set(?pd_arena_attr_id, Val) ->
    erlang:put(?pd_arena_attr_id, Val);    %%  竞技段位
% do_set(?pd_attr_bati, Val) -> attr_algorithm:integer_limit_add(?pd_attr_bati, Val, 0, ?MAX_LIMIT);       %%  霸体

do_set(?pd_crown_yuansu_moli, Val) -> attr_algorithm:integer_limit_add(?pd_crown_yuansu_moli, Val, 0, ?MAX_LIMIT);
do_set(?pd_crown_guangan_moli, Val) -> attr_algorithm:integer_limit_add(?pd_crown_guangan_moli, Val, 0, ?MAX_LIMIT);
do_set(?pd_crown_mingyun_moli, Val) -> attr_algorithm:integer_limit_add(?pd_crown_mingyun_moli, Val, 0, ?MAX_LIMIT);


%% other
do_set(Other, Val) -> erlang:put(Other, Val).                                                         %%  other


%% 同步客户端
begin_sync_attr() ->
    case attr_new:get(?pd_attr_sync_in_attr_new, 0) of
        0 ->
            erlang:put(?pd_attr_sync_in_attr_new, 1),
            put(?pd_temp_field_state, 1),
            put(?pd_temp_field_list_ex, []),
            put(?pd_temp_field_list, []);
        Ret ->
            erlang:put(?pd_attr_sync_in_attr_new, Ret + 1)
    end.


%% %%% 结束客户端
%% send_field(Key, Val) ->
%%     ?INFO_LOG("send_field ~p", [{Key, Val}]).
%% %%?player_send(player_sproto:pkg_msg(?MSG_PLAYER_DATA_CHANGED, {Key, Val})).
%% %%     Attr = get_oldversion_attr(),
%% %%     ?player_send(player_sproto:pkg_msg(?MSG_PLAYER_ATTR_CHANGE, {?r2t(Attr)})),
%% %%     FieldList = attr_new:get(?pd_temp_field_list, []),
%% %%     [send_field(Key, Val) || {Key, Val} <- FieldList],
end_sync_attr() ->
    end_sync_attr(false).

end_sync_attr(Force) ->
    Ret = erlang:get(?pd_attr_sync_in_attr_new),
    case Ret of
        1 ->
            erlang:put(?pd_attr_sync_in_attr_new, 0),
            FieldListEx = attr_new:get(?pd_temp_field_list_ex, []),
            Root = player_prop_zip_key:get_zip_keys_data_ex(#zip_keys_data{}, FieldListEx),
            Data = player_prop_zip_key:get_final_ret(Root),
            case erlang:get(?pd_init_completed) of
                1 ->
                    %?DEBUG_LOG("Data---------------------------:~p",[Data]),
                    ?player_send(player_sproto:pkg_msg(?MSG_PLAYER_FIELD_CHANGE, Data));
                _ ->
                    ?ifdo(Force =:= true, ?player_send(player_sproto:pkg_msg(?MSG_PLAYER_FIELD_CHANGE, Data))),
                    ok
            end,
            case erlang:get(?pd_temp_field_state) of
                2 ->
                    update_player_attr();
                _ ->
                    ok
            end;
        Count ->
            erlang:put(?pd_attr_sync_in_attr_new, Count - 1)
    end.


%% 同步数据压栈
push_sync_list(Key, Val) ->
    if
        Key >= ?pd_fight_begin andalso Key =< ?pd_fight_end andalso Key =/= ?pd_fight_attr_2lvl andalso Key =/= ?pd_fight_attr_pre ->
            erlang:put(?pd_temp_field_state, 2);
        true ->
            NewList = util:lists_set_ex(attr_new:get(?pd_temp_field_list, []), Key, Val),
            put(?pd_temp_field_list, NewList)
    end.

push_sync_list_ex(Key, _Val) ->
    if
        Key >= ?pd_fight_begin andalso Key =< ?pd_fight_end andalso Key =/= ?pd_fight_attr_2lvl andalso Key =/= ?pd_fight_attr_pre ->
            erlang:put(?pd_temp_field_state, 2); %% 当属性有变动的时候，把属性控制变量设置成可同步
        true -> %% 当是资产类的数据有变动是，先将变动的存在临时变量里面，最后一起同步
            NewList = util:lists_set_ex(attr_new:get(?pd_temp_field_list_ex, []), Key, _Val),
            put(?pd_temp_field_list_ex, NewList)
    end.


%% 同步玩家字段数据
on_sync_data(Key, _OldData, NewData) ->
%%     ?INFO_LOG("on_sync_data ~p", [{Key, NewData}]),
    if
        Key >= ?pd_fight_begin andalso Key =< ?pd_fight_end ->
            push_sync_list_ex(Key, NewData),
            push_sync_list(Key, NewData);
        Key >= ?pd_attr_public_begin andalso Key =< ?pd_attr_public_end ->
            push_sync_list_ex(Key, NewData),
            push_sync_list(Key, NewData);
        ?pd_money == Key ->
            push_sync_list_ex(Key, NewData),
            push_sync_list(?PL_MONEY, NewData);
        ?pd_diamond == Key ->
            push_sync_list_ex(Key, NewData),
            push_sync_list(?PL_DIAMOND, NewData);
        ?pd_fragment == Key ->
            push_sync_list_ex(Key, NewData),
            push_sync_list(?PL_FRAGMENT, NewData);
        ?pd_level == Key ->
            push_sync_list_ex(Key, NewData),
            push_sync_list(?PL_LEVEL, NewData);
        ?pd_exp == Key ->
            push_sync_list_ex(Key, NewData),
            push_sync_list(?PL_EXP, NewData);
        ?pd_hp == Key ->
            push_sync_list_ex(Key, NewData),
            push_sync_list(?PL_HP, NewData);
        ?pd_longwens == Key ->
            push_sync_list_ex(Key, NewData),
            push_sync_list(?PL_LONGWENS, NewData);
        ?pd_honour == Key ->
            push_sync_list_ex(Key, NewData),
            push_sync_list(?PL_HONOUR, NewData);
        ?pd_pearl == Key ->
            push_sync_list_ex(Key, NewData),
            push_sync_list(?PL_PEARL, NewData);
        ?pd_long_wen == Key ->
            push_sync_list_ex(Key, NewData),
            push_sync_list(?PL_LONG_WEN, NewData);
        ?pd_combat_power == Key ->
            push_sync_list_ex(Key, NewData),
            push_sync_list(?PL_COMBAT_POWER, NewData);
        ?pd_mp == Key ->
            push_sync_list_ex(Key, NewData),
            push_sync_list(?PL_MP, NewData);
        ?pd_sp == Key ->
            push_sync_list_ex(Key, NewData),
            push_sync_list(?PL_SP, NewData);
        ?pd_sp_buy_count == Key ->
            push_sync_list_ex(Key, NewData),
            push_sync_list(?PL_SP_COUNT, NewData);

        ?pd_main_ins_jinxing == Key ->
            push_sync_list_ex(Key, NewData),
            push_sync_list(?PL_JINXING, NewData);

        ?pd_main_ins_yinxing == Key ->
            push_sync_list_ex(Key, NewData),
            push_sync_list(?PL_YINXING, NewData);

        ?pd_crown_yuansu_moli == Key ->
            push_sync_list_ex(Key, NewData),
            push_sync_list(Key, NewData);

        ?pd_crown_guangan_moli == Key ->
            push_sync_list_ex(Key, NewData),
            push_sync_list(Key, NewData);

        ?pd_crown_mingyun_moli == Key ->
            push_sync_list_ex(Key, NewData),
            push_sync_list(Key, NewData);


        true ->
            ok
    end.


%% 二级属性刷新
up_prop_l2 () ->
    ListSrc = [?pd_attr_strength, ?pd_attr_intellect, ?pd_attr_nimble, ?pd_attr_strong],
    AttrL2 =
    lists:foldl(fun(Key, Acc) ->
        Val =
        case erlang:get(Key) of
            undefined ->
                get_old_version_attr_item(Key);
            Val0 ->
                get_old_version_attr_item(Key) + Val0
        end,
        %?DEBUG_LOG("Key-----:~p--------Val------:~p",[Key, Val]),
        case Key of
            %% 力量
            ?pd_attr_strength ->
                Old = Acc#attr.atk,
                Acc1 = Acc#attr{atk = (Old + Val * 2)},
                Old1 = Acc1#attr.hp,
                Acc2 = Acc1#attr{hp = (Old1 + Val * 10)},
                Acc2;

            %% 智力
            ?pd_attr_intellect ->
                Old = Acc#attr.mp,
                Acc1 = Acc#attr{mp = (util:floor(Old + Val*0.1))},
                Acc1;

            %% 敏捷
            ?pd_attr_nimble ->
                Old = Acc#attr.crit,
                Acc1 = Acc#attr{crit = (Old + Val * 2)},
                Old1 = Acc1#attr.atk,
                Acc2 = Acc1#attr{atk = (Old1 + Val * 1)},
                Acc2;

            %% 体质
            ?pd_attr_strong ->
                Old = Acc#attr.hp,
                Acc1 = Acc#attr{hp = (Old + Val * 20)},
                Old1 = Acc1#attr.def,
                Acc2 = Acc1#attr{def = (Old1 + Val * 1)},
                Acc2;

            _ ->
                0
        end
    end,
    #attr{},
    ListSrc),
    %?DEBUG_LOG("pd_fight_attr_2lvl Key --------------------:~p",[{AttrL2}]),
    erlang:put(?pd_fight_attr_2lvl, AttrL2),
    ok.

%%装备二级属性刷新
up_equip_prop_l2(Attr) ->
    ListSrc = [?pd_attr_strength, ?pd_attr_intellect, ?pd_attr_nimble, ?pd_attr_strong],
    AttrL2 =
        lists:foldl
        (
            fun
                (Key, Acc) ->
                    Val = base_get_attr_item(Key, Attr),
                    case Key of
                        %% 力量
                        ?pd_attr_strength ->
                            Old = Acc#attr.atk,
                            Acc1 = Acc#attr{atk = (Old + Val * 2)},
                            Old1 = Acc1#attr.hp,
                            Acc2 = Acc1#attr{hp = (Old1 + Val * 10)},
                            Acc2;

                        %% 智力
                        ?pd_attr_intellect ->
                            Old = Acc#attr.mp,
                            Acc1 = Acc#attr{mp = (util:floor(Old + Val * 0.1))},
                            Acc1;

                        %% 敏捷
                        ?pd_attr_nimble ->
                            Old = Acc#attr.crit,
                            Acc1 = Acc#attr{crit = (Old + Val * 2)},
                            Old1 = Acc1#attr.atk,
                            Acc2 = Acc1#attr{atk = (Old1 + Val * 1)},
                            Acc2;

                        %% 体质
                        ?pd_attr_strong ->
                            Old = Acc#attr.hp,
                            Acc1 = Acc#attr{hp = (Old + Val * 20)},
                            Old1 = Acc1#attr.def,
                            Acc2 = Acc1#attr{def = (Old1 + Val * 1)},
                            Acc2;

                        _ ->
                            0
                    end
            end,
            #attr{},
            ListSrc
        ),
    erlang:put(?pd_equip_attr_2lvl, AttrL2),
    ok.

get_all_attr_by_lv1_attr(Attr) ->
    ListSrc = [{attr_strength, Attr#attr.strength}, {attr_intellect, Attr#attr.intellect}, {attr_nimble, Attr#attr.nimble}, {attr_strong, Attr#attr.strong}],
    lists:foldl(
        fun({Key, Val}, Acc) ->
                case Key of
                    attr_strength ->
                        Atk = Acc#attr.atk,
                        AccNew = Acc#attr{atk = Atk + Val * 2},
                        Hp = AccNew#attr.hp,
                        AccNew#attr{hp = Hp + Val * 10};
                    attr_intellect ->
                        Mp = Acc#attr.mp,
                        Acc#attr{mp = util:floor(Mp + Val * 0.1)};
                    attr_nimble ->
                        Crit = Acc#attr.crit,
                        AccNew = Acc#attr{crit = Crit + Val * 2},
                        Atk = AccNew#attr.atk,
                        AccNew#attr{atk = Atk + Val * 1};
                    attr_strong ->
                        Hp = Acc#attr.hp,
                        AccNew = Acc#attr{hp = Hp + Val * 20},
                        Def = AccNew#attr.def,
                        AccNew#attr{def = Def + Val * 1};
                    _ ->
                        Acc
                end
        end,
        Attr,
        ListSrc
    ).

on_data_change(Key, OldData, NewData) ->
    case Key of
        %%  升级日志
        ?pd_level ->
            DtData = NewData - OldData,
            system_log:info_role_levelup(DtData);

%%         ?pd_main_ins_jinxing ->
%%             ?INFO_LOG("pd_main_ins_jinxing ~p", [{OldData, NewData}]);
%%
%%         ?pd_main_ins_yinxing ->
%%             ?INFO_LOG("pd_main_ins_yinxing ~p", [{OldData, NewData}]);

        %%  充值日志
        % ?pd_diamond ->
        %     if
        %         NewData > OldData ->
        %             system_log:info_diamond_log(NewData, OldData);
        %         true ->
        %             system_log:info_pay_log()
        %     end;

        %% 竞技属性
%%         ?pd_arena_attr_id ->
%%             if
%%                 OldData =/= 0 ->
%%                     player_sub_attr_by_id(OldData);
%%                 true ->
%%                     ok
%%             end,
%%             if
%%                 NewData =/= 0 ->
%%                     player_add_attr_by_id(NewData);
%%                 true ->
%%                     ok
%%             end;

        _ ->
            ok
    end.


init(_PlayerId, FieldData) ->
    %?ERROR_LOG("attr_new init ~w ~w", [_PlayerId, FieldData]),
    init_all_fields(?pd_field_begin, ?pd_field_end),
    init_all_fields(?pd_attr_private_begin, ?pd_attr_private_end),
    init_all_fields(?pd_fight_begin, ?pd_fight_end),
    init_all_fields(?pd_temp_field_list, ?pd_temp_field_list),
    init_all_fields(?pd_temp_res_list, ?pd_temp_res_list),
    init_all_fields(?pd_vote_evts_tree, ?pd_run_evts_tree),
    [load_field(Key, Val) || {Key, Val} <- FieldData].

%% 玩家下线属性保存，但不会保存战斗属性
uninit(_PlayerId) ->
    ListField = get_fields_list(?pd_field_begin, ?pd_field_end),
    ListPrivate = get_fields_list(?pd_attr_private_begin, ?pd_attr_private_end),
    ListPublic = get_fields_list(?pd_attr_public_begin, ?pd_attr_public_end),
    ListField ++ ListPrivate ++ ListPublic.


player_add_attr_by_id(CfgId) ->
    case load_spirit_attr:lookup_attr(CfgId) of
        ?none ->
            ?err(none_cfg);
        Attr ->
            set_attr(1, Attr)
    end.
player_sub_attr_by_id(CfgId) ->
    case load_spirit_attr:lookup_attr(CfgId) of
        ?none ->
            ?err(none_cfg);
        Attr ->
            set_attr(-1, Attr)
    end.
get_attr_by_id(CfgId) ->
    case load_spirit_attr:lookup_attr(CfgId) of
        ?none -> ?err(none_cfg);
        Attr -> Attr
    end.


player_add_attr(Attr) ->
    set_attr(1, Attr).
player_sub_attr(Attr) ->
    set_attr(-1, Attr).
set_attr(Inter, Attr) ->
    %%Attr已经包含计算过的二级属性，当设置一级属性时，二级属性已经被加进去了
%%     ?INFO_LOG("set_attr ~p",[{Inter, Attr}]),
    attr_new:set(?pd_attr_max_hp, Inter * Attr#attr.hp),
    attr_new:set(?pd_attr_max_mp, Inter * Attr#attr.mp),
    attr_new:set(?pd_attr_max_sp, Inter * Attr#attr.sp),
    attr_new:set(?pd_attr_max_np, Inter * Attr#attr.np),
    attr_new:set(?pd_attr_strength, Inter * Attr#attr.strength),
    attr_new:set(?pd_attr_intellect, Inter * Attr#attr.intellect),
    attr_new:set(?pd_attr_nimble, Inter * Attr#attr.nimble),
    attr_new:set(?pd_attr_strong, Inter * Attr#attr.strong),
    attr_new:set(?pd_attr_atk, Inter * Attr#attr.atk),
    attr_new:set(?pd_attr_def, Inter * Attr#attr.def),
    attr_new:set(?pd_attr_crit, Inter * Attr#attr.crit),
    attr_new:set(?pd_attr_block, Inter * Attr#attr.block),
    attr_new:set(?pd_attr_pliable, Inter * Attr#attr.pliable),
    attr_new:set(?pd_attr_pure_atk, Inter * Attr#attr.pure_atk),
    attr_new:set(?pd_attr_break_def, Inter * Attr#attr.break_def),
    attr_new:set(?pd_attr_atk_deep, Inter * Attr#attr.atk_deep),
    attr_new:set(?pd_attr_atk_free, Inter * Attr#attr.atk_free),
    attr_new:set(?pd_attr_atk_speed, Inter * Attr#attr.atk_speed),
    attr_new:set(?pd_attr_precise, Inter * Attr#attr.precise),
    attr_new:set(?pd_attr_thunder_atk, Inter * Attr#attr.thunder_atk),
    attr_new:set(?pd_attr_thunder_def, Inter * Attr#attr.thunder_def),
    attr_new:set(?pd_attr_fire_atk, Inter * Attr#attr.fire_atk),
    attr_new:set(?pd_attr_fire_def, Inter * Attr#attr.fire_def),
    attr_new:set(?pd_attr_ice_atk, Inter * Attr#attr.ice_atk),
    attr_new:set(?pd_attr_ice_def, Inter * Attr#attr.ice_def),
    attr_new:set(?pd_attr_move_speed, Inter * Attr#attr.move_speed),
    attr_new:set(?pd_attr_run_speed, Inter * Attr#attr.run_speed),
    attr_new:set(?pd_attr_suck_blood, Inter * Attr#attr.suck_blood),
    attr_new:set(?pd_attr_reverse, Inter * Attr#attr.reverse),
    % attr_new:set(?pd_attr_bati, Inter * Attr#attr.bati),
    case erlang:get(?pd_temp_field_state) of
        1 ->
            erlang:put(?pd_temp_field_state, 2);
        _ ->
            update_player_attr()
    end,
    ok.

%% 增加属性百分比（例如攻击力加成 20%）
player_add_attr_pre(FieldList) ->
    AttrPre = attr_new:get(?pd_fight_attr_pre, #attr{}),
    SumAttr =
    lists:foldl(fun
        ({CfgKey, Val}, Acc) ->
            AttrKey = CfgKey - ?cfg_attr_key_dt,
            OldVal = element(AttrKey, Acc),
            setelement(AttrKey, Acc, (OldVal + Val))
    end,
    AttrPre,
    FieldList),
    attr_new:set(?pd_fight_attr_pre, SumAttr),
    case erlang:get(?pd_temp_field_state) of
        1 ->
            erlang:put(?pd_temp_field_state, 2);
        _ ->
            update_player_attr()
    end,
    ok.

%% 减少属性百分比（例如攻击力减少 20%）
player_sub_attr_pre(FieldList) ->
    AttrPre = attr_new:get(?pd_fight_attr_pre, #attr{}),
    SumAttr =
        lists:foldl
        (
            fun
                ({CfgKey, Val}, Acc) ->
                    AttrKey = CfgKey - ?cfg_attr_key_dt,
                    OldVal = element(AttrKey, Acc),
                    setelement(AttrKey, Acc, (OldVal - Val))
            end,
            AttrPre,
            FieldList
        ),
%%     ?INFO_LOG("AttrPre ~p", [SumAttr]),
    attr_new:set(?pd_fight_attr_pre, SumAttr),
    case erlang:get(?pd_temp_field_state) of
        1 ->
            erlang:put(?pd_temp_field_state, 2);
        _ ->
            update_player_attr()
    end,
    ok.


get_attr_item_pre(Key) ->
    AttrPre = erlang:get(?pd_fight_attr_pre),
    case AttrPre of
        undefined -> 0;
        _ -> base_get_attr_item(Key, AttrPre)
    end.

get_old_version_attr_item(Key) ->
    Attr = erlang:get(?pd_attr),
    case Attr of
        undefined -> 
            %?ERROR_LOG("attr is error-----------------------------"),
            0;
        _ -> 
            base_get_attr_item(Key, Attr)
    end.

get_attr_l2_item(Key) ->
    AttrL2 = erlang:get(?pd_fight_attr_2lvl),
    case AttrL2 of
        undefined -> 
            0;
        _ -> 
            base_get_attr_item(Key, AttrL2)
    end.


base_get_attr_item(Key, Attr) ->
    case Key of
        ?pd_attr_max_hp -> Attr#attr.hp;
        ?pd_attr_max_mp -> Attr#attr.mp;
        ?pd_attr_max_sp -> Attr#attr.sp;
        ?pd_attr_max_np -> Attr#attr.np;
        ?pd_attr_strength -> Attr#attr.strength;
        ?pd_attr_intellect -> Attr#attr.intellect;
        ?pd_attr_nimble -> Attr#attr.nimble;
        ?pd_attr_strong -> Attr#attr.strong;
        ?pd_attr_atk -> Attr#attr.atk;
        ?pd_attr_def -> Attr#attr.def;
        ?pd_attr_crit -> Attr#attr.crit;
        ?pd_attr_block -> Attr#attr.block;
        ?pd_attr_pliable -> Attr#attr.pliable;
        ?pd_attr_pure_atk -> Attr#attr.pure_atk;
        ?pd_attr_break_def -> Attr#attr.break_def;
        ?pd_attr_atk_deep -> Attr#attr.atk_deep;
        ?pd_attr_atk_free -> Attr#attr.atk_free;
        ?pd_attr_atk_speed -> Attr#attr.atk_speed;
        ?pd_attr_precise -> Attr#attr.precise;
        ?pd_attr_thunder_atk -> Attr#attr.thunder_atk;
        ?pd_attr_thunder_def -> Attr#attr.thunder_def;
        ?pd_attr_fire_atk -> Attr#attr.fire_atk;
        ?pd_attr_fire_def -> Attr#attr.fire_def;
        ?pd_attr_ice_atk -> Attr#attr.ice_atk;
        ?pd_attr_ice_def -> Attr#attr.ice_def;
        ?pd_attr_move_speed -> Attr#attr.move_speed;
        ?pd_attr_run_speed -> Attr#attr.run_speed;
        ?pd_attr_suck_blood -> Attr#attr.suck_blood;
        ?pd_attr_reverse -> Attr#attr.reverse;
        ?pd_attr_bati -> Attr#attr.bati;
        _ -> 0
    end.

get_attr_item(Key) ->
    if
        Key >= ?pd_fight_begin andalso Key =< ?pd_fight_end andalso Key =/= ?pd_fight_attr_2lvl andalso Key =/= ?pd_fight_attr_pre ->
            compute_attr_val(get_old_version_attr_item(Key), erlang:get(Key), get_attr_l2_item(Key), get_attr_item_pre(Key));
        true ->
            erlang:get(Key)
    end.



compute_attr_val(AttrItemVal, PropVal, L2Val, Pre) ->
    Val = round
    (
        (attr_algorithm:get(AttrItemVal, 0) + attr_algorithm:get(PropVal, 0) + attr_algorithm:get(L2Val, 0))
            * get_prop_pre(attr_algorithm:get(Pre, 0))
    ),
    Val.

get_prop_pre(Val) ->
    Val1 = erlang:max(0, 1 + Val / 1000),
    Val1.

%% 进渡版本用，后面转换工程后去掉
get_oldversion_attr() ->
    up_prop_l2(),
    %% 为了兼容老版本
    %% attr是老版本的属性，字段是新版本的属性， attrpre是属性加成, AttrL2是2级属性
    Attr = attr_algorithm:get(erlang:get(?pd_attr), #attr{}),
    AttrPre = attr_algorithm:get(erlang:get(?pd_fight_attr_pre), #attr{}),
    AttrL2 = attr_algorithm:get(erlang:get(?pd_fight_attr_2lvl), #attr{}),
    get_oldversion_attr(Attr, AttrPre, AttrL2).

get_oldversion_attr(Attr, AttrPre, AttrL2) ->
    AttrRet = #attr
    {
        hp = compute_attr_val(Attr#attr.hp, attr_new:get(?pd_attr_max_hp), AttrL2#attr.hp, AttrPre#attr.hp), %%  max_hp
        mp = compute_attr_val(Attr#attr.mp, attr_new:get(?pd_attr_max_mp), AttrL2#attr.mp, AttrPre#attr.mp), %%  max_mp
        sp = compute_attr_val(Attr#attr.sp, attr_new:get(?pd_attr_max_sp), AttrL2#attr.sp, AttrPre#attr.sp), %%  max_体力
        np = compute_attr_val(Attr#attr.np, attr_new:get(?pd_attr_max_np), AttrL2#attr.np, AttrPre#attr.np), %%  max_能量
        strength = compute_attr_val(Attr#attr.strength, attr_new:get(?pd_attr_strength), AttrL2#attr.strength, AttrPre#attr.strength), %%  力量
        intellect = compute_attr_val(Attr#attr.intellect, attr_new:get(?pd_attr_intellect), AttrL2#attr.intellect, AttrPre#attr.intellect), %%  智力
        nimble = compute_attr_val(Attr#attr.nimble, attr_new:get(?pd_attr_nimble), AttrL2#attr.nimble, AttrPre#attr.nimble), %%  敏捷
        strong = compute_attr_val(Attr#attr.strong, attr_new:get(?pd_attr_strong), AttrL2#attr.strong, AttrPre#attr.strong), %%  体质
        atk = compute_attr_val(Attr#attr.atk, attr_new:get(?pd_attr_atk), AttrL2#attr.atk, AttrPre#attr.atk), %%  攻击
        def = compute_attr_val(Attr#attr.def, attr_new:get(?pd_attr_def), AttrL2#attr.def, AttrPre#attr.def), %%  防御
        crit = compute_attr_val(Attr#attr.crit, attr_new:get(?pd_attr_crit), AttrL2#attr.crit, AttrPre#attr.crit), %%  暴击等级
        block = compute_attr_val(Attr#attr.block, attr_new:get(?pd_attr_block), AttrL2#attr.block, AttrPre#attr.block), %%  格挡
        pliable = compute_attr_val(Attr#attr.pliable, attr_new:get(?pd_attr_pliable), AttrL2#attr.pliable, AttrPre#attr.pliable), %%  柔韧
        pure_atk = compute_attr_val(Attr#attr.pure_atk, attr_new:get(?pd_attr_pure_atk), AttrL2#attr.pure_atk, AttrPre#attr.pure_atk), %%  无视防御伤害
        break_def = compute_attr_val(Attr#attr.break_def, attr_new:get(?pd_attr_break_def), AttrL2#attr.break_def, AttrPre#attr.break_def), %%  破甲
        atk_deep = compute_attr_val(Attr#attr.atk_deep, attr_new:get(?pd_attr_atk_deep), AttrL2#attr.atk_deep, AttrPre#attr.atk_deep), %%  伤害加深
        atk_free = compute_attr_val(Attr#attr.atk_free, attr_new:get(?pd_attr_atk_free), AttrL2#attr.atk_free, AttrPre#attr.atk_free), %%  伤害减免
        atk_speed = compute_attr_val(Attr#attr.atk_speed, attr_new:get(?pd_attr_atk_speed), AttrL2#attr.atk_speed, AttrPre#attr.atk_speed), %%  攻击速度
        precise = compute_attr_val(Attr#attr.precise, attr_new:get(?pd_attr_precise), AttrL2#attr.precise, AttrPre#attr.precise), %%  精确
        thunder_atk = compute_attr_val(Attr#attr.thunder_atk, attr_new:get(?pd_attr_thunder_atk), AttrL2#attr.thunder_atk, AttrPre#attr.thunder_atk), %%  雷攻
        thunder_def = compute_attr_val(Attr#attr.thunder_def, attr_new:get(?pd_attr_thunder_def), AttrL2#attr.thunder_def, AttrPre#attr.thunder_def), %%  雷防
        fire_atk = compute_attr_val(Attr#attr.fire_atk, attr_new:get(?pd_attr_fire_atk), AttrL2#attr.fire_atk, AttrPre#attr.fire_atk), %%  火攻
        fire_def = compute_attr_val(Attr#attr.fire_def, attr_new:get(?pd_attr_fire_def), AttrL2#attr.fire_def, AttrPre#attr.fire_def), %%  火防
        ice_atk = compute_attr_val(Attr#attr.ice_atk, attr_new:get(?pd_attr_ice_atk), AttrL2#attr.ice_atk, AttrPre#attr.ice_atk), %%  冰攻
        ice_def = compute_attr_val(Attr#attr.ice_def, attr_new:get(?pd_attr_ice_def), AttrL2#attr.ice_def, AttrPre#attr.ice_def), %%  移动速度
        move_speed = compute_attr_val(Attr#attr.move_speed, attr_new:get(?pd_attr_move_speed), AttrL2#attr.move_speed, AttrPre#attr.move_speed), %%  跑步速度
        run_speed = compute_attr_val(Attr#attr.run_speed, attr_new:get(?pd_attr_run_speed), AttrL2#attr.run_speed, AttrPre#attr.run_speed), %%
        suck_blood = compute_attr_val(Attr#attr.suck_blood, attr_new:get(?pd_attr_suck_blood), AttrL2#attr.suck_blood, AttrPre#attr.suck_blood), %%
        reverse = compute_attr_val(Attr#attr.reverse, attr_new:get(?pd_attr_reverse), AttrL2#attr.reverse, AttrPre#attr.reverse)
        % bati = compute_attr_val(Attr#attr.bati, attr_new:get(?pd_attr_bati), AttrL2#attr.bati, AttrPre#attr.bati)%%
    },
    erlang:put(?pd_combat_power, get_combat_power(AttrRet)),
    %?DEBUG_LOG("AttrRet--------------------------:~p",[AttrRet]),
    AttrRet.

get_oldversion_equip_attr(Attr) ->
    %%Attr = item_equip:get_cur_equip_attr(Item),
%%     show_attr(Attr),
    up_equip_prop_l2(Attr),
    %% attr是老版本的属性，字段是新版本的属性， attrpre是属性加成, AttrL2是2级属性
    %%Attr = attr_algorithm:get( erlang:get(?pd_attr), #attr{}),
    AttrPre = #attr{},
    AttrL2 = attr_algorithm:get(erlang:get(?pd_equip_attr_2lvl), #attr{}),
%%     ?INFO_LOG("get_oldversion_attr ~p",[{Attr, AttrPre, AttrL2}]),
    AttrRet = #attr
    {
        hp = compute_attr_val(Attr#attr.hp, 0, AttrL2#attr.hp, AttrPre#attr.hp), %%  max_hp
        mp = compute_attr_val(Attr#attr.mp, 0, AttrL2#attr.mp, AttrPre#attr.mp), %%  max_mp
        sp = compute_attr_val(Attr#attr.sp, 0, AttrL2#attr.sp, AttrPre#attr.sp), %%  max_体力
        np = compute_attr_val(Attr#attr.np, 0, AttrL2#attr.np, AttrPre#attr.np), %%  max_能量
        strength = compute_attr_val(Attr#attr.strength, 0, AttrL2#attr.strength, AttrPre#attr.strength), %%  力量
        intellect = compute_attr_val(Attr#attr.intellect, 0, AttrL2#attr.intellect, AttrPre#attr.intellect), %%  智力
        nimble = compute_attr_val(Attr#attr.nimble, 0, AttrL2#attr.nimble, AttrPre#attr.nimble), %%  敏捷
        strong = compute_attr_val(Attr#attr.strong, 0, AttrL2#attr.strong, AttrPre#attr.strong), %%  体质
        atk = compute_attr_val(Attr#attr.atk, 0, AttrL2#attr.atk, AttrPre#attr.atk), %%  攻击
        def = compute_attr_val(Attr#attr.def, 0, AttrL2#attr.def, AttrPre#attr.def), %%  防御
        crit = compute_attr_val(Attr#attr.crit, 0, AttrL2#attr.crit, AttrPre#attr.crit), %%  暴击等级
        block = compute_attr_val(Attr#attr.block, 0, AttrL2#attr.block, AttrPre#attr.block), %%  格挡
        pliable = compute_attr_val(Attr#attr.pliable, 0, AttrL2#attr.pliable, AttrPre#attr.pliable), %%  柔韧
        pure_atk = compute_attr_val(Attr#attr.pure_atk, 0, AttrL2#attr.pure_atk, AttrPre#attr.pure_atk), %%  无视防御伤害
        break_def = compute_attr_val(Attr#attr.break_def, 0, AttrL2#attr.break_def, AttrPre#attr.break_def), %%  破甲
        atk_deep = compute_attr_val(Attr#attr.atk_deep, 0, AttrL2#attr.atk_deep, AttrPre#attr.atk_deep), %%  伤害加深
        atk_free = compute_attr_val(Attr#attr.atk_free, 0, AttrL2#attr.atk_free, AttrPre#attr.atk_free), %%  伤害减免
        atk_speed = compute_attr_val(Attr#attr.atk_speed, 0, AttrL2#attr.atk_speed, AttrPre#attr.atk_speed), %%  攻击速度
        precise = compute_attr_val(Attr#attr.precise, 0, AttrL2#attr.precise, AttrPre#attr.precise), %%  精确
        thunder_atk = compute_attr_val(Attr#attr.thunder_atk, 0, AttrL2#attr.thunder_atk, AttrPre#attr.thunder_atk), %%  雷攻
        thunder_def = compute_attr_val(Attr#attr.thunder_def, 0, AttrL2#attr.thunder_def, AttrPre#attr.thunder_def), %%  雷防
        fire_atk = compute_attr_val(Attr#attr.fire_atk, 0, AttrL2#attr.fire_atk, AttrPre#attr.fire_atk), %%  火攻
        fire_def = compute_attr_val(Attr#attr.fire_def, 0, AttrL2#attr.fire_def, AttrPre#attr.fire_def), %%  火防
        ice_atk = compute_attr_val(Attr#attr.ice_atk, 0, AttrL2#attr.ice_atk, AttrPre#attr.ice_atk), %%  冰攻
        ice_def = compute_attr_val(Attr#attr.ice_def, 0, AttrL2#attr.ice_def, AttrPre#attr.ice_def), %%  移动速度
        move_speed = compute_attr_val(Attr#attr.move_speed, 0, AttrL2#attr.move_speed, AttrPre#attr.move_speed), %%  跑步速度
        run_speed = compute_attr_val(Attr#attr.run_speed, 0, AttrL2#attr.run_speed, AttrPre#attr.run_speed), %%
        suck_blood = compute_attr_val(Attr#attr.suck_blood, 0, AttrL2#attr.suck_blood, AttrPre#attr.suck_blood), %%
        reverse = compute_attr_val(Attr#attr.reverse, 0, AttrL2#attr.reverse, AttrPre#attr.reverse)
        % bati = compute_attr_val(Attr#attr.bati, 0, AttrL2#attr.bati, AttrPre#attr.bati)
    },
    AttrRet.


update_player_attr() ->
    Attr = get_oldversion_attr(),
    Val = get_combat_power(Attr),
    achievement_mng:do_ac2(?zuiqiangzhanli, 0, Val),

%%     ?INFO_LOG("update_player_attr ~p",[Attr]),
    %%  刷新镜像数据
%%  player_base_data:update_equip_global_image(get(?pd_id)),
%%  player_base_data:update_attr_global_image(get(?pd_id)),
    attr_new:set(?pd_combat_power, Val),
    scene_mng:send_msg({?msg_update_attr, erlang:get(?pd_idx), Attr}),
    case erlang:get(?pd_init_completed) of
        1 ->
            ?player_send(player_sproto:pkg_msg(?MSG_PLAYER_ATTR_CHANGE, {?r2t(Attr)}));
        _ ->
            ok
    end.




show() ->
    Attr = get_oldversion_attr(),
    show_attr(Attr).

show_attr(Attr) ->
    ?INFO_LOG("pd_attr_max_hp,       ~p", [Attr#attr.hp]),
    ?INFO_LOG("pd_attr_max_mp,       ~p", [Attr#attr.mp]),
    ?INFO_LOG("pd_attr_max_sp,       ~p", [Attr#attr.sp]),
    ?INFO_LOG("pd_attr_max_np,       ~p", [Attr#attr.np]),
    ?INFO_LOG("pd_attr_strength,     ~p", [Attr#attr.strength]),
    ?INFO_LOG("pd_attr_intellect,    ~p", [Attr#attr.intellect]),
    ?INFO_LOG("pd_attr_nimble,       ~p", [Attr#attr.nimble]),
    ?INFO_LOG("pd_attr_strong,       ~p", [Attr#attr.strong]),
    ?INFO_LOG("pd_attr_atk,          ~p", [Attr#attr.atk]),
    ?INFO_LOG("pd_attr_def,          ~p", [Attr#attr.def]),
    ?INFO_LOG("pd_attr_crit,         ~p", [Attr#attr.crit]),
    ?INFO_LOG("pd_attr_block,        ~p", [Attr#attr.block]),
    ?INFO_LOG("pd_attr_pliable,      ~p", [Attr#attr.pliable]),
    ?INFO_LOG("pd_attr_pure_atk,     ~p", [Attr#attr.pure_atk]),
    ?INFO_LOG("pd_attr_break_def,    ~p", [Attr#attr.break_def]),
    ?INFO_LOG("pd_attr_atk_deep,     ~p", [Attr#attr.atk_deep]),
    ?INFO_LOG("pd_attr_atk_free,     ~p", [Attr#attr.atk_free]),
    ?INFO_LOG("pd_attr_atk_speed,    ~p", [Attr#attr.atk_speed]),
    ?INFO_LOG("pd_attr_precise,      ~p", [Attr#attr.precise]),
    ?INFO_LOG("pd_attr_thunder_atk,  ~p", [Attr#attr.thunder_atk]),
    ?INFO_LOG("pd_attr_thunder_def,  ~p", [Attr#attr.thunder_def]),
    ?INFO_LOG("pd_attr_fire_atk,     ~p", [Attr#attr.fire_atk]),
    ?INFO_LOG("pd_attr_fire_def,     ~p", [Attr#attr.fire_def]),
    ?INFO_LOG("pd_attr_ice_atk,      ~p", [Attr#attr.ice_atk]),
    ?INFO_LOG("pd_attr_ice_def,      ~p", [Attr#attr.ice_def]),
    ?INFO_LOG("pd_attr_move_speed,   ~p", [Attr#attr.move_speed]),
    ?INFO_LOG("pd_attr_run_speed,    ~p", [Attr#attr.run_speed]),
    ?INFO_LOG("pd_attr_suck_blood,   ~p", [Attr#attr.suck_blood]),
    ?INFO_LOG("pd_attr_reverse,      ~p", [Attr#attr.reverse]).

%% 加载角色字段表
init_all_fields(Key, Key) -> erlang:put(Key, init_fields(Key));
init_all_fields(HeadField, TailField) ->
    erlang:put(HeadField, init_fields(HeadField)),
    init_all_fields(HeadField + 1, TailField).


%% 加载角色字段表
load_field(_Key, ?undefined) ->
    pass;
load_field(Key, Val) ->
    %?ERROR_LOG("load_field done ~w ~w", [Key, Val]),
    attr_new:set(Key, Val).

%% 获得字段链表
get_fields_list(Key, Key) ->
    case attr_new:get(Key) of
        undefined ->
            [];
        Val ->
            [{Key, Val}]
    end;
get_fields_list(HeadField, TailField) ->
    case attr_new:get(HeadField) of
        undefined ->
            get_fields_list(HeadField + 1, TailField);
        Val ->
            [{HeadField, Val} | get_fields_list(HeadField + 1, TailField)]
    end.


%% 设置开关数据
set_sink_state(Id, Val) ->
    %% 修正开关值
    Len = (?sinks_state_len),
    if
        is_integer(Val) andalso Val > 0 ->
            State = 1;
        true ->
            State = 0
    end,
    %% 设置开关值
    if
        is_integer(Id) andalso Id >= 1 andalso 1 =< Len ->
            LeftLen = Id - 1,
            RightLen = Len - Id,
            <<Left:LeftLen, _X:1, Right:RightLen>> = attr_new:get(?pd_sinks_state),
            put(?pd_sinks_state, <<Left:LeftLen, State:1, Right:RightLen>>),
            %% 同步数据到客户端
            IsInitCliendCompleted = attr_new:get(?pd_init_cliend_completed),
            case IsInitCliendCompleted of
                1 ->
                    <<NewVal:16>> =
                    case State of
                        1 ->
                            <<1:1, Id:15>>;
                        _ ->
                            <<0:1, Id:15>>
                    end,
                    ?player_send(sinks_state_sproto:pkg_msg(?MSG_SYNC_SINK_ITEM_SC, {[{NewVal}]}));
                _ ->
                    ok
            end,
            true;
        true ->
            false
    end.

%% 获得开关数据
get_sink_state(Id) ->
    Len = (?sinks_state_len),
    if
        is_integer(Id) andalso Id >= 1 andalso 1 =< Len ->
            LeftLen = Id - 1,
            RightLen = Len - Id,
            <<_Left:LeftLen, Ret:1, _Right:RightLen>> = attr_new:get(?pd_sinks_state),
            Ret;
        true ->
            0
    end.


%% 获得VIP等级
get_vip_lvl() ->
    % RMBVip = attr_new:get(?pd_vip),
    % CardVip = attr_new:get(?pd_card_vip),
    % if
    %     RMBVip > CardVip ->
    %         Vip = RMBVip;
    %     true ->
    %         Vip = CardVip
    % end,
    % Vip.
    attr_new:get(?pd_vip).


%% 得到战斗力
get_combat_power(OAttr) ->
    Attr = player_base_data:change_old_attr(OAttr),
    #attr{
        block = Blo
        , precise = Pre
        , crit = Crit
        , pliable = Pli
        , atk = Atk
        , def = Def
        , atk_speed = AtkS
        , hp = Hp
        , break_def = Bre
        , ice_atk = IceAtk
        , ice_def = IceDef
        , fire_atk = FireAtk
        , fire_def = FireDef
        , thunder_atk = ThuAtk
        , thunder_def = ThuDef
        , intellect = Intellect
    } = Attr,
    round(Blo * ?PF_BLOCK + Pre * ?PF_PRECISE  + Crit * ?PF_CRIT + Pli * ?PF_PLIABLE + Atk * ?PF_ATK + Def * ?PF_DEF + AtkS * ?PF_ATK_SPEED + Hp * ?PF_HP + Bre * ?PF_BREAK_DEF + IceAtk * ?PF_ICE_ATK + FireAtk * ?PF_FIRE_ATK + ThuAtk * ?PF_THUNDER_ATK + IceDef * ?PF_ICE_DEF + FireDef * ?PF_FIRE_DEF + ThuDef * ?PF_THUNDER_DEF + Intellect * ?PF_INTELLECT_DEF).
    %round(Blo * 3 + Pre * 3 + Crit * 1.5 + Pli * 1.5 + Atk + Def * 2 + AtkS * 5 + Hp * 0.2 + Bre * 2 + IceAtk + FireAtk + ThuAtk + IceDef * 10 + FireDef * 10 + ThuDef * 10 + Intellect * 5).
    %%round(Blo * 3 + Pre * 3 + Crit * 1.5 + Pli * 1.5 + Atk + Def * 2 + AtkS * 5 + Hp).

check_uid(_UID) ->
    ret:ok().
%%     <<_:15, ReadUID:17>> = <<UID:32>>,
%%     if
%%         ReadUID >= ?MAX_UID -> ret:error(error_uid);
%%         true -> ret:ok()
%%     end.

create_uid() ->
    ID = attr_new:get(?pd_system_item_id, 0),
    {PreFix, ID1} =
    if
        ID >= 9 ->
            Pre = server_res_eng:call_get_uid_prefix(),
            attr_new:set(?pd_uid_prefix, Pre),
            attr_new:set(?pd_system_item_id, 1),
            {Pre, 1};
        true ->
            case attr_new:get(?pd_uid_prefix, 0) of
                0 ->
                    Pre1 = server_res_eng:call_get_uid_prefix(),
                    attr_new:set(?pd_uid_prefix, Pre1),
                    attr_new:set(?pd_system_item_id, 1),
                    {Pre1, 1};
                Pre2 ->
                    attr_new:set(?pd_system_item_id, ID + 1),
                    {Pre2, ID + 1}
            end
    end,
    UID = PreFix * 10 + ID1,
    UID.




list_2_attr(FieldList) ->
%%     ?INFO_LOG("list_2_attr ~p", [FieldList]),
    SumAttr =
        lists:foldl(
            fun({CfgKey, Val}, Acc) ->
                AttrKey = CfgKey - ?cfg_attr_key_dt,
                OldVal = element(AttrKey, Acc),
                setelement(AttrKey, Acc, (OldVal + Val))
            end,
            #attr{},
            FieldList),
    SumAttr.

%% 增加属性的千分比
list_2_attr_pre(Attr, FieldPreList) ->
    SumAttr =
        lists:foldl(
            fun({CfgKey, Pre}, Acc) ->
                AttrKey = CfgKey - ?cfg_attr_key_dt,
                OldVal = element(AttrKey, Acc),
                setelement(AttrKey, Acc, round(OldVal*(1 + Pre/1000)))
            end,
            Attr#attr{},
            FieldPreList),
    SumAttr.



amend(Attr = #attr{strength = _Str, def = _Def, intellect = _Int, nimble = _Ni, mp = _Mp, strong = _Sto, atk = _Atk, hp = _Hp, crit = _Crit}) ->
%%     Attr#attr{atk = Atk + Str * 5 + Ni * 2,
%%         hp = Hp + Str + Sto * 15,
%%         mp = Mp + Int,
%%         crit = Crit + Ni * 3,
%%         def = Def + Sto * 2
%%     }.
    Attr;

amend(Attr) ->
    amend(player_base_data:change_old_attr(Attr)).


begin_room_prize(PrizeId) ->
    attr_new:set(pd_room_prize_id, PrizeId),
    % system_log:info_finish_room(RoomId),
%%     attenuation:self_add(),
    ok.


end_room_prize(_RoomID) ->
    attr_new:set(pd_room_prize_id, 0).

get_room_prize() ->
    case attr_new:get(pd_room_prize_id) of
        undefined -> 0;
        PrizeID -> PrizeID
    end.


is_room_prize() ->
    case get_room_prize() of
        0 -> false;
        _ -> true
    end.

get_online_time_this() ->                                           %% 本次在线时长
    RetSec = util:get_now_second(0) - get(?pd_player_scene_second_this_time, util:get_now_second(0)),
%%    ?INFO_LOG("获取本次在线时长 RetSec = ~p", [RetSec]),
    RetSec.

get_online_time_onday() ->                                          %%  当天在线时长
    Times =
        case erlang:get(?pd_player_scene_time_count) of
            undefined ->
                get_online_time_this();
            0 ->
                get_online_time_this();
            RetT ->
                RetT + get_online_time_this()
        end,
    Times.

get_sub_attr(AttrOld,AttrNew) ->
    AttrRet = #attr
    {
        hp = max(0,AttrNew#attr.hp - AttrOld#attr.hp), %%  max_hp
        mp = max(0,AttrNew#attr.mp - AttrOld#attr.mp),
        sp = max(0,AttrNew#attr.sp - AttrOld#attr.sp),
        np = max(0,AttrNew#attr.np - AttrOld#attr.np),
        strength = max(0,AttrNew#attr.strength - AttrOld#attr.strength),
        intellect = max(0,AttrNew#attr.intellect - AttrOld#attr.intellect),
        nimble = max(0,AttrNew#attr.nimble - AttrOld#attr.nimble),
        strong = max(0,AttrNew#attr.strong - AttrOld#attr.strong),
        atk = max(0,AttrNew#attr.atk - AttrOld#attr.atk),
        def = max(0,AttrNew#attr.def - AttrOld#attr.def),
        crit = max(0,AttrNew#attr.crit - AttrOld#attr.crit),
        block = max(0,AttrNew#attr.block - AttrOld#attr.block),
        pliable = max(0,AttrNew#attr.pliable - AttrOld#attr.pliable),
        pure_atk = max(0,AttrNew#attr.pure_atk - AttrOld#attr.pure_atk),
        break_def = max(0,AttrNew#attr.break_def - AttrOld#attr.break_def),
        atk_deep = max(0,AttrNew#attr.atk_deep - AttrOld#attr.atk_deep),
        atk_free = max(0,AttrNew#attr.atk_free - AttrOld#attr.atk_free),
        atk_speed = max(0,AttrNew#attr.atk_speed - AttrOld#attr.atk_speed),
        precise = max(0,AttrNew#attr.precise - AttrOld#attr.precise),
        thunder_atk = max(0,AttrNew#attr.thunder_atk - AttrOld#attr.thunder_atk),
        thunder_def = max(0,AttrNew#attr.thunder_def - AttrOld#attr.thunder_def),
        fire_atk = max(0,AttrNew#attr.fire_atk - AttrOld#attr.fire_atk),
        fire_def = max(0,AttrNew#attr.fire_def - AttrOld#attr.fire_def),
        ice_atk = max(0,AttrNew#attr.ice_atk - AttrOld#attr.ice_atk),
        ice_def = max(0,AttrNew#attr.ice_def - AttrOld#attr.ice_def),
        move_speed = max(0,AttrNew#attr.move_speed - AttrOld#attr.move_speed),
        run_speed = max(0,AttrNew#attr.run_speed - AttrOld#attr.run_speed),
        suck_blood = max(0,AttrNew#attr.suck_blood - AttrOld#attr.suck_blood),
        reverse = max(0,AttrNew#attr.reverse - AttrOld#attr.reverse)
        % bati = compute_attr_val(Attr#attr.bati, attr_new:get(?pd_attr_bati), AttrL2#attr.bati, AttrPre#attr.bati)%%
    },
    AttrRet.
