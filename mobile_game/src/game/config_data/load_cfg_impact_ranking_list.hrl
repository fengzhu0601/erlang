%%%-------------------------------------------------------------------
%%% @author fengzhu
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 23. 九月 2016 下午12:34
%%%-------------------------------------------------------------------
-author("fengzhu").

%% 战力王者排行榜奖励
-record(power_ranking_list_prize_cfg,
{
    id,                 %% id
    min_rank,        %% 最小排名
    max_rank,        %% 最大排名
    prize,            %% 奖励ID
    title           %% 称号
}).

%% 宠物王者排行榜奖励
-record(pet_ranking_list_prize_cfg,
{
    id,                 %% id
    min_rank,        %% 最小排名
    max_rank,        %% 最大排名
    prize,           %% 奖励ID
    title           %% 称号
}).

%% 坐骑王者排行榜奖励
-record(ride_ranking_list_prize_cfg,
{
    id,                 %% id
    min_rank,        %% 最小排名
    max_rank,        %% 最大排名
    prize,           %% 奖励ID
    title           %% 称号
}).

%% 套装王者排行榜奖励
-record(suit_ranking_list_prize_cfg,
{
    id,                 %% id
    min_rank,           %% 最小排名
    max_rank,           %% 最大排名
    prize,           %% 奖励ID
    title           %% 称号
}).

%% 深渊王者排行榜奖励
-record(abyss_ranking_list_prize_cfg,
{
    id,                 %% id
    min_rank,        %% 最小排名
    max_rank,        %% 最大排名
    prize,           %% 奖励ID
    title           %% 称号
}).

%% 公会王者排行榜奖励
-record(guild_ranking_list_prize_cfg,
{
    id,                 %% id
    min_rank,           %% 最小排名
    max_rank,           %% 最大排名
    prize_1,           %% 公会奖励
    prize_2,           %% 会长奖励
    prize_3,           %% 会员奖励
    title,           %% 称号
    server_prize      %% 服务器用的公会经验奖励
}).

%% 开服冲榜商店
-record(rank_shop_cfg,
{
    id,         %%id
    type,       %%类型
    prize,      %%道具内容
    cost        %%价格
}).
