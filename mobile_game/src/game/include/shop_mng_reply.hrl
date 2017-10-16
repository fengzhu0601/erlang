%% 商店模块回复码定义
%%----------------------------------------------------
%% ?MSG_SHOP_BUY  购买物品
-define(REPLY_MSG_SHOP_BUY_OK, 0).   %% 购买物品成功
-define(REPLY_MSG_SHOP_BUY_1, 1).   %% 钻石不足
-define(REPLY_MSG_SHOP_BUY_2, 2).   %% 金币不足
-define(REPLY_MSG_SHOP_BUY_3, 3).   %% 背包已满
-define(REPLY_MSG_SHOP_BUY_4, 4).   %% 限时物品时间未到
-define(ERPLY_MSG_SHOP_BUY_5, 5).   %% count is not enough
-define(REPLY_MSG_SHOP_BUY_255, 255). %% 购买物品失败，请重试。重试失败，请联系GM。

%%----------------------------------------------------
%% ?MSG_SHOP_SELL  出售物品
-define(REPLY_MSG_SHOP_SELL_OK, 0).   %% 出售物品成功
-define(REPLY_MSG_SHOP_SELL_1, 1).   %% 绑定物品不能出售
-define(REPLY_MSG_SHOP_SELL_255, 255). %% 出售物品失败，请重试。重试失败，请联系GM。


%%----------------------------------------------------
%% ?MSG_SHOP_BUY_BACK 回购物品
-define(REPLY_MSG_SHOP_BUY_BACK_OK, 0).   %% 回购物品成功
-define(REPLY_MSG_SHOP_BUY_BACK_1, 1).   %% 钻石不足
-define(REPLY_MSG_SHOP_BUY_BACK_2, 2).   %% 金币不足
-define(REPLY_MSG_SHOP_BUY_BACK_3, 3).   %% 背包已满
-define(REPLY_MSG_SHOP_BUY_BACK_255, 255). %% 回购物品失败，请重试。重试失败，请联系GM。
