%%%-------------------------------------------------------------------
%%% @author lan
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 13. 七月 2016 上午11:25
%%%-------------------------------------------------------------------

-module(crown_new_mng).


-include_lib("pangzi/include/pangzi.hrl").
%-include_lib("config/include/config.hrl").

-include("inc.hrl").
-include("player_mod.hrl").
-include("handle_client.hrl").
-include("load_cfg_crown.hrl").
-include("cost.hrl").
-include("load_phase_ac.hrl").
-include("crown_new.hrl").
-include("player.hrl").
-include("../wonderful_activity/bounty_struct.hrl").
-include("system_log.hrl").

%% 皇冠的怒气值
-export
([
    add_anger/1,
    is_full_anger/0,
    get_anger/0,
    clear_anger/0,
    collection_anger/1,
    restore_crown/0,
    get_crown_skill_modify_id_list/0
]).

load_db_table_meta() ->
    [
        #db_table_meta{
            name = ?player_crown_new_tab,
            fields = ?record_fields(?player_crown_new_tab),
            shrink_size = 1,
            flush_interval = 3
        }
    ].


%% 玩家第一次登陆时调用
create_mod_data(SelfId) ->
    CrownSkillId = misc_cfg:get_level_crown_skill_list(),
    PCT = #player_crown_new_tab{id = SelfId, skill_list = [{CrownSkillId, ?SKILL_INIT_LEVEL, ?CROWN_SKILL_USE}]},
    ?debug_log_crown("init_gem self ~p gems ~p", [SelfId, PCT]),
    case dbcache:insert_new(?player_crown_new_tab, PCT) of
        ?true ->
            ok;
        ?false ->
            ?ERROR_LOG("player ~p create new player_auction_tab not alread exists ", [SelfId])
    end,
    ok.



load_mod_data(PlayerId) ->
    case dbcache:load_data(?player_crown_new_tab, PlayerId) of
        [] ->
            ?ERROR_LOG("player ~p can not find auction_tab  mode", [PlayerId]),
            create_mod_data(PlayerId),
            load_mod_data(PlayerId);
        [#player_crown_new_tab{skill_list = SkillList, anger = Anger}] ->
            ?pd_new(?pd_crown_skill_list, SkillList),
            ?pd_new(?pd_crown_anger, Anger)
    end,
    ok.

init_client() ->
    SkillList = get(?pd_crown_skill_list),
    Anger = get(?pd_crown_anger),
    ?debug_log_crown("init_client  ~p", [SkillList]),
    {SkillList1, SkillUseList} =
        lists:foldl
        (
            fun({SkillId, SkillLvl, IsUse}, {L1, L2}) ->
                case IsUse =:= 1 of
                    true ->
                        {[{SkillId, SkillLvl} | L1], [SkillId | L2]};
                    _ ->
                        {[{SkillId, SkillLvl} | L1], L2}
                end
            end,
            {[],[]},
            SkillList
        ),
    %% 初始化皇冠信息到客户端
%%    ?INFO_LOG("++++++++++++++++++++++ INIT CROWN Anger = ~p", [Anger]),
%%    ?INFO_LOG("++++++++++++++++++++++ INIT CROWN SkillList1 = ~p", [SkillList1]),
%%    ?INFO_LOG("++++++++++++++++++++++ INIT CROWN SkillUseList = ~p", [SkillUseList]),
    ?player_send(crown_new_sproto:pkg_msg(?MSG_CROWN_NEW_INIT_CLIENT, {Anger, SkillList1, SkillUseList})),
    ok.


view_data(Acc) -> Acc.

online() ->
    ok.

save_data(_) ->
    dbcache:update(?player_crown_new_tab, #player_crown_new_tab{id = get(?pd_id),
        anger = get(?pd_crown_anger),
        skill_list = get(?pd_crown_skill_list)
    }).

offline(_SelfId) ->
%%    ?INFO_LOG("save data ++++++++++++++++++++++++++++++++"),
%%    ?INFO_LOG("SkillList ======================== ~p", [get(?pd_crown_skill_list)]),
    save_data(get(?pd_id)),
    ok.

handle_frame(_) -> todo.




handle_client({Pack, Arg}) ->
    case task_open_fun:is_open(?OPEN_CROWN) of
        ?false ->
            ?return_err(?ERR_NOT_OPEN_FUN);
        ?true ->
            handle_client(Pack, Arg)
    end.

