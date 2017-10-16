%%%-------------------------------------------------------------------
%%% @author fengzhu
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 07. 九月 2016 下午5:17
%%%-------------------------------------------------------------------
-module(bounty_server).
-author("fengzhu").

-include("load_db_misc.hrl").
-include("rank.hrl").
-include("inc.hrl").
-include("bounty_struct.hrl").

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

-define(SERVER, ?MODULE).

bountyList() ->
    [
        ?misc_bounty_open_times,
        ?misc_free_refresh_times,
        ?misc_pay_refresh_times
    ].

-record(state, {}).

start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

init([]) ->
    %% 每隔3秒检查一次是否能够发放赏金任务排行榜奖励
    erlang:send_after(3000, self(), try_send_bounty_prize),
    {ok, #state{}}.

handle_call({count_bounty_times, BountyType}, _From, State) ->
    case lists:member(BountyType, bountyList()) of
        true ->
            CurTimes = load_db_misc:get(BountyType, 0),
            NewTimes = CurTimes + 1,
            load_db_misc:set(BountyType, NewTimes);
        _ ->
            pass
    end,
    {reply, ok, State};
handle_call(_Request, _From, State) ->
    {reply, ok, State}.

handle_cast(_Request, State) ->
    {noreply, State}.

handle_info({sendprize, ?ranking_bounty}, State) ->
    %% 获取玩家ID
    Ranking = ranking_lib:lookup_data_by_name(?ranking_bounty),
    %% 记录前10名玩家和赏金值
    load_db_misc:set(?misc_bounty_rank_liveness, lists:sublist(Ranking,10)),
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
            {Order, _Value} = ranking_lib:get_rank_order(?ranking_bounty, Id, {0, 0}),
            PrizeId = load_abyss_integral_reward:get_prize(Order),
            {ok, PrizeList} = prize:get_prize(PrizeId),
            mail_mng:send_sysmail(Id, ?S_MAIL_BOUNTY_PRIZE, PrizeList)
        end,
        lists:sublist(AbyssPlayerList,10)
    ),
    {noreply, State};
handle_info(try_send_bounty_prize, State) ->
    try_send_bounty_prize(),
    erlang:send_after(3000, self(), try_send_bounty_prize),
    {noreply, State};
handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

try_send_bounty_prize() ->
    BountyIsOver = load_db_misc:get(?misc_bounty_is_over, 0),
    case BountyIsOver =:= 0 andalso bounty_mng:is_in_activity_period() =:= false of
        true ->
            ranking_lib:flush_rank_only_by_rankname(?ranking_bounty),
            load_db_misc:set(?misc_bounty_is_over, 1), %% 结束了
            %% 发放奖励
            send_prize_rank(?ranking_bounty),
            %% 广播
%%            Members = ranking_lib:get_rank_player_list(?ranking_bounty),
%%            broadcast_bounty_over(lists:sublist(Members,10)),
            notice_system:send_player_bounty_over(),
            %% 清理活动数据
            ranking_lib:reset_rank(?ranking_bounty),
            ok;
        false ->
            pass
    end.

send_prize_rank(RankName) ->
    ?MODULE ! {sendprize, RankName},
    ok.
