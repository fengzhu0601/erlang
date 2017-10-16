%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 21. 七月 2015 上午10:57
%%%-------------------------------------------------------------------
-author("clark").

-define(ALL_TASK_TYPE, [?main_task_type, ?newbie_guide_task_type]).

%% 0 - 主线（main）：根据游戏特点引导玩家进行游戏，少量装备、道具、金钱，大量经验。
-define(main_task_type, 0).

%% 1 - 新手指引（Newbie Guide）
-define(newbie_guide_task_type, 1).

%% 2 - 日常（daily）：提高玩家参与各类玩法的积极性，保障非R、小R的基本资源开销。
-define(daily_task_type, 2).

-define(user_task1, user_task1).
-define(user_task2, user_task2).


-define(first_one, first_one).


-define(accpet_get_item_data, accpet_get_item_data).
-define(accpet_get_item_data_of_daily_task, accpet_get_item_data_of_daily_task).

%% 任务状态
-define(task_nil, nil).
-define(task_accepting, task_accepting).
-define(task_finishing, task_finishing).
-define(task_submiting, task_submiting).
-define(task_over, task_over).

%% id=_Id,                                 %% 任务ID
%% type=_Type,
%% %% 目标类型
%% %% 1.杀死指定数量的怪物{MonsterId, KillCount}
%% %% 2.和NPC对话　NpcId;
%% %% 3.收集{GoodsId, Count}
%% %% 4.购买任务{GoodsId, Count}，
%% %% 8.完成副本｛sceneID,Ciunt｝如果MonserId 为0 表示任意的怪物；
%% %% 28新手指引
%% goal_type=_GT,
%% goal=_Goal,                             %%
%% per = _PerTask,
%% next=_NextTask,
%% publish_trigger=_TaskAccept,            %%
%% finish_trigger=_TaskCpmpleted,          %%
%% submit_trigger=_TaskSubmit,             %%
%% cost=_Cost,                             %%
%% prize=_Prize,                           %%
%% limit_level=_LL,                        %%
%% submit_npc=_NPC_ID,                     %%

%% 任务进度表
-record(task_progress_tab,
{
    task_type = 0,
    task_accept_progress = 0,
    task_finish_progress = 0
}).

%% 任务表
-record(task_tab,
{
    task_type = 0,
    task_dbid = 0,
    task_state = 0,
    task_tgr_list = []
}).

%% 任务表
-record(task_tgr_tab,
{
    tgr_dbid = 0,
    tgr_list = []
}).
%% 任务表
-record(task_tgr_par2_tab,
{
    taskid = 0,
    par1 = 0,
    par2 = 0
}).