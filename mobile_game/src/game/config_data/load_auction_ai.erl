-module(load_auction_ai).

-include("inc.hrl").
-include_lib("config/include/config.hrl").
-include("load_auction_ai.hrl").

%% API
-export([
    get_auction_ai_data_by_size/1
]).



get_auction_ai_data_by_size(Size) ->
    do_get_auction_ai_data_by_size(Size, []).
do_get_auction_ai_data_by_size(0, List) ->
    ?DEBUG_LOG("List---------------------:~p",[List]),
    List;
do_get_auction_ai_data_by_size(Size, List) ->
    Id = random:uniform(com_ets:table_size(auction_ai_cfg)),
    do_get_auction_ai_data_by_size(Size - 1, [lookup_auction_ai_cfg(Id)|List]).


load_config_meta() ->
    [
        #config_meta{record = #auction_ai_cfg{},
            fields = ?record_fields(auction_ai_cfg),
            file = "auction_ai.txt",   
            keypos = #auction_ai_cfg.id,
            verify = fun verify/1}
    ].



verify(#auction_ai_cfg{id = Id, lv={Min,Max} =L, time=Time, item_id=ItemId, auction_price=AuctionPrice, butyot_price=Bp, player_name=Name}) ->
    ?check(load_item:is_exist_item_attr_cfg(ItemId), "auction_ai_cfg Id [~w] item_id [~w] 没有找到", [Id, ItemId]),
    ?check(Min >= 1 andalso Max =< 100,  "auction_ai_cfg id [~w] lv [~w] 无效" ,[Id, L]),
    ?check(AuctionPrice >= 1,  "auction_ai_cfg id [~w] auction_price [~w] 无效" ,[Id, AuctionPrice]),
    ?check(Bp >= 1,  "auction_ai_cfg id [~w] butyot_price [~w] 无效" ,[Id, Bp]),
    ok;

verify(_R) ->
    ?ERROR_LOG("auction_ai_cfg ~p 无效格式", [_R]),
    exit(bad).



