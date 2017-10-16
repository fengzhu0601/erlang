%%%-------------------------------------------------------------------
%%% @author zl

%%% @doc 组队场景类型
%%%
%%% @end
%%%-------------------------------------------------------------------

-module(scene_team).

-include("inc.hrl").
-include("scene.hrl").
-include("scene_type_mod.hrl").
-include("load_cfg_scene.hrl").
-include("scene_player_plugin.hrl").
-include("scene_agent.hrl").
-include("scene_event.hrl").

-define(XML_FILE_DIR, "./data/scene/"). 

type_id() -> ?SC_TYPE_TEAM.


init(Cfg) ->
    ?assert(?SC_TYPE_TEAM =:= Cfg#scene_cfg.type),
    {SceneId, _, _} = Cfg#scene_cfg.id,
    XmlFile = ?XML_FILE_DIR ++ "scene_" ++ integer_to_list(SceneId) ++ ".xml",
    SceneProcessList = xml_parse:get_process_list(XmlFile),
    NewSceneProcessList = add_default_fun(SceneProcessList),
    ?pd_new(pd_process_list, NewSceneProcessList),
    ?pd_new(pd_state, 1),
    ?pd_new(pd_is_monsters_flush_ok, false),
    ?pd_new(pd_all_lock_area_list, []),
    scene_player_plugin:set_player_plugin(?MODULE),
    ok.

uninit(_) ->
    ok.

player_enter_scene(_Agent) ->
    self() ! {event, ?PLAYER_ENTER_SCENE},
    ok.

player_leave_scene(_Agent) ->
    case scene_player:players_count() of
        1 ->
            scene_eng:terminate_scene(normal);
        _C ->
            ok
    end.

player_die(_Self, _Killer) ->
    ?DEBUG_LOG("What the fuck ......die die die!!!"),
    ok.

player_kill_agent(_Self, DealAgent) ->
    case DealAgent#agent.idx < 0 of
        true ->
            ?DEBUG_LOG("monster was killed!!!"),
            self() ! {event, ?PLAYER_KILL_MONSTER};
        _ ->
            ignore
    end,
    ok.

handle_msg({start_next_scene_id, PlayerPid, _Idx, NextSceneId, IsLastScene}) ->
    start_next_scene( PlayerPid, NextSceneId, IsLastScene);

handle_msg(Msg) ->
    ?err({unknown_msg, Msg}).

handle_timer(_, Msg) ->
    ?err({unknown_timer, Msg}).

add_default_fun(PList) ->
    [{StateId, [{?PLAYER_MOVEING, 0, [], [{can_do_lock_area, []}]} | EventList]} || {StateId, EventList} <- PList].

start_next_scene(PlayerPid, NextSceneId, _IsLastScene) ->
    {_, ?scene_team, {team, TeamId}} = get(?pd_scene_id),
    NextMakeScene = scene:make_scene_id(?SC_TYPE_TEAM, team, NextSceneId, TeamId),
    Cfg = load_cfg_main_ins:lookup_main_ins_cfg(NextSceneId),
    case main_ins_mod:can_enter_ins(NextMakeScene, Cfg) of
        true ->
            main_ins:remove_scene(get(?pd_scene_id)),
            case scene_sup:start_client_scene(NextMakeScene, ?false, undefined) of
                {error, W} ->
                    ?ERROR_LOG("start next scene ~p", [W]);
                _Pid ->
                    main_ins:insert_scene(NextMakeScene),
                    % {StartTime, DieCount1, KillMonsterCount, KillBossCount} = get(?pd_ins_data),
                    % Pid ! ?scene_mod_msg(?MODULE,
                    %     {
                    %         init_room_data,
                    %         {
                    %             StartTime,
                    %             DieCount1 + deal_count(),
                    %             KillMonsterCount + kill_min_monster_count(),
                    %             KillBossCount + kill_boss_monster_count()
                    %         },
                    %         IsLastScene
                    %     }),
                    PlayerPid ! ?mod_msg(main_instance_mng, {start_next_scene, NextMakeScene})
            end;
        false -> scene_eng:terminate_scene(normal)
    end.