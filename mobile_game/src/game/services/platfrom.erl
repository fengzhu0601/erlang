%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 08. 七月 2015 上午2:09
%%%-------------------------------------------------------------------
-module(platfrom).
-author("clark").

%% API
-export
([
    get_user_key/3,
    get_player_id_by_platform_id/1,
    is_same_name/1,
    register_name/2,
    get_player_id_by_name/1
]).


-include("inc.hrl").
-include("player_def.hrl").
-include("player_data_db.hrl").


get_user_key(PlatformId, ServerId, PlatformPlayerName) ->
    list_to_binary(lists:concat([PlatformPlayerName, integer_to_list(PlatformId), 
        integer_to_list(ServerId)])).



-spec get_player_id_by_platform_id(_) -> ?none | player_id().
get_player_id_by_platform_id(UsrKey) ->
    case dbcache:lookup(?player_platform_id_tab, UsrKey) of
        [] -> 
            none;
        [UsrTab] -> 
            UsrTab#player_platform_id_tab.player_id
    end.



%% @doc　玩家注册角色时，注册名字 要保证是player 首次注册
is_same_name(Name) when is_binary(Name) ->
    case dbcache:lookup(?player_name_tab, Name) of
        [#player_name_tab{}] ->
            true;
        _ ->
            false
    end.

register_name(Name, PlayerId) when is_integer(PlayerId), is_binary(Name) ->
    case dbcache:insert_new(?player_name_tab, #player_name_tab{name = Name, id = PlayerId}) of
        ?true ->
            ok;
        ?false ->
            case dbcache:lookup(?player_name_tab, Name) of
                [#player_name_tab{id = PlayerId}] ->
                    ok;
                _ ->
                    ?alreay_exist
            end
    end.


do_get_player_id_by_name(PlayerName) ->
    case dbcache:lookup(?player_name_tab, PlayerName) of
        [] -> none;
        [#player_name_tab{id = Id}] ->
            Id
    end.

get_player_id_by_name(PlayerName) when is_binary(PlayerName) ->
    do_get_player_id_by_name(PlayerName);
get_player_id_by_name(PlayerName) when is_list(PlayerName) ->
    do_get_player_id_by_name(unicode:characters_to_binary(PlayerName)).