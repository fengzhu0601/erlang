-module(mount_tgr).

-include("inc.hrl").
-include("task_tgr.hrl").
-include("task_new_def.hrl").
-include("task_def.hrl").
-include("player.hrl").
-include("load_task_progress.hrl").
-include("ride_def.hrl").


-export([
    online_give_task_mount/0,
    getoff_ride_for_shapeshift/0,
    geton_tgr_ride_for_scene/0,
    getoff_tgr_ride_for_scene/0
]).


do(_TgrDBID) -> ok.


reset(_TgrDBID) ->
    ok.


start(TgrDBID) ->
    %?DEBUG_LOG("mount_tgr tgrdbid-----------:~p", [TgrDBID]),
    case TgrDBID of
        {_TaskType, TaskId, _Key} ->
            %TaskDdId = {TaskType, TaskId},
            case load_task_progress:get_task_new_cfg(TaskId) of
                #task_new_cfg{id = TaskId, type = _Type, goal = {_, MountId, Time}} ->
                    NewMountId = 
                    if
                        MountId =/= 0, is_integer(MountId) ->
                            MountId;
                        true ->
                            load_cfg_ride:get_random_ride_id()
                    end,
                    if
                        Time =/= 0 ->
                            put(?pd_task_mount_time, {NewMountId, Time + com_time:now()}),
                            player_mng:task_mount_after(Time*1000);
                        true ->
                            put(?pd_task_mount_time, {NewMountId,1}),
                            pass
                    end,
                    shapeshift_mng:stop_shapeshift_effect(),
                    %put(?pd_riding, MountId),
                    ?player_send(player_sproto:pkg_msg(?MSG_PlAYER_RIDE, {NewMountId})),
                    geton_tgr_ride_for_scene();
                ?none ->
                    pass
            end;
        _ ->
            pass
    end,
    ok.

stop(_TgrDBID) ->
    ok.
can(TgrDBID) ->
    %?DEBUG_LOG("mount_tgr  CAN --------------------------:~p",[TgrDBID]),
    case TgrDBID of
        {_TaskType, TaskId, _Key} ->
            %TaskDdId = {TaskType, TaskId},
            case load_task_progress:get_task_new_cfg(TaskId) of
                #task_new_cfg{goal = {_, MountId, 0}} ->
                    %?DEBUG_LOG("mount_tgr---------------------------"),
                    put(?pd_task_mount_time, {0, 0}),
                    ride_mng:getoff_ride(MountId),
                    %put(?pd_riding, 0),
                    ?player_send(player_sproto:pkg_msg(?MSG_PlAYER_RIDE, {0}));
                _ ->
                    pass
            end;
        _ ->
            pass
    end,
    true.
can_accept(_TgrDBID) ->
    true.

online_give_task_mount() ->
    %?DEBUG_LOG("pd_task_mount_time------------------------:~p",[get(?pd_task_mount_time)]),
    NowTime = com_time:now(),
    case get(?pd_task_mount_time) of
        ?undefined ->
            pass;
        {0, 0} ->
            pass;
        {MountId, 1} ->
            shapeshift_mng:stop_shapeshift_effect(),
            %put(?pd_riding, MountId),
            ?player_send(player_sproto:pkg_msg(?MSG_PlAYER_RIDE, {MountId}));
        {_MountId, Time} when NowTime > Time ->
            put(?pd_task_mount_time, {0,0});
        {MountId, Time} ->
            shapeshift_mng:stop_shapeshift_effect(),
            %put(?pd_riding, MountId),
            ?player_send(player_sproto:pkg_msg(?MSG_PlAYER_RIDE, {MountId})),
            player_mng:task_mount_after((Time - NowTime)*1000)
    end.

getoff_ride_for_shapeshift() ->
    %% ?return_err会终止执行函数
    case get(?pd_task_mount_time) of
        ?undefined ->
            pass;
        {0,0} ->
            pass;
        {MountId, _Time} ->
            %% 任务坐骑变身后, 取消坐骑
            tool:cancel_sendafter(task_mount_after_timerref),
            put(?pd_task_mount_time, {0,0}),
            ride_mng:getoff_ride(MountId),
            ?player_send(player_sproto:pkg_msg(?MSG_PlAYER_RIDE, {0}))
    end,
    ok.

geton_tgr_ride_for_scene() ->
    %%增加移动属性
    case get(?pd_task_mount_time) of
        ?undefined ->
            pass;
        {0,0} ->
            pass;
        {MountId, _Time} ->
            attr_new:begin_sync_attr(),
            ride_mng:add_ride_speed(MountId),
            attr_new:end_sync_attr()
    end,
    ok.

getoff_tgr_ride_for_scene() ->
    %%减去移动属性
    case get(?pd_task_mount_time) of
        ?undefined ->
            pass;
        {0,0} ->
            pass;
        {MountId, _Time} ->
            attr_new:begin_sync_attr(),
            ride_mng:del_ride_speed(MountId),
            attr_new:end_sync_attr()
    end,
    ok.

