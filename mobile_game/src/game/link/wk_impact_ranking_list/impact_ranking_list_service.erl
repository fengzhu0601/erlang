%%%-------------------------------------------------------------------
%%% @author fengzhu
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%     开服冲榜
%%% @end
%%% Created : 22. 九月 2016 下午6:43
%%%-------------------------------------------------------------------
-module(impact_ranking_list_service).
-author("fengzhu").

-include("inc.hrl").
-include("load_db_misc.hrl").
-include("rank.hrl").
-include("load_cfg_open_server_happy.hrl").
-include("system_log.hrl").
-include("player.hrl").
-include("game.hrl").
-include("item_new.hrl").

-behaviour(gen_server).

%% API
-export([
    start_link/0
    , boardcast_ranking_list_change/3
    , add_guild_impact_ranking_list_title/0
    , add_impact_ranking_list_title/1
    ]).

%% gen_server callbacks
-export([init/1,
    handle_call/3,
    handle_cast/2,
    handle_info/2,
    terminate/2,
    code_change/3]).

-define(ACTIVITY_STATE_WAIT, 0).
-define(ACTIVITY_STATE_START, 1).
-define(ACTIVITY_STATE_END, 2).

-define(OPEN_RANKING_LIST_ACTIVITY, 5).     %% 开服冲榜活动
-define(POWER_RANKING_LIST_ACTIVITY, 6).    %% 战力排行榜活动
-define(RIDE_RANKING_LIST_ACTIVITY, 7).     %% 坐骑排行榜活动
-define(PET_RANKING_LIST_ACTIVITY, 8).      %% 宠物排行榜活动
-define(SUIT_RANKING_LIST_ACTIVITY, 9).     %% 套装排行榜活动
-define(ABYSS_RANKING_LIST_ACTIVITY, 10).   %% 深渊排行榜活动
-define(GUILD_RANKING_LIST_ACTIVITY, 11).   %% 公会排行榜活动

-define(GUILD_EXP_PRIZE_1, 10000).         %% 公会经验奖励
-define(GUILD_EXP_PRIZE_2, 9000).         %% 公会经验奖励
-define(GUILD_EXP_PRIZE_3, 8000).         %% 公会经验奖励
-define(GUILD_EXP_PRIZE_4, 7000).         %% 公会经验奖励
-define(GUILD_EXP_PRIZE_5, 6000).         %% 公会经验奖励
-define(GUILD_EXP_PRIZE_6, 5000).         %% 公会经验奖励

-record(state, {}).

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).


