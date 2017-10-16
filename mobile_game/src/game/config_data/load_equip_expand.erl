%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 24. 七月 2015 上午11:07
%%%-------------------------------------------------------------------
-module(load_equip_expand).
-author("clark").


-export([
    get_jianding_money/1                    %% 鉴定
    , create_equip_rand_attr/1
    , create_room_equip_rand_attr/2
    , get_qiang_hua_cost/2
    , get_qiang_hua_attr/2
    , get_qiang_hua_attr/3
    , can_qiang_hua_success/1
    , get_qiang_hua_failed_lvl/2
    , get_he_cheng_change_num/1
    , get_he_cheng_cost_list/2
    , create_equip_rand_buf_attr/1
    , create_room_equip_rand_buf_attr/2
    , get_equip_qh_eftid/2
    , get_equip_gem_eftid/3
    , get_ji_cheng_cost_list/2
    , get_equip_suit_attrId/1               %%获得身上套装的属性ID
    , get_equip_suit_attrId/3
    , get_ji_cheng_failed_list/2
    , get_all_equip_bid_list/0
    , get_equip_cfg_type/1
    , get_equip_cfg_level/1
    , get_equip_cfg_job/1
    , get_rand_equip/3
    , get_equip_output_new_cfg_jd_attr/1
    , get_cfg_jd_attr/1
    , is_suit_by_bid/1
]).

%% 装备提炼配置表
-export([
      get_equip_can_exchange/1                  %% 字段在equip.txt表中
    , get_equip_cfg_exchange_num_section/1
    , get_equip_cfg_exchange_quality/1
    , get_equip_cfg_enhance_level/1
    , get_cfg_exchange_cost_id/1
]).

%% 装备的附魔与萃取(key值是附魔公式id)
-export([
     get_equip_fumo_scroll_id/1
    , get_equip_fumo_buff_id/1
    , get_equip_fumo_part_list/1
    , get_equip_fumo_cost_id/1
    , get_equip_leach_cost_id/1
    , get_equip_enchant_stone_id/1
    , get_all_equip_fumo_state_id/0
    , get_equip_fumo_jd_attr/1                  %% 获取装备的鉴定附魔属性（在表equip_output.txt中）
    , get_equip_fumo_jd_id/1
    , get_equip_fumo_cfg_attr_list/1
    , filter_fumo_list_buff/1
    , change_jc_attr_fumo/2
    , change_jd_attr_fumo/2
    , fumo_save_list_to_attr_list/1
    , get_equip_fumo_cfg_buff_id_list/1
]).


%% 装备部位强化
-export([
    get_part_qiang_hua_attr/3,
    get_part_qiang_hua_extra_attr/3,
    get_failed_down/3,
    get_part_qiang_hua_cost/3,
    get_part_qh_all_attr/3,
    part_qh_max_level/1,
    can_part_qh_succeed/2,
    get_part_qianghua_effect/3,
    change_attr_by_permill/2
]).

-include("inc.hrl").
-include_lib("config/include/config.hrl").
-include("load_dial_prize.hrl").
-include("load_equip_expand.hrl").
-include("load_item.hrl").
-include("load_spirit_attr.hrl").
-include("item_new.hrl").


load_config_meta() ->
    [
        #config_meta{record = #equip_output_new_cfg{},
            fields = ?record_fields(equip_output_new_cfg),
            file = "equip_output.txt",
            keypos = #equip_output_new_cfg.id,
            rewrite = fun change/1,
            verify = fun verify_equip/1},

        #config_meta{record = #equip_suit_combine_new_cfg{},
            fields = ?record_fields(equip_suit_combine_new_cfg),
            file = "equip_suit_combine.txt",
            keypos = #equip_suit_combine_new_cfg.id,
            verify = fun verify_suit_combine/1},

        #config_meta{record = #equip_qiang_hua_new_cfg{},             %% 之前的装备强化方式已经取消所以先屏蔽掉
            fields = ?record_fields(equip_qiang_hua_new_cfg),
            file = "equip_qiang_hua.txt",
            keypos = #equip_qiang_hua_new_cfg.id,
            verify = fun verify/1},

        #config_meta{record = #equip_he_cheng_new_cfg{},
            fields = ?record_fields(equip_he_cheng_new_cfg),
            file = "equip_he_cheng.txt",
            keypos = #equip_he_cheng_new_cfg.id,
            verify = fun verify_he/1},

        #config_meta{record = #equip_ji_cheng_new_cfg{},
            fields = ?record_fields(equip_ji_cheng_new_cfg),
            file = "equip_ji_cheng.txt",
            keypos = #equip_ji_cheng_new_cfg.id,
            verify = fun verify_jc/1},

        #config_meta{record = #equip_jianding_new_cfg{},
            fields = ?record_fields(equip_jianding_new_cfg),
            file = "equip_jianding.txt",
            keypos = #equip_jianding_new_cfg.id,
            verify = fun verify_jd/1},

        #config_meta{record = #equip_change_cfg{},
            fields = ?record_fields(equip_change_cfg),
            file = "equip_change.txt",
            keypos = #equip_change_cfg.id,
            verify = fun verify_ec/1},

        #config_meta{record = #equip_org_cfg{},
            fields = ?record_fields(equip_org_cfg),
            file = "equip.txt",
            keypos = #equip_org_cfg.bid,
            verify = fun verify_equ_org/1},

        #config_meta{record = #epurate_cfg{},
            fields = ?record_fields(epurate_cfg),
            file = "epurate.txt",
            keypos = #epurate_cfg.id,
            verify = fun verify_epurate_cfg/1},

        #config_meta{record = #equip_enhancement_cfg{},
            fields = ?record_fields(equip_enhancement_cfg),
            file = "equip_enhancements.txt",
            keypos = #equip_enhancement_cfg.id,
            all = [#equip_enhancement_cfg.id],
            verify = fun verify_equip_enhancement/1
            },

        #config_meta{record = #equip_part_qiang_hua_cfg{},
            fields = ?record_fields(equip_part_qiang_hua_cfg),
            file = "equip_part_qiang_hua.txt",
            keypos = #equip_part_qiang_hua_cfg.id,
            rewrite = fun change_type_to_pos/1,
            verify = fun verify_equip_part_qiang_hua/1
        }
    ].


%% 此函数是特效没更改之前获取特效的函数
get_equip_qh_eftid(Bid, QHLvl ) ->
    case lookup_equip_org_cfg(Bid) of
        #equip_org_cfg{improve_effect = EftList} ->
            Ret =
                lists:foldl
                (
                    fun
                        ({CfgLvl, ID}, {MaxLvL, MaxID}) ->
                            if
                                QHLvl >= CfgLvl andalso CfgLvl > MaxLvL ->
                                    {CfgLvl, ID};
                                true ->
                                    {MaxLvL, MaxID}
                            end
                    end,
                    {0, 0},
                    EftList
                ),
            case Ret of
                {_, 0} -> ?none;
                {_, RetID} ->
                    case is_integer(RetID) of
                        true -> [Ret];
                        _ -> RetID
                    end
            end;
        _ ->
            ?none
    end.