%% 激活技能
handle_client(?MSG_CROWN_SKILL_ACTIVATE, {SkillId}) ->
%%    ?INFO_LOG("SkillId  jihuo +++++++++++++++++ :~p", [SkillId]),
    CurCrownSkillModifyList = get_crown_skill_modify_id_list(),
    attr_new:begin_sync_attr(),
    Ret = activate_skill(SkillId),
    attr_new:end_sync_attr(),
    ReplyNum =
        case Ret of
            ok ->
                NewCrownSkillModifyList = get_crown_skill_modify_id_list(),
                update_crown_skill_modify_attr(CurCrownSkillModifyList, NewCrownSkillModifyList),
                equip_system:sync_skill_change_list(),
                ?REPLAY_MSG_SKILL_ACTIVATE_OK;
            {error, already_skill} ->
                ?REPLAY_MSG_SKILL_ACTIVATE_1;
            {error, level_not_enough} ->
                ?REPLAY_MSG_SKILL_ACTIVATE_2;
            {error, cost_not_enough} ->
                ?REPLAY_MSG_SKILL_ACTIVATE_3;
            {error, condition} ->
                ?REPLAY_MSG_SKILL_ACTIVATE_4;
            {error, unknown_type} ->
                ?REPLAY_MSG_SKILL_ACTIVATE_5;
            _ ->
                ?REPLAY_MSG_SKILL_ACTIVATE_255
        end,
%%    ?INFO_LOG("SkillId  jihuo +++++++++++++++++ :~p", [SkillId]),
%%    ?INFO_LOG("ReplayNum  jihuo +++++++++++++++++ :~p", [ReplyNum]),
    ?player_send(crown_new_sproto:pkg_msg(?MSG_CROWN_SKILL_ACTIVATE, {ReplyNum, SkillId}));

%% 技能升级
handle_client(?MSG_CROWN_SKILL_LEVELUP, {SkillId}) ->
%%    ?INFO_LOG("SkillId  shengji +++++++++++++++++ :~p", [SkillId]),
    CurCrownSkillModifyList = get_crown_skill_modify_id_list(),
    attr_new:begin_sync_attr(),
    {Ret, SkillLevel} = crown_skill_update(SkillId),
    attr_new:end_sync_attr(),
    ReplyNum =
        case Ret of
            ok ->
                bounty_mng:do_bounty_task(?BOUNTY_TASK_SHENGJI_CROWN, 1),
                NewCrownSkillModifyList = get_crown_skill_modify_id_list(),
                update_crown_skill_modify_attr(CurCrownSkillModifyList, NewCrownSkillModifyList),
                equip_system:sync_skill_change_list(),
                ?REPLAY_MSG_SKILL_UPDATE_OK;
            error_max_level ->
                ?REPLAY_MSG_SKILL_UPDATE_1;
            error_cost_not_enough ->
                ?REPLAY_MSG_SKILL_UPDATE_2;
            _ ->
                ?REPLAY_MSG_SKILL_UPDATE_255
        end,
%%    ?INFO_LOG("SkillId  shengji  +++++++++++++++++ :~p", [SkillId]),
%%    ?INFO_LOG("ReplyNum = ~p, SkillLevel = ~p", [ReplyNum, SkillLevel]),
    ?player_send(crown_new_sproto:pkg_msg(?MSG_CROWN_SKILL_LEVELUP, {ReplyNum, {SkillId, SkillLevel}}));

%% 装备皇冠技能
handle_client(?MSG_CROWN_DRESS_SKILL, {SkillId}) ->
%%    ?INFO_LOG("zhuangbei SkillId ========================= ~p", [SkillId]),
    Ret = crown_dress_skill(SkillId),
    ReplayNum =
        case Ret of
            ok ->
                equip_system:sync_skill_change_list(),
                ?REPLAY_MSG_SKILL_DRESS_OK;
            {error, not_find_skill} ->
                ?REPLAY_MSG_SKILL_DRESS_1;
            _ ->
                ?REPLAY_MSG_SKILL_DRESS_255
        end,
%%    ?INFO_LOG("zhuangbei return ============================== ~p", [ReplayNum]),
    ?player_send(crown_new_sproto:pkg_msg(?MSG_CROWN_DRESS_SKILL, {ReplayNum, SkillId}));

%% 脱掉皇冠技能
handle_client(?MSG_CROWN_UNDRESS_SKILL, {SkillId}) ->
%%    ?INFO_LOG("xiediao skillId ================= ~p", [SkillId]),
    Ret = undress_crown_skill(SkillId),
    ReplayNum =
        case Ret of
            ok ->
                equip_system:sync_skill_change_list(),
                ?REPLAY_MSG_UNDRESS_CROWN_STAR_OK;
            _ ->
                ?REPLAY_MSG_UNDRESS_CROWN_STAR_255
        end,
