% %%% coding:utf-8
% %%%-------------------------------------------------------------------
% %%% @author wcg
% %%% @doc 宠物系统
% %%% @end
% %%%-------------------------------------------------------------------
% %% API
-module(pet_mng).


% -include_lib("pangzi/include/pangzi.hrl").
% %-include_lib("config/include/config.hrl").

% -include("inc.hrl").
% -include("player.hrl").
% -include("load_spirit_attr.hrl").
% -include("pet.hrl").
% -include("pet_def.hrl").
% -include("player_mod.hrl").
% -include("load_item.hrl").
% -include("item.hrl").
% -include("item_new.hrl").
% -include("item_bucket.hrl").
% -include("handle_client.hrl").
% -include("load_cfg_pet.hrl").

% -export([create_pet/2, get_cur_fight_pet/0]).

% -export
% ([
%     player_die/0                    % 副本中玩家死亡
%     , main_instacne_complete/0      % 副本中玩家通关
%     , add_pet_exp_if_fight/1        % 通关副本后给出战宠物增加经验值
%     , pet_enter_scene/4, pet_leave_scene/2, pet_send_msg/1
% ]).

% -define(player_pet_tab, player_pets).
% -define(PET_LIST_WAY_ALL, 1).
% -define(PET_LIST_WAY_ADD, 2).
% -define(PET_LIST_WAY_CHANGE, 3).
% -define(PET_LIST_WAY_DEL, 4).

% -define(COST_TYPE_PET, 1).
% -define(COST_TYPE_ITEM, 2).

% -define(HMSG_TREASURE_FINISH(__PETID, __TREASUREID), {treasure_finish, __PETID, __TREASUREID}).

