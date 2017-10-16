%%%-------------------------------------------------------------------
%%% @author zlb
%%% @doc 卡牌大师
%%%
%%% @end
%%%-------------------------------------------------------------------

-module(card).

%%-include_lib("config/include/config.hrl").

%%%% API
%%-export([
%%    is_valid_star/1
%%]
%%).
%%
%%-include("inc.hrl").
%%-include("player.hrl").
%%-include("card.hrl").
%%-include("item.hrl").

%%is_valid_star(Star) ->
%%    lists:member(Star, ?CARD_STAR_ALL).
%%
%%load_config_meta() ->
%%    [
%%        #config_meta{record = #card_cfg{},
%%            fields = ?record_fields(card_cfg),
%%            file = "card_group.txt",
%%            keypos = #card_cfg.group,
%%            verify = fun verify/1}
%%    ].
%%
%%verify(#card_cfg{group = Id, quality = Qua, prize_id = PrizeId}) ->
%%    lists:foreach(fun({ItemBid, ItemCount}) ->
%%        ?check(load_item:get_type(ItemBid) =:= ?ITEM_TYPE_CARD, "card.txt [~w] 物品[~w] 类型错误", [Id, ItemBid]),
%%        ?check(com_util:is_valid_uint16(ItemCount), "card.txt [~w] 的物品[~w]数量错误count ~w", [Id, ItemBid, ItemCount]),
%%        ?check(prize:is_exist_prize_cfg(PrizeId), "card.txt [~w] 对应的奖励id ~w 不存在", [Id, PrizeId])
%%    end, Id),
%%    ?check(is_valid_star(Qua), "card.txt [~w] 对应的品质错误 ~w", [Id, Qua]),
%%    ok.
