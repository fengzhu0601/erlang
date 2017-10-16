-ifndef(COM_PACKET_BASE_HRL).
-define(COM_PACKET_BASE_HRL, 1).


%% @doc 而进程打包函数 都是特化 do/3
%%
-include("com_type.hrl").
-include("com_proto.hrl").


%% 原子类型
%% uint8
%% uint16
%% uint32
%% uint64
%% string

%% ---write {{{
write(uint8 , Num, Bin) when is_integer(Num), is_binary(Bin) ->
    <<Bin/binary, Num:?b_int8_t>>;
write(uint16, Num, Bin) when is_integer(Num), is_binary(Bin) ->
    <<Bin/binary, Num:?b_int16_t>>;
write(uint32, Num, Bin) when is_integer(Num), is_binary(Bin) ->
    <<Bin/binary, Num:?b_int32_t>>;
write(uint64, Num, Bin) when is_integer(Num), is_binary(Bin) ->
    <<Bin/binary, Num:?b_int64_t>>;
write(string, Str, Bin) when is_list(Str), is_binary(Bin) ->
    BStr = list_to_binary(Str),
    StrLen = byte_size(BStr),
    <<Bin/binary, StrLen:?b_int16_t, BStr/binary>>.

%% ---write }}}
%%
%% 打包大端序
new(Cmd, Param) when is_integer(Cmd), is_integer(Param) ->
    <<Cmd   : ?b_uint16_t,
      Param : ?b_uint16_t,
      0     : ?b_uint16_t
    >>.

%% 设置报的长度
eos(Bin) when is_binary(Bin) ->
    ProtoLen  = byte_size(Bin)+2,
    <<ProtoLen : ?b_int16_t, Bin/binary>>.


%% -------------------------------------------------------------------
%% 所有的协议都要在这里定义打包过程
%% 打包指定协议的二进制包
%% do(Cmd::integer(), Parm::integer, List) -> binary()
%%
-spec do(non_neg_integer(), non_neg_integer(), list()) -> binary().

                                                %do(_Cmd, _Parm, _) ->
                                                %?ERROR_LOG("new bed arg cmd:~p, param:~p~n", [_Cmd, _Parm]).

-endif.
