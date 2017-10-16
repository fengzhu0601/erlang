%%%-------------------------------------------------------------------
%%% @author yujian
%%% @doc 功能开放
%%%-------------------------------------------------------------------
-module(load_task_open_fun).
-include_lib("config/include/config.hrl").
-include("inc.hrl").
-include("load_task_open_fun.hrl").
-include("safe_ets.hrl").


-export([
    init_open_task_ets/0,
    get_level_limit_by_level/1,
    get_main_task_limit_by_taskId/1
]).

-define(open_fun_level_limit, open_fun_level_limit).
-define(open_fun_taskId_limit, open_fun_taskId_limit).


load_config_meta() ->
    [
        #config_meta
        {
            record = #open_fun_cfg{},
            fields = ?record_fields(open_fun_cfg),
            file = "open_fun.txt",
            keypos = #open_fun_cfg.id,
            all = [#open_fun_cfg.id],
            verify = fun verify/1
        }
    ].

verify(#open_fun_cfg{id = Id, sinks = Sinks, limit_level = LimitLevel, limit_main_task = LimitMainTaskId, limit_chapter = LimitChapter}) ->
    ?check(Id > 0, "open_fun.txt [~p] id  无效!", [Id]),
    ?check(Sinks > 0, "open_fun.txt [~p] sinks ~p 配置无效!", [Id, Sinks]),
    ?check(LimitLevel > 0 andalso LimitLevel =< 100, "open_fun.txt [~p] limit_level ~p 配置无效!", [Id, LimitLevel]),
    ?check(is_integer(LimitMainTaskId), "open_fun.txt ~w LimitMainTaskId ~w 无效!", [Id]),
    ?check(is_integer(LimitChapter), "open_fun.txt ~w LimitChapter ~w 无效!", [Id]).

create_safe_ets() ->
    [
        safe_ets:new(?open_fun_level_limit, [?named_table, ?public, {?read_concurrency, ?true}, {?write_concurrency, ?true}]),
        safe_ets:new(?open_fun_taskId_limit, [?named_table, ?public, {?read_concurrency, ?true}, {?write_concurrency, ?true}])
    ].

init_open_task_ets() ->
    {LimitLevelList, LimitTaskList} =
        lists:foldl
        (
            fun({_Num, Record}, {AccLevelList, AccTaskIdList}) ->
                case is_record(Record, open_fun_cfg) of
                    true ->
                        Id = Record#open_fun_cfg.id,
                        LimitLevel = Record#open_fun_cfg.limit_level,
                        LimitTaskId = Record#open_fun_cfg.limit_main_task,
                        case is_integer(LimitLevel) andalso LimitLevel =/= 0 of
                            true ->
                                LevelList1 = val_add_list(LimitLevel, Id, AccLevelList),
                                case is_integer(LimitTaskId) andalso LimitTaskId =/= 0 of
                                    true ->
                                        TaskIdList1 = val_add_list(LimitTaskId, Id, AccTaskIdList),
                                        {LevelList1, TaskIdList1};
                                    _ ->
                                        {LevelList1, AccTaskIdList}
                                end;
                            _ ->
                                case is_integer(LimitTaskId) andalso LimitTaskId =/= 0 of
                                    true ->
                                        TaskIdList1 = val_add_list(LimitTaskId, Id, AccTaskIdList),
                                        {AccLevelList, TaskIdList1};
                                    _ ->
                                        {AccLevelList, AccTaskIdList}
                                end
                        end;
                    _ ->
                        {AccLevelList, AccTaskIdList}
                end
            end,
            {[], []},
            ets:tab2list(open_fun_cfg)
        ),
    ets:insert(?open_fun_level_limit, LimitLevelList),
    ets:insert(?open_fun_taskId_limit, LimitTaskList).

val_add_list(Key, Val, List) ->
    case lists:keyfind(Key, 1, List) of
        {_Key, ListTemp} ->
            lists:keyreplace(Key, 1, List, {Key, [Val|ListTemp]});
        _ ->
            [{Key, [Val]} | List]
    end.

get_level_limit_by_level(Level) ->
    case ets:lookup(?open_fun_level_limit, Level) of
        [] ->
            [];
        [{_Level, IdList}] ->
            IdList
    end.

get_main_task_limit_by_taskId(TaskId) ->
    case ets:lookup(?open_fun_taskId_limit, TaskId) of
        [] ->
            [];
        [{_TaskId, TaskIdList}] ->
            TaskIdList
    end.



