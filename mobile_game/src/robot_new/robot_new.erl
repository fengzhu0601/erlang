%%-----------------------------------
%% @Module  : robot_new
%% @Author  : Holtom
%% @Email   : 
%% @Created : 2016.6.28
%% @Description: robot_new
%%-----------------------------------
-module(robot_new).

-export([
	init_robot/1,
	is_robot/1,
	get_robot_account/1,
	handle_msg/2
]).

-include("inc.hrl").
-include("game.hrl").
-include("player.hrl").
-include("virtual_db.hrl").
-include("player_data_db.hrl").

-define(ROBOT_ACCOUNT_HEAD, "lzqy_robot_").
-define(ROBOT_ID_BASE_NUM, 100000).


%% =============================================================================
%% API
%% =============================================================================
init_robot(RobotId) ->
    #{platform_id := _PlatformId, id := ServerId} = global_data:get_server_info(),
    erlang:put(pd_robot_id, RobotId),	%% 没有组合前的id
    erlang:put(?pd_platform_id, 5000),
    erlang:put(?pd_server_id, ServerId),
    User = list_to_binary(?ROBOT_ACCOUNT_HEAD ++ integer_to_list(?ROBOT_ID_BASE_NUM + RobotId)),
    {FinalId, IsCreate} = case virtual_db:lookup(?quick_db, ?account_tab, User, 0) of
    	[] ->
    		NewRobotId = create_role(RobotId),
    		At = #account_tab{
    			account_name = User, player_id = [{1, NewRobotId}],
    			platform_id = 5000, create_time = com_time:now(), password = <<>>
    		},
    		virtual_db:insert_new(?quick_db, ?account_tab, At, ?make_record_fields(account_tab)),
    		put(cur_account_info, At),
    		{NewRobotId, true};
		[#account_tab{player_id = []} = OldAt] ->
			NewRobotId = create_role(RobotId),
			At = OldAt#account_tab{player_id = [{1, NewRobotId}]},
			dbcache:update(?account_tab, At),
			put(cur_account_info, At),
			{NewRobotId, true};
    	[#account_tab{player_id = [{_, PlayerId} | _]} = At] ->
    		put(cur_account_info, At),
    		{PlayerId, false}
    end,
    case FinalId =/= 0 of
    	true ->
			account:enter_game(FinalId),
			case erase(?pd_entering_scene) of
				{SceneId, X, Y} ->
					scene_mng:enter_scene(SceneId, X, Y),
					robot_fsm:start(IsCreate);
				_E ->
					?ERROR_LOG("enter scene error :~p", [_E])
			end;
		_ ->
			ignore
	end.

is_robot(PlayerId) ->
	case is_integer(PlayerId) of
		true ->
			{PlatformId, _, _} = tool:un_playerid(PlayerId),
			PlatformId =:= 5000;
		_ ->
			false
	end.

get_robot_account(Id) ->
	list_to_binary(?ROBOT_ACCOUNT_HEAD ++ integer_to_list(?ROBOT_ID_BASE_NUM + Id)).

handle_msg(_, {navigation, Idx, Type, RetId, NpcId, PointList}) ->
	robot_fsm:navigation(Idx, Type, RetId, NpcId, PointList);

handle_msg(F, Msg) ->
    ?ERROR_LOG("unknow msg ~p ~p", [F, Msg]).

%% =============================================================================
%% PRIVATE
%% =============================================================================
create_role(RobotId) ->
	NewRobotId = tool:make_player_id(get(?pd_platform_id), get(?pd_server_id), RobotId),
    Career = case random:uniform(3) of
		3 -> 4;
		Num -> Num
	end,
	Name = get_robot_name(NewRobotId),
	?pd_new(?pd_name, Name),
	?pd_new(?pd_career, Career),
	player_mods_manager:create_mods(NewRobotId),
	put(pd_create_time, com_time:now()),
	NewRobotId.

get_robot_name(RobotId) ->
    Name = load_robot_cfg:get_random_robot_name(),
    case platfrom:register_name(Name, RobotId) of
        ok -> Name;
        _ -> get_robot_name(RobotId)
    end.