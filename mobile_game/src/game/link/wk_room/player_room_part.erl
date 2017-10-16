%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 07. 四月 2016 下午5:11
%%%-------------------------------------------------------------------
-module(player_room_part).
-author("clark").

%% API
-export
([
    is_enter_action/0,
    is_in_room/0,
    begin_enter_room_by_client/1,
    end_enter_room_by_client/0,
    leave_scene/0,
    handle_msg/2
]).


-include("player.hrl").
-include("scene.hrl").
-include("room_system.hrl").
-include("scene_agent.hrl").
-include("achievement.hrl").
-include("load_cfg_main_ins.hrl").
-include("load_phase_ac.hrl").
-include("main_ins_struct.hrl").
-include("load_cfg_card.hrl").
-include("team.hrl").
-include("system_log.hrl").
-include("../wk_open_server_happy/open_server_happy.hrl").

-define(pd_is_enter_action, '@pd_is_enter_room_action@').
-define(pd_is_in_room_ex, '@pd_pd_is_in_room_ex@').
-define(pd_player_is_ob, pd_player_is_ob).


is_enter_action() ->
    case util:get_pd_field(?pd_is_enter_action, 0) of
        1 -> true;
        0 -> false
    end.


is_in_room() ->
    case util:get_pd_field(?pd_is_in_room_ex, 0) of
        1 -> true;
        0 -> false
    end.

get_agent_type() ->
    %?DEBUG_LOG("IS OB---------------------------------------:~p",[get(?pd_player_is_ob)]),
    case get(?pd_player_is_ob) of
        2 ->
            ?agent_ob;
        _ ->
            ?agent_player
    end.


%% 10011, 4, 16, 3
begin_enter_room_by_client({RoomPid, RoomCfgId, Ob, X, Y, Dir}) ->
    util:set_pd_field(?pd_is_enter_action, 1),
    util:set_pd_field(?pd_entering_scene, {RoomPid, RoomCfgId, X, Y, Dir}),
    %?DEBUG_LOG("Ob----------------------------:~p",[Ob]),
    util:set_pd_field(?pd_player_is_ob, Ob),
    % ?INFO_LOG("player_send MSG_SCENE_PLAYER_ENTER_REQUEST ~p", [{RoomPid, RoomCfgId, X, Y, Dir}]),
    ?player_send(scene_sproto:pkg_msg(?MSG_SCENE_PLAYER_ENTER_REQUEST, {RoomCfgId, X, Y, Dir, 1})),
    ok.


