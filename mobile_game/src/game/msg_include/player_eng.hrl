%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 18. 一月 2016 下午5:44
%%%-------------------------------------------------------------------
-author("clark").




%% 删除玩家进程
-define(player_eng_delete, player_eng_delete).
-record(player_eng_delete,
{
    reason             = 0
}).



%% 玩家数据
-define(player_eng_msg, player_eng_msg).
-record(player_eng_msg,
{
    msg             = 0
}).

%% 拍卖行日志
-define(auction_timeout_msg, auction_timeout_msg).
-record(auction_timeout_msg,
{
    item,                   %% 拍卖的物品
    price,                  %% 物品的价格
    sellerId                %% 物品拥有者id
}).