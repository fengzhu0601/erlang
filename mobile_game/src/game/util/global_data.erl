%%% coding:utf-8
%%%-------------------------------------------------------------------
%%% @author zl
%%% @doc 用于存储游戏全局运行时信息
%%%      所有存储的操作都必须定义API 其他模块不能直接使用ets函数来操作
%%%
%%%      depen global_table app
%%%
%%% @end
%%%-------------------------------------------------------------------

-module(global_data).

-include_lib("common/include/inc.hrl").

-define(normal_scenes, normal_scenes).


%% API
-export(
[
    add_normal_scene/1,
    get_normal_scenes/0,
    init_server_info/1,
    get_server_info/0,
    set_log_server/1,
    get_log_server/0,
    add_gm_controller_port/1,
    get_gm_controller_port/0,
    get/2,
    set/2,
    init_player_count/2,
    update_player_count/0,
    init_account_count/2,

    update_account_count/0,
    get_player_count/0,
    get_account_count/0

    %init_online_count/0,
    %update_online_count/1,
    %get_online_count/0
]).

% ets:insert(global_table, {online_player_count, ets:info(world,size)}).

-define(TAB_LIB, global_table).
-define(LOG_SERVER, log_server).
-define(get_global_key(X), {global_cfg, X}).

init_server_info(Info) ->
    true = ets:insert_new(?TAB_LIB, {server_info, Info}).

get_server_info() ->
    case ets:lookup(?TAB_LIB, server_info) of
        [] -> none;
        [{server_info, Info}] -> Info
    end.

% init_online_count() ->
%     true = ets:insert_new(?TAB_LIB, {online_player_count, 0}).

% update_online_count(IsAdd) ->
%     case ets:lookup(?TAB_LIB, online_player_count) of
%         [] ->
%             pass;
%         [{online_player_count, Count}] ->
%             ets:insert(?TAB_LIB, {online_player_count, op_player:get_count(IsAdd, Count)})
%     end,
%     ok.

% get_online_count() ->
%     case ets:lookup(?TAB_LIB, online_player_count) of
%         [] ->
%             0;
%         [{online_player_count, Count}] ->
%             Count
%     end.

init_player_count(PlatFormId, ServerId) ->
    Count = op_player:get_create_player_count(PlatFormId, ServerId),
    true = ets:insert_new(?TAB_LIB, {player_count, Count}).

update_player_count() ->
    case ets:lookup(?TAB_LIB, player_count) of
        [] ->
            pass;
        [{player_count, Count}] ->
            ets:insert(?TAB_LIB, {player_count, Count+1})
    end,
    ok.
get_player_count() ->
    case ets:lookup(?TAB_LIB, player_count) of
        [] ->
            0;
        [{player_count, Count}] ->
            Count
    end.

init_account_count(PlatFormId, ServerId) ->
    Count = op_player:get_re_account_count(PlatFormId, ServerId),
    true = ets:insert_new(?TAB_LIB, {account_count, Count}).

update_account_count() ->
    case ets:lookup(?TAB_LIB, account_count) of
        [] ->
            io:format("global_data-2------pass  ~n"),
            pass;
        [{account_count, Count}] ->
            io:format("global_data 2 count-------:~p~n",[Count]),
            ets:insert(?TAB_LIB, {account_count, Count+1})
    end,
    ok.
get_account_count() ->
    case ets:lookup(?TAB_LIB, account_count) of
        [] ->
            0;
        [{account_count, Count}] ->
            Count
    end.

add_gm_controller_port(Port) ->
    ets:insert_new(?TAB_LIB, {gm_controller_port, Port}).

get_gm_controller_port() ->
    case ets:lookup(?TAB_LIB, gm_controller_port) of
        [] ->
            none;
        [{gm_controller_port, Port}] ->
            Port
    end. 

add_normal_scene(CfgId) ->
    case ets:lookup(?TAB_LIB, ?normal_scenes) of
        [] ->
            ets:insert(?TAB_LIB, {?normal_scenes, [CfgId]});
        [{?normal_scenes, IdList}] ->
            ets:insert(?TAB_LIB, {?normal_scenes, [CfgId | IdList]})
    end,
    ok.

get_normal_scenes() ->
    case ets:lookup(?TAB_LIB, ?normal_scenes) of
        [] -> [];
        [{?normal_scenes, IdList}] -> IdList;
        O -> io:format("sc :~p ", [O])
    end.

set_log_server(LogServer) ->
    true = ets:insert_new(?TAB_LIB, {?LOG_SERVER, LogServer}).

get_log_server() ->
    case ets:lookup(?TAB_LIB, ?LOG_SERVER) of
        [] -> [];
        [{?LOG_SERVER, IdList}] -> IdList;
        O -> io:format("sc :~p ", [O])
    end.

%% --------------------------
get(Key, Default) ->
    case ets:lookup(?TAB_LIB, ?get_global_key(Key)) of
        [] ->
            Default;
        [{?get_global_key(Key), Val}] ->
            Val
    end.


set(Key, Val) ->
    Key1 = ?get_global_key(Key),
    case ets:lookup(?TAB_LIB, Key1) of
        [] ->
            ets:insert_new(?TAB_LIB, {Key1, Val});
        [{Key1, Val}] ->
            ets:update_element(?TAB_LIB, Key1, {2,Val})
    end.

