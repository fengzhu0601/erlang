%% 公会表结构

%% 公会信息
-record(guild_id_tab, {
    guild_id,           %公会ID，区号+创建顺序*1000
    guild_name
}).
-record(guild_tab, {
    guild_name,             % 公会名称，不能重复，当作key值
    master_id,              % 公会会长
    totle_exp = 0,          % 公会当前获得总经验（用于排序）
    totle_player = 0,       % 公会目前的总人数
    notice = <<>>,          % 公会公告
    notice_update_time = 0, % 公告修改/创建时间
    totem_id,               % 公会图腾
    border_id,              % 公会边框
    create_time             % 公会创建时间
}).

%%玩家申请公会列表
-record(player_apply_tab, {
    player_id,
    guild_id
}).

%% 公会成员表
-record(player_guild_member, {
    player_id,            %玩家ID（一个玩家只能有一个公会）
    guild_id,             %公会ID
    player_position,      %用户职位ID
    join_time,            %加入时间
    totle_exp = 0,          %总贡献值
    lv = 1,                 %在该公会达到的会员等级
    exp = 0,                %在该等级得到的贡献值
    daily_task_count = []   %日常提升贡献值剩余使用次数[{BuildingType:建筑类型, Num:次数}]
    % 废弃这个 daily_task_count 因为退出公会重新加入又可以升级
}).

%% 玩家是否加入过公会
-record(player_guild_is_join_guild, {
    player_id,
    quit_guild_times = 0  %玩家退出公会时间
}).

%%公会和玩家关联表。（玩家入会加入该表，退会删除该玩家ID）
-record(guild_player_association_tab, {
    guild_id,
    player_list = []        %玩家列表[playerId1,playerId2,...]
}).

%% 公会成员上线维护表
-record(guild_member_online_tab, {
    guild_id,           %公会ID
    player_list = []      %在线玩家列表。[{player_id,player_pid}]
}).

-define(DEFAULT_GUILD_LV, 1).     %公会建筑默认等级
%% 公会建筑信息 目前两个建筑：公会大厅、公会科技馆 
-record(guild_buildings_tab, {
    guild_id,        %公会ID
    building_list = [] %[{building_id::公会建筑ID, lv::建筑等级, exp::建筑当前等级经验},...]
}).

%% 公会事件表（各类成就、成员加入离开、职位变更）
-record(guild_event_tab, {
    guild_id,      %公会ID
    event_list = []  %[{typeId::事件类型, content::事件内容, time::事件时间},...]
}).

%% 玩家公会建筑科技馆信息，科技技能、科技等级、
-record(player_guild_tech_buildings, {
    player_id,             %玩家id
    guild_id = 0,          %公会ID
    tech_items = []        %科技技能[{tech_id,tech_lv}]
}).


%%玩家升级公会每日升级次数
-record(player_guild_count, {
    player_id,
    daily_task_count = []   %日常提升贡献值剩余使用次数[{BuildingType:建筑类型, Num:次数}]
}).

%%玩家公会圣物列表
-record(player_guild_saint_tab, {
    player_id,
    guild_saint_list = []   %公会圣物列表 [{SaintId:圣物Id, SaintStatus:圣物状态(0:未领,1：已领)}]
}).