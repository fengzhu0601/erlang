%%%-------------------------------------------------------------------
%%% @author fengzhu
%%% @copyright (C) 2016, <COMPANY>
%%% @doc 宝石
%%%
%%% @end
%%% Created : 04. 一月 2016 下午2:41
%%%-------------------------------------------------------------------
-module(load_cfg_gem).
-author("fengzhu").

-include_lib("config/include/config.hrl").

%% API
-export([
    get_attrs/2
    , is_valid_type/1
    , get_attr_by_bid/1
    , get_cost_by_bid/1
    , get_exp_by_bid/1
    , is_epic_Gem/1
    , get_attrid_by_bid/1
    , get_lv_by_bid/1
    , get_exp_cost_by_bid/1
    , get_gem_cfg_attr/1
    , get_up_exp_by_bid/1
    , get_next_level_id_by_bid/1
    , get_gem_lev/1
]).

-include("inc.hrl").
-include("player.hrl").
-include("item.hrl").
-include("load_cfg_gem.hrl").

load_config_meta() ->
    [
        #config_meta
        {
            record = #gem_cfg{},
            fields = ?record_fields(gem_cfg),
            file = "gem.txt",
            keypos = #gem_cfg.id,
            verify = fun verify_gem/1
        }
    ].

%% @spec get_attrs(GemId) -> AList
%% @doc 获取宝石相关属性
get_attrs(_, []) -> [];
get_attrs(GemBid, AtomL) ->
    get_attrs_1(AtomL, lookup_gem_cfg(GemBid), []).

get_attrs_1([], _, Rnt) -> lists:reverse(Rnt);
get_attrs_1(_AtomL, ?none, _Rnt) -> [];
get_attrs_1([Atom | TL], GemCfg = #gem_cfg{}, Rnt) ->
    Pos = atom2pos(Atom),
    get_attrs_1(TL, GemCfg, [element(Pos, GemCfg) | Rnt]).

%% 是否有效的宝石类型
is_valid_type(Type) ->
    ?ITEM_TYPE_GEM == Type.


atom2pos(lev) -> #gem_cfg.lev;
atom2pos(up_cost) -> #gem_cfg.up_cost;
atom2pos(attr) -> #gem_cfg.attr;
atom2pos(type) -> #gem_cfg.type.



verify_gem(#gem_cfg{id = Id, up_cost = UpCost, embed_cost = EmbedCost, attr = Attr, lev = Lev}) ->
    ?check(load_item:is_exist_item_attr_cfg(Id), "gem.txt [~w] id 无法在item表中找到", [Id]),
    ?check(load_spirit_attr:is_exist_attr(Attr), "gem.txt [~p] attr 无效 ~p", [Id, Attr]),
    ?check(com_util:is_valid_uint8(Lev), "gem.txt [~w] lev 无效 ~w", [Id, Lev]),
    cost:check_cost_not_empty(EmbedCost, "gem.txt [~w] embed_cost 无法在cost表中找到 ~w ", [Id, EmbedCost]),
    cost:check_cost_not_empty(UpCost, "gem.txt [~w] up_cost 无法在cost表中找到 ~w ", [Id, UpCost]),
    ok.

get_attr_by_bid(GemBid) ->
    case lookup_gem_cfg(GemBid) of
        #gem_cfg{attr = AttrID} ->
            attr_new:get_attr_by_id(AttrID);
        _ ->
            ?DEBUG_LOG("gem 3--------------------"),
            {error, gem_lev_max}
    end.

get_cost_by_bid(GemBid) ->
    case lookup_gem_cfg(GemBid) of
        #gem_cfg{embed_cost = CostID} ->
            case load_cost:get_cost_list(CostID) of
                {error, Error} -> {error, Error};
                List -> List
            end;
        _ ->
            ?DEBUG_LOG("gem 3--------------------"),
            {error, gem_lev_max}
    end.

get_exp_by_bid(GemBid)  ->
    case lookup_gem_cfg(GemBid) of
        #gem_cfg{exp = Exp} ->
            Exp;
        _ ->
            ?DEBUG_LOG("gem 3--------------------"),
            {error, no_exp}
    end.
get_gem_cfg_attr(GemBid) ->
    case lookup_gem_cfg(GemBid) of
        #gem_cfg{attr = AttrId} ->
            AttrId;
        _ ->
            ret:error(unknown_type)
    end.

get_exp_cost_by_bid(GemBid) ->
    case lookup_gem_cfg(GemBid) of
        #gem_cfg{exp_cost = ExpCost} ->
            ExpCost;
        _ ->
            ?DEBUG_LOG("gem 3--------------------"),
            {error, no_exp}
    end.


%% 是否是史诗宝石
is_epic_Gem(GemBid) ->
    case lookup_gem_cfg(GemBid) of
        #gem_cfg{type = Type} ->
            if
                Type > 50 ->
                    ?true;
                true ->
                    ?false
            end;
        _ ->
            ?DEBUG_LOG("gem 3--------------------"),
            {error, no_type}
    end.

get_attrid_by_bid(GemBid) ->
    case lookup_gem_cfg(GemBid) of
        #gem_cfg{attr = Attr} ->
            Attr;
        _ ->
            ?DEBUG_LOG("gem 3--------------------"),
            {error, no_attr}
    end.

get_lv_by_bid(GemBid) ->
    case lookup_gem_cfg(GemBid) of
        #gem_cfg{lev = Lev} ->
            Lev;
        _ ->
            ?DEBUG_LOG("gem 3--------------------"),
            {error, no_lev}
    end.


get_up_exp_by_bid(GemBid) ->
    case lookup_gem_cfg(GemBid) of
        #gem_cfg{up_exp = UpExp} ->
            UpExp;
        _ ->
            ?DEBUG_LOG("gem 3--------------------"),
            {error, no_up_exp}
    end.

get_next_level_id_by_bid(GemBid) ->
    case lookup_gem_cfg(GemBid) of
        #gem_cfg{next_level_id = NextLevelId} ->
            NextLevelId;
        _ ->
            ?DEBUG_LOG("gem 3--------------------"),
            {error, next_level_id}
    end.

get_gem_lev(GemBid) ->
    case lookup_gem_cfg(GemBid) of
        #gem_cfg{lev = Level} ->
            Level;
        _ ->
            ?DEBUG_LOG("gem 3--------------------"),
            {error, lev}
    end.
