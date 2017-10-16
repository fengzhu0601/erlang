-module(load_vip_new).

%% API
-export([
    get_vip_level_need_up_num/1,
    get_vip_cfg_by_vip_level/1,
    get_vip_gift_one_list/0,
    get_vip_buy_one_list/0,
    get_vip_buy_prize_by_viplevel/1,
    get_vip_gift_prize_by_viplevel/1,
    get_vip_day_gift_prize_by_viplevel/1,
    get_vip_new_need_diamond/3,
    get_vip_zuan_to_jin_by_vip_level/1,
    get_vip_arean_times_by_vip_level/1,
    get_vip_mining_count_by_vip_level/1,
    get_vip_course_times_by_vip_level/1,
    get_vip_pata_enter_times_and_reset_times_by_vip_level/1,
    get_vip_pata_integral_by_vip_level/1,
    get_vip_pata_zhekou_by_vip_level/1,
    is_yijian_saodang_by_vip_level/1,
    % is_renyu_sandang_by_vip_level/1,
    % is_shangnihao_sandang_by_vip_level/1,
    % is_shikong_sandang_by_vip_level/1,
    get_daily_activity1_sweep_info_by_vip_level/1,
    get_daily_activity2_sweep_info_by_vip_level/1,
    get_daily_activity3_sweep_info_by_vip_level/1,
    get_daily_activity4_sweep_info_by_vip_level/1,
    get_daily_activity5_sweep_info_by_vip_level/1,
    get_vip_zhuan_pan_times_by_vip_level/2,
    get_vip_boss_challenge_flush_by_vip_level/1,
    get_vip_main_ins_shop_times_by_vip_level/1,
    get_vip_lock_attr_count_by_level/1,
    get_vip_sp_by_vip_level/1,
    get_vip_new_free_times/1,
    get_long_wen_num_by_vip_level/1,
    get_vip_buy_gift_cost_by_vip_level/1,
    is_can_clean_main_ins_of_saodang/1,
    is_saodang_by_vip_level/1,
    get_sp_limit_by_vip_level/1,
    get_reset_instance_times_of_normal_by_vip_level/1,
    get_reset_instance_times_of_difficulty_by_vip_level/1,
    get_reset_instance_times_of_many_people_by_vip_level/1,
    get_vip_new_pay_times/1,
    get_vip_new_pay_list/1,
    get_daily_activity_1_by_vip_level/1,
    get_daily_activity_2_by_vip_level/1,
    get_daily_activity_3_by_vip_level/1,
    get_fish_net_count_by_vip_level/1
]).


-include("inc.hrl").
-include_lib("config/include/config.hrl").
-include("load_vip_new_cfg.hrl").

%% 挑战次数
get_reset_instance_times_of_normal_by_vip_level(VipLevel) ->
    case lookup_vip_cfg(VipLevel) of
        ?none ->
            [];
        #vip_cfg{reset_instance_times_of_normal = Normal} ->
            Normal
    end.

get_reset_instance_times_of_difficulty_by_vip_level(VipLevel) ->
    case lookup_vip_cfg(VipLevel) of
        ?none ->
            [];
        #vip_cfg{reset_instance_times_of_difficulty = Difficulty} ->
            Difficulty
    end.

get_reset_instance_times_of_many_people_by_vip_level(VipLevel) ->
    case lookup_vip_cfg(VipLevel) of
        ?none ->
            [];
        #vip_cfg{reset_instance_times_of_many_people = ManyPeople} ->
            ManyPeople
    end.

get_daily_activity_1_by_vip_level(VipLevel) ->
    case lookup_vip_cfg(VipLevel) of
        ?none ->
            [];
        #vip_cfg{daily_activity_1 = DailyActivity1} ->
            DailyActivity1
    end.

get_daily_activity_2_by_vip_level(VipLevel) ->
    case lookup_vip_cfg(VipLevel) of
        ?none ->
            [];
        #vip_cfg{daily_activity_2 = DailyActivity2} ->
            DailyActivity2
    end.

get_daily_activity_3_by_vip_level(VipLevel) ->
    case lookup_vip_cfg(VipLevel) of
        ?none ->
            [];
        #vip_cfg{daily_activity_3 = DailyActivity3} ->
            DailyActivity3
    end.

%% 扫荡一次功能
is_saodang_by_vip_level(VipLevel) ->
    case lookup_vip_cfg(VipLevel) of
        #vip_cfg{auto_saodang=1} ->
            ?true;
        _ ->
            ?false
    end.

%% 一键扫荡十次功能开启
is_yijian_saodang_by_vip_level(VipLevel) ->
    case lookup_vip_cfg(VipLevel) of
        #vip_cfg{yijian_saodang=1} ->
            ?true;
        _ ->
            ?false
    end.

