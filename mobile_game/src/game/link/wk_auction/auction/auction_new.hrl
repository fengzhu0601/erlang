%%%-------------------------------------------------------------------
%%% @author lan
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 13. 九月 2016 下午6:41
%%%-------------------------------------------------------------------
-author("lan").



%% 拍卖行的拍卖信息结构
-define(com_auction_new_tab, com_auction_new_tab).
-record(com_auction_new_tab,{
	id = 0,                  %% 拍卖id(配置表中的索引id)
	item_state = 1,        %% 物品的拍卖状态（1，正在拍卖中， 0已经被经被卖掉，一口价）
	ver = 0,               %% 版本号,用于数据升级
	item = undefined,      %% 物品             #item_new{} | {Bid, Count}
	item_type = 0,         %% 物品类型
	seller,                %% 物品出售者name

	money_type = 0,        %% 货币类型
	start_price = 0,       %% 起拍价格
	high_price = 0,        %% 一口价
	step_price = 0,        %% 最小单位的计算价格（最少加价）

	cur_price = 0,         %% 当前价格
	bider_id = 0,          %% 竞拍人
	fee_rate = 0          %% 当被新增拍卖者的价格超过时，原拍卖者的钱按照此比率退回（千分比）
}).

%% 拍卖行的日志信息
-define(auction_log_tab, auction_log_tab).
-record(auction_log_tab,
{
	id = 0,                 %% 拍卖id
	playerId = 0,           %% 拍下物品的玩家id
	itemId = 0,               %% 拍下物品
	money_type = 0,         %% 拍卖时使用的货币类型
	owner_name = [],        %% 物品拥有者名字
	price = 0,              %% 价格
	datetime = 0,           %% 参加竞拍的时间
	payType = 0             %% 支付类型（1 一口价， 0 最高价）
}).

%% 拍卖物品的两种状态
-define(item_auction_ed, 0).			%% 不能被拍卖
-define(item_auction_ing, 1).			%% 正在被拍卖

