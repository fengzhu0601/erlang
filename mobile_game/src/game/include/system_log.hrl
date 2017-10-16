%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 24. 十月 2015 下午12:43
%%%-------------------------------------------------------------------
-author("clark").

%% =========================== 事件定义 ===========================
-define(INIT_LIST, [1, 2, 3, 4]).       %% 进入游戏时前4个节点已加载完
-define(ACCOUNT_ENTER_LOG_EVT, "001").  %% 账号登录事件
-define(ACCOUNT_EXIT_LOG_EVT, "002").   %% 账号退出事件
-define(ROLE_ENTER_LOG_EVT, "003").     %% 角色进入游戏事件
-define(ROLE_EXIT_LOG_EVT, "004").      %% 角色退出游戏事件
-define(CREATE_ROLE_EVT, "005").        %% 角色创建事件
-define(ROLE_LEVEL_UP_EVT, "006").      %% 角色升级事件
-define(TOPUP_LOG_EVT, "007").          %% 充值事件
-define(PAY_LOG_EVT, "008").            %% 消费事件
-define(TASK_START_LOG_EVT, "009").     %% 开始任务事件
-define(TASK_FINISH_LOG_EVT, "010").    %% 结束任务事件
-define(TASK_CANCEL_LOG_EVT, "011").    %% 取消任务事件
-define(ENTER_COPY_LOG_EVT, "012").     %% 进入副本事件
-define(FINISH_COPY_LOG_EVT, "013").    %% 完成副本事件
-define(EXIT_COPY_LOG_EVT, "014").      %% 退出副本事件
-define(STAR_SHOP_PAY_LOG_EVT, "015").  %% 星级商店消费事件
-define(LOAD_PROGRESS, "016").          %% 客户端加载日志
-define(DELETE_ROLE_EVT, "017").        %% 删除角色事件
-define(SKILL_LEVELUP_EVT, "018").      %% 技能升级事件
-define(OFF_LINE_EVT, "019").           %% 掉线事件
-define(GET_SYSTEM_DIAMOND_EVT, "020"). %% 系统钻石产出事件
-define(GET_PAY_ITEM_EVT, "021").       %% 付费道具产生事件
-define(USE_PAY_ITEM_EVT, "022").       %% 付费道具消耗事件
-define(GET_ITEM_EVT, "023").           %% 道具产生事件
-define(USE_ITEM_EVT, "024").           %% 道具消耗事件
-define(PLAYER_FUBEN_DIE_EVT, "025").   %% 玩家副本死亡事件
-define(PLAYER_ARENA_DIE_EVT, "026").   %% 玩家竞技场死亡事件
-define(AUCTION_SELL_EVT, "027").       %% 拍卖行寄卖事件
-define(AUCTION_BUY_EVT, "028").        %% 拍卖行购买事件` 
-define(AUCTION_P2P_EVT, "029").        %% 拍卖行p2p交易事件
-define(NPC_BUY_EVT, "030").            %% 从NPC处购买事件
-define(GET_MAIL_EVT, "031").           %% 接受邮件事件
-define(GET_MAIL_ATTACH_EVT, "032").    %% 接受邮件附件事件
-define(PLAYRE_CHAT_EVT, "033").        %% 聊天事件
-define(CLIENT_LOAD_EVT, "034").        %% 客户端加载事件
-define(MONEY_FLOW_EVT, "035").         %% 金钱流动事件
-define(ITEM_FLOW_EVT, "036").          %% 普通道具流动事件
-define(LONGWEN_LEVELUP_EVT, "037").    %% 龙纹升级事件
-define(ITEM_HANDLE_EVT, "038").        %% 道具操作事件
-define(PHASE_ACHIEVEMENT, "039").      %% 玩家阶段奖励事件
-define(PLAYER_VIP_EVT, "040").         %% 玩家购买vip事件
-define(PLAYER_SUIT_EVT, "041").        %% 玩家套装事件
-define(RIDE_PHASE_EVT, "042").         %% 坐骑进阶事件
-define(PET_PHASE_EVT, "043").          %% 宠物进阶事件
-define(ONLINE_COUNT_EVT, "044").       %% 记录在线人数日志

%% =========================== 流水原因定义 ===========================
-define(FLOW_REASON_AUCTION, 1).            %% 拍卖行
-define(FLOW_REASON_EQUIP_XQ, 2).           %% 装备镶嵌
-define(FLOW_REASON_TAKE_OFF_GEM, 3).       %% 卸宝石
-define(FLOW_REASON_MAIL, 4).               %% 邮件
-define(FLOW_REASON_ALCHEMY, 5).            %% 点金手
-define(FLOW_REASON_PET_FENGYIN, 6).        %% 宠物封印
-define(FLOW_REASON_FUBEN_DROP, 7).         %% 副本掉落
-define(FLOW_REASON_ARENA_TURN_AWARD, 8).   %% 竞技场抽奖
-define(FLOW_REASON_GEM_UPDATE, 9).         %% 宝石升级
-define(FLOW_REASON_SHOP_SELL, 10).         %% 出售物品
-define(FLOW_REASON_SHOP_BUY, 11).          %% 购买物品
-define(FLOW_REASON_ABYSS, 12).             %% 虚空深渊
-define(FLOW_REASON_SAODANG, 13).           %% 扫荡
-define(FLOW_REASON_SHOP_BACK_BUY, 14).     %% 商店回购
-define(FLOW_REASON_ARENA, 15).             %% 竞技场
-define(FLOW_REASON_FRIEND_GIFT, 16).       %% 好友系统
-define(FLOW_REASON_DAILY_ACTIVITY, 17).    %% 日常活动
-define(FLOW_REASON_EQUIP_EXCHANGE, 18).    %% 装备提炼
-define(FLOW_REASON_GM, 19).                %% GM
-define(FLOW_REASON_ITEM_HECHENG, 20).      %% 物品合成
-define(FLOW_REASON_USE_ITEM, 20).          %% 使用物品
-define(FLOW_REASON_FUBEN_SHOP, 21).        %% 副本商店
-define(FLOW_REASON_LONGWEN_RESET, 22).     %% 龙纹重置
-define(FLOW_REASON_ROLL_LOTTERY, 23).      %% 每日抽奖
-define(FLOW_REASON_VIP_PRIZE, 24).         %% VIP奖励
-define(FLOW_REASON_RECHARGE, 25).          %% 充值
-define(FLOW_REASON_DIAMOND_CARD, 26).      %% 钻石卡
-define(FLOW_REASON_ROLE_LEVELUP, 27).      %% 主角升级
-define(FLOW_REASON_GUILD_BOSS_DONATE, 28). %% 公会boss献祭
-define(FLOW_REASON_GUILD_BOSS_PHASE, 29).  %% 公会boss进阶
-define(FLOW_REASON_OPEN_SERVER_HAPPY, 30). %% 开服狂欢
-define(FLOW_REASON_ACHIEVEMENT, 31).       %% 成就系统
-define(FLOW_REASON_DIG, 32).               %% 采集
-define(FLOW_REASON_LOGIN_PRIZE, 33).       %% 登录奖励
-define(FLOW_REASON_BOUNTY, 34).            %% 赏金任务
-define(FLOW_REASON_CAMP, 35).              %% 神魔系统
-define(FLOW_REASON_CARD_TURN, 36).         %% 卡牌抽奖
-define(FLOW_REASON_HONEST_USER, 37).       %% 忠实用户
-define(FLOW_REASON_PHASE_ACHIEVEMENT, 38). %% 阶级成就
-define(FLOW_REASON_RIDE_CHANGE, 39).       %% 兽魂转化
-define(FLOW_REASON_STAR_LEV_PRIZE, 40).    %% 副本星级奖励
-define(FLOW_REASON_FUBEN_TURN_CARD, 41).   %% 副本翻牌奖励
-define(FLOW_REASON_FUBEN_COMPLETE, 42).    %% 副本结算奖励
-define(FLOW_REASON_NINE_STAR_PRIZE, 43).   %% 副本九星通关奖励
-define(FLOW_REASON_CHAPTER_PRIZE, 44).     %% 副本章节奖励
-define(FLOW_REASON_LEVEL_PRIZE, 45).       %% 等级奖励
-define(FLOW_REASON_SIGN_PRIZE, 46).        %% 签到奖励
-define(FLOW_REASON_DAILY_TASK, 47).        %% 日常任务
-define(FLOW_REASON_SKY, 48).               %% 天空之城
-define(FLOW_REASON_COURSE, 49).            %% 战争学院
-define(FLOW_REASON_GUILD, 50).             %% 公会消耗
-define(FLOW_REASON_CHAT, 51).              %% 聊天
-define(FLOW_REASON_PET_XISHOU, 52).        %% 宠物吸收
-define(FLOW_REASON_ENTER_FUBEN, 53).       %% 进入副本
-define(FLOW_REASON_BUY_FUBEN_TIMES, 54).   %% 购买副本挑战次数
-define(FLOW_REASON_SELLER, 55).            %% 神秘商人
-define(FLOW_REASON_BUY_SP, 56).            %% 购买体力
-define(FLOW_REASON_GUILD_BOSS_CALL, 57).   %% 公会boss召唤
-define(FLOW_REASON_GUILD_BOSS_RELIVE, 58). %% 公会boss买活
-define(FLOW_REASON_CROWN, 59).             %% 皇冠系统
-define(FLOW_REASON_EQUIP_JIANGDING, 60).   %% 装备鉴定
-define(FLOW_REASON_EQUIP_QIANGHUA, 61).    %% 装备强化
-define(FLOW_REASON_EQUIP_JICHENG, 62).     %% 装备继承
-define(FLOW_REASON_EQUIP_HECHENG, 63).     %% 装备合成
-define(FLOW_REASON_EQUIP_DAKONG, 64).      %% 装备打孔
-define(FLOW_REASON_EQUIP_FUMO, 65).        %% 装备附魔
-define(FLOW_REASON_ACTIVITY_FUMO, 66).     %% 激活附魔
-define(FLOW_REASON_EUQIP_CUIQU, 67).       %% 装备萃取
-define(FLOW_REASON_BUCKET_UNLOCK, 68).     %% 背包解锁
-define(FLOW_REASON_PET_UPGRADE, 69).       %% 宠物升级
-define(FLOW_REASON_FUBEN_RELIVE, 70).      %% 副本复活
-define(FLOW_REASON_FUBEN_ADD_HP, 71).      %% 副本加血
-define(FLOW_REASON_LONGWEN_UPGRADE, 72).   %% 龙纹升级
-define(FLOW_REASON_SIGN, 73).              %% 补签
-define(FLOW_REASON_TASK, 74).              %% 任务
-define(FLOW_REASON_PET_PHASE, 75).         %% 宠物进阶
-define(FLOW_REASON_PET_SKILL, 76).         %% 宠物技能
-define(FLOW_REASON_RIDE_ACTIVATE, 77).     %% 坐骑激活
-define(FLOW_REASON_RIDE_PHASE, 78).        %% 坐骑进化
-define(FLOW_REASON_RIDE_UPLEVEL, 79).      %% 兽魂升级
-define(FLOW_REASON_RIDE_ADVANCE, 80).      %% 兽魂突破
-define(FLOW_REASON_RIDE_FEED, 81).         %% 兽魂喂养
-define(FLOW_REASON_RECHARGE_PRIZE, 82).    %% 充值满金额送礼
-define(FLOW_REASON_NINE_LOTTERY, 83).      %% 九宫格
-define(FLOW_REASON_ARENA_SHOP, 84).        %% 竞技场商店
-define(FLOW_REASON_EQUIP_XILIANG, 85).     %% 装备洗炼
-define(FLOW_REASON_IMPACT_RANKING_LIST, 86).   %% 开服冲榜奖励
-define(FLOW_REASON_RANK_SHOP, 87).         %% 冲榜商店
-define(FLOW_REASON_SERVER_LOGIN, 88).      %% 开服登录奖励
-define(FLOW_REASON_GUILD_MINING, 89).      %% 公会挖矿
-define(FLOW_REASON_FISHING, 90).           %% 钓鱼
-define(FLOW_REASON_RESET_NAME, 91).        %% 改名
-define(FLOW_REASON_GUILD_SAINT, 92).       %% 公会圣物
-define(FLOW_REASON_UNKNOWN, 999).          %% 未知

%% 玩家节点记录表
-record(player_progress_tab,
{
    player_id,
    iprogress_list = ?INIT_LIST
}).

%% 账号登入日志
-record(account_login_log,
{
    iLogField = "AccountLogin",
    iEventId,
    dtEventTime = 0,
    iWorldId = 0,
    iUin = 0,
    vClientIp = "",
    dtCreateTime = 0,
    iLoginWay = 0,
    vDeviceMac = "",
    vDeviceId = "",
    vDeviceStyle = "",
    vDeviceInfo = ""
}).

%% 账号登出日志
-record(account_logout_log,
{
    iLogField = "AccountLogout",
    iEventId,
    dtEventTime = 0,
    iWorldId = 0,
    iUin = 0,
    iRoleId = 0,
    vRoleName = "",
    dtLoginTime = "",
    vClientIp = "",
    dtCreateTime = 0,
    iOnlineTime = 0,
    vDeviceMac = "",
    vDeviceId = "",
    vDeviceStyle = "",
    vDeviceInfo = ""
}).

%% 角色登入日志
-record(role_login_log,
{
    iLogField = "RoleLogin",
    iEventId,
    dtEventTime = 0,
    iWorldId = 0,
    iRoleId = 0,
    vRoleName = "",
    iUin = 0,
    vClientIp = "",
    iRoleLevel = 0,
    iMoney = 0,
    dtCreateTime = 0,
    iLoginWay = 0,
    iRoleVipLevel = 0,
    iXP = 0,
    iOnlineTotalTime = 0,
    iRoleGoldcount = 0,
    iRoleExpendGold = 0,
    vMac = "",
    vDeviceId = "",
    vDeviceStyle = "",
    vDeviceInfo = ""
}).

%% 角色登出日志
-record(role_logout_log,
{
    iLogField = "RoleLogout",
    iEventId,
    dtEventTime = 0,
    iWorldId = 0,
    iRoleId = 0,
    vRoleName = "",
    iUin = 0,
    vClientIp = "",
    iOnlineTime = 0,
    iOnlineTotalTime = 0,
    iRoleLevel = 0,
    iMoney = 0,
    iLoginWay = 0,
    iRoleVipLevel = 0,
    iRoleGoldcount = 0,
    iRoleExpendGold = 0,
    vDeviceMac = "",
    vDeviceId = ""
}).

%% 创角日志
-record(create_role_log,
{
    iLogField = "CreateRole",       %% 日志标识
    iEventId,                       %% 事件id
    dtEventTime = 0,                %% 角色创建时间
    iWorldId = 0,                   %% 游戏大区id
    iRoleId = 0,                    %% 角色id
    vRoleName = "",                 %% 角色名
    iUin = 0,                       %% 用户open_id
    vClientIp = "",                 %% 角色创建时客户端ip
    iJobId = 0,                     %% 角色职业
    iLoginWay = 0,                  %% 注册渠道
    vDeviceMac = 0,                 %% 设备Mac地址
    vDeviceId = 0,                  %% 设备唯一标致
    vDeviceStyle = "",
    vDeviceInfo = ""
}).

%% 升级日志
-record(role_level_up_log,
{
    iLogField = "RoleLevelUp",
    iEventId,
    dtEventTime = 0,
    iWorldId = 0,
    iRoleId = 0,
    vRoleName = "",
    iUin = 0,
    iJobId = 0,
    iRoleLevel = 0,
    vUpLevelReason = "",
    iXP = 0,
    vDeviceMac = "",
    vDeviceId = "",
    vDeviceInfo = "",
    vDeviceStyle = ""
}).

%% 任务开始日志
-record(task_start_log,
{
    iLogField = "TaskStart",
    iEventId,
    dtEventTime = 0,
    iWorldId = 0,
    iRoleId = 0,
    vRoleName = "",
    iUin = 0,
    iJobId = 0,
    iRoleLevel = 0,
    iTaskId = 0
}).

%% 完成任务日志
-record(task_finish_log,
{
    iLogField = "TaskFinished",
    iEventId,
    dtEventTime = 0,
    iWorldId = 0,
    iRoleId = 0,
    vRoleName = "",
    iUin = 0,
    iJobId = 0,
    iRoleLevel = 0,
    iTaskId = 0
}).

%% 取消任务日志
-record(task_cancel_log,
{
    iLogField = "CancelTask",
    iEventId,
    iWorldId = 0,
    iUin = 0,
    dtEventTime = 0,
    dtTaskStartTime = 0,
    iRoleId = 0,
    vRoleName = "",
    iJobId = 0,
    iGender = 0,
    iRoleLevel = 0,
    iMoneyBeforeTask = 0,
    iMoneyAfterTask = 0,
    iTaskId = 0,
    vTaskName = "",
    iNpcId = 0,
    vNpcName = "",
    iMoneyTransfer = 0,
    iGetItemId = 0,
    iGetItemType = 0,
    iGetItemNum = 0,
    iGetItemGuid = 0,
    iLostItemId = 0,
    iLostItemType = 0,
    iLostItemNum = 0,
    iLostItemGuid = 0,
    vDeviceMac = "",
    vDeviceId = ""
}).

%% 充值日志
-record(topup_log,
{
    iLogField = "Recharge",
    iEventId,
    dtEventTime = 0,
    iWorldId = 0,
    iRoleId = 0,
    vRoleName = "",
    iUin = 0,
    vArriveAccount = "",    %% 到账账号
    vClientIp = 0,
    iTopupProtal = "",      %% 充值流水号
    iPayBefore = 0,         %% 充值前元宝
    iPayDelta = 0,          %% 充值元宝
    iPayAfter = 0,          %% 充值后元宝
    iLoginWay = 0,          %% 注册渠道
    iTopuoWay = 0,          %% 充值渠道
    vPayAccount = "",       %% 付费账号
    vRemark = ""            %% 备注
}).

%% 消费日志
-record(pay_log,
{
    iLogField = "Shop",
    iEventId,
    dtEventTime = 0,
    iWorldId = 0,
    iRoleId = 0,
    vRoleName = "",
    iUin = 0,
    dtPayTime = "",
    vClientIp = 0,
    vPayType = 0,           %% 支付类型
    iCost = 0,              %% 支付消耗
    iPayAfterGold = 0,      %% 支付后剩余元宝
    iLoginWay = 0,
    vDealType = 0,          %% 交易类型
    iGoldPay = 0,           %% 元宝支付额
    ibuyProtal = 0,         %% 购买流水号
    vPayReason = ""         %% 支付原因
}).

%% 进入副本日志
-record(enter_copy_log,
{
    iLogField = "enter_copy_log",
    iEventId,
    dtEventTime = 0,
    iWorldId = 0,
    iRoleId = 0,
    vRoleName = "",
    iUin = 0,
    iJobId = 0,
    iRoleLevel = 0,
    iAfterGoldNum = 0,  %% 玩家进入副本身上的金钱数
    iCopyId = 0
}).

%% 完成副本日志
-record(finish_copy_log,
{
    iLogField = "finish_copy_log",
    iEventId,
    dtEventTime = 0,
    iWorldId = 0,
    iRoleId = 0,
    vRoleName = "",
    iUin = 0,
    iJobId = 0,
    iRoleLevel = 0,
    iCopyId = 0,
    iPassTimeStarLv = 0,
    iMaxComboStarLv = 0,
    iMinBeatenStarLv = 0
}).

%% 退出副本日志
-record(exit_copy_log,
{
    iLogField = "exit_copy_log",
    iEventId,
    dtEventTime = 0,
    iWorldId = 0,
    iRoleId = 0,
    vRoleName = "",
    iUin = 0,
    iJobId = 0,
    iRoleLevel = 0,
    iExitGoldNum = 0,
    iCopyId = 0
}).

%% 星级商店消费日志
-record(star_shop_pay_log,
{
    iLogField = "star_shop_pay_log",
    iEventId,
    dtEventTime = 0,
    iWorldId = 0,
    iRoleId = 0,
    vRoleName = "",
    iUin = 0,
    iJobId = 0,
    iRoleLevel = 0,
    iStarLvBefore = 0,
    iStarLvAfter = 0,
    iStarLvCost = 0,
    iGoodsId = 0,
    iGoodsNum = 0,
    vDeviceMac = "",
    vDeviceId = "",
    vDeviceInfo = "",
    vDeviceStyle = ""
}).

%% 客户端加载日志
-record(load_progress_log,
{
    iLogField = "LoadProgress",
    iEventId,
    dtEventTime,
    iWorldId,
    iUin,
    iRoleId,
    iProgress,
    vRoleName,
    iRoleLevel,
    iPower
}).

%% 玩家副本死亡日志
-record(player_copy_die_log,
{
    iLogField = "player_copy_die_log",
    iEventId,
    iWorldId,
    iUin,
    dtDieTime,
    iRoleId,
    vRoleName,
    iJobId,
    iRoleLevel,
    iCopyId,
    vMac,
    vDeviceId,
    vDeviceInfo,
    vDeviceMac
}).

%% 删除角色日志
-record(delete_role_log, 
{
    iLogField = "delete_role_log",
    iEventId,
    iWorldId = 0,
    iUin = 0,
    vClientIp = 0,
    iRoleId = 0,
    vRoleName = "",
    iJobId = 0,
    iRoleLevel = 0,
    vDeviceMac = "",
    vDeviceID = "",
    vDeviceInfo = "",
    vDeviceMes = ""
}).


%% 玩家接收附件日志
-record(player_get_mail_attach_log,
{
    iLogField = "player_get_mail_attach_log",
    iEventId,
    iWorldId,
    iUin,
    dtGetTime,
    iRoleId,
    vRoleName,
    iRoleLevel,
    iSendRoleId,
    vMailName,
    iItemId,
    iItemCount,
    vMac,
    vDeviceId,
    vDeviceInfo,
    vDeviceMac
}).


%% 角色技能升级日志
-record(skill_levelup_log, 
{
    iLogField = "skill_levelup_log",
    iEventId,
    iWorldId = 0,
    iUin = 0,
    iRoleId = 0,
    vRoleName = "",
    iJobId = 0,
    iRoleLevel = 0,
    iRoleExp = 0,
    iSkillIdBefore = 0,
    iSkillIdAfter = 0,
    iSkillLevelBefore = 0,
    iSkillLevelAfter = 0,
    iMoneyBefore = 0,
    iMoneyCost = 0,
    iMoneyAfter = 0,
    vDeviceMac = "",
    vDeviceID = "",
    vDeviceInfo = "",
    vDeviceMes = ""
}).


%% 角色掉线日志
-record(role_offline_log, 
{
    iLogField = "RoleOffline",
    iEventId,
    iWorldId = 0,
    iUin = 0,
    iRoleId = 0,
    vRoleName = "",
    vClientIp = 0,
    port =0,
    offlineType = 0,
    vDeviceMac = "",
    vDeviceID = ""
}).


%% 玩家阶段奖励日志
-record(player_phase_achievement_log, 
{
    iLogField = "player_phase_achievement_log",
    iEventId,
    iWorldId = 0,
    iUin = 0,
    iRoleId = 0,
    vRoleName = "",
    iJobId = 0,
    iRoleLevel = 0,
    iPhaseId = 0,
    vDeviceMac = "",
    vDeviceID = "",
    vDeviceInfo = "",
    vDeviceMes = ""
}).


%% 玩家接收邮件日志
-record(player_get_mail_log, 
{
    iLogField = "player_get_mail_log",
    iEventId,
    iWorldId = 0,
    iUin = 0,
    dtGetTime = 0,
    iRoleId = 0,
    vRoleName = "",
    iRoleLevel = 0,
    iSendRoleId = 0,
    vMailName = "",
    vMailContent = "",
    vDeviceMac = "",
    vDeviceID = "",
    vDeviceInfo = "",
    vDeviceMes = ""
}).


%% 龙纹升级日志
-record(longwen_levelup_log,
{
    iLogField = "longwen_levelup_log",
    iEventId,
    iWorldId = 0,
    iUin = 0,
    iRoleId = 0,
    vRoleName = "",
    iJobId,
    iRoleLevel = 0,
    iLongwenLevelBefore,
    iLongwenLevelAfter,
    iLongwenIdBefore,
    iLongwenIdAfter,
    iMoneyBefore,
    iMoneyCost,
    iMoneyAfter,
    vDeviceMac = "",
    vDeviceId = "",
    vDeviceInfo = "",
    vDeviceStyle = ""
}).


%% 免费元宝充值日志
-record(free_give_diamond_log,
{
    iLogField = "free_give_diamond_log",
    iEventId,
    iWorldId = 0,
    iUin = 0,
    iRoleId = 0,
    vRoleName = "",
    iJobId,
    iRoleLevel = 0,

    iDiamondBefore,
    iDiamond,
    iDiamondAfter,
    iComment,

    iIP="",
    vDeviceMac = "",
    vDeviceId = "",
    vDeviceInfo = "",
    vDeviceStyle = ""
}).


% 产生物品
-record(get_item_log,
{
    iLogField = "get_item_log",
    iEventId,
    iWorldId = 0,
    iUin = 0,
    iRoleId = 0,
    vRoleName = "",
    iJobId,
    iRoleLevel = 0,

    iItemId,
    iItemType,
    iItemNumBefore,
    iItemNumAfter,
    iItemNum,
    iItemUID,
    iReason,

    vDeviceMac = "",
    vDeviceId = "",
    vDeviceInfo = "",
    vDeviceStyle = ""
}).


% 消耗物品
-record(use_item_log,
{
    iLogField = "use_item_log",
    iEventId,
    iWorldId = 0,
    iUin = 0,
    iRoleId = 0,
    vRoleName = "",
    iJobId,
    iRoleLevel = 0,

    iItemId,
    iItemType,
    iUseItemBefore,
    iUseItemAfter,
    iUseItemNum,
    iItemUID,
    iReason,

    vDeviceMac = "",
    vDeviceId = "",
    vDeviceInfo = "",
    vDeviceStyle = ""
}).

% 物品流向
-record(item_trend_log,
{
    iLogField = "item_trend_log",
    iEventId,
    iWorldId = 0,
    iUin = 0,
    iRoleId = 0,
    vRoleName = "",
    iJobId,
    iRoleLevel = 0,

    iItemType,
    iItemNum,
    iItemNumBefore,
    iItemNumAfter,
    iItemUID,
    trendId,
    iReason,

    vDeviceMac = "",
    vDeviceId = "",
    vDeviceInfo = "",
    vDeviceStyle = ""
}).


%% 拍卖行寄售日志
-record(auction_sell_log,
{
    iLogField = "auction_sell_log",
    iEventId,
    iWorldId,
    iUin,
    dtSellTime,
    iRoleId,
    vRoleName = "",
    iJobId = 0,
    iRoleLevel = 0,
    iGoodsId = 0,
    iType = 0,
    iPrice,
    vDeviceMac = "",
    vDeviceId = "",
    vDeviceInfo = "",
    vDeviceMes = ""
}).

%% 拍卖行购买日志
-record(auction_buy_log,
{
    iLogField = "auction_buy_log",
    iEventId,
    iWorldId,
    iUin,
    dtBuyTime,
    iRoleId,
    vRoleName = "",
    iJobId = 0,
    iRoleLevel = 0,
    iMoneyBefore,
    iMoneyAfter,
    iGoodsId = 0,
    iCount,
    iPrice,
    iSellerId,
    vDeviceMac = "",
    vDeviceId = "",
    vDeviceInfo = "",
    vDeviceMes = ""
}).


%% 玩家聊天日志
-record(player_chat_log,
{
    iLogField = "player_chat_log",
    iEventId,
    iUin,
    dtChatTime,
    iRoleId,
    vRoleName,
    iRoleLevel,
    vAddressIP,
    iChannel,
    iContent,
    vDeviceMac = "",
    vDeviceId = "",
    vDeviceInfo = "",
    vDeviceMes = ""
}).

%% 玩家竞技场死亡日志
-record(player_arena_die_log,
{
    iLogField = "player_arena_die_log",
    iEventId,
    iWorldId,
    iUin,
    dtDieTime,
    iRoleId,
    vRoleName,
    iJobId,
    iRoleLevel,
    iKillerId,
    vKillerName,
    iKillerJobId,
    iKillerLevel,
    iCopyId,
    iKillerRank,
    iKillerHonour,
    iRoleRank,
    iRoleHonour,
    vDeviceMac = "",
    vDeviceId = "",
    vDeviceInfo = "",
    vDeviceMes = ""
}).

%% 从NPC处购买日志
-record(npc_buy_log,
{
    iLogField = "npc_buy_log",
    iEventId,
    iWorldId,
    iUin,
    dtDealTime,
    iRoleId,
    vRoleName,
    iJobId,
    iRoleLevel,
    iMoneyBefore,
    iMoneyAfter,
    iNPCId,
    vNPCName,
    iItemPay,
    iItemId,
    iItemType,
    iBuyItemCount,
    iGetItemCount,
    vDeviceMac = "",
    vDeviceId = "",
    vDeviceInfo = "",
    vDeviceMes = ""
}).

%% 金钱流动日志
-record(money_flow_log,
{
    iLogField = "money_flow_log",
    iEventId,
    iWorldId,
    iUin,
    dtMoneyFlowTime,
    iRoleId,
    vRoleName,
    iJobId,
    iRoleLevel,
    iMoneyBefore,
    iMoneyAfter,
    iMoneyCount,
    iMoneyType,
    iFlowId,
    vFlowReason,
    vDeviceMac = "",
    vDeviceId = "",
    vDeviceInfo = "",
    vDeviceMes = ""
}).

%% 购买vip日志
-record(player_vip_log,
{
    iLogField = "player_vip_log",
    iEventId,
    iWorldId,
    dtEventTime,
    iUin,
    iRoleId,
    vRoleName,
    iVipLevel,
    vMac,
    vDeviceId,
    vDeviceInfo,
    vDeviceMes
}).

%% 玩家套装日志
-record(player_suit_log,
{
    iLogField = "player_suit_log",
    iEventId,
    iWorldId,
    dtEventTime,
    iUin,
    iRoleId,
    vRoleName,
    iSuitId,
    iSuitLevel,
    vMac,
    vDeviceId,
    vDeviceInfo,
    vDeviceMes
}).

%% 坐骑进阶日志
-record(ride_phase_log,
{
    iLogField = "ride_phase_log",
    iEventId,
    iWorldId,
    dtEventTime,
    iUin,
    iRoleId,
    vRoleName,
    iRoleLevel,
    iPower,
    iRideId,
    iRideLevBefore,
    iRideLevAfter
}).

%% 宠物进阶日志
-record(pet_phase_log,
{
    iLogField = "pet_phase_log",
    iEventId,
    iWorldId,
    dtEventTime,
    iUin,
    iRoleId,
    vRoleName,
    iRoleLevel,
    iPower,
    iPetId,
    iPetLevBefore,
    iPetLevAfter
}).

%% 在线人数日志 (每五分钟记录一次)
-record(online_count,
{
    iLogField = "OnlineCount",
    dtEventTime,
    iEventId,
    iWorldId,
    iAccountCount
}).