%%%-------------------------------------------------------------------
%%% @author lan
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 13. 九月 2016 下午6:40
%%%-------------------------------------------------------------------
-module(auction_new_mng).
-author("lan").

%% API



-export([
	bider_win/2,
	handle_msg/2
]).

-include("handle_client.hrl").
-include("inc.hrl").
-include("game.hrl").
-include("../../wk_player/part/wonderful_activity/bounty_struct.hrl").
-include("player.hrl").
-include("auction_new.hrl").
-include("item_new.hrl").
-include("auction_mng_reply.hrl").
-include("load_phase_ac.hrl").
-include("achievement.hrl").
-include("system_log.hrl").
-include("../../wk_open_server_happy/open_server_happy.hrl").

bider_win(BiderId, Item) ->
%%    ?DEBUG_LOG("BiderId---------:~p-----Item---:~p",[BiderId, Item]),
	world:send_to_player(BiderId, ?mod_msg(auction_new_mng, gouwukuang)),
    world:send_to_player(BiderId, ?mod_msg(bounty_mng, {bounty_task_heishi})),
	mail_mng:send_sysmail(BiderId, ?S_MAIL_AUCTION_BIDER_WIN, [Item]),
	ok.

%% 给竞拍失败者通过邮件返还东西
bider_loss(?undefined, _MoneyType, _Price, _DiscItem) -> ok;
bider_loss(BiderId, MoneyType, Price, _DiscItem) ->
	%GoodsIdList = [{DiscItem, 1}],
	%?DEBUG_LOG("Price------------------------:~p",[Price]),
	mail_mng:send_sysmail(BiderId, ?S_MAIL_AUCTION_BIDER_LOSS, [], [{MoneyType, Price}]),
	ok.

handle_client({Pack, Arg}) ->
	handle_client(Pack, Arg).

%% 获取拍卖行面板的信息
handle_client(?MSG_AUCTION_PANEL, {}) ->
	ACTS = auction_new_svr:get_auction_all(),
	SendMes = refresh_auction_list(ACTS),
%%	?INFO_LOG("SendMes = ~p", [SendMes]),
	?player_send(auction_sproto:pkg_msg(?MSG_AUCTION_PANEL, SendMes)),
	ok;

%% 竞价物品
handle_client(?MSG_AUCTION_PRICE, {AId, Price}) ->
%%    ?DEBUG_LOG("AId--Price-----------------:~p", [{AId, Price}]),
	ReplyNum = add_price(Price, AId),
	%% 刷新拍卖行的竞拍数据
	ReList = get_refresh_data(),
	?player_send(auction_sproto:pkg_msg(?MSG_AUCTION_REFRESH, {ReList})),
	?player_send(auction_sproto:pkg_msg(?MSG_AUCTION_PRICE, {ReplyNum, AId})),
	api:sync_phase_prize_data(),
	open_server_happy_mng:sync_task(?BLACK_SHOP_COUNT, 1),
	ok;

%% 刷新拍卖行的竞拍数据
handle_client(?MSG_AUCTION_REFRESH, {}) ->
%%    ?INFO_LOG("refresh auction data --------- "),
	ReList = get_refresh_data(),
	?player_send(auction_sproto:pkg_msg(?MSG_AUCTION_REFRESH, {ReList})),
	ok;

%% 刷新拍卖行的日志信息
handle_client(?MSG_AUCTION_LOG_REFRESH, {}) ->
%%    ?INFO_LOG("refresh auction log -------- "),
	LogList = auction_new_svr:get_log_all(),
	LogList1 =
		lists:foldl
		(
			fun(#auction_log_tab{playerId = PlayerId,itemId = ItemId, money_type = MoneyType,
				price = Price, datetime = Time, payType = PayType}, Acc) ->
				PlayerName =
					case player:lookup_info(PlayerId, [?pd_name]) of
						[?none] -> ?ERROR_LOG("is not find player name -----");
						[Name] -> Name
					end,
				[{PlayerId,PlayerName,ItemId,MoneyType,Price,Time,PayType}|Acc]
			end,
			[],
			LogList
		),
	?player_send(auction_sproto:pkg_msg(?MSG_AUCTION_LOG_REFRESH, {LogList1})),
	ok;

