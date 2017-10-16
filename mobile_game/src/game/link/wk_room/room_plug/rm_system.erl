%%%-------------------------------------------------------------------
%%% @author fengzhu
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 13. 四月 2016 下午12:09
%%%-------------------------------------------------------------------
-module(rm_system).
-author("fengzhu").

%% API
-export
([
    check_empty_room/1
    , on_nobody_in_room/1
    , init_droplist_for_playerId/1
]).

-include("inc.hrl").
-include("player.hrl").
-include("porsche_gearbox.hrl").
-include("scene_agent.hrl").




%% 检查房间的定时器
-define(room_system_timer, '@room_system_timer@').

%% 检查房间中是否还有玩家存在
on_nobody_in_room(Dt) ->
%%    ?INFO_LOG("检查房间中是否还有玩家存在"),
    PlayerList = scene_player:get_all_player_ids(),
%%    ?INFO_LOG("On_nobody_in_room,~p",[PlayerList]),
    case erlang:length(PlayerList) of
        %% 副本中没有玩家了
        0 ->
            ?INFO_LOG("场景中没有玩家了"),
            Ret = get(?room_system_timer),
            timer_server:stop(Ret),
            put(?room_system_timer, nil),

            %% 副本中没玩家了就关闭副本
            room_system:release_room();

        _ ->
            Ret = get(?room_system_timer),
            timer_server:stop(Ret),
            NewRet = timer_server:start(Dt * 1000, {?MODULE, on_nobody_in_room, [Dt]}),
            put(?room_system_timer, NewRet),
            ok
    end.

%% 每隔Dt时间检查一次
check_empty_room(Dt) ->
    Ret = timer_server:start(Dt * 1000, {?MODULE, on_nobody_in_room, [Dt]}),
    put(?room_system_timer, Ret).

%% 检测到怪物死亡事件，给场景中的所有玩家发送掉落物品的消息
init_droplist_for_playerId(SceneId) ->
%%    ?INFO_LOG("==========================SceneId:~p", [SceneId]),

    ?INFO_LOG("接收怪物死亡消息"),
    Drop =
        fun(Args) ->
%%            Killer = Args#monster_die.killer,
            Die = Args#monster_die.die,
            X = Die#agent.x,
            Y = Die#agent.y,
            MonsterId = Die#agent.id,
%%            ?INFO_LOG("==========================MonsterId:~p", [MonsterId]),

            %% 副本中的所有玩家
            PlayerList = scene_player:get_all_player_ids(),
%%            ?INFO_LOG("==========================PlayerList:~p", [PlayerList]),
            %% 给客户端发送掉落物品的消息
            lists:foreach
            (
                fun(PlayerID) ->
                    Lv = player:lookup_info(PlayerID, [?pd_level]),
%%                    ?INFO_LOG("==========================Lv:~p", [Lv]),

                    %% 每种怪物有自己固定的掉落列表
                    %% 给客户端发送消息掉落奖励
                    scene_drop:player_drop_item(MonsterId, {X,Y}, PlayerID)
                end,
                PlayerList
            )
        end,

    evt_util:sub(#monster_die{}, Drop),
    ok.


