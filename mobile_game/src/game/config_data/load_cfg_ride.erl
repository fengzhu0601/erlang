%%%-------------------------------------------------------------------
%%% @author fengzhu
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 11. 五月 2016 下午3:08
%%%-------------------------------------------------------------------
-module(load_cfg_ride).
-author("fengzhu").

%% API
-export([
%%    get_ride_list/0
    get_ride_formId_by_id/1,
    get_random_ride_id/0,
    get_max_soul_level/0
]).

-include_lib("config/include/config.hrl").
-include("inc.hrl").
-include("load_cfg_ride.hrl").

load_config_meta() ->
    [
        #config_meta{record = #ride_attr_cfg{},
            fields = ?record_fields(ride_attr_cfg),
            file = "ride_attr.txt",
            keypos = [#ride_attr_cfg.id,#ride_attr_cfg.level],
            verify = fun verify_ride_attr_cfg/1
        } ,
        #config_meta{record = #ride_form_cfg{},
            fields = ?record_fields(ride_form_cfg),
            file = "ride_form.txt",
            keypos = #ride_form_cfg.id,
            verify = fun verify_ride_form_cfg/1
        },
        #config_meta{record = #ride_soul_attr_cfg{},
            fields = ?record_fields(ride_soul_attr_cfg),
            file = "ride_soul_attr.txt",
            keypos = #ride_soul_attr_cfg.id,
            verify = fun verify_ride_soul_attr_cfg/1
        },
        #config_meta{record = #ride_soul_form_cfg{},
            fields = ?record_fields(ride_soul_form_cfg),
            file = "ride_soul_form.txt",
            keypos = #ride_soul_form_cfg.id,
            verify = fun verify_ride_soul_form_cfg/1
        }
    ].

verify_ride_attr_cfg(RideCfg) ->
    ?check(load_cfg_ride:is_exist_ride_form_cfg(RideCfg#ride_attr_cfg.form_id), "ride ~p form_id ~p error", [RideCfg#ride_attr_cfg.id, RideCfg#ride_attr_cfg.form_id]),
    ?check(cost:is_exist_cost_cfg(RideCfg#ride_attr_cfg.cost_id), "ride ~p cost_id ~p error", [RideCfg#ride_attr_cfg.id, RideCfg#ride_attr_cfg.cost_id]),
    ok.

verify_ride_form_cfg(#ride_form_cfg{id = Id}) ->
    ?check(is_integer(Id), "ride_form.txt id ~p error", [Id]),
    ok.

verify_ride_soul_attr_cfg(RideSoulCfg) ->
    {CostId, _, _} = RideSoulCfg#ride_soul_attr_cfg.get_happy,
    ?check(cost:is_exist_cost_cfg(CostId), "ride ~p cost_id ~p error", [RideSoulCfg#ride_soul_form_cfg.id, CostId]),
    ok.

verify_ride_soul_form_cfg(#ride_soul_form_cfg{id = Id, happy = Happy}) ->
    ?check((Happy >= 0) andalso (Happy =< 100), "ride_soul_form.txt id ~p per error", [Id]),
    ok.

%%get_ride_list() ->
%%    lookup_all_ride_attr_cfg(#ride_attr_cfg.id).

get_ride_formId_by_id(RideId) ->
    case lookup_ride_attr_cfg(RideId) of
        none ->
            0;
        #ride_attr_cfg{form_id = Form_id} ->
            Form_id
    end.


get_random_ride_id() ->
    L = com_ets:keys(ride_form_cfg),
    lists:nth(random:uniform(length(L)), L).

get_max_soul_level() ->
    L = com_ets:keys(ride_soul_attr_cfg),
    erlang:length(L).

