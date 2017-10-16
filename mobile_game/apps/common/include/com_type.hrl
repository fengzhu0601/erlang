-ifndef(COM_TYPE_HRL).
-define(COM_TYPE_HRL, 1).

%% 类型
%% little end
                                                %-define(uint8_t ,  8/unsigned-little-integer).
                                                %-define(uint16_t, 16/unsigned-little-integer).
                                                %-define(uint32_t, 32/unsigned-little-integer).
                                                %-define(uint64_t, 64/unsigned-little-integer).

                                                %-define(int8_t ,  8/signed-little-integer).
                                                %-define(int16_t, 16/signed-little-integer).
                                                %-define(int32_t, 32/signed-little-integer).
                                                %-define(int64_t, 64/signed-little-integer).

%% big end
-define(b_uint8_t ,  8/unsigned-big-integer).
-define(b_uint16_t, 16/unsigned-big-integer).
-define(b_uint32_t, 32/unsigned-big-integer).
-define(b_uint64_t, 64/unsigned-big-integer).

-define(b_int8_t ,  8/signed-big-integer).
-define(b_int16_t, 16/signed-big-integer).
-define(b_int32_t, 32/signed-big-integer).
-define(b_int64_t, 64/signed-big-integer).

%% 原始包
-record(raw_pkg, {cmd=0      :: non_neg_integer(),
                  param=0    :: non_neg_integer(),
                  rtnCode=0  :: non_neg_integer(),
                  body= <<>> :: binary()}).


-type s_raw_pkg() :: #raw_pkg{}.

%% 解饱函数
-type s_unpack_call() :: fun((s_raw_pkg()) ->
                                    {ok, call, {non_neg_integer(), list()}}
                                        | {ok, call_err, {non_neg_integer(), list()}}
                                        | {error, {_, s_raw_pkg()}}).


-endif.
