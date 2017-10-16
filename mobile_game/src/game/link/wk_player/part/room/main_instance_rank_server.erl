-module(main_instance_rank_server).



-export([start_link/0,init/1,handle_call/3, handle_cast/2, handle_info/2, code_change/3, terminate/2]).

-behaviour(gen_server).

-include("inc.hrl").


-include("main_ins_struct.hrl").
-include("main_ins_mng_reply.hrl").
-include("load_cfg_main_ins.hrl").

-export([
]).

-record(data, {
	rank_data=[]
}).


start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

init([]) ->
	MinsCfgData = misc_cfg:get_timer_renovating(),
	Data = 
	lists:foldl(fun({Type, T}, A) ->
		[{Type, T, []}|A]
	end,
	[],
	MinsCfgData),
	lists:foreach(fun({Type, T, _D}) ->
        erlang:send_after(T * ?SECONDS_PER_MINUTE * 1000, self(), {rank_main_ins, Type})
	end,
	Data),
    {ok, #data{rank_data=Data}}.


handle_call(_Msg, _, State) ->
    {noreply, State}.

handle_info({rank_main_ins, Type}, State) ->
	Data = State#data.rank_data,
	case lists:keyfind(Type, 1, Data) of
		?false ->
			pass;
		{_, T, List} ->
			lists:foreach(fun(FubenId) ->
				case dbcache:lookup(?player_main_ins_rank, FubenId) of
			        [] ->
			            pass;
			        [#main_ins_rank{rank_list = RankList}] ->
			            L = lists:keysort(2, RankList),
			            L2 = lists:reverse(L),
			            dbcache:update(?player_main_ins_rank,
			      			#main_ins_rank{
			                scene_id = FubenId,
			                rank_list = L2})
			    end
			end,
			List),
			erlang:send_after(T * ?SECONDS_PER_MINUTE * 1000, self(), {rank_main_ins, Type})
	end,
	{noreply, State};    

handle_info({add_m_ins_id, MainId}, State) ->
	Data = State#data.rank_data,
	NewState = 
	case load_cfg_main_ins:get_ins_sub_type(MainId) of
		?none ->
			State;
		Type ->
			case lists:keyfind(Type, 1, Data) of
				?false ->
					State;
				{_, T, List} ->
					NewList = 
					case lists:member(MainId, List) of
						?false ->
							[MainId|List];
						?true ->
							List
					end,
					NewData = lists:keyreplace(Type, 1, Data, {Type,T,NewList}),
					State#data{rank_data=NewData}
			end
	end,
	{noreply, NewState};    

handle_info(Msg, State) ->
    {noreply, State}.

handle_cast(Msg, State) ->
    {noreply, State}.

code_change(_, _, State) ->
    {ok, State}.

terminate(Reason,State) ->
    ok.
