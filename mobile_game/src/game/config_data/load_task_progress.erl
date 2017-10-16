%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 22. 七月 2015 下午2:25
%%%-------------------------------------------------------------------
-module(load_task_progress).
-author("clark").

%% API
-export([
    get_task_cfg/2,  % 获取某个taskcfg
    get_task_cfg_field/2,
    is_complete/2 %某任务是否已经完成
]).

-export([
    init_task_remap/0,
    get_task_type_by_taskid/1,
    get_task_progress_by_taskid/1,
    get_task_type_and_progress/1,
    get_task_type/1,
    get_next_task_id/1,
    get_per_task_id/1,
    is_new_wizard_task/1,
    get_taskid/2,
    get_task_new_cfg/1,
    get_task_unlock_course_boss/1,
    get_task_goal_type/1,
    get_all_unlock_course_boss/0
]).

-include("inc.hrl").
-include("load_task_progress.hrl").
-include_lib("config/include/config.hrl").
-include("task_new_def.hrl").
-include("safe_ets.hrl").
-include("task_def.hrl").
-define(TP, task_progress_remap).
-define(TP2, task_to_progress).

create_safe_ets() ->
    [
        safe_ets:new(?TP, [?named_table, ?public, {?read_concurrency, ?true}, {?write_concurrency, ?true}]),
        safe_ets:new(?TP2, [?named_table, ?public, {?read_concurrency, ?true}, {?write_concurrency, ?true}])
    ].

get_task_unlock_course_boss(TaskId) ->
    case lookup_task_new_cfg(TaskId) of
        #task_new_cfg{unlock_course_boss = InsId} = _Cfg ->
            InsId;
        _ ->
            0
    end.

get_task_type_and_progress(Id) ->
    Type = get_task_type_by_taskid(Id),
    Progress = get_task_progress_by_taskid(Id),
    %?DEBUG_LOG("Id,Type,Progress--------:~p",[{Id, Type, Progress}]),
    if
        Type =/= ?none, Progress =/= ?none ->
            %?DEBUG_LOG("get_task_type_and_progress"),
            {Type, Progress};
        true ->
            false
    end.

get_task_type_by_taskid(Id) ->
    case ets:lookup(?TP, Id) of
        [] ->
            ?none;
        [{_, Type}] ->
            Type
    end.
get_task_progress_by_taskid(Id) ->
    case ets:lookup(?TP2, Id) of
        [] ->
            ?none;
        [{_, P}] ->
            P
    end.

init_task_remap() ->
    {NewL1, NewL2} =
    lists:foldl(fun({Key, R}, {List1, List2}) ->
        Mt = R#task_progress_cfg.main_task,
        Dt = R#task_progress_cfg.dialy_task,
        U1t = R#task_progress_cfg.user_task1,
        U2t = R#task_progress_cfg.user_task2,
        L = [{Mt, ?main_task_type}, {Dt, ?daily_task_type}, {U1t, ?user_task1}, {U2t, ?user_task2}],
        L2 = [{Mt, Key}, {Dt, Key}, {U1t, Key}, {U2t, Key}],
        {util:list_add_list(L, List1), util:list_add_list(L2, List2)}
    end,
    {[], []},
    ets:tab2list(task_progress_cfg)),
    ets:insert(?TP, NewL1),
    ets:insert(?TP2, NewL2).



get_taskid(Type, _Porgress) when Type > 2 ->
    load_simple_task:get_simple_taskid(Type);
get_taskid(TaskType, Porgress) ->
    case lookup_task_progress_cfg(Porgress) of
        #task_progress_cfg{
            main_task = Main,
            dialy_task = Dialy,
            user_task1 = _User1,
            user_task2 = _User2
        } ->
            case TaskType of
                ?main_task_type ->
                    Main;
                ?daily_task_type ->
                    Dialy;
                _ ->
                    0
            end;
        _Other ->
            0
    end.

get_task_cfg(TaskType, Progress) ->
    case get_taskid(TaskType, Progress) of
        0 -> ?none;
        TaskId -> lookup_task_new_cfg(TaskId)
    end.