%% 打开拍卖行的面板
handle_client(?MSG_OPEN_AUCTION_PANEL, {}) ->
	%% 发送刷新的数据
%%    ReList = get_refresh_data(),
%%    ?player_send(auction_sproto:pkg_msg(?MSG_AUCTION_REFRESH, {ReList})),
	ACTList = auction_new_svr:get_auction_all(),
	SendMes = refresh_auction_list(ACTList),
	?player_send(auction_sproto:pkg_msg(?MSG_AUCTION_PANEL, SendMes)),
	?player_send(auction_sproto:pkg_msg(?MSG_OPEN_AUCTION_PANEL, {0})),
	ok;

handle_client(Mod, Msg) ->
	?ERROR_LOG("no known msg Mod:~p Msg:~p", [Mod, Msg]).

handle_msg(_FromMod, gouwukuang) ->
%%	?INFO_LOG("test gouwukuang -----------------------"),
	achievement_mng:do_ac(?gouwukuang),
	ok.


%% 刷新面板的数据
refresh_auction_list(ACTS) ->
	%% 获取当前时间的秒数
	IsOpen = auction_new_svr:get_black_shop_is_open(),
	SendTime = auction_new_svr:get_time_out(),
	VipLevel = get(?pd_vip),
	ACTL =
		lists:foldr
		(
			fun(#com_auction_new_tab{id = Id, item_state = ItemState, seller = OwnName
				, item = Item, bider_id = BiderId, money_type = MoneyType
				, cur_price = CurPrice, high_price = HPrice, step_price = StepPrice
			}, Acc) ->
				CfgVipLevel = load_black_shop_cfg:get_goods_vip_level(Id),
%%				?INFO_LOG("CfgLevel = ~p, VipLevel = ~p", [CfgVipLevel, VipLevel]),
				case VipLevel >= CfgVipLevel of
					true ->
						BiderName =
							case player:lookup_info(BiderId, ?pd_name) of
								?none ->
									<<>>;
								Name ->
									Name
							end,
						case is_record(Item, item_new) of
							true ->
								#item_new{bid = Bid, quantity = Count} = Item,
								[{ItemState, Id, OwnName, Bid, Count, MoneyType, CurPrice, StepPrice, HPrice, BiderId, BiderName} | Acc];
							_ ->
								Acc
						end;
					_ ->
						Acc
				end
			end,
			[],
			ACTS
		),
    {IsOpen, round(SendTime), ACTL}.


%% 竞价
add_price(Price, AId) ->
	SelfId = get(?pd_id),
	Ret =
		case dbcache:lookup(?com_auction_new_tab, AId) of
			[#com_auction_new_tab{bider_id = BiderId, money_type = MoneyType,
				cur_price = CPrice, high_price = HPrice,
				step_price = StepPrice} = CAT] ->
%%				Now = com_time:timestamp_sec(),
				if
					SelfId =:= BiderId ->                           %% 自己已经是最高竞价者
						{error, is_bider_id};
					Price - CPrice < StepPrice, HPrice > CPrice -> %% 加价幅度小于默认值
						{error, add_price_little};
					?true ->
						case game_res:try_del([{MoneyType, Price}], ?FLOW_REASON_AUCTION) of
							ok ->
								case do_add_price(SelfId, CPrice, CAT#com_auction_new_tab{cur_price = Price}) of
									ok ->
										phase_achievement_mng:do_pc(?PHASE_AC_PAIMAI_JIAOYI, 1),
%%										?DEBUG_LOG("add price is ok-------------------------"),
										ok;
									{error, APReason} ->
										{error, APReason}
								end;
							_ ->
								{error, money_not_enough}
						end
				end;
			_E ->  %% 你下手晚了，已经被别人买了
				{error, aready_acutoin}
		end,
	case Ret of
		ok ->
			event_eng:post(?ev_auction_jingjia_totle, {?ev_auction_jingjia_totle, 0}, 1),
			?REPLY_MSG_AUCTION_PRICE_OK;  %% 竞价成功
		{error, add_price_little} ->      %% 加价幅度小于默认值
			?REPLY_MSG_AUCTION_PRICE_1;
		{error, last_min} ->              %% 竞价时间已经截止（还有一分钟的时候就不给竞价了
			?REPLY_MSG_AUCTION_PRICE_2;
		{error, is_bider_id} ->           %% 您已经是最高竞价者了
			?REPLY_MSG_AUCTION_PRICE_3;
		{error, money_not_enough} ->    %% 钻石不足，无法竞价
			?REPLY_MSG_AUCTION_PRICE_4;
		{error, aready_acutoin} ->        %% 您下手晚了，已经被别人拍走了
			?REPLY_MSG_AUCTION_PRICE_5;
		{error, _Reason} ->               %% 竞价失败，请重试。重试失败，请联系GM
			?REPLY_MSG_AUCTION_PRICE_255
	end.

%% 加价处理函数（分为两种情况,1 正常加价， 2 一口价）
do_add_price(SelfId, OCPrice, #com_auction_new_tab{id = AId, seller = Name, bider_id = OBiderId,
	high_price = HPrice, item = Item, money_type = MoneyType, cur_price = Price} = CAT) ->
	NCAT = CAT#com_auction_new_tab{bider_id = SelfId},
