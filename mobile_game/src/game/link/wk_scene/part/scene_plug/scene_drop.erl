%%%-------------------------------------------------------------------
%%% @author zl
%%% @doc 场景掉落
%%%  掉落管理
%%%
%%%  gb_trees key = dropId, value={X,Y}
%%%
%%%  每个掉落包 可以拾取的id, 自动消失时间
%%%  如果不支持那个就写0
%%%  {playerId, teamId, guildId, nationId}
%%%  [{ItemId, Count}]
%%%
%%%  random_drop_items
%%%
%%%  [{DropRate, itemId, ItemCount}]
%%%
%%%
%%%
%%% @end
%%%-------------------------------------------------------------------

-module(scene_drop).

%-include_lib("config/include/config.hrl").
-include_lib("common/include/com_log.hrl").
-include("inc.hrl").
-include("scene_mod.hrl").

-include("main_ins_struct.hrl").
-include("scene.hrl").
-include("load_cfg_scene.hrl").
-include("load_cfg_scene_drop.hrl").
-include("load_cfg_main_ins.hrl").
-include("system_log.hrl").

-export
([
    drop_item/3
    , pick_item/2
    , pick_item/3
    , drop_item_remove/2
    , pack_drop_info/0
    , get_drop_items/0
    , get_drop_items_by_id/1
    , put_drop_items/1
    , drop_more_item/3
    , init_drop_item/1
    , player_drop_item/3
]).

%%-record(scene_drop_cfg, {id,
%%    items = [],
%%    exp = none %% 经验一般是怪物死亡时立即加上
%%}).

-define(pd_drop_mng, pd_drop_mng).
-define(pd_drop_info, pd_drop_info).
-define(pd_drop_id, pd_drop_id).
-define(scene_drop_list, scene_drop_list). %每个场景维护的掉落列表
%% PickUpPlayerIdList :: [playerId] | all
-define(make_value(Point, Owner, ItemId, ItemCount, Ref), {Point, Owner, ItemId, ItemCount, Ref}).

pack_drop_info() ->
    ?assert(?ptype() =:= ?PT_SCENE),
    Mng = get(?pd_drop_mng),
    com_util:gb_trees_fold(fun(DropId, {{X, Y}, _, ItemId, ItemCount}, Acc) ->
        <<Acc/binary, DropId:16, X:16, Y:16, ItemId:32, ItemCount:32>>;
        (DropId, _Unkonw, _Acc) ->
            ?ERROR_LOG("can not match ~p ~p", [DropId, _Unkonw])
    end,
        <<>>,
        Mng).



pick_item(DropId, PlayerId, P) ->
    case get(?pd_drop_mng) of
        ?undefined ->
            % ?INFO_LOG("==dp drop undefined======================Mng"),
            ?ERROR_LOG("dp drop undefined");
        Mng ->
            % ?INFO_LOG("========================Mng:~p",[Mng]),
            case gb_trees:lookup(DropId, Mng) of
                ?none ->
                    ?ERROR_LOG("can not find drop item ~p", [DropId]);
                {?value, {Dp, Owner, ItemId, ItemCount, Ref}} ->
                    case is_can_pick_up(P, Dp, PlayerId, Owner) of
                        true ->
                            scene_eng:cancel_timer(Ref),
                            put(?pd_drop_mng, gb_trees:delete(DropId, Mng)),
                            world:send_to_player(PlayerId, ?add_item_msg(ItemId, ItemCount, ?FLOW_REASON_FUBEN_DROP)),
                            scene:broadcast_msg__(?to_client_msg(
                                scene_sproto:pkg_msg(?MSG_SCENE_DROP_ITEMS_REMOVE, {DropId})));
                        false ->
                            ?ERROR_LOG("player ~p can not pick item", [PlayerId])
                    end
            end
    end.

pick_item(DropId, PlayerId) ->
    % ?INFO_LOG("========================DropId:~p",[DropId]),
    % ?INFO_LOG("========================PlayerId:~p",[PlayerId]),
    case get(?pd_drop_info) of
        ?undefined ->
            ?ERROR_LOG("dp drop undefined");
        Mng ->
            % ?INFO_LOG("========================Mng:~p",[Mng]),
            case gb_trees:lookup(DropId, Mng) of
                ?none ->
                    ?ERROR_LOG("can not find drop item ~p", [DropId]);
                {?value, {ItemId, ItemCount}} ->
                    put(?pd_drop_info, gb_trees:delete(DropId, Mng)),
                    % ?INFO_LOG("========================Value:~p",[{ItemId, ItemCount}]),
                    world:send_to_player(PlayerId, ?add_item_msg(ItemId, ItemCount, ?FLOW_REASON_FUBEN_DROP)),
                    ok
            end
    end.


