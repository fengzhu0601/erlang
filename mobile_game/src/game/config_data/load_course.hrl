
-record(course_cfg,{
    id,
    next_id,
    career,
    type,  
    prize_id,
    instance_id,
    state_id
}).

-record(boss_challenge_cfg,{
    id,
    type,
    ins_id,
    complete_conditions,                 
    prize_list,
    is_display
}).

-define(pd_course_boss_list, pd_course_boss_list).
-define(player_course_boss_tab, player_course_boss_tab).
-define(pd_course_count, pd_course_count).
-define(pd_course_buy_count, pd_course_buy_count).
-define(pd_course_new_boss_id, pd_course_new_boss_id).
-define(pd_course_flush_count, pd_course_flush_count).
-define(pd_course_current_list, pd_course_current_list).
-define(player_course_tab, player_course_tab).
-define(pd_course_data_list, pd_course_data_list).%% 记录战争学院普通副本的挑战信息
-define(pd_course_buy_flush_count, pd_course_buy_flush_count).  %% 购买刷新次数的累加
-record(player_course_boss_tab,
{
	id,
	count=0,                %% 已经挑战次数
	buy_count=0,            %% 已购买的挑战次数
	courseind_list=[],
    flush_count=0,          %% 已经刷新次数
    current_list = [],
    buy_flush_count = 0     %% 已购买的刷新次数
}).

-record(course_boss_prize, {
	id,
    boss_challenge_id,
	prize_id
}).


-record(player_course_tab, {
    id,
    list=[]
}).
