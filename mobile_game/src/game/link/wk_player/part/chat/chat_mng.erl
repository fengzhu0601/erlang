-module(chat_mng).

-include("inc.hrl").
-include("player.hrl").
-include("handle_client.hrl").
-include("system_log.hrl").
-include("team.hrl").
-include("team_struct.hrl").

-export
([
    chat_sys_p2p_friend/2,
    chat_sys_broadcast/1,
    pack_chat_system/1,
    system_broadcast/1,
    send_team_world_msg/2,
    send_msg/3,
    pack_chat_broadcast/5
]).

-define(CHAT_LEV_LIMIT, 15).        %% 聊天等级限制
-define(CHAT_HORN_LEV_LIMIT, 15).   %% 小喇叭聊天等级限制
-define(CHAT_LEN_LIMIT, 64).        %% 聊天长度限制

-define(HORN_ID, 2006).        %% 喇叭的物品id

chat_sys_p2p_friend(ToId, {FromId, Msg}) ->
    %?DEBUG_LOG("FromId----:~p----Msg----:~p",[FromId, Msg]),
    %?DEBUG_LOG("chat_sys_p2p_friend-------------------------------:~p",[pack_chat_sys_p2p_friend({FromId, Msg})]),
    world:send_to_player_if_online(ToId, pack_chat_sys_p2p_friend({FromId, Msg})).
    %%  msg_service:send_msg(ToId, pack_chat_sys_p2p_friend({FromId, Msg})).

chat_sys_broadcast(Msg) ->
    world:broadcast2(?to_client_msg(chat_sproto:pkg_msg(?MSG_CHAT_SYSTEM, {Msg}))).

system_broadcast(Msg) ->
    world:broadcast(?to_client_msg(chat_sproto:pkg_msg(?MSG_CHAT_SYSTEM, {Msg}))).

send_team_world_msg(Type, Msg) ->
    Title = get(?pd_attr_cur_title),
    world:broadcast(pack_chat_broadcast(?CHAT_WORLD, Title, Msg, Type, 0)).

handle_client({Pack, Arg}) ->
    handle_client(Pack, Arg).

handle_client(?MSG_CHAT_P2P, {ToId, Channel, Msg, Type, Duration}) ->
    Lev = get(?pd_level),
    IsLen = is_len_limit(Msg, ?CHAT_LEN_LIMIT),
    case title_service:is_player_status(2, get(?pd_id)) of
        ?false ->
            Lvl = misc_cfg:get_chat_lev_limit(),
            case is_time_limit(get(?pd_client_p2p_chat), 10) of
                %% false when Lev >= ?CHAT_LEV_LIMIT, IsLen ->
                false when Lev >= Lvl, IsLen ->
                    %% todo 添加语音
                    put(?pd_client_p2p_chat, com_time:now()),
                    %%world:send_to_player_if_online(ToId, pack_chat_p2p(Channel, Msg));
                    %% 发送聊天日志
                    Title = get(?pd_attr_cur_title),
                    system_log:info_player_chat_log(Channel, Msg),
                    msg_service:send_msg(ToId, pack_chat_p2p(Channel, Title, Msg, Type, Duration));
                true ->
                    ?debug_log_chat(" time not cool!"),
                    ok;
                _ ->
                    ?debug_log_chat(" lev (~w) need ~w, len out ~w !", [Lev, misc_cfg:get_chat_lev_limit(), ?CHAT_LEN_LIMIT]),
                    ok
            end;
        ?true ->
            world:send_to_player(get(?pd_id), ?to_client_msg(chat_sproto:pkg_msg(?MSG_CHAT_SYSTEM, {<<"you is shut up">>})))
    end;


