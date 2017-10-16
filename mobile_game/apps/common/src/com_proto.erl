-module(com_proto).

%% @doc 发送协议
-export([get_next_pkg/1]).
-include("com_proto.hrl").
-include("com_type.hrl").

%% @space  register_user_req(string()) 注册玩家 {{{
                                                %register_user_req(Num) when is_list(Num) ->

                                                %register_user_req(_Bad) ->
%% }}}


%% @doc 得到下一个完整的包
%% -> {incomplete, Rest::binary()} |
%%               没有完整的包
%%    {error, Reason} |
%%               应当colse socket
%%    {ok, #raw_pkg(), Reset::binary()}
%%               有一个完整的包

%% 每个协议头的长度
-define(PKG_BASE_SIZE, 8).
-define(MAX_PACKET_SIZE, 8192).

get_next_pkg(<<>>) ->
    {incomplete, <<>>};

%% -> {ok, raw_pkg()} | {error, packet_too_big} | {incomplete, binary()}
get_next_pkg(Bin) when is_binary(Bin) ->
    BinLen = byte_size(Bin),
    if  BinLen < ?PKG_BASE_SIZE ->
            {incomplete, Bin};
        true ->
            <<PkgLen:?b_uint16_t, Reset/binary>> = Bin,
            if  PkgLen >= ?MAX_PACKET_SIZE ->
                    {error, packet_too_big};
                PkgLen > BinLen ->
                    {incomplete, Bin};
                true ->
                    <<Cmd:?b_uint16_t, Param:?b_uint16_t, RtnCode:?b_uint16_t,
                      Reset1/binary>> = Reset,
                    BodyBitLen = PkgLen - 8,
                    <<Body:BodyBitLen/binary, Reset2/binary>> = Reset1,
                    {ok,
                     #raw_pkg{cmd = Cmd, param = Param, rtnCode = RtnCode, body = Body},
                     Reset2}
            end
    end.
