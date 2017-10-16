%%%-------------------------------------------------------------------
%%% @author fengzhu
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 23. 九月 2016 下午12:34
%%%-------------------------------------------------------------------
-module(load_cfg_impact_ranking_list).
-author("fengzhu").

%% API
-export([
	get_prize/2,
	get_rank_shop_prize_and_cost_by_id/1,
	get_title/2,
	get_ranking_list_prize_cfg_by_rankId/2
]).

-include_lib("config/include/config.hrl").
-include("inc.hrl").
-include("load_cfg_impact_ranking_list.hrl").
-include("rank.hrl").

load_config_meta() ->
	[
		#config_meta
		{
			record = #power_ranking_list_prize_cfg{},
			fields = ?record_fields(power_ranking_list_prize_cfg),
			file = "zhanli_rank.txt",
			keypos = #power_ranking_list_prize_cfg.id,
			verify = fun verify_power_ranking_list_prize_cfg/1
		},

		#config_meta
		{
			record = #pet_ranking_list_prize_cfg{},
			fields = ?record_fields(pet_ranking_list_prize_cfg),
			file = "pet_rank.txt",
			keypos = #pet_ranking_list_prize_cfg.id,
			verify = fun verify_pet_ranking_list_prize_cfg/1
		},

		#config_meta
		{
			record = #ride_ranking_list_prize_cfg{},
			fields = ?record_fields(ride_ranking_list_prize_cfg),
			file = "zuoqi_rank.txt",
			keypos = #ride_ranking_list_prize_cfg.id,
			verify = fun verify_ride_ranking_list_prize_cfg/1
		},

		#config_meta
		{
			record = #suit_ranking_list_prize_cfg{},
			fields = ?record_fields(suit_ranking_list_prize_cfg),
			file = "equip_rank.txt",
			keypos = #suit_ranking_list_prize_cfg.id,
			verify = fun verify_suit_ranking_list_prize_cfg/1
		},

		#config_meta
		{
			record = #abyss_ranking_list_prize_cfg{},
			fields = ?record_fields(abyss_ranking_list_prize_cfg),
			file = "xukongsy_rank.txt",
			keypos = #abyss_ranking_list_prize_cfg.id,
			verify = fun verify_abyss_ranking_list_prize_cfg/1
		},

		#config_meta
		{
			record = #guild_ranking_list_prize_cfg{},
			fields = ?record_fields(guild_ranking_list_prize_cfg),
			file = "guild_rank.txt",
			keypos = #guild_ranking_list_prize_cfg.id,
			verify = fun verify_guild_ranking_list_prize_cfg/1
		},

		#config_meta
		{
			record = #rank_shop_cfg{},
			fields = ?record_fields(rank_shop_cfg),
			file = "rank_shop.txt",
			keypos = #rank_shop_cfg.id,
			verify = fun verify_rank_shop_cfg/1
		}
	].


