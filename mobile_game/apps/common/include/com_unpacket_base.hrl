-ifndef(COM_UNPACKET_BASE_HRL).
-define(COM_UNPACKET_BASE_HRL, 1).

-include("com_proto.hrl").
-include("com_type.hrl").

%% ------read func {{{
read(uint8 , <<Num:?b_uint8_t,  Other/binary>>) -> {Num, Other};
read(uint16, <<Num:?b_uint16_t, Other/binary>>) -> {Num, Other};
read(int32 , <<Num:?b_int32_t,  Other/binary>>) -> {Num, Other};
read(uint32, <<Num:?b_uint32_t, Other/binary>>) -> {Num, Other};
read(uint64, <<Num:?b_uint64_t, Other/binary>>) -> {Num, Other};


%% @return -> {card :: card(),
%%             Other::binary()}
read(card, <<_:2, S:4, V:2, Other/binary>>) -> {com_card:get(V, S), Other};

%% @space get_string(Bin::binary()) -> {string :: list(),
%%                                       Other :: binary()}
read(string, Bin) when is_binary(Bin) ->
    case Bin of
        <<Len :?b_uint16_t, Other/binary>> ->
            <<Str:Len/binary, Rest/binary>> = Other,
            {binary_to_list(Str), Rest};
        _R1 ->
            {[], <<>>}
    end.

%% ------read func  }}}



%% -------------------------------------------------------------------
%% @doc  所有的协议都要在定义do/1解包过程
%%       把二进制包转换为对应的tuple 调用处理函数
%%
-spec do(s_raw_pkg()) ->
                {ok, call, {non_neg_integer(), list()}}
                    | {ok, call_err, {non_neg_integer(), list()}}
                    | {error, {_, s_raw_pkg()}}.

%% e.g.
%%% @doc 一个unpack 宏指定对应的接受pkg cmd=?CLIENT_2_LOGIC_CMD, rtnCode=?ERR_NO_ERROR
                                                %-define(UNPACK_LOGIC(Param),
                                                %do(#raw_pkg{cmd=?CLIENT_2_LOGIC_CMD, param=Param, rtnCode=?ERR_NO_ERROR, body=_Body})).

%%% @doc rtnCode 非 ERR_NO_ERROR 的包
                                                %-define(UNPACK_LOGIC_ERR(Param, RtnCode),
                                                %do(#raw_pkg{cmd=?CLIENT_2_LOGIC_CMD, param=Param, rtnCode=RtnCode, body=_Body})).



                                                %?UNPACK(?CLIENT_2_GATE_CMD, ?CMD_CG_ROBOT_Get_LogicInfo, ?ERR_NO_ERROR) ->
                                                %{Id, Body1} = read(uint16, _Body),
                                                %{Ip, Body2} = read(string, Body1),
                                                %{Port, _} = read(uint16, Body2),
                                                %{ok, call,
                                                %{?CMD_CG_ROBOT_Get_LogicInfo,
                                                %[#logic_server_info{id = Id, ip =Ip, port = Port}]
                                                %}
                                                %};


%% ------------------------------------------------------------------------
%% call_err
%% ------------------------------------------------------------------------


                                                %?UNPACK_LOGIC_ERR(?CMD_CL_Client_SitDown, ?ERR_TABLE_SEAT_IS_FULL) ->
                                                %{ok, call_err,
                                                %{?ERR_TABLE_SEAT_IS_FULL,
                                                %[]
                                                %}
                                                %};

                                                %do(RawPkg) ->
                                                %{error, {unkonw_pkg, RawPkg}}.

-endif.