%%根据套装ID,套装等级Lev，套装个数Count,获得套装属性ID
get_equip_suit_attrId( {ID, Lev, Count} ) ->
    case lookup_equip_suit_combine_new_cfg( ID ) of %%根据套装ID获取配置表
        #equip_suit_combine_new_cfg{attr = List} -> %%匹配属性表
            _Ret =
                lists:foldl
                (
                    fun
                        ({{Lev1,Count1},AttrId1},AttrId) ->
                            if
                                Lev =:= Lev1 andalso Count =:= Count1 ->
                                    AttrId1;
                                true ->
                                    AttrId
                            end
                    end,
                    0,
                    List
                );
        _ ->
            ?none
    end.

get_equip_suit_attrId(Id, Level, Count) ->
    case lookup_equip_suit_combine_new_cfg(Id) of
        #equip_suit_combine_new_cfg{attr = List} ->
            case lists:keyfind({Level, Count}, 1, List) of
                {_, AttrId} ->
                    AttrId;
                _ ->
                    0
            end;
        _ ->
            0
    end.




get_equip_gem_eftid( Bid, GemTopLvl, GemTopNum ) ->
    case lookup_equip_org_cfg(Bid) of
        #equip_org_cfg{gem_effect = EftList} ->
            List1 = lists:filter
                (
                    fun({GemLvl, GemNum, _Id}) ->
                        GemTopLvl >= GemLvl andalso GemTopNum >= GemNum
                    end,
                    EftList
                ),
                case List1 of
                    [] -> ?none;
                    [{_GemLvl1, _GemNum1, Id1}|_T] -> Id1
                end;
        _ ->
            ?none
    end.

change(_) ->
    NewCfgList =
        ets:foldl(fun({_, #equip_output_new_cfg{
            id = Id, suit_per = Ss, gem_slot_num = Gs, jd_attr_min_num = JdAMinN
            , jd_attr_max_num = JdAMaxN, jd_attr = JdAttrs} = Cfg}, FAcc
        ) ->
            {TTs, SSs} = com_util:probo_build(Ss),
            {Tg, SGs} = com_util:probo_build(Gs),
            SJAs = case JdAttrs of
                       [{AttrNumId, AttrValue} | R] ->
                           [{AttrNumId, AttrValue} | R];
                       JdAttrs ->
                            [{{AttrNumId, AttrValue},Weight} || {AttrNumId, Weight, AttrValue} <- JdAttrs]
                   end,
            JdLen = length(JdAttrs),
            ?check(com_util:is_valid_uint_max(JdAMinN, JdLen) andalso com_util:is_valid_uint_max(JdAMaxN, JdLen)
                , "qeuip_output.txt [~w] jd_attr ~w 条数约束错误 JdLen~w, JdMin~w, JdMax~w ", [Id, JdAttrs, JdLen, JdAMinN, JdAMaxN]),
            ?check(TTs == 100, "qeuip_output.txt [~p] suit_per 权重和不为100 ~p", [Id, Ss]),
            ?check(Tg == 100, "qeuip_output.txt [~p] gem_slot_num 权重和不为100 ~p", [Id, Gs]),
            [Cfg#equip_output_new_cfg{suit_per = SSs, gem_slot_num = SGs, jd_attr = SJAs} | FAcc]
        end, [], equip_output_new_cfg),
    NewCfgList.

