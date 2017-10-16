%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 20. 七月 2015 下午6:32
%%%-------------------------------------------------------------------
-module(prize_tgr).
-author("clark").

-include("inc.hrl").
-include("task_tgr.hrl").
-include("player.hrl").
-include("task_new_def.hrl").
-include("task_def.hrl").
-include("load_task_progress.hrl").
-include("system_log.hrl").

reset(_TgrDBID) -> ok.

start(_TgrDBID) -> ok.
stop(_TgrDBID) -> ok.
can(TgrDBID) ->
    {TaskType, TaskId, _Key} = TgrDBID,
    PrizeId =
        case TaskType of
            ?daily_task_type ->
                daily_task_tool:get_daily_prize_by_id();
            _ ->
                task_system:get_tgr_config_data(TgrDBID)
        end,
    IsCan = prize:is_can_prize(PrizeId),
    %?DEBUG_LOG("TaskId-------:~p-----PrizeId--------:~p----IsCAN---:~p",[TaskId, PrizeId, IsCan]),
    %R = 
    if
        IsCan =:= ?true; PrizeId =:= 0 ->
            ?true;
        ?true ->
            ?player_send(task_sproto:pkg_msg(?MSG_TASK_SUBMIT, {1, TaskId})), %% bag is not enough
            ?false
    end.
    %?DEBUG_LOG("R----------------------------:~p",[R]),
    %R.

can_accept(_TgrDBID) ->
    true.
do(TgrDBID) ->
    %{GoldTaskId, TriggerTaskId} = misc_cfg:get_bag_trigger(),
    {TaskType, TaskId, _Key} = TgrDBID,
    PrizeId =
        case TaskType of
            ?daily_task_type ->
                daily_task_tool:get_daily_prize_by_id();
            _ ->
                task_system:get_tgr_config_data(TgrDBID)
        end,
    %?DEBUG_LOG("PrizeId------------------:~p",[PrizeId]),
    attr_new:begin_room_prize(PrizeId),
    R = prize:prize_mail(PrizeId, ?S_MAIL_TASK, ?FLOW_REASON_TASK),
    attr_new:end_room_prize(TaskId),
    pet_new_mng:add_pet_new_exp_if_fight(R).
    %?DEBUG_LOG("R-------------------------:~p",[R]),
    % if
    %     TaskId =< GoldTaskId ->
    %         ?DEBUG_LOG("prize TriggerTaskId------------:~p",[TriggerTaskId]),
    %         ?DEBUG_LOG("TaskId-----:~p",[TaskId]),
    %         case load_simple_task:get_simple_task_type_by_taskid(TriggerTaskId) of
    %             ?none ->
    %                 pass;
    %             TriggerTaskIdType ->
    %                 case task_system:get_task_state({TriggerTaskIdType, TaskId}) of
    %                     ?task_over ->
    %                         %?DEBUG_LOG("prize pass-----------------------"),
    %                         pass;
    %                     _ ->
    %                         if
    %                             GoldTaskId =:= TaskId ->
    %                                 ?DEBUG_LOG("GoldTaskId---TaskId-----:~p",[{GoldTaskId, TaskId}]),
    %                                 task_system:accept(TriggerTaskId);
    %                             true ->
    %                                 case R of
    %                                     {error, _Other} ->
    %                                         ?DEBUG_LOG("prize error------------------"),
    %                                         task_system:accept(TriggerTaskId);
    %                                     _ ->
    %                                         pass
    %                                 end
    %                         end
    %                 end
    %         end;
    %     true ->
    %         pass
    % end.