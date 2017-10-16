%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 15. 七月 2015 下午3:28
%%%-------------------------------------------------------------------
-module(account).
-author("clark").

%% API
-export
([
    handle_client/2
    , handle_msg/4
    , init/5
    , init/1
    , uninit/1
    %, login/6
    , create_role/3
    , enter_game/1
    , online_cb/0
    , insert_account/4
    , login_account/4
    , auto_login_account/3
    , login_player/3
    , delete_role/1
    , enter_scene/0
]).


-include("scene.hrl").
-include("inc.hrl").
-include("game.hrl").
-include("player.hrl").
-include("item_bucket.hrl").
-include("player_data_db.hrl").
-include("../../auto/proto/all_mods.inl").
-include("virtual_db.hrl").
-define(cur_account_info, cur_account_info).
-define(pd_init_robot_ontime, pd_init_robot_ontime).



handle_client({tcp, Socket, <<_SendTime:64, ID:16, Data/binary>>}, #connect_state{wait = W} = State) ->
    ?ERROR_LOG("player wait msg ~p but rev other id:~p msg~p, terminate player", [W, ID, {proto_info:to_s(ID), Data}]),
    put(?pd_socket, Socket),
    NewState =
        if
            ID =:= ?MSG_PLAYER_SYS_TIME ->
                Now = com_time:timestamp_sec(),
                ?player_send(player_sproto:pkg_msg(?MSG_PLAYER_SYS_TIME, {Now})),
                State;
            ID =:= ?MSG_PLAYER_PING ->
                ?player_send(player_sproto:pkg_msg(?MSG_PLAYER_PING, {})),
                State;
            ID =:= ?MSG_VERSION ->
                VersionModID = ID bsr 8,
                {_, VrsSprotoMod} = get_proto_mod(VersionModID),
                {ParTuple, <<>>} = VrsSprotoMod:unpkg_msg(ID, Data),
                ?NODE_INFO_LOG("version ~p", [ParTuple]),
                version:check_version(ParTuple),
                State; %%!!!后面进入场景时没有版本验证结果的， 要把人T掉。
            W =:= ?undefined ->
                % put(flowId,ID),
                State;
            true ->
                case lists:member(ID, W) of
                    true ->
                        State#connect_state{wait = ?undefined, name = <<"player">>};
                    false ->
                        ?ERROR_LOG("player wait msg ~p but rev other id:~p msg~p, terminate player", [W, ID, {proto_info:to_s(ID), Data}]),
                        ?player_send(player_sproto:pkg_msg(?MSG_PLAYER_RECONNECTION, {0})),
                        ?wait_msg_unmatch
                end
        end,

    ModId = ID bsr 8,
    if NewState =/= ?wait_msg_unmatch ->
        case get_proto_mod(ModId) of
            nil ->
                {noreply, NewState, player_eng:get_next_timeout()};
            {Mod, SprotoMod} ->
                % case Mod =:= scene_mng andalso ID =:= 534 orelse Mod =:= scene_mng andalso ID =:= 535 orelse Mod =:= scene_mng andalso ID =:= 536 orelse
                %     Mod =:= player_handle_client andalso ID =:= 306 of
                %     true -> pass;
                %     _ -> ?DEBUG_LOG("PlayerId:~p, Mod:~p, VrsSprotoModtoMod:~p, Id:~p", [get(?pd_id), Mod, SprotoMod, ID])
                % end,
                case catch SprotoMod:unpkg_msg(ID, Data) of
                    {'EXIT', E} ->
                        ?DEBUG_LOG("unpkg proto:~p data: ~p EXIT error:~p", [SprotoMod:to_s(ID), Data, E]),
                        {noreply, NewState, player_eng:get_next_timeout()};
                    {Tuple, <<>>} ->
                        case catch Mod:handle_client({ID, Tuple}) of
                            {error, E} ->
                                err_info:handle_client_error(E, SprotoMod, ID, Tuple),
                                {noreply, NewState, player_eng:get_next_timeout()};
                            {'@offline@', Reason} ->
                                ?NODE_INFO_LOG("offline reason ~p", [Reason]),
                                {stop, ?normal, NewState};
                            {'@wait_msg@', Msg, Timeout} ->
                                {noreply, NewState#connect_state{wait = [Msg]}, Timeout};
                            {'EXIT', E} ->
                                player_log_service:add_crash_log(get(?pd_id), get(?pd_name), E),
                                case E of
                                    {{badmatch, _}, _} ->
                                        case erase(?pd_defer_badmath) of
                                            ?undefined ->
                                                ?NODE_ERROR_LOG("handle ~p p ~p EXIT ~p", [SprotoMod:to_s(ID), Data, E]),
                                                {stop, crash, NewState};
                                            Fn ->
                                                Fn(),
                                                {noreply, NewState, player_eng:get_next_timeout()}
                                        end;
                                    _ ->
                                        ?NODE_INFO_LOG("handle ~p p ~p EXIT ~p", [SprotoMod:to_s(ID), Data, E]),
                                        {stop, crash, NewState}
                                end;
                            _ ->
                                {noreply, NewState, player_eng:get_next_timeout()}
                        end;
                    {_, Remain} ->
                        ?NODE_INFO_LOG("pkg proto ~p but has remain ~p all data~p", [SprotoMod:to_s(ID), Remain, Data]),
                        {noreply, NewState, player_eng:get_next_timeout()}
                end
        end;
        true ->
            {stop, ?wait_msg_unmatch, State}
    end.

handle_msg(Mod, From, Msg, State) ->
    %?assertNotEqual(?undefined, get(?pd_init_completed)),
    %% 在offline之后，就不再接收消息了。
%%     ?INFO_LOG("=================== account ~p", [{Mod, From, Msg}]),
    case Mod:handle_msg(From, Msg) of
        {'@offline@', _Reason} ->
            {stop, ?normal, State};
        {error, What} ->
            ?ERROR_LOG("handle_msg mod ~p ~p from ~p ~p", [Mod, Msg, From, What]),
            {noreply, State, player_eng:get_next_timeout()};
        _ ->
            {noreply, State, player_eng:get_next_timeout()}
    end.


%% @doc player gen_server:init 最后会调用此函数
init(Node, Socket, IP_Address, Port, Pid) ->
    com_process:init_type(?MODULE),
    erlang:put(?pd_gateway_node_addr, Node),
    erlang:put(?pd_socket, Socket),
    IP_Address1 = util:ip_to_str(IP_Address),
    erlang:put(?pd_account_ip, IP_Address1),
    erlang:put(?pd_account_port, Port),
    erlang:put(?pd_gateway_node_pid, Pid),
    % 之前是一个协议版本号，因为要处理多渠道登陆，变成list处理
    % 模块返回还是一个协议版本号, 在状态哪里变成list处理了
    % code : NewState#connect_state{wait = [Msg]}
    {'@wait_msg@', [?MSG_PLAYER_ACCOUNT_LOGIN, ?MSG_PLAYER_QQ_AUTH_LOGIN, ?MSG_PLAYER_RECONNECTION]}.

init(CSocket) ->
    com_process:init_type(?MODULE),
    erlang:put(?pd_socket, CSocket),
    {ok, {IP_Address, Port}} = inet:peername(CSocket),
    IP_Address1 = util:ip_to_str(IP_Address),
    erlang:put(?pd_account_ip, IP_Address1),
    erlang:put(?pd_account_port, Port),
    {'@wait_msg@', [?MSG_PLAYER_ACCOUNT_LOGIN, ?MSG_PLAYER_QQ_AUTH_LOGIN, ?MSG_PLAYER_RECONNECTION]}.


%% @doc 玩家下线是调用,uninit 函数返回后本player 进程将会终结
uninit(Action) ->
    ?NODE_INFO_LOG("uninit ~ts", [?pname()]),
    CurAccountInfo = get(?cur_account_info),

    case erase(?pd_init_completed) of
        ?undefined ->
            ?debug_log_player("player ~p offline but not init compelete", [?pname()]);
        _ ->
            case get(?pd_alread_offline) of
                ?undefined ->
                    ?pd_new(?pd_alread_offline, true),
                    AccountName = CurAccountInfo#account_tab.account_name,
                    dbcache:update(?account_tab, CurAccountInfo),
                    scene_mng:leave_scene(),

                    PlayerId = get(?pd_id),
                    world:leave_world(),
                    world:del_online_account(AccountName),
                    player_mods_manager:offline(PlayerId),
                    case Action of
                        ?TRUE ->
                            player_mods_manager:save_data(PlayerId);
                        ?FALSE ->
                            ok
                    end,
                    ?debug_log_player("player ~ts offline", [?pname()]);
                true ->
                    ?WARN_LOG("is alreay offline")
            end
    end,
    ok.


login_account(PlatformPlayerName, PassWord, _PlatformId1, _ServerId1) ->
    world:is_online_account_to_kick_account_and_player(PlatformPlayerName),
    %?ifdo(world:is_online_account_to_kick_account_and_player(PlatformPlayerName),
    %    ?return_err(?ERR_ACCOUNT_ONLY_JOIN_ONE)),

    #{platform_id := PlatformId, id := ServerId} = global_data:get_server_info(),
    erlang:put(?pd_platform_id, PlatformId),
    erlang:put(?pd_server_id, ServerId),

    %% 需保留IsCheckAccount 到时外网出BUG时， 可以改这里然后直接拿外网的帐号在本地用
    %?DEBUG_LOG("Pd--1----------------------:~p", [PassWord]),
    %Pd = list_to_atom(binary:bin_to_list(PassWord)),  %% 内部测试密码匹配的是Pd密码，正常流程密码匹配的是PassWord
    %?DEBUG_LOG("Pd--2----------------------:~p",[Pd]),
    UsrKey = PlatformPlayerName,
    %?DEBUG_LOG("UsrKey----------------------:~p",[UsrKey]),
    erlang:put(?pd_user_id, UsrKey),
    erlang:put(?pd_user_id_log, <<PlatformPlayerName/binary>>),
    case virtual_db:lookup(?quick_db, ?account_tab, UsrKey, 0) of
        [] ->
            system_log:info_load_progress(1),
            UsrKey = PlatformPlayerName,
            put(?pd_user_id, UsrKey),
            NewPassWorld = PassWord,
            At = #account_tab{account_name = UsrKey,
                platform_id = PlatformId, create_time = com_time:now(), password = NewPassWorld},
            virtual_db:insert_new(?quick_db, ?account_tab, At,
                ?make_record_fields(account_tab)),
            op_player:create_account_to_mysql(UsrKey, NewPassWorld, PlatformId),
            global_data:update_account_count(),
            put(?cur_account_info, At),
            ?DEBUG_LOG("login_account---------------------------------1"),
            world:add_online_account(UsrKey, get(?pd_socket)),
            ?player_send_err(?MSG_PLAYER_ACCOUNT_LOGIN, ?ERR_ROLE_NOT_EXIST),
            system_log:info_account_login(com_time:now());
            % ?return_err(?ERR_ACCOUNT_PASSWORD);
        [#account_tab{player_id = [], password = PassWord, create_time = CreateTime} = OldAt] ->
            put(?cur_account_info, OldAt),
            world:add_online_account(UsrKey, get(?pd_socket)),
            ?player_send_err(?MSG_PLAYER_ACCOUNT_LOGIN, ?ERR_ROLE_NOT_EXIST),
            system_log:info_account_login(CreateTime);

        [#account_tab{player_id = List, password = PassWord, player_statue = PlayerStatue, create_time = CreateTime} = OldAt] ->
            {NewNum, NewBin, NewList} =
                lists:foldl(fun({Index, PlayerId}, {Num, Bin, List2}) ->
                    case player:lookup_info(PlayerId, [?pd_career, ?pd_name, ?pd_level]) of
                        [?none] ->
                            {Num, Bin, lists:keydelete(Index, 1, List2)};
                        [Car, Name, Lev] ->
                            EquipList = api:get_equip_change_list(PlayerId),
                            EquipListBin = lists:foldl(
                                fun(Bid1, Acc) ->
                                        <<Acc/binary, Bid1:32>>
                                end,
                                <<(length(EquipList)):16>>,
                                EquipList
                            ),
                            EftsList = api:get_efts_list(PlayerId),
                            EftsListBin = lists:foldl(
                                fun(Bid2, Acc) ->
                                        <<Acc/binary, Bid2:16>>
                                end,
                                <<(length(EftsList)):16>>,
                                EftsList
                           ),
                            {
                                Num + 1,
                                <<Bin/binary, Index:8, PlayerId:64, (byte_size(Name)), Name/binary, Lev:8, Car:8, EftsListBin/binary, EquipListBin/binary>>,
                                List2
                            }
                    end
                            end,
                    {0, <<>>, List},
                    List),
            NewBin2 = <<NewNum:8, NewBin/binary>>,
            world:add_online_account(UsrKey, get(?pd_socket)),
            put(?cur_account_info, OldAt#account_tab{player_id = NewList}),
            system_log:info_account_login(CreateTime),
            case NewList of
                [] ->
                    ?DEBUG_LOG("login_account---------------------------2"),
                    ?player_send_err(?MSG_PLAYER_ACCOUNT_LOGIN, ?ERR_ROLE_NOT_EXIST);
                _ ->
                    FinalLeaveGameIndex = util:is_on_list(PlayerStatue, NewList),
                    %?DEBUG_LOG("login_account------------FinalLeaveGameIndex---:~p------List------------:~p", [FinalLeaveGameIndex, NewList]),
                    ?player_send(player_sproto:pkg_msg(?MSG_PLAYER_ACCOUNT_LOGIN, {FinalLeaveGameIndex, NewBin2}))
            end;
        _B ->
            ?DEBUG_LOG("login_account---------------------------------3:~p", [_B]),
            ?return_err(?ERR_ACCOUNT_PASSWORD)
    end.

% 自动登陆
auto_login_account(PlatformPlayerName, _PlatformId1, _ServerId1) ->
    world:is_online_account_to_kick_account_and_player(PlatformPlayerName),
    %?ifdo(world:is_online_account_to_kick_account_and_player(PlatformPlayerName),
    %    ?return_err(?ERR_ACCOUNT_ONLY_JOIN_ONE)),

    #{platform_id := PlatformId, id := ServerId} = global_data:get_server_info(),
    erlang:put(?pd_platform_id, PlatformId),
    erlang:put(?pd_server_id, ServerId),

    %% 需保留IsCheckAccount 到时外网出BUG时， 可以改这里然后直接拿外网的帐号在本地用
%%    ?DEBUG_LOG("Pd--1----------------------:~p", [PassWord]),
    %Pd = list_to_atom(binary:bin_to_list(PassWord)),
    %?DEBUG_LOG("Pd--2----------------------:~p",[Pd]),
    UsrKey = PlatformPlayerName,
    %?DEBUG_LOG("UsrKey----------------------:~p",[UsrKey]),
    erlang:put(?pd_user_id, UsrKey),
    erlang:put(?pd_user_id_log, <<PlatformPlayerName/binary>>),
    case virtual_db:lookup(?quick_db, ?account_tab, UsrKey, 0) of
        [#account_tab{player_id = []} = OldAt] ->
            put(?cur_account_info, OldAt),
            world:add_online_account(UsrKey, get(?pd_socket)),
            ?player_send_err(?MSG_PLAYER_ACCOUNT_LOGIN, ?ERR_ROLE_NOT_EXIST);

        [#account_tab{player_id = List, player_statue = PlayerStatue} = OldAt] ->
            {_NewNum, _NewBin, NewList} =
                lists:foldl(fun({Index, PlayerId}, {Num, Bin, List2}) ->
                    case player:lookup_info(PlayerId, [?pd_career, ?pd_name, ?pd_level]) of
                        [?none] ->
                            {Num, Bin, lists:keydelete(Index, 1, List2)};
                        [Car, Name, Lev] ->
                            EquipList = api:get_equip_change_list(PlayerId),
                            EquipListBin = lists:foldl(
                                fun(Bid1, Acc) ->
                                        <<Acc/binary, Bid1:32>>
                                end,
                                <<(length(EquipList)):16>>,
                                EquipList
                            ),
                            EftsList = api:get_efts_list(PlayerId),
                            EftsListBin = lists:foldl(
                                fun(Bid2, Acc) ->
                                        <<Acc/binary, Bid2:16>>
                                end,
                                <<(length(EftsList)):16>>,
                                EftsList
                           ),
                            {
                                Num + 1,
                                <<Bin/binary, Index:8, PlayerId:64, (byte_size(Name)), Name/binary, Lev:8, Car:8, EftsListBin/binary, EquipListBin/binary>>,
                                List2
                            }
                    end
                            end,
                    {0, <<>>, List},
                    List),
%%            NewBin2 = <<NewNum:8, NewBin/binary>>,
            world:add_online_account(UsrKey, get(?pd_socket)),
            put(?cur_account_info, OldAt#account_tab{player_id = NewList}),
            case NewList of
                [] ->
                    ?DEBUG_LOG("login_account---------------------------2"),
                    ?player_send_err(?MSG_PLAYER_ACCOUNT_LOGIN, ?ERR_ROLE_NOT_EXIST);
                _ ->
                    FinalLeaveGameIndex = util:is_on_list(PlayerStatue, NewList),
                    ?DEBUG_LOG("login_account------------FinalLeaveGameIndex---:~p------List------------:~p", [FinalLeaveGameIndex, NewList])
%%                    ?player_send(player_sproto:pkg_msg(?MSG_PLAYER_ACCOUNT_LOGIN, {FinalLeaveGameIndex, NewBin2}))
            end;
        _B ->
            ?DEBUG_LOG("login_account---------------------------------3"),
            ?return_err(?ERR_ACCOUNT_PASSWORD)
    end.

login_player(Index, _Vx, _Vy) ->
    CurAccountInfo = get(?cur_account_info),
    %?DEBUG_LOG("CurAccountInfo----------------------:~p",[CurAccountInfo]),
    AccountName = CurAccountInfo#account_tab.account_name,
    %case world:is_online_account(AccountName) of
    %?false ->
    case lists:keyfind(Index, 1, CurAccountInfo#account_tab.player_id) of
        ?false ->
            pass;
        {_, PlayerId} ->
            ?ifdo(world:is_player_online(PlayerId), world:kick_out_player(PlayerId)),
            % 查发全局表看玩家进程是否创建完毕
            case dbcache:lookup(?player_tab, PlayerId) of
                [] ->
                    %erlang:put(?pd_id, PlayerId),
                    ?player_send_err(?MSG_PLAYER_JOIN_GAME, ?ERR_ROLE_NOT_EXIST),
                    {'@wait_msg@', ?MSG_PLAYER_CREATE_ROLE, ?ONLINE_TIMEOUT};

                [_P] ->
                    case title_service:is_freeze(1, PlayerId) of
                        ?false ->
                            account:enter_game(PlayerId),
                            put(?cur_account_info, CurAccountInfo#account_tab{player_statue = Index}),
                            world:update_online_account(AccountName, get(?pd_socket), PlayerId);
                        _ ->
                            ?return_err(?ERR_PLAYER_FREEZE)
                    end
            end
    end.




insert_account(UsrKey, NewPlayerId, PlatformId, NewPassWorld) ->
    virtual_db:insert_new(?quick_db, ?account_tab, #account_tab{
        account_name = UsrKey,
        player_id = [{UsrKey, NewPlayerId}], %% todo   UsrKey   
        platform_id = PlatformId,
        create_time = com_time:now(),
        password = NewPassWorld},
        ?make_record_fields(account_tab)),
    op_player:create_account_to_mysql(UsrKey, NewPassWorld, PlatformId).
    % op_player:create_account_to_mysql(UsrKey, NewPassWorld, PlatformId, NewPlayerId).


delete_role(Index) when Index >= 1, Index =< 3 ->
    CurAccountInfo = get(?cur_account_info),
    List = CurAccountInfo#account_tab.player_id,
    {DeleteId, NewList} = case lists:keyfind(Index, 1, List) of
                              {Index, Id} ->
                                  {Id, lists:keydelete(Index, 1, List)};
                              _ ->
                                  {0, List}
                          end,
    NewAccountInfo = case NewList of
                         [] ->
                             CurAccountInfo#account_tab{player_id = NewList, player_statue = 0};
                         _ ->
                             {State, _} = lists:nth(1, NewList),
                             CurAccountInfo#account_tab{player_id = NewList, player_statue = State}
                     end,
    put(?cur_account_info, NewAccountInfo),
    dbcache:update(?account_tab, NewAccountInfo),
    case player:lookup_info(DeleteId, [?pd_name, ?pd_career, ?pd_level]) of
        [?none] ->
            ignore;
        [Name, Career, Lev] ->
            system_log:info_delete_role(DeleteId, Name, Career, Lev),
            dbcache:delete(?player_name_tab, Name)
    end,
    ?player_send(player_sproto:pkg_msg(?MSG_PLAYER_DELETE, {1}));
delete_role(_Index) ->
    ?ERROR_LOG("_Index-------------------------:~p", [_Index]),
    ?player_send(player_sproto:pkg_msg(?MSG_PLAYER_DELETE, {0})).


create_role(Index, JobAndIsOpen, Name) ->
    system_log:info_load_progress(2),
    <<IsOpen:1, Career:7>> = <<JobAndIsOpen>>,
    attr_new:set(?pd_task_is_open, IsOpen),
    ?NODE_INFO_LOG("create_role ~w ~ts", [Career, Name]),
    %% Id判断
    %%PlayerId = get(?pd_id),
    %%?assert(PlayerId =/= ?undefined),

    %% 职业判断
    ?ifdo(not player_def:is_valid_career(Career),
        ?return_err({invalid_carrer, Career})
    ),

    %% 非法字符判断
    ?ifdo(dirty_chars:is_has_dirty_chars(Name),
        ?debug_log_player("role name not illegal"),
        ?player_send_err(?MSG_PLAYER_CREATE_ROLE, ?ERR_ROLE_NAME_NOT_ILLEGAL),
        ?return({'@wait_msg@', ?MSG_PLAYER_CREATE_ROLE, ?ONLINE_TIMEOUT})
    ),

    PlatformId = erlang:get(?pd_platform_id),
    ServerId = erlang:get(?pd_server_id),

    CurAccountInfo = get(?cur_account_info),

    List = CurAccountInfo#account_tab.player_id,
    PlayerJoinId =
        case lists:keyfind(Index, 1, List) of
            false ->
                NewPlayerId = tool:make_player_id(PlatformId, ServerId, gen_id:next_id(?player_tab)),
                PlayerTuple = {Index, NewPlayerId},
                NewTuple = [PlayerTuple | List],
                NewAccountInfo = CurAccountInfo#account_tab{player_id = NewTuple, player_statue = Index},
                put(?cur_account_info, NewAccountInfo),
                AccountName = CurAccountInfo#account_tab.account_name,
                op_player:update_account(NewTuple, AccountName),
                dbcache:update(?account_tab, NewAccountInfo),
                NewPlayerId;
            {_, CurPlayerId} ->
                ?ifdo(world:is_player_online(CurPlayerId), world:kick_out_player(CurPlayerId)),
                CurPlayerId
        end,
    put(?pd_id, PlayerJoinId),
    case platfrom:register_name(Name, PlayerJoinId) of
        ?alreay_exist ->
            ?player_send_err(?MSG_PLAYER_CREATE_ROLE, ?ERR_ROLE_NAME_ALREAY_EXIST),
            ?debug_log_player("role name already exist"),
            {'@wait_msg@', ?MSG_PLAYER_CREATE_ROLE, ?ONLINE_TIMEOUT};
        ok ->
            ?pd_new(?pd_name, Name),
            ?pd_new(?pd_career, Career),
            system_log:info_load_progress(3),
            system_log:info_load_progress(4),
            player_mods_manager:create_mods(PlayerJoinId),
            op_player:create_player_to_mysql(PlayerJoinId, Name, Career),
            global_data:update_player_count(),
            put(pd_create_time, com_time:now()),
            system_log:info_create_role(PlayerJoinId),
            ?player_send(player_sproto:pkg_msg(?MSG_PLAYER_CREATE_ROLE, {}))
    end.


% %% 注册名字
% case platfrom:register_name(PlayerId, Name) of
%     ?alreay_exist ->
%         ?player_send_err(?MSG_PLAYER_CREATE_ROLE, ?ERR_ROLE_NAME_ALREAY_EXIST),
%         ?debug_log_player("role name already exist"),
%         {'@wait_msg@', ?MSG_PLAYER_CREATE_ROLE, ?ONLINE_TIMEOUT};
%     ok ->
%         system_log:info_load_progress(3),
%         system_log:info_load_progress(4),
%         PlayerId = erlang:erase(?pd_id),
%         ?pd_new(?pd_name, Name),
%         ?pd_new(?pd_career, Career),
%         player_mods_manager:create_mods(PlayerId),
%         op_player:create_player_to_mysql(PlayerId, Name, Career),
%         ?pd_new(?pd_is_first_enter_game, true),
%         ?player_send(player_sproto:pkg_msg(?MSG_PLAYER_CREATE_ROLE, {})),
%         %op_player:save_create_player_count(get(?pd_platform_id),get(?pd_server_id)),
%         global_data:update_player_count(),
%         enter_game(PlayerId, true)
% end.


%% @doc 加载角色，　这时所有player 模块的数据都已创建完成.
%%      但是还没有加载到player process 里
enter_game(PlayerId) ->
    StTime = com_time:timestamp_msec(),
    % case get(?pd_is_first_enter_game) of
    %     ?undefined ->
    %         player_mods_manager:load_eng_mods(PlayerId),
    %         ?pd_new(?pd_is_first_enter_game, false);
    %     _ ->
    %         ok
    % end,
    player_mods_manager:load_eng_mods(PlayerId),
    player_mods_manager:load_logic_mods(PlayerId),
    player_mods_manager:init_client(),
    ?player_send(player_sproto:pkg_msg(?MSG_PLAYER_ONLINE_FINISH, {virtual_time:get_uptime()})),
    erase(?pd_idx),
    erase(?pd_scene_pid),
    erase(?pd_scene_id),
    enter_scene(),
    put(?pd_init_completed, 1),
    world:enter_world(PlayerId),
    % case robot_new:is_robot(PlayerId) of
    %     true -> pass;
    %     _ -> world:enter_world(PlayerId)
    % end,
    %% TODO auto cb will enter first scene ok
    timer_eng:start_tmp_timer_mfa(2000, {?MODULE, online_cb, []}),
    DtTime = com_time:timestamp_msec() - StTime,
    ?NODE_INFO_LOG("player : ~p init over, cost : ~p", [get(?pd_id), DtTime]),
    system_log:info_role_login(PlayerId),
    player_base_data:on_time(),
    ok.

online_cb() ->
    player_mods_manager:online().

enter_scene() ->
    case main_ins_team_mod:get_player_team_id(get(?pd_id)) of
        TeamId when is_integer(TeamId) ->
            case main_ins_team_mod:send_info_and_return_fuben(get(?pd_id), TeamId) of
                error ->
                    {SceneId, SceneCfgId, X, Y} = get_online_enter_scene(),
                    put(?pd_entering_scene, {SceneId, X, Y}),
                    ?player_send(scene_sproto:pkg_msg(?MSG_SCENE_PLAYER_ENTER_REQUEST, {SceneCfgId, X, Y, ?D_R, 0}));
                _ ->
                    ignore
            end;
        _ ->
            {SceneId, SceneCfgId, X, Y} = get_online_enter_scene(),
            % ?DEBUG_LOG("SceneId:~p, SceneCfgId:~p, X:~p, Y:~p", [SceneId, SceneCfgId, X, Y]),
            put(?pd_entering_scene, {SceneId, X, Y}),
            ?player_send(scene_sproto:pkg_msg(?MSG_SCENE_PLAYER_ENTER_REQUEST, {SceneCfgId, X, Y, ?D_R, 0}))
    end.

%%在线进入场景
get_online_enter_scene() ->
    Ret = task_mng_new:get_scene_ins_id(),
    SceneId = case Ret =:= false orelse robot_new:is_robot(get(?pd_id)) =:= true of
        true ->
            case get(?pd_save_scene_id) of
                ?undefined ->
                    load_cfg_scene:get_default_scene_id(get(?pd_career));
                _SceneId ->
                    case load_cfg_scene:get_pid(_SceneId) of
                        ?none ->
                            load_cfg_scene:get_default_scene_id(get(?pd_career));
                        _Ok ->
                            TempSceneCfgId = load_cfg_scene:get_config_id(_SceneId),
                            Level = get(?pd_level),
                                case load_cfg_scene:get_enter_level_limit(TempSceneCfgId) of
                                    L when Level >= L ->
                                        _SceneId;
                                    _ ->
                                        load_cfg_scene:get_default_scene_id(get(?pd_career))
                                end
                        end
            end;
        _ ->
            TempSceneCfgId = load_cfg_scene:get_config_id(Ret),
            Level = get(?pd_level),
            case load_cfg_scene:get_enter_level_limit(TempSceneCfgId) of
                L when Level >= L ->
                    Ret;
                _ ->
                    load_cfg_scene:get_default_scene_id(get(?pd_career))
            end
    end,
    SceneCfgId = load_cfg_scene:get_config_id(SceneId),
    {X, Y} = case {get(?pd_save_x), get(?pd_save_y)} of
        {?undefined, _} ->
            load_cfg_scene:get_default_enter_point(SceneCfgId);
        {_, ?undefined} ->
            load_cfg_scene:get_default_enter_point(SceneCfgId);
        ?DEFAULT_ENTER_POINT ->
            load_cfg_scene:get_default_enter_point(SceneCfgId);
        P ->
            case scene_map:map_is_walkable(load_cfg_scene:get_map_id(SceneCfgId), P) of
                true -> P;
                false -> load_cfg_scene:get_default_enter_point(SceneCfgId)
            end
    end,
    % {Ts, Tx, Ty} = scene_client_mng:tidy_postion(SceneId, X, Y),
    % {X1, Y1} = case scene_map:map_is_walkable(load_cfg_scene:get_map_id(SceneCfgId), {Tx, Ty}) of   %% 此处处理过后的点如果不能进入场景，则改为配置表进入场景时的点
    %     true -> {Tx, Ty};
    %     _ -> load_cfg_scene:get_default_enter_point(SceneCfgId)
    % end,
    % {Ts, SceneCfgId, X1, Y1}.
    {X1, Y1} = case scene_map:map_is_walkable(load_cfg_scene:get_map_id(SceneCfgId), {X, Y}) of   %% 此处处理过后的点如果不能进入场景，则改为配置表进入场景时的点
        true -> {X, Y};
        _ -> load_cfg_scene:get_default_enter_point(SceneCfgId)
    end,
    {SceneId, SceneCfgId, X1, Y1}.



