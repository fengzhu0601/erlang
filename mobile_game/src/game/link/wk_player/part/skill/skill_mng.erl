%%% coding:utf-8
%%%-------------------------------------------------------------------
%%% @author zl
%%% @doc 用户技能模块
%%%
%%% @end
%%%-------------------------------------------------------------------

-module(skill_mng).


%% API
-export([
    add_skill/1,
    del_skill/1,
    release_skill/6,
    release_pet_skill/6,
    reset_dress_skill/0, %离开新手副本时删除特殊技能
    dress_skill/0        %进入新手副本时添加特殊技能
]).


-include_lib("pangzi/include/pangzi.hrl").


-include("inc.hrl").
-include("player.hrl").
-include("player_mod.hrl").
-include("skill_struct.hrl").
-include("handle_client.hrl").
-include("scene.hrl").
-include("achievement.hrl").
-include("cost.hrl").
-include("day_reset.hrl").
-include("load_phase_ac.hrl").
-include("../wonderful_activity/bounty_struct.hrl").
-include("system_log.hrl").

-define(longwen_flag_dress, 1).%%裝上狀態
-define(longwen_flag_undress, 0).%%卸下狀態
-define(LONG_WEN_CFG_FILE, "long_wen.txt").



release_skill(_SkillId, _SkillDuanId, _D, _X, _Y, _H) -> ok.
    % case
    %     %%is_have_skill(SkillId) andalso
    %     D =:= ?D_L orelse D =:= ?D_R
    % of
    %     false ->
    %         ?ERROR_LOG("player ~p not skill or bad dir ~p", [?pname(), {SkillId, D}]);
    %     true ->
    %         Now = com_time:timestamp_msec(),
    %         Cd = load_cfg_skill:lookup_skill_cfg(SkillDuanId, #skill_cfg.cd),
    %         IsCdPassed = case get(?pd_release_skill_time(SkillDuanId)) of
    %             ?undefined ->
    %                 true;
    %             T ->
    %                 Now - T >= Cd
    %         end,
    %         CostMp = load_cfg_skill:lookup_skill_cfg(SkillDuanId, #skill_cfg.cost_mp),
    %         IsAngerSkill = load_cfg_crown:is_anger_skill(SkillDuanId),
    %         if
    %             IsAngerSkill ->%%怒气技能
    %                 case crown_mng:is_full_anger() of
    %                     ?true ->
    %                         crown_mng:clear_anger(),
    %                         crown_mng:release_skill(SkillDuanId),
    %                         scene_mng:send_msg({?release_skill_msg, get(?pd_idx), SkillId, SkillDuanId, D, X, Y, H});
    %                     ?false ->
    %                         ?player_send_err(?MSG_SCENE_RELEASE_SKILL, ?ERR_COST_NOT_ENOUGH)
    %                 end;
    %             IsCdPassed =:= ?false ->
    %                 ?player_send_err(?MSG_SCENE_RELEASE_SKILL, ?ERR_CD_LIMIT),
    %                 ?ERROR_LOG("player ~p release skill ~p cd limit", [?pname(), SkillId]);
    %            % is_integer(CostMp) andalso CostMp > ExistMp ->
    %            %     ?player_send_err(?MSG_SCENE_RELEASE_SKILL, ?ERR_COST_NOT_ENOUGH),
    %            %     ?ERROR_LOG("player ~p release skill ~p cost limit~w", [?pname(), SkillId, {CostMp, ExistMp}]);
    %             true ->
    %                 put(?pd_release_skill_time(SkillDuanId), Now),
    %                 %%消耗MP
    %                 (is_integer(CostMp) andalso CostMp > 0) andalso put(?pd_mp, get(?pd_mp) - CostMp),
    %                 %%获得anger
    %                 GainAnger = load_cfg_skill:lookup_skill_cfg(SkillDuanId, #skill_cfg.gain_anger),
    %                 (is_integer(GainAnger) andalso GainAnger > 0) andalso crown_mng:add_anger(GainAnger),
    %                 % LongWenEffect = find_skill_dress_long_wen_effect(SkillId),
    %                 % ?INFO_LOG("longwen effect:~p", [LongWenEffect]),
    %                 scene_mng:send_msg({?release_skill_msg, get(?pd_idx), SkillId, SkillDuanId, D, X, Y, H})
    %         end
    % end.

release_pet_skill(SkillId, SkillDuanId, D, X, Y, H) ->
    case
        %%is_have_skill(SkillId) andalso
        D =:= ?D_L orelse D =:= ?D_R
    of
        false ->
            ?ERROR_LOG("pet ~p not skill or bad dir ~p", [?pname(), {SkillId, D}]);
        true ->
            Now = com_time:timestamp_msec(),
            Cd = load_cfg_skill:lookup_skill_cfg(SkillDuanId, #skill_cfg.cd),
            IsCdPassed =
                case get(?pd_release_skill_time(SkillDuanId)) of
                    ?undefined ->
                        true;
                    T ->
                        Now - T >= Cd
                end,
            if IsCdPassed ->
                put(?pd_release_skill_time(SkillDuanId), Now),
                scene_mng:send_msg({?release_skill_msg, get(?pd_pet_idx), SkillId, SkillDuanId, D, X, Y, H});
                true ->
                    ?player_send_err(?MSG_SCENE_RELEASE_SKILL, ?ERR_CD_LIMIT),
                    ?ERROR_LOG("player ~p release skill ~p cd limit", [?pname(), SkillId])
            end
    end.

-define(ACTIVATION_LONGWEN_ID, 1). %龙纹激活等级

%% 龙纹从没到有(的升级)
add_long_wen(LongWens) when is_list(LongWens) ->
    lists:foreach(fun(LongWenId) ->
        add_long_wen(LongWenId)
                  end,
        LongWens);

add_long_wen(LongWenId) when is_integer(LongWenId) ->
    case gb_trees:is_defined(LongWenId, get(?pd_longwens_mng)) of
        true -> % 如果是重置过的不需要激活,升级就可以了
            upgrade_long_wen_(LongWenId, ?ACTIVATION_LONGWEN_ID);
        _ ->
            add_long_wen_(LongWenId)
    end.

add_long_wen_(LongWenId) ->
    Ret =
        (catch
            begin
                case load_cfg_skill:lookup_long_wen_cfg({LongWenId, ?ACTIVATION_LONGWEN_ID}) of
                    #long_wen_cfg{unlock_level = LevelLimit, skill = _SkillId, cost = Cost} ->
                        %%?ifdo(not gb_sets:is_element(SkillId, get(?pd_skill_mng)), ?return_err(?ERR_SKILL_NO_ID)),
                        ?ifdo(not player:is_level_enough(LevelLimit), ?return_err(?ERR_SKILL_LW_LEVEL_NOT_ENOUGH)),

                        ?ifdo(ok =/= cost:cost(Cost, ?FLOW_REASON_LONGWEN_UPGRADE), ?return_err(?ERR_COST_NOT_ENOUGH)),

                        Diamond = attr_new:get(?pd_diamond),
                        system_log:info_longwen_levelup(0, 1, LongWenId, Diamond, 0),
                        bounty_mng:do_bounty_task(?BOUNTY_TASK_SHENGJI_LONGWEN, 1),

                        put(?pd_longwens_mng, gb_trees:insert(LongWenId, {LongWenId, ?ACTIVATION_LONGWEN_ID, ?longwen_flag_undress}, get(?pd_longwens_mng))),

                        ?player_send(skill_sproto:pkg_msg(?MSG_SKILL_UPGRADE_LONG_WEN, {LongWenId, ?ACTIVATION_LONGWEN_ID}));
                    _ ->
                        {error, ?ERR_SKILL_LW_MAX}
                end
            end),
    case Ret of
        ok ->
            achievement_mng:do_ac2(?longwenshitan, 0, 1),
            ok;
        {_, W} ->
            SkillMngs = get(?pd_skill_mng),
            ?ERROR_LOG("MSG_skill_ADD_LONG_WEN error(~p) skills(~p)", [W, gb_sets:to_list(SkillMngs)])
    end.


% 龙纹重置功能
reset_long_wen(SkillId) ->
    % 次数消耗 , 金额消耗
    % cost 1000 gold

    RestTimes = orddict:from_list(get(?pd_skill_reset_longwens)),
    {TempSkillId, TimeOfDay} = case orddict:is_key(SkillId, RestTimes) of
                                   true ->
                                       {SkillId, orddict:fetch(SkillId, RestTimes)};
                                   _ ->
                                       {0, 0}
                               end,

%%  TimeOfDay = 1,
%%  Cost = 6001,
%%  ?INFO_LOG("Rest long wen skillId:~p, Time of day:~p ", [SkillId, TimeOfDay]),
    GoodsList = [reset_long_wen_cost(TimeOfDay)],
%%  ?INFO_LOG("Rest long wen skillId:~p, Time of day:~p , cost list:~p", [SkillId, TimeOfDay, GoodsList]),
    GoodsList1 = cost:do_cost_tp(GoodsList),
    case game_res:can_del(GoodsList1) of
        {error, _} ->
            ?return_err(?ERR_COST_NOT_ENOUGH);
        _ ->
            game_res:del(GoodsList1, ?FLOW_REASON_LONGWEN_RESET),
            ok
    end,

    LongWens = get(?pd_longwens_mng),
    ResetLongWens = find_skill_long_wen(SkillId),
% set the longwen level
%%  ?INFO_LOG("Rest long wen:~p", [ResetLongWens]),
    {UpdateLongWens, AddLongwen, LongWenIds} = lists:foldl(
        fun({LongWenId, Level, _DressFlag}, {NLongWens, SUM, IdAcc}) ->
            NewLongWens = gb_trees:update(LongWenId, {LongWenId, 0, 0}, NLongWens),
            ASUM = SUM + get_long_wen_cost(LongWenId, Level),
            {NewLongWens, ASUM, [LongWenId | IdAcc]}
        end
        , {LongWens, 0, []}
        , ResetLongWens),

% get back longwen
    game_res:try_give_ex([{?PL_LONGWENS, AddLongwen}], ?FLOW_REASON_LONGWEN_RESET),
    % calculate the day of operation time
    put(?pd_longwens_mng, UpdateLongWens),
    NRestTimes = case TempSkillId of
                     0 ->
                         orddict:store(SkillId, 1, RestTimes);
                     _ -> orddict:update_counter(SkillId, 1, RestTimes)
                 end,

    put(?pd_skill_reset_longwens, orddict:to_list(NRestTimes)),
    phase_achievement_mng:do_pc(?PHASE_AC_LONGWEN_XIDIAN, 1),
%%    ?INFO_LOG("SkillId = ~p TimeOfDay = ~p LongWenIds = ~p", [SkillId, TimeOfDay, LongWenIds]),
    ?player_send(skill_sproto:pkg_msg(?MSG_SKILL_RESET_LONG_WEN, {SkillId, TimeOfDay + 1, LongWenIds})),
    equip_system:sync_skill_change_list(),
    ok.

% 龙纹的重置消耗
reset_long_wen_cost(Num) ->
    %{5000,10000,15000,20000,40000,60000,100000}
    Rum = if
              Num > 5 -> 6;
              true -> Num
          end,
    lists:nth(Rum + 1, misc_cfg:get_longwen_xidian()).
%%  [Num1, Num2, Num3, Num4, Num5, Num6, Num7] = misc_cfg:get_longwen_xidian(),


% 统计升级 需要的龙纹
get_long_wen_cost(_LongWenId, 0) ->
    0;
%%get_long_wen_cost(_LongWenId, 1) ->
%%  0;
get_long_wen_cost(LongWenId, Level) ->
    NextCfg = load_cfg_skill:lookup_long_wen_cfg({LongWenId, Level}),
    #long_wen_cfg{cost = Cost} = NextCfg,
    case cost:lookup_cost_cfg(Cost) of
        ?none -> get_long_wen_cost(LongWenId, Level - 1);
        #cost_cfg{goods = GoodsList} ->
            long_wen_cost(GoodsList) + get_long_wen_cost(LongWenId, Level - 1)
    end.

% 从配置读取龙纹的消耗
long_wen_cost(GoodsList) ->
    lists:foldr(fun({Bid, Count}, AccIn) ->
        if
            Bid =:= 23 ->
                Count + AccIn;
            true -> AccIn
        end;
        ({Bid, Count, _Bind}, AccIn) ->
            if
                Bid =:= 23 ->
                    Count + AccIn;
                true -> AccIn
            end
                end, 0, GoodsList).


upgrade_long_wen(LongWenId, ?ACTIVATION_LONGWEN_ID) ->
    Result = add_long_wen(LongWenId),
    Result;

%% upgrade_long_wen(LongWenId, Level) ->
%%     LongWens = get(?pd_longwens_mng),
%%     ?ifdo(not gb_trees:is_defined(LongWenId, LongWens),
%%         ?return_err(?ERR_SKILL_LW_IS_EXIST)),
%%
%%     {_, OldLevel, IsDress} = gb_trees:get(LongWenId, LongWens),
%%     ?ifdo((OldLevel + 1) =/= Level, ?return_err(?ERR_SKILL_LW_LEVEL_ERROR)),
%%     NextCfg = load_cfg_skill:lookup_long_wen_cfg({LongWenId, Level}),
%%
%%     ?ifdo(NextCfg == ?none, ?return_err(?ERR_SKILL_LW_MAX)),
%%
%%     #long_wen_cfg{cost = Cost} = NextCfg,
%%     case cost:cost(Cost) of
%%         {error, _} ->
%%             ?return_err(?ERR_COST_NOT_ENOUGH);
%%         _ -> ok
%%     end,
%%     NewLongWens = gb_trees:update(LongWenId, {LongWenId, Level, IsDress}, LongWens),
%%     put(?pd_longwens_mng, NewLongWens),
%%
%%     ?ifdo(IsDress == ?longwen_flag_dress,
%%         refresh_spirit_attr({LongWenId, Level - 1}, {LongWenId, Level})),%%TODO
%%
%%     %event_eng:post(?ev_long_wen_level_up_totle, {?ev_long_wen_level_up_totle, 0}, 1),
%%     achievement_mng:do_ac2(?longwendashi, 0, 1),
%%
%%     ?player_send(skill_sproto:pkg_msg(?MSG_SKILL_UPGRADE_LONG_WEN, {LongWenId, Level})),
%%     ?debug_log_skill_mng("upgrade_long_wen id(~p) level(~p) result success", [LongWenId, Level]),
%%     ok.

upgrade_long_wen(LongWenId, Level) ->
    upgrade_long_wen_(LongWenId, Level).

upgrade_long_wen_(LongWenId, Level) ->
    LongWens = get(?pd_longwens_mng),
    ?ifdo(not gb_trees:is_defined(LongWenId, LongWens), ?return_err(?ERR_SKILL_LW_IS_EXIST)),

    {_, OldLevel, IsDress} = gb_trees:get(LongWenId, LongWens),
    ?ifdo((OldLevel + 1) =/= Level, ?return_err(?ERR_SKILL_LW_LEVEL_ERROR)),
    NextCfg = load_cfg_skill:lookup_long_wen_cfg({LongWenId, Level}),

    ?ifdo(NextCfg == ?none, ?return_err(?ERR_SKILL_LW_MAX)),

    MoneyBefore = attr_new:get(?pd_money),

    #long_wen_cfg{cost = Cost} = NextCfg,
    case cost:lookup_cost_cfg(Cost) of
        ?none ->
            {error, not_found_cost};
        #cost_cfg{goods = GoodsList} ->
            GoodsList1 = cost:do_cost_tp(GoodsList),
            ?INFO_LOG("good list : ~p", [GoodsList1]),
            case game_res:can_del(GoodsList1) of
                {error, _} ->
                    ?return_err(?ERR_COST_NOT_ENOUGH);
                _ ->
                    game_res:del(GoodsList1, ?FLOW_REASON_LONGWEN_UPGRADE),
                    ok
            end
    end,
    MoneyAfter = attr_new:get(?pd_diamond),
    system_log:info_longwen_levelup(Level - 1, Level, LongWenId, MoneyBefore, (MoneyBefore - MoneyAfter)),

    NewLongWens = gb_trees:update(LongWenId, {LongWenId, Level, IsDress}, LongWens),
    put(?pd_longwens_mng, NewLongWens),

    ?ifdo(IsDress == ?longwen_flag_dress, refresh_spirit_attr({LongWenId, Level - 1}, {LongWenId, Level})),%%TODO

    %event_eng:post(?ev_long_wen_level_up_totle, {?ev_long_wen_level_up_totle, 0}, 1),
    achievement_mng:do_ac2(?longwendashi, 0, 1),

    bounty_mng:do_bounty_task(?BOUNTY_TASK_SHENGJI_LONGWEN, 1),
%%    ?INFO_LOG("LongWenId = ~p Level = ~p", [LongWenId, Level]),
    ?player_send(skill_sproto:pkg_msg(?MSG_SKILL_UPGRADE_LONG_WEN, {LongWenId, Level})),
    ?debug_log_skill_mng("upgrade_long_wen id(~p) level(~p) result success", [LongWenId, Level]),
    ok.

%% get_long_wen_skill_modifications(Id) ->
%%     case load_cfg_skill:lookup_long_wen_cfg(Id) of
%%         ?none ->
%%             ?none;
%%         #long_wen_cfg{skill_modifications = SkillModfications} ->
%%             SkillModfications
%%     end.


%% 装上指定的龙纹(如果该龙纹所对应的技能已装其它的龙纹,会自动替换)
% dress_long_wen(LongWenID) ->
%     LongWens = get(?pd_longwens_mng),
%     ?ifdo(not gb_trees:is_defined(LongWenID, LongWens),?return_err(not_exist)),
%     case gb_trees:get(LongWenID, LongWens) of
%         {_, _Level, ?longwen_flag_dress} ->
%             ?return_err(is_dress);
%         {_, Level, ?longwen_flag_undress} ->
%             #long_wen_cfg{skill = Skill} = load_cfg_skill:lookup_long_wen_cfg({LongWenID, Level}),
%             DressedLongWen = find_skill_dress_long_wen(Skill),
%             NewLongWens = gb_trees:update(LongWenID, {LongWenID, Level, ?longwen_flag_dress}, LongWens),
%             put(?pd_longwens_mng, NewLongWens),
%             ?ifdo(DressedLongWen > 0, undress_long_wen(DressedLongWen)),
%             ?player_send(skill_sproto:pkg_msg(?MSG_SKILL_DRESS_LONG_WEN, {DressedLongWen, LongWenID})),
%             equip_system:sync_skill_change_list()
%     end,
%     ok.

%% 装上指定的龙纹(如果该龙纹所对应的技能已装其它的龙纹,会自动替换)
dress_long_wen(LongWenID) ->
    LongWens = get(?pd_longwens_mng),
    PlayerLevel = get(?pd_level),
    ?ifdo(not gb_trees:is_defined(LongWenID, LongWens), ?return_err(not_exist)),
    case gb_trees:get(LongWenID, LongWens) of
        {_, _Level, ?longwen_flag_dress} ->
            ?return_err(is_dress);
        {_, Level, ?longwen_flag_undress} ->
            #long_wen_cfg{skill = Skill, skill_modifications = SkillModifyIds} = load_cfg_skill:lookup_long_wen_cfg({LongWenID, Level}),
            DressedLongWenIdList = find_skill_dress_long_wen(Skill),
            NewLongWens = gb_trees:update(LongWenID, {LongWenID, Level, ?longwen_flag_dress}, LongWens),
            put(?pd_longwens_mng, NewLongWens),
            DoubleLongWenLevel = misc_cfg:get_longwen_doublegift(),
            lists:foreach( % 处理添加永久属性的龙纹效果
                fun(SkillModifyId) ->
                    equip_buf:add_skill_modify_attr(SkillModifyId)
                end, SkillModifyIds),
            DressedLongWen =
                if
                    PlayerLevel >= DoubleLongWenLevel ->
                        Size = length(DressedLongWenIdList),
                        if
                            Size >= 2 ->
                                Id = lists:nth(random:uniform(Size), DressedLongWenIdList),
                                undress_long_wen(Id),
                                Id;
                            true ->
                                0
                        end;
                    true ->
                        undress_long_wen(DressedLongWenIdList),
                        if
                            DressedLongWenIdList =:= [] ->
                                0;
                            true ->
                                lists:nth(1, DressedLongWenIdList)
                        end
                end,
            phase_achievement_mng:do_pc(?PHASE_AC_LONGWEN_ADD, 10002, count_dress_long_wen()),
%%            ?INFO_LOG("DressedLongWen = ~p LongWenID = ~p", [DressedLongWen, LongWenID]),
            ?player_send(skill_sproto:pkg_msg(?MSG_SKILL_DRESS_LONG_WEN, {DressedLongWen, LongWenID})),
            equip_system:sync_skill_change_list()
    end,
    ok.

undress_long_wen(DressedLongWen) when is_list(DressedLongWen) ->
    lists:foreach(fun(LongWenId) ->
        undress_long_wen(LongWenId)
                  end,
        DressedLongWen);
%% 卸下指定的龙纹
undress_long_wen(DressedLongWen) ->
    LongWens = get(?pd_longwens_mng),
    ?ifdo(not gb_trees:is_defined(DressedLongWen, LongWens), ?return_err(not_exist)),
    case gb_trees:get(DressedLongWen, LongWens) of
        {_, _Level, ?longwen_flag_undress} ->
            ?return_err(is_undress);
        {_, Level, ?longwen_flag_dress} ->
            NewLongWens = gb_trees:update(DressedLongWen, {DressedLongWen, Level, ?longwen_flag_undress}, LongWens),
            put(?pd_longwens_mng, NewLongWens),
            #long_wen_cfg{skill_modifications = SkillModifyIds} = load_cfg_skill:lookup_long_wen_cfg({DressedLongWen, Level}),
            lists:foreach( % 处理永久属性的龙纹效果
                fun(SkillModifyId) ->
                    equip_buf:remove_skill_modify_attr(SkillModifyId)
                end, SkillModifyIds)
    end,
    ok.

%% 找出该技能已装了哪个龙纹
find_skill_dress_long_wen(Skill) ->
    LongWenList = gb_trees:values(get(?pd_longwens_mng)),
    lists:foldl(fun(
            {LongWenId, Level, ?longwen_flag_dress}, L) ->
        case load_cfg_skill:lookup_long_wen_cfg({LongWenId, Level}, #long_wen_cfg.skill) =:= Skill of
            ?true ->
                [LongWenId | L];
            ?false ->
                L
        end;
        (_, L) ->
            L
                end,
        [],
        LongWenList).


% %% 找出该技能已装了哪个龙纹
% find_skill_dress_long_wen(Skill) ->
%     LongWens = gb_trees:values(get(?pd_longwens_mng)),
%     com_lists:break(fun({LongWenId, Level, ?longwen_flag_dress}) ->
%         case load_cfg_skill:lookup_long_wen_cfg({LongWenId, Level}, #long_wen_cfg.skill) =:= Skill of
%             ?true -> {break, LongWenId};
%             ?false -> continue
%         end;
%         (_) ->
%             continue
%     end, 
%     0, 
%     LongWens).

% 技能使用龙纹的效果
find_skill_dress_long_wen_effect(Skill) ->
    LongWenList = gb_trees:values(get(?pd_longwens_mng)),
    lists:foldl(fun(
            {LongWenId, Level, ?longwen_flag_dress}, L) ->
        #long_wen_cfg{skill = Skill2, skill_modifications = SkillModifyIds} = load_cfg_skill:lookup_long_wen_cfg({LongWenId, Level}),
        if
            Skill2 =:= Skill ->
                SkillModifyIds ++ L;
            true ->
                L
        end;
        (_, L) ->
            L
                end,
        [],
        LongWenList).

% 找出技能相关的龙纹 -> []
find_skill_long_wen(SkillId) ->
    LongWens = gb_trees:values(get(?pd_longwens_mng)),
    %%  ?INFO_LOG("skill id:~p,long wens:~p", [SkillId, LongWens]),
    Ret =
        lists:foldl(fun({LongWenId, Level, DressFlag}, Acc) ->
            %%    ?INFO_LOG("longwenId Id:~p,Level:~p,SkillId,~p", [LongWenId, Level, load_cfg_skill:lookup_long_wen_cfg({LongWenId, Level}, #long_wen_cfg.skill)]),
            case load_cfg_skill:lookup_long_wen_cfg({LongWenId, Level}, #long_wen_cfg.skill) =:= SkillId of
                ?true ->
                    [{LongWenId, Level, DressFlag} | Acc];
                ?false ->
                    Acc
            end
                    end,
            [],
            LongWens),
    Ret.


count_dress_long_wen() ->
    LongWenList = gb_trees:values(get(?pd_longwens_mng)),
    lists:foldl(
        fun({_LongWenId, _Level, ?longwen_flag_dress}, L) ->
            L + 1;
            (_, L) ->
                L
        end,
        0,
        LongWenList).

%% @doc 添加新技能 or upgrade
add_skill(Skills) when is_list(Skills) ->
    lists:foreach(fun(SkillId) -> add_skill(SkillId) end, Skills);
add_skill(SkillId) when is_integer(SkillId) ->
    Mng = get(?pd_skill_mng),
    case gb_sets:is_element(SkillId, Mng) of
        ?true ->
            ?ERROR_LOG("player ~p already has skill ~p", [?pname(), SkillId]);
        ?false ->
            case add_skill__(SkillId) of
                ok ->
                    %% TODO
                    put(?pd_skill_mng, gb_sets:insert(SkillId, Mng));
                %%?player_send(skill_sproto:pkg_msg(?MSG_SKILL_ADD, {SkillId}));
                {error, Why} ->
                    ?ERROR_LOG("player ~ts add_skill ~p ~p", [?pname(), SkillId, Why])
            end
    end,
    ok.

%% add_skill__(SkillId) ->
%%     case load_cfg_skill:lookup_skill_cfg(SkillId) of
%%         ?none ->
%%             ?err(badarg);
%%         #skill_cfg{level_limit = LL, upgrade_cost = CostId} -> % upgrade_cost or learning cost
%%             case get(?pd_level) >= LL of
%%                 false ->
%%                     ?ERROR_LOG("player ~p can not add skill level limit ~p", [?pname(), LL]),
%%                     ?err(level_not_enough);
%%                 true ->
%%                     case
%%                             case cost:cost(CostId) of
%%                                 ?not_enough ->
%%                                     ?err(cost_not_enough);
%%                                 _ ->
%%                                     ok
%%                             end
%%                     end
%%             end
%%     end.

add_skill__(SkillId) ->
    case load_cfg_skill:lookup_skill_cfg(SkillId) of
        ?none ->
            ?err(badarg);
        #skill_cfg{level_limit = LL, upgrade_cost = CostId} -> % upgrade_cost or learning cost
            case get(?pd_level) >= LL of
                false ->
                    ?ERROR_LOG("player ~p can not add skill level limit ~p", [?pname(), LL]),
                    ?err(level_not_enough);
                true ->
                    case cost:lookup_cost_cfg(CostId) of
                        ?none -> {error, not_found_cost};
                        #cost_cfg{goods = GoodsList} ->
                            GoodsList1 = cost:do_cost_tp(GoodsList),
                            case game_res:can_del(GoodsList1) of
                                ok ->
                                    game_res:del(GoodsList1, ?FLOW_REASON_LONGWEN_UPGRADE),
                                    ok;
                                ?not_enough ->
                                    ?err(cost_not_enough)
                            end
                    end
            end
    end.

del_skill(SkillId) when is_integer(SkillId) ->
    Mng = get(?pd_skill_mng),
    case gb_sets:is_element(SkillId, Mng) of
        ?true ->
            RemainSkills = gb_sets:del_element(SkillId, Mng),
            put(?pd_skill_mng, RemainSkills);
        ?false ->
            ?ERROR_LOG("player ~p not_exist skill ~p", [?pname(), SkillId])
    end.

handle_client({Pack, Arg}) ->
    handle_client(Pack, Arg).

%% 前台要主动拉取得
handle_client(?MSG_SKILL_INIT_CLIENT, {}) ->
    ?player_send(skill_sproto:pkg_msg(?MSG_SKILL_INIT_CLIENT, {get(?pd_dressed_skills), get(?pd_skill_dress_group_id)})),
    ok;

handle_client(?MSG_SKILL_GET_LONG_WEN, {}) ->
    Gb = get(?pd_longwens_mng),
    LongWens = gb_trees:values(Gb),
%%    ?INFO_LOG("Gb = ~p", [Gb]),
%%    ?INFO_LOG("LongWens = ~p", [LongWens]),
    ?player_send(skill_sproto:pkg_msg(?MSG_SKILL_GET_LONG_WEN, {LongWens})),
    ok;
handle_client(?MSG_SKILL_UPGRADE_LONG_WEN, {LongWenId, Level}) ->
%%    ?INFO_LOG("LongWenId = ~p Level = ~p", [LongWenId, Level]),
    upgrade_long_wen(LongWenId, Level),
    ok;
%% use longwen 
handle_client(?MSG_SKILL_DRESS_LONG_WEN, {LongWenId}) ->
    dress_long_wen(LongWenId),
    ok;

%% todo 安放装备需要check
handle_client(?MSG_SKILL_DRESS_SKILL, {SkillId, Index}) ->
    %% SkillId 有可能是已经装备的,也有可能是没有装备的
    Dressed =
        case is_dressed_skill(SkillId) of
            ?true ->
                lists:keydelete(SkillId, 2, get(?pd_dressed_skills));
            ?false ->
                get(?pd_dressed_skills)
        end,
    case lists:keyfind(Index, 1, Dressed) of
        ?false ->
            put(?pd_dressed_skills, [{Index, SkillId} | Dressed]);
        {_, _OldSkillId} ->
            put(?pd_dressed_skills, lists:keyreplace(Index, 1, Dressed, {Index, SkillId}))
    end,
%%      ?DEBUG_LOG(" longwens SkillId = ~p Index = ~p", [SkillId, Index]),
    ?player_send(skill_sproto:pkg_msg(?MSG_SKILL_DRESS_SKILL, {SkillId, Index})),
    ok;


handle_client(?MSG_SKILL_UNDRESS_SKILL, {Index}) ->
    Dressed = get(?pd_dressed_skills),
    put(?pd_dressed_skills, lists:keydelete(Index, 1, Dressed)),
    ?DEBUG_LOG("undress index ~p successed", [Index]),
    ?player_send(skill_sproto:pkg_msg(?MSG_SKILL_UNDRESS_SKILL, {Index})),
    ok;

handle_client(?MSG_SKILL_CHANGE_USE_SKILL_GROUP, {GroupId}) ->
    put(?pd_skill_dress_group_id, GroupId),
    ?player_send(skill_sproto:pkg_msg(?MSG_SKILL_CHANGE_USE_SKILL_GROUP, {}));


handle_client(?MSG_SKILL_RESET_LONG_WEN, {SkillId}) ->
%%    ?INFO_LOG("LONG WEN XI DAIN"),
    reset_long_wen(SkillId);

handle_client(?MSG_SKILL_RESET_LONG_WEN_STATUS, {}) ->
%%    ?INFO_LOG("MSG_SKILL_RESET_LONG_WEN_STATUS"),
    ?ifdo(get(?pd_skill_reset_longwens) =:= undefined, put(?pd_skill_reset_longwens, [])),
    {_Career, InitSkill, Skills} = lists:keyfind(get(?pd_career), 1, misc_cfg:get_misc_cfg(skill_init)),

    RestTimes = orddict:from_list(get(?pd_skill_reset_longwens)),
    Ret =
        lists:foldl(fun({_Index, SkillId}, Acc) ->
            case orddict:is_key(SkillId, RestTimes) of
                ?true ->
                    [{SkillId, orddict:fetch(SkillId, RestTimes)} | Acc];
                _ ->
                    [{SkillId, 0} | Acc]
            end
                    end,
            [],
            InitSkill ++ Skills),

%%    ?INFO_LOG("Rest data:~p ", [Ret]),
    ?player_send(skill_sproto:pkg_msg(?MSG_SKILL_RESET_LONG_WEN_STATUS, {Ret}));


handle_client(_Cmd, _Msg) ->
    ?err(nonknown_msg).

handle_msg(_FromMod, {add_player_mp, Value}) ->
    put(?pd_mp, get(?pd_mp) + Value);

handle_msg(_FromMod, {add_player_anger, Value}) ->
    crown_new_mng:add_anger(Value);

handle_msg(FromMod, Msg) ->
    ?ERROR_LOG("~p recv a unknown msg ~p from ~p", [?pname(), Msg, FromMod]).


handle_frame({?frame_levelup, OldLvl}) ->
    Carrer = get(?pd_career),

    OldLevel1 = OldLvl + 1,
    CurLvL = get(?pd_level),
    if
        OldLevel1 =< CurLvL ->
            AllSkillList =
                com_util:fold(
                    OldLevel1,
                    CurLvL,
                    fun(Lvl, Acc) ->
                        Ids = load_cfg_skill:get_level_skills(Lvl, Carrer),
                        Ids ++ Acc
                    end,
                    gb_sets:to_list(get(?pd_skill_mng))
                ),
            put(?pd_skill_mng, gb_sets:from_list(AllSkillList));
        true ->
            ok
    end,
    ok;

handle_frame(_) -> ok.


create_mod_data(SelfId) ->
    Carrer = get(?pd_career),
    InitSkillList = load_cfg_skill:get_level_skills(1, Carrer),
    DressSkill =
        case lists:keyfind(Carrer, 1, misc_cfg:get_misc_cfg(skill_init)) of
            ?false ->
                [];
            {_Carrer, Ds, _InitSpecialSkill} ->
                Ds
        end,


    %% 所有的技能不主动添加,都是使用时检查可以释放就释放
    case dbcache:insert_new(?player_skill_tab, #player_skill_tab{id = SelfId,
        long_wens = [],
        skills = InitSkillList, %% 1 is level 1,
        dressed_skills = DressSkill}) of
        ?true ->
            ok;
        ?false ->
            ?ERROR_LOG("player ~p create player_skill_tab  not alread exists ", [SelfId])
    end,
    ok.

load_mod_data(PlayerId) ->
    case dbcache:load_data(?player_skill_tab, PlayerId) of
        [] ->
            ?ERROR_LOG("player ~p can not find data ~p mode", [PlayerId, ?MODULE]),
            create_mod_data(PlayerId),
            load_mod_data(PlayerId);
        [#player_skill_tab{skills = Mng, long_wens = LongWenList, dressed_skills = Dressed, dress_group_id = DressGroupId,
            skills_reset_times = RestTimes}] ->
            % ?DEBUG_LOG("skill load data --------------------:~p", [RestTimes]),
            ?pd_new(?pd_skill_mng, gb_sets:from_list(Mng)),
            ?pd_new(?pd_dressed_skills, Dressed),
            ?pd_new(?pd_longwens_mng, gb_trees:from_orddict(LongWenList)),
            ?pd_new(?pd_skill_dress_group_id, DressGroupId),
            ?pd_new(?pd_skill_reset_longwens, RestTimes)
    end,
    ok.

offline(PlayerId) ->
    %%     ?DEBUG_LOG("skill offline------------------------:~p",[get(?player_is_on_new_wizard)]),
    case erlang:get(?player_is_on_new_wizard) of
        true ->
            %%             ?DEBUG_LOG("skill offline is reset ok ------------------------"),
            erlang:put(?player_is_on_new_wizard, false),
            #{first_task := List} = misc_cfg:get_task_info(),
            [task_system:submit(task_system:get_dbid_of_task(Id)) || Id <- List],
            reset_dress_skill();
        0 ->
            erlang:put(?player_is_on_new_wizard, false),
            #{first_task := List} = misc_cfg:get_task_info(),
            [task_system:submit(task_system:get_dbid_of_task(Id)) || Id <- List],
            reset_dress_skill();
        _ ->
            pass
        %%             ?DEBUG_LOG("offline  is pass------------------")
    end,
    save_data(PlayerId),
    ok.

save_data(PlayerId) ->
    %?DEBUG_LOG("PlayerId------------------:~p",[PlayerId]),
    dbcache:update(?player_skill_tab,
        #player_skill_tab{id = PlayerId,
            skills = gb_sets:to_list(get(?pd_skill_mng)),
            dressed_skills = get(?pd_dressed_skills),
            long_wens = gb_trees:to_list(get(?pd_longwens_mng)),
            dress_group_id = get(?pd_skill_dress_group_id),
            skills_reset_times = get(?pd_skill_reset_longwens)
        }),
    ok.

init_client() -> nonused.
view_data(Acc) -> Acc.
online() ->
    ok.


%% @doc 安放特殊技能-新手副本使用
dress_skill() ->
    {_Career, InitSkill, InitSpecialSkill} = lists:keyfind(get(?pd_career), 1, misc_cfg:get_misc_cfg(skill_init)),
    FunFoldl = fun({Index, Skill}, DressSkill) ->
        lists:keystore(Index, 1, DressSkill, {Index, Skill})
               end,
    put(?pd_dressed_skills, lists:foldl(FunFoldl, InitSkill, InitSpecialSkill)),
    handle_client(?MSG_SKILL_INIT_CLIENT, {}). %走init协议，4号协议目前不支持

%% @doc 重置特殊技能-新手副本使用
reset_dress_skill() ->
    {_Carrer, InitDressSkill, InitSpecialSkill} = lists:keyfind(get(?pd_career), 1, misc_cfg:get_misc_cfg(skill_init)),
    put(?pd_dressed_skills, InitDressSkill),
    GroupId = get(?pd_skill_dress_group_id),
    ?player_send(skill_sproto:pkg_msg(?MSG_SKILL_UNDRESS_SKILL, {GroupId, [{Index} || {Index, _SkillId} <- InitSpecialSkill]})).


load_db_table_meta() ->
    [
        #db_table_meta
        {
            name = ?player_skill_tab,
            fields = ?record_fields(?player_skill_tab),
            shrink_size = 10,
            flush_interval = 1
        }
    ].

is_dressed_skill(SkillId) ->
    lists:keymember(SkillId, 2, get(?pd_dressed_skills)).



refresh_spirit_attr(_OldLongwen, _NewLongWen) ->
%%     case lookup_long_wen_cfg(OldLongwen) of
%%         ?none ->
%%             ignore;
%%         #long_wen_cfg{spirit_attr = DelSpiritAttr} ->
%%             del_attr(DelSpiritAttr)
%%     end,
%%     case lookup_long_wen_cfg(NewLongWen) of
%%         ?none ->
%%             ignore;
%%         #long_wen_cfg{spirit_attr = AddSpiritAttr} ->
%%             add_attr(AddSpiritAttr)
%%     end.
    %% 龙纹设计有改动
    ignore.

%% del_attr(SpiritAttr) ->
%%     player:sub_attr_amend(SpiritAttr).
%%
%% add_attr(SpiritAttr) ->
%%     player:add_attr_amend(SpiritAttr).



on_day_reset(_SelfId) ->
    put(?pd_skill_reset_longwens, []).