% %% 桑尼号功能开启（0未开启，1开启）
% is_shangnihao_sandang_by_vip_level(VipLevel) ->
%     case lookup_vip_cfg(VipLevel) of
%         #vip_cfg{daily_activity2_times=1} ->
%             ?true;
%         _ ->
%             ?false
%     end.
% %% 人鱼扫荡功能开启（0未开启，1开启）
% is_renyu_sandang_by_vip_level(VipLevel) ->
%     case lookup_vip_cfg(VipLevel) of
%         #vip_cfg{daily_activity1_times=1} ->
%             ?true;
%         _ ->
%             ?false
%     end.
% %% 时空裂缝功能开启（0未开启，1开启）
% is_shikong_sandang_by_vip_level(VipLevel) ->
%     case lookup_vip_cfg(VipLevel) of
%         #vip_cfg{daily_activity3_times=1} ->
%             ?true;
%         _ ->
%             ?false
%     end.

get_daily_activity1_sweep_info_by_vip_level(VipLevel) ->
    case lookup_vip_cfg(VipLevel) of
        ?none ->
            ?none;
        #vip_cfg{daily_activity1_sweep_info = Cost} ->
            Cost
    end.

get_daily_activity2_sweep_info_by_vip_level(VipLevel) ->
    case lookup_vip_cfg(VipLevel) of
        ?none ->
            ?none;
        #vip_cfg{daily_activity2_sweep_info = Cost} ->
            Cost
    end.

get_daily_activity3_sweep_info_by_vip_level(VipLevel) ->
    case lookup_vip_cfg(VipLevel) of
        ?none ->
            ?none;
        #vip_cfg{daily_activity3_sweep_info = Cost} ->
            Cost
    end.

get_daily_activity4_sweep_info_by_vip_level(VipLevel) ->
    case lookup_vip_cfg(VipLevel) of
        ?none ->
            ?none;
        #vip_cfg{daily_activity4_sweep_info = Cost} ->
            Cost
    end.

get_daily_activity5_sweep_info_by_vip_level(VipLevel) ->
    case lookup_vip_cfg(VipLevel) of
        ?none ->
            ?none;
        #vip_cfg{daily_activity5_sweep_info = Cost} ->
            Cost
    end.

get_vip_new_free_times(List) ->
    do__vip_new_get_free_times(List, 0).
do__vip_new_get_free_times([], Num) ->
    Num;
do__vip_new_get_free_times([0|T], Num) ->
    do__vip_new_get_free_times(T, Num + 1);
do__vip_new_get_free_times([_H|T], Num) ->
    do__vip_new_get_free_times(T, Num).

get_vip_new_pay_times(List) ->
    do__vip_new_get_pay_times(List, 0).
do__vip_new_get_pay_times([], Num) ->
    Num;
do__vip_new_get_pay_times([0|T], Num) ->
    do__vip_new_get_pay_times(T, Num);
do__vip_new_get_pay_times([H|T], Num) ->
    do__vip_new_get_pay_times(T, Num + 1).

get_vip_new_pay_list(List) ->
    do__vip_new_get_pay_list(List, []).
do__vip_new_get_pay_list([], L) ->
    lists:reverse(L);
do__vip_new_get_pay_list([0|T], L) ->
    do__vip_new_get_pay_list(T, L);
do__vip_new_get_pay_list([H|T], L) ->
    do__vip_new_get_pay_list(T, [H|L]).

%% 初始化没等级vip购买和领取的数据
get_vip_gift_one_list() ->
    List = com_ets:keys(vip_cfg),
    InitStatus = lists:duplicate(length(List),0),
    NewL = lists:zip(List, InitStatus),
    lists:keyreplace(0, 1, NewL, {0, 1}).

get_vip_buy_one_list() ->
    List = com_ets:keys(vip_cfg),
    InitStatus = lists:duplicate(length(List),0),
    lists:zip(List, InitStatus).

get_vip_buy_prize_by_viplevel(VipLevel) ->
    case lookup_vip_cfg(VipLevel) of
        ?none ->
            0;
        #vip_cfg{vip_buy_gift=PrizeId} ->
            PrizeId
    end.

get_vip_gift_prize_by_viplevel(VipLevel) ->
    case lookup_vip_cfg(VipLevel) of
        ?none ->
            0;
        #vip_cfg{vip_gift=PrizeId} ->
            PrizeId
    end.

get_vip_day_gift_prize_by_viplevel(VipLevel) ->
    case lookup_vip_cfg(VipLevel) of
        ?none ->
            0;
        #vip_cfg{vip_day_gift=PrizeId} ->
            PrizeId
    end.


