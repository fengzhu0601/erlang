-module(mobile_game_app).

-behaviour(application).

%% Application callbacks
-export
([
    start/2
    , stop/1
]).

-include("inc.hrl").
-include("load_db_misc.hrl").

%% ===================================================================
%% Application callbacks
%% ===================================================================


start(_StartType, _StartArgs) ->
    io:format(" ~n~n========================== mobile_game_app game_app start ~n~n"),
    catch sync:go(),
    %% 初始化配置表
    {ok, PlatFormId} = application:get_env(platform_id),
    {ok, Id} = application:get_env(server_id),
    {ok, Name} = application:get_env(server_name),
    CurIP =
        case application:get_env(server_ip) of
            {ok, Ip} ->
                if
                    Ip =/= "0.0.0.0" ->
                        Ip;
                    true ->
                        {ok, Ip1} = util:get_cur_ip(),
                        util:ip_to_str(Ip1)
                end;
            _ ->
                {ok, Ip2} = util:get_cur_ip(),
                util:ip_to_str(Ip2)
        end,
    case load_db_misc:get(?misc_server_start_time, 0) of
        0 -> load_db_misc:set(?misc_server_start_time, erlang:localtime());
        _ -> pass
    end,
    {ok, Port} = application:get_env(server_port),
    {ok, MysqlCofing} = application:get_env(gmhoutai_mysql),
    {ok, LogSrvNodeName} = application:get_env(logsrv_node_name),
    {ok, GmPort} = application:get_env(gm_port),
    {ok, CurDebugId} = application:get_env(server_debug_version),
    {ok, MainVersion} = application:get_env(server_main_version),
    {ok, AssVersion} = application:get_env(server_assish_version),
    {ok, Version} = application:get_env(server_res_version),
    {ok, IsCheckAccount} = application:get_env(is_check_account),
    {ok, SceneViewMax} = application:get_env(scene_view_max),
    {ok, IsNewPlayerGuide} = application:get_env(newplayer_guide),
    {ok, LoginPlayerMax} = application:get_env(login_player_count_max),
    {ok, IsOpenGm} = application:get_env(is_open_module),
    {ok, CenterSvrNodeInfo} = application:get_env(center_svr_node_info),

    global_data:init_server_info
    (#{
        platform_id => PlatFormId
        , id => Id
        , name => Name
        , ip => CurIP
        , port => Port
        , mysql_config => MysqlCofing
        , logsrv_node_name => LogSrvNodeName
        , gmport => GmPort
        , is_check_account => IsCheckAccount
    }),
    my_ets:set(server_id,                       Id),
    my_ets:set(server_debug_version,            CurDebugId),
    my_ets:set(server_main_version,             MainVersion),
    my_ets:set(server_assish_version,           AssVersion),
    my_ets:set(server_res_version,              Version),
    my_ets:set(is_check_account,                IsCheckAccount),
    my_ets:set(ip,                              CurIP),
    my_ets:set(misc_scene_view_max,             SceneViewMax),
    my_ets:set(newplayer_guide,                 IsNewPlayerGuide),
    my_ets:set(login_player_count_max,          LoginPlayerMax),
    my_ets:set(is_open_module,                  IsOpenGm),

    db_agent:init_db(),
    timer:sleep(2000),
    global_data:init_player_count(PlatFormId, Id),
    global_data:init_account_count(PlatFormId, Id),

    op_player:save_game_server_node(),
    op_player:save_houtai_goods(),
    %global_data:init_online_count(),
    %% 开启进程
    {ok, Pid} = mobile_game_sup:start_link(),
    listener_cmd:start_child(),
    my_ets:set(center_svr_node_info, CenterSvrNodeInfo),
    {ok, Pid}.


stop(_State) ->
    listener_cmd:stop_child(),
    ok.
