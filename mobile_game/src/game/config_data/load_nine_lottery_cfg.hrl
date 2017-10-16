-record(nine_lottery_per_day_prize_cfg, {
    id,
    nine_lottery_prize_list
}).

-record(nine_lottery_prize_cfg, {
	id,
	nine_lottery_prize_id,
	grid_index,
	prize,
	prize_num,
	weight
}).