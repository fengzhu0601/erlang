%%%-------------------------------------------------------------------
%%% @author fengzhu
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 05. 一月 2016 下午4:34
%%%-------------------------------------------------------------------
-module(load_cfg_main_ins).
-author("fengzhu").

%% API
-export
([
    get_ins_id/1 %获取副本id
    , get_last_layer_cfg/1 %获取某个副本最后一层的配置
    , get_all_scene_by_ins_id/2 %根据副本id获取该副本所有场景
    , get_add_hp_mp_info/1
    , lookup_next_scene_id/2
    , next_scene_id/2 %获取下一层场景id
    , get_scene_tag/2 %获取某个场景的副本掉落
    , is_boss_room/1 %是否是boss房间
    , get_ins_type/1
    , get_count_by_star_and_type/3
    , get_main_shop_price/1
    , get_main_chapter_prize/2
    , get_ins_sub_type/1
    , get_main_instance_id/1
    , get_main_instance_relive_num/1
    , get_main_instance_relive_cost_by_num/2
    , get_main_instance_battle_num/1            %% 获取副本挑战次数
    , get_main_instance_sweep_cost/1            %% 获取副本挑战消耗Id
    , get_main_card_prize/1
    , get_main_ins_chapterid/1
    , get_main_card_prize_pool/1
    , get_ins_type_and_sub_type/1
]).

-include_lib("config/include/config.hrl").
-include("inc.hrl").
-include("load_cfg_main_ins.hrl").
-include("load_cfg_scene.hrl").
-include("load_cfg_scene_drop.hrl").

load_config_meta() ->
    [
    #config_meta{record = #main_ins_cfg{},
        fields = ?record_fields(main_ins_cfg),
        file = "main_ins.txt",
        keypos = #main_ins_cfg.id,
        groups = [#main_ins_cfg.type, #main_ins_cfg.chapter_id],
        verify = fun verify/1},
    % #config_meta{record = #main_prize_cfg{},
    %     fields = ?record_fields(main_prize_cfg),
    %     file = "ins_lvl_prize.txt",
    %     keypos = [#main_prize_cfg.ins_id, #main_prize_cfg.match_level],
    %     verify = fun ins_lvl_prize_verify/1},
    #config_meta{record = #main_ins_shop_cfg{},
        fields = ?record_fields(main_ins_shop_cfg),
        file = "main_ins_shop.txt",
        keypos = #main_ins_shop_cfg.id,
        verify = fun verify_main_instance_shop/1},
    #config_meta{record = #main_chapter_star_prize_cfg{},
        fields = ?record_fields(main_chapter_star_prize_cfg),
        file = "main_chapter_star_prize.txt",
        keypos = #main_chapter_star_prize_cfg.id,
        verify = fun verify_main_instance_chapter/1}
    ].


