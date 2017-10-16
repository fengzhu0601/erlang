-define(pd_seller_count_down, pd_seller_count_down). %倒计时key值
-define(pd_seller_send_history, pd_seller_send_history).

-define(player_seller_tab, player_seller_tab).
-record(player_seller_tab, {
    player_id,
    seller_item_list = [],
    activation_time = 0,    %激活神秘商人时间戳
    refresh_time = 0        %下次刷新时间戳
}).

-define(player_shopping_history, player_shopping_history).
-record(player_shopping_history, {
    id = 1,
    seller_history = []    %[{time::时间戳,name,itemid,itemnum}]
}).

%%-define(seller_cfg, seller_cfg).
%%-record(seller_cfg, {
%%    id = 0,  %售卖id（由策划确定）
%%    item_bid = 0,  %物品bid
%%    money_type = 0,  %货币类型
%%    price = 0   %购买价格
%%}).
%%
%%-define(seller_refresh_cfg, seller_refresh_cfg).
%%-record(seller_refresh_cfg, {
%%    id = 0,
%%    lv_range = [],
%%    sellerIds_and_career = [] %[{career, [{itemid, weight}]}]
%%}).