init([]) ->
    com_process:init_name(<<"impact_ranking_list_server">>),
    com_process:init_type(?MODULE),

    set_sendId(),
    %% 每隔3秒检查一次是否能够发放开服冲榜奖励
    erlang:send_after(3000, self(), try_send_impact_ranking_list_prize),
    boardcast_rank_start(),
    {ok, #state{}}.

handle_call(_Request, _From, State) ->
    {reply, ok, State}.

handle_cast(_Request, State) ->
    {noreply, State}.

handle_info(try_send_impact_ranking_list_prize, State) ->
    try_send_impact_ranking_list_prize(),
    %% 所有活动结束后取消定时器
    case is_all_activity_in_time() of
        ?false ->
            erlang:send_after(3000, self(), try_send_impact_ranking_list_prize);
        ?true ->
            pass
    end,
    {noreply, State};

%% 活动开启
handle_info({boardcast_start,ActivityId}, State) ->
    %% 广播活动开启
    case ActivityId of
        ?POWER_RANKING_LIST_ACTIVITY ->
            notice_system:zhangli_king_rank_over();
        ?RIDE_RANKING_LIST_ACTIVITY ->
            notice_system:zuoqi_king_rank_over();
        ?PET_RANKING_LIST_ACTIVITY ->
            notice_system:pet_king_rank_over();
        ?SUIT_RANKING_LIST_ACTIVITY ->
            notice_system:suit_king_rank_over();
        ?ABYSS_RANKING_LIST_ACTIVITY ->
            notice_system:shengyuan_king_rank_over();
        ?GUILD_RANKING_LIST_ACTIVITY ->
            notice_system:guild_king_rank_over();
        _ ->
            pass
    end,
    {noreply, State};

%% {sendprize, 发放奖励Id, 排行榜Id}
%% 公会排行有点不同，单独处理
handle_info({sendprize, SendId, ?ranking_guild}, State) ->
    %% 获取所有排行榜公会
    Ranking = ranking_lib:lookup_data_by_name(?ranking_guild), %% [{ 公会Id, 公会经验 }]
    GuildIdList =
        lists:foldl(
            fun({GuildId, _SortValue} , AccList) ->
                [GuildId | AccList]
            end,
            [],
            Ranking
        ),
    lists:foreach(
        fun(GuildId) ->
            {Order, _Value} = ranking_lib:get_rank_order(?ranking_guild, GuildId),
            {_PrizeId1, PrizeId2, PrizeId3, ServerPrize} = load_cfg_impact_ranking_list:get_prize(?ranking_guild, Order),
            GuildMaster = guild_service:get_guild_master(GuildId),
            GuildMember = guild_service:get_guild_member_except_master(GuildId),
            {ok, PrizeList1} = prize:get_prize(ServerPrize),
            {ok, PrizeList2} = prize:get_prize(PrizeId2),
            {ok, PrizeList3} = prize:get_prize(PrizeId3),

            {MailTitle, BuildAddExp} = get_mail_title_by_order(Order),
            guild_service:guild_build_add_exp(GuildId, BuildAddExp),
            mail_mng:send_sysmail(GuildMaster, MailTitle, PrizeList1),
            mail_mng:send_sysmail(GuildMaster, ?S_MAIL_GUILD_RANKING_MASTER_PRIZE, PrizeList2),
            lists:foreach(
                fun(MemberId) ->
                    mail_mng:send_sysmail(MemberId, ?S_MAIL_GUILD_RANKING_MEMBER_PRIZE, PrizeList3)
                end,
                GuildMember
            ),
            %% 会长加称号
            add_guild_impact_ranking_list_title()
        end,
        lists:sublist(GuildIdList,50)
    ),
    %% 设置
    load_db_misc:set(SendId, 1),
    {noreply, State};

handle_info({sendprize, SendId, RankName}, State) ->
    %% 获取玩家ID
    Ranking = ranking_lib:lookup_data_by_name(RankName),
    RankingListPlayers =
        lists:foldr(
            fun({PlayerId,_SortValue}, AccList) ->
                [PlayerId | AccList]
            end,
            [],
            Ranking),
    case RankName of
        ?ranking_zhanli ->
            send_prize_by_rankid(RankingListPlayers, RankName, SendId, ?S_MAIL_POWER_RANKING_PRIZE);
        ?ranking_pet ->
            send_prize_by_rankid(RankingListPlayers, RankName, SendId, ?S_MAIL_PET_RANKING_PRIZE);
        ?ranking_suit_new ->
            send_prize_by_rankid(RankingListPlayers, RankName, SendId, ?S_MAIL_SUIT_RANKING_PRIZE);
        ?ranking_ride ->
            send_prize_by_rankid(RankingListPlayers, RankName, SendId, ?S_MAIL_RIDE_RANKING_PRIZE);
        ?ranking_abyss ->
            send_prize_by_rankid(RankingListPlayers, RankName, SendId, ?S_MAIL_ABYSS_RANKING_PRIZE);
        _ ->
            pass
    end,

    {noreply, State};

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

get_all_ranking_list() ->
    [
        {?POWER_RANKING_LIST_ID, ?misc_power_ranking_list_prize, ?ranking_zhanli},
        {?PET_RANKING_LIST_ID, ?misc_pet_ranking_list_prize, ?ranking_pet},
        {?SUIT_RANKING_LIST_ID, ?misc_suit_ranking_list_prize, ?ranking_suit_new},
        {?RIDE_RANKING_LIST_ID, ?misc_ride_ranking_list_prize, ?ranking_ride},
        {?ABYSS_RANKING_LIST_ID, ?misc_abyss_ranking_list_prize, ?ranking_abyss},
        {?GUILD_RANKING_LIST_ID, ?misc_guild_ranking_list_prize, ?ranking_guild}
    ].

get_all_activity_list() ->
    [
        ?OPEN_RANKING_LIST_ACTIVITY,
        ?POWER_RANKING_LIST_ACTIVITY,
        ?RIDE_RANKING_LIST_ACTIVITY,
        ?PET_RANKING_LIST_ACTIVITY,
        ?SUIT_RANKING_LIST_ACTIVITY,
        ?ABYSS_RANKING_LIST_ACTIVITY,
        ?GUILD_RANKING_LIST_ACTIVITY
    ].

%% 活动结束发放冲榜奖励到玩家邮箱
try_send_impact_ranking_list_prize() ->
    AllRankingList = get_all_ranking_list(),
    lists:foreach(
        fun({Id,SendId,RankName}) ->
%%            put(SendId, 0),
            IsOver = load_cfg_open_server_happy:the_activity_is_over(Id),
            IsSend = load_db_misc:get(SendId, 0),
            case {IsOver, IsSend} of
                %% 活动结算并且奖励还没有发送
                {?false, 0} ->
                    boardcast_rank_over(RankName),
                    ranking_lib:flush_rank_by_rankname(RankName),
                    send_impact_ranking_list_prize(SendId, RankName);
                _ ->
                    pass
            end
        end,
        AllRankingList
    ).

%% get_the_ranking_list_prize_is_send(SendId) ->
%%     case get(SendId) of
%%         undefined ->
%%             0;
%%         IsSend ->
%%             IsSend
%%     end.

%% 发放排行榜奖励
send_impact_ranking_list_prize(SendId, RankName) ->
    ?MODULE ! {sendprize, SendId, RankName}.

%% 根据排行榜发奖励
send_prize_by_rankid(RankingListPlayers, RankName, SendId, EmailId) ->
    lists:foreach(
        fun(Id) ->
            Order = get_rank_order_by_rankid(RankName, Id),
            PrizeId = load_cfg_impact_ranking_list:get_prize(RankName, Order),
            {ok, PrizeList} = prize:get_prize(PrizeId),
            mail_mng:send_sysmail(Id, EmailId, PrizeList)
        end,
        lists:sublist(RankingListPlayers,200)
    ),
    add_impact_ranking_list_title(RankName),
    %% 设置
    load_db_misc:set(SendId, 1).

get_rank_order_by_rankid(RankName, PlayerId) ->
    case RankName of
        ?ranking_zhanli ->
            {Order, _Value} = ranking_lib:get_rank_order(?ranking_zhanli, PlayerId, {0, 0}),
            Order;
        ?ranking_pet ->
            {Order, _Value} = ranking_lib:get_rank_order(?ranking_pet, PlayerId, {0, {0, 0}}),
            Order;
        ?ranking_suit_new ->
            {Order, _Value} = ranking_lib:get_rank_order(?ranking_suit_new, PlayerId, {0, 0}),
            Order;
        ?ranking_ride ->
            {Order, _Value} = ranking_lib:get_rank_order(?ranking_ride, PlayerId, {0, {0, 0}}),
            Order;
        ?ranking_abyss ->
            {Order, _Value} = ranking_lib:get_rank_order(?ranking_abyss, PlayerId, {0, {0, 0, 0, 0}}),
            Order;
        _ ->
            0
    end.



%% 广播排行榜前3名的变化
boardcast_ranking_list_change( RankName, OldTop3, NewTop3 ) ->
    {_, OldTop3Id} =
        lists:foldl(
            fun({Id, _RankValue}, {Rank,Acc}) ->
                {Rank+1,[{Id, Rank+1} | Acc]}
            end,
            {0,[]},
            OldTop3
        ),
    {_, NewTop3Id} =
        lists:foldl(
            fun({Id, _RankValue}, {Rank,Acc}) ->
                {Rank+1,[{Id, Rank+1} | Acc]}
            end,
            {0,[]},
            NewTop3
        ),

    lists:foreach(
        fun({Id,NewRank}) ->
            case lists:keyfind(Id, 1, OldTop3Id) of
                ?false ->       %% 以前不在前三名中，直接广播
                    boardcast_rank(RankName, Id, NewRank);
                {Id, OldRank} ->
                    if
                        NewRank < OldRank ->    %% 以前在前三名中，新排名大于老排名才广播
                            boardcast_rank(RankName, Id, NewRank);
                        true ->
                            pass
                    end;
                _ ->
                    pass
            end
        end,
        NewTop3Id
    ).



%% 广播（排行榜Id， 玩家或公会Id， 新排名)
boardcast_rank(RankName, Id, NewRank) ->
    case RankName of
        ?ranking_guild ->
            notice_system:guild_king_rank_up(Id, NewRank),
            ok;
        ?ranking_ride ->
            notice_system:ride_king_rank_up(Id, NewRank),
            ok;
        ?ranking_suit_new ->
            notice_system:suit_king_rank_up(Id, NewRank),
            ok;
        ?ranking_pet ->
            notice_system:pet_king_rank_up(Id, NewRank),
            ok;
        ?ranking_abyss ->
            notice_system:shenyuan_king_rank_up(Id, NewRank),
            ok;
        ?ranking_zhanli ->
            notice_system:zhanli_king_rank_up(Id, NewRank),
            ok;
        _ ->
            pass
    end.

