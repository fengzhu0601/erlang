%%% coding:utf-8
%%%-------------------------------------------------------------------
%%% @author zl
%%% @doc 采集
%%%
%%% @end
%%%-------------------------------------------------------------------

-module(scene_collect).

%-include_lib("config/include/config.hrl").
-include_lib("common/include/com_log.hrl").
-include("inc.hrl").
-include("scene_mod.hrl").
-include("load_cfg_scene_collect.hrl").

%%-define(CT_TASK_COLLECT, 1). % 任务采集
%%-define(CT_ITEM_COLLECT, 2). % 真实物品采集
%%-define(CT_ITEM_RESFIGHT, 3). % 资源争夺战物品采集



%%-record(scene_collect_cfg,
%%{id,
%%    type = 1, % 1 任务采集 2 真实物品采集
%%    scene_id,
%%    direction,
%%    item,
%%    x,
%%    y
%%}).


%% API
-export([
    collect_item/3
]).



%% player process call
collect_item(CollectId, SceneId, _Idx) ->
    ?assert(?ptype() =:= ?PT_PLAYER),
    %% TODO

    ?debug_log_scene("CollectId ~p", [CollectId]),
    try
        Cfg = load_cfg_scene_collect:lookup_scene_collect_cfg(CollectId),
        ?ifdo(Cfg =:= ?none, ?return_err("not find")),

        ?ifdo(Cfg#scene_collect_cfg.scene_id =/= SceneId, ?return_err("not in current scene")),

        #scene_collect_cfg{scene_id = SceneId, type = Type, item = ItemId, x = X, y = Y} = Cfg,
        CPoint = {X, Y},

        % P = scene:get_agent_point(SceneId, Idx),
        % ?ifdo(P =:= ?none, ?return_err("not find point")),

        % Dist = com_util:get_point_distance(P, CPoint),
        % ?ifdo(Dist > 6, ?return_err("distance too lager")),

        IsCanCollect = event_eng:is_reg_arg(?ev_collect_item, ItemId),
        ?debug_log_scene("IsCanCollect-------------------------~p", [IsCanCollect]),
        ?ifdo(not IsCanCollect, ?return_err("can not collect")),

        if Type =:= ?CT_ITEM_COLLECT ->
            case item_mng:add_item(ItemId, 1) of
                {error, _} ->
                    throw("can not add item bag full");
                _ ->
                    event_eng:post(?ev_collect_item, ItemId)
            end;
            true ->
                event_eng:post(?ev_collect_item, ItemId)
        end
    catch
        _:R ->
            ?ERROR_LOG("player ~p collect item ~p ~p", [?pname(), CollectId, R])
    end,

    ok.


init(_) -> nonused.

uninit(_) -> nonused.


handle_msg(Msg) ->
    ?ERROR_LOG("unknow msg ~p", [Msg]).

handle_timer(_Ref, Msg) ->
    ?ERROR_LOG("unknow timer ~p", [Msg]).

%%load_config_meta() ->
%%    [
%%        #config_meta{record = #scene_collect_cfg{},
%%            fields = record_info(fields, scene_collect_cfg),
%%            file = "scene_collect.txt",
%%            keypos = #scene_collect_cfg.id,
%%            verify = fun collect_verify/1}
%%    ].
%%
%%collect_verify(#scene_collect_cfg{id = Id, type = Type, scene_id = SId, item = ItemId, x = X, y = Y}) ->
%%    ?check(scene:is_exist_scene_cfg(SId), "scene_collect.txt [~p] scene_id ~p 没有找到", [Id, SId]),
%%
%%    case Type of
%%        ?CT_TASK_COLLECT ->  %并不是真实物品
%%            ?check(not goods:is_exist_goods_cfg(ItemId), "scene_collect.txt [~p] 任务item ~p 和goods冲突", [Id, ItemId]);
%%        ?CT_ITEM_COLLECT ->
%%            ?check(goods:is_exist_goods_cfg(ItemId), "scene_collect.txt [~p] item ~p 没有找到", [Id, ItemId]);
%%        ?CT_ITEM_RESFIGHT ->
%%            ok;
%%        _ ->
%%            ok
%%    end,
%%    MapId = scene:get_map_id(SId),
%%    ?check(scene_map:is_walkable(MapId, {X, Y}), "scene_collect.txt [~p] item xy ~p 无可行走点", [Id, {X, Y}]),
%%    ok.


