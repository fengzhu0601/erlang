%%%-------------------------------------------------------------------
%%% @author hank
%%% @copyright (C) 2016, <SANTI>
%%% @doc
%%%
%%% @end
%%% Created : 07. Apr 2016 3:47 PM
%%%-------------------------------------------------------------------
-module(agent_util).
-author("hank").

%% API
-export([
    add_attrs/2,
    sub_attrs/2,
    add_attrs_pre/2,
    sub_attrs_pre/2
]).

-define(cfg_attr_key_dt, 8).

-include("inc.hrl").
-include("buff_system.hrl").
-include("load_spirit_attr.hrl").

%-spec add_attrs/2 :: (_,_) -> attr.
add_attrs(OAttr, AttrList) ->
    set_attr(OAttr, 1, attr_new:list_2_attr(AttrList)).

sub_attrs(OAttr, AttrList) ->
    set_attr(OAttr, -1, attr_new:list_2_attr(AttrList)).

add_attrs_pre(OAttr, AttrList) ->
    {Attr, ChangeData} = list_2_attr_pre(OAttr, AttrList),
    {set_attr(OAttr, 1, Attr), ChangeData}.

sub_attrs_pre(OAttr, AttrList) ->
    {Attr, _ChangeData} = list_2_attr_pre(OAttr, AttrList),
    set_attr(OAttr, -1, Attr).

% 千分比
list_2_attr_pre(OAttr, FieldList) ->
    SumAttr = lists:foldl(
        fun({CfgKey, Val}, {Acc, ChangeData}) ->
                AttrKey = CfgKey - ?cfg_attr_key_dt,
                OldVal = element(AttrKey, Acc),
                AttrVal = element(AttrKey, OAttr),
                AddValue = if
                    CfgKey =:= 26 ->    % 伤害加深
                        (1 * Val / 1000);
                    CfgKey =:= 27 ->    % 伤害减免
                        (1 * Val / 1000);
                    true -> trunc(AttrVal * Val / 1000)
                end,
                NValue = (OldVal + AddValue),
                NewList = util:lists_set_ex(util:get_pd_field(?pd_agent_attrs_sync, []), AttrKey, NValue),
                put(?pd_agent_attrs_sync, NewList),
                {setelement(AttrKey, Acc, NValue), ChangeData ++ [{CfgKey, AddValue}]}
        end,
        {#attr{}, []},
        FieldList
    ),
    % ?INFO_LOG("list_2_attr_pre ~p ~p", [FieldList, SumAttr]),
    SumAttr.


set_attr(OAttr, Inter, Attr) ->
    %%Attr已经包含计算过的二级属性，当设置一级属性时，二级属性已经被加进去了
%%     ?INFO_LOG("set_attr ~p",[{Inter, Attr}]),
    OAttr#attr{
        hp = max(0, OAttr#attr.hp + Inter * Attr#attr.hp),
        mp = max(0, OAttr#attr.mp + Inter * Attr#attr.mp),
        sp = max(0, OAttr#attr.sp + Inter * Attr#attr.sp),
        np = max(0, OAttr#attr.np + Inter * Attr#attr.np),
        strength = max(0, OAttr#attr.strength + Inter * Attr#attr.strength),
        intellect = max(0, OAttr#attr.intellect + Inter * Attr#attr.intellect),
        nimble = max(0, OAttr#attr.nimble + Inter * Attr#attr.nimble),
        strong = max(0, OAttr#attr.strong + Inter * Attr#attr.strong),
        atk = max(0, OAttr#attr.atk + Inter * Attr#attr.atk),
        def = max(0, OAttr#attr.def + Inter * Attr#attr.def),
        crit = max(0, OAttr#attr.crit + Inter * Attr#attr.crit),
        block = max(0, OAttr#attr.block + Inter * Attr#attr.block),
        pliable = max(0, OAttr#attr.pliable + Inter * Attr#attr.pliable),
        pure_atk = max(0, OAttr#attr.pure_atk + Inter * Attr#attr.pure_atk),
        break_def = max(0, OAttr#attr.break_def + Inter * Attr#attr.break_def),
        atk_deep = max(0, OAttr#attr.atk_deep + Inter * Attr#attr.atk_deep),
        atk_free = max(0, OAttr#attr.atk_free + Inter * Attr#attr.atk_free),
        atk_speed = max(0, OAttr#attr.atk_speed + Inter * Attr#attr.atk_speed),
        precise = max(0, OAttr#attr.precise + Inter * Attr#attr.precise),
        thunder_atk = max(0, OAttr#attr.thunder_atk + Inter * Attr#attr.thunder_atk),
        thunder_def = max(0, OAttr#attr.thunder_def + Inter * Attr#attr.thunder_def),
        fire_atk = max(0, OAttr#attr.fire_atk + Inter * Attr#attr.fire_atk),
        fire_def = max(0, OAttr#attr.fire_def + Inter * Attr#attr.fire_def),
        ice_atk = max(0, OAttr#attr.ice_atk + Inter * Attr#attr.ice_atk),
        ice_def = max(0, OAttr#attr.ice_def + Inter * Attr#attr.ice_def),
        move_speed = max(0, OAttr#attr.move_speed + Inter * Attr#attr.move_speed),
        run_speed = max(0, OAttr#attr.run_speed + Inter * Attr#attr.run_speed),
        suck_blood = max(0, OAttr#attr.suck_blood + Inter * Attr#attr.suck_blood),
        reverse = max(0, OAttr#attr.reverse + Inter * Attr#attr.reverse)
    }.