%% 排行榜广播活动结束
boardcast_rank_over(RankName) ->
    case RankName of
        ?ranking_guild ->
            ok;
        ?ranking_ride ->
            ok;
        ?ranking_suit_new ->
            ok;
        ?ranking_pet ->
            ok;
        ?ranking_abyss ->
            ok;
        ?ranking_zhanli ->
            ok;
        _ ->
            pass
    end.

%% 排行榜广播活动开始
boardcast_rank_start() ->
    lists:foreach(
        fun(ActivityId) ->
            OpenTime = load_cfg_open_server_happy:get_activity_begin_time(ActivityId),
            case OpenTime of
                [0,0,0,0,0] ->
                    pass;
                OpenTime ->
                    %% 广播开启
                    [Y,M,D,H,Mi] = OpenTime,
                    OpenTimeSec = calendar:datetime_to_gregorian_seconds({{Y, M, D}, {H, Mi, 0}}),
                    CurTime = calendar:local_time(),
                    CurTimeSec = calendar:datetime_to_gregorian_seconds(CurTime),
                    RemainTime = OpenTimeSec - CurTimeSec,
                    if
                        RemainTime > 0 ->
                            SendId = get_sendId_by_activityid(ActivityId),
                            case SendId of
                                pass ->
                                    pass;
                                SendId ->
                                    load_db_misc:set(SendId, 0)
                            end,
                            erlang:send_after( RemainTime * 1000, self(), {boardcast_start,ActivityId});
                        true ->
                            pass
                    end
            end

        end,
        get_all_activity_list()
    ).

