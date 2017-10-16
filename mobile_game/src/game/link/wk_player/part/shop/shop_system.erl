%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 07. 八月 2015 下午5:51
%%%-------------------------------------------------------------------
-module(shop_system).
-author("clark").

%% API
-export([sell/2]).


-include("inc.hrl").
-include("bucket_interface.hrl").
-include("item_bucket.hrl").
-include("equip.hrl").
-include("load_spirit_attr.hrl").
-include("system_log.hrl").


%% @doc 出售物品
sell(ItemId, Count) when Count > 0 ->
    game_res:set_res_reasion(<<"出售">>),
    BagBucket = game_res:get_bucket(?BUCKET_TYPE_BAG),
    case goods_bucket:find_goods(BagBucket, by_id, {ItemId}) of
        {error, Error} -> {error, Error};
        Goods ->
            Bid = item_new:get_bid(Goods),
            case load_item:can_sell(Bid) of
                ok ->
                    Type = item_new:get_type(Goods),            %% 判断该物品类型是否是装备类型
                    case lists:member(Type, ?all_equips_type) of
                        true ->
                            IsJd = item_new:get_field(Goods, ?item_equip_is_jd),
                            case IsJd =:= 1 of                    %% 判断装备是否已经鉴定
                                true ->
                                    JCAttr = item_new:get_field(Goods, ?item_equip_base_prop),
                                    QHLevel = item_new:get_field(Goods, ?item_equip_qianghua_lev),
                                    QHAttr = load_equip_expand:get_qiang_hua_attr(Bid, QHLevel),
                                    JDAttr = item_new:get_field(Goods, ?item_equip_extra_prop_list),
                                    GemMes = item_new:get_field(Goods, ?item_equip_igem_slot),
                                    SSGMesBid = item_new:get_item_new_field_value_by_key(Goods, ?item_use_data, ?item_equip_epic_gem, 0),
%%                                    ?INFO_LOG("SSGesBid = ~p", [SSGMesBid]),
                                    SSPower = get_ssgem_combat(SSGMesBid),
%%                                    ?INFO_LOG("SSPower = ~p", [SSPower]),
%%                                    io:format("QHAttr = ~p~n", [QHAttr]),
                                    TotalPrice = get_combat_power(JCAttr)*10 + get_combat_power(QHAttr)*100 + get_jd_combat_power(JDAttr)/100
                                        + (get_gem_combat(GemMes)+SSPower)*100,
%%                                    ?INFO_LOG("JC combat = ~p", [get_combat_power(JCAttr)]),
%%                                    ?INFO_LOG("QhLevel = ~p", [QHLevel]),
%%                                    ?INFO_LOG("JD combat = ~p", [get_jd_combat_power(JDAttr)]),
%%                                    ?INFO_LOG("gem_combat = ~p", [get_gem_combat(GemMes)]),
%%                                    ?INFO_LOG("TotalPrice = ~p", [TotalPrice]),
%%                                    io:format("JCAttr = ~p~n", [JCAttr]),
%%                                    io:format("JDAttr = ~p~n", [JDAttr]),
%%                                    io:format("GemMes = ~p~n", [GemMes]),
                                    game_res:del([{by_id, {ItemId, Count}}], ?FLOW_REASON_SHOP_SELL),
                                    SumPrice =  com_util:floor(TotalPrice), %% 计算出价格以后向下取整
                                    game_res:give([{?MONEY_BID, SumPrice}], ?FLOW_REASON_SHOP_SELL),
                                    shop_mng:add_back_item({Goods#item_new{quantity = Count}, SumPrice}),
                                    ok;
                                _ ->
                                    %% 获取该装备的使用等级
                                    UseLvl = load_equip_expand:get_equip_cfg_level(Bid),
                                    game_res:del([{by_id, {ItemId, Count}}], ?FLOW_REASON_SHOP_SELL),
                                    SumPrice = UseLvl * 50,
                                    game_res:give([{?MONEY_BID, SumPrice}], ?FLOW_REASON_SHOP_SELL),
                                    shop_mng:add_back_item({Goods#item_new{quantity = Count}, SumPrice}),
                                    ok
                            end;
                        _ ->
                            game_res:del([{by_id, {ItemId, Count}}], ?FLOW_REASON_SHOP_SELL),
                            Price = load_item:get_price(Bid),
                            SumPrice = Price * Count,
                            game_res:give([{?MONEY_BID, SumPrice}], ?FLOW_REASON_SHOP_SELL),
                            shop_mng:add_back_item({Goods#item_new{quantity = Count}, SumPrice}),
                            ok
                    end;
%%                shop_mng:add_back_item({Item#item{quantity = Count}, SumPrice});
                _ ->
                    {error, cant_sell}
            end
    end.




%% private -------------------------------------------------------------------
get_jd_combat_power(JDAttr) ->
    case lists:keyfind(?EQM_ATTR_JD, 1, JDAttr) of
        {_, AttrList} when is_list(AttrList) ->
            AttrList1 = [{AttrId, AttrVal} || {AttrId, AttrVal, _P} <- AttrList],
            Attr = attr_new:list_2_attr(AttrList1),
            attr_new:get_combat_power(Attr);
        _ ->
            ?ERROR_LOG("not find jd attr list"),
            0
    end.

get_gem_combat(GemMes) when is_tuple(GemMes) ->
    GemList = tuple_to_list(GemMes),
    Combat =
        lists:foldl
        (
            fun(GemBid, Acc) ->
                case GemBid =:= 0 of
                    false ->
                        AttrId = load_cfg_gem:get_gem_cfg_attr(GemBid),
                        OAttr = load_spirit_attr:get_attr(AttrId),
                        Attr = attr_new:get_oldversion_equip_attr(OAttr),
                        Power = attr_new:get_combat_power(Attr),
                        Power + Acc;
                    _ ->
                        Acc
                end
            end,
            0,
            GemList
        ),
    Combat;
get_gem_combat(_) -> 0.

get_ssgem_combat(0) -> 0;
get_ssgem_combat(GemBid) ->
    AttrId = load_cfg_gem:get_gem_cfg_attr(GemBid),
%%    ?INFO_LOG("AttrId = ~p =========================", [AttrId]),
    OAttr = load_spirit_attr:get_attr(AttrId),
    Attr = attr_new:get_oldversion_equip_attr(OAttr),
%%    io:format("Attr = ~p~n", [Attr]),
    Power = attr_new:get_combat_power(Attr),
%%    ?INFO_LOG("Power = ~p", [Power]),
    Power.


get_combat_power(OAttr) ->
%%    Old_Attr = get_cur_equip_attr(Item),
    Attr = attr_new:get_oldversion_equip_attr(OAttr),
    Power = attr_new:get_combat_power(Attr),
    Power.
%%round(Blo * 3 + Pre * 3 + Crit * 1.5 + Pli * 1.5 + Atk + Def * 2 + AtkS * 5 + Hp).


