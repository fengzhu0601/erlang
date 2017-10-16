%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 08. 九月 2015 下午2:46
%%%-------------------------------------------------------------------
-module(scene_agent_factory).
-author("clark").

%% API
-export(
[
    build_agent/1
    % , build_player/13
    % , build_player/14
    % , build_player/16
    , build_player/1
    , build_player/2
    , try_build_bullet/3
    , try_build_bullet/4
]).

-include("inc.hrl").
-include("scene_agent.hrl").
-include("skill_struct.hrl").
-include("load_spirit_attr.hrl").
-include("load_scene_monster.hrl").
-include("buff_system.hrl").

build_agent(Agent) ->
    %% 老版游戏架构都是以玩家对象为所有对象通用的， 优化成各个对象有各个对象的结构改动太多， 目前先不动这块并且把玩家对象定位为地图对象。
    %% 日后地图对象会做为地图上各种实体的基类
    map_agent:create(Agent).

build_player(Agent) ->
    build_player(Agent, 0).
build_player(Agent, TeamId) ->
    Idx = scene_agent:take_player_idx(),
    PlayerId = Agent#agent.id,
    put(?player_idx(PlayerId), Idx),
    [PkMode | _] = get(?pd_cfg_pk_modes),
    % NewTeamId = case PkMode of
    %     4 ->
    %         TeamId;
    %     _ ->
    %         main_ins_team_mod:get_player_team_id(PlayerId)
    % end,
    % PkInfo = ?make_player_pk_info(PkMode, PlayerId, NewTeamId, 0),
    PkInfo = ?make_player_pk_info(PkMode, PlayerId, TeamId, 0),
    Attr = Agent#agent.attr,
    NewAgent = Agent#agent{
        idx = Idx,
        pk_info = PkInfo,
        id = PlayerId,
        %type = ?agent_player,
        h = 0,
        move_vec = move_util:create_move_vector(erlang:make_tuple(4, Attr#attr.run_speed))
    },
    map_agent:create(NewAgent).

%% try_build_bullet(#agent{d = Dir}=A, #skill_cfg{release_objs = []} = SkillCfg) ->
%%     try_build_bullet(A, SkillCfg, Dir).
try_build_bullet(#agent{d = Dir} = A, SkillId, #skill_cfg{} = SkillCfg) ->
    try_build_bullet(A, SkillId, SkillCfg, Dir).
try_build_bullet(Agent, SkillId, #skill_cfg{id = FromSkillId, release_objs = Objs} = _SkillCfg, Dir) when is_integer(Dir) ->
    Objs1 = if
        [] =/= Objs -> Objs;
        true -> load_segments:get_emits(FromSkillId)
    end,
    lists:foreach(
        fun
            (ObjId) ->
                Segments = load_cfg_skill:get_segments_by_emitid(ObjId),
                % 添加龙纹触发的buff
                lists:foreach(
                    fun(_SegmentId) ->
                        buff_system:apply_init(Agent, SkillId)
                    end, Segments),
                ?INFO_LOG("emit skills:~p", [load_cfg_skill:get_segments_by_emitid(ObjId)]),
                case load_cfg_skill:lookup_skill_release_obj_cfg(ObjId) of
                    ?none ->
                        ?ERROR_LOG("error in release_obj ~p", [ObjId]);
                    #skill_release_obj_cfg{id = MonsterBid, size = Box} = BuildCfg ->
                        case load_scene_monster:lookup_monster_new_cfg(MonsterBid) of
                            ?none ->
                                ?ERROR_LOG("error in monster_bid ~p", [MonsterBid]);
                            MonsterCfg ->
                                case load_cfg_emits:get_skill(MonsterBid) of
                                    ?none ->
                                        ?ERROR_LOG("error in monster_bid11 ~p", [MonsterBid]);
                                    EmitsCfg ->
%%                                         ?INFO_LOG("bullet_agent ~p",[EmitsCfg]),
                                        BulletAgent = bullet_agent:build(Agent, MonsterCfg, BuildCfg, Dir, Box, FromSkillId),
                                        pl_util:play_bullet_skill(BulletAgent, SkillId, {EmitsCfg})
                                end
                        end
                end
        end,
        Objs1
    );
try_build_bullet(Agent, _SkillId, #skill_cfg{id = FromSkillId}, {EmitsId, X, Y, H, Dir}) ->
    case load_cfg_skill:lookup_skill_release_obj_cfg(EmitsId) of
        ?none ->
            ?ERROR_LOG("error in release_obj ~p", [EmitsId]);
        #skill_release_obj_cfg{id = MonsterBid, size = Box} = BuildCfg ->
            case load_cfg_emits:get_skill(MonsterBid) of
                ?none ->
                    ?ERROR_LOG("error in monster_bid11 ~p", [MonsterBid]);
                _EmitsCfg ->
                    _BulletAgent = bullet_agent:buile_new(Agent, MonsterBid, BuildCfg#skill_release_obj_cfg{born_point = {X, Y, H}}, Dir, Box, FromSkillId)
            end
    end.