%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 20. 七月 2015 下午3:15
%%%-------------------------------------------------------------------

-module(item_equip).

-export([
    build/2                             %% 生成装备
    , is_equip_type/1                    %% 是否装备类型
    , can_take_on/2                      %% 是否装戴
    , take_on/1                          %% 装戴
    , take_off/1                         %% 脱下
    , get_gem_empty_pos/2                %%
    , can_take_on_gem/3                  %% 装戴宝石
    , take_on_gem/3                      %% 装戴宝石
    , can_take_off_gem/2                 %% 脱下宝石
    , take_off_gem/2                     %% 脱下宝石
    , can_set_strength_lvl/2             %% 是否设置强化等级
    , set_strength_lvl/2                 %% 设置强化等级
    , get_authenticate_cost_list/1       %% 鉴定开销
    , authenticate/1                     %% 鉴定
    , can_authenticate/1                 %% 能否鉴定
    , restore_take_on/1                  %% 重置数据
    , get_sink_info/2                    %% 获得槽信息
    , get_gem_total_size/1               %% 获得宝石总数
    , get_authenticate_attr_list/1       %% 获得鉴定属性列表
    , get_gem_cur_size/1
    , change_jd_attr/2
    , change_gem_tuple/2
    , get_gem_by_pos/2
    , update_equip_eft/1                %% 刷新装备特效
    , get_equip_skills/1
    , get_equip_all_gem_num/1           %% 获得装备镶嵌的所有宝石总数
    , get_gem_tuple/1                   %% 获取宝石元组
    , get_equip_pos/1
    , change_fumo_attr/2
    , change_buf_list/2
    , get_fumo_attr_list/1
    , update_attr_do_epic_gem/2
    , is_has_gem_in_epic_slot/1         %% 史诗宝石孔里是否有宝石
    , can_be_exchange_epic_slot/1
    , update_part_qianghua_effect/0
    , get_jd_qly/2
]).




-include("inc.hrl").
-include("item.hrl").
-include("load_item.hrl").
-include("item_new.hrl").
-include("player.hrl").
-include("load_equip_expand.hrl").
-include("equip.hrl").
-include("load_spirit_attr.hrl").


-define(weapon_type, 110).       %% 装备的武器类型





