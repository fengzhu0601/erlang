-module(load_cfg_city).

%% API
-export([
    get_scene_list_by_city_id/1
]).



-include("inc.hrl").
-include_lib("config/include/config.hrl").
-include("load_cfg_city.hrl").



get_scene_list_by_city_id(CityId) ->
    case lookup_city_cfg(CityId) of
        ?none ->
            ?false;
        #city_cfg{scenes=L} ->
            L
    end.


load_config_meta() ->
    [
        #config_meta{
            record = #city_cfg{},
            fields = ?record_fields(city_cfg),
            file = "city.txt",
            keypos = #city_cfg.id,
            verify = fun verify/1}
    ].

verify(#city_cfg{id = Id}) ->
    ok.



