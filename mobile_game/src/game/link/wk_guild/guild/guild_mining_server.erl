%%-----------------------------------
%% @Module  : guild_mining_server
%% @Author  : Henry
%% @Email   : 
%% @Created : 2016.12.3
%% @Description: guild_mining_server
%%-----------------------------------
-module(guild_mining_server).
-behaviour(gen_server).

-include("inc.hrl").
-include("guild_struct.hrl").
-include("player.hrl").
-include("game.hrl").
-include("guild_mining_server.hrl").
-include_lib("pangzi/include/pangzi.hrl").

-define(guild_mining_state, guild_mining_state).
-record(state,{
	id = guild_mining,
	guild_minging_state_list = []
	% guild_id = 0,
	% player_id_list = [],
	% end_time = 0
	}).

%% gen_server callbacks
-export([
	init/1,
	handle_call/3,
	handle_cast/2,
	handle_info/2,
	terminate/2,
	code_change/3
	]).

%% Module Interface
-export([
	start_link/0,
	join_mining/3,
	get_mining_info/1,
	delete_player/2
	]).

%% ===================================================================
%% Module Interface
%% ===================================================================
start_link() ->
	gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

%% player join mining
join_mining(GuildId, Index, PlayerId) ->
	gen_server:call(?MODULE, {'join_mining', GuildId, Index, PlayerId}).

%% get mining player info
get_mining_info(GuildId) ->
	gen_server:call(?MODULE,{'get_mining_info', GuildId}).

delete_player(GuildId, PlayerId) ->
	gen_server:call(?MODULE, {'delete_player', GuildId, PlayerId}).

%% ===================================================================
%% gen_server callbacks
%% ===================================================================
init([]) ->
	process_flag(trap_exit, ?true),
	{State, AcceptSendPrizeGuilds} = init_mining(),
	% ?DEBUG_LOG("AcceptSendPrizeGuilds-------------------------------:~p",[AcceptSendPrizeGuilds]),
	lists:foreach(fun(GuildId) ->
		%self() ! {'MINING_PRIZE', Id}
		erlang:send_after(2000, self(), {'MINING_PRIZE', GuildId})
	end,
	AcceptSendPrizeGuilds),
	{ok, State}.

