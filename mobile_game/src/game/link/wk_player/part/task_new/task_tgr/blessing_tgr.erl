-module(blessing_tgr).

-include("inc.hrl").
-include("task_tgr.hrl").
-include("task_new_def.hrl").
-include("task_def.hrl").
-include("player.hrl").
-include("load_task_progress.hrl").


-export([
    update_task_bless_buff/1,
    offline_del_task_bless_buff/0,
    add_task_bless_buff/1
]).


do(_TgrDBID) -> ok.


reset(_TgrDBID) ->
    ok.


start(TgrDBID) ->
    case TgrDBID of
        {TaskType, TaskId, _Key} ->
            TaskDdId = {TaskType, TaskId},
            case load_task_progress:get_task_new_cfg(TaskId) of
                #task_new_cfg{id = TaskId, type = Type, goal = {_,TaskBuffPoolId}} ->
                    BuffList = load_cfg_task_buff_pool:get_task_buff_pool_id_list(TaskBuffPoolId),
                    put(?pd_task_bless_buff, BuffList),
                    [equip_buf:add_task_bless_buff(BuffId) || BuffId <- BuffList];
                ?none ->
                    pass
            end;
        _ ->
            ?DEBUG_LOG("collect pass--------------------------"),
            pass
    end,
    ok.

stop(_TgrDBID) ->
    ok.
can(_TgrDBID) ->
   true.
can_accept(_TgrDBID) ->
    true.

add_task_bless_buff(BuffList) ->
    case get(?pd_task_bless_buff) of
        ?undefined ->
            pass;
        List ->
            put(?pd_task_bless_buff, util:list_add_list(BuffList, List))
    end.


update_task_bless_buff(BuffId) ->
    case get(?pd_task_bless_buff) of
        ?undefined ->
            pass;
        List ->
            put(?pd_task_bless_buff, lists:delete(BuffId, List))
    end.

offline_del_task_bless_buff() ->
    case get(?pd_task_bless_buff) of
        [] ->
            pass;
        ?undefined ->
            pass;
        List ->
            [equip_buf:take_off_buf2(BuffId) || BuffId <- List]
    end.
