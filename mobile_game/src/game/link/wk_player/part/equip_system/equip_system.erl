%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 27. 七月 2015 下午9:08
%%%-------------------------------------------------------------------
-module(equip_system).
-author("clark").

%% API
-export(
[
    restore_equip_system/0
    , get_takeon_equips_list/0
    , try_take_on_equip/2
    , try_take_off_equip/1
%%    , try_jianding/1
    , try_embed_gem/4
    , try_unembed_gem/3
    , try_unembed_all_gem/2
%%    , try_qiang_hua/3
%%    , try_he_cheng/6
%%    , try_ji_cheng/4
%%    , try_all_jianding/0
    , sync_equip_efts/0
    , get_equip_fast_efts/0             %% 获得装备特效快照
    , sync_skill_change_list/0
    , equip_slot/4
    , robot_embed_gem/2
    , equip_exchange/1
    , equip_one_key_exchange/1
    , equip_epic_slot/3                 %% 装备的史诗打孔
    , get_equip/2
    , try_embed_epic_gem/3
    , try_unembed_epic_gem/2
]).

%% 装备扩展附魔与萃取部分
-export([
    restore_equip_fumo_state/0
    , equip_fumo/5
    , activate_fumo_state/1
    , sync_fumo_mode_list/0
    , equip_cuiqu/2
]).


%% 玩家装备部位强化与洗炼部分
-export([
    restone_part_qiang_hua_list/0,
    restone_part_qiang_hua_attr/0,
    part_qiang_hua/2,
    equip_xilian/3
]).


-include("inc.hrl").
-include("player.hrl").
-include("bucket_interface.hrl").
-include("item_bucket.hrl").
-include("achievement.hrl").
-include("load_cfg_skill.hrl").
-include("../crown/crown_new.hrl").
-include("load_equip_expand.hrl").
-include("load_cfg_punchs.hrl").
-include("system_log.hrl").
-include("../part/wonderful_activity/bounty_struct.hrl").


-define(pd_do_he_cheng_equip_store, pd_do_he_cheng_equip_store).
-define(pd_stone_player_take_on_off_equip, pd_stone_player_take_on_off_equip). %% 玩家穿上脱去装备时保存装备信息

sync_equip_efts() ->
    %% 同步自已和其他玩家客户端
    IsInitCliendCompleted = attr_new:get(?pd_init_cliend_completed),
    case IsInitCliendCompleted of
        1 ->
            List = get_equip_fast_efts(),
            List1 = attr_new:get(?pd_part_qiang_hua_effect, []),
            List2 = List ++ List1,
%%            ?INFO_LOG("texiao List = ~p ++++++++++++++++", [List2]),
            ?player_send(player_sproto:pkg_msg(?MSG_PLAYER_EFFECT_CHANGE, {List2})),
            scene_mng:send_msg({?msg_update_equip_efts, get(?pd_idx), List2});
        0 ->
            ok
    end.

sync_skill_change_list() ->
    IsInitCliendCompleted = attr_new:get(?pd_init_cliend_completed),
    case IsInitCliendCompleted of
        1 ->
            %% 计算装备的技能修改集
            EquipBucket = game_res:get_bucket(?BUCKET_TYPE_EQM),
            EquipList = goods_bucket:get_goods(EquipBucket),
            SkillList = lists:foldl(
                fun(Equip, TempList) ->
                    TempList ++ item_equip:get_equip_skills(Equip)
                end,
                [],
                EquipList
            ),
            %% 计算龙纹的技能修改集
            LongWens = gb_trees:values(get(?pd_longwens_mng)),
            SkillCgList = lists:foldl(
                fun({LWId, Lvl, DressFlag}, TempList) ->
                    case DressFlag of
                        1 ->
                            case load_cfg_skill:lookup_long_wen_cfg({LWId, Lvl}) of
                                Cfg when is_record(Cfg, long_wen_cfg) ->
                                    TempList ++ Cfg#long_wen_cfg.skill_modifications;%erlang:tuple_to_list(Cfg#long_wen_cfg.skill_modifications);
                                _ ->
                                    TempList
                            end;
                        _ ->
                            TempList
                    end
                end,
                [],
                LongWens
            ),
            %% 计算皇冠技能的修改集
            AllCrownSkillList = get(?pd_crown_skill_list),
            CrownSkillCfgList =
                lists:foldl
                (
                    fun({SkillId, SkillLevel, _}, AccList) ->
                        case load_cfg_crown:get_crown_skill_modify_id(SkillId, SkillLevel) of
                            CfgId when is_integer(CfgId) andalso CfgId =/= 0 ->
                                [CfgId | AccList];
                            _ ->
                                AccList
                        end
                    end,
                    [],
                    AllCrownSkillList
                ),
            ?player_send(player_sproto:pkg_msg(?MSG_PLAYER_SKILL_CHANGE, {SkillList ++ SkillCgList ++ CrownSkillCfgList}));
        0 ->
            ok
    end.


get_equip_fast_efts() ->
    TotalList = attr_new:get(?pd_temp_equip_efts, []),
    Ret = 
    lists:foldl(fun
        ({_Bid, EftList}, Acc) ->
            EftList ++ Acc
    end,
    [],
    TotalList),
    Ret.


%% 还原装备穿戴情况
restore_equip_system() ->
%%    RestorEquip =
%%        fun
%%            (_ThisFun, []) -> ok;
%%            (ThisFun, [Equip | TailList]) ->
%%                item_equip:restore_take_on(Equip),
%%                ThisFun(ThisFun, TailList)
%%        end,
    EquipBucket = game_res:get_bucket(?BUCKET_TYPE_EQM),
    EquipList = goods_bucket:get_goods(EquipBucket),

    %% 添加装备属性并筛选出套装的个数（选择套装使用等级最低进行计算,需要计算套装的个数）
    {SuitId, SuitLevel, SuitCount} =
        lists:foldl
        (
            fun(Equip, {Id, MinLevel, Count}) ->
                item_equip:restore_take_on(Equip),
                SuitId = item_new:get_field(Equip, ?item_equip_suit_id, 0),
                Bid = item_new:get_bid(Equip),
                UseLvl = load_equip_expand:get_equip_cfg_level(Bid),
                case SuitId =/= 0 of
                    true ->
                        case UseLvl =< MinLevel of
                            true ->
                                {SuitId, UseLvl, Count+1};
                            _ ->
                                {SuitId, MinLevel, Count+1}
                        end;
                    _ ->
                        {Id, MinLevel, Count}
                end
            end,
            {0, 1, 0},
            EquipList
        ),
%%    ?INFO_LOG("restone:~p", [{SuitId, SuitLevel, SuitCount}]),
    case SuitId =:= 0 of
        false ->
            SuitAttrId = load_equip_expand:get_equip_suit_attrId(SuitId, SuitLevel, count_to_cfg_count(SuitCount)),
%%            ?INFO_LOG("1111111 SuitAttrId = ~p", [SuitAttrId]),
            case SuitAttrId of
                ?none ->
                    ok;
                _ ->
                    %%添加套装属性到角色身上
                    attr_new:player_add_attr_by_id(SuitAttrId),
                    ok
            end;
        _ ->
            pass
    end,
%%    RestorEquip(RestorEquip, EquipList),
    %%获取套装属性
%%    SuitEquipList = api:get_suit_equip_list(),
%%     ?INFO_LOG("SuitEquipList, ~p", [SuitEquipList]),
%%    SuitEquipLists = api:get_suit_equip_lists(SuitEquipList),
%%     ?INFO_LOG("SuitEquipLists, ~p", [SuitEquipLists]),
%%
%%    lists:foreach
%%    (
%%        fun(L) ->
%%            if
%%                L == [] -> ?FALSE;
%%                true ->
%%                    SuitEquipInfo = api:get_suit_equip_infos(L),
%%                     ?INFO_LOG("SuitEquipInfos,    ~p",[SuitEquipInfo]),
%%                    SuitEquipInfos = api:get_suit_num(SuitEquipInfo),
%%                     ?INFO_LOG("SuitEquipInfos,    ~p",[SuitEquipInfos]),
%%                    SuitAttrId = load_equip_expand:get_equip_suit_attrId(SuitEquipInfos),
%%                     ?INFO_LOG("SuitAttrID,       ~p", [SuitAttrId]),
%%                    case SuitAttrId of
%%                        ?FALSE ->
%%                            ok;
%%                        _ ->
%%                            %%添加套装属性到角色身上
%%                            attr_new:player_add_attr_by_id(SuitAttrId),
%%                            ok
%%                    end
%%            end
%%        end,
%%        SuitEquipLists
%%    ),
    ok.

%% 获得装备的套装信息
get_takeon_equips_list() ->
    GetEquipBids =
        fun
            (_ThisFun, RetList, _Bucket, _M, _M) -> RetList;
            (ThisFun, RetList, Bucket, I, M) ->
                Bid =
                    case goods_bucket:find_goods(Bucket, by_pos, {I}) of
                        {error, _} -> 0;
                        Goods -> Goods#item_new.bid
                    end,
                NewRetList = [Bid | RetList],
                ThisFun(ThisFun, NewRetList, Bucket, I + 1, M)
        end,
    EquipBucket = game_res:get_bucket(?BUCKET_TYPE_EQM),
    TotalSize = goods_bucket:get_field(EquipBucket, ?goods_bucket_size, 0),
    EquipBidList = GetEquipBids(GetEquipBids, [], EquipBucket, 1, TotalSize + 1),
    <<(iolist_to_binary([<<Bid:32>> || Bid <- EquipBidList]))/binary>>.

