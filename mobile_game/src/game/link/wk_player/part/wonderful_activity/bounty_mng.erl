%%%-------------------------------------------------------------------
%%% @author fengzhu
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%     赏金任务
%%% @end
%%% Created : 31. 八月 2016 下午3:44
%%%-------------------------------------------------------------------
-module(bounty_mng).
-author("fengzhu").

-include_lib("pangzi/include/pangzi.hrl").
-include("inc.hrl").
-include("player_mod.hrl").
-include("handle_client.hrl").
-include("load_cfg_shangjin_task.hrl").
-include("bounty_struct.hrl").
-include("player.hrl").
-include("rank.hrl").
-include("day_reset.hrl").
-include("load_db_misc.hrl").
-include("load_cfg_open_server_happy.hrl").
-include("system_log.hrl").
-include("../../../wk_open_server_happy/open_server_happy.hrl").

%% API
-export([
    do_bounty_task/2
    , is_in_activity_period/0
    , pass_room_star/1
    , count_get_yinxing/1
    , start_bounty_activity/0
    , count_update_gem/2
]).

-define(bounty_timerref, bounty_timerref).    %% 赏金任务活动定时器
-define(BOUNTY_RESET_TIME, misc_cfg:get_shangjin_task_reset_time()). %% 赏金任务刷新间隔时间
-define(IS_OPENED, is_opened).      %%是否主动打开过赏金任务

start_bounty_activity() ->
    case bounty_server:start_link() of
        {ok, _Pid} ->
            pass;
        _E ->
            todo
    end.

load_db_table_meta() ->
    [
        #db_table_meta
        {
            name = ?player_bounty_tab,
            fields = ?record_fields(?player_bounty_tab),
            shrink_size = 1,
            flush_interval = 3
        }
    ].

create_mod_data(PlayerId) ->
    ShangjinTaskLiveness = init_liveness_prize_list(),
    BountyTab =
        #player_bounty_tab
        {
            id = PlayerId,
            is_opened = 0,
            bounty_task = [],
            liveness = 0,
            bounty_liveness_prize = ShangjinTaskLiveness
        },
    case dbcache:insert_new(?player_bounty_tab, BountyTab) of
        ?true ->
            ok;
        ?false ->
            ?ERROR_LOG("player ~p create new player_equip_goods_table error mode ~p", [PlayerId, ?MODULE])
    end,
    ok.

load_mod_data(PlayerId) ->
    case load_cfg_open_server_happy:the_activity_is_over(?BOUNTY_TASK_ID) of
        true ->
            load_db_misc:set(?misc_bounty_is_over, 0),

            case dbcache:load_data(?player_bounty_tab, PlayerId) of
                [] ->
                    ?INFO_LOG("player ~p not find player_bounty_tab mode ~p", [PlayerId, ?MODULE]),
                    create_mod_data(PlayerId),
                    load_mod_data(PlayerId);
                [#player_bounty_tab{is_opened = IsOpened, bounty_task = Bounty_task_List, liveness = Liveness,
                    bounty_liveness_prize = Bounty_liveness_prize_List}] ->
                    ?pd_new(?IS_OPENED, IsOpened, 0),
                    ?pd_new(?pd_bounty_task_list, Bounty_task_List),
                    ?pd_new(?pd_bounty_liveness_prize_list, Bounty_liveness_prize_List),
                    ?pd_new(?pd_bounty_liveness, Liveness)
            end;
        false ->
            pass
    end.

init_client() ->
    ok.

view_data(Acc) -> Acc.

handle_frame(_Frame) -> ok.

handle_msg(_FromMod, {bounty_task_heishi}) ->
    do_bounty_task(?BOUNTY_TASK_HEISHI, 1);
handle_msg(_, {refresh_bounty_task}) ->
    refresh_bounty_task();
handle_msg(_FromMod, _Msg) -> ok.

