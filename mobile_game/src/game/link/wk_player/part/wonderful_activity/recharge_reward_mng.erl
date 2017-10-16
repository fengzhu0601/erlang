%%%-------------------------------------------------------------------
%%% @author fengzhu
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%     开服充值满额送礼
%%% @end
%%% Created : 18. 九月 2016 下午4:58
%%%-------------------------------------------------------------------
-module(recharge_reward_mng).
-author("fengzhu").

-include_lib("pangzi/include/pangzi.hrl").
-include("inc.hrl").
-include("player_mod.hrl").
-include("handle_client.hrl").
-include("recharge_reward_struct.hrl").
-include("player.hrl").
%%-include("day_reset.hrl").
-include("load_db_misc.hrl").
-include("load_cfg_open_server_happy.hrl").
-include("system_log.hrl").
-include("load_cfg_recharge_prize.hrl").

%% API
-export([
    init_recharge_prize_list/0
    , update_recharge/1
]).

load_db_table_meta() ->
    [
        #db_table_meta
        {
            name = ?player_recharge_reward_tab,
            fields = ?record_fields(?player_recharge_reward_tab),
            shrink_size = 1,
            flush_interval = 3
        }
    ].

create_mod_data(PlayerId) ->
    RechargeRewardTab =
        #player_recharge_reward_tab
        {
            id = PlayerId,
            recharge = 0,
            reward_status = init_recharge_prize_list()
        },
    case dbcache:insert_new(?player_recharge_reward_tab, RechargeRewardTab) of
        ?true ->
            ok;
        ?false ->
            ?ERROR_LOG("player ~p create new player_equip_goods_table error mode ~p", [PlayerId, ?MODULE])
    end,
    ok.

load_mod_data(PlayerId) ->
    case load_cfg_open_server_happy:the_activity_is_over(?RECHARGE_REWARD_ID) of
        true ->
            case dbcache:load_data(?player_recharge_reward_tab, PlayerId) of
                [] ->
                    ?INFO_LOG("player ~p not find player_bounty_tab mode ~p", [PlayerId, ?MODULE]),
                    create_mod_data(PlayerId),
                    load_mod_data(PlayerId);
                [#player_recharge_reward_tab{recharge = Recharge, reward_status = RewardStatus}] ->
                    ?pd_new(?pd_total_recharge, Recharge),
                    ?pd_new(?pd_reward_status, RewardStatus)
            end;
        false ->
            dbcache:delete(?player_recharge_reward_tab, PlayerId)
    end.


init_client() ->
    ok.

view_data(Acc) -> Acc.

handle_frame(_Frame) -> ok.

handle_msg(_, {board_recharge_reward_over}) ->
    %% 广播活动结束
    ok;
handle_msg(_FromMod, _Msg) -> ok.


online() ->
    case load_cfg_open_server_happy:the_activity_is_over(?RECHARGE_REWARD_ID) of
        true ->
            boardcast_recharge_reward_over(),
            push_recharge_reward_info();
        false ->
            pass
    end.

offline(SelfId) ->
    save_data(SelfId),
    ok.

save_data(SelfId) ->
    RechargeRewardTab =
        #player_recharge_reward_tab{
            id = SelfId,
            recharge = get(?pd_total_recharge),
            reward_status = get(?pd_reward_status)
        },
    dbcache:update(?player_recharge_reward_tab, RechargeRewardTab).


handle_client({Pack, Arg}) ->
    handle_client(Pack, Arg).
    %% case task_open_fun:is_open(?OPEN_BOUNTY) of
    %%     ?false -> ?return_err(?ERR_NOT_OPEN_FUN);
    %%     ?true ->
    %%         handle_client(Pack, Arg)
    %% end;

handle_client(?MSG_RECHARGE_REWARD_GET_PRIZE, {Id}) ->
    Ret = do_get_recharge_reward_prize(Id),
    Reply =
        case Ret of
            ok ->
                ?REPLY_MSG_RECHARGE_PRIZE_OK;
            {error, not_find} ->
                ?REPLY_MSG_RECHARGE_PRIZE_1;
            {error, cant_get} ->
                ?REPLY_MSG_RECHARGE_PRIZE_2;
            _ ->
                ?REPLY_MSG_RECHARGE_PRIZE_255
        end,
    ?player_send(recharge_reward_sproto:pkg_msg(?MSG_RECHARGE_REWARD_GET_PRIZE, { Reply }));

handle_client(Mod, Msg) ->
    ?ERROR_LOG("no known msg Mod:~p Msg:~p", [bounty_sproto:to_s(Mod), Msg]),
    {error, unknown_msg}.

