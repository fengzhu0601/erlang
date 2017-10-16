
% %%%-------------------------------------------------------------------
% %%% @author yujian
% %%% @doc 处理事件信息
% %%%-------------------------------------------------------------------
-module(accomplishments_plugin).

% -include("inc.hrl").
% -include("accomplishments.hrl").

% -define(Type_1, 1). %正常情况，数值累加
% -define(Type_2, 2). %根据事件实时查询数据
% -define(Type_3, 3). %积累数据，数据存储,[data|data]
% -define(Type_4, 4). %调用函数获取目前的总数量
% -define(Type_5, 5). %根据max_value中的具体值，是否和传入的值相等
% -define(Type_6, 6). %传入的值是否大于等于max_value中的具体值

% -define( EVENT_TYPE, [
%                     {?ev_auction_buy_totle,?Type_1},
%                     {?ev_auction_sale_totle,?Type_1},
%                     {?ev_long_wen_activate_totle,?Type_1},
%                     {?ev_player_power,?Type_6},
%                     {?ev_player_level,?Type_1},
%                     {?ev_attr_diamond,?Type_1},
%                     {?ev_branch_task_totle,?Type_1},
%                     {?ev_dress_top_level_equ,{?Type_2, {equip_mng, is_top_level_equ, []}}},
%                     {?ev_equ_qiang_hua_success,?Type_1},
%                     {?ev_task_chapter,?Type_5},
%                     {?ev_equ_qiang_hua,?Type_1},
%                     {?ev_equ_ji_cheng,?Type_1},
%                     {?ev_seller_buy_item,?Type_1},
%                     {?ev_arena_level,?Type_5},
%                     {?ev_arena_pvp_fight,?Type_1},
%                     {?ev_unlock_depot,?Type_1},
%                     {?ev_unlock_bag,?Type_1},
%                     {?ev_kill_boss,?Type_1},
%                     {?ev_daily_task_totle,?Type_1},
%                     {?ev_main_ins_pass,?Type_1},
%                     {?ev_attr_money,?Type_1},
%                     {?ev_kill_monster,?Type_1},
%                     {?ev_pet_totle,?Type_1},
%                     {?ev_pet_skill_level,?Type_1},
%                     {?ev_kill_monster_by_bid,?Type_1},
%                     {?ev_auction_jingjia_totle,?Type_1},
%                     {?ev_arena_multi_pvp_fight,?Type_1},
%                     {?ev_pet_advance,?Type_1},
%                     {?ev_instance_success,?Type_1},
%                     {?ev_friend_score,?Type_1},
%                     {?ev_guild_create,?Type_1},
%                     {?ev_equ_he_cheng,?Type_1},
%                     {?ev_guild_activity,?Type_1},
%                     {?ev_pet_hatching,?Type_1},
%                     {?ev_equ_qiang_hua_fail,?Type_1},
%                     {?ev_buy_item,?Type_1},
%                     {?ev_dress_equ_suit,{?Type_2, {equip_mng, is_equ_all_suit, []}}},
%                     {?ev_arena_fight_all,?Type_1},
%                     {?ev_guild_join,?Type_1},
%                     {?ev_arena_multi_pvp_fail,?Type_1},
%                     {?ev_gem_he_cheng,?Type_1},
%                     {?ev_ins_fail_totle,?Type_1},
%                     {?ev_arena_pve_fail,?Type_1},
%                     {?ev_died,?Type_1},
%                     {?ev_friend_gift_quality,?Type_5},
%                     {?ev_crown_exchange,?Type_1},
%                     {?ev_guild_player_level, ?Type_5},
%                     {?ev_guild_tech_level, ?Type_1},
%                     {?ev_friend_add, ?Type_1},
%                     {?ev_long_wen_level_up_totle, ?Type_1},
%                     {?ev_crown_level, ?Type_1},
%                     {?ev_crown_imbue, ?Type_1},
%                     {?ev_get_item, ?Type_1},
%                     {?ev_friend_gift_num, ?Type_5},
%                     {?ev_crown_type_totle, ?Type_3},
%                     {?ev_convoy_npc, ?Type_1},
%                     {?ev_collect_item, ?Type_1},
%                     {?ev_crown_skill_use_totle, ?Type_1},
%                     {?ev_ins_relive_totle, ?Type_1},
%                     {?ev_arena_pve_fight, ?Type_1},
%                     {?ev_complete_task, ?Type_1},
%                     {?ev_instance_pass_time, ?Type_1},
%                     {?ev_arena_pve_win, ?Type_1},
%                     {?ev_arena_pvp_win, ?Type_1},
%                     {?ev_pet_treasure, ?Type_1},
%                     {?ev_arena_pvp_fail, ?Type_1},
%                     {?ev_equ_xiangqian, ?Type_1},
%                     {?ev_arena_success_all, ?Type_1},
%                     {?ev_arena_multi_pvp_win, ?Type_1},
%                     {?ev_double_hit, ?Type_1},
%                     {?ev_chapter_accomplishment_num, {?Type_4, {accomplishments_mng, chapter_accomplishment_num, []}}}]).


% -export([event/3]).