update_equip_eft(#item_new{bid = Bid} = Item) ->
    IsTake = item_new:get_field(Item, ?item_equip_take_state),
    case IsTake of
        0 ->
            List = attr_new:get(?pd_temp_equip_efts, []),
            List1 = lists:keydelete(Bid,1, List),
            attr_new:set(?pd_temp_equip_efts, List1);
        _ ->
            ItemList = [],
            QHLvl = item_new:get_field(Item, ?item_equip_qianghua_lev, 0),
            ItemList1 =
                case load_equip_expand:get_equip_qh_eftid(Bid, QHLvl) of
                    ?none -> ItemList;
                    ID1 ->
                        case load_equip_expand:get_equip_cfg_type(Bid) =:= ?weapon_type of
%%                            true -> [ID1|ItemList];
                            true -> ID1 ++ ItemList;
                            _ -> ItemList
                        end
                end,
            {GemTopLvl, SizeOfGemTopLvl} = get_gem_top_data(Item),
            ItemList2 =
                case load_equip_expand:get_equip_gem_eftid(Bid, GemTopLvl, SizeOfGemTopLvl) of
                    ?none -> ItemList1;
                    ID2 ->
                        case load_equip_expand:get_equip_cfg_type(Bid) =:= ?weapon_type of
                            true -> [ID2|ItemList1];
                            _ -> ItemList1
                        end
                end,
            List = attr_new:get(?pd_temp_equip_efts, []),
            List1 = lists:keystore(Bid,1, List, {Bid,ItemList2}),
%%             ?INFO_LOG("Efts ~p", [List1]),
            attr_new:set(?pd_temp_equip_efts, List1)
    end,
    equip_system:sync_equip_efts(),
    ok.

%% 升级部位强化特效
update_part_qianghua_effect() ->
    %% 添加部位强化等级特效
    PartQHList = get(?pd_part_qiang_hua_list),
%%    ?INFO_LOG("PartQHList = ~p", [PartQHList]),
    PartType = ?weapon_type - 100,
    WeaponLevel = util:get_field(PartQHList, PartType, 0),
%%    ?INFO_LOG("WeaponLevel = ~p role = ~p", [WeaponLevel, get(?pd_career)]),
    case load_equip_expand:get_part_qianghua_effect(get(?pd_career), PartType, WeaponLevel) of
        EffectQHList when is_list(EffectQHList) ->
            attr_new:set(?pd_part_qiang_hua_effect, EffectQHList),
            equip_system:sync_equip_efts();
        _ ->
            pass
    end.


get_gem_top_data(Item) ->
    GemTuple = item_new:get_field(Item, ?item_equip_igem_slot, 0),
    List = tuple_to_list(GemTuple),
    lists:foldl
    (
        fun( Bid, {CurLvL, CurNum}) ->
            UseLvl = load_item:get_use_lev(Bid),
            if
                UseLvl > CurLvL andalso is_integer(UseLvl) ->
                    {UseLvl, 1};
                UseLvl == CurLvL andalso is_integer(UseLvl) ->
                    {UseLvl, CurNum+1};
                true ->
                    {CurLvL, CurNum}
            end
        end,
        {0, 0},
        List
    ).

get_equip_skills(#item_new{} = Item) ->
    item_new:get_field(Item, ?item_equip_buf_list, []).


%% 生成装备
build(Bid, _BuildParList) ->
%%    ?INFO_LOG("Bid = ~p", [Bid]),
    Item = item_new:build(Bid, 1),
    case Item of
        {error, Error} -> {error, Error};
        _ ->
            RandAttr =
                case attr_new:get_room_prize() of
                    0 -> load_equip_expand:create_equip_rand_attr(Bid);
                    PrizeId -> load_equip_expand:create_room_equip_rand_attr(PrizeId, Bid)
                end,
            RandBuf =
                case attr_new:get_room_prize() of
                    0 -> load_equip_expand:create_equip_rand_buf_attr(Bid);
                    PrizeId1 -> load_equip_expand:create_room_equip_rand_buf_attr(PrizeId1, Bid)
                end,
            case {RandAttr, RandBuf} of
                {
                    #equip_rand_attr_ret
                    {
                        suit_id = SuitId,
                        gem_slots_tuple = GemTuple,
                        is_jd = EquipIsJd,
                        jd_attr = JdAttrAndPerL,
                        base_attr = BaseAttrId,
                        quality = Qly
                    },
                    BufList
                } ->
                    BAttr = attr_new:get_attr_by_id(BaseAttrId),

                    %% 设置装备的附魔属性
                    FumoId = load_equip_expand:get_equip_fumo_jd_id(Bid),
%%                    ?INFO_LOG("FumoId = ~p", [FumoId]),
                    %% 获取所有的附魔需要添加的属性的信息
                    FumoAttrList = load_equip_expand:get_equip_fumo_cfg_attr_list(FumoId),
                    %% 从附魔全部属性的列表中获取buffId
                    BufFumoList = load_equip_expand:filter_fumo_list_buff(FumoAttrList),
                    %% 从附魔的全部属性列表中获取属性修改千分比
%%                    MillList = [{AttrId, Rat} || {Type, AttrId, Rat} <- FumoAttrList, Type =:= ?equip_fumo_cfg_type_per_mill],
%%                    BAttr1 = load_equip_expand:change_jc_attr_fumo(BAttr, MillList),
%%                    JdAttrAndPerL1 = load_equip_expand:change_jd_attr_fumo(JdAttrAndPerL, MillList),

%%                    FumoListPer = [{AttrId,AttrVal,100} || {FumoType, AttrId, AttrVal} <- FumoAttrList, FumoType =:= ?equip_fumo_cfg_type_min_max],
%%                    ?INFO_LOG("JdAttrAndPerL = ~p", [JdAttrAndPerL]),
                    ExtraAttrL = [{?EQM_ATTR_JD, JdAttrAndPerL}],
%%                    ExtraAttrL1 = [{?EQM_ATTR_JD, JdAttrAndPerL ++ FumoListPer}],  %% 把装备的附魔属性添加到鉴定属性中一起参与战斗力的计算
%%                    Qly = get_jd_qly(length(JdAttrAndPerL), SuitId),
                    BufList1 = BufList ++ BufFumoList,
                    Power = get_equip_init_power(BAttr, ExtraAttrL, FumoAttrList),

                    ExtraAttrFM = [{?EQM_ATTR_FM, FumoAttrList}],

                    %% 判断装备是否时套装
                    case load_equip_expand:is_suit_by_bid(Bid) of
                        true ->
                            put(?pd_is_build_suit, 1);
                        _ ->
                            pass
                    end,

                    DefaultKeyVal =
                        [
                            {?item_equip_quality, Qly},
                            {?item_equip_is_jd, EquipIsJd},
                            {?item_equip_suit_id, SuitId},
                            {?item_equip_qianghua_lev, 0},
                            {?item_equip_power, Power},
                            {?item_equip_igem_slot, GemTuple},
                            {?item_equip_base_prop, BAttr},
                            {?item_equip_extra_prop_list, ExtraAttrL},
                            {?item_equip_take_state, 0},
                            {?item_equip_attr_state, 0},
                            {?item_equip_qh_prop_id, 0},
                            {?item_equip_extra_qh_prop_id, 0},
                            {?item_equip_buf_list, BufList1},
                            {?item_equip_fumo_mode_message, FumoId},
                            {?item_equip_fumo_attr_list, ExtraAttrFM},
                            {?item_use_data, [
                                {?item_equip_epic_gem_slot, 0},
                                {?item_equip_epic_gem, 0},
                                {?item_equip_epic_gem_exp, 0}
                            ]}
                        ],
                    item_new:set_fields(Item, DefaultKeyVal);
                Other ->
                    Other
            end
    end.


%% 获得装备放于背包槽时的槽位信息
get_sink_info(Item, Pos) ->
    ItemType = item_new:get_type(Item),
    case is_equip_type(ItemType) of
        ?true ->
            Bid = item_new:get_bid(Item),
            Cfg = load_item:get_item_cfg(Bid),
            EquipIsJd = item_new:get_field(Item, ?item_equip_is_jd),
            SuitId = item_new:get_field(Item, ?item_equip_suit_id),
            QhLvL = item_new:get_field(Item, ?item_equip_qianghua_lev),
            Power = item_new:get_field(Item, ?item_equip_power),
            FumoId = item_new:get_field(Item, ?item_equip_fumo_mode_message, 0),
            FumoAttrList = item_equip:get_fumo_attr_list(Item),
            UseData = item_new:get_field(Item, ?item_use_data, []), %% UseData = [{Key,Val}|TailList]

            {ExtraAttrL, Qly} =
                if
                    EquipIsJd =/= 1 ->
                        {[], 1};
                    true ->
                        TempExtraAttrL = item_new:get_field(Item, ?item_equip_extra_prop_list),
                        Qly1 = item_new:get_field(Item, ?item_equip_quality, Cfg#item_attr_cfg.quality),
                        {TempExtraAttrL, Qly1}
                end,
            GemTuple = item_new:get_field(Item, ?item_equip_igem_slot),
            GemList = tuple_to_list(GemTuple),
            BufL =
                if
                    EquipIsJd =/= 1 -> [];
                    true ->
                        TempBufL = item_new:get_field(Item, ?item_equip_buf_list, []),
                        TempBufL
                end,


            %% 装备的扩展属性
            %% 计算装备的属性范围列表
            AttrCfgList = load_equip_expand:get_equip_output_new_cfg_jd_attr(Item#item_new.bid),
            AttrCfgList1 =
                lists:foldl
                (
                    fun({T1, _}, Acc) ->
                        [T1 | Acc]
                    end,
                    [],
                    AttrCfgList
                ),
            ExtraAttrL1 =
                lists:map
                (
                    fun
                        ({AttrId, AttrVal, Per}) ->
                            {Min, Max} =
                                case lists:keyfind(AttrId, 1, AttrCfgList1) of
                                    {_,_,Min1,Max1} ->
                                        {Min1, Max1};
                                    _ ->
                                        {1, AttrVal}
                                end,
                            {AttrId, AttrVal, Per, Min, Max};
                        (AttrTuple) ->
                            AttrTuple
                    end,
                    exAttrList_2_AttrList(ExtraAttrL)
                ),

            ExtraAttrL2 =
                [{?EQM_ATTR_JD, [{AttrId, AttrVal, Per} || {AttrId,AttrVal,Per,_Min1,_Max1} <- ExtraAttrL1]}],

            {MinAttrList, MaxAttrList} =
                lists:foldr
                (
                    fun({_AId, _AVal, _Aper, AMin, AMax}, {AccList1, AccList2}) ->
                        {[AMin | AccList1], [AMax | AccList2]}
                    end,
                    {[], []},
                    ExtraAttrL1
                ),

%%            ?INFO_LOG("FumoId = ~p", [FumoId]),
            ItemInfo =
                {
                    Item#item_new.id,               %% 物品id
                    Item#item_new.bid,              %% 物品bid
                    Pos,                            %% 物品位置
                    Qly,                            %% 物品品质
                    Item#item_new.quantity,         %% 物品数量
                    Item#item_new.bind,             %% 物品绑定状态 0非绑 1绑定
                    EquipIsJd,                      %% 是否鉴定
                    SuitId,                         %% 套装id
                    QhLvL,                          %% 强化等级
                    Power,                          %% 装备评分
                    ExtraAttrL2,                    %% 扩展属性
                    GemList,                        %% 宝石属性
                    UseData,                             %% 物品属性
                    BufL,
                    MaxAttrList,
                    MinAttrList,
                    FumoId,
                    FumoAttrList                    %% 附魔属性列表
                },
%%            ?INFO_LOG("+++++++++++++++++++++++++++++++++++++++++++++++"),
%%            ?INFO_LOG("FumoId = ~p FumoAttrList = ~p", [FumoId, FumoAttrList]),
            ItemInfo;
        ?false ->
            goods_bucket:get_sink_info(Item, 0)
    end.


exAttrList_2_AttrList(ExAttrList) ->
    case lists:keyfind(?EQM_ATTR_JD, 1, ExAttrList) of
        {_Mod, AttrList} ->
            AttrList;
        _ ->
            []
    end.


%% 是否装备类型
is_equip_type(Type) -> lists:member(Type, ?ITEM_TYPE_EQM_ALL).


get_equip_pos(Item) ->
    Type = item_new:get_type(Item),
    Pos = Type div 100,
    Pos.


%% 能否装戴
can_take_on(Item, ToPos) ->
    case item_new:get_main_type(Item) of
        ?val_item_main_type_equip ->
            Type = item_new:get_type(Item),
            RightPos = ToPos + 100, %% 类型值正好对应位置值*100
%%             ?INFO_LOG("can_take_on ~p",[{Type, RightPos}]),
            if
                Type == RightPos ->
                    IsJD = item_new:get_field(Item, ?item_equip_is_jd),
                    if
                        IsJD == 1 -> ret:ok();
                        true -> ret:error(not_jd)
                    end;

                true ->
                    ret:error(error_pos)
            end;
        _ -> ret:error(unknown_type)
    end.

%% 装戴
take_on(Item) ->
    NewItem = item_new:set_field(Item, ?item_equip_take_state, 1),
    ItemFinal = case load_item:get_is_bind(NewItem#item_new.bid) of
        1 ->
            NewItem#item_new{bind = 1};
        _ ->
            NewItem
    end,
    try_add_equip_attr(ItemFinal).

%% 脱下
take_off(Item) ->
    NewItem = item_new:set_field(Item, ?item_equip_take_state, 0),
    try_sub_equip_attr(NewItem).

%% 恢复穿载情况
restore_take_on(Item) ->
    IsTake = item_new:get_field(Item, ?item_equip_take_state),
    if
        IsTake == 1 ->
            Attr = get_cur_equip_attr(Item),
            Power = attr_new:get_combat_power(Attr),
            item_new:set_field(Item, ?item_equip_power, Power),
            attr_new:player_add_attr(Attr),
            update_equip_eft(Item),
            BufIdList = item_new:get_field(Item, ?item_equip_buf_list, []),
            lists:foreach
            (
                fun
                    (BufId) -> equip_buf:take_on_buf(BufId)
                end,
                BufIdList
            ),
            attr_new:update_player_attr(),
            ok;
        true ->
            %%没穿在身上的装备也要更新战斗力
            Attr = get_cur_equip_attr(Item),
            Power = attr_new:get_combat_power(Attr),
            item_new:set_field(Item, ?item_equip_power, Power),
            ok
    end.


%% 装戴宝石(获取装备空位置)
get_gem_empty_pos(Item, DefaultPos) ->
    FindEmptyPos =
        fun
            (_ThisFun, _GemTuple, _M, _M) -> ret:error(no_empty);
            (ThisFun, GemTuple, I, M) ->
                CurGem = element(I, GemTuple),
                if
                    CurGem == 0 -> I;
                    true -> ThisFun(ThisFun, GemTuple, I + 1, M)
                end
        end,
    GemTuple = item_new:get_field(Item, ?item_equip_igem_slot),
    Num = tuple_size(GemTuple),
    case FindEmptyPos(FindEmptyPos, GemTuple, 1, Num + 1) of
        {error, _} ->
            if
                Num >= DefaultPos -> DefaultPos;
                true -> ret:error(no_empty)
            end;
        EmptyPos -> EmptyPos
    end.
get_gem_by_pos(Item, Pos) ->
    GemTuple = item_new:get_field(Item, ?item_equip_igem_slot),
    Num = tuple_size(GemTuple),
    if
        Pos =< Num -> element(Pos, GemTuple);
        true -> 0
    end.



can_take_on_gem(Item, ToPos, Goods) ->
    CurType = item_new:get_type(Goods),
    case CurType of
        ?val_item_type_gem ->
            GemTuple = item_new:get_field(Item, ?item_equip_igem_slot),
            Num = tuple_size(GemTuple),
            if
                ToPos =< 0 -> ret:error(error_pos);
                ToPos > Num -> ret:error(error_pos);
                true ->
                    CurGem = element(ToPos, GemTuple),
                    if
                        CurGem =/= 0 -> ret:error(has_gem);
                        true -> ret:ok()
                    end
            end;
        {error, Error} -> {error, Error};
        _ -> ret:error(unknown_type)
    end.
take_on_gem(Item, ToPos, Goods) ->
    OrgAttrItem = try_sub_equip_attr(Item),
    NewItem = do_take_on_gem(OrgAttrItem, ToPos, Goods),
    try_add_equip_attr(NewItem).

update_attr_do_epic_gem(Item, DefaultKeyVal) ->
    OrgAttrItem = try_sub_equip_attr(Item),
    NewItem = item_new:set_fields(OrgAttrItem, DefaultKeyVal),
    try_add_equip_attr(NewItem).


%% 脱下宝石
can_take_off_gem(Item, FromPos) ->
    GemTuple = item_new:get_field(Item, ?item_equip_igem_slot),
    Num = tuple_size(GemTuple),
    if
        FromPos =< 0 -> ret:error(error_pos);
        FromPos > Num -> ret:error(error_pos);
        true ->
            CurGem = element(FromPos, GemTuple),
            if
                CurGem == 0 -> ret:error(no_gem);
                true -> ret:ok(CurGem)
            end
    end.
take_off_gem(Item, FromPos) ->
    OrgAttrItem = try_sub_equip_attr(Item),
    {NewItem, Bid} = do_take_off_gem(OrgAttrItem, FromPos),
    NewItem1 = try_add_equip_attr(NewItem),
    {NewItem1, Bid}.

%% 设置强化等级
%% 装备强化等级上线 Level 装备自身等级
get_qh_lvl(Level) when Level < 10 -> 10;
get_qh_lvl(Level) -> 10 + 5 * (Level div 10 - 1).
can_set_strength_lvl(Item = #item_new{bid = Bid}, LvL) ->
    case load_item:can_qh(Bid) of
        {error, Error} -> {error, Error};
        _ ->
            UseLvl = load_item:get_use_lev(Bid),
            LimitLvL = get_qh_lvl(UseLvl),
            if
            %% 强化达到最大等级
                LimitLvL >= LvL ->
                    %% 未鉴定装备
                    IsJD = item_new:get_field(Item, ?item_equip_is_jd),
                    if
                        IsJD =/= 0 -> ret:ok();
                        true -> ret:error(not_jiand_ding)
                    end;
                true -> ret:error(max_qiang_hua)
            end
    end.

set_strength_lvl(Item, LvL) ->
    OrgAttrItem = try_sub_equip_attr(Item),
    NewItem = do_set_strength_lvl(OrgAttrItem, LvL),
    try_add_equip_attr(NewItem).

%% 能否鉴定
can_authenticate(Item) ->
    MainType = item_new:get_main_type(Item),
    case MainType of
        ?val_item_main_type_equip ->
            IsJD = item_new:get_field(Item, ?item_equip_is_jd),
            if
                IsJD =/= 0 -> ret:error(already_jd);
                true -> ret:ok()
            end;
        _ -> ret:error(unknown_type)
    end.

%% 鉴定开销
get_authenticate_cost_list(Item) ->
    case Item of
        #item_new{} ->
            Qly = item_new:get_field(Item, ?item_equip_quality),
            load_equip_expand:get_jianding_money(Qly);
        _ -> ret:error(unknown_type)
    end.

%% 鉴定
authenticate(Item) ->
    OrgAttrItem = try_sub_equip_attr(Item),
    NewItem = do_authenticate(OrgAttrItem),
    try_add_equip_attr(NewItem).

%% 鉴定
get_authenticate_attr_list(Item) ->
    case Item of
        #item_new{} ->
            AttrList = item_new:get_field(Item, ?item_equip_extra_prop_list),
            case lists:keyfind(?EQM_ATTR_JD, 1, AttrList) of
                false -> [];
                PropTuple -> element(2, PropTuple) %%[{Key, Val, Per, Min, Max}]
            end;
        _ -> ret:error(unknown_type)
    end.

%% 获取附魔列表
get_fumo_attr_list(Item) ->
    case Item of
        #item_new{} ->
            AttrList = item_new:get_field(Item, ?item_equip_fumo_attr_list, []),
            case lists:keyfind(?EQM_ATTR_FM, 1, AttrList) of
                false -> 
                    [];
                PropTuple -> 
                    element(2, PropTuple) %%[{Key, Val, Per}]
            end;
        _ -> 
            %ret:error(unknown_type),
            []
    end.


%% 重算属性属性到达最大属性的百分比
%% is_top_level_equ(UnknownList) ->
%%     ?INFO_LOG("is_top_level_equ").

%% 获取套装属性信息
%% get_eqm_suit() ->
%%     ?INFO_LOG("get_eqm_suit").
%%
%% is_equ_all_suit([]) ->
%%     ?INFO_LOG("is_equ_all_suit").

change_jd_attr(Item, AttrList) ->
    OrgAttrItem = try_sub_equip_attr(Item),
    ExtraAttrL = [{?EQM_ATTR_JD, AttrList}],
    NewItem = item_new:set_field(OrgAttrItem, ?item_equip_extra_prop_list, ExtraAttrL),
    try_add_equip_attr(NewItem).

change_gem_tuple(Item, GemTuple) ->
    OrgAttrItem = try_sub_equip_attr(Item),
    NewItem = item_new:set_field(OrgAttrItem, ?item_equip_igem_slot, GemTuple),
    try_add_equip_attr(NewItem).

change_fumo_attr(Item, AttrList) ->
    OrgAttrItem = try_sub_equip_attr(Item),
    ExtraAttrL = [{?EQM_ATTR_FM, AttrList}],
    NewItem = item_new:set_field(OrgAttrItem, ?item_equip_fumo_attr_list, ExtraAttrL),
    try_add_equip_attr(NewItem).

change_buf_list(Item, BufList) ->
    OrgAttrItem = try_sub_equip_attr(Item),
    NewItem = item_new:set_field(OrgAttrItem, ?item_equip_buf_list, BufList),
    try_add_equip_attr(NewItem).


%% -----------------------------
%% private
%% -----------------------------
%% 配戴装备属性
try_add_equip_attr(Item) ->
    %% 刷新装备属性
    Old_Attr = get_cur_equip_attr(Item),
    Attr = attr_new:get_oldversion_equip_attr(Old_Attr),
    Power = attr_new:get_combat_power(Attr),
    %?INFO_LOG("add equip_power = ~p", [Power]),
    RetItem = item_new:set_field(Item, ?item_equip_power, Power),
    %% 刷新人物属性
    IsTake = item_new:get_field(Item, ?item_equip_take_state),
    AttrState = item_new:get_field(Item, ?item_equip_attr_state),
    if
        IsTake == 1 ->
            update_equip_eft(RetItem);
        true ->
            ok
    end,
    if
        IsTake == 1 andalso AttrState == 0 ->
            attr_new:player_add_attr(Old_Attr),%%这里加的是没转换的原始属性
            attr_new:update_player_attr(),
            BufIdList = item_new:get_field(RetItem, ?item_equip_buf_list, []),
            lists:foreach
            (
                fun
                    (BufId) -> equip_buf:take_on_buf(BufId)
                end,
                BufIdList
            ),
            RetItem1 = item_new:set_field(RetItem, ?item_equip_attr_state, 1),
            %add_suit_equip_attr(Item),
            RetItem1;
        true ->
            RetItem
    end.

%% 去掉装备属性
try_sub_equip_attr(Item) ->
    %% 刷新装备属性
    Old_Attr = get_cur_equip_attr(Item),
    Attr = attr_new:get_oldversion_equip_attr(Old_Attr),
    %%Attr = get_cur_equip_attr(Item),
    Power = attr_new:get_combat_power(Attr),
%%    ?INFO_LOG("sub equip_power = ~p", [Power]),
    RetItem = item_new:set_field(Item, ?item_equip_power, Power),
    %% 刷新人物属性
    AttrState = item_new:get_field(Item, ?item_equip_attr_state),
    if
        AttrState == 1 ->
            attr_new:player_sub_attr(Old_Attr),%%这里减的是没转换的原始属性
            attr_new:update_player_attr(),
            RetItem1 = item_new:set_field(RetItem, ?item_equip_attr_state, 0),
            BufIdList = item_new:get_field(RetItem, ?item_equip_buf_list, []),
            lists:foreach
            (
                fun
                    (BufId) -> equip_buf:take_off_buf(BufId)
                end,
                BufIdList
            ),
            update_equip_eft(RetItem1),
%%            sub_suit_equip_attr(Item),
            RetItem1;
        true ->
            RetItem
    end.

%% add套装属性
%%add_suit_equip_attr(Item) ->
%%    SuitId = item_new:get_field(Item, ?item_equip_suit_id),
%%    if
%%        SuitId == 0 -> false;
%%        true ->
%%            %%获取身上Item套装属性
%%            SuitList = api:get_suit_equip_list_by_id(api:get_suit_equip_list(),SuitId),
%%            SuitEquipInfos = api:get_suit_equip_infos(SuitList),
%%%%             ?INFO_LOG("add---SuitEquipInfos,       ~p", [SuitEquipInfos]),
%%            {Id, Lv, Count} = SuitEquipInfos,
%%            SuitCount = if
%%                            Count+1 >= 6 -> 6;
%%                            Count+1 >= 4 -> 4;
%%                            Count+1 >= 2 -> 2;
%%                            true -> 0
%%                        end,
%%            #item_attr_cfg{lev = CurrLv} = load_item:get_item_cfg(Item#item_new.bid),%%bid获取装备的套装等级Lv
%%            SuitLv = api:getMax(Lv,CurrLv),
%%            SuitEquipInfo = {Id, SuitLv, SuitCount},
%%%%             ?INFO_LOG("add---SuitEquipInfos,       ~p", [SuitEquipInfo]),
%%            SuitAttrId = load_equip_expand:get_equip_suit_attrId(SuitEquipInfo),
%%
%%            SuidAttrList = attr_new:get(?pd_suid_attr_list,[]),
%%            SuidTuple = lists:keyfind(SuitId,1,SuidAttrList),
%%            if
%%                SuidTuple == false ->
%%                    case SuitAttrId of
%%                        ?none -> ?none;
%%                        _ ->
%%                            %%erlang:set(?pd_suid_attr_list, [{SuitId, SuitAttrId} | SuidAttrList]),
%%                            attr_new:set(?pd_suid_attr_list, [{SuitId, SuitAttrId} | SuidAttrList]),
%%                            attr_new:player_add_attr_by_id(SuitAttrId)
%%                    end;
%%
%%                true ->
%%                    case SuitAttrId of
%%                        ?none -> ?none;
%%                        _ ->
%%                            {_,SuitAttrIdTemp} = SuidTuple,
%%                            lists:delete(SuidTuple,SuidAttrList),
%%                            attr_new:player_sub_attr_by_id(SuitAttrIdTemp),
%%                            %%erlang:set(?pd_suid_attr_list, [{SuitId, SuitAttrId} | SuidAttrList]),
%%                            attr_new:set(?pd_suid_attr_list, [{SuitId, SuitAttrId} | SuidAttrList]),
%%                            %%添加套装属性到角色身上
%%                            attr_new:player_add_attr_by_id(SuitAttrId)
%%                    end
%%            end
%%
%%    end.
%%%% sub套装属性
%%sub_suit_equip_attr(Item) ->
%%    SuitId = item_new:get_field(Item, ?item_equip_suit_id),
%%    if
%%        SuitId == 0 -> false;
%%        true ->
%%            %%获取身上Item套装属性
%%            SuitList = api:get_suit_equip_list_by_id(api:get_suit_equip_list(),SuitId),
%%            SuitEquipInfos = api:get_suit_equip_infos(SuitList),
%%%%             ?INFO_LOG("sub---SuitEquipInfos,       ~p", [SuitEquipInfos]),
%%            {Id, Lv, Count} = SuitEquipInfos,
%%            SuitCount = if
%%                            Count-1 >= 6 -> 6;
%%                            Count-1 >= 4 -> 4;
%%                            Count-1 >= 2 -> 2;
%%                            true -> 0
%%                        end,
%%            #item_attr_cfg{lev = CurrLv} = load_item:get_item_cfg(Item#item_new.bid),%%bid获取装备的套装等级Lv
%%            SuitLv = api:getMin(Lv,CurrLv),
%%            SuitEquipInfo = {Id, SuitLv, SuitCount},
%%%%             ?INFO_LOG("sub---SuitEquipInfos,       ~p", [SuitEquipInfo]),
%%            SuitAttrId = load_equip_expand:get_equip_suit_attrId(SuitEquipInfo),
%%
%%            SuidAttrList = attr_new:get(?pd_suid_attr_list,[]),
%%            SuidTuple = lists:keyfind(SuitId,1,SuidAttrList),
%%            %%1.首先判断有没有套装属性加成
%%            if
%%                %%没有
%%                SuidTuple == false ->
%%                    case SuitAttrId of
%%                        ?none -> ?none;
%%                        _ ->
%%                        %%erlang:set(?pd_suid_attr_list, [{SuitId, SuitAttrId} | SuidAttrList]),
%%                        attr_new:set(?pd_suid_attr_list, [{SuitId, SuitAttrId} | SuidAttrList]),
%%                        attr_new:player_add_attr_by_id(SuitAttrId)
%%                    end;
%%                true ->
%%                    {_,SuitAttrIdTemp} = SuidTuple,
%%                    lists:delete(SuidTuple,SuidAttrList),
%%                    attr_new:player_sub_attr_by_id(SuitAttrIdTemp),
%%                    case SuitAttrId of
%%                        ?none -> ?none;
%%                        _ ->
%%                        SuidAttrList = erlang:get(?pd_suid_attr_list),
%%                        %%erlang:set(?pd_suid_attr_list, [{SuitId, SuitAttrId} | SuidAttrList]),
%%                        attr_new:set(?pd_suid_attr_list, [{SuitId, SuitAttrId} | SuidAttrList]),
%%                        %%添加套装属性到角色身上
%%                        attr_new:player_add_attr_by_id(SuitAttrId)
%%                    end
%%            end
%%
%%    end.


get_exattrL([]) -> [];
get_exattrL([{_ModID, KeyValPerList} | TailList]) ->
    AttrList =
        lists:foldl(
            fun
                ({Key, Val, _Per}, Acc) ->
                    [{Key, Val} | Acc];
                ({Key, Val, _Per, _Min, _Max}, Acc) ->
                    [{Key, Val} | Acc]
            end,
            [],
            KeyValPerList),
    ExtraAttr = attr_new:list_2_attr(AttrList),
    [ExtraAttr | get_exattrL(TailList)].

get_fumo_exattr(FumoAttrList) ->
    AttrList = [{AttrId, AttrVal} || {Type, AttrId, AttrVal} <- FumoAttrList, Type =:= ?equip_fumo_cfg_type_min_max],
    Attr = attr_new:list_2_attr(AttrList),
    Attr.

get_fumo_pre(FumoAttrList) ->
    [{AttrId, AttrPre} || {Type, AttrId, AttrPre} <- FumoAttrList, Type =:= ?equip_fumo_cfg_type_per_mill].

%% 获得当前装备的附加属性
get_equip_attr(BaseAttr, ExtraAttrParL, FumoAttrList, EpicGemAttr, GemAttr, QHAttr) ->
    %% 扩展属性
    ExtraAttrL = get_exattrL(ExtraAttrParL),
    % ?DEBUG_LOG("ExtraAttrL:~p", [ExtraAttrL]),
    %% 增加宝石属性
    ExtraAttr_Gem_L = [GemAttr | ExtraAttrL],
    % ?DEBUG_LOG("ExtraAttr_Gem_L:~p", [ExtraAttr_Gem_L]),
    %% 强化属性
    ExtraAttr_QH_L = [QHAttr | ExtraAttr_Gem_L],
    % ?DEBUG_LOG("ExtraAttr_QH_L:~p", [ExtraAttr_QH_L]),
    %% 史诗宝石属性
    ExtraAttr_EpicGem_L = [EpicGemAttr | ExtraAttr_QH_L],
    % ?DEBUG_LOG("ExtraAttr_EpicGem_L:~p", [ExtraAttr_EpicGem_L]),
    %% 附魔属性
    FumoAttr = get_fumo_exattr(FumoAttrList),
    ExtraAttr_EpicGem_L_Fumo = [FumoAttr | ExtraAttr_EpicGem_L],
    % ?DEBUG_LOG("BaseAttr:~p, ExtraAttr_EpicGem_L_Fumo:~p", [BaseAttr, ExtraAttr_EpicGem_L_Fumo]),
    %% 总属性
    SumAttr =
        lists:foldl(
            fun(Attr, Acc) ->
                attr_algorithm:add(Acc, Attr)
            end,
            BaseAttr,
            ExtraAttr_EpicGem_L_Fumo),
    %% 修正
    Ret = attr_new:amend(SumAttr),
%%     ?INFO_LOG("start get_cur_equip_attr -------------  "),
%%     attr_new:show_attr(Ret),
%%     ?INFO_LOG("end get_cur_equip_attr -------------  "),
    Ret1 = attr_new:list_2_attr_pre(Ret, get_fumo_pre(FumoAttrList)),   %% 通过附魔的千分比属性来计算装备已有的属性
    Ret1.

get_cur_equip_attr(Item) ->
    %% 属性
    BaseAttr = item_new:get_field(Item, ?item_equip_base_prop, #attr{}),
    %% 扩展属性
    ExtraAttrParL = item_new:get_field(Item, ?item_equip_extra_prop_list, []),
    %% 增加宝石属性
    GemAttr = get_gem_attr(Item),
    %% 史诗宝石属性
    EpicGemAttr = get_epic_gem_attr(Item),
    %% 附魔属性
    FumoAttrList = item_equip:get_fumo_attr_list(Item),
%%    FumoAttrList1 = load_equip_expand:fumo_save_list_to_attr_list(FumoAttrList),
%%    FumoAttrList2 = [{AttrId, AttrVal, 100} || {AttrId, AttrVal} <- FumoAttrList1],
    ExtraAttrParL2 =
        case ExtraAttrParL of
            [] -> [];
            _ ->
                case lists:keyfind(?EQM_ATTR_JD, 1, ExtraAttrParL) of
                    false -> [];
                    {Ex,List} ->
                        lists:keyreplace(?EQM_ATTR_JD, 1, ExtraAttrParL, {Ex, List});
                    _ ->
                        ExtraAttrParL
                end
        end,
    %% 强化属性
    QHLvl = item_new:get_field(Item, ?item_equip_qianghua_lev, 0),
    QHAttr = case load_equip_expand:get_qiang_hua_attr(Item#item_new.bid, QHLvl) of
        Attr when is_record(Attr, attr) ->
            Attr;
        _ ->
            #attr{}
    end,
    get_equip_attr(BaseAttr, ExtraAttrParL2, FumoAttrList, EpicGemAttr, GemAttr, QHAttr).

%% 获得当前装备的战斗力
get_equip_init_power(BaseAttr, ExtraAttrL, FumoAttrList) ->
    Attr = get_equip_attr(BaseAttr, ExtraAttrL, FumoAttrList, #attr{}, #attr{}, #attr{}),
    New_attr = attr_new:get_oldversion_equip_attr(Attr),
    attr_new:get_combat_power(New_attr).

%% 获得鉴定值
get_jd_qly(_AttrLen, SuitId) when SuitId =/= ?EQM_NON_SUIT -> ?ITEM_QLY_GRE;
get_jd_qly(AttrLen, _SuitId) ->
    EqmQlyL = misc_cfg:get_equip_qualily(),
    EqmQlyL1 = com_lists:rkeysort(2, EqmQlyL),
    do_jd_attr_len2quality(AttrLen, EqmQlyL1).
do_jd_attr_len2quality(AttrLen, [{Qly, Len} | _T]) when AttrLen >= Len ->
    Qly;
do_jd_attr_len2quality(AttrLen, [_QltInfo | T]) ->
    do_jd_attr_len2quality(AttrLen, T).

%% 鉴定
do_authenticate(Item) ->
    item_new:set_field(Item, ?item_equip_is_jd, 1).

%% 装上宝石
do_take_on_gem(Item, ToPos, Goods) ->
    BranchKey =
        [
            #item_new.field,
            {1, ?item_equip_igem_slot, {}},
            2, %% val of key:val
            ToPos
        ],
    NewItem = util:set_branch_val(Item, BranchKey, Goods#item_new.bid),
    NewItem.

%% 脱下宝石
do_take_off_gem(Item, FromPos) ->
    BranchKey =
        [
            #item_new.field,
            {1, ?item_equip_igem_slot, {}},
            2, %% val of key:val
            FromPos
        ],
    GoodsBid = util:get_branch_val(Item, BranchKey, 0),
    NewItem = util:set_branch_val(Item, BranchKey, 0),
    {NewItem, GoodsBid}.

get_gem_total_size(Item) ->
    BranchKey =
        [
            #item_new.field,
            {1, ?item_equip_igem_slot, {}},
            2 %% val of key:val
        ],
    GoodsBidTuple = util:get_branch_val(Item, BranchKey, {}),
    tuple_size(GoodsBidTuple).

get_gem_cur_size(Item) ->
    DoCount =
        fun
            (_ThisFun, _GoodsTuple, _Max, _Max) -> 0;
            (ThisFun, GoodsTuple, I, Max) ->
                Bid = element(I, GoodsTuple),
                if
                    Bid =< 0 -> 0 + ThisFun(ThisFun, GoodsTuple, I + 1, Max);
                    true -> 1 + ThisFun(ThisFun, GoodsTuple, I + 1, Max)
                end
        end,
    BranchKey =
        [
            #item_new.field,
            {1, ?item_equip_igem_slot, {}},
            2 %% val of key:val
        ],
    GoodsBidTuple = util:get_branch_val(Item, BranchKey, {}),
    DoCount(DoCount, GoodsBidTuple, 1, tuple_size(GoodsBidTuple) + 1).

gem_attr_list(_Item, M, M) -> [];
gem_attr_list(Item, I, M) ->
    GemTuple = item_new:get_field(Item, ?item_equip_igem_slot, {}),
    GoodsBid = element(I, GemTuple),
    if
        GoodsBid > 0 ->
            Attr = load_cfg_gem:get_attr_by_bid(GoodsBid),
            [Attr | gem_attr_list(Item, I + 1, M)];
        true ->
            gem_attr_list(Item, I + 1, M)
    end.

get_gem_attr(Item) ->
    GemTuple = item_new:get_field(Item, ?item_equip_igem_slot, {}),
    Num = tuple_size(GemTuple),
    GemAttrList = gem_attr_list(Item, 1, Num + 1),
    GemAttr = attr_algorithm:sum(#attr{}, GemAttrList),
    GemAttr.

get_epic_gem_attr(Item) ->
    EpicGemBid = item_new:get_item_new_field_value_by_key(Item,?item_use_data, ?item_equip_epic_gem, 0),
    case EpicGemBid of
        0 ->
            #attr{};
        _ ->
            load_cfg_gem:get_attr_by_bid(EpicGemBid)
    end.

%% 设置强化等级
do_set_strength_lvl(Item, LvL) ->
    MinLvL = min(LvL, 55),
    MaxLvL = max(0, MinLvL),
    item_new:set_field(Item, ?item_equip_qianghua_lev, MaxLvL).

%%获得装备镶嵌的所有宝石总数
get_equip_all_gem_num(Item) ->
    BranchKey =
        [
            #item_new.field,
            {1, ?item_equip_igem_slot, {}},
            2 %% val of key:val
        ],
    GoodsBidTuple = util:get_branch_val(Item, BranchKey, {}),
    GoodsBidList = tuple_to_list(GoodsBidTuple),
    Fun =
        fun(_, []) -> [];
            (F, [H|T]) ->
                case H =/= 0 of
                    true -> [H|F(F, T)];
                    _ -> F(F, T)
                end
        end,
    GoodsBidList2 = Fun(Fun, GoodsBidList),
    erlang:length(GoodsBidList2).

%%获取宝石元组
get_gem_tuple(Item) ->
    BranchKey =
        [
            #item_new.field,
            {1, ?item_equip_igem_slot, {}},
            2 %% val of key:val
        ],
    GoodsBidTuple = util:get_branch_val(Item, BranchKey, {}),
    GoodsBidTuple.

%% 装备史诗宝石孔是否有宝石
is_has_gem_in_epic_slot(Item) ->
    case item_new:get_item_new_field_value_by_key(Item, ?item_use_data, ?item_equip_epic_gem, 0) of
        0 ->
            ?false;
        _ ->
            ?true
    end.

can_be_exchange_epic_slot(Item) ->
    case item_new:get_item_new_field_value_by_key(Item, ?item_use_data, ?item_equip_epic_gem, 0) of
        0 ->
            ?true;
        _ ->
            ?false
    end.













