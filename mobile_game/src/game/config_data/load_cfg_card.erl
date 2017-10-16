%%%-------------------------------------------------------------------
%%% @author fengzhu
%%% @copyright (C) 2016, <COMPANY>
%%% @doc 卡牌大师
%%%
%%% @end
%%% Created : 05. 一月 2016 上午11:08
%%%-------------------------------------------------------------------
-module(load_cfg_card).
-author("fengzhu").

%% API
-export([
    is_valid_star/1
    ,get_item_card_attr_cfg_class/1
    ,get_all_card_id/0
    , get_activation_num_by_id/1
    , get_activation_buffs_by_id/1
]).

-include_lib("config/include/config.hrl").
-include("inc.hrl").
-include("load_cfg_card.hrl").
-include("item.hrl").
-include("load_item.hrl").
%%-include("player.hrl").


load_config_meta() ->
    [
        #config_meta{record = #card_cfg{},
            fields = ?record_fields(card_cfg),
            file = "card_group.txt",
            keypos = #card_cfg.group,
            verify = fun verify/1},

        #config_meta{record = #item_card_attr_cfg{},
            fields = ?record_fields(item_card_attr_cfg),
            file = "card.txt",
            keypos = #item_card_attr_cfg.id,
            all = [#item_card_attr_cfg.id],
            verify = fun verify_card/1
        }
    ].

verify(#card_cfg{group = Id, quality = Qua, prize_id = PrizeId}) ->
    lists:foreach(
        fun
            ({ItemBid, ItemCount}) ->
                ?check(load_item:get_type(ItemBid) =:= ?ITEM_TYPE_CARD, "card.txt [~w] 物品[~w] 类型错误", [Id, ItemBid]),
                ?check(com_util:is_valid_uint16(ItemCount), "card.txt [~w] 的物品[~w]数量错误count ~w", [Id, ItemBid, ItemCount]),
                ?check(prize:is_exist_prize_cfg(PrizeId), "card.txt [~w] 对应的奖励id ~w 不存在", [Id, PrizeId])
        end,
        Id
    ),
    ?check(is_valid_star(Qua), "card.txt [~w] 对应的品质错误 ~w", [Id, Qua]),
    ok.

verify_card(#item_card_attr_cfg{id = Id, time = Time}) ->
    ok.

is_valid_star(Star) ->
    lists:member(Star, ?CARD_STAR_ALL).

get_item_card_attr_cfg_class(Bid) ->
    case lookup_item_card_attr_cfg(Bid) of
        #item_card_attr_cfg{card_class = Class} ->
            Class;
        _ -> 0
    end.

get_all_card_id() ->
    lookup_all_item_card_attr_cfg(#item_card_attr_cfg.id).

get_activation_num_by_id(Bid) ->
    case lookup_item_card_attr_cfg(Bid) of
        #item_card_attr_cfg{activation_num = ActivationNum} ->
            ActivationNum;
        _ -> 0
    end.

get_activation_buffs_by_id(Bid) ->
    case lookup_item_card_attr_cfg(Bid) of
        #item_card_attr_cfg{activation_buffs = ActivationBuffs} ->
            ActivationBuffs;
        _ -> 0
    end.
