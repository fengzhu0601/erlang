%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%% 1,空间换时间,在本地缓存大量定时器数据,以节省向系统大量申请和交互定时器开销.
%%% 2,时间轴可变.
%%% @end
%%% Created : 08. 三月 2016 下午3:25
%%%-------------------------------------------------------------------
-module(timer_server).
-author("clark").

%% API
-export([
    start/2,
    stop/1,
    is_wait_timer/1,
    get_timer_mfa/1
]).

-export([
    start/3,
    get_timeaxle/0,
    handle_min_timeout/0,
    get_next_timeout_dt/0,
    show/0
]).

%% 这模块蛋碎了一地。
%% gb_tree的排序居然是以结点的ID: key来排的，不是结点value。 操蛋了……
%% 先临时用列表修正了，性能问题日后再调整

-include("inc.hrl").
-define(cur_timers_list, '@cur_timers_list@'). %%[{Ref, Timer}]

-record(timer_item,{
    ref,    %% 
    dt,     %% 结束时间
    mfa     %% 待调用的方法函数
}).

%% 开启触发器
start(TimeDt, {_,_,_} = MFA) ->
    start(com_time:timestamp_msec(), TimeDt, MFA).
start(TimeAxle, TimeDt, {_M,_F,_A} = MFA) ->
    Ref = make_ref(),
    List = util:get_pd_field(?cur_timers_list, []),
    util:set_pd_field(?cur_timers_list, [#timer_item{ref=Ref, dt=(TimeAxle+TimeDt), mfa=MFA} | List]),
    Ref.

%% 关闭触发器
stop(Ref) ->
    List = util:get_pd_field(?cur_timers_list, []),
    List1 = lists:keydelete(Ref, #timer_item.ref, List),
    util:set_pd_field(?cur_timers_list, List1),
    ok.

is_wait_timer(Ref) ->
    List = util:get_pd_field(?cur_timers_list, []),
    case lists:keyfind(Ref, #timer_item.ref, List) of
        false -> 
            false;
        _ -> 
            true
    end.

get_timer_mfa(Ref) ->
    List = util:get_pd_field(?cur_timers_list, []),
    case lists:keyfind(Ref, #timer_item.ref, List) of
        false -> 
            false;
        #timer_item{mfa=MFA} -> 
            MFA
    end.

%% 获得默认时间轴
get_timeaxle() ->
    com_time:timestamp_msec().

%% 处理最小时间槽
handle_min_timeout() ->
    case get_smallest() of
        nil ->
            ok;

        #timer_item{ref=Ref, mfa={M,F,A}, dt=_Dt} ->
            stop(Ref),
            erlang:apply(M, F, A)
    end.

%% 获得最小超时间隔
get_next_timeout_dt()->
    NowTimeMsec = com_time:timestamp_msec(),
    case get_smallest() of
        nil -> 
            infinity;
        #timer_item{dt=Dt, mfa={_M,_F,_A}} ->
            erlang:max(0, Dt - NowTimeMsec)
    end.


get_smallest() ->
    List = util:get_pd_field(?cur_timers_list, []),
    Min =
    lists:foldl(fun
        (CurItem, nil) ->
            CurItem;
        (#timer_item{dt=Dt} = CurItem, #timer_item{dt=MinDt} = MinItem) ->
            if
                MinDt >= Dt ->  
                    CurItem;
                true -> 
                    MinItem
            end
    end,
    nil,
    List),
    %%     List = util:get_pd_field(?cur_timers_list, []),
    %%     List1 = [ {Timer#timer_item.dt} || Timer <- List ],
    Min.


show() ->
    List = util:get_pd_field(?cur_timers_list, []),
    List1 = [ {Timer#timer_item.dt, Timer#timer_item.mfa} || Timer <- List ],
    ?INFO_LOG("--------------------------- timers ~p", [List1]).