get_vip_cfg_by_vip_level(VipLevel) ->
    case lookup_vip_cfg(VipLevel) of
        ?none ->
            ?none;
        Cfg ->
            Cfg
    end.

get_vip_zuan_to_jin_by_vip_level(VipLevel) ->
    case lookup_vip_cfg(VipLevel) of
        ?none ->
            ?none;
        #vip_cfg{zuan_to_jin=List} ->
            List
    end.

get_vip_course_times_by_vip_level(VipLevel) ->
    case lookup_vip_cfg(VipLevel) of
        ?none ->
            [];
        #vip_cfg{course_times=List} ->
            List
    end.

%% 根据Vip等级获取可购买的公会挖矿次数
get_vip_mining_count_by_vip_level(VipLevel) ->
    case lookup_vip_cfg(VipLevel) of
        ?none ->
            [];
        #vip_cfg{mining_count=List} ->
            List
        end.

get_vip_arean_times_by_vip_level(VipLevel) ->
    case lookup_vip_cfg(VipLevel) of
        ?none ->
            [];
        #vip_cfg{buy_arena=List} ->
            List
    end.

get_vip_pata_enter_times_and_reset_times_by_vip_level(VipLevel) ->
    case lookup_vip_cfg(VipLevel) of
        ?none ->
            {[], []};
        #vip_cfg{pata_enter_times=List, pata_reset_times=L2} ->
            {List, L2}
    end.

%% 根据Vip获得虚空深渊积分加成
get_vip_pata_integral_by_vip_level(VipLevel) ->
    case lookup_vip_cfg(VipLevel) of
        #vip_cfg{pata_integral = AbyssIntegral} ->
            AbyssIntegral;
        _ ->
            0
    end.
%% 爬塔扫荡折扣
get_vip_pata_zhekou_by_vip_level(VipLevel) ->
    case lookup_vip_cfg(VipLevel) of
        #vip_cfg{pata_zhekou = N} ->
            N;
        _ ->
            0
    end.

get_vip_buy_gift_cost_by_vip_level(VipLevel) ->
    case lookup_vip_cfg(VipLevel) of
        #vip_cfg{vip_buy_gift_cost = N} ->
            N;
        _ ->
            0
    end.

%% 根据vip等级获取装备合成时可选择锁定的属性条数
get_vip_lock_attr_count_by_level(VipLevel) ->
    case lookup_vip_cfg(VipLevel) of
        #vip_cfg{equipcompound_locknum = List} ->
            List;
        _ ->
            []
    end.

get_vip_boss_challenge_flush_by_vip_level(VipLevel) ->
    case lookup_vip_cfg(VipLevel) of
        ?none ->
            [];
        #vip_cfg{boss_challenge_flush = List} ->
            List
    end.

get_vip_main_ins_shop_times_by_vip_level(VipLevel) ->
    case lookup_vip_cfg(VipLevel) of
        ?none ->
            ?none;
        #vip_cfg{main_ins_shop_times = List} ->
            List
    end.

get_vip_sp_by_vip_level(VipLevel) ->
    case lookup_vip_cfg(VipLevel) of
        ?none ->
            [];
        #vip_cfg{buy_sp = List} ->
            List
    end.


%% 获得第count次转盘抽奖时所需的钻石
get_vip_zhuan_pan_times_by_vip_level(VipLevel, Count) ->    
    case lookup_vip_cfg(VipLevel) of
        #vip_cfg{zhuan_pan_times=List} ->
            case lists:nth(Count, List) of
                none ->
                    -1;
                Diamond ->
                    Diamond
            end;
        _ ->
            -1
    end.

%% 当前vip等级能否扫荡副本
is_can_clean_main_ins_of_saodang(VipLevel) ->
    case lookup_vip_cfg(VipLevel) of
        ?none ->
            ?FALSE;
        Cfg ->
            Cfg#vip_cfg.auto_saodang
    end.

get_vip_level_need_up_num(VipLevel) ->
    case lookup_vip_cfg(VipLevel) of
        ?none ->
            ?none;
        #vip_cfg{need_up_num=Num} ->
            Num
    end.


get_vip_new_need_diamond(Vip, TableFiled, Count) ->
    case lookup_vip_cfg(Vip, TableFiled) of
        DiamondList when is_list(DiamondList) ->
            case lists:nth(Count, DiamondList) of
                ?none -> ?none;
                Diamond -> Diamond
            end;
        _ ->
            ?none
    end.

