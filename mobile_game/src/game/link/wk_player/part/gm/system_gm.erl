%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 07. 一月 2016 下午2:23
%%%-------------------------------------------------------------------
-module(system_gm).
-author("clark").

%% API
-export
([
    close_server/1
    ,broadcast_mes/1
    ,show_scene_count/1
    ,test_trace/0
    ,send_server_busy/1
    ,test_lua/0
    ,test_lua1/0
]).

-include("scene_msg_sign.hrl").
-include("player.hrl").
-include("room_system.hrl").



-define(pd_close_server_time_begin, pd_close_server_time_begin).
-define(pd_close_server_time_over,  pd_close_server_time_over).
-define(pd_api_close_server_time,   pd_api_close_server_time).
-define(pd_api_close_server_pid,    pd_api_close_server_pid).




%% 设置关闭服务器的时间(s)
close_server(Time) when is_integer(Time) ->
    case erlang:get(?pd_api_close_server_time) of
        _ -> erlang:put(?pd_api_close_server_time, Time)
    end,
    Ret_time = erlang:get(?pd_api_close_server_time),
    case erlang:get(?pd_api_close_server_pid) of
        undefined -> ok;
        Pid1 ->
            exit(Pid1,kill),
            erlang:erase(?pd_api_close_server_pid)
    end,
    Pid = spawn
    (
        fun() ->
            delay_time(Ret_time*1000),
            mobile_game_cmd:stop()
        end
    ),
    erlang:put(?pd_api_close_server_pid, Pid),
    TimeList = integer_to_list(Time),
    broadcast_mes(string:concat(TimeList, unicode:characters_to_binary("秒后服务器关闭"))).



%% 发送公告信息
broadcast_mes(Notice) ->
    world:broadcast(?to_client_msg(chat_sproto:pkg_msg(?MSG_CHAT_SYSTEM, {list_to_binary(Notice)}))),
    ok.


%% 显示场景人数
show_scene_count(CfgID) ->
    ScenePid = load_cfg_scene:get_pid(CfgID),
    Count =
        gen_server:call
        (
            ScenePid,
            {
                mod, scene_gm,
                {
                    ?scene_call_player_count
                }
            }
        ),
    ?INFO_LOG("scene_count scene: ~p  count:~p ",[CfgID, Count]).


%% trace
test_trace() ->
    ?INFO_LOG("test_trace").


send_server_busy(MsgId) ->
    ?player_send(player_sproto:pkg_msg(?MSG_PLAYER_ERROR, {MsgId,9999,<<>>})).


test_lua() ->

    New = luerl:init(),

    {ok, Chunk, LuaStack} = luerl:loadfile("./lua/test.lua", New),
    {_FileRet, LuaStack1} = luerl:do(Chunk, LuaStack),
    luerl:call_function([print], [<<"hello world 123">>], LuaStack1),
    {Result1, _} = luerl:call_function([my_print], [], LuaStack1),

    St = com_time:timestamp_msec(),
    {Result2, _} = luerl:call_function([get_ai], [], LuaStack1),
    St1 = com_time:timestamp_msec(),
    ?INFO_LOG("---------- hello Cost ---------- ~p \n", [(St1-St)]),
    ?INFO_LOG("---------- Lua ---------- ~p \n", [{Result1, Result2}]),
    ok.

test_lua1() ->
    New = luerl:init(),
    luerl_emul:load_libs(),

    {_, New1} = luerl:dofile("./lua/base.lua", New),
    {_, New2}= luerl:dofile("./lua/test.lua", New1),
    luerl:call_function([base_print], [<<"test base_print 123">>], New2),
    ok.

%% private
delay_time(Time) ->
    receive
    after Time -> true
    end.
