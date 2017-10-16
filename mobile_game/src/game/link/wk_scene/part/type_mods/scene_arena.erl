%%%-------------------------------------------------------------------
%%% @author zlb
%%% @doc
%%%      竞技场
%%%      scene_mod
%%%      player_plugin
%% @end
%%%-------------------------------------------------------------------

-module(scene_arena).

-export
([
    % player_leave_arean_scene/1
]).

-include("inc.hrl").
-include("mod_name_def.hrl").
-include("scene.hrl").
-include("scene_type_mod.hrl").
-include("scene_player_plugin.hrl").
-include("scene_agent.hrl").
-include("load_spirit_attr.hrl").
-include("load_cfg_scene.hrl").

-include("scene_monster.hrl").
-define(pd_arean_start_time, pd_arean_start_time).
-define(DEL_SCENE_AFTER_SEC, 30).

-define(pd_ins_data, pd_ins_data). %场景初始化信息

type_id() -> ?SC_TYPE_ARENA.

init(#scene_cfg{run_arg = {ArenaType, Args}}) ->
    scene_player_plugin:set_player_plugin(?MODULE),
    case ArenaType of
        p2e ->
            Time = (misc_cfg:get_arena_p2e_time() + 8),
            scene_eng:start_timer(Time * 1000, ?MODULE, {p2e_time_out, Args});
        p2p ->
            Time = (misc_cfg:get_arena_p2p_time() + 9),
            scene_eng:start_timer(Time * 1000, ?MODULE, {p2p_time_out, Args}),
            scene_eng:start_timer(1000, ?MODULE, {add_hp_and_mp});
        multi_p2p ->
            Time = (misc_cfg:get_arena_multi_p2p_time() + 10),
            scene_eng:start_timer(Time * 1000, ?MODULE, {multi_p2p_time_out, Args}),
            scene_eng:start_timer(1000, ?MODULE, {add_hp_and_mp});
        compete ->
            Time = (misc_cfg:get_arena_p2p_time() + 8),
            scene_eng:start_timer(Time * 1000, ?MODULE, {compete_time_out, Args}),
            scene_eng:start_timer(1000, ?MODULE, {add_hp_and_mp});
        _ ->
            pass
    end,
    ok.

uninit(_) -> ok.

handle_msg({player_die}) ->
    ?INFO_LOG("scene_arena player_die"),
    case get(?pd_ins_data) of
        ?undefined -> put(?pd_ins_data, {1});
        {DieCount} -> put(?pd_ins_data, {DieCount + 1})
    end;

%% 客户端提交
handle_msg({client_sumbit, PlayerId, _PlayerPid}) ->
    case get(?pd_scene_id) of
        {_, ?scene_arena, ArenaInfo} ->
            case get(?pd_ins_data) of
                ?undefined ->
                    arena_server:player_kill_others(PlayerId, 0, 0, ArenaInfo, self());
                _ ->
                    arena_server:player_die(PlayerId, ArenaInfo)
            end;
        _E ->
            ?ERROR_LOG("bad arena type:~p", [_E])
    end;

handle_msg(Msg) -> ?ERROR_LOG("unknown msg ~p", [Msg]).

handle_timer(_, {p2e_time_out, Args}) ->
    arena_server:arena_timeout({p2e, Args});
handle_timer(_, {p2p_time_out, Args}) ->
    arena_server:arena_timeout({p2p, Args});
handle_timer(_, {multi_p2p_time_out, Args}) ->
    arena_server:arena_timeout({multi_p2p, {self(), Args}});
handle_timer(_, {compete_time_out, Args}) ->
    arena_server:arena_timeout({compete, Args});
handle_timer(_, {add_hp_and_mp}) ->
    PlayerIdxList = scene_player:get_all_player_idx(),
    lists:foreach(
        fun(Idx) when Idx > 0 ->
                case ?get_agent(Idx) of
                    #agent{hp = Hp, max_hp = MaxHp, mp = Mp, max_mp = MaxMp} = Agent ->
                        Agent1 = case Hp < MaxHp of
                            true ->
                                AddHp = trunc(max(MaxHp * 1 / 1000, 1)),
                                NewHp = min(Hp + AddHp, MaxHp),
                                Agent#agent{hp = NewHp};
                            _ ->
                                Agent
                        end,
                        Agent2 = case Mp < MaxMp of
                            true ->
                                AddMp = trunc(max(MaxMp * 10 / 1000, 1)),
                                NewMp = min(Mp + AddMp, MaxMp),
                                Agent1#agent{mp = NewMp};
                            _ ->
                                Agent1
                        end,
                        ?update_agent(Idx, Agent2);
                    _ ->
                        ignore
                end
        end,
        PlayerIdxList
    ),
    scene_eng:start_timer(1000, ?MODULE, {add_hp_and_mp});
handle_timer(_, Msg) ->
    ?ERROR_LOG("unknown msg ~p", [Msg]).

player_enter_scene(_Agent) ->
    ok.

player_leave_scene(_Agent = #agent{id = Id}) ->
    case get(?pd_scene_id) of
        _SceneId = {_, ?scene_arena, ArenaInfo} ->
            arena_server:player_leave(Id, {self(), ArenaInfo}),
            case scene_player:players_count() of
                1 ->
                    scene_eng:terminate_scene(normal);
                _C ->
                    ?INFO_LOG("player ~p leave remain player count ~p", [_Agent#agent.idx, _C]),
                    ok
            end;
        _SceneId ->
            ignore
    end,
    ok.

player_die(_Agent = #agent{id = _Id}, _Killer) ->
    ok.

player_kill_agent(#agent{id = KillerId}, #agent{id = DeadId, idx = DeadIdx}) ->
    case get(?pd_scene_id) of
        _SceneId = {_, ?scene_arena, ArenaInfo} ->
            arena_server:player_kill_others(KillerId, DeadId, DeadIdx, ArenaInfo, self());
        _ ->
            ignore
    end,
    ok.