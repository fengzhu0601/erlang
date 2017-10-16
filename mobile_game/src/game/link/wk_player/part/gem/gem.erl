%%%-------------------------------------------------------------------
%%% @author zl
%%% @doc 宝石
%%%
%%% @end
%%%-------------------------------------------------------------------

-module(gem).
%%
%%-include_lib("config/include/config.hrl").
%%
%%%% API
%%-export([
%%    get_attrs/2
%%    , is_valid_type/1
%%    , get_attr_by_bid/1
%%    , get_cost_by_bid/1
%%]).
%%
%%-include("inc.hrl").
%%-include("player.hrl").
%%-include("gem.hrl#").
%%-include("item.hrl").
%%
%%
%%
%%%% @spec get_attrs(GemId) -> AList
%%%% @doc 获取宝石相关属性
%%get_attrs(_, []) -> [];
%%get_attrs(GemBid, AtomL) ->
%%    get_attrs_1(AtomL, lookup_gem_cfg(GemBid), []).
%%
%%get_attrs_1([], _, Rnt) -> lists:reverse(Rnt);
%%get_attrs_1(_AtomL, ?none, _Rnt) -> [];
%%get_attrs_1([Atom | TL], GemCfg = #gem_cfg{}, Rnt) ->
%%    Pos = atom2pos(Atom),
%%    get_attrs_1(TL, GemCfg, [element(Pos, GemCfg) | Rnt]).
%%
%%%% 是否有效的宝石类型
%%is_valid_type(Type) ->
%%    ?ITEM_TYPE_GEM == Type.
%%
%%
%%atom2pos(lev) -> #gem_cfg.lev;
%%atom2pos(up_cost) -> #gem_cfg.up_cost;
%%atom2pos(attr) -> #gem_cfg.attr;
%%atom2pos(type) -> #gem_cfg.type.
%%
%%load_config_meta() ->
%%    [
%%
%%        #config_meta{record = #gem_cfg{},
%%            fields = ?record_fields(gem_cfg),
%%            file = "gem.txt",
%%            keypos = #gem_cfg.id,
%%            verify = fun verify_gem/1}
%%    ].
%%
%%verify_gem(#gem_cfg{id = Id, up_cost = UpCost, embed_cost = EmbedCost, attr = Attr, lev = Lev}) ->
%%    ?check(load_item:is_exist_item_attr_cfg(Id), "gem.txt [~w] id 无法在item表中找到", [Id]),
%%    ?check(load_spirit_attr:is_exist_attr(Attr), "gem.txt [~p] attr 无效 ~p", [Id, Attr]),
%%    ?check(com_util:is_valid_uint8(Lev), "gem.txt [~w] lev 无效 ~w", [Id, Lev]),
%%    cost:check_cost_not_empty(EmbedCost, "gem.txt [~w] embed_cost 无法在cost表中找到 ~w ", [Id, EmbedCost]),
%%    cost:check_cost_not_empty(UpCost, "gem.txt [~w] up_cost 无法在cost表中找到 ~w ", [Id, UpCost]),
%%    ok.
%%
%%get_attr_by_bid(GemBid) ->
%%    case gem:lookup_gem_cfg(GemBid) of
%%        #gem_cfg{attr = AttrID} ->
%%            attr_new:get_attr_by_id(AttrID);
%%        _ ->
%%            ?DEBUG_LOG("gem 3--------------------"),
%%            {error, gem_lev_max}
%%    end.
%%
%%get_cost_by_bid(GemBid) ->
%%    case gem:lookup_gem_cfg(GemBid) of
%%        #gem_cfg{embed_cost = CostID} ->
%%            case load_cost:get_cost_list(CostID) of
%%                {error, Error} -> {error, Error};
%%                List -> List
%%            end;
%%        _ ->
%%            ?DEBUG_LOG("gem 3--------------------"),
%%            {error, gem_lev_max}
%%    end.

