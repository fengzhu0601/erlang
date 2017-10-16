%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 27. 六月 2015 下午6:30
%%%-------------------------------------------------------------------
-module(load_vip_right).
-author("clark").

%% API
% -export([
%     get_need_diamond/2,
%     get_need_diamond/3,
%     get_value_lenght/1, % 获取总次数
%     get_value/1,       % 获取字段的值
%     get_alchemy_count/1,
%     get_course_boss_count/1,
%     get_free_times/1,
%     can_clean_main_ins/1,    %能否扫荡副本
%     get_main_ins_shop_times_count/1,
%     get_course_boss_flush_count/1,
%     get_vip_lock_attr_count/1,
%     get_abyss_integral_by_vip/1
% ]).


% -include("inc.hrl").
% -include_lib("config/include/config.hrl").
% -include("load_vip_right.hrl").


% get_alchemy_count(VipLevel) ->
%     case load_vip_right:lookup_vip_right_cfg(VipLevel) of
%         ?none ->
%             ?none;
%         Cfg ->
%             Cfg#vip_right_cfg.alchemy_cost_diamond
%     end.

% get_course_boss_count(VipLevel) ->
%     case load_vip_right:lookup_vip_right_cfg(VipLevel) of
%         ?none ->
%             ?none;
%         Cfg ->
%             Cfg#vip_right_cfg.boos_challenges
%     end.

% get_course_boss_flush_count(VipLevel) ->
%     case load_vip_right:lookup_vip_right_cfg(VipLevel) of
%         ?none ->
%             ?none;
%         Cfg ->
%             Cfg#vip_right_cfg.boss_challenge_flush
%     end.

% get_main_ins_shop_times_count(VipLevel) ->
%     case load_vip_right:lookup_vip_right_cfg(VipLevel) of
%         ?none ->
%             ?none;
%         Cfg ->
%             Cfg#vip_right_cfg.main_ins_shop_times
%     end.


% load_config_meta() ->
%     [
%         #config_meta{
%             record = #vip_right_cfg{},
%             fields = ?record_fields(vip_right_cfg),
%             file = "vip_right.txt",
%             keypos = #vip_right_cfg.id,
%             verify = fun verify/1}
%     ].

% verify(#vip_right_cfg{id = Id, base_diamond = BaseDiamond, vip_prize_id = VipPrizeId, auto_fight_limit = AutoFightLimit,
%     buy_power_limit = BuyPowerLimit}) ->
%     ?check(BaseDiamond >= 0, "vip_right.txt中， [~p] base_diamond: ~p 配置无效。", [Id, BaseDiamond]),
%     ?check(VipPrizeId =:= 0 orelse prize:is_exist_prize_cfg(VipPrizeId), "vip_right.txt中， [~p] vip_prize_id: ~p 配置无效。", [Id, VipPrizeId]),
%     ?check(AutoFightLimit =:= 0 orelse AutoFightLimit =:= 1, "vip_right.txt中， [~p] auto_fight_limit: ~p 配置无效。", [Id, AutoFightLimit]),
%     ?check(BuyPowerLimit > 0, "vip_right.txt中， [~p] buy_power_limit: ~p 配置无效。", [Id, BuyPowerLimit]),
%     ok.



% %% 获得第count次转盘抽奖时所需的钻石
% get_need_diamond(Vip, Count) ->
%     Cfg = load_vip_right:lookup_vip_right_cfg(Vip),
%     case Cfg of
%         #vip_right_cfg{dial_prize_diamond = DiamondList} ->
%             case lists:nth(Count, DiamondList) of
%                 none ->
%                     -1;
%                 Diamond ->
%                     Diamond
%             end;
%         _ ->
%             -1
%     end.

% get_need_diamond(Vip, TableFiled, Count) ->
%     case load_vip_right:lookup_vip_right_cfg(Vip, TableFiled) of
%         DiamondList when is_list(DiamondList) ->
%             case lists:nth(Count, DiamondList) of
%                 ?none -> ?none;
%                 Diamond -> Diamond
%             end;
%         _ ->
%             ?none
%     end.

% get_free_times(List) ->
%     do_get_free_times(List, 0).
% do_get_free_times([], Num) ->
%     Num;
% do_get_free_times([0|T], Num) ->
%     do_get_free_times(T, Num + 1);
% do_get_free_times([H|T], Num) ->
%     do_get_free_times(T, Num).

% get_value(TableFiled) ->
%     load_vip_right:lookup_vip_right_cfg(attr_new:get_vip_lvl(), TableFiled).
% get_value_lenght(TableFiled) ->
%     length(load_vip_right:lookup_vip_right_cfg(attr_new:get_vip_lvl(), TableFiled)).

% %% 当前vip等级能否扫荡副本
% can_clean_main_ins(VipLevel) ->
%     case load_vip_right:lookup_vip_right_cfg(VipLevel) of
%         ?none ->
%             ?FALSE;
%         Cfg ->
%             Cfg#vip_right_cfg.auto_fight_limit
%     end.

% %% 根据vip等级获取装备合成时可选择锁定的属性条数
% get_vip_lock_attr_count(VipLevel) ->
%     case lookup_vip_right_cfg(VipLevel) of
%         #vip_right_cfg{equipcompound_locknum = CountList} ->
%             CountList;
%         _ ->
%             ret:error(unknowType)
%     end.

% %% 根据Vip获得虚空深渊积分加成
% get_abyss_integral_by_vip(VipLevel) ->
%     case lookup_vip_right_cfg(VipLevel) of
%         #vip_right_cfg{abyss_integral = AbyssIntegral} ->
%             AbyssIntegral;
%         _ ->
%             ret:error(unknowType)
%     end.
