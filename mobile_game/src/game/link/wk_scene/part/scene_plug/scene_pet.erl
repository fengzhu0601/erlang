%%% coding:utf-8
%%%-------------------------------------------------------------------
%%% @author wcg
%%% @doc 管理宠物模块 1.目前实现的功能：在城镇场景中宠物跟随玩家
%%	a.进入场景时，生成宠物。
%%  b.在场景进程针对每一个宠物做1秒倒计时，每隔1s同步一次宠物和角色之间的位置
%%%-------------------------------------------------------------------

-module(scene_pet).

-include("inc.hrl").
-include("game.hrl").
-include("load_spirit_attr.hrl").

% -include("pet.hrl").
-include("pet_new.hrl").

-include("scene.hrl").
-include("scene_agent.hrl").
-include("scene_monster.hrl").
-include("scene_mod.hrl").


-export([add_buff/3]).

-define(MODULE_PET_AI, pet_ai).

-define(PET_FOLLOW_RATE, 1000).

-define(PET_FOLLOW_X, 4).

init(_) -> ok.

uninit(_) -> ok.

handle_msg({?enter_scene_msg, PlayerNamePkg, PlayerIdx, X, Y, Pet}) ->
    PetCfgId = Pet#pet_new.pet_id,
    {OffsetX, OffsetY, _OffsetZ} = load_cfg_new_pet:get_pet_new_offset_by_id(PetCfgId),
    Agent = init_agent(self(), PlayerNamePkg, PlayerIdx, max(X+OffsetX, 0), max(Y+OffsetY, 0), 1, 1, Pet),
    put(?fight_pet_new_on_scene, Pet),
    enter_scene(Agent),
    case load_cfg_scene:is_normal_scene(get(?pd_scene_id)) of
        ?true ->
            start_timer(PlayerIdx);
        _ ->
            pass
    end;

handle_msg({?leave_scene_msg, PlayerIdx}) ->
    case ?get_agent(get(?pet_idx(PlayerIdx))) of
        ?undefined -> 
            ok;
        Agent ->
            erase(?fight_pet_new_on_scene),
            scene_agent:leave_scene(Agent)
    end;

