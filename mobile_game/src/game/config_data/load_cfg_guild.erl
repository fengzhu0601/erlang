%%%-------------------------------------------------------------------
%%% @author fengzhu
%%% @copyright (C) 2016, <COMPANY>
%%% @doc 玩家公会模块
%%%
%%% @end
%%% Created : 05. 一月 2016 下午5:31
%%%-------------------------------------------------------------------
-module(load_cfg_guild).
-author("fengzhu").

%% API
-export([
  lookup_cfg/1, lookup_cfg/2, lookup_cfg/3  % 获取公会中玩家配置信息
]).

-include_lib("config/include/config.hrl").
-include("inc.hrl").
-include("load_cfg_guild.hrl").
-include("guild_def.hrl").

load_config_meta() ->
  [
    #config_meta{record = #guild_member_lvup_cfg{},
      fields = ?record_fields(?guild_member_lvup_cfg),
      file = "guild_member.txt",
      keypos = #guild_member_lvup_cfg.lv,
      all = [#guild_member_lvup_cfg.lv],
      verify = fun verify_guild_member_lvup/1},

    #config_meta{record = #guild_tech_cfg{},
      fields = ?record_fields(?guild_tech_cfg),
      file = "guild_tech.txt",
      keypos = #guild_tech_cfg.id,
      all = [#guild_tech_cfg.id, #guild_tech_cfg.tech_type_id],
      verify = fun verify_guild_tech/1},

    #config_meta{record = #guild_buildings_cfg{},
      fields = ?record_fields(?guild_buildings_cfg),
      file = "guild_buildings.txt",
      keypos = #guild_buildings_cfg.id,
      all = [#guild_buildings_cfg.id, #guild_buildings_cfg.building_type_id],
      verify = fun verify_guild_buildings/1},

    #config_meta{record = #guild_shop_cfg{},
      fields = ?record_fields(?guild_shop_cfg),
      file = "guild_shop.txt",
      keypos = #guild_shop_cfg.id,
      verify = fun verify_guild_shop/1}
  ].

verify_guild_member_lvup(#guild_member_lvup_cfg{lv = Lv, member_lv = MemberLv, exp = Exp}) ->
  ?check((?is_pos_integer(Lv) and is_integer(MemberLv) and
    is_integer(Exp)), "guild_member_lvup_cfg.txt this record lv:[~w] 无效! ", [Lv]),
  ok.

verify_guild_tech(#guild_tech_cfg{id = Id, tech_type_id = TechTypeId, lv = Lv, reward = Reward,
  condition = Condition}) ->
  ?check((?is_pos_integer(Id) and
    ?is_pos_integer(TechTypeId) and
    is_integer(Lv) and
    is_integer(Reward) and
    is_list(Condition)), "guild_tech_cfg.txt this record id:[~w] 无效! ", [Id]),
  ok.

verify_guild_buildings(#guild_buildings_cfg{id = Id, building_type_id = BuildingType, lv = Lv, need_exp = NeedExp,
  reward = Reward, need_guild_lv = Condition, daily_task_totlecount = TotleCount}) ->
  ?check((?is_pos_integer(Id) and
    ?is_pos_integer(BuildingType) and
    ?is_pos_integer(Lv) and
    is_integer(NeedExp) and
    is_list(Reward) and
    is_integer(Condition) and
    ?is_pos_integer(TotleCount)), "guild_buildings.txt this record id:[~w] 无效! ", [Id]),
  ok.

verify_guild_shop(#guild_shop_cfg{id = Id, item_bid = ItemBid, money_type = MoneyType,
  price = Price, buy_condition = Condition}) ->
  ?check(com_util:is_valid_uint64(Id), "guild_shop.txt id [~w] 无效! ", [Id]),
  ?check(load_item:is_exist_item_attr_cfg(ItemBid), "guild_shop.txt id [~w] item_bid [~w] 物品不存在! ", [Id, ItemBid]),
  ?check(?is_pos_integer(MoneyType), "guild_shop.txt  id [~w]  money_type [~w] 无效  ", [Id, MoneyType]),
  ?check(com_util:is_valid_uint64(Price), "guild_shop.txt  id [~w]  price [~w] 无效  ", [Id, Price]),
  ?check(is_list(Condition), "guild_shop.txt  id [~w]  Condition [~w] 无效  ", [Id, Condition]),
  ok.

