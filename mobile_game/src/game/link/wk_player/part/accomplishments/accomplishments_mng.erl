-module(accomplishments_mng).
% %%% coding:utf-8
% %%%-------------------------------------------------------------------
% %%% @author wcg
% %%% @doc 成就系统
% %%%
% %%% @end
% %%%-------------------------------------------------------------------

% -include_lib("pangzi/include/pangzi.hrl").
% -include_lib("config/include/config.hrl").


% -include("inc.hrl").
% -include("player.hrl").
% -include("accomplishments.hrl").
% -include("player_mod.hrl").
% -include("handle_client.hrl").
% -include("main_ins_struct.hrl").
% -export([
%     trigger/4,
%     uplevel/2,
%     cfg/1,lookup/1,update/1,
%     complete_ins/2  %完成副本成就
%     ,open_fun/1     %功能开放
%     ,chapter_accomplishment_num/1,
%     ins_start_init_acc/1, %副本初始化时，初始化成就信息
%     update_ins_acc/1,  %更新副本星级成就
%     ins_fail_reset_acc/0
% ]).

% load_config_meta() ->
%     [
%         #config_meta{record = #achievement_cfg{},
%             fields = ?record_fields(achievement_cfg),
%             file = "achievement.txt",
%             keypos = #achievement_cfg.id,
%             all = [#achievement_cfg.id],
%             verify = fun verify_achievement_cfg/1}
%     ].

% verify_achievement_cfg(_AchievmentCfg) -> 
%     ok.

% load_db_table_meta() ->
%     [
%         #db_table_meta{
%             name = accomplishments,
%             fields = ?record_fields(accomplishments),
%             shrink_size = 10,
%             flush_interval = 2
%         }
%     ].

% handle_frame(_NotMatch) -> 
%     ?err(notmatch).

% handle_msg(_FromMod, _Msg) -> 
%     ?err(notmatch).

% create_mod_data(SelfId) -> 
%     open(SelfId).

% load_mod_data(_PlayerId) -> 
%     ok.

% init_client() ->
%     case lookup(get(?pd_id)) of
%         ?none -> 
%             ok;
%         Accomplishment -> 
%             ?player_send(accomplishments_sproto:pkg_msg(?MSG_ACCOMPLISHMENT_LIST, {achievements2infos(Accomplishment)}))
%     end.

% view_data(Msg) -> 
%     Msg.

% online() -> 
%     ok.

% offline(_PlayerId) -> 
%     ok.
% save_data( _ ) -> 
%     ok.
% open_fun( [] ) ->
%     case lookup(get(?pd_id)) of
%         ?none -> 
%             open(get(?pd_id));
%         _ -> 
%             ok
%     end.

% open(SelfId) ->
%     All = lookup_all_achievement_cfg(#achievement_cfg.id),

%     FunFoldl = 
%     fun(CFGId, Data) ->
%         CFG = lookup_achievement_cfg(CFGId),
%         if
%             CFG#achievement_cfg.id >= 100000 -> 
%                 Data;
%             ?true ->
%                 [#achievement{id = CFG#achievement_cfg.id,
%                     type = CFG#achievement_cfg.event,
%                     type_id = CFG#achievement_cfg.type_id,
%                     type_value = 0,
%                     level = 0,
%                     status = ?achievement_status_begin,
%                     reward = 0} | Data]
%         end
%     end,
%     Achievements = lists:foldl(FunFoldl, [], All),

