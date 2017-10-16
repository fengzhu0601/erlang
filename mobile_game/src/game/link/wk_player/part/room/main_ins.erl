%%%-------------------------------------------------------------------
%%% @author zl
%%% @doc 副本
%%%-------------------------------------------------------------------

-module(main_ins).

%%-include_lib("config/include/config.hrl").

-include("inc.hrl").
-include("safe_ets.hrl").
-include("player.hrl").
-include("main_ins_struct.hrl").
-include("scene_cfg_struct.hrl").
-include("load_cfg_scene.hrl").
-include("load_cfg_scene_drop.hrl").
-include("load_cfg_main_ins.hrl").
-include("system_log.hrl").

-export([insert_scene/1,remove_scene/1,get_scene_id/1 ,% 把当前生成的场景插入ets表，供进入该副本场景时使用
%%        get_ins_id/1, %获取副本id
%%        get_last_layer_cfg/1, %获取某个副本最后一层的配置
%%        get_all_scene_by_ins_id/2, %根据副本id获取该副本所有场景
%%        get_add_hp_mp_info/1,
%%        lookup_next_scene_id/2, next_scene_id/2, %获取下一层场景id
        get_auto_pass_prize/1, get_pass_prize/1, get_pass_prize/3 %获取某个副本结算奖励（新增根据等级匹配计算奖励的机制）
%%        get_scene_tag/2, %获取某个场景的副本掉落
%%        is_boss_room/1 %是否是boss房间
        ]).


-export(
[
%%        get_ins_type/1,
%%        get_count_by_star_and_type/3,
%%        get_main_shop_price/1,
        send_main_ins_star_level_rewards/4,
        get_main_ins_data/1,
        update_main_ins_data/2,
        update_main_ins_lianji/2,
        del_main_ins_data/1,
        get_main_ins_lianji/2,
        get_total_star/1,
        get_clean_pass_prize/1, 
        get_frist_starprize/1
%%        get_main_chapter_prize/1
]).


-define(main_ins_3idmap, main_ins_3idmap).
-define(main_ins_data, main_ins_data).

get_total_star(List) ->
    do_total_star(List, 0).
do_total_star([], Total) ->
    Total;
do_total_star([{_, Count}|T], Total) ->
    do_total_star(T, Total + Count).

send_main_ins_star_level_rewards(ActivityId, CfgId, AllStarList, Type) ->
    case load_cfg_main_ins:lookup_main_ins_cfg(CfgId) of
        ?none ->
            [];
        Cfg ->
            case Cfg#main_ins_cfg.star_level_rewards of
                ?undefined ->
                    [];
                List ->
                    case lists:keyfind(Type, 1, AllStarList) of
                        ?false ->
                            [];
                        {_, Star} ->
                            PrizeId = 
                            case lists:keyfind(Star, 1, List) of
                                ?false ->
                                    0;
                                {_, L} ->
                                    lists:nth(Star, L)
                            end,
                            prize:prize_mail_2(ActivityId, PrizeId, ?S_MAIL_INSTANCE, ?FLOW_REASON_STAR_LEV_PRIZE)
                            % case prize:prize_mail(PrizeId, ?S_MAIL_INSTANCE, ?FLOW_REASON_STAR_LEV_PRIZE) of
                            %     {error, _Other} ->
                            %         case prize:get_prize(PrizeId) of
                            %             {ok, ListP} ->
                            %                 ListP;
                            %             _ ->
                            %                 []
                            %         end;
                            %     ListPrize ->
                            %         ListPrize
                            % end
                    end
            end
    end.


