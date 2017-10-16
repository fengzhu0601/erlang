%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 25. 十一月 2015 下午5:20
%%%-------------------------------------------------------------------
-module(load_equip_change).
-author("clark").

%% API
-export([
    get_equipList/1
    ,get_effList/1
    ,get_attrId/1
]).

-include("inc.hrl").
-include_lib("config/include/config.hrl").
-include("load_equip_change.hrl").


load_config_meta() ->
    [
        #config_meta
        {
            record = #equip_change{},
            fields = ?record_fields(equip_change),
            file = "equip_change_list.txt",
            keypos = #equip_change.id,
            verify = fun verify/1
        }
    ].

verify(#equip_change{}) ->
    ok.

get_equipList(BulletId) ->
    case lookup_equip_change(BulletId) of
        #equip_change{} = Date ->
            Date#equip_change.equip_list;
        _->
            ?none
    end.

get_effList(BulletId) ->
    case lookup_equip_change(BulletId) of
        #equip_change{} = Date ->
            Date#equip_change.eff_list;
        _->
            ?none
    end.

get_attrId(BulletId) ->
    case lookup_equip_change(BulletId) of
        #equip_change{} = Date ->
            Date#equip_change.attr_id;
        _->
            ?none
    end.



