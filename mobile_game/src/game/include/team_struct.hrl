
%% 队伍信息
-record(team,
{
    id,               %%队伍id
    team_name,        %%队伍名字
    pid,              %%队伍pid
    members = [],     %%队伍成员
    power = 0,        %%队伍战力
    type = 0,         %%队伍类型
    master_id,        %%队长id
    auto_flg=0,       
    team_msg = []     %%申请入队的列表信息
}).

-ifndef(TEAM_MEMBERS_MAX).
%% 队伍最多人数
-define(TEAM_MEMBERS_MAX, 3).
-endif.

-ifndef(TEAM_TYPE_MULTI_ARENA).
%% 队伍类型
-define(TEAM_TYPE_MULTI_ARENA, 1).  %% 多人竞技场队伍
-endif.

-define(TEAM_TYPE_GONGCHENG, 3).    %% 怪物攻城

-ifndef(TEAM_TYPES).
-define(TEAM_TYPES, [?TEAM_TYPE_MULTI_ARENA, ?TEAM_TYPE_GONGCHENG]).  %% 队伍类型
-endif.

%% 队员信息
-record(team_member,
{
    id,          %% 角色id
    name,        %% 角色名字
    lev,         %% 角色等级
    career,      %% 角色职业
    power,       %% 角色战力
    max_hp,      %% 角色最大血量
    online       %% 在线/离线  1在线0离线
}).

-define(team_mem_index, team_mem_index).%% 存的是玩家id对应的组队id
-define(team_type_index, team_type_index). %% 存的是组队类型对应的队伍id
-define(team_info, team_info). %% 存的是组队信息
-define(is_full_team_id_list, team_is_full_team_id_list).%% 没有满的队伍列表

-define(team_is_auto_flg, team_is_auto_flg).    %% 设置队伍自动允许加入

