%%%-------------------------------------------------------------------
%%% @author yujian
%%% @doc 单机副本和客户端的交互
%%%-------------------------------------------------------------------
-module(scene_client_mng).

-include("inc.hrl").
-include("scene.hrl").
-include("player.hrl").
-include("main_ins_struct.hrl").
-include("scene_monster.hrl").
-include("achievement.hrl").
-include("item_new.hrl").
-include("load_cfg_gates.hrl").
-include("item.hrl").
-include("load_item.hrl").
-include("porsche_event.hrl").
-include("../wonderful_activity/bounty_struct.hrl").
-include("system_log.hrl").

-define(pd_dropid_list, pd_dropid_list).

-export([handle_client/2, reset_drop/0, all_drop/4, tidy_postion/3]).

-export
([
    delete_nobuff_from_droplist/1
    , category_droplist/1   %% 将掉落列表分为buff和非buff物品 {BuffList, DisBuffList}
]).

tidy_postion(_SceneId, _X, _Y) -> ok.
    % Xp = X * ?GRID_PIX,
    % Yp = Y * ?GRID_PIX,
    % GateList = my_ets:get(?pd_offset_gate_msg, []),
    % ThisGateList = lists:filter
    % (
    %     fun
    %         ({SceneIdCfg, {XC,YC}, _OutOffset, {_,{L,W},_}}) when SceneIdCfg =:= SceneId ->
    %             XCfgMin = XC - L/2,
    %             XCfgMax = XC + L/2,
    %             YCfgMin = YC,
    %             YCfgMax = YC + W,
    %             if
    %                 Xp >= XCfgMin andalso Xp =< XCfgMax andalso Yp >= YCfgMin andalso Yp =< YCfgMax ->
    %                     true;
    %                 true ->
    %                     false
    %             end;
    %         (_) ->
    %             false
    %     end,
    %     GateList
    % ),
    % case ThisGateList of
    %     [{_SceneIdCfg, {_CfgX, _CfgY}, {_OffsetX, _OffsetY}, {_,{_L,_W},_}}|_TailList] ->
    %         %% 碰撞检测的可以，但按配置表算出来的偏移值是不可行走点，合版本在前，此处问题临时处理。
    %         X2 = erlang:max(10, X-3),
    %         {SceneId, X2, Y};
    %     _ ->
    %         {SceneId, X, Y}
    % end.