set_sendId() ->
    lists:foreach(
        fun(Id) ->
            case load_cfg_open_server_happy:the_activity_is_over(Id) of
                ?false ->
                    pass;
                _ ->
                    SendId = get_sendId_by_activityid(Id),
                    case SendId of
                        pass ->
                            pass;
                        SendId ->
                            load_db_misc:set(SendId, 0)
                    end
            end
        end,
        get_all_activity_list()
    ).

get_sendId_by_activityid(ActivityId) ->
    case ActivityId of
        ?POWER_RANKING_LIST_ACTIVITY ->
            ?misc_power_ranking_list_prize;
        ?RIDE_RANKING_LIST_ACTIVITY ->
            ?misc_ride_ranking_list_prize;
        ?PET_RANKING_LIST_ACTIVITY ->
            ?misc_pet_ranking_list_prize;
        ?SUIT_RANKING_LIST_ACTIVITY ->
            ?misc_suit_ranking_list_prize;
        ?ABYSS_RANKING_LIST_ACTIVITY ->
            ?misc_abyss_ranking_list_prize;
        ?GUILD_RANKING_LIST_ACTIVITY ->
            ?misc_guild_ranking_list_prize;
        _ ->
            pass
    end.

get_mail_title_by_order(Order) ->
    if
        Order == 1 ->
            {?S_MAIL_GUILD_RANKING_GUILD_PRIZE_1, ?GUILD_EXP_PRIZE_1};
        Order == 2 ->
            {?S_MAIL_GUILD_RANKING_GUILD_PRIZE_2, ?GUILD_EXP_PRIZE_2};
        Order == 3 ->
            {?S_MAIL_GUILD_RANKING_GUILD_PRIZE_3, ?GUILD_EXP_PRIZE_3};
        Order =< 10 ->
            {?S_MAIL_GUILD_RANKING_GUILD_PRIZE_4, ?GUILD_EXP_PRIZE_4};
        Order =< 20 ->
            {?S_MAIL_GUILD_RANKING_GUILD_PRIZE_5, ?GUILD_EXP_PRIZE_5};
        true ->
            {?S_MAIL_GUILD_RANKING_GUILD_PRIZE_6, ?GUILD_EXP_PRIZE_6}
    end.

%% [{称号Id， 玩家Id}]
add_impact_ranking_list_title(RankName) ->
    %% 获得RankName的前三名，玩家
    L = ranking_lib:get_top_n_info(RankName, 200),
    TitleList =
        lists:foldl(
            fun({Id,Mc}, Acc) ->
                TitleId = load_cfg_impact_ranking_list:get_title(RankName, Mc),
                case TitleId of
                    0 ->
                        Acc;
                    _ ->
                        [{TitleId, Id} | Acc]
                end
            end,
            [],
            L
        ),
    gen_server:call(title_service,{add_rank_title, TitleList}).

add_guild_impact_ranking_list_title() ->
    L = ranking_lib:get_top_n_info(?ranking_guild, 200),
    TitleList =
        lists:foldl(
            fun({GuildId,Mc}, Acc) ->
                TitleId = load_cfg_impact_ranking_list:get_title(?ranking_guild, Mc),
                case TitleId of
                    0 ->
                        Acc;
                    _ ->
                        MasterId = guild_service:get_guild_master(GuildId),
                        [{TitleId, MasterId} | Acc]
                end
            end,
            [],
            L
        ),
    gen_server:call(title_service,{add_rank_title, TitleList}).

is_all_activity_in_time() ->
    AllRankingList = get_all_ranking_list(),
    Result =
        lists:foldl(
            fun({Id,SendId,_RankName}, Acc) ->
                IsOver = load_cfg_open_server_happy:the_activity_is_over(Id),
                IsSend = load_db_misc:get(SendId, 0),
                case {IsOver,IsSend} of
                    %% 活动结束并且奖励已发送
                    {?false, 1} ->
                        [0 | Acc];
                    _ ->
                        [1 | Acc]
                end
            end,
            [],
            AllRankingList
        ),
    lists:all(fun(E) -> E =:= 0 end, Result).
