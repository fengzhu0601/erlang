%%%-------------------------------------------------------------------
%%% @author zl
%%% @doc 一个虚拟时间系统
%%%      所有的时间都是本地时间.
%%%
%%% @end
%%%-------------------------------------------------------------------

-module(virtual_time).

-compile({no_auto_import, [now/0, time/0, date/0]}).

-include("com_define.hrl").

-export([
         now/0
         ,time/0
         ,date/0
         ,localtime/0
         ,day_of_the_week/0
         ,day_of_the_month/0
         ,month_of_year/0

         ,reset/0
         ,offset/0

         ,set_date/1
         ,set_time/1
         ,set_localtime/1


         ,real_2_virtual/1

         ,init_uptime/0
         ,get_uptime/0

        ]).


%% Returns: {date(), time()}, date() = {Y, M, D}, time() = {H, M, S}.
%%set_localtime({X,}) ->


%% @doc 初始化启动时间， 一般在服务器启动时调用一次
-spec init_uptime() -> no_return().
init_uptime() ->
    {ok, Meta} = smerl:new_from_module(?MODULE),
    NowMSec = com_time:timestamp_msec(),

    UptimeFn = io_lib:format("get_uptime()-> com_time:timestamp_msec() - ~p .", [NowMSec]),

    case smerl:replace_func(Meta, lists:flatten(UptimeFn)) of
        {ok, NewMeta} ->
            smerl:compile(NewMeta);
        {error, R} ->
            io:format("init_uptime error ~p", [ R])
    end.

%% @doc 得到自从上次init_uptime 后过去的毫秒数
%% 没有设置init_uptime 时返回0.
get_uptime() ->
    0.


now() ->
    com_time:localtime_to_sec(localtime()).

%% @doc set today time of the virtual time.
-spec set_time(calendar:time()) -> ok.
set_time({H, M, S}) ->
    {Rh, Rm, Rs} = erlang:time(),
    Offset = (H - Rh) * ?SECONDS_PER_HOUR +
             (M - Rm) * ?SECONDS_PER_MINUTE +
             (S - Rs),


    update_offset(Offset),
    ok.

%% @doc set date of the virtual time. time not changed.
-spec set_date(calendar:date()) -> ok.
set_date(Date) -> 
    {_, RTime} = erlang:localtime(),
    RealNow = com_time:now(),
    VirtualNow = com_time:localtime_to_sec({Date, RTime}),
    update_offset(VirtualNow -  RealNow),
    ok.


%% @doc set localtime of the vritual time.
set_localtime(LocalTime) -> 
    RealNow = com_time:now(),
    VirtualNow = com_time:localtime_to_sec(LocalTime),
    update_offset(VirtualNow -  RealNow),
    ok.


day_of_the_week() ->
    com_time:day_of_the_week(date()).

day_of_the_month() ->
    com_time:day_of_the_month(localtime()).

month_of_year() ->
    com_time:month_of_year(localtime()).

reset() ->
    update_offset(0).

time() -> 
    {_, Time} = localtime(),
    Time.

date() -> 
    {Date, _} = localtime(),
    Date.

?INLINE(localtime, 0).
localtime() -> 
    case offset() of
        0 -> erlang:localtime();
        Offset ->
            com_time:sec_to_localtime(com_time:now() + Offset)
    end.


offset() -> 0.

real_2_virtual(_) -> todo.


update_offset(Offset) ->
    {ok, Meta} = smerl:new_from_module(?MODULE),

    OffsetFn = io_lib:format("offset()-> ~p .", [Offset]),

    case smerl:replace_func(Meta, lists:flatten(OffsetFn)) of
        {ok, NewMeta} ->
            smerl:compile(NewMeta);
        {error, R} ->
            io:format("replace offset error ~p", [ R])
    end.


            


