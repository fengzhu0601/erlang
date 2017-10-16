-module(load_richang_task).

%% API
-export([
    get_daily_task_id_list_by_player_level/0,
    get_daily_baoxiang_prize/0,
    flush_baoxiang/0,
    update_daily_baoxiang_prize/0
]).


-include("inc.hrl").
-include("player.hrl").

-include("load_task_progress.hrl").
-include_lib("config/include/config.hrl").
-include("load_richang_task.hrl").

%% {正在做的宝箱，今天是否还能计数1yes,0no，宝箱数据}
get_daily_baoxiang_prize() ->
    L = misc_cfg:get_task_daily_baoxiang(),
    {1, 1, L}.

update_daily_baoxiang_prize() ->
    L = misc_cfg:get_task_daily_baoxiang(),
    {1, 0, L}.

flush_baoxiang() ->
    put(?pd_daily_task_prize_list, get_daily_baoxiang_prize()).


get_daily_task_size(IdList) ->
    Size = length(IdList),
    if
        Size >= 3 ->
            3;
        true ->
            Size
    end.


get_daily_task_id_list_by_player_level() ->
    DailyTaskLevel = misc_cfg:get_task_daily_openlevel(),
    Level = get(?pd_level),
    if
        Level >= DailyTaskLevel -> 
            IdList = 
            lists:foldl(fun({_Key, Cbp}, Acc) ->
                Id = Cbp#richang_task_cfg.id,
                {MinLv, MaxLv} = Cbp#richang_task_cfg.lv,
                Weight = Cbp#richang_task_cfg.weight,
                if
                    Level >= MinLv, Level =< MaxLv ->
                        [{Id, Weight}|Acc];
                    true ->
                        Acc
                end
            end,
            [],
            ets:tab2list(richang_task_cfg)),
            %?DEBUG_LOG("IdList-------------------:~p",[IdList]),
            NewIdList = util:get_val_by_weight(IdList, get_daily_task_size(IdList)),
            %?DEBUG_LOG("NewIdList-------------------:~p",[NewIdList]),
            lists:foldl(fun(Id, L) ->
                #richang_task_cfg{task=TaskId, stars=Stars, award=AwardList} = lookup_richang_task_cfg(Id),
                StarList = util:get_val_by_weight(Stars, 1),
                Star = lists:nth(1, StarList),
                {_, PrizeId} = lists:keyfind(Star, 1, AwardList),
                [{TaskId, Star, 0, PrizeId}|L]
            end,
            [],
            NewIdList);
        true ->
            []
    end.




load_config_meta() ->
    [
        #config_meta{
            record = #richang_task_cfg{},
            fields = ?record_fields(richang_task_cfg),
            file = "richang_task.txt",
            keypos = #richang_task_cfg.id,
            verify = fun verify/1}
    ].



verify(#richang_task_cfg{id = Id, task = TaskId, award=AwardList}) ->
    ?check(TaskId =:= 0 orelse load_task_progress:is_exist_task_new_cfg(TaskId), "richang_task.txt中， [~p] per: ~p 配置无效。", [Id, TaskId]),

    lists:foreach(fun({_, Prize}) ->
        ?check(Prize =:= 0 orelse prize:is_exist_prize_cfg(Prize), "richang_task.txt中， [~p] prize: ~p 配置无效。", [Id, Prize])
    end,
    AwardList),
    ok.