lookup_cfg(?guild_tech_cfg) ->
  [lookup_guild_tech_cfg(Id) || Id <- lookup_all_guild_tech_cfg(#guild_tech_cfg.id)];
lookup_cfg(?guild_buildings_cfg) ->
  [lookup_guild_buildings_cfg(Id) || Id <- lookup_all_guild_buildings_cfg(#guild_buildings_cfg.id)].

lookup_cfg(?guild_member_lvup_cfg, Key) when is_integer(Key) ->
  MaxLv = lists:max(lookup_all_guild_member_lvup_cfg(#guild_member_lvup_cfg.lv)),
  #guild_member_lvup_cfg{exp = Exp} = lookup_guild_member_lvup_cfg(Key),
  #guild_member_lvup_cfg{exp = MaxExp} = lookup_guild_member_lvup_cfg(MaxLv),
  {MaxLv, MaxExp, Exp};

lookup_cfg(?guild_tech_cfg, {TechType, Lv}) ->
  TechLvupCFG = lookup_cfg(?guild_tech_cfg),
  TechTypeList = [{LvCFG, RewardCFG, ConditionCFG, UpdateCostIDCFG} ||
    #guild_tech_cfg{tech_type_id = TypeCFG, lv = LvCFG, reward = RewardCFG, condition = ConditionCFG, update_cost = UpdateCostIDCFG}
      <- TechLvupCFG, TypeCFG =:= TechType],
  {MaxLv, _, _, _} = lists:max(TechTypeList),
  [{Reward, Condition, UpdateCostID}] = [{Reward1, Condition1, UpdateCost1} || {Lv1, Reward1, Condition1, UpdateCost1} <- TechTypeList, Lv1 =:= Lv],
  {MaxLv, Reward, Condition, UpdateCostID};

lookup_cfg(?guild_tech_cfg, #guild_tech_cfg.tech_type_id) ->
  lookup_all_guild_tech_cfg(#guild_tech_cfg.tech_type_id);

lookup_cfg(?guild_buildings_cfg, #guild_buildings_cfg.building_type_id) ->
  lookup_all_guild_buildings_cfg(#guild_buildings_cfg.building_type_id);

lookup_cfg(?guild_shop_cfg, Key) ->
  lookup_guild_shop_cfg(Key);

lookup_cfg(?guild_buildings_cfg, BuildingList) when is_list(BuildingList) ->
  BuildingsCFG = lookup_cfg(?guild_buildings_cfg),
  FunMap = fun({BuildingTypeId, BuildingLv, _BuildingExp}) ->
    [{Type, Count}] = [{BuildingType, DailyTotleCount} ||
      #guild_buildings_cfg{building_type_id = BuildingType, lv = Lv, daily_task_totlecount = DailyTotleCount}
        <- BuildingsCFG, BuildingType =:= BuildingTypeId, Lv =:= BuildingLv],
    {Type, Count}
           end,
  lists:map(FunMap, BuildingList);

lookup_cfg(?guild_buildings_cfg, {BuildingType, BuildingLv}) ->
  [{LvCFG, NeedExp, Reward, NeedGuildLv, DailyTotleCount, UpdateCost}
    || #guild_buildings_cfg{building_type_id = BuildingTypeCFG, lv = LvCFG, need_exp = NeedExp,
    reward = Reward, need_guild_lv = NeedGuildLv, daily_task_totlecount = DailyTotleCount,
    update_cost = UpdateCost}
    <- lookup_cfg(?guild_buildings_cfg), BuildingTypeCFG =:= BuildingType, LvCFG =:= BuildingLv];

lookup_cfg(?guild_buildings_cfg, {max, BuildingType, BuildingLv}) ->
  BuildingTypeList = [{LvCFG, NeedExp, Reward, NeedGuildLv, DailyTotleCount, UpdateCost}
    || #guild_buildings_cfg{building_type_id = BuildingTypeCFG, lv = LvCFG, need_exp = NeedExp,
      reward = Reward, need_guild_lv = NeedGuildLv, daily_task_totlecount = DailyTotleCount,
      update_cost = UpdateCost}
      <- lookup_cfg(?guild_buildings_cfg), BuildingTypeCFG =:= BuildingType],
  {MaxLv, MaxNeedExp, _MaxReward, _MaxNeedGuildLv, _MaxDailyTotleCount, _MaxUpdateCost} = lists:max(BuildingTypeList),
  [{LvCFG, NeedExp, Reward, NeedGuildLv, DailyTotleCount, UpdateCost}] =
    [{LvCFG_, NeedExp_, Reward_, NeedGuildLv_, DailyTotleCount_, UpdateCost_}
      || {LvCFG_, NeedExp_, Reward_, NeedGuildLv_, DailyTotleCount_, UpdateCost_}
      <- BuildingTypeList, LvCFG_ =:= BuildingLv],
  {MaxLv, MaxNeedExp, LvCFG, NeedExp, Reward, NeedGuildLv, DailyTotleCount, UpdateCost}.

lookup_cfg(?guild_member_lvup_cfg, Lv, "member_lv") ->
  case lookup_guild_member_lvup_cfg(Lv) of
    none -> 0;
    #guild_member_lvup_cfg{member_lv = MemLv} ->
      MemLv
  end.







