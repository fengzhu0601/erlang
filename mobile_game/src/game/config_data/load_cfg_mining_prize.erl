-module(load_cfg_mining_prize).

-include("inc.hrl").
-include_lib("config/include/config.hrl").
-include("load_cfg_mining_prize.hrl").

-export([
	get_prize/1
	]).


load_config_meta() ->
	[
		#config_meta
		{
			record = #mining_prize_cfg{},
			fields = ?record_fields(mining_prize_cfg),
			file = "guild_mining_prize.txt",
			keypos = #mining_prize_cfg.offer_lv,
			verify = fun verify/1
		}
	].

verify(#mining_prize_cfg{offer_lv = OfferLv, prize_id = PrizeId, add_guild_exp = GuildExp, add_offer_exp = OfferExp}) -> 
	?check(?is_pos_integer(OfferLv), "guild_mining_prize.txt  [OfferLv:~w] 无效! ", [OfferLv]),
	?check(is_list(PrizeId), "guild_mining_prize.txt OfferLv:[~w]  [PrizeId :~w] 无效", [OfferLv, PrizeId]),
	lists:foreach(fun({Index, Prize}) ->
       		?check(lists:member(Index, [1,2,3,4]) andalso prize:is_exist_prize_cfg(Prize), "guild_mining_prize.txt中 [Prize:~w] 配置无效。", [Prize])
             end,
        	PrizeId),
	?check(is_list(GuildExp), "guild_mining_prize.txt OfferLv:[~w]  [GuildExp :~w] 无效", [OfferLv, GuildExp]),
	lists:foreach(fun({Index, _}) ->
       		?check(lists:member(Index, [1,2,3,4]), "guild_mining_prize.txt中 [Index:~w] 配置无效。", [Index])
             end,
        	GuildExp),
	?check(is_list(OfferExp), "guild_mining_prize.txt OfferLv:[~w]  [OfferExp :~w] 无效", [OfferLv, OfferExp]),
	lists:foreach(fun({Index, _}) ->
       		?check(lists:member(Index, [1,2,3,4]), "guild_mining_prize.txt中 [Index:~w] 配置无效。", [Index])
             end,
        	OfferExp),
	ok.

%% 通过玩家贡献等级得到奖励列表
get_prize(OfferLv) ->
	case lookup_mining_prize_cfg(OfferLv) of
		#mining_prize_cfg{prize_id = PrizeId,
				add_guild_exp = GuildExp,
				add_offer_exp = OfferExp
		} ->
			[PrizeId, GuildExp, OfferExp];
		_ ->
			error
	end.

