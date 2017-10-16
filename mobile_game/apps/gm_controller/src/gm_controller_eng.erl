-module(gm_controller_eng).
-behaviour(gen_server).

%% Module Interface
-export([start_link/1]).
%% gen_server callbacks

-define(mail_mod_msg2(Mod, Msg), {mod, Mod, ?MODULE, Msg}).

-export([init/1,
         handle_call/3,
         handle_cast/2,
         handle_info/2,
         terminate/2,
         code_change/3
        ]).

-export([
    %est/1,
    get_player_id_by_limit/7]).

-record(state, {
        socket
    }).

%% @doc Starts the server
start_link(CSocket) ->
    ok = inet:setopts(CSocket, [binary, {nodelay, true}, {packet, 0}, {active, true}]),
    gen_server:start_link(?MODULE, CSocket, []).

init(CSocket) when is_port(CSocket) ->
    process_flag(trap_exit, true),
    {ok, #state{socket = CSocket}}.

handle_call(_Request, _From, State) ->
    {reply, ok, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.
%% add broadcast    
handle_info({tcp, _Socket, <<1>>}, State) ->
    io:format("gm_controller_eng Data-------:~n"),
    system_broadcast_worker:do_broadcast(),
    {stop, normal, State};
%% send gm prize
handle_info({tcp, _Socket, <<2, Bin/binary>>}, State) ->
    <<TitleSize:16, TitleName:TitleSize/binary, ContentSize:16, Content:ContentSize/binary,
    EndTime:64, ItemListSize:64, B/binary>> = Bin,
    {ItemList, PlayerList} = get_item_and_player_list(B, ItemListSize, []),
    io:format("ItemListSize----------------------:~p~n",[ItemListSize]),
    io:format("ItemList--------------------:~p~n",[ItemList]),
    io:format("PlayerList----------------------:~p~n",[PlayerList]),
    %PlayerList2 =
    case PlayerList of
        [] ->
            %gm_data:get_all_player_id();
            get_player_id_by_limit(1, 1, 500, TitleName, Content, EndTime, ItemList);
        _ ->    
            send_gm_to_players(PlayerList, TitleName, Content, EndTime, ItemList)
    end,
    %io:format("PlayerList2---------------------:~p~n",[lists:sublist(PlayerList2, 3)]),
    %lists:foreach(fun(IntId) ->
    %    world:send_to_player_any_state(IntId,?mail_mod_msg2(mail_mng, {gm_mail, IntId, TitleName, Content, EndTime, ItemList}))
    %end,
    %PlayerList2),
    {stop, normal, State};

%% add freeze player
handle_info({tcp, _Socket, <<3, IsAdd, Bin/binary>>}, State) ->
    <<PlayerSize:64, B2/binary>> = Bin,
    L = get_player_list(B2, PlayerSize, []),
    title_service:update_player_status_list_by_id(1, IsAdd, L),
    {stop, normal, State};


%% add gag player
handle_info({tcp, _Socket, <<4, IsAdd, Bin/binary>>}, State) ->
    <<PlayerSize:64, B2/binary>> = Bin,
    L = get_player_list(B2, PlayerSize, []),
    title_service:update_player_status_list_by_id(2, IsAdd, L),
    {stop, normal, State};

%% add internal player
handle_info({tcp, _Socket, <<5, IsAdd, Bin/binary>>}, State) ->
    <<PlayerSize:64, B2/binary>> = Bin,
    L = get_player_list(B2, PlayerSize, []),
    title_service:update_player_status_list_by_id(3, IsAdd, L),
    {stop, normal, State};

%% 生成cd_key到数据库
handle_info({tcp, _Socket, <<6, Bin/binary>>}, State) ->
    <<Platform:16, Server:16, Duration:16, Sum:16, PrizeId, UseTimes/binary>> = Bin,
    op_player:create_new_cd_key_to_mysql(Platform,Server,Duration,PrizeId, UseTimes,Sum),
    {stop, normal, State};

handle_info({tcp_error, _Socket, _Reason}, _State) ->
    {noreply, _State};

handle_info(_Info, State) ->
    io:format("gm_controller_eng 43 -------------:~p~n",[_Info]),
    {noreply, State}.

%% @spec terminate(Reason, State) -> no_return()
%%       Reason = normal | shutdown | Term
terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

get_item_and_player_list(B, 0, List) ->
    <<PlayerSize:64, B2/binary>> = B,
    L = get_player_list(B2, PlayerSize, []),
    {List, L};
get_item_and_player_list(<<ItemID:32, ItemCount:32, IsBind, B/binary>> = _Bdata, Size, List) ->
    get_item_and_player_list(B, Size - 1, [{ItemID, ItemCount, IsBind}|List]).


 
get_player_list(<<>> ,0, List) ->
    List;
get_player_list(<<PlayerId:64, Res1/binary>> = Res, Size, List) ->
    get_player_list(Res1, Size - 1,[PlayerId | List]);
get_player_list(_A, _B, _C) ->
    io:format("_A---------------------:~p~n",[byte_size(_A)]),
    io:format("_B---------------------:~p~n",[_B]),
    io:format("_C---------------------:~p~n",[_C]),
    [].

to_int(Id) when is_list(Id) ->
    lists:nth(1, Id);
to_int(Id) ->
    Id.


send_gm_to_players(List, TitleName, Content, EndTime, ItemList) ->
    lists:foreach(fun(Id) ->
        IntId = to_int(Id),
        world:send_to_player_any_state(IntId,?mail_mod_msg2(mail_mng, {gm_mail, IntId, TitleName, Content, EndTime, ItemList}))
    end,
    List).


get_player_id_by_limit(1, Offset, Count, TitleName, Content, EndTime, ItemList) ->
    %io:format("Offset----------------------------:~p~n",[Offset]),
    %case gm_data:get_player_id_list(Offset, Count) of
    %    [] ->
    %        io:format("-------------------------------------------------~n"),
    %        pass;
    %    List ->
    %        io:format("List---------------------:~p~n",[Offset]),
    %        send_gm_to_players(List, TitleName, Content, EndTime, ItemList),
    %        get_player_id_by_limit(Offset+Count, Count, TitleName, Content, EndTime, ItemList)
    %end.
    statistics(wall_clock),
    L = gm_data:get_player_id_list(Offset, Count),
    {_, UseTime1} = statistics(wall_clock), %% 毫秒
    io:format("UseTime111111 -------------------------------------is :~p~n",[UseTime1]),
    Can = 
    if
        L =:= [] ->
            0;
        L =:= error ->
            io:format("1-------------------------------------------------~n"),
            0;
        true ->
            1
    end,
    statistics(wall_clock),
    send_gm_to_players(L, TitleName, Content, EndTime, ItemList),
    {_, UseTime} = statistics(wall_clock), %% 毫秒
    io:format("UseTime222--------------------------------- is :~p~n",[UseTime]),
    get_player_id_by_limit(Can, Offset+Count, Count, TitleName, Content, EndTime, ItemList);

get_player_id_by_limit(_, _, _, _, _, _, _) ->
    io:format("2-------------------------------------------------~n").

% test(PlayerList) ->
%     case PlayerList of
%         [] ->
%             gm_data:get_all_player_id();
%         _ ->
%             send_gm_to_players(PlayerList)
%     end.
    %io:format("PlayerList2---------------------:~p~n",[lists:sublist(PlayerList2, 3)]),
