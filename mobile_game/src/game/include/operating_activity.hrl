-define(player_pc_prize_tab, player_pc_prize_tab).
-define(player_pc_goal_tab, player_pc_goal_tab).
-define(player_honest_user_tab, player_honest_user_tab).

-define(pd_pc_goal_list, pd_pc_goal_list).
-define(pd_pc_prize, pd_pc_prize).

-define(CANT_GET, 0).	% 不可领取
-define(CAN_GET, 1).	% 可领取
-define(HAS_GOT, 2).	% 已领取

-define(LEVEL_ACTIVITY_INDEX, 1).	% 等级活动索引
-define(SUIT_ACTIVITY_INDEX, 2).	% 套装活动索引

-define(GET_PRIZE_SUCC, 1).		% 领取成功
-define(GET_PRIZE_FAIL, 0).		% 领取失败

-record(player_honest_user_tab, {
	id,
	level_prize_state = 0,
	suit_prize_state = 0
}).

-record(player_pc_goal_tab, {
	id,
	list=[]
}).

-record(player_pc_prize_tab, {
	id,
	list=[]
}).