online() ->
    case load_cfg_open_server_happy:the_activity_is_over(?BOUNTY_TASK_ID) of
        true ->
            %% ?INFO_LOG("=====bounty_mng online===========~n"),
            Liveness = util:get_pd_field(?pd_bounty_liveness, 0),
            %% Bounty_liveness_prize_List = get(?pd_bounty_liveness_prize_list),
            Bounty_liveness_prize_List = util:get_pd_field(?pd_bounty_liveness_prize_list, init_liveness_prize_list()),
            LivenessPrizeList = package_liveness_prize_list(Bounty_liveness_prize_List),
            ?player_send(bounty_sproto:pkg_msg(?MSG_BOUNTY_PUSH_LIVENESS_PRIZE_LIST, { Liveness, LivenessPrizeList })),

            FreeRefreshCount = attr_new:get(?pd_bounty_task_free_refresh_count), % 免费刷新次数
            PayRefreshCount = attr_new:get(?pd_bounty_task_pay_refresh_count),  % 付费刷新次数
            case util:get_pd_field(?pd_bounty_task_list, [])of
                [] ->
                    BountyTaskList = do_flush_bounty_task(),
                    NewTaskList = package_bounty_task_list(BountyTaskList),
                    %% ?DEBUG_LOG("NewTaskList0:~p", [NewTaskList]),
                    tool:do_send_after(?BOUNTY_RESET_TIME * 1000,
                        ?mod_msg(?MODULE, {refresh_bounty_task}),
                        ?bounty_timerref),
                    TimeStamp = get_bounty_time_stamp(),
                    ?player_send(bounty_sproto:pkg_msg(?MSG_BOUNTY_TASK_LIST, {TimeStamp, (FreeRefreshCount+PayRefreshCount), NewTaskList })),
                    ok;
                TaskList ->
                    OfflineTime =  erlang:get(?pd_last_logout_time),
                    RemainTime = get(?pd_bounty_refresh_remain),
                    NowTime = com_time:now(),
                    DTime = NowTime - OfflineTime + (RemainTime div 1000),
                    Num = DTime div ?BOUNTY_RESET_TIME,
                    NewRemainTime = (DTime rem ?BOUNTY_RESET_TIME) * 1000,
                    tool:do_send_after(NewRemainTime,
                        ?mod_msg(?MODULE, {refresh_bounty_task}),
                        ?bounty_timerref),
                    %% 时间戳
                    TimeStamp = get_bounty_time_stamp(),
                    if
                        Num >= 1 ->
                            BountyTaskList = do_flush_bounty_task(),
                            NewTaskList = package_bounty_task_list(BountyTaskList),
                            %% ?DEBUG_LOG("NewTaskList1:~p", [NewTaskList]),
                            ?player_send(bounty_sproto:pkg_msg(?MSG_BOUNTY_TASK_LIST, {TimeStamp, (FreeRefreshCount + PayRefreshCount), NewTaskList }));
                        true ->
                            NewTaskList = package_bounty_task_list(TaskList),
                            %% ?DEBUG_LOG("NewTaskList2:~p", [NewTaskList]),
                            %% ?DEBUG_LOG("time:~p", [trunc(NewRemainTime div 1000)]),
                            ?player_send(bounty_sproto:pkg_msg(?MSG_BOUNTY_TASK_LIST, {TimeStamp, (FreeRefreshCount + PayRefreshCount), NewTaskList }))
                    end
            end;
        false ->
            ok
    end.

offline(_SelfId) ->
    case load_cfg_open_server_happy:the_activity_is_over(?BOUNTY_TASK_ID) of
        true ->
            save_data(_SelfId),
            get_refresh_remain(),
            tool:cancel_sendafter([?bounty_timerref]);
        false ->
            dbcache:delete(?player_bounty_tab, _SelfId)
    end.
save_data(_SelfId) ->
    case is_in_activity_period() of
        true ->
            BountyTab =
                #player_bounty_tab{
                    id = _SelfId,
                    is_opened = util:get_pd_field(?IS_OPENED, 0),
                    bounty_task = get(?pd_bounty_task_list),
                    liveness = get(?pd_bounty_liveness),
                    bounty_liveness_prize = get(?pd_bounty_liveness_prize_list)
                },
            dbcache:update(?player_bounty_tab, BountyTab);
        false ->
            ok
    end.

%% 隔天重置刷新次数
on_day_reset(_Player) ->
    case is_in_activity_period() of
        true ->
            attr_new:set(?pd_bounty_task_free_refresh_count, 0),
            attr_new:set(?pd_bounty_task_pay_refresh_count, 0),
            ok;
        false ->
            ok
    end.

