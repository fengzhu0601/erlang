-module(load_nine_lottery_cfg).

-export([
	get_day_prize_info_without_one/2,
	get_grid_prize_list/1
]).

-include("inc.hrl").
-include_lib("config/include/config.hrl").
-include("load_nine_lottery_cfg.hrl").

load_config_meta() ->
	[
        #config_meta{
            record = #nine_lottery_per_day_prize_cfg{},
            fields = ?record_fields(nine_lottery_per_day_prize_cfg),
            file = "nine_lottery_per_day_prize.txt",
            keypos = #nine_lottery_per_day_prize_cfg.id,
            verify = fun verify_1/1
        },

        #config_meta{
            record = #nine_lottery_prize_cfg{},
            fields = ?record_fields(nine_lottery_prize_cfg),
            file = "nine_lottery_prize.txt",
            keypos = #nine_lottery_prize_cfg.id,
            verify = fun verify_2/1
        }
	].

verify_1(#nine_lottery_per_day_prize_cfg{}) -> ok.
verify_2(#nine_lottery_prize_cfg{}) -> ok.

get_day_prize_info_without_one(Day, Id) ->
	case lookup_nine_lottery_per_day_prize_cfg(Day) of
		#nine_lottery_per_day_prize_cfg{
			nine_lottery_prize_list = List
		} ->
			NewList = lists:keydelete(Id, 1, List),
			{NineLotteryPrizeId, Pro} = lists:nth(random:uniform(length(NewList)), NewList),
			{NineLotteryPrizeId, random:uniform(1000) =< Pro};
		_ ->
			error
	end.

% get_grid_prize_list(Day, NineLotteryPrizeId) ->
% 	get_grid_prize_list(1, Day, NineLotteryPrizeId, 0).

% get_grid_prize_list(Max, Max, NineLotteryPrizeId, Count) ->
% 	BeginId = (Count + NineLotteryPrizeId - 1) * 9 + 1,
% 	?DEBUG_LOG("BeginId:~p", [BeginId]),
% 	get_prize_list(BeginId, []);
% get_grid_prize_list(Min, Max, NineLotteryPrizeId, Count) ->
% 	NewCount = case lookup_nine_lottery_per_day_prize_cfg(Min) of
% 		#nine_lottery_per_day_prize_cfg{
% 			nine_lottery_prize_list = List
% 		} ->
% 			?DEBUG_LOG("List:~p, NineLotteryPrizeId:~p", [List, NineLotteryPrizeId]),
% 			length(List) + Count;
% 		_ ->
% 			Count
% 	end,
% 	get_grid_prize_list(Min + 1, Max, NineLotteryPrizeId, NewCount).

get_grid_prize_list(NineLotteryPrizeId) ->
	BeginId = (NineLotteryPrizeId - 1) * 9 + 1,
	get_prize_list(BeginId, []).

get_prize_list(Id, List) ->
	case length(List) >= 9 of
		true ->
			List;
		_ ->
			NewList = case lookup_nine_lottery_prize_cfg(Id) of
				#nine_lottery_prize_cfg{
					grid_index = GridIndex,
					prize = PrizeId,
					prize_num = PrizeNum,
					weight = Weight
				} ->
					[{GridIndex, PrizeId, PrizeNum, Weight} | List];
				_ ->
					List
			end,
			get_prize_list(Id + 1, NewList)
	end.
