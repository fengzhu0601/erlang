-record(vip_cfg,
{
    id,
    need_up_num=0,
    buy_sp=[],                              %% 购买体力次数,格式[0,1]0表示免费，1表示消耗的钻石数量
    auto_saodang=0,                         %% 扫荡特权
    yijian_saodang=0,                       %% 一键扫荡十次功能开启
    zhuan_pan_times=[],                     %% 抽奖所扣钻石
    zuan_to_jin=[],                         %% 炼金手,格式同第四列
    buy_arena=[],                           %% 竞技场购买次数,格式同第四列
    reset_instance_times_of_normal=[],      %% 可重置副本次数（普通—所有普通模式共享),格式同第四列
    reset_instance_times_of_difficulty=[],  %% 可重置副本次数（困难—所有困难模式共享),格式同第四列
    reset_instance_times_of_many_people=[], %% 可重置副本次数（多人模式——所有多人模式共享),格式同第四列
    daily_activity_1=[],                    %% 日常活动守卫美人鱼公主挑战次数[消耗钻石数量]
    daily_activity_2=[],                    %% 日常活动桑尼号挑战次数[消耗钻石数量]
    daily_activity_3=[],                    %% 日常活动时空裂缝挑战次数[消耗钻石数量]
    mining_count = [],                      %% 公会挖矿次数[消耗钻石数量]
    fish_net_count =[],                     %% 钓鱼撒网次数[消耗鱼饵个数]
    boss_challenge_flush=[],                %% 战争学院BOSS刷新次数
    course_times=[],                        %% 战争学院-挑战boss,格式同第四列
    main_ins_shop_times=[],                 %% 星商店刷新次数价格
    equipcompound_locknum=[],               %% 装备合成属性锁定条数   todo  暂定
    guild_mobai_times=[],                   %% 公会膜拜额外次数,格式同第四列
    tuhao_mobai=0,                          %% 土豪膜拜模式（开关）0，不开启，1开启
    pata_enter_times=[],                    %% 爬塔虚空深渊挑战次数
    pata_reset_times=[],                    %% 爬塔重置次数,格式同第四列
    pata_integral=0,                        %% 爬塔积分加成（额外百分比）
    pata_zhekou=0,                          %% 百分比  爬塔扫荡折扣
    daily_activity1_sweep_info=0,           %% 人鱼扫荡功能
    daily_activity2_sweep_info=0,           %% 桑尼号功能
    daily_activity3_sweep_info=0,           %% 时空裂缝功能
    daily_activity4_sweep_info=0,           %% 打木桶
    daily_activity5_sweep_info=0,           %% 摘星星
    long_wen_num=0,                         %% 
    vip_gift=0,
    vip_buy_gift=0,
    vip_buy_gift_cost=0,
    vip_day_gift=0,
    relive=[],                              %% 副本复活次数（0表示免费，具体值表示复活额外增加次数）
    add_hp_limit=[],                        %% 副本加血次数（0表示免费，具体值表示复活购买钻石数）
    login_prize_rate=0,                     %% 登陆奖励所获得的货币类为普通用户的百分比（百分比）
    sp_limit = 0                            %% 玩家自然回复体力上限
}).
