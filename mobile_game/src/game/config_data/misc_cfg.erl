%%% coding:utf-8
%%%-------------------------------------------------------------------
%%% @author zl
%%% @doc 用于存放一些单条配置
%%%
%%% @end
%%%-------------------------------------------------------------------

-module(misc_cfg).


-include_lib("config/include/config.hrl").
-include_lib("common/include/com_log.hrl").
-include("inc.hrl").
-include("item.hrl").


%% API
-export
([
    get_bag_info/0
    , get_task_info/0
    , get_depot_info/0
    , get_default_scene_id/0
    , get_jian_ding_id/0, get_qiang_hua_id/0, get_yu_lan_id/0, get_equip_qualily/0
    , get_auction_cfg/0
    , get_task_daily_free_flush_times/0, get_task_daily_pay_flush_times/0, get_task_daily_flush_cost/0
    , get_friend_cfg/0
    , get_item_type_index/0
    , get_he_cheng_cfg/0
    , get_add_hp_mp_cfg/1
    , get_arena_p2e_count/0, get_arena_p2e_time/0, get_arena_p2e_attr_per/0
    , get_arena_p2p_count/0, get_arena_p2p_time/0, get_arena_p2p_start_time/0
    , get_arena_multi_p2p_count/0, get_arena_multi_p2p_time/0, get_arena_multi_p2p_start_time/0
    , get_arena_glory_award_time/0, get_arena_glory_cost/0
    , get_arena_single_p2e_scene/0, get_arena_single_p2p_scene/0, get_arena_multi_p2p_scene/0
    , get_misc_cfg/1, get_max_lev/0, get_bag_trigger/0, get_p2e_prize/0
    , max_room_pass_count/0
    , get_chat_lev_limit/0
    , get_chat_horw_lev_limit/0
    , max_room_time_count/0
    , prize_attenuation_per_time/0
    , prize_attenuation_per_count/0
    , get_load_progress_data_submit/0
    , get_load_progress_data_accept/0
    , get_unbind_cost_id/0
    , get_longwen_xidian/0
    , get_longwen_huoqu/0
    , get_task_daily_baoxiang/0
    , get_task_daily_up_number/0
    , get_task_daily_openlevel/0
    , get_load_progress_data_enter_scene/0
    , get_load_progress_data_leave_scene/0
    , get_longwen_doublegift/0
    , get_hecheng_guide_bid/0
    , get_drill_cost/0
    , get_main_ins_shop_info/0
    , get_pet_pool/0
    , get_pet_fengyin/0
    , get_black_shop_misc/0
    , get_beast_soul_happy_reduce_interview_misc/0
    , get_beast_soul_happy_reduce_value_misc/0
    , get_equip_hecheng_lock_cost/0
    , get_abyss_reward_decay/0
    % , get_daily_activity_balance/0
    , get_robot_refresh/0
    , get_equip_exchange_bag_limit/0
    , get_epic_gem_drill_cost/0
    , get_course_prize_attenuation/0
    , get_main_ins_open_card_cost/0
    , get_shangjin_task_liveness/0
    , get_shangjin_task_reset_time/0
    , get_shangjin_refresh_cost/0
    , get_skill_mp_cost/0
    , get_attr_times_by_player_num/0
    , get_nine_lottery_cost/0
    , get_nine_lottery_accumulat_pro/0
    , get_nine_lottery_sup_prize_pro/0
    , get_nine_lottery_max_num/0
    , get_equip_xilian_cost/0
    , get_level_crown_skill_list/0
    , get_xilian_stone_id/0
    , get_daily_activity_time/0
    , get_pata_cost/0
    , get_arena_flush_cost/0
    , get_buy_sp_limit/0
    , get_jd_attr_range/0
    , get_vip_deal_first_pay/0
    , get_qianghua_by_quality/0
    , get_zuiqiang_rank_shop_count/0
    , get_timer_renovating/0
    , get_survey_prize/0
    , get_sp_time/0
    , get_share_prize/0
    ,get_mining_cost/0
    , get_equip_qianghua_lv/0
    , get_fish_count/0
    , get_alter_name/0
    , get_guild_saint_pro/0
    , get_guild_saint_touch/0
    , get_guild_max_lv/0
]).



-record(misc_cfg, {id, data}).

