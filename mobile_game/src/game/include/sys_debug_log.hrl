%%==============auto generate hrl (time:{{2015,12,4},{1,47,15}})==================
-ifndef(SYS_DEBUG_LOG_HRL_).
-define(SYS_DEBUG_LOG_HRL_,1).
-include_lib("common/include/com_log.hrl").

-include("sys_debug_log_enable.hrl").

%% sproto 
-ifdef(enable_debug_log_sproto).
-define(debug_log_sproto(_MSG), ?DEBUG_LOG_COLOR(?color_blue,"<sproto>" _MSG)).
-define(debug_log_sproto(_FMT,_MSG), ?DEBUG_LOG_COLOR(?color_blue,"<sproto>" _FMT,_MSG)).
-else.
-define(debug_log_sproto(_MSG), ok).
-define(debug_log_sproto(_FMT,_MSG), ok).
-endif.

%% team 
-ifdef(enable_debug_log_team).
-define(debug_log_team(_MSG), ?DEBUG_LOG_COLOR(?color_blue,"<team>" _MSG)).
-define(debug_log_team(_FMT,_MSG), ?DEBUG_LOG_COLOR(?color_blue,"<team>" _FMT,_MSG)).
-else.
-define(debug_log_team(_MSG), ok).
-define(debug_log_team(_FMT,_MSG), ok).
-endif.

%% item 
-ifdef(enable_debug_log_item).
-define(debug_log_item(_MSG), ?DEBUG_LOG_COLOR(?color_none,"<item>" _MSG)).
-define(debug_log_item(_FMT,_MSG), ?DEBUG_LOG_COLOR(?color_none,"<item>" _FMT,_MSG)).
-else.
-define(debug_log_item(_MSG), ok).
-define(debug_log_item(_FMT,_MSG), ok).
-endif.

%% gm 
-ifdef(enable_debug_log_gm).
-define(debug_log_gm(_MSG), ?DEBUG_LOG_COLOR(?color_none,"<gm>" _MSG)).
-define(debug_log_gm(_FMT,_MSG), ?DEBUG_LOG_COLOR(?color_none,"<gm>" _FMT,_MSG)).
-else.
-define(debug_log_gm(_MSG), ok).
-define(debug_log_gm(_FMT,_MSG), ok).
-endif.

%% shop 
-ifdef(enable_debug_log_shop).
-define(debug_log_shop(_MSG), ?DEBUG_LOG_COLOR(?color_none,"<shop>" _MSG)).
-define(debug_log_shop(_FMT,_MSG), ?DEBUG_LOG_COLOR(?color_none,"<shop>" _FMT,_MSG)).
-else.
-define(debug_log_shop(_MSG), ok).
-define(debug_log_shop(_FMT,_MSG), ok).
-endif.

%% equip 
-ifdef(enable_debug_log_equip).
-define(debug_log_equip(_MSG), ?DEBUG_LOG_COLOR(?color_none,"<equip>" _MSG)).
-define(debug_log_equip(_FMT,_MSG), ?DEBUG_LOG_COLOR(?color_none,"<equip>" _FMT,_MSG)).
-else.
-define(debug_log_equip(_MSG), ok).
-define(debug_log_equip(_FMT,_MSG), ok).
-endif.

%% mail 
-ifdef(enable_debug_log_mail).
-define(debug_log_mail(_MSG), ?DEBUG_LOG_COLOR(?color_none,"<mail>" _MSG)).
-define(debug_log_mail(_FMT,_MSG), ?DEBUG_LOG_COLOR(?color_none,"<mail>" _FMT,_MSG)).
-else.
-define(debug_log_mail(_MSG), ok).
-define(debug_log_mail(_FMT,_MSG), ok).
-endif.

%% accomplishments 
-ifdef(enable_debug_log_accomplishments).
-define(debug_log_accomplishments(_MSG), ?DEBUG_LOG_COLOR(?color_none,"<accomplishments>" _MSG)).
-define(debug_log_accomplishments(_FMT,_MSG), ?DEBUG_LOG_COLOR(?color_none,"<accomplishments>" _FMT,_MSG)).
-else.
-define(debug_log_accomplishments(_MSG), ok).
-define(debug_log_accomplishments(_FMT,_MSG), ok).
-endif.