%%
%%get_count_by_star_and_type(CfgId, Star, Type) ->
%%    case lookup_main_ins_cfg(CfgId) of
%%        ?none ->
%%            ?none;
%%        Cfg ->
%%            case Cfg#main_ins_cfg.stars of
%%                ?undefined ->
%%                    ?none;
%%                List ->
%%                    case lists:keyfind(Type, 1, List) of
%%                        ?false ->
%%                            ?none;
%%                        {_, L} ->
%%                            lists:nth(Star, L)
%%                    end
%%            end
%%    end.
%%
%%get_main_shop_price(GoodsId) ->
%%    case lookup_main_ins_shop_cfg(GoodsId) of
%%        ?none ->
%%            ?none;
%%        Cfg ->
%%            Cfg#main_ins_shop_cfg.price
%%    end.
%%
%%
%%get_main_chapter_prize(Id) ->
%%    case lookup_main_chapter_star_prize_cfg(Id) of
%%        ?none ->
%%            0;
%%        Cfg ->
%%             Cfg#main_chapter_star_prize_cfg.prize
%%    end.
%%
%%get_last_layer_cfg(CfgId) ->
%%    case lookup_main_ins_cfg(CfgId) of
%%        ?none ->
%%            ?none;
%%        Cfg ->
%%            case Cfg#main_ins_cfg.next of
%%                ?none ->
%%                    Cfg;
%%                NextId ->
%%                    get_last_layer_cfg(NextId)
%%            end
%%    end.
%%
%%get_all_scene_by_ins_id( InsId, SceneList ) ->
%%    case lookup_main_ins_cfg(InsId) of
%%        ?none ->
%%            SceneList;
%%        Cfg ->
%%            case Cfg#main_ins_cfg.next of
%%                ?none ->
%%                    SceneList;
%%                NextId ->
%%                    get_all_scene_by_ins_id( NextId, [NextId|SceneList] )
%%            end
%%    end.
%%
%%get_add_hp_mp_info(CfgId) ->
%%    case lookup_main_ins_cfg(CfgId) of
%%    ?none -> ?none;
%%    #main_ins_cfg{ins_id = InsId, type = _Type, sub_type= Difficulty} ->
%%%%         when Type =:= ?T_INS_MAIN;Type =:=?T_INS_FREE; Type =:= ?T_INS_SHENMO->
%%            %%TODO:类型部分
%%            {InsId, Difficulty, ?SC_TYPE_MAIN_INS};
%%    _ -> ?none
%%    end.

get_scene_id( Key ) ->
    case ets:lookup(?main_ins_3idmap, Key) of
        [] -> ?none;
        [{_, SceneId}] -> SceneId
    end.

%% 建立scene3id  -> scene_id() 的映射
insert_scene({_, ?scene_main_ins, Id3}=SceneId) ->
    ets:insert(?main_ins_3idmap, {Id3, SceneId});
insert_scene(_) ->
    ok.

%% 移除
remove_scene({_, ?scene_main_ins, Id3}=SceneId) ->
    case ets:lookup(?main_ins_3idmap, Id3) of
        [{_,SceneId}] ->
            ets:delete(?main_ins_3idmap, Id3);
        _ -> %% 已经更新为其他场景
            ok
    end;
remove_scene(_) ->
    ok.

%%lookup_next_scene_id( team, CFGId ) ->
%%    next_scene_id( {}, CFGId );
%%
%%lookup_next_scene_id( FightStart, CFGId ) ->
%%    case FightStart#fight_start.next_scene_call of
%%        {} ->
%%            complete;
%%        {Mod,Fun,Arg} ->
%%            try Mod:Fun(Arg, CFGId) of
%%                ?none -> complete;
%%                NextSceneId ->
%%                    scene:make_scene_id(?SC_TYPE_MAIN_INS, FightStart, NextSceneId, FightStart#fight_start.playerIdOrtermId)
%%            catch
%%                _C:_Why ->
%%                    ?ERROR_LOG( "lookup_next_scene_id error reason:~w~n", [[_C,_Why]] ),
%%                    complete
%%            end
%%    end.
%%
%%next_scene_id( _CallArg, CFGId ) ->
%%    case lookup_main_ins_cfg(CFGId) of
%%        #main_ins_cfg{next=?none} ->
%%            ?none;
%%        #main_ins_cfg{ins_id = _InsId, next=NextSceneId} ->
%%            NextSceneId
%%    end.

%%get_ins_id( SceneId ) ->
%%    lookup_main_ins_cfg(scene:get_config_id(SceneId), #main_ins_cfg.ins_id).
%%
%%get_ins_type(SceneId) ->
%%    case lookup_main_ins_cfg(scene:get_config_id(SceneId)) of
%%        ?none ->
%%            ?none;
%%        #main_ins_cfg{type = Type} ->
%%            Type
%%    end.
%%
%%

get_frist_starprize(SceneId) ->
    #main_ins_cfg{frist_starprize = FristStarPrize} = load_cfg_main_ins:lookup_main_ins_cfg(SceneId),
    FristStarPrize.

get_auto_pass_prize( SceneId ) ->
    #main_ins_cfg{
        ins_id = InsId,
        is_monster_match_level = IsMatch,
        pass_prize = PrizeId}
    = MainInsCFG = load_cfg_main_ins:get_last_layer_cfg(SceneId),
    {get_pass_prize(InsId, IsMatch, PrizeId), MainInsCFG}.

get_pass_prize( SceneId ) ->
    #main_ins_cfg{
        pass_prize = PrizeId}
    = MainInsCFG = load_cfg_main_ins:lookup_main_ins_cfg(SceneId),
    {PrizeId, MainInsCFG}.

get_pass_prize(_InsId, _IsMatch, PrizeId) ->
    PrizeId.
    % case IsMatch of
    %     ?TRUE ->
    %         case load_cfg_main_ins:lookup_main_prize_cfg({InsId, get(?pd_level)}) of
    %             ?none ->
    %                 0;
    %             #main_prize_cfg{pass_prize = Prize} ->
    %                 Prize
    %         end;
    %     ?FALSE ->
    %         PrizeId
    % end.