verify_power_ranking_list_prize_cfg(#power_ranking_list_prize_cfg{id = Id, prize = PrizeId, title = Title}) ->
	?check(prize:is_exist_prize_cfg(PrizeId),
		"zhanli_rank.txt id:[~p] 奖励id:~p 在配置表 prize.txt 中没有找到", [Id, PrizeId]),
	?check(load_cfg_title:is_exist_title_cfg(Title),
		"zhanli_rank.txt id:[~p] 称号id:~p 在配置表 title.txt 中没有找到", [Id, Title]),
	ok.

verify_pet_ranking_list_prize_cfg(#pet_ranking_list_prize_cfg{id = Id, prize = PrizeId, title = Title}) ->
	?check(prize:is_exist_prize_cfg(PrizeId),
		"pet_rank.txt id:[~p] 奖励id:~p 在配置表 prize.txt 中没有找到", [Id, PrizeId]),
	?check(load_cfg_title:is_exist_title_cfg(Title),
		"pet_rank.txt id:[~p] 称号id:~p 在配置表 title.txt 中没有找到", [Id, Title]),
	ok.

verify_ride_ranking_list_prize_cfg(#ride_ranking_list_prize_cfg{id = Id, prize = PrizeId, title = Title}) ->
	?check(prize:is_exist_prize_cfg(PrizeId),
		"zuoqi_rank.txt id:[~p] 奖励id:~p 在配置表 prize.txt 中没有找到", [Id, PrizeId]),
	?check(load_cfg_title:is_exist_title_cfg(Title),
		"zuoqi_rank.txt id:[~p] 称号id:~p 在配置表 title.txt 中没有找到", [Id, Title]),
	ok.

verify_suit_ranking_list_prize_cfg(#suit_ranking_list_prize_cfg{id = Id, prize = PrizeId, title = Title}) ->
	?check(prize:is_exist_prize_cfg(PrizeId),
		"equip_rank.txt id:[~p] 奖励id:~p 在配置表 prize.txt 中没有找到", [Id, PrizeId]),
	?check(load_cfg_title:is_exist_title_cfg(Title),
		"equip_rank.txt id:[~p] 称号id:~p 在配置表 title.txt 中没有找到", [Id, Title]),
	ok.

verify_abyss_ranking_list_prize_cfg(#abyss_ranking_list_prize_cfg{id = Id, prize = PrizeId, title = Title}) ->
	?check(prize:is_exist_prize_cfg(PrizeId),
		"xukongsy_rank.txt id:[~p] 奖励id:~p 在配置表 prize.txt 中没有找到", [Id, PrizeId]),
	?check(load_cfg_title:is_exist_title_cfg(Title),
		"xukongsy_rank.txt id:[~p] 称号id:~p 在配置表 title.txt 中没有找到", [Id, Title]),
	ok.

verify_guild_ranking_list_prize_cfg(#guild_ranking_list_prize_cfg{id = Id, prize_1 = PrizeId1, prize_2 = PrizeId2, prize_3 = PrizeId3, title = Title}) ->
	?check(prize:is_exist_prize_cfg(PrizeId1),
		"guild_rank.txt id:[~p] 奖励id:~p 在配置表 prize.txt 中没有找到", [Id, PrizeId1]),
	?check(prize:is_exist_prize_cfg(PrizeId2),
		"guild_rank.txt id:[~p] 奖励id:~p 在配置表 prize.txt 中没有找到", [Id, PrizeId2]),
	?check(prize:is_exist_prize_cfg(PrizeId3),
		"guild_rank.txt id:[~p] 奖励id:~p 在配置表 prize.txt 中没有找到", [Id, PrizeId3]),
	?check(load_cfg_title:is_exist_title_cfg(Title),
		"guild_rank.txt id:[~p] 称号id:~p 在配置表 title.txt 中没有找到", [Id, Title]),
	ok.
verify_rank_shop_cfg(#rank_shop_cfg{}) ->
	ok.

%% 公会的单独处理
%% @排行榜Id, 排名
get_prize(?ranking_guild, Rank) ->
	get_prize(?ranking_guild, Rank, 1);
get_prize(RankName, Rank) -> get_prize(RankName, Rank, 1).

get_prize(?ranking_guild, Rank, N) ->
	case lookup_guild_ranking_list_prize_cfg(N) of
        #guild_ranking_list_prize_cfg{min_rank = Min, max_rank = Max, prize_1 = PrizeId1, prize_2 = PrizeId2, prize_3 = PrizeId3, server_prize = ServerPrize} ->
            if
                Rank >= Min andalso Rank =< Max ->
					{PrizeId1, PrizeId2, PrizeId3, ServerPrize};
                true ->
                    get_prize(?ranking_guild, Rank, N+1)
            end;
        _ ->
			{0,0,0, 0}
    end;
get_prize(RankName, Rank, N) ->
	{RankMin, RankMax, NewPrizeId} =
		case get_ranking_list_prize_cfg_by_rankId(RankName, N) of
			#power_ranking_list_prize_cfg{min_rank = Min, max_rank = Max, prize = PrizeId} ->
				{Min, Max, PrizeId};
			#pet_ranking_list_prize_cfg{min_rank = Min, max_rank = Max, prize = PrizeId} ->
				{Min, Max, PrizeId};
			#ride_ranking_list_prize_cfg{min_rank = Min, max_rank = Max, prize = PrizeId} ->
				{Min, Max, PrizeId};
			#suit_ranking_list_prize_cfg{min_rank = Min, max_rank = Max, prize = PrizeId} ->
				{Min, Max, PrizeId};
			#abyss_ranking_list_prize_cfg{min_rank = Min, max_rank = Max, prize = PrizeId} ->
				{Min, Max, PrizeId};
			_ ->
				{0, 0, 0}
		end,
	if
		Rank >= RankMin andalso Rank =< RankMax ->
			NewPrizeId;
		true ->
			get_prize(RankName, Rank, N+1)
	end.

get_title(RankName, Rank) -> get_title(RankName, Rank, 1).
get_title(RankName, Rank, N) ->
	{RankMin, RankMax, TitleId} =
		case get_ranking_list_prize_cfg_by_rankId(RankName, N) of
			#power_ranking_list_prize_cfg{min_rank = Min, max_rank = Max, title = Title} ->
				{Min, Max, Title};
			#pet_ranking_list_prize_cfg{min_rank = Min, max_rank = Max, title = Title} ->
				{Min, Max, Title};
			#ride_ranking_list_prize_cfg{min_rank = Min, max_rank = Max, title = Title} ->
				{Min, Max, Title};
			#suit_ranking_list_prize_cfg{min_rank = Min, max_rank = Max, title = Title} ->
				{Min, Max, Title};
			#abyss_ranking_list_prize_cfg{min_rank = Min, max_rank = Max, title = Title} ->
				{Min, Max, Title};
			#guild_ranking_list_prize_cfg{min_rank = Min, max_rank = Max, title = Title} ->
				{Min, Max, Title};
			_ ->
				{0, 0, 0}
		end,
	if
		Rank >= RankMin andalso Rank =< RankMax ->
			TitleId;
		true ->
			get_title(RankName, Rank, N+1)
	end.

get_ranking_list_prize_cfg_by_rankId(RankName, N) ->
	case RankName of
		?ranking_zhanli ->
			lookup_power_ranking_list_prize_cfg(N);
		?ranking_pet ->
			lookup_pet_ranking_list_prize_cfg(N);
		?ranking_ride ->
			lookup_ride_ranking_list_prize_cfg(N);
		?ranking_suit_new ->
			lookup_suit_ranking_list_prize_cfg(N);
		?ranking_abyss ->
			lookup_abyss_ranking_list_prize_cfg(N);
		?ranking_guild ->
			lookup_guild_ranking_list_prize_cfg(N);
		_ ->
			0
	end.

get_rank_shop_prize_and_cost_by_id(Id) ->
	case lookup_rank_shop_cfg(Id) of
		#rank_shop_cfg{ prize = Prize, cost = Cost } ->
			{ Prize, Cost };
		_ ->
			{error, unknown_type}
	end.


