%%%-------------------------------------------------------------------
%%% @author dsl
%%% @doc 每日任务
%%%
%%% @end
%%%-------------------------------------------------------------------

-module(daily_task_tool).

%-include_lib("config/include/config.hrl").

-include("inc.hrl").
-include("player.hrl").
-include("task_def.hrl").
-include("item_bucket.hrl").
-include("task_new_def.hrl").
-include("load_cfg_daily_task.hrl").


-export([
    % get_count/0,
    % get_daily_task_id/0,
    % set_daily_task_star/0,
    % get_daily_prize_by_id/0,
    % flush_star/1,
    % get_next_daily_task_id/0
]).

%%-record(task_daily_star_cfg, {
%%    id,         %% 本日常任务的玩家等级ID
%%    up_probo,   %% 1,任务升星概率。2,升星概率为一个含五个元素的列表，[P1,P2,P3,P4,P5]。比如：[20,20,30,20,10]。
%%    task_ids,   %% 任务ids [TaskId]
%%    prize       %% 奖励ID列表。比如：[3001,3002,3003,3004,3005]
%%}).

% -define(daily_max_star, 5).  %% 最大星级

% -define(daily_task_use_do_max_time, 5).

%% get daily task id by player level 
% get_daily_task_id() ->
%     UsedCount = get(?pd_task_daily_task_times),
%     TaskId = load_task_progress:get_taskid(?daily_task_type, UsedCount),
%     TaskStatus = task_system:get_task_state({?daily_task_type, TaskId}),
%     if
%         UsedCount =:= 0 ->
%             do_daily_task_id(UsedCount);
%         true ->
%             case TaskStatus of
%                 ?task_over ->
%                     do_daily_task_id(UsedCount);
%                 _ ->
%                     0
%             end
%     end.

% do_daily_task_id(UsedCount) ->
%     if
%         UsedCount >= ?daily_task_use_do_max_time ->
%             0;
%         ?true ->
%             load_task_progress:get_taskid(?daily_task_type, UsedCount + 1)
%     end.

% get_next_daily_task_id() ->
%     UsedCount = get(?pd_task_daily_task_times),
%     load_task_progress:get_taskid(?daily_task_type, UsedCount + 1).


% set_daily_task_star() ->
%     UsedCount = get(?pd_task_daily_task_times),
%     attr_new:set(?pd_task_daily_task_times, UsedCount + 1),
%     attr_new:set(?pd_task_daily_star, 1).

% get_daily_prize_by_id() ->
%     CurLvL = attr_new:get(?pd_level),
%     case load_cfg_daily_activity:lookup_task_daily_star_cfg(CurLvL) of
%         #task_daily_star_cfg{prize = PirzeList} ->
%             Star = get(?pd_task_daily_star),
%             lists:nth(Star, PirzeList);
%         _ ->
%             0
    % end.

%% 刷星级
% flush_star(FlushTimes) ->
%     CurLvL = attr_new:get(?pd_level),
%     Star = get(?pd_task_daily_star),
%     case load_cfg_daily_activity:lookup_task_daily_star_cfg(CurLvL) of
%         #task_daily_star_cfg{up_probo = UpProtoL} ->
%             RandomStar = util:random_list_of_task_star(UpProtoL),
%             NStar = max(RandomStar, Star),
%             attr_new:set(?pd_task_daily_star, NStar),
%             attr_new:set(?pd_task_daily_flush_times, FlushTimes + 1),
%             ok;
%         _ ->
%             {error, not_found_cfg}
%     end.



%% 获取每日任务次数{Count, MaxCount}
% get_count() ->
%     {get(?pd_task_daily_task_times), ?daily_task_use_do_max_time}.


%%load_config_meta() ->
%%    [
%%        #config_meta{
%%            record = #task_daily_star_cfg{},
%%            fields = ?record_fields(task_daily_star_cfg),
%%            file = "task_daily_star.txt",
%%            keypos = #task_daily_star_cfg.id,
%%            rewrite = fun change/1,
%%            verify = fun verify_star/1}
%%    ].



%%verify_star(#task_daily_star_cfg{id = Id, up_probo = _Upp, prize = Prize, task_ids = _TaskIds}) ->
%%    ?check(check_player_level(Id), "task_daily_star.txt中，[~w] 是无效的玩家等级。", [Id]),
%%    check_prize(Prize),
%%    ok.

%%%% 每日任务星级转换
%%change(_) ->
%%    NewCfgList =
%%        ets:foldl(fun({_, #task_daily_star_cfg{id = Id, up_probo = ProboList} = Cfg}, FAcc) ->
%%            {Total, NProtoL} = com_util:probo_build_single(ProboList),
%%            ?check(Total =:= 100, "task_daily_star.txt [~w] up_probo 权重和不为100 ~w", [Id, ProboList]),
%%            [Cfg#task_daily_star_cfg{up_probo = NProtoL} | FAcc]
%%        end, [], task_daily_star_cfg),
%%    NewCfgList.


%%check_player_level(Id) ->
%%    is_integer(Id) andalso (1 =< Id).


%% 3. prize.
%%check_prize(Prize) ->
%%    ?check(is_list(Prize), "in task_daily_star.txt, [~p] is not a list", [Prize]),
%%    ?check(length(Prize) == 5, "in task_daily_star.txt, the element number of [~p] is not 5", [Prize]),
%%    lists:foreach(
%%        fun(PrizeID) ->
%%            ?check(prize:is_exist_prize_cfg(PrizeID), "in task_daily_star.txt, [~p] is not a valid PrizeID", [PrizeID])
%%        end,
%%        Prize).