%% 扫荡副本的奖励
get_clean_pass_prize( SceneId ) ->
    #main_ins_cfg{
        pass_prize = PrizeId}
    = MainInsCFG = load_cfg_main_ins:lookup_main_ins_cfg(SceneId),
    {PrizeId, MainInsCFG}.
%%
%%is_boss_room( SceneId ) ->
%%    case lookup_main_ins_cfg( SceneId ) of
%%        ?none -> ok;
%%        #main_ins_cfg{has_boss=IsBoss} -> IsBoss
%%    end.
%%
%%get_scene_tag( SceneId, PlayerLevel ) ->
%%    case main_ins:lookup_main_ins_cfg(SceneId) of
%%        ?none -> [];
%%        #main_ins_cfg{is_monster_match_level = IsMatch} ->
%%            case IsMatch of
%%                ?TRUE ->
%%                    case scene_drop:lookup_scene_tag_cfg({SceneId, PlayerLevel}) of
%%                        ?none -> [];
%%                        #scene_tag_cfg{tag_list = TagList1} -> TagList1
%%                    end;
%%                ?FALSE ->
%%                    SceneCFG = scene:lookup_scene_cfg(SceneId),
%%                    SceneCFG#scene_cfg.tag_list
%%            end
%%    end.



insert_main_ins_data(Id, Data) ->
    ets:insert(?main_ins_data, {Id, Data}).

del_main_ins_data(Id) ->
    ets:delete(?main_ins_data, Id).

get_main_ins_data(Id) ->
    case ets:lookup(?main_ins_data, Id) of
        [] ->
            0;
        [{_, Data}] ->
            del_main_ins_data(Id),
            Data
    end.
update_main_ins_data(Id, Count) ->
     case ets:lookup(?main_ins_data, Id) of
        [] ->
            insert_main_ins_data(Id, Count);
        [{_, Data}] ->
            insert_main_ins_data(Id, Data+Count)
    end.

update_main_ins_lianji(Id, Count) ->
    OldCount = get_main_ins_data(Id),
    %?DEBUG_LOG("Id-----Count---OldCount-----:~p",[{Id, Count, OldCount}]),
    if
        Count > OldCount ->
            insert_main_ins_data(Id, Count);
        true ->
            pass
    end.
get_main_ins_lianji(Id, Count) ->
    OldCount = get_main_ins_data(Id),
    if
        Count > OldCount ->
            Count;
        true ->
            OldCount
    end.

create_safe_ets() ->
    [
     %%%% 映射scene3Id 到当前对应的场景id
    safe_ets:new(?main_ins_3idmap,  [?named_table, ?public ,{?read_concurrency, ?true}, {?write_concurrency, ?true}]),
    safe_ets:new(?main_ins_data,  [?named_table, ?public ,{?read_concurrency, ?true}, {?write_concurrency, ?true}])
    ].

