%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 20. 七月 2015 下午3:15
%%%-------------------------------------------------------------------
-module(task_system).
-author("clark").

%% API
-export
([
    accept/1
    , submit/1
    , try_change_state/1
    , get_task_dbid/2
    , get_tgr_config_data/1
    , get_tgr_db_data/1
    , get_task_dbid/1
    , set_tgr_db_data/4
    , get_accept_progress/1
    , get_finish_progress/1
    , get_all_branch_task_progress/0
    , get_dbid_of_task/1
    , delete_tgr_db_data/1
    , get_task_state/1
    , get_newbie_guide_task_is_open/0
    , finish_task_trigger_task/2
    , gm_accept/1
    , set_task_state/2
    , reset_task/1
    , reset_task_data/1
    , is_open_xitong_of_task/1
]).


-include("inc.hrl").
-include("task_new_def.hrl").
-include("day_reset.hrl").
-include("player.hrl").
-include("task_mng_reply.hrl").
-include("achievement.hrl").

%% 日重置
on_day_reset(_SelfId) ->
    % ?DEBUG_LOG("task system ------------on_day_reset ------"),
    task_mng_new:do_flush_daily_task(),
    daily_task_tgr:flush_daily_num(),
    ok.


is_open_xitong_of_task(TaskId) ->
    Type = load_task_progress:get_task_type(TaskId),
    if
        Type =:= ?main_task_type ->
            CanAcceptProgress = get_finish_progress(Type),
            case load_task_progress:get_task_type_and_progress(TaskId) of
                {_, TaskProgress} ->
                    %?DEBUG_LOG("CanAcceptProgress--------:~p------TaskProgress-----:~p",[TaskProgress]),
                    TaskProgress =< CanAcceptProgress;
                _ ->
                    %?DEBUG_LOG("1--------------------------------------"),
                    ?false
            end;
        true ->
            %?DEBUG_LOG("2----------------------------------"),
            ?false 
    end.


get_newbie_guide_task_is_open() ->
    case get(?pd_task_is_open) of
        undefined ->
            0;
        IsOpen ->
            IsOpen
    end.


get_task_type_and_progress_by_task_id(TaskId) ->
    Type = load_task_progress:get_task_type(TaskId),
    %?DEBUG_LOG("TaskId--type---------:~p",[{TaskId, Type}]),
    IsCan = is_can_accept_task(Type, TaskId),
    if
        Type =:= ?none ->
            ?none;
        (Type =:= ?main_task_type orelse Type =:= ?daily_task_type) andalso IsCan =:= true ->
            load_task_progress:get_task_type_and_progress(TaskId);
        Type =:= ?newbie_guide_task_type andalso IsCan =:= true ->
            load_simple_task:get_simple_task_type_and_progress(TaskId);
        true ->
            ?none
    end.

get_dbid_of_task(TaskId) ->
    Type = load_task_progress:get_task_type(TaskId),
    if
        Type =:= ?none ->
            ?none;
        Type =:= ?main_task_type; Type =:= ?daily_task_type ->
            {Type, TaskId};
        Type =:= ?newbie_guide_task_type ->
            case load_simple_task:get_simple_task_type_by_taskid(TaskId) of
                ?none ->
                    ?none;
                T ->
                    {T, TaskId}
            end;
        true ->
            ?none
    end.



%% 发送接受任务的回复
send_reply_accept(TaskId, _AcceptTgrs, Reason) ->
    ReplyNum = if
                   Reason == ok ->
                       ?REPLY_MSG_TASK_ACCEPT_OK;
                   Reason == already_accept ->
                       ?REPLY_MSG_TASK_ACCEPT_1;
                   Reason == per_not_complete ->
                       ?REPLY_MSG_TASK_ACCEPT_2;
                   Reason == complete_times_limit ->
                       ?REPLY_MSG_TASK_ACCEPT_3;
                   ?true ->
                       ?REPLY_MSG_TASK_ACCEPT_255
               end,
    if
        TaskId == 40034 ->
            ?DEBUG_LOG("accept TaskId-------------------ok--:~p",[TaskId]);
        true ->
            pass
    end,
    ?player_send(task_sproto:pkg_msg(?MSG_TASK_ACCEPT, {ReplyNum, TaskId})).
    %util:mod_fun(AcceptTgrs, start).

