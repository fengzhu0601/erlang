%%%-------------------------------------------------------------------
%%% @author fengzhu
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 17. 六月 2016 下午4:42
%%%-------------------------------------------------------------------
-author("fengzhu").

%% 虚空深渊排行榜奖励
-record(abyss_integral_reward_cfg,
{
    id,                 %% id
    min_rank,        %% 最小排名
    max_rank,        %% 最大排名
    rewardId            %% 奖励ID
}).
