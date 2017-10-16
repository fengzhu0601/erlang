%%%-------------------------------------------------------------------
%%% @author yujian
%%% @doc
%%%
%%%-------------------------------------------------------------------
-module(title_service).
-include("inc.hrl").
-include("rank.hrl").
-include_lib("pangzi/include/pangzi.hrl").

-include("title.hrl").
-include("player.hrl").
-include("load_course.hrl").
-include("load_cfg_title.hrl").
-include("load_db_misc.hrl").

-behaviour(gen_server).
-export([start_link/0, init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-export([ 
    get_title/1,
    get_course_boss_prize/1,
    get_course_boss_prize_by_id/1,
    update_player_status_list_by_id/3,
    is_player_status/2,
    is_freeze/2,
    get_boss_challenge_id_of_course_boss_prize/1
    %update_instance_rank_top1/2,
    %get_instance_rank_top1_data/1
]).

-record(state, {}).

-define(TITLE_GLOBAL_DATA_TIMEOUT, element(1, misc_cfg:get_misc_cfg(title_global_info)) * 60 * 1000).
-define(course_boss_prize, course_boss_prize).
-define(SAVE_PLAYER_AND_ACCOUNT_NUM_TIME, 10).
-define(save_player_and_account_num, save_player_and_account_num).
-define(flush_daily_task, flush_daily_task).
% -define(main_ins_rank_no1, main_ins_rank_no1).

-define(TITEL_LIST, [ 
    ?C_ZS, %盾战士
    ?C_FS, %法师  
    ?C_SS, %弓箭手
    ?C_QS, %骑士
    {?ranking_zhanli, zhanli}  
 ]).





%% todo del
% update_instance_rank_top1(FuBenId, {P, F} = NewData) ->
%     %?DEBUG_LOG("update_instance_rank_top1---------:~p--NewData----:~p",[FuBenId, NewData]),
%     case ets:lookup(?main_ins_rank_no1, FuBenId) of
%         [] ->
%             %?DEBUG_LOG("1--------------------------------------------"),
%             ets:insert(?main_ins_rank_no1, {FuBenId, NewData});
%         [{_, {PlayerId, OldF}}] when F > OldF ->
%             ets:insert(?main_ins_rank_no1, NewData);
%         _B ->
%             %?DEBUG_LOG("2--------------------------------------:~p",[_B]),
%             pass
%     end;
% update_instance_rank_top1(_, _) ->
%     pass.

% get_instance_rank_top1_data(FuBenId) ->
%     case ets:lookup(?main_ins_rank_no1, FuBenId) of
%         [] -> 
%             {0, <<>>, 0};
%         [{_, {PlayerId, F}}] -> 
%             [Car, Name] = player:lookup_info(PlayerId, [?pd_career, ?pd_name]),
%             {F, Name, Car}
%     end.




get_title_id_by_titleypte(Type) ->
    case Type of
        ?C_ZS ->
            11;
        ?C_FS ->
            12;
        ?C_SS ->
            13;
        ?C_QS ->
            14;
        {?ranking_zhanli, zhanli} ->
            10
    end.

get_title(MyPlayerId) ->
    NewGlobalTitleList = [],
        %% case dbcache:lookup(?title_global_data, ?global_title_type) of
        %%     [] ->
        %%         [];
        %%     [#title_global_data{title_list = GlobalTitleList}] ->
        %%         [TitleId || {TitleId, PlayerId} <- GlobalTitleList, PlayerId =:= MyPlayerId]
        %% end,
    NewRankTitleList =
        case dbcache:lookup(?title_global_data, ?rank_title_type) of
            [] ->
                [];
            [#title_global_data{title_list = RankTitleList}] ->
                [TitleId || {TitleId, PlayerId} <- RankTitleList, PlayerId =:= MyPlayerId]
        end,
    lists:umerge(NewGlobalTitleList,NewRankTitleList).

get_course_boss_prize(List) ->
    lists:foldl(fun(Cbp, Acc) ->
        Id = Cbp#course_boss_prize.boss_challenge_id,
        case lists:member(Id, List) of
            ?false ->
                Acc;
            _ ->
                Cbp#course_boss_prize.prize_id ++ Acc
                %PrizeId = Cbp#course_boss_prize.prize_id,
                %case prize:get_course_prize(PrizeId) of
                %    none ->
                %        Acc;
                %    {GoodId, Count} ->
                %        [{Id, GoodId, Count}|Acc]
                %end
        end
    end,
    [],
    ets:tab2list(course_boss_prize)).

get_course_boss_prize_by_id(Id) ->
    case ets:lookup(?course_boss_prize, Id) of
        [] ->
            0;
        [#course_boss_prize{prize_id=PrizeId}] ->
            PrizeId
    end.

get_boss_challenge_id_of_course_boss_prize(Id) ->
    case ets:lookup(?course_boss_prize, Id) of
        [] ->
            0;
        [#course_boss_prize{boss_challenge_id=BossChallengeId}] ->
            BossChallengeId
    end.

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

init([]) ->
    %?DEBUG_LOG("title_service----------------------------------"),
    ets:new(?course_boss_prize, [public,set,named_table,{keypos, #course_boss_prize.id}]),
    %ets:new(?main_ins_rank_no1, [?named_table, ?public, {?write_concurrency, ?true}, {?read_concurrency, ?true}]),

    init_course_boss_prize(),
    M = com_time:get_seconds_to_next_day(),
    DailyTaskTime = com_time:get_seconds_to_next_day(5),
    erlang:send_after(M * 1000, self(), reset_course_boss_prize),
    erlang:send_after(?SAVE_PLAYER_AND_ACCOUNT_NUM_TIME * 1000, self(), ?save_player_and_account_num),
    %% erlang:send_after(?TITLE_GLOBAL_DATA_TIMEOUT, self(), global_server_title),
    erlang:send_after(DailyTaskTime * 1000, self(), ?flush_daily_task),

    {ok, #state{}}.

init_course_boss_prize() ->
    lists:foreach(fun({_, Cbp}) ->
        Id = Cbp#boss_challenge_cfg.id,
        InsId = Cbp#boss_challenge_cfg.ins_id,
        PrizeList = Cbp#boss_challenge_cfg.prize_list,
        PrizeId = lists:nth(1, PrizeList),
        {ok, ItemList} = prize:get_prize(PrizeId),
        {GoodId, Count} = lists:nth(1, ItemList),
        NewItemList = [{Id, GoodId, Count}],
        ets:insert(?course_boss_prize, #course_boss_prize{id=InsId, boss_challenge_id=Id, prize_id=NewItemList})
    end,
    ets:tab2list(boss_challenge_cfg)).


handle_call({add_rank_title, NewList2}, _From, State) ->
    OldTitleList = get_rank_title(),
    NewTitleList =
        lists:foldl(
            fun({Tid, Pid}, Acc) ->
                world:send_to_player_any_state(Pid, ?mod_msg(title_mng, {add_rank_title_id, Tid})),
                [{Tid, Pid} | Acc]
            end,
            OldTitleList,
            NewList2),

    dbcache:update(?title_global_data,
        #title_global_data{id = ?rank_title_type,
            title_list = NewTitleList,
            old_title_list = OldTitleList}),

    {reply, ok, State, player_eng:get_next_timeout()};

handle_call(_Request, _From, State) ->
    {reply, ok, State}.

handle_cast(_Request, State) ->
    {reply, ok, State}.

handle_info(?flush_daily_task, State) ->
    world:broadcast(?mod_msg(task_mng_new, {?flush_daily_task})),
    {noreply, State};


handle_info(reset_course_boss_prize, State) ->
    init_course_boss_prize(),
    M = com_time:get_seconds_to_next_day(),
    erlang:send_after(M * 1000, self(), reset_course_boss_prize),
    {noreply, State};


handle_info(global_server_title, State) ->
    %?DEBUG_LOG("title service timeout----------------------------"),
    NewList2 = 
    lists:foldl(
        fun
            (Role, List) ->
                %?DEBUG_LOG("data-------------:~p",[Role]),
                if
                    Role =:= {?ranking_zhanli, zhanli} ->
                        case ranking_lib:get_top1_by_name(?ranking_zhanli, 1) of
                            0 ->
                                List;
                            PlayerId2 ->
                                AllServerTop1OfZhanliTitleId = get_title_id_by_titleypte({?ranking_zhanli, zhanli}),
                                [{AllServerTop1OfZhanliTitleId, PlayerId2} | List]
                        end;
                    true ->
                        case ranking_lib:get_top1_by_zhanli_and_role(?ranking_zhanli, Role) of
                            pass ->
                                List;
                            {PlayerId, _}->
                                TitelId = get_title_id_by_titleypte(Role),
                                [{TitelId , PlayerId} | List]
                        end
                end
          
    end,    
    [],
    ?TITEL_LIST),
    %?DEBUG_LOG("NewList2-----------------------:~p",[NewList2]),
    OldTitleList = get_global_title(),
    NewTitleList =
    lists:foldl(fun({Tid, Pid}, Acc) ->
        case lists:keyfind(Tid, 1, OldTitleList) of
            false ->
                world:send_to_player_any_state(Pid, ?mod_msg(title_mng, {add_global_title_id, Tid})),
                [{Tid, Pid} | Acc];
            {_, Pid} ->
                Acc;
            {_, Pid2} ->
                world:send_to_player_any_state(Pid2, ?mod_msg(title_mng, {del_old_global_title_id, Tid})),
                world:send_to_player_any_state(Pid, ?mod_msg(title_mng, {add_global_title_id, Tid})),
                [{Tid, Pid} | Acc]
        end
    end,
    [],
    NewList2),


    dbcache:update(?title_global_data,
        #title_global_data{id = ?global_title_type,
            title_list = NewTitleList,
            old_title_list = OldTitleList}),
    erlang:send_after(?TITLE_GLOBAL_DATA_TIMEOUT, self(), global_server_title),
    {noreply, State};

handle_info(?save_player_and_account_num, State) ->
    op_player:save_player_and_account_num(),
    op_player:save_online_player_and_account_count(),
    erlang:send_after(?SAVE_PLAYER_AND_ACCOUNT_NUM_TIME * 1000, self(), ?save_player_and_account_num),
    {noreply, State};

handle_info(_Info, State) ->
    {noreply, State}.


terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

load_db_table_meta() ->
    [
        #db_table_meta{name = ?title_global_data,
            fields = ?record_fields(title_global_data),
            load_all = ?true,
            shrink_size = 1,
            flush_interval = 5},
        #db_table_meta{name = ?player_status_tab,
            fields = ?record_fields(player_status_tab),
            load_all = ?true,
            shrink_size = 1,
            flush_interval = 5}
    ].

get_global_title() ->
    case dbcache:lookup(?title_global_data, ?global_title_type) of
        [] -> 
            [];
        [#title_global_data{title_list = TitleList}] ->
            TitleList
    end.

get_rank_title() ->
    case dbcache:lookup(?title_global_data, ?rank_title_type) of
        [] ->
            [];
        [#title_global_data{title_list = TitleList}] ->
            TitleList
    end.

update_player_status_list_by_id(Id, 1, PlayerList) ->
    ?DEBUG_LOG("title_service--1----Id, PlayerList-----------:~p",[{Id, PlayerList}]),
    NewPlayerList = 
    case dbcache:lookup(?player_status_tab, Id) of
        [] ->
            PlayerList;
        [#player_status_tab{list = List}] ->
            lists:umerge(PlayerList, List)
    end,
    dbcache:update(?player_status_tab,
                    #player_status_tab{
                        id = Id,
                        list = NewPlayerList
                    });

update_player_status_list_by_id(Id, 0, PlayerList) ->
    ?DEBUG_LOG("title_service---0---Id, PlayerList-----------:~p",[{Id, PlayerList}]),
    NewPlayerList = 
    case dbcache:lookup(?player_status_tab, Id) of
        [] ->
            [];
        [#player_status_tab{list = List}] ->
            List -- PlayerList
    end,
    dbcache:update(?player_status_tab,
                    #player_status_tab{
                        id = Id,
                        list = NewPlayerList
                    }).

is_player_status(Id, PlayerId) ->
    % ?DEBUG_LOG("title_service-------Id ,PlayerId------:~p",[{Id, PlayerId}]),
    case dbcache:lookup(?player_status_tab, Id) of
        [] ->
            false;
        [#player_status_tab{list = List}] ->
            lists:member(PlayerId, List)
    end.

is_freeze(Id, PlayerId) ->
    case get(?pd_id) of
        undefined ->
            is_player_status(Id, PlayerId);
        _ ->
            false
    end.