handle_call({'join_mining', GuildId, Index, PlayerId}, _From, State) ->
	GuildMiningStateList =  State#state.guild_minging_state_list,
	case lists:keyfind(GuildId, 1, GuildMiningStateList) of
		{GuildId, PlayerList, EndTime} ->
			case erlang:length(PlayerList) of
				3->
					NewPlayerIdList = [{Index, PlayerId} | PlayerList],
					{_, NewPlayerList} = lists:unzip(NewPlayerIdList),
					lists:foreach(fun(Id) ->
							case dbcache:load_data(?player_guild_member, Id) of
								[] ->
									?ERROR_LOG("load player_guild_member failed");
								[#player_guild_member{lv=GulidLv}] ->
									[PrizeList, GuildExpList, OfferExpList] = load_cfg_mining_prize:get_prize(GulidLv),
									{4, PrizeId} = lists:keyfind(4, 1, PrizeList),		% 奖励物品id
									{4, GuildExp} = lists:keyfind(4, 1, GuildExpList),		% 奖励公会经验值
									{4, OfferExp} = lists:keyfind(4, 1, OfferExpList),		% 奖励个人贡献值
									%  发奖
									world:send_to_player_any_state(Id, ?mod_msg(guild_mining_mng, {send_prize, PrizeId, GuildExp, OfferExp})),
									world:send_to_player(NewPlayerList, ?mod_msg(guild_mining_mng, {push_guild_info}))
							end
					end,
					NewPlayerList),
					NewGuildMiningStateList = lists:keydelete(GuildId, 1, GuildMiningStateList),
					NewState =  State#state{guild_minging_state_list = NewGuildMiningStateList},
					{reply, ok, NewState};
				_ ->
					NewPlayerIdList = [{Index, PlayerId} | PlayerList],
					{_, NewPlayerList} = lists:unzip(NewPlayerIdList),
					world:send_to_player(NewPlayerList, ?mod_msg(guild_mining_mng, {push_guild_info})),
					NewGuildMiningStateList =  lists:keyreplace(GuildId, 1, GuildMiningStateList, {GuildId,NewPlayerIdList,EndTime}),
					NewState = #state{id = guild_mining, guild_minging_state_list = NewGuildMiningStateList},
					% ?INFO_LOG("NewState-----------~p",[NewState]),
					{reply, ok, NewState}
			end;
		_ ->
			erlang:send_after(?START_MINING_TIME * 1000, ?MODULE, {'MINING_PRIZE', GuildId}),
			EndTime = com_time:now() + ?START_MINING_TIME,
			NewGuildMiningStateList = [{GuildId,[{Index, PlayerId}],EndTime} | GuildMiningStateList],
			NewState = #state{id = guild_mining, guild_minging_state_list = NewGuildMiningStateList},
			{reply, ok, NewState}
	end;
handle_call({'get_mining_info', GuildId}, _From, State) ->
	GuildMiningStateList =  State#state.guild_minging_state_list,
	Reply =
		case lists:keyfind(GuildId, 1, GuildMiningStateList) of
			{GuildId, PlayerList, EndTime} ->
				{GuildId, PlayerList, EndTime};
			_ ->
				0
		end,
	{reply,Reply, State};
handle_call({'delete_player', GuildId, PlayerId}, _From, State) ->
	GuildMiningStateList =  State#state.guild_minging_state_list,
	NewGuildMiningStateList =
		case lists:keyfind(GuildId, 1, GuildMiningStateList) of
			{GuildId, PlayerList, EndTime} ->
				NewPlayerList = lists:keydelete(PlayerId, 2, PlayerList),
				lists:keyreplace(GuildId, 1, GuildMiningStateList, {GuildId, NewPlayerList, EndTime});
			_ ->
				?ERROR_LOG("can not find the player")
		end,
	NewState = State#state{guild_minging_state_list = NewGuildMiningStateList},
	{reply, ok, NewState};
handle_call(_Request, _From, State) ->
	?ERROR_LOG("receive unknown call msg:~p", [_Request]),
	{reply, error, State}.

handle_cast(_Msg, State) ->
	?ERROR_LOG("receive unknown cast msg:~p", [_Msg]),
	{noreply, State}.


%% send prize
handle_info({'MINING_PRIZE', GuildId}, State) ->
	% ?DEBUG_LOG("-------State: ~p", [State]),
	GuildMiningStateList =  State#state.guild_minging_state_list,
	case lists:keyfind(GuildId, 1, GuildMiningStateList) of
		{GuildId, PlayerIdList, _EndTime} ->
			Len = erlang:length(PlayerIdList),
			{_, PlayerList} = lists:unzip(PlayerIdList),
			% ?DEBUG_LOG("----------PlayerIdList----~p",[PlayerIdList]),
			% ?DEBUG_LOG("----------PlayerList----~p",[PlayerList]),
			lists:foreach(fun(Id) ->
					case dbcache:load_data(?player_guild_member, Id) of
						[] ->
							?ERROR_LOG("load player_guild_member failed");
						[#player_guild_member{lv=GulidLv}] ->
							[PrizeList, GuildExpList, OfferExpList] = load_cfg_mining_prize:get_prize(GulidLv),
							{Len, PrizeId} = lists:keyfind(Len, 1, PrizeList),
							{Len, GuildExp} = lists:keyfind(Len, 1, GuildExpList),
							{Len, OfferExp} = lists:keyfind(Len, 1, OfferExpList),
							%  发奖
							% guild_mining_mng:send_prize(PrizeId, GuildExp, OfferExp)
							world:send_to_player_any_state(Id, ?mod_msg(guild_mining_mng, {send_prize, PrizeId, GuildExp, OfferExp}))
					end
			end,
			PlayerList),
			world:send_to_player(PlayerList, ?mod_msg(guild_mining_mng, {push_guild_info})),
			NewGuildMiningStateList = lists:keydelete(GuildId, 1, GuildMiningStateList),
			NewState =  State#state{guild_minging_state_list=NewGuildMiningStateList},
			{noreply, NewState};
		_ ->
			?ERROR_LOG("get info error"),
			{noreply, State}
	end;
handle_info(_Info, State) ->
	{noreply, State}.

terminate(_Reason, State) ->
	?INFO_LOG("process shutdown of reason = ~p", [_Reason]),
	mnesia:dirty_write(?guild_mining_state, State),
	ok.

code_change(_OldVsn, State, _Extra) ->
	{ok, State}.

load_db_table_meta() ->
	[
		#db_table_meta
		{
			name = ?guild_mining_state,
			fields = record_info(fields, state),
			record_name = state,
			load_all = true,
			shrink_size = 1,
			flush_interval = 3
		}
	].

init_mining() ->
	CurTIme = com_time:now(),
	case dbcache:lookup(?guild_mining_state, guild_mining) of
		[#state{guild_minging_state_list = GuildMiningStateList}] = [State] ->
			%NewGuildMiningStateList =
			% 需要发放奖励的公会列表
			AcceptSendPrizeGuilds = 
				lists:foldl(
					fun({GuildId, PlayerList,EndTime}, Acc) ->
						if
							CurTIme =< EndTime ->
								Time = EndTime - CurTIme,
								erlang:send_after(Time * 1000, ?MODULE, {'MINING_PRIZE', GuildId}),
								Acc;
								% lists:keyreplace(GuildId, 1, GuildMiningStateList, {GuildId, PlayerList, EndTime});
							true ->
								% lists:foreach(fun(Id) ->
								% 	mail_mng:send_sysmail(Id, ?S_MAIL_GUILD_MINING_PRIZE, PrizeList)
								% end,
								% PlayerList)
								%self() ! {'MINING_PRIZE', GuildId},
								%lists:keydelete(GuildId, 1, Acc)
								[GuildId | Acc]
						end
				end,
				[],
				GuildMiningStateList),
			%NewState =  State#state{guild_minging_state_list = NewGuildMiningStateList};
			{State, AcceptSendPrizeGuilds};
		_ ->
			{#state{id = guild_mining, guild_minging_state_list = []}, []}
			% #state{id=guild_mining,guild_id=0,player_id_list=[]}
	end.
