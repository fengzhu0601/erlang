%%%-------------------------------------------------------------------
%%% @author fengzhu
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 12. 九月 2016 上午10:34
%%%-------------------------------------------------------------------
-module(abyss_server).
-author("fengzhu").

-include("inc.hrl").
-include("rank.hrl").
-include("load_db_misc.hrl").

-behaviour(gen_server).

%% API
-export([start_link/0]).

%% gen_server callbacks
-export([init/1,
    handle_call/3,
    handle_cast/2,
    handle_info/2,
    terminate/2,
    code_change/3]).

-export([
    send_abyss_prize_rank/1
]).

-record(state, {}).

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

init([]) ->
    %% 每隔3秒检查一次是否能够发放虚空深渊奖励
    erlang:send_after(3000, self(), try_send_abyss_prize),

    {ok, #state{}}.

handle_call(_Request, _From, State) ->
    {reply, ok, State}.

handle_cast(_Request, State) ->
    {noreply, State}.

handle_info(try_send_abyss_prize, State) ->
    try_send_abyss_prize(),
    erlang:send_after(3000, self(), try_send_abyss_prize),
    {noreply, State};

%% 给排行榜的玩家发奖励
handle_info({send_abyss_prize, ?ranking_abyss}, State) ->
    %% 获取玩家ID
    Ranking = ranking_lib:lookup_data_by_name(?ranking_abyss),
    %?INFO_LOG("Ranking:~p", [Ranking]),
    AbyssPlayerList =
        lists:foldr(
            fun({PlayerId,_SortValue}, AccList) ->
                [PlayerId | AccList]
            end,
            [],
            Ranking),
    %?INFO_LOG("AbyssPlayerList:~p", [AbyssPlayerList]),

    %% 玩家ID获取排行信息
    lists:foreach(
        fun(Id) ->
            {Order, _Value} = ranking_lib:get_rank_order(?ranking_abyss, Id, {0, 0}),
            PrizeId = load_abyss_integral_reward:get_prize(Order),
            {ok, PrizeList} = prize:get_prize(PrizeId),
            mail_mng:send_sysmail(Id, ?S_MAIL_ABYSS_WEEK_PRIZE, PrizeList)
        end,
        AbyssPlayerList
    ),

    {noreply, State};

handle_info(_Msg, State) ->
    ?ERROR_LOG("~p unkonwn msg ~p", [?pname(), _Msg]),
    {noreply, State}.


terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

send_abyss_prize_rank(RankName) ->
    ?MODULE ! {send_abyss_prize, RankName}.

try_send_abyss_prize() ->
    RecordAbyssTime =
        case load_db_misc:get(?misc_abyss_prize_time, ?undefined) of
            ?undefined ->
                load_db_misc:set(?misc_abyss_prize_time, virtual_time:date() ),
                load_db_misc:get(?misc_abyss_prize_time, virtual_time:date() );
            Date ->
                Date
        end,
    CurTime = virtual_time:date(),

    case util:is_in_same_week(RecordAbyssTime, CurTime) of
        ?true->
            ok;
        ?false ->
            %% 发放奖励
            send_abyss_prize_rank(?ranking_abyss),
            %% 刷新记录
            load_db_misc:set(?misc_abyss_prize_time, virtual_time:date() )
    end.