%% 鉴定
%%try_jianding(GoodsID) ->
%%%%    ?INFO_LOG("try_jianding"),
%%    game_res:set_res_reasion(<<"鉴定">>),
%%    BagBucket = game_res:get_bucket(?BUCKET_TYPE_BAG),
%%    case goods_bucket:find_goods(BagBucket, by_id, {GoodsID}) of
%%        {error, Error} -> {error, Error};
%%        Goods ->
%%            case item_equip:can_authenticate(Goods) of
%%                {error, _} -> {error, already_jd};
%%                _ ->
%%                    CostList = item_equip:get_authenticate_cost_list(Goods),
%%                    case game_res:can_del(CostList) of
%%                        {error, _} -> {error, diamond_not_enough};
%%                        _ ->
%%                            bounty_mng:do_bounty_task(?BOUNTY_TASK_JIANDING_EQUIP, 1),
%%
%%                            goods_bucket:begin_sync(BagBucket),
%%                            NewEquip = item_equip:authenticate(Goods),
%%                            NewBucket = goods_bucket:update(BagBucket, NewEquip),
%%                            goods_bucket:end_sync(NewBucket),
%%                            game_res:del(CostList, ?FLOW_REASON_EQUIP_JIANGDING),
%%                            ok
%%                    end
%%            end
%%    end.
%%%% 鉴定
%%try_all_jianding() ->
%%%%    ?INFO_LOG("try_all_jianding"),
%%    BagBucket = game_res:get_bucket(?BUCKET_TYPE_BAG),
%%    GoodsList = goods_bucket:get_goods(BagBucket),
%%    lists:foldl(
%%        fun
%%            (#item_new{id =ID}, Acc) ->
%%                try_jianding(ID),
%%                Acc;
%%            (_Other, Acc) ->
%%                Acc
%%        end,
%%        0,
%%        GoodsList),
%%    ok.

%% 尝试穿装备
try_take_on_equip(GoodsID, ToEquipPos) ->
%%    ?INFO_LOG("take_on 1power = ~p", [get(?pd_combat_power)]),
    game_res:set_res_reasion(<<"穿装备">>),
    Goods = get_equip(?BUCKET_TYPE_BAG, GoodsID),
    case Goods of
        {error, Error} ->
            {error, Error};
        #item_new{} ->
            case item_equip:can_take_on(Goods, ToEquipPos) of
                ok ->
                    %% 进行装备操作
                    %% ----------------------------
                    %% 移出装备栏的装备
                    BagBucket = game_res:get_bucket(?BUCKET_TYPE_BAG),
                    EquipBucket = game_res:get_bucket(?BUCKET_TYPE_EQM),
                    begin_suit_equip_attr(EquipBucket),
                    goods_bucket:begin_sync(BagBucket),
                    goods_bucket:begin_sync(EquipBucket),

                    Ret = goods_bucket:del(EquipBucket, item_by_pos, {ToEquipPos}),
                    %% 把背包栏的装备移出， 穿上
                    {NewPopBagBucket, NewEquips} = goods_bucket:del(BagBucket, item_by_id, {GoodsID}),
                    {RetBagBacket, RetEqupBacket, RetEquips} =
                        case Ret of
                            {error, _} ->
                                %% 装备栏原槽位为空 放进装备栏 保存
                                NewTakeEquips = item_equip:take_on(NewEquips),
                                {NewEquipBucket, _} = goods_bucket:add(EquipBucket, item_by_pos, {NewTakeEquips, ToEquipPos}),
                                {NewPopBagBucket, NewEquipBucket, NewEquips};

                            {NewPopEquipBucket, CurPopEquips} ->
                                %% 装备栏原槽位不为空 放进装备栏 放进背包栏 直接保存
                                CurPopEquips1 = item_equip:take_off(CurPopEquips),
                                take_off_equip_sub_qh_attr(CurPopEquips, ToEquipPos),
%%                                ?INFO_LOG("take_off power:~p", [get(?pd_combat_power)]),
                                NewTakeEquips = item_equip:take_on(NewEquips),
                                {NewPushEquipBucket, _} = goods_bucket:add(NewPopEquipBucket, item_by_pos, {NewTakeEquips, ToEquipPos}),
                                {NewPushBagBucket, _} = goods_bucket:add(NewPopBagBucket, item_by_id, {CurPopEquips1}),
                                {NewPushBagBucket, NewPushEquipBucket, CurPopEquips}
                        end,

                    goods_bucket:end_sync(RetBagBacket),
                    goods_bucket:end_sync(RetEqupBacket),
                    end_suit_equip_attr(NewEquips, RetEquips),
%%                    ?INFO_LOG("take_on 2power = ~p", [get(?pd_combat_power)]),

                    %% 增加强化属2
                    take_on_equip_add_qh_attr(Goods, ToEquipPos),

                    %% 派发相关事件
                    event_eng:post(?ev_dress_top_level_equ, {?ev_dress_top_level_equ, 0}, 1),
                    event_eng:post(?ev_dress_equ_suit, {?ev_dress_equ_suit, 0}, 1),
                    equip_system:sync_skill_change_list(),
                    ok;
                _ ->
                    {error, cant_put_on_eqm}
            end
    end.


%% 尝试脱装备
try_take_off_equip(GoodsID) ->
%%    ?INFO_LOG("take_off 1power = ~p", [get(?pd_combat_power)]),
    EquipBucket = game_res:get_bucket(?BUCKET_TYPE_EQM),
    Pos = goods_bucket:find_pos(EquipBucket, by_id, {GoodsID}),
    Goods = get_equip(?BUCKET_TYPE_EQM, GoodsID),
    case goods_bucket:can_del(EquipBucket, item_by_id, {GoodsID}) of
        {error, PopError} -> {error, PopError};
        _ ->
            BagBucket = game_res:get_bucket(?BUCKET_TYPE_BAG),
            case goods_bucket:can_add(BagBucket, item_by_id, {GoodsID}) of
                {error, PushError} -> {error, PushError};
                _ ->
                    begin_suit_equip_attr(EquipBucket),
                    goods_bucket:begin_sync(EquipBucket),
                    goods_bucket:begin_sync(BagBucket),

                    {NewPopEquipBucket, OnEquip} = goods_bucket:del(EquipBucket, item_by_id, {GoodsID}),
                    NewOffEquips = item_equip:take_off(OnEquip),
                    {NewPushBagBucket, _} = goods_bucket:add(BagBucket, item_by_id, {NewOffEquips}),

                    goods_bucket:end_sync(NewPushBagBucket),
                    goods_bucket:end_sync(NewPopEquipBucket),
                    end_suit_equip_attr(OnEquip, OnEquip),
                    equip_system:sync_skill_change_list(),
%%                    ?INFO_LOG("take_off 2power = ~p", [get(?pd_combat_power)]),
                    %% 减掉强化属性
                    take_off_equip_sub_qh_attr(Goods, Pos),
                    ok
            end
    end.

%% robot put on gems
robot_embed_gem(#item_new{} = Goods, #item_new{} = Gem) ->
    case item_equip:get_gem_empty_pos(Goods, 1) of
        {error, Error} -> {error, Error};
        SlotIndex ->
            case item_equip:can_take_on_gem(Goods, SlotIndex, Gem) of
                ok ->
                    item_equip:take_on_gem(Goods, SlotIndex, Gem);
                _Err ->
                    _Err
            end
    end;
robot_embed_gem(Goods, Gem) ->
    ?ERROR_LOG("error, bad format for goods:~p, gem:~p", [Goods, Gem]),
    ok.

%% 穿宝石
try_embed_gem(BucketType, GoodsID, PointIndex, GemId) ->
%%    ?INFO_LOG("try_embed_gem"),
    game_res:set_res_reasion(<<"穿宝石">>),
    Goods = get_equip(BucketType, GoodsID),
    case Goods of
        {error, Error} -> {error, Error};
        #item_new{} ->
            BagBucket = attr_new:get(?pd_goods_bucket),
            Gem = goods_bucket:find_goods(BagBucket, by_id, {GemId}),
            case Gem of
                #item_new{} ->
                    case item_equip:get_gem_empty_pos(Goods, 1) of
                        {error, Error} -> {error, Error};
                        SlotIndex ->
                            NewSlotIndex =
                                if
                                    PointIndex > 0 ->
                                        PointIndex;
                                    true ->
                                        SlotIndex
                                end,
                            %% 卸宝石
                            {NewGoods1, OldBid} = item_equip:take_off_gem(Goods, NewSlotIndex),
                            CostList = load_cfg_gem:get_cost_by_bid(Gem#item_new.bid),
                            case {game_res:can_del(CostList),item_equip:can_take_on_gem(NewGoods1, NewSlotIndex, Gem)} of
                                {ok,ok} ->
                                    game_res:del(CostList, ?FLOW_REASON_EQUIP_XQ),
                                    CurBagBucket = attr_new:get(?pd_goods_bucket),
                                    goods_bucket:begin_sync(CurBagBucket),
                                    {NewGemBucket, CurGem} = goods_bucket:del(CurBagBucket, item_by_id, {GemId, 1}),
                                    goods_bucket:end_sync(NewGemBucket),

                                    GoodsBucket = game_res:get_bucket(BucketType),
                                    goods_bucket:begin_sync(GoodsBucket),
                                    NewGoods = item_equip:take_on_gem(NewGoods1, NewSlotIndex, CurGem),
                                    NewGoodsBucket = goods_bucket:update(GoodsBucket, NewGoods),
                                    goods_bucket:end_sync(NewGoodsBucket),
                                    if
                                        OldBid > 0 ->
                                            game_res:give([{OldBid, 1}], ?FLOW_REASON_EQUIP_XQ);
                                        true -> ok
                                    end,
                                    event_eng:post(?ev_equ_xiangqian, {?ev_equ_xiangqian, 0}, 1),
                                    ok;
                                {error, Reason} ->
                                    {error, Reason};
                                _ ->
                                    {error, unknown}
                            end
                    end;
                _ ->
                    {error, unknown}
            end;
        _ -> {error, unknown}
    end.

%% 脱宝石
try_unembed_gem(BucketType, GoodsID, SlotIndex) ->
%%    ?INFO_LOG("try_unembed_gem"),
    Goods = get_equip(BucketType, GoodsID),
    case Goods of
        {error, Error} -> {error, Error};
        #item_new{} ->
            case item_equip:can_take_off_gem(Goods, SlotIndex) of
                {ok, GemBid} ->
                    case game_res:can_give([{GemBid, 1}]) of
                        ok ->
                            GoodsBucket = game_res:get_bucket(BucketType),
                            goods_bucket:begin_sync(GoodsBucket),
                            {NewGoods, Bid} = item_equip:take_off_gem(Goods, SlotIndex),
                            NewGoodsBucket = goods_bucket:update(GoodsBucket, NewGoods),
                            goods_bucket:end_sync(NewGoodsBucket),
                            game_res:give([{Bid, 1}], ?FLOW_REASON_TAKE_OFF_GEM),
                            event_eng:post(?ev_equ_xiangqian, {?ev_equ_xiangqian, 0}, 1),
                            ok;
                        _ ->
                            {error, no_empty_size}
                    end;
                {error, Reason} -> {error, Reason};
                _ -> {error, unknown}
            end;
        _ -> {error, unknown}
    end.

%% 穿史诗宝石
try_embed_epic_gem(BucketType, GoodsID, GemId) ->
    ?INFO_LOG("try_embed_epic_gem"),
    game_res:set_res_reasion(<<"穿宝石">>),
    Goods = get_equip(BucketType, GoodsID),
    case Goods of
        {error, Error} -> {error, Error};
        #item_new{} ->
            BagBucket = attr_new:get(?pd_goods_bucket),
            Gem = goods_bucket:find_goods(BagBucket, by_id, {GemId}),
            case Gem of
                #item_new{bid = GemBid} ->
                    case load_cfg_gem:is_epic_Gem(GemBid) of
                        %% 镶嵌史诗宝石
                        ?true ->
                            GemExp = item_new:get_item_new_field_value_by_key(Gem, ?item_use_data, ?item_epic_gem_exp, 0),
                            try_embed_epic_gem_to_epic_solt(BucketType, Goods, GemId, GemBid, GemExp);
                        %% 镶嵌普通宝石
                        ?false ->
                            try_embed_normal_gem_to_epic_solt(BucketType, Goods, Gem, GemId, GemBid)
                    end;
                _ ->
                    {error, unknown}
            end;
        _ ->
            {error, unknown}
    end.

%% 镶嵌史诗宝石到史诗孔位
try_embed_epic_gem_to_epic_solt(BucketType, Goods, GemId, GemBid, GemExp) ->
    case item_new:get_item_new_field_value_by_key(Goods, ?item_use_data, ?item_equip_epic_gem_slot, 0) of
        0 ->
            {error, no_epic_solt};
        _ ->
            case item_new:get_item_new_field_value_by_key(Goods, ?item_use_data, ?item_equip_epic_gem, 0) of
                %% 还没镶嵌宝石
                0 ->
                    case game_res:can_del([{by_id,{GemId, 1}}]) of
                        ok ->
                            %% 1.修改装备的item_equip_epic_gem_slot
                            DefaultKeyVal =
                                [
                                    {?item_use_data, [
                                        {?item_equip_epic_gem_slot, 1},
                                        {?item_equip_epic_gem, GemBid},
                                        {?item_equip_epic_gem_exp, GemExp}
                                    ]}
                                ],
%%                            NEqmItem = item_new:set_fields(Goods, DefaultKeyVal),
                            NEqmItem = item_equip:update_attr_do_epic_gem(Goods, DefaultKeyVal),
%%                             2.删掉史诗宝石
                            game_res:del([{by_id,{GemId, 1}}], ?FLOW_REASON_EQUIP_XQ),

                            %% 同步装备
                            GoodsBucket = game_res:get_bucket(BucketType),
                            goods_bucket:begin_sync(GoodsBucket),
                            NewGoodsBucket = goods_bucket:update(GoodsBucket, NEqmItem),
                            goods_bucket:end_sync(NewGoodsBucket),
                            ok;
                        _ ->
                            {error, cost_not_enough}
                    end;
                %% 装备上镶嵌了宝石
                EquipGemBid ->
                    case load_cfg_gem:is_epic_Gem(EquipGemBid) of
                        ?true ->
                            Exp = item_new:get_item_new_field_value_by_key(Goods, ?item_use_data, ?item_equip_epic_gem_exp, 0),
                            NGemItem = entity_factory:build(EquipGemBid, 1, Exp, ?FLOW_REASON_EQUIP_XQ),
                            case {game_res:can_del([{by_id,{GemId, 1}}]), game_res:can_give([{NGemItem}])} of
                                {ok,ok} ->
                                    game_res:try_del([{by_id,{GemId, 1}}], ?FLOW_REASON_EQUIP_XQ),
                                    game_res:set_res_reasion(<<"史诗宝石替换">>),
                                    game_res:try_give_ex([{NGemItem}], ?FLOW_REASON_EQUIP_XQ),

                                    %% 替换掉史诗宝石
                                    DefaultKeyVal =
                                        [
                                            {?item_use_data, [
                                                {?item_equip_epic_gem_slot, 1},
                                                {?item_equip_epic_gem, GemBid},
                                                {?item_equip_epic_gem_exp, GemExp}
                                            ]}
                                        ],
%%                                    NEqmItem = item_new:set_fields(Goods, DefaultKeyVal),
                                    NEqmItem = item_equip:update_attr_do_epic_gem(Goods, DefaultKeyVal),
                                    %% 同步装备
                                    GoodsBucket = game_res:get_bucket(BucketType),
                                    goods_bucket:begin_sync(GoodsBucket),
                                    NewGoodsBucket = goods_bucket:update(GoodsBucket, NEqmItem),
                                    goods_bucket:end_sync(NewGoodsBucket),
                                    ok;
                                _ ->
                                    {error, cost_not_enough}
                            end;
                        ?false ->
                            case {game_res:can_del([{by_id,{GemId, 1}}]), game_res:can_give([{EquipGemBid, 1}])} of
                                {ok,ok} ->
                                    %% 1.删掉史诗宝石加到装备上
                                    DefaultKeyVal =
                                        [
                                            {?item_use_data, [
                                                {?item_equip_epic_gem_slot, 1},
                                                {?item_equip_epic_gem, GemBid},
                                                {?item_equip_epic_gem_exp, GemExp}
                                            ]}
                                        ],
                                    NEqmItem = item_equip:update_attr_do_epic_gem(Goods, DefaultKeyVal),
%%                                    NEqmItem = item_new:set_fields(Goods, DefaultKeyVal),
                                    game_res:try_del([{by_id,{GemId, 1}}], ?FLOW_REASON_EQUIP_XQ),

                                    %% 2.给装备上的普通宝石
                                    game_res:set_res_reasion(<<"史诗宝石替换">>),
                                    game_res:give([{EquipGemBid, 1}], ?FLOW_REASON_EQUIP_XQ),

                                    %% 同步装备
                                    GoodsBucket = game_res:get_bucket(BucketType),
                                    goods_bucket:begin_sync(GoodsBucket),
                                    NewGoodsBucket = goods_bucket:update(GoodsBucket, NEqmItem),
                                    goods_bucket:end_sync(NewGoodsBucket),
                                    ok;
                                _ ->
                                    {error, cost_not_enough}
                            end
                    end
            end
    end.

%% 镶嵌普通宝石到史诗孔位
try_embed_normal_gem_to_epic_solt(BucketType, Goods, Gem, GemId, GemBid) ->
    case item_new:get_item_new_field_value_by_key(Goods, ?item_use_data, ?item_equip_epic_gem_slot, 0) of
        %% 装备没打孔
        0 ->
            {error, no_epic_solt};
        %% 装备已打孔
        _ ->
            case item_new:get_item_new_field_value_by_key(Goods, ?item_use_data, ?item_equip_epic_gem, 0) of
                0 ->
                    %% 1.判断装备有没有该类型的普通宝石
                    case is_already_has_gem(Goods, GemBid) of
                        ?true ->
                            {error, has_gem};
                        ?false ->
                            case game_res:can_del([{by_id,{GemId, 1}}]) of
                                ok ->
                                    %% 更新装备上的宝石
                                    GoodsBucket = game_res:get_bucket(BucketType),
                                    goods_bucket:begin_sync(GoodsBucket),
                                    GemExp = item_new:get_item_new_field_value_by_key(Gem, ?item_use_data, ?item_equip_epic_gem_exp, 0),
                                    DefaultKeyVal =
                                        [
                                            {?item_use_data, [
                                                {?item_equip_epic_gem_slot, 1},
                                                {?item_equip_epic_gem, GemBid},
                                                {?item_equip_epic_gem_exp, GemExp}
                                            ]}
                                        ],
%%                                    NewGoods = item_new:set_fields(Goods, DefaultKeyVal),
                                    NewGoods = item_equip:update_attr_do_epic_gem(Goods, DefaultKeyVal),
                                    NewGoodsBucket = goods_bucket:update(GoodsBucket, NewGoods),
                                    goods_bucket:end_sync(NewGoodsBucket),

                                    %% 删除背包中的宝石
                                    CurBagBucket = attr_new:get(?pd_goods_bucket),
                                    goods_bucket:begin_sync(CurBagBucket),
                                    {NewGemBucket, _CurGem} = goods_bucket:del(CurBagBucket, item_by_id, {GemId, 1}),
                                    goods_bucket:end_sync(NewGemBucket),
                                    ok;
                                _ ->
                                    {error, cost_not_enough}
                            end
                    end;
                %% 装备上镶嵌了宝石
                EquipGemBid ->
                    %% 1.判断装备有没有该类型的普通宝石
                    case is_already_has_gem(Goods, GemBid) of
                        ?true ->
                            {error, has_gem};
                        ?false ->
                            case load_cfg_gem:is_epic_Gem(EquipGemBid) of
                                ?true ->
                                    Exp = item_new:get_item_new_field_value_by_key(Goods, ?item_use_data, ?item_equip_epic_gem_exp, 0),
                                    NGemItem = entity_factory:build(EquipGemBid, 1, Exp, ?FLOW_REASON_EQUIP_XQ),
                                    case {game_res:can_del([{by_id,{GemId, 1}}]), game_res:can_give([{NGemItem}])} of
                                        {ok,ok} ->
                                            %% 给背包史诗宝石
                                            game_res:try_give_ex([{NGemItem}], ?FLOW_REASON_TAKE_OFF_GEM),
                                            %% 删除背包中的宝石
                                            CurBagBucket = attr_new:get(?pd_goods_bucket),
                                            goods_bucket:begin_sync(CurBagBucket),
                                            {NewGemBucket, _CurGem} = goods_bucket:del(CurBagBucket, item_by_id, {GemId, 1}),
                                            goods_bucket:end_sync(NewGemBucket),

                                            %% 更新装备上的宝石
                                            GoodsBucket = game_res:get_bucket(BucketType),
                                            goods_bucket:begin_sync(GoodsBucket),
                                            DefaultKeyVal =
                                                [
                                                    {?item_use_data, [
                                                        {?item_equip_epic_gem_slot, 1},
                                                        {?item_equip_epic_gem, GemBid},
                                                        {?item_equip_epic_gem_exp, 0}
                                                    ]}
                                                ],
                                            NewGoods = item_equip:update_attr_do_epic_gem(Goods, DefaultKeyVal),
%%                                            NewGoods = item_new:set_field(Goods, ?item_equip_epic_gem, GemBid),
                                            NewGoodsBucket = goods_bucket:update(GoodsBucket, NewGoods),
                                            goods_bucket:end_sync(NewGoodsBucket),
                                            ok;
                                        _ ->
                                            {error, cost_not_enough}
                                    end;
                                ?false ->
                                    if
                                        EquipGemBid =:= GemBid ->
                                            {error, has_gem};
                                        true ->
                                            case {game_res:can_give([{EquipGemBid, 1}]), game_res:can_del([{by_id,{GemId, 1}}])} of
                                                {ok, ok} ->
                                                    %% 给背包普通宝石
                                                    game_res:give([{EquipGemBid, 1}], ?FLOW_REASON_TAKE_OFF_GEM),
                                                    %% 删除背包中的普通宝石
                                                    CurBagBucket = attr_new:get(?pd_goods_bucket),
                                                    goods_bucket:begin_sync(CurBagBucket),
                                                    {NewGemBucket, _CurGem} = goods_bucket:del(CurBagBucket, item_by_id, {GemId, 1}),
                                                    goods_bucket:end_sync(NewGemBucket),

                                                    %% 更新装备上的宝石
                                                    GoodsBucket = game_res:get_bucket(BucketType),
                                                    goods_bucket:begin_sync(GoodsBucket),
                                                    DefaultKeyVal =
                                                        [
                                                            {?item_use_data, [
                                                                {?item_equip_epic_gem_slot, 1},
                                                                {?item_equip_epic_gem, GemBid},
                                                                {?item_equip_epic_gem_exp, 0}
                                                            ]}
                                                        ],
                                                    NewGoods = item_equip:update_attr_do_epic_gem(Goods, DefaultKeyVal),
%%                                                    NewGoods = item_new:set_field(Goods, ?item_equip_epic_gem_slot, GemBid),
                                                    NewGoodsBucket = goods_bucket:update(GoodsBucket, NewGoods),
                                                    goods_bucket:end_sync(NewGoodsBucket),
                                                    ok;
                                                _ ->
                                                    {error, cost_not_enough}
                                            end
                                    end
                            end
                    end
            end
    end.

%% 脱史诗宝石
try_unembed_epic_gem(BucketType, GoodsID) ->
    ?INFO_LOG("try_unembed_epic_gem"),
    Goods = get_equip(BucketType, GoodsID),
    case Goods of
        {error, Error} -> {error, Error};
        #item_new{} ->
            case item_new:get_item_new_field_value_by_key(Goods, ?item_use_data, ?item_equip_epic_gem_slot, 0) of
                0 ->
                    {error, no_epic_solt};
                _ ->
                    case item_new:get_item_new_field_value_by_key(Goods, ?item_use_data, ?item_equip_epic_gem, 0) of
                        0 ->
                            {error, no_gem};
                        EquipGemBid ->
                            BagBucket = game_res:get_bucket(?BUCKET_TYPE_BAG),
                            Size = goods_bucket:get_empty_size(BagBucket),
                            if
                                Size > 0 ->
                                    case load_cfg_gem:is_epic_Gem(EquipGemBid) of
                                        ?true ->
                                            %% 给背包史诗宝石
                                            Exp = item_new:get_item_new_field_value_by_key(Goods, ?item_use_data, ?item_equip_epic_gem_exp, 0),
                                            NGemItem = entity_factory:build(EquipGemBid, 1, Exp, ?FLOW_REASON_TAKE_OFF_GEM),
                                            game_res:try_give_ex([{NGemItem}], ?FLOW_REASON_TAKE_OFF_GEM),

                                            %% 更新装备上的宝石
                                            GoodsBucket = game_res:get_bucket(BucketType),
                                            goods_bucket:begin_sync(GoodsBucket),
                                            DefaultKeyVal =
                                                [
                                                    {?item_use_data, [
                                                        {?item_equip_epic_gem_slot, 1},
                                                        {?item_equip_epic_gem, 0},
                                                        {?item_equip_epic_gem_exp, 0}
                                                    ]}
                                                ],
%%                                    NewGoods = item_new:set_fields(Goods, DefaultKeyVal),
                                            NewGoods = item_equip:update_attr_do_epic_gem(Goods, DefaultKeyVal),
                                            NewGoodsBucket = goods_bucket:update(GoodsBucket, NewGoods),
                                            goods_bucket:end_sync(NewGoodsBucket),
                                            ok;
                                        ?false ->
                                            %% 给背包普通宝石
                                            game_res:give([{EquipGemBid, 1}], ?FLOW_REASON_TAKE_OFF_GEM),
                                            %% 更新装备上的宝石
                                            GoodsBucket = game_res:get_bucket(BucketType),
                                            goods_bucket:begin_sync(GoodsBucket),
                                            DefaultKeyVal =
                                                [
                                                    {?item_use_data, [
                                                        {?item_equip_epic_gem_slot, 1},
                                                        {?item_equip_epic_gem, 0},
                                                        {?item_equip_epic_gem_exp, 0}
                                                    ]}
                                                ],
                                            NewGoods = item_equip:update_attr_do_epic_gem(Goods, DefaultKeyVal),
%%                                    NewGoods = item_new:set_fields(Goods, DefaultKeyVal),
                                            NewGoodsBucket = goods_bucket:update(GoodsBucket, NewGoods),
                                            goods_bucket:end_sync(NewGoodsBucket),
                                            ok
                                    end;
                                true ->
                                    {error, full_bucket}
                            end
                    end
            end;
        _ -> {error, unknown}
    end.

%% 是否已经镶嵌该普通宝石
is_already_has_gem(Goods, Bid) ->
    GemTuple = item_new:get_field(Goods, ?item_equip_igem_slot),
    lists:member(Bid, tuple_to_list(GemTuple)).

try_unembed_normal_gem(BucketType, GoodsId) ->
    ?INFO_LOG("try_unembed_normal_gem"),
    TryUnembedGem =
        fun
            (_ThisFun, _BucketType, _GoodsID, _Max, _Max) -> ok;
            (ThisFun, BucketType2, GoodsID, I, Max) ->
                case try_unembed_gem(BucketType2, GoodsID, I) of
                    {error,no_gem} ->
                        ThisFun(ThisFun, BucketType2, GoodsID, I + 1, Max);
                    ok ->
                        ThisFun(ThisFun, BucketType2, GoodsID, I + 1, Max);
                    Error ->
                        Error
                end
        end,
    Goods = get_equip(BucketType, GoodsId),
    case Goods of
        {error, Error} -> {error, Error};
        Item = #item_new{} ->
            Size = item_equip:get_gem_total_size(Goods),
            BagBucket = game_res:get_bucket(?BUCKET_TYPE_BAG),
            LeftSize = goods_bucket:get_empty_size(BagBucket),
            GemNum = item_equip:get_equip_all_gem_num(Item),
            case GemNum =< LeftSize of
                true ->
                    case TryUnembedGem(TryUnembedGem, BucketType, GoodsId, 1, Size + 1) of
                        ok ->
                            ok;
                        _ -> {error, unknown}
                    end;
                _ ->  {error,no_empty_size}
            end
    end.

%% 摘除所有宝石
try_unembed_all_gem(BucketType, GoodsID) ->
%%    ?INFO_LOG("try_unembed_all_gem"),
    case try_unembed_normal_gem(BucketType, GoodsID) of
        {error, E} ->
            {error, E};
        ok ->
            case try_unembed_epic_gem(BucketType, GoodsID) of
                {error,no_gem} ->        % 史诗孔没宝石
                    ok;
                {error, no_epic_solt} -> % 史诗孔没打孔
                    ok;
                ok ->
                    ok;
                {error, Epic_E} ->
                    {error, Epic_E}
            end
    end.

%% 强化
%%try_qiang_hua(BucketType, GoodsID, IsDownLevelFree) ->
%%%%    ?INFO_LOG("try_qiang_hua"),
%%    Goods = get_equip(BucketType, GoodsID),
%%    game_res:set_res_reasion(<<"强化">>),
%%    case Goods of
%%        {error, Error0} -> {error, Error0};
%%        #item_new{} ->
%%            %% 能否强化
%%            CurQHLvl = item_new:get_field(Goods, ?item_equip_qianghua_lev),
%%            case item_equip:can_set_strength_lvl(Goods, CurQHLvl) of
%%                {error, Error1} -> {error, Error1};
%%                _ ->
%%                    %% 强化成本是否满足
%%                    CostList = load_equip_expand:get_qiang_hua_cost(Goods#item_new.bid, CurQHLvl),
%%                    NewCostList =
%%                        case IsDownLevelFree of
%%%%                            1 -> [{misc_cfg:get_qiang_hua_id(), 1} | CostList];  %% 装备强化暂时用不到强化消耗已经调整为部位强化
%%                            0 -> CostList
%%                        end,
%%                    case game_res:can_del(NewCostList) of
%%                        {error, Error2} -> {error, Error2};
%%                        _ ->
%%                            game_res:del(NewCostList, ?FLOW_REASON_EQUIP_QIANGHUA),
%%                            case load_equip_expand:can_qiang_hua_success(CurQHLvl) of
%%                                {error, _} ->
%%                                    if
%%                                        IsDownLevelFree =/= 1 ->
%%                                            GoodsBucket = game_res:get_bucket(BucketType),
%%                                            goods_bucket:begin_sync(GoodsBucket),
%%
%%                                            %% 强化失败，下降等级
%%                                            NewLvL = load_equip_expand:get_qiang_hua_failed_lvl(Goods#item_new.bid, CurQHLvl),
%%                                            NewItem = item_equip:set_strength_lvl(Goods, NewLvL),
%%                                            NewGoodsBucket = goods_bucket:update(GoodsBucket, NewItem),
%%
%%                                            goods_bucket:end_sync(NewGoodsBucket);
%%                                        true ->
%%                                            ok
%%                                    end,
%%                                    ret:error(failed_qiang_hua);
%%
%%                                _ ->
%%                                    GoodsBucket = game_res:get_bucket(BucketType),
%%                                    goods_bucket:begin_sync(GoodsBucket),
%%
%%                                    %% 强化成功，设等级， 改属性
%%                                    NewItem = item_equip:set_strength_lvl(Goods, CurQHLvl+1),
%%                                    NewGoodsBucket = goods_bucket:update(GoodsBucket, NewItem),
%%
%%                                    goods_bucket:end_sync(NewGoodsBucket),
%%                                    ok
%%                            end
%%                    end
%%            end;
%%        _ ->
%%            ret:error(unknown_type)
%%    end.
%%
%%%% 继承(只能继承更强的)
%%get_ji_cheng_drop_lvl([]) -> 0;
%%get_ji_cheng_drop_lvl(List) ->
%%    {Total, List1} =
%%        lists:foldl
%%        (
%%            fun
%%                ({FailedLvl, Pro}, {Sum, RetList}) ->
%%                    Total = Pro+Sum,
%%                    {Total, [{FailedLvl, Total} | RetList]}
%%            end,
%%            {0,[]},
%%            List
%%        ),
%%    List2 = lists:reverse(List1),
%%    Rand = com_util:random(0, Total),
%%    ?INFO_LOG("List ~p", [List]),
%%    ?INFO_LOG("List2 ~p", [List2]),
%%    ?INFO_LOG("Rand ~p", [Rand]),
%%    case lists:dropwhile
%%    (
%%        fun
%%            ({_, Pro}) ->
%%                if
%%                    Rand =< Pro -> false;
%%                    true -> true
%%                end
%%        end,
%%        List2
%%    ) of
%%        [] -> 0;
%%        [{Lvl, _}|_TaiList] =List3 ->
%%            ?INFO_LOG("List3 ~p", [List3]),
%%            Lvl
%%    end.
%%try_ji_cheng(BucketType1, GoodsID, BucketType2, ItemId) ->
%%%%    ?DEBUG_LOG("try_ji_cheng------------------:~p", [{BucketType1, GoodsID, BucketType2, ItemId}]),
%%    FromGoods = get_equip(BucketType2, ItemId),
%%    ToGoods = get_equip(BucketType1, GoodsID),
%%    case FromGoods of
%%        {error, Error1} -> {error, Error1};
%%        #item_new{} ->
%%            case ToGoods of
%%                {error, Error2} -> {error, Error2};
%%                _ ->
%%                    FromCurQHLvL = item_new:get_field(FromGoods, ?item_equip_qianghua_lev),
%%                    ToCurQHLvL = item_new:get_field(ToGoods, ?item_equip_qianghua_lev),
%%                    if
%%                        FromCurQHLvL =< ToCurQHLvL ->
%%                            ret:error(cant_qh);
%%
%%                        true ->
%%                            UseLvl = load_item:get_use_lev(ToGoods#item_new.bid),
%%                            EquipType = item_new:get_type(ToGoods),
%%                            FromCurQHLvL1 =
%%                                if
%%                                    FromCurQHLvL > 2 ->
%%                                        FailedList = load_equip_expand:get_ji_cheng_failed_list(EquipType, UseLvl),
%%                                        FailedLvl = get_ji_cheng_drop_lvl(FailedList),
%%                                        FromCurQHLvLTemp = erlang:max(2, FromCurQHLvL+FailedLvl),
%%                                        erlang:max(FromCurQHLvLTemp, ToCurQHLvL);
%%
%%                                    true ->
%%                                        FromCurQHLvL
%%                                end,
%%                            case item_equip:can_set_strength_lvl(ToGoods, FromCurQHLvL1) of
%%                                {error, _Error1} ->
%%                                    {error, cant_qh};
%%
%%                                _ ->
%%                                    %%继承的成本是否满足
%%                                    CostList = load_equip_expand:get_ji_cheng_cost_list(EquipType, UseLvl),
%%                                    case CostList of
%%                                        {error, Error} ->
%%                                            {error, Error};
%%                                        _ ->
%%                                            case game_res:can_del(CostList) of
%%                                                {error, Error3} ->
%%                                                    {error, Error3};
%%                                                _ ->
%%                                                    game_res:del(CostList, ?FLOW_REASON_EQUIP_JICHENG),
%%                                                    %% 老装备去强化
%%                                                    GoodsFromBucket = game_res:get_bucket(BucketType2),
%%                                                    goods_bucket:begin_sync(GoodsFromBucket),
%%                                                    NewFromItem = item_equip:set_strength_lvl(FromGoods, 0),
%%                                                    NewGoodsFromBucket = goods_bucket:update(GoodsFromBucket, NewFromItem),
%%                                                    goods_bucket:end_sync(NewGoodsFromBucket),
%%
%%                                                    %% 新装备做强化
%%                                                    GoodsBucket = game_res:get_bucket(BucketType1),
%%                                                    goods_bucket:begin_sync(GoodsBucket),
%%                                                    NewItem = item_equip:set_strength_lvl(ToGoods, FromCurQHLvL1),
%%                                                    NewGoodsBucket = goods_bucket:update(GoodsBucket, NewItem),
%%                                                    goods_bucket:end_sync(NewGoodsBucket),
%%                                                    ok
%%                                            end
%%                                    end
%%                            end
%%                    end
%%            end
%%    end.
%%
%%
%%%% 合成(宝石必须全部拿下才可，切宝石槽位会在三个装备中随机。随机jd属性其他的不管。基础属性为主装备。
%%%% #合成类型 1直接合成 2预览合成 3再次合成
%%-record(he_cheng_tmp,
%%{
%%    all_jd_list = [],
%%    all_jd_new_len = 0,
%%    gem_lens = 0,
%%    main_equip_gem_tuple = {0}
%%}).
%%
%%-record(he_cheng_temp_new,
%%{
%%    mainJDList,      %% {bid, JDList}
%%    goods1JDList,    %% {bid, JDList}
%%    goods2JDList     %% {bid, JDList}
%%}).
%%
%%%% 装备合成
%%do_he_cheng(BucketType, GoodsID, 0, 0, 1, LockAttrList) ->
%%%%    ?INFO_LOG("yulan_he_cheng"),
%%    NewHechengTemp = attr_new:get(?pd_do_he_cheng_equip_store, 0),
%%    if
%%        NewHechengTemp =:= 0 ->
%%            ret:error(cant_he_cheng);
%%        true ->
%%
%%            #he_cheng_temp_new{mainJDList = MainJDList, goods1JDList = G1JDList, goods2JDList = G2JDList} = NewHechengTemp,
%%            MainGoods = get_equip(BucketType, GoodsID),
%%            api:record_he_cheng_attr_begin(MainGoods), %% 用于记录装备合成前后的属性判断
%%
%%            %% 判断锁定的属性条数是否合法
%%            PlayerVipLvl = attr_new:get_vip_lvl(),
%%            %VipLockCountList = load_vip_right:get_vip_lock_attr_count(PlayerVipLvl),      %% vip等级可锁定的属性条数
%%            VipLockCountList = load_vip_new:get_vip_lock_attr_count_by_level(PlayerVipLvl),      %% vip等级可锁定的属性条数
%%
%%            MainGoodsQual = item_new:get_field(MainGoods, ?item_equip_quality),       %% 根据装备品质获取的可锁定的属性条数
%%
%%            QuaLockNum =
%%                case lists:keyfind(MainGoodsQual, 1, VipLockCountList) of
%%                    {_, LockNum} ->
%%                        LockNum;
%%                    _ ->
%%                        ?ERROR_LOG("not find locknum"),
%%                        0
%%                end,
%%            case length(LockAttrList) =< QuaLockNum of
%%                true ->
%%
%%                    %% 成本预判
%%                    %% 消耗成本的是由预览卷轴加上锁定属性条数
%%                    CfgLockCostList = misc_cfg:get_equip_hecheng_lock_cost(),
%%                    LockCostId =
%%                        case lists:keyfind(length(LockAttrList), 1, CfgLockCostList) of
%%                            {_, CostId} ->
%%                                CostId;
%%                            _ ->
%%                                1
%%                        end,
%%                    LockCostList = cost:get_cost(LockCostId),
%%                    CostList = [{by_bid, {misc_cfg:get_yu_lan_id(), 1}}] ++ LockCostList,
%%                    case game_res:can_del(CostList) of
%%                        {error, Error} ->
%%                            {error, Error};
%%                        _ ->
%%
%%                            hecheng_choose_sync_attr(BucketType, MainGoods, MainJDList, G1JDList, G2JDList, LockAttrList),
%%                            %% 扣除成本
%%                            game_res:del(CostList, ?FLOW_REASON_EQUIP_HECHENG),
%%%%                            put(?pd_do_he_cheng_equip_store, 0),
%%                            ok
%%                    end;
%%                _ ->
%%                    {error, lock_attr_more}
%%            end
%%    end;
%%
%%
%%do_he_cheng(BucketType, GoodsID, ItemId1, ItemId2, IsNeedSave, LockAttrList) ->
%%%%    ?INFO_LOG("try_he_cheng"),
%%    game_res:set_res_reasion(<<"合成">>),
%%    attr_new:set(?pd_hecheng_equip_tmp, 0),
%%    MainGoods = get_equip(BucketType, GoodsID),
%%    HCGoods1 = get_equip(?BUCKET_TYPE_BAG, ItemId1),
%%    HCGoods2 = get_equip(?BUCKET_TYPE_BAG, ItemId2),
%%    api:record_he_cheng_attr_begin(MainGoods), %% 用于记录装备合成前后的属性判断
%%
%%    %% 物品预判
%%    case {MainGoods, HCGoods1, HCGoods2} of
%%        {{error, Error}, _, _} -> {error, Error};
%%        {_, {error, Error}, _} -> {error, Error};
%%        {_, _, {error, Error}} -> {error, Error};
%%        _ ->
%%%%             CurGemNum1 = item_equip:get_gem_cur_size(MainGoods),
%%            CurGemNum2 = item_equip:get_gem_cur_size(HCGoods1),
%%            CurGemNum3 = item_equip:get_gem_cur_size(HCGoods2),
%%            if
%%%%                 CurGemNum1 > 0 -> ret:error(cant_he_cheng);
%%                CurGemNum2 > 0 -> ret:error(cant_he_cheng);
%%                CurGemNum3 > 0 -> ret:error(cant_he_cheng);
%%            %% 条件预判
%%                true ->
%%                    UseLvl = load_item:get_use_lev(MainGoods#item_new.bid),
%%                    MainGoodsType = item_new:get_type(MainGoods),
%%                    CostList = load_equip_expand:get_he_cheng_cost_list(MainGoodsType, UseLvl),
%%                    case CostList of
%%                        {error, Error} ->
%%                            {error, Error};
%%                        _ ->
%%                            %% 判断锁定的属性条数是否合法
%%                            PlayerVipLvl = attr_new:get_vip_lvl(),
%%                            %VipLockCountList = load_vip_right:get_vip_lock_attr_count(PlayerVipLvl),      %% vip等级可锁定的属性条数
%%                            VipLockCountList = load_vip_new:get_vip_lock_attr_count_by_level(PlayerVipLvl),      %% vip等级可锁定的属性条数
%%
%%                            MainGoodsQual = item_new:get_field(MainGoods, ?item_equip_quality),       %% 根据装备品质获取的可锁定的属性条数
%%
%%                            QuaLockNum =
%%                                case lists:keyfind(MainGoodsQual, 1, VipLockCountList) of
%%                                    {_, LockNum} ->
%%                                        LockNum;
%%                                    _ ->
%%                                        ?ERROR_LOG("not find locknum"),
%%                                        0
%%                                end,
%%
%%                            case length(LockAttrList) =< QuaLockNum of
%%                                true ->
%%                                    CostList1 = [{by_id, {HCGoods1#item_new.id, 1}} | CostList],
%%                                    CostList2 = [{by_id, {HCGoods2#item_new.id, 1}} | CostList1],
%%                                    CostList3 =
%%                                        if
%%                                            IsNeedSave == 1 -> [{by_bid, {misc_cfg:get_yu_lan_id(), 1}} | CostList2];
%%                                            true -> CostList2
%%                                        end,
%%                                    %% 成本预判
%%                                    %% 消耗成本的是由预览卷轴消耗、锁定属性条数消耗、合成消耗
%%                                    CfgLockCostList = misc_cfg:get_equip_hecheng_lock_cost(),
%%                                    LockCostId =
%%                                        case lists:keyfind(length(LockAttrList), 1, CfgLockCostList) of
%%                                            {_, CostId} ->
%%                                                CostId;
%%                                            _ ->
%%                                                1
%%                                        end,
%%                                    LockCostList = cost:get_cost(LockCostId),
%%                                    case game_res:can_del(CostList3 ++ LockCostList) of
%%                                        {error, Error} -> {error, Error};
%%                                        _ ->
%%                                            MainJDList = item_equip:get_authenticate_attr_list(MainGoods),
%%                                            G1JDList = item_equip:get_authenticate_attr_list(HCGoods1),
%%                                            G2JDList = item_equip:get_authenticate_attr_list(HCGoods2),
%%
%%                                            hecheng_choose_sync_attr(BucketType, MainGoods, MainJDList, G1JDList, G2JDList, LockAttrList),
%%
%%                                            %% 扣除成本
%%                                            game_res:del(CostList2 ++ LockCostList, ?FLOW_REASON_EQUIP_HECHENG),
%%
%%                                            if
%%                                                IsNeedSave == 1 ->
%%                                                    HeChengTempNew = #he_cheng_temp_new
%%                                                    {
%%                                                        mainJDList = MainJDList,
%%                                                        goods1JDList = G1JDList,
%%                                                        goods2JDList = G2JDList
%%                                                    },
%%                                                    put(?pd_do_he_cheng_equip_store, HeChengTempNew);
%%                                                true
%%                                                    -> ok
%%                                            end,
%%                                            ok
%%                                    end;
%%                                _ ->
%%                                    {error, lock_attr_more}
%%                            end
%%                    end
%%            end
%%    end.
%%
%%%% 装备再次和合成的时候ItemId1,ItemId2发的数据是0
%%try_he_cheng(Type, BucketType, GoodsID, ItemId1, ItemId2, LockAttrList) ->
%%    case Type of
%%        1 -> do_he_cheng(BucketType, GoodsID, ItemId1, ItemId2, 0, LockAttrList);
%%        2 -> do_he_cheng(BucketType, GoodsID, ItemId1, ItemId2, 1, LockAttrList);
%%        _ -> ?ERROR_LOG("he cheng error")
%%    end.

%% 筛选合成数据并同步合成信息
%%hecheng_choose_sync_attr(BucketType, MainGoods, MainJDList, G1JDList, G2JDList, LockAttrList) ->
%%    AllJDList = lists:append([MainJDList, G1JDList, G2JDList]),
%%%%  ?INFO_LOG("AllJDList = ~p", [AllJDList]),
%%    %% 获取鉴定要保存的鉴定属性
%%    LockJDList =
%%        lists:foldl
%%        (
%%            fun
%%                ({TAttrId, TAttrVal, Tpro, Min, Max}, AccList) ->
%%                    case lists:keyfind(TAttrId, 1, LockAttrList) of
%%                        {AttrId, AttrVal} when TAttrVal =:= AttrVal ->
%%                            case lists:keymember(AttrId, 1, AccList) of
%%                                true ->
%%                                    AccList;
%%                                _ ->
%%                                    [{AttrId, AttrVal, Tpro, Min, Max} | AccList]
%%                            end;
%%                        _ ->
%%                            AccList
%%                    end;
%%                ({TAttrId, TAttrVal, Tpro}, AccList) ->
%%                    case lists:keyfind(TAttrId, 1, LockAttrList) of
%%                        {AttrId, AttrVal} when TAttrVal =:= AttrVal ->
%%                            case lists:keymember(AttrId, 1, AccList) of
%%                                true ->
%%                                    AccList;
%%                                _ ->
%%                                    [{AttrId, AttrVal, Tpro} | AccList]
%%                            end;
%%                        _ ->
%%                            AccList
%%                    end
%%            end,
%%            [],
%%            AllJDList
%%        ),
%%
%%    %% 去掉锁定的属性相同的id
%%    AllJDList1 =
%%        lists:foldl
%%        (
%%            fun
%%                ({TAttrId, TAttrVal, Tpro, Min, Max}, Acc) ->
%%                    case lists:keymember(TAttrId, 1, LockAttrList) of
%%                        true ->
%%                            Acc;
%%                        _ ->
%%                            [{TAttrId, TAttrVal, Tpro, Min, Max} | Acc]
%%                    end;
%%                ({TAttrId, TAttrVal, Tpro}, Acc) ->
%%                    case lists:keymember(TAttrId, 1, LockAttrList) of
%%                        true ->
%%                            Acc;
%%                        _ ->
%%                            [{TAttrId, TAttrVal, Tpro} | Acc]
%%                    end
%%            end,
%%            [],
%%            AllJDList
%%        ),
%%
%%    ChangeNum = load_equip_expand:get_he_cheng_change_num(length(MainJDList)),
%%    AllJDList2 = do_he_cheng_filter(AllJDList1),
%%    %% 所有属性条目里随出相关的随机数目。
%%    JdLen1 = length(MainJDList),
%%    JdLen2 = length(G1JDList),
%%    JdLen3 = length(G2JDList),
%%    NewLen = min(max(0, JdLen1 + ChangeNum - length(LockJDList)), JdLen1 + JdLen2 + JdLen3),
%%
%%    %% 获取杂项表中的引导合成使用的装备bid进行对比
%%    MiscHechengList = misc_cfg:get_hecheng_guide_bid(),
%%    {_Job, GuideBid} = lists:keyfind(get(?pd_career), 1, MiscHechengList),
%%    #item_new{bid = MainEquipBid} = MainGoods,
%%    HeChengCount = attr_new:get(?pd_do_he_cheng_count, 0),
%%
%%    %% 这里的玩家装备合成的次数匹配为原来的策划需求需要对装备第一次合成与第二次合成时做特殊处理（用于玩家合成引导中）
%%    %% 现在等策划出新的合成引导需求，所以暂使其不匹配（匹配对象为a,b）
%%    NewAttrList =
%%        if
%%            HeChengCount =:= a andalso GuideBid =:= MainEquipBid ->
%%                do_first_he_cheng_attr(AllJDList2, 2);  %% 第一次合成为2条附加属性，第2次合成为3条附加属性
%%            HeChengCount =:= b andalso GuideBid =:= MainEquipBid ->
%%                do_second_he_cheng_attr(AllJDList2, 3);
%%            true ->
%%                AllJDList2Len = length(AllJDList2),
%%                case NewLen > AllJDList2Len of
%%                    true ->
%%                        AllJDList2;
%%                    _ ->
%%                        com_util:rand_more(AllJDList2, NewLen)
%%                end
%%        end,
%%    NewAttrList1 = LockJDList ++ NewAttrList,
%%    put(?pd_do_he_cheng_count, HeChengCount+1),
%%
%%    %% 设置装备的鉴定属性
%%    MainGoods1 = item_equip:change_jd_attr(MainGoods, NewAttrList1),
%%    %%获取主装备宝石元组
%%    MainGemTuple = item_equip:get_gem_tuple(MainGoods),
%%
%%    MainGoods2 = item_equip:change_gem_tuple(MainGoods1, MainGemTuple),
%%    %% 设置装备的品质(当主装备是套装的时候品质不需要改变)
%%    MainGoods3 =
%%        case api:is_suit(MainGoods) of
%%            true ->
%%                MainGoods2;
%%            _ ->
%%                AttrLen = length(NewAttrList1),
%%                Quality =
%%                    case AttrLen >= ?equip_orange of
%%                        true ->
%%                            ?equip_orange;
%%                        _ ->
%%                            case AttrLen =:= 0 of
%%                                true -> 1;
%%                                _ -> AttrLen
%%                            end
%%                    end,
%%                item_new:set_field(MainGoods2, ?item_equip_quality, Quality)
%%        end,
%%    %% 刷新数据
%%    GoodsBucket = game_res:get_bucket(BucketType),
%%    goods_bucket:begin_sync(GoodsBucket),
%%    NewGoodsBucket = goods_bucket:update(GoodsBucket, MainGoods3),
%%    goods_bucket:end_sync(NewGoodsBucket),
%%    api:record_he_cheng_attr_end(MainGoods3).


%% 现在取消了装备的二次合成的功能所以暂时屏蔽掉
%%do_he_cheng_again(BucketType, GoodsID) ->
%%    HeChengTmp = attr_new:get(?pd_hecheng_equip_tmp, 0),
%%    if
%%        HeChengTmp =:= 0 ->
%%            ret:error(cant_he_cheng);
%%        true ->
%%            case get_equip(BucketType, GoodsID) of
%%                {error, Error} -> {error, Error};
%%                MainGoods ->
%%                    NewList = do_he_cheng_filter(HeChengTmp#he_cheng_tmp.all_jd_list),
%%                    api:record_he_cheng_attr_begin(MainGoods),
%%
%%                    HeChengCount = attr_new:get(?pd_do_he_cheng_count, 0),
%%
%%                    %% 获取杂项表中的引导合成使用的装备bid进行对比
%%                    MiscHechengList = misc_cfg:get_hecheng_guide_bid(),
%%                    {_Job, GuideBid} = lists:keyfind(get(?pd_career), 1, MiscHechengList),
%%                    #item_new{bid = MainEquipBid} = MainGoods,
%%
%%                    NewAttrList =
%%                        if
%%                            HeChengCount =:= 0 andalso GuideBid =:= MainEquipBid ->
%%                                do_first_he_cheng_attr(NewList, 2);
%%                            HeChengCount =:= 1 andalso GuideBid =:= MainEquipBid ->
%%                                do_second_he_cheng_attr(NewList, 3);
%%                            true ->
%%                                NewListLen = length(NewList),
%%                                case HeChengTmp#he_cheng_tmp.all_jd_new_len > NewListLen of
%%                                    true ->
%%                                        NewList;
%%                                    _ ->
%%                                        com_util:rand_more(NewList, HeChengTmp#he_cheng_tmp.all_jd_new_len)
%%                                end
%%                        end,
%%                    put(?pd_do_he_cheng_count, HeChengCount+1),
%%
%%%%                    NewAttrList = com_util:rand_more(NewList, HeChengTmp#he_cheng_tmp.all_jd_new_len),
%%                    MainGoods1 = item_equip:change_jd_attr(MainGoods, NewAttrList),
%%
%%%%                     NewGemLen = com_util:rand(HeChengTmp#he_cheng_tmp.gem_lens),
%%%%                     NewGemTuple = erlang:make_tuple(NewGemLen, 0),
%%                    MainGoods2 = item_equip:change_gem_tuple(MainGoods1, HeChengTmp#he_cheng_tmp.main_equip_gem_tuple),
%%
%%                    %% 设置装备的品质(当主装备是套装的时候品质不需要改变)
%%                    MainGoods3 =
%%                        case api:is_suit(MainGoods) of
%%                            true ->
%%                                MainGoods2;
%%                            _ ->
%%                                AttrLen = length(NewAttrList),
%%                                Qualily =
%%                                    case AttrLen >= ?equip_orange of
%%                                        true -> ?equip_orange;
%%                                        _ -> AttrLen
%%                                    end,
%%                                item_new:set_field(MainGoods2, ?item_equip_quality, Qualily)
%%                        end,
%%
%%                    %% 刷新数据
%%                    GoodsBucket = game_res:get_bucket(BucketType),
%%                    goods_bucket:begin_sync(GoodsBucket),
%%                    NewGoodsBucket = goods_bucket:update(GoodsBucket, MainGoods3),
%%                    goods_bucket:end_sync(NewGoodsBucket),
%%                    api:record_he_cheng_attr_end(MainGoods3),
%%
%%                    attr_new:set(?pd_hecheng_equip_tmp, 0),
%%                    ok
%%            end
%%    end.


%% 装备史诗打孔
equip_epic_slot(BucketType, GoodsId, CostItemBid) ->
    Goods = get_equip(BucketType, GoodsId),
    game_res:set_res_reasion(<<"打孔">>),

    EquipLevel = get_equip_level(Goods),
    case Goods of
        {error, Error} ->
            {error, Error};
        #item_new{} ->
            case is_equip_slot_all_normal(Goods) of
                ?true ->
                    case load_cfg_punchs:get_punch_type_by_bid(CostItemBid) of
                        ?PUNCH_EPIC_TYPE ->
                            case item_new:get_item_new_field_value_by_key(Goods, ?item_use_data, ?item_equip_epic_gem_slot, 0) of
                                0 ->
                                    {EquipLevel, CostId} = lists:keyfind(EquipLevel, 1, misc_cfg:get_epic_gem_drill_cost()),
                                    CostList = load_cost:get_cost_list(CostId),

                                    case game_res:can_del(CostList) of
                                        {error, _} ->
                                            {error, cost_not_enough};
                                        _ ->
                                            DefaultKeyVal =
                                                [
                                                    {?item_use_data, [
                                                        {?item_equip_epic_gem_slot, 1},
                                                        {?item_equip_epic_gem, 0},
                                                        {?item_equip_epic_gem_exp, 0}
                                                    ]}
                                                ],
                                            NewGoods = item_new:set_fields(Goods, DefaultKeyVal),

                                            %% 扣除消耗物品
                                            game_res:del(CostList, ?FLOW_REASON_EQUIP_DAKONG),
                                            GoodsBucket = game_res:get_bucket(BucketType),
                                            goods_bucket:begin_sync(GoodsBucket),
                                            NewGoodsBucket = goods_bucket:update(GoodsBucket, NewGoods),
                                            goods_bucket:end_sync(NewGoodsBucket),
                                            ok
                                    end;
                                _ ->
                                    {error, cant_slot}
                            end;
                        _ ->
                            {error,punch_type_error}
                    end;
                ?false ->
                    {error,no_solt_all_normal}
            end
    end.

%% 获取装备等级
get_equip_level(Goods) when is_tuple(Goods) ->
    load_equip_expand:get_equip_cfg_level(Goods#item_new.bid);

get_equip_level(Bid) when is_integer(Bid) ->
    load_equip_expand:get_equip_cfg_level(Bid);

get_equip_level(Id) ->
    {err, Id}.

%% 装备普通孔是否全部解锁
is_equip_slot_all_normal(Goods) ->
    case item_new:get_field(Goods, ?item_equip_igem_slot) of
        GemTuple when is_tuple(GemTuple) ->
            GemSoltNum = erlang:size(GemTuple),
            if
                GemSoltNum =:= ?max_gem_slot_count ->
                    ?true;
                true ->
                    ?false
            end;
        _ ->
            ?false
    end.

%% 装备打孔
equip_slot(BucketType, GoodsId, SlotNum, CostItemBid) ->
    Goods = get_equip(BucketType, GoodsId),
    game_res:set_res_reasion(<<"打孔">>),

    case load_cfg_punchs:get_punch_type_by_bid(CostItemBid) of
        ?PUNCH_NORMAL_TYPE ->
            case SlotNum < 1 of
                false ->
                    case Goods of
                        {error, Error} ->
                            {error, Error};
                        #item_new{} ->
                            case lists:keyfind(?item_equip_igem_slot, 1, Goods#item_new.field) of
                                {_Lable, GemTuple} ->
                                    %% 判断打孔之后宝石孔的数量是否超过了最大的宝石孔的数量
                                    GemSoltNum = erlang:size(GemTuple),
                                    case GemSoltNum + SlotNum > ?max_gem_slot_count of
                                        ?true ->
                                            {error, max_slot};
                                        _ ->

                                            CostList2 = get_slot_cost_list(GemSoltNum,SlotNum,CostItemBid),

                                            case game_res:can_del(CostList2) of
                                                {error, _} ->
                                                    {error, cost_not_enough};
                                                _ ->
                                                    NewGemTuple = list_to_tuple(tuple_to_list(GemTuple) ++ lists:duplicate(SlotNum, 0)),
                                                    NewGoods = item_new:set_field(Goods, ?item_equip_igem_slot, NewGemTuple),

                                                    %% 扣除消耗物品
                                                    game_res:del(CostList2, ?FLOW_REASON_EQUIP_DAKONG),

                                                    GoodsBucket = game_res:get_bucket(BucketType),
                                                    goods_bucket:begin_sync(GoodsBucket),
                                                    NewGoodsBucket = goods_bucket:update(GoodsBucket, NewGoods),
                                                    goods_bucket:end_sync(NewGoodsBucket),
                                                    ok
                                            end
                                    end;
                                _ ->
                                    {error, cant_slot}
                            end
                    end;
                _ ->
                    {error, slot_0}
            end;
        _ ->
            {error,punch_type_error}
    end.

%% 装备打孔计算消费
%% @参数(装备拥有的孔个数，装备要打的孔个数，消耗打孔石Id)
get_slot_cost_list(GemSlotNum, SlotNum, CostItemBid) ->
    %% 判断花费是否够用
    TempList = lists:seq(1, ?max_gem_slot_count),
    %% 算出需要打孔的位置
    SlotList = lists:sublist(TempList, GemSlotNum+1, SlotNum),
    %% 全部消耗列表
    CostList1 =
        lists:foldl
        (
            fun(Sit, Acc) ->
                case lists:keyfind(Sit, 1, misc_cfg:get_drill_cost()) of
                    {_Site, CostId} ->
                        case load_cost:get_cost_list(CostId) of
                            CostList when is_list(CostList) ->
                                CostList ++ Acc;
                            _ ->
                                Acc
                        end;
                    _ -> Acc
                end
            end,
            [],
            SlotList
        ),

    %% 把配置表中的消耗Id转换成客户端返回的CostItemId
    %% 获取消耗列表中的底层消耗的物品id个数
    TempCostCount =
        lists:foldl
        (
            fun({CostId, Count}, Acc) ->
                case CostId =:= ?slot_cost_rate_id of
                    true -> Count + Acc;
                    _ -> Acc
                end
            end,
            0,
            CostList1
        ),

    CostItemRate = load_cfg_punchs:get_punch_rate(CostItemBid),

    %% 计算需要消耗的物品个数(结果需要向上求整)
    CostItemCount = util:ceil(TempCostCount / CostItemRate),

    CostList2 =
        [{by_bid, {CostItemBid, CostItemCount}}
            | lists:filter(fun({CostId, _Count}) -> CostId =/= ?slot_cost_rate_id end, CostList1)],
%%    io:format("CostList1:~p \n", [CostList1]),
%%    io:format("CostList2:~p \n", [CostList2]),

    CostList2.

%% 单件装备分解   返回{提炼情况， 提炼物品列表} 注：只能分解背包中的装备
%% 装备分解的时候分为套装和非套装分解生成配置
equip_exchange(ItemId) ->
    Item = get_exchange_equip(ItemId),
    case api:is_suit(Item) of
        ?true ->
            suit_equip_exchange(ItemId);
        ?false ->
            common_equip_exchange(ItemId)
    end.

%% 获取要分解的装备，分解的装备只能是背包中的
get_exchange_equip(ItemId) ->
    Item =
        case get_equip(?BUCKET_TYPE_BAG, ItemId) of
            Item1 when is_record(Item1, item_new) ->
                Item1;
            _ ->
                ?return_err(?ERR_NOT_FOUND_THIS_ITEM)
        end,
    Item.

%% 套装分解
suit_equip_exchange(ItemId) ->
    Item = get_exchange_equip(ItemId),
    SuitBid = item_new:get_bid(Item),

    %% 判断装备是否镶嵌宝石
    case is_equip_have_gem(Item) of
        false ->
            %% 判断消耗是否够用
            CostId = load_cfg_suit_fenjie:get_suit_fenjie_cost(SuitBid),
            CostList = cost:get_cost(CostId),
            case game_res:can_del(CostList) of
                ok ->
                    %% 判断背包的空间是否充足
                    Quality = item_new:get_field(Item, ?item_equip_quality),
                    GiveGoodsList = load_cfg_suit_fenjie:get_create_goods_list(SuitBid, Quality),
                    case game_res:can_give(GiveGoodsList) of
                        ok ->
                            %% 扣除装备和消耗
                            CostList1 = [{by_id, {ItemId, 1}} | CostList],
                            game_res:del(CostList1, ?FLOW_REASON_EQUIP_EXCHANGE),
                            %% 给玩家赠送生成物品
                            game_res:give(GiveGoodsList, ?FLOW_REASON_EQUIP_EXCHANGE),
                            {ok, GiveGoodsList};
                        _ ->
                            {{error, bag_not_enough}, []}
                    end;
                _ ->
                    {{error, cost_not_enough}, []}
            end;
        _ ->
            {{error, equip_can_not_exchange}, []}
    end.



%% 普通装备分解
common_equip_exchange(ItemId) ->
    Item = get_exchange_equip(ItemId),
    %% 判断此装备是否可以提炼
    #item_new{
        bid = ItemBid,field = Field, type = Type
    } = Item,

    %% 宝石情况是否可以提炼
    CanGem =
        case lists:keyfind(?item_equip_igem_slot, 1, Field) of
            {_Lable, GemTuple} ->
                GemList = lists:filter(fun(X) -> X =/= 0 end, tuple_to_list(GemTuple)),
                case length(GemList) =:= 0 of
                    true ->
                        case item_equip:can_be_exchange_epic_slot(Item) of
                            ?false ->
                                0;
                            ?true ->
                                1
                        end;
                    _ ->
                        0
                end;
            _ ->
                0
        end,

    IsCan = load_equip_expand:get_equip_can_exchange(ItemBid),
%%    ?INFO_LOG("CanGem = ~p,   IsCan = ~p", [IsCan, CanGem]),
    CanType = com_util:bool_to_integer(lists:member(Type, ?all_equips_type)),
    case IsCan band CanGem band CanType of
        ?TRUE ->
            %% 判断背包的格子数量
            BagLimitNum = misc_cfg:get_equip_exchange_bag_limit(),
            BagBucket = game_res:get_bucket(?BUCKET_TYPE_BAG),
            LeftSize = goods_bucket:get_empty_size(BagBucket),
            case LeftSize >= BagLimitNum of
                true ->
                    %% 判断消耗
                    EquipUseLevel = load_equip_expand:get_equip_cfg_level(ItemBid),
                    CostId = load_equip_expand:get_cfg_exchange_cost_id(EquipUseLevel),
                    CostList = cost:get_cost(CostId),
                    case game_res:can_del(CostList) of
                        ok ->
                            QHlevel = item_new:get_field(Item, ?item_equip_qianghua_lev),
                            Quality = item_new:get_field(Item, ?item_equip_quality),
                            GoodsList1 = equip_change_goods_of_quality(EquipUseLevel, Quality),
                            GoodsList2 = equip_change_goods_of_qhlevel(EquipUseLevel, QHlevel),

                            %% 消除bid重复的元素
                            GoodsList3 =
                                lists:foldl
                                (
                                    fun({Bid, Count}, Acc) ->
                                        case lists:keyfind(Bid, 1, Acc) of
                                            {_Bid, Count1} ->
                                                lists:keyreplace(Bid, 1, Acc, {Bid, Count+Count1});
                                            _ ->
                                                [{Bid, Count} | Acc]
                                        end
                                    end,
                                    [],
                                    GoodsList1 ++ GoodsList2
                                ),
                            case game_res:try_del([{by_id, {ItemId, 1}}], ?FLOW_REASON_EQUIP_EXCHANGE) of
                                {error, _} ->
                                    ?INFO_LOG("delete goods error"),
                                    ?return_err(?ERR_DEL_GOODS_ERROR);
                                _ ->
                                    %% 扣除消耗
                                    game_res:del(CostList, ?FLOW_REASON_EQUIP_EXCHANGE),
                                    bounty_mng:do_bounty_task(?BOUNTY_TASK_FENJIE_EQUIP, 1),
                                    %% 给提取到的物品
                                    case game_res:try_give_ex(GoodsList3, ?FLOW_REASON_EQUIP_EXCHANGE) of
                                        {error, _Err} ->
                                            ?ERROR_LOG("give gooods error ~p", [_Err]),
                                            ?return_err(?ERR_GIVE_GOODS_ERROR);
                                        _ ->
                                            ok
                                    end,
                                    {ok, GoodsList3}
                            end;
                        _ ->
                            {{error, cost_not_enough}, []}
                    end;
                _ ->
                    {{error, bag_not_enough}, []}
            end;
        _ ->
            {{error, equip_can_not_exchange}, []}
    end.


%% 装备一键提取（根据背包中装备的品质）   返回{提炼情况， 提炼物品列表}
equip_one_key_exchange(QuaList) ->
    %% 获取背包中的物品列表
    BagEqmBucket = game_res:get_bucket(?BUCKET_TYPE_BAG),
    BagItemList = goods_bucket:get_goods(BagEqmBucket),

    %% 筛选出符合品质列表的装备列表
    {EquipItemList, GoodsList, CostList} =   %%{消耗装备列表, 生成物品列表, 消耗列表}
    lists:foldl
    (
        fun(Item, {TItemList, TGoodsList, TCostList}) ->
            case Item of
                #item_new{id = Id, bid = Bid, type = Type} ->
                    case lists:member(Type, ?all_equips_type) of
                        true ->
                            Quality = item_new:get_field(Item, ?item_equip_quality),
                            IsCan = load_equip_expand:get_equip_can_exchange(Bid),
                            QhLevel = item_new:get_field(Item, ?item_equip_qianghua_lev),
                            CanQh =
                                case QhLevel =:= 0 of
                                    true ->
                                        true;
                                    _ ->
                                        false
                                end,
%%                                ?INFO_LOG("Field = ~p", [Field]),
%%                                ?INFO_LOG("Quality = ~p", [Quality]),
%%                                ?INFO_LOG("IsCan = ~p", [IsCan]),
                            CanJd = item_new:get_field(Item, ?item_equip_is_jd),
                            %% 判断宝石情况
                            CanGem =
                                case is_equip_have_gem(Item) of
                                    true ->
                                        false;
                                    _ ->
                                        true
                                end,
                            case lists:member(Quality, QuaList)
                                andalso com_util:integer_to_bool(IsCan)
                                andalso CanQh
                                andalso com_util:integer_to_bool(CanJd)
                                andalso CanGem of
                                true ->

                                    %% 判断装备是否是套装来给出相应的物品列表和消耗列表
                                    {GoodsList1, CostList1} =
                                        case api:is_suit(Item) of
                                            true ->
                                                SuitGoodsList = load_cfg_suit_fenjie:get_create_goods_list(Bid, Quality),
                                                SuitCostId = load_cfg_suit_fenjie:get_suit_fenjie_cost(Bid),
                                                SuitCostList = cost:get_cost(SuitCostId),
                                                {SuitGoodsList, SuitCostList};
                                            _ ->
                                                EquipUseLevel = load_equip_expand:get_equip_cfg_level(Bid),
                                                RetGoodsList2 = equip_change_goods_of_quality(EquipUseLevel, Quality),
                                                CostId = load_equip_expand:get_cfg_exchange_cost_id(EquipUseLevel),
                                                RetCostList2 = cost:get_cost(CostId),
                                                {RetGoodsList2, RetCostList2}
                                        end,
                                    AGoodsList = GoodsList1 ++ TGoodsList,
                                    ACostList = CostList1 ++ TCostList,
                                    {[{by_id, {Id, 1}} | TItemList], AGoodsList, ACostList};
                                _ ->
                                    {TItemList, TGoodsList, TCostList}
                            end;
                        _ ->
                            {TItemList, TGoodsList, TCostList}
                    end;
                _ ->
                    {TItemList, TGoodsList, TCostList}
            end
        end,
        {[], [], []},
        BagItemList
    ),
%%    io:format("{EquipItemList, GoodsList, CostList} = ~p~n", [{EquipItemList, GoodsList, CostList}]),

    %% 消除bid重复的元素
    GoodsList2 =
        lists:foldl
        (
            fun({Bid, Count}, Acc) ->
                case lists:keyfind(Bid, 1, Acc) of
                    {_Bid, Count1} ->
                        lists:keyreplace(Bid, 1, Acc, {Bid, Count+Count1});
                    _ ->
                        [{Bid, Count} | Acc]
                end
            end,
            [],
            GoodsList
        ),

    case EquipItemList of
        [] ->
            {{error, no_list}, []};
        _ ->
            %% 判断背包的格子数量
            BagLimitNum = misc_cfg:get_equip_exchange_bag_limit(),
            LeftSize = goods_bucket:get_empty_size(BagEqmBucket),
            case LeftSize >= BagLimitNum of
                true ->
                    %% 判断消耗
                    case game_res:can_del(CostList) of
                        ok ->
                            %% 判断装备是否可以扣除
                            case game_res:try_del(EquipItemList, ?FLOW_REASON_EQUIP_EXCHANGE) of
                                {error, _} ->
                                    ?INFO_LOG("delete goods error"),
                                    ?return_err(?ERR_DEL_GOODS_ERROR);
                                _ ->
                                    bounty_mng:do_bounty_task(?BOUNTY_TASK_FENJIE_EQUIP, length(EquipItemList)),
                                    %% 扣除消耗
                                    game_res:del(CostList, ?FLOW_REASON_EQUIP_EXCHANGE),
                                    %% 给提取到的物品
                                    case game_res:try_give_ex(GoodsList2, ?FLOW_REASON_EQUIP_EXCHANGE) of
                                        {error, _Err} ->
                                            ?ERROR_LOG("give gooods error ~p", [_Err]),
                                            ?return_err(?ERR_GIVE_GOODS_ERROR);
                                        _ ->
                                            ok
                                    end,
                                    {ok, GoodsList2}
                            end;
                        _ ->
                            {{error, cost_not_enough}, []}
                    end;
                _ ->
                    {{error, bag_not_enough}, []}
            end
    end.


%% 根据装备的品质获取随机物品的数量 返回[{bid, num}]
equip_change_goods_of_quality(EquipUseLevel, Quality) ->
    QuaCfgList = load_equip_expand:get_equip_cfg_exchange_quality(EquipUseLevel),
%%    ?INFO_LOG("EquipUseLevel = ~p", [EquipUseLevel]),
%%    ?INFO_LOG("QuaCfgList = ~p", [QuaCfgList]),
    {MinNum, MaxNum} = load_equip_expand:get_equip_cfg_exchange_num_section(EquipUseLevel),
%%    ?INFO_LOG("Min = ~p, Max = ~p", [MinNum, MaxNum]),
    GoodsNum = com_util:random(MinNum, MaxNum),
    CfgGoodsList =
        case lists:keyfind(Quality, 1, QuaCfgList) of
            {_Qua, GoodsList} ->
                GoodsList;
            _ ->
                ?ERROR_LOG("not find cfg goods list")
        end,
%%    ?INFO_LOG("CfgGoodsList = ~p", [CfgGoodsList]),
    GoodsBidList =
        lists:foldl
        (
            fun(_X, Acc) ->
                util:get_val_by_weight(CfgGoodsList, 1) ++ Acc
            end,
            [],
            lists:seq(1, GoodsNum)
        ),
    GoodsList1 =
        lists:foldl
        (
            fun(Bid, Acc) ->
                case lists:keyfind(Bid, 1, Acc) of
                    {_Bid, Count} ->
                        lists:keyreplace(Bid, 1, Acc, {Bid, Count+1});
                    _ ->
                        [{Bid, 1} | Acc]
                end
            end,
            [],
            GoodsBidList
        ),
    GoodsList1.


%% 根据装备的强化等级获取物品的数量 返回[{id, num}]
equip_change_goods_of_qhlevel(_EquipUseLevel, 0) -> [];
equip_change_goods_of_qhlevel(EquipUseLevel, QHlevel) ->
%%    ?INFO_LOG("EquipUseLevel = ~p, QHLevel = ~p", [EquipUseLevel, QHlevel]),
    QHCfgList = load_equip_expand:get_equip_cfg_enhance_level(EquipUseLevel),
%%    ?INFO_LOG("QHCfgList = ~p", [QHCfgList]),
    case lists:filter(fun({{Min, Max}, _, _}) -> QHlevel >= Min andalso QHlevel =< Max end, QHCfgList) of
        [{_, {NumMin, NumMax}, Bid}] ->
            Count = com_util:random(NumMin, NumMax),
            [{Bid, Count}];
        _ ->
            ?ERROR_LOG("not find cfg goods list"),
            ?return_err(?ERR_NOT_FOUND_CFG_GOODS_LIST)
    end.

%% 还原装备附魔公式情况
restore_equip_fumo_state() ->
    FumoModeList =
    case get(?pd_equip_fumo_mode_state) of
        0 ->
            handle_init_fumo_state();
        ?undefined ->
            handle_init_fumo_state();
        StateList when is_list(StateList) ->
            StateList
    end,

    %% 附魔初始化的数据发送到前端
    SendList =
    lists:foldl(fun({Id, State}, AccList) ->
        case State =:= ?EQUIP_FUMO_STATE_USE of
            true ->
                [Id | AccList];
            _ ->
                AccList
        end
    end,
    [],
    FumoModeList),
    ?player_send(equip_sproto:pkg_msg(?MSG_EQUIP_FUMO_MODE_LIST, {SendList})),
    ok.

handle_init_fumo_state() ->
    AllStateList = load_equip_expand:get_all_equip_fumo_state_id(),
    FumoList =
    lists:foldl(fun(Id, AccList) ->
        [{Id, ?EQUIP_FUMO_STATE_INIT} | AccList]
    end,
    [],
    AllStateList),
    put(?pd_equip_fumo_mode_state, FumoList),
    FumoList.


%% 装备附魔
%% 注：装备附魔有两种形式，一种是附魔卷轴附魔，另一种时附魔石附魔
equip_fumo(FumoId, BucketType, ItemId, FumoType, ServerFumoId) ->
    case FumoType of
        1 ->%% 附魔卷轴附魔
            scroll_fumo(FumoId, BucketType, ItemId);
        2 ->%% 附魔石附魔
            stone_fumo(FumoId, BucketType, ItemId, ServerFumoId);
        _ ->
            ?ERROR_LOG("error fumo type: ~p", [FumoType]),
            pass
    end.

%% 普通附魔
scroll_fumo(FumoId, BucketType, ItemId) ->
    %% 判断该附魔公式是否被激活
    AllFumoModeList = get(?pd_equip_fumo_mode_state),
    case lists:keyfind(FumoId, 1, AllFumoModeList) of
        {_FumoId, _IsUse} ->
            %case IsUse =:= ?EQUIP_FUMO_STATE_USE of
            %    true ->
                    %% 判断附魔id与装备是否是相符
                    EquipPartList = load_equip_expand:get_equip_fumo_part_list(FumoId),
                    Item = get_equip(BucketType, ItemId),
                    #item_new{type = EquipType} = Item,
                    %% 判断装备是否鉴定
                    case item_new:get_field(Item, ?item_equip_is_jd) of
                        1 ->
                            case lists:member(EquipType, EquipPartList) of
                                true ->
                                    CostId = load_equip_expand:get_equip_fumo_cost_id(FumoId),
                                    CostList = cost:get_cost(CostId),
                                    case game_res:can_del(CostList) of
                                        ok ->
                                            game_res:del(CostList, ?FLOW_REASON_EQUIP_FUMO),
                                            %% 添加附魔属性与装备的bufId
                                            NewItem = add_fumo_attr_and_buf(FumoId, Item),
                                            %% 同步背包的相关数据
                                            GoodsBucket = game_res:get_bucket(BucketType),
                                            goods_bucket:begin_sync(GoodsBucket),
                                            NewGoodsBucket = goods_bucket:update(GoodsBucket, NewItem),
                                            goods_bucket:end_sync(NewGoodsBucket),
                                            ok;
                                        _ ->
                                            {error, cost_not_enough}
                                    end;
                                _ ->
                                    {error, type_error}
                            end;
                        _ ->
                            {error, not_jd}
                    end;
                %_ ->
                %    {error, fumo_not_activate}
            %end;
        _ ->
            ?ERROR_LOG("not find fumo mode"),
            {error, not_find_fumo_mode}
    end.

%% 附魔石附魔
stone_fumo(FumoId, BucketType, ItemId, ServerFumoId) ->
    %?DEBUG_LOG("ServerFumoId-----:~p----ItemId----:~p",[ServerFumoId, ItemId]),
    case goods_bucket:find_goods(game_res:get_bucket(?BUCKET_TYPE_BAG), by_id, {ServerFumoId}) of
        #item_new{} = MoshiItem ->
            %% 判断附魔id与装备是否是相符
            EquipPartList = load_equip_expand:get_equip_fumo_part_list(FumoId),
            %?DEBUG_LOG("FumoId-----:~p---------------EquipParList-----:~p",[FumoId, EquipPartList]),
            Item = get_equip(BucketType, ItemId),
            %?DEBUG_LOG("Item--------------------------:~p",[Item]),
            #item_new{type = EquipType} = Item,

            %% 判断装备是否已经鉴定
            case item_new:get_field(Item, ?item_equip_is_jd) of
                1 ->
                    %% 判断装备的附魔类型
                    case lists:member(EquipType, EquipPartList) of
                        true ->
                            %% 获取装备的附魔石id
                            StoneId = load_equip_expand:get_equip_enchant_stone_id(FumoId),
                            case game_res:can_del([{by_bid, {StoneId, 1}}]) of
                                ok ->
                                    game_res:del([{by_bid, {StoneId, 1}}], ?FLOW_REASON_EQUIP_FUMO),
                                    %% 添加附魔属性与装备的bufId
                                    %NewItem = add_fumo_attr_and_buf(FumoId, Item),
                                    NewItem = add_fumo_attr_and_buf_of_moshi(Item, MoshiItem, FumoId),
                                    %% 同步背包的相关数据
                                    GoodsBucket = game_res:get_bucket(BucketType),
                                    goods_bucket:begin_sync(GoodsBucket),
                                    NewGoodsBucket = goods_bucket:update(GoodsBucket, NewItem),
                                    goods_bucket:end_sync(NewGoodsBucket),
                                    ok;
                                _ ->
                                    {error, cost_not_enough}
                            end;
                        _ ->
                            {error, type_error}
                    end;
                _ ->
                    {error, not_jd}
            end;
        _ ->
            {error, type_error}
    end.

add_fumo_attr_and_buf_of_moshi(Item, MoshiItem, FumoId) ->
    FuMoData = item_equip:get_fumo_attr_list(MoshiItem),
    if
        FuMoData =:= [] ->
            add_fumo_attr_and_buf(FumoId, Item);
        true ->
            OldFumoId = item_new:get_field(Item, ?item_equip_fumo_mode_message, 0),
            NewItem = item_new:set_field(Item, ?item_equip_fumo_mode_message, FumoId),

            NewItem1 = item_equip:change_fumo_attr(NewItem, FuMoData),

            %% 增加装备的buf属性
            OldBufList = item_new:get_field(NewItem1, ?item_equip_buf_list, []),
            RetBufList = load_equip_expand:get_equip_fumo_cfg_buff_id_list(FumoId),
            RetBufList1 =
            case OldFumoId =:= 0 of
                true ->
                    OldBufList ++ RetBufList;
                _ ->
                    OldBufList2 = OldBufList -- load_equip_expand:get_equip_fumo_cfg_buff_id_list(OldFumoId),
                    OldBufList2 ++ RetBufList
            end,
            item_equip:change_buf_list(NewItem1, RetBufList1)
    end.


%% 添加、附魔的的buf属性
add_fumo_attr_and_buf(FumoId, Item) ->
    %% 设置装备的附魔公式
    OldFumoId = item_new:get_field(Item, ?item_equip_fumo_mode_message, 0),
    NewItem = item_new:set_field(Item, ?item_equip_fumo_mode_message, FumoId),

    FumoList = load_equip_expand:get_equip_fumo_cfg_attr_list(FumoId),
    NewItem1 = item_equip:change_fumo_attr(NewItem, FumoList),

    %% 增加装备的buf属性
    OldBufList = item_new:get_field(NewItem1, ?item_equip_buf_list, []),
    RetBufList = load_equip_expand:get_equip_fumo_cfg_buff_id_list(FumoId),
    RetBufList1 =
    case OldFumoId =:= 0 of
        true ->
            OldBufList ++ RetBufList;
        _ ->
            OldBufList2 = OldBufList -- load_equip_expand:get_equip_fumo_cfg_buff_id_list(OldFumoId),
            OldBufList2 ++ RetBufList
    end,
    NewItem2 = item_equip:change_buf_list(NewItem1, RetBufList1),

%%    %% 获取参加计算的千分比列表
%%    MillList = [{AttrId, Rat} || {Type, AttrId, Rat} <- FumoList, Type =:= ?equip_fumo_cfg_type_per_mill],
%%    %% 修改装备的基础属性
%%    JCAttr = item_new:get_field(Item, ?item_equip_base_prop),
%%    NewJCAttr = load_equip_expand:change_jc_attr_fumo(JCAttr, MillList),
%%    NewItem3 = item_new:set_field(NewItem2, ?item_equip_base_prop, NewJCAttr),
%%
%%    %% 修改装备的鉴定属性
%%    JdAttrList = item_equip:get_authenticate_attr_list(NewItem3),
%%    NewJdAttrList = load_equip_expand:change_jd_attr_fumo(JdAttrList, MillList),
%%    NewItem4 = item_equip:change_jd_attr(NewItem3, NewJdAttrList),
    NewItem2.


%% 激活附魔公式
activate_fumo_state(FumoModeId) ->
    %% 获取对应的附魔卷轴的id
    FumoScrollId = load_equip_expand:get_equip_fumo_scroll_id(FumoModeId),
    FumoModeList = get(?pd_equip_fumo_mode_state),

    case lists:keyfind(FumoModeId, 1, FumoModeList) of
        {FumoModeId, IsUse} ->
            case IsUse =:= ?EQUIP_FUMO_STATE_USE of
                false ->
                    case game_res:can_del([{by_bid, {FumoScrollId, 1}}]) of         %% 每次激活消耗1个附魔卷轴
                        ok ->
                            %% 扣除消耗
                            game_res:del([{by_bid, {FumoScrollId, 1}}], ?FLOW_REASON_ACTIVITY_FUMO),
                            NewFumoModeList =
                                lists:foldl
                                (
                                    fun({FumoId, State}, AccList) ->
                                        case FumoId =:= FumoModeId of
                                            true ->
                                                [{FumoId, ?EQUIP_FUMO_STATE_USE} | AccList];
                                            _ ->
                                                [{FumoId, State} | AccList]
                                        end
                                    end,
                                    [],
                                    FumoModeList
                                ),
                            put(?pd_equip_fumo_mode_state, NewFumoModeList),
                            ok;
                        _ ->
                            {error, cost_not_enough}
                    end;
                _ ->
                    {error, already_use}
            end;
        _ ->
            ?ERROR_LOG("not fing fumo id"),
            pass
    end.




%% 同步附魔公式列表
sync_fumo_mode_list() ->
    AllFumoModeList = get(?pd_equip_fumo_mode_state),
    SendFumoList =
        lists:foldl
        (
            fun({FumoId, State}, AccList) ->
                case State =:= ?EQUIP_FUMO_STATE_USE of
                    true ->
                        [FumoId | AccList];
                    _ ->
                        AccList
                end
            end,
            [],
            AllFumoModeList
        ),
    ?player_send(equip_sproto:pkg_msg(?MSG_EQUIP_FUMO_MODE_LIST, {SendFumoList})).


%% 装备萃取
equip_cuiqu(BucketType, ItemId) ->
    %% 获取物品
    Item = get_equip(BucketType, ItemId),
    %% 先判断该装备是否已经被附魔
    FumoState = item_new:get_field(Item, ?item_equip_fumo_mode_message),

    case is_equip_have_gem(Item) of
        false ->
            case FumoState =:= ?EQUIP_FUMO_STATE_INIT of
                false ->
                    %% 获取此装备的附魔公式
                    FumoMode = item_new:get_field(Item, ?item_equip_fumo_mode_message),
%%            ?INFO_LOG("FumoModeID = ~p", [FumoMode]),
                    CostId = load_equip_expand:get_equip_leach_cost_id(FumoMode),
%%            ?INFO_LOG("CostId = ~p", [CostId]),
                    CostList = [{by_id, {ItemId, 1}} | cost:get_cost(CostId)],
                    case game_res:can_del(CostList) of
                        ok ->
                            game_res:del(CostList, ?FLOW_REASON_EUQIP_CUIQU),
                            %% 获取需要添加附魔石的bid

                            OldFumoAttr = item_new:get_field(Item, ?item_equip_fumo_attr_list, []),
                            %?DEBUG_LOG("OldFumoAttr--------------------------:~p",[OldFumoAttr]),
                            StoneId = load_equip_expand:get_equip_enchant_stone_id(FumoMode),
                            game_res:try_give_ex([{StoneId, 1, OldFumoAttr}], ?FLOW_REASON_EQUIP_EXCHANGE),
                            ok;
                        _ ->
                            {error, cost_not_enough}
                    end;
                _ ->
                    {error, not_fumo}
            end;
        _ ->
            {error, have_gem}
    end.

%% 判断装备是否含有宝石（包含史诗级宝石）
is_equip_have_gem(ItemEquip) when is_record(ItemEquip, item_new)->
    %% 判断普通宝石
    GemTuple = item_new:get_field(ItemEquip, ?item_equip_igem_slot),
    GemSlotList = tuple_to_list(GemTuple),
    GemList = [GemId || GemId <- GemSlotList, GemId =/= 0],
    GemRet1 =
        case erlang:length(GemList) of
            0 -> false;
            _ -> true
        end,

    %% 判断史诗宝石
    MiscList = item_new:get_field(ItemEquip, ?item_use_data),
    GemRet2 =
        case lists:keyfind(?item_equip_epic_gem, 1, MiscList) of
            {_Key, GemId} when GemId =/= 0 andalso GemId =/= 1 ->
                true;
            _ ->
                false
        end,

    GemRet1 or GemRet2;

is_equip_have_gem(Msg) ->
    ?ERROR_LOG("Msg ~p is not item_new record", [Msg]).

restone_part_qiang_hua_attr() ->
    QHList = get(?pd_part_qiang_hua_list),
    Role = get(?pd_career),
    lists:foreach
    (
        fun({PartType, Lvl}) ->
            case is_have_equip_by_part(PartType) of
                {true, Quality} ->
                    CfgQualityList = misc_cfg:get_qianghua_by_quality(),
                    PerMill = util:get_field(CfgQualityList, Quality, 0),
                    Attr = load_equip_expand:get_part_qh_all_attr(Role, PartType, Lvl),
                    Attr1 = load_equip_expand:change_attr_by_permill(Attr, PerMill),
                    attr_new:player_add_attr(Attr1);
                _ ->
                    pass
            end
        end,
        QHList
    ),
    attr_new:update_player_attr(),
    ok.

%% 还原角色的强化属性
restone_part_qiang_hua_list() ->
    QHList = get(?pd_part_qiang_hua_list),

    %?INFO_LOG("QHList = ~p", [QHList]),
    item_equip:update_part_qianghua_effect(),
    ?player_send(equip_sproto:pkg_msg(?MSG_EQUIP_PART_QAINGHUA_INIT, {QHList})).

%% 强化根据玩家身体穿装备的部分进行强化，与是否穿装备无关
part_qiang_hua(PartType, UsCount) ->
%%    ?INFO_LOG("PartType = ~p", [PartType]),
    QhList = get(?pd_part_qiang_hua_list),
    case lists:keyfind(PartType, 1, QhList) of
        {_, BeforeLevel} ->
            PlayerLevel = get(?pd_level),
            Role = get(?pd_career),
            %% 判断当前等级是否已经超过了最大的等级
            case BeforeLevel >= PlayerLevel of
                false ->
                    %% 判断是否能找到相关配置信息
                    case load_equip_expand:get_part_qiang_hua_cost(Role, PartType, BeforeLevel+1) of
                        {error, _} ->
                            {{error, not_find_cfg}, PartType, BeforeLevel};
                        CostId ->
%%                            ?INFO_LOG("CostId = ~p", [CostId]),
                            CostList = cost:get_cost(CostId),
%%                            ?INFO_LOG("CostList = ~p", [CostList]),
                            {BaoHuId, Per} = misc_cfg:get_qiang_hua_id(),
                            CostList1 =
                                case UsCount of
                                    0 -> CostList;
                                    Num -> [{by_bid, {BaoHuId, Num}}|CostList]
                                end,
                            %% 判断消耗是否足够
                            case game_res:can_del(CostList1) of
                                ok ->
                                    bounty_mng:do_bounty_task(?BOUNTY_TASK_QIANGHUA_EQUIP, 1),
                                    game_res:del(CostList1, ?FLOW_REASON_EQUIP_QIANGHUA),
                                    %% 判断强化是否成功
                                    case load_equip_expand:can_part_qh_succeed(BeforeLevel+1, (UsCount * Per)) of
                                        true ->
                                            NewQHList = util:set_field(QhList, PartType, BeforeLevel+1),
                                            put(?pd_part_qiang_hua_list, NewQHList),
                                            OldAttr = load_equip_expand:get_part_qh_all_attr(Role, PartType, BeforeLevel),
                                            NewAttr = load_equip_expand:get_part_qh_all_attr(Role, PartType, BeforeLevel+1),
                                            set_qianghua_attr(PartType, OldAttr, NewAttr),
                                            item_equip:update_part_qianghua_effect(),
                                            {ok, PartType, BeforeLevel+1};
                                        _ ->
                                            %% 强化失败等级下降
                                            FailList = load_equip_expand:get_failed_down(Role, PartType, BeforeLevel+1),
                                            [FailLevel] = util:get_val_by_weight(FailList, 1),
                                            NewLevel = max(BeforeLevel-FailLevel, 0),
                                            OldAttr = load_equip_expand:get_part_qh_all_attr(Role, PartType, BeforeLevel),
                                            NewAttr = load_equip_expand:get_part_qh_all_attr(Role, PartType, NewLevel),
                                            set_qianghua_attr(PartType, OldAttr, NewAttr),
                                            NewList = util:set_field(QhList, PartType, NewLevel),
                                            put(?pd_part_qiang_hua_list, NewList),
                                            item_equip:update_part_qianghua_effect(),
                                            {{error, qh_failed}, PartType, NewLevel}
                                    end;
                                _ ->
                                    {{error, cost_not_enough}, PartType, BeforeLevel}
                            end
                    end;
                _ ->
                    {{error, max_level}, PartType, BeforeLevel}
            end;
        _ ->
            ?ERROR_LOG("not find Type: ~p", [PartType]),
            {{error, not_find_type}, PartType, 0}
    end.

%% 装备洗炼
equip_xilian(ItemId, BucketType, LockAttrList) ->
    Item = get_equip(BucketType, ItemId),
%%    ?INFO_LOG("Item = ~p", [Item]),
    ItemBid = item_new:get_bid(Item),
    CfgJdAttr = load_equip_expand:get_cfg_jd_attr(ItemBid),
    [Head | _] = CfgJdAttr,
%%    ?INFO_LOG("xilian equip attr type:~p", [Head]),
    %% 判断属性的配置类型(是根据配置筛选还是已经定死的数据)
    case Head of
%%        {{_Id, _Min, _Max}, {_, _}} ->
        {{_Id, _Val}, _W} ->
            %% 判断消耗
            LockNum = length(LockAttrList),
            AllCostList = misc_cfg:get_equip_xilian_cost(),
            CostId = util:get_field(AllCostList, LockNum, 0),
            CostList = cost:get_cost(CostId),
            XiLianId = misc_cfg:get_xilian_stone_id(),
            CostList1 = [{XiLianId, 1}|CostList],
%%            ?INFO_LOG("CostList1 = ~p~n", [CostList1]),
            case game_res:can_del(CostList1) of
                ok ->
                    ItemAttrList = item_equip:get_authenticate_attr_list(Item),
                    ShengAttrList =
                        lists:foldl
                        (
                            fun({{Id, Val},_}, AccList) ->
                                case lists:member(Id, LockAttrList) of
                                    true ->
                                        AccList;
                                    _ ->
                                        [{Id, Val} | AccList]
                                end
                            end,
                            [],
                            CfgJdAttr
                        ),
                    {LockList, UnLockList} =
                        lists:foldr
                        (
                            fun({Id, Val, Per, Min, Max}, {List1, List2}) ->
                                case lists:member(Id, LockAttrList) of
                                    true ->
                                        {[{Id, Val, Per, Min, Max}|List1], List2};
                                    _ ->
                                        {List1, [{Id, Val, Per, Min, Max} | List2]}
                                end
                            end,
                            {[], []},
                            ItemAttrList
                        ),
                    Num = length(UnLockList),
                    %% 从剩余列表中的属性随机选出需要的属性条数
%%                    ?INFO_LOG("ShengAttrList = ~p", [ShengAttrList]),
                    RandList = com_util:rand_more(ShengAttrList, Num),
%%                    ?INFO_LOG("RandList = ~p", [RandList]),
                    Quality = item_new:get_field(Item, ?item_equip_quality),
                    {PerMin, PerMax} =
                        case lists:keyfind(Quality, 1, misc_cfg:get_jd_attr_range()) of
                            {Quality, {PMin, PMax}} ->
                                {PMin, PMax};
                            _ ->
                                ?ERROR_LOG("not find quality:~p range", [Quality])
                        end,
                    %% 属性概率还是使用之前的item
                    {NewRandList, _} =
                        lists:foldl
                        (
                            fun({AttrId, CfgVal}, {AccList, AccCount}) ->
                                RetPer = com_util:random(PerMin, PerMax),
                                AttrVal = max(1, com_util:floor(CfgVal * (RetPer/100))),
                                AttrMin = max(1, com_util:floor(CfgVal * (PerMin/100))),
                                AttrMax = com_util:floor(CfgVal * (PerMax/100)),
                                {[{AttrId, AttrVal, 100, AttrMin, AttrMax} | AccList],
                                    AccCount+1}
                            end,
                            {[], 1},
                            RandList
                        ),
%%                    ?INFO_LOG("LockList = ~p", [LockList]),
%%                    ?INFO_LOG("NewRandList = ~p", [NewRandList]),
                    NewAttrList = LockList ++ NewRandList,
                    %% 设置装备的鉴定属性
                    NewItem = item_equip:change_jd_attr(Item, NewAttrList),
                    %% 扣除消耗
                    game_res:del(CostList1, ?FLOW_REASON_EQUIP_XILIANG),
                    %% 同步背包的相关数据
                    GoodsBucket = game_res:get_bucket(BucketType),
                    goods_bucket:begin_sync(GoodsBucket),
                    NewGoodsBucket = goods_bucket:update(GoodsBucket, NewItem),
                    goods_bucket:end_sync(NewGoodsBucket),

                    bounty_mng:do_bounty_task(?BOUNTY_TASK_XILIAN, 1),
                    ok;
                _ ->
                    {error, cost_not_enough}
            end;
        _ ->
            {error, cant_xilian}
    end.





%% -----------------------------
%% private
%% -----------------------------
get_equip(BucketType, GoodsID) ->
    Goods =
    case BucketType of
        ?BUCKET_TYPE_BAG ->
            TempBucket = game_res:get_bucket(?BUCKET_TYPE_BAG),
            case goods_bucket:find_goods(TempBucket, by_id, {GoodsID}) of
                {error, _} ->
                    ret:error(no_goods);
                FindGoods ->
                    case item_new:get_main_type(FindGoods) of
                        ?val_item_main_type_equip ->
                            FindGoods;
                        _ ->
                            ret:error(no_goods)
                    end
            end;
        ?BUCKET_TYPE_EQM ->
            TempBucket = game_res:get_bucket(?BUCKET_TYPE_EQM),
            case goods_bucket:find_goods(TempBucket, by_id, {GoodsID}) of
                {error, _} ->
                    ret:error(no_goods);
                FindGoods ->
                    case item_new:get_main_type(FindGoods) of
                        ?val_item_main_type_equip ->
                            FindGoods;
                        _ ->
                            ret:error(no_goods)
                    end
            end
    end,
    Goods.

%% 判断该部位是否有装备 {true, Quality} or false
is_have_equip_by_part(PartType) ->
    Bucket = game_res:get_bucket(?BUCKET_TYPE_EQM),
    case goods_bucket:find_goods(Bucket, by_pos, {PartType}) of
        {error, _} ->
            false;
        Item ->
            Quality = item_new:get_field(Item, ?item_equip_quality),
            {true, Quality}
    end.

%% 设置玩家的强化属性(当该部位没有装备时,不改变属性)
set_qianghua_attr(TypePart, OldAttr, NewAttr) ->
    case is_have_equip_by_part(TypePart) of
        {true, Quality} ->
            CfgQualityList = misc_cfg:get_qianghua_by_quality(),
            PerMill = util:get_field(CfgQualityList, Quality, 0),
            OldAttr1 = load_equip_expand:change_attr_by_permill(OldAttr, PerMill),
            attr_new:player_sub_attr(OldAttr1),
            NewAttr1 = load_equip_expand:change_attr_by_permill(NewAttr, PerMill),
            attr_new:player_add_attr(NewAttr1),
            attr_new:update_player_attr();
        _ ->
            pass
    end.

%% 穿装备的时候增加强化属性
take_on_equip_add_qh_attr(Item, PartType) ->
    EquipBid = Item#item_new.bid,
    EquipLevel = load_equip_expand:get_equip_cfg_level(EquipBid),
    %?DEBUG_LOG("EquipBid---:~p------EquipLevel----:~p",[EquipBid, EquipLevel]),
    Quality = item_new:get_field(Item, ?item_equip_quality),
    CfgQualityList = misc_cfg:get_qianghua_by_quality(),
    PerMill = util:get_field(CfgQualityList, Quality, 0),
    QhLevel = util:get_field(get(?pd_part_qiang_hua_list), PartType, 0),
    CfgLevelList = misc_cfg:get_equip_qianghua_lv(),
    QhLevelPer = util:get_field(CfgLevelList, EquipLevel, 0),
    Attr = load_equip_expand:get_part_qh_all_attr(get(?pd_career), PartType, QhLevel),
    Attr1 = load_equip_expand:change_attr_by_permill(Attr, PerMill),
    Attr2 = load_equip_expand:change_attr_by_permill(Attr1, QhLevelPer),
    attr_new:player_add_attr(Attr2),
    attr_new:update_player_attr().

%% 脱掉装备的时候减掉强化属性
take_off_equip_sub_qh_attr(Item, PartType) ->
%%    ?INFO_LOG("2Power_1 = ~p", [get(?pd_combat_power)]),
    EquipBid = Item#item_new.bid,
    EquipLevel = load_equip_expand:get_equip_cfg_level(EquipBid),
    %?DEBUG_LOG("EquipBid---:~p------EquipLevel----:~p",[EquipBid, EquipLevel]),
    Quality = item_new:get_field(Item, ?item_equip_quality),
    CfgQualityList = misc_cfg:get_qianghua_by_quality(),
    PerMill = util:get_field(CfgQualityList, Quality, 0),
    QhLevel = util:get_field(get(?pd_part_qiang_hua_list), PartType, 0),
    CfgLevelList = misc_cfg:get_equip_qianghua_lv(),
    QhLevelPer = util:get_field(CfgLevelList, EquipLevel, 0),
    %?DEBUG_LOG("QHlevel-------:~p-----QhLevelPer-----:~p------CfgLevelLIst--:~p",[QhLevel, QhLevelPer, CfgLevelList]),
    Attr = load_equip_expand:get_part_qh_all_attr(get(?pd_career), PartType, QhLevel),
    Attr1 = load_equip_expand:change_attr_by_permill(Attr, PerMill),
    Attr2 = load_equip_expand:change_attr_by_permill(Attr1, QhLevelPer),
    attr_new:player_sub_attr(Attr2),
%%    ?INFO_LOG("2Power_2 = ~p", [get(?pd_combat_power)]),
    attr_new:update_player_attr().

%% 记录玩家身上的装备变化信息
begin_suit_equip_attr(EquipBucket) ->
    put(?pd_stone_player_take_on_off_equip, EquipBucket).

%% 玩家身上套装发生变化时重新计算套装属性
end_suit_equip_attr(Equip1, Equip2) ->
    case api:is_suit(Equip1) or api:is_suit(Equip2) of
        true ->
            %% 获取装备变化之前的套装属性
            OldEquipBucket = get(?pd_stone_player_take_on_off_equip),
            OldEquipList = goods_bucket:get_goods(OldEquipBucket),
            OldAttrId = get_player_suit_attrId(OldEquipList),
            %% 减掉原来的套装属性
            attr_new:player_sub_attr_by_id(OldAttrId),

            NewEquipBucket = game_res:get_bucket(?BUCKET_TYPE_EQM),
            NewEquipList = goods_bucket:get_goods(NewEquipBucket),
            NewAttrId = get_player_suit_attrId(NewEquipList),
            %% 增加新的套装属性
            attr_new:player_add_attr_by_id(NewAttrId);
        _ ->
            pass

    end,
    ok.

get_player_suit_attrId(EquipList) ->
    {SuitId, SuitLevel, SuitCount} =
        lists:foldl
        (
            fun(Equip, {Id, MinLevel, Count}) ->
                SuitId = item_new:get_field(Equip, ?item_equip_suit_id, 0),
                Bid = item_new:get_bid(Equip),
                UseLvl = load_equip_expand:get_equip_cfg_level(Bid),
                case SuitId =/= 0 of
                    true ->
                        case UseLvl =< MinLevel of
                            true ->
                                {SuitId, UseLvl, Count+1};
                            _ ->
                                {SuitId, MinLevel, Count+1}
                        end;
                    _ ->
                        {Id, MinLevel, Count}
                end
            end,
            {0, 1, 0},
            EquipList
        ),
    case SuitId =:= 0 of
        false ->
%%            ?INFO_LOG("cfg ~p", [{SuitId, SuitLevel, SuitCount}]),
            SuitAttrId = load_equip_expand:get_equip_suit_attrId(SuitId, SuitLevel, count_to_cfg_count(SuitCount)),
%%            ?INFO_LOG("SuitAttrId = ~p", [SuitAttrId]),
            SuitAttrId;
        _ ->
            0
    end.

%% 转换套装的个数
count_to_cfg_count(Count) ->
%%    ?INFO_LOG("Count = ~p", [Count]),
    case (Count rem 2) == 0 of
        true ->
            Count;
        _ ->
            Count + 1
    end.

%% 去掉相同的属性id, 相同属性的id随机选择
%%do_he_cheng_filter([]) -> [];
%%do_he_cheng_filter(AttrList) ->
%%    AttrList1 =
%%        lists:foldl
%%        (
%%            fun
%%                ({I,_P,_Cm, _Min1, _Max1}, Acc) ->
%%                    case lists:keyfind(I, 1, Acc) of
%%                        false ->
%%                            List1 =
%%                                lists:filter
%%                                (
%%                                    fun
%%                                        ({I1,_C1,_P1, _Min2, _Max2}) -> I =:= I1;
%%                                        ({I1,_C1,_P1}) -> I =:= I1
%%                                    end,
%%                                    AttrList
%%                                ),
%%                            [AttrTuple] = com_util:rand_more(List1, 1),
%%                            [AttrTuple|Acc];
%%                        _ ->
%%                            Acc
%%                    end;
%%                ({I,_P,_Cm}, Acc) ->
%%                    case lists:keyfind(I, 1, Acc) of
%%                        false ->
%%                            List1 =
%%                                lists:filter
%%                                (
%%                                    fun
%%                                        ({I1,_C1,_P1}) -> I =:= I1;
%%                                        ({I1,_C1,_P1,_Min3,_Max3}) -> I =:= I1
%%                                    end,
%%                                    AttrList
%%                                ),
%%                            [AttrTuple] = com_util:rand_more(List1, 1),
%%                            [AttrTuple|Acc];
%%                        _ ->
%%                            Acc
%%                    end
%%            end,
%%            [],
%%            AttrList
%%        ),
%%    AttrList1.

%% 第一次合成选择属性中值最小的
%%do_first_he_cheng_attr(JDList, Len) ->
%%    List =
%%        lists:sort
%%        (
%%            fun
%%                ({_A1,A2,_A3,_Min1,_Max1},{_B1,B2,_B3,_Min2,_Max2}) ->
%%                    A2 < B2;
%%                ({_A1,A2,_A3},{_B1,B2,_B3}) ->
%%                    A2 < B2
%%            end,
%%            JDList
%%        ),
%%    lists:sublist(List, Len).
%%
%%%% 第二次合成选择属性中值最大的
%%do_second_he_cheng_attr(JDList, Len) ->
%%    List =
%%        lists:sort
%%        (
%%            fun
%%                ({_A1,A2,_A3,_Min1,_Max1},{_B1,B2,_B3,_Min2,_Max2}) ->
%%                    A2 > B2;
%%                ({_A1,A2,_A3},{_B1,B2,_B3}) ->
%%                    A2 > B2
%%            end,
%%            JDList
%%        ),
%%    lists:sublist(List, Len).


