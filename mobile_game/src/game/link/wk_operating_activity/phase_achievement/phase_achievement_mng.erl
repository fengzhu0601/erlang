-module (phase_achievement_mng).
%% API
-export([
	do_pc/2,
	do_pc/3,
	get_pc_goal_by_goaltype/1
]).


-include("inc.hrl").
-include("player.hrl").
-include_lib("pangzi/include/pangzi.hrl").
-include("player_mod.hrl").
-include("handle_client.hrl").
-include("operating_activity.hrl").
-include("load_phase_ac.hrl").
-include("system_log.hrl").

do_pc(_, 0) ->
	pass;
do_pc(GoalType, Count) when GoalType > 0 ->
	%?DEBUG_LOG("GoalType------:~p-----Count----:~p",[GoalType, Count]),
	GoalList = get(?pd_pc_goal_list),
	%?DEBUG_LOG("GoalList------------------:~p",[GoalList]),
	%{NewGoalList, Total} =  
	case lists:keyfind(GoalType, 1, GoalList) of
		?false ->
			?ERROR_LOG("GoalType error------------------------:~p",[GoalType]);
		{_, GoalId, MaxCount, OldCount} ->
			NewCount = OldCount + Count,
			NewGoalList = lists:keyreplace(GoalType, 1, GoalList, {GoalType, GoalId, MaxCount, NewCount}),
			put(?pd_pc_goal_list, NewGoalList),
			%?DEBUG_LOG("GoalType-------------:~p-----Count---:~p",[GoalType, Count]),
			?player_send(phase_achievement_sproto:pkg_msg(?MSG_PHASE_ACHIEVEMENT_PROGRESS, {GoalType, NewCount})),
			update_pc_status()
	end;
	

do_pc(GoalType, _) ->
	?ERROR_LOG("phase_achievement_mng error GoalType----------------:~p",[GoalType]). 

do_pc(GoalType, GoalId, Count) when GoalId > 0 andalso Count > 0->
	%?DEBUG_LOG("do pc 3---------GoalType--:~p-----GoalId----:~p-----Count---:~p",[GoalType, GoalId, Count]),
	GoalList = get(?pd_pc_goal_list),
	A = 
	case lists:keyfind(GoalType, 1, GoalList) of
		?false ->
			?false;
		{_, CfgGoal, MaxCount, OldCount} when CfgGoal =:= GoalId ->
			%?DEBUG_LOG("CfgGoal---------------------:~p",[CfgGoal]),
			NewCount = erlang:max(OldCount, Count),
			{lists:keyreplace(GoalType, 1, GoalList, {GoalType, CfgGoal, MaxCount, NewCount}), NewCount};
		{_, CfgGoal, MaxCount, OldCount} ->
			%?DEBUG_LOG("do_pc-------------------------------"),
			if
				GoalId =:= 10000; GoalId =:= 10001; GoalId =:= 10002; GoalId =:= 10003 ->
					NewCount = erlang:max(OldCount, Count),
 					?DEBUG_LOG("GoalType------:~p-----GoalId----:~p",[MaxCount, Count]),
					{lists:keyreplace(GoalType, 1, GoalList, {GoalType, CfgGoal, MaxCount, NewCount}), NewCount};
				true ->
					?false
			end;
		_Aa ->
			?ERROR_LOG("_Aa--------------------------:~p",[_Aa]),
			?false
	end,
	case A of
		?false ->
			pass;
		{NewGoalList, Total} ->
 			% ?DEBUG_LOG("MSG_PHASE_ACHIEVEMENT_PROGRESS  --------------:~p",[{GoalType, Total}]),
			put(?pd_pc_goal_list, NewGoalList),
			?player_send(phase_achievement_sproto:pkg_msg(?MSG_PHASE_ACHIEVEMENT_PROGRESS, {GoalType, Total})),
			update_pc_status()
	end;
do_pc(_GoalType, _GoalId, _Count) ->
	ok.
	%?ERROR_LOG("phase_achievement_mng error GoalType-- :~p-----GoalId---------:~p--Count---:~p",[GoalType, GoalId, Count]). 


