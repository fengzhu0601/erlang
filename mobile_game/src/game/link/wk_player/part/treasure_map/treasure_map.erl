%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 23. 七月 2015 下午2:49
%%%-------------------------------------------------------------------
-module(treasure_map).
-author("clark").

%% API
-export([
    create_treasure_map/1
    , dig_treasure/1]).

-include("inc.hrl").
-include("player.hrl").
-include("treasure_map.hrl").

%% 创建藏宝图
create_treasure_map(MapID) ->
    MapList = attr_new:get(?pd_treasure_map_list),
    NewTuple = #treasure_map_tab{id = MapID, x = 0, y = 0},
    attr_new:set(?pd_treasure_map_list, [NewTuple | MapList]).


%% 挖宝
dig_treasure(MapID) ->
    MapList = attr_new:get(?pd_treasure_map_list),
    case lists:keyfind(MapID, #treasure_map_tab.id, MapList) of
        false -> MapList;
        #treasure_map_tab{id = _TaskType, x = X, y = Y} ->
            PlayerX = 0,
            PlayerY = 0,
            Dt_x = erlang:abs(PlayerX - X),
            Dt_y = erlang:abs(PlayerY - Y),
            CanGetTreasure =
                if
                    Dt_x > 8 -> false;
                    Dt_y > 8 -> false;
                    true -> true
                end,
            case CanGetTreasure of
                true ->
                    %% 给奖励
                    %% 同步客户端
                    NewTaskList = lists:keydelete(MapID, #treasure_map_tab.id, MapList),
                    attr_new:set(?pd_treasure_map_list, NewTaskList);
                false -> ok
            end
    end.
