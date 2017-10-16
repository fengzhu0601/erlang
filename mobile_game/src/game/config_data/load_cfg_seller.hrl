%%%-------------------------------------------------------------------
%%% @author fengzhu
%%% @copyright (C) 2016, <COMPANY>
%%% @doc 神秘商人
%%%
%%% @end
%%% Created : 04. 一月 2016 下午3:56
%%%-------------------------------------------------------------------
-author("fengzhu").

-define(seller_cfg, seller_cfg).
-record(seller_cfg,
{
  id = 0,  %售卖id（由策划确定）
  item_bid = 0,  %物品bid
  money_type = 0,  %货币类型
  price = 0   %购买价格
}).

-define(seller_refresh_cfg, seller_refresh_cfg).
-record(seller_refresh_cfg,
{
  id = 0,
  lv_range = [],
  sellerIds_and_career = [] %[{career, [{itemid, weight}]}]
}).

-define(SELLER_DEFAULT_ITEM_NUM, 6).     %默认发给前端的item数量
-define(SELLER_HISTORY_MAX_NUM, 60).     %购买历史记录条数
-define(PageMaxNum, 40).                 %购买历史记录一页数量
-define(SHOPPING_HISTORY_TABLE_KEY, 1).  %购买历史记录表默认key值