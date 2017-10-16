-define(player_abyss_tab, player_abyss_tab).

-define(abyss_fight_layer, abyss_fight_layer).
-define(abyss_fight_state, abyss_fight_state). %1正常进入副本，2正常结束副本, 挑战次数消耗：只有主动退出或者掉线或者死亡退出时消耗挑战次数

-define(pd_abyss_fight_easy, 1). %简单难度
-define(pd_abyss_fight_hard, 2). %噩梦难度

-record(player_abyss_tab, {
    player_id,
    max_easy_layer = 0,     %简单难度通关的最高层数
    easy_layer = 0,         %简单难度通关的目前层数
    auto_easy_layer = 0,    %简单自动爬塔目前层数

    max_hard_layer = 0,     %困难难度通关的最高层数
    hard_layer = 0,         %困难难度通关的目前层数
    auto_hard_layer = 0,    %困难自动爬塔目前层数

    daily_count = 0,        %每日进入次数
    buy_fight_count = 0,    %购买进入次数
    daily_reset = 0,        %每日重置次数
    buy_daily_reset = 0,    %购买重置次数

    score = 0,              %简单难度积分
    hard_score = 0,         %困难难度积分
    max_score = 0,          %虚空深渊每次挑战最高积分(简单 + 困难)
    rankIndex = 0           %当前排名
}).

%%-define(player_abyss_prize_info_tab, player_abyss_prize_info_tab).
-define(player_abyss_prize_info_tab, player_abyss_prize_info_tab). %% 保存未重置的积分

-record(player_abyss_prize_info_tab,
{
    player_id,
    abyss_score = 0,        %% 虚空深渊基础积分
    prizeList = [],         %% 奖励列表
    is_in_abyss = false     %% 是否还在虚空深渊,用于强制退出后登陆发奖励，挑战次数等
}).

-define(already_in_abyss, '@already_in_abyss@'). %% 是否已经在深渊中,已经在就不要扣钻石了

-define(abyss_prize_info, '@abyss_prize_info@').    %% 虚空深渊玩家非正常退出后的奖励信息
