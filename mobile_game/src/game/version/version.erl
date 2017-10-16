%%%-------------------------------------------------------------------
%%% @author simba
%%% @copyright (C) 2015, <santi COMPANY>
%%% @doc    用于与客户端进行版本调试
%%%
%%% @end
%%% Created : 05. 八月 2015 下午3:39
%%%-------------------------------------------------------------------
-module(version).

-author("simba").

-include("inc.hrl").
-include("player.hrl").
-include("load_db_misc.hrl").

%% -define(DEBUG_ID, 0).
%% -define(MAIN_VERSIN_ID, 12).
%% -define(ASSIST_VERSION, 0).

-define(DEBUG_SUCCED, 0).
-define(DEBUG_FAILD, 1).
-define(VERSIN_UNMATCH, 2).
-define(RESOUCE_VERSION_MATCH_FAILD, 3).
-define(ASSIST_VERSION_MATCH_FAILD, 4).

%% API 检查版本
-export(
[
    check_version/1,
    show/0
]).

check_version({DebugId, MainVersionId, AssisVersionId, ResouceVersionId}) ->
    CurDebugId  = my_ets:get(server_debug_version,   0),
    MainVersion = my_ets:get(server_main_version,    0),
    AssVersion  = my_ets:get(server_assish_version,  0),
    Version     = my_ets:get(server_res_version,     0),
    % ReplyNum =
    %     case DebugId of
    %         CurDebugId when MainVersionId =:= MainVersion, ResouceVersionId =:= Version, AssisVersionId =:= AssVersion
    %             ->
    %             ?DEBUG_SUCCED;                                  %%  调试号和主版本匹配，调试成功
    %         CurDebugId when MainVersionId =/= MainVersion ->
    %             ?VERSIN_UNMATCH;                                %%  协议不兼容
    %         CurDebugId when AssisVersionId > AssVersion ->
    %             ?VERSIN_UNMATCH;                                %%  协议不兼容
    %         CurDebugId when AssisVersionId < AssVersion ->
    %             ?ASSIST_VERSION_MATCH_FAILD;                    %%  辅助版本匹配失败
    %         CurDebugId when ResouceVersionId =/= Version ->
    %             ?RESOUCE_VERSION_MATCH_FAILD;                   %%  资源版本匹配失败
    %         _ ->
    %             ?DEBUG_FAILD                                    %%  调试失败
    %     end,
    % ?NODE_INFO_LOG("MSG_VERSION_DEBUG Ret ~p", [{ReplyNum}]),
    % ?player_send(player_sproto:pkg_msg(?MSG_VERSION, {ReplyNum})).
    ReplyNum = case CurDebugId of
        0 when MainVersionId =:= MainVersion, ResouceVersionId =:= Version, AssisVersionId =:= AssVersion -> ?DEBUG_SUCCED;
        0 when MainVersionId =/= MainVersion -> ?VERSIN_UNMATCH;
        0 when AssisVersionId > AssVersion -> ?VERSIN_UNMATCH;
        0 when AssisVersionId < AssVersion -> ?ASSIST_VERSION_MATCH_FAILD;
        0 when ResouceVersionId =/= Version -> ?RESOUCE_VERSION_MATCH_FAILD;
        DebugId when MainVersionId =:= MainVersion, ResouceVersionId =:= Version, AssisVersionId =:= AssVersion -> ?DEBUG_SUCCED;
        DebugId when MainVersionId =/= MainVersion -> ?VERSIN_UNMATCH;
        DebugId when AssisVersionId > AssVersion -> ?VERSIN_UNMATCH;
        DebugId when AssisVersionId < AssVersion -> ?ASSIST_VERSION_MATCH_FAILD;
        DebugId when ResouceVersionId =/= Version -> ?RESOUCE_VERSION_MATCH_FAILD;
        _ -> ?DEBUG_FAILD
    end,
    ?NODE_INFO_LOG("MSG_VERSION_DEBUG Ret ~p", [{ReplyNum}]),
    ?player_send(player_sproto:pkg_msg(?MSG_VERSION, {ReplyNum})).


show() ->
    CurDebugId              = my_ets:get(server_debug_version,     0),
    MainVersion             = my_ets:get(server_main_version,      0),
    AssVersion              = my_ets:get(server_assish_version,    0),
    Version                 = my_ets:get(server_res_version,       0),
    SceneViewMax            = my_ets:get(misc_scene_view_max,     20),
    IsNewPlayerGuide        = my_ets:get(newplayer_guide,          1),
    LoginPlayerMax          = my_ets:get(login_player_count_max,   0),

    ?INFO_LOG("***************** version *******************"),
    ?INFO_LOG("** main_version      ~p", [MainVersion]),
    ?INFO_LOG("** debug_version     ~p", [CurDebugId]),
    ?INFO_LOG("** assish_version    ~p", [AssVersion]),
    ?INFO_LOG("** res_version       ~p", [Version]),
    ?INFO_LOG("** scene_view_max    ~p", [SceneViewMax]),
    ?INFO_LOG("** login_player_max  ~p", [LoginPlayerMax]),
    ?INFO_LOG("** server_info       ~p", [global_data:get_server_info()]),
    ?INFO_LOG("** server_players    ~p", [ets:info(world, size)]),
    ?INFO_LOG("** server_start_time ~p", [load_db_misc:get(?misc_server_start_time, 0)]),
    ?INFO_LOG("** newplayer_guide   ~p", [IsNewPlayerGuide]),
    ?INFO_LOG("** memory_can_use    ~p", [1-erlang:memory(processes_used)/erlang:memory(total)]),
    ?INFO_LOG("** cur process count ~p", [erlang:system_info(process_count)]),
    ?INFO_LOG("** process rate      ~p", [erlang:system_info(process_count)/erlang:system_info(process_limit)]),
    ?INFO_LOG("************************************").

