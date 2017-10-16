%%-----------------------------------
%% @Module  : guild_mining_mng
%% @Author  : Henry
%% @Email   : 
%% @Created : 2016.12.3
%% @Description: 公会挖矿模块
%%-----------------------------------
-module(guild_mining_mng).

-include("handle_client.hrl").
-include("inc.hrl").
-include("system_log.hrl").
-include("player.hrl").
-include("game.hrl").
-include("player_mod.hrl").
-include("guild_define.hrl").
-include("item_new.hrl").
-include("day_reset.hrl").
% -include("err_info_def.hrl").

-define(success, 0).    % 成功
-define(fail, 1).       % 失败
-define(msg_send_time, 30).     % 召集消息cd
-define(guild_mining, 7).   % 公会挖矿

-export([
    send_prize/3,
    get_free_count/0,
    push_guild_info/0
    ]).

pack_guild_mining_player_info(List) ->
	% ?DEBUG_LOG("---------List-----: ~p",[List]),
	{Total, Bin} = 
	lists:foldl(fun({Index, PlayerId}, {Count, Acc}) ->
		case player:lookup_info(PlayerId, [?pd_career, ?pd_name, ?pd_combat_power, ?pd_level]) of
			[?none] ->
				{Count, Acc};
			[Car, Name, Power, Lev] ->
				EquipList = 
				api:get_equip_change_list(PlayerId),
				EquipListBin = 
				lists:foldl(fun(Bid1, Acc) ->
				   <<Acc/binary, Bid1:32>>
				end,
				<<(length(EquipList)):16>>,
				EquipList),
				EftsList = api:get_efts_list(PlayerId),
				EftsListBin = 
				lists:foldl(fun(Bid2, Acc) ->
					<<Acc/binary, Bid2:16>>
				end,
				<<(length(EftsList)):16>>,
				EftsList),
				{Count+1, <<Acc/binary, Index:8, PlayerId:64,(byte_size(Name)), Name/binary, Car:8, Lev:8, Power:32, EquipListBin/binary, EftsListBin/binary>>}
		end
	end,
	{0,<<>>},
	List),
	<<Total, Bin/binary>>.

handle_client({Pack, Args}) ->
    handle_client(Pack, Args).

handle_client(?MSG_GUILD_MINING_INFO_SEND, {}) -> 
    push_guild_info();