%%    ?INFO_LOG("xiediao return ====================== ~p", [ReplayNum]),
    ?player_send(crown_new_sproto:pkg_msg(?MSG_CROWN_UNDRESS_SKILL, {ReplayNum}));

%% 装备皇冠之星
handle_client(?MSG_CROWN_DRESS_CROWN_STAR, {SkillId}) ->
%%    ?INFO_LOG("dress crown star ======================= ~p", [SkillId]),
    Ret = crown_dress_crown_star(SkillId),
    ReplayNum =
        case Ret of
            ok ->
                equip_system:sync_skill_change_list(),
                ?REPLAY_MSG_DRESS_CROWN_STAR_OK;
            _ ->
                ?REPLAY_MSG_DRESS_CROWN_STAR_255
        end,
%%    ?INFO_LOG("dess crown start return ReplayNum = ~p, SkillId = ~p", [ReplayNum, SkillId]),
    ?player_send(crown_new_sproto:pkg_msg(?MSG_CROWN_DRESS_CROWN_STAR, {ReplayNum, SkillId}));

%% 脱掉皇冠之星技能
handle_client(?MSG_CROWN_UNDRESS_CROWN_STAR, {SkillId}) ->
    Ret = undress_crown_star(SkillId),
    ReplayNum =
        case Ret of
            ok ->
                equip_system:sync_skill_change_list(),
                ?REPLAY_MSG_UNDRESS_CROWN_STAR_OK;
            _ ->
                ?REPLAY_MSG_UNDRESS_CROWN_STAR_OK
        end,
    ?player_send(crown_new_sproto:pkg_msg(?MSG_CROWN_UNDRESS_CROWN_STAR, {ReplayNum}));

handle_client(?MSG_CROWN_SKILL_ADD_ATTR, {}) ->
    NewCrownSkillModifyList = get_crown_skill_modify_id_list(),
    update_crown_skill_modify_attr([], NewCrownSkillModifyList);

handle_client(_Msg, _) ->
    {error, unknown_msg}.

handle_msg(_FromMod, _Msg) ->
    {error, unknown_msg}.


%% 技能激活
activate_skill(SkillId) ->
    AllSkillList = get(?pd_crown_skill_list),
    PlayerLevel = get(?pd_level),
    case lists:keyfind(SkillId, 1, AllSkillList) of
        false ->
            CfgLvl = load_cfg_crown:get_skill_open_level(SkillId),
            case PlayerLevel >= CfgLvl of
                true ->
                    %% 获取激活消耗
                    CostId = load_cfg_crown:get_skill_activate_cost_id(SkillId, ?SKILL_INIT_LEVEL),
                    CostList = load_cost:get_cost_list(CostId),
                    case game_res:can_del(CostList) of
                        ok ->
                            %% 获取配置表中技能的激活条件
                            case load_cfg_crown:get_open_crown_before(SkillId) of
                                {error, Error} ->
                                    {error, Error};
                                [] ->
                                    game_res:del(CostList, ?FLOW_REASON_CROWN),                %% 扣除消耗
                                    put(?pd_crown_skill_list, [{SkillId, ?SKILL_INIT_LEVEL, ?CROWN_SKILL_UNUSE} | AllSkillList]),
                                    ok;
                                OpenCrownBeforeList ->
                                    case is_meet_activate_condition(OpenCrownBeforeList) of
                                        true ->
                                            game_res:del(CostList, ?FLOW_REASON_CROWN),                %% 扣除消耗
                                            put(?pd_crown_skill_list, [{SkillId, ?SKILL_INIT_LEVEL, ?CROWN_SKILL_UNUSE} | AllSkillList]),
                                            ok;
                                        _ ->
                                            {error, condition}
                                    end
                            end;
                        _ ->
                            {error, cost_not_enough}
                    end;
                _ ->
                    {error, level_not_enough}
            end;
        _ ->
            {error, already_skill}
    end.

crown_skill_update(SkillId) ->
    AllSkillList = get(?pd_crown_skill_list),