verify(#main_ins_cfg{id = Id, ins_id = InsId, chapter_id=_Chapter, type = Type, sub_type = Diff,
    pervious = Per, limit_level = LimitLev, cost = Cost, next = NextId, limit_pervious = _UnLockId,
    pass_prize = PassPrize, frist_starprize=FristStarPrize, card_prize_pool=CardPrizePool,
    is_monster_match_level = IsMatchLevel, guaiwu_gc_best_prize=GwgcPrize}) ->
    ?check(load_cfg_scene:is_exist_scene_cfg(Id), "main_ins.txt [~p] 没有找到对应 scene id ", [Id]),
    ?check(load_cfg_scene:get_config_type(Id) =:= ?SC_TYPE_MAIN_INS, "main_ins.txt [~p] scene 不是单人副本类型", [Id]),
    ?check(game_def:is_valid_ins_type(Type), "main_ins.txt [~w] type [~w] 无效", [Id, Type]),
    ?check(?is_pos_integer(InsId), "main_ins.txt [~p] ins_id ~p 无效", [Id, InsId]),
    if

        Type =:= ?T_INS_MAIN orelse Type =:= ?T_INS_FREE ->
            ?check(scene_def:is_valid_main_in_difficulty(Diff), "main_ins.txt [~w] ins_id ~w 无效", [Id, Diff]);
        ?true -> ignore
    end,
    % ?check(load_cfg_scene:is_exist_scene_cfg(UnLockId) orelse UnLockId=:=?undefined, "main_ins.txt limit_pervious[~p] 没有找到对应 scene id ", [UnLockId]),
    
    ?check(prize:is_exist_prize_cfg(PassPrize) orelse PassPrize =:= 0, "main_ins.txt [~p] pass_prize:~p 没有找到! ", [Id, PassPrize]),

    ?check(prize:is_exist_prize_cfg(FristStarPrize) orelse FristStarPrize =:= 0, "main_ins.txt [~p] frist_starprize:~p 没有找到! ", [Id, FristStarPrize]),

    ?check(prize:is_exist_prize_cfg(GwgcPrize) orelse GwgcPrize =:= 0, "main_ins.txt [~p] guaiwu_gc_best_prize:~p 没有找到! ", [Id, GwgcPrize]),

    [?check(prize:is_exist_prize_cfg(CpId) orelse CpId =:= 0, "main_ins.txt  card_prize_pool:~p 没有找到! ", [Id, CpId]) || {CpId, _} <- CardPrizePool],

    
    ?check(com_util:is_valid_uint16(LimitLev), "main_ins.txt[~w] limit_lev ~w 无效", [Id, LimitLev]),


    ?check(cost:is_exist_cost_cfg(Cost), "main_ins.txt [~w] cost:~w 没有找到! ", [Id, Cost]),
    ?check(?IS_BOOLEN(IsMatchLevel), "main_ins.txt [~p] is_monster_match_level ~p 无效格式", [Id, IsMatchLevel]),

    ?check(Per =/= Id, "main_ins.txt [~w] pervious ~w 不能和自己", [Id, Per]),
    ?check(Per =:= 0 orelse is_exist_main_ins_cfg(Per), "main_ins.txt [~w] pervious ~w 没有找到 ", [Id, Per]),
    ?check(Per =:= 0 orelse load_cfg_scene:is_exist_scene_cfg(Per), "main_ins.txt [~w] pervious 没有找到对应 ~w scene id ", [Id, Per]),
    case NextId of
        ?none ->
            %%?check(length(RP) >= 8, "main_ins.txt [~p] random_prize 格式必须>=8 ~p", [Id, RP]),
            %%[check_random_prize(Id, XX) || XX <- RP],
            ?check(load_cfg_scene:get_config_type(Id) =:= ?SC_TYPE_MAIN_INS, "main_ins.txt [~p] scene 类型不正确 ", [Id]);
        _ ->
            ?check(NextId =/= Id, "main_ins.txt [~p] next ~p 不能和自己", [Id, NextId]),
            ?check(is_exist_main_ins_cfg(NextId), "main_ins.txt [~p] next ~p 没有找到 ", [Id, NextId]),
            ?check(load_cfg_scene:is_exist_scene_cfg(NextId), "main_ins.txt [~p] next 没有找到对应 ~p scene id ", [Id, NextId]),
            ?check(load_cfg_scene:get_config_type(NextId) =:= ?SC_TYPE_MAIN_INS, "main_ins.txt [~p] next  ~p scene type 不是单人副本类型", [Id, NextId])
    end,
    ?check(is_list(CardPrizePool), "main_ins.txt[~w] card_prize_pool ~w 无效", [Id, CardPrizePool]);

verify(_R) ->
    ?ERROR_LOG("signin 配置　错误格式"),
    exit(bad).

