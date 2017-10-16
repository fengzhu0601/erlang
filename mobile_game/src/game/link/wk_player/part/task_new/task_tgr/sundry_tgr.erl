%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 22. 七月 2015 下午4:20
%%%-------------------------------------------------------------------
-module(sundry_tgr).
-author("clark").

%% API
-export([handle_event/4]).

-include("inc.hrl").

-include("task_tgr.hrl").
-include("player.hrl").
-include("task_new_def.hrl").
-include("task_def.hrl").
-include("load_task_progress.hrl").
-include("system_log.hrl").

-define(TASK_GOAL,
    [
        {?task_ev_gem_he_cheng, ?ev_gem_he_cheng, 1},
        {?task_ev_pet_hatching, ?ev_pet_hatching, 1},
        {?task_ev_pet_advance, ?ev_pet_advance, 1},
        {?task_ev_pet_skill_level, ?ev_pet_skill_level, 1},
        {?task_ev_pet_treasure, ?ev_pet_treasure, 1},
        {?task_ev_guild_tech_level, ?ev_guild_tech_level, 2},
        {?task_ev_guild_activity, ?ev_guild_activity, 1},
        {?task_ev_friend_add, ?ev_friend_add, 1},
        {?task_ev_crown_exchange, ?ev_crown_exchange, 1},
        {?task_ev_crown_imbue, ?ev_crown_imbue, 1},
        {?task_ev_crown_level, ?ev_crown_level, 1},
        {?task_ev_arena_pve_fight, ?ev_arena_pve_fight, 2},
        {?task_ev_arena_pev_fight_win, ?ev_arena_pve_win, 2},
        {?task_ev_seller_buy_item, ?ev_seller_buy_item, 1},
        {?task_ev_get_item, ?ev_get_item, 1},
        {?task_ev_equ_he_cheng, ?ev_equ_he_cheng, 1},
        {?task_ev_equ_ji_cheng, ?ev_equ_ji_cheng, 1},
        {?task_ev_equ_qiang_hua, ?ev_equ_qiang_hua, 1},
        {?task_ev_equ_xiangqian, ?ev_equ_xiangqian, 1},
        {?task_ev_nine_star_pass_ins, ?ev_nine_star_pass_ins, 2}
    ]).



reset(TgrDBID) ->
    case TgrDBID of
        {TaskType, TaskId, _Key} ->
            TaskDdId = {TaskType, TaskId},
            case load_task_progress:get_task_new_cfg(TaskId) of
                #task_new_cfg{id = TaskId, goal_type = GoalType, type = Type, goal = Goal} ->
                    case lists:keyfind(GoalType, 1, ?TASK_GOAL) of
                        false ->
                            pass;
                        {?task_ev_get_item, ?ev_get_item, 1} ->
                            task_system:reset_task_data(TaskDdId),
                            event_eng:unreg(?ev_get_item, {task, TaskId});
                        {_GoalType, Event, 1} ->
                            task_system:reset_task_data(TaskDdId),
                            event_eng:unreg(Event, {task, TaskDdId});
                        {_GoalType, _Event, 2} ->
                            pass
                    end;
                ?none ->
                    pass
            end;
        _ ->
            pass
    end,
    ok.




start(TgrDBID) ->
    %?DEBUG_LOG("sundry tgrdbid-----------:~p",[TgrDBID]),
    case TgrDBID of
        {TaskType, TaskId, _Key} ->
            TaskDdId = {TaskType, TaskId},
            case load_task_progress:get_task_new_cfg(TaskId) of
                #task_new_cfg{id = TaskId, goal_type = GoalType, type = Type, goal = Goal} ->
                    case lists:keyfind(GoalType, 1, ?TASK_GOAL) of
                        false ->
                            pass;
                        {?task_ev_get_item, ?ev_get_item, 1} ->
                            {ItemBid, Num} = Goal,
                            ItemNum = goods_bucket:count_item_size(game_res:get_bucket(1), 0, ItemBid),
                            event_eng:reg(?ev_get_item, {?ev_get_item, ItemBid}, {task, TaskDdId}, {?MODULE, handle_event}, Type),
                            task_system:set_tgr_db_data(TaskDdId, {item, Num}, {ItemBid, ItemNum}, true),
                            put(?accpet_get_item_data, ItemBid);
                        {GoalType, Event, 1} ->
                            event_eng:reg(Event, {Event, 0}, {task, TaskDdId}, {?MODULE, handle_event}, Type),
                            task_system:set_tgr_db_data(TaskDdId, Goal, 0, true);
                        {GoalType, Event, 2} ->
                            {GoldId, Num} = Goal,
                            %?DEBUG_LOG("GoalType---------------:~p-----------Goal--------------:~p",[GoalType, Goal]),
                            event_eng:reg(Event, {Event, GoldId}, {task, TaskDdId}, {?MODULE, handle_event}, Type),
                            task_system:set_tgr_db_data(TaskDdId, Num, {GoldId, 0}, true)
                    end;
                ?none ->
                    pass
            end;
        _ ->
            %?DEBUG_LOG("sundry pass--------------------------"),
            pass
    end,
    ok.