%%    ?INFO_LOG("AllSkillList ======================= ~p", [AllSkillList]),
    case lists:keyfind(SkillId, 1, AllSkillList) of
        {SkillId1, SkillLevel, IsUse} ->
            case SkillLevel+1 =< ?CROWN_SKILL_MAX_LEVEL of
                true ->
                    %% 获取皇冠技能的升级消耗
                    CostId = load_cfg_crown:get_skill_activate_cost_id(SkillId, SkillLevel+1),
                    CostList = load_cost:get_cost_list(CostId),
                    case game_res:can_del(CostList) of
                        ok ->
                            game_res:del(CostList, ?FLOW_REASON_CROWN),
                            %% 升级后装备相应的技能
                            CfgSkillId = load_cfg_crown:get_skill_id(SkillId1, SkillLevel),
                            case CfgSkillId =/= 0 andalso CfgSkillId =/= ?undefined of
                                true ->
                                    skill_mng:add_skill(CfgSkillId);
                                _ ->
                                    pass
                            end,
                            NewSkillList = lists:keyreplace(SkillId, 1, AllSkillList, {SkillId, SkillLevel+1, IsUse}),
                            put(?pd_crown_skill_list, NewSkillList),
                            {ok, SkillLevel+1};
                        _ ->
                            {error_cost_not_enough, SkillLevel}
                    end;
                _ ->
                    {error_max_level, SkillLevel}
            end;
        _ ->
            ?ERROR_LOG("not find skill id"),
            {pass, 0}
    end.

crown_dress_skill(SkillId) ->
    AllSkillList = get(?pd_crown_skill_list),
%%    ?INFO_LOG(" dress before AllSkillList ================================= ~p", [AllSkillList]),
    case lists:keymember(SkillId, 1, AllSkillList) of
        true ->
            SkillListNew =
                lists:foldl
                (
                    fun({Id, Level, _IsUse}, Acc) ->
                        case Id =:= SkillId of
                            true ->
                                %% 装备技能id
                                CfgSkillId = load_cfg_crown:get_skill_id(Id, Level),
                                case CfgSkillId =/= 0 andalso CfgSkillId =/= ?undefined of
                                    true ->
                                        skill_mng:add_skill(CfgSkillId);
                                    _ ->
                                        pass
                                end,
                                [{Id, Level, ?CROWN_SKILL_USE} | Acc];
                            _ ->
                                [{Id, Level, ?CROWN_SKILL_UNUSE} | Acc]
                        end
                    end,
                    [],
                    AllSkillList
                ),
%%            ?INFO_LOG(" dress after SkillListNew ================================= ~p", [SkillListNew]),
            put(?pd_crown_skill_list, SkillListNew),
            ok;
        _ ->
            {error, not_find_skill}
    end.

undress_crown_skill(SkillId) ->
    AllSkillList = get(?pd_crown_skill_list),
%%    ?INFO_LOG(" undress before AllSkillList = ~p", [AllSkillList]),
    AllSkillList1 =
        lists:foldl
        (
            fun({Id, Level, IsUse}, Acc) ->
                case Id =:= SkillId of
                    true ->
                        %% 删除技能
                        CfgSkillId = load_cfg_crown:get_skill_id(Id, Level),
                        case CfgSkillId =/= 0 andalso CfgSkillId =/= ?undefined of
                            true ->
                                skill_mng:del_skill(CfgSkillId);
                            _ ->
                                pass
                        end,
                        [{Id, Level, ?CROWN_SKILL_UNUSE} | Acc];
                    _ ->
                        [{Id, Level, IsUse} | Acc]
                end
            end,
            [],
            AllSkillList
        ),
%%    ?INFO_LOG(" undress after AllSkillList = ~p", [AllSkillList1]),
    put(?pd_crown_skill_list, AllSkillList1),
    ok.


crown_dress_crown_star(SkillId) ->
    AllSkillList = get(?pd_crown_skill_list),
%%    ?INFO_LOG(" dress start before AllSkillList = ~p", [AllSkillList]),
    SkillListNew =
        lists:foldl
        (
            fun({Id, Level, IsUse}, Acc) ->
                case load_cfg_crown:get_crown_type(Id) =:= ?HUANGGUAN_ZHIXING of
                    true ->
                        case Id =:= SkillId of
                            true ->
                                [{Id, Level, ?CROWN_SKILL_USE} | Acc];
                            _ ->
                                [{Id, Level, ?CROWN_SKILL_UNUSE} | Acc]
                        end;
                    _ ->
                        [{Id, Level, IsUse} | Acc]
                end
            end,
            [],
            AllSkillList
        ),

%%    ?INFO_LOG(" dress star after AllSkillList = ~p", [SkillListNew]),
    put(?pd_crown_skill_list, SkillListNew),
    ok.

undress_crown_star(SkillId) ->
    AllSkillList = get(?pd_crown_skill_list),
