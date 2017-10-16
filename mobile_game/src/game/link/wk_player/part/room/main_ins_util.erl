%%%-------------------------------------------------------------------
%%% @author yujian
%%% @doc
%%%-------------------------------------------------------------------
-module(main_ins_util).

-include("inc.hrl").
-include("player.hrl").
-include("load_vip_right.hrl").
-include("load_vip_new_cfg.hrl").
-include("item_bucket.hrl").
-include("day_reset.hrl").
-include("scene.hrl").
-include("system_log.hrl").

-export([
    ins_cost_times/1, 
    ins_cost/1,    %加血、复活消耗
    calculate_drop_prize/2,  %计算副本掉落道具
    init_relive_times/0,
    leave_main_instance/0,
    team_relive_cost/0
]).

-define(TEAM_RELIVE_COST, 5).

on_day_reset(_) ->
    attr_new:set(?pd_main_instance_relive_times, init_relive_times()).

init_relive_times() ->
    {0, []}.

%% @doc 进入场景时，初始化复活次数。1.一个副本的第二个场景 2.其他情况
ins_cost_times(SceneId) ->
    MainIntanceId = load_cfg_main_ins:get_ins_id(SceneId),
    leave_main_instance(),
    %MainIntanceId = load_cfg_main_ins:get_main_instance_id(SceneId),
    case MainIntanceId of
        ?none -> ok;
        _ ->
            case get(?pd_ins_id) of
                MainIntanceId ->
                    %put(?pd_ins_id, MainIntanceId);
                    pass;
                _ ->
                    put(?pd_ins_id, MainIntanceId),
                    put(?pd_ins_die_count, 0),
                    attr_new:begin_sync_attr(),
                    %attr_new:set(?pd_attr_add_hp_times, 0),
                    init_add_hp_times(SceneId),
                    init_relive_times_by_insid(MainIntanceId),
                    attr_new:end_sync_attr()
            end
    end.
leave_main_instance() ->
    %?DEBUG_LOG("leave_main_instance------------------"),
    erase(?pd_ins_id).

init_add_hp_times(SceneId) ->
    CurrentId = load_cfg_main_ins:get_main_instance_id(SceneId),
    % ?DEBUG_LOG("init_add_hp_times-------------------:~p",[CurrentId]),
    case load_cfg_main_ins:is_boss_room(CurrentId) of
        ?TRUE ->
            % ?DEBUG_LOG("init add_hp ----------------------1:~p", [attr_new:get(?pd_attr_add_hp_times, 0)]),
            attr_new:set(?pd_attr_add_hp_times, attr_new:get(?pd_attr_add_hp_times, 0));
        _ -> 
            % ?DEBUG_LOG("init add add_hp-----------------------2"),
            attr_new:set(?pd_attr_add_hp_times, 0)
    end.


init_relive_times_by_insid(MainIntanceId) ->
    %?DEBUG_LOG("MainIntanceId---------3-------------:~p",[MainIntanceId]),
    {Num, RevlieList} = attr_new:get(?pd_main_instance_relive_times, init_relive_times()),
    case lists:keyfind(MainIntanceId, 1, RevlieList) of
        ?false ->
            attr_new:set(?pd_attr_relive_times, Num),
            attr_new:set(?pd_main_instance_relive_times, {Num, [{MainIntanceId, 0} | RevlieList]});
        {_, OldNum} ->
            attr_new:set(?pd_main_instance_relive_times, {Num, lists:keyreplace(MainIntanceId, 1, RevlieList, {MainIntanceId, 0})}),
            attr_new:set(?pd_attr_relive_times, Num)
    end.
    %?DEBUG_LOG("RevlieList-------222222------------------:~p",[get(?pd_main_instance_relive_times)]).


update_relive_times(MainIntanceId) ->
    {Num, RevlieList} = attr_new:get(?pd_main_instance_relive_times, init_relive_times()),
    case lists:keyfind(MainIntanceId, 1, RevlieList) of
        ?false ->
            attr_new:set(?pd_main_instance_relive_times, {Num, [{MainIntanceId, 0} | RevlieList]}),
            Num;
        {_, N} ->
            NewN = N + 1,
            %?DEBUG_LOG("NewN-------------------------------:~p",[NewN]),
            %attr_new:set(?pd_attr_relive_times, NewN + Num),
            attr_new:set(?pd_main_instance_relive_times, {Num, lists:keyreplace(MainIntanceId, 1, RevlieList, {MainIntanceId, NewN})}),
            NewN + Num
    end.
    %?DEBUG_LOG("RevlieList------11111111-------------------:~p",[get(?pd_main_instance_relive_times)]).



