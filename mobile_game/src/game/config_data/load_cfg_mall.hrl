%%%-------------------------------------------------------------------
%%% @author fengzhu
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 04. 一月 2016 下午3:33
%%%-------------------------------------------------------------------
-author("fengzhu").

-record(mall_cfg,
{
  id = 0   %售卖id（由策划确定）
  , item_bid = 0    %物品bid
  , money_type = 0    %货币类型
  , rate = 100  %折扣比率（百分比
  , price = 0    %购买价格
  , time              %限购时间
  , label = []   %商品标签
  , number = 0   % 默认无限够
}).

-define(mall_cfg, mall_cfg).

-define(MALL_LABEL_TIME, 1).  %% 限时
-define(MALL_LABEL_NEW, 2).  %% 新品
-define(MALL_LABEL_RATE, 3).  %% 折扣
-define(MALL_LABEL_HOT, 4).  %% 热卖

-define(MALL_LABEL_ALL,
  [
    ?MALL_LABEL_TIME,
    ?MALL_LABEL_NEW,
    ?MALL_LABEL_RATE,
    ?MALL_LABEL_HOT,
    5
  ]
).

-define(system_mall, system_mall).
-record(system_mall, {
    id,
    number=0
}).
-define(player_mall_tab, player_mall_tab).
-record(player_mall_tab, {
    id,
    list=[]
}).

-define(pd_mall_list, pd_mall_list).