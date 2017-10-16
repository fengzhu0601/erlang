%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 11. 八月 2015 下午7:54
%%%-------------------------------------------------------------------
-module(ret).
-author("clark").

%% API
-export(
[
    error/1
    , error/2
    , ok/0
    , ok/1
    , data2/2
    , data3/3
    , system_error/2
]).





error(ErrorCode) -> {error, ErrorCode}.

error(ErrorCode1, ErrorCode2) -> {error, {ErrorCode1, ErrorCode2}}.

ok() -> ok.

ok(OkCode) -> {ok, OkCode}.

data2(Data1, Data2) -> {Data1, Data2}.

data3(Data1,Data2,Data3) -> {Data1,Data2,Data3}.

system_error(Type, Error) -> ret:error(Type, Error).




