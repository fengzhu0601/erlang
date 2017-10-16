%%----------------------------------------------------
%% ?MSG_AUCTION_CREATE 创建竞拍回复码
-define(REPLY_MSG_AUCTION_CREATE_OK, 0).    %% 创建拍卖成功
-define(REPLY_MSG_AUCTION_CREATE_1, 1).    %% 当时拍卖超过上限
-define(REPLY_MSG_AUCTION_CREATE_2, 2).    %% 同时拍卖超过上限
-define(REPLY_MSG_AUCTION_CREATE_3, 3).    %% 拍卖行太忙
-define(REPLY_MSG_AUCTION_CREATE_4, 4).    %% 你的等级不够无法寄卖
-define(REPLY_MSG_AUCTION_CREATE_5, 5).    %% 起拍价超过了一口价
-define(REPLY_MSG_AUCTION_CREATE_6, 6).    %% 起拍价格太低啦
-define(REPLY_MSG_AUCTION_CREATE_7, 7).    %% 不能重新上架
-define(REPLY_MSG_AUCTION_CREATE_8, 8).    %% 花费不足
-define(REPLY_MSG_AUCTION_CREATE_9, 9).    %% 已绑定物品无法拍卖
-define(REPLY_MSG_AUCTION_CREATE_255, 255).  %% 创建拍卖失败，请重试。重试失败请联系GM。

%%----------------------------------------------------
%% ?MSG_AUCTION_PRICE 拍卖竞价
-define(REPLY_MSG_AUCTION_PRICE_OK, 0).   %% 竞价成功
-define(REPLY_MSG_AUCTION_PRICE_1, 1).   %% 加价幅度小于默认值
-define(REPLY_MSG_AUCTION_PRICE_2, 2).   %% 竞价时间已经截止（还有一分钟的时候就不给竞价了
-define(REPLY_MSG_AUCTION_PRICE_3, 3).   %% 您已经是最高竞价者了
-define(REPLY_MSG_AUCTION_PRICE_4, 4).   %% 钻石不足，无法竞价
-define(REPLY_MSG_AUCTION_PRICE_5, 5).   %% 您下手晚了，已经被别人拍走了
-define(REPLY_MSG_AUCTION_PRICE_255, 255). %% 竞价失败，请重试。重试失败，请联系GM

%%----------------------------------------------------
%% ?MSG_AUCTION_BACK_BAG 下架物品
-define(REPLY_MSG_AUCTION_BACK_BAG_OK, 0).   %% 下架物品成功
-define(REPLY_MSG_AUCTION_BACK_BAG_1, 1).   %% 下架物品失败，背包满
-define(REPLY_MSG_AUCTION_BACK_BAG_2, 2).   %% 下架物品失败，该物品不能下架
-define(REPLY_MSG_AUCTION_BACK_BAG_3, 3).   %% 下架物品失败，所下架物品不存在
-define(REPLY_MSG_AUCTION_BACK_BAG_255, 255). %% 下架物品失败，请重试。重试失败，请联系GM
