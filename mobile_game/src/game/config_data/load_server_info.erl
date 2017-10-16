-module(load_server_info).

%% API
-export([get_fs_name_by_id/2
]).


-include("inc.hrl").
-include_lib("config/include/config.hrl").
-include("load_server_info.hrl").


get_fs_name_by_id(PlatformId, ServerId) ->
    ?DEBUG_LOG("PlatformId-----:~p------ServerId----:~p",[PlatformId, ServerId]),
    case lookup_server_info_cfg({PlatformId, ServerId}) of
        ?none ->
            %pass;
             {<<"molin">>, <<"longzhiqiyuan">>};
        #server_info_cfg{platform_name=Pn, server_name=Sn} ->
            {Pn, Sn}
    end.


load_config_meta() ->
    [
        #config_meta{record = #server_info_cfg{},
            fields = ?record_fields(server_info_cfg),
            file = "server_info.txt",   
            keypos = [#server_info_cfg.id,#server_info_cfg.server_id],
            verify = fun verify/1}
    ].



verify(#server_info_cfg{}) ->
    ok;

verify(_R) ->
    ?ERROR_LOG("item ~p 无效格式", [_R]),
    exit(bad).