stop(_TgrDBID) -> ok.
do(_TgrDBID) -> ok.
can(TgrDBID) ->
    case TgrDBID of
        {TaskType, TaskId, _Key} ->
            TaskDdId = {TaskType, TaskId},
            case task_system:get_tgr_db_data(TaskDdId) of
                ?task_nil ->
                    %?DEBUG_LOG("sundry tgr ----------------false"),
                    false;
                {{item, Num}, {ItemId, _Count}} ->
                    %TaskCfg = load_task_progress:get_task_new_cfg(TaskId),
                    %{ItemBid, G} = TaskCfg#task_new_cfg.goal,
                    NewItemNum = goods_bucket:count_item_size(game_res:get_bucket(1), 0, ItemId),
                    if
                        NewItemNum >= Num ->
                            game_res:del([{ItemId, Num}], ?FLOW_REASON_TASK),
                            true;
                        true ->
                            false
                    end;
                {G, Current} ->
                    %?DEBUG_LOG("sundry_tgr G-------:~p-----Current----:~p",[G, Current]),
                    case Current of
                        {_MonsterId, CurrentNum} ->
                            if
                                CurrentNum >= G ->
                                    true;
                                true ->
                                    false
                            end;
                        Current ->
                            if
                                Current >= G ->
                                    true;
                                true ->
                                    false
                            end
                    end
            end;
        _ ->
            false
    end.

can_accept(_TgrDBID) ->
    true.



handle_event({task, TaskDdId}, {Event, GoldId}, _Type, Value) ->
    %?DEBUG_LOG("sundry event------------------:~p",[{TaskDdId, Event, GoldId, Value}]),
    {TaskType, TaskId} = TaskDdId,
    GoalType = load_task_progress:get_task_goal_type(TaskId),
    case task_system:get_tgr_db_data(TaskDdId) of
        ?task_nil ->
            pass;
        {{item, Num}, {ItemId, Count}} ->
            %NewCurrent = erlang:min(Count + Value, Num),
            NewCurrent = util:get_min(Count+Value, 0, Num),
            NewCount = 
            if
                NewCurrent >= Num, ItemId =:= GoldId ->
                    task_system:try_change_state(TaskDdId),
                    event_eng:unreg(?ev_get_item, {task, TaskId}),
                    Num;
                true ->
                    NewCurrent 
            end,
            task_system:set_tgr_db_data(TaskDdId, {item, Num}, {ItemId, NewCount}, true),
            %?DEBUG_LOG("NewCOunt------------------------------:~p",[NewCount]),
            ?player_send(task_sproto:pkg_msg(?MSG_TASK_PROGRESS, {TaskId, GoalType, ItemId, NewCount}));
        {G, Current} ->
            %?DEBUG_LOG("G---:~p-----Current---:~p",[G, Current]),
            case Current of
                {GoldId, CurrentNum} ->
                    %NewCurrent = erlang:min(CurrentNum + Value, G),
                    NewCurrent = util:get_min(CurrentNum + Value, 0, G),
                    D2 = 
                    if
                        NewCurrent =:= G ->
                            task_system:finish_task_trigger_task(TaskType, TaskId),
                            task_system:try_change_state(TaskDdId),
                            event_eng:unreg(Event, {task, TaskDdId}),
                            {GoldId, G};
                        true ->
                            {GoldId, NewCurrent}
                    end,
                    %?DEBUG_LOG("D2----------------------:~p",[D2]),
                    ?player_send(task_sproto:pkg_msg(?MSG_TASK_PROGRESS, {TaskId, GoalType, GoldId, NewCurrent})),
                    task_system:set_tgr_db_data(TaskDdId, G, D2, true);
                Current ->
                    % NewCurrent = erlang:min(Current + Value, G),
                    NewCurrent = util:get_min(Current+Value, 0, G),
                    %?DEBUG_LOG("Current-----:~p-----Value---:~p",[Current, Value]),
                    D =
                    if
                        NewCurrent =:= G ->
                            task_system:finish_task_trigger_task(TaskType, TaskId),
                            event_eng:unreg(Event, {task, TaskDdId}),
                            task_system:try_change_state(TaskDdId),
                            {G, G};
                        NewCurrent > G ->
                            pass;
                        true ->
                            {G, NewCurrent}
                    end,
                    case D of
                        {NewG, NewCount} ->
                            %?DEBUG_LOG("NewG---------:~p---NewCOunt-------------:~p",[NewG, NewCount]),
                            ?player_send(task_sproto:pkg_msg(?MSG_TASK_PROGRESS, {TaskId, GoalType, 0, NewCount})),
                            task_system:set_tgr_db_data(TaskDdId, G, NewCount, true);
                        _ ->
                            pass
                    end
            end
    end.