%% timer_eng 
-ifdef(enable_debug_log_timer_eng).
-define(debug_log_timer_eng(_MSG), ?DEBUG_LOG_COLOR(?color_none,"<timer_eng>" _MSG)).
-define(debug_log_timer_eng(_FMT,_MSG), ?DEBUG_LOG_COLOR(?color_none,"<timer_eng>" _FMT,_MSG)).
-else.
-define(debug_log_timer_eng(_MSG), ok).
-define(debug_log_timer_eng(_FMT,_MSG), ok).
-endif.

%% main_ins 
-ifdef(enable_debug_log_main_ins).
-define(debug_log_main_ins(_MSG), ?DEBUG_LOG_COLOR(?color_none,"<main_ins>" _MSG)).
-define(debug_log_main_ins(_FMT,_MSG), ?DEBUG_LOG_COLOR(?color_none,"<main_ins>" _FMT,_MSG)).
-else.
-define(debug_log_main_ins(_MSG), ok).
-define(debug_log_main_ins(_FMT,_MSG), ok).
-endif.

%% team_ins 
-ifdef(enable_debug_log_team_ins).
-define(debug_log_team_ins(_MSG), ?DEBUG_LOG_COLOR(?color_none,"<team_ins>" _MSG)).
-define(debug_log_team_ins(_FMT,_MSG), ?DEBUG_LOG_COLOR(?color_none,"<team_ins>" _FMT,_MSG)).
-else.
-define(debug_log_team_ins(_MSG), ok).
-define(debug_log_team_ins(_FMT,_MSG), ok).
-endif.

%% crown 
-ifdef(enable_debug_log_crown).
-define(debug_log_crown(_MSG), ?DEBUG_LOG_COLOR(?color_none,"<crown>" _MSG)).
-define(debug_log_crown(_FMT,_MSG), ?DEBUG_LOG_COLOR(?color_none,"<crown>" _FMT,_MSG)).
-else.
-define(debug_log_crown(_MSG), ok).
-define(debug_log_crown(_FMT,_MSG), ok).
-endif.

%% family 
-ifdef(enable_debug_log_family).
-define(debug_log_family(_MSG), ?DEBUG_LOG_COLOR(?color_none,"<family>" _MSG)).
-define(debug_log_family(_FMT,_MSG), ?DEBUG_LOG_COLOR(?color_none,"<family>" _FMT,_MSG)).
-else.
-define(debug_log_family(_MSG), ok).
-define(debug_log_family(_FMT,_MSG), ok).
-endif.

%% buff 
-ifdef(enable_debug_log_buff).
-define(debug_log_buff(_MSG), ?DEBUG_LOG_COLOR(?color_none,"<buff>" _MSG)).
-define(debug_log_buff(_FMT,_MSG), ?DEBUG_LOG_COLOR(?color_none,"<buff>" _FMT,_MSG)).
-else.
-define(debug_log_buff(_MSG), ok).
-define(debug_log_buff(_FMT,_MSG), ok).
-endif.

%% bag 
-ifdef(enable_debug_log_bag).
-define(debug_log_bag(_MSG), ?DEBUG_LOG_COLOR(?color_none,"<bag>" _MSG)).
-define(debug_log_bag(_FMT,_MSG), ?DEBUG_LOG_COLOR(?color_none,"<bag>" _FMT,_MSG)).
-else.
-define(debug_log_bag(_MSG), ok).
-define(debug_log_bag(_FMT,_MSG), ok).
-endif.

%% scene_bag 
-ifdef(enable_debug_log_scene_bag).
-define(debug_log_scene_bag(_MSG), ?DEBUG_LOG_COLOR(?color_none,"<scene_bag>" _MSG)).
-define(debug_log_scene_bag(_FMT,_MSG), ?DEBUG_LOG_COLOR(?color_none,"<scene_bag>" _FMT,_MSG)).
-else.
-define(debug_log_scene_bag(_MSG), ok).
-define(debug_log_scene_bag(_FMT,_MSG), ok).
-endif.

%% field_boss_ins 
-ifdef(enable_debug_log_field_boss_ins).
-define(debug_log_field_boss_ins(_MSG), ?DEBUG_LOG_COLOR(?color_none,"<field_boss_ins>" _MSG)).
-define(debug_log_field_boss_ins(_FMT,_MSG), ?DEBUG_LOG_COLOR(?color_none,"<field_boss_ins>" _FMT,_MSG)).
-else.
-define(debug_log_field_boss_ins(_MSG), ok).
-define(debug_log_field_boss_ins(_FMT,_MSG), ok).
-endif.