get_drop_items() ->
    get(?scene_drop_list).

get_drop_items_by_id(DropId) ->
    FunFoldl = fun({_Tag, DropItems}, Item) ->
        case lists:keyfind(DropId, 1, DropItems) of
            false -> Item;
            {DropId, Item, ItemCount, _DropRate} ->
                [{Item, ItemCount} | Item]
        end
    end,
    lists:foldl(FunFoldl, [], get_drop_items()).

put_drop_items(DropItems) ->
    case get(?scene_drop_list) of
        ?undefined ->
            put(?scene_drop_list, DropItems);
        ExirDropItems ->
            put(?scene_drop_list, lists:append(DropItems, ExirDropItems))
    end.

init_drop_item(_Level) ->
    [].

drop_more_item(SceneId, Tag, PlayerLevel) ->
    TagList = case load_cfg_main_ins:lookup_main_ins_cfg(SceneId) of
                  ?none -> [];
                  #main_ins_cfg{is_monster_match_level = IsMatch} ->
                      case IsMatch of
                          ?TRUE ->
                              case load_cfg_scene_drop:lookup_scene_tag_cfg({SceneId#scene_cfg.id, PlayerLevel}) of
                                  ?none -> [];
                                  #scene_tag_cfg{tag_list = TagList1} -> TagList1
                              end;
                          ?FALSE ->
                              SceneCFG = load_cfg_scene:lookup_scene_cfg(SceneId),
                              SceneCFG#scene_cfg.tag_list
                      end
              end,
    case lists:keyfind(Tag, 1, TagList) of
        false -> [];
        {Tag, DropId} ->
            case get_drop_items() of
                ?undefined ->
                    Fun = fun({ItemId, ItemCount, DropRate}) ->
                        {get_id(), ItemId, ItemCount, DropRate}
                    end,
                    DropList = lists:map(Fun, prize:get_random(DropId)),
                    put(?scene_drop_list, [{Tag, DropList}]),
                    DropList;
                ExirDropItems ->
                    case lists:keyfind(Tag, 1, ExirDropItems) of
                        false ->
                            Fun = fun({ItemId, ItemCount, DropRate}) ->
                                {get_id(), ItemId, ItemCount, DropRate}
                            end,
                            DropList = lists:map(Fun, prize:get_random(DropId)),
                            put(?scene_drop_list, [{Tag, DropList} | ExirDropItems]),
                            DropList;
                        {Tag, _NowDropList} ->
                            []
                    end
            end
    end.

drop_item(DropCfgId, PickUpPlayerIdList, P) ->
    case ?ptype() of
        ?PT_SCENE ->
            %% 只适用单机
            ?debug_log_scene_drop("start drop item ~p", [DropCfgId]),
            case load_cfg_scene_drop:lookup_scene_drop_cfg(DropCfgId) of
                ?none ->
                    ?ERROR_LOG("Can not find drop id ~p", [DropCfgId]);
                #scene_drop_cfg{items = Items, exp = Exp} ->
                    if Exp =:= ?none ->
                        ok;
                        true ->
                            ?INFO_LOG("Exp:~p, PickUpPlayerIdList:~p", [Exp, PickUpPlayerIdList]),
                            AddExp = Exp div erlang:length(PickUpPlayerIdList),

                            lists:foreach(fun(FPlayerId) ->
                                world:send_to_player(FPlayerId, ?mod_msg(player_mng, {?msg_kill_monster_add_exp, AddExp}))
                            end,
                                PickUpPlayerIdList)
                    end,

                    DropItems =
                        lists:foldl(fun({DropRate, ItemId, ItemCount}, Acc) ->
                            case random:uniform(100) =< DropRate of
                                true ->
                                    [{ItemId, ItemCount} | Acc];
                                false ->
                                    Acc
                            end
                        end,
                            [],
                            Items),

                    {NewMng, Info} = drop_to_points(DropItems, P, PickUpPlayerIdList, get(?pd_drop_mng)),

                    put(?pd_drop_mng, NewMng),

                    scene:broadcast_msg__(?to_client_msg(scene_sproto:pkg_msg(?MSG_SCENE_DROP_ITEMS, {Info}))),
                    ok

            end;

        _ ->
            pass
    end.

%% 多人副本每个玩家的掉落
player_drop_item(DropCfgId, P, PlayerId) ->
    ?debug_log_scene_drop("start drop item ~p", [DropCfgId]),
    case load_cfg_scene_drop:lookup_scene_drop_cfg(DropCfgId) of
        ?none ->
            pass;
        #scene_drop_cfg{items = Items, exp = Exp} ->
            if
                Exp =:= ?none ->
                    ok;
                true ->
                    world:send_to_player(PlayerId, ?mod_msg(player_mng, {?msg_kill_monster_add_exp, Exp}))
            end,
            DropItems =
                lists:foldl
                (
                    fun({DropRate, ItemId, ItemCount}, Acc) ->
                        case random:uniform(100) =< DropRate of
                            true ->
                                [{ItemId, ItemCount} | Acc];
                            false ->
                                Acc
                        end
                    end,
                    [],
                    Items
                ),
            {Info, SaveDrop} = drop_to_points(DropItems, P),
            %% 玩家保存掉落信息
            case SaveDrop of
                [{Id, ItemId, ItemCount}] ->
                    Mng = gb_trees:insert(Id, {ItemId, ItemCount}, get(?pd_drop_info)),
                    put(?pd_drop_info, Mng);
                _ ->
                    ok
            end,
            world:send_to_player_if_online(PlayerId, ?to_client_msg(scene_sproto:pkg_msg(?MSG_SCENE_DROP_ITEMS, {Info})))
    end.


-define(SET_OWNER_TIEM, 120).
-define(REMOVE_TIME, 120).
drop_to_points(DropItems, P, Owner, Mng) ->
    drop_to_points__(DropItems, P, Owner, Mng, []).

drop_to_points(DropItems, P) ->
    drop_to_points__(DropItems, P, [], []).

drop_to_points__([], _O, _Owner, Mng, Acc) ->
    {Mng, Acc};
drop_to_points__([{ItemId, ItemCount} | Other] = DropItems, O, Owner, Mng, Acc) ->
    Id = get_id(),
    {X, Y} = get_point(O),
    case gb_trees:is_defined(Id, Mng) orelse not scene_map:is_walkable({X, Y}) of
        true ->
            drop_to_points__(DropItems, O, Owner, Mng, Acc);
        false ->
            ?debug_log_scene_drop("drop item ~p", [Id]),
            Ref = scene_eng:start_timer(?SET_OWNER_TIEM * 1000, ?MODULE, {drop_item_set_owner_all, Id}),
            drop_to_points__(Other, O, Owner,
                gb_trees:insert(Id, ?make_value({X, Y}, Owner, ItemId, ItemCount, Ref), Mng),
                [{Id, X, Y, ItemId} | Acc])
    end.

drop_to_points__([], _P, Acc, SaveDrop) ->
    {Acc, SaveDrop};
drop_to_points__([{ItemId, ItemCount} | Other] = _DropItems, O, Acc, SaveDrop) ->
    Id = get_id(),
    {X, Y} = get_point(O),
    drop_to_points__(Other, O, [{Id, X, Y, ItemId} | Acc], [{Id, ItemId, ItemCount} | SaveDrop]).

init(_SceneCFG) ->
    ?pd_new(?pd_drop_info, gb_trees:empty()),
    ?pd_new(?pd_drop_mng, gb_trees:empty()).
%%     case get(?pd_scene_id) of
%%         {SceneId, ?scene_main_ins, {#fight_start{ins_state = ?ins_state_client}, _}} ->
%%             put(pd_career, (SceneCFG#scene_cfg.run_arg)#run_arg.start_scene_career), %根据生成场景的玩家进程的玩家职业，生成掉落库
%%             case (SceneCFG#scene_cfg.run_arg)#run_arg.is_match of
%%                 ?TRUE ->
%%                     TagDropList = case lookup_scene_tag_cfg({SceneId, (SceneCFG#scene_cfg.run_arg)#run_arg.match_level}) of
%%                                       ?none -> [];
%%                                       #scene_tag_cfg{tag_list = TagList} ->
%%                                           Fun = fun({Tag, PrizeId}) ->
%%                                               DropList = prize:get_random(PrizeId),
%%                                               Fun = fun({ItemId, ItemCount, DropRate}) ->
%%                                                   {get_id(), ItemId, ItemCount, DropRate}
%%                                               end,
%%                                               {Tag, lists:map(Fun, DropList)}
%%                                           end,
%%
%%                                           lists:map(Fun, TagList)
%%                                   end,
%%                     put_drop_items(TagDropList);
%%                 ?FALSE ->
%%                     Fun = fun({Tag, PrizeId}) ->
%%                         DropList = prize:get_random(PrizeId),
%%                         Fun = fun({ItemId, ItemCount, DropRate}) ->
%%                             {get_id(), ItemId, ItemCount, DropRate}
%%                         end,
%%                         {Tag, lists:map(Fun, DropList)}
%%                     end,
%%                     TagDropList = lists:map(Fun, SceneCFG#scene_cfg.tag_list),
%%                     put_drop_items(TagDropList)
%%             end;
%%         _ -> []
%%     end.


uninit(_) -> ok.


handle_msg(_Msg) ->
    {error, nonkonw_msg}.


handle_timer(Ref, {drop_item_set_owner_all, Id}) ->
    drop_item_set_owner_all(Id, Ref),
    ok;

handle_timer(Ref, {drop_item_remove, Id}) ->
    drop_item_remove(Id, Ref),
    ok;

handle_timer(_Ref, Msg) ->
    ?ERROR_LOG("unknow timer ~p", [Msg]).


%% @private
is_can_pick_up(P, Dp, PlayerId, Owner) ->
    com_util:get_point_distance(P, Dp) < 10 andalso
        (Owner =:= all orelse lists:member(PlayerId, Owner)).

drop_item_set_owner_all(Id, _Ref) ->
    Mng = get(?pd_drop_mng),
    ?assert(Mng =/= undefined),
    case gb_trees:lookup(Id, Mng) of
        ?none ->
            ?ERROR_LOG("drop id ~p tiemout but can find", [Id]);
        {?value, {Dp, _, ItemId, ItemCount, _Ref}} ->
            ?debug_log_scene_drop("item owner change all ~p", [Id]),
            NewRef = scene_eng:start_timer(?REMOVE_TIME * 1000, ?MODULE, {drop_item_remove, Id}),
            put(?pd_drop_mng, gb_trees:update(Id, ?make_value(Dp, all, ItemId, ItemCount, NewRef), Mng))
    end.

drop_item_remove(Id, _Ref) ->
    Mng = get(?pd_drop_mng),
    ?assert(Mng =/= undefined),

    case gb_trees:lookup(Id, Mng) of
        ?none ->
            ?ERROR_LOG("drop id ~p tiemout but can find", [Id]);
        {?value, _} ->
            ?debug_log_scene_drop("remove drop item ~p", [Id]),
            put(?pd_drop_mng, gb_trees:delete(Id, Mng)),
            scene:broadcast_msg__(?to_client_msg(scene_sproto:pkg_msg(?MSG_SCENE_DROP_ITEMS_REMOVE, {Id})))
    end.

get_id() ->
    case get(?pd_drop_id) of
        ?undefined ->
            ?pd_new(?pd_drop_id, 2),
            1;
        Id ->
            put(?pd_drop_id, (Id + 1) band 16#FFFF)
    end.

get_point({X, Y}) ->
    {X + com_util:random(-1, 1), Y + com_util:random(-1, 1)}.


%%load_config_meta() ->
%%    [
%%        #config_meta{record = #scene_drop_cfg{},
%%            fields = record_info(fields, scene_drop_cfg),
%%            file = "scene_drop.txt",
%%            keypos = #scene_drop_cfg.id,
%%            verify = fun verify/1},
%%
%%        #config_meta{record = #scene_tag_cfg{},
%%            fields = record_info(fields, scene_tag_cfg),
%%            file = "scene_lvl_drop.txt",
%%            keypos = [#scene_tag_cfg.scene_id, #scene_tag_cfg.match_level],
%%            verify = fun scene_tag_verify/1}
%%    ].
%%
%%verify(#scene_drop_cfg{id = Id, items = Items, exp = Exp}) ->
%%    ?check(is_list(Items), "scene_drop_cfg [~p] 无效 items ~p", [Id, Items]),
%%    lists:foreach(fun({Race, ItemId, ItemCount}) ->
%%        ?check(Race > 0 andalso Race =< 100, "scene_drop_cfg [~p] 无效 items race ~p", [Id, Race]),
%%        ?check(player_def:is_valid_special_item_id(ItemId) orelse
%%            load_item:is_exist_item_attr_cfg(ItemId)
%%            , "scene_drop_cfg [~p] items id ~p 没有找到", [Id, ItemId]),
%%        ?check(ItemCount > 0, "scene_drop_cfg [~p] 无效 items dropCount ~p", [Id, ItemCount])
%%    end,
%%        Items),
%%    ?check(Exp =:= ?none orelse Exp > 0, "scene_drop_cfg [~p] exp 无效 必须 >0 ~p", [Id, Exp]),
%%    ok.
%%
%%scene_tag_verify(#scene_tag_cfg{id = Id, scene_id = SceneId, match_level = Level, tag_list = TagList}) ->
%%    ?check(is_integer(Id), "scene_lvl_drop [~p] 无效 id ~p", [Id, Id]),
%%    ?check(load_cfg_scene:is_exist_scene_cfg(SceneId), "scene_lvl_drop.txt [~p] 没有找到对应 scene_id", [SceneId]),
%%    ?check(is_integer(Level), "scene_lvl_drop.txt [~p] 没有找到对应 match_level ", [Level]),
%%    ?check(is_list(TagList), "scene_lvl_drop.txt [~p] tag_list:~p 验证失败! ", [Id, TagList]).