verify_equip(#equip_output_new_cfg{id = Id, base_attr = BaseAttrId}) ->
    ?check(load_item:is_exist_item_attr_cfg(Id), "equip_output.txt id [~w] 物品不存在! ", [Id]),
    ?check(load_spirit_attr:is_exist_attr(BaseAttrId), "equip_output.txt [~w] 中 base_attr ~w 无效", [Id, BaseAttrId]),
    ok.

verify_suit_combine(#equip_suit_combine_new_cfg{id = _Id}) ->
%%     lists:foreach(fun({{Lev, Count}, Attr}) ->
%%         ?check(com_util:is_valid_uint8(Lev), "equip_suit_combine_new_cfg.txt [~w] 套装等级 lev ~w", [Id, Lev]),
%%         ?check(com_util:is_valid_uint8(Count), "equip_suit_combine_new_cfg.txt [~w] 套装件数 count ~w", [Id, Count]),
%%         ?check(load_spirit_attr:is_exist_attr(Attr), "equip_suit_combine_new_cfg.txt [~w] 属性配置错误 attr ~w", [Id, Attr])
%%     end, CAttrs),
    ok.

%% 之前的装备强化暂时用不到所以线屏蔽掉
verify(#equip_qiang_hua_new_cfg{id = _Id, attr = _Attr, extra_attr = _ExAttr, cost = _Cost}) ->
%%    ?check(load_spirit_attr:is_exist_attr(Attr), "equip_qiang_hua.txt [~w] attr ~w 属性配置错误", [Id, Attr]),
%%    ?check(load_spirit_attr:is_exist_attr(ExAttr), "equip_qiang_hua.txt [~w] extra_attr ~w 属性配置错误", [Id, ExAttr]),
%%    cost:check_cost_not_empty(Cost, "equip_qiang_hua.txt [~p] cost 无法找到 ~p ", [Id, Cost]),
    ok.

verify_equ_org(#equip_org_cfg{ bid = Bid, type = Type, lev = Lvl, job = Job, resolve = Res}) ->
    Equips = my_ets:get({equip, Type, Lvl, Job}, []),
    my_ets:set({equip, Type, Lvl, Job}, [Bid | Equips]),
    ?check(lists:member(Res, [?TRUE, ?FALSE]), "equip_qiang_hua.txt [~p] attr ~p 配置错误,应该为0 1", [Bid, Res]),
    ok.

verify_he(#equip_he_cheng_new_cfg{id = Id, cost = Cost}) ->
    cost:check_cost_not_empty(Cost, "equip_he_cheng.txt [~p] cost 无法找到 ~p ", [Id, Cost]),
    ok.

verify_jc(#equip_ji_cheng_new_cfg{id = Id, cost = Cost}) ->
    cost:check_cost_not_empty(Cost, "equip_ji_cheng.txt [~p] cost 无法找到 ~p ", [Id, Cost]),
    ok.

verify_jd(#equip_jianding_new_cfg{id = Id, cost = Cost}) ->
    cost:check_cost_not_empty(Cost, "equip_jianding.txt [~p] cost 无法找到 ~p ", [Id, Cost]),
    ok.

%% 装备改造
verify_ec(#equip_change_cfg{id = Id, gem_slot_num = GemSlot, jd_attr_num = JDAttrNum, buf_attr_num = BufAttrNum}) ->
    ?check(is_list(GemSlot), "equip_change.txt [~p] gem_slot_num 格式不正确 ~p", [Id, GemSlot]),
    ?check(is_list(JDAttrNum), "equip_change.txt [~p] jd_attr_num 格式不正确 ~p", [Id, JDAttrNum]),
    ?check(is_list(BufAttrNum), "equip_change.txt [~p] buf_attr_num 格式不正确 ~p", [Id, BufAttrNum]),
    ok.

%% 装备提取
verify_epurate_cfg(#epurate_cfg{id = Id, num = Num, quality = Qua, enhance_level = EnLvl, cost = CostId}) ->
    case is_tuple(Num) of
        true ->
            ?check(size(Num) =:= 2, "epurate.txt [~p] num 格式不正确 ~p", [Id, Num]);
        _ ->
            ?ERROR_LOG("epurate.txt [~p] num 格式不正确 ~p", [Id, Num])
    end,
    ?check(is_list(Qua), "epurate.txt [~p] quality 格式不正确 ~p", [Id, Qua]),
    lists:foreach(
        fun({Q, List}) ->
            ?check(is_list(List), "epurate.txt [~p] 格式不正确 ~p", [Id, {Q, List}])
        end,
        Qua
    ),
    ?check(is_list(EnLvl), "epurate.txt [~p] enhance_level 格式不正确 ~p", [Id, EnLvl]),
    ?check(cost:is_exist_cost_cfg(CostId), "cost.txt [~p] cost: ~p 没有找到", [Id, CostId]),
    ok.

%% 装备附魔与萃取
verify_equip_enhancement(#equip_enhancement_cfg{id = Id, enhancements_item = ItemId, buff = Buff,
    part = PartList, enhancements_cost = CostId1, leach_cost = CostId2, enchant_stones = StoneId}) ->
    ?check(load_item:is_exist_item_cfg(ItemId), "equip_enhancements.txt [~p] enhancements_item:~p 没有找到", [Id, ItemId]),
    ?check(is_list(Buff), "equip_enhancements.txt [~p] buff:~p 类型不正确", [Id, Buff]),
    lists:foreach
    (
        fun
            ({?equip_fumo_cfg_type_min_max, {_AttrId, {Min, Max}}}) ->
                ?check(Max >= Min, "equip_enhancements.txt [~p] 数值格式不正确 {~p,{~p, ~p}}", [Id, _AttrId, Min, Max] );
            ({?equip_fumo_cfg_type_per_mill, {_AttrId, {MillMin, MillMax}}}) ->
                ?check(MillMax >= MillMin, "equip_enhancements.txt [~p] 数值格式不正确 {~p,{~p, ~p}}", [Id, _AttrId, MillMin, MillMax] );
            ({?equip_fumo_cfg_type_buff, BuffId}) ->
                ?check(load_cfg_skill:is_exist_skill_modify_cfg(BuffId), "equip_enhancements.txt [~p] buffId:~p 没有找到", [Id, BuffId]);
            (Mes) ->
                ?ERROR_LOG("equip_enhancements.txt [~p]  buff: ~p 配置类型错误！！！", [Id, Mes]),
                pass
        end,
        Buff
    ),
    ?check(is_list(PartList), "equip_enhancements.txt [~p] part:~p 格式不正确 ", [Id, PartList]),
    lists:foreach
    (
        fun(PartType) ->
            ?check(lists:member(PartType, ?all_equips_type), "equip_enhancements.txt [~p] 装备部位的类型不正确 type:~p", [Id, PartType])
        end,
        PartList
    ),
    ?check(cost:is_exist_cost_cfg(CostId1), "equip_enhancements.txt [~p] enhancements_cost:~p 没有在cost.txt中找到", [Id, CostId1]),
    ?check(cost:is_exist_cost_cfg(CostId2), "equip_enhancements.txt [~p] leach_cost:~p 没有在cost.txt中找到", [Id, CostId2]),
    ?check(load_item:is_exist_item_cfg(StoneId), "equip_enhancements.txt [~p] enchant_stones:~p 没有找到", [Id, StoneId]),
    ok.

%% 更改装备的部位类型配置把配置中的type转换成前端需要的位置pos,转换方法是将类型减掉100
change_type_to_pos(_) ->
    NewList =
        ets:foldl
        (
            fun({_, Cfg = #equip_part_qiang_hua_cfg{part = Type}}, AccList) ->
                [Cfg#equip_part_qiang_hua_cfg{part = Type-100} | AccList]
            end,
            [],
            equip_part_qiang_hua_cfg
        ),
    NewList.

%% 按照可穿装备强化模块
verify_equip_part_qiang_hua(#equip_part_qiang_hua_cfg{id = Id, attr = AttrId, extra_attr = EAttrId, failed_down = DownList, cost = CostId}) ->
    ?check(load_spirit_attr:is_exist_attr(AttrId), "配置equip_part_qiang_hua.txt id: ~p attr:~p 在配置表spirit_attr.txt中没有找到", [Id, AttrId]),
    case is_integer(EAttrId) of
        true ->
            ?check(load_spirit_attr:is_exist_attr(EAttrId), "配置equip_part_qiang_hua.txt id: ~p extra_attr:~p 在配置表spirit_attr.txt中没有找到", [Id, EAttrId]);
        _ ->
            pass
    end,
    ?check(is_list(DownList), "配置equip_part_qiang_hua.txt id: ~p failed _down格式不正确", [Id, DownList]),
    ?check(cost:is_exist_cost_cfg(CostId), "配置equip_part_qiang_hua.txt id:~p cost: ~p 在配置表cost.txt中没有找到", [Id, CostId]),
    ok.

%% 获取装备鉴定消耗(品质)
get_jianding_money(Qly) ->
    case load_equip_expand:lookup_equip_jianding_new_cfg(Qly) of
        #equip_jianding_new_cfg{cost = CostID} ->
            load_cost:get_cost_list(CostID);
        _ ->
            ret:error(error_qly)
    end.

%% 获取装备配置的鉴定属性
get_cfg_jd_attr(Bid) ->
    case lookup_equip_output_new_cfg(Bid) of
        #equip_output_new_cfg{jd_attr = JDAttr} ->
            JDAttr;
        _ ->
            {error, unknown_type}
    end.


%% 鉴定属性,生成一个固定属性
do_create_equip_fixed_attr(IsNeedJd, Ss, Gs, JdAMinN, JdAMaxN, JdAttrs, BaseAttrID) ->
    SuitId = com_util:probo_random(Ss),
    GemTuple =
        case Gs of
            [] ->
                erlang:make_tuple(0, 0);
            _ ->
                SlotSize = com_util:probo_random(Gs),
                erlang:make_tuple(SlotSize, 0)
        end,
    {EquipIsJd, JdAttrL} =
        case IsNeedJd of
            ?TRUE ->
                JdAttrList = rand_equip_jd_attr(JdAMinN, JdAMaxN, JdAttrs, SuitId),
                {?FALSE, JdAttrList};
            ?FALSE ->
                JdAttrList = no_rand_equip_jd_attr(JdAttrs, SuitId),
                {?TRUE, JdAttrList}
        end,
    #equip_rand_attr_ret{suit_id = SuitId, gem_slots_tuple = GemTuple, is_jd = EquipIsJd,
        jd_attr = JdAttrL, base_attr = BaseAttrID, quality = item_equip:get_jd_qly(length(JdAttrL), SuitId)}.

%% 鉴定属性
do_create_equip_rand_attr(IsNeedJd, Ss, Gs, JdAMinN, JdAMaxN, JdAttrs, BaseAttrID) ->
    SuitId = com_util:probo_random(Ss),
    GemTuple =
        case Gs of
            [] ->
                erlang:make_tuple(0, 0);
            _ ->
                SlotSize = com_util:probo_random(Gs),
                erlang:make_tuple(SlotSize, 0)
        end,
    {EquipIsJd, JdAttrL} =
        case IsNeedJd of
            ?TRUE ->
                JdAttrListRet = rand_equip_jd_attr(JdAMinN, JdAMaxN, JdAttrs, SuitId),
                {?FALSE, JdAttrListRet};
            ?FALSE ->
                case JdAttrs of
                    [] ->
                        {?TRUE, []};
                    JdAttrs ->
                        [OneTuple|_] = JdAttrs,
                        case OneTuple of
                            {{_AId, _AVal}, _AWgh} ->
                                AttrList = rand_equip_jd_attr(JdAMinN, JdAMaxN, JdAttrs, SuitId),
                                {?TRUE, AttrList};
                            {_AttrNumId, _AttrNum} ->
                                AttrList = no_rand_equip_jd_attr(JdAttrs, SuitId),
                                {?TRUE, AttrList}
                        end
                end
        end,
    #equip_rand_attr_ret{suit_id = SuitId, gem_slots_tuple = GemTuple, is_jd = EquipIsJd,
        jd_attr = JdAttrL, base_attr = BaseAttrID, quality = item_equip:get_jd_qly(length(JdAttrL), SuitId)}.

%% 随机鉴定属性与属性范围的处理
rand_equip_jd_attr(0, 0, _, _) -> [];
rand_equip_jd_attr(JdAMin, JdAMax, JdAttrs, SuitId) ->
    AttrNum = com_util:random(JdAMin, JdAMax),
    RetAttrList = util:get_val_by_weight(JdAttrs, AttrNum),
    Quality = item_equip:get_jd_qly(length(RetAttrList), SuitId),
    %% 根据品质来设定装备的取值范围
    CfgJdList = misc_cfg:get_jd_attr_range(),
    {PerMin, PerMax} =
        case lists:keyfind(Quality, 1, CfgJdList) of
            {_Q, {Min, Max}} ->
                {Min, Max};
            _Mes ->
                ?ERROR_LOG("not find quality:~p range Mes:~p", [Quality, _Mes])
        end,
    lists:map
    (
        fun({AttrId, AttrCfgVal}) ->
%%            ?INFO_LOG("AttrId = ~p", [AttrId]),
            Per = com_util:random(PerMin, PerMax),
%%            ?INFO_LOG("Per = ~p", [Per]),
            AttrVal = max(1, com_util:floor(AttrCfgVal * (Per/100))),
%%            ?INFO_LOG("AttrVal = ~p", [AttrVal]),
            AttrMin = max(1, com_util:floor(AttrCfgVal * (PerMin/100))),
%%            ?INFO_LOG("AttrMin = ~p", [AttrMin]),
            AttrMax = com_util:floor(AttrCfgVal * (PerMax/100)),
%%            ?INFO_LOG("AttrMax = ~p", [AttrMax]),
            {AttrId, AttrVal, 100, AttrMin, AttrMax}
        end,
        RetAttrList
    ).

%% 非随机属性的鉴定属性与范围的处理
no_rand_equip_jd_attr(AttrList, SuitId) ->
    Quality = item_equip:get_jd_qly(length(AttrList), SuitId),
    %% 根据品质来设定装备的取值范围
    CfgJdList = misc_cfg:get_jd_attr_range(),
    {PerMin, PerMax} =
        case lists:keyfind(Quality, 1, CfgJdList) of
            {_Q, {Min, Max}} ->
                {Min, Max};
            _Mes ->
                ?ERROR_LOG("not find quality:~p range Mes:~p", [Quality, _Mes])
        end,
    lists:map
    (
        fun({AttrId, AttrVal}) ->
            %% 通过范围的随机值逆运算出属性的上下限
%%            Per = com_util:random(PerMin, PerMax),
%%            Num = AttrVal/(Per/100),
%%            AttrMin = max(1, com_util:floor(Num * (PerMin/100))),
%%            AttrMax = max(AttrVal, com_util:floor(Num * (PerMax/100))),
            AttrMin = max(1, com_util:floor(AttrVal * (PerMin/PerMax))),
            AttrMax = AttrVal,
            {AttrId, AttrVal, 100, AttrMin, AttrMax}
        end,
        AttrList
    ).

%% 根据equip_output.txt的配置属性来随机相应的属性(含属性的突变设置暂时不用)
%%rand_equip_jd_attr(JdAMinN, JdAMaxN, JdAttrs) ->
%%    JdAttrProbo = com_util:random_more({JdAMinN, JdAMaxN}, JdAttrs),
%%
%%%%                io:format("JdAttrs = ~p~n", [JdAttrs]),
%%%%    ?INFO_LOG("JdMinN = ~p, JdAMaxN = ~p", [JdAMinN, JdAMaxN]),
%%%%    ?INFO_LOG("JdAttrProbo = ~p", [JdAttrProbo]),
%%    %% 突变属性Index
%%    MutantAttrId = com_util:random(1, erlang:length(JdAttrProbo)),
%%    CalculateValFun =
%%        fun(Val, LvLAddPro, RandAddPro) ->
%%            Va1 = Val * LvLAddPro * (1 + RandAddPro),
%%            com_util:ceil(Va1)
%%        end,
%%    {JdAttrListRet, _} =
%%        lists:mapfoldl
%%        (
%%            fun
%%                ({{JdAttrId, Min, Max}, _}, Index) ->
%%                    %% ----------------- old version ----------------
%%                    %% %% 鉴定属性数值
%%                    %% JdAttrVal = com_util:random(Min, Max),
%%                    %% %% 计算属性数值所处品质
%%                    %% JdAttrLvl = com_util:ceil((JdAttrVal / Max) * 100),
%%                    %% {JdAttrId, JdAttrVal, JdAttrLvl}
%%
%%                    %% ----------------- new version ----------------
%%                    case Index of
%%                        MutantAttrId ->
%%                            %% 突变属性
%%%%                                        AddList = [0.1, 0.25, 0.5, 1],
%%                            AddList = [1,1,1,1],                    %% 根据策划的需求生成属性暂时不发生突变(yty)
%%                            JdAttrRand = com_util:random(1, erlang:length(AddList)),
%%                            LvLAddPro = lists:nth(JdAttrRand, AddList),
%%
%%
%%                            JdAttrVal = com_util:random(Min, Max),
%%%%                                        RandAdd = (com_util:random(0, 20) - 10)/100,
%%                            RandAdd = 0,                            %% 根据策划的需求属性暂时不添加(yty)
%%                            JdAttrVal1 = CalculateValFun(JdAttrVal, LvLAddPro, RandAdd),
%%
%%%%                                         ?INFO_LOG(" =========================== MutantAttrId"),
%%%%                                         ?INFO_LOG(" =========================== JdAttrId ~p", [JdAttrId]),
%%%%                                         ?INFO_LOG(" =========================== JdAttrVal ~p", [JdAttrVal]),
%%%%                                         ?INFO_LOG(" =========================== JdAttrVal1 ~p", [JdAttrVal1]),
%%%%                                         ?INFO_LOG(" =========================== LvLAddPro ~p", [LvLAddPro]),
%%%%                                         ?INFO_LOG(" =========================== RandAdd ~p", [RandAdd]),
%%%%                                         ?INFO_LOG(" =========================== lvl ~p", [com_util:ceil(LvLAddPro*100)]),
%%
%%                            {{JdAttrId, JdAttrVal1, com_util:ceil(LvLAddPro*100), Min, Max}, Index+1};
%%
%%                        _ ->
%%                            %% 基本属性
%%%%                                        LvLAddPro = 0.1,
%%                            LvLAddPro = 1,
%%                            JdAttrVal = com_util:random(Min, Max),
%%%%                                        RandAdd = (com_util:random(0, 20) - 10)/100,
%%                            RandAdd = 0,
%%                            JdAttrVal1 = CalculateValFun(JdAttrVal, LvLAddPro, RandAdd),
%%
%%%%                                         ?INFO_LOG(" =========================== no MutantAttrId"),
%%%%                                         ?INFO_LOG(" =========================== JdAttrId ~p", [JdAttrId]),
%%%%                                         ?INFO_LOG(" =========================== JdAttrVal ~p", [JdAttrVal]),
%%%%                                         ?INFO_LOG(" =========================== JdAttrVal1 ~p", [JdAttrVal1]),
%%%%                                         ?INFO_LOG(" =========================== LvLAddPro ~p", [LvLAddPro]),
%%%%                                         ?INFO_LOG(" =========================== RandAdd ~p", [RandAdd]),
%%%%                                         ?INFO_LOG(" =========================== lvl ~p", [com_util:ceil(LvLAddPro*100)]),
%%
%%                            {{JdAttrId, JdAttrVal1, com_util:ceil(LvLAddPro*100), Min, Max}, Index+1}
%%                    end
%%            end,
%%            1,
%%            JdAttrProbo
%%        ),
%%    JdAttrListRet.




create_equip_rand_attr(Bid) ->
%%    ?INFO_LOG("create Bid = ~p", [Bid]),
    case lookup_equip_output_new_cfg(Bid) of
        #equip_output_new_cfg
        {
            is_jd = IsNeedJd,
            suit_per = Ss,
            gem_slot_num = Gs,
            jd_attr_min_num = JdAMinN,
            jd_attr_max_num = JdAMaxN,
            jd_attr = JdAttrs,
            base_attr = BaseAttrID
        } ->
%%            ?INFO_LOG("JdAMinN = ~p, JdAMaxN = ~p", [JdAMinN, JdAMaxN]),
            case Bid of
                100000001 ->
                    do_create_equip_fixed_attr(IsNeedJd, Ss, Gs, JdAMinN, JdAMaxN, JdAttrs, BaseAttrID);
                _ ->
                    do_create_equip_rand_attr(IsNeedJd, Ss, Gs, JdAMinN, JdAMaxN, JdAttrs, BaseAttrID)
            end;
        _ ->
            {error, not_found_eqm_out_cfg}
    end.

%% 鉴定属性
get_precent_total([]) -> 0;
get_precent_total([{Pre, _Min, _Max} | AttrNumList]) ->
    Pre + get_precent_total(AttrNumList).

get_present_val(_RandPre, _SumPre, []) -> {0, 0};
get_present_val(RandPre, SumPre, [{Pre, Min, Max} | AttrNumList]) ->
    if
        RandPre =< (SumPre + Pre) ->
            {Min, Max};
        true ->
            get_present_val(RandPre, SumPre + Pre, AttrNumList)
    end.




create_room_equip_rand_attr(PrizeId, Bid) ->
    case lookup_equip_change_cfg(PrizeId) of
        #equip_change_cfg
        {
            gem_slot_num = GsCfg,
            jd_attr_num = AttrNumCfg
        } ->
            {Gs, AttrNum} =
            case is_suit_by_bid(Bid) of
                true ->
                    GemList =
                        case lists:keyfind(2, 1, GsCfg) of         %% 普通装备查找配置类型1， 套装查找配置类型2
                            {_, GList} -> GList;
                            _ -> []
                        end,
                    AttrList =
                        case lists:keyfind(2, 1, AttrNumCfg) of         %% 普通装备查找配置类型1， 套装查找配置类型2
                            {_, AList} -> AList;
                            _ -> []
                        end,
                    {GemList, AttrList};
                _ ->
                    GemList =
                        case lists:keyfind(1, 1, GsCfg) of         %% 普通装备查找配置类型1， 套装查找配置类型2
                            {_, GList} -> GList;
                            _ -> []
                        end,
                    AttrList =
                        case lists:keyfind(1, 1, AttrNumCfg) of         %% 普通装备查找配置类型1， 套装查找配置类型2
                            {_, AList} -> AList;
                            _ -> []
                        end,
                    {GemList, AttrList}
            end,

            case lookup_equip_output_new_cfg(Bid) of
                #equip_output_new_cfg
                {
                    is_jd = IsNeedJd,
                    suit_per = Ss,
                    jd_attr = JdAttrs,
                    base_attr = BaseAttrID
                } ->
                    Total = get_precent_total(AttrNum),
                    RandPer = com_util:random(0, Total),
                    {MinNum, MaxNum} = get_present_val(RandPer, 0, AttrNum),
%%                     ?INFO_LOG("room prize ~p", [{MinNum, MaxNum}]),
                    do_create_equip_rand_attr(IsNeedJd, Ss, Gs, MinNum, MaxNum, JdAttrs, BaseAttrID);
                _ ->
                    {error, not_found_eqm_out_cfg}
            end;
        _ ->
            create_equip_rand_attr(Bid)
    end.

%%get_present_buf_val(_RandPre, _SumPre, []) -> {0, 0};
%%get_present_buf_val(RandPre, SumPre, [{Pre, Min, Max} | AttrNumList]) ->
%%    if
%%        RandPre =< (SumPre + Pre) ->
%%            {Min, Max};
%%        true ->
%%            get_present_val(RandPre, SumPre + Pre, AttrNumList)
%%    end.

do_create_equip_rand_buf_attr(IsNeedJd, MinNum, MaxNum, BufAttrList) ->
%%    ?DEBUG_LOG("IsNeedJd---:~p-----BufAttrList-----:~p",[IsNeedJd, BufAttrList]),
    BufAttrL =
        case IsNeedJd of
            ?TRUE ->
                Num = com_util:random(MinNum, MaxNum),
                rand_util:get_random_list(Num, BufAttrList);
            ?FALSE ->
                [ BufId || {BufId, _BufNum} <- BufAttrList]
        end,
    BufAttrL.
create_equip_rand_buf_attr(Bid) ->
    case lookup_equip_output_new_cfg(Bid) of
        #equip_output_new_cfg
        {
            is_jd = IsNeedJd,
            buf_attr_num = BufNumList,
            buf_attr = BufAttrList
        } ->
            Total = get_precent_total(BufNumList),
            RandPer = com_util:random(0, Total),
            {MinNum, MaxNum} = get_present_val(RandPer, 0, BufNumList),
%%             ?INFO_LOG("room prize ~p", [{MinNum, MaxNum}]),
            do_create_equip_rand_buf_attr(IsNeedJd, MinNum, MaxNum, BufAttrList);
        _ ->
            {error, not_found_eqm_out_cfg}
    end.
create_room_equip_rand_buf_attr(_PrizeId, Bid) ->
    create_equip_rand_buf_attr(Bid).


%% 强化-----------------------------------------------------------------------------------

%% 获取强化配置
get_qiang_hua_cfg(Bid, QHLvl) ->
    case load_item:get_item_cfg(Bid) of
        {error, Error} ->
            {error, Error};
        #item_attr_cfg{type = GoodsType, job = Job, lev = UseLvl} ->
            CfgId = Job * 100000000 + GoodsType * 100000 + UseLvl * 100 + QHLvl,
            Cfg = lookup_equip_qiang_hua_new_cfg(CfgId),
            case Cfg of
                #equip_qiang_hua_new_cfg{} -> Cfg;
                _ -> ret:error(unknown_type)
            end
    end.

%% 获取强化配置Cost
get_qiang_hua_cost(Bid, QHLvl) ->
    case get_qiang_hua_cfg(Bid, QHLvl) of
        {error, Error} -> {error, Error};
        #equip_qiang_hua_new_cfg{cost = CostID} ->
            load_cost:get_cost_list(CostID)
    end.

get_qiang_hua_attr(Bid, QHLvl) ->
    if
        QHLvl =< 0 ->
            #attr{};
        true ->
            case get_qiang_hua_cfg(Bid, QHLvl) of
                {error, Error} ->
                    {error, Error};
                #equip_qiang_hua_new_cfg
                {
                    attr = AttrID,
                    extra_attr = ExtraAttrID
                } ->
                    BAttr = attr_new:get_attr_by_id(AttrID),
                    EAttr = attr_new:get_attr_by_id(ExtraAttrID),
                    attr_algorithm:add(BAttr, EAttr)
            end
    end.

get_qiang_hua_attr(Bid, QHLvl, FumoList) ->
    if
        QHLvl =< 0 ->
            #attr{};
        true ->
            case get_qiang_hua_cfg(Bid, QHLvl) of
                {error, Error} ->
                    {error, Error};
                #equip_qiang_hua_new_cfg
                {
                    attr = AttrID,
                    extra_attr = ExtraAttrID
                } ->
                    BAttr = attr_new:get_attr_by_id(AttrID),
                    EAttr = attr_new:get_attr_by_id(ExtraAttrID),
                    MillList = [{AttrId, Rat} || {Type, AttrId, Rat} <- FumoList,
                        Type =:= ?equip_fumo_cfg_type_per_mill],
                    BAttr1 = change_jc_attr_fumo(BAttr, MillList),
                    EAttr1 = change_jc_attr_fumo(EAttr, MillList),
                    attr_algorithm:add(BAttr1, EAttr1)
            end
    end.

%% 强化是否成功
can_qiang_hua_success(QHLvl) ->
    %?random(100) =< (100 + math:log(1+Qh) / math:log(0.9)).
    Rand = ?random(100),
    Limit = (100 + math:log(1 + QHLvl) / math:log(0.95)),
    if
        Rand =< Limit -> ret:ok();
        true -> ret:error(qh_failed)
    end.

%% 强化是否成功
get_qiang_hua_failed_lvl(Bid, QHLvl) ->
    if
        QHLvl =< 0 -> 0;
        true ->
            case get_qiang_hua_cfg(Bid, QHLvl) of
                {error, Error} -> {error, Error};
                #equip_qiang_hua_new_cfg
                {
                    failed_down = FailedPer
                } ->
                    DownLev = com_util:probo_random(FailedPer),
                    max(0, QHLvl - DownLev)
            end
    end.


%% -----------------------------------

get_he_cheng_change_num(MainNum) ->
    HeChengPerAll = misc_cfg:get_he_cheng_cfg(),
    HeChengPer =
        case lists:keyfind(MainNum, 1, HeChengPerAll) of
            {_, List} ->
                List;
            _ ->
                ?ERROR_LOG("not found hecheng cfg")
        end,
    {_TmpT, HeChengPer1} = com_util:probo_build(HeChengPer),
    ChangeVal = com_util:probo_random(HeChengPer1),
    ChangeVal.

get_he_cheng_cost_list(MainEquipType, MainEquipLvl) ->
    CfgId = MainEquipType * 1000 + MainEquipLvl,
    case lookup_equip_he_cheng_new_cfg(CfgId) of
        #equip_he_cheng_new_cfg{cost = CostID} -> load_cost:get_cost_list(CostID);
        _ -> ret:error(unknown_type)
    end.

get_ji_cheng_cost_list(EquipType, EquipLvl) ->
    CfgId = EquipType*1000+EquipLvl,
    case lookup_equip_ji_cheng_new_cfg(CfgId) of
        #equip_ji_cheng_new_cfg{cost = CostID} -> load_cost:get_cost_list(CostID);
        _ -> ret:error(unknown_type)
    end.


get_ji_cheng_failed_list(EquipType, EquipLvl) ->
    CfgId = EquipType*1000+EquipLvl,
    case lookup_equip_ji_cheng_new_cfg(CfgId) of
        #equip_ji_cheng_new_cfg{odds = Odds} -> Odds;
        _ -> ret:error(unknown_type)
    end.

%%  获取所有的装备bid列表
get_all_equip_bid_list() ->
    lookup_all_equip_org_cfg(#equip_org_cfg.bid).

%%  获取装备的配置类型
get_equip_cfg_type(Bid) ->
    case lookup_equip_org_cfg(Bid) of
        #equip_org_cfg{type = Type} ->
            Type;
        _ -> ret:error(unknown_type)
    end.

%%  获取装备的配置等级
get_equip_cfg_level(Bid) ->
    case lookup_equip_org_cfg(Bid) of
        #equip_org_cfg{lev = Level} ->
            Level;
        _ -> 
            1
    end.

%%  获取装备的配置职业
get_equip_cfg_job(Bid) ->
    case lookup_equip_org_cfg(Bid) of
        #equip_org_cfg{job = Job} ->
            Job;
        _ -> ret:error(unknown_type)
    end.

get_rand_equip(Job, Type, Level) ->
    Equips = my_ets:get({equip, Type, Level, Job}, []),
    case Equips of
        [] ->
            nil;
        _ ->
            Index = com_util:random(1, length(Equips)),
            lists:nth(Index, Equips)
    end.
% get_rand_equip(Job, Type, MinLvl, MaxLvl) ->
%     EquipSet =
%         lists:foldl
%         (
%             fun
%                 (Lvl, Set) ->
%                     Equips = my_ets:get({equip, Type, Lvl, Job}, []),
%                     Set ++ Equips
%             end,
%             [],
%             lists:seq(MinLvl, MaxLvl, 1)
%         ),
%     Len = erlang:length(EquipSet),
%     if
%         1 =< Len ->
%             Index = com_util:random(1, Len),
%             lists:nth(Index, EquipSet);
%         true ->
%             nil
%     end.

%% 获取装备的鉴定基础属性列表
get_equip_output_new_cfg_jd_attr(Bid) ->
    case lookup_equip_output_new_cfg(Bid) of
        #equip_output_new_cfg{jd_attr = JDAttr} -> JDAttr;
        _ -> {error, no_msg}
    end.


%% 获取该装备是否可以提炼
get_equip_can_exchange(EquipBid) ->
    case lookup_equip_org_cfg(EquipBid) of
        #equip_org_cfg{resolve = Res} ->
            Res;
        _ ->
            ret:error(unknow_type)
    end.

%% 获取装备提炼的数量兑换区间
get_equip_cfg_exchange_num_section(EquipLvl) ->
    case lookup_epurate_cfg(EquipLvl) of
        #epurate_cfg{num = Num} ->
            Num;
        _ ->
            ret:error(unknow_type)
    end.

%% 获取装备提炼的品质兑换列表
get_equip_cfg_exchange_quality(EquipLvl) ->
    case lookup_epurate_cfg(EquipLvl) of
        #epurate_cfg{quality = Quality} ->
            Quality;
        _ ->
            ret:error(unknow_type)
    end.

%% 获取装备提炼的强化等级兑换列表
get_equip_cfg_enhance_level(EquipLvl) ->
    case lookup_epurate_cfg(EquipLvl) of
        #epurate_cfg{enhance_level = EnLvlList} ->
            EnLvlList;
        _ ->
            ret:error(unknow_type)
    end.

%% 获取装备提炼的消耗id
get_cfg_exchange_cost_id(EquipLvl) ->
    case lookup_epurate_cfg(EquipLvl) of
        #epurate_cfg{cost = CostId} ->
            CostId;
        _ ->
            ret:error(unknow_type)
    end.

%% 获取装备的附魔卷轴id
get_equip_fumo_scroll_id(Id) ->
    case lookup_equip_enhancement_cfg(Id) of
        #equip_enhancement_cfg{enhancements_item = ItemId} ->
            ItemId;
        _ ->
            ret:error(unknown_type)
    end.


%% 获取装备的附魔buff的id
get_equip_fumo_buff_id(Id) ->
    case lookup_equip_enhancement_cfg(Id) of
        #equip_enhancement_cfg{buff = BuffId} ->
            BuffId;
        _ ->
            ret:error(unknown_type)
    end.

%% 获取可附魔的装备的列表
get_equip_fumo_part_list(Id) ->
    case lookup_equip_enhancement_cfg(Id) of
        #equip_enhancement_cfg{part = PartList} ->
            PartList;
        _ ->
            []
    end.

%% 获取装备的附魔消耗的id
get_equip_fumo_cost_id(Id) ->
    case lookup_equip_enhancement_cfg(Id) of
        #equip_enhancement_cfg{enhancements_cost = CostId} ->
            CostId;
        _ ->
            ret:error(unknown_type)
    end.

%% 获取装备的萃取消耗id
get_equip_leach_cost_id(Id) ->
    case lookup_equip_enhancement_cfg(Id) of
        #equip_enhancement_cfg{leach_cost = CostId} ->
            CostId;
        _ ->
            ret:error(unknown_type)
    end.

%% 获取装备的附魔石id
get_equip_enchant_stone_id(Id) ->
    case lookup_equip_enhancement_cfg(Id) of
        #equip_enhancement_cfg{enchant_stones = StoneId} ->
            StoneId;
        _ ->
            ret:error(unknown_type)
    end.

%% 获取所有附魔公式的id
get_all_equip_fumo_state_id() ->
    List = [X || X <- lookup_all_equip_enhancement_cfg(#equip_enhancement_cfg.id), is_integer(X)],
    List.


%% 获取装备的附魔列表
get_equip_fumo_jd_attr(ItemBid) ->
    case lookup_equip_output_new_cfg(ItemBid) of
        #equip_output_new_cfg{enhancements = FumoAttrList} ->
            FumoAttrList;
        _ ->
            ret:error(unknown_type)
    end.

%% 根据附魔鉴定列表的权值来获取装备鉴定时的附魔id
get_equip_fumo_jd_id(ItemBid) ->
    [ID] = util:get_val_by_weight(get_equip_fumo_jd_attr(ItemBid), 1),
    ID.


%% 获取附魔时的所有的附魔信息列表（需要同步到前端）
get_equip_fumo_cfg_attr_list(0) -> [];
get_equip_fumo_cfg_attr_list(FumoId) ->
    AttrList =
    lists:foldl(fun(BufMes, Acc) ->
        case BufMes of
            {?equip_fumo_cfg_type_min_max, {AttrId, {Min, Max}}} ->
                [{?equip_fumo_cfg_type_min_max, AttrId, com_util:random(Min, Max)} | Acc];
            {{?equip_fumo_cfg_type_per_mill,{AttrId, {MillMin, MillMax}}}} ->
                [{?equip_fumo_cfg_type_per_mill, AttrId, com_util:random(MillMin, MillMax)} | Acc];
            {?equip_fumo_cfg_type_buff, BuffId} ->
                [{?equip_fumo_cfg_type_buff, 0, BuffId} | Acc];
            _ ->
                Acc
        end
    end,
    [],
    get_equip_fumo_buff_id(FumoId)),
    AttrList.

%% 筛选出附魔信息中的buf列表
filter_fumo_list_buff(FumoList) ->
    BuffList =
        lists:foldl
        (
            fun(Mes, Acc) ->
                case Mes of
                    {?equip_fumo_cfg_type_buff, 0, BuffId} ->
                        [BuffId | Acc];
                    _ ->
                        Acc
                end
            end,
            [],
            FumoList
        ),
    BuffList.

%% 根据附魔属性的千分比修改装备的基础属性
change_jc_attr_fumo(Attr, MillList) when is_record(Attr,attr) ->
    NewAttr =
        lists:foldl
        (
            fun({AttrKey, Rat}, Acc) ->
                AttrKey1 = AttrKey - ?cfg_attr_key_dt,
                OldVal = element(AttrKey1, Acc),
                setelement(AttrKey1, Acc, (OldVal + OldVal*(Rat/1000)))
            end,
            Attr#attr{},
            MillList
        ),
    NewAttr.

%% 根据附魔属性的千分比修改装备的鉴定属性
change_jd_attr_fumo(JDAttr, MillList) ->
    ChangeList =
        lists:foldl
        (
            fun({AttrId, AttrVal, Pro}, Acc) ->
                case lists:keyfind(AttrId, 1, MillList) of
                    {_AttrId, Fac} ->
                        [{AttrId, erlang:round(AttrVal*(Fac/1000))+AttrVal, Pro} | Acc];
                    _ ->
                        [{AttrId, AttrVal, Pro} | Acc]
                end;
                ({AttrId, AttrVal}, Acc) ->
                    case lists:keyfind(AttrId, 1, MillList) of
                        {_AttrId, Fac} ->
                            [{AttrId, erlang:round(AttrVal*(Fac/1000))+AttrVal} | Acc];
                        _ ->
                            [{AttrId, AttrVal} | Acc]
                    end
            end,
            [],
            JDAttr
        ),
    ChangeList.

fumo_save_list_to_attr_list(SaveList) ->
    AttrList =
        lists:foldl
        (
            fun({Type, AttrId, AttrVal}, Acc) ->
                case Type =:= ?equip_fumo_cfg_type_min_max of
                    true ->
                        [{AttrId, AttrVal} | Acc];
                    _ ->
                        Acc
                end
            end,
            [],
            SaveList
        ),
    AttrList.

%% 筛选出附魔时添加的buffId列表
get_equip_fumo_cfg_buff_id_list(0) ->[];
get_equip_fumo_cfg_buff_id_list(FumoId) ->
    BuffIdList =
    lists:foldl(fun(BufMes, Acc) ->
        case BufMes of
            {?equip_fumo_cfg_type_buff, BuffId} ->
                [BuffId | Acc];
            _ ->
                Acc
        end
    end,
    [],
    get_equip_fumo_buff_id(FumoId)),
    BuffIdList.


%% 根据bid判断装备是否是套装(根据套装的品质)
is_suit_by_bid(EquipBid) ->
    case lookup_equip_org_cfg(EquipBid) of
        #equip_org_cfg{quality = Qua} ->
            Qua >= ?equip_suit_quality;
        _ ->
            false
    end.

%% equip_part_qiang_hua.txt id的生成规则
get_part_qiang_hua_id(RoleId, PartType, QHLevel) ->
    RoleId*10000000 + (100+PartType)*1000 + QHLevel.

get_part_qiang_hua_attr(RoleId, Type, Level) ->
    Id = get_part_qiang_hua_id(RoleId, Type, Level),
    case lookup_equip_part_qiang_hua_cfg(Id) of
        #equip_part_qiang_hua_cfg{attr = Attr} ->
            Attr;
        _ ->
            {error, unknown_type}
    end.

get_part_qiang_hua_extra_attr(RoleId, Type, Level) ->
    Id = get_part_qiang_hua_id(RoleId, Type, Level),
    case lookup_equip_part_qiang_hua_cfg(Id) of
        #equip_part_qiang_hua_cfg{extra_attr = ExAttr} ->
            ExAttr;
        _ ->
            {error, unknown_type}
    end.

get_failed_down(RoleId, Type, Level) ->
    Id = get_part_qiang_hua_id(RoleId, Type, Level),
    case lookup_equip_part_qiang_hua_cfg(Id) of
        #equip_part_qiang_hua_cfg{failed_down = DownList} ->
            DownList;
        _ ->
            {error, unknown_type}
    end.

get_part_qiang_hua_cost(RoleId, Type, Level) ->
    Id = get_part_qiang_hua_id(RoleId, Type, Level),
    case lookup_equip_part_qiang_hua_cfg(Id) of
        #equip_part_qiang_hua_cfg{cost = Cost} ->
            Cost;
        _ ->
            ?INFO_LOG("not find mes ~p, Id:~p", [{RoleId, Type, Level}, Id]),
            1
    end.

%% 获取强化的属性，根据角色，部位，等级
get_part_qh_all_attr(_Role, _PartType, 0) -> #attr{};
get_part_qh_all_attr(Role, PartType, Level) ->
    Id = get_part_qiang_hua_id(Role, PartType, Level),
    case lookup_equip_part_qiang_hua_cfg(Id) of
        #equip_part_qiang_hua_cfg{attr = Attr, extra_attr = ExAttr} ->
            Attr1 = attr_new:get_attr_by_id(Attr),
            Attr2 =
                case is_integer(ExAttr) of
                    true ->
                        attr_new:get_attr_by_id(ExAttr);
                    _ ->
                        #attr{}
                end,
            SAttr = attr_algorithm:add(Attr1, Attr2),
            SAttr;
        _ ->
%%            ?INFO_LOG("not find cfg  role:~p, partType:~p, Level:~p", [Role,PartType,Level]),
            #attr{}
    end.

%% 获取部位强化的特效列表
get_part_qianghua_effect(Role, PartType, Level) ->
    Bid = get_part_qiang_hua_id(Role, PartType, Level),
    case lookup_equip_part_qiang_hua_cfg(Bid) of
        #equip_part_qiang_hua_cfg{improve_effect = Effect} ->
            Effect;
        _ ->
            {error, unknown_type}
    end.

%% 强化至相应等级成功率百分比
can_part_qh_succeed(Level, Per) ->
    RandNum = ?random(100),
    Limit = 100 + math:log(Level)/math:log(0.92),
%%    ?INFO_LOG("RandNum = ~p, Level = ~p, Per = ~p, Limit = ~p", [RandNum, Level, Per, Limit]),
    RandNum =< Limit + Per.


%% 最大强化等级限制
part_qh_max_level(PlayerLevel) when PlayerLevel < 10 -> 10;
part_qh_max_level(PlayerLevel) ->
    10 + 10*(PlayerLevel div 10 - 1).


%% 根据千分比修改强化属性
change_attr_by_permill(Attr, PerMill) when is_record(Attr,attr) ->
    % {NewAttrList, _} =
    % lists:foldl(fun(X, {Acc, Count}) ->
    %     case Count =< 1 of
    %         true ->
    %             {[X | Acc], Count+1};
    %         _ ->
    %             {[round(X*(PerMill/1000)) | Acc], Count+1}
    %     end
    % end,
    % {[], 0},
    % tuple_to_list(Attr)),
    % list_to_tuple(lists:reverse(NewAttrList)).
    Ratio = PerMill / 1000,
    lists:foldl(fun(Index, Tuple) ->
        setelement(Index, Tuple, round(element(Index, Tuple) * Ratio))
    end,
    Attr,
    lists:seq(2, tuple_size(Attr))).

