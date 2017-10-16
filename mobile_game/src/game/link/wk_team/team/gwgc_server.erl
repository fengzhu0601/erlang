-module(gwgc_server).
-include("inc.hrl").
-include("game.hrl").

-include("player.hrl").
-include("scene.hrl").
-include("rank.hrl").
-behaviour(gen_server).
-export([start_link/0, init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).


-export([
    sent_gwgc_data_to_client/1,
    update_npc_status/2,
    add_npc_jifen/2,
    add_team_fighting_data/2,
    update_player_to_broadcast_list/2,
    get_team_fighting_data/1,
    update_npc_status_by_teamid/2,
    npc_is_look/2,
    get_npc_status_by_teamid/1
]).


-define(gwgc_info, gwgc_info).
-record(gwgc_info, 
{
    id,
    npc_list=[] %% [{NpcId, Status}]
}).
-define(city_info, city_info).
-record(city_info,
{
   id,
   num=0,  %% 当前城镇对应的所有NPC个数
   count=1 %% 已经刷了多次波
}).
-define(scene_to_city, scene_to_city).
-record(scene_to_city,{
    scene_id,
    city_id
}).


-define(team_fighting_data, team_fighting_data).
-record(team_fighting_data, {
    id,
    data
}).


-define(broadcast_list, broadcast_list).

-record(broadcast_list, {
    type_id=1,
    list
}).


-record(state, {}).


flush_npc_data(List, Count) ->
    lists:foreach(fun(CityId) ->
        case load_cfg_city:get_scene_list_by_city_id(CityId) of
            ?false ->
                pass;
            L ->
                %do_save_city_info(CityId, length(L), Count),
                do_save_scene_to_city(L, CityId),
                CurSceneNpcCount = 
                lists:foldl(fun(SceneId, Total) ->
                    SceneNpcCount = add_data_to_gwgc_info(SceneId, Count),
                    Total + SceneNpcCount
                end,
                0,
                L),
                do_save_city_info(CityId, CurSceneNpcCount, Count)
                %[add_data_to_gwgc_info(SceneId, Count) || SceneId <- L]
        end
    end,
    List).

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

init([]) ->
    init_ets(),

    ?DEBUG_LOG("gwgc_server----------------------------------------"),
    flush_npc_data(com_ets:keys(city_cfg), 1),
    ranking_lib:start_send_after_by_rankname(?ranking_gwgc, gwgc_server, 10),
    {ok, #state{}}.

handle_call({get_npc_status, NpcId, SceneId}, _From, State) ->
    Reply = get_npc_status(NpcId, SceneId),
    {reply, Reply, State};
handle_call(_Request, _From, State) ->
    {reply, ok, State}.

handle_cast(_Request, State) ->
    {reply, ok, State}.

handle_info({is_over, TeamId}, State) ->
    %?DEBUG_LOG("is_over------------------1------------:~p",[ets:info(team_fighting_data, size)]),
    case get_team_fighting_data(TeamId) of
        ?none ->
            pass;
        {NpcId, SceneId} ->
            del_team_fighting_data(TeamId),
            delete_npc(NpcId, SceneId)
    end,
    %?DEBUG_LOG("is_over------------------2------------:~p",[ets:info(team_fighting_data, size)]),
    case team_svr:get_team_pid_by_teamid(TeamId) of
        Pid when is_pid(Pid) ->
            %Pid ! scene_notice_disband;
            pass;
        _E ->
            ?ERROR_LOG("player_eng----------------------------------------:~p",[_E])
    end,
    {noreply, State};

handle_info({reflush_npc_by_city, CityId, Count}, State) ->
    %?DEBUG_LOG("reflush_npc_by_city---------------------------:~p",[CityId]),
    flush_npc_data([CityId], Count+1),
    {noreply, State};

handle_info(test, State) ->
    %?DEBUG_LOG("teat--------------------------------------"),
    {noreply, State};

handle_info(stop_gwgc, State) ->
    case com_time:day_of_the_week() of
        7 ->%% 每周日活动结束后发一次
            {_Size, _, Ranks} = A = ranking_lib:get_rank_order_page(1, 201, ?ranking_gwgc),
            %?DEBUG_LOG("Ranks---------------------------------:~p",[Ranks]),
            lists:foldl(fun({PlayerId, _}, Index) ->
                PrizeId = load_cfg_gwgc:get_gwgc_prize(Index),
                %?DEBUG_LOG("Index-------:~p------PrizeId------:~p",[Index, PrizeId]),
                ItemList = prize:get_itemlist_by_prizeid(PrizeId),
                %?DEBUG_LOG("PlayerId--------------------------:~p",[PlayerId]),
                world:send_to_player_any_state(PlayerId,?mod_msg(mail_mng, {gwgc_mail, PlayerId, ?S_MAIL_GWGC_PRIZE,ItemList})),
                Index + 1
            end,
            1,
            Ranks),
            ranking_lib:reset_rank(17);
        _ ->
            pass
    end,
    team_svr ! {all_team_disband, 3},
    {stop, normal, State};


handle_info(_Info, State) ->
    {noreply, State}.


terminate(_Reason, _State) ->
    %?DEBUG_LOG("gwgc_server-------------------------------------------:~p",[_Reason]),
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% 保存的是，城镇ID对应此城镇包含的主场景
do_save_city_info(CityId, Total, Count) ->
    ets:insert(?city_info, #city_info{id=CityId, num=Total, count=Count}).

%% 映射一个主场景id对应的城镇id
do_save_scene_to_city([], _) ->
    pass;
do_save_scene_to_city([SceneId|T], CityId) ->
    ets:insert(?scene_to_city, #scene_to_city{scene_id=SceneId, city_id=CityId}),
    do_save_scene_to_city(T, CityId).
    

get_city_id_by_sceneid(SceneId) ->
    case ets:lookup(?scene_to_city, SceneId) of
        [] ->
            ?none;
        [#scene_to_city{city_id=CityId}] ->
            CityId
    end.

update_city_info(SceneId) ->
    case get_city_id_by_sceneid(SceneId) of
        ?none ->
            %?DEBUG_LOG("update_city_info----------------------------------1"),
            pass;
        CityId ->
            %?DEBUG_LOG("update_city_info-------------------------------------:~p",[{SceneId, CityId}]),
            case ets:lookup(?city_info, CityId) of
                [] ->
                    %?DEBUG_LOG("update_city_info----------------------------------2"),
                    pass;
                [#city_info{num=Num, count=Count}] when Num < 5 ->
                    ?DEBUG_LOG("update_city_info------------------------------------- count----:~p",[Count]),
                    gwgc_server ! {reflush_npc_by_city, CityId, Count};
                [#city_info{num=Num}=C] ->
                    %?DEBUG_LOG("update_city_info----------------------------------num--:~p",[Num]),
                    ets:insert(?city_info,C#city_info{num=Num-1})
            end
    end.
%% 
add_data_to_gwgc_info(SceneId, Count) ->
    Data = npc:get_npc_data_by_sceneid(SceneId, Count),
    GwgcInfo = #gwgc_info{id=SceneId, npc_list=Data},
    ets:insert(?gwgc_info, GwgcInfo),
    length(Data).

add_team_fighting_data(TeamId, Data) ->
    case ets:lookup(?team_fighting_data, TeamId) of
        [] ->
            ets:insert(?team_fighting_data, #team_fighting_data{id=TeamId, data=Data});
        _ ->
            pass
    end.

del_team_fighting_data(TeamId) ->
    ets:delete(?team_fighting_data, TeamId).

get_team_fighting_data(TeamId) ->
    case ets:lookup(?team_fighting_data, TeamId) of
        [] ->
            ?none;
        [#team_fighting_data{data=Data}] ->
            Data
    end.    

init_ets() ->
    ets:new(?gwgc_info, [public,set,named_table,{keypos, #gwgc_info.id}, {write_concurrency, true}, {read_concurrency, true}]),
    ets:new(?city_info, [public,set,named_table,{keypos, #city_info.id}, {write_concurrency, true}, {read_concurrency, true}]),
    ets:new(?team_fighting_data, [public,set,named_table,{keypos, #team_fighting_data.id}, {write_concurrency, true}, {read_concurrency, true}]),
    ets:new(?scene_to_city, [public,set,named_table,{keypos, #scene_to_city.scene_id}, {write_concurrency, true}, {read_concurrency, true}]),
    ets:new(?broadcast_list, [public,set,named_table,{keypos, #broadcast_list.type_id}, {write_concurrency, true}, {read_concurrency, true}]).


sent_gwgc_data_to_client(SceneId) ->
    case ets:info(?gwgc_info) of
        ?undefined ->
            pass;
        _ ->
            case ets:lookup(?gwgc_info, SceneId) of
                [] ->
                    pass;
                [#gwgc_info{npc_list=List}] ->
                    %?DEBUG_LOG("scene_gwgc List-------------------------------:~p",[List]),
                    ?player_send(scene_sproto:pkg_msg(?MSG_SCENE_MONSTER_GONGCHENG_LIST, {List}))
            end
    end.

update_player_to_broadcast_list(TypeId, 1) ->
    SelfId = get(?pd_id),
    NewList = 
    case ets:lookup(?broadcast_list, TypeId) of
        [] ->
            [SelfId];
        [T] ->
            List = T#broadcast_list.list,
            case lists:member(SelfId, List) of
                ?false ->
                    [SelfId|List];
                _ ->
                    List
            end
    end,
    ets:insert(?broadcast_list, #broadcast_list{type_id=TypeId, list=NewList});

update_player_to_broadcast_list(TypeId, 2) ->
    SelfId = get(?pd_id),
    case ets:lookup(?broadcast_list, TypeId) of
        [] ->
            pass;
        [T] ->
            List = T#broadcast_list.list,
            case lists:member(SelfId, List) of
                ?false ->
                    pass;
                _ ->
                    ets:insert(?broadcast_list, #broadcast_list{type_id=TypeId, list=lists:delete(SelfId, List)})
            end
    end.

broadcast_npc_status(NpcId, SceneId, Status) ->
    %?DEBUG_LOG("broadcast_list-------------------------------:~p",[{NpcId, Status}]),
    IdList = scene_player:get_all_player_ids_by_scene(SceneId),
    %?DEBUG_LOG("IdList-------------------------------:~p",[IdList]),
    Msg = ?to_client_msg(scene_sproto:pkg_msg(?MSG_SCENE_MONSTER_GONGCHENG_DELETE_CHANGE_STATUS, {NpcId, Status})),
    world:send_to_player_if_online(IdList, Msg).

broadcast_npc_del(NpcId, SceneId) ->
    %?DEBUG_LOG("broadcast_npc_del-------------------------------:~p",[NpcId]),
    IdList = scene_player:get_all_player_ids_by_scene(SceneId),
    %?DEBUG_LOG("IdList-------------------------------:~p",[IdList]),
    Msg = ?to_client_msg(scene_sproto:pkg_msg(?MSG_SCENE_MONSTER_GONGCHENG_DELETE, {NpcId})),
    world:send_to_player_if_online(IdList, Msg).


update_npc_status(NpcId, NewStatus) ->
    SceneId = load_cfg_scene:get_config_id(get(?pd_scene_id)),
    case ets:lookup(?gwgc_info, SceneId) of
        [] ->
            pass;
        [#gwgc_info{npc_list=List}] ->
            case lists:keysearch(NpcId, 1, List) of
                ?false ->
                    pass;
                {?value, {_, X, Y, _Status}} ->
                    NewList = lists:keyreplace(NpcId, 1, List, {NpcId, X, Y, NewStatus}),
                    ets:update_element(?gwgc_info, SceneId, {#gwgc_info.npc_list, NewList}),
                    broadcast_npc_status(NpcId, SceneId, NewStatus)
            end
    end.

update_npc_status_by_teamid(TeamId, NewStatus) ->
    case get_team_fighting_data(TeamId) of
        ?none ->
            pass;
        {NpcId, SceneId} ->
            case ets:lookup(?gwgc_info, SceneId) of
                [] ->
                    pass;
                [#gwgc_info{npc_list=List}] ->
                    case lists:keysearch(NpcId, 1, List) of
                        ?false ->
                            pass;
                        {?value, {_, X, Y, _Status}} ->
                            NewList = lists:keyreplace(NpcId, 1, List, {NpcId, X, Y, NewStatus}),
                            ets:update_element(?gwgc_info, SceneId, {#gwgc_info.npc_list, NewList}),
                            broadcast_npc_status(NpcId, SceneId, NewStatus)
                    end
            end
    end.

get_npc_status_by_teamid(TeamId) ->
    case get_team_fighting_data(TeamId) of
        ?none ->
            %?DEBUG_LOG("1-----------------------------------"),
            ?true;
        {NpcId, SceneId} ->
            case ets:lookup(?gwgc_info, SceneId) of
                [] ->
                    %?DEBUG_LOG("2-----------------------------------"),
                    ?true;
                [#gwgc_info{npc_list=List}] ->
                    case lists:keysearch(NpcId, 1, List) of
                        {?value, {_, X, Y, 0}} ->
                            %?DEBUG_LOG("3-----------------------------------"),
                           ?true;
                        _ ->
                            ?false
                    end
            end
    end.


get_npc_status(NpcId, SceneId) ->
    %?DEBUG_LOG("NpcId------:~p-----SceneId----:~p",[NpcId, SceneId]),
    case ets:lookup(?gwgc_info, SceneId) of
        [] ->
            ?false;
        [#gwgc_info{npc_list=List}] ->
            case lists:keysearch(NpcId, 1, List) of
                {?value, {_, _X, _Y, 0}} ->
                    ?true;
                _ ->
                    ?false
            end
    end.

npc_is_look(NpcId, SceneId) ->
    case ets:lookup(?gwgc_info, SceneId) of
        [] ->
            ?false;
        [#gwgc_info{npc_list=List}] ->
            case lists:keysearch(NpcId, 1, List) of
                {?value, {_, _X, _Y, 1}} ->
                    ?true;
                _ ->
                    ?false
            end
    end.

add_npc_jifen(PlayerId, Num) ->
    ranking_lib:update(?ranking_gwgc, PlayerId, Num).

delete_npc(NpcId, SceneId) ->
    case ets:lookup(?gwgc_info, SceneId) of
        [] ->
            pass;
        [#gwgc_info{npc_list=List}] ->
            NewList = lists:keydelete(NpcId, 1, List),
            update_city_info(SceneId),
            broadcast_npc_del(NpcId, SceneId),
            ets:update_element(?gwgc_info, SceneId, {#gwgc_info.npc_list, NewList})
    end.