%%    ?INFO_LOG(" undress start before AllSkillList = ~p", [AllSkillList]),
    NewSkillList =
        lists:foldl
        (
            fun({Id, Level, IsUse}, Acc) ->
                case Id =:= SkillId of
                    true ->
                        [{Id, Level, ?CROWN_SKILL_UNUSE} | Acc];
                    _ ->
                        [{Id, Level, IsUse} | Acc]
                end
            end,
            [],
            AllSkillList
        ),
%%    ?INFO_LOG(" undress start after AllSkillList = ~p", [NewSkillList]),
    put(?pd_crown_skill_list, NewSkillList),
    ok.

%% 增加怒气值
add_anger(GainAnger) ->
    OldAnger = get(?pd_crown_anger),
    NewAnger = min(OldAnger + GainAnger, ?crown_anger_max_value),
    put(?pd_crown_anger, NewAnger),
    ?player_send(crown_sproto:pkg_msg(?MSG_CROWN_NEW_ANGER_CHANGE, {NewAnger})).

is_full_anger() ->
    get_anger() >= ?crown_anger_max_value.

get_anger() ->
    get(?pd_crown_anger).

clear_anger() ->
    NewAnger = 0,
    put(?pd_crown_anger, NewAnger),
    ?player_send(crown_sproto:pkg_msg(?MSG_CROWN_NEW_ANGER_CHANGE, {NewAnger})).


collection_anger(Anger) ->
    OldAnger = get(?pd_crown_anger),
    NewAnger = min(OldAnger ++ Anger, ?crown_anger_max_value),
    put(?pd_crown_anger, NewAnger),
    ?player_send(crown_sproto:pkg_msg(?MSG_CROWN_NEW_ANGER_CHANGE, {NewAnger})).


restore_crown() ->
    AllSkillList = get(?pd_crown_skill_list),
    lists:foreach
    (
        fun({Id, Level, IsUse}) ->
            SkillId = load_cfg_crown:get_skill_id(Id, Level),
            case IsUse =:= 1 andalso SkillId =/= ?undefined andalso SkillId =/= 0 of
                true -> skill_mng:add_skill(SkillId);
                _ -> pass
            end
        end,
        AllSkillList
    ),
    NewCrownSkillModifyList = get_crown_skill_modify_id_list(),
    update_crown_skill_modify_attr([], NewCrownSkillModifyList),
    ok.

%% 开启条件是否满足
is_meet_activate_condition(OpenCrownBeforeList) ->
    AllSkillList = get(?pd_crown_skill_list),
    ResultList =
        lists:foldl(
            fun({Id,NeedLv}, Acc) ->
                case lists:keyfind(Id,1,AllSkillList) of
                    false ->
                        [error | Acc];
                    {Id, Lv, _} ->
                        if
                            Lv >= NeedLv ->
                                [ok | Acc];
                            true ->
                                [error | Acc]
                        end
                end
            end,
            [],
            OpenCrownBeforeList
        ),

    lists:all(
        fun(E) ->
            E == ok
        end,
        ResultList
    ).

%% 获取皇冠技能修改集
get_crown_skill_modify_id_list() ->
    %% 计算皇冠技能的修改集
    AllCrownSkillList = get(?pd_crown_skill_list),
    CrownSkillCfgList =
        lists:foldl
        (
            fun({SkillId, SkillLevel, _}, AccList) ->
                case load_cfg_crown:get_crown_skill_modify_id(SkillId, SkillLevel) of
                    CfgId when is_integer(CfgId) andalso CfgId =/= 0 ->
                        [CfgId | AccList];
                    _ ->
                        AccList
                end
            end,
            [],
            AllCrownSkillList
        ),
    CrownSkillCfgList.

%% 更新皇冠技能修改集属性
update_crown_skill_modify_attr(CurCrownSkillModifyList, NewCrownSkillModifyList) ->
    lists:foreach(
        fun(OldSkillModifyId) ->
%%            equip_buf:take_off_buf(OldSkillModifyId)
            equip_buf:remove_skill_modify_attr(OldSkillModifyId)
        end, CurCrownSkillModifyList),
    OldPlayerAttr = attr_new:get_oldversion_attr(),
    lists:foreach(
        fun(NewSkillModifyId) ->
%%            equip_buf:take_on_buf(NewSkillModifyId)
            equip_buf:add_skill_modify_attr(NewSkillModifyId)
        end, NewCrownSkillModifyList),
    NewPlayerAttr = attr_new:get_oldversion_attr(),
    SubPlayerAttr = attr_new:get_sub_attr(OldPlayerAttr, NewPlayerAttr),
    ?player_send(crown_new_sproto:pkg_msg(?MSG_CROWN_SKILL_ADD_ATTR, {?r2t(SubPlayerAttr)})).