finish_task_trigger_task(TaskType, TaskID) ->
    FinishTgrs = task_tgr_builder:get_tgrs(TaskType, TaskID, ?task_finishing),
    %?DEBUG_LOG("FinishTgrs--------------:~p",[FinishTgrs]),
    util:mod_fun(FinishTgrs, start).

%%GM修改指定玩家的任务
gm_send_taskid_to_player(PlayerId,TaskId) ->
    world:send_taskid_to_player(PlayerId, ?mod_msg(task_system, {send_task, TaskId})).

handle_msg(_FromMod, {send_task, TaskId}) ->
    gm_accept(TaskId).


%%GM增加接受任务
gm_accept(TaskId) ->
    %%将任务从任务列表中删除
    Type = load_task_progress:get_task_type(TaskId),
    TaskList = attr_new:get(?pd_task_list,[]),
    %%NewTaskList = lists:keydelete(TaskDBID, #task_tab.task_dbid, TaskList),
    %%attr_new:set(?pd_task_list, NewTaskList),

    if
        %%主线任务
        (Type =:= ?main_task_type orelse Type =:= ?daily_task_type) ->
            lists:foreach(fun(#task_tab{task_dbid = TaskDBID}) ->
                {TypeID,TaskID} = TaskDBID,
                if
                    TypeID == Type andalso TaskID >= TaskId ->
                        %?INFO_LOG("DBID------:~p~n--",[{TypeID,TaskID}]),
                        NewTaskList = lists:keydelete(TaskDBID, #task_tab.task_dbid, attr_new:get(?pd_task_list,[])),
                        attr_new:set(?pd_task_list, NewTaskList);
                    true -> ok
                end
                          end, TaskList);
        %%支线任务
        Type =:= ?newbie_guide_task_type ->
            TypeID = load_simple_task:get_simple_task_type_by_taskid(TaskId),
            TaskDBID = {TypeID,TaskId},
            NewTaskList = lists:keydelete(TaskDBID, #task_tab.task_dbid, TaskList),
            attr_new:set(?pd_task_list, NewTaskList),
            %要接取支线任务22001，必须将它的前置任务12002设置成完成状态
            %1.获取该支线任务的前置任务
            PerId = load_task_progress:get_per_task_id(TaskId),
            %2.设置前置Id状态
            PerTaskType = load_task_progress:get_task_type_by_taskid(PerId),
            set_task(PerTaskType, PerId, ?task_over, []),
            %3.50038这个任务要设置
            GuideTaskId = 50038,
            GuideTaskType = load_simple_task:get_simple_task_type_by_taskid(GuideTaskId),
            set_task(GuideTaskType, GuideTaskId, ?task_over, []),
            TaskListNow = attr_new:get(?pd_task_list, []),
            ?INFO_LOG("TaskListNow ~p", [TaskListNow]);
        true ->
            ?none
    end,



    case get_task_type_and_progress_by_task_id(TaskId) of
        ?none ->
            pass;
        false ->
            pass;
        {TaskType, TaskProgress} ->
            TaskProgressList = attr_new:get(?pd_task_progress_list, []),
            NewTaskProgressList =
                case lists:keyfind(TaskType, #task_progress_tab.task_type, TaskProgressList) of
                    false ->
                        NewTuple = #task_progress_tab{task_type = TaskType, task_accept_progress = TaskProgress - 1, task_finish_progress = TaskProgress - 1},
                        [NewTuple | TaskProgressList];
                    _ ->
                        NewTuple = #task_progress_tab{task_type = TaskType, task_accept_progress = TaskProgress - 1, task_finish_progress = TaskProgress - 1},
                        lists:keyreplace(TaskType, #task_progress_tab.task_type, TaskProgressList, NewTuple)
                end,
            attr_new:set(?pd_task_progress_list, NewTaskProgressList),

            %reset_progress(TaskType),
            %?DEBUG_LOG("TaskType----:~p------TaskProgress-----:~p",[TaskType, TaskProgress]),
            TaskID = load_task_progress:get_taskid(TaskType, TaskProgress),
            %?DEBUG_LOG("TaskID--------:~p",[TaskID]),
            CurAcceptProgress = get_accept_progress(TaskType),
            CanAcceptProgress = get_finish_progress(TaskType),
            %?DEBUG_LOG("CurAcceptProgress---:~p-----CanAcceptProgress----:~p",[CurAcceptProgress, CanAcceptProgress]),
            {CanAccept, AcceptTgrs} =
                if
                    TaskType > 2 ->
                        accept_(TaskType, TaskID);
                    CurAcceptProgress > CanAcceptProgress ->  %% 处于任务进行中
                        {false, []};
                    TaskID < 0 ->                             %% 无配置任务
                        {false, []};
                    true ->
                        accept_(TaskType, TaskID)
                end,
            %?DEBUG_LOG("CanAccept------AcceptTgrs---:~p",[{CanAccept, AcceptTgrs}]),
            case CanAccept of %% todo
                true ->
                    %% 任务接取
                    %FinishTgrs = task_tgr_builder:get_tgrs(TaskType, TaskID, ?task_finishing),
                    %?DEBUG_LOG("FinishTgrs--------------:~p",[FinishTgrs]),
                    %util:mod_fun(FinishTgrs, start),
                    add_accept_progress(TaskType),
                    _TaskDBID = set_task(TaskType, TaskID, ?task_finishing, []),
                    util:mod_fun(AcceptTgrs, start),
                    %try_change_state(TaskDBID),
                    case get(?first_one) of
                        true ->
                            %?DEBUG_LOG("true ----------------------------"),
                            pass;
                        _ ->
                            send_reply_accept(TaskId, AcceptTgrs, ok)
                    end,
                    ok;
                _ ->
                    {error, unknow}
            end
    end.

reset_task(TaskId) ->
    case get_task_type_and_progress_by_task_id(TaskId) of
        ?none ->
            pass;
        false ->
            pass;%% return not find progress cfg
        {TaskType, TaskProgress} ->
            case task_tgr_builder:get_tgrs(TaskType, TaskId, ?task_accepting) of
                [] ->
                    pass;
                AcceptTgrs ->
                    util:mod_fun(AcceptTgrs, reset)
            end
    end.



%% 接收任务 - accept
accept(TaskId) ->
    %?DEBUG_LOG("Accept taskid--------------------:~p",[TaskId]),
    case get_task_type_and_progress_by_task_id(TaskId) of
        ?none ->
            pass;
        false ->
            ?return_err(?ERR_NO_CFG);%% return not find progress cfg
        {TaskType, TaskProgress} ->
            %?DEBUG_LOG("TaskType----:~p------TaskProgress-----:~p",[TaskType, TaskProgress]),
            TaskID = load_task_progress:get_taskid(TaskType, TaskProgress),
            %?DEBUG_LOG("TaskID--------:~p",[TaskID]),
            CurAcceptProgress = get_accept_progress(TaskType),
            CanAcceptProgress = get_finish_progress(TaskType),
            %?DEBUG_LOG("CurAcceptProgress---:~p-----CanAcceptProgress----:~p",[CurAcceptProgress, CanAcceptProgress]),
            {CanAccept, AcceptTgrs} =
                if
                    TaskType > 2 ->
                        accept_(TaskType, TaskID);
                    CurAcceptProgress > CanAcceptProgress ->  %% 处于任务进行中
                        {false, []};
                    TaskID < 0 ->                             %% 无配置任务
                        {false, []};
                    true ->
                        accept_(TaskType, TaskID)
                end,
            %?DEBUG_LOG("CanAccept------AcceptTgrs---:~p",[{CanAccept, AcceptTgrs}]),
            case CanAccept of %% todo 
                true ->
                    %% 任务接取
                    %FinishTgrs = task_tgr_builder:get_tgrs(TaskType, TaskID, ?task_finishing),
                    %?DEBUG_LOG("FinishTgrs--------------:~p",[FinishTgrs]),
                    %util:mod_fun(FinishTgrs, start),
                    add_accept_progress(TaskType),
                    _TaskDBID = set_task(TaskType, TaskID, ?task_finishing, []),
                    util:mod_fun(AcceptTgrs, start),
                    %try_change_state(TaskDBID),
                    case get(?first_one) of
                        true ->
                            %?DEBUG_LOG("true ----------------------------"),
                            pass;
                        _ ->
                            send_reply_accept(TaskId, AcceptTgrs, ok)
                    end,
                    ok;
                _ ->
                    {error, unknow}
            end
    end.
accept_(TaskType, TaskID) ->
    %% 任务接取判断
    case task_tgr_builder:get_tgrs(TaskType, TaskID, ?task_accepting) of
        [] ->
            {true, []};
        AcceptTgrs ->
            %?DEBUG_LOG("AcceptTgrs-----------:~p",[AcceptTgrs]),
            %% 前端没有预接受状态，故接受需求只能是一些查询的条件， 这里没必要start后再can了。
            case util:mod_can(AcceptTgrs, can_accept) of
                true ->
                    if
                        TaskType =:= ?main_task_type orelse TaskType =:= ?daily_task_type ->
                            system_log:info_task_start(TaskID);
                        true ->
                            ok
                    end,
                    {true, AcceptTgrs};
                _ ->
                    {false, []}
            end
    end.


%% 尝试切换状态(任务触发器回调)
try_change_state(TaskDBID) ->
    State = get_task_state(TaskDBID),
    case State of
        ?task_finishing ->
            do_try_change_state(TaskDBID, ?task_finishing, ?task_submiting);
        _ ->
            ok
    end.


%% 提交任务 - submit
submit(TaskDBID) ->
    try_change_state(TaskDBID),
    State = get_task_state(TaskDBID),
    TaskType = get_task_type(TaskDBID),
    TaskID = get_task_id(TaskDBID),
    IsWizard = load_task_progress:is_new_wizard_task(TaskID),
    {CanSubmit, CurSubmitTgrs} =
        if
            IsWizard =:= true ->
                submit_(TaskType, TaskID);
            State =/= ?task_submiting ->
                {false, []};
            true ->
                submit_(TaskType, TaskID)
        end,
    %?DEBUG_LOG("state------:~p--CanSubmit--------:~p--CurSubmitTgrs--:~p",[State, CanSubmit, CurSubmitTgrs]),
    case CanSubmit of
        true ->
            %% 提交完成进度
            add_finish_progress(TaskType),
            set_task_state(TaskDBID, ?task_over),
            %% 给任务奖励
            util:mod_fun(CurSubmitTgrs, stop),
            util:mod_fun(CurSubmitTgrs, do),
            send_submit_msg_to_client(TaskType, TaskID),
            if
                TaskType =:= ?main_task_type orelse TaskType =:= ?daily_task_type ->
                    achievement_mng:do_ac2(?tulongze, TaskID, 1),
                    achievement_mng:do_ac2(?damaoxianjia, TaskID, 1),
                    achievement_mng:do_ac2(?jiushize, TaskID, 1),
                    system_log:info_finish_task(TaskID);
                true ->
                    ok
            end;
        _ ->
            ok
    end.


submit_(TaskType, TaskID) ->
    case task_tgr_builder:get_tgrs(TaskType, TaskID, ?task_submiting) of
        [] ->
            {true, []};
        SubmitTgrs ->
            %?DEBUG_LOG("TaskTYpe--:~p---TaskId---:~p--SubmitTgrs----------111----:~p",[TaskType,TaskID,SubmitTgrs]),
            case util:mod_can(SubmitTgrs, can) of
                true ->
                    %?DEBUG_LOG("submit_-----------------1"),
                    {true, SubmitTgrs};
                _ ->
                    %?DEBUG_LOG("submit_--------------------2"),
                    {false, []}
            end
    end.

send_submit_msg_to_client(TaskType, TaskID) ->
    ReplyNum = ?REPLY_MSG_TASK_SUBMIT_OK,
    %?DEBUG_LOG("TaskType--:~p----TaskId--:~p --ReplyNum---------------:~p",[TaskType,TaskID,ReplyNum]),
    course_mng:unlock_course_boss_ins(TaskID),
    case TaskType of
        ?main_task_type ->
            task_open_fun:task_trigger_1(TaskID),
            %achievement_mng:do_ac2(?zhuxiandaren, TaskID, 1),
            achievement_mng:do_ac(?zhuxiandaren),
            %?DEBUG_LOG("main send data to client ok --------------------TaskId---:~p",[TaskID]),
            ?player_send(task_sproto:pkg_msg(?MSG_TASK_SUBMIT, {ReplyNum, TaskID}));
        ?daily_task_type ->
            achievement_mng:do_ac(?richanggaoshou),
            %daily_task_tool:set_daily_task_star(),
            %CanDailyTaskId = daily_task_tool:get_next_daily_task_id(),
            %?DEBUG_LOG("daily send data to client ok --------------------TaskId---:~p",[TaskID]),
            ?player_send(task_sproto:pkg_msg(?MSG_TASK_SUBMIT, {ReplyNum, TaskID}));
        T when T > 1000 ->
            %?DEBUG_LOG("newbie guide send data to client ok --------------------TaskId---:~p",[TaskID]),
            achievement_mng:do_ac(?zhixiandaren),
            case load_task_progress:is_new_wizard_task(TaskID) of
                true ->
                    pass;
                false ->
                    event_eng:post(?ev_branch_task_totle, {?ev_branch_task_totle, 0}, 1)
            end,
            ?player_send(task_sproto:pkg_msg(?MSG_TASK_SUBMIT, {ReplyNum, TaskID}));
        _ ->
            ?player_send(task_sproto:pkg_msg(?MSG_TASK_SUBMIT, {ReplyNum, TaskID}))
    end.



%% 获得触发器配置数据
get_tgr_config_data(TgrDBUID) ->
    case TgrDBUID of
        {_TaskType, TaskID, Key} ->
            %%获得配置表数据
            D = load_task_progress:get_task_cfg_field(TaskID, Key),
            %?DEBUG_LOG("TaskId-----:~p-Key---:~p---Gold---:~p",[TaskID, Key, D]),
            D;
        _ ->
            ?task_nil
    end.


%% 获得触发器数据
get_tgr_db_data(TaskDBID) ->
    %?DEBUG_LOG("TaskDBID----------------:~p",[TaskDBID]),
    TaskList = attr_new:get(?pd_task_list, []),
    %?DEBUG_LOG("TaskList----------:~p",[TaskList]),
    case lists:keyfind(TaskDBID, #task_tab.task_dbid, TaskList) of
        false ->
            %?DEBUG_LOG("task nil 1-----------------"),
            ?task_nil;
        #task_tab{task_tgr_list = TgrsDataList} ->
            %?DEBUG_LOG("TgrsDataList---------:~p",[TgrsDataList]),
            if
                is_tuple(TgrsDataList) ->
                    #task_tgr_par2_tab{par1 = Par1, par2 = Par2} = TgrsDataList,
                    {Par1, Par2};
                TgrsDataList =:= [] ->
                    ?none;
                    %?task_nil;
                true ->
                    ?task_nil
            end
    end.

%% 设置触发器数据
set_tgr_db_data(TaskDBID, Par1, Par2, _IsSyncFlag) ->
    %?DEBUG_LOG("TaskDBID--:~p--Par1--:~p---Par2--:~p",[TaskDBID, Par1, Par2]),
    case TaskDBID of
        {TaskType, TaskId} ->
            TaskList = attr_new:get(?pd_task_list, []),
            %?DEBUG_LOG("TaskList-------------:~p",[TaskList]),
            Tuple = #task_tgr_par2_tab{taskid = TaskId, par1 = Par1, par2 = Par2},
            NewTaskList =
                case lists:keyfind(TaskDBID, #task_tab.task_dbid, TaskList) of
                    false ->
                        %?DEBUG_LOG("false-------------------------"),
                        [#task_tab{task_type = TaskType, task_dbid = TaskDBID,
                            task_state = ?task_finishing, task_tgr_list = Tuple} | TaskList];
                    #task_tab{} = T ->
                        %?DEBUG_LOG("t------------------------------------"),
                        NewT = T#task_tab{task_tgr_list = Tuple},
                        lists:keyreplace(TaskDBID, #task_tab.task_dbid, TaskList, NewT)
                end,
            %?DEBUG_LOG("NewTaskList-------------:~p",[NewTaskList]),
            attr_new:set(?pd_task_list, NewTaskList),
            if
                Par1 =:= Par2 ->
                    try_change_state(TaskDBID);
                true ->
                    pass
            end;
        _ ->
            pass
    end.

%% delete tgr data
delete_tgr_db_data(TgrDBUID) ->
    TaskDBID = get_task_dbid(TgrDBUID),
    NewList = lists:keydelete(TaskDBID, #task_tab.task_dbid, attr_new:get(?pd_task_list, [])),
    attr_new:set(?pd_task_progress_list, NewList).



%% 获得任务DBID
get_task_dbid(TgrDBUID) ->
    case TgrDBUID of
        {TaskType, TaskID, _Key} ->
            get_task_dbid(TaskType, TaskID);
        _ ->
            ?task_nil
    end.



%%-------------------------------------------
%% private:
%%-------------------------------------------
%% 尝试切换状态
do_try_change_state(TaskDBID, FromState, ToState) ->
    %?DEBUG_LOG("TaskDBID--:~p---FromState---:~p--ToState--:~p",[TaskDBID, FromState, ToState]),
    TaskType = get_task_type(TaskDBID),
    TaskID = get_task_id(TaskDBID),
    State = get_task_state(TaskDBID),
    %?DEBUG_LOG("State-----:~p",[State]),
    {CanChange, _CurFromTgrs} =
        if
        %% 无效任务
            TaskID =< 0 ->
                {false, []};
            State =/= FromState ->
                {false, []};
            true ->
                %% 能否完成
                case task_tgr_builder:get_tgrs(TaskType, TaskID, FromState) of
                    [] ->
                        {true, []};
                    FromTgrs ->
                        %?DEBUG_LOG("FromTgrs----------:~p",[FromTgrs]),
                        case util:mod_can(FromTgrs, can) of
                            true ->
                                {true, FromTgrs};
                            _ ->
                                {false, []}
                        end
                end
        end,
    %?DEBUG_LOG("CanChange---:~p----CurFromTgrs--:~p",[CanChange, CurFromTgrs]),
    case CanChange of
        true ->
            %% 切换任务状态
            %util:mod_fun(CurFromTgrs,stop),
            %util:mod_fun(CurFromTgrs,do),
            _ToStateTgrs = task_tgr_builder:get_tgrs(TaskType, TaskID, ToState),
            %?DEBUG_LOG("ToStateTgrs----------:~p",[ToStateTgrs]),
            %util:mod_fun(ToStateTgrs, start),
            set_task_state(TaskDBID, ToState);
        _ ->
            ok
    end.
get_all_branch_task_progress() ->
    %?DEBUG_LOG("branch progress list----------------:~p",[attr_new:get(?pd_task_progress_list, [])]),
    lists:foldl(fun(T, {L1, L2}) ->
        Type = T#task_progress_tab.task_type,
        AccepteP = get_accept_progress(Type),
        FinishP = get_finish_progress(Type),
        %?DEBUG_LOG("branch  Ap----:~p----Fp---:~p",[AccepteP, FinishP]),
        if
            Type > 2, is_integer(Type) ->
                %TaskId = 
                case load_simple_task:get_simple_taskid(Type) of
                    ?none ->
                        {L1, L2};
                    TaskId ->
                        GoalType = load_task_progress:get_task_goal_type(TaskId),
                        {F, NewA} =
                            if
                                FinishP =:= 0 ->
                                    A =
                                        if
                                            AccepteP =:= 0 ->
                                                [];
                                            true ->
                                                %?DEBUG_LOG("branch type--:~p---TaskId-----------:~p",[Type,TaskId]),
                                                case load_task_progress:is_new_wizard_task(TaskId) of
                                                    true ->
                                                        case get(?first_one) of
                                                            true ->
                                                                [{TaskId, GoalType, 0, 0}];
                                                            _ ->
                                                                []
                                                                %task_mng_new:get_pack_data(Type, TaskId)
                                                        end;
                                                    false ->
                                                        task_mng_new:get_pack_data(Type, TaskId)
                                                end
                                        end,
                                    {[], A};
                                true ->
                                    {[{Type, TaskId}], []}
                            end,
                        {util:list_add_list(F, L1), util:list_add_list(NewA, L2)}
                end;
            true ->
                {L1, L2}
        end
    end,
    {[], []},
    attr_new:get(?pd_task_progress_list, [])).

%% 获得接受进度
get_accept_progress(TaskType) ->
    TaskProgressList = attr_new:get(?pd_task_progress_list, []),
    case lists:keyfind(TaskType, #task_progress_tab.task_type, TaskProgressList) of
        false ->
            0;
        #task_progress_tab{task_accept_progress = Accept} ->
            Accept
    end.

%% 获得完成进度
get_finish_progress(TaskType) ->
    TaskProgressList = attr_new:get(?pd_task_progress_list, []),
    case lists:keyfind(TaskType, #task_progress_tab.task_type, TaskProgressList) of
        false ->
            0;
        #task_progress_tab{task_finish_progress = Finish} ->
            Finish
    end.

%% 增加接受进度（最多只比完成进度多1）
add_accept_progress(TaskType) ->
    TaskProgressList = attr_new:get(?pd_task_progress_list, []),
    NewTaskProgressList =
        case lists:keyfind(TaskType, #task_progress_tab.task_type, TaskProgressList) of
            false ->
                NewTuple = #task_progress_tab{task_type = TaskType, task_accept_progress = 1, task_finish_progress = 0},
                [NewTuple | TaskProgressList];
            #task_progress_tab{task_finish_progress = Finish} = Tap ->
                NewAccept = Finish + 1,
                NewTuple = Tap#task_progress_tab{task_accept_progress = NewAccept},
                lists:keyreplace(TaskType, #task_progress_tab.task_type, TaskProgressList, NewTuple)
        end,
    attr_new:set(?pd_task_progress_list, NewTaskProgressList).

%% 增加完成进度（最多=接受进度）
add_finish_progress(TaskType) ->
    TaskProgressList = attr_new:get(?pd_task_progress_list, []),
    NewTaskProgressList =
        case lists:keyfind(TaskType, #task_progress_tab.task_type, TaskProgressList) of
            false ->
                NewTuple = #task_progress_tab{task_type = TaskType, task_accept_progress = 1, task_finish_progress = 1},
                [NewTuple | TaskProgressList];
            #task_progress_tab{task_accept_progress = Accept, task_finish_progress = Finish} = T ->
                NewFinish =
                    if
                        Accept > Finish ->
                            Accept;
                        true ->
                            Finish + 1
                    end,
                NewTuple = T#task_progress_tab{task_finish_progress = NewFinish},
                lists:keyreplace(TaskType, #task_progress_tab.task_type, TaskProgressList, NewTuple)
        end,
    attr_new:set(?pd_task_progress_list, NewTaskProgressList).


%% 获得任务DBID
get_task_dbid(TaskType, TaskID) ->
    {TaskType, TaskID}.



%% 设置任务
set_task(TaskType, TaskID, State, TgrsDataList) ->
    TaskDBID = get_task_dbid(TaskType, TaskID),
    Task = #task_tab{task_type = TaskType, task_dbid = TaskDBID, task_state = State, task_tgr_list = TgrsDataList},
    TaskList = attr_new:get(?pd_task_list, []),
    NewTaskList =
        case lists:keyfind(TaskDBID, #task_tab.task_dbid, TaskList) of
            false ->
                [Task | TaskList];
            #task_tab{} = T ->
                NewTask = T#task_tab{task_state = State},
                lists:keyreplace(TaskDBID, #task_tab.task_dbid, TaskList, NewTask)
        end,
    attr_new:set(?pd_task_list, NewTaskList),
    TaskDBID.

is_can_accept_task(TaskType, TaskID) ->
    TaskDBID = get_task_dbid(TaskType, TaskID),
    TaskList = attr_new:get(?pd_task_list, []),
    case lists:keyfind(TaskDBID, #task_tab.task_dbid, TaskList) of
        false ->
            true;
        #task_tab{} ->
            false
    end.


%% 获得任务id
get_task_id(TaskDBID) ->
    case TaskDBID of
        {_TaskType, TaskID} ->
            TaskID;
        _ ->
            0
    end.

%% 获得任务类型
get_task_type(TaskDBID) ->
    case TaskDBID of
        {TaskType, _TaskID} ->
            TaskType;
        _ ->
            0
    end.

%% 设置任务状态
set_task_state(TaskDBID, State) ->
    TaskList = attr_new:get(?pd_task_list, []),
    NewTaskList =
    case lists:keyfind(TaskDBID, #task_tab.task_dbid, TaskList) of
        false ->
            TaskList;
        #task_tab{} = T ->
            Task = T#task_tab{task_state = State},
            lists:keyreplace(TaskDBID, #task_tab.task_dbid, TaskList, Task)
    end,
    attr_new:set(?pd_task_list, NewTaskList).

%% 获得任务状态
get_task_state(TaskDBID) ->
    TaskList = attr_new:get(?pd_task_list, []),
    case lists:keyfind(TaskDBID, #task_tab.task_dbid, TaskList) of
        false ->
            ?nil;
        #task_tab{task_state = State} ->
            State
    end.

reset_task_data({TaskType, _TaskID}=TaskDBID) ->
    %?DEBUG_LOG("reset_task_data------------------------------:~p",[TaskDBID]),
    TaskList = attr_new:get(?pd_task_list, []),
    NewTaskList = lists:keydelete(TaskDBID, #task_tab.task_dbid, TaskList),
    %?DEBUG_LOG("NewTaskList----------------------------------:~p",[NewTaskList]),
    attr_new:set(?pd_task_list, NewTaskList),
    TaskProgressList = attr_new:get(?pd_task_progress_list, []),
    NewTaskProgressList =
    case lists:keyfind(TaskType, #task_progress_tab.task_type, TaskProgressList) of
        false ->
            TaskProgressList;
        _ ->
            NewTuple = #task_progress_tab{task_type = TaskType, task_accept_progress = 0, task_finish_progress = 0},
            lists:keyreplace(TaskType, #task_progress_tab.task_type, TaskProgressList, NewTuple)
    end,
    attr_new:set(?pd_task_progress_list, NewTaskProgressList).



%% 重置任务
%% reset_progress(TaskType) ->
%%     TaskProgressList = attr_new:get(?pd_task_progress_list, []),
%%     NewTaskProgressList =
%%         case lists:keyfind(TaskType, #task_progress_tab.task_type, TaskProgressList) of
%%             false ->
%%                 NewTuple = #task_progress_tab{task_type = TaskType, task_accept_progress = 0, task_finish_progress = 0},
%%                 [NewTuple | TaskProgressList];
%%             _ ->
%%                 NewTuple = #task_progress_tab{task_type = TaskType, task_accept_progress = 0, task_finish_progress = 0},
%%                 lists:keyreplace(TaskType, #task_progress_tab.task_type, TaskProgressList, NewTuple)
%%         end,
%%     attr_new:set(?pd_task_progress_list, NewTaskProgressList),
%%     TaskList = attr_new:get(?pd_task_list, []),
%%     NewTaskList = lists:keydelete(TaskType, #task_tab.task_type, TaskList),
%%     attr_new:set(?pd_task_list, NewTaskList).




