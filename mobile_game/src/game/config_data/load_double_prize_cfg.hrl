-record(double_prize_cfg,
{
    id,
    double_activity_id=0,
    yugao_activity,
    start_activity,
    end_activity,
    double_type_and_fanbei=[],
    circulation_time=0
}).

-define(YUGAO_DP, 1).
-define(START_DP, 2).
-define(END_DP, 3).