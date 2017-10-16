-module(achievement_mng).
%%% coding:utf-8
%%%-------------------------------------------------------------------
%%% @author dsl
%%% @doc 成就系统
%%%
%%% @end
%%%-------------------------------------------------------------------

-include_lib("pangzi/include/pangzi.hrl").
%-include_lib("config/include/config.hrl").


-include("inc.hrl").
-include("player.hrl").
-include("achievement.hrl").
-include("player_mod.hrl").
-include("handle_client.hrl").
-include("main_ins_struct.hrl").
-include("rank.hrl").
-include("load_cfg_achievement.hrl").
-include("system_log.hrl").


-define(zishenwanjia_init, zishenwanjia_init).


-export([
    do_ac/1,
    do_ac2/3,
    init_instance_ac/2,
    complete_instance_ac/1,
    get_total_star/5
]).



get_ac_prize(AcList, AchievementId) ->
    case lists:keyfind(AchievementId, 2, AcList) of
        ?false ->
            ?return_err(?ERR_ACC_THIS_ACCID_NOT_ACCEPT);
        #ac{id = Id, is_get_prize_star = GetCount, star = Star} = Ac ->
            NewGetCount = GetCount + 1,
            if
                NewGetCount > Star ->
                    ?return_err(?ERR_ACC_CHECH_ERR);
                true ->
                    case load_cfg_achievement:get_ac_cfg(Id) of
                        ?none ->
                            pass;
                        Cfg ->
                            PrizeId = lists:nth(NewGetCount, Cfg#achievement_cfg.reward),
                            prize:prize(PrizeId, ?FLOW_REASON_ACHIEVEMENT),
                            NewAc = Ac#ac{is_get_prize_star = NewGetCount},
                            NewList = lists:keyreplace(AchievementId, 2, AcList, NewAc),
                            %?DEBUG_LOG("NewList---------------------:~p",[NewList]),
                            put(?pd_ac_list, NewList),
                            ?player_send(accomplishments_sproto:pkg_msg(?MSG_ACCOMPLISHMENT_EXTRACT_REWARD, {AchievementId, NewGetCount}))
                    end
            end
    end.


do_ac(AchievementId) ->
    case get(?pd_ac_list) of
        ?undefined ->
            pass;
        AcList ->
            case lists:keyfind(AchievementId, 2, AcList) of
                ?false ->
                    %?DEBUG_LOG("ac false ----------------------------"),
                    pass;
                #ac{star = 3} ->
                    pass;
                #ac{star = Star, current_value = CurrentValue, max_value = MaxValue} = Ac ->
                    NewCurrentValue = CurrentValue + 1,
                    %?DEBUG_LOG("Ac-------------------:~p",[Ac]),
                    Star2 = do_star_by_goal(NewCurrentValue, MaxValue, 0),
                    NewStar =
                        if
                            Star2 > Star ->
                                Star2;
                            true ->
                                Star
                        end,
                    %?DEBUG_LOG("AchievementId-----:~p---Star2-----:~p---NewStar---:~p---NewCurrentValue--:~p",[AchievementId,Star2, NewStar, NewCurrentValue]),
                    NewAc = Ac#ac{star = NewStar, current_value = NewCurrentValue},
                    NewList = lists:keyreplace(AchievementId, 2, AcList, NewAc),
                    ?player_send(accomplishments_sproto:pkg_msg(?MSG_ACCOMPLISHMENTS_ACHIEVEMENT_CHANGE,
                        {AchievementId,
                            NewStar,
                            NewCurrentValue})),
                    put(?pd_ac_list, NewList),
                    update_all_ac_star(),
                    case load_cfg_achievement:get_ac_title_cfg(AchievementId) of
                        ?none ->
                            pass;
                        ?undefined ->
                            pass;
                        Title ->
                            %?DEBUG_LOG("Title------------:~p",[Title]),
                            if
                                NewStar > 0 ->
                                    TitleId = lists:nth(NewStar, Title),
                                    title_mng:add_title(TitleId);
                                true ->
                                    pass
                            end
                    end
            end
    end.
do_ac2(_, _, 0) ->
    pass;
do_ac2(AchievementId, EventGoal, Count) ->
    %?DEBUG_LOG("AchievementId, EventGoal, Count--------------:~p",[{AchievementId, EventGoal, Count}]),
    case get(?pd_ac_list) of
        ?undefined ->
            pass;
        AcList ->
            case lists:keyfind(AchievementId, 2, AcList) of
                ?false ->
                    %?DEBUG_LOG("1--------------------------"),
                    pass;
                #ac{star = 3} ->
                    %?DEBUG_LOG("2----------------------------"),
                    pass;
                #ac{star = Star, event_goal = Eg, current_value = CurrentValue, max_value = MaxValue} = Ac ->
                    if
                        EventGoal =:= Eg; EventGoal =:= 0 ->
                            NewCurrentValue = 
                            case AchievementId of
                                ?lianjidashi ->
                                    Count;
                                ?zuiqiangzhanli ->
                                    Count;
                                ?taozhuangzhishen ->
                                    Count;
                                ?yishenshenzhuang ->
                                    Count;
                                _ ->
                                    CurrentValue + Count
                            end,
                            %?DEBUG_LOG("CurrentValue, Count------------:~p",[{CurrentValue, Count}]),
                            Star2 = do_star_by_goal(NewCurrentValue, MaxValue, 0),
                            NewStar =
                                if
                                    Star2 > Star ->
                                        Star2;
                                    true ->
                                        Star
                                end,
                            %?DEBUG_LOG("NewStar---------------:~p",[NewStar]),
                            NewAc = Ac#ac{star = NewStar, current_value = NewCurrentValue},
                            NewList = lists:keyreplace(AchievementId, 2, AcList, NewAc),
                            %?DEBUG_LOG("AchievementId---:~p------NewCurrentValue-----:~p",[AchievementId, NewCurrentValue]),
                            ?player_send(accomplishments_sproto:pkg_msg(?MSG_ACCOMPLISHMENTS_ACHIEVEMENT_CHANGE,
                                {AchievementId,
                                    NewStar,
                                    NewCurrentValue})),
                            put(?pd_ac_list, NewList),
                            update_all_ac_star(),
                            case load_cfg_achievement:get_ac_title_cfg(AchievementId) of
                                ?none ->
                                    pass;
                                ?undefined ->
                                    pass;
                                Title ->
                                    if
                                        NewStar > 0 ->
                                            TitleId = lists:nth(NewStar, Title),
                                            title_mng:add_title(TitleId);
                                        true ->
                                            pass
                                    end
                            end;
                        true ->
                            pass
                    end
            end
    end.


update_all_ac_star() ->
    AcList = get(?pd_ac_list),
    Count = do_all_ac_star(AcList, 0),
    ranking_lib:update(?ranking_ac, get(?pd_id), Count).
do_all_ac_star(?undefined, _) ->
    pass;
do_all_ac_star([], Count) ->
    Count;
do_all_ac_star([#ac{star = Star}|T], Count) ->
    do_all_ac_star(T, Count + Star).



do_star_by_goal(_Value, [], Star) ->
    Star;
do_star_by_goal(Value, [Goal | T], Star) ->
    if
        Value > Goal ->
            do_star_by_goal(Value, T, Star + 1);
        Value =:= Goal ->
            Star + 1;
        true ->
            Star
    end.


init_instance_ac([], InstanceList) ->
    put(?pd_instance_ac_list, InstanceList);
init_instance_ac([{Type, Goal} | T], List) ->
    InstanceAc = #instance_ac{
        id = Type,
        goal = Goal},
    init_instance_ac(T, [InstanceAc | List]);
init_instance_ac(_, _) ->
    ignore.

get_goal_by_type(Type, StarsCfg) ->
    case lists:keyfind(Type, 1, StarsCfg) of
        ?false ->
            [];
        {_, List} ->
            lists:sublist(List, 2, 4)
    end.

get_total_star(MaxDoubleCount, ShoujiCount, PassTime, ReliveNum, StarsCfg) ->
    LianJiGoal = get_goal_by_type(?lianji, StarsCfg),
    LianJiStar = calculate_star(MaxDoubleCount, LianJiGoal, 0, ?lianji),
    ShouJiGoal = get_goal_by_type(?shouji, StarsCfg),
    ShouJiStar = calculate_star(ShoujiCount, ShouJiGoal, 0, ?shouji),
    PassTimeGoal = get_goal_by_type(?passtime, StarsCfg),
    PassTimeStar = calculate_star(PassTime, PassTimeGoal, 0, ?passtime),
    ReliveGoal = get_goal_by_type(?add_xue, StarsCfg),
    ReliveStar = calculate_star(ReliveNum, ReliveGoal, 0, ?add_xue),
    %?DEBUG_LOG("LianJiStar---:~p----ShouJiStar----:~p-----PassTimeStar---:~p",[LianJiStar, ShouJiStar, PassTimeStar]),
    LianJiStar + ShouJiStar + PassTimeStar + ReliveStar. 


complete_instance_ac({FubenId, ChapterId, _KillMinMonsterCount, _KillBossMonsterCount, PassTime, ReliveNum, MaxDoubleCount, ShoujiCount, _DieCount}) ->
    InstanceAcList = get(?pd_instance_ac_list),
    {AllStartCount2, TotalFenshu} =
    lists:foldl(fun(#instance_ac{id = Type, goal = GoalList} = _InstanceAc, {AllStartCount, AllFenShu}) ->
        ZeroStar = get_count(FubenId, Type, 1),
        Goal = lists:sublist(GoalList, 2, 4),
        {StarCount, FenShu} = D =
        case Type of
            ?lianji ->
                LianJiStar = calculate_star(MaxDoubleCount, Goal, 0, Type),
                LianJiFs = erlang:trunc( erlang:min(300, (300 * (MaxDoubleCount - ZeroStar)) / (get_count(FubenId, Type, 4) - ZeroStar)) * 1 ),
                FinalLianJiFs = 
                if
                    LianJiFs =:= 300 ->
                        300 + get_extra_fenshu_by_type(lists:nth(3, Goal), MaxDoubleCount, ?lianji);
                    true ->
                        LianJiFs
                end,
                {{?lianji, LianJiStar}, FinalLianJiFs};
            ?shouji ->
                ShouJiStar = calculate_star(ShoujiCount, Goal, 0, Type),
                ShouJiFs = erlang:trunc( erlang:min(300, (300 * (ZeroStar - ShoujiCount)) / (ZeroStar - get_count(FubenId, Type, 4))) * 1.1 ),
                FinalShouJiFs = 
                if
                    ShouJiFs =:= 330 ->
                        330 + get_extra_fenshu_by_type(lists:nth(3, Goal), ShoujiCount, ?shouji);
                    true ->
                        ShouJiFs
                end,
                {{?shouji, ShouJiStar}, FinalShouJiFs};
            ?passtime ->
                PassTimeStar = calculate_star(PassTime, Goal, 0, Type),
                PassTimeFs = erlang:trunc( erlang:min(300, (300 * (ZeroStar - PassTime)) / (ZeroStar - get_count(FubenId, Type, 4))) * 1.2 ),
                FinalPassTimeFs = 
                if
                    PassTimeFs =:= 360 ->
                        360 + get_extra_fenshu_by_type(lists:nth(3, Goal), PassTime, ?passtime);
                    true ->
                        PassTimeFs
                end,
                {{?passtime, PassTimeStar}, FinalPassTimeFs};
            ?relive_num ->
                ReliveNumStar = calculate_star(ReliveNum, Goal, 0, Type),
                ReliveNumStarFs = erlang:trunc( erlang:min(300, (300 * (ZeroStar - ReliveNum)) / (ZeroStar - get_count(FubenId, Type, 4))) * 1 ),
                FinalReliveNumStarFs = 
                if
                    ReliveNumStarFs =:= 300 ->
                        300 + get_extra_fenshu_by_type(lists:nth(3, Goal), ReliveNum, ?relive_num);
                    true ->
                        ReliveNumStarFs
                end,
                {{?relive_num, ReliveNumStar}, FinalReliveNumStarFs};
            ?add_xue ->
                AddXueNumStar = calculate_star(ReliveNum, Goal, 0, Type),
                AddXueNumStarFs = erlang:trunc( erlang:min(300, (300 * (ReliveNum - ZeroStar)) / (get_count(FubenId, Type, 4) - ZeroStar)) * 1 ),
                FinalAddXueNumStarFs = erlang:max(AddXueNumStarFs, 0),
                % if
                %     AddXueNumStarFs =:= 300 ->
                %         300 + get_extra_fenshu_by_type(lists:nth(3, Goal), ReliveNum, Type);
                %     true ->
                %         ReliveNumStarFs
                % end,
                {{?add_xue, AddXueNumStar}, FinalAddXueNumStarFs};
            _ ->
                {-1,-1}
        end,
        %?DEBUG_LOG("Type---------:~p-------FenShu--------:~p",[Type, FenShu]),
        case D of
            {-1,-1} ->
                {AllStartCount, AllFenShu};
            _ ->
                {[StarCount|AllStartCount], AllFenShu + FenShu}
        end;
        (_, {AllStartCount, AllFenShu}) ->
            {AllStartCount, AllFenShu}
    end,
    {[], 0},
    InstanceAcList),
    
    %?DEBUG_LOG("TotalFenshu---------------------------:~p",[TotalFenshu]),
    % if
    %     ChapterId =:= 1 -> %% is achievement need when chapterid==1
    %         achievement_mng:do_ac2(?xingjidaren, 0, main_ins:get_total_star(AllStartCount2));
    %     true ->
    %         pass
    % end,

    erase(?pd_instance_ac_list),
    %?DEBUG_LOG("AllStartCount2----:~p-----TotalFenShu----:~p",[AllStartCount2, TotalFenshu]),
    {AllStartCount2,
        if
            TotalFenshu >= 0 ->
                TotalFenshu;
            true ->
                0
        end
    }.

get_extra_fenshu_by_type(Goal, NowC, Type) when Type =:= ?lianji orelse Type =:= ?add_xue ->
    %?DEBUG_LOG("NowC,Goal-----------------------------:~p",[{NowC,Goal}]),
    erlang:max(NowC-Goal, 0);

get_extra_fenshu_by_type(Goal, NowC, _) ->
    %?DEBUG_LOG("Goal, NowC-----------------------:~p",[{Goal,NowC}]),
    erlang:max(Goal-NowC, 0).



calculate_star(_Count, [], Star, Type) when Type =:= ?lianji orelse Type =:= ?add_xue ->
    Star;
calculate_star(Count, [Goal | T], Star, Type) when Type =:= ?lianji orelse Type =:= ?add_xue ->
    %?DEBUG_LOG("Count,Goal,Star, Type111---------------:~p",[{Count, Goal, Star,?lianji}]),
    if
        Count >= Goal ->
            calculate_star(Count, T, Star + 1, Type);
        true ->
            Star
    end;
calculate_star(_, [], Star, _) ->
    Star;
calculate_star(Count, [Goal | T], Star, Type) ->
    %?DEBUG_LOG("Count,Goal,Star, Type-222--------------:~p",[{Count, Goal, Star, Type}]),
    if
        Count =< Goal ->
            calculate_star(Count, T, Star + 1, Type);
        true ->
            Star
    end.



get_count(FubenId, Type, Star) ->
    case load_cfg_main_ins:get_count_by_star_and_type(FubenId, Star, Type) of
        ?none ->
            1;
        Count ->
            Count
    end.


handle_client({Pack, Arg}) ->
    handle_client(Pack, Arg).

handle_client(?MSG_ACCOMPLISHMENT_EXTRACT_REWARD, {AchievementId}) ->
    %?DEBUG_LOG("AchievementId------------------------:~p",[AchievementId]),
    case get(?pd_ac_list) of
        ?undefined ->
            pass;
        List ->
            get_ac_prize(List, AchievementId)
    end;

handle_client(_Mod, _Msg) ->
    ?err(notmatch).






create_mod_data(SelfId) ->
    List = load_cfg_achievement:get_reg_achievement_cfg(),
    %?DEBUG_LOG("List----------------------------:~p",[List]),
    case dbcache:insert_new(?player_achievement_tab, #player_achievement_tab{id = SelfId, list = List}) of
        ?true ->
            ok;
        ?false ->
            ?ERROR_LOG("player ~p create new player_achievement_tab not alread exists ", [SelfId])
    end,
    put(?zishenwanjia_init, true),
    ok.

load_mod_data(PlayerId) ->
    case dbcache:load_data(?player_achievement_tab, PlayerId) of
        [] ->
            create_mod_data(PlayerId),
            load_mod_data(PlayerId);
        [#player_achievement_tab{list = List}] ->
            put(?pd_ac_list, List)
    end,
    ok.

init_client() ->
    case get(?pd_ac_list) of
        ?undefined ->
            pass;
        List ->
            %?DEBUG_LOG("achievement_mng List----------------------:~p",[List]),
            ?player_send(accomplishments_sproto:pkg_msg(?MSG_ACCOMPLISHMENT_LIST, {load_cfg_achievement:achievements2info(List)}))
    end,
    ok.

view_data(Msg) ->
    Msg.

online() ->
    case erase(?zishenwanjia_init) of
        ?true ->
            achievement_mng:do_ac2(?zishenwanjia, 0, 1);
        _ ->
            pass
    end,
    ok.

offline(PlayerId) ->
    save_data(PlayerId),
    ok.
save_data(PlayerId) ->
    dbcache:update(?player_achievement_tab, #player_achievement_tab{id = PlayerId, list = get(?pd_ac_list)}),
    ok.

handle_frame(_NotMatch) ->
    ok.

handle_msg(_FromMod, _Msg) ->
    ok.




load_db_table_meta() ->
    [
        #db_table_meta{
            name = ?player_achievement_tab,
            fields = ?record_fields(?player_achievement_tab),
            shrink_size = 10,
            flush_interval = 3
        }
    ].


    