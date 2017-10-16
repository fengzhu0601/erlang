%%-----------------------------------
%% @Module  : nine_lottery_mng
%% @Author  : Holtom
%% @Email   : 
%% @Created : 2016.9.19
%% @Description: 九宫格抽奖模块
%%-----------------------------------
-module(nine_lottery_mng).

-export([

]).

-include("inc.hrl").
-include("game.hrl").
-include("player.hrl").
-include("player_mod.hrl").
-include("handle_client.hrl").
-include_lib("pangzi/include/pangzi.hrl").
-include("load_item.hrl").
-include("item_new.hrl").
-include("system_log.hrl").

-define(player_nine_lottery_tab, player_nine_lottery_tab).

-record(player_nine_lottery_tab, {
	id,
	nine_lottery_times = 0,
	log_list = []
}).

load_db_table_meta() ->
    [
        #db_table_meta{
            name = ?player_nine_lottery_tab,
            fields = ?record_fields(?player_nine_lottery_tab),
            record_name = ?player_nine_lottery_tab,
            shrink_size = 1,
            load_all = false,
            flush_interval = 3
        }
    ].

create_mod_data(SelfId) ->
    case dbcache:insert_new(?player_nine_lottery_tab, #player_nine_lottery_tab{id = SelfId}) of
        ?true -> ok;
        ?false ->
            ?ERROR_LOG("player ~p create new player_nine_lottery_tab not alread exists ", [SelfId])
    end,
    ok.

load_mod_data(PlayerId) ->
    case dbcache:load_data(?player_nine_lottery_tab, PlayerId) of
        [] ->
            ?ERROR_LOG("player ~p can not find player_nine_lottery_tab mode", [PlayerId]),
            create_mod_data(PlayerId),
            load_mod_data(PlayerId);
        [#player_nine_lottery_tab{nine_lottery_times = Times, log_list = LogList}] ->
        	put(pd_nine_lottery_times, Times),
            put(pd_nine_lottery_log, LogList),
            ok
    end,
    ok.

init_client() -> ok.

view_data(Msg) ->
    Msg.

handle_frame(_) -> ok.

online() -> ok.

offline(Id) ->
	save_data(Id),
	ok.

save_data(PlayerId) ->
	Times = get(pd_nine_lottery_times),
	LogList = get(pd_nine_lottery_log),
	Tab = #player_nine_lottery_tab{
		id = PlayerId,
		nine_lottery_times = Times,
		log_list = LogList
	},
	dbcache:update(?player_nine_lottery_tab, Tab),
	ok.

handle_client({Pack, Arg}) ->
	handle_client(Pack, Arg).

handle_client(?MSG_NINE_LOTTERY_INFO, {}) ->
	get_nine_lottery_info();

handle_client(?MSG_NINE_LOTTERY_GET_PRIZE, {Count}) ->
	CostList = misc_cfg:get_nine_lottery_cost(),
	Ret = case lists:keyfind(Count, 1, CostList) of
		{_, Cost} ->
			{game_res:can_del([{?PL_DIAMOND, Cost}]), Cost};
		_ ->
			{error, 0}
	end,
	case Ret of
		{ok, NeedDiamond} ->
			{_IsSupPrize, IndexList, PrizeList} = get_prize(0, Count, {false, [], []}),
			case PrizeList of
				[] ->
					pass;
				_ ->
					% case IsSupPrize of
					% 	true ->
					% 		get_nine_lottery_info();
					% 	_ ->
					% 		pass
					% end,
					game_res:del([{?PL_DIAMOND, NeedDiamond}], ?FLOW_REASON_NINE_LOTTERY),
					ItemList = lists:foldl(
						fun({PrizeId, IsSP}, RetList) ->
								case prize:prize_mail(PrizeId, ?S_MAIL_NINE_LOTTERY_PRIZE, ?FLOW_REASON_NINE_LOTTERY) of
									List when is_list(List) ->
										[{ItemId, Num, IsSP} || {ItemId, Num} <- List] ++ RetList;
									E ->
										?DEBUG_LOG("error:~p", [E]),
										RetList
								end
						end,
						[],
						PrizeList
					),
					?player_send(nine_lottery_sproto:pkg_msg(?MSG_NINE_LOTTERY_GET_PRIZE, {lists:last(IndexList), ItemList})),
					do_nine_lottery_log([{ItemId, Num} || {ItemId, Num, _} <- ItemList])
			end,
			get_nine_lottery_info();
		_ ->
			pass
	end;

handle_client(?MSG_NINE_LOTTERY_RECORD, {Type}) ->
	Data = case Type of
		1 ->	%% 1:全部
			nine_lottery_server:get_all_player_log();
		2 -> 	%% 2:个人
			LogList = get(pd_nine_lottery_log),
			CurNum = length(LogList),
			RetList = case CurNum =< 100 of
				true -> LogList;
				_ -> lists:sublist(LogList, CurNum - 100 + 1, 100)
			end,
			[{Time, get(?pd_id), get(?pd_name), [{ItemId, Num}]} || {Time, ItemId, Num} <- RetList]
	end,
	?player_send(nine_lottery_sproto:pkg_msg(?MSG_NINE_LOTTERY_RECORD, {Data}));

handle_client(_Mod, _Msg) ->
	?ERROR_LOG("_Mod:~p, _Msg:~p", [_Mod, _Msg]),
    ?err(notmatch).

handle_msg(FromMod, Msg) ->
    ?ERROR_LOG("~p recv a unknown msg ~p from ~p", [?pname(), Msg, FromMod]).

get_nine_lottery_info() ->
	{State, List} = nine_lottery_server:get_nine_lottery_info(),
	case State of
		true ->
			RetList = lists:foldl(
				fun({GridIndex, PrizeId, Num, _Weight}, RetList) ->
						{ok, ItemList} = prize:get_prize(PrizeId),
						[{GridIndex, ItemList, Num} | RetList]
				end,
				[],
				List
			),
			?player_send(nine_lottery_sproto:pkg_msg(?MSG_NINE_LOTTERY_INFO, {RetList}));
		_ ->
			?ERROR_LOG("activity end"),
			?player_send(nine_lottery_sproto:pkg_msg(?MSG_NINE_LOTTERY_INFO, {[{0, []}]})),
			ok
	end.

get_prize(Max, Max, Data) -> Data;
get_prize(Min, Max, {IsSupPrize, IndexList, PrizeList}) ->
	Times = get(pd_nine_lottery_times),
	{AccumulatProList, _} = misc_cfg:get_nine_lottery_accumulat_pro(),
	{_, Pro} = lists:max([{T, Val} || {T, Val} <- AccumulatProList, T =< Times]),
	Ret = case nine_lottery_server:get_nine_lottery_prize(Pro) of
		{true, Index, PrizeId} ->
			put(pd_nine_lottery_times, 0),
			{true, [Index | IndexList], [{PrizeId, 1} | PrizeList]};
		{false, Index, PrizeId} ->
			put(pd_nine_lottery_times, Times + 1),
			{IsSupPrize, [Index | IndexList], [{PrizeId, 0} | PrizeList]};
		_ ->
			?ERROR_LOG("nine lottery get prize error, count = :~p", [Min]),
			{IsSupPrize, IndexList, PrizeList}
	end,
	get_prize(Min + 1, Max, Ret).

do_nine_lottery_log(ItemList) ->
	lists:foreach(
		fun({ItemId, Num}) ->
				LogList = get(pd_nine_lottery_log),
				NewLogList = LogList ++ [{com_time:now(), ItemId, Num}],
				put(pd_nine_lottery_log, NewLogList)
		end,
		ItemList
	),
	List = lists:foldl(
		fun({ItemId, Num}, RetList) ->
				case load_item:get_main_type(ItemId) of
					?val_item_main_type_goods ->
					    case load_item:lookup_item_attr_cfg(ItemId) of
					        #item_attr_cfg{quality = Quality} ->
					        	case Quality =:= 3 orelse Quality =:= 4 orelse Quality =:= 5 of
					        		true ->
					        			[{com_time:now(), get(?pd_id), get(?pd_name), [{ItemId, Num}]} | RetList];
					        		_ ->
					        			RetList
					        	end;
					        _ ->
					        	RetList
					    end;
					?val_item_main_type_equip ->
						pass
				end
		end,
		[],
		ItemList
	),
	nine_lottery_server:do_log(List).