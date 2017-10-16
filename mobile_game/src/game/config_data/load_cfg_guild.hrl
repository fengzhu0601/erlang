%%%-------------------------------------------------------------------
%%% @author fengzhu
%%% @copyright (C) 2016, <COMPANY>
%%% @doc 玩家公会模块
%%%
%%% @end
%%% Created : 05. 一月 2016 下午5:31
%%%-------------------------------------------------------------------
-author("fengzhu").

%% 公会成员升级配置表
-record(guild_member_lvup_cfg, {
  lv,           %会员等级
  member_lv,    %会员type
  exp           %升级到下一级所需经验
}).

-record(guild_tech_cfg, {
  id,
  tech_type_id,  %科技类型ID
  lv,            %科技等级,从0级开始
  reward = [],     %升级到本级奖励[]
  condition = [],  %升级到下一级所需条件[{buildingTypeId,lv(建筑等级)}]
  update_cost       %[{Type::货币类型, Coin::货币数量}]
}).

%% 公会建筑配置表
-record(guild_buildings_cfg, {
  id,
  building_type_id, %建筑类型ID
  lv,               %建筑等级
  need_exp,         %升级到下一级所需经验
  reward = [],        %升级到本级奖励 [{1, 30}] 该公会等级下，公会最大总人数30人
  need_guild_lv = 0,  %升级到下一级所需公会等级
  daily_task_totlecount,  %该建筑每日提升贡献值总次数
  update_cost       %[{Type::货币类型, Coin::货币数量, Promotion::贡献值}]
}).

%% 公会商店物品列表
-record(guild_shop_cfg, {
  id = 0,  %售卖id（由策划确定）
  item_bid = 0,  %物品bid
  money_type = 0,  %货币类型
  price = 0,  %购买价格
  buy_condition = [] %购买条件[{1::玩家公会等级, 9}, {2::玩家公会贡献值, 5000}, {3::公会等级}]
}).