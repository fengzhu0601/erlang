-module(load_cfg_task_buff_pool).

-include_lib("config/include/config.hrl").
-include("inc.hrl").
-include("load_cfg_task_buff_pool.hrl").

%% API
-export([
    get_task_buff_pool_id_list/1
]).


get_task_buff_pool_id_list(Id) ->
    case lookup_task_buff_pool_cfg(Id) of
        ?none ->
            [];
        #task_buff_pool_cfg{num=Num, buff_list=List} ->
            util:get_val_by_weight(List, random:uniform(Num))
    end.

load_config_meta() ->
    [
        #config_meta{record = #task_buff_pool_cfg{},
        fields = ?record_fields(task_buff_pool_cfg),
        file = "task_buff_pool.txt",
        keypos = #task_buff_pool_cfg.id,
        verify = fun verify/1}
    ].


verify(#task_buff_pool_cfg{id = _Id}) ->
    ok.