get_pc_goal_by_goaltype(GoalType) ->
	GoalList = get(?pd_pc_goal_list),
	case lists:keyfind(GoalType, 1, GoalList) of
		?false ->
			pass;
		{_, GoalId,_, _} ->
			GoalId
	end.

init_pc_goal_list() ->
	lists:foldl(fun({_, Pac}, List) ->
        GoalList = Pac#phase_achievement_cfg.goal_list,
        do_init_pc_goal_list(GoalList, List) 
    end,
    [],
    ets:tab2list(phase_achievement_cfg)).

do_init_pc_goal_list(List, GoalTypeList) ->
	lists:foldl(fun({GoalType, GoalId, MaxCount}, L) ->
        case lists:keyfind(GoalType, 1, L) of
        	?false ->
        		if
        			GoalType =:= ?PHASE_AC_LEVEL ->
        				[{GoalType, GoalId, MaxCount, 1}|L];
        			true ->
        				[{GoalType, GoalId, MaxCount, 0}|L]
        		end;
        	_ ->
        		L
        end
    end,
    GoalTypeList,
    List).

update_pc_status() ->
	TableSize = com_ets:table_size(phase_achievement_cfg),
	PcIdList = lists:seq(1, TableSize),
	do_update_pc_status(PcIdList),
	ok.
do_update_pc_status([]) ->
	pass;
do_update_pc_status([Id|T]) ->
	case load_phase_ac:get_phase_achievement_cfg(Id) of
		L when is_list(L) ->
			case next_do_update_pc_status(L) of
				?true ->
					set_pc_prize_status(Id);
				?false ->
					pass
			end,
			do_update_pc_status(T);
		_ ->
			pass
	end.

next_do_update_pc_status([]) ->
	?true;
next_do_update_pc_status([{?PHASE_AC_ARENA_RANK, _GoalId, MaxCount} | T]) ->
	GoalList = get(?pd_pc_goal_list),
	case lists:keyfind(?PHASE_AC_ARENA_RANK, 1, GoalList) of
		?false ->
			?false;
		{_, _, _, OldCount} when OldCount =< MaxCount ->
			next_do_update_pc_status(T);
		_ ->
			?false
	end;
next_do_update_pc_status([{GoalType, _GoalId, MaxCount} | T]) ->
	GoalList = get(?pd_pc_goal_list),
	case lists:keyfind(GoalType, 1, GoalList) of
		?false ->
			?false;
		{_, _, _, OldCount} when OldCount >= MaxCount ->
			next_do_update_pc_status(T);
		_ ->
			?false
	end.

set_pc_prize_status(Id) ->
	PcPirzeList = get(?pd_pc_prize),
	NewPcPrizeList = 
	case lists:keyfind(Id, 1, PcPirzeList) of
		?false ->
			system_log:info_phase_achievement(Id),
			[{Id, 1}|PcPirzeList];
		_ ->
			PcPirzeList
	end,
	put(?pd_pc_prize, NewPcPrizeList).

update_pc_prize_status(Id, Status) ->
	PcPirzeList = get(?pd_pc_prize),
	%NewPcPrizeList = 
	case lists:keyfind(Id, 1, PcPirzeList) of
		%?false ->
		%	PcPirzeList;
		{Id, 1} ->
			put(?pd_pc_prize, lists:keyreplace(Id, 1, PcPirzeList, {Id, Status})),
			?true;
		_ ->
			?false
	end.
	%put(?pd_pc_prize, NewPcPrizeList).

send_pc_prize_of_jieduan(JieDuan) ->
	case update_pc_prize_status(JieDuan, 2) of
		?false ->
			?DEBUG_LOG("send_pc_prize_of_jieduan -------------2----------"),
			pass;
		?true ->
			case load_phase_ac:get_phase_achievement_prize(JieDuan) of
				?false ->
					?DEBUG_LOG("send_pc_prize_of_jieduan -------------2----------"),
					pass;
				PrizeId ->
					?DEBUG_LOG("PrizeId---------------------------:~p",[PrizeId]),
					update_pc_prize_status(JieDuan, 2),
					player_data_db:update_pc_prize(JieDuan),
					prize:prize_mail(PrizeId, ?S_MAIL_JIEDUAN_CHENGJIU_PRIZE, ?FLOW_REASON_PHASE_ACHIEVEMENT),
					?player_send(phase_achievement_sproto:pkg_msg(?MSG_PHASE_ACHIEVEMENT_GET_PRIZE, {}))
			end
	end.




