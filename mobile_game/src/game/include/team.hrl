-ifdef(TEAM_HRL).
-else.

    % 队伍信息
    -record(team_info, {
            id,                 % 队伍id
            master_id,          % 队长id
            max_member_num,     % 最大人数
            members = [],       % 成员列表
            scene_id_list = [], % 队伍对应的场景
            state = 0,          % 队伍状态(0：等待  1：开始 2：完成)
            start_time = 0      % 开始时间戳
        }).

    -record(member_info, {
            player_id,
            name,
            level,
            combar_power,
            career,
            max_hp,
            ex_list = []
        }).

    % 队伍状态
    -define(TEAM_STATE_WAIT, 0).    %% 等待状态
    -define(TEAM_STATE_START, 1).   %% 开始状态

    % 队伍类型
    -define(TEAM_TYPE_MULTI_ARENA, 1).  %% 多人竞技场队伍
    -define(TEAM_TYPE_MAIN_INS, 2).     %% 对人组队副本

    -define(TEAM_TYPES, [?TEAM_TYPE_MULTI_ARENA, ?TEAM_TYPE_MAIN_INS]).  %% 队伍类型

    -define(TEAM_MULTI_ARENA_MAX_MEMBERS, 3).

-endif.
