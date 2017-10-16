-module(load_phase_ac).

%% API
-export([
    get_phase_achievement_cfg/1,
    get_phase_achievement_prize/1
]).



-include("inc.hrl").
-include_lib("config/include/config.hrl").
-include("load_phase_ac.hrl").


get_phase_achievement_cfg(Id) ->
    case lookup_phase_achievement_cfg(Id) of
        ?none ->
            ?false;
        #phase_achievement_cfg{goal_list=List} ->
            List
    end.
get_phase_achievement_prize(Id) ->
    case lookup_phase_achievement_cfg(Id) of
        ?none ->
            ?false;
        #phase_achievement_cfg{prize=PrizeList} ->
            {_, PrizeId} = lists:nth(1, PrizeList),
            PrizeId
    end.

load_config_meta() ->
    [
        #config_meta{
            record = #phase_achievement_cfg{},
            fields = ?record_fields(phase_achievement_cfg),
            file = "phase_achievement.txt",
            keypos = #phase_achievement_cfg.id,
            verify = fun verify_phase_ac/1}
    ].


verify_phase_ac(
    #phase_achievement_cfg{
        id = Id,                                 
        goal_list = GT,
        prize = PrizeList}) ->
    ?check(Id > 0, "phase_achievement.txt [~p] id  无效!", [Id]),
    lists:foreach(fun({_, Prize}) ->
        ?check(Prize =:= 0 orelse prize:is_exist_prize_cfg(Prize), "phase_achievement.txt中, [~p] prize: ~p 配置无效。", [Id, Prize])
    end,
    PrizeList),
    lists:foreach(fun({GoalType,_,Count}) ->
        if
            GoalType =:= ?PHASE_AC_INSTANCE_CHAPER_1;
            GoalType =:= ?PHASE_AC_INSTANCE_CHAPER_2;
            GoalType =:= ?PHASE_AC_INSTANCE_CHAPER_3 ->
                ?check(Count > 0, "phase_achievement.txt中, [~p] Count: ~p 配置无效。", [Id, Count]);
            true ->
                pass
        end
    end,
    GT),
    ok.