% event( Event, Achievement, TypeValue ) ->
%     case lists:keyfind(Event, 1, ?EVENT_TYPE) of
%         ?false -> 
%             Achievement;
%         {Event, ?Type_1} ->
%             CFG = accomplishments_mng:cfg(Achievement#achievement.id),
%             MaxValue = lists:nth(Achievement#achievement.level+1, CFG#achievement_cfg.max_value),
%             NewTypeValue = Achievement#achievement.type_value+TypeValue,
%             NewAchievement = Achievement#achievement{status = ?achievement_status_underway, type_value = NewTypeValue},
%             ?if_else(NewTypeValue >= MaxValue,
%                     accomplishments_mng:uplevel(NewAchievement, NewTypeValue),
%                     NewAchievement);
%         {Event, {?Type_2, {Mod, Fun, Arg}}} ->
%             try Mod:Fun(Arg) of
%                 ?true -> accomplishments_mng:uplevel(Achievement, 1);
%                 ?false -> Achievement
%             catch
%                 _C:_W ->
%                     Achievement
%             end;
%         {Event, ?Type_3} ->
%             case lists:member(TypeValue, Achievement#achievement.type_value) of
%                 ?true -> Achievement;
%                 ?false ->
%                     CFG = accomplishments_mng:cfg(Achievement#achievement.id),
%                     MaxValue = lists:nth(Achievement#achievement.level+1, CFG#achievement_cfg.max_value),
%                     NewTypeValue = [TypeValue|Achievement#achievement.type_value],
%                     NewTypeValueLen = length( NewTypeValue ),
%                     NewAchievement = Achievement#achievement{status = ?achievement_status_underway, type_value = NewTypeValue},
%                     ?if_else(NewTypeValueLen >= MaxValue,
%                             accomplishments_mng:uplevel(NewAchievement, NewTypeValue),
%                             NewAchievement)
%             end;
%         {Event, {?Type_4, {Mod, Fun, _Arg}}} ->
%             try Mod:Fun(Achievement#achievement.type_id) of
%                 Int ->
%                     CFG = accomplishments_mng:cfg(Achievement#achievement.id),
%                     MaxValue = lists:nth(Achievement#achievement.level+1, CFG#achievement_cfg.max_value),
%                     NewAchievement = Achievement#achievement{type_value = Int},
%                     ?if_else(Int >= MaxValue,
%                             accomplishments_mng:uplevel(NewAchievement, Int),
%                             NewAchievement)
%             catch
%                 _C:_W ->
%                     Achievement
%             end;
%         {Event, ?Type_5} ->
%                 CFG = accomplishments_mng:cfg(Achievement#achievement.id),
%                 MaxValue = lists:nth(Achievement#achievement.level+1, CFG#achievement_cfg.max_value),
%                 NewAchievement = Achievement#achievement{status = ?achievement_status_underway, type_value = 1},
%                 ?if_else(TypeValue =:= MaxValue,
%                         accomplishments_mng:uplevel(NewAchievement, 1),
%                         NewAchievement);
%         {Event, ?Type_6} ->
%             CFG = accomplishments_mng:cfg(Achievement#achievement.id),
%             MaxValue = lists:nth(Achievement#achievement.level+1, CFG#achievement_cfg.max_value),

%             NewAchievement = Achievement#achievement{status = ?achievement_status_underway, type_value = 1},
%             ?if_else(TypeValue >= MaxValue,
%                 accomplishments_mng:uplevel(NewAchievement, 1),
%                 NewAchievement)
%     end.
% %%
% %% event( ?ev_kill_monster, #achievement{type_id = 0}=Achievement, TypeValue ) ->
% %%     CFG = accomplishments_mng:cfg(Achievement#achievement.id),
% %%     MaxValue = lists:nth(Achievement#achievement.level+1, CFG#achievement_cfg.max_value),
% %%     NewTypeValue = Achievement#achievement.type_value+TypeValue,
% %%     NewAchievement = Achievement#achievement{status = ?achievement_status_underway, type_value = NewTypeValue},
% %%     ?if_else(NewTypeValue >= MaxValue,
% %%              accomplishments_mng:uplevel(NewAchievement, NewTypeValue),
% %%              NewAchievement#achievement{type_value = NewTypeValue});
% %%
% %% event( ?ev_kill_monster, Achievement, TypeValue ) ->
% %%     CFG = accomplishments_mng:cfg(Achievement#achievement.id),
% %%     MaxValue = lists:nth(Achievement#achievement.level+1, CFG#achievement_cfg.max_value),
% %%     NewTypeValue = Achievement#achievement.type_value+TypeValue,
% %%     ?if_else(NewTypeValue >= MaxValue,
% %%              accomplishments_mng:uplevel(Achievement, NewTypeValue),
% %%              Achievement);
% %%
% %% event( ?ev_kill_boss, Achievement, TypeValue ) ->
% %%     CFG = accomplishments_mng:cfg(Achievement#achievement.id),
% %%     MaxValue = lists:nth(Achievement#achievement.level+1, CFG#achievement_cfg.max_value),
% %%     NewTypeValue = Achievement#achievement.type_value+TypeValue,
% %%     ?if_else(NewTypeValue >= MaxValue,
% %%              accomplishments_mng:uplevel(Achievement, NewTypeValue),
% %%              Achievement#achievement{type_value=NewTypeValue});
% %%
% %% %% 复活次数不能大于多少
% %% event( ?ev_died, Achievement, {_Diff, TypeValue} ) ->
% %%     CFG = accomplishments_mng:cfg(Achievement#achievement.id),
% %%     MaxValue = lists:nth(Achievement#achievement.level+1, CFG#achievement_cfg.max_value),
% %%     ?if_else(TypeValue =<  MaxValue,
% %%              accomplishments_mng:uplevel(Achievement, TypeValue),
% %%              Achievement);
% %%
% %% event( ?ev_instance_pass_time, Achievement, TypeValue ) ->
% %%     CFG = accomplishments_mng:cfg(Achievement#achievement.id),
% %%     MaxValue = lists:nth(Achievement#achievement.level+1, CFG#achievement_cfg.max_value),
% %%     ?if_else(TypeValue =< MaxValue,
% %%              accomplishments_mng:uplevel(Achievement, TypeValue),
% %%              Achievement);
% %%
% %% event(_Event, _Arg, _Value) ->
% %%     {error, "no this event"}.
