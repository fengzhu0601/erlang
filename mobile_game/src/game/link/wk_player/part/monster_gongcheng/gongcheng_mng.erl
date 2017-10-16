-module(gongcheng_mng).

-include_lib("pangzi/include/pangzi.hrl").


-include("inc.hrl").
-include("scene.hrl").

-include("player.hrl").
-include("handle_client.hrl").
-include("player_mod.hrl").
-include("team_struct.hrl").
-include("main_ins_struct.hrl").
-include("load_cfg_main_ins.hrl").
-include("load_cfg_gwgc.hrl").

-export([
    notice_members/2,
    start_activity/0,
    stop_activity/0
]).


start_activity() ->
    case gwgc_server:start_link() of
        {ok, Pid} ->
            pass;
        _E ->
            todo
    end.

stop_activity() ->
    case whereis(gwgc_server) of
        undefined -> 
            pass;
        Pid -> 
            Pid ! stop_gwgc
    end,
    ok.

is_player_on_normal_scene([]) ->
    ?true;
is_player_on_normal_scene([M | T]) ->
    PlayerId = M#team_member.id,
    case scene_mng:lookup_player_scene_id_if_online(PlayerId) of
        offline ->
            ?false;
        SceneId ->
            case load_cfg_scene:is_normal_scene(SceneId) of
                ?false ->
                    ?false;
                _ ->
                    is_player_on_normal_scene(T)
            end
    end.
start(NpcId) ->
    %?ifdo(gwgc_server:get_npc_status(NpcId), ?return_err(?ERR_GWGC_NOT_CAN_FIGHT)),
    SceneId = load_cfg_scene:get_config_id(get(?pd_scene_id)),
    try
        gen_server:call(gwgc_server, {get_npc_status, NpcId, SceneId}, 2000)
    of
        ?true ->
            case npc:get_npc_can_challenge(NpcId) of
                ?false ->
                    ?return_err(?ERR_NOT_TEAM_MAIN_INS);
                MainInsId ->
                    TeamId = get(?pd_team_id),
                    %?DEBUG_LOG("MainInsId------:~p---TeamId-----------:~p",[MainInsId, TeamId]),
                    case team_mod:get_team_info_by_leader(TeamId) of
                        {?true, TeamInfo} ->
                            case is_player_on_normal_scene(TeamInfo#team.members) of
                                ?true ->
                                    case room_system:get_gwgc_pid(NpcId, TeamId) of
                                    %case room_system:get_gwgc_pid(NpcId, TeamId) of
                                        Pid when is_pid(Pid) ->
                                            gwgc_server:update_npc_status(NpcId, 1),
                                            gwgc_server:add_team_fighting_data(TeamId, {NpcId, SceneId}),
                                            gwgc_server:add_team_fighting_data({NpcId, SceneId}, TeamId),
                                            notice_members(TeamInfo#team.members, ?mod_msg(gongcheng_mng, {gwgc_start, {TeamInfo, MainInsId, NpcId, Pid}}));
                                        _Err ->
                                            ?ERROR_LOG("_Err--------------------------------:~p",[_Err])
                                    end;
                                ?false ->
                                    ?return_err(?ERR_GWGC_PLAYER_NORMAL_SCENE)%% 
                            end;
                        ?false ->
                            ?return_err(?ERR_TEAM_NOT_LEADER)
                    end
            end;
        _O ->
            ?ERROR_LOG("_O----------------------------:~p",[_O]),
            ?return_err(?ERR_GWGC_NOT_CAN_FIGHT)
    catch
        E:W ->
            pass
    end.
    
notice_members(TeamInfo, Msg) when is_record(TeamInfo, team) ->
    MemberS = TeamInfo#team.members,
    [world:send_to_player_if_online(M#team_member.id, Msg) || M <- MemberS];
notice_members(MemberS, Msg) ->
    [world:send_to_player_if_online(M#team_member.id, Msg) || M <- MemberS].



create_mod_data(_SelfId) ->
    ok.


load_mod_data(_PlayerId) ->
    ok.

init_client() ->
    ignore.

view_data(Msg) ->
    Msg.

online() ->
    ok.

offline(_PlayerId) ->
    ok.

save_data(_) -> ok.

load_db_table_meta() -> [].

handle_client({Pack, Arg}) ->
    handle_client(Pack, Arg).

handle_client(?MSG_GONGCHENG_STAR, {NpcId, 1}) ->
    ?DEBUG_LOG("NpcId------------:~p",[NpcId]),
    start(NpcId);

handle_client(?MSG_GONGCHENG_STAR, {NpcId, 2}) ->
    case get(?pd_team_id) of
        ?undefined ->
            case npc:get_npc_can_challenge(NpcId) of
                ?false ->
                    ?return_err(?ERR_NOT_TEAM_MAIN_INS);
                MainInsId ->
                    SceneId = load_cfg_scene:get_config_id(get(?pd_scene_id)),
                    case gwgc_server:npc_is_look(NpcId, SceneId) of
                        ?true ->
                            TeamId = gwgc_server:get_team_fighting_data({NpcId, SceneId}),
                            %Pid = room_system:get_room_pid_by_cfg(NpcId, TeamId),
                            Pid = room_system:get_gwgc_pid(NpcId, TeamId),
                            ?DEBUG_LOG("MSG_GONGCHENG_STAR-------------------:~p",[Pid]),
                            {X, Y} = load_cfg_scene:get_enter_pos_by_cfg(MainInsId),
                            player_room_part:begin_enter_room_by_client({Pid, MainInsId, 2, X, Y, ?D_R});
                        ?false ->
                            ?return_err(?ERR_GWGC_NOT_LOOK)
                    end
            end;
        _T ->
            ?ERROR_LOG("_T--------------------------:~p",[_T]),
            ?return_err(?ERR_GWGC_NOT_LOOK)
    end;

handle_client(Mod, Msg) ->
    ?ERROR_LOG("no known msg Mod:~p Msg:~p", [gem_sproto:to_s(Mod), Msg]).

handle_msg(_FromMod, {gwgc_start, {TeamInfo, MainInsId, NpcId, Pid}}) ->
    put(?main_instance_id_ing, MainInsId),
    put(?pd_figthing_npc_id, NpcId),
    %Pid = room_system:get_room_pid_by_cfg(MainInsId, TeamInfo#team.id),
    %?DEBUG_LOG("playerid--:~p------Pid---:~p---teamid----:~p---NpcId---:~p",[get(?pd_id), Pid, TeamInfo#team.id, NpcId]),
    {X, Y} = load_cfg_scene:get_enter_pos_by_cfg(MainInsId),
    player_room_part:begin_enter_room_by_client({Pid, MainInsId, 1, X, Y, ?D_R}),
    MainInsCfg = load_cfg_main_ins:lookup_main_ins_cfg(MainInsId),
    %?DEBUG_LOG("MainInsCfg----------------------:~p",[MainInsCfg]),
    achievement_mng:init_instance_ac(MainInsCfg#main_ins_cfg.stars, []);


handle_msg(FromMod, Msg) ->
    ?ERROR_LOG("~p recv a unknown msg ~p from ~p", [?pname(), Msg, FromMod]).

handle_frame(_) -> 
    ok.
