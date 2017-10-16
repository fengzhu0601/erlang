%%%-------------------------------------------------------------------
%%% @author fengzhu
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 03. 十二月 2016 上午10:36
%%%-------------------------------------------------------------------
-module(daily_activity_service).
-author("fengzhu").

-include("inc.hrl").
-include("daily_struct.hrl").

-behaviour(gen_server).

%% API
-export([start_link/1
        , get_not_full_fishing_room/0
        , is_fishing_room/1
        , get_fishing_id_info/0
        , call_enter_fishing_room/2
        , call_leave_fishing_room/2
]).

%% gen_server callbacks
-export([init/1,
    handle_call/3,
    handle_cast/2,
    handle_info/2,
    terminate/2,
    code_change/3]).

-define(SERVER, ?MODULE).

-record(state, {id}).

%%%===================================================================
%%% API
%%%===================================================================

start_link(Id) ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [Id], []).

get_fishing_id_info() ->
    try
        gen_server:call(?MODULE, {'GET_FISHING_ID_INFO'}, 5000)
    of
        Id ->
            Id
    catch
        _E:_W ->
            ?ERROR_LOG("------get_fishing_id_info---timeout------"),
            1
    end.

init([Id]) ->
    ets_new(),
    {ok, #state{id = Id}}.

handle_call({'GET_FISHING_ID_INFO'}, _From, #state{id = Id} = State) ->
    {reply, Id, State};
handle_call({enter_fishing_room, NewSceneId, PlayerId}, _From, State) ->
    case ets:lookup(?service_fishing_instance, NewSceneId) of
        [] -> ets:insert(?service_fishing_instance,
            #service_fishing_instance{instance_id = NewSceneId,
                player_list = [PlayerId]});
        [ServiceFishingInstance] ->
            PlayerList = ServiceFishingInstance#service_fishing_instance.player_list,
            NewPlayerList = case lists:member(PlayerId, PlayerList) of
                             false -> [PlayerId | PlayerList];
                             _ -> PlayerList
                         end,
            ets:insert(?service_fishing_instance,
                #service_fishing_instance{instance_id = NewSceneId,
                    player_list = NewPlayerList})
    end,
    {reply, ok, State};

handle_call({leave_fishing_room, NewSceneId, PlayerId}, _From, State) ->
    case ets:lookup(?service_fishing_instance, NewSceneId) of
        [] -> ok;
        [ServiceFishingInstance] ->
            PlayerList = lists:delete(PlayerId, ServiceFishingInstance#service_fishing_instance.player_list),
            if
                length(PlayerList) == 0 ->
                    ets:delete(?service_fishing_instance, NewSceneId);
                true ->
                    ets:insert(?service_fishing_instance,
                        #service_fishing_instance{instance_id = NewSceneId,
                            player_list = PlayerList})
            end
    end,
    {reply, ok, State};

handle_call(_Request, _From, State) ->
    {reply, ok, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling cast messages
%%
%% @end
%%--------------------------------------------------------------------
handle_cast(_Request, State) ->
    {noreply, State}.

handle_info(stop_fishing, State) ->
%%    ScenePid ! over_fishing,
    ets:foldl(
        fun(#service_fishing_instance{instance_id= RoomId, player_list = PlayerList}, _Acc) ->
            ?INFO_LOG("PlayerList:~p", [PlayerList]),
            world:send_to_player(PlayerList, ?mod_msg(daily_activity_mng, {fishing_over})),
            case load_cfg_scene:get_pid(RoomId) of
                ?none ->
                    pass;
                ScenePid ->
                    ScenePid ! {'@stop@', ?normal}
            end
        end,
        [],
        ?service_fishing_instance
    ),
    {stop, normal, State};

handle_info(_Info, State) ->
    {noreply, State}.

-spec(terminate(Reason :: (normal | shutdown | {shutdown, term()} | term()),
    State :: #state{}) -> term()).
terminate(_Reason, _State) ->
    ok.

-spec(code_change(OldVsn :: term() | {down, term()}, State :: #state{},
    Extra :: term()) ->
    {ok, NewState :: #state{}} | {error, Reason :: term()}).
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% 获取未满房间列表
get_not_full_fishing_room() ->
    ets:foldl(
        fun(#service_fishing_instance{instance_id= RoomId, player_list = PlayerList}, Acc) ->
            if
                erlang:length(PlayerList) =< ?FISH_ROOM_MAX_PLAYER_COUNT ->
                    [RoomId | Acc];
                true ->
                    Acc
            end
        end,
        [],
        ?service_fishing_instance
    ).

ets_new() ->
    ets:new(?service_fishing_instance, [?named_table, ?public, {keypos, #service_fishing_instance.instance_id}, {?read_concurrency, ?true}, {?write_concurrency, ?true}]).

is_fishing_room(RoomId) ->
    %% 活动未开ets表不存在
    case ets:info(?service_fishing_instance) of
        undefined ->
            false;
        _ ->
            ets:member(?service_fishing_instance, RoomId)
    end.

call_enter_fishing_room(SceneId, PlayerId) ->
    try
        gen_server:call(?MODULE, {enter_fishing_room, SceneId, PlayerId}, 5000)
    of
        _ ->
            pass
    catch
        _E:_W ->
            ?ERROR_LOG("------enter_fishing_room---timeout------")
    end.

call_leave_fishing_room(SceneId, PlayerId) ->
    try
        gen_server:call(?MODULE, {leave_fishing_room, SceneId, PlayerId},5000)
    of
        _ ->
            pass
    catch
        _E:_W ->
            ?ERROR_LOG("------leave_fishing_room---timeout------")
    end.