%%load_config_meta() ->
%%    [
%%        #config_meta{record = #main_ins_cfg{},
%%            fields = ?record_fields(main_ins_cfg),
%%            file = "main_ins.txt",
%%            keypos = #main_ins_cfg.id,
%%            groups = [#main_ins_cfg.type, #main_ins_cfg.chapter_id],
%%            verify = fun verify/1},
%%        #config_meta{record = #main_prize_cfg{},
%%            fields = ?record_fields(main_prize_cfg),
%%            file = "ins_lvl_prize.txt",
%%            keypos = [#main_prize_cfg.ins_id, #main_prize_cfg.match_level],
%%            verify = fun ins_lvl_prize_verify/1},
%%        #config_meta{record = #main_ins_shop_cfg{},
%%            fields = ?record_fields(main_ins_shop_cfg),
%%            file = "main_ins_shop.txt",
%%            keypos = #main_ins_shop_cfg.id,
%%            verify = fun verify_main_instance_shop/1},
%%        #config_meta{record = #main_chapter_star_prize_cfg{},
%%            fields = ?record_fields(main_chapter_star_prize_cfg),
%%            file = "main_chapter_star_prize.txt",
%%            keypos = #main_chapter_star_prize_cfg.id,
%%            verify = fun verify_main_instance_chapter/1}
%%    ].
%%
%%
%%verify(#main_ins_cfg{id = Id, ins_id = InsId, chapter_id=_Chapter, type = Type, sub_type = Diff,
%%    pervious = Per, limit_level = LimitLev, cost = Cost, next = NextId, limit_pervious = UnLockId,
%%    is_monster_match_level = IsMatchLevel}) ->
%%    ?check(load_cfg_scene:is_exist_scene_cfg(Id), "main_ins.txt [~p] 没有找到对应 scene id ", [Id]),
%%    ?check(load_cfg_scene:get_config_type(Id) =:= ?SC_TYPE_MAIN_INS, "main_ins.txt [~p] scene 不是单人副本类型", [Id]),
%%    ?check(game_def:is_valid_ins_type(Type), "main_ins.txt [~w] type [~w] 无效", [Id, Type]),
%%    ?check(?is_pos_integer(InsId), "main_ins.txt [~p] ins_id ~p 无效", [Id, InsId]),
%%    if
%%
%%        Type =:= ?T_INS_MAIN orelse Type =:= ?T_INS_FREE ->
%%            ?check(scene_def:is_valid_main_in_difficulty(Diff), "main_ins.txt [~w] ins_id ~w 无效", [Id, Diff]);
%%        ?true -> ignore
%%    end,
%%    ?check(load_cfg_scene:is_exist_scene_cfg(UnLockId) orelse UnLockId=:=?undefined, "main_ins.txt limit_pervious[~p] 没有找到对应 scene id ", [UnLockId]),
%%    ?check(com_util:is_valid_uint16(LimitLev), "main_ins.txt[~w] limit_lev ~w 无效", [Id, LimitLev]),
%%
%%
%%    ?check(cost:is_exist_cost_cfg(Cost), "main_ins.txt [~w] cost:~w 没有找到! ", [Id, Cost]),
%%    ?check(?IS_BOOLEN(IsMatchLevel), "main_ins.txt [~p] is_monster_match_level ~p 无效格式", [Id, IsMatchLevel]),
%%
%%    ?check(Per =/= Id, "main_ins.txt [~w] pervious ~w 不能和自己", [Id, Per]),
%%    ?check(Per =:= 0 orelse is_exist_main_ins_cfg(Per), "main_ins.txt [~w] pervious ~w 没有找到 ", [Id, Per]),
%%    ?check(Per =:= 0 orelse load_cfg_scene:is_exist_scene_cfg(Per), "main_ins.txt [~w] pervious 没有找到对应 ~w scene id ", [Id, Per]),
%%    case NextId of
%%        ?none ->
%%            %%?check(length(RP) >= 8, "main_ins.txt [~p] random_prize 格式必须>=8 ~p", [Id, RP]),
%%            %%[check_random_prize(Id, XX) || XX <- RP],
%%            ?check(load_cfg_scene:get_config_type(Id) =:= ?SC_TYPE_MAIN_INS, "main_ins.txt [~p] scene 类型不正确 ", [Id]);
%%        _ ->
%%            ?check(NextId =/= Id, "main_ins.txt [~p] next ~p 不能和自己", [Id, NextId]),
%%            ?check(is_exist_main_ins_cfg(NextId), "main_ins.txt [~p] next ~p 没有找到 ", [Id, NextId]),
%%            ?check(load_cfg_scene:is_exist_scene_cfg(NextId), "main_ins.txt [~p] next 没有找到对应 ~p scene id ", [Id, NextId]),
%%            ?check(load_cfg_scene:get_config_type(NextId) =:= ?SC_TYPE_MAIN_INS, "main_ins.txt [~p] next  ~p scene type 不是单人副本类型", [Id, NextId])
%%    end;
%%verify(_R) ->
%%    ?ERROR_LOG("signin 配置　错误格式"),
%%    exit(bad).
%%
%%ins_lvl_prize_verify(#main_prize_cfg{id = Id, ins_id = InsId, match_level = MatchLevel, pass_prize = PrizeId}) ->
%%    ?check(is_integer(Id), "ins_lvl_prize.txt [~p] 没有找到对应 id ", [Id]),
%%    ?check(load_cfg_scene:is_exist_scene_cfg(InsId), "ins_lvl_prize.txt [~p] 没有找到对应 ins id ", [InsId]),
%%    ?check(is_integer(MatchLevel), "ins_lvl_prize.txt [~p] 没有找到对应 match_level ", [MatchLevel]),
%%    ?check(prize:is_exist_prize_cfg(PrizeId) orelse PrizeId =:= 0, "ins_lvl_prize.txt [~p] pass_prize:~p 没有找到! ", [Id, PrizeId]).
%%
%%verify_main_instance_shop(#main_ins_shop_cfg{id=Id, price=Prize}) ->
%%    % ?check(goods:is_exist_goods_cfg(Id),"main_ins_shop.txt中， [~p] id: ~p 配置无效。", [Id, Id]),
%%    ?check(Prize > 0,"main_ins_shop.txt中， [~p] price~p 配置无效。", [Id, Prize]).
%%
%%verify_main_instance_chapter(#main_chapter_star_prize_cfg{id=Id, prize=Prize}) ->
%%    ?check(Prize > 0,"main_chapter_star_prize.txt中， [~p] price~p 配置无效。", [Id, Prize]).