%%
%% %% @doc agent move 更新宠物跟随.
%% handle_msg({?pet_msg_move, PlayerIdx, PlayerX,Y,H, MoveVector}) ->
%% 	{Vx, _Vy, _Vh} = MoveVector,
%% 	{X, Direction} = if
%% 			   Vx >= 0 -> {PlayerX - ?PET_FOLLOW_X, ?D_R};
%% 			   true -> {PlayerX + ?PET_FOLLOW_X, ?D_L}
%% 		   end,
%% 	?ERROR_LOG( "111:~w~n", [ [X, Direction] ] ),
%% 	Idx = get(?pet_idx(PlayerIdx)),
%% 	case ?get_agent(Idx) of
%% 		?undefined ->
%% 			?ERROR_LOG("can not find agent ~p", [Idx]);
%% 		#agent{stiff_state =?ss_stiff} ->
%% 			?ERROR_LOG("player idx ~p stiff can not move", [Idx]);
%% 		_A ->
%% 			?if_(_A#agent.state =:= ?ss_beat_back_stiff,
%% 				?ERROR_LOG("player idx ~p back_stiff_st can not move", [_A#agent.idx])),
%%
%% 			case scene_map:is_walkable(X,Y) of
%% 				?true ->
%% 					A = scene_aoi:stop_moving_and_sync_position(_A#agent{d = Direction}, {X, Y, H}),
%% 					scene_aoi:move_with_vector_and_notify(A, {Vx, _Vy, H});
%% 				?false -> %% not is_walkable
%% 					?ERROR_LOG("idx ~p move not is_walkable ~p", [Idx, {X, Y}])
%% 			end
%% 	end;
%%
%% handle_msg({?pet_msg_move_stop, PlayerIdx, {PlayerX, Y, H}}) ->
%% 	Idx = get(?pet_idx(PlayerIdx)),
%% 	case ?get_agent(Idx) of
%% 		?undefined -> ok;
%% 		#agent{x = Ox, y = Oy, d = Direction} = _A ->
%% 			X = case Direction of
%% 					?D_R -> PlayerX - ?PET_FOLLOW_X;
%% 					?D_L -> PlayerX + ?PET_FOLLOW_X
%% 				end,
%% 			?ERROR_LOG( "222:~w~n", [ [X, Direction] ] ),
%% 			case scene_map:is_walkable(X, Y) of
%% 				?true ->
%% 					A = scene_aoi:stop_if_moving(_A),
%% 					case {X - Ox, Y - Oy} of
%% 						{0, 0} ->
%% 							?debug_log_scene_player("idx:~p stoppp move oo ~p ", [Idx, {X, Y}]),
%% 							scene_aoi:broadcast_view_me_agnets_lazy(A, fun() ->
%% 								scene_sproto:pkg_msg(?MSG_SCENE_MOVE_STOP, {Idx, X, Y, H}) end);
%% 						{Dx, Dy} ->
%% 							?ifdo(abs(Dx) >= 5 orelse abs(Dy) >= 5,
%% 								?ERROR_LOG("idx ~p scene move, but xy diff >= 5! ~p", [Idx, {Dx, Dy}])),
%% 							large_move(A, X, Y, ?move_stop)
%% 					end;
%% 				?false ->
%% 					?ERROR_LOG("idx ~p move_stop not is_walkable ~p", [Idx, {X, Y}])
%% 			end
%%
%% 	end;
%%
%% handle_msg({?pet_switch_move_mode_msg, PlayerIdx, Mode}) ->
%% 	Idx = get(?pet_idx(PlayerIdx)),
%% 	case ?get_agent(Idx) of
%% 		?undefined ->
%% 			?debug_log_scene_player("can not find idx ~p", [Idx]);
%% 		#agent{move_vec=MV}=A ->
%% 			#agent{attr=PlayerAttr} = ?get_agent(PlayerIdx),
%% 			Current = MV#move_vec.x_speed,
%%
%% 			Speed = ?if_else(Mode =:= ?MT_MOVE,
%% 				PlayerAttr#attr.move_speed,
%% 				PlayerAttr#attr.run_speed),
%%
%% 			?if_(Current =/= Speed,
%% 				?update_agent(Idx, A#agent{move_vec=MV#move_vec{x_speed=Speed, y_speed=Speed}}),
%% 				scene_aoi:broadcast_view_me_agnets(A, scene_sproto:pkg_msg(?MSG_SCENE_PLAYER_SWITCH_MOVE_MODE, {Idx, Mode})))
%% 	end;

handle_msg(Msg) ->
    ?ERROR_LOG("unknown msg ~p", [Msg]).


%% @doc 1.宠物与人物间隔4个格子
%%		2.正整数 当人物x-宠物x大于4表明是向右方向， 人物x-宠物x小于4表明人物换方向
%%      3.负数   当人物x-宠物x小于-4表明是向左方向， 人物x-宠物x大于-4表明人物换方向
handle_timer(_, {sync_pet_position, PlayerIdx}) ->
    PlayerAgent = ?get_agent(PlayerIdx),
    IsSyncPet = case PlayerAgent of
        #agent{} ->
            PlayerX = PlayerAgent#agent.x,
            PlayerY = PlayerAgent#agent.y,
            Idx = get(?pet_idx(PlayerIdx)),
            case ?get_agent(Idx) of
                ?undefined ->
                    ?ERROR_LOG("can not find agent ~p", [Idx]),
                    error;
                #agent{stiff_state = ?ss_stiff} ->
                    ?ERROR_LOG("player idx ~p stiff can not move", [Idx]),
                    error;
                _A ->
                    PetX = _A#agent.x,
                    PetY = _A#agent.y,
                    MvX = PlayerX - PetX,
                    {_D, MoveX} = if
                        MvX > ?PET_FOLLOW_X -> {?D_R, MvX - ?PET_FOLLOW_X};
                        MvX =:= -?PET_FOLLOW_X -> {_A#agent.d, 0};
                        MvX =:= ?PET_FOLLOW_X -> {_A#agent.d, 0};
                        (0 < MvX) andalso (MvX =< ?PET_FOLLOW_X) ->
                        {?D_L, MvX + ?PET_FOLLOW_X};
                        (-?PET_FOLLOW_X =< MvX) andalso (MvX =< 0) ->
                        {?D_R, MvX - ?PET_FOLLOW_X};
                        MvX < -?PET_FOLLOW_X -> {?D_L, MvX + ?PET_FOLLOW_X}
                    end,
                    {MoveY, MoveH} = {PlayerY - PetY, 0},
                    case {MoveX, MoveY, MoveH} of
                        {0, 0, 0} -> ok;
                        _ ->
                            case scene_map:is_walkable(PetX + MoveX, PetY + MoveY) of
                                ?true ->
                                    pl_util:move(_A, {PetX, PetY, 0, MoveX, MoveY});
                                ?false -> %% not is_walkable
                                    pass
                                    % ?ERROR_LOG("idx ~p move not is_walkable ~p", [Idx, {PlayerX + MoveX, PetY}])
                            end
                    end,
                    ok
            end;
        _ -> error
    end,
    case IsSyncPet of
        ok -> start_timer(PlayerIdx);
        error -> ok
    end;

handle_timer(_Ref, _Msg) ->
    ?ERROR_LOG("handle_timer/2: ~p~n", [[_Ref, _Msg]]).

init_agent(Pid, PlayerNamePkg, PlayerIdx, X, Y, R, Dir, Pet) ->
    % ?DEBUG_LOG("scene pet-----------------------------------:~p",[Pet]),
    % ?DEBUG_LOG("attr--------------------------------------:~p",[load_spirit_attr:lookup_attr(Pet#pet_new.attr_new)]),
    AiFlag = case load_cfg_scene:is_normal_scene(get(?pd_scene_id)) of
        ?true ->
            0;
        _ ->
            1
    end,
    Party = case ?get_agent(get(?pet_idx(PlayerIdx))) of
        ?undefined -> 
            1;
        Agent -> 
            Agent#agent.party
    end,
    #agent{
        pid = Pid,
        id = Pet#pet_new.pet_id,
        fidx = PlayerIdx,
        type = ?agent_pet,
        state = ?st_stand,
        d = Dir,
        h = 0,
        stiff_state = ?none,
        x = X,
        y = Y,
        rx = R, 
        ry = R,
        max_hp = 100,
        hp = 100,
        %attr = load_spirit_attr:lookup_attr(Pet#pet_new.attr),
        attr = Pet#pet_new.attr_new,
        level = load_cfg_new_pet:get_pet_level(Pet#pet_new.pet_level),
        pk_info = ?make_monster_pk_info(-1),
        move_vec = move_util:create_move_vector(erlang:make_tuple(4, 115)),
        skill_modifies = load_cfg_new_pet:get_pet_skill_modify(Pet#pet_new.pet_id),
        skill_modifies_effects = [],
        party = Party,
        ai_flag = AiFlag,
        %%type:u8  id:player_id  vassalageid:player_id##隶属哪个玩家的
        %%name:sstr  advance:u8  facade:u32
        %%   old ---------------------------------------------------------------------
        %enter_view_info = <<?MT_PET, (Pet#pet_new.id):32, PlayerNamePkg/binary, 
        %                    (byte_size(Name)), Name/binary,
        %                    (Pet#pet_new.have_advance_count), 
        %                    (Pet#pet_new.facade):32>>, %% TODO 0 is BuffSIze
        %% old -----------------------------------------------------------------------
        enter_view_info = <<
            ?MT_PET, 
            (Pet#pet_new.pet_id):32, 
            PlayerNamePkg/binary, 
            (Pet#pet_new.pet_advance),
            PlayerIdx:16/signed
        >>,
        ex = #m_ex{ai_mod = pet_ai}
    }.

enter_scene(#agent{id = PetId, fidx = PlayerIdx} = Agent) ->
    Idx = scene_monster:take_monster_idx(),
    put(?pet_idx(PlayerIdx), Idx),
    NewAgent = scene_agent_factory:build_agent(Agent#agent{idx = Idx, x = Agent#agent.x, y = Agent#agent.y}),
    case load_cfg_scene:is_normal_scene(get(?pd_scene_id)) of
        ?true -> pass;
        _ -> skill_modify_util:init_pet_halo_buff(PetId, NewAgent)
    end,
    NewAgent.

%% init_skill(_Idx, _Skills) ->
%% 	ok.

%% large_move(#agent{idx=Idx, pid=_Pid, h=H}=_A, X, Y, Action) ->
%% 	A= scene_aoi:stop_if_moving(_A),
%%
%% 	if A#agent.x =:= X andalso A#agent.y =:= Y ->
%% 		A2=A;
%% 		?true ->
%% 			A2 = scene_aoi:move_agent(A, {X,Y, H})
%% 	end,
%%
%% 	case Action of
%% 		?move_stop->
%% 			scene_aoi:broadcast_view_me_agnets(A2, scene_sproto:pkg_msg(?MSG_SCENE_MOVE_STOP, {Idx, X, Y, H}));
%% 		?large_move ->
%% 			scene_aoi:broadcast_view_me_agnets_and_me(A2, scene_sproto:pkg_msg(?MSG_SCENE_LARGE_MOVE, {Idx, X, Y}));
%% 		_ ->
%% 			?ERROR_LOG("idx ~p large move bad reason ~p", [Idx, Action])
%% 	end,
%% 	A2.

add_buff([], _A, _ReleaseA) -> ok;
add_buff(BuffList, A, _ReleaseA) -> ?send_mod_msg(A#agent.pid, buff_mng, {add_buff, BuffList}).

start_timer(PlayerIdx) -> scene_eng:start_timer(1 * 1000, ?MODULE, {sync_pet_position, PlayerIdx}).