handle_client({Pack, Arg}) ->
    case is_in_activity_period() of
        true ->
            handle_client(Pack, Arg);
           %%  case task_open_fun:is_open(?OPEN_BOUNTY) of
           %%      ?false -> ?return_err(?ERR_NOT_OPEN_FUN);
           %%      ?true ->
           %%          handle_client(Pack, Arg)
           %%  end;
        false ->
            ?return_err(?ERR_NOT_OPEN_FUN)
    end.


%% 打开赏金任务面板
handle_client(?MSG_BOUNTY_TASK_LIST, {0}) ->
    FreeRefreshCount = attr_new:get(?pd_bounty_task_free_refresh_count), % 免费刷新次数
    PayRefreshCount = attr_new:get(?pd_bounty_task_pay_refresh_count),  % 付费刷新次数

    %% 统计打开过面板的玩家数
    case util:get_pd_field(?IS_OPENED, 0) of
        0 ->
            OpenedNum = load_db_misc:get(?misc_bounty_opened_num, 0),
            load_db_misc:set(?misc_bounty_opened_num, OpenedNum + 1),
            util:set_pd_field(?IS_OPENED, 1);
        _ ->
            pass
    end,

    BountyTaskList =
    case util:get_pd_field(?pd_bounty_task_list, []) of
        [] ->
            do_flush_bounty_task();
        List ->
            List
    end,
    NewTaskList = package_bounty_task_list(BountyTaskList),

    %% 统计玩家打开赏金任务面板的次数
    OldCount = load_db_misc:get(?misc_bounty_open_times, 0),
    load_db_misc:set(?misc_bounty_open_times, OldCount + 1),
    %%    load_db_misc:add_bounty_type_once(?misc_bounty_open_times),

    TimeStamp = get_bounty_time_stamp(),
    %% ?DEBUG_LOG("task_o:~p", [bounty_sproto:pkg_msg(?MSG_BOUNTY_TASK_LIST, { TimeStamp, (FreeRefreshCount + PayRefreshCount), NewTaskList })]),
    ?player_send(bounty_sproto:pkg_msg(?MSG_BOUNTY_TASK_LIST, { TimeStamp, (FreeRefreshCount + PayRefreshCount), NewTaskList }));


%% 刷新赏金任务
handle_client(?MSG_BOUNTY_TASK_LIST, {1}) ->
    %% 免费总共次数
    FreeRefreshTimes = get_free_refresh_times(),
    FreeRefreshCount = attr_new:get(?pd_bounty_task_free_refresh_count),
    PayRefreshCount = attr_new:get(?pd_bounty_task_pay_refresh_count),
    TotalCount = FreeRefreshCount + PayRefreshCount,

    Ret =
    if
        FreeRefreshCount < FreeRefreshTimes->
            attr_new:set(?pd_bounty_task_free_refresh_count, FreeRefreshCount + 1),
            %% 统计玩家免费刷新次数
            OldCount = load_db_misc:get(?misc_free_refresh_times, 0),
            load_db_misc:set(?misc_free_refresh_times, OldCount + 1),
            %% load_db_misc:add_bounty_type_once(?misc_free_refresh_times),
            ok;
        ?true ->
            CostIdList = misc_cfg:get_shangjin_refresh_cost(),
            CostId =
                if
                    TotalCount >= erlang:length(CostIdList) ->
                        lists:last(CostIdList);
                    true ->
                        lists:nth(TotalCount + 1, CostIdList)
                end,

             case cost:cost(CostId, ?FLOW_REASON_BOUNTY) of
                 ok ->
                     %% ?DEBUG_LOG("cost:~p", [CostId]),
                     %% 统计玩家付费刷新次数
                     OldCount = load_db_misc:get(?misc_pay_refresh_times, 0),
                     load_db_misc:set(?misc_pay_refresh_times, OldCount + 1),
                     %% load_db_misc:add_bounty_type_once(?misc_pay_refresh_times),
                     attr_new:set(?pd_bounty_task_pay_refresh_count, PayRefreshCount + 1),
                     ok;
                 _ ->
                     {error, cost_not_enought}
             end
    end,
    case Ret of
        ok ->
            BountyTaskList = do_flush_bounty_task(),
            NewFreeRefreshCount = attr_new:get(?pd_bounty_task_free_refresh_count),
            NewPayRefreshCount = attr_new:get(?pd_bounty_task_pay_refresh_count),
            NewTaskList = package_bounty_task_list(BountyTaskList),
            TimeStamp = get_bounty_time_stamp(),
            %% ?DEBUG_LOG("PKG_MSG:~p", [bounty_sproto:pkg_msg(?MSG_BOUNTY_TASK_LIST, {TimeStamp,(NewFreeRefreshCount + NewPayRefreshCount), NewTaskList})]),
            ?player_send(bounty_sproto:pkg_msg(?MSG_BOUNTY_TASK_LIST, {TimeStamp,(NewFreeRefreshCount + NewPayRefreshCount), NewTaskList}));
        {error, flush_max} ->
            ?return_err(?REPLY_MSG_BOUNTY_REFRESH_1);
        {error, cost_not_enought} ->
            ?return_err(?REPLY_MSG_BOUNTY_REFRESH_2);
        _ ->
            ?return_err(?REPLY_MSG_BOUNTY_REFRESH_255)
     end;

