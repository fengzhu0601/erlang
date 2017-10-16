%%%-------------------------------------------------------------------
%%% @author lan
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 17. 十月 2016 下午2:26
%%%-------------------------------------------------------------------
-author("lan").


-define(player_server_login_prize_tab, player_server_login_prize_tab).
-record(player_server_login_prize_tab,
{
	id,
	get_prize_list = [],			%% [{day, state}, {天数， 领奖状态}]
	zero_time_of_day = 0,			%% 每天登录的零点时间
	login_day = 0					%% 记录玩家登录天数
}).

%% 玩家登录奖励的数据保存列表
-define(pd_server_login_prize_state_list, pd_server_login_prize_state_list).
-define(pd_player_login_server_day, pd_player_login_server_day).  %% 记录玩家登录天数
-define(pd_server_login_zero_time, pd_server_login_zero_time).

-define(no_get_prize, 0).		%% 没有被领奖
-define(can_get_prize, 1).		%% 可以被领奖
-define(is_get_prize, 2).		%% 已经被领奖


%% replyNum

-define(SERVER_LOGIN_GET_PRIZE_OK, 0).			%% 领奖成功
-define(SERVER_LOGIN_GET_PRIZE_1, 1).			%% 领奖天数未达到
-define(SERVER_LOGIN_GET_PRIZE_2, 2).			%% 没找到相关奖励
-define(SERVER_LOGIN_GET_PRIZE_3, 3).			%% 该天数对应的奖励已经领取
-define(SERVER_LOGIN_GET_PRIZE_255, 255).		%% 其它错误