%     Accomplishments = #accomplishments{id = SelfId, ver = ?VER_CUR, achievements = Achievements},
%     case dbcache:insert_new(accomplishments, Accomplishments) of
%         ?true ->
%             Fun = 
%             fun(Achievement) ->
%                 if
%                     Achievement#achievement.id > ?ACHIEVEMENT_MAIN_INS_ID -> 
%                         ok;
%                     Achievement#achievement.type =:= ?ev_chapter_accomplishment_num -> % 特殊情况，完成每一个主线任务都触发
%                         event_eng:reg(Achievement#achievement.type, all,
%                             {?MODULE, Achievement#achievement.id}, {?MODULE, trigger}, Achievement#achievement.type);
%                     ?true ->
%                         event_eng:reg(Achievement#achievement.type, {Achievement#achievement.type, Achievement#achievement.type_id},
%                             {?MODULE, Achievement#achievement.id}, {?MODULE, trigger}, Achievement#achievement.type)
%                 end
%             end,
%             lists:foreach(Fun, Achievements);
%         ?false -> 
%             ?ERROR_LOG("player ~p create new accomplishments not alread exists ", [SelfId])
%     end,
%     init_client().

% handle_client({Pack, Arg}) -> 
%     handle_client(Pack, Arg).

% handle_client(?MSG_ACCOMPLISHMENT_LIST, {Id}) ->
%     case lookup(Id) of
%         ?none ->
%             ok;
%         Accomplishment ->
%             AchievementList = [{Achievement#achievement.id,
%                 Achievement#achievement.type_value, Achievement#achievement.level,
%                 Achievement#achievement.status, Achievement#achievement.reward}
%                 || Achievement <- Accomplishment#accomplishments.achievements],
%             ?player_send(accomplishments_sproto:pkg_msg(?MSG_ACCOMPLISHMENT_LIST, {AchievementList}))
%     end;

% handle_client(?MSG_ACCOMPLISHMENT_EXTRACT_REWARD, {AchievementID}) ->
%     PlayerId = get(?pd_id),
%     case lookup(PlayerId) of
%         ?none ->
%             ?return_err(?ERR_NO_CFG);
%         Accomplishment ->
%             case get_reward(Accomplishment, AchievementID) of
%                 {error, ReplyNum} -> 
%                     ?return_err(ReplyNum);
%                 {ExtractLevel, RewardPrizeId} ->
%                     prize:prize(RewardPrizeId),
%                     Accomplishment1 = set_reward(lookup( PlayerId ), AchievementID, ExtractLevel),
%                     update(Accomplishment1),
%                     ?player_send(accomplishments_sproto:pkg_msg(?MSG_ACCOMPLISHMENT_EXTRACT_REWARD, {AchievementID, ExtractLevel}))
%             end
%     end;

% handle_client(_Mod, _Msg) ->
%     ?err(notmatch).

% trigger({?MODULE, AchievementID}, _Arg, Data, CbData) ->
%     case lookup(get(?pd_id), AchievementID) of
%         ?none -> 
%             ok;
%         OldAchievement ->
%             case accomplishments_plugin:event(Data, OldAchievement, CbData) of
%                 {error, Other} -> 
%                     ?ERROR_LOG("error:~p~n", [Other]);
%                 NewAchievement ->
%                      if
%                         AchievementID == 40013 ->
%                             ?DEBUG_LOG("Data------:~p=---NewAchievement---:~p---CbData--:~p",[Data, NewAchievement, CbData]);
%                         true ->
%                             pass
%                     end,
%                     update_achievement(get(?pd_id), NewAchievement),
%                     ?ifdo(NewAchievement#achievement.status == ?achievement_status_end,
%                           event_eng:unreg(NewAchievement#achievement.type, {?MODULE, NewAchievement#achievement.id})),
%                     issued_achievement_change([NewAchievement])
%             end
%     end.

% update_achievement(PlayerId, Achievement) ->
%     case lookup(PlayerId) of
%         ?none -> 
%             ?none;
%         #accomplishments{achievements = Acc} = Accs ->
%             case lists:keytake(Achievement#achievement.id, #achievement.id, Acc) of
%                 false -> 
%                     ?none;
%                 {value, _, RemainAcc} ->
%                     update(Accs#accomplishments{achievements = [Achievement | RemainAcc]})
%             end
%     end.

% issued_achievement_change([]) ->
%     ok;%%ignore
% issued_achievement_change([ChangeAchievement | ChangeAchievements]) ->
%     ?player_send(accomplishments_sproto:pkg_msg(?MSG_ACCOMPLISHMENTS_ACHIEVEMENT_CHANGE, {ChangeAchievement#achievement.id,
%         ChangeAchievement#achievement.level,
%         ChangeAchievement#achievement.type_value})),
%     issued_achievement_change(ChangeAchievements).

% uplevel(Achievement, TypeValue) ->
%     Cfg = cfg(Achievement),
%     NextLevel = Achievement#achievement.level + 1,
%     case Cfg#achievement_cfg.title of
%         0 -> 
%             [];
%         [] -> 
%             [];
%         TitleList ->
%             case lists:nth(NextLevel, TitleList) of
%                 0 -> 
%                     [];
%                 [] -> 
%                     [];
%                 Title -> 
%                     title_mng:add_title(Title)
%             end
%     end,
%     MaxValue = Cfg#achievement_cfg.max_value,
%     EndValue = lists:last(MaxValue),
%     case length(MaxValue) =< NextLevel of
%         ?true ->
%             Achievement#achievement{status = ?achievement_status_end, level = NextLevel, type_value = EndValue};
%         ?false ->
%             Achievement#achievement{status = ?achievement_status_underway, level = NextLevel, type_value = TypeValue}
%     end.

% get_reward(#accomplishments{achievements = Achievements}, AchievementID) ->
%     case lists:keyfind(AchievementID, #achievement.id, Achievements) of
%         ?false -> 
%             {error, ?ERR_ACC_THIS_ACCID_NOT_ACCEPT};
%         #achievement{id = Id, reward = Reward, level = Level} ->
%             RewardLevel = Reward + 1,
%             if
%                 RewardLevel > Level -> 
%                     {error, ?ERR_ACC_CHECH_ERR};
%                 ?true ->
%                     CFG = cfg(Id),
%                     {RewardLevel, lists:nth(RewardLevel, CFG#achievement_cfg.reward)}
%             end
%     end.

% set_reward(Achievements, AchievementID, Reward) ->
%     case lists:keytake(AchievementID, #achievement.id, Achievements#accomplishments.achievements) of
%         ?false ->
%             Achievements;
%         {value, Achievement, OtherAchievements} ->
%             NewAchievement = Achievement#achievement{reward = Reward},
%             Achievements#accomplishments{achievements = [NewAchievement | OtherAchievements]}
%     end.

% achievements2infos(#accomplishments{achievements = As, main_ins_achievements = MainAs}) ->
%     Fun = fun(Achievement) ->
%         case Achievement#achievement.status of
%             ?achievement_status_begin -> 
%                 ?false;
%             _ ->
%                 {?true, {Achievement#achievement.id,
%                     Achievement#achievement.type_value,
%                     Achievement#achievement.level,
%                     Achievement#achievement.status,
%                     Achievement#achievement.reward
%                 }}
%         end
%     end,
%     lists:filtermap(Fun, As++MainAs).


% cfg(#achievement{id = ID}) -> 
%     cfg(ID);
% cfg(ID) -> 
%     lookup_achievement_cfg(ID).

% lookup(PlayerId) ->
%     case dbcache:lookup(accomplishments, PlayerId) of
%         [Accomplishments = #accomplishments{}] -> 
%             Accomplishments;
%         _ -> 
%             ?none
%     end.

% lookup(PlayerId, AchievementId) ->
%     case lookup(PlayerId) of
%         ?none -> 
%             ?none;
%         #accomplishments{achievements = Acc} ->
%             case lists:keyfind(AchievementId, #achievement.id, Acc) of
%                 ?false -> 
%                     ?none;
%                 Ach -> 
%                     Ach
%             end
%     end.

% update(Accomplishments) ->
%     dbcache:update(accomplishments, Accomplishments).

% %% @doc 副本结算计算副本星级成就
% complete_ins(Achievements, {KillMinMonsterCount, KillBossMonsterCount, PassTime, _DieCount}) ->
%     Accomplishments = 
%     case lookup(get(?pd_id)) of
%         ?none -> 
%             #accomplishments{id = get(?pd_id)};
%         Accomplishments1 -> 
%             Accomplishments1
%     end,
%     MainIns = Accomplishments#accomplishments.main_ins_achievements,
%     FunFoldl = fun({AchievementId, _}, MainIns2) ->
%         case lists:keymember(AchievementId, #achievement.id, MainIns) of
%             ?true -> 
%                 MainIns2;
%             ?false ->
%                 #achievement_cfg{event = Event, type_id = {_, AccLevel}, max_value = MaxValue} = cfg(AchievementId),
% %%                 Value = lists:nth(AccLevel, MaxValue),
%                 Value = hd(MaxValue),
%                 IsComplete = case Event of
%                                 ?ev_kill_monster -> 
%                                     (KillMinMonsterCount + KillBossMonsterCount) >= Value;
%                                 ?ev_died -> 
%                                     get(?pd_ins_die_count) =< Value;
%                                 ?ev_instance_pass_time -> PassTime =< Value;
%                                 _ -> 
%                                     ?false
%                              end,
%                 case IsComplete of
%                     ?true -> 
%                         [#achievement{id=AchievementId,level=AccLevel,status=?achievement_status_end}|MainIns2];
%                     ?false -> 
%                         MainIns2
%                 end
%         end
%     end,
%     NewMainIns =
%         case lists:foldl(FunFoldl, [], Achievements) of
%             [] -> 
%                 [];
%             _NewMainIns1 ->
%                 event_eng:post( ?ev_chapter_accomplishment_num, {?ev_chapter_accomplishment_num, 0}, 1 ),
%                 _NewMainIns1
%         end,
%     NewAchievement = Accomplishments#accomplishments{main_ins_achievements = NewMainIns++MainIns},
%     update(NewAchievement),
%     issued_achievement_change(NewMainIns).

% %% @doc 根据章节计算目前该章节的成就数量
% chapter_accomplishment_num(ChapterId) ->
%     case lookup(get(?pd_id)) of
%         ?none -> 
%             0;
%         #accomplishments{main_ins_achievements = MainAchievements} ->
%             ChapterInsIds = main_ins:lookup_group_main_ins_cfg(#main_ins_cfg.chapter_id, ChapterId),
%             AchList = [main_ins:lookup_main_ins_cfg(Id, #main_ins_cfg.achievements) || Id <- ChapterInsIds],
%             FunFoldl = fun([], Int) -> Int;
%                 (AchList1, Int) ->
%                     ResInt = lists:foldl(fun({AchId, _}, Int1) ->
%                         case lists:keymember(AchId, #achievement.id, MainAchievements) of
%                             ?true -> 
%                                 Int1 + 1;
%                             ?false -> 
%                                 Int1
%                         end
%                     end, 0, AchList1),
%                     ResInt + Int
%             end,
%             lists:foldl(FunFoldl, 0, AchList)
%     end.


% %% @doc 副本开始初始化星级成就信息，目前只有该副本杀怪数量
% %-spec ins_start_init_acc([{AccId::integer(), InsLv::integer}]) -> [] | [{Event::atom(), MaxValue::integer(), 0, AccId::integer}].
% ins_start_init_acc([]) ->
%     put(?ins_start_init_acc,[]);

% ins_start_init_acc(MainInsAchievements) ->
%     MainIns = 
%     case lookup(get(?pd_id)) of
%         ?none -> 
%             [];
%         Accomplishments1 -> 
%             Accomplishments1#accomplishments.main_ins_achievements
%     end,
%     FunFoldl = 
%     fun({AchievementId, _}, MainIns2) ->
%         case lists:keymember(AchievementId, #achievement.id, MainIns) of
%             ?true -> 
%                 MainIns2;
%             ?false ->
%                 case cfg(AchievementId) of
%                     #achievement_cfg{event = ?ev_kill_monster, type_id = {_, AccLevel}, max_value = MaxValue} ->
%                         [{?ev_kill_monster, lists:nth(AccLevel, MaxValue), 0, AchievementId} | MainIns2];
%                     _ ->
%                         MainIns2
%                 end
%         end
%     end,
%     put(?ins_start_init_acc, {lists:foldl(FunFoldl, [], MainInsAchievements), []}).

% %% @doc 杀怪更新数据，如果完成发送协议到客户端，但是不保存数据，最后副本结算时再次统一结算，存储到数据库
% update_ins_acc(Event) ->
%     case get(?ins_start_init_acc) of
%         ?undefined -> 
%             ok;
%         [] -> 
%             ok;
%         {Acc, ResetAcc} ->
%             case lists:keyfind( Event, 1, Acc ) of
%                 ?false -> 
%                     ok;
%                 {Event, MaxValue, Value, AccId} ->
%                     NewValue = Value+1,
%                     if
%                         NewValue >= MaxValue ->
%                             put(?ins_start_init_acc, {lists:keydelete(Event, 1, Acc), [{AccId, 0, 0}|ResetAcc]}),
%                             ?player_send(accomplishments_sproto:pkg_msg(?MSG_ACCOMPLISHMENTS_ACHIEVEMENT_CHANGE, {AccId, 1, NewValue}));
%                         ?true -> 
%                             put(?ins_start_init_acc, {lists:keystore(Event, 1, Acc, {Event, MaxValue, Value+1, AccId}), ResetAcc})
%                     end
%             end

%     end.

% ins_fail_reset_acc() ->
%     case get(?ins_start_init_acc) of
%         ?undefined -> 
%             ok;
%         [] -> 
%             ok;
%         {_Acc, ResetAcc} ->
%             [?player_send(accomplishments_sproto:pkg_msg(?MSG_ACCOMPLISHMENTS_ACHIEVEMENT_CHANGE, {AccId, AccLevel,NewValue}))||{AccId, AccLevel,NewValue} <- ResetAcc]
%     end.