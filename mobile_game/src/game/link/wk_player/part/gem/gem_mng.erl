%%% coding:utf-8
%%%-------------------------------------------------------------------
%%% @author zlb
%%% @doc 宝石模块 
%%%
%%% @end
%%%-------------------------------------------------------------------

-module(gem_mng).

-include_lib("pangzi/include/pangzi.hrl").


%-define(com_debug_log, ok).
-include("inc.hrl").
-include("player.hrl").
-include("player_mod.hrl").
-include("gem_mng_reply.hrl").
-include("item.hrl").
-include("item_bucket.hrl").
-include("item_new.hrl").
-include("handle_client.hrl").
-include("load_cfg_gem.hrl").
-include("../wonderful_activity/bounty_struct.hrl").
-include("system_log.hrl").
-include("achievement.hrl").


-define(GEM_MAX_NEXT_LEVEL, 0).

create_mod_data(_SelfId) -> ok.


load_mod_data(_PlayerId) -> ok.


init_client() -> ignore.

view_data(Msg) -> Msg.

online() -> ok.

offline(_PlayerId) -> ok.

save_data(_) -> ok.

load_db_table_meta() -> [].

handle_client({Pack, Arg}) ->
    handle_client(Pack, Arg).

handle_client(?MSG_GEM_UPDATE, {GemId, Count}) ->
    Pds = player_eng:tran_assets_pds_mix([?pd_bag]),
    player_eng:transaction_start(Pds),
    ReplyNum = 
    case gem_update(GemId, Count) of
        {ok, _NewGemId} ->
            player_eng:transaction_commit(),
            %NGemId = NewGemId,
            bounty_mng:do_bounty_task(?BOUNTY_TASK_HECHENG_GEM, 1),
            event_eng:post( ?ev_gem_he_cheng, {?ev_gem_he_cheng,0}, Count ),
            daily_task_tgr:do_daily_task({?ev_gem_he_cheng, 0}, Count),
            ?REPLY_MSG_GEM_UPDATE_OK;
        {error, Reason} ->
            player_eng:transaction_rellback(),
            %NGemId = 0,
            case Reason of
                diamond_not_enough ->  %% 钻石不足
                    ?REPLY_MSG_GEM_UPDATE_1;
                cost_not_enough ->     %% 花费不足
                    ?REPLY_MSG_GEM_UPDATE_2;
                gem_lev_max ->         %% 宝石等级达到最大
                    ?REPLY_MSG_GEM_UPDATE_3;
                bucket_full ->         %% 背包已满
                    ?REPLY_MSG_GEM_UPDATE_4;
                _E ->
                    ?debug_log_equip("gem_update ~w", [Reason]),
                    ?REPLY_MSG_GEM_UPDATE_255
            end      
    end,
    %?DEBUG_LOG("GemId----:~p---Count---:~p---REplyNum---:~p",[GemId, Count, ReplyNum]),
    ?player_send(gem_sproto:pkg_msg(?MSG_GEM_UPDATE, {ReplyNum}) );


handle_client(?MSG_EPIC_GEM_UP, {BucketType, QemId, GemId, GemList}) ->
    Pds = player_eng:tran_assets_pds_mix([?pd_bag]),
    player_eng:transaction_start(Pds),
    %% 升级玩家身上装备的宝石时，要刷新属性
    attr_new:begin_sync_attr(),
    Ret = equip_epic_gem_up(BucketType, QemId, GemId, GemList),
    attr_new:end_sync_attr(),
    ?INFO_LOG("Ret:~p" , [Ret]),
    ReplyNum =
        case Ret of
            {ok, _NewGemId} ->
                bounty_mng:do_bounty_task(?BOUNTY_TASK_SHENGJI_GEM, 1),
                player_eng:transaction_commit(),
                ?REPLY_MSG_GEM_UPDATE_OK;
            {error, Reason} ->
                player_eng:transaction_rellback(),
                case Reason of
                    diamond_not_enough ->  %% 钻石不足
                        ?REPLY_MSG_GEM_UPDATE_1;
                    cost_not_enough ->     %% 花费不足
                        ?REPLY_MSG_GEM_UPDATE_2;
                    gem_lev_max ->         %% 宝石等级达到最大
                        ?REPLY_MSG_GEM_UPDATE_3;
                    _E ->
                        ?debug_log_equip("gem_update ~w", [Reason]),
                        ?REPLY_MSG_GEM_UPDATE_255
                end
        end,

    ?player_send(gem_sproto:pkg_msg(?MSG_EPIC_GEM_UP, {ReplyNum}) );

