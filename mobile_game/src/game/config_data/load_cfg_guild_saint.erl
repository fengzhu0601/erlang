%%%-------------------------------------------------------------------
%%% @author fengzhu
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 12. 十二月 2016 下午4:23
%%%-------------------------------------------------------------------
-module(load_cfg_guild_saint).
-author("fengzhu").

-include_lib("config/include/config.hrl").
-include("inc.hrl").
-include("load_cfg_guild_saint.hrl").

%% API
-export([
    get_all_saint_type_by_offer_lv/1
    , get_all_saint_type_open_lv/1
]).

load_config_meta() ->
    [
        #config_meta
        {
            record = #guild_saint_cfg{},
            fields = ?record_fields(guild_saint_cfg),
            file = "guild_saint.txt",
            keypos = [#guild_saint_cfg.offer_lv, #guild_saint_cfg.type],
            groups = [#guild_saint_cfg.offer_lv, #guild_saint_cfg.type],
            verify = fun verify/1
        }
    ].

verify(#guild_saint_cfg{id = Id, offer_lv = OfferLv, type = Type, prize = Prize}) ->
    ?check(is_integer(OfferLv), "guild_saint.txt中， [~p] offer_lv:~p 配置无效。", [Id, OfferLv]),
    ?check(is_integer(Type), "guild_saint.txt中， [~p] type:~p 配置无效。", [Id, Type]),
    ?check(is_list(Prize), "guild_saint.txt中， [~p] prize:~p 配置无效。", [Id, Prize]),
    ok.


get_all_saint_type_by_offer_lv(OfferLv) ->
    lookup_group_guild_saint_cfg(#guild_saint_cfg.offer_lv, OfferLv).

get_all_saint_type_open_lv(SaintId) ->
    lookup_group_guild_saint_cfg(#guild_saint_cfg.type, SaintId).