%% 完成赏金任务
handle_client(?MSG_BOUNTY_COMPLETE, {TaskId}) ->
    Ret = complete_bounty_task(TaskId),
    %% ?DEBUG_LOG("Ret:~p", [Ret]),
    Reply =
        case Ret of
            ok ->
                BountyTaskList = get(?pd_bounty_task_list),
                NewFreeRefreshCount = attr_new:get(?pd_bounty_task_free_refresh_count),
                NewPayRefreshCount = attr_new:get(?pd_bounty_task_pay_refresh_count),
                NewTaskList = package_bounty_task_list(BountyTaskList),
                TimeStamp = get_bounty_time_stamp(),
                %% ?DEBUG_LOG("pkg_taskLIst:~p", [bounty_sproto:pkg_msg(?MSG_BOUNTY_TASK_LIST, {TimeStamp,(NewFreeRefreshCount + NewPayRefreshCount), NewTaskList})]),
                ?player_send(bounty_sproto:pkg_msg(?MSG_BOUNTY_TASK_LIST, {TimeStamp,(NewFreeRefreshCount + NewPayRefreshCount), NewTaskList})),

                Liveness = get(?pd_bounty_liveness),
                Bounty_liveness_prize_List = get(?pd_bounty_liveness_prize_list),
                LivenessPrizeList = package_liveness_prize_list(Bounty_liveness_prize_List),
                %% ?DEBUG_LOG("pkg_prize:~p", [bounty_sproto:pkg_msg(?MSG_BOUNTY_PUSH_LIVENESS_PRIZE_LIST, { Liveness, LivenessPrizeList })]),
                ?player_send(bounty_sproto:pkg_msg(?MSG_BOUNTY_PUSH_LIVENESS_PRIZE_LIST, { Liveness, LivenessPrizeList })),
                open_server_happy_mng:sync_task(?SHANGJIN_TASK, 1),
                ?REPLY_MSG_BOUNTY_COMPLETE_OK;
            {error, bounty_no_this_task} ->
                ?REPLY_MSG_BOUNTY_COMPLETE_1;
            {error, bounty_already_complete} ->
                ?REPLY_MSG_BOUNTY_COMPLETE_2;
            {error, bounty_cant_complete} ->
                ?REPLY_MSG_BOUNTY_COMPLETE_3;
            _ ->
                ?REPLY_MSG_BOUNTY_COMPLETE_255
        end,
    ?player_send(bounty_sproto:pkg_msg(?MSG_BOUNTY_COMPLETE, {Reply}));