get_task_cfg_field(TaskID, Key) ->
    case lookup_task_new_cfg(TaskID) of
        #task_new_cfg{} = Cfg ->
            element(Key, Cfg);
        _ ->
            ?task_nil
    end.

get_task_type(TaskId) ->
    case lookup_task_new_cfg(TaskId) of
        #task_new_cfg{type = Type} = _Cfg ->
            Type;
        _ ->
            ?none
    end.

get_task_goal_type(TaskId) ->
    case lookup_task_new_cfg(TaskId) of
        #task_new_cfg{goal_type=T} ->
            T;
        _ ->
            ?none
    end.


get_next_task_id(TaskId) ->
    case lookup_task_new_cfg(TaskId) of
        #task_new_cfg{next = NextId} = _Cfg ->
            NextId;
        _ ->
            ?none
    end.

%获取前置任务Id
get_per_task_id(TaskId) ->
    case lookup_task_new_cfg(TaskId) of
        #task_new_cfg{per = PerId} = _Cfg ->
            PerId;
        _ ->
            ?none
    end.


is_new_wizard_task(TaskId) ->
    case lookup_task_new_cfg(TaskId) of
        #task_new_cfg{goal_type = ?task_new_wizard} = _Cfg ->
            true;
        _ ->
            false
    end.

get_task_new_cfg(TaskId) ->
    case lookup_task_new_cfg(TaskId) of
        #task_new_cfg{type = _Type} = Cfg ->
            Cfg;
        _ ->
            ?none
    end.

%% @doc 是否完成
is_complete(TaskType, TaskProId) ->
    FinishId = task_mng_new:get_finish_progress(TaskType),
    TaskProId =< FinishId.

