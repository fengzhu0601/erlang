%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 31. 七月 2015 上午11:56
%%%-------------------------------------------------------------------
-module(load_item).
-author("clark").

%% API
-export(
[
    get_main_type/1,
    get_type/1,
    is_exist_item_cfg/1,
    get_item_cfg/1,
    get_use_lev/1,
    get_item_quality/1,
    get_price/1,
    can_sell/1,
    can_qh/1,
    check_normal_item/1,
    can_overlap/1,
    get_is_bind/1,
    get_overlap/1,
    get_petid_on_item_use_effect/1,
    get_pet_exp_on_item_use_effect/1,
    get_random_gem/2,
    check_gem_overlap/3,
    get_is_use_type/1
]).


-include("inc.hrl").
-include_lib("config/include/config.hrl").
-include("load_dial_prize.hrl").
-include("load_item.hrl").
-include("item.hrl").
-include("item_new.hrl").



load_config_meta() ->
    [
        #config_meta{record = #item_attr_cfg{},
            fields = ?record_fields(item_attr_cfg),
            file = "generated_item_all.txt",   %% TODO:这里的文件是预处理生成的，使用item.txt和equip.txt拼接而成(处理的脚本为config_pp
            keypos = #item_attr_cfg.bid,
            groups = [#item_attr_cfg.type],
            rewrite = fun change/1,
            verify = fun verify/1}
    ].


change(_) ->
    NewCfgList =
        ets:foldl(fun({_, #item_attr_cfg{bid = Id, use_effect = UseEffect} = Cfg}, FAcc) ->
            NUseEffect = [begin
                              case Effect of
                                  {ins_rand, PrizeId, InsIdInfos} when is_list(InsIdInfos) ->
                                      {Tj, NInsIdInfos} = com_util:probo_build(InsIdInfos),
                                      ?check(Tj == 1000, "qeuip_output.txt [~p] jd_attr 权重和不为1000 ~p", [Id, InsIdInfos]),
                                      {ins_rand, PrizeId, NInsIdInfos};
                                  _ -> Effect
                              end
                          end || Effect <- UseEffect],
            [Cfg#item_attr_cfg{use_effect = NUseEffect} | FAcc]
        end, [], item_attr_cfg),
    NewCfgList.

verify(#item_attr_cfg{bid = Id, type = Type, lev = Lev, quality = Qly
    , overlap = OverLap, job = _Job, use_type = _UseType
    , use_effect = _UseEffect, val = Vals, cant_qhjch = _CnQh
    , cant_sell = _CnSl, cant_hecheng = _CnHc
}) ->
    case Type of
        ?ITEM_TYPE_RAND_INS ->
            ?debug_log_item("id ~w, effect ~w", [Id, UseEffect]);
        ?ITEM_TYPE_GEM ->
            Gems = my_ets:get({gems, Qly, Lev}, []),
            my_ets:set({gems, Qly, Lev}, [Id | Gems]);
        _ -> ignore
    end,
%%     ?check( com_util:is_valid_uint32(Id), "item.txt or equip.txt Item (~w) Id error !", [Id]),
%%     ?check( is_valid_type(Type), "item.txt or equip.txt Item (~w) Type ~w error!", [Id, Type]),
%%     ?check( com_util:is_valid_uint8(Lev), "item.txt or equip.txt Item (~w) Lev ~w error!", [Id, Lev]),
%%     ?check( check_overlap(Type, OverLap) ,"item.txt or equip.txt Item (~w) OverLap ~w error!", [Id, OverLap]),
%%     ?check( is_valid_use_type(UseType), "item.txt or equip.txt Item (~w) UseType ~w error!", [Id, UseType]),
%%     ?check( player_def:is_valid_career(Job), "item.txt or equip.txt Item (~w) Job ~w error!", [Id, Job]),
%%     ?check( item:is_valid_qly(Qly), "item.txt or equip.txt Item (~w) Qly ~w error!", [Id, Qly]),
%%     ?check( com_util:is_valid_cli_bool(CnQh), "item.txt or equip.txt Item (~w) cant_qhjch~w error!", [Id, CnQh]),
%%     ?check( com_util:is_valid_cli_bool(CnSl), "item.txt or equip.txt Item (~w) cant_sell ~w error!", [Id, CnSl]),
%%     ?check( com_util:is_valid_cli_bool(CnHc), "item.txt or equip.txt Item (~w) cant_hecheng ~w error!", [Id, CnHc]),
%%     ?check( is_valid_use_effect(UseEffect), "item.txt or equip.txt Item(~w) error ~w", [Id, UseEffect]),
    check_val_config(Id, Vals),
    check_gem_overlap(Id, Type, OverLap),
    ok;
verify(_R) ->
    ?ERROR_LOG("item ~p 无效格式", [_R]),
    exit(bad).

%% 检测价格列表的有效性
check_val_config(Id, Val) ->
    ?check(com_util:is_valid_uint64(Val), "Item[~w] val ~w 无效", [Id, Val]).

%% 检测史诗宝石的堆叠个数
check_gem_overlap(Id, Type, OverLap) when Type=:=?val_item_type_gem ->
    case load_cfg_gem:is_epic_Gem(Id) of
        ?true ->
            ?check(OverLap =:= 1, "Item[~w] overlap[~w] 无效", [Id,OverLap]);
        _ ->
            ok
    end;
check_gem_overlap(_Id, _Type, _OverLap) ->
    ok.


get_main_type(Bid) ->
    case get_type(Bid) of
        {error, Error} -> {error, Error};
        GoodsType ->
            if
                GoodsType =< 100 -> ?val_item_main_type_goods;
                true -> ?val_item_main_type_equip
            end
    end.

get_type(Bid) ->
    case lookup_item_attr_cfg(Bid) of
        #item_attr_cfg{type = ItemType} -> ItemType;
        _ -> ret:error(unknown_type, Bid)
    end.


is_exist_item_cfg(Bid) ->
    case lookup_item_attr_cfg(Bid) of
        #item_attr_cfg{} -> true;
        _ -> false
    end.

get_petid_on_item_use_effect(Bid) ->
    Cfg = lookup_item_attr_cfg(Bid),
    case Cfg of
        #item_attr_cfg{use_effect=[{pet,2,PetId}]} -> 
            PetId;
        _ -> 
            ?none
    end.
get_pet_exp_on_item_use_effect(Bid) ->
    case lookup_item_attr_cfg(Bid) of
        #item_attr_cfg{use_effect=[{pet,1,Exp}]} ->
            Exp;
        _ ->
            PetId = get_petid_on_item_use_effect(Bid),
            load_cfg_new_pet:get_pet_new_exp_by_id(PetId)
    end.

get_item_cfg(Bid) ->
    Cfg = lookup_item_attr_cfg(Bid),
    case Cfg of
        #item_attr_cfg{} -> Cfg;
        _ -> ret:error(unknown_type)
    end.


get_use_lev(Bid) ->
    Cfg = lookup_item_attr_cfg(Bid),
    case Cfg of
        #item_attr_cfg{lev = Lev} -> Lev;
        _ -> ret:error(unknown_type)
    end.

get_item_quality(Bid) ->
    Cfg = lookup_item_attr_cfg(Bid),
    case Cfg of
        #item_attr_cfg{quality = Quality} -> Quality;
        _ -> ret:error(unknown_type)
    end.

get_price(Bid) ->
    Cfg = lookup_item_attr_cfg(Bid),
    case Cfg of
        #item_attr_cfg{val = Price} -> Price;
        _ -> ret:error(unknown_type)
    end.

%% 能否出售
can_sell(Bid) ->
    Cfg = lookup_item_attr_cfg(Bid),
    case Cfg of
        #item_attr_cfg{cant_sell = CantSell} ->
            case CantSell of
                0 -> ret:ok();
                _ -> ret:error(cant_sell)
            end;
        _ -> ret:error(unknown_type)
    end.

can_overlap(Bid) ->
    Cfg = lookup_item_attr_cfg(Bid),
    case Cfg of
        #item_attr_cfg{overlap = Overlap} ->
            if
                Overlap =< 1 -> ret:error(cant_overlap);
                true -> ret:ok()
            end;
        _ -> ret:error(unknown_type)
    end.

get_overlap(Bid) ->
    Cfg = lookup_item_attr_cfg(Bid),
    case Cfg of
        #item_attr_cfg{overlap = Overlap} ->
            Overlap;
        _ -> 1
    end.

get_is_bind(Bid) ->
    case lookup_item_attr_cfg(Bid) of
        Cfg when is_record(Cfg, item_attr_cfg) ->
            Cfg#item_attr_cfg.is_bind;
        _ ->
            0
    end.

get_is_use_type(Bid) ->
    case lookup_item_attr_cfg(Bid) of
        Cfg when is_record(Cfg, item_attr_cfg) ->
            Cfg#item_attr_cfg.use_type;
        _ ->
            0
    end.

%% 对外接口部分
check_normal_item(ItemId) ->
    is_exist_item_attr_cfg(ItemId).

%% 能否强化
can_qh(Bid) ->
    Cfg = lookup_item_attr_cfg(Bid),
    case Cfg of
        #item_attr_cfg{cant_qhjch = CanQH} ->
            case CanQH of
                0 -> ret:ok();
                _ -> ret:error(cant_qiang_hua)
            end;
        _ -> ret:error(unknown_type)
    end.

get_random_gem(Quality, Lev) ->
    get_random_gem(Quality, Lev, []).

get_random_gem(_, 1, []) -> none;
get_random_gem(_, 1, Gems) ->
    Len = length(Gems),
    Index = com_util:random(1, Len),
    lists:nth(Index, Gems);
get_random_gem(Quality, Lev, Gems) ->
    NewGems = my_ets:get({gems, Quality, Lev}, []),
    get_random_gem(Quality, Lev - 1, NewGems ++ Gems).