%% 领取活跃度奖励
handle_client(?MSG_BOUNTY_LIVENESS_GET_PRIZE, {Id}) ->
    Ret = get_prize_by_bounty_liveness(Id),
    Reply =
        case Ret of
            ok ->
                %% 每个阶段的领取人数
                OldLivenessGet = load_db_misc:get(?misc_bounty_liveness_get, []),
                NewLivenessGet =
                    case lists:keyfind(Id, 1, OldLivenessGet) of
                        ?false ->
                            [{Id, 1} | OldLivenessGet];
                        {Id, Count} ->
                            lists:keyreplace(Id, 1, OldLivenessGet, {Id, Count+1})
                    end,
                load_db_misc:set(?misc_bounty_liveness_get, NewLivenessGet),

                Liveness = get(?pd_bounty_liveness),
                Bounty_liveness_prize_List = get(?pd_bounty_liveness_prize_list),
                LivenessPrizeList = package_liveness_prize_list(Bounty_liveness_prize_List),
                %% ?DEBUG_LOG("prize_list:~p", [bounty_sproto:pkg_msg(?MSG_BOUNTY_PUSH_LIVENESS_PRIZE_LIST, { Liveness, LivenessPrizeList })]),
                ?player_send(bounty_sproto:pkg_msg(?MSG_BOUNTY_PUSH_LIVENESS_PRIZE_LIST, { Liveness, LivenessPrizeList })),

                ?REPLY_MSG_BOUNTY_PRIZE_OK;
            {error, cant_get} ->
                ?REPLY_MSG_BOUNTY_PRIZE_1;
            {error, already_get} ->
                ?REPLY_MSG_BOUNTY_PRIZE_2;
            {error, other_err} ->
                ?REPLY_MSG_BOUNTY_PRIZE_255
        end,
    ?player_send(bounty_sproto:pkg_msg(?MSG_BOUNTY_LIVENESS_GET_PRIZE, {Reply}));

handle_client(Mod, Msg) ->
    ?ERROR_LOG("no known msg Mod:~p Msg:~p", [bounty_sproto:to_s(Mod), Msg]),
    {error, unknown_msg}.



refresh_bounty_task() ->
    FreeRefreshCount = attr_new:get(?pd_bounty_task_free_refresh_count), % 免费刷新次数
    PayRefreshCount = attr_new:get(?pd_bounty_task_pay_refresh_count),  % 付费刷新次数
    BountyTaskList = do_flush_bounty_task(),
    NewTaskList = package_bounty_task_list(BountyTaskList),
    tool:do_send_after(?BOUNTY_RESET_TIME * 1000,
        ?mod_msg(?MODULE, {refresh_bounty_task}),
        ?bounty_timerref),
    TimeStamp = get_bounty_time_stamp(),
    ?player_send(bounty_sproto:pkg_msg(?MSG_BOUNTY_TASK_LIST, { TimeStamp, (FreeRefreshCount + PayRefreshCount),NewTaskList })),
    ok.

do_flush_bounty_task() ->
    %% 随机三个任务Id
    %% BountyList = load_richang_task:get_daily_task_id_list_by_player_level(), %% [{taskId,taskStatus,goaltype,goalId,count}]
    BountyList = get_bounty_task_id_list(), %% [{taskId,taskStatus,goaltype,goalId,count}]
    %% ?INFO_LOG("BountyList:~p", [BountyList]),
    put(?pd_bounty_task_list, BountyList),
    BountyList.

%% 随机任务
get_bounty_task_id_list() ->
    MyLev = get(?pd_level),
    %% 筛选出所有任务Id
    IdList =
        lists:foldl(
            fun({_Key, Cbp}, Acc) ->
                Id = Cbp#bounty_task_cfg.id,
                Weight = Cbp#bounty_task_cfg.weight,
                {MinLev,MaxLev} = Cbp#bounty_task_cfg.level,
                if
                    MyLev >= MinLev andalso MyLev =< MaxLev ->
                        [{Id, Weight}|Acc];
                    true ->
                        Acc
                end
            end,
            [],
            ets:tab2list(bounty_task_cfg)),

    %?DEBUG_LOG("IdList-------------------:~p",[IdList]),
    %% 根据权重随机出3个任务
    NewIdList = util:get_val_by_weight(IdList, get_bounty_task_size(IdList)),
    %?DEBUG_LOG("NewIdList-------------------:~p",[NewIdList]),
    lists:foldl(
        fun(Id, L) ->
            #bounty_task_cfg{condition = Condition} = load_cfg_shangjin_task:lookup_bounty_task_cfg(Id),
            {BountyType, MaxCount} = Condition,
            %%[{ Id, BountyType, ?BOUNTY_TASK_STATUS_0, MaxCount, 0 } | L]
            [{ Id, BountyType, 0, MaxCount ,?BOUNTY_TASK_STATUS_0} | L]
        end,
        [],
        NewIdList).

