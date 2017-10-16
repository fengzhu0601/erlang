%%% coding:utf-8
%%%-------------------------------------------------------------------
%%% @author zl
%%% @doc 一些有用的时间函数.
%%%
%%% @end
%%%-------------------------------------------------------------------

-module(com_time).

-compile({no_auto_import, [now/0]}).

-export([
         timestamp/0,
         timestamp/1,
         timestamp2now/1,
         timestamp_sec/0,
         timestamp_sec/1,
         timestamp_sec2now/1,
         timestamp_msec/0,
         timestamp_msec/1,
         timestamp_msec2now/1,
         timestamp_micro_f/0,
         local_time_str/0,
         now/0,

         sec_to_localtime/1,
         localtime_to_sec/1,
         align_second/0,
         align_minue/0,
         is_same_day/1,
         is_same_day/2,
         is_same_month/1,

         zero_clock_timestamp/0,
         zero_clock_timestamp_msec/0,

         day_of_the_week/0,
         day_of_the_week/1,
         day_of_the_month/0,
         day_of_the_month/1,
         month_of_year/0,
         month_of_year/1,

         today_passed_sec/0,
         now_diff/1,
         now_diff/2,
         get_seconds_to_next_day/1,
         get_seconds_to_next_day/0,
         get_seconds_to_specific_hour_today/1

        ]).

-include("com_define.hrl").

-export_type([unix_timestamp/0, 
              unix_timestamp_msec/0,
              unix_timestamp_micro/0
             ]).






-type unix_timestamp() :: non_neg_integer().
-type unix_timestamp_msec() :: non_neg_integer().
-type unix_timestamp_micro() :: non_neg_integer().

%%% @doc time and calendar tools func.
%%% conver
%%%  erlang:timestamp()        local_time calendar:datetime()
%%%           ----->  now_to_local_time/1
%%%           <------ local_time_to_now/1
%%%
%%%  local_time calendar:datetime()          unix_timestamp()
%%%            ---------> sec_to_localtime/1
%%%            <--------- localtime_to_sec/1
%%%
%%%
%% @doc erlang:timestamp to integer.

-spec timestamp() -> unix_timestamp_micro().
timestamp() ->
    timestamp(os:timestamp()).

%% @doc 当天凌晨时间戳
-spec zero_clock_timestamp() -> unix_timestamp().
zero_clock_timestamp() ->
    localtime_to_sec({erlang:date(), {0,0,0}}).

%% @doc 当天凌晨时间戳 ms
-spec zero_clock_timestamp_msec() -> unix_timestamp_msec().
zero_clock_timestamp_msec() ->
    zero_clock_timestamp() * ?MICOSEC_PER_SECONDS.


-spec timestamp(Timestamp :: erlang:timestamp()) -> unix_timestamp_micro().
timestamp({Me, Sec, Mico}) ->
    Me * 1000000000000 + Sec * 1000000 + Mico.

-spec timestamp2now(T :: unix_timestamp_micro()) -> erlang:timestamp().
timestamp2now(T) ->
    {T div 1000000000000,
     T rem 1000000000000 div 1000000,
     T rem 1000000
    }.


-spec timestamp_sec() -> unix_timestamp().
timestamp_sec() ->
    os_sec__(os:timestamp()).

now() ->
    timestamp_sec().

timestamp_sec2now(V) ->
    {V div 1000000,
     V rem 1000000,
     0
    }.

%% @doc millisecond timestamp.
timestamp_msec() ->
    os_msec(os:timestamp()).

%% @doc 得到当前任意时间的时间戳 today_time_timestamp
-spec timestamp_sec(Timestamp ::_ ) ->
                           unix_timestamp().
timestamp_sec({Hour, Min, Sec}) ->
    zero_clock_timestamp()  + Hour * ?SECONDS_PER_HOUR + Min * ?SECONDS_PER_MINUTE + Sec;

%% @doc 得到明天凌晨零点时间戳 
timestamp_sec(tomorrow) ->
    zero_clock_timestamp() + ?SECONDS_PER_DAY;

