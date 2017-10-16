%%-----------------------------------
%% @Module  : robot_fsm
%% @Author  : Holtom
%% @Email   : 
%% @Created : 2016.6.29
%% @Description: robot_fsm
%%-----------------------------------
-module(robot_fsm).

-export([
	start/1,
	add_exp/1,
	robot_off_line/1,
	robot_level_up/1,
	state_loop/0,
	handle_state/2,
	enter_scene_and_loop/3,
	navigation/5,
	enter_new_scene_and_navigation/2
]).

-include("inc.hrl").
-include("game.hrl").
-include("player.hrl").
-include("scene.hrl").
-include("load_robot_cfg.hrl").
-include("load_career_attr.hrl").
-include("item_bucket.hrl").
-include("player_data_db.hrl").
-include("load_spirit_attr.hrl").

start(IsCreate) ->
	handle_on_off_line(),	%% 上下线处理
	online_add_exp(),		%% 定时加经验
	random_move(),			%% 随机走动一段距离
	state_loop(),
	case IsCreate of
		true ->		%% 给新角色加武器
			give_rand_equip(?val_item_type_weapon, 1, 1, 0);
		_ ->
			ignore
	end,
	ok.

handle_on_off_line() ->
	Level = get(?pd_level),
	case load_robot_cfg:get_level_cfg(Level) of
		Cfg when is_record(Cfg, robot_new_cfg) ->
			[OnlineTime] = util:get_val_by_weight(Cfg#robot_new_cfg.online_time, 1),
			[OfflineTime] = util:get_val_by_weight(Cfg#robot_new_cfg.offline_time, 1),
			timer_server:start(OnlineTime * 1000, {?MODULE, robot_off_line, [OfflineTime]});
		_ ->
			?ERROR_LOG("can not get cfg:~p", [Level]),
			ignore
	end.

online_add_exp() ->
	Level = get(?pd_level),
	Career = get(?pd_career),
	LevUpExp = case load_career_attr:lookup_role_cfg({Career, Level}) of
		RoleCfg when is_record(RoleCfg, role_cfg) ->
			RoleCfg#role_cfg.level_up_exp;
		_ ->
			0
	end,
	case load_robot_cfg:get_level_cfg(Level) of
		Cfg when is_record(Cfg, robot_new_cfg) ->
			{Time, [Min, Max]} = Cfg#robot_new_cfg.gain_exp,
			AddExp = trunc(LevUpExp * (random:uniform(max(1, Max - Min)) + Min) / 1000),
			timer_server:start(Time * 1000, {?MODULE, add_exp, [AddExp]});
		_ ->
			?ERROR_LOG("can not get cfg:~p", [Level]),
			ignore
	end.

random_move() ->
	scene_mng:send_msg({robot_random_move_msg, get(?pd_idx)}).

state_loop() ->
	Level = get(?pd_level),
	case load_robot_cfg:get_level_cfg(Level) of
		Cfg when is_record(Cfg, robot_new_cfg) ->
			StateList = Cfg#robot_new_cfg.state_list,
			NewList = [{State, Weight} || {State, Weight, _} <- StateList],
			[NewState] = util:get_val_by_weight(NewList, 1),
			% ?DEBUG_LOG("NewState:~p", [NewState]),
			{NewState, _, Contain} = lists:keyfind(NewState, 1, StateList),
			change_robot_state(get(pd_robot_id), get(pd_name), Level, NewState),
			timer_server:start(10 * 1000, {?MODULE, handle_state, [NewState, Contain]});
		_ ->
			?ERROR_LOG("can not get cfg:~p", [Level]),
			ignore
	end.

add_exp(AddExp) ->
	player:add_exp(AddExp),
	online_add_exp().

robot_off_line(OfflineTime) ->
	account:uninit(?TRUE),
	RobotId = get(pd_robot_id),
	RobotName = get(pd_name),
	case get(robot_delete) of
		true ->
			?DEBUG_LOG("robot delete, robot_id:~p, level:~p", [RobotId, get(?pd_level)]),
			robot_new_server:robot_delete(RobotId);
		_ ->
			robot_new_server:robot_online(RobotId, OfflineTime)
	end,
	robot_new_server:change_robot_state(RobotId, RobotName, get(?pd_level), off_line),
	self() ! {'ROBOT_OFFLINE'}.

robot_level_up(Level) ->
	case load_robot_cfg:get_level_cfg(Level) of
		Cfg when is_record(Cfg, robot_new_cfg) ->
			DeleteRoleList = Cfg#robot_new_cfg.delete_role,
			[{Level, Pro}] = lists:filter(
				fun({TempLev, _}) ->
						TempLev =:= Level
				end,
				DeleteRoleList
			),
			case random:uniform(100) =< Pro of
				true ->
					erlang:put(robot_delete, true);
				_ ->
					ignore
			end,
			change_equip(Cfg);
		_ ->
			?ERROR_LOG("can not get cfg:~p", [Level]),
			ignore
	end.

handle_state(1, NpcList) ->			%% 寻找npc
	NpcId = lists:nth(random:uniform(length(NpcList)), NpcList),
	IdList = scene_player:get_all_player_ids_by_scene(get(?pd_scene_id)),
	PlayerId = case lists:filter(fun(Id) -> Id =/= get(?pd_id) andalso robot_new:is_robot(Id) =:= false end, IdList) of
		List when length(List) >= 1 ->
			lists:nth(random:uniform(length(List)), List);
		_ ->
			0
	end,
	case PlayerId of
		0 ->
			state_loop();
		_ ->
			world:send_to_player_if_online(PlayerId, ?to_client_msg(scene_sproto:pkg_msg(?MSG_SCENE_NAVIGATION, {get(?pd_idx), get(?pd_id), 1, NpcId})))
	end,
	ok;
handle_state(2, _) ->				%% 随机走动
	random_move(),
	timer_server:start(10 * 1000, {?MODULE, state_loop, []}),
	ok;
handle_state(3, [TMin, TMax]) ->	%% 站立
	Time = random:uniform(max(1, TMax - TMin)) + TMin,
	timer_server:start(Time * 1000, {?MODULE, state_loop, []}),
	ok;
handle_state(4, [TMin, TMax]) ->	%% 进副本(消失)
	Time = random:uniform(max(1, TMax - TMin)) + TMin,
	{SceneId, X, Y} = case get(?pd_scene_id) =:= undefined orelse get(?pd_x) =:= undefined orelse get(?pd_y) =:= undefined of
		true ->
			{103, 23, 18};
		_ ->
			{get(?pd_scene_id), get(?pd_x), get(?pd_y)}
	end,
	scene_mng:leave_scene(),
	timer_server:start(Time * 1000, {?MODULE, enter_scene_and_loop, [SceneId, X, Y]}),
	ok;
handle_state(State, Contain) ->
	?ERROR_LOG("known state:~p, Contain:~p", [State, Contain]),
	ok.

enter_scene_and_loop(SceneId, X, Y) ->
	scene_mng:enter_scene(SceneId, X, Y),
	state_loop().

change_equip(Cfg) ->
	%% take off old equipment
	EquipBucket = game_res:get_bucket(?BUCKET_TYPE_EQM),
	GoodsList = goods_bucket:get_goods(EquipBucket),
	lists:foreach(
		fun(Item) ->
				attr_new:begin_sync_attr(),
				equip_system:try_take_off_equip(Item#item_new.id),
				attr_new:end_sync_attr()
		end,
		GoodsList
	),

	%% get equipment to put on
	[EquipNum] = util:get_val_by_weight(Cfg#robot_new_cfg.equip_num, 1),
	RandomList = get_random_list(EquipNum, [1, 2, 3, 4, 5, 6], []),
	PartList = [
		lists:nth(
			Index,
			[
				?val_item_type_helmet, 		% 头盔
				?val_item_type_clothes, 	% 衣服
				?val_item_type_sash,  		% 腰带
				?val_item_type_pants, 		% 裤子
				?val_item_type_shoes, 		% 鞋子
				?val_item_type_ring 		% 戒指
			]
		) || Index <- RandomList
	] ++ [?val_item_type_weapon],

	%% put on equipment
	lists:foreach(
		fun(Type) ->
				[Level] = util:get_val_by_weight(Cfg#robot_new_cfg.equip_level, 1),
				[Quality] = util:get_val_by_weight(Cfg#robot_new_cfg.equip_quality, 1),
				[QHLev] = util:get_val_by_weight(Cfg#robot_new_cfg.equip_qh_level, 1),
				give_rand_equip(Type, Level, Quality, QHLev)
		end,
		PartList
	),

	%% put on gems
	[GemNumMin, GemNumMax] = Cfg#robot_new_cfg.gem_num,
	GemNum = random:uniform(GemNumMax - GemNumMin + 1) + GemNumMin - 1,
	put_on_gems(GemNum, Cfg#robot_new_cfg.gem_quality, 0).

get_random_list(Count, OriList, RetList) ->
	case Count =:= 0 orelse OriList =:= [] of
		true ->
			RetList;
		_ ->
			Val = lists:nth(random:uniform(length(OriList)), OriList),
			get_random_list(Count - 1, lists:delete(Val, OriList), [Val | RetList])
	end.

give_rand_equip(Type, Level, _Quality, _QHLev) ->
	case load_equip_expand:get_rand_equip(get(?pd_career), Type, Level) of
		nil ->
			?DEBUG_LOG("can not find equip, ~p", [{Type, Level}]),
			pass;
		EquipBid ->
			BagBucket = game_res:get_bucket(?BUCKET_TYPE_BAG),
			goods_bucket:begin_sync(BagBucket),
			goods_bucket:end_sync(BagBucket#bucket_interface{goods_list = []}),
			gm_mng:add_res([{EquipBid, 1}]),
			NewBagBucket = game_res:get_bucket(?BUCKET_TYPE_BAG),
			GoodsList = goods_bucket:get_goods(NewBagBucket),
			Goods = lists:keyfind(EquipBid, 3, GoodsList),
			%% 鉴定
			goods_bucket:begin_sync(NewBagBucket),
			NewEquip = item_equip:authenticate(Goods),
			NewBucket = goods_bucket:update(NewBagBucket, NewEquip),
			goods_bucket:end_sync(NewBucket),
			%% 穿装备
			Pos = Type rem 100,
			equip_system:try_take_on_equip(Goods#item_new.id, Pos)
			% %% 强化
			% case load_equip_expand:get_qiang_hua_attr(EquipBid, QHLev) of
			% 	Attr when is_record(Attr, attr) ->
			% 		EquipBucket = game_res:get_bucket(?BUCKET_TYPE_EQM),
			% 		goods_bucket:begin_sync(EquipBucket),
			% 		NewItem = item_equip:set_strength_lvl(NewEquip, QHLev),
			% 		NewEquipBucket = goods_bucket:update(EquipBucket, NewItem),
			% 		goods_bucket:end_sync(NewEquipBucket);
			% 	_ ->
			% 		pass
			% end
	end.

put_on_gems(0, _, _) -> ok;
put_on_gems(_, _, 15) ->
	?ERROR_LOG("loop times lager than 15"),
	ok;
put_on_gems(GemNum, WeightList, Count) ->
	Bucket = game_res:get_bucket(?BUCKET_TYPE_EQM),
	GoodsList = goods_bucket:get_goods(Bucket),
	case GoodsList of
		[] -> ok;
		_ ->
			[Quality] = util:get_val_by_weight(WeightList, 1),
			case load_item:get_random_gem(Quality, get(?pd_level)) of
				none ->
					?ERROR_LOG("can not get gem, Quality:~p, Level:~p", [Quality, get(?pd_level)]),
					put_on_gems(GemNum, WeightList, Count + 1);
				GemId ->
					Gem = item_new:build(GemId, 1),
					Equip = lists:nth(random:uniform(length(GoodsList)), GoodsList),
					case equip_system:robot_embed_gem(Equip, Gem) of
						#item_new{} = NewEquip ->
							goods_bucket:begin_sync(Bucket),
							NewBucket = goods_bucket:update(Bucket, NewEquip),
							goods_bucket:end_sync(NewBucket),
							put_on_gems(GemNum - 1, WeightList, Count + 1);
						_ ->
							put_on_gems(GemNum, WeightList, Count + 1)
					end
			end
	end.

navigation(Idx, Type, RetId, NpcId, PointList) ->
	case Type of
		0 ->	%% 异常
			?ERROR_LOG("navigation error"),
			state_loop(),
			ignore;
		1 ->	%% 寻找npc
			scene_mng:send_msg({continue_move_msg, Idx, PointList}),
			{_, _, _, AllTime} = lists:foldl(
				fun({TX, TY, TZ}, {X, Y, _Z, TempTime}) ->
						NewTime = case TX =/= X andalso TY =/= Y of
                            true ->
                                trunc((abs(TX - X) + abs(TY - Y)) / 2) * ?next_45_angle_step_time(150) + TempTime;
		                    _ ->
		                        (abs(TX - X) + abs(TY - Y)) * ?next_step_time(150) + TempTime
		                end,
		                {TX, TY, TZ, NewTime}
		        end,
		        {get(?pd_x), get(?pd_y), 0, 0},
		        PointList
			),
			timer_server:start(AllTime + 200, {?MODULE, state_loop, []});
		2 ->	%% 寻找传送门
			scene_mng:send_msg({continue_move_msg, Idx, PointList}),
			{_, _, _, AllTime} = lists:foldl(
				fun({TX, TY, TZ}, {X, Y, _Z, TempTime}) ->
						NewTime = case TX =/= X andalso TY =/= Y of
		                    true ->
		                        trunc((abs(TX - X) + abs(TY - Y)) / 2) * ?next_45_angle_step_time(150) + TempTime;
		                    _ ->
		                        (abs(TX - X) + abs(TY - Y)) * ?next_step_time(150) + TempTime
		                end,
		                {TX, TY, TZ, NewTime}
		        end,
		        {get(?pd_x), get(?pd_y), 0, 0},
		        PointList
			),
			timer_server:start(AllTime + 200, {?MODULE, enter_new_scene_and_navigation, [RetId, NpcId]})
	end.

enter_new_scene_and_navigation(DoorId, NpcId) ->
	case load_cfg_scene_portal:get_portal_position(DoorId) of
		{_, _, _, _, _, SceneId, X, Y} ->
			scene_mng:enter_scene(SceneId, X, Y),
			handle_state(1, [NpcId]);
		_ ->
			?ERROR_LOG("can not get door info, door_id:~p", [DoorId])
	end.

change_robot_state(RobotId, Name, Level, NewState) ->
	robot_new_server:change_robot_state(RobotId, Name, Level, NewState).