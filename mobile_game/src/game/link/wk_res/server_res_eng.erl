%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 27. 十一月 2015 下午12:38
%%%-------------------------------------------------------------------
-module(server_res_eng).
-author("clark").


-extends(gen_server_ex).


%% API
-export([
    init/1,
    on_get_uid_prefix/3,
    call_get_uid_prefix/0
]).


-include("event_server.hrl").
-include("load_db_misc.hrl").
-include_lib("common/include/com_log.hrl").


init(_Args) ->
    event_server:sub_call(uid_prefix, {server_res_eng, on_get_uid_prefix}),
    {ok, nil}.


call_get_uid_prefix() ->
    case gen_server:call(?MODULE,{uid_prefix,nil}) of
        {ok, Prefix} ->
            Prefix;
        _Error ->
            {error, _Error}
    end.

on_get_uid_prefix(_TPar, _From, State) ->
    ServerId = my_ets:get(server_id, error),
    Key = load_db_misc:get(?misc_server_res_key, 1),
    if
        Key >= 1000000 ->
            ?call_reply({error, 99999999}, State);
        true ->
            load_db_misc:set(?misc_server_res_key, Key+1),
            ID = ServerId*1000000 + Key,
            ?call_reply({ok, ID}, State)
    end.