timestamp_sec(today) ->
    zero_clock_timestamp();

timestamp_sec(next_monday) ->
    zero_clock_timestamp() + ?SECONDS_PER_DAY * (8 - day_of_the_week()).

-spec timestamp_msec(Timestamp ::_ )->
                            unix_timestamp_msec().

timestamp_msec(Time) ->
    timestamp_sec(Time) * ?MICOSEC_PER_SECONDS.

    
?INLINE(os_sec__, 1).
os_sec__({Me, Sec, _}) ->
    Me * 1000000 + Sec.
os_msec({Me, Sec, Mico}) ->
    Me * 1000000000 + Sec * 1000 + Mico div 1000.

timestamp_msec2now(V) ->
    {V div 1000000000 ,
     V rem 1000000000 div 1000,
     V rem 1000 * 1000
    }.

-spec timestamp_micro_f() -> float().
timestamp_micro_f() ->
    {Me, Sec, Micor} = os:timestamp(),
    Me * 1000000 + Sec + Micor / 100000.

%%-spec time2now(Time :: calendar:time()) -> erlang:timestamp().

%%% @doc 得到一个制定time的localtime
%%-spec local_time(calendar:time()) -> calendar:datetime().
%%local_time(Time) ->
%%{Date, _Time} = erlang:localtime(),
%%{Date, Time}.



is_same_day(T) when erlang:is_tuple(T) ->
    is_same_day(T, calendar:local_time());
is_same_day(Sec) when erlang:is_integer(Sec) ->
    com_time:is_same_day(sec_to_localtime(Sec), calendar:local_time()).

%% @doc prarm datatime(), timestamp_sec
is_same_day(A, B) when is_tuple(A) andalso is_tuple(B) ->
    is_same_day__datetime(A, B);
is_same_day(A, B) when is_integer(A) andalso is_integer(B) ->
    is_same_day__integer(A, B).

is_same_day__integer(Sec1, Sec2) ->
    is_same_day(
      sec_to_localtime(Sec1),
      sec_to_localtime(Sec2)).

is_same_day__datetime({{Y, M, D}, _T1}, {{Y,M,D}, _T2}) ->
    true;
is_same_day__datetime(_, _) ->
    false.



-define(GREGORIAN_1970, 62167219200).  %calendar:datetime_to_gregorian_seconds({{1970,1,1},{0,0,0}}). 

-spec localtime_to_sec(DateTime :: calendar:datetime()) -> unix_timestamp().
localtime_to_sec(DateTime) ->
    calendar:datetime_to_gregorian_seconds(
      erlang:localtime_to_universaltime(DateTime)) - ?GREGORIAN_1970.

-spec sec_to_localtime(Timestamp :: unix_timestamp()) -> calendar:datetime().
sec_to_localtime(Timestamp) ->
    erlang:universaltime_to_localtime(
      calendar:gregorian_seconds_to_datetime(Timestamp+ ?GREGORIAN_1970)).

%% -> 2012-09-21 12:14:05
-spec local_time_str() -> list().
local_time_str() ->
    {{Y, M, D}, {H, Min, S}} = calendar:local_time(),
    lists:flatten(io_lib:format("~4.10.0B-~2.10.0B-~2.10.0B ~2.10.0B:~2.10.0B:~2.10.0B",
                                [Y, M, D, H, Min, S])).

day_of_the_week() ->
    day_of_the_week(date()).

day_of_the_week(Date) ->
    calendar:day_of_the_week(Date).


%%  获取当月的日期
-spec day_of_the_month() -> 1..31.
day_of_the_month() ->
    day_of_the_month(erlang:localtime()).

day_of_the_month(LocalTime) ->
  {{_,_,D},_} = LocalTime,
  D.


%% @doc 返回当前的月份。
-spec month_of_year() -> 1..12.
month_of_year() ->
    month_of_year(erlang:localtime()).

month_of_year(LocalTime) ->
    {{_,M,_},_} = LocalTime,
    M.

