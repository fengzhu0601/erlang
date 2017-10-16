%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 20. 七月 2015 下午5:38
%%%-------------------------------------------------------------------
-module(task_tgr_builder).
-author("clark").

%% API
-export([get_tgrs/3]).

-include("task_def.hrl").
-include("task_new_def.hrl").
-include("player_def.hrl").
-include("load_task_progress.hrl").



get_tgrs(TaskType, TaskID, State) ->
    TgrList =
        case State of
            ?task_accepting ->
                util:list_from_for(get_accept_tgr(), build_tgr(TaskType, TaskID));
            ?task_submiting ->
                util:list_from_for(get_submit_tgr(TaskType), build_tgr(TaskType, TaskID));
            ?task_finishing ->
                util:list_from_for(get_finish_tgr(), build_tgr(TaskType, TaskID))
        end,
    lists:append(TgrList, []).




%%-------------------------------------------
%% private:
%%-------------------------------------------
%% 获得触发器的DBID
get_tgr_dbid(TaskType, TaskID, Key) ->
    {TaskType, TaskID, Key}.


%% 创建触发器
build_tgr(TaskType, TaskID) ->
    fun(Key) ->
        Tgr =
        case Key of
            #task_new_cfg.publish_trigger -> accept_newbie_guide_task_tgr;     %% accept task trigger
            #task_new_cfg.finish_trigger -> finish_task_trigger_tgr;          %% finish task trigger
            #task_new_cfg.submit_trigger -> submit_task_trigger_tgr;          %% submit task trigger
            #task_new_cfg.prize -> prize_tgr;                        %% 任务奖励
            #task_new_cfg.limit_level -> lvl_tgr;                          %% 等级限制
            #task_new_cfg.submit_npc -> talk_npc_tgr;                     %% 对话
            _ ->
                case load_task_progress:get_task_cfg_field(TaskID, Key) of
                    [] -> ?task_nil;
                    undefined -> ?task_nil;
                    0 -> ?task_nil;
                    ?TG_KILL_MONSTER -> kill_monster_tgr;               %% 杀怪
                    ?TG_NPC_TALK -> talk_npc_tgr;                   %% 对话
                    ?TG_COLLECT_VIRTUAL_GOODS -> collect_thing_tgr;              %% 采集物品
                    ?TG_BUY_ITEM -> prize_tgr;                      %% 购买物品
                    %?TG_CONVOY_NPC                  -> prize_tgr;                      %% 护送NPC
                    ?TG_GUARD_FRONTIER -> prize_tgr;                      %% 守卫
                    ?TG_SINGLE_INSTANCE -> single_dig_tgr;                 %% 单人副本
                    ?task_ev_mount -> mount_tgr;
                    ?task_ev_blessing -> blessing_tgr;
                    ?task_ev_nine_star_pass_ins -> sundry_tgr;
                    ?task_ev_gem_he_cheng -> sundry_tgr;                     %% 宝石合成
                    ?task_ev_pet_hatching -> sundry_tgr;                     %% 杂项
                    ?task_ev_pet_advance -> sundry_tgr;                     %% 杂项
                    ?task_ev_pet_skill_level -> sundry_tgr;                     %% 杂项
                    ?task_ev_pet_treasure -> sundry_tgr;                     %% 杂项
                    ?task_ev_guild_tech_level -> sundry_tgr;                     %% 杂项
                    ?task_ev_guild_activity -> sundry_tgr;                     %% 杂项
                    ?task_ev_friend_add -> sundry_tgr;                     %% 杂项
                    ?task_ev_crown_exchange -> sundry_tgr;                     %% 杂项
                    ?task_ev_crown_imbue -> sundry_tgr;                     %% 杂项
                    ?task_ev_crown_level -> sundry_tgr;                     %% 杂项
                    ?task_ev_arena_pve_fight -> sundry_tgr;                     %% 杂项
                    ?task_ev_arena_pev_fight_win -> sundry_tgr;                     %% 杂项
                    ?task_ev_seller_buy_item -> sundry_tgr;                     %% 杂项
                    ?task_ev_get_item -> sundry_tgr;                     %% 杂项
                    ?task_ev_equ_he_cheng -> sundry_tgr;                     %% 杂项
                    ?task_ev_equ_ji_cheng -> sundry_tgr;                     %% 杂项
                    ?task_ev_equ_qiang_hua -> sundry_tgr;                     %% 杂项
                    ?task_ev_equ_xiangqian -> sundry_tgr;                     %% 杂项
                    _ ->
                        ?task_nil
                end
        end,
        case Tgr of
            ?task_nil ->
                ?task_nil;
            _ ->
                DBID = get_tgr_dbid(TaskType, TaskID, get_key(Key)),
                {Tgr, DBID}
        end
    end.

get_key(Key) ->
    case Key of
        #task_new_cfg.goal_type ->
            #task_new_cfg.goal;
        _ ->
            Key
    end.



%% 配置表Key
-define(accept_tgr_key1, [#task_new_cfg.limit_level, #task_new_cfg.goal_type, #task_new_cfg.publish_trigger]).
-define(accept_tgr_key2, [#task_new_cfg.limit_level, #task_new_cfg.goal_type]).
-define(finish_tgr_key1, [#task_new_cfg.finish_trigger]).
-define(finish_tgr_key2, []).
-define(submit_tgr_key1, [#task_new_cfg.prize, #task_new_cfg.goal_type, #task_new_cfg.submit_trigger]).
-define(submit_tgr_key2, [#task_new_cfg.prize, #task_new_cfg.goal_type]).
-define(submit_tgr_key3, [#task_new_cfg.prize, #task_new_cfg.goal_type, #task_new_cfg.submit_trigger]).
-define(submit_tgr_key4, [#task_new_cfg.prize]).

get_accept_tgr() ->
    IsOpen = attr_new:get(?pd_task_is_open),
    if
        IsOpen =:= undefined; IsOpen =:= 0 ->
            ?accept_tgr_key1;
        true ->
            ?accept_tgr_key2
    end.

get_finish_tgr() ->
    IsOpen = attr_new:get(?pd_task_is_open),
    if
        IsOpen =:= undefined; IsOpen =:= 0 ->
            ?finish_tgr_key1;
        true ->
            ?finish_tgr_key2
    end.


get_submit_tgr(Type) ->
    if
        Type =:= ?daily_task_type; Type =:= ?main_task_type ->
            get_submit_tgr_(1);
        true ->
            get_submit_tgr_(2)
    end.


get_submit_tgr_(1) ->
    IsOpen = attr_new:get(?pd_task_is_open),
    if
        IsOpen =:= undefined;IsOpen =:= 0 ->
            ?submit_tgr_key1;
        true ->
            ?submit_tgr_key2
    end;
get_submit_tgr_(2) ->
    IsOpen = attr_new:get(?pd_task_is_open),
    if
        IsOpen =:= undefined;IsOpen =:= 0 ->
            ?submit_tgr_key3;
        true ->
            ?submit_tgr_key4
    end.