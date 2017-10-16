% -define(ranking_arena, ranking_arena).
% -define(ranking_guild, ranking_guild).
% -define(ranking_lev, ranking_lev).
% -define(ranking_power, ranking_power).
% -define(ranking_friend_score, ranking_friend_score).
% -define(ranking_camp, ranking_camp).
% -define(ranking_camp_god, ranking_camp_god).
% -define(ranking_camp_magic, ranking_camp_magic).
% -define(ranking_camp_person, ranking_camp_person).
% -define(ranking_daily_1, ranking_daily_1). %守卫人鱼公主排行榜
% -define(ranking_daily_2, ranking_daily_2). %桑尼号的试炼排行榜
%%-define(ranking_abyss, ranking_abyss). %虚空深渊挑战
%-define(ranking_sky_ins_kill_player, ranking_sky_ins_kill_player). %天空副本杀人排行榜
%-define(ranking_sky_ins_kill_monster, ranking_sky_ins_kill_monster). %天空副本杀怪排行榜


% %% @doc 特殊称号
% -define(ranking_career_1_power, ranking_career_1_power).
% -define(ranking_career_2_power, ranking_career_2_power).
% -define(ranking_career_3_power, ranking_career_3_power).
% -define(ranking_career_4_power, ranking_career_4_power).


% -define(pd_ranking(Name), {pd_ranking, Name}).
% -define(pd_ranking_tree(Name), {pd_ranking_tree, Name}).
% -define(RANKING_INTERVAL_MINUTE, 1).                       %% 1分钟更新排行榜

-define(ranking_level,          1).
-define(ranking_zhanli,         2).
-define(ranking_arena,          3).
-define(ranking_ac,             4).
-define(ranking_meili,          5).
-define(ranking_abyss,          6).     % 虚空深渊挑战    按积分排的
-define(ranking_guild,          7).     % 公會
-define(ranking_camp,           8).     % 总榜
-define(ranking_camp_god,       9).     % 神榜
-define(ranking_camp_magic,     10).    % 魔榜
-define(ranking_camp_person,    11).    % 人榜
-define(ranking_daily_1,		12). 	% 守卫人鱼公主
-define(ranking_daily_2,		13). 	% 桑尼号的试炼
-define(ranking_sky_ins_kill_monster, 14).
-define(ranking_sky_ins_kill_player, 15).
-define(ranking_suit, 			16).	% 套装排行
-define(ranking_gwgc,           17).
-define(ranking_bounty,         18).    % 赏金排行
-define(ranking_ride,           19).    % 坐骑排行
-define(ranking_pet,            20).    % 宠物排行
-define(ranking_suit_new,       21).    % 套装排行      获得一件套装
-define(ranking_daily_4, 		22).	% 打木桶
-define(ranking_daily_5,		23).	% 摘星星