handle_client(Mod, Msg) ->
    ?ERROR_LOG("no known msg Mod:~p Msg:~p", [gem_sproto:to_s(Mod), Msg]).

handle_msg(FromMod, Msg) ->
    ?ERROR_LOG("~p recv a unknown msg ~p from ~p", [?pname(), Msg, FromMod]).

handle_frame(_) -> ok.


%% 宝石升级
gem_update(GemId, Count)->
    ?DEBUG_LOG("gem update----------------------:~p",[{GemId, Count}]),
    achievement_mng:do_ac2(?zhennuli, 0, Count),
    BagBucket = game_res:get_bucket(?BUCKET_TYPE_BAG),
    game_res:set_res_reasion(<<"宝石升级">>),
    case goods_bucket:find_goods(BagBucket, by_bid, {GemId}) of
        #item_new{id = _Id, bid = Bid, bind = _Bind,quantity = Qua, type = Type} ->
            if
                Type /= ?ITEM_TYPE_GEM ->
                    %?DEBUG_LOG("gem 1-----------------------------"),
                    {error, not_gem};
                Qua < ?UPDATE_GEM_NEED_NUM ->
                    %?DEBUG_LOG("gem 2-----------------------------"),
                    {error, gem_not_enough};
                ?true ->
                    %?DEBUG_LOG("Bid--------------------:~p",[Bid]),
                    NGemBid = Bid + 1,
                    case load_cfg_gem:lookup_gem_cfg(NGemBid) of
                        #gem_cfg{up_cost = Cost} ->
                            case {game_res:can_del([{GemId, ?UPDATE_GEM_NEED_NUM * Count}]), game_res:can_give([{NGemBid, Count}])} of
                                {ok,ok} ->
                                    CostList = load_cost:get_cost_list(Cost, Count),
                                    case game_res:can_del(CostList) of
                                        {error, _} ->
                                            cost_not_enough;
                                        ok ->
                                            Lev = load_cfg_gem:get_gem_lev(NGemBid),
                                            bounty_mng:count_update_gem(Lev, Count),
                                            achievement_mng:do_ac2(?yuelaiyueda, Lev, Count),
                                            open_server_happy_mng:update_gem(Lev, Count),
                                            game_res:del(CostList, ?FLOW_REASON_GEM_UPDATE),
                                            game_res:del([{GemId, ?UPDATE_GEM_NEED_NUM * Count}], ?FLOW_REASON_GEM_UPDATE),
                                            game_res:give([{NGemBid, Count}], ?FLOW_REASON_GEM_UPDATE),
                                            {ok, NGemBid}
                                    end;
                                _ ->
                                    {error, gem_lev_max}
                            end;
                        _ ->
                            %?DEBUG_LOG("gem 3--------------------"), 
                            {error, gem_lev_max}
                    end
            end;
        _A -> 
            %?DEBUG_LOG("gem 4--------------------------:~p",[A]),
            {error, gem_not_found}
    end.

%% 史诗宝石升级
equip_epic_gem_up( BucketType, EqmId, GemId, GemList ) ->
    CostGemExp = get_gemlist_exp(GemList),
    CostList = get_gemlist_cost(GemList),
    DelGemList = get_del_gem_list(GemList),
    case EqmId of
        %% 背包中的宝石
        0 ->
            GemItem = get_epic_gem(?BUCKET_TYPE_BAG, GemId),
            case GemItem of
                #item_new{id = _Id, bid = Bid, bind = _Bind, quantity = 1, type = Type} ->
                    if
                        Type /= ?ITEM_TYPE_GEM ->
                            {error, not_gem};
                        ?true ->