% ins_lvl_prize_verify(#main_prize_cfg{id = Id, ins_id = InsId, match_level = MatchLevel, pass_prize = PrizeId}) ->
%     ?check(is_integer(Id), "ins_lvl_prize.txt [~p] 没有找到对应 id ", [Id]),
%     ?check(load_cfg_scene:is_exist_scene_cfg(InsId), "ins_lvl_prize.txt [~p] 没有找到对应 ins id ", [InsId]),
%     ?check(is_integer(MatchLevel), "ins_lvl_prize.txt [~p] 没有找到对应 match_level ", [MatchLevel]).
%     ?check(prize:is_exist_prize_cfg(PrizeId) orelse PrizeId =:= 0, "ins_lvl_prize.txt [~p] pass_prize:~p 没有找到! ", [Id, PrizeId]).

verify_main_instance_shop(#main_ins_shop_cfg{id=Id, price=Prize}) ->
    % ?check(goods:is_exist_goods_cfg(Id),"main_ins_shop.txt中， [~p] id: ~p 配置无效。", [Id, Id]),
    ?check(Prize > 0,"main_ins_shop.txt中， [~p] price~p 配置无效。", [Id, Prize]).

verify_main_instance_chapter(#main_chapter_star_prize_cfg{id=Id, prize=Prize}) ->
    ?check(Prize > 0,"main_chapter_star_prize.txt中， [~p] price~p 配置无效。", [Id, Prize]).



get_main_card_prize(CfgId) ->
    case lookup_main_ins_cfg(CfgId) of
        ?none -> 
            [];
        #main_ins_cfg{card_prize_pool=Pool} ->
            lists:foldl(fun({PrizeId, Q}, L) ->
                ItemList = prize:get_prize_item_tuples(PrizeId),
                Size = length(ItemList),
                NewItemList = 
                if
                    Size > 1 ->
                        lists:nth(1, ItemList);
                    true ->
                        ItemList
                end,
                [{NewItemList, Q}|L]
            end,
            [],
            Pool)
    end.

get_main_card_prize_pool(CfgId) ->
    case lookup_main_ins_cfg(CfgId) of
        ?none ->
            [];
        #main_ins_cfg{card_prize_pool=Pool} ->
            Pool
    end.

get_main_ins_chapterid(CfgId) ->
    case lookup_main_ins_cfg(CfgId) of
        ?none ->
            0;
        #main_ins_cfg{chapter_id=Id} ->
            Id
    end.


get_count_by_star_and_type(CfgId, Star, Type) ->
    case lookup_main_ins_cfg(CfgId) of
        ?none ->
            ?none;
        Cfg ->
            case Cfg#main_ins_cfg.stars of
                ?undefined ->
                    ?none;
                List ->
                    case lists:keyfind(Type, 1, List) of
                        ?false ->
                            ?none;
                        {_, L} ->
                            lists:nth(Star, L)
                    end
            end
    end.

get_main_shop_price(GoodsId) ->
    case lookup_main_ins_shop_cfg(GoodsId) of
        ?none ->
            ?none;
        Cfg ->
            Cfg#main_ins_shop_cfg.price
    end.


get_main_chapter_prize(Id, Index) ->
    case lookup_main_chapter_star_prize_cfg(Id) of
        ?none ->
            0;
        Cfg ->
            ?NODE_INFO_LOG("get_main_chapter_prize ~p", [Cfg]),
            lists:nth(Index, Cfg#main_chapter_star_prize_cfg.prize)
    end.

get_last_layer_cfg(CfgId) ->
    case lookup_main_ins_cfg(CfgId) of
        ?none ->
            ?none;
        Cfg ->
            case Cfg#main_ins_cfg.next of
                ?none ->
                    Cfg;
                NextId ->
                    get_last_layer_cfg(NextId)
            end
    end.

get_all_scene_by_ins_id( InsId, SceneList ) ->
    case lookup_main_ins_cfg(InsId) of
        ?none ->
            SceneList;
        Cfg ->
            case Cfg#main_ins_cfg.next of
                ?none ->
                    SceneList;
                NextId ->
                    get_all_scene_by_ins_id( NextId, [NextId|SceneList] )
            end
    end.

get_add_hp_mp_info(CfgId) ->
    case lookup_main_ins_cfg(CfgId) of
        ?none -> ?none;
        #main_ins_cfg{ins_id = InsId, type = _Type, sub_type= Difficulty} ->
            %% when Type =:= ?T_INS_MAIN;Type =:=?T_INS_FREE; Type =:= ?T_INS_SHENMO->
            %%TODO:类型部分
            {InsId, Difficulty, ?SC_TYPE_MAIN_INS};
        _ -> 
            ?none
    end.

get_ins_sub_type(SceneId) ->
    case lookup_main_ins_cfg( SceneId ) of
        ?none -> 
            ?none;
        #main_ins_cfg{sub_type=SubType} -> 
            SubType
    end.


get_ins_id( SceneId ) ->
    %lookup_main_ins_cfg(load_cfg_scene:get_config_id(SceneId), #main_ins_cfg.ins_id).
    case lookup_main_ins_cfg(load_cfg_scene:get_config_id(SceneId)) of
        ?none ->
            ?none;
        #main_ins_cfg{ins_id =InsId, type = Type} ->
            case Type =:= 1 orelse Type =:= 8 orelse Type =:= 9 of
                true -> InsId;
                _ -> ?none
            end;
        _ ->
            ?none
    end.
get_main_instance_id(SceneId) ->
    lookup_main_ins_cfg(load_cfg_scene:get_config_id(SceneId), #main_ins_cfg.id).

get_main_instance_relive_num(MainIntanceId) ->
    case lookup_main_ins_cfg(MainIntanceId) of
        ?none ->
            0;
        #main_ins_cfg{relive_num = Num} ->
            Num
    end.

%% 得到副本的最大挑战次数
get_main_instance_battle_num(MainInstanceId) ->
    case lookup_main_ins_cfg(MainInstanceId) of
        ?none ->
            0;
        #main_ins_cfg{battle_num = Num} ->
            Num
    end.

%% 获得副本挑战消耗Id
get_main_instance_sweep_cost(MainInstanceId) ->
    case lookup_main_ins_cfg(MainInstanceId) of
        ?none ->
            ?none;
        #main_ins_cfg{sweep_cost = CostId} ->
            CostId
    end.

get_main_instance_relive_cost_by_num(MainIntanceId, Num) ->
    case lookup_main_ins_cfg(MainIntanceId) of
        ?none ->
            0;
        #main_ins_cfg{relive_cost = List} ->
            Size = length(List),
            if
                Num >= Size ->
                    lists:last(List);
                true ->
                    lists:nth(Num, List)
            end
    end.


get_ins_type(SceneId) ->
    case lookup_main_ins_cfg(load_cfg_scene:get_config_id(SceneId)) of
        ?none ->
            ?none;
        #main_ins_cfg{type = Type} ->
            Type
    end.

get_ins_type_and_sub_type(SceneId) ->
    case lookup_main_ins_cfg(load_cfg_scene:get_config_id(SceneId)) of
        ?none ->
            ?none;
        #main_ins_cfg{type = Type, sub_type = SubType} ->
            {Type, SubType}
    end.

is_boss_room( SceneId ) ->
    case lookup_main_ins_cfg( SceneId ) of
        ?none -> ?none;
        #main_ins_cfg{has_boss=IsBoss} -> IsBoss
    end.

get_scene_tag( SceneId, PlayerLevel ) ->
    case lookup_main_ins_cfg(SceneId) of
        ?none -> [];
        #main_ins_cfg{is_monster_match_level = IsMatch} ->
            case IsMatch of
                ?TRUE ->
                    case load_cfg_scene_drop:lookup_scene_tag_cfg({SceneId, PlayerLevel}) of
                        ?none -> 
                            [];
                        #scene_tag_cfg{tag_list = TagList1} -> 
                            TagList1
                    end;
                ?FALSE ->
                    SceneCFG = load_cfg_scene:lookup_scene_cfg(SceneId),
                    SceneCFG#scene_cfg.tag_list
            end
    end.

lookup_next_scene_id( team, CFGId ) ->
    next_scene_id( {}, CFGId );

lookup_next_scene_id( FightStart, CFGId ) ->
    case FightStart#fight_start.next_scene_call of
        {} ->
            complete;
        {Mod,Fun,Arg} ->
            try Mod:Fun(Arg, CFGId) of
                ?none -> 
                    complete;
                NextSceneId ->
                    scene:make_scene_id(?SC_TYPE_MAIN_INS, FightStart, NextSceneId, FightStart#fight_start.playerIdOrtermId)
            catch
                _C:_Why ->
                    ?ERROR_LOG( "lookup_next_scene_id error reason:~w~n", [[_C,_Why]] ),
                    complete
          end
    end.

next_scene_id( _CallArg, CFGId ) ->
    case lookup_main_ins_cfg(CFGId) of
        #main_ins_cfg{next=?none} ->
            ?none;
        #main_ins_cfg{ins_id = _InsId, next=NextSceneId} ->
            NextSceneId
    end.
