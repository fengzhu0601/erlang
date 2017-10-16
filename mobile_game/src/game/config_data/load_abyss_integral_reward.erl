%%%-------------------------------------------------------------------
%%% @author fengzhu
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 17. 六月 2016 下午4:43
%%%-------------------------------------------------------------------
-module(load_abyss_integral_reward).
-author("fengzhu").

%% API
-export([
    get_prize/1
    , test/0
]).

-include_lib("config/include/config.hrl").
-include("inc.hrl").
-include("load_abyss_integral_reward.hrl").
%%-include("load_db_misc.hrl").
-include("rank.hrl").

load_config_meta() ->
    [
        #config_meta
        {
            record = #abyss_integral_reward_cfg{},
            fields = ?record_fields(abyss_integral_reward_cfg),
            file = "abyss_integral_reward.txt",
            keypos = #abyss_integral_reward_cfg.id,
            verify = fun verify/1
        }
    ].



verify(#abyss_integral_reward_cfg{id = Id, rewardId = PrizeId}) ->
    ?check(prize:is_exist_prize_cfg(PrizeId),
        "abyss_integral_reward.txt id:[~p] 奖励id:~p 在配置表 prize.txt 中没有找到", [Id, PrizeId]),
    ok.


get_prize(Rank) -> get_prize(Rank, 1).


test() ->
    Data = ranking_lib:lookup_data_by_name(?ranking_abyss).

get_prize(Rank, N) ->
    case lookup_abyss_integral_reward_cfg(N) of
        #abyss_integral_reward_cfg{min_rank = Min, max_rank = Max, rewardId = Award} ->
            if
                Rank >= Min andalso Rank =< Max ->
                    Award;
                true ->
                    get_prize(Rank, N+1)
            end;
        _ ->
            0
    end.