%% scene_ins 
-ifdef(enable_debug_log_scene_ins).
-define(debug_log_scene_ins(_MSG), ?DEBUG_LOG_COLOR(?color_none,"<scene_ins>" _MSG)).
-define(debug_log_scene_ins(_FMT,_MSG), ?DEBUG_LOG_COLOR(?color_none,"<scene_ins>" _FMT,_MSG)).
-else.
-define(debug_log_scene_ins(_MSG), ok).
-define(debug_log_scene_ins(_FMT,_MSG), ok).
-endif.

%% scene_aoi 
-ifdef(enable_debug_log_scene_aoi).
-define(debug_log_scene_aoi(_MSG), ?DEBUG_LOG_COLOR(?color_none,"<scene_aoi>" _MSG)).
-define(debug_log_scene_aoi(_FMT,_MSG), ?DEBUG_LOG_COLOR(?color_none,"<scene_aoi>" _FMT,_MSG)).
-else.
-define(debug_log_scene_aoi(_MSG), ok).
-define(debug_log_scene_aoi(_FMT,_MSG), ok).
-endif.

%% scene_drop 
-ifdef(enable_debug_log_scene_drop).
-define(debug_log_scene_drop(_MSG), ?DEBUG_LOG_COLOR(?color_none,"<scene_drop>" _MSG)).
-define(debug_log_scene_drop(_FMT,_MSG), ?DEBUG_LOG_COLOR(?color_none,"<scene_drop>" _FMT,_MSG)).
-else.
-define(debug_log_scene_drop(_MSG), ok).
-define(debug_log_scene_drop(_FMT,_MSG), ok).
-endif.

%% scene_portal 
-ifdef(enable_debug_log_scene_portal).
-define(debug_log_scene_portal(_MSG), ?DEBUG_LOG_COLOR(?color_none,"<scene_portal>" _MSG)).
-define(debug_log_scene_portal(_FMT,_MSG), ?DEBUG_LOG_COLOR(?color_none,"<scene_portal>" _FMT,_MSG)).
-else.
-define(debug_log_scene_portal(_MSG), ok).
-define(debug_log_scene_portal(_FMT,_MSG), ok).
-endif.

%% scene_mng 
-ifdef(enable_debug_log_scene_mng).
-define(debug_log_scene_mng(_MSG), ?DEBUG_LOG_COLOR(?color_none,"<scene_mng>" _MSG)).
-define(debug_log_scene_mng(_FMT,_MSG), ?DEBUG_LOG_COLOR(?color_none,"<scene_mng>" _FMT,_MSG)).
-else.
-define(debug_log_scene_mng(_MSG), ok).
-define(debug_log_scene_mng(_FMT,_MSG), ok).
-endif.

%% scene_player 
-ifdef(enable_debug_log_scene_player).
-define(debug_log_scene_player(_MSG), ?DEBUG_LOG_COLOR(?color_none,"<scene_player>" _MSG)).
-define(debug_log_scene_player(_FMT,_MSG), ?DEBUG_LOG_COLOR(?color_none,"<scene_player>" _FMT,_MSG)).
-else.
-define(debug_log_scene_player(_MSG), ok).
-define(debug_log_scene_player(_FMT,_MSG), ok).
-endif.

%% scene 
-ifdef(enable_debug_log_scene).
-define(debug_log_scene(_MSG), ?DEBUG_LOG_COLOR(?color_none,"<scene>" _MSG)).
-define(debug_log_scene(_FMT,_MSG), ?DEBUG_LOG_COLOR(?color_none,"<scene>" _FMT,_MSG)).
-else.
-define(debug_log_scene(_MSG), ok).
-define(debug_log_scene(_FMT,_MSG), ok).
-endif.

%% scene_ss 
-ifdef(enable_debug_log_scene_ss).
-define(debug_log_scene_ss(_MSG), ?DEBUG_LOG_COLOR(?color_none,"<scene_ss>" _MSG)).
-define(debug_log_scene_ss(_FMT,_MSG), ?DEBUG_LOG_COLOR(?color_none,"<scene_ss>" _FMT,_MSG)).
-else.
-define(debug_log_scene_ss(_MSG), ok).
-define(debug_log_scene_ss(_FMT,_MSG), ok).
-endif.