-define(lookup(N), #misc_cfg{data = D} = lookup_misc_cfg(N), D).

get_bag_info() -> ?lookup(bag_info).

get_depot_info() -> ?lookup(depot_info).
get_task_info() -> ?lookup(task_info).
get_default_scene_id() -> ?lookup(default_scene_id).
get_jian_ding_id() -> ?lookup(jian_ding_info).
get_qiang_hua_id() -> ?lookup(qiang_hua_id).
get_yu_lan_id() -> ?lookup(yu_lan_id).
get_equip_qualily() -> ?lookup(equip_qualily).
get_auction_cfg() -> ?lookup(auction_cfg).
get_task_daily_free_flush_times() -> ?lookup(task_daily_free_flush_times).
get_task_daily_pay_flush_times() -> ?lookup(task_daily_pay_flush_times).
get_task_daily_flush_cost() -> ?lookup(task_daily_flush_cost).
get_friend_cfg() -> ?lookup(friend_cfg).
get_item_type_index() -> ?lookup(item_type_index).
get_he_cheng_cfg() -> ?lookup(he_cheng_cfg).
get_add_hp_mp_cfg(_) -> ?lookup(add_hp_mp_cfg).
get_arena_p2e_count() -> ?lookup(arena_pve_count).
get_arena_p2e_time() -> ?lookup(arena_pve_time).
get_arena_p2e_attr_per() -> ?lookup(arena_pve_attr_per).
get_arena_p2p_count() -> ?lookup(arena_pvp_count).
get_arena_p2p_time() -> ?lookup(arena_pvp_time).
get_arena_p2p_start_time() -> ?lookup(arena_pvp_start_time).
get_arena_multi_p2p_count() -> ?lookup(arena_multi_pvp_count).
get_arena_multi_p2p_time() -> ?lookup(arena_multi_pvp_time).
get_arena_multi_p2p_start_time() -> ?lookup(arena_multi_pvp_start_time).
get_arena_glory_award_time() -> ?lookup(arena_glory_award_time).
get_arena_glory_cost() -> ?lookup(arena_glory_cost).
get_arena_single_p2e_scene() -> ?lookup(arena_single_pve_scene).
get_arena_single_p2p_scene() -> ?lookup(arena_single_pvp_scene).
get_arena_multi_p2p_scene() -> ?lookup(arena_multi_pvp_scene).
get_max_lev() -> ?lookup(max_lev).
get_bag_trigger() -> ?lookup(bag_trigger).
get_p2e_prize() -> ?lookup(p2e_prize).
get_misc_cfg(Atom) -> ?lookup(Atom).
max_room_pass_count() -> ?lookup(max_room_pass_count).
get_chat_lev_limit() -> ?lookup(chat_lev_limit).
get_chat_horw_lev_limit() -> ?lookup(chat_horw_lev_limit).
max_room_time_count() -> ?lookup(max_room_time_count).
prize_attenuation_per_time() -> ?lookup(prize_attenuation_per_time).
prize_attenuation_per_count() -> ?lookup(prize_attenuation_per_count).
get_load_progress_data_submit() -> ?lookup(load_progress_data_submit).
get_load_progress_data_accept() -> ?lookup(load_progress_data_accpet).
get_unbind_cost_id() -> ?lookup(unbind_cost_id).
get_task_daily_baoxiang() -> ?lookup(task_daily_baoxiang).
get_task_daily_up_number() -> ?lookup(task_daily_up_number).
get_longwen_xidian() -> ?lookup(longwen_xidian).
get_longwen_huoqu() -> ?lookup(longwen_huoqu).
get_task_daily_openlevel() -> ?lookup(task_daily_openlevel).
get_load_progress_data_enter_scene() -> ?lookup(load_progress_enter_scene).
get_load_progress_data_leave_scene() -> ?lookup(load_progress_leave_scene).
get_longwen_doublegift() -> ?lookup(longwen_doublegift).
get_hecheng_guide_bid() -> ?lookup(equipCompound_id).
get_drill_cost() -> ?lookup(drill_cost).
get_main_ins_shop_info() -> ?lookup(main_ins_shop_info).
get_pet_pool() -> ?lookup(pet_pool).
get_pet_fengyin() -> ?lookup(pet_fengyin).
get_black_shop_misc() -> ?lookup(black_shop_misc_new).
get_beast_soul_happy_reduce_interview_misc() -> ?lookup(beast_soul_happy_reduce_interview).
get_beast_soul_happy_reduce_value_misc() -> ?lookup(beast_soul_happy_reduce_value).
get_equip_hecheng_lock_cost() -> ?lookup(equipcompound_lockcost).
get_abyss_reward_decay() -> ?lookup(abyss_reward_decay).
% get_daily_activity_balance() -> ?lookup(daily_activity_balance).
get_robot_refresh() -> ?lookup(robot_refresh).
get_equip_exchange_bag_limit() -> ?lookup(epurate_bagnum).
get_epic_gem_drill_cost() -> ?lookup(epic_gem_drill_cost).
get_course_prize_attenuation() -> ?lookup(course_prize_attenuation).
get_main_ins_open_card_cost() -> ?lookup(main_ins_open_card_cost).
get_shangjin_task_liveness() -> ?lookup(shangjin_task_liveness).
get_shangjin_task_reset_time() -> ?lookup(shangjin_task_reset_time).
get_shangjin_refresh_cost() -> ?lookup(shangjin_refresh_cost).
get_skill_mp_cost() -> ?lookup(skill_mp_cost).
get_attr_times_by_player_num() -> ?lookup(attr_times_by_player_num).
get_nine_lottery_cost() -> ?lookup(nine_lottery_cost).
get_nine_lottery_accumulat_pro() -> ?lookup(nine_lottery_accumulat_pro).
get_nine_lottery_sup_prize_pro() -> ?lookup(nine_lottery_sup_prize_pro).
get_nine_lottery_max_num() -> ?lookup(nine_lottery_max_num).
get_equip_xilian_cost() -> ?lookup(xilian_cost).
get_level_crown_skill_list() -> ?lookup(level_crown_skill).
get_xilian_stone_id() -> ?lookup(xilian_id).
get_daily_activity_time() -> ?lookup(daily_activity_time).
get_pata_cost() -> ?lookup(pata_cost).
get_arena_flush_cost() -> ?lookup(arena_flush_cost).
get_buy_sp_limit() -> ?lookup(buy_sp_limit).
get_jd_attr_range() -> ?lookup(equip_jd_attr_range).
get_vip_deal_first_pay() -> ?lookup(zuanshi).
get_qianghua_by_quality() -> ?lookup(equip_qianghua_quality).
get_zuiqiang_rank_shop_count() -> ?lookup(zuiqiang_rank_shop_count).
get_timer_renovating() -> ?lookup(timer_renovating).
get_survey_prize() -> ?lookup(survey_prize).
get_sp_time() -> ?lookup(sp_time).
get_share_prize() -> ?lookup(share_prize).
get_mining_cost() ->    ?lookup(mining_cost).
get_equip_qianghua_lv() -> ?lookup(equip_qianghua_lv).
get_alter_name() -> ?lookup(alter_name).
get_fish_count() -> ?lookup(fish_count).
get_guild_saint_pro() -> ?lookup(guild_saint_pro).
get_guild_saint_touch() -> ?lookup(guild_saint_touch).
get_guild_max_lv() -> ?lookup(guild_max_lv).


load_config_meta() ->
    [
        #config_meta{record = #misc_cfg{},
            fields = record_info(fields, misc_cfg),
            file = "misc.txt",
            keypos = #misc_cfg.id,
            verify = fun verify/1}
    ].

