
%%-----------------------------------
%% @Module  : robot_new_server
%% @Author  : Holtom
%% @Email   : 
%% @Created : 2016.6.28
%% @Description: robot_new_server
%%-----------------------------------
-module(robot_new_server).
-behaviour(gen_server).

-include("inc.hrl").

-record(robot_new_state, {
    robot_id = 0,           %% 当前机器人id
    all_robot_num = 0,      %% 当前活跃机器人数量
    delete_id_list = [],    %% 已经流失机器人
    limit_num = 0,          %% 机器人数量上限
    robot_state_list = []   %% 机器人状态列表
}).

% gen_server callbacks
-export([
        init/1,
        handle_call/3,
        handle_cast/2,
        handle_info/2,
        terminate/2,
        code_change/3
    ]).

%% Module Interface 
-export([
        start_link/0,
        create_robot/0,
        robot_online/2,
        robot_delete/1,
        get_robot_server_state/0,
        get_robot_id_list/0,
        change_robot_state/4,
        get_robot_state/0,
        get_online_robot_num/0
    ]).

%% =================================================================== 
%% Module Interface
%% ===================================================================
start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

create_robot() ->
    gen_server:cast(?MODULE, {'CREATE_ROBOT'}).

robot_online(RobotId, Time) ->
    erlang:send_after(Time * 1000, ?MODULE, {'ROBOT_ONLINE', RobotId}).

robot_delete(RobotId) ->
    gen_server:cast(?MODULE, {'ROBOT_DELETE', RobotId}).

get_robot_server_state() ->
    gen_server:cast(?MODULE, {'GET_ROBOT_SERVER_STATE'}).

get_robot_id_list() ->
    gen_server:call(?MODULE, {'GET_ROBOT_ID_LIST'}).

change_robot_state(RobotId, Name, Lev, State) ->
    gen_server:cast(?MODULE, {'CHANGE_ROBOT_STATE', RobotId, Name, Lev, State}).

get_robot_state() ->
    gen_server:call(?MODULE, {'GET_ROBOT_STATE'}).

get_online_robot_num() ->
    gen_server:call(?MODULE, {'GET_ONLINE_ROBOT_NUM'}).

%% ===================================================================
%% gen_server callbacks
%% ===================================================================
init([]) ->
    com_process:init_name(<<"robot_new_server">>),
    com_process:init_type(?MODULE),
    ?INFO_LOG("robot_new_server start"),
    [{_, StartNum}, {Time, Num}, {LoopTime, LoopNum}, LimitNum] = misc_cfg:get_misc_cfg(robot_refresh),
    erlang:send_after(10 * 1000, ?MODULE, {'CREATE_ROBOT', 0, 500}),
%%    erlang:send_after(Time * 60 * 1000, ?MODULE, {'CREATE_ROBOT', 0, Num}),
%%    erlang:send_after(LoopTime * 60 * 1000, ?MODULE, {'CREATE_LOOP_ROBOT', 0, LoopNum, LoopTime}),
    {ok, #robot_new_state{limit_num = 1000}}.

handle_call({'GET_ROBOT_ID_LIST'}, _From, #robot_new_state{robot_id = RobotId, delete_id_list = DeleteIdList} = State) ->
    RetList = case RobotId of
        0 ->
            [];
        _ ->
            lists:filter(
                fun(Id) ->
                    not lists:member(Id, DeleteIdList)
                end,
                lists:seq(1, RobotId - 1)
            )
    end,
    {reply, RetList, State};
handle_call({'GET_ROBOT_STATE'}, _From, #robot_new_state{robot_state_list = RobotStateList} = State) ->
    {reply, RobotStateList, State};
handle_call({'GET_ONLINE_ROBOT_NUM'}, _From, #robot_new_state{robot_state_list = RobotStateList} = State) ->
    Num = length([{Id, Name, Lev, RobotState} || {Id, Name, Lev, RobotState} <- RobotStateList, RobotState =/= off_line]),
    {reply, Num, State};
handle_call(_Request, _From, State) ->
    ?ERROR_LOG("receive unknown call msg:~p", [_Request]),
    {reply, ok, State}.

handle_cast({'CREATE_ROBOT'}, #robot_new_state{robot_id = RobotId, all_robot_num = AllNum, limit_num = LimitNum} = State) ->
    {NewRobotId, NewNum} = case AllNum < LimitNum of
        true ->
            player_sup:start_child({robot_socket, RobotId + 1}),
            {RobotId + 1, AllNum + 1};
        _ ->
            {RobotId, AllNum}
    end,
    {noreply, State#robot_new_state{robot_id = NewRobotId, all_robot_num = NewNum}};
handle_cast({'ROBOT_DELETE', RobotId}, #robot_new_state{all_robot_num = AllNum, delete_id_list = DeleteIdList} = State) ->
    NewState = State#robot_new_state{all_robot_num = max(0, AllNum - 1), delete_id_list = [RobotId | DeleteIdList]},
    {noreply, NewState};
handle_cast({'GET_ROBOT_SERVER_STATE'}, State) ->
    ?DEBUG_LOG("robot_state:~p", [State]),
    {noreply, State};
handle_cast({'CHANGE_ROBOT_STATE', RobotId, Name, Lev, RobotState}, #robot_new_state{robot_state_list = RobotStateList} = State) ->
    NewList = lists:keystore(RobotId, 1, RobotStateList, {RobotId, Name, Lev, RobotState}),
    NewState = State#robot_new_state{robot_state_list = NewList},
    {noreply, NewState};
handle_cast(_Msg, State) ->
    ?ERROR_LOG("receive unknown cast msg:~p", [_Msg]),
    {noreply, State}.

handle_info({'ROBOT_ONLINE', RobotId}, State) ->
    player_sup:start_child({robot_socket, RobotId}),
    {noreply, State};
handle_info({'CREATE_ROBOT', Min, Max}, #robot_new_state{robot_id = RobotId, all_robot_num = AllNum, limit_num = LimitNum} = State) ->
    {NewRobotId, NewNum} = case Min =/= Max andalso AllNum < LimitNum of
        true ->
            player_sup:start_child({robot_socket, RobotId + 1}),
            erlang:send_after(1 * 1000, ?MODULE, {'CREATE_ROBOT', Min + 1, Max}),
            {RobotId + 1, AllNum + 1};
        _ ->
            {RobotId, AllNum}
    end,
    {noreply, State#robot_new_state{robot_id = NewRobotId, all_robot_num = NewNum}};
handle_info({'CREATE_LOOP_ROBOT', Min, Max, NextTime}, #robot_new_state{robot_id = RobotId, all_robot_num = AllNum, limit_num = LimitNum} = State) ->
    {NewRobotId, NewNum} = case Min =/= Max andalso AllNum < LimitNum of
        true ->
            player_sup:start_child({robot_socket, RobotId + 1}),
            erlang:send_after(30 * 1000, ?MODULE, {'CREATE_LOOP_ROBOT', Min + 1, Max, NextTime}),
            {RobotId + 1, AllNum + 1};
        _ ->
            erlang:send_after(NextTime * 60 * 1000, ?MODULE, {'CREATE_LOOP_ROBOT', 0, Max, NextTime}),
            {RobotId, AllNum}
    end,
    {noreply, State#robot_new_state{robot_id = NewRobotId, all_robot_num = NewNum}};
handle_info(_Info, State) ->
    ?ERROR_LOG("receive unknown info msg:~p", [_Info]),
    {noreply, State}.

terminate(_Reason, _State) ->
    ?INFO_LOG("process shutdown with reason = ~p", [_Reason]),
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% =====================================================================
%% private
%% =====================================================================