handle_client({Pack, Arg}) ->
    handle_client(Pack, Arg).

handle_client(?MSG_PHASE_ACHIEVEMENT_LIST, {}) ->
	PcList = get(?pd_pc_goal_list),
	StatusList = get(?pd_pc_prize),
	NewPcList = 
	lists:foldl(fun({GoalType, _GoalId, _MaxCount, Count}, L) when Count > 0 ->
						[{GoalType, Count}|L];
				(_, L) ->
						L				
	end,
	[],
	PcList),
	%?DEBUG_LOG("NewPcList------:~p------StatusList---:~p",[NewPcList, StatusList]),
	?player_send(phase_achievement_sproto:pkg_msg(?MSG_PHASE_ACHIEVEMENT_LIST, {NewPcList, StatusList}));

handle_client(?MSG_PHASE_ACHIEVEMENT_GET_PRIZE, {JieDuan}) ->
	?DEBUG_LOG("JieDuan-----------------------:~p",[JieDuan]),
	send_pc_prize_of_jieduan(JieDuan),
	ok;

handle_client(_Msg, _Arg) ->
    ok.

handle_msg(FromMod, Msg) ->
    ?ERROR_LOG("~p recv a unknown msg ~p from ~p", [?pname(), Msg, FromMod]).


create_mod_data(PlayerId) ->
	GoalTypeList = init_pc_goal_list(),
	%?DEBUG_LOG("GoalTypeList------------------:~p",[GoalTypeList]), 
    case dbcache:insert_new(?player_pc_goal_tab, #player_pc_goal_tab{id=PlayerId, list=GoalTypeList}) of
        true ->
            ok;
        false ->
            ?ERROR_LOG("create ~p module ~p data is already_exist", [PlayerId, ?MODULE])
    end,
    case dbcache:insert_new(?player_pc_prize_tab, #player_pc_prize_tab{id=PlayerId}) of
        true ->
            ok;
        false ->
            ?ERROR_LOG("create ~p module ~p data is already_exist", [PlayerId, ?MODULE])
    end,
    ok.

load_mod_data(PlayerId) ->
    case dbcache:load_data(?player_pc_goal_tab, PlayerId) of
        [] ->
            create_mod_data(PlayerId),
            load_mod_data(PlayerId);
        [#player_pc_goal_tab{list=GoalList}] ->
            put(?pd_pc_goal_list, GoalList)
    end,
  	case dbcache:load_data(?player_pc_prize_tab, PlayerId) of
    	[] ->
        	create_mod_data(PlayerId),
        	load_mod_data(PlayerId);
    	[#player_pc_prize_tab{list=PrizeList}] ->
        	put(?pd_pc_prize, PrizeList)
    end,
    ok.

init_client() ->
    ok.


save_data(PlayerId) ->
    dbcache:update(?player_pc_goal_tab, 
                   #player_pc_goal_tab{
                      id=PlayerId,
                      list=get(?pd_pc_goal_list)
                     }),
    dbcache:update(?player_pc_prize_tab, 
                   #player_pc_prize_tab{
                      id=PlayerId,
                      list=get(?pd_pc_prize)
                     }),
    ok.

online() ->
    ok.
offline(_PlayerId) ->
    ok.
handle_frame(_) -> ok.

view_data(Acc) -> Acc.


load_db_table_meta() ->
    [
        #db_table_meta{
            name = ?player_pc_goal_tab,
            fields = ?record_fields(player_pc_goal_tab),
            shrink_size = 1,
            flush_interval = 3
        },

        #db_table_meta{
            name = ?player_pc_prize_tab,
            fields = ?record_fields(player_pc_prize_tab),
            shrink_size = 1,
            flush_interval = 3
        }

    ].
