%% 竞技场类型
-define(ARENA_TYPE_P2E, 1).                   %% 人机模式
-define(ARENA_TYPE_P2P, 2).                   %% p2p模式
-define(ARENA_TYPE_MULTI_P2P, 3).             %% 多人p2p模式
-define(ARENA_TYPE_COMPETE, 4).               %% 切磋

-define(player_arena_tab, player_arena_tab).   %% 竞技场数据表

-define(pd_arena_match, pd_arena_match).       %% 竞技场匹配参数


-define(day_arena_p2e_count, day_arena_p2e_count).             %% p2e次数
-define(day_arena_p2p_count, day_arena_p2p_count).             %% p2p次数
-define(day_arena_multi_p2p_count, day_arena_multi_p2p_count). %% multi_p2p次数


-define(team_id_to_arena_pid, team_id_to_arena_pid).        %% 队伍id和竞技场pid的映射
-define(player_id_to_arena_pid, player_id_to_arena_pid).    %% 角色id和竞技场pid的映射
-define(p2p_match, p2p_match).                              %% p2p匹配
-define(multi_p2p_match_team, multi_p2p_match_team).        %% 多人匹配模式(待匹配队伍
-define(multi_p2p_join_team, multi_p2p_join_team).          %% 多人匹配模式(待加入队伍



-define(pd_day_p2e_cent_limit, pd_day_p2e_cent_limit).  %% p2e获取分数限制
-define(pd_day_p2p_cent_limit, pd_day_p2p_cent_limit).  %% p2p获取分数限制
-define(ADD_CENT_COUNT, 3). %% 加分次数