get_long_wen_num_by_vip_level(VipLevel) ->
    case lookup_vip_cfg(VipLevel) of
        #vip_cfg{long_wen_num=Num} ->
            Num;
        _ ->
            0
    end.

get_sp_limit_by_vip_level(VipLevel) ->
    case lookup_vip_cfg(VipLevel) of
        #vip_cfg{sp_limit = Num} ->
            Num;
        _ ->
            0
    end.

get_fish_net_count_by_vip_level(VipLevel) ->
    case lookup_vip_cfg(VipLevel) of
        ?none ->
            [];
        #vip_cfg{fish_net_count = List} ->
            List
    end.

load_config_meta() ->
    [
        #config_meta{
            record = #vip_cfg{},
            fields = ?record_fields(vip_cfg),
            file = "vip.txt",
            keypos = #vip_cfg.id,
            verify = fun verify/1,
            is_compile = true}
    ].


verify(#vip_cfg{id = Id, need_up_num = NeedUpNum, buy_sp = BuySp, zuan_to_jin = ZuanToJin,
    buy_arena = BuyArena,reset_instance_times_of_normal = Riton, reset_instance_times_of_difficulty = Ritod, reset_instance_times_of_many_people = Ritom,
    daily_activity_1 = Bdat, mining_count = MiningCount, fish_net_count = FishNetCount, course_times = CourseTimes, guild_mobai_times = GuildMobaiTimes,tuhao_mobai = TuHaoMoBai,
    pata_enter_times = PataTimes, daily_activity1_sweep_info = DailyAt,long_wen_num=Lwn,vip_gift=VipGift,
    vip_buy_gift=VipBuyGift,vip_day_gift=VipDayGift}) ->
    ?check(NeedUpNum >= 0, "vip.txt中， [~p] need_up_num~p 配置无效。", [Id, NeedUpNum]),
    ?check(is_list(BuySp), "vip.txt中， [~p] buy_sp~p 配置无效。", [Id, BuySp]),
    ?check(is_list(ZuanToJin), "vip.txt中， [~p] zuan_to_jin~p 配置无效。", [Id, ZuanToJin]),
    ?check(is_list(BuyArena), "vip.txt中， [~p] buy_arena~p 配置无效。", [Id, BuyArena]),
    ?check(is_list(Riton), "vip.txt中， [~p] reset_instance_times_of_normal~p 配置无效。", [Id, Riton]),
    ?check(is_list(Ritod), "vip.txt中， [~p] reset_instance_times_of_difficulty~p 配置无效。", [Id, Ritod]),
    ?check(is_list(Ritom), "vip.txt中， [~p] reset_instance_times_of_many_people~p 配置无效。", [Id, Ritom]),
    ?check(is_list(Bdat), "vip.txt中， [~p] daily_activity_1~p 配置无效。", [Id, Bdat]),
    ?check(is_list(MiningCount), "vip.txt中， [~p] mining_count~p 配置无效。", [Id, MiningCount]),
    ?check(is_list(FishNetCount), "vip.txt中， [~p] fish_net_count~p 配置无效。", [Id, FishNetCount]),

    ?check(is_list(MiningCount), "vip.txt中， [~p] mining_count~p 配置无效。", [Id, MiningCount]),
    ?check(is_list(CourseTimes), "vip.txt中， [~p] course_times~p 配置无效。", [Id, CourseTimes]),
    ?check(is_list(GuildMobaiTimes), "vip.txt中， [~p] guild_mobai_times~p 配置无效。", [Id, GuildMobaiTimes]),

    ?check(TuHaoMoBai >= 0, "vip.txt中， [~p] tuhao_mobai~p 配置无效。", [Id, TuHaoMoBai]),


    ?check(is_list(PataTimes), "vip.txt中， [~p] pata_enter_times~p 配置无效。", [Id, PataTimes]),

    ?check(DailyAt >= 0, "vip.txt中， [~p] daily_activity_times~p 配置无效。", [Id, DailyAt]),



    ?check(Lwn >= 0, "vip.txt中， [~p] long_wen_num~p 配置无效。", [Id, Lwn]),

    ?check(VipGift =:= 0 orelse prize:is_exist_prize_cfg(VipGift), "vip.txt中， [~p] vip_gift: ~p 配置无效。", [Id, VipGift]),
    ?check(VipBuyGift =:= 0 orelse prize:is_exist_prize_cfg(VipBuyGift), "vip.txt中， [~p] vip_buy_gift: ~p 配置无效。", [Id, VipBuyGift]),
    ?check(VipDayGift =:= 0 orelse prize:is_exist_prize_cfg(VipDayGift), "vip.txt中， [~p] vip_day_gift: ~p 配置无效。", [Id, VipDayGift]),
    ok.