%% 最多随机三个赏金任务
get_bounty_task_size(IdList) ->
    Size = length(IdList),
    if
        Size >= 3 ->
            3;
        true ->
            Size
    end.

%% 供外部调用的接口
do_bounty_task(_BountyType, 0) ->
    pass;
do_bounty_task(BountyType, Count)  ->
    BountyList = get(?pd_bounty_task_list),
    case BountyList of
        ?undefined ->
            pass;
        _ ->
            %% 每个任务都算完成
            lists:foreach(
                fun(BountyTask) ->
                    case BountyTask of
                        %% 赏金任务已完成
                        { Id, BountyType,  MaxCount, MaxCount, _} ->
                            pass;
                        { Id, BountyType, OldCount, MaxCount, ?BOUNTY_TASK_STATUS_0} ->
                            NewCount = OldCount + Count,
                            NewBountyList = get(?pd_bounty_task_list),
                            TaskList =
                                if
                                    NewCount >= MaxCount ->
                                        lists:keyreplace(Id, 1, NewBountyList, {Id, BountyType, MaxCount, MaxCount, ?BOUNTY_TASK_STATUS_0});
                                    true ->
                                        lists:keyreplace(Id, 1, NewBountyList, {Id, BountyType, NewCount, MaxCount, ?BOUNTY_TASK_STATUS_0})
                                end,
                            put(?pd_bounty_task_list, TaskList),
                            NewTaskList = package_bounty_task_list(TaskList),
                            FreeRefreshCount = attr_new:get(?pd_bounty_task_free_refresh_count), % 免费刷新次数
                            PayRefreshCount = attr_new:get(?pd_bounty_task_pay_refresh_count),  % 付费刷新次数
                            TimeStamp = get_bounty_time_stamp(),
                            ?player_send(bounty_sproto:pkg_msg(?MSG_BOUNTY_TASK_LIST, { TimeStamp, (FreeRefreshCount + PayRefreshCount), NewTaskList }));
                        _ ->
                            pass
                    end
                end,
                BountyList
            )
    end.


%% 玩家提交任务
complete_bounty_task(Id) ->
    BountyList = get(?pd_bounty_task_list),
    case lists:keyfind(Id, 1, BountyList) of
        %% 没接取该赏金任务
		?false ->
            {error, bounty_no_this_task};
        { Id, BountyType, _, _ , ?BOUNTY_TASK_STATUS_1} ->
            {error, bounty_already_complete};
        { Id, BountyType, MaxCount, CurCount , ?BOUNTY_TASK_STATUS_0} ->
            if
                CurCount >= MaxCount ->
                    PrizeId = load_cfg_shangjin_task:get_bounty_prizeId_by_id(Id),
                    case PrizeId of
                        0 ->
                            pass;
                        _ ->
                            prize:prize_mail(PrizeId, ?S_MAIL_BOUNTY_COMPLETE_PRIZE, ?FLOW_REASON_BOUNTY)
                    end,
                    %% 设置活跃度
                    CurLiveness = util:get_pd_field(?pd_bounty_liveness, 0),
                    Liveness = load_cfg_shangjin_task:get_bounty_liveness_by_id(Id),
                    NewLiveness = CurLiveness + Liveness,
                    put(?pd_bounty_liveness, NewLiveness),

                    ListPrize = update_liveness_prize_list(),
                    put(?pd_bounty_liveness_prize_list,ListPrize),
                    %% ?DEBUG_LOG("ListPrize:~p", [ListPrize]),
                    %% 完成任务后更新排行榜
                    ranking_lib:update(?ranking_bounty, get(?pd_id), NewLiveness),

                    NewGoalList = lists:keyreplace(Id, 1, BountyList, {Id, BountyType, MaxCount, MaxCount, ?BOUNTY_TASK_STATUS_1}),
                    put(?pd_bounty_task_list, NewGoalList),
                    ok;
                true ->
                    {error, bounty_cant_complete}
            end
	end.