%% @doc wait unitl next scond have came.
%% precision is +10 millisecond.
-spec align_second() -> ok.
align_second() ->
    case os:timestamp() of
        {_,_,Mico} when Mico < 10000 -> %% 10 millisecond precision
            ok;
        {_,_,Mico} ->
            timer:sleep(1000 - Mico div 1000)
    end.

%% @doc wait unitl next minue have came.
%% precision is +0..999 millisecond.
align_minue() ->
    case erlang:time() of
        {_,_,0}  ->
            ok;
        {_,_,Sec} ->
            timer:sleep((60 - Sec) * 1000)
    end.




-spec tomorrow_hour( calendar:datetime() , non_neg_integer() )-> calendar:datetime().

tomorrow_hour({ Date, _ }, Hours) ->
    D = calendar:date_to_gregorian_days(Date),
    Date2 = calendar:gregorian_days_to_date( D + 1 ),
    { Date2, { Hours, 0, 0 } }.



%% @doc 从现在到到第二天 Hours 点，总共会经过多少秒。例如，现在开始到第二天3点，那么Hours为3。
-spec get_seconds_to_next_day(0..23) -> integer().

get_seconds_to_next_day(Hours) ->
    Now = calendar:local_time(),
    TomorrowWithHours = tomorrow_hour( Now, Hours ),
    NowSeconds = calendar:datetime_to_gregorian_seconds(Now),
    TomorrowSeconds = calendar:datetime_to_gregorian_seconds( TomorrowWithHours ),
    TomorrowSeconds - NowSeconds.

%% @doc 从现在到到第二天零点，总共会经过多少秒。
-spec get_seconds_to_next_day() -> integer().

get_seconds_to_next_day() ->
    get_seconds_to_next_day(0).


%% @doc 判断IndexMonth跟系统当前月份是否相同，如果想同返回true，如果不相同返回false。
-spec is_same_month(OldMonth :: integer()) ->  boolean().

is_same_month(OldMonth) ->
    IndexMonth = month_of_year(),
    OldMonth =:= IndexMonth.

%% @doc 从现在到到今天 Hours 点，总共会经过多少秒。例如，现在开始到今天3点，那么Hours为3。
-spec get_seconds_to_specific_hour_today(0..23) -> integer().

get_seconds_to_specific_hour_today(Hours) ->
    case calendar:local_time() of
        { Date, _ } = Now ->
            NewTime = { Date, { Hours, 0, 0 } },
            NowSeconds = calendar:datetime_to_gregorian_seconds(Now),
            NewSeconds = calendar:datetime_to_gregorian_seconds(NewTime),
            NewSeconds - NowSeconds
    end.




%% @doc get tow now diff
%% Calculate the time difference (second) of two
%% now.
%% 
-spec now_diff(unix_timestamp()) -> integer().
now_diff(OldTimestamp) ->
    now() - OldTimestamp.

-spec now_diff(unix_timestamp(), unix_timestamp()) -> integer().
now_diff(TL, TR) ->
    TR - TL.

%% @doc 得到从今天零点开始到现在经过的秒数.
%% INLINE
today_passed_sec() ->
    {_, {H, M, S}} = sec_to_localtime(now()),
    ((H * ?MINUTES_PER_HOUR) + M) * ?MINUTES_PER_HOUR + S.






-include_lib("eunit/include/eunit.hrl").
all_test_() ->
    [
     fun() ->
             Now = os:timestamp(),
             T= timestamp(Now),
             ?assertEqual(Now,timestamp2now(T))
     end,
     fun() ->
             {A,B,_} = Now = os:timestamp(),
             T= os_msec(Now),
             {A,B,_} = timestamp_msec2now(T)
     end,
     fun() ->
             {A,B,_} = Now = os:timestamp(),
             T= os_sec__(Now),
             {A,B,_} = timestamp_sec2now(T)
     end,
     fun() ->
             Date = calendar:local_time(),
             T = localtime_to_sec(Date),
             ?assertEqual(sec_to_localtime(T), Date)
     end,

     fun() ->
             Date = calendar:local_time(),
             ?assert(is_same_day(erlang:localtime(),Date)),
             ok
     end
    ].