%% player 
-ifdef(enable_debug_log_player).
-define(debug_log_player(_MSG), ?DEBUG_LOG_COLOR(?color_blue,"<player>" _MSG)).
-define(debug_log_player(_FMT,_MSG), ?DEBUG_LOG_COLOR(?color_blue,"<player>" _FMT,_MSG)).
-else.
-define(debug_log_player(_MSG), ok).
-define(debug_log_player(_FMT,_MSG), ok).
-endif.

%% skill_mng 
-ifdef(enable_debug_log_skill_mng).
-define(debug_log_skill_mng(_MSG), ?DEBUG_LOG_COLOR(?color_none,"<skill_mng>" _MSG)).
-define(debug_log_skill_mng(_FMT,_MSG), ?DEBUG_LOG_COLOR(?color_none,"<skill_mng>" _FMT,_MSG)).
-else.
-define(debug_log_skill_mng(_MSG), ok).
-define(debug_log_skill_mng(_FMT,_MSG), ok).
-endif.

%% scene_monster 
-ifdef(enable_debug_log_scene_monster).
-define(debug_log_scene_monster(_MSG), ?DEBUG_LOG_COLOR(?color_none,"<scene_monster>" _MSG)).
-define(debug_log_scene_monster(_FMT,_MSG), ?DEBUG_LOG_COLOR(?color_none,"<scene_monster>" _FMT,_MSG)).
-else.
-define(debug_log_scene_monster(_MSG), ok).
-define(debug_log_scene_monster(_FMT,_MSG), ok).
-endif.

%% monster_ai 
-ifdef(enable_debug_log_monster_ai).
-define(debug_log_monster_ai(_MSG), ?DEBUG_LOG_COLOR(?color_none,"<monster_ai>" _MSG)).
-define(debug_log_monster_ai(_FMT,_MSG), ?DEBUG_LOG_COLOR(?color_none,"<monster_ai>" _FMT,_MSG)).
-else.
-define(debug_log_monster_ai(_MSG), ok).
-define(debug_log_monster_ai(_FMT,_MSG), ok).
-endif.

%% task_mng 
-ifdef(enable_debug_log_task_mng).
-define(debug_log_task_mng(_MSG), ?DEBUG_LOG_COLOR(?color_none,"<task_mng>" _MSG)).
-define(debug_log_task_mng(_FMT,_MSG), ?DEBUG_LOG_COLOR(?color_none,"<task_mng>" _FMT,_MSG)).
-else.
-define(debug_log_task_mng(_MSG), ok).
-define(debug_log_task_mng(_FMT,_MSG), ok).
-endif.

%% vip 
-ifdef(enable_debug_log_vip).
-define(debug_log_vip(_MSG), ?DEBUG_LOG_COLOR(?color_none,"<vip>" _MSG)).
-define(debug_log_vip(_FMT,_MSG), ?DEBUG_LOG_COLOR(?color_none,"<vip>" _FMT,_MSG)).
-else.
-define(debug_log_vip(_MSG), ok).
-define(debug_log_vip(_FMT,_MSG), ok).
-endif.

%% scene_fight 
-ifdef(enable_debug_log_scene_fight).
-define(debug_log_scene_fight(_MSG), ?DEBUG_LOG_COLOR(?color_none,"<scene_fight>" _MSG)).
-define(debug_log_scene_fight(_FMT,_MSG), ?DEBUG_LOG_COLOR(?color_none,"<scene_fight>" _FMT,_MSG)).
-else.
-define(debug_log_scene_fight(_MSG), ok).
-define(debug_log_scene_fight(_FMT,_MSG), ok).
-endif.

%% scene_device 
-ifdef(enable_debug_log_scene_device).
-define(debug_log_scene_device(_MSG), ?DEBUG_LOG_COLOR(?color_none,"<scene_device>" _MSG)).
-define(debug_log_scene_device(_FMT,_MSG), ?DEBUG_LOG_COLOR(?color_none,"<scene_device>" _FMT,_MSG)).
-else.
-define(debug_log_scene_device(_MSG), ok).
-define(debug_log_scene_device(_FMT,_MSG), ok).
-endif.

