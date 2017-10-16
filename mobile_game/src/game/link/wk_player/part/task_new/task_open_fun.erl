%%%-------------------------------------------------------------------
%%% @author yujian
%%% @doc
%%%-------------------------------------------------------------------
-module(task_open_fun).
-include("inc.hrl").
-include("player.hrl").
-include("task_def.hrl").
-include("load_task_open_fun.hrl").

-export([is_open/1, level_trigger/1, task_trigger/1]).
-export([
    level_trigger_1/1,
    task_trigger_1/1
]).

%% 做主线任务触发
task_trigger(TaskId) ->
    % lists:foreach(fun(#open_fun_cfg{sinks = Sinks, limit_level = LimitLevel, limit_main_task = LimitTaskId})
    %     if
    %         TaskId == ->
    %             body
    %     end
    % end,
    % lookup_all_tab()).
    FunMap = fun(#open_fun_cfg{sinks = Sinks, task_trigger = _TaskIdList, limit_level = Level, limit_main_task = LimitTaskId, limit_chapter = _LimitChapter}) ->
        if
            LimitTaskId =:= TaskId ->
                case attr_new:get_sink_state(Sinks) of
                    ?FALSE ->
                        case check_level(Level) of
                            ?true ->
                                attr_new:set_sink_state(Sinks, ?TRUE),
                                ?true;
                            ?false ->
                                ?false
                        end;
                    _ ->
                        ?true
                end;
            true ->
                ok
        end
    end,
    lists:map(FunMap, lookup_all_tab()).

task_trigger_1(TaskId) ->
    Fun =
        fun(CfgId) ->
            #open_fun_cfg{sinks = Sinks, limit_level = LimitLevel,
                limit_main_task = LimitTaskId} = load_task_open_fun:lookup_open_fun_cfg(CfgId),
            if
                LimitTaskId =:= TaskId ->
                    case attr_new:get_sink_state(Sinks) of
                        ?FALSE ->
                            case check_level(LimitLevel) of
                                ?true ->
                                    attr_new:set_sink_state(Sinks, ?TRUE),
                                    ?true;
                                ?false ->
                                    ?false
                            end;
                        _ ->
                            ?true
                    end;
                true ->
                    ok
            end
        end,
    lists:foreach(Fun, load_task_open_fun:get_main_task_limit_by_taskId(TaskId)).



level_trigger(Level) ->
    FunMap =
        fun(#open_fun_cfg{
            sinks = Sinks,
            limit_level = LimitLevel,
            limit_main_task = TaskId}) ->
            if
                LimitLevel =:= Level ->
                    case attr_new:get_sink_state(Sinks) of
                        ?FALSE ->
                            case check_main_task(TaskId) of
                                ?true ->
                                    attr_new:set_sink_state(Sinks, ?TRUE),
                                    ?true;
                                ?false ->
                                    ?false
                            end;
                        _ ->
                            ?true
                    end;
                true ->
                    ok
            end
        end,
    lists:map(FunMap, lookup_all_tab()).

level_trigger_1(Level) ->
    Fun =
        fun(CfgId) ->
            #open_fun_cfg{sinks = Sinks, limit_level = LimitLevel,
                limit_main_task = TaskId} = load_task_open_fun:lookup_open_fun_cfg(CfgId),
            if
                LimitLevel =:= Level ->
                    case attr_new:get_sink_state(Sinks) of
                        ?FALSE ->
                            case check_main_task(TaskId) of
                                ?true ->
                                    attr_new:set_sink_state(Sinks, ?TRUE),
                                    ?true;
                                ?false ->
                                    ?false
                            end;
                        _ ->
                            ?true
                    end;
                true ->
                    ok
            end
        end,
    lists:foreach(Fun, load_task_open_fun:get_level_limit_by_level(Level)).


%% 判断是否已经开启此功能
is_open(Id) ->
    %?DEBUG_LOG("Id---------------------------:~p",[Id]),
    case load_task_open_fun:lookup_open_fun_cfg(Id) of
        ?none ->
            ?true;
        #open_fun_cfg{limit_level = 1} ->
            ?true;
        #open_fun_cfg{sinks = Sinks, limit_level = LimitLevel, limit_main_task = LimitMainTaskId, limit_chapter = _LimitChapter} ->
            case attr_new:get_sink_state(Sinks) of
                ?FALSE ->
                    case util:can([fun() -> check_level(LimitLevel) end,fun() -> check_main_task(LimitMainTaskId) end]) of
                        ?true ->
                            %?DEBUG_LOG("task_open_fun--------------------------1"),
                            attr_new:set_sink_state(Sinks, ?TRUE),
                            ?true;
                        ?false ->
                            %?DEBUG_LOG("task_open_fun-----------------------------2"),
                            ?false
                    end;
                _ ->
                    ?true
            end
    end.

check_level(0) -> ?true;
check_level(LimitLevel) ->
    Level = get(?pd_level),
    %?DEBUG_LOG("LimitLevel-----:~p----Level-----:~p",[LimitLevel, Level]),
    Level >= LimitLevel.

check_main_task(0) -> ?true;
check_main_task(TaskId) ->
    %load_task_progress:get_task_type(TaskId) =:= ?TT_MAIN.
    % task_mng:is_member(TaskId, ?TT_MAIN).
    task_system:is_open_xitong_of_task(TaskId).


lookup_all_tab() ->
    Ids = load_task_open_fun:lookup_all_open_fun_cfg(#open_fun_cfg.id),
    [load_task_open_fun:lookup_open_fun_cfg(Id) || Id <- Ids].