handle_client(?MSG_CHAT_GROUP, {Channel, Msg, Type, Duration}) ->
    PlayerId = get(?pd_id),
    Lev = get(?pd_level),
    IsLen = is_len_limit(Msg, ?CHAT_LEN_LIMIT),
    ?INFO_LOG("is_player_status:~p",[title_service:is_player_status(2, PlayerId)]),
    case title_service:is_player_status(2, PlayerId) of
        ?false ->
            Lvl = misc_cfg:get_chat_lev_limit(),
            LvlHorn = misc_cfg:get_chat_horw_lev_limit(),
            Title = get(?pd_attr_cur_title),
            case is_time_limit(get(?pd_client_chat), 10) of
                ?false when Lev >= Lvl, IsLen ->
                    put(?pd_client_chat, com_time:now()),
                    system_log:info_player_chat_log(Channel, Msg),
                    %% todo 添加语音
                    case Channel of
                        ?CHAT_WORLD ->
                            world:broadcast(pack_chat_broadcast(Channel, Title, Msg, Type, Duration));
                        ?CHAT_SCENE ->
                            scene_mng:send_msg({broadcast, pack_chat_broadcast(Channel, Title, Msg, Type, Duration)});
                        ?CHAT_HORN when Lev >= LvlHorn ->
                            case game_res:try_del([{?HORN_ID, 1}], ?FLOW_REASON_CHAT) of
                                ok ->
                                    world:broadcast(pack_chat_broadcast(Channel, Title, Msg, Type, Duration));
                                _E ->
                                    ?debug_log_chat("horn fail ~w", [_E]),
                                    ok
                            end;
                        ?CHAT_TEAM ->
                            team_mng:broadcast(pack_chat_broadcast(Channel, Title, Msg, Type, Duration));
                        ?CHAT_GUILD ->
                            guild_mng:broadcast(pack_chat_broadcast(Channel, Title, Msg, Type, Duration));
                        ?CHAT_HORN ->
                            ?debug_log_chat(" horn lev (~w) need ~w", [Lev, LvlHorn]),
                            ok;
                        _U ->
                            ?ERROR_LOG("player unknown chat channel ~w", [_U])
                    end;
                ?true ->
                    ?debug_log_chat(" time not cool!"),
                    ok;
                _E ->
                    ?debug_log_chat(" lev (~w) need ~w, len out ~w !", [Lev, Lvl, LvlHorn]),
                    ok
            end;
        ?true ->
            world:send_to_player(PlayerId, ?to_client_msg(chat_sproto:pkg_msg(?MSG_CHAT_SYSTEM, {<<"you is shut up">>})))
    end;

handle_client(?MSG_CHAT_SYSTEM, {Msg}) ->
    case title_service:is_player_status(2, get(?pd_id)) of
        ?false ->
            ?DEBUG_LOG("chat_mng false ---------------------------"),
            world:broadcast2(?to_client_msg(chat_sproto:pkg_msg(?MSG_CHAT_SYSTEM, {Msg})));
        ?true ->
            world:send_to_player(get(?pd_id), ?to_client_msg(chat_sproto:pkg_msg(?MSG_CHAT_SYSTEM, {<<"you is shut up">>})))
    end;


handle_client(_Mod, _Msg) ->
    {error, unknown_msg}.

% is_time_limit(OldTimeOut, Int) when is_integer(OldTimeOut) ->
%     %?ERROR_LOG("old~w, Int ~w, Now ~w", [OldTimeOut, Int, com_time:now()]),
%     com_time:now() =< (OldTimeOut + Int);
is_time_limit(_, _) -> ?false.

is_len_limit(Msg, Len) ->
    List = unicode:characters_to_list(Msg),
    length(List) =< Len.
pack_chat_sys_p2p_friend({FromId, Text}) ->
    {FName, FCareer} =
    case player:lookup_info(FromId, [?pd_name, ?pd_career]) of
        [Name, Career] -> 
            {Name, Career};
        _ -> 
            {<<>>, 1}
    end,
    ?to_client_msg(chat_sproto:pkg_msg(?MSG_CHAT_P2P, {
    ?CHAT_P2P_FERIEND_SYS, FromId, FName, FCareer, Text, 1, 0})).

pack_chat_p2p(Channel, Title, Text, Type, Duration ) ->
    ?to_client_msg(chat_sproto:pkg_msg(?MSG_CHAT_P2P, {
    Channel, get(?pd_id), get(?pd_name), get(?pd_career), Title, Text, Type, Duration })).
pack_chat_broadcast(Channel, Title, Text, Type, Duration) ->
    ?to_client_msg(chat_sproto:pkg_msg(?MSG_CHAT_GROUP, {
    Channel, get(?pd_id), get(?pd_name), get(?pd_career), Title, Text, Type, Duration })).

pack_chat_system(Text) ->
    ?to_client_msg(chat_sproto:pkg_msg(?MSG_CHAT_SYSTEM, {Text})).


send_msg(PlayerIdLists, Id, ValList) ->
    ?INFO_LOG("chat_mng broadcast ~p", [{PlayerIdLists, Id, ValList}]),
    Pkg = chat_sproto:pkg_msg(?MSG_CHAT_SYSTEM_EX, {Id, ValList}),
    world:send_to_player_if_online(PlayerIdLists, ?to_client_msg(Pkg)).