%% friend 
-ifdef(enable_debug_log_friend).
-define(debug_log_friend(_MSG), ?DEBUG_LOG_COLOR(?color_none,"<friend>" _MSG)).
-define(debug_log_friend(_FMT,_MSG), ?DEBUG_LOG_COLOR(?color_none,"<friend>" _FMT,_MSG)).
-else.
-define(debug_log_friend(_MSG), ok).
-define(debug_log_friend(_FMT,_MSG), ok).
-endif.

%% friend2 
-ifdef(enable_debug_log_friend2).
-define(debug_log_friend2(_MSG), ?DEBUG_LOG_COLOR(?color_none,"<friend2>" _MSG)).
-define(debug_log_friend2(_FMT,_MSG), ?DEBUG_LOG_COLOR(?color_none,"<friend2>" _FMT,_MSG)).
-else.
-define(debug_log_friend2(_MSG), ok).
-define(debug_log_friend2(_FMT,_MSG), ok).
-endif.

%% arena 
-ifdef(enable_debug_log_arena).
-define(debug_log_arena(_MSG), ?DEBUG_LOG_COLOR(?color_cyan,"<arena>" _MSG)).
-define(debug_log_arena(_FMT,_MSG), ?DEBUG_LOG_COLOR(?color_cyan,"<arena>" _FMT,_MSG)).
-else.
-define(debug_log_arena(_MSG), ok).
-define(debug_log_arena(_FMT,_MSG), ok).
-endif.

%% auction 
-ifdef(enable_debug_log_auction).
-define(debug_log_auction(_MSG), ?DEBUG_LOG_COLOR(?color_purple,"<auction>" _MSG)).
-define(debug_log_auction(_FMT,_MSG), ?DEBUG_LOG_COLOR(?color_purple,"<auction>" _FMT,_MSG)).
-else.
-define(debug_log_auction(_MSG), ok).
-define(debug_log_auction(_FMT,_MSG), ok).
-endif.

%% chat 
-ifdef(enable_debug_log_chat).
-define(debug_log_chat(_MSG), ?DEBUG_LOG_COLOR(?color_none,"<chat>" _MSG)).
-define(debug_log_chat(_FMT,_MSG), ?DEBUG_LOG_COLOR(?color_none,"<chat>" _FMT,_MSG)).
-else.
-define(debug_log_chat(_MSG), ok).
-define(debug_log_chat(_FMT,_MSG), ok).
-endif.

%% pet 
-ifdef(enable_debug_log_pet).
-define(debug_log_pet(_MSG), ?DEBUG_LOG_COLOR(?color_none,"<pet>" _MSG)).
-define(debug_log_pet(_FMT,_MSG), ?DEBUG_LOG_COLOR(?color_none,"<pet>" _FMT,_MSG)).
-else.
-define(debug_log_pet(_MSG), ok).
-define(debug_log_pet(_FMT,_MSG), ok).
-endif.

%% scene_pet 
-ifdef(enable_debug_log_scene_pet).
-define(debug_log_scene_pet(_MSG), ?DEBUG_LOG_COLOR(?color_none,"<scene_pet>" _MSG)).
-define(debug_log_scene_pet(_FMT,_MSG), ?DEBUG_LOG_COLOR(?color_none,"<scene_pet>" _FMT,_MSG)).
-else.
-define(debug_log_scene_pet(_MSG), ok).
-define(debug_log_scene_pet(_FMT,_MSG), ok).
-endif.

%% pet_ai 
-ifdef(enable_debug_log_pet_ai).
-define(debug_log_pet_ai(_MSG), ?DEBUG_LOG_COLOR(?color_none,"<pet_ai>" _MSG)).
-define(debug_log_pet_ai(_FMT,_MSG), ?DEBUG_LOG_COLOR(?color_none,"<pet_ai>" _FMT,_MSG)).
-else.
-define(debug_log_pet_ai(_MSG), ok).
-define(debug_log_pet_ai(_FMT,_MSG), ok).
-endif.

%% attr 
-ifdef(enable_debug_log_attr).
-define(debug_log_attr(_MSG), ?DEBUG_LOG_COLOR(?color_red,"<attr>" _MSG)).
-define(debug_log_attr(_FMT,_MSG), ?DEBUG_LOG_COLOR(?color_red,"<attr>" _FMT,_MSG)).
-else.
-define(debug_log_attr(_MSG), ok).
-define(debug_log_attr(_FMT,_MSG), ok).
-endif.

-endif.