handle_client(?MSG_GUILD_MINING_KIND, {Ret, Seat}) ->
	CostList = misc_cfg:get_mining_cost(),
	Cost = 
		case lists:keyfind(Ret, 1, CostList) of
			{Ret, C} ->
				C;
			_ ->
				0
		end,
	case  Ret of
		0 -> 
			% 参与挖矿
			case game_res:try_del([{?DIAMOND_BID, Cost}], ?FLOW_REASON_GUILD) of
				{error, _E} -> 
					?player_send(guild_mining_sproto:pkg_msg(?MSG_GUILD_MINING_KIND, {?fail})),
					?return_err(?ERR_SELLER_DIAMOND_NOT_ENOUGH);
				ok ->
					PlayerId = get(?pd_id),
					% PlayerName = get(?pd_name),
					% PlayerJob = get(?pd_career),
					% PlayerInfo = {Seat, PlayerId, PlayerName, PlayerJob},
					GuildId = get(?pd_guild_id),
					case guild_mining_server:join_mining(GuildId, Seat, PlayerId) of
						ok ->
							%  BuyCount = get(?pd_guild_mining_buyed_time), % 玩家已购买公会挖矿的次数
							% LeaveCount = get(?pd_guild_mining_leave_time),
							?player_send(guild_mining_sproto:pkg_msg(?MSG_GUILD_MINING_KIND, {?success})),
							MiningCount = get(?pd_guild_mining_leave_time),
							put(?pd_guild_mining_leave_time, MiningCount - 1),
							push_guild_info();
						_ ->
							?return_err(?ERR_GUILD_MINING_INFO)
					end;
				_ ->
					?return_err(?ERR_COST_NOT_ENOUGH)
			end;
		1 ->
			% 一键挖矿
			case game_res:try_del([{?DIAMOND_BID, Cost}], ?FLOW_REASON_GUILD) of
				{error, _E} -> 
					?player_send(guild_mining_sproto:pkg_msg(?MSG_GUILD_MINING_KIND, {?fail})),
					?return_err(?ERR_SELLER_DIAMOND_NOT_ENOUGH);
				ok ->
					PlayerId = get(?pd_id),
					case dbcache:load_data(?player_guild_member, PlayerId) of
						[] ->
							?ERROR_LOG("load player_guild_member failed");
						[#player_guild_member{lv=OfferLv}] ->
							[PrizeList, GuildExpList, OfferExpList] = load_cfg_mining_prize:get_prize(OfferLv),
							{4, PrizeId} = lists:keyfind(4, 1, PrizeList),      % 奖励物品id
							{4, GuildExp} = lists:keyfind(4, 1, GuildExpList),      % 奖励公会经验值
							{4, OfferExp} = lists:keyfind(4, 1, OfferExpList),      % 奖励个人贡献值
							% 发奖
							send_prize(PrizeId, GuildExp, OfferExp),
							MiningCount = get(?pd_guild_mining_leave_time),
							put(?pd_guild_mining_leave_time, MiningCount - 1),
							push_guild_info(),
							?player_send(guild_mining_sproto:pkg_msg(?MSG_GUILD_MINING_KIND, {?success}))
					end;
				_ ->
					?return_err(?ERR_COST_NOT_ENOUGH)
			end;
		_ ->
			?player_send(guild_mining_sproto:pkg_msg(?MSG_GUILD_MINING_KIND, {?fail})),
			?ERROR_LOG("receive unknown send Ret:~p", [Ret])
	end;

%% 购买次数
handle_client(?MSG_GUILD_MINING_BUY_COUNT, {BuyCount}) ->
    VipLevel = attr_new:get_vip_lvl(),
    case load_vip_new:get_vip_mining_count_by_vip_level(VipLevel) of
        ?none ->
            pass;
        List ->
            % PlayerLevel = get(?pd_level),
            Size = length(List),
            Count = get(?pd_guild_mining_leave_time),
            NewCount = Count + BuyCount,
            if
                NewCount =< Size ->
                    PayList = load_vip_new:get_vip_new_pay_list(List),
                    %Cost = get_mining_cost(BuyCount, Count+1, Size),
                    Cost = lists:nth(BuyCount, PayList),
                    case game_res:try_del([{?PL_DIAMOND, Cost}], ?FLOW_REASON_GUILD_MINING) of
                        ok ->
                            put(?pd_guild_mining_leave_time, NewCount),
                            put(?pd_guild_mining_buyed_time, BuyCount),
                            push_guild_info(),
                            ?player_send(guild_mining_sproto:pkg_msg(?MSG_GUILD_MINING_BUY_COUNT, {?success}));
                        _ ->
                            ?player_send(guild_mining_sproto:pkg_msg(?MSG_GUILD_MINING_BUY_COUNT, {?fail}))
                    end;
                true ->
                    ?player_send(guild_mining_sproto:pkg_msg(?MSG_GUILD_MINING_BUY_COUNT, {?fail}))
            end
    end,
    ok;

%% 召集玩家
handle_client(?MSG_GUILD_MINING_ZHAOJI, {}) ->
     case is_time_limit(get(?pd_mining_zhaoji), ?msg_send_time) of
        ?false ->
            put(?pd_mining_zhaoji, com_time:now()),
            Title = get(?pd_attr_cur_title),
            world:broadcast(chat_mng:pack_chat_broadcast(?CHAT_GUILD, Title, <<>>, ?guild_mining, 0)),
            ?player_send(guild_mining_sproto:pkg_msg(?MSG_GUILD_MINING_ZHAOJI, {?success}));
        ?true ->
                            ?player_send(guild_mining_sproto:pkg_msg(?MSG_GUILD_MINING_ZHAOJI, {?fail})),
                            ok;
                _E ->
                            ?ERROR_LOG("error")
    end;
handle_client(_Msg, _) ->
    {error, unknown_msg}.

%% 限制玩家发言
is_time_limit(OldTimeOut, Int) when is_integer(OldTimeOut) ->
	%?ERROR_LOG("old~w, Int ~w, Now ~w", [OldTimeOut, Int, com_time:now()]),
	com_time:now() =< (OldTimeOut + Int).

push_guild_info() ->
	GuildId = get(?pd_guild_id),
	Reply = guild_mining_server:get_mining_info(GuildId),
	case Reply of
		{GuildId, PlayerList, EndTime} ->
			% {_, NewPlayerList} = lists:unzip(PlayerList),
			% ?DEBUG_LOG("--------PlayerList--------: ~p", [PlayerList]),
			PlayerBin  = pack_guild_mining_player_info(PlayerList),
			LeaveCount = get(?pd_guild_mining_leave_time),  % 玩家剩余的挖矿次数
			BuyCount = get(?pd_guild_mining_buyed_time),    % 玩家已购买公会挖矿的次数
			% ?DEBUG_LOG("-------LeaveCount-------~p", [LeaveCount]),
			% ?DEBUG_LOG("-------BuyCount-------~p", [BuyCount]),
			?player_send(guild_mining_sproto:pkg_msg(?MSG_GUILD_MINING_INFO_SEND, {PlayerBin, EndTime, LeaveCount, BuyCount}));
		_ ->
			PlayerBin = <<0>>,
			EndTime = 0,
			LeaveCount = get(?pd_guild_mining_leave_time),
			BuyCount = get(?pd_guild_mining_buyed_time),
			% ?DEBUG_LOG("-------LeaveCount-------~p", [LeaveCount]),
			% ?DEBUG_LOG("-------BuyCount-------~p", [BuyCount]),
			% ?return_err(?ERR_GUILD_MINING_INFO)   % 获取挖矿信息失败
			% ?DEBUG_LOG("MSG_GUILD_MINING_INFO_SEND get info error"),
			?player_send(guild_mining_sproto:pkg_msg(?MSG_GUILD_MINING_INFO_SEND, {PlayerBin, EndTime, LeaveCount, BuyCount}))
	end.

% 日刷新
on_day_reset(_PlayerId) ->
	put(?pd_guild_mining_leave_time, 1),
	put(?pd_guild_mining_buyed_time, 0),
	push_guild_info(),
	ok.

%  发奖
send_prize(PrizeId, GuildExp, OfferExp) ->
    PlayerId = get(?pd_id),
    % ?DEBUG_LOG("-------PlayerId~p", [PlayerId]),
    GuildId = get(?pd_guild_id),
    guild_service:guild_build_add_exp(GuildId, GuildExp),
    Prize = prize:get_itemlist_by_prizeid(PrizeId),
    Offer = {?GUILD_CONTRIBUTION, OfferExp},
    ItemList = [Offer | Prize],
    world:send_to_player_any_state(PlayerId,?mod_msg(mail_mng, {gwgc_mail, PlayerId, ?S_MAIL_GUILD_MINING_PRIZE,ItemList})).
    % mail_mng:send_sysmail(PlayerId, ?S_MAIL_GUILD_MINING_PRIZE, ItemList).

get_free_count() ->
    VipLevel = attr_new:get_vip_lvl(),
    List = load_vip_new:get_vip_mining_count_by_vip_level(VipLevel),
    Count = load_vip_new:get_vip_new_free_times(List).

handle_msg(_FromMod, {send_prize, PrizeId, GuildExp, OfferExp}) ->
    send_prize(PrizeId, GuildExp, OfferExp),
    ok;
handle_msg(_FromMod,{push_guild_info}) ->
    push_guild_info(),
    ok;
handle_msg(_FromMod, _Msg) ->
    {error, unknown_msg}.

load_mod_data(PlayerId) ->
    ok.

create_mod_data(PlayerId) ->
    ok.
    
init_client() ->
    push_guild_info(),
    put(?pd_mining_zhaoji, com_time:now() - ?msg_send_time),
    ok.

save_data(PlayerId) ->
    ok.

online() -> ok.

view_data(Acc) -> Acc.

offline(PlayerId) ->
    save_data(PlayerId),
    ok.

handle_frame(_) -> todo.
