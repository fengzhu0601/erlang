-module(load_cfg_time_trigger).

%% API
-export([
    get_interval_time_by_id/1
]).



-include("inc.hrl").
-include("player.hrl").
-include_lib("config/include/config.hrl").
-include("load_cfg_time_trigger.hrl").



get_interval_time_by_id(Id) ->
    case lookup_time_trigger_cfg(Id) of
        ?none ->
            ?none;
        #time_trigger_cfg{time=Time} ->
            {_, NowTime} = calendar:now_to_local_time(os:timestamp()),
            calendar:time_to_seconds(Time) - calendar:time_to_seconds(NowTime)
    end.



load_config_meta() ->
    [
        #config_meta{record = #time_trigger_cfg{},
          fields = record_info(fields, time_trigger_cfg),
          file = "time_trigger.txt",
          keypos = #time_trigger_cfg.id,
          verify = fun verify/1}
    ].



verify(#time_trigger_cfg{id = Id, time = Time, week=Week, command = Command, is_end = End}) ->
    ?check(erlang:is_integer(Id), "time_trigger_cfg.txt 用户ｉｄ　＝　[~p] 非法! ",[Id]),
    if
        is_integer(Week) ->
            ?check(Week >= 0 andalso Week =< 7, "time_trigger_cfg.txt id　＝　[~p] 非法! week:[~p] ",[Id, Week]);
        is_list(Week) ->
            lists:foreach(fun(D) ->
              ?check(D >= 0 andalso D =< 7, "time_trigger_cfg.txt id　＝　[~p] 非法! week:[~p] ",[Id, D])
            end,
            Week);
        true ->
            pass
    end,
    ?check(erlang:is_integer(End) orelse End =:=?undefined, "time_trigger_cfg.txt is_end　＝　[~p] 非法! is_end:[~p] ",[Id, End]),
    case Time of
        {Hours, Minutes, Seconds} ->
            if
                Hours>=24 orelse Hours<0 orelse Minutes>60 orelse Minutes<0 orelse Seconds<0 ->
                    ?check(?false, "time_trigger_cfg time　　[~p] 非法! ",[Time]);
                true ->
                    pass
            end;
        _ ->
            ?check(?false, "time_trigger_cfg!~p~n", [Time])
    end,
    case Command of
        [C] ->
            ?check(C > 0, "time_trigger_cfg的command必须 > 0! ~p", [C]);
        _ ->
            pass
    end,
    ok;
verify(_R) ->
    exit(bad).
