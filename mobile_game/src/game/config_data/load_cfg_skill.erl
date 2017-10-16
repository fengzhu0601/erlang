%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 29. 十月 2015 上午10:32
%%%-------------------------------------------------------------------
-module(load_cfg_skill).
-author("clark").


%% API
-export(
[
    get_skill_move_point/2
    , get_level_skills/2
    , get_hit_boxs/5
    , get_next_grid/3
    , get_hit_points/2
    % , get_skill_cfg_by_segment/1
    % , get_skill_move_type_by_segment/1
    % , get_skill_special_key_by_segment/1
    , get_cost_mp/1
    , get_bullet_box/1
    , get_bullet_speed/1
    , get_skill_type/1
    , get_segments_by_emitid/1
    , get_segments_by_skillid/2
]).



-include("inc.hrl").
-include_lib("config/include/config.hrl").
-include("load_cfg_skill.hrl").

-record(skill_move_cfg,
{
    id
    , movement
}).


%% -> [SkillId]
get_level_skills(Level, Carrer) ->
    case lookup_group_skill_cfg(#skill_cfg.level_limit, Level) of
        ?none ->
            [];
        SkillIdList ->
            lists:foldl
            (
                fun(Id, Acc) ->
                    case lookup_skill_cfg(Id, #skill_cfg.career_limit) of
                        Carrer ->
                            [Id | Acc];
                        _ ->
                            Acc
                    end
                end,
                [],
                SkillIdList
            )
    end.


%% -> [{delay,lx,ty,rx,dy,th,dh}]
get_hit_boxs(X, Y, H, SkillCfg, Dir) ->
    case SkillCfg#skill_cfg.hit_area of
        [] ->
            [{0, 0, 0, 0, 0, 0, 0}];
        Area ->
            lists:foldl
            (
                fun
                    ({Delay, Lx, Ty, Rx, Dy, Th, Dh}, Acc) ->
                        case Dir of %%　默认向右边
                            ?D_L ->
                                [{Delay, X - Rx, Y + Ty, X - Lx, Y + Dy, H + Th, max(0, H + Dh)} | Acc];
                            _ ->
                                [{Delay, X + Lx, Y + Ty, X + Rx, Y + Dy, H + Th, max(0, H + Dh)} | Acc]
                        end
                end,
                [],
                Area
            )
    end.

get_next_grid(SkillID, Dir, {FromX, FromY, FromH}) ->
    case SkillID#skill_cfg.move_grid of
        ?none -> ret:error(?none);
        {CfgX, CfgY, CfgH} ->
            X =
                if
                    CfgX =:= 0 -> CfgX;
                    Dir =:= ?D_L -> -CfgX;
                    true -> CfgX
                end,
            {FromX + X, FromY + CfgY, max(0, FromH + CfgH)}
    end.


%% 获得碰撞点
get_hit_points(SkillCfg, D) ->
    case D of
        ?D_L ->
            element(2, SkillCfg#skill_cfg.hit_area);
        _ ->
            element(1, SkillCfg#skill_cfg.hit_area)
    end.

%% %% 技能产生
%% on_skill_start(_A, SkillCfg, D) -> ok.
%%
%% %% 机关技能攻击
%% device_skill_start(DeviceId, {Ox, Oy}, HitPer, #skill_cfg{id = SkillId, release_range = SRange} = Skill) -> ok.


%% TODO compiler to beam
%% -> ?none | {Daley, Offset ::{_,_}}
get_skill_move_point(SkillId, Index) ->
    case lookup_skill_move_cfg(SkillId, #skill_move_cfg.movement) of
        ?none -> ?none;
        [] -> ?none;
        PointList ->
            lists:nth(Index, PointList)
    end.

get_skill_type(SkillId) ->
    lookup_skills_org_cfg(SkillId, #skills_org_cfg.type).


load_config_meta() ->
    [
        #config_meta
        {
            record = #skill_cfg{},
            fields = ?record_fields(skill_cfg),
            file = "generated_server_skills.txt",
            keypos = #skill_cfg.id,
            groups = [#skill_cfg.level_limit],
            verify = fun verify/1
        },

        #config_meta
        {
            record = #skill_move_cfg{},
            fields = ?record_fields(skill_move_cfg),
            file = "generated_server_skill_moves.txt",
            keypos = #skill_move_cfg.id,
            verify = fun verify_skill_move/1
        },

        #config_meta
        {
            record = #skill_release_obj_cfg{},
            fields = ?record_fields(skill_release_obj_cfg),
            file = "generated_release_objects.txt",
%%            file = "emits.txt",
            keypos = #skill_release_obj_cfg.id,
            verify = fun verify_skill_release_obj/1
        },

        #config_meta
        {
            record = #skill_modify_cfg{},
            fields = ?record_fields(skill_modify_cfg),
            file = "skill_modify.txt",
            keypos = #skill_modify_cfg.id,
            verify = fun verify_sk/1
        },

        #config_meta
        {
            record = #long_wen_cfg{},
            fields = ?record_fields(long_wen_cfg),
            file = "long_wen.txt",
            keypos = [#long_wen_cfg.id, #long_wen_cfg.lev],
            verify = fun verify_long_wen_cfg/1
        },

        #config_meta
        {
            record = #skills_org_cfg{},
            fields = ?record_fields(skills_org_cfg),
            file = "skills.txt",
            keypos = #skills_org_cfg.id,
            all = [#skills_org_cfg.id],
            rewrite = fun change_skill/1,
            verify = fun verify_org/1
        }
    ].

% -define(segment(Segment), {"@segment_tab@", Segment}).

% change_skill(_) ->
%     {NewCfgList, TotalSegmentList} =
%         ets:foldl
%         (
%             fun
%                 ({_, #skills_org_cfg{id = Id, segments = Segments} = Cfg}, {CfgList, SegList}) ->
%                     SegList1 =
%                         lists:foldl
%                         (
%                             fun
%                                 (SegmentID, Acc) ->
%                                     [{SegmentID, Id} | Acc]
%                             end,
%                             SegList,
%                             Segments
%                         ),
%                     CfgList1 = [Cfg | CfgList],
%                     {CfgList1, SegList1}
%             end,
%             {[], []},
%             skills_org_cfg
%         ),
%     my_ets:set(?segment(1), TotalSegmentList),
%     NewCfgList.
change_skill(_) ->
    ets:foldl(
        fun({_, #skills_org_cfg{} = Cfg}, CfgList) ->
                [Cfg | CfgList]
        end,
        [],
        skills_org_cfg
    ).

verify_org(#skills_org_cfg{}) ->
    ok.

verify_sk(#skill_modify_cfg{id = _Id}) ->
    ok.

verify_long_wen_cfg(_) ->
    ok.


verify_skill_release_obj(#skill_release_obj_cfg{id = Id, delay = Delay, born_point = BP,
    speed = Speed, move_grid = MG, size = Size}) ->
    ?check(is_integer(Delay) andalso Delay > 50, "skill_release_obj.txt [~p] delay ~p 无效 > 50", [Id, Delay]),
    ?check(is_tuple(BP) andalso tuple_size(BP) =:= 3, "skill_release_obj.txt [~p] born_point~p 无效 > 50", [Id, BP]),
    ?check(is_integer(Speed) andalso Speed >= 0, "skill_release_obj.txt [~p] speed ~p 无效 >= 0", [Id, Speed]),
    ?check(is_integer(MG), "skill_release_obj.txt [~p] move_grid ~p 无效 > 3", [Id, MG]),
    ?check(is_tuple(Size) andalso tuple_size(Size) =:= 3, "skill_release_obj.txt [~p] size ~p 无效 {x,y,h}", [Id, Size]),
    ok.


verify_skill_move(#skill_move_cfg{id = Id, movement = M}) ->
    ?check(is_list(M), "skill_move[~p] movent ~p 无效类型", [Id, M]),
    ok.

verify(#skill_cfg{id = Id, upgrade_cost = UpCost, cd = Cd, release_range = Range,
    delay = Delay, base_hit = Bh, pure_hit = Ph, render_time = SHT,
    hard_time = HT, hit_repeat_time = RT, hit_repeat_interval = HRI,
    beat_back_dist = BBD, beat_back_speed = _BBS,
    hit_repeat_is_follow = HTF,
    move_grid = MG, buffs = BuffList, link = _Link, rush = Rush,
    rush_speed = RushSpeed,
    hit_area = Area,
    break_pri = BreakPRI,
    breaked_pri = BreakedPRI,
    skill_coe = SkillCoe,
    var_coe = VarCoe,
    attr_type = AttrType,
    m = M,
    skill_bias = SkillBias
} = _R) ->

    case M of
        ?none -> %% 特殊技能
            ?check(is_number(SkillCoe), "skill [~p] skill_coe ~p 无效", [Id, SkillCoe]),
            ?check(is_number(VarCoe), "skill [~p] var_coe ~p 无效", [Id, VarCoe]),
            ?check(game_def:is_valid_skill_attr(AttrType), "skill [~p] attr_type ~p 无效", [Id, AttrType]);
        _ -> %% 普通技能
            ?check(is_number(M), "skill [~p] m~p 无效", [Id, M])
    end,


    ?check(Id > 0 andalso Id =< ?MAX_UINT32, "skill[~p] 大于 uint16", [Id]),
    ?check(Cd >= 0, "skill [~p] cd ~p 必须>= 0", [Id, Cd]),
    cost:check_cost_not_empty(UpCost, "skill[~p] cost ~p 无法找到", [Id, UpCost]),
    ?check(Delay =:= ?none orelse Delay >= 10, "skill[~p] delay ~p 必须>=10 毫秒", [Id, Delay]),
    ?check(is_integer(Bh), "skill[~p] base_hti ~p 无效", [Id, Bh]),
    ?check(is_integer(Ph), "skill[~p] pure_hti ~p 无效", [Id, Ph]),
    %%?check(sprite_stat:is_exist_sprite_stat_cfg(SpriteId), "skill[~p] sprite_stat ~p 无法找到 ", [Id, SpriteId]),
    case Range of
        {_RMin, _RMax} ->
            ?check(is_tuple(Range) andalso tuple_size(Range) =:= 2 andalso _RMin =< _RMax, "skill[~p] release_range ~p 必须>= 0 X <= Y", [Id, Range]);
        _ ->
            ?check(false, "skill.txt [~p] release_range ~p 格式无效", [Id, Range])
    end,

    ?check(SHT >= 0, "skill[~p] render_time~p 必须 >= 0毫秒", [Id, SHT]),
    ?check(HT =:= 0 orelse HT >= 100, "skill[~p] hard_time ~p 必须 == 0 or > 100毫秒", [Id, HT]),

    ?check(HTF =:= ?TRUE orelse HTF =:= ?FALSE, "skill[~p] hit_repeat_is_follow ~p 无效必须是0,1", [Id, HTF]),

    ?check(RT =:= 0 orelse RT < 30, "skill[~p] hit_repeat_time 重复次数太多了 ~p", [Id, RT]),

    if RT =/= 0 ->
        ?check(HRI >= 200 andalso HRI =< 1000, "skill[~p] hit_repeat_interval 间隔时间无效 ~p", [Id, HRI]);
        true -> ok
    end,

    ?check(BBD =:= 0 orelse BBD < 50, "skill[~p] beat_back_dist ~p should < 50太长了", [Id, BBD]),
    %% 如果有击退就不能配置
    if BBD =/= 0 ->
        %%?check(HT =:= 0, "skill[~p] 不能同时配置hard_time 和 beat_back_dist ", [Id]),
%%             ?check(BBS > 0, "skill[~p] beat_back_speed ~p 必须 >0", [Id, BBS]);
        ok;
        true ->
            ok
    end,

    ?check(?is_pos_integer(BreakPRI), "skill[~p] break_prirotiy ~p invalied", [Id, BreakPRI]),
    ?check(?is_pos_integer(BreakedPRI), "skill[~p] breaked_prirotiy ~p invalied", [Id, BreakedPRI]),

    ?check(is_list(Area), "skill[~p] hit_area~p 无效格式", [Id, Area]),
    [?check(is_tuple(Box) andalso tuple_size(Box) =:= 7, "skill[~p] hit_area 无效格式", [Id]) || Box <- Area],

    case MG of
        ?none -> ok;
        {__A, __B, __C} when
            is_integer(__A),
            is_integer(__B),
            is_integer(__C) ->
            ok;
        _ ->
            ?check(false, "skill.txt[~p] move_grid 无效参数 ~p ", [Id, MG])
    end,


    ?check(is_list(BuffList), "skill.txt [~p] buff_list 无效格式 ~p not list", [Id, BuffList]),
    [?check(buff:is_exist_buff_cfg(BuffId) andalso
        _Range > 0 andalso
        _Range =< 100, "skill.txt [~p] bad buff ~p", [Id, BuffId])
        || {_Range, BuffId} <- BuffList],

    [?check(buff:is_valid_skill_buff(BuffId), "skill.txt [~p] buff ~p 不能用作技能 buff", [Id, BuffId]) || {_Range, BuffId} <- BuffList],

    %%case Link of
    %%?none -> ok;
    %%{LDelay, Lid} ->
    %%?check(is_integer(LDelay) andalso LDelay > 0, "skill.txt [~p] link 时间~p 必须>=0 不存在", [Id, LDelay]),
    %%?check(is_exist_skill_cfg(Lid), "skill.txt [~p] link 技能 ~p 不存在", [Id, Lid]);
    %%_ ->
    %%?ERROR_LOG("skill.txt [~p] 无效link ~p", [Id, Link]),
    %%exit(bad)
    %%end,

    ?check(is_integer(Rush), "skill.txt [~p] rush ~p 无效", [Id, Rush]),
    case RushSpeed of
        ?none ->
            ok;
        {Xs, Hs} ->
            ?check(Xs >= 0 andalso Hs >= 0, "skill.txt [~p] rush_speed ~p 无效", [Id, RushSpeed]);
        _ ->
            ?check(false, "skill.txt [~p] rush_speed ~p 无效", [Id, RushSpeed])
    end,

    case SkillBias of
        List when is_list(List) ->
            AllVal = lists:foldl(
                fun({_ProKey, ProVal}, TempVal) ->
                        ProVal + TempVal
                end,
                0,
                List
            ),
            ?check(AllVal =:= 100, "skill.txt [~p] bad skill_bias ~p", [Id, SkillBias]);
        _ ->
            pass
    end,
    ok;

verify(_R) ->
    ?ERROR_LOG("skill 配置　错误格式"),
    exit(bad).


%% 目前技能段不支持复用
% get_skill_cfg_by_segment(SegmentID) ->
%     case my_ets:get(?segment(1), []) of
%         [] ->
%             ?none;
%         List ->
%             case lists:keyfind(SegmentID, 1, List) of
%                 false ->
%                     ?none;
%                 {_S, SkillID} ->
%                     Record = lookup_skills_org_cfg(SkillID),
%                     case Record of
%                         #skills_org_cfg{} ->
%                             Record;
%                         _ ->
%                             ?none
%                     end
%             end
%     end.


%% get_segment(SkillId, Pos) ->
%%     case lookup_skills_org_cfg(SkillID) of
%%         #skills_org_cfg{segments = Segments} ->
%%             Record;
%%         _ ->
%%             ?none


%% 移动类型（0代表自定义,1代表自由移动,2代表固定移动（动画固定））
% get_skill_move_type_by_segment(SegmentID) ->
%     Cfg = get_skill_cfg_by_segment(SegmentID),
%     case Cfg of
%         #skills_org_cfg{move_type = MoveType} -> MoveType;
%         _ -> 0
%     end.

% get_skill_special_key_by_segment(SegmentID) ->
%     Cfg = get_skill_cfg_by_segment(SegmentID),
%     case Cfg of
%         #skills_org_cfg{key = SpeKey} -> SpeKey;
%         _ -> 0
%     end.

get_cost_mp(SegmentID) ->
    Cfg = lookup_skill_cfg(SegmentID),
    case Cfg of
        #skill_cfg{cost_mp = Mp} when is_integer(Mp) ->
            Mp;
        _ ->
            0
    end.

get_bullet_box(ObjId) ->
    %% 这里表重复逻辑混乱，历史原因，团队原因。
    case load_cfg_skill:lookup_skill_release_obj_cfg(ObjId) of
        ?none ->
            {0, 0, 0};
        #skill_release_obj_cfg{size = Box} ->
            Box
    end.

get_bullet_speed(ObjId) ->
    %% 这里表重复逻辑混乱，历史原因，团队原因。
    case load_cfg_skill:lookup_skill_release_obj_cfg(ObjId) of
        ?none ->
            erlang:make_tuple(4, 0);
        #skill_release_obj_cfg{size = _Box} ->
            erlang:make_tuple(4, speed)
    end.

get_segments_by_emitid(EmitId) ->
    SkillId = load_cfg_emits:get_skill_id(EmitId),
    case lookup_skills_org_cfg(SkillId, #skills_org_cfg.segments) of
        none ->[];
        Ret -> Ret
    end.

get_segments_by_skillid(SkillId, Index) ->
    case lookup_skills_org_cfg(SkillId, #skills_org_cfg.segments) of
        none ->
            nil;

        Ret ->
            ListLen = erlang:length(Ret),
            if
                Index > ListLen -> nil;
                Index =< 0 -> nil;
                true -> lists:nth(Index, Ret)
            end
    end.

%% 配置支持格式
%% 如果有0点就是从0点开始释放
%% 如果没有就从x点开始释放
%%           +++++
%%       x   ++0++
%%           +++++
%% 不同的方向释放距离不同
%%change(_) ->
%%    {ok, Path} = application:get_env(config_file_path),
%%    Path1 = Path++ "skill/hit/",
%%    HitFiles = com_file:list_dir_filter(fun(File) ->
%%                                                lists:suffix(".txt", File)
%%                                        end,
%%                                        Path1),
%%    %%?debug_log_skill_mng("all hist file~p",[HitFiles]),
%%
%%    lists:foldl(fun(_File, NewRowList) ->
%%                          Id = erlang:list_to_integer(_File -- ".txt"),
%%                          File = Path1++_File,
%%                          case file:read_file(File) of
%%                              {error, R} ->
%%                                  ?ERROR_LOG("can not find hit file ~p error:~p", [File, R]),
%%                                  exit(bad);
%%                              {ok, Binary} ->
%%                                  LienList = binary:split(Binary, [<<$\n>>, <<$\r,$\n>>], [global, trim]),
%%                                  {_Y, {X, Bo, HitPointList}}=
%%                                      lists:foldl(fun(FLine, {FY, Acc}) ->
%%                                                          case  parse_line(FLine, Acc, 0, FY) of
%%                                                              {error, R} ->
%%                                                                  ?ERROR_LOG("skill hit file ~p 格式错误 ~p", [File, R]);
%%                                                              R ->
%%                                                                  {FY+1, R}
%%                                                          end
%%                                                  end,
%%                                                  {0, {nil, nil, []}},
%%                                                  LienList),
%%                                  ?check(X =/= nil, "skill hit file ~p 没有配置原点", [File]),
%%                                  ?check(HitPointList =/= [], "skill hit file ~p 没有伤害点", [File]),
%%
%%                                  %% 计算释放距离(玩家释放时自己的点和释放中心点的距离)
%%                                  %%ReleaseRange = case Bo of
%%                                                     %%nil ->
%%                                                         %%0;
%%                                                     %%_ ->
%%                                                         %%com_util:origin_distance(Bo, X)
%%                                                 %%end,
%%
%%                                  %%if Bo =:= nil ->
%%                                          %%% 以原点重新计算相对坐标
%%                                          %%RelationHitPointList = relationPoint(X, [X | HitPointList]),
%%
%%                                          %%% 以原点距离排序
%%                                          %%SL = lists:sort(fun(P1, P2) ->
%%                                                                  %%com_util:origin_distance(P1) =<
%%                                                                      %%com_util:origin_distance(P2)
%%                                                          %%end,
%%                                                          %%RelationHitPointList);
%%                                     %%true ->
%%                                                %%% 以Bo距离排序
%%                                          %%BoSl = lists:sort(fun(P1, P2) ->
%%                                                                    %%com_util:get_point_distance(P1, Bo) =<
%%                                                                        %%com_util:get_point_distance(P2, Bo)
%%                                                            %%end,
%%                                                            %%HitPointList),
%%
%%                                          %%% 以原点计算相对坐标
%%                                          %%SL = relationPoint(X, BoSl)
%%
%%                                  %%end,
%%
%%                                  %?DEBUG_LOG("A:~p ~p ", [X, HitPointList]),
%%                                  %?DEBUG_LOG("RelationHitPointList:~p ", [RelationHitPointList]),
%%                                  %?DEBUG_LOG("SL:~p ", [SL]),
%%
%%                                  % 生成8方向
%%
%%
%%                                  [#skill_hit_cfg{id={Id, D}, points=FPoints} ||
%%                                   %%{D, FPoints} <- [{D, gen_diction(D,SL)} ||
%%                                   {D, FPoints} <- [{D, gen_hit(D, X, Bo, HitPointList)} ||
%%                                                    D <- [?D_R, ?D_L, ?D_U, ?D_D, ?D_RU, ?D_RD, ?D_LD, ?D_LU]]] ++
%%                                  NewRowList
%%
%%                          end
%%                end,
%%                [],
%%                HitFiles).
%%
%%
%%gen_hit(D, X, nil, HitPointList) ->
%%    % 以原点重新计算相对坐标
%%    RelationHitPointList = relationPoint(X, [X | HitPointList]),
%%
%%    % 以原点距离排序
%%    SL = lists:sort(fun(P1, P2) ->
%%                            com_util:origin_distance(P1) =<
%%                            com_util:origin_distance(P2)
%%                    end,
%%                    RelationHitPointList),
%%    gen_diction(D, SL);
%%
%%gen_hit(D, X, Bo, HitPointList) ->
%%    Range=get_range(D, X, Bo),
%%    % 以Bo距离排序
%%    BoSl = lists:sort(fun(P1, P2) ->
%%                              com_util:get_point_distance(P1, Bo) =<
%%                              com_util:get_point_distance(P2, Bo)
%%                      end,
%%                      HitPointList),
%%
%%    % 以原点计算相对坐标
%%    SL = relationPoint(X, move_hit_point(Range, BoSl)),
%%    gen_diction(D, SL).
%%

% gen_diction(?D_R, PointList) -> PointList;
% gen_diction(?D_L, PointList) -> [{-X, Y} || {X,Y} <- PointList];
% gen_diction(?D_U, PointList) -> [{Y, -X} || {X,Y} <- PointList];
% gen_diction(?D_D, PointList) -> [{-Y, X} || {X,Y} <- PointList];

% gen_diction(?D_RU, PointList) -> com_lists:drop_repeat_element([trun_point(X,Y, math:pi()/4) || {X,Y} <- PointList]);
% gen_diction(?D_RD, PointList) -> com_lists:drop_repeat_element([trun_point(X,Y, -math:pi()/4) || {X,Y} <- PointList]);
% gen_diction(?D_LD, PointList) -> com_lists:drop_repeat_element([trun_point(X,Y, -math:pi()/4*3) || {X,Y} <- PointList]);
% gen_diction(?D_LU, PointList) -> com_lists:drop_repeat_element([trun_point(X,Y, math:pi()/4*3) || {X,Y} <- PointList]).

% get_range(D, X, Bo) ->
%     if D =:= ?D_R; D=:=?D_L; D=:=?D_U; D=:=?D_RU; D=:= ?D_LU ->
%            {0, 0};
%        D =:= ?D_D ->
%            {round(0.7 * com_util:get_point_distance(X, Bo)), 0};
%        true ->
%            {round(0.7 * com_util:get_point_distance(X, Bo)), 0}
%     end.


%% 根据不同的range 修正hit_point_list
% move_hit_point({Rx, Ry}, HitPointList) ->
%     [{X-Rx, Y-Ry} || {X,Y} <- HitPointList].


% trun_point(0, Y, AddTheta) ->
%     OTheta = math:pi()/2,
%     H = Y,
%     NewX = math:cos(OTheta+AddTheta) * H,
%     NewY = math:sin(OTheta+AddTheta) * H,
%     {round(NewX), -round(NewY)};

% trun_point(X, Y, AddTheta) ->
%     OTheta = math:atan(Y/X),
%     H = com_util:origin_distance(X,Y),
%     NewX = math:cos(OTheta+AddTheta) * H,
%     NewY = math:sin(OTheta+AddTheta) * H,
%     {round(NewX), -round(NewY)}.

%% 玩家所在点也是伤害点
% parse_line(<<>>, Acc, _, _) -> Acc;
% parse_line(<<$+, Other/binary>>, {O, Bo, HitPointList}, X, Y) ->
%     parse_line(Other, {O, Bo, [{X,Y} | HitPointList]}, X+1, Y);

% parse_line(<<$0, Other/binary>>, {O, nil, HitPointList}, X, Y) ->
%     parse_line(Other, {O, {X,Y}, [{X,Y} | HitPointList]}, X+1, Y);

% parse_line(<<$x, Other/binary>>, {nil, Bo, HitPointList}, X, Y) ->
%     parse_line(Other, {{X,Y}, Bo, HitPointList}, X+1, Y);

% parse_line(<<$ , Other/binary>>, Acc, X, Y) ->
%     parse_line(Other, Acc, X+1, Y);

% parse_line(<<C, _/binary>>, _Acc, _X, _Y) ->
%     {error, {"bad char", C}}.

% relationPoint({X,Y}, HitPointList) ->
%     [{Hx-X, Hy-Y} || {Hx, Hy} <- HitPointList].