% %% 创建宠物 1.0级宠物 2.封印后的宠物（宠物信息保持封印前的状态）
% create_pet(PetCFGId, ItemBasicInfo) ->
%     #{limit_num:=PetCount} = misc_cfg:get_misc_cfg(pet_info),
%     PlayerPetCount = length(get(?pd_all_pets)),
%     if
%         (PlayerPetCount + 1) > PetCount ->
%             {?error, pet_max_count};
%         true ->
%             #pet_cfg{hatch_cost = CostId} = load_cfg_pet:lookup_pet_cfg(PetCFGId),
%             case cost:cost(CostId) of
%                 {?error, _Reason} ->
%                     {?error, cost_not_enough};
%                 _ ->
%                     case ItemBasicInfo of
%                         [] ->
%                             add_pet(init_pet(PetCFGId)),
%                             ok;
%                         [{?item_ex_pet_attr_key_petid, PetId}] ->
%                             case pet_global_server:get_pet(PetId) of
%                                 [] ->
%                                     {?error, pet_egg_null};
%                                 Pet ->
%                                     add_pet(Pet#pet{status = ?PET_STATUS_ALIVE}),
%                                     pet_global_server:del_pet(PetId),
%                                     ok
%                             end

%                     end
%             end
%     end.

% init_pet(PetCfgID) ->
%     PetCfg = load_cfg_pet:lookup_pet_cfg(PetCfgID),
%     AttrSats = random_attr__(PetCfg#pet_cfg.jd_attr_min_num,
%         PetCfg#pet_cfg.jd_attr_max_num,
%         PetCfg#pet_cfg.jd_attr),

%     InitiativeSkill = init_initiative_skill(PetCfg#pet_cfg.quality),
%     PassivitySkill = init_passivity_skill(PetCfg#pet_cfg.quality),
%     PetId = gen_id:next_id(pet_id_tab),
%     Attr = attr:add_by_sats(AttrSats, attr:new()),
%     NewPetLevel = load_cfg_pet:lookup_pet_level_cfg({PetCfgID, 1}),
%     Attr1 = attr:add(NewPetLevel#pet_level_cfg.attr, Attr),

%     #pet{id = PetId,
%         cfgid = PetCfgID,
%         name = erlang:list_to_binary(PetCfg#pet_cfg.name),
%         quality = PetCfg#pet_cfg.quality,
%         attr = Attr1#attr{id = 0},
%         facade = lists:nth(1, PetCfg#pet_cfg.facade),
%         level = 1,
%         tacit_value = PetCfg#pet_cfg.tacit_value,
%         exclusive_skill = lists:nth(1, PetCfg#pet_cfg.exclusive_skill),
%         initiative_skill = InitiativeSkill,
%         passivity_skill = PassivitySkill,
%         status = ?PET_STATUS_ALIVE}.

% random_attr__(Min, Max, Attr) ->
%     {OutL, DropL} =
%         lists:foldl(fun({Id, Probo, B, E}, {Out, Drop}) ->
%             ROut = ?random(1000),
%             if
%                 ROut =< Probo ->
%                     {[{Id, com_util:random(B, E)} | Out], Drop};
%                 ?true ->
%                     {Out, [{Id, com_util:random(B, E)} | Drop]}
%             end
%         end,
%             {[], []},
%             Attr),

%     OutLen = length(OutL),
%     if
%         OutLen - Min < 0 ->
%             lists:sublist(DropL, Min - OutLen) ++ OutL;
%         OutLen - Max > 0 ->
%             lists:sublist(OutL, OutLen - Max);
%         ?true ->
%             OutL
%     end.

% random_attr___(Min, Max, Attr) ->
%     {OutL, DropL} =
%         lists:foldl(fun({Id, Probo, {B, E}}, {Out, Drop}) ->
%             ROut = ?random(1000),
%             if
%                 ROut =< Probo ->
%                     {[{Id, com_util:random(B, E)} | Out], Drop};
%                 ?true ->
%                     {Out, [{Id, com_util:random(B, E)} | Drop]}
%             end
%                     end,
%             {[], []},
%             Attr),

%     OutLen = length(OutL),
%     if
%         OutLen - Min < 0 ->
%             lists:sublist(DropL, Min - OutLen) ++ OutL;
%         OutLen - Max > 0 ->
%             lists:sublist(OutL, OutLen - Max);
%         ?true ->
%             OutL
%     end.


% init_initiative_skill(Quality) ->
%     Slots0 = [{Slot, ?PET_SKILL_STATE_VOID} || Slot <- lists:seq(1, ?PET_INITIATIVE_MAX_SLOT)],
%     QulityCfg = load_cfg_pet:lookup_pet_quality_ratio_cfg(Quality),
%     Max = lists:seq(1, QulityCfg#pet_quality_ratio_cfg.initialtive_max),
%     Slots1 = lists:map(fun({Slot, _Data} = SlotData) ->
%         ?if_else(lists:member(Slot, Max), {Slot, ?PET_SKILL_STATE_NOT_OPEN}, SlotData)
%     end, Slots0),
%     Open = lists:seq(1, QulityCfg#pet_quality_ratio_cfg.initialtive_open),
%     Slots2 = lists:map(fun({Slot, _Data} = SlotData) ->
%         ?if_else(lists:member(Slot, Open), {Slot, ?PET_SKILL_STATE_OPEN}, SlotData)
%     end, Slots1),
%     Slots2.

% init_passivity_skill(Quality) ->
%     Slots0 = [{Slot, ?PET_SKILL_STATE_VOID} || Slot <- lists:seq(1, ?PET_PASSIVITY_MAX_SLOT)],
%     QulityCfg = load_cfg_pet:lookup_pet_quality_ratio_cfg(Quality),
%     Max = lists:seq(1, QulityCfg#pet_quality_ratio_cfg.passivity_max),
%     Slots1 = lists:map(fun({Slot, _Data} = SlotData) ->
%         ?if_else(lists:member(Slot, Max), {Slot, ?PET_SKILL_STATE_NOT_OPEN}, SlotData)
%     end, Slots0),
%     Open = lists:seq(1, QulityCfg#pet_quality_ratio_cfg.passivity_open),
%     Slots2 = lists:map(fun({Slot, _Data} = SlotData) ->
%         ?if_else(lists:member(Slot, Open), {Slot, ?PET_SKILL_STATE_OPEN}, SlotData)
%     end, Slots1),
%     Slots2.

% add_pet_attr(Pet, AttrId) ->
%     Attr = attr_new:get_attr_by_id(AttrId),
%     NewAttr = attr:add(Attr, Pet#pet.attr),
%     Pet#pet{attr = NewAttr}.

% add_pet_exp_if_fight(Exp) ->
%     case get_cur_fight_pet() of
%         0 -> ok;
%         PetId ->
%             add_pet_exp(PetId, Exp, "FuBen")
%     end.

% add_pet_exp(PetID, Exp, From) ->
%     Pet = get_pet(PetID),
%     ?ifdo(is_record(Pet, pet), add_pet_exp_do(Pet, Exp, From)).

% add_pet_exp_do(Pet, Exp, From) ->
%     AddExp = fix_exp_addition(Exp, From),
%     NewPet = add_pet_exp_do2(Pet, AddExp),
%     update_pet(NewPet),

%     ?player_send(pet_sproto:pkg_msg(?MSG_PET_LIST, {?PET_LIST_WAY_CHANGE, [pet2pet_info(NewPet)]})).

% add_pet_exp_do2(Pet, AddExp) ->
%     AfterExp = Pet#pet.exp + AddExp,
%     case load_cfg_pet:lookup_pet_level_cfg({Pet#pet.cfgid, Pet#pet.level}) of
%         ?none ->
%             Pet;
%         PetLevel ->
%             case PetLevel#pet_level_cfg.need_exp =< AfterExp of
%                 ?true ->
%                     NewPet = upgrade_pet_level(Pet),
%                     add_pet_exp_do2(NewPet, AfterExp - PetLevel#pet_level_cfg.need_exp);
%                 ?false ->
%                     Pet#pet{exp = AfterExp}
%             end
%     end.


% fix_exp_addition(Exp, _From) ->
%     Exp.

% upgrade_pet_level(Pet) ->
%     NewLevel = Pet#pet.level + 1,
%     LevelCount = NewLevel div ?ADVANCE_LEVEL,
%     HaveAdvanceCount =
%         case LevelCount of
%             0 -> 0;
%             LevelCount ->
%                 QualityCFG = load_cfg_pet:lookup_pet_quality_ratio_cfg(Pet#pet.quality),
%                 MaxCount = QualityCFG#pet_quality_ratio_cfg.max_level,
%                 if
%                     Pet#pet.done_advance_count =:= MaxCount ->
%                         0;
%                     ((LevelCount - (Pet#pet.done_advance_count + Pet#pet.have_advance_count)) >= 1) and (LevelCount =< MaxCount) ->
%                         Pet#pet.have_advance_count + 1;
%                     (LevelCount - (Pet#pet.done_advance_count + Pet#pet.have_advance_count)) < 1 ->
%                         Pet#pet.have_advance_count;
%                     true -> Pet#pet.have_advance_count
%                 end
%         end,
%     NewPet = Pet#pet{have_advance_count = HaveAdvanceCount, level = NewLevel, exp = 0},

%     %OldPetLevel = lookup_pet_level_cfg({Pet#pet.cfgid, Pet#pet.level}),
%     NewPetLevel = load_cfg_pet:lookup_pet_level_cfg({NewPet#pet.cfgid, NewPet#pet.level}),
%     %NewPet1 = sub_pet_attr(NewPet, OldPetLevel#pet_level_cfg.attr),
%     NewPet2 = add_pet_attr(NewPet, NewPetLevel#pet_level_cfg.attr),

%     update_pet_attr_if_fight_status(NewPet2),
%     ?debug_log_pet("upgrade_pet_level ~p ~p", [Pet#pet.id, NewLevel]),
%     NewPet2.

% %% @doc宠物战斗状态下,宠物自身属性更改时,同时也要更新玩家身上(宠物的默契加成),及更新场景上的宠物属性
% update_pet_attr_if_fight_status(Pet) ->
%     case Pet#pet.status =:= ?PET_STATUS_FIGHT of
%         ?true ->
%             %update_pet_attr_to_player(Pet),
%             scene_mng:send_msg_pet({?msg_update_attr, get(?pd_idx), Pet#pet.attr}),
%             ok;
%         ?false ->
%             ignore
%     end.

% %%更新玩家身上的宠物属性, 1.获取上次添加的属性.2.总属性减去该属性.3.计算新增加的属性.4.添加入角色属性
% update_pet_attr_to_player(NewPet) ->
%     AddRatioAttr = attr:ratio(NewPet#pet.tacit_value / ?PET_MAX_TACIT_VALUE, NewPet#pet.attr),
%     case NewPet#pet.attr_old of
%         ?undefined ->
%             ok;
%         SubOneAttr ->
%             player:sub_attr_amend(SubOneAttr)
%     end,
%     NewAttr1 = AddRatioAttr#attr{move_speed = 0, run_speed = 0},
%     update_pet(NewPet#pet{attr_old = NewAttr1}),
%     player:add_attr_amend(NewAttr1).

% add_pet(Pet) ->
%     event_eng:post(?ev_pet_hatching, {?ev_pet_hatching, 0}, 1),
%     event_eng:post(?ev_pet_totle, {?ev_pet_totle, 0}, 1),
%     Pets = get(?pd_all_pets),
%     put(?pd_all_pets, [Pet | Pets]),
%     ?player_send(pet_sproto:pkg_msg(?MSG_PET_LIST, {?PET_LIST_WAY_ADD, [pet2pet_info(Pet)]})).

% del_pet(PetID) ->
%     event_eng:post(?ev_pet_totle, {?ev_pet_totle, 0}, -1),
%     Pets = get(?pd_all_pets),
%     NewPets = lists:keydelete(PetID, #pet.id, Pets),
%     put(?pd_all_pets, NewPets).

% get_pet(PetID) ->
%     Pets = get(?pd_all_pets),
%     lists:keyfind(PetID, #pet.id, Pets).

% update_pet(NewPet) ->
%     Pets = get(?pd_all_pets),
%     NewPets = lists:keyreplace(NewPet#pet.id, #pet.id, Pets, NewPet),
%     put(?pd_all_pets, NewPets).


% %% 玩家进入场景让宠物也进入场景
% pet_enter_scene(PlayerNamePkg, PlayerIdx, X, Y) ->
%     Pid = get(?pd_scene_pid),
%     case get(?pd_fight_pets) of
%         ?undefined ->
%             ok;
%         0 ->
%             ok;
%         FightPetId ->
%             Pid ! {mod, scene_pet, {?enter_scene_msg, PlayerNamePkg, PlayerIdx, X, Y, get_pet(FightPetId)}}
%     end.

% %% 玩家离开场景让宠物也离开场景
% pet_leave_scene(LeaveScenePid, PlayerIdx) ->
%     case get(?pd_fight_pets) of
%         ?undefined ->
%             ok;
%         0 ->
%             ok;
%         _FightPetId ->
%             LeaveScenePid ! {mod, scene_pet, {?leave_scene_msg, PlayerIdx}}
%     end.

% %% 玩家进程发送消息给场景进程的宠物模块
% pet_send_msg(Msg) ->
%     case get(?pd_fight_pets) of
%         ?undefined -> ok;
%         0 -> ok;
%         _PetId ->
%             case get(?pd_scene_pid) of
%                 Pid when is_pid(Pid) ->
%                     Pid ! ?scene_mod_msg(scene_pet, Msg);
%                 _ ->
%                     ?ERROR_LOG("player ~w can not send to scene pid ~w=======~w", [?pname(), get(?pd_scene_pid), Msg])
%             end
%     end.

% %%load_config_meta() ->
% %%    [
% %%        #config_meta{record = #pet_cfg{},
% %%            fields = ?record_fields(pet_cfg),
% %%            file = "pet.txt",
% %%            keypos = #pet_cfg.id,
% %%            verify = fun verify_pet_cfg/1
% %%        },
% %%        #config_meta{record = #pet_level_cfg{},
% %%            fields = ?record_fields(pet_level_cfg),
% %%            file = "pet_level.txt",
% %%            keypos = [#pet_level_cfg.id, #pet_level_cfg.level],
% %%            verify = fun verify_pet_level_cfg/1
% %%        },
% %%        #config_meta{record = #pet_quality_ratio_cfg{},
% %%            fields = ?record_fields(pet_quality_ratio_cfg),
% %%            file = "pet_quality_ratio.txt",
% %%            keypos = #pet_quality_ratio_cfg.quality,
% %%            verify = fun verify_pet_quality_cfg/1
% %%        },
% %%        #config_meta{record = #pet_advance_cfg{},
% %%            fields = ?record_fields(pet_advance_cfg),
% %%            file = "pet_advance.txt",
% %%            keypos = [#pet_advance_cfg.pet_id, #pet_advance_cfg.level],
% %%            verify = fun verify_pet_advance_cfg/1
% %%        },
% %%        #config_meta{record = #pet_advance_prop_cfg{},
% %%            fields = ?record_fields(pet_advance_prop_cfg),
% %%            file = "pet_advance_prop.txt",
% %%            keypos = #pet_advance_prop_cfg.diff_value,
% %%            verify = fun verify_pet_advance_pro_cfg/1},
% %%
% %%        #config_meta{record = #pet_skill_level_cfg{},
% %%            fields = ?record_fields(pet_skill_level_cfg),
% %%            file = "pet_skill_level.txt",
% %%            keypos = #pet_skill_level_cfg.id,
% %%            verify = fun verify_pet_skill_level_cfg/1
% %%        },
% %%        #config_meta{record = #pet_treasure_cfg{},
% %%            fields = ?record_fields(pet_treasure_cfg),
% %%            file = "pet_treasure.txt",
% %%            keypos = #pet_treasure_cfg.id,
% %%            groups = [#pet_treasure_cfg.type],
% %%            verify = fun verify_pet_treasure_cfg/1
% %%        },
% %%        #config_meta{record = #pet_skill_pos_open_cfg{},
% %%            fields = ?record_fields(pet_skill_pos_open_cfg),
% %%            file = "pet_skill_pos_open.txt",
% %%            keypos = [#pet_skill_pos_open_cfg.type, #pet_skill_pos_open_cfg.pos],
% %%            verify = fun verify_pet_skill_pos_open_cfg/1
% %%        }
% %%    ].

% load_db_table_meta() ->
%     [
%         #db_table_meta{
%             name = ?player_pet_tab,
%             fields = ?record_fields(player_pets),
%             shrink_size = 1,
%             flush_interval = 2
%         }
%     ].

% %% 玩家第一次登陆是调用
% create_mod_data(PlayerID) ->
%     dbcache:insert_new(?player_pet_tab, #player_pets{id = PlayerID, treasure_pets = [], fight_pet = 0, pets = []}).

% load_mod_data(PlayerId) ->
%     case dbcache:load_data(?player_pet_tab, PlayerId) of
%         [] ->
%             ?ERROR_LOG("player ~p can not player_pet_tab  mode", [PlayerId]),
%             create_mod_data(PlayerId),
%             load_mod_data(PlayerId);
%         [#player_pets{pets = Pets, treasure_log_pets = TreasurePetsLogs, treasure_pets = TreasurePets, fight_pet = Fights}] ->
%             ?pd_new(?pd_all_pets, Pets),
%             ?pd_new(?pd_pet_treasure, TreasurePets),
%             ?pd_new(?pd_fight_pets, Fights),
%             ?pd_new(?pd_pet_treasure_log, TreasurePetsLogs)

%     end.

% init_client() ->
%     recover_pet_treasures(),
%     handle_client(?MSG_PET_LIST, {}),
%     init_client_pet_treasure().

% init_client_pet_treasure() ->
%     Treasures = get(?pd_pet_treasure),
%     ?debug_log_pet("init_client_pet_treasure ~p", [length(Treasures)]),
%     Fun = fun(Treasure) ->
%         {Treasure#pet_treasure.id, Treasure#pet_treasure.treasureid, Treasure#pet_treasure.finishtime}
%     end,
%     ?player_send(pet_sproto:pkg_msg(?MSG_PET_TREASURE_LIST, {lists:map(Fun, Treasures)})).

% init_client_pet_treasure_log() ->
%     Gets = treasure_log_gets(),
%     ?debug_log_pet("init_client_pet_treasure_log ~p", [length(Gets)]),
%     ?player_send(pet_sproto:pkg_msg(?MSG_PET_TREASURE_LOG_LIST, {[pettreasurelog2info(Old) || Old <- Gets]})).

% view_data(Acc) ->
%     PetId = get(?pd_fight_pets),
%     <<Acc, PetId:32>>.

% %% 上线加上attr, 下线删除attr
% online() ->
%     case get(?pd_fight_pets) of
%         0 ->
%             ok;
%         PetId ->
%             case get_pet(PetId) of
%                 false ->
%                     ok;
%                 _Pet ->
%                     ok%% todo add sprite to player
%             end
%     end.



% offline(_SelfId) ->
%     case get(?pd_fight_pets) of
%         0 ->
%             ok;
%         PetId ->
%             case get_pet(PetId) of
%                 false ->
%                     ok;
%                 _Pet ->
%                     ok%% todo delete sprite to player
%             end
%     end.

% save_data(_SelfId) ->
%     PlayerPet =
%         #player_pets{id = _SelfId,
%             pets = get(?pd_all_pets),
%             fight_pet = get(?pd_fight_pets),
%             treasure_pets = get(?pd_pet_treasure),
%             treasure_log_pets = get(?pd_pet_treasure_log)},
%     dbcache:update(?player_pet_tab, PlayerPet),
%     ok.

% handle_msg(_, ?HMSG_TREASURE_FINISH(PetID, TreasureID)) ->
%     NOW = virtual_time:now(),
%     case treasure_get(PetID, TreasureID) of
%         ?false ->
%             ?debug_log_pet("treasure_finish not_exist ~p ~p", [PetID, TreasureID]);
%         #pet_treasure{finishtime = FinishTime} when FinishTime > NOW ->
%             ?debug_log_pet("treasure_finish not_timeout ~p ~p", [PetID, TreasureID]);
%         Treasure ->
%             ?debug_log_pet("treasure_finish ok ~p ~p", [PetID, TreasureID]),
%             ?debug_log_pet("treasure_finish ~p ~p", [Treasure#pet_treasure.id, Treasure#pet_treasure.treasureid]),
%             %% Add prize
%             PetTreasureCFG = load_cfg_pet:lookup_pet_treasure_cfg(Treasure#pet_treasure.treasureid),
%             PlayerPrizeId = PetTreasureCFG#pet_treasure_cfg.reward,

%             PrizeList = prize:get_prize_tuples(PlayerPrizeId),
%             PrizeInfo =
%                 case prize:prize(PlayerPrizeId) of
%                     {error, _} -> [];
%                     PrizeInfo_ -> PrizeInfo_
%                 end,

%             PrizeInfo1 = case lists:keyfind(?PL_PEARL, 1, PrizeList) of
%                              false -> PrizeInfo;
%                              {_, Exp} -> add_pet_exp(PetID, Exp, "HMSG_TREASURE_FINISH"),
%                                  [{?PL_PEARL, Exp} | PrizeInfo]
%                          end,
%             PrizeInfo2 = case lists:keyfind(?PL_PET_TACIT, 1, PrizeList) of
%                              false -> PrizeInfo1;
%                              {_, TacitValue} -> tacit_eval(PetID, TacitValue),
%                                  [{?PL_PET_TACIT, TacitValue} | PrizeInfo1]
%                          end,
%             treasure_log(Treasure, PrizeInfo2),
%             treasure_del(PetID, TreasureID),
%             Pet = get_pet(PetID),
%             event_eng:post(?ev_pet_treasure, {?ev_pet_treasure, 0}, 1),
%             ?player_send(pet_sproto:pkg_msg(?MSG_PUSH_PET_TREASURE_FINISH, {Pet#pet.level, Pet#pet.exp}))
%     end,
%     ok.

% handle_frame(_) -> ok.

% handle_client({Pack, Arg}) ->
%     case task_open_fun:is_open(?OPEN_PET) of
%         ?false -> ?return_err(?ERR_NOT_OPEN_FUN);
%         ?true -> handle_client(Pack, Arg)
%     end.

% %%宠物列表
% handle_client(?MSG_PET_LIST, {}) ->
%     Pets = get(?pd_all_pets),
%     ?player_send(pet_sproto:pkg_msg(?MSG_PET_LIST, {?PET_LIST_WAY_ALL, [pet2pet_info(Pet) || Pet <- Pets]}));

% handle_client(?MSG_PET_EGG_DATA, {PetId}) ->
%     Pet = pet_global_server:get_pet(PetId),
%     ?player_send(pet_sproto:pkg_msg(?MSG_PET_EGG_DATA, {pet2pet_info(Pet)}));

% %%封印宠物
% handle_client(?MSG_PET_SEAL, {PetID}) ->
%     case can_make_egg() of
%         {error, Error} ->
%             {error, Error};
%         _ ->
%             Pets = get(?pd_all_pets),
%             FightPets = get(?pd_fight_pets),
%             case lists:keymember(PetID, #pet.id, Pets) of
%                 ?true ->
%                     ?ifdo(FightPets =:= PetID, ?return_err(?ERR_PET_FIGHT_STATUS)),
%                     if
%                         FightPets =/= PetID ->
%                             #{tacit_cost:={_, _, TacitSEALNum}} = misc_cfg:get_misc_cfg(pet_info),
%                             tacit_eval(PetID, (-TacitSEALNum)),
%                             NewPets = get(?pd_all_pets),
%                             {Pet, RemainPets} = com_lists:extract_member(PetID, #pet.id, NewPets),
%                             PetCFG = load_cfg_pet:lookup_pet_cfg(Pet#pet.cfgid),
%                             put(?pd_all_pets, RemainPets),
%                             cost:cost(PetCFG#pet_cfg.seal_cost),
%                             pet_global_server:add_pet(Pet#pet{status = ?PET_STATUS_SEAL}),
%                             make_egg(Pet#pet.cfgid, Pet#pet.id),

%                             ?player_send(pet_sproto:pkg_msg(?MSG_PET_LIST, {?PET_LIST_WAY_CHANGE, [pet2pet_info(Pet#pet{status = ?PET_STATUS_SEAL})]})),
%                             ?player_send(pet_sproto:pkg_msg(?MSG_PET_SEAL, {}));
%                         true ->
%                             pass
%                     end;
%                 _ ->
%                     pass
%             end
%     end;

% %%学习技能
% handle_client(?MSG_PET_SKILL_STUDY, {PetID, SkillPos, SkillID}) ->
%     ?DEBUG_LOG("PetID--:~p---SKillPos--:~p---SkillId--:~p", [PetID, SkillPos, SkillID]),
%     case get_pet(PetID) of
%         ?false ->
%             ?DEBUG_LOG("pet false ----------------------"),
%             pass;
%         Pet ->
%             case load_cfg_pet:lookup_pet_skill_level_cfg(SkillID) of
%                 ?none ->
%                     ?DEBUG_LOG("pet false 2--------------------"),
%                     pass;
%                 SkillCfg ->
%                     SkillType = what_skill_type(SkillID),
%                     PositionState = get_skill_by_position(Pet, SkillType, SkillPos),
%                     if
%                         PositionState =/= ?PET_SKILL_STATE_VOID, PositionState =/= ?PET_SKILL_STATE_NOT_OPEN, PositionState =:= ?PET_SKILL_STATE_OPEN ->
%                             case is_exist_same_skill(Pet, SkillType, SkillID) of
%                                 ?false ->
%                                     case cost:cost(SkillCfg#pet_skill_level_cfg.study_cost) of
%                                         ok ->
%                                             NewPet = set_skill_position(Pet, SkillType, SkillPos, SkillID),
%                                             NewPets = lists:keyreplace(PetID, #pet.id, get(?pd_all_pets), NewPet),
%                                             put(?pd_all_pets, NewPets),
%                                             ?player_send(pet_sproto:pkg_msg(?MSG_PET_SKILL_STUDY, {PetID, SkillPos, SkillID}));
%                                         _ ->
%                                             ?DEBUG_LOG("pet false 3---------------------"),
%                                             pass
%                                     end;
%                                 _ ->
%                                     ?DEBUG_LOG("pet false 4---------------------"),
%                                     pass
%                             end;
%                         true ->
%                             ?DEBUG_LOG("pet false 5---------------------"),
%                             pass
%                     end
%             end
%     end;

% %%遗忘技能
% handle_client(?MSG_PET_SKILL_FORGET, {PetID, SkillID}) ->
%     case get_pet(PetID) of
%         ?false ->
%             pass;
%         Pet ->
%             if
%                 SkillID =/= ?PET_SKILL_STATE_VOID, SkillID =/= ?PET_SKILL_STATE_NOT_OPEN, SkillID =/= 0 ->
%                     Result = ?catch_return(find_skill(Pet, SkillID)),
%                     case Result of
%                         ?false ->
%                             pass;
%                         _ ->
%                             {SkillType, SkillPos} = Result,
%                             NewPet = set_skill_position(Pet, SkillType, SkillPos, ?PET_SKILL_STATE_OPEN),
%                             NewPets = lists:keyreplace(PetID, #pet.id, get(?pd_all_pets), NewPet),
%                             put(?pd_all_pets, NewPets),
%                             ?player_send(pet_sproto:pkg_msg(?MSG_PET_SKILL_FORGET, {PetID, SkillID}))
%                     end;
%                 true ->
%                     pass
%             end
%     end;

% %%升级技能
% handle_client(?MSG_PET_SKILL_UPLEVEL, {PetID, SkillID}) ->
%     case get_pet(PetID) of
%         ?false ->
%             pass;
%         Pet ->
%             Result = ?catch_return(find_skill(Pet, SkillID)),
%             case Result of
%                 ?false ->
%                     pass;
%                 {SkillType, SkillPos} ->
%                     PositionState = get_skill_by_position(Pet, SkillType, SkillPos),
%                     if
%                         PositionState =/= ?PET_SKILL_STATE_VOID, PositionState =/= ?PET_SKILL_STATE_NOT_OPEN, PositionState =:= ?PET_SKILL_STATE_OPEN ->
%                             case cost:cost(next_level_skill_cost(SkillID)) of
%                                 ok ->
%                                     NewSkill = next_level_skill(SkillID),
%                                     NewPet = set_skill_position(Pet, SkillType, SkillPos, NewSkill),
%                                     NewPets = lists:keyreplace(PetID, #pet.id, get(?pd_all_pets), NewPet),
%                                     event_eng:post(?ev_pet_skill_level, {?ev_pet_skill_level, 0}, 1),
%                                     put(?pd_all_pets, NewPets),
%                                     ?player_send(pet_sproto:pkg_msg(?MSG_PET_SKILL_UPLEVEL, {PetID, SkillPos, NewSkill}));
%                                 _ ->
%                                     pass
%                             end;
%                         true ->
%                             pass
%                     end
%             end
%     end;

% %%进阶宠物
% handle_client(?MSG_PET_ADVANCE, {PetID, Costs}) ->
%     ?DEBUG_LOG("PetID Costs---------------:~p", [{PetID, Costs}]),
%     case get_pet(PetID) of
%         ?false ->
%             ?DEBUG_LOG("pet advance false 1-----------------------"),
%             pass;%% is not PetId
%         Pet ->
%             if
%                 Pet#pet.have_advance_count > 0 ->
%                     ?DEBUG_LOG("pet advance false 2-----------------------"),
%                     QualityCFG = load_cfg_pet:lookup_pet_quality_ratio_cfg(Pet#pet.quality),
%                     CurrentAdvanceCount = Pet#pet.done_advance_count + 1,
%                     if
%                         QualityCFG#pet_quality_ratio_cfg.max_level > CurrentAdvanceCount ->
%                             ?DEBUG_LOG("pet advance false 4-----------------------:~p", [{QualityCFG#pet_quality_ratio_cfg.max_level, CurrentAdvanceCount}]),
%                             AdvanceCFG = load_cfg_pet:lookup_pet_advance_cfg({Pet#pet.cfgid, CurrentAdvanceCount}),
%                             #{item_prop:=ItemCFG} = misc_cfg:get_misc_cfg(pet_info),
%                             case check_advance_arg(AdvanceCFG, game_res:get_bucket(?BUCKET_TYPE_BAG), Costs, ItemCFG) of
%                                 ?true ->
%                                     ?DEBUG_LOG("pet advance false 6-----------------------"),
%                                     HaveAdvanceCount =
%                                         if
%                                             CurrentAdvanceCount =:= QualityCFG#pet_quality_ratio_cfg.max_level ->
%                                                 0;
%                                             true ->
%                                                 Pet#pet.have_advance_count - 1
%                                         end,
%                                     case advance_pet(Pet#pet{have_advance_count = HaveAdvanceCount, done_advance_count = CurrentAdvanceCount}, Costs, AdvanceCFG) of
%                                         {error, _Other} ->
%                                             pass;
%                                         NewPet ->
%                                             ?DEBUG_LOG("is advance ok ----------------------"),
%                                             update_pet(NewPet),
%                                             event_eng:post(?ev_pet_advance, {?ev_pet_advance, 0}, 1),
%                                             ?player_send(pet_sproto:pkg_msg(?MSG_PET_ADVANCE, {PetID})),
%                                             ?player_send(pet_sproto:pkg_msg(?MSG_PET_LIST, {?PET_LIST_WAY_CHANGE, [pet2pet_info(NewPet)]}))
%                                     end;
%                                 _ ->
%                                     ?DEBUG_LOG("pet advance false 7-----------------------"),
%                                     pass  %% is cost is enough
%                             end;
%                         true ->
%                             ?DEBUG_LOG("pet advance false 5-----------------------"),
%                             pass   %% is max advance count
%                     end;
%                 true ->
%                     ?DEBUG_LOG("pet advance false 3-----------------------"),
%                     pass %% count is enough
%             end
%     end;

% handle_client(?MSG_PET_TREASURE, {PetID, TreasureType}) ->
%     case is_exist_same_treasure(PetID, TreasureType) of
%         ?false ->
%             case get_pet(PetID) of
%                 ?false ->
%                     pass;
%                 Pet ->
%                     if
%                         Pet#pet.status =:= ?PET_STATUS_ALIVE ->
%                             TreasureID = random_treasure(TreasureType),
%                             case load_cfg_pet:lookup_pet_treasure_cfg(TreasureID) of
%                                 ?none ->
%                                     pass; %% is not cfg
%                                 TreasureCfg ->
%                                     case cost:cost(TreasureCfg#pet_treasure_cfg.cost) of
%                                         ok ->
%                                             treasure_start(Pet, TreasureCfg);
%                                         _ ->
%                                             pass%% is not cost enough
%                                     end
%                             end;
%                         true ->
%                             pass
%                     end
%             end;
%         _ ->
%             pass
%     end;

% handle_client(?MSG_PET_CANCEL_TREASURE, {PetID, TreasureID}) ->
%     case get_pet(PetID) of
%         ?false ->
%             pass;
%         Pet ->
%             FightPet = get(?pd_fight_pets),
%             if
%                 FightPet =/= PetID ->
%                     case lists:keymember(TreasureID, #pet_treasure.treasureid, (get(?pd_pet_treasure))) of
%                         ?true ->
%                             treasure_cancel(Pet, TreasureID);
%                         ?false ->
%                             pass
%                     end;
%                 true ->
%                     pass
%             end
%     end;
% handle_client(?MSG_PET_SKILL_POS_OPEN, {PetID, Type, Pos}) ->
%     case get_pet(PetID) of
%         ?false ->
%             pass;
%         Pet ->
%             FightPet = get(?pd_fight_pets),
%             if
%                 FightPet =/= PetID ->
%                     SkillState = get_skill_by_position(Pet, Type, Pos),
%                     if
%                         SkillState =/= ?PET_SKILL_STATE_VOID, SkillState < ?PET_SKILL_STATE_OPEN ->
%                             Cost = load_cfg_pet:lookup_pet_skill_pos_open_cfg({Type, Pos}, #pet_skill_pos_open_cfg.cost),
%                             case cost:cost(Cost) of
%                                 ok ->
%                                     NewPet = set_skill_position(Pet, Type, Pos, ?PET_SKILL_STATE_OPEN),
%                                     update_pet(NewPet),
%                                     ?player_send(pet_sproto:pkg_msg(?MSG_PET_SKILL_POS_OPEN, {PetID, Type, Pos}));
%                                 _ ->
%                                     pass
%                             end;
%                         true ->
%                             pass
%                     end;
%                 true ->
%                     pass
%             end
%     end;

% %% @doc 宠物出战，休战
% handle_client(?MSG_PET_STATE, {PetID}) ->
%     case get_pet(PetID) of
%         ?false ->
%             pass;
%         _Pet ->
%             FightPetID = get_cur_fight_pet(),
%             if
%                 PetID == FightPetID ->
%                     cancel_fight_pet(PetID);
%                 FightPetID > 0 ->
%                     cancel_fight_pet(FightPetID),
%                     fight_pet(PetID);
%                 true ->
%                     fight_pet(PetID)
%             end
%     end;
% handle_client(?MSG_PET_TREASURE_LOG_LIST, {}) ->
%     init_client_pet_treasure_log(),
%     ok.

% random_treasure(TreasureType) ->
%     case load_cfg_pet:lookup_group_pet_treasure_cfg(#pet_treasure_cfg.type, TreasureType) of
%         ?none -> ?return_err(?ERR_NOT_EXIST_CFG);
%         IDS ->
%             {WeightMax, WeightList} = lists:foldl(fun(ID, {WeightSum, List}) ->
%                 Weight = load_cfg_pet:lookup_pet_treasure_cfg(ID, #pet_treasure_cfg.weight),
%                 {WeightSum + Weight, [{ID, WeightSum + Weight} | List]} end, {0, []}, IDS),
%             WeightSelected = com_util:random(1, WeightMax),
%             WeightListReverse = lists:reverse(WeightList),
%             {SelectID, _} = com_lists:break(fun({_ID1, Weight1} = IW) ->
%                 case Weight1 >= WeightSelected of
%                     ?true -> {continue, IW};
%                     ?false -> break
%                 end
%             end, hd(WeightListReverse), WeightListReverse),
%             SelectID
%     end.
% %%
% get_cur_fight_pet() ->
%     get(?pd_fight_pets).

% set_cur_fight_pet(PetID) ->
%     put(?pd_fight_pets, PetID).

% cancel_fight_pet(PetID) ->
%     pet_leave_scene(get(?pd_scene_pid), get(?pd_idx)),
%     set_cur_fight_pet(0),
%     Pet = get_pet(PetID),
%     NewPet = Pet#pet{status = ?PET_STATUS_ALIVE},
%     RatioAttr = NewPet#pet.attr_old,
%     player:sub_attr_amend(RatioAttr),
%     update_pet(NewPet#pet{attr_old = ?undefined}),
%     %% OK 把宠物的属性加成到玩家身上的删掉
%     ?player_send(pet_sproto:pkg_msg(?MSG_PET_STATE, {NewPet#pet.id, NewPet#pet.status})).

% fight_pet(PetID) ->
%     set_cur_fight_pet(PetID),
%     Pet = get_pet(PetID),
%     NewPet = Pet#pet{status = ?PET_STATUS_FIGHT},
%     %% OK 把宠物的属性加成到玩家身上的加上
%     update_pet_attr_to_player(NewPet),
%     pet_enter_scene(get(?pd_name_pkg), get(?pd_idx), get(?pd_x), get(?pd_y)),
%     ?player_send(pet_sproto:pkg_msg(?MSG_PET_STATE, {NewPet#pet.id, NewPet#pet.status})).

% %% 验证进阶消耗的道具和宠物
% check_advance_arg(AdvanceCFG, BagBucket, ItemList, ItemCFG) ->
%     AssetList = cost:get_cost(AdvanceCFG#pet_advance_cfg.cost),
%     FunAll = fun({?PL_MONEY, Num}) ->
%         Num =< get(?pd_money);
%         ({?PL_DIAMOND, Num}) ->
%             Num =< get(?pd_diamond)
%     end,
%     case lists:all(FunAll, AssetList) of
%         ?true ->
%             Len = length(ItemList),
%             case Len >= AdvanceCFG#pet_advance_cfg.mini_slots of
%                 ?true ->
%                     check_advance(BagBucket, ItemList, ItemCFG);
%                 ?false ->
%                     ?false
%             end;
%         ?false ->
%             ?false
%     end.

% check_advance(_BagBucket, [], _ItemCFG) ->
%     ?false;
% check_advance(BagBucket, [{?COST_TYPE_PET, PetId} | RList], ItemCFG) ->
%     case get_pet(PetId) of
%         ?false ->
%             check_advance(BagBucket, RList, ItemCFG);
%         _ ->
%             ?true
%     end;

% check_advance(BagBucket, [{?COST_TYPE_ITEM, ItemId} | _RList] = L, ItemCFG) ->
%     case lists:keyfind(ItemId, 1, ItemCFG) of
%         ?false ->
%             ?false;
%         _ ->
%             case goods_bucket:find_goods(BagBucket, by_bid, {ItemId}) of
%                 {error, _Error} ->
%                     ?false;
%                 [] ->
%                     ?false;
%                 ItemList ->
%                     Count = ItemList#item_new.quantity,
%                     if
%                         Count >= length(L) ->
%                             ?true;
%                         ?true ->
%                             ?false
%                     end
%             end
%     end.

% %% 进阶宠物
% advance_pet(Pet, Costs, AdvanceCFG) ->
%     BasicAttr = attr_new:get_attr_by_id(AdvanceCFG#pet_advance_cfg.attr_basic_add),
%     RandomExtra = count_advance_rand(Costs, Pet),
%     Random1 = ?random(?DEFAULT_PERCENT_MIN_AND_MAX),
%     NewPet1 =
%         if
%             RandomExtra > Random1 ->
%                 ExtraAttrAdvanceCFG = load_cfg_pet:lookup_pet_advance_cfg({Pet#pet.cfgid, Pet#pet.advance_seccuss_count + 1}),
%                 AttrSats = random_attr___(ExtraAttrAdvanceCFG#pet_advance_cfg.min_num, ExtraAttrAdvanceCFG#pet_advance_cfg.max_num,
%                     ExtraAttrAdvanceCFG#pet_advance_cfg.attr_prize),
%                 ExtraAttr = attr:add_by_sats(AttrSats, attr:new()),
%                 AllAttr = attr:add(BasicAttr, ExtraAttr),

%                 {_NIndex, FacePerList} = com_util:probo_range_build([{FaceId, Per} || {Per, FaceId} <- AdvanceCFG#pet_advance_cfg.facade_prize]),
%                 [{FaceId, _}] = com_util:random_more({1, 1}, FacePerList),
%                 NewPet =
%                     case Pet#pet.facade of
%                         FaceId ->
%                             Pet#pet{attr = attr:add(AllAttr, Pet#pet.attr)};
%                         _ ->
%                             Pet#pet{facade = FaceId, attr = attr:add(AllAttr, Pet#pet.attr)}
%                     end,
%                 NewPet#pet{advance_seccuss_count = Pet#pet.advance_seccuss_count + 1};
%             ?true ->
%                 Pet#pet{attr = attr:add(BasicAttr, Pet#pet.attr)}
%         end,

%     cost:cost(AdvanceCFG#pet_advance_cfg.cost),
%     costs(Costs),
%     NewPet2 = NewPet1#pet{tacit_value = NewPet1#pet.tacit_value + AdvanceCFG#pet_advance_cfg.tacit_value_add},
%     update_pet_attr_if_fight_status(NewPet2),
%     NewPet2.

% %% 计算进阶添加的属性概率
% count_advance_rand(Costs, Pet) ->
%     Fun =
%         fun({?COST_TYPE_PET, PetId}, Random) ->%%宠物
%             CostPet = get_pet(PetId),
%             AdvanceProCFG = load_cfg_pet:lookup_pet_advance_prop_cfg(CostPet#pet.quality - Pet#pet.quality),
%             Random + AdvanceProCFG#pet_advance_prop_cfg.per;
%             ({?COST_TYPE_ITEM, ItemId}, Random) ->%%物品
%                 #{item_prop:=ItemList} = misc_cfg:get_misc_cfg(pet_info),%% :=是键值分隔符
%                 case lists:keyfind(ItemId, 1, ItemList) of
%                     ?false ->
%                         Random;
%                     {ItemId, ItemR} ->
%                         ItemR + Random
%                 end

%         end,
%     lists:foldl(Fun, 0, Costs).

% costs([{?COST_TYPE_PET, PetID} | Costs]) ->
%     Pet = get_pet(PetID),
%     del_pet(PetID),
%     ?player_send(pet_sproto:pkg_msg(?MSG_PET_LIST, {?PET_LIST_WAY_DEL, [pet2pet_info(Pet)]})),
%     costs(Costs);

% costs([{?COST_TYPE_ITEM, ItemID} | Costs]) ->
%     game_res:try_del([{ItemID, 1}]),
%     costs(Costs);

% costs(_) ->
%     ok.

% is_exist_same_treasure(PetID, TreasureType) ->
%     Treasures = treasure_gets(PetID),
%     com_lists:break(fun(Treasure) ->
%         ExistType = load_cfg_pet:lookup_pet_treasure_cfg(Treasure#pet_treasure.treasureid, #pet_treasure_cfg.type),
%         case ExistType =:= TreasureType of
%             ?false -> continue;
%             ?true -> {break, ?true}
%         end
%     end, ?false, Treasures).

% treasure_start(Pet, TreasureCfg) ->
%     Now = virtual_time:now(),
%     FinishTime = Now + TreasureCfg#pet_treasure_cfg.need_time,
%     Treasure =
%         #pet_treasure{id = Pet#pet.id,
%             treasureid = TreasureCfg#pet_treasure_cfg.id,
%             createtime = Now,
%             finishtime = FinishTime
%         },
%     NewTreasure = start_treasure_timer(Treasure, Now),
%     treasure_add(NewTreasure),
%     ?player_send(pet_sproto:pkg_msg(?MSG_PET_TREASURE, {Pet#pet.id, TreasureCfg#pet_treasure_cfg.id, FinishTime})),
%     ok.

% treasure_cancel(Pet, TreasureID) ->
%     case treasure_get(Pet#pet.id, TreasureID) of
%         ?false ->
%             ?return_err(?ERR_PET_NOT_TREASURE);
%         Treasure ->
%             %%消取定时器
%             erlang:cancel_timer(Treasure#pet_treasure.timer_ref),
%             treasure_del(Pet#pet.id, TreasureID),
%             ?player_send(pet_sproto:pkg_msg(?MSG_PET_CANCEL_TREASURE, {Pet#pet.id, TreasureID}))
%     end.

% treasure_add(Treasure) ->
%     Treasures = get(?pd_pet_treasure),
%     put(?pd_pet_treasure, [Treasure | Treasures]).

% treasure_del(PetID, TreasureID) ->
%     Treasures = get(?pd_pet_treasure),
%     RemainTreasures = lists:filter(fun(Treasure) ->
%         not (Treasure#pet_treasure.id =:= PetID andalso Treasure#pet_treasure.treasureid =:= TreasureID)
%     end, Treasures),
%     put(?pd_pet_treasure, RemainTreasures).

% %% @doc -> ?false | #pet_treasure{}
% treasure_get(PetID, TreasureID) ->
%     Treasures = get(?pd_pet_treasure),
%     com_lists:break(fun(Treasure) ->
%         case Treasure#pet_treasure.id =:= PetID andalso Treasure#pet_treasure.treasureid =:= TreasureID of
%             ?false -> continue;
%             ?true -> {break, Treasure}
%         end end, ?false, Treasures).

% %% @doc -> [#pet_treasure{}]
% treasure_gets(PetID) ->
%     Treasures = get(?pd_pet_treasure),
%     com_lists:break_foldl(fun(Treasure, OKTreasures) ->
%         case Treasure#pet_treasure.id =:= PetID of
%             ?false -> continue;
%             ?true -> {break, [Treasure | OKTreasures]}
%         end end, [], Treasures).

% %% @doc 记录宠物活动日志
% treasure_log(Treasure, PrizeInfo) ->
%     Pet = get_pet(Treasure#pet_treasure.id),

%     Log = #pet_treasure_log{name = Pet#pet.name,
%         prize_info = PrizeInfo,
%         treasureid = Treasure#pet_treasure.treasureid,
%         finishtime = Treasure#pet_treasure.finishtime},

%     %% add new log
%     OldPetLog = get(?pd_pet_treasure_log),
%     RObject = if
%                   length(OldPetLog) =:= 99 -> lists:reverse(tl(lists:keysort(#pet_treasure_log.createtime, OldPetLog)));
%                   true -> OldPetLog
%               end,

%     put(?pd_pet_treasure_log, [Log | RObject]),
%     ok.


% treasure_log_gets() ->
%     get(?pd_pet_treasure_log).


% %% @doc 玩家死亡，减少出战宠物的默契度
% player_die() ->
%     PetId = get_cur_fight_pet(),
%     case get_pet(PetId) of
%         false -> ok;
%         Pet ->
%             if
%                 Pet#pet.status =:= ?PET_STATUS_FIGHT ->
%                     #{tacit_cost:={_, PlayerDieTacitNum, _}} = misc_cfg:get_misc_cfg(pet_info),
%                     tacit_eval(PetId, -PlayerDieTacitNum);
%                 true ->
%                     ok
%             end
%     end.

% main_instacne_complete() ->
%     PetId = get_cur_fight_pet(),
%     case get_pet(PetId) of
%         false -> ok;
%         Pet ->
%             if
%                 Pet#pet.status =:= ?PET_STATUS_FIGHT ->
%                     #{tacit_cost:={TacitNum, _, _}} = misc_cfg:get_misc_cfg(pet_info),
%                     tacit_eval(PetId, TacitNum);
%                 true ->
%                     ok
%             end
%     end.

% tacit_eval(PetId, TacitValue) ->
%     case get_pet(PetId) of
%         false -> ok;
%         PetTab ->
%             NewTacitValue = PetTab#pet.tacit_value + TacitValue,
%             #{tacit_value:={TacitMin, TacitMax}} = misc_cfg:get_misc_cfg(pet_info),
%             ResultTacitValue = if
%                                    NewTacitValue =< TacitMin -> TacitMin;
%                                    NewTacitValue >= TacitMax -> TacitMax;
%                                    true -> NewTacitValue
%                                end,
%             NewPet = PetTab#pet{tacit_value = ResultTacitValue},
%             update_pet(NewPet),
%             update_pet_attr_if_fight_status(NewPet)
%     end.

% %% 恢复寻宝数据真实性(离线时间已寻到宝的会处理)
% recover_pet_treasures() ->
%     Now = virtual_time:now(),
%     Fun = fun(Treasure) when Treasure#pet_treasure.finishtime =< Now ->
%         self() ! ?mod_msg(?MODULE, ?HMSG_TREASURE_FINISH(Treasure#pet_treasure.id, Treasure#pet_treasure.treasureid)),
%         ?true;
%         (Treasure) ->
%             {?true, start_treasure_timer(Treasure, Now)}
%     end,
%     NewPetTreasures = lists:filtermap(Fun, get(?pd_pet_treasure)),
%     put(?pd_pet_treasure, NewPetTreasures),
%     ok.

% start_treasure_timer(Treasure, Now) ->
%     TimerRef = erlang:send_after((Treasure#pet_treasure.finishtime - Now) * 1000,
%         self(),
%         ?mod_msg(?MODULE, ?HMSG_TREASURE_FINISH(Treasure#pet_treasure.id, Treasure#pet_treasure.treasureid))),
%     Treasure#pet_treasure{timer_ref = TimerRef}.

% pet2pet_info(Pet) ->
%     {Pet#pet.id,
%         Pet#pet.cfgid,
%         (Pet#pet.name),
%         Pet#pet.level,
%         Pet#pet.exp,
%         Pet#pet.tacit_value,
%         Pet#pet.status,
%         Pet#pet.quality,
%         Pet#pet.facade,
%         Pet#pet.done_advance_count,
%         Pet#pet.exclusive_skill,
%         initiactive_skill_info(Pet#pet.initiative_skill),
%         passivity_skill_info(Pet#pet.passivity_skill),
%         ?r2t(player_base_data:change_old_attr(Pet#pet.attr)),
%         attr:get_combat_power(attr:amend(Pet#pet.attr))}.

% pettreasurelog2info(#pet_treasure_log{name = Name,
%     prize_info = PrizeInfo,
%     treasureid = TreasureID,
%     finishtime = FinishTime
% }) ->
%     {Name, TreasureID, PrizeInfo, FinishTime}.

% initiactive_skill_info(InitiactiveSkill) ->
%     list_to_tuple(lists:map(fun({_, ID}) -> ID end, InitiactiveSkill)).

% passivity_skill_info(PassivitySkill) ->
%     list_to_tuple(lists:map(fun({_, ID}) -> ID end, PassivitySkill)).

% set_skill_position(Pet, ?PET_SKILL_TYPE_EXCLUSIVE, _Pos, Skill) ->
%     Pet#pet{exclusive_skill = Skill};

% set_skill_position(Pet, Type, Pos, Skill) ->
%     case Type of
%         ?PET_SKILL_TYPE_INITIATIVE ->
%             Initiative = Pet#pet.initiative_skill,
%             NewInitiative = lists:keyreplace(Pos, 1, Initiative, {Pos, Skill}),
%             Pet#pet{initiative_skill = NewInitiative};

%         ?PET_SKILL_TYPE_PASSIVITY ->
%             Passivity = Pet#pet.passivity_skill,
%             NewInitiative = lists:keyreplace(Pos, 1, Passivity, {Pos, Skill}),
%             Pet#pet{passivity_skill = NewInitiative}
%     end.

% find_skill(Pet, SkillID) ->
%     ?ifdo(Pet#pet.exclusive_skill =:= SkillID,
%         ?return({?PET_SKILL_TYPE_EXCLUSIVE, 0})),
%     ?ifdo(lists:keymember(SkillID, 2, Pet#pet.initiative_skill),
%         ?return({?PET_SKILL_TYPE_INITIATIVE, com_lists:match_value(SkillID, 2, Pet#pet.initiative_skill, 1)})),
%     ?ifdo(lists:keymember(SkillID, 2, Pet#pet.passivity_skill),
%         ?return({?PET_SKILL_TYPE_PASSIVITY, com_lists:match_value(SkillID, 2, Pet#pet.passivity_skill, 1)})),
%     ?return(false).

% get_skill_by_position(Pet, ?PET_SKILL_TYPE_EXCLUSIVE, _Pos) ->
%     Pet#pet.exclusive_skill;
% get_skill_by_position(Pet, Type, Pos) ->
%     SkillList =
%         case Type of
%             ?PET_SKILL_TYPE_INITIATIVE ->
%                 Pet#pet.initiative_skill;
%             ?PET_SKILL_TYPE_PASSIVITY ->
%                 Pet#pet.passivity_skill
%         end,
%     proplists:get_value(Pos, SkillList).

% get_skills_by_type(_Pet, ?PET_SKILL_TYPE_EXCLUSIVE) ->
%     [];
% get_skills_by_type(Pet, ?PET_SKILL_TYPE_INITIATIVE) ->
%     Pet#pet.initiative_skill;
% get_skills_by_type(Pet, ?PET_SKILL_TYPE_PASSIVITY) ->
%     Pet#pet.passivity_skill.

% %%技能是什么类型(主动/被动)
% what_skill_type(SkillID) ->
%     case load_cfg_pet:lookup_pet_skill_level_cfg(SkillID, #pet_skill_level_cfg.type) of
%         ?none_cfg ->
%             ?return_err(?ERR_NOT_EXIST_CFG);
%         Type -> Type
%     end.

% is_exist_same_skill(Pet, SkillType, SkillID) ->
%     Fun = fun({_, ExistID}) when ExistID > 0 ->
%         case skill_prototype(ExistID) == SkillID of
%             ?true -> {break, ?true};
%             ?false -> continue
%         end;
%         ({_, _}) -> continue
%     end,
%     com_lists:break(Fun, ?false, get_skills_by_type(Pet, SkillType)).

% skill_prototype(SkillID) ->
%     case load_cfg_pet:lookup_pet_skill_level_cfg(SkillID, #pet_skill_level_cfg.level) of
%         ?none_cfg ->
%             ?return_err(?ERR_NOT_EXIST_CFG);
%         Level ->
%             SkillID - Level + 1
%     end.

% %%技能升级后的技能
% next_level_skill(SkillID) ->
%     case load_cfg_pet:lookup_pet_skill_level_cfg(SkillID, #pet_skill_level_cfg.next_id) of
%         0 -> ?return_err(?ERR_NOT_EXIST_CFG);
%         ?none_cfg -> ?return_err(?ERR_NOT_EXIST_CFG);
%         NextID -> NextID
%     end.

% next_level_skill_cost(SkillID) ->
%     case load_cfg_pet:lookup_pet_skill_level_cfg(SkillID, #pet_skill_level_cfg.uplevel_cost) of
%         0 -> ?return_err(?ERR_NOT_EXIST_CFG);
%         ?none_cfg ->
%             ?return_err(?ERR_NOT_EXIST_CFG);
%         UpLevelCost -> UpLevelCost
%     end.

% can_make_egg() ->
%     BagBucket = game_res:get_bucket(?BUCKET_TYPE_BAG),
%     Size = goods_bucket:get_empty_size(BagBucket),
%     if
%         Size > 0 -> ret:ok();
%         true -> ret:error(no_size)
%     end.
% make_egg(PetCfg, PetID) ->
%     ItemBid = load_cfg_pet:find_egg_itembid(PetCfg),
%     NewItem = entity_factory:build(ItemBid, 1, [{?item_ex_pet_attr_key_petid, PetID}]),
%     game_res:set_res_reasion(<<"宠物蛋">>),
%     game_res:try_give([{NewItem}]).

% %%verify_pet_cfg(PetCfg) ->
% %%    ?check(length(PetCfg#pet_cfg.facade) > 0, "pet ~p not default facade", [PetCfg#pet_cfg.id]),
% %%    ?check(cost:is_exist_cost_cfg(PetCfg#pet_cfg.hatch_cost), "pet ~p hatch_cost error", [PetCfg#pet_cfg.id, PetCfg#pet_cfg.hatch_cost]),
% %%    ?check(cost:is_exist_cost_cfg(PetCfg#pet_cfg.seal_cost), "pet ~p seal_cost error", [PetCfg#pet_cfg.id, PetCfg#pet_cfg.seal_cost]),
% %%    ok.
% %%
% %%verify_pet_level_cfg(PetLevelCfg) ->
% %%    ?check(load_spirit_attr:is_exist_attr(PetLevelCfg#pet_level_cfg.attr), "pet_level_cfg id ~p attr ~p not exist in attr table",
% %%        [PetLevelCfg#pet_level_cfg.id, PetLevelCfg#pet_level_cfg.attr]),
% %%    ok.
% %%
% %%verify_pet_quality_cfg(_QualityCfg) ->
% %%    ok.
% %%
% %%verify_pet_advance_cfg(AdvanceCfg) ->
% %%    ?check(cost:is_exist_cost_cfg(AdvanceCfg#pet_advance_cfg.cost), "pet_advance_cfg id ~p cost ~p not exist in cost table",
% %%        [AdvanceCfg#pet_advance_cfg.id, AdvanceCfg#pet_advance_cfg.cost]),
% %%    ?check(load_spirit_attr:is_exist_attr(AdvanceCfg#pet_advance_cfg.attr_basic_add), "pet_advance_cfg id ~p attr ~p not exist in attr table",
% %%        [AdvanceCfg#pet_advance_cfg.id, AdvanceCfg#pet_advance_cfg.attr_basic_add]),
% %%
% %%    ok.
% %%
% %%verify_pet_advance_pro_cfg(#pet_advance_prop_cfg{diff_value = Diff, per = Per}) ->
% %%    ?check(is_integer(Diff), "pet_advance_prop.txt id ~p  diff_value error", [Diff]),
% %%    ?check((Per >= 0) andalso (Per =< 100), "pet_advance_prop.txt id ~p per error", [Diff]),
% %%    ok.
% %%
% %%verify_pet_skill_level_cfg(PetSkillSlot) ->
% %%%% 	study_cost, uplevel_cost, forget_cost
% %%    ?check(cost:is_exist_cost_cfg(PetSkillSlot#pet_skill_level_cfg.study_cost), "pet_skill_level_cfg id ~p study ~p not exist in attr table",
% %%        [PetSkillSlot#pet_skill_level_cfg.id, PetSkillSlot#pet_skill_level_cfg.study_cost]),
% %%    ?check(cost:is_exist_cost_cfg(PetSkillSlot#pet_skill_level_cfg.uplevel_cost), "pet_skill_level_cfg id ~p upgrade ~p not exist in table",
% %%        [PetSkillSlot#pet_skill_level_cfg.id, PetSkillSlot#pet_skill_level_cfg.uplevel_cost]),
% %%    ?check(cost:is_exist_cost_cfg(PetSkillSlot#pet_skill_level_cfg.forget_cost), "pet_skill_level_cfg id ~p forget ~p not exist in attr table",
% %%        [PetSkillSlot#pet_skill_level_cfg.id, PetSkillSlot#pet_skill_level_cfg.forget_cost]),
% %%    ok.
% %%
% %%verify_pet_treasure_cfg(PetTreasureCfg) ->
% %%    ?check(cost:is_exist_cost_cfg(PetTreasureCfg#pet_treasure_cfg.cost), "pet_treasure_cfg id ~p cost ~p not exist cost table",
% %%        [PetTreasureCfg#pet_treasure_cfg.id, PetTreasureCfg#pet_treasure_cfg.cost]),
% %%    ok.
% %%
% %%verify_pet_skill_pos_open_cfg(PetSkillPosOpen) ->
% %%    ?check(cost:is_exist_cost_cfg(PetSkillPosOpen#pet_skill_pos_open_cfg.cost), "pet_skill_pos_open_cfg id ~p cost ~p not exist cost table",
% %%        [PetSkillPosOpen#pet_skill_pos_open_cfg.id, PetSkillPosOpen#pet_skill_pos_open_cfg.cost]),
% %%    ok.
% %%
% %%
% %%find_egg_itembid(PetCfgId) ->
% %%    ItemCidS = load_item:lookup_group_item_attr_cfg(#item_attr_cfg.type, 6),
% %%    com_lists:break(fun(ItemCid) ->
% %%        case lists:keymember(PetCfgId, 2, load_item:lookup_item_attr_cfg(ItemCid, #item_attr_cfg.use_effect)) of
% %%            ?true -> {break, ItemCid};
% %%            ?false -> continue
% %%        end
% %%    end, ?false, ItemCidS).