%%获取所有战争学院boss挑战列表
get_all_unlock_course_boss() ->
    lookup_all_task_new_cfg(#task_new_cfg.unlock_course_boss).


load_config_meta() ->
    [
        #config_meta{
            record = #task_progress_cfg{},
            fields = ?record_fields(task_progress_cfg),
            file = "task_progress.txt",
            keypos = #task_progress_cfg.id,
            verify = fun verify_progress/1},

        #config_meta{
            record = #task_new_cfg{},
            fields = ?record_fields(task_new_cfg),
            file = "task.txt",
            keypos = #task_new_cfg.id,
            all = [#task_new_cfg.unlock_course_boss],
            groups = [#task_new_cfg.goal_type],
            verify = fun verify_task_new/1}
    ].


verify_progress(#task_progress_cfg{id = Id, main_task = Main, dialy_task = Dialy}) ->
    ?check(Id > 0, "task_progress.txt [~p] id  无效!", [Id]),
    ?check(Main =:= 0 orelse is_exist_task_new_cfg(Main), "task_progress.txt中， [~p] main_task: ~p 配置无效。", [Id, Main]),
    ?check(Dialy =:= 0 orelse is_exist_task_new_cfg(Dialy), "task_progress.txt中， [~p] dialy_task: ~p 配置无效。", [Id, Dialy]),
    ok.

verify_task_new(
    #task_new_cfg{
        id = Id,                                 %% 任务ID
        type = Type,                             %任务类型   0:主线（main） 1:支线（branch） 2:日常（daily）
        %% 目标类型
        %% 1.杀死指定数量的怪物{MonsterId, KillCount}
        %% 2.和NPC对话　NpcId;
        %% 3.收集{GoodsId, Count}
        %% 4.购买任务{GoodsId, Count}，
        %% 8.完成副本｛sceneID,Ciunt｝如果MonserId 为0 表示任意的怪物；
        %% 28新手指引
        goal_type = GT,
        goal = Goal,                             %%
        per = PerTask,
        next = NextTask,
        publish_trigger = TaskAccept,            %%
        finish_trigger = TaskCpmpleted,          %%
        submit_trigger = TaskSubmit,             %%
        cost = Cost,                             %%
        prize = Prize,                           %%
        limit_level = LL,                        %%
        submit_npc = _NPC_ID,                     %%
        is_daily_task = _IsDailyTask,
        max_complete_times = MaxCompleteTimes,
        unlock_course_boss = UnlockCourseBoss}) ->
    ?check(Id > 0, "task.txt [~p] id  无效!", [Id]),
    ?check(Type >= 0 andalso Type =< 2, "task.txt中， [~p] type: ~p 配置无效。", [Id, Type]),
    if
        GT =:= 1 ->
            {MonsterId, Count} = Goal,
            ?check(scene_monster:is_exist_monster_cfg(MonsterId) orelse MonsterId =:= 0, "task.txt中， [~p] goal: ~p 配置无效。", [Id, Goal]),
            ?check(Count > 0, "task.txt中， [~p] goal~p 配置无效。", [Id, Goal]);
        GT =:= 2 ->
            ?check(npc:is_exist_npc_cfg(Goal), "task.txt中， [~p] goal: ~p 配置无效。", [Id, Goal]);
        GT =:= 3; Type =:= 4 ->
            {_GoodsId, Count} = Goal,
            %?check(goods:is_exist_goods_cfg(GoodsId),"task.txt中， [~p] goal: ~p 配置无效。", [Id, Goal]),
            ?check(Count > 0, "task.txt中， [~p] goal~p 配置无效。", [Id, Goal]);
        GT =:= 5 ->
            {_UnGoodsId, Count} = Goal,
            %?check(not goods:is_exist_goods_cfg(UnGoodsId),"task.txt中， [~p] goal: ~p 配置无效。", [Id, Goal]),
            ?check(Count > 0, "task.txt中， [~p] goal~p 配置无效。", [Id, Goal]);
        GT =:= 8 ->
            {SceneId, _Count} = Goal,
            ?check(load_cfg_scene:is_exist_scene_cfg(SceneId), "task.txt中， [~p] goal: ~p 配置无效。", [Id, Goal]);
        GT =:= 14 ->
            todo;
        GT =:= 20 ->
            todo;
        GT =:= 21 ->
            todo;
        GT =:= 23 ->
            todo;
        GT =:= 28 ->
            todo;
        true ->
            ?check(Goal > 0, "task.txt中， [~p] goal: ~p 配置无效。", [Id, Goal])
    end,
    ?check(PerTask =:= 0 orelse is_exist_task_new_cfg(PerTask), "task.txt中， [~p] per: ~p 配置无效。", [Id, PerTask]),
    ?check(NextTask =:= 0 orelse is_exist_task_new_cfg(NextTask), "task.txt中， [~p] next: ~p 配置无效。", [Id, NextTask]),
    lists:foreach(fun(TaskId) ->
        ?check(is_exist_task_new_cfg(TaskId), "task.txt中， [~p] publish_trigger: ~p 配置无效。", [Id, TaskId])
    end,
        TaskAccept),
    lists:foreach(fun(TaskId) ->
        ?check(is_exist_task_new_cfg(TaskId), "task.txt中， [~p] publish_trigger: ~p 配置无效。", [Id, TaskId])
    end,
        TaskCpmpleted),
    lists:foreach(fun(TaskId) ->
        ?check(is_exist_task_new_cfg(TaskId), "task.txt中， [~p] publish_trigger: ~p 配置无效。", [Id, TaskId])
    end,
        TaskSubmit),
    ?check(cost:is_exist_cost_cfg(Cost), "task.txt中， [~p] cost: ~p 配置无效。", [Id, Cost]),
    ?check(Prize =:= 0 orelse prize:is_exist_prize_cfg(Prize), "task.txt中， [~p] prize: ~p 配置无效。", [Id, Prize]),
    ?check(LL >= 1 andalso LL =< 100, "task.txt中， [~p] limit_level: ~p 配置无效。", [Id, LL]),
    ?check(MaxCompleteTimes >= 1, "task.txt中， [~p] max_complete_times: ~p 配置无效。", [Id, MaxCompleteTimes]),
    ?check(load_course:is_exist_boss_challenge_cfg(UnlockCourseBoss) orelse UnlockCourseBoss =:= ?undefined, "task.txt中， [~p] unlock_course_boss: ~p 配置无效。", [Id, UnlockCourseBoss]),
    ok.

