%%%-------------------------------------------------------------------
%%% @author zl
%%% @doc 游戏错误信息
%%%      转换错误信息为可读,并发送给前端.
%%%
%%% @end
%%%-------------------------------------------------------------------

-module(err_info).

-include("inc.hrl").
-include("player.hrl").

-export([
    handle_client_error/4
]).

%% Error ::{error, Info} | {error, {MODULE, LINE}, Info}
handle_client_error(Error, SprotoMod, CmdId, Tuple) ->
    case Error of
        {{where, Mod, Line}, Err} ->
            ?ERROR_LOG("handle ~p data: ~p [~p:~p] ~p", [SprotoMod:to_s(CmdId), Tuple, Mod, Line, Err]);
        _ ->
            ?ERROR_LOG("handle ~p data: ~p ~p", [SprotoMod:to_s(CmdId), Tuple, Error]),
            Err = Error
    end,
    send_to_client(Err, CmdId).

send_to_client(ErrorCode, CmdId) when is_integer(ErrorCode) ->
    player_eng:tcp_send(<<?MSG_PLAYER_ERROR:16, CmdId:16, ErrorCode:16>>);

send_to_client(ErrorAtom, CmdId) when is_atom(ErrorAtom) ->
    case err_info_def:err_code_to_i(ErrorAtom) of
        badarg -> ok;
        ErrorCode ->
            player_eng:tcp_send(<<?MSG_PLAYER_ERROR:16, CmdId:16, ErrorCode:16>>)
    end;
send_to_client({Info, _Arg}, CmdId) ->
    send_to_client(Info, CmdId);
send_to_client(_E, CmdId) ->
    ?ERROR_LOG("bad error info ~p ~p", [_E, CmdId]).

%%-spec show(ErrInfo::any()) -> any().
%%show({?none_cfg, __TableName, __Id}) ->
%%Msg = erlang:iolist_to_binary(io:format("在 ~ts 配置表中没有找到 Id ~p",[__TableName, __Id])),
%%?player_send(debug_proto:pkg_msg(?MSG_DEBUG_ERROR_MSG, Msg)),
%%Msg;

%%show(E) when is_atom(E) ->
%%Msg = ?a2b(E),
%%?player_send(<<?MSG_DEBUG_ERROR_MSG, ?pkg_sstr(Msg)>>),
%%E;
%%show(E) ->
%%E.


