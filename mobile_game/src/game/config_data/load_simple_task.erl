-module(load_simple_task).

%% API
-export([get_simple_task_type_by_taskid/1,
    get_simple_task_progress_by_taskid/1,
    init_simple_task_remap/0,
    get_simple_task_type_and_progress/1,
    get_simple_taskid/1]).


-include("inc.hrl").
-include("load_simple_task.hrl").
-include_lib("config/include/config.hrl").
-include("safe_ets.hrl").
-define(TST, simple_task_to_type).
-define(TST2, simple_task_to_progress).
-define(TST3, simple_task_type_to_id).

create_safe_ets() ->
    [
        safe_ets:new(?TST, [?named_table, ?public, {?read_concurrency, ?true}, {?write_concurrency, ?true}]),
        safe_ets:new(?TST2, [?named_table, ?public, {?read_concurrency, ?true}, {?write_concurrency, ?true}]),
        safe_ets:new(?TST3, [?named_table, ?public, {?read_concurrency, ?true}, {?write_concurrency, ?true}])
    ].

get_simple_task_type_and_progress(Id) ->
    Type = get_simple_task_type_by_taskid(Id),
    Progress = get_simple_task_progress_by_taskid(Id),
    %?DEBUG_LOG("simple task Type---:~p--Progress---:~p",[Type, Progress]),
    if
        Type =/= ?none, Type =/= ?none ->
            {Type, Progress};
        true ->
            false
    end.

get_simple_task_type_by_taskid(Id) ->
    case ets:lookup(?TST, Id) of
        [] ->
            ?none;
        [{_, Type}] ->
            Type
    end.
get_simple_task_progress_by_taskid(Id) ->
    case ets:lookup(?TST2, Id) of
        [] ->
            ?none;
        [{_, P}] ->
            P
    end.

init_simple_task_remap() ->
    {NewL1, NewL2, NewL3} =
        lists:foldl(fun({Key, R}, {List1, List2, List3}) ->
            StId = R#simple_task_cfg.simple_task_progress,
            DType = R#simple_task_cfg.simple_task_type,
            {util:list_add_list([{StId, DType}], List1), util:list_add_list([{StId, Key}], List2), util:list_add_list([{DType, StId}], List3)}
        end,
            {[], [], []},
            ets:tab2list(simple_task_cfg)),
    ets:insert(?TST, NewL1),
    ets:insert(?TST2, NewL2),
    ets:insert(?TST3, NewL3).



get_simple_taskid(TaskType) ->
    case ets:lookup(?TST3, TaskType) of
        [] ->
            ?none;
        [{_, Id}] ->
            Id
    end.



load_config_meta() ->
    [
        #config_meta{
            record = #simple_task_cfg{},
            fields = ?record_fields(simple_task_cfg),
            file = "simple_task.txt",
            keypos = #simple_task_cfg.id,
            verify = fun verify_simple_task/1}
    ].


verify_simple_task(#simple_task_cfg{id = Id, simple_task_type = St, simple_task_progress = Sp}) ->
    ?check(St > 1000, "simple_task.txt中， [~p] simple_task_type: ~p 配置无效。", [Id, St]),
    ?check(load_task_progress:is_exist_task_new_cfg(Sp), "task.txt中， [~p] simple_task_progress: ~p 配置无效。", [Id, Sp]),
    ok.


