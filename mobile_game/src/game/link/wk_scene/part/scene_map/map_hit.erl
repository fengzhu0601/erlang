%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 22. 九月 2015 上午10:24
%%%-------------------------------------------------------------------
-module(map_hit).
-author("clark").

%% API
-export
([
    get_obj_hit_box/4
    , hit_area/2
    , skill_obj_hit/3
    , hit_box/5
    , all_ids/1
    , be_hit/8
]).



-include("inc.hrl").
-include("skill_struct.hrl").
-include("load_spirit_attr.hrl").
-include("scene.hrl").
-include("scene_agent.hrl").
-include("scene_monster.hrl").
-include("model_box.hrl").

%% 技能对象碰撞
skill_obj_hit(#agent{x = X, y = Y, h = H, d = D, pid = Idx} = _A, SkillCfg, ObjCfg) ->
    case ?get_agent(Idx) of
        ?undefined ->
            scene_monster:leave_scene(_A);
        ReleaseA ->
            Box = map_hit:get_obj_hit_box(X, Y, H, ObjCfg),
            hit_box(ReleaseA, D, Box, 0, SkillCfg)
    end,
    ok.


%% 获得相关人员列表
all_ids(HitPointList) ->
    Set = gb_sets:from_list(HitPointList),
    com_util:fold
    (
        get(?pd_monster_max_id),
        get(?pd_player_max_id),
        fun(Idx, Acc) ->
            case ?get_agent(Idx) of
                ?undefined ->
                    Acc;
                A ->
                    case gb_sets:is_element({A#agent.x, A#agent.y}, Set) of
                        ?true ->
                            [Idx | Acc];
                        ?false ->
                            Acc
                    end
            end
        end,
        []
    ).

get_hit_xy_list(Hxl, Hxr, Hyb, Hyt) ->
%%     ?INFO_LOG("get_hit_xy_list ~p", [{Hxl, Hxr, Hyb, Hyt}]),
    Xs = min(Hxl, Hxr),
    Xe = max(Hxl, Hxr),
    Ys = min(Hyb, Hyt),
    Ye = max(Hyb, Hyt),

    List1 =
        com_util:fold
        (
            Xs, Xe,
            fun
                (Bx, Acc1) ->
                    com_util:fold
                    (
                        Ys, Ye,
                        fun
                            (By, Acc2) -> [{Bx, By} | Acc2]
                        end,
                        Acc1
                    )
            end,
            []
        ),
    List1.


%%     if
%%         Hxl =< Hxr andalso Hyb =< Hyt ->
%%             List1 =
%%                 com_util:fold
%%                 (
%%                     Hxl, Hxr,
%%                     fun
%%                         (Bx, Acc1) ->
%%                             com_util:fold
%%                             (
%%                                 Hyb, Hyt,
%%                                 fun
%%                                     (By, Acc2) -> [{Bx, By} | Acc2]
%%                                 end,
%%                                 Acc1
%%                             )
%%                     end,
%%                     []
%%                 ),
%%             List1;
%%         true ->
%%             []
%%     end.


hit_box(?undefined, _Dir, _HitBox, _SkillId, _Skill) ->
    ok;
hit_box(#agent{x = _X, y = _Y} = Attacker, Dir, {_Dealy, _Hxl, _Hyb, _Hxr, _Hyt, _Th, _Dh} = _HitBox, SkillId, #skill_cfg{id = SkillId0} = Skill) ->
    % SkillId = SkillId0,
%%         case load_segments:get_emits(SkillId0) of
%%             0 -> SkillId0;
%%             SkillId1 -> SkillId1
%%         end,
%%    ?INFO_LOG("hit_box ~p", [SkillId]),
    AttackerIdx = Attacker#agent.idx,
    Hxl1 = min(_Hxl, _Hxr),
    HxR1 = max(_Hxl, _Hxr),
    HyT1 = min(_Hyb, _Hyt),
    HyB1 = max(_Hyb, _Hyt),

    HitBox1 = {_Dealy, Hxl1, HyT1, HxR1, HyB1, _Th, _Dh},
    % Ids = get_hit_box_agents_ids(Attacker, HitBox1),
    Ids = [],
    Tm = (com_time:timestamp_msec()),
    AccHead =
        <<
            ?MSG_SCENE_RELEASE_SKILL_JUDGE:16,
            AttackerIdx:16,
            SkillId:32,
            SkillId0:32,
            (Attacker#agent.x):16,
            (Attacker#agent.y):16,
            (Attacker#agent.h):16,
            Tm:64
        >>,
    HitRet =
        lists:foldl
        (
            fun
                ({FIdx, _Bl, _Br, _Bht, _Bhd}, Acc) when FIdx =:= AttackerIdx ->
                    Acc;
                ({FIdx, Bl, Br, Bht, Bhd}, {DAcc, Acc, HAcc}) ->
%%                     ?INFO_LOG("why ~p", [FIdx]),
                    case ?get_agent(FIdx) of
                        ?undefined ->
                            {DAcc, Acc, HAcc};
                        Defender ->
                            erlang:put(?scene_hit_box_ret, 0),
                            pl_util:attack(Attacker, Defender, Skill, Dir),
                            FaMsg = erlang:get(?scene_hit_box_ret),
                            case {?get_agent(FIdx), FaMsg} of
                                {0, _} ->
                                    {DAcc, Acc, HAcc};
                                {_, 0} ->
                                    {DAcc, Acc, HAcc};
                                {#agent{hp = 0} = DA, FaMsg} ->
                                    {[DA | DAcc], <<Acc/binary, FaMsg/binary, Bl:16, Br:16, Bht, Bhd>>, HAcc};
                                {NA, _} ->
                                    Damage = Defender#agent.hp - NA#agent.hp,
                                    {DAcc, <<Acc/binary, FaMsg/binary, Bl:16, Br:16, Bht, Bhd>>, [{NA, Damage} | HAcc]}
                            end
                    end
            end,
            {[], AccHead, []},
            Ids
        ),

    {DieAgents, AttMsg, HurtAgents} = HitRet,

    ?ifdo(AttackerIdx > 0, ?send_to_client(Attacker#agent.pid, AttMsg)),
    map_aoi:broadcast_view_me_agnets(Attacker, AttMsg),
    [map_agent:on_agent_die(DA, Attacker) || DA <- DieAgents],
    [buff_system:buff_passive_damage(Attacker, HA, Damage) || {HA, Damage} <- HurtAgents],

    % add skill buff
    buff_system:apply_skillId(Attacker, Ids, Skill#skill_cfg.id),
    ok.

be_hit(?undefined, _SkillId, _SkillDuanId, _Dir, _ReleaseX, _ReleaseY, _ReleaseZ, _AgentBeHitIdxList) ->
    ok;
be_hit(Attacker, SkillId, SkillDuanId, Dir, ReleaseX, ReleaseY, ReleaseZ, AgentBeHitIdxList) ->
    SkillCfg = load_cfg_skill:lookup_skill_cfg(SkillDuanId),
    Tm = (com_time:timestamp_msec()),
    AccHead = <<
        ?MSG_SCENE_RELEASE_SKILL_JUDGE:16,
        (Attacker#agent.idx):16,
        SkillId:32,
        SkillDuanId:32,
        ReleaseX:16,
        ReleaseY:16,
        ReleaseZ:16,
        Tm:64
    >>,
    HitRet = lists:foldl(
        fun({FIdx, _, _, _, _Bl, _Br, _Bht, _Bhd}, Acc) when FIdx =:= Attacker#agent.idx ->
                Acc;
            ({FIdx, X, Y, H, Bl, Br, Bht, Bhd}, {DAcc, Acc, HAcc}) ->
                case ?get_agent(FIdx) of
                    ?undefined ->
                        {DAcc, Acc, HAcc};
                    Defender ->
                        erlang:put(?scene_hit_box_ret, 0),
                        pl_util:attack(Attacker, Defender#agent{x = X, y = Y, h = H}, SkillId, SkillCfg, Dir),
                        FaMsg = erlang:get(?scene_hit_box_ret),
                        case {?get_agent(FIdx), FaMsg} of
                            {0, _} ->
                                {DAcc, Acc, HAcc};
                            {_, 0} ->
                                {DAcc, Acc, HAcc};
                            {#agent{hp = 0} = DA, FaMsg} ->
                                {[DA | DAcc], <<Acc/binary, FaMsg/binary, Bl:16, Br:16, Bht, Bhd>>, HAcc};
                            {NA, _} ->
                                Damage = Defender#agent.hp - NA#agent.hp,
                                {DAcc, <<Acc/binary, FaMsg/binary, Bl:16, Br:16, Bht, Bhd>>, [{NA, Damage} | HAcc]}
                        end
                end
        end,
        {[], AccHead, []},
        AgentBeHitIdxList
    ),
    {DieAgents, AttMsg, HurtAgents} = HitRet,
    % ?ifdo(Attacker#agent.idx > 0, ?send_to_client(Attacker#agent.pid, AttMsg)),
    map_aoi:broadcast_view_me_agnets(Attacker, AttMsg),
    skill_modify_util:be_hit(Attacker, SkillDuanId, HurtAgents),
    NewAttacker = case Attacker#agent.type of
        ?agent_skill_obj -> %% 如果是释放物应该是释放者的idx
            ?get_agent(Attacker#agent.fidx);
        _ ->
            Attacker
    end,
    [map_agent:on_agent_die(DA, NewAttacker) || DA <- DieAgents],
    ok.

%% 产生碰撞区
hit_area(#agent{idx = _Idx, x = _X, y = _Y, h = _H, d = _Dir} = _Agent, _Skill) ->
    ok.

%% 获得子弹攻击箱子
get_obj_hit_box(X, Y, H, #skill_release_obj_cfg{size = {_Rx, Ry, _Rh} = _Size}) ->
    {0, X, Y - Ry, X, Y + Ry, H + _Rh, H - _Rh}.

%% 得到和指定矩形相交的ids
get_hit_box_agents_ids({_, Hxl, Hyt, Hxr, Hyb, HTh, HDh} = _BoxArea) ->
    com_util:fold
    (
        get(?pd_monster_max_id),
        get(?pd_player_max_id),
        fun(Idx, Acc) ->
            case ?get_agent(Idx) of
                ?undefined ->
                    Acc;
                #agent{type = ?agent_skill_obj} = _A ->
                    Acc;
                #agent{} = A ->
                    {ALT, ARB, Ath, Adh} = _B = get_model_box(A),
%%                     ?INFO_LOG("BoxArea ~p", [{{Hxl, Hyt}, {Hxr, Hyb}}]),

                    {_LxB, _TyB} = ALT,
                    {_RxB, _ByB} = ARB,
%%                     debug:show_hit_area(A, get_hit_xy_list(LxB, RxB, ByB, TyB)),
                    case com_util:is_rect_intersection2({Hxl, Hyt}, {Hxr, Hyb}, ALT, ARB) of
                        {?true, BoxXL, BoxXR} ->
                            Mth = min(HTh, Ath),
                            Mdh = max(HDh, Adh),
                            WUDI = buff_system:is_buff_inter_damage(Idx),
                            if
                                WUDI -> Acc;
                                Mth >= Mdh -> [{Idx, BoxXL, BoxXR, Mth, Mdh} | Acc];
                                true -> Acc
                            end;
                        _ ->
%%                             ?INFO_LOG("H error"),
                            Acc
                    end
            end
        end,
        []
    ).

is_rect_intersection2_tt(#agent{idx = _Idx1} = _Agent, {LxA, TyA}, {RxA, ByA}, {LxB, TyB}, {RxB, ByB}) ->
    %% 如果相交则相交区域构成矩形
    %% HACK native code
    _InterLx = max(LxA, LxB),
    _InterTy = max(TyA, TyB),
    _InterRx = min(RxA, RxB),
    _InterBy = min(ByA, ByB),
%%     ?INFO_LOG("is_rect_intersection2_tt1 ~p", [{{LxA, TyA}, {RxA,ByA}}]),
%%     ?INFO_LOG("is_rect_intersection2_tt2 ~p", [{{LxB, TyB}, {RxB, ByB}}]),
%%     ?INFO_LOG("is_rect_intersection2_tt3 ~p", [(InterLx =< InterRx andalso InterTy =< InterBy)]),
%%     debug:show_hit_area(Agent, get_hit_xy_list(InterLx, InterRx, InterTy, InterBy)),
    ok.

get_hit_box_agents_ids(#agent{idx = Idx1, pk_info = APkInfo}, {_, Hxl, Hyt, Hxr, Hyb, HTh, HDh}) ->
    com_util:fold
    (
        get(?pd_monster_max_id),
        get(?pd_player_max_id),
        fun(Idx, Acc) ->
            case ?get_agent(Idx) of
                ?undefined ->
                    Acc;
                #agent{type = ?agent_skill_obj} ->
                    Acc;
                #agent{idx = Idx2, pk_info = BPkInfo} = B ->
                    {ALT, ARB, Ath, Adh} = get_model_box(B),
%%                    ?INFO_LOG("BoxArea ~p", [{{Hxl, Hyt}, {Hxr, Hyb},ALT,ARB}]),
                    if
                        Idx1 =/= Idx2 ->
                            {LxB, TyB} = ALT,
                            {RxB, ByB} = ARB,
                            debug:show_hit_area(B, get_hit_xy_list(LxB, RxB, ByB, TyB)),
                            is_rect_intersection2_tt(B, {Hxl, Hyt}, {Hxr, Hyb}, ALT, ARB);
                        true ->
                            ok
                    end,
                    case is_pk_mode_can_hit(APkInfo, BPkInfo) of
                        true ->
                            case com_util:is_rect_intersection2({Hxl, Hyt}, {Hxr, Hyb}, ALT, ARB) of
                                {?true, BoxXL, BoxXR} ->
                                    Mth = min(HTh, Ath),
                                    Mdh = max(HDh, Adh),
                                    % ?INFO_LOG("load check interrupt damage "),
                                    WUDI = buff_system:is_buff_inter_damage(B),
                                    if
                                        WUDI -> Acc;
                                        Mth >= Mdh -> [{Idx, BoxXL, BoxXR, Mth, Mdh} | Acc];
                                        true -> Acc
                                    end;
                                _ ->
                                    Acc
                            end;
                        _ ->
                            % ?INFO_LOG("H error"),
                            Acc
                    end
            end
        end,
        []
    ).

%% @doc 得到对应模型当前的位置矩形
get_model_box(#agent{idx = Idx, id = Id, x = X, y = Y, h = H}) ->
    CfgId =
        if
            Idx > 0 -> 1;
            true -> Id
        end,
    {{X1, Y1}, {X2, Y2}, H1, H2} =
        case model_box:lookup_model_box_cfg(CfgId) of
            #model_box_cfg{x = Vx, y = Vy, h = Vh} ->
                {{X - Vx, Y - Vy}, {X + Vx, Y + Vy}, H + Vh, H};
            none ->
                case load_cfg_skill:lookup_skill_release_obj_cfg(CfgId) of
                    #skill_release_obj_cfg{size = {Vx, Vy, Vh}} ->
                        {{X - Vx, Y - Vy}, {X + Vx, Y + Vy}, H + Vh, H};
                    ?none ->
                        {{X - 1, Y - 1}, {X + 1, Y + 1}, H + 4, H}
                end
        end,
    Hxl1 = min(X1, X2),
    HxR1 = max(X1, X2),
    HyT1 = min(Y1, Y2),
    HyB1 = max(Y1, Y2),
    {{Hxl1, HyT1}, {HxR1, HyB1}, H1, H2}.


%% %% 产生碰撞区
%% hit_area({_Ox, _Oy, _Oh}, A, Skill, D) ->
%%     Idx = A#agent.idx,
%%     X = A#agent.x,
%%     Y = A#agent.y,
%%     H = A#agent.h,
%%     lists:foreach
%%     (
%%         fun
%%             (Box) ->
%%                 case element(1, Box) of
%%                     0 ->
%%                         %% TODO 是否要每次都get_A
%%                         hit_box(A, D, Box, Skill);
%%                     Delay ->
%%                         scene_eng:start_timer(Delay, scene_fight, {hit_box, Idx, D, Box, Skill#skill_cfg.id})
%%                 end
%%         end,
%%         load_cfg_skill:get_hit_boxs(X, Y, H, Skill, D)
%%     ),
%%     ok.

is_pk_mode_can_hit({_, _}, {_, _}) -> false;                    %% 怪打怪
is_pk_mode_can_hit({_, _}, {_, _, _, _}) -> true;               %% 怪打人
is_pk_mode_can_hit({_, _, _, _}, {_, _}) -> true;               %% 人打怪
is_pk_mode_can_hit({PkMode, _, Team1, _}, {_, _, Team2, _}) ->  %% 人打人
    case PkMode of
        ?PK_TEAM ->
            Team1 =/= Team2;
        4 ->
            Team1 =/= Team2;
        _ ->
            true
    end.