%% misc 的每一条都要验证
%% 
verify(#misc_cfg{id=alter_name, data = Data}) ->
    ?check(is_list(Data), "misc alter_name   ~p 无效", [Data]);

verify(#misc_cfg{id= task_daily_openlevel, data = Level}) ->
    ?check(?is_pos_integer(Level), "misc task_daily_openlevel ~p 无效 > 0", [Level]);

verify(#misc_cfg{id = longwen_doublegift, data = Level}) ->
    ?check(?is_pos_integer(Level), "misc longwen_doublegift ~p 无效 > 0", [Level]);


verify(#misc_cfg{id = task_daily_free_flush_times, data = Times}) ->
    ?check(?is_pos_integer(Times), "misc task_daily_free_flush_times ~p 无效 > 0", [Times]),
    ok;
verify(#misc_cfg{id = task_daily_pay_flush_times, data = Times}) ->
    ?check(?is_pos_integer(Times), "misc task_daily_pay_flush_times ~p 无效 > 0", [Times]),
    ok;
verify(#misc_cfg{id = task_daily_flush_cost, data = _CostId}) ->
    %cost:check_cost_not_empty(CostId, "misc task_daily_flush_cost~p 没有找到 > 0", [CostId]),
    ok;
verify(#misc_cfg{id = bag_info, data = #{size:=Size, init_size:=InitSize}}) ->
    ?check(InitSize =< Size, "misc [~p] 配置无效　size 必须　>= init_size", [bag_info]),
    ok;
verify(#misc_cfg{id = depot_info, data = #{size:=Size, init_size:=InitSize}}) ->
    ?check(InitSize =< Size, "misc [~p] 配置无效　size 必须　>= init_size", [depot]),
    ok;
verify(#misc_cfg{id = task_info, data = #{first_task := Task}}) ->
    if
        Task =:= 0 ->
            ok;
        true ->
            [?check(load_task_progress:is_exist_task_new_cfg(T), "misc [task_info] 无法找到初始任务~p", [T]) || T <- Task]
    end;

verify(#misc_cfg{id = load_progress_data_submit, data = Data}) ->
    [?check(load_task_progress:is_exist_task_new_cfg(T), "misc [load_progress_data_submit] task无法找到任务~p", [T]) || {T, _} <- Data],
    ok;
verify(#misc_cfg{id = load_progress_data_accpet, data = Data}) ->
    [?check(load_task_progress:is_exist_task_new_cfg(T), "misc [load_progress_data_accept] task无法找到任务~p", [T]) || {T, _} <- Data],
    ok;
verify(#misc_cfg{id = bag_trigger, data = Data}) ->
    [?check(load_task_progress:is_exist_task_new_cfg(T), "misc [bag_trigger] 无法找到初始任务~p", [T]) || T <- tuple_to_list(Data)];


verify(#misc_cfg{id = friend_info, data = #{max_friend_size:=T}}) ->
    ?check(is_integer(T), "misc [~p] max_friend_size ~p 无效", [friend_info, T]),
    ok;
verify(#misc_cfg{id = jian_ding_info, data = GoodsId}) ->
    ?check(load_item:is_exist_item_attr_cfg(GoodsId), "misc [jiand_ding_info] 鉴定物品~p 没有找到", [GoodsId]),
    ok;
verify(#misc_cfg{id = qiang_hua_id, data = {GoodsId, _Per}}) ->
    ?check(load_item:is_exist_item_attr_cfg(GoodsId), "misc [qiang_hua_id] 强化免疫物品~p 没有找到", [GoodsId]),
    ok;

verify(#misc_cfg{id = yu_lan_id, data = GoodsId}) ->
    ?check(load_item:is_exist_item_attr_cfg(GoodsId), "misc [yu_lan_if] 合成预览物品~p 没有找到", [GoodsId]),
    ok;
verify(#misc_cfg{id = spell_info, data = {_JH, _QJ, _FW, _ZW}}) ->
    %%[?check(skill:is_exist_skill_cfg(Id), "misc spell_info 职业 ~p 默认技能没有找到 ~p", ["FW", Id]) || Id <- FW],
    %%[?check(skill:is_exist_skill_cfg(Id), "misc spell_info 职业 ~p 默认技能没有找到 ~p", ["JH", Id]) || Id <- JH],
    %%[?check(skill:is_exist_skill_cfg(Id), "misc spell_info 职业 ~p 默认技能没有找到 ~p", ["QJ", Id]) || Id <- QJ],
    %%[?check(skill:is_exist_skill_cfg(Id), "misc spell_info 职业 ~p 默认技能没有找到 ~p", ["ZW", Id]) || Id <- ZW],
    ok;
verify(#misc_cfg{id = default_scene_id, data = {A, B, C, D}}) ->
    [?check(is_integer(Id) andalso load_cfg_scene:is_exist_scene_cfg(A), "misc.txt default_scene_id ~p can not find", [Id]) || Id <- [A, B, C, D]],
    ok;

verify(#misc_cfg{id = main_ins_open_card_cost, data = Data}) ->
    ?check(is_list(Data), "misc [main_ins_open_card_cost:~w] 配置无效! ", [Data]),
    ok;

verify(#misc_cfg{id = timer_renovating, data = Data}) ->
    ?check(is_list(Data), "misc [timer_renovating:~w] 配置无效! ", [Data]),
    ok;

verify(#misc_cfg{id = he_cheng_cfg, data = Data}) ->
    lists:foreach(fun({Len, _Per}) ->
%%    ?check(com_util:is_valid_uint_max(Per, 100), "misc he_cheng_cfg ~w Per ill", [Per]),
        ?check(is_integer(Len), "misc he_cheng_cfg ~w Len ill", [Len])
                  end, Data),
    ok;

verify(#misc_cfg{id = item_type_index, data = _Data}) ->
%%     lists:foreach(fun({Type, Index}) ->
%%                         ?check(is_integer(Index), "misc item_type_index ~w Index ill", [Index]),
%%                   end, Data),
    ok;

verify(#misc_cfg{id = equip_qualily, data = Data}) ->
    lists:foreach(fun({AttrCount, CostCount}) ->
        ?check(is_integer(AttrCount) andalso is_integer(CostCount), "equip_qualily data:~p error", [{AttrCount, CostCount}]) end, Data),
    ok;

verify(#misc_cfg{id = equip_qianghua_lv, data = Data}) ->
    ?check(is_list(Data), "misc equip_qianghua_lv [Data:~w] 配置无效! ", [Data]);


verify(#misc_cfg{id = friend_cfg, data = Data}) ->
    #{
        max := Max,
        vip_max :=  VipMax,
        apply_max := ApplyMax,
        apply_timeout := ApplyTimeOut,
        send_gift_max := SendGiftMax,
        recv_gift_max := RecvGiftMax,
        gift_qua := GiftQua,
        gift_per_score := GiftPerScore,
        day_score_max := DayScoreMax,
        day_chat_score_max := DayChatScoreMax,
        item_flowers_give_score := ItemFlowersGiveScore
    } = Data,
    ?check(is_integer(Max), "misc friend_cfg [Max:~w] 配置无效! ", [Max]),
    ?check(is_integer(VipMax), "misc friend_cfg [VipMax:~w] 配置无效! ", [VipMax]),
    ?check(is_integer(ApplyMax), "misc friend_cfg [ApplyMax:~w] 配置无效! ", [ApplyMax]),
    ?check(is_integer(ApplyTimeOut), "misc friend_cfg [ApplyTimeOut:~w] 配置无效! ", [ApplyTimeOut]),
    ?check(is_integer(SendGiftMax), "misc friend_cfg [SendGiftMax:~w] 配置无效! ", [SendGiftMax]),
    ?check(is_integer(RecvGiftMax), "misc friend_cfg [RecvGiftMax:~w] 配置无效! ", [RecvGiftMax]),
    ?check(is_list(GiftQua), "misc friend_cfg [GiftQua:~w] 配置无效! ", [GiftQua]),
    ?check(is_list(GiftPerScore), "misc friend_cfg [GiftPerScore:~w] 配置无效! ", [GiftPerScore]),
    ?check(is_integer(DayScoreMax), "misc friend_cfg [DayScoreMax:~w] 配置无效! ", [DayScoreMax]),
    ?check(is_integer(DayChatScoreMax), "misc friend_cfg [DayChatScoreMax:~w] 配置无效! ", [DayChatScoreMax]),
    ?check(is_list(ItemFlowersGiveScore), "misc friend_cfg [ItemFlowersGiveScore:~w] 配置无效! ", [ItemFlowersGiveScore]),
    ok;
verify(#misc_cfg{id = auction_cfg, data = Data}) ->
    #{
        page_size := PageSize,
        page_max := PageMax,
        bail := Bail,
        charge_rate := ChargeRate,
        add_price := AddPrice,
        check_price := CheckPrice,
        auction_hours := AuctionHours,
        player_lev := PlayerLev,
        count := Count,
        day_count := DayCount
    } = Data,
    ?check(is_integer(PageSize), "misc auction_cfg [PageSize:~w] 配置无效! ", [PageSize]),
    ?check(is_integer(PageMax), "misc auction_cfg [PageMax:~w] 配置无效! ", [PageMax]),
    ?check(is_integer(Bail), "misc auction_cfg [Bail:~w] 配置无效! ", [Bail]),
    ?check(is_list(ChargeRate), "misc auction_cfg [ChargeRate:~w] 配置无效! ", [ChargeRate]),
    ?check(is_integer(AddPrice), "misc auction_cfg [AddPrice:~w] 配置无效! ", [AddPrice]),
    ?check(is_integer(CheckPrice), "misc auction_cfg [CheckPrice:~w] 配置无效! ", [CheckPrice]),
    ?check(is_integer(AuctionHours), "misc auction_cfg [AuctionHours:~w] 配置无效! ", [AuctionHours]),
    ?check(is_integer(PlayerLev), "misc auction_cfg [PlayerLev:~w] 配置无效! ", [PlayerLev]),
    ?check(is_integer(Count), "misc auction_cfg [Count:~w] 配置无效! ", [Count]),
    ?check(is_integer(DayCount), "misc auction_cfg [DayCount:~w] 配置无效! ", [DayCount]),
    ok;

verify(#misc_cfg{id = arena_pve_count, data = Count}) ->
    ?check(com_util:is_valid_uint8(Count), "misc [arena_pve_count] 参加次数[~w]错误 ", [Count]),
    ok;
verify(#misc_cfg{id = arena_pve_time, data = Time}) ->
    ?check(com_util:is_valid_uint16(Time), "misc [arena_pve_time] 战斗时长[~w]错误 ", [Time]),
    ok;
verify(#misc_cfg{id = arena_pve_attr_per, data = AttrPer}) ->
    ?check(com_util:is_valid_uint16(AttrPer), "misc [arena_pve_per] 镜像怪物属性[~w]错误 ", [AttrPer]),
    ok;
verify(#misc_cfg{id = arena_pvp_count, data = Count}) ->
    ?check(com_util:is_valid_uint8(Count), "misc [arena_pvp_count] 参加次数[~w]错误 ", [Count]),
    ok;
verify(#misc_cfg{id = arena_pvp_time, data = Time}) ->
    ?check(com_util:is_valid_uint16(Time), "misc [arena_pvp_time] 战斗时长[~w]错误 ", [Time]),
    ok;
verify(#misc_cfg{id = arena_pvp_start_time, data = TimeL}) ->
    lists:foreach(fun({{Hour, Min, Sec}, Len}) ->
        ?check(com_util:is_valid_uint_max(Hour, 23), "misc [arena_pvp_start_time] 战斗开启时间Hour[~w]错误 ", [Hour]),
        ?check(com_util:is_valid_uint_max(Min, 59), "misc [arena_pvp_start_time] 战斗开启时间Min[~w]错误 ", [Min]),
        ?check(com_util:is_valid_uint_max(Sec, 59), "misc [arena_pvp_start_time] 战斗开启时间Sec[~w]错误 ", [Sec]),
        ?check(com_util:is_valid_uint16(Len), "misc [arena_pvp_start_time] 战斗开启时间Len[~w]错误 ", [Len])
                  end, TimeL),
    ok;
verify(#misc_cfg{id = arena_multi_pvp_count, data = Count}) ->
    ?check(com_util:is_valid_uint8(Count), "misc [arena_multi_pvp_count] 参加次数[~w]错误 ", [Count]),
    ok;
verify(#misc_cfg{id = arena_multi_pvp_time, data = Time}) ->
    ?check(com_util:is_valid_uint16(Time), "misc [arena_multi_pvp_time] 战斗时长[~w]错误 ", [Time]),
    ok;
verify(#misc_cfg{id = arena_multi_pvp_start_time, data = TimeL}) ->
    lists:foreach(fun({{Hour, Min, Sec}, Len}) ->
        ?check(com_util:is_valid_uint_max(Hour, 23), "misc [arena_multi_pvp_start_time]战斗开启时间Hour[~w]错误 ", [Hour]),
        ?check(com_util:is_valid_uint_max(Min, 59), "misc [arena_multi_pvp_start_time] 战斗开启时间Min[~w]错误 ", [Min]),
        ?check(com_util:is_valid_uint_max(Sec, 59), "misc [arena_multi_pvp_start_time] 战斗开启时间Sec[~w]错误 ", [Sec]),
        ?check(com_util:is_valid_uint16(Len), "misc [arena_multi_pvp_start_time] 战斗开启时间Len[~w]错误 ", [Len])
                  end, TimeL),

    ok;
verify(#misc_cfg{id = arena_glory_award_time, data = {Hour, Min, Sec}}) ->
    ?check(com_util:is_valid_uint_max(Hour, 23), "misc [arena_glory_award_time] 战斗开启时间Hour[~w]错误 ", [Hour]),
    ?check(com_util:is_valid_uint_max(Min, 59), "misc [arena_glory_award_time] 战斗开启时间Min[~w]错误 ", [Min]),
    ?check(com_util:is_valid_uint_max(Sec, 59), "misc [arena_glory_award_time] 战斗开启时间Sec[~w]错误 ", [Sec]),
    ok;
verify(#misc_cfg{id = arena_glory_cost, data = CostTuple}) ->
    CostL = tuple_to_list(CostTuple),
    Len = length(CostL),
    ?check(Len == 8, "misc [arena_glory_cost] 消耗个数[~w]错误 ", [Len]),
    lists:foreach(fun(Num) ->
        ?check(com_util:is_valid_uint16(Num), "misc [arena_glory_cost] 消耗数值[~w]错误 ", [Num])
                  end, CostL),
    ok;
verify(#misc_cfg{id = arena_single_pve_scene, data = {SceneId, {X1, Y1}, MonId, {X2, Y2}}}) ->
    ?check(load_cfg_scene:is_exist_scene_cfg(SceneId), "misc [arena_single_pve_scene] 场景id[~w]不存在", [SceneId]),
    ?check(com_util:is_valid_uint16(X1) andalso com_util:is_valid_uint16(Y1), "misc [arena_single_pve_scene]坐标1[~w]错误", [{X1, Y1}]),
    ?check(scene_monster:is_exist_monster_cfg(MonId), "misc [arena_single_pve_scene] 怪物id[~w]不存在", [MonId]),
    ?check(com_util:is_valid_uint16(X2) andalso com_util:is_valid_uint16(Y2), "misc [arena_single_pve_scene]坐标2[~w]错误", [{X2, Y2}]),
    ok;

verify(#misc_cfg{id = arena_single_pvp_scene, data = {SceneId, {X1, Y1}, {X2, Y2}}}) ->
    ?check(load_cfg_scene:is_exist_scene_cfg(SceneId), "misc [arena_single_pvp_scene] 场景id[~w]不存在", [SceneId]),
    ?check(com_util:is_valid_uint16(X1) andalso com_util:is_valid_uint16(Y1), "misc [arena_single_pvp_scene]坐标1[~w]错误", [{X1, Y1}]),
    ?check(com_util:is_valid_uint16(X2) andalso com_util:is_valid_uint16(Y2), "misc [arena_single_pvp_scene]坐标2[~w]错误", [{X2, Y2}]),
    ok;

verify(#misc_cfg{id = arena_multi_pvp_scene, data = {SceneId, {X1, Y1, R1}, {X2, Y2, R2}}}) ->
    ?check(load_cfg_scene:is_exist_scene_cfg(SceneId), "misc [arena_multi_pvp_scene] 场景id[~w]不存在", [SceneId]),
    ?check(com_util:is_valid_uint16(X1) andalso com_util:is_valid_uint16(Y1) andalso com_util:is_valid_uint16(R1), "misc [arena_multi_pvp_scene]坐标1[~w]错误", [{X1, Y1, R1}]),
    ?check(com_util:is_valid_uint16(X2) andalso com_util:is_valid_uint16(Y2) andalso com_util:is_valid_uint16(R2), "misc [arena_multi_pvp_scene]坐标2[~w]错误", [{X2, Y2, R2}]),
    ok;
verify(#misc_cfg{id = add_hp_mp_cfg, data = {Cd}}) ->
    ?check(is_integer(Cd), "misc [add_hp_mp_cfg:~w] 配置无效! ", [add_hp_mp_cfg]),
    ok;

verify(#misc_cfg{id = guild_info, data = [{create_guild_need_diamond, NeedDiamond}, {create_guild_need_items, NeedItems}]}) ->
    ?check((?is_pos_integer(NeedDiamond) and
        is_list(NeedItems)), "misc [guild_info:~w] 配置无效! ", [guild_info]);

verify(#misc_cfg{id=zuanshi, data = Data}) ->
    ?check(is_tuple(Data), "misc [zuanshi:~w] 配置无效! ", [zuanshi]);


verify(#misc_cfg{id = seller_info, data = Data}) ->
    ?check(is_map(Data), "misc [seller_info:~w] 配置无效! ", [seller_info]);

verify(#misc_cfg{id = pet_info, data = Data}) ->
    ?check(is_map(Data), "misc [pet_info:~w] 配置无效! ", [pet_info]);

verify(#misc_cfg{id = viod_abyss_info, data = Data}) ->
    ?check(is_tuple(Data), "misc [pet_info:~w] 配置无效! ", [viod_abyss_info]);

verify(#misc_cfg{id = camp_info, data = Data}) ->
    ?check(is_list(Data), "misc [camp_info:~w] 配置无效! ", [camp_info]);

verify(#misc_cfg{id = sky_ins_info, data = Data}) ->
    ?check(is_list(Data), "misc [sky_ins_info:~w] 配置无效! ", [sky_ins_info]);

verify(#misc_cfg{id = max_lev, data = Lev}) ->
    ?check(com_util:is_valid_uint16(Lev) andalso Lev > 0, "misc [max_lev:~w] 配置无效! ", [Lev]);

verify(#misc_cfg{id = sky_rand_cost, data = CostL}) ->
    ?check(check_sky_ins_cost(CostL), "misc [sky_ins_cost:~w] 配置无效! ", [CostL]);

verify(#misc_cfg{id = enter_game_ins_task_id, data = SceneId}) ->
    ?check(is_list(SceneId), "misc [new_player_ins:~w] 配置无效! ", [SceneId]);

verify(#misc_cfg{id = daily_activity, data = List}) ->
    ?check(is_list(List), "misc [daily_activity:~w] 配置无效! ", [List]);

% verify(#misc_cfg{id = daily_activity_sklf, data = List}) ->
%     ?check(is_list(List), "misc [daily_activity_sklf:~w] 配置无效! ", [List]);

verify(#misc_cfg{id = skill_init, data = Tuple}) ->
    ?check(is_list(Tuple), "misc [skill_init:~w] 配置无效! ", [Tuple]);

verify(#misc_cfg{id = sp_info, data = SpTuple}) ->
    ?check(is_tuple(SpTuple), "misc [sp_info:~w] 配置无效! ", [SpTuple]);

verify(#misc_cfg{id = title_global_info, data = SpTuple}) ->
    ?check(is_tuple(SpTuple), "misc [title_global_info:~w] 配置无效! ", [SpTuple]);

verify(#misc_cfg{id = resource_version, data = Version}) ->
    ?check(is_integer(Version), "misc [resource_version:~w] 配置无效! ", [Version]);

verify(#misc_cfg{id = task_daily_baoxiang, data = PrizeList}) ->
    lists:foreach(fun({_, _, _, Prize}) ->
        ?check(Prize =:= 0 orelse prize:is_exist_prize_cfg(Prize), "misc.txt中 [task_daily_baoxiang:~w] 配置无效。", [Prize])
                  end,
        PrizeList);
verify(#misc_cfg{id=course_prize_attenuation, data = Data}) ->
    ?check(is_list(Data), "misc [course_prize_attenuation:~w] 配置无效! ", [Data]);

verify(#misc_cfg{id = main_ins_shop_info, data = Data}) ->
    ?check(is_tuple(Data), "misc [main_ins_shop_info:~w] 配置无效! ", [Data]);

verify(#misc_cfg{id = task_daily_up_number, data = Data}) ->
    ?check(is_integer(Data), "misc [task_daily_up_number:~w] 配置无效! ", [Data]);

verify(#misc_cfg{id = p2e_prize, data = PrizeId}) ->
    ?check(prize:is_exist_prize_cfg(PrizeId), "misc [p2e_prize:~w] 配置无效! ", [PrizeId]);

verify(#misc_cfg{id = max_room_pass_count, data = Count}) ->
    ?check(is_integer(Count), "misc [max_room_pass_count:~w] 配置无效! ", [Count]);

verify(#misc_cfg{id = max_effect_count, data = MaxEffectCount}) ->
    ?check(is_integer(MaxEffectCount), "misc [max_effect_count:~w] 配置无效! ", [MaxEffectCount]);

verify(#misc_cfg{id = chat_lev_limit, data = ChatLevLimit}) ->
    ?check(is_integer(ChatLevLimit), "misc [chat_lev_limit:~w] 配置无效! ", [ChatLevLimit]);

verify(#misc_cfg{id = chat_horw_lev_limit, data = ChatHorwLevLimit}) ->
    ?check(is_integer(ChatHorwLevLimit), "misc [chat_horw_lev_limit:~w] 配置无效! ", [ChatHorwLevLimit]);

verify(#misc_cfg{id = max_room_time_count, data = TimeLimit}) ->
    ?check(is_integer(TimeLimit), "misc [max_room_time_count:~w] 配置无效! ", [TimeLimit]);

verify(#misc_cfg{id = prize_attenuation_per_time, data = PrizePerTime}) ->
    ?check(is_integer(PrizePerTime), "misc [prize_attenuation_per_time:~w] 配置无效! ", [PrizePerTime]);

verify(#misc_cfg{id = prize_attenuation_per_count, data = PrizePerCount}) ->
    ?check(is_integer(PrizePerCount), "misc [prize_attenuation_per_count:~w] 配置无效! ", [PrizePerCount]);

verify(#misc_cfg{id = unbind_cost_id, data = ItemBid}) ->
    ?check(load_item:is_exist_item_cfg(ItemBid),"misc [unbind_cost_id:~w] 配置无效! ", [ItemBid]);

verify(#misc_cfg{id = longwen_xidian, data = ItemBid}) ->
    ?check(is_list(ItemBid),"misc [longwen_xidian:~w] 配置无效! ", [ItemBid]);

verify(#misc_cfg{id = longwen_huoqu, data = ItemBid}) ->
    ?check(is_list(ItemBid),"misc [longwen_huoqu:~w] 配置无效! ", [ItemBid]);

verify(#misc_cfg{id = pet_pool, data = Data}) ->
    ?check(length(Data) =:= 3, "misc.txt中 [pet_pool:~w] 配置无效。", [Data]),
    ok;

verify(#misc_cfg{id = pet_fengyin, data = {_, List} = Data}) ->
    ?check(is_list(List), "misc.txt中 [pet_fengyin:~w] 配置无效。", [Data]),
    ok;


verify(#misc_cfg{id = load_progress_enter_scene, data = Data}) ->
    ?check(is_list(Data), "misc.txt中 [load_progress_enter_scene:~w] 配置无效。", [Data]);

verify(#misc_cfg{id = load_progress_leave_scene, data = Data}) ->
    ?check(is_list(Data), "misc.txt中 [load_progress_leave_scene:~w] 配置无效。", [Data]);

verify(#misc_cfg{id = equipCompound_id, data = Data}) ->
    ?check(is_list(Data), "misc.txt中 [equipCompound_id:~w] 配置无效。", [Data]);

verify(#misc_cfg{id = drill_cost, data = Data}) ->
    ?check(is_list(Data), "misc.txt中 [drill_cost:~w] 配置无效。", [Data]);

verify(#misc_cfg{id = epic_gem_drill_cost, data = Data}) ->
    ?check(is_list(Data), "misc.txt中 [epic_gem_drill_cost:~w] 配置无效.", [Data]),
    ok;

verify(#misc_cfg{id = black_shop_misc_new, data = Data}) ->
    #{open_shop_time := {H,M,S},
        count_of_day :=  DayCount,
        start_time := SHour,
        end_time := EHour,
        free := F,
        refresh_num := Num
        } = Data,
    ?check(24*3600 - (H*3600+M*60+S + DayCount*60*(SHour+EHour)) >= 0, "~p black_shop_misc_new 配置的开市与休市时间之和超越了一天的总时间24小时...",[{H,M,S}]),
    ?check(DayCount >= 1, "count_of_day:~p 大于 1", [DayCount]),
    ?check(is_integer(F), "free:~p 配置格式不是整数", [F]),
    ?check(is_integer(Num), "refresh_num 配置的格式不是整数", [Num]),
    ok;

verify(#misc_cfg{id = beast_soul_happy_reduce_interview, data = Data}) ->
    ?check(is_integer(Data), "misc [beast_soul_happy_reduce_interview:~w] 配置无效! ", [Data]);

verify(#misc_cfg{id = beast_soul_happy_reduce_value}) ->
    ok;

verify(#misc_cfg{id = equipcompound_lockcost, data = Data}) ->
    ?check(is_list(Data), "misc.txt中 [equipcompound_lockcost:~w]配置无效。", [Data]),
    ok;

verify(#misc_cfg{id = abyss_reward_decay, data = Data}) ->
    ?check(is_tuple(Data), "misc.txt中 [abyss_reward_decay:~w]配置无效。", [Data]),
    ok;

% verify(#misc_cfg{id = daily_activity_balance, data = Data}) ->
%     ?check(is_tuple(Data), "misc.txt中 [daily_activity_balance:~w]配置无效。", [Data]),
%     ok;

verify(#misc_cfg{id = robot_refresh, data = Data}) ->
    ?check(is_list(Data), "misc.txt中 [robot_refresh:~w]配置无效。", [Data]),
    ok;

verify(#misc_cfg{id = epurate_bagnum, data = Data}) ->
    ?check(is_integer(Data), "misc.txt中 [epurate_bagnum:~w]配置无效。", [Data]),
    ok;

verify(#misc_cfg{id = shangjin_task_liveness, data = Data}) ->
    ?check(is_list(Data), "misc.txt中 [shangjin_task_liveness:~w]配置无效。", [Data]),
    ok;

verify(#misc_cfg{id = shangjin_task_reset_time, data = Data}) ->
    ?check(is_integer(Data), "misc.txt中 [shangjin_task_reset_time:~w]配置无效。", [Data]),
    ok;

verify(#misc_cfg{id= shangjin_refresh_cost, data = Data}) ->
    ?check(is_list(Data), "misc.txt中 [shangjin_refresh_cost:~w]配置无效。", [Data]),
    ok;

verify(#misc_cfg{id = skill_mp_cost, data = _Data}) ->
    ok;

verify(#misc_cfg{id = attr_times_by_player_num, data = Data}) ->
    ?check(is_list(Data), "misc.txt中 [attr_times_by_player_num:~w]配置无效。", [Data]),
    ok;

verify(#misc_cfg{id = nine_lottery_cost, data = Data}) ->
    ?check(is_list(Data), "misc.txt中 [nine_lottery_cost:~w]配置无效。", [Data]),
    ok;

verify(#misc_cfg{id = nine_lottery_accumulat_pro, data = Data}) ->
    ?check(is_tuple(Data), "misc.txt中 [nine_lottery_accumulat_pro:~w]配置无效。", [Data]),
    ok;

verify(#misc_cfg{id = nine_lottery_sup_prize_pro, data = Data}) ->
    ?check(is_list(Data), "misc.txt中 [nine_lottery_sup_prize:~w]配置无效。", [Data]),
    ok;

verify(#misc_cfg{id = nine_lottery_max_num, data = [Val1, _Val2]}) ->
    ?check(not(Val1 =:= 0), "misc.txt中 [nine_lottery_max_num:~w]配置无效。", [Val1]),
    ok;


verify(#misc_cfg{id = xilian_cost, data = CostList}) ->
    lists:foreach
    (
        fun({Num, CostId}) ->
            ?check(cost:is_exist_cost_cfg(CostId), "misc.txt xilian_cost [~p] costId:~p 在配置表cost.txt中没找到", [{Num, CostId}, CostId])
        end,
        CostList
    ),
    ok;

verify(#misc_cfg{id = level_crown_skill, data = Data}) ->
    ?check(is_integer(Data), "misc.txt中 [level_crown_skill:~w]配置无效。", [Data]),
    ok;

verify(#misc_cfg{id = xilian_id, data = Data}) ->
    ?check(load_item:is_exist_item_cfg(Data), "misc.txt中 [xilian_id:~w]配置无效。", [Data]),
    ok;

verify(#misc_cfg{id = daily_activity_time, data = Data}) ->
    ?check(is_list(Data), "misc.txt中 [daily_activity_time:~w]配置无效。", [Data]),
    ok;

verify(#misc_cfg{id = pata_cost, data = Data}) ->
    ?check(is_list(Data), "misc.txt中 [pata_cost:~w]配置无效。", [Data]),
    ok;

verify(#misc_cfg{id = arena_flush_cost, data = Data}) ->
    ?check(is_tuple(Data), "misc.txt中 [arena_flush_cost:w]配置无效。", [Data]),
    ok;

verify(#misc_cfg{id = buy_sp_limit, data = Data}) ->
    ?check(is_integer(Data), "misc.txt中 [buy_sp_limit:~w]配置无效。", [Data]),
    ok;


verify(#misc_cfg{id = equip_jd_attr_range, data = Data}) ->
    ?check(is_list(Data), "misc.txt 中 [equip_jd_attr_range:~w]配置无效", [Data]),
    ok;

verify(#misc_cfg{id = equip_qianghua_quality, data = Data}) ->
    ?check(is_list(Data), "misc.txt 中 [equip_qianghua_quality:~w]配置无效", [Data]),
    ok;

verify(#misc_cfg{id = zuiqiang_rank_shop_count, data = Data}) ->
    ?check(is_list(Data), "misc.txt 中 [equip_qianghua_quality:~w]配置无效", [Data]),
    ok;

verify(#misc_cfg{id = survey_prize, data = _}) ->
    ok;

verify(#misc_cfg{id = sp_time, data = Data}) ->
    ?check(is_tuple(Data), "misc.txt中 [sp_time:w]配置无效。", [Data]),
    ok;

verify(#misc_cfg{id = share_prize, data = Data}) ->
    ?check(is_integer(Data), "misc.txt中 [share_prize:w]配置无效。", [Data]),
    ok;

verify(#misc_cfg{id = mining_cost, data = Data}) ->
    ?check(is_list(Data), "misc.txt 中 [mining_cost:~w]配置无效", [Data]),
    ok;

verify(#misc_cfg{id = fish_count, data = Data}) ->
    ?check(is_tuple(Data), "misc.txt中 [fish_count:w]配置无效。", [Data]),
    ok;

verify(#misc_cfg{id = guild_saint_pro, data = Data}) ->
    ?check(is_list(Data), "misc.txt中 [guild_saint_pro:w]配置无效。", [Data]),
    ok;

verify(#misc_cfg{id = guild_saint_touch, data = Data}) ->
    ?check(is_list(Data), "misc.txt中 [guild_saint_touch:w]配置无效。", [Data]),
    ok;

verify(#misc_cfg{id = guild_max_lv, data = Data}) ->
    ?check(is_integer(Data), "misc.txt中 [guild_max_lv:w]配置无效。", [Data]),
    ok;

verify(#misc_cfg{id = Id}) ->
    %% client_xxxx 是前台的
    case lists:prefix("client_", erlang:atom_to_list(Id)) of
        true ->
            ok;
        _ ->
            ?ERROR_LOG("无效 misc cfg ~p ", [Id]),
            exit(bad)
    end.

check_sky_ins_cost({ItemBid, Num}) ->
    ItemType = load_item:get_type(ItemBid),
    if
        ItemType =:= ?ITEM_TYPE_RAND_INS, Num > 0, is_integer(Num) ->
            ?true;
        ?true -> ?false
    end.