do_relive(ReliveIdx) ->
    achievement_mng:do_ac(?yuandifuhuo),
    evt_util:send(#player_revive{}),
    get(?pd_scene_pid) ! ?scene_mod_msg(scene_player, {scene_relive, ReliveIdx}).

handle_client(?MSG_SCENE_GOTO_LAST_CITY, {}) ->
    %main_instance_mng:leave_main_instance_clear_data(),
    {SceneId, X, _Y} = scene_mng:get_save_point(),
    % ?DEBUG_LOG("SceneId---:~p----X---:~p---Y---:~p",[SceneId, X, Y]),
    % {SceneId1, X1, Y1} = scene_client_mng:tidy_postion(SceneId, X, Y),
    %?DEBUG_LOG("SceneId1---:~p----X1---:~p---Y1---:~p",[SceneId1, X1, Y1]),
    main_ins_team_mod:leave_team_if_in(get(?pd_id)),
    scene_mng:enter_scene_request(SceneId, erlang:max(20, X - 3), 16);

%% 单件副本加血
handle_client(?MSG_SCENE_CLIENT_ADD_HP_MP, {}) ->
    %?DEBUG_LOG("add_hp----------------------------"),
    {Cd} = ?ADD_HP_MP_CD,
    ?ifdo(com_time:now() - get(?pd_attr_add_hp_mp_cd) < Cd,
        ?return_err(?cd_limit)),

    case main_ins_util:ins_cost(add_hp) of
        ok -> 
            %?DEBUG_LOG("add_hp is ok------------------------------"),
            ?player_send(scene_sproto:pkg_msg(?MSG_SCENE_CLIENT_ADD_HP_MP, {0}));
        {error, Reply} -> 
            %?DEBUG_LOG("error----------------------:~p",[Reply]),
            ?player_send(scene_sproto:pkg_msg(?MSG_SCENE_CLIENT_ADD_HP_MP, {Reply}))
    end;

handle_client(?MSG_SCENE_CLIENT_PLAYER_DIE, {}) ->
    ?DEBUG_LOG("player die --------------------------"),
    {PdSceneId, SceneMode, _Other} = get(?pd_scene_id),
    Pid = get(?pd_scene_pid),
    case load_cfg_scene:get_scene_type({PdSceneId, SceneMode, _Other}) of
        ?SC_TYPE_MAIN_INS ->
            put(bufajiangli, ?false),
            put(abyss_player_die, ?false),
            Die = util:get_pd_field(?pd_ins_die_count, 0),
            put(?pd_ins_die_count, 1 + Die),
            achievement_mng:do_ac(?sierhousheng),
            system_log:info_copy_die(PdSceneId),
            % ?ERROR_LOG("player die1 --------------------------:~p", [PdSceneId]),
            Pid ! ?scene_mod_msg(SceneMode, {player_die});
        ?SC_TYPE_ARENA ->
            % ?DEBUG_LOG("player die2 --------------------------"),
            Pid ! ?scene_mod_msg(SceneMode, {player_die});
        _ -> ok
    end;

handle_client(?MSG_SCENE_INS_RESET_HP_CD, {}) ->
    %?DEBUG_LOG("hp cd -=-----------------------------"),
    put(?pd_attr_add_hp_mp_cd, get(?pd_attr_add_hp_mp_cd) - 30),
    ?player_send(scene_sproto:pkg_msg(?MSG_SCENE_INS_RESET_HP_CD, {}));

handle_client(?MSG_SCENE_INS_RESET_USE_COUNT, {}) ->
    Count = erlang:max(0, get(?pd_attr_add_hp_times) - 1),
    put(?pd_attr_add_hp_times, Count),
    %?DEBUG_LOG("Count---------------------------------:~p",[Count]),
    ?player_send(scene_sproto:pkg_msg(?MSG_SCENE_INS_RESET_USE_COUNT, {Count}));

handle_client(?MSG_SCENE_RELIVE, {_, AgentIdx}) ->
    %?DEBUG_LOG("MSG_SCENE_RELIVE----------------------------------"),
    SceneId = load_cfg_scene:get_config_id(get(?pd_scene_id)),
    case load_cfg_main_ins:get_ins_type(SceneId) of
        ?T_INS_GWGC ->
            %?DEBUG_LOG("T_INS_GWGC---------------------------"),
            case main_ins_util:team_relive_cost() of
                ?true ->
                    SelfIdx = get(?pd_idx),
                    %?DEBUG_LOG("SelfIdx-----:~p-----AgenIdx-----:~p",[SelfIdx, AgentIdx]),
                    if
                        AgentIdx =:= SelfIdx ->
                            do_relive(SelfIdx);
                        true ->
                            do_relive(AgentIdx)
                    end;
                {error, Reply} ->
                    ?player_send(scene_sproto:pkg_msg(?MSG_SCENE_RELIVE, {Reply}))
            end;
        _ ->
            case main_ins_util:ins_cost(?relive) of
                ok ->
                    do_relive(get(?pd_idx));
                {error, Reply} ->
                    ?player_send(scene_sproto:pkg_msg(?MSG_SCENE_RELIVE, {Reply}))
            end
    end;


handle_client(?MSG_SCENE_CLIENT_RELIVE, {}) ->
    ?DEBUG_LOG("relive----------------------------------:"),
    case main_ins_util:ins_cost(?relive) of
        ok ->
            %?DEBUG_LOG("relive------------------------------------2"),
            achievement_mng:do_ac(?yuandifuhuo),
            %% 丢出玩家复活事件
            evt_util:send(#player_revive{}),
            ?player_send(scene_sproto:pkg_msg(?MSG_SCENE_CLIENT_RELIVE, {0}));
        {error, Reply} ->
            %?DEBUG_LOG("relive----Reply--------------------------------:~p",[Reply]),
            ?player_send(scene_sproto:pkg_msg(?MSG_SCENE_CLIENT_RELIVE, {Reply}))
    end;

%% @doc 释放怒气技
handle_client(?MSG_SCENE_CLIENT_RELEASE_ANGER_SKILL, {}) ->
    achievement_mng:do_ac2(?huangguanzhili, 0, 1);

handle_client(?MSG_SCENE_CLIENT_KILL_MONSTER, {MonsterBid, IsKillSelf}) ->
    SceneData = get(?pd_scene_id),
    case load_cfg_scene:get_scene_type(SceneData) of
        ?SC_TYPE_MAIN_INS ->
            {_PdSceneId, SceneMode, _Other} = SceneData,
            case scene_monster:lookup_monster_cfg(MonsterBid) of
                ?none -> 0;
                MonsterCFG ->
                    bounty_mng:do_bounty_task(?BOUNTY_TASK_KILL_MONSTER, 1),
                    daily_task_tgr:do_daily_task({?ev_kill_monster, 0}, 1),
                    daily_task_tgr:do_daily_task({?ev_kill_monster, MonsterBid}, 1),
                    MainInsType = load_cfg_main_ins:get_ins_type(SceneData),
                    %?DEBUG_LOG("MainInsType----------------------:~p",[MainInsType]),
                    PdKey = 
                    case MonsterCFG#monster_cfg.type of
                        ?MT_BOOS ->
                            if
                                MainInsType =:= ?none; MainInsType =:= ?T_INS_FREE ->
                                    pass;
                                true ->
                                    achievement_mng:do_ac(?emolieshou),
                                    event_eng:post(?ev_kill_monster_by_bid, MonsterBid)
                            end,
                            pd_kill_boss_monster_count;
                        _ ->
                            if
                                MainInsType =:= ?none; MainInsType =:= ?T_INS_FREE ->
                                    pass;
                                true ->
                                    achievement_mng:do_ac(?guaiwulieren),
                                    event_eng:post(?ev_kill_monster_by_bid, MonsterBid)
                            end,
                            pd_kill_normal_monster_count
                    end,
                    MonsterExp = MonsterCFG#monster_cfg.monster_exp,
                    player:add_exp(MonsterExp),
                    pet_new_mng:add_pet_new_exp_if_fight(MonsterExp),
                    Pid = get(?pd_scene_pid),
                    Pid ! ?scene_mod_msg(SceneMode, {del_monsters, self(), PdKey, MonsterBid, IsKillSelf})
            %achievement_mng:update_instance_ac(?ev_kill_monster)
            end;
        _ ->
            ok
    end;

handle_client(?MSG_SCENE_CLIENT_DROP_BY_MONSTER, {ClientId, TagId}) ->
    %%Todo 如果体力不够进副本，非buff物品要剔除掉
    PdSceneId = get(?pd_scene_id),
    case load_cfg_scene:get_scene_type(PdSceneId) of
        ?SC_TYPE_MAIN_INS ->
            DropList = get_drop_by_tag(load_cfg_scene:get_config_id(PdSceneId), TagId, get(?pd_level)),
            % ?INFO_LOG("DropList1: ~p", [DropList]),
            NewDropList = delete_nobuff_from_droplist(DropList),
            % ?INFO_LOG("NewDropList1: ~p", [NewDropList]),
%%            case attr_new:get(?pd_can_get_prize_from_room, false) of
            % ?INFO_LOG("NewDropList2: ~p", [main_ins_mod:is_can_get_prize_from_room()]),
            case main_ins_mod:is_can_get_prize_from_room() of
                ?true ->
                    ?player_send(scene_sproto:pkg_msg(?MSG_SCENE_CLIENT_DROP_BY_MONSTER, {ClientId, DropList}));
                ?false ->
                    ?player_send(scene_sproto:pkg_msg(?MSG_SCENE_CLIENT_DROP_BY_MONSTER, {ClientId, NewDropList}))
            end;
        _ ->
            ?player_send(scene_sproto:pkg_msg(?MSG_SCENE_CLIENT_DROP_BY_MONSTER, {ClientId, []}))
    end;

handle_client(?MSG_SCENE_CLIENT_PICKUP_DROP, {DropId}) ->
    PdSceneId = get(?pd_scene_id),
    case load_cfg_scene:get_scene_type(PdSceneId) of
        ?SC_TYPE_MAIN_INS ->
            lists:map(
                fun
                    ({Item, _ItemNum}) when is_record(Item, item_new) ->
                        game_res:set_res_reasion(<<"掉落">>),
                        game_res:try_give_ex([{Item}], ?S_MAIL_INSTANCE, ?FLOW_REASON_FUBEN_DROP);

                    ({Item, ItemNum}) ->
                        if
                            %% 如果是金币就保存后一起发
                            Item =:= ?PL_MONEY ->
                                save_drop_money({Item, ItemNum});
                            true ->
                                game_res:try_give_ex([{Item, ItemNum}], ?S_MAIL_INSTANCE, ?FLOW_REASON_FUBEN_DROP)
                        end
                end,
                get_drop_by_id(DropId)),
            ?player_send(scene_sproto:pkg_msg(?MSG_SCENE_CLIENT_PICKUP_DROP, {}));
        _ ->
            ?player_send(scene_sproto:pkg_msg(?MSG_SCENE_CLIENT_PICKUP_DROP, {}))
    end;

handle_client(?MSG_SCENE_INSTANCE_CLIENT_KILL_MON, {IsInsComplete, WaveNum, DoubleHit, ShouJi, PassTime, ReliveNum, AbyssPercent, AbyssScore, MonsterBin}) ->
    send_all_droplist(),
    % ?INFO_LOG("IsInsComplete-----:~p----WaveNum---:~p----DoubleHIt---:~p---Shouji--:~p----PassTime---:~p---MonsterBin--:~p",[IsInsComplete, WaveNum, DoubleHit, ShouJi, PassTime, MonsterBin]),
    <<Size:8, OtherBin/binary>> = MonsterBin,
    A = un_pack_of_monsterbin(OtherBin, Size, []),
    Pid = get(?pd_scene_pid),
    case get(?pd_scene_id) of
        {PdSceneId, SceneMode, _Other} ->
            case guild_boss:is_guild_boss_fight() of
                true ->
                    if
                        1 == IsInsComplete -> guild_boss:stop_self_guild_boss_fight();
                        true -> pass
                    end;
                _O ->
                    case load_cfg_scene:get_scene_type({PdSceneId, SceneMode, _Other}) of
                        ?SC_TYPE_MAIN_INS ->
                            Pid ! ?scene_mod_msg(SceneMode, {client_sumbit, get(?pd_id), self(), {IsInsComplete, WaveNum, DoubleHit, ShouJi, PassTime, ReliveNum, AbyssPercent, AbyssScore, A}});
                        ?T_INS_SKY_RAND ->
                            Pid ! ?scene_mod_msg(SceneMode, {client_sumbit, get(?pd_id), self(), {IsInsComplete, WaveNum, DoubleHit, ShouJi, PassTime, ReliveNum, AbyssPercent, AbyssScore, A}});
                        ?SC_TYPE_ARENA ->
                            Pid ! ?scene_mod_msg(SceneMode, {client_sumbit, get(?pd_id), self()});
                        _ ->
                            ignore
                    end
            end;
        SceneId when is_integer(SceneId) ->
            % ?INFO_LOG("4----------------------------------"),
            Pid ! ?scene_mod_msg(room_system, {team_fuben_complete, get(?pd_id), get(?pd_idx), self(), IsInsComplete, WaveNum, DoubleHit, ShouJi, PassTime, ReliveNum, A});
        Other ->
            ?ERROR_LOG("error, unknow scene_id:~p", [Other])
    end;

handle_client(_Cmd, _Msg) ->
    {error, unknow_msg}.

-define(pd_scene_drop_list, pd_scene_drop_list). %{掉落列表, 已经发放的奖励dropid}
-define(pd_drop_id, pd_drop_id).

%% @doc 重置掉落列表
reset_drop() ->
    erase(pd_dropid_list),
    erase(pd_scene_drop_list),
    erase(pd_drop_id).

%% @doc 获取掉落列表
get_drop_items() ->
    get(?pd_scene_drop_list).

%% @doc 根据掉落id获取掉落道具
get_drop_by_id(DropId) ->
    {_AllDrops, DropsDone} = get_drop_items(),
    case lists:keyfind(DropId, 1, DropsDone) of
        {DropId, ItemOrItemBid, ItemCount} -> [{ItemOrItemBid, ItemCount}];
        false -> []
    end.

get_drop_by_tag(SceneId, Tag, PlayerLevel) ->
    {AllDrops, DropsDone} = 
    case get_drop_items() of
        ?undefined -> 
            {[], []};
        DropList -> 
            DropList
    end,
    NowTagDrops = 
    case lists:keyfind(Tag, 1, AllDrops) of
        ?false ->
            lookup_drop_by_tag(SceneId, Tag, PlayerLevel);
        {_Tag, TagDrops} -> 
            TagDrops
    end,
    random_drop(Tag, NowTagDrops, AllDrops, DropsDone). %一个tag中随机掉落道具
%%     all_drop(Tag, NowTagDrops, AllDrops, DropsDone). % 掉落一个tag的所有道具


%% @doc 根据场景id、tag、人物等级初始化掉落库
lookup_drop_by_tag(SceneId, Tag, PlayerLevel) ->
    TagList = load_cfg_main_ins:get_scene_tag(SceneId, PlayerLevel),
    case lists:keyfind(Tag, 1, TagList) of
        false -> [];
        {Tag, DropId} ->
            Fun =
                fun
                    ({ItemId, ItemCount, _}) ->
                        Item =
                            if
                                ItemId =< 1000 -> ItemId;
                                true -> entity_factory:build(ItemId, 1, [], ?FLOW_REASON_FUBEN_DROP)
                            end,
                        {get_drop_id(), Item, ItemCount}
                end,
            lists:map(Fun, prize:get_random(DropId))
    end.

random_drop(Tag, NowTagDrops, AllDrops, DropsDone) ->
    ThisTagDrops = case NowTagDrops of
                       [] ->
                           [];
                       [OneDrop] -> [OneDrop];%只剩一个掉落
                       NowTagDrops ->
                           %% @doc 随机掉落
%%                            ThisTagDropNum = com_util:random(1, length(NowTagDrops)),
%%                            com_util:rand_more(NowTagDrops, ThisTagDropNum)
                           %%策划提供掉落规律
                           case com_util:rand_more(NowTagDrops, get_drop_num_by_tag(Tag)) of
                               ?undefined -> [];
                               RandDrop -> RandDrop
                           end
                   end,

    FunFoldl = fun({DropId1, Item, _ItemNum}, {NowTagDrops1, ThisTagDrops1, DropsDone1}) when is_record(Item, item_new) ->
        Drop = {DropId1, Item#item_new.bid, Item#item_new.quantity, 1},
        {
            lists:keydelete(DropId1, 1, NowTagDrops1),
            [Drop | ThisTagDrops1],
            [{DropId1, Item, _ItemNum} | DropsDone1]
        };
        ({DropId1, ItemBid, ItemNum}, {NowTagDrops1, ThisTagDrops1, DropsDone1}) ->
            Drop = {DropId1, ItemBid, 1, ItemNum},
            {
                lists:keydelete(DropId1, 1, NowTagDrops1),
                [Drop | ThisTagDrops1],
                [{DropId1, ItemBid, ItemNum} | DropsDone1]
            }
    end,
    {NowTagDrops2, ThisTagDrops2, DropsDone2} = lists:foldl(FunFoldl, {NowTagDrops, [], DropsDone}, ThisTagDrops),
    put(?pd_scene_drop_list, {lists:keystore(Tag, 1, AllDrops, {Tag, NowTagDrops2}), DropsDone2}),
    ThisTagDrops2.

all_drop(Tag, NowTagDrops, AllDrops, DropsDone) ->
    FunFoldl = fun({DropId1, Item, _ItemNum}, {SendToClient1, DropsDone1}) when is_record(Item, item_new) ->
        Drop = {DropId1, Item#item_new.bid, Item#item_new.quantity, 1},
        {
            [Drop | SendToClient1],
            [{DropId1, Item, 1} | DropsDone1]
        };
        ({DropId1, ItemBid, ItemNum}, {SendToClient1, DropsDone1}) ->
            Drop = {DropId1, ItemBid, 1, ItemNum},
            {
                [Drop | SendToClient1],
                [{DropId1, ItemBid, ItemNum} | DropsDone1]
            }

    end,
    {SendToClient2, DropsDone2} = lists:foldl(FunFoldl, {[], DropsDone}, NowTagDrops),
    put(?pd_scene_drop_list, {lists:keystore(Tag, 1, AllDrops, {Tag, []}), DropsDone2}),
    SendToClient2.

%% @doc 自增长的掉落id
get_drop_id() ->
    case get(?pd_drop_id) of
        ?undefined ->
            ?pd_new(?pd_drop_id, 2),
            1;
        Id ->
            put(?pd_drop_id, (Id + 1) band 16#FFFF)
    end.

%%根据tagid，获取掉落数量 tag = 1 掉落1件道具,  tag = 2 -> 掉落1件道具 tag = 3 -> 掉落2件道具, tag = 4 -> 掉落2件道具, tag = 5 -> 掉落2件道具
get_drop_num_by_tag(1) -> 1;
get_drop_num_by_tag(2) -> 1;
get_drop_num_by_tag(3) -> 2;
get_drop_num_by_tag(4) -> 2;
get_drop_num_by_tag(5) -> 2;
get_drop_num_by_tag(_) -> 2.

%% 剔除掉掉落列表中的非buff物品
delete_nobuff_from_droplist(Droplist) ->
    NewDropList =
        lists:foldl
        (
            fun(Drop = {_, Item_bid, _, _}, List) ->
                case load_item:get_item_cfg(Item_bid) of
                    {error, Error} -> {error, Error};
                    #item_attr_cfg{type = ItemType} ->
                        case ItemType of
                            %% 物品是buff时加到新列表中
                            ?ITEM_TYPE_BUFF ->
                                [Drop | List];
                            _ ->
                                List
                        end;
                    _ -> {error, not_found_cfg}
                end
            end,
            [],
            Droplist
        ),
    NewDropList.

%% 将掉落列表中的物品分为buff物品和非buff物品
category_droplist(Droplist) ->
    lists:foldl
    (
        fun(Drop = {Item_bid, _}, {BuffList, DisBuffList}) ->
            case load_item:get_item_cfg(Item_bid) of
                {error, Error} -> {error, Error};
                #item_attr_cfg{type = ItemType} ->
                    case ItemType of
                        %% 物品分类
                        ?ITEM_TYPE_BUFF ->
                            {[Drop | BuffList], DisBuffList};
                        _ ->
                            {BuffList, [Drop | DisBuffList]}
                    end;
                _ -> {error, not_found_cfg}
            end
        end,
        {[], []},
        Droplist
    ).

send_all_droplist() ->
    DropList = get(?pd_dropid_list),
%%    ?DEBUG_LOG("DropList:~p", [DropList]),

    MergeList = item_goods:merge_goods(DropList),
%%    ?DEBUG_LOG("MergeList:~p", [MergeList]),
    game_res:set_res_reasion(<<"掉落">>),
    game_res:try_give_ex(MergeList, ?S_MAIL_INSTANCE, ?FLOW_REASON_FUBEN_DROP),
    put(?pd_dropid_list, []).


save_drop_money(Money) ->
    case get(?pd_dropid_list) of
        ?undefined ->
            put(?pd_dropid_list, [Money]);
        List ->
            put(?pd_dropid_list, [Money | List])
    end.

un_pack_of_monsterbin(<<>>, 0, List) ->
    List;
un_pack_of_monsterbin(<<MonsterBid:32, Count:16, Res/binary>>, Size, List) ->
    un_pack_of_monsterbin(Res, Size - 1, [{MonsterBid, Count} | List]).
