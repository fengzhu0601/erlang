-define(player_vip_new_tab, player_vip_new_tab).
% -define(pd_vip, pd_vip).
-define(pd_vip_value, pd_vip_value).
-define(pd_vip_use_data, pd_vip_use_data).
-define(pd_vip_buy_status, pd_vip_buy_status).
-define(pd_vip_gift_one, pd_vip_gift_one).
-define(pd_vip_buy_gift_one, pd_vip_buy_gift_one).
-define(pd_vip_gift_every_day, pd_vip_gift_every_day).
-define(pd_vip_month_card, pd_vip_month_card).
-define(pd_vip_yongjiu_card, pd_vip_yongjiu_card).
-define(pd_vip_grow_jijin_card, pd_vip_grow_jijin_card).
-define(pd_vip_grow_jijin_list, pd_vip_grow_jijin_list).
-define(pd_vip_every_day_cost, pd_vip_every_day_cost).
-define(pd_vip_sum_cost, pd_vip_sum_cost).
-define(pd_vip_prize_status_list, pd_vip_prize_status_list).
-define(pd_vip_is_get_month_card_prize, pd_vip_is_get_month_card_prize).
-define(pd_vip_is_get_yongjiu_card_prize, pd_vip_is_get_yongjiu_card_prize).
-define(pd_vip_cost_total_rmb, pd_vip_cost_total_rmb).

-record(player_vip_new_tab,{
    id,
    vip_level=0,         %% vip等级       
    vip_value=0,         %% 充值总钻石
    month_card=0,        %% 月卡，记录结束时间
    yongjiu_card=0,      %% 永久卡, 1表示有，0表示没有
    grow_jijin_card=0,   %% 成长基金卡，有此卡，才能做成长基金活动
    grow_jijin_list=[],  %% 成长基金对应的等级任务[{PlayerLevel, PayPrizeId}] 
    vip_use_data=[],     %% vip特权有次数限制的数据
    vip_buy_status=[],   %% vip商品列表状态，{PayId, IsBuy} pay.txt表中的id，和是否可购买（0不可购买，1可购买）
    vip_gift_one=[],     %% 每个vip等级对应可领取的奖励，只限一次,{VipLevel, Status} 0不可领取，1可领取，2已领取
    vip_buy_gift_one=[], %% 每个vip等级对应购买一次，只限一次，{VipLevel，Status} 0未购买，1已购买
    vip_gift_every_day=0,%% 对应当前VIP等级奖励，每天只可领取一次，日重置，e.g当天领取等级7的奖励，要是升到8，也不能领取，0未领取，1已领取
    every_day_cost_list=[],     %% 每天消费,日重置{0,[{CostSum, PayPrizeId}]} 
    sum_cost_list=[],           %% 累积消费, {0,[{CostSum, PayPrizeId}]} 
    prize_status_list=[],        %% 每日消费，累积消费，成长基金对应的奖励状态1可领取，2已领取
    is_get_month_card_prize=0,   %% 0不可领取，1可领取，2已领取
    is_get_yongjiu_card_prize=0, %% 0不可领取，1可领取，2已领取
    cost_total_rmb=0             %% 总共花费了多少人民币，单位分
}).