%% 初始化活跃度奖励表
init_liveness_prize_list() ->
    L = misc_cfg:get_shangjin_task_liveness(), %% #{1,20,id}
    lists:foldl(
        fun({Id, Liveness, PirzeId}, Acc) ->
            [ { Id, Liveness, PirzeId, ?LIVENESS_PRIZE_STATUS_0 } | Acc]
        end,
        [],
        L
    ).

%% 领取活跃度奖励
get_prize_by_bounty_liveness(Id) ->
    Bounty_liveness_prize_list = get(?pd_bounty_liveness_prize_list),   %% #{id ,liveness, prizeId, status}
    %% ?INFO_LOG("Bounty_liveness_prize_list:~p", [Bounty_liveness_prize_list]),
    {Id, Liveness, PrizeId, Status} = lists:keyfind(Id, 1, Bounty_liveness_prize_list),
    %% ?DEBUG_LOG("status:~p", [Status]),

    %%prize:prize(PrizeId),
    %%NewBountyLivenessPrizeList = lists:keyreplace(Id, 1, Bounty_liveness_prize_list, {Id, Liveness, PrizeId, ?LIVENESS_PRIZE_STATUS_2}),
    %%put(?pd_bounty_liveness_prize_list, NewBountyLivenessPrizeList),
    %%ok.
    case Status of
        ?LIVENESS_PRIZE_STATUS_0 ->
            {error, cant_get};
        ?LIVENESS_PRIZE_STATUS_1 ->
            prize:prize(PrizeId, ?FLOW_REASON_BOUNTY),
            NewBountyLivenessPrizeList = lists:keyreplace(Id, 1, Bounty_liveness_prize_list, {Id, Liveness, PrizeId, ?LIVENESS_PRIZE_STATUS_2}),
            put(?pd_bounty_liveness_prize_list, NewBountyLivenessPrizeList),
            ok;
        ?LIVENESS_PRIZE_STATUS_2 ->
            {error, already_get};
        _ ->
            {error, other_err}
    end.

%% 获取定时器剩余时间
get_refresh_remain() ->
    Timerref = get(?bounty_timerref),
    case Timerref of
        ?undefined ->
            NewRemain = ?BOUNTY_RESET_TIME * 1000,
            put(?pd_bounty_refresh_remain, NewRemain),
            NewRemain;
        _ ->
            Remain = erlang:read_timer(Timerref),
            NewRemain =
                case Remain of
                    false ->
                        ?BOUNTY_RESET_TIME * 1000;
                    _ ->
                        Remain
                end,
            put(?pd_bounty_refresh_remain, NewRemain),
            NewRemain
    end.


%% 获取免费次数
get_free_refresh_times() ->
    CostList = misc_cfg:get_shangjin_refresh_cost(),
    NewList = lists:filter(
        fun(E) ->
            E =:= 0
        end, CostList),
    erlang:length(NewList).

update_liveness_prize_list() ->
    PrizeList = get(?pd_bounty_liveness_prize_list),
    Liveness = get(?pd_bounty_liveness),
    lists:foldl(
        fun({Id, Ln, PrizeId, Status}, Acc) ->
            if
                Status =:= ?LIVENESS_PRIZE_STATUS_0 ->
                    if
                        Liveness >= Ln ->
                            NewAcc = lists:keyreplace(Id, 1, Acc, {Id, Ln, PrizeId, ?LIVENESS_PRIZE_STATUS_1}),
                            NewAcc;
                        true ->
                            Acc
                    end;
                true ->
                    Acc
            end
        end,
        PrizeList,
        PrizeList).

package_liveness_prize_list(PrizeList) ->
    lists:foldl(
        fun({Id,_,_,Status}, Acc) ->
            [{Id, Status} | Acc]
        end,
        [],
        PrizeList
    ).

package_bounty_task_list(TaskList) ->
    lists:foldl(
        fun({Id, _BountyType, NewCount, MaxCount, Status}, Acc) ->
            [{Id, NewCount, MaxCount, Status} | Acc]
        end,
        [],
        TaskList
    ).