end_enter_room_by_client() ->
    CurrentPid = get(?pd_scene_pid),
    util:set_pd_field(?pd_is_enter_action, 0),
    case util:get_pd_field(?pd_entering_scene, nil) of
        nil ->
            ?ERROR_LOG("no_begin_enter");
        {CurrentPid, _RoomCfgId, _X, _Y, _Dir} ->
            ?ERROR_LOG("alreay enter");
        {RoomPid, RoomCfgId, ToX, ToY, Dir} ->
            erase(?pd_entering_scene),
            %% 申请进入房间
            {Hp, Mp, Anger} = case team_server:get_team_info(get(?pd_id), ?TEAM_TYPE_MAIN_INS) of
                {ok, TeamInfo} ->
                    SceneIdList = TeamInfo#team_info.scene_id_list,
                    case length(SceneIdList) > 1 of
                        true ->
                            {get(?pd_hp), get(?pd_mp), get(?pd_crown_anger)};
                        _ ->
                            {attr_new:get_attr_item(?pd_attr_max_hp), attr_new:get_attr_item(?pd_attr_max_mp), 0}
                    end;
                _ ->
                    {attr_new:get_attr_item(?pd_attr_max_hp), attr_new:get_attr_item(?pd_attr_max_mp), 0}
            end,
            Attr = attr_new:get_oldversion_attr(),
            ShapeData = player:pack_view_data(),
            EquShapeData = equip_system:get_equip_fast_efts(),
            SSData = attr_new:get(?pd_shapeshift_data, 0),
            NLimit = attr_new:get(?pd_is_near_player_count_set, 0),
            AgentType = get_agent_type(),
            % ?DEBUG_LOG("AgentType---------------------------:~p",[AgentType]),
            SkillModifies = skill_modify_util:load_longwen_skill_modifies(),
            case gen_server:call
            (
                RoomPid,
                #enter_room_args
                {
                    x = ToX,                      %% 坐标
                    y = ToY,                      %% 坐标
                    dir = Dir,                      %% 方向
                    player_id = get(?pd_id),              %% 玩家ID
                    type = AgentType,
                    machine_screen_w = util:get_pd_field(?pd_vx, 30), %3 断线重连时, 这时会出现undefine, 待查,
                    machine_screen_h = util:get_pd_field(?pd_vy, 20), %3 断线重连时, 这时会出现undefine, 待查
                    hp = Hp,                    %% HP
                    mp = Mp,                    %% MP
                    anger = Anger,
                    attr = Attr,                     %% 属性
                    lvl = get(?pd_level),           %% 等级
                    shape_data = ShapeData,                %% 外形数据
                    equip_shape_data = EquShapeData,             %% 装备外形数据
                    shapeshift_data = SSData,                   %% 外形数据
                    ride_data = 0,                  %% 坐骑数据
                    near_limit = NLimit,                    %% 周边限制人数
                    skill_modify = SkillModifies,
                    from_pid = self()
                }
            )
            of
                {ok, Agent, {EnterX, EnterY}} ->
                    %% 离开当前场景(使用scene_mng以兼容其它类型)
                    scene_mng:leave_scene(),
                    %% 进入新场景
                    % save_normal_pos(),
                    put(?pd_scene_id, RoomCfgId),
                    put(?pd_scene_pid, RoomPid),
                    put(?pd_idx, Agent#agent.idx),
                    put(?pd_x, EnterX),
                    put(?pd_y, EnterY),
                    put(?pd_is_in_room_ex, 1),
                    pet_new_mng:pet_new_enter_scene(1, get(?pd_name_pkg), Agent#agent.idx, EnterX, EnterY),
                    ?player_send(scene_sproto:pkg_msg(?MSG_SCENE_PLAYER_ENTER, {Agent#agent.idx, 1})),
                    enter_scene_ok(Agent, SSData),
                    main_ins_util:ins_cost_times(RoomCfgId),
                    ok;
                _E ->
                    ?ERROR_LOG("player ~p enter scene ~p unmatch ~p", [?pname(), {RoomCfgId, get(?pd_x), get(?pd_y)}, _E])
            end
    end,
    ok.


leave_scene() ->
    put(?pd_attr_add_hp_mp_cd, 0),
    case util:get_pd_field(?pd_scene_pid, ?undefined) of
        ?undefined ->
            pass;
        RoomPid ->
            Idx = get(?pd_idx),
            ?Assert(Idx =/= ?undefined, "leave scence can not find idx"),
            RoomCfgId = get(?pd_scene_id),
            case gen_server:call
            (
                RoomPid,
                #exit_room_args
                {
                    idx = Idx
                }
            )
            of
                {ok, Hp, _X, _Y} ->
                    save_normal_pos(),
                    put(?pd_hp, Hp),
                    erase(?pd_scene_id),
                    erase(?pd_x),
                    erase(?pd_y),
                    erase(?pd_is_in_room_ex),
                    PdIdx = erase(?pd_idx),
                    pet_new_mng:pet_new_leave_scene(RoomPid, PdIdx);
                ok ->
                    ?ERROR_LOG("player ~p leave scene error ~p", [?pname(), {RoomCfgId, get(?pd_x), get(?pd_y)}]);
                {error, Why} ->
                    ?ERROR_LOG("player ~p leave scene error ~p", [?pname(), {RoomCfgId, Why}])
            end
    end.

enter_scene_ok(Agent, SSData) ->
    %% 进场景后广播玩家装备特效
    equip_system:sync_equip_efts(),
    case SSData of
        0 -> ok;
        CardId ->
            case load_cfg_card:lookup_item_card_attr_cfg(CardId) of
                #item_card_attr_cfg{buffs = Buffs} ->
                    lists:foreach(
                        fun(BuffId) ->
                                EndTime = attr_new:get(?pd_shapeshift_end_time),
                                ?player_send(scene_sproto:pkg_msg(?MSG_SCENE_ADD_BUFF, {Agent#agent.idx, BuffId, EndTime}))
                        end,
                        Buffs
                    );
                _ -> ok
            end
    end.

save_normal_pos() ->
    %% ---------- 主场景才需要 ---------
    RoomCfgId = get(?pd_scene_id),
    case load_cfg_scene:is_normal_scene(RoomCfgId) of
        true ->
            put(?pd_save_scene_id, get(?pd_scene_id)),
            put(?pd_save_x, get(?pd_x)),
            put(?pd_save_y, get(?pd_y));
        _ ->
            pass
    end.

handle_msg(_, {start_next_scene, Pid, NextSceneId, {Hp, Mp, Anger}}) ->
    put(?pd_hp, Hp), put(?pd_mp, Mp), put(?pd_crown_anger, Anger),
    {X, Y} = load_cfg_scene:get_enter_pos_by_cfg(NextSceneId),
    player_room_part:begin_enter_room_by_client({Pid, NextSceneId, 1, X, Y, ?D_R});
handle_msg(_, {team_complete, IsInsComplete, WaveNum, DoubleHit, ShouJi, PassTime, HpPercent, MaxPlayerId, A}) ->
    team_complete(IsInsComplete, WaveNum, DoubleHit, ShouJi, PassTime, HpPercent, MaxPlayerId, A);
handle_msg(A, B) ->
    ?ERROR_LOG("unknown msg:~p, ~p", [A, B]),
    ok.

team_complete(_IsInsComplete, _WaveNum, DoubleHit, ShouJi, PassTime, HpPercent, MaxPlayerId, _A) ->
    % ?INFO_LOG("team_complete------------------------------------"),
    Id = main_instance_mng:get_current_instance_doing(),
    {PassPrizeId, MainInsCfg} = main_ins:get_pass_prize(Id),
    % MainType = 
    case MainInsCfg#main_ins_cfg.type of
        ?T_INS_GWGC ->
            Score = MainInsCfg#main_ins_cfg.guaiwu_gc_score,
            BestPrizeId = MainInsCfg#main_ins_cfg.guaiwu_gc_best_prize,
            gwgc_server:add_npc_jifen(get(?pd_id), Score),
            [Car, Name, Lev, Power] = player:lookup_info(MaxPlayerId, [?pd_career, ?pd_name, ?pd_level, ?pd_combat_power]),
            PrizeInfo = prize:prize_mail(PassPrizeId, ?S_MAIL_INSTANCE, ?FLOW_REASON_FUBEN_COMPLETE),
            BsetPrizeInfo = prize:prize_mail(BestPrizeId, ?S_MAIL_INSTANCE, ?FLOW_REASON_FUBEN_COMPLETE),
            MergePrizeInfo = item_goods:merge_goods(PrizeInfo),
            ?player_send(gongcheng_sproto:pkg_msg(?MSG_GONGCHENG_COMPLETE, {Score, Name, Lev, Car, Power, MergePrizeInfo, BsetPrizeInfo}));
        _ ->
            do_team_complete(Id, PassPrizeId, MainInsCfg, DoubleHit, ShouJi, PassTime, HpPercent)
    end.

do_team_complete(Id, PassPrizeId, MainInsCfg, DoubleHit, ShouJi, PassTime, HpPercent) ->
    ?INFO_LOG("team_complete PassPrizeId:~p, HpPercent:~p", [PassPrizeId, HpPercent]),
    ReliveNum = HpPercent,
    ChapterId = MainInsCfg#main_ins_cfg.chapter_id,
    Difficulty = MainInsCfg#main_ins_cfg.sub_type,
    case Difficulty of
        1 -> phase_achievement_mng:do_pc(?PHASE_AC_INSTANCE_CHAPER_1, get(?pd_scene_id), 1);
        2 -> phase_achievement_mng:do_pc(?PHASE_AC_INSTANCE_CHAPER_2, get(?pd_scene_id), 1);
        3 -> phase_achievement_mng:do_pc(?PHASE_AC_INSTANCE_CHAPER_3, get(?pd_scene_id), 1);
        _ -> ok
    end,
    open_server_happy_mng:sync_task(?IS_CROSS_FUBEN, Id),
    {StarList, FenShu} = achievement_mng:complete_instance_ac({Id, ChapterId, 0, 0, PassTime, ReliveNum, DoubleHit, ShouJi, 0}),
    AllStar = main_ins:get_total_star(StarList),
    MainMng = get(?pd_main_ins_mng),
    {F, Coin, _TaskStarCount} = case gb_trees:lookup(Id, MainMng) of
        ?none ->
            put(?pd_main_ins_mng,
                gb_trees:insert(
                    Id,
                    #main_ins{
                        id = Id,
                        pass_time = PassTime,
                        lianjicount = DoubleHit,
                        shoujicount = ShouJi,
                        relivenum = ReliveNum,
                        star = AllStar,
                        fenshu = FenShu,
                        today_passed_times = 1
                    },
                    MainMng
                )
            ),
            {FenShu, AllStar, AllStar};
        {?value, #main_ins{pass_time = OldPassTime, lianjicount = OldLianjiCount, shoujicount = OldShoujiCount, relivenum=OldReliveNum, star = OldStar,
            fenshu = OldFenshu, first_nine_star_pass = Fnsp, today_passed_times = Times} = OldMainIns} ->
            NewFenshu = erlang:max(OldFenshu, FenShu),
            Pt = erlang:min(OldPassTime, PassTime),
            Lj = erlang:max(OldLianjiCount, DoubleHit),
            Sj = erlang:min(OldShoujiCount, ShouJi),
            Rn = erlang:max(OldReliveNum, ReliveNum),
            AllStar2 = achievement_mng:get_total_star(Lj, Sj, Pt, Rn, MainInsCfg#main_ins_cfg.stars),
            FinalAllStar = lists:max([AllStar, AllStar2, OldStar]),
            put(?pd_main_ins_mng,
                gb_trees:update(Id, OldMainIns#main_ins{
                    id = Id,
                    pass_time = Pt,
                    lianjicount = Lj,
                    shoujicount = Sj,
                    relivenum = Rn,
                    star = FinalAllStar,
                    fenshu = NewFenshu,
                    first_nine_star_pass = Fnsp,
                    today_passed_times = Times + 1
                    },
                    MainMng
                )
            ),
            {NewFenshu, erlang:max(0, AllStar - OldStar), FinalAllStar}
    end,
    {{No1F, No1Name, No1Job}, SelfRank} = main_instance_mng:flush_main_instance_rank(Id, F),
    NewCoin = get(?player_main_ins_coin) + Coin,
    main_instance_mng:do_chapter_prize({get(?pd_id), ChapterId, Difficulty}, Coin),
    put(?player_main_ins_coin, NewCoin),
    event_eng:post(?ev_main_ins_pass, {Id, MainInsCfg#main_ins_cfg.ins_id, Difficulty}),
    daily_task_tgr:do_daily_task({?ev_main_ins_pass, Id}, 1),
    {CanGet, FinalPrizeInfo, FinalLianJiPrize, FinalShouJiPrize, FinalPassTimePrize, FinalRelivePrize} = case main_ins_mod:is_can_get_prize_from_room() of
        true ->
            Exp = main_instance_mng:get_exp_by_sp(),
            Gold = main_instance_mng:get_gold_by_sp(),
            attr_new:begin_room_prize(PassPrizeId),

            {ok, ItemTpL} = prize:get_prize(PassPrizeId),
            PrizeList = item_goods:merge_goods(ItemTpL ++ [{?PL_EXP, Exp}] ++ [{?PL_MONEY, Gold}]),
            PrizeInfo = prize:double_items(1000, PrizeList),
            game_res:try_give_ex(PrizeInfo, ?S_MAIL_INSTANCE, ?FLOW_REASON_FUBEN_COMPLETE),
%%            PrizeInfo = prize:prize_mail_2(1000, PassPrizeId, ?S_MAIL_INSTANCE, ?FLOW_REASON_FUBEN_COMPLETE),
            attr_new:end_room_prize(MainInsCfg#main_ins_cfg.ins_id),
            LianJiPrize = main_ins:send_main_ins_star_level_rewards(1000, Id, StarList, ?lianji),
            ShouJiPrize = main_ins:send_main_ins_star_level_rewards(1000, Id, StarList, ?shouji),
            PassTimePrize = main_ins:send_main_ins_star_level_rewards(1000, Id, StarList, ?passtime),
            RelivePrize = main_ins:send_main_ins_star_level_rewards(1000, Id, StarList, ?add_xue),
            {1, PrizeInfo, LianJiPrize, ShouJiPrize, PassTimePrize, RelivePrize};
        _ ->
            {0, [], [], [], [], []}
    end,
    FirstStarPrizeInfo = main_instance_mng:get_first_nine_star_pass_prize_and_set_statue(Id, AllStar, ChapterId),
    ?player_send(
        main_instance_sproto:pkg_msg(
            ?MSG_MAIN_INSTANCE_COMPLETE,
            {
                Id, PassTime, DoubleHit, ShouJi,
                ReliveNum, F, NewCoin, No1F, No1Name,
                No1Job, SelfRank, CanGet, FinalPrizeInfo,
                FirstStarPrizeInfo, FinalLianJiPrize, FinalShouJiPrize,
                FinalPassTimePrize, FinalRelivePrize, main_instance_mng:get_open_card_item_list()
            }
        )
    ).
