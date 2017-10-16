-module(load_cfg_main_star_shop).

%% API
-export([
    get_main_star_shop_id_list_by_player_level/0
]).

-include_lib("config/include/config.hrl").
-include("inc.hrl").
-include("player.hrl").

-include("load_cfg_main_star_shop.hrl").


get_main_star_shop_id_list_by_player_level() ->
    Level = get(?pd_level),
    IdList = 
    lists:foldl(fun({_Key, Cbp}, Acc) ->
        Id = Cbp#main_ins_star_shop_cfg.id,
        Lv = Cbp#main_ins_star_shop_cfg.level,
        Weight = Cbp#main_ins_star_shop_cfg.weight,
        if
            Level =< Lv ->
                [{Id, Weight}|Acc];
            true ->
                Acc
        end
    end,
    [],
    ets:tab2list(main_ins_star_shop_cfg)),
    NewIdList = util:get_val_by_weight(IdList, 6),
    lists:foldl(fun(Id, L) ->
        [{Id, 1}|L]
    end,
    [],
    NewIdList).



load_config_meta() ->
    [
        #config_meta{record = #main_ins_star_shop_cfg{},
            fields = ?record_fields(main_ins_star_shop_cfg),
            file = "main_ins_star_shop.txt",
            keypos = #main_ins_star_shop_cfg.id,
            verify = fun verify_main_ins_shop/1}
    ].

verify_main_ins_shop(#main_ins_star_shop_cfg{id = Id, level=Level, item = {GoodId, Count}, price = Price, weight=Ratio, choose_num=Cn}) ->
    ?check(com_util:is_valid_uint64(Id), "main_ins_star_shop_cfg.txt id [~w] 无效! ", [Id]),
    ?check((load_item:is_exist_item_attr_cfg(GoodId) andalso Count > 0), "main_ins_star_shop_cfg.txt id [~w] item [~w] 物品不存在! ", [Id, GoodId]),
    ?check((Level > 0 andalso Level =< 100), "main_ins_star_shop_cfg.txt id [~w] level [~w] 无效! ", [Id, Level]),
    %?check((Type == 14 orelse Type == 13), "main_ins_star_shop_cfg.txt id [~w] type [~w] 无效! ", [Id, Type]),
    ?check(Price > 0, "main_ins_star_shop_cfg.txt  id [~w]  num [~w] 无效  ", [Id, Price]),
    ?check(Ratio > 0, "main_ins_star_shop_cfg.txt  id [~w]  ratio [~w] 无效  ", [Id, Ratio]),
    ?check(Cn > 0, "main_ins_star_shop_cfg.txt  id [~w]  choose_num [~w] 无效  ", [Id, Cn]),
    ok.