%% 获取赏金任务到结束的时间戳
get_bounty_time_stamp() ->
    %% 定时器时间
    RefreshTime = get_refresh_remain(),
    %% CloseTime = load_cfg_open_server_happy:get_open_server_close_time(),
    %% CloseTimeSec = calendar:datetime_to_gregorian_seconds(CloseTime),
    %% LocalTimeSec = calendar:datetime_to_gregorian_seconds(calendar:local_time()),
    %% TimeStamp = CloseTimeSec - LocalTimeSec + com_time:now(),
    TimeStamp = (RefreshTime div 1000) + com_time:now(),
    TimeStamp.


%% 判断是否在活动期间
is_in_activity_period() ->
    {BeginTime,[Y2,M2,D2,H2,Mi2]} = load_cfg_open_server_happy:get_activity_time_by_id(?BOUNTY_TASK_ID),
    CurTime = calendar:local_time(),
    CloseTime = {{Y2,M2,D2},{H2,Mi2,0}},
    case BeginTime of
        [0,0,0,0,0] ->
            CurTime =< CloseTime;
        [Y1,M1,D1,H1,Mi1] ->
            StartTime = {{Y1,M1,D1},{H1,Mi1,0}},
            CurTime >= StartTime andalso CurTime =< CloseTime;
        _ ->
            false
    end.

pass_room_star(PassStar) ->
    if
        PassStar >= 9 ->
            do_bounty_task(?BOUNTY_TASK_PASS_9_STAR, 1),
            do_bounty_task(?BOUNTY_TASK_PASS_8_STAR, 1),
            do_bounty_task(?BOUNTY_TASK_PASS_7_STAR, 1);
        PassStar >= 8 ->
            do_bounty_task(?BOUNTY_TASK_PASS_8_STAR, 1),
            do_bounty_task(?BOUNTY_TASK_PASS_7_STAR, 1);
        PassStar >= 7 ->
            do_bounty_task(?BOUNTY_TASK_PASS_7_STAR, 1);
        true ->
            pass
    end.

%% 获得银星
count_get_yinxing(Num) ->
    if
        Num >= 9 ->
            do_bounty_task(?BOUNTY_TASK_GET_5_STAR, 1),
            do_bounty_task(?BOUNTY_TASK_GET_6_STAR, 1),
            do_bounty_task(?BOUNTY_TASK_GET_7_STAR, 1),
            do_bounty_task(?BOUNTY_TASK_GET_8_STAR, 1),
            do_bounty_task(?BOUNTY_TASK_GET_9_STAR, 1);
        Num >= 8 ->
            do_bounty_task(?BOUNTY_TASK_GET_5_STAR, 1),
            do_bounty_task(?BOUNTY_TASK_GET_6_STAR, 1),
            do_bounty_task(?BOUNTY_TASK_GET_7_STAR, 1),
            do_bounty_task(?BOUNTY_TASK_GET_8_STAR, 1);
        Num >= 7 ->
            do_bounty_task(?BOUNTY_TASK_GET_5_STAR, 1),
            do_bounty_task(?BOUNTY_TASK_GET_6_STAR, 1),
            do_bounty_task(?BOUNTY_TASK_GET_7_STAR, 1);
        Num >= 6 ->
            do_bounty_task(?BOUNTY_TASK_GET_5_STAR, 1),
            do_bounty_task(?BOUNTY_TASK_GET_6_STAR, 1);
        Num >= 5 ->
            do_bounty_task(?BOUNTY_TASK_GET_5_STAR, 1);
        true ->
            pass
    end.

%% 合成宝石
count_update_gem(GemLev, Count) ->
    case GemLev of
        2 ->
            do_bounty_task(?BOUNTY_TASK_GEM2, Count);
        3 ->
            do_bounty_task(?BOUNTY_TASK_GEM3, Count);
        4 ->
            do_bounty_task(?BOUNTY_TASK_GEM4, Count);
        5 ->
            do_bounty_task(?BOUNTY_TASK_GEM5, Count);
        6 ->
            do_bounty_task(?BOUNTY_TASK_GEM6, Count);
        7 ->
            do_bounty_task(?BOUNTY_TASK_GEM7, Count);
        8 ->
            do_bounty_task(?BOUNTY_TASK_GEM8, Count);
        9 ->
            do_bounty_task(?BOUNTY_TASK_GEM9, Count);
        10 ->
            do_bounty_task(?BOUNTY_TASK_GEM10, Count);
        _ ->
            pass
    end.
