%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 26. 六月 2015 下午4:29
%%%-------------------------------------------------------------------
-author("clark").


-define(lvl_prize_state_len, 400).               %% 状态表字节空间 400 = 50*8

%% 等级奖励
-record(lvl_prize_cfg,
{
    %% 等级奖励ID
    id,

    %% 等级
    level,

    %% 开关
    state,

    %% 奖励
    prize_id
}).