get_relive_times(MainIntanceId) ->
    {N, RevlieList} = attr_new:get(?pd_main_instance_relive_times, init_relive_times()),
    %?DEBUG_LOG("N-----:~p-----RevlieList----:~p",[N, RevlieList]),
    case lists:keyfind(MainIntanceId, 1, RevlieList) of
        ?false ->
            0;
        {_, Num} ->
            Num
    end.


%% @doc 复活，加血次数+1  (复活消耗的计算方法先使用免费复活次数，再消耗复活石，然后开始消耗钻石的数量)
%% 8
%% [1,,,,,8]
ins_cost(Action) ->
    %?DEBUG_LOG("Action-------------------------:~p",[Action]),
    Vip = attr_new:get_vip_lvl(),
    %VipCFG = load_vip_right:lookup_vip_right_cfg(Vip),
    VipCFG = load_vip_new:get_vip_cfg_by_vip_level(Vip),
    VipRevlieList = VipCFG#vip_cfg.relive,
    VipAddHpList = VipCFG#vip_cfg.add_hp_limit,
    {ReliveNum, RevlieList} = attr_new:get(?pd_main_instance_relive_times),
    {Count, Times} = 
    case Action of
        ?relive ->
            %{length(VipCFG#vip_right_cfg.relive), attr_new:get(?pd_attr_relive_times)};
            %{load_vip_right:get_free_times(VipRevlieList), ReliveNum};
            {load_vip_new:get_vip_new_free_times(VipRevlieList), ReliveNum};
        add_hp ->
            %{length(VipCFG#vip_right_cfg.add_hp_limit), attr_new:get(?pd_attr_add_hp_times,0)}
            %{load_vip_right:get_free_times(VipAddHpList), attr_new:get(?pd_attr_add_hp_times,0)}
            {load_vip_new:get_vip_new_free_times(VipAddHpList), attr_new:get(?pd_attr_add_hp_times,0)}
    end,
    IsSet = 
    if
        Times + 1 > Count ->
            case Action of
                ?relive -> 
                    BagBucket = game_res:get_bucket(?BUCKET_TYPE_BAG),      %%复活石复活
                    ReStoneNum = goods_bucket:count_item_size(BagBucket, 0, 2010),
                    if
                        ReStoneNum > 0 ->
                            game_res:del([{2010, 1}], ?FLOW_REASON_FUBEN_RELIVE),
                            restone;
                        true ->
                            MainIntanceId = get(?pd_ins_id),
                            %?DEBUG_LOG("MainIntanceId--------------------:~p",[MainIntanceId]),
                            N = load_cfg_main_ins:get_main_instance_relive_num(MainIntanceId),
                            MaxCount = N + lists:last(VipRevlieList) + Count,
                            %?DEBUG_LOG("N---:~p-----n2 ---:~p----Count-0--:~p",[N, lists:last(VipRevlieList), Count]),
                            UsedN = get_relive_times(MainIntanceId),
                            %?DEBUG_LOG("MaxCount------------------:~p---UsedN---:~p",[MaxCount, UsedN]),
                            if
                                UsedN >= MaxCount ->
                                    {error, ?ERR_MAX_COUNT};
                                true ->
                                    Dn = load_cfg_main_ins:get_main_instance_relive_cost_by_num(MainIntanceId, UsedN+1),
                                    case game_res:can_del([{?PL_DIAMOND, Dn}]) of
                                        ok ->
                                            NewUsedN = update_relive_times(MainIntanceId),
                                            %?DEBUG_LOG("Dn-----------:~p-----NewUsedN----:~p",[Dn, NewUsedN]),
                                            game_res:del([{?PL_DIAMOND, Dn}], ?FLOW_REASON_FUBEN_RELIVE),
                                            {relive_diamon, NewUsedN};
                                        {error, _Other} ->
                                            {error, ?ERR_COST_DIAMOND_FAIL}
                                    end
                            end
                    end;
                add_hp ->
                    NewTimes = Times + 1,
                    %CostDiamondNum = lists:nth(NewTimes, RevlieList),
                    %VipAddHpSize = length(VipRevlieList),
                    VipAddHpSize = length(VipAddHpList),
                    %?DEBUG_LOG("NewTimes------:~p-----VipAddHpSize---:~p",[NewTimes, VipAddHpSize]),
                    if
                        NewTimes =< VipAddHpSize ->
                            CostDiamondNum = lists:nth(NewTimes, VipAddHpList),
                            case game_res:can_del([{?PL_DIAMOND, CostDiamondNum}]) of
                                ok ->
                                    game_res:del([{?PL_DIAMOND, CostDiamondNum}], ?FLOW_REASON_FUBEN_ADD_HP),
                                    {addhp_diamon, NewTimes};
                                {error, _Other} ->
                                    {error, ?ERR_COST_DIAMOND_FAIL}
                            end;
                        true ->
                            {error, ?ERR_MAX_COUNT}
                    end
                    
            end;
        true ->
            ok
    end,
    attr_new:begin_sync_attr(),
    %?DEBUG_LOG("IsSet------------------------------:~p",[IsSet]),
    Return = 
    case IsSet of
        ok ->
            case Action of
                ?relive ->
                    NewReliveNum = erlang:min(Count, ReliveNum + 1),
                    %?DEBUG_LOG("NewReliveNum---------------------------------:~p",[NewReliveNum]),
                    attr_new:set(?pd_attr_relive_times, NewReliveNum),
                    attr_new:set(?pd_main_instance_relive_times, {NewReliveNum, RevlieList});
                add_hp ->
                    player:set_full_hp(),
                    player:set_full_mp(),
                    attr_new:set(?pd_attr_add_hp_times, Times + 1),
                    attr_new:set(?pd_attr_add_hp_mp_cd, com_time:now())
            end,
            ok;
        {relive_diamon, C} ->
            %?DEBUG_LOG("C---------------------------------:~p",[C]),
            attr_new:set(?pd_attr_relive_times, C),
            ok;
        {addhp_diamon, C2} ->
            player:set_full_hp(),
            player:set_full_mp(),
            attr_new:set(?pd_attr_add_hp_times, C2),
            attr_new:set(?pd_attr_add_hp_mp_cd, com_time:now()),
            ok;
        restone ->
            case Action of
                ?relive ->
                    NewReliveNum = erlang:min(Count, ReliveNum + 1),
                    %?DEBUG_LOG("NewReliveNum---------------------------------:~p",[NewReliveNum]),
                    attr_new:set(?pd_attr_relive_times, NewReliveNum),
                    attr_new:set(?pd_main_instance_relive_times, {NewReliveNum, RevlieList}),
                    ok;
                _ ->
                    pass
            end;
        diamon ->
            ok;
        {error, Reply} ->
            {error, Reply}
     end,
    attr_new:end_sync_attr(),
    Return.

calculate_drop_prize(SceneList, PlayerLevel) ->
    FunFoldl = fun(SceneId, DropList) ->
        case load_cfg_main_ins:get_scene_tag(SceneId, PlayerLevel) of
            [] -> DropList;
            TagList ->
                SceneDropList = lists:append([prize:get_random(PrizeId) || {_TagId, PrizeId} <- TagList]),
                NewSceneDropList = lists:foldl(
                    fun({ItemBid, ItemNum, _Rate}, AllDropList) ->
                        case lists:keyfind(ItemBid, 1, AllDropList) of
                            false -> [{ItemBid, ItemNum} | AllDropList];
                            {ItemBid, Num} ->
                                lists:keyreplace(ItemBid, 1, AllDropList, {ItemBid, Num + ItemNum})
                        end
                    end,
                    DropList,
                    SceneDropList),
                [NewSceneDropList | DropList]
        end
    end,
    lists:append(lists:foldl(FunFoldl, [], SceneList)).

team_relive_cost() ->
    BagBucket = game_res:get_bucket(?BUCKET_TYPE_BAG),      %%复活石复活
    ReStoneNum = goods_bucket:count_item_size(BagBucket, 0, 2010),
    if
        ReStoneNum > 0 ->
            game_res:del([{2010, 1}], ?FLOW_REASON_FUBEN_RELIVE),
            ?true;
        true ->
            case game_res:can_del([{?PL_DIAMOND, ?TEAM_RELIVE_COST}]) of
                ok ->
                    game_res:del([{?PL_DIAMOND, ?TEAM_RELIVE_COST}], ?FLOW_REASON_FUBEN_RELIVE),
                    ?true;
                {error, _Other} ->
                    {error, ?ERR_COST_DIAMOND_FAIL}
            end
    end.