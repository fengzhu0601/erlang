-define( cur_arena_type, '@arena_type_20151229@' ).
-define(ARENA_P2E_FREE_TIMES, misc_cfg:get_arena_p2e_count()).
-define(arena_robot_tab, arena_robot_tab).
-define(arena_p2e_rank_tab, arena_p2e_rank_tab).

%%竞技场信息结构
-record(arena_info,
{
    id = 0
    , name = <<>>
    , career = 0
    , power = 0  %%20151229: 该参数已做废
    , arena_lev = 1
    , high_arena_lev = 1  %% 历史最高竞技场等级
    , arena_cent = 0
    , award_state = []    %% [{ItemBid, ItemNum, IsGet}]
    , trun_state = erlang:make_tuple(8, 1)
    %% 人机竞技
    , flush_times = 0
    , challenge_list = []
    , best_rank = 999999
    , p2e_win = 0
    , p2e_loss = 0
    %% 1v1竞技
    , p2p_win = 0
    , p2p_loss = 0
    , p2p_kill = 0
    %% 3v3竞技
    , m_p2p_win = 0
    , m_p2p_loss = 0
    , m_p2p_kill = 0
    , m_p2p_die = 0
}).

%% 竞技场机器人结构表
-record(arena_robot_tab, {
    id,
    name,
    career,
    lev,
    attr,
    skills
}).

%% 竞技场人机排行表
-record(arena_p2e_rank_tab, {
    id = 0,
    count = 0,
    rank_list = []
}).

%% 队伍与竞技场的映射
-record(team_arena_index, {
    id          %% TeamId
    , arena_id
}).

%% 竞技场配置结构
-record(arena_cfg, {
    id = 0        %% 竞技等级
    , up_cent = 0        %% 升到下一级所需积分
    , daily_award = []    %% 每日发放勋章数量
    , trun_award         %% 转盘奖励{1星，2星，3星，4星，5星，6星，7星，8星}
    , p2e_win = 0       %% 非即时胜利获得积分
    , p2e_loss = 0       %% 非即时失败失去积分
    , p2p_win = 0       %% 即时胜利获得积分
    , p2p_loss = 0       %% 即时失败失去积分
    , multi_p2p_win = 0 %% 多人即时胜利获得积分
    , multi_p2p_loss = 0 %% 多人即时失败失去积分
    , kill_ratio = 0     %% 多人即时杀人系数
    , attr_award = []    %% 段位属性奖励
    , honour_award = 0    %% 段位奖励
    , turn_times = []     %% 转盘感受控制，每次抽奖的保底成功次数
}).

%% 竞技场人机排行奖励配置结构表
-record(challeng_reward_cfg, {
    id,                 %% id
    min_ranking,        %% 最小排名
    max_ranking,        %% 最大排名
    rewardld            %% 奖励ID
}).

%% 竞技场商店配置结构表
-record(arena_shop_cfg, {
    id = 0,
    item = 0,
    num = 0,
    price = 0
}).

%% 人机排行区间奖励配置结构表
-record(arena_p2e_rank_prize_cfg, {
    id = 0,
    rank = 0,
    prize = 0
}).