%% 活动结束时间戳
get_recharge_time_stamp() ->
    {_,[Y,M,D,H,Mi]} = load_cfg_open_server_happy:get_activity_time_by_id(?RECHARGE_REWARD_ID),
    CloseTime = {{Y,M,D},{H,Mi,0}},
    CloseTimeSec = calendar:datetime_to_gregorian_seconds(CloseTime),
    LocalTimeSec = calendar:datetime_to_gregorian_seconds(calendar:local_time()),
    TimeStamp = CloseTimeSec - LocalTimeSec + com_time:now(),
    TimeStamp.

%% 初始化充值奖励状态列表
%% [{1,金额,奖励Id,0}]
init_recharge_prize_list() ->
    RechargeIdList = load_cfg_recharge_prize:lookup_all_recharge_prize_cfg(#recharge_prize_cfg.id),
    lists:foldr(
        fun(Id, Acc) ->
            [ {Id, ?REWARD_STATUS_0} | Acc]
        end,
        [],
        RechargeIdList
    ).

%% 推送累计充值奖励信息
push_recharge_reward_info() ->
    Recharge = attr_new:get(?pd_total_recharge, 0),
    RewardStatus = attr_new:get(?pd_reward_status, []),
    ?player_send(recharge_reward_sproto:pkg_msg(?MSG_RECHARGE_REWARD_INFO, { Recharge, RewardStatus })).

%% 领取累计充值奖励
do_get_recharge_reward_prize(Id) ->
    Recharge = get(?pd_total_recharge),
    RewardStatusList = get(?pd_reward_status),
    CurRewardStatus = lists:keyfind(Id, 1, RewardStatusList),
    case CurRewardStatus of
        {Id, Status} ->
            Amount = load_cfg_recharge_prize:get_total_recharge_by_id(Id),
            PrizeId = load_cfg_recharge_prize:get_prizeId_by_id(Id),
            if
                Recharge >= Amount andalso Status =:= ?REWARD_STATUS_1 ->
                    prize:prize(PrizeId, ?FLOW_REASON_RECHARGE_PRIZE),
                    NewRewardStatusList = lists:keyreplace(Id, 1, RewardStatusList, {Id, ?REWARD_STATUS_2}),
                    put(?pd_reward_status, NewRewardStatusList),
                    push_recharge_reward_info(),
                    ok;
                true ->
                    {error, cant_get}   %% 领取失败
            end;
        _ ->
            {error, not_find}           %% 没找到对应奖励
    end.

%% 更新累计充值金额(充值的时候,更新累计金额同步到前端),Money是钻石来着
update_recharge(Money) ->
    Recharge = attr_new:get(?pd_total_recharge, 0),
    NewRecharge = Recharge + Money,
    put(?pd_total_recharge, NewRecharge),

    RewardStatus = update_reward_status(),

    ?player_send(recharge_reward_sproto:pkg_msg(?MSG_RECHARGE_REWARD_INFO, { NewRecharge, RewardStatus })).

%% 玩家充值后更新奖励列表状态
update_reward_status() ->
    Recharge = get(?pd_total_recharge),
    RewardStatus = attr_new:get(?pd_reward_status, []),
    NewRewardStatus =
        lists:foldr(
            fun({Id, Status},Acc) ->
                Amount = load_cfg_recharge_prize:get_total_recharge_by_id(Id),
                case Status of
                    ?REWARD_STATUS_0 ->
                        if
                            Recharge >= Amount ->
                                [{Id, ?REWARD_STATUS_1} | Acc];
                            true ->
                                [{Id, Status} | Acc]
                        end;
                    _ ->
                        [{Id, Status} | Acc]
                end
            end,
            [],
            RewardStatus
        ),
    put(?pd_reward_status, NewRewardStatus),
    NewRewardStatus.

%% 广播充值满额活动结束
boardcast_recharge_reward_over() ->
    {_,[Y,M,D,H,Mi]} = load_cfg_open_server_happy:get_activity_time_by_id(?RECHARGE_REWARD_ID),
    CloseTime = {{Y,M,D},{H,Mi,0}},
    CloseTimeSec = calendar:datetime_to_gregorian_seconds(CloseTime),
    LocalTimeSec = calendar:datetime_to_gregorian_seconds(calendar:local_time()),
    TimeStamp = CloseTimeSec - LocalTimeSec,
    erlang:send_after(TimeStamp * 1000, self(), board_recharge_reward_over).