%%    ?DEBUG_LOG("OBiderId--------------------:~p",[OBiderId]),
	#{free := Free} = misc_cfg:get_black_shop_misc(),
	if
		Price >= HPrice ->          %% 一口价成交
			case auction_new_svr:high_price(NCAT) of
				ok ->
					Money = get(?pd_money),

					%% 发送系统日志
					if
						is_integer(Item) ->
							system_log:info_auction_buy_log(Money+Price, Money, Item, 1, Price, 0);
						is_record(Item, item_new) ->
							#item_new{id = GoodsId, quantity = QuaCount} = Item,
							system_log:info_auction_buy_log(Money+Price, Money, GoodsId, QuaCount, Price, 0);
						is_tuple(Item) ->
							system_log:info_auction_buy_log(Money+Price, Money, element(1, Item), element(2, Item), Price, 0);
						true ->
							?ERROR_LOG("auction system log error")
					end,

					%% 向竞拍失败者返还金币或者钻石
					bider_loss(OBiderId, MoneyType, com_util:ceil(OCPrice - OCPrice * (Free/1000)), Item),
					%% 设置该物品已经被竞拍掉了
					dbcache:update(?com_auction_new_tab, CAT#com_auction_new_tab{item_state = ?item_auction_ed, bider_id = SelfId}), %% 设置该拍卖数据为玩家自己成功拍卖

					ItemBid =
						if
							is_integer(Item) ->
								Item;
							is_record(Item, item_new) ->
								#item_new{bid = Bid} = Item,
								Bid;
							is_tuple(Item) ->
								element(1, Item);
							true ->
								?ERROR_LOG("undefine auction item ")
						end,

					LogAuc =
						#auction_log_tab{
							id = AId,
							playerId = SelfId,
							itemId = ItemBid,
							money_type = MoneyType,
							owner_name = Name,
							price = Price,
							datetime = com_time:timestamp_sec(),
							payType = 1
						},
					%% 添加拍卖行的拍卖日志
					dbcache:insert_new(?auction_log_tab, LogAuc),
					ok;
				_ ->
					{error, high_price_error}
			end;
		?true ->          %% 正常加价
			case auction_new_svr:add_price(NCAT) of
				ok ->
					achievement_mng:do_ac(?jingjiagaoshou),

					%% 向竞拍失败者返还物品
					bider_loss(OBiderId, MoneyType, com_util:ceil(OCPrice - OCPrice * (Free/1000)), Item),
					ok;
				_ ->
					{error, add_price_error}
			end
	end.


get_refresh_data() ->
	AuctList = auction_new_svr:get_auction_all(),
	AuctList1 =
		lists:foldr
		(
			fun(#com_auction_new_tab{item_state = State,
				id = Id, cur_price = Price, bider_id = BiderId}, Acc) ->
				BiderName =
					case player:lookup_info(BiderId, ?pd_name) of
						?none -> <<>>;
						Name -> Name
					end,
				[{State, Id, Price, BiderId, BiderName} | Acc]
			end,
			[],
			AuctList
		),
	AuctList1.



