%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 22. 七月 2015 下午2:25
%%%-------------------------------------------------------------------
-author("clark").

-record(task_progress_cfg,
{
    id = 0,
    main_task = 0,
    dialy_task = 0,
    user_task1 = 0,
    user_task2 = 0
}).

-record(task_new_cfg,
{id,
    %% Task ID。

    type,
    %% 任务类型
    %% 0 - 主线（main）：根据游戏特点引导玩家进行游戏，少量装备、道具、金钱，大量经验。
    %% 1 - 支线（branch）：丰富游戏内容。
    %% 2 - 日常（daily）：提高玩家参与各类玩法的积极性，保障非R、小R的基本资源开销。
    %% 3 -  特殊副本(special_instance)：高难度任务，丰富任务奖励，PVE装备价值的体现之一。

    is_daily_task = 0,
    %% 是否是每日任务。

    %% kill_monster {MonsterId, KillCount}

    %% npc_talk_task NpcId

    per = 0,
    %% 前一个任务，即要完成该任务必须想要完成的任务
    next = 0,%% 下一个任务，即：任务完成后

    publish_trigger = [], %在该任务接取时触发
    finish_trigger = [], %在该任务完成时触发
    submit_trigger = [], %任务提交时触发

    limit_level = 0,
    %% 等级限制，即：任务对玩家等级的限制。
    %% 任务有等级，玩家没有等级。
    %% 只有到一定等级的玩家才能领取该任务。
    %% 等级值越大，玩家等级越高。

    goal_type,
    %% 目标类型，即：目标子任务类型。
    %% 相应内容见task_def.hrl。
    %% 具体子目标任务在/task/plugin中实现。

    goal,
    %% 目标参数，即：目标子任务的相关信息。
    %%    goal_type和goal的对应关系如下：
    %%            task_plugin_kill_monster              [{MonsterId, KillCount}]
    %%            task_plugin_npc_talk                  NPC_ID
    %%            task_plugin_collect_item              {ItemId, Count}
    %%            task_plugin_buy_item	                {ItemId,Count}
    %%            task_plugin_convoy_npc                {MonsterId,PathList}
    %%            task_plugin_guard_frontier            {Minutes, SceneCfgId}} – 待定
    %%            task_plugin_single_instance	          {SingleId, Count}

    cost = 1,
    %% cost表示任务可以直接完成时所需要的花费。
    %% 当cost为 1 时，表示任务不可以通过支付（金币等）手段直接完成。

    submit_npc = 0,
    %% 将完成的任务提交给NPC，对应的NPC_ID。
    %% 如果submit_npc为none，表示该任务完成后不需要向NPC提交。

    prize = 0,
    %% 任务完成的奖励，prize表示对应奖励的Prize_ID。
    %% 对应到prize配置表的主键ID。

    is_auto_submit = 0,
    %% 任务完成后，是否自动向NPC提交。
    %% 后台没有NPC概念。
    %%  NPC由前台控制，Monster由后台控制。

    max_complete_times = 1,
    unlock_course_boss}).
%% 任务最多完成次数，即：允许同一任务最多可以完成的次数。
%% 对于主线任务，max_complete_times只能为1。
%% max_complete_times主要为日常任务设置，
%% 用于规定某一日常任务在用户一次上线期间的可以完成的最多次数。