%%                            CurExp = item_new:get_field(GemItem, ?item_epic_gem_exp),
                            CurExp = item_new:get_item_new_field_value_by_key(GemItem, ?item_use_data, ?item_epic_gem_exp, 0),
                            ?DEBUG_LOG("CurExp:~p", [CurExp]),
                            TotalExp = CostGemExp + CurExp,

                            case load_cfg_gem:lookup_gem_cfg(Bid) of
                                #gem_cfg{up_exp = UpExp} ->
                                    if
                                        TotalExp < UpExp ->
                                            case {game_res:can_del(DelGemList), game_res:can_del(CostList)} of
                                                {ok, ok} ->
                                                    game_res:del(CostList, ?FLOW_REASON_GEM_UPDATE),
                                                    game_res:del(DelGemList, ?FLOW_REASON_GEM_UPDATE),

                                                    DefaultKeyVal =
                                                        [
                                                            {?item_use_data, [{?item_epic_gem_exp, TotalExp}]}
                                                        ],
                                                    NewGoods = item_new:set_fields(GemItem, DefaultKeyVal),

                                                    %% 同步背包
                                                    GoodsBucket = game_res:get_bucket(?BUCKET_TYPE_BAG),
                                                    goods_bucket:begin_sync(GoodsBucket),
                                                    NewGoodsBucket = goods_bucket:update(GoodsBucket, NewGoods),
                                                    goods_bucket:end_sync(NewGoodsBucket),
                                                    {ok, GemId};
                                                _ ->
                                                    {error, cost_not_enough}
                                            end;
                                        true ->
                                            {NGemBid, NExp} = gem_add_exp(Bid, TotalExp, UpExp),
                                            case {game_res:can_del(DelGemList), game_res:can_del(CostList)} of
                                                {ok, ok} ->
                                                    NGemItem1 = GemItem#item_new{bid = NGemBid},
                                                    DefaultKeyVal =
                                                        [
                                                            {?item_use_data, [{?item_epic_gem_exp, NExp}]}
                                                        ],
                                                    NGemItem2 = item_new:set_fields(NGemItem1, DefaultKeyVal),

                                                    game_res:del(DelGemList, ?FLOW_REASON_GEM_UPDATE),
                                                    game_res:del(CostList, ?FLOW_REASON_GEM_UPDATE),
                                                    %% 同步背包
                                                    GoodsBucket = game_res:get_bucket(?BUCKET_TYPE_BAG),
                                                    goods_bucket:begin_sync(GoodsBucket),
                                                    NewGoodsBucket = goods_bucket:update(GoodsBucket, NGemItem2),
                                                    goods_bucket:end_sync(NewGoodsBucket),
                                                    {ok, NGemItem2#item_new.id};
                                                _ ->
                                                    {error, cost_not_enough}
                                            end
                                    end;

                                _ ->
                                    %?DEBUG_LOG("gem 3--------------------"),
                                    {error, gem_lev_max}
                            end
                    end;
                {error, Err} ->
                    {error, Err}
            end;
        %% todo 装备中的宝石
        _ ->
            EqmItem = equip_system:get_equip(BucketType, EqmId),
            case item_new:get_item_new_field_value_by_key(EqmItem,?item_use_data, ?item_equip_epic_gem_slot, 0) of
                0 ->
                    {error, no_epic_solt};
                _ ->
                    case item_new:get_item_new_field_value_by_key(EqmItem, ?item_use_data, ?item_equip_epic_gem, 0) of
                        0 ->
                            {error, no_gem};
                        GemBid ->
                            case load_cfg_gem:is_epic_Gem(GemBid) of
                                ?true ->
                                    Exp = item_new:get_item_new_field_value_by_key(EqmItem, ?item_use_data, ?item_equip_epic_gem_exp, 0),
                                    CanGetExp = CostGemExp + Exp,
                                    case load_cfg_gem:lookup_gem_cfg(GemBid) of
                                        #gem_cfg{up_exp = UpExp} ->
                                            if
                                                CanGetExp < UpExp ->
                                                    case {game_res:can_del(DelGemList), game_res:can_del(CostList)} of
                                                        {ok, ok} ->
                                                            game_res:del(CostList, ?FLOW_REASON_GEM_UPDATE),
                                                            game_res:del(DelGemList, ?FLOW_REASON_GEM_UPDATE),
                                                            DefaultKeyVal =
                                                                [
                                                                    {?item_use_data, [
                                                                        {?item_equip_epic_gem_slot, 1},
                                                                        {?item_equip_epic_gem, GemBid},
                                                                        {?item_equip_epic_gem_exp, CanGetExp}
                                                                    ]}
                                                                ],
                                                            NEqmItem = item_equip:update_attr_do_epic_gem(EqmItem, DefaultKeyVal),
%%                                                            NEqmItem = item_new:set_field(EqmItem, ?item_equip_epic_gem_exp, CanGetExp),
                                                            %% 同步装备
                                                            GoodsBucket = game_res:get_bucket(BucketType),
                                                            goods_bucket:begin_sync(GoodsBucket),
                                                            NewGoodsBucket = goods_bucket:update(GoodsBucket, NEqmItem),
                                                            goods_bucket:end_sync(NewGoodsBucket),
                                                            {ok, EqmId};
                                                        _ ->
                                                            {error, cost_not_enough}
                                                    end;
                                                true ->
                                                    {NGemBid, NExp} = gem_add_exp(GemBid, CanGetExp, UpExp),
                                                    ?INFO_LOG("NewGem:~p", [{NGemBid, NExp}]),
                                                    case {game_res:can_del(DelGemList), game_res:can_del(CostList)} of
                                                        {ok,ok} ->
                                                            game_res:del(CostList, ?FLOW_REASON_GEM_UPDATE),
                                                            game_res:del(DelGemList, ?FLOW_REASON_GEM_UPDATE),
                                                            DefaultKeyVal =
                                                                [
                                                                    {?item_use_data, [
                                                                        {?item_equip_epic_gem_slot, 1},
                                                                        {?item_equip_epic_gem, NGemBid},
                                                                        {?item_equip_epic_gem_exp, NExp}
                                                                    ]}
                                                                ],
                                                            NEqmItem = item_equip:update_attr_do_epic_gem(EqmItem, DefaultKeyVal),
%%                                                            NEqmItem = item_new:set_fields(EqmItem, DefaultKeyVal),
                                                            %% 同步装备
                                                            GoodsBucket = game_res:get_bucket(BucketType),
                                                            goods_bucket:begin_sync(GoodsBucket),
                                                            NewGoodsBucket = goods_bucket:update(GoodsBucket, NEqmItem),
                                                            goods_bucket:end_sync(NewGoodsBucket),
                                                            {ok, EqmId};
                                                        _ ->
                                                            {error, cost_not_enough}
                                                    end
                                            end;

                                        _ ->
                                            %?DEBUG_LOG("gem 3--------------------"),
                                            {error, gem_lev_max}
                                    end;
                                ?false ->
                                    {error, is_normal_gem}
                            end
                    end
            end
    end.

gem_add_exp(GemBid, Exp, UpExp) ->
    NGemBid = load_cfg_gem:get_next_level_id_by_bid(GemBid),
    if
        NGemBid =:= ?GEM_MAX_NEXT_LEVEL ->
            ?INFO_LOG("gem_add_exp2:~p",[{GemBid, Exp}]),
            {GemBid, Exp};
        true ->
            if
                Exp < UpExp ->
                    ?INFO_LOG("gem_add_exp1:~p",[{GemBid, Exp}]),
                    {GemBid, Exp};
                true ->
                    NExp = Exp - UpExp,
                    NUpExp = load_cfg_gem:get_up_exp_by_bid(NGemBid),
                    ?INFO_LOG("gem_add_exp3:~p",[{NGemBid, NExp}]),
                    gem_add_exp(NGemBid, NExp, NUpExp)
            end
end.

get_gemlist_exp(GemList) ->
    ?INFO_LOG("GemList:~p", [GemList]),
    lists:foldl(
        fun({Id,Count},AllExp) ->
            Bid = get_bid_by_id(Id),
            Exp = load_cfg_gem:get_exp_by_bid(Bid),
            Exp * Count + AllExp
        end,
        0,
        GemList
    ).

get_gemlist_cost(GemList) ->
    lists:foldl(
        fun({Id,Count},NewCostList) ->
            Bid = get_bid_by_id(Id),
            CostId = load_cfg_gem:get_exp_cost_by_bid(Bid),
            CostList = load_cost:get_cost_list(CostId, Count),
            lists:append(CostList, NewCostList)
        end,
        [],
        GemList
    ).

get_epic_gem(BucketType, GoodsID) ->
    Goods =
        case BucketType of
            ?BUCKET_TYPE_BAG ->
                TempBucket = game_res:get_bucket(?BUCKET_TYPE_BAG),
                FindGoods = goods_bucket:find_goods(TempBucket, by_id, {GoodsID}),
                case item_new:get_main_type(FindGoods) of
                    ?val_item_main_type_goods -> FindGoods;
                    _ -> ret:error(no_goods)
                end;
            _ -> {error, no_goods}
        end,
    Goods.

get_bid_by_id(GoodsID) ->
    TempBucket = game_res:get_bucket(?BUCKET_TYPE_BAG),
    FindGoods = goods_bucket:find_goods(TempBucket, by_id, {GoodsID}),
    item_new:get_bid(FindGoods).

get_del_gem_list(GemList) ->
    %% {by_id,{GoodsID, num}
    lists:foldl(
        fun({Id,Count},Acc) ->
            [{by_id, {Id,Count}} | Acc]
        end,
        [],
        GemList
    ).

