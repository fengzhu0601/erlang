%%% @doc 配置加载和相关的纯操作
-module(attr).






-include("game.hrl").
-include("inc.hrl").
-include("load_spirit_attr.hrl").

-compile({no_auto_import, [get/2]}).

%% API
-export([
    get_attr_value_by_sats/2,
    sat_2_field_index/1,
    field_index_2_sat/1,
    new/0,
    get_attr/1,
    get_base_attr/1,
    add/2,
    add_amend/2,
    add/3,
    add_by_sat/3,
    add_by_sats/2,
    add_attrs/2,
    add_attrs_amend/2,

    sub/2,
    sub_amend/2,
    sub/3,
    sub_by_sat/3,
    sub_by_sats/2,
    sub_attrs/2,
    sub_attrs_amend/2,
    ratio/2,
    secondary/1,
    amend/1,

    random_sats/1,
    attr_2_sats/1,
    sats_2_attr/1,

    get_combat_power/1
]).

%% @doc 在随机属性中随机
-spec random_sats(_) -> ?none | [sat()].
random_sats(RandomAttrCfgId) ->
    case load_spirit_attr:lookup_random_sats_cfg(RandomAttrCfgId) of
        ?none -> ?none;
        #random_sats_cfg{min_num = MinN, max_num = MaxN, sats = Sats} ->
            {OutL, DropL} =
                lists:foldl(fun({Id, Probo, B, E}, {Out, Drop}) ->
                    ROut = ?random(1000),
                    if ROut =< Probo ->
                        {[{Id, com_util:random(B, E)} | Out], Drop};
                        ?true ->
                            {Out, [{Id, com_util:random(B, E)} | Drop]}
                    end
                end, {[], []}, Sats),

            OutLen = length(OutL),
            if OutLen - MinN < 0 ->
                lists:sublist(DropL, MinN - OutLen) ++ OutL;
                OutLen - MaxN > 0 ->
                    lists:sublist(OutL, OutLen - MaxN);
                ?true -> OutL
            end
    end.




%% 得到战斗力
get_combat_power(Attr) ->
    #attr{
        block = Blo
        , precise = Pre
        , crit = Crit
        , pliable = Pli
        , atk = Atk
        , def = Def
        , atk_speed = AtkS
        , hp = Hp
    } = Attr,
    %}= amend(Attr),
    ?debug_log_player("Blo ~w, Pre ~w, Crit ~w, Pli ~w, Atk ~w, Def ~w, AtkS ~w, Hp ~w",
        [Blo, Pre, Crit, Pli, Atk, Def, AtkS, Hp]),
    round(Blo * 3 + Pre * 3 + Crit * 1.5 + Pli * 1.5 + Atk + Def * 2 + AtkS * 5 + Hp).

%%L = Attr#attr.strength,
%%Z = Attr#attr.intellect,
%%M = Attr#attr.nimble,
%%T = Attr#attr.strong,

%%round(Attr#attr.block * 3 +
%%Attr#attr.precise * 3 +
%%(Attr#attr.crit + M*3) * 1.5 +
%%Attr#attr.pliable  * 1.5 +
%%(Attr#attr.atk + M * 2) +
%%(Attr#attr.def + M * 2 + L*5) * 2 +
%%Attr#attr.atk_speed +
%%Attr#attr.hp + L + T * 15).



sat_2_field_index(Sat) ->
    Sat - 8.
field_index_2_sat(FieldIndex) ->
    FieldIndex + 9.
-spec new() -> #attr{}.
%% get new attr
new() ->
    #attr{}.

%% @doc 属性List 换行到attr recrod.
-spec sats_2_attr(_) -> #attr{}.
sats_2_attr(SatList) ->
    add_by_sats(SatList, attr:new()).




%% 属性结构转化属性list
attr_2_sats(Attr = #attr{}) ->
    com_record:foldl_index(
        fun(Index, E, TmpAcc) ->
            case E > 0 of
                ?true ->
                    Sat = field_index_2_sat(Index - 1),
                    [{Sat, E} | TmpAcc];
                _ ->
                    TmpAcc
            end
        end,
        [],
        Attr,
        3).


add(AttrListL, AttrListR)
    when is_list(AttrListL),
    is_list(AttrListR) ->
    com_lists:t2_merage(fun(V1, V2) -> V1 + V2 end,
        AttrListL,
        AttrListR);
add(CfgId, Spirit) when is_integer(CfgId) ->
    case load_spirit_attr:lookup_attr(CfgId) of
        ?none ->
            ?ERROR_LOG("can not find sprite ~p", [CfgId]),
            Spirit;
        AddSpirit ->
            com_record:merge(fun(A, B) -> A + B end,
                Spirit,
                AddSpirit)
    end;
add(Attr1, Attr2) ->
    com_record:merge(fun(A, B) -> A + B end,
        Attr1,
        Attr2).
%% 先修正要添加的属性，然后再添加，Attr只能为AttrId或者#attr{}
-spec add_amend(#attr{}, #attr{}) -> #attr{}.
add_amend(Attr, Spirit) ->
    AttrAMend = amend(Attr),
    add(AttrAMend, Spirit).
%% 添加多个属性
-spec add_attrs([#attr{}], #attr{}) -> #attr{}.
add_attrs([], Spirit) -> Spirit;
add_attrs([Attr | Attrs], Spirit) ->
    NSpirit = add(Attr, Spirit),
    add_attrs(Attrs, NSpirit).

%% 先修要添加的属性，然后添加多个属性
-spec add_attrs_amend([#attr{}], #attr{}) -> #attr{}.
add_attrs_amend([], Spirit) -> Spirit;
add_attrs_amend([Attr | Attrs], Spirit) ->
    NSpirit = add_amend(Attr, Spirit),
    add_attrs_amend(Attrs, NSpirit).

add(FieldIndex, AddV, Spirit) ->
    FieldIndexV = erlang:element(FieldIndex, Spirit),
    erlang:setelement(FieldIndex, Spirit, FieldIndexV + AddV).

%% 添加属性列表到属性结构
-spec add_by_sats(list(), #attr{}) -> #attr{}.
add_by_sats([], Spirit) -> Spirit;
add_by_sats([{Sat, AddV} | AttrL], Spirit) ->
    NSpirit = add_by_sat(Sat, AddV, Spirit),
    add_by_sats(AttrL, NSpirit).

-spec add_by_sat(sat(), non_neg_integer(), #attr{}) -> #attr{}.
add_by_sat(Sat, AddV, Spirit) ->
    add(sat_2_field_index(Sat), AddV, Spirit).

sub(AttrListL, AttrListR)
    when is_list(AttrListL),
    is_list(AttrListR) ->
    com_lists:t2_merage(fun(V1, V2) -> V1 - V2 end,
        AttrListL,
        AttrListR);
sub(CfgId, Spirit) when is_integer(CfgId) ->
    case load_spirit_attr:lookup_attr(CfgId) of
        ?none ->
            ?ERROR_LOG("can not find sprite ~p", [CfgId]),
            Spirit;
        DelSpirit ->
            com_record:merge(fun(A, B) -> erlang:max(0, A - B) end,
                Spirit,
                DelSpirit)
    end;
sub(Attr1, Attr2) ->
    com_record:merge(fun(A, B) -> erlang:max(0, A - B) end,
        Attr1,
        Attr2).

%% 先修正要删除属性，然后再删除，Attr只能为AttrId或者#attr{}
-spec sub_amend(#attr{}, #attr{}) -> #attr{}.
sub_amend(Attr, Spirit) ->
    AttrAMend = amend(Attr),
    sub(Spirit, AttrAMend).

%% 减少属性列表到属性结构
-spec sub_by_sats(list(), #attr{}) -> #attr{}.
sub_by_sats([], Spirit) -> Spirit;
sub_by_sats([{Sat, SubV} | AttrL], Spirit) ->
    NSpirit = sub_by_sat(Sat, SubV, Spirit),
    sub_by_sats(AttrL, NSpirit).

%% 删除多个属性
-spec sub_attrs([#attr{}], #attr{}) -> #attr{}.
sub_attrs([], Spirit) -> Spirit;
sub_attrs([Attr | Attrs], Spirit) ->
    NSpirit = sub(Spirit, Attr),
    sub_attrs(Attrs, NSpirit).

%% 先修要删除的属性，然后删除多个属性
-spec sub_attrs_amend([#attr{}], #attr{}) -> #attr{}.
sub_attrs_amend([], Spirit) -> Spirit;
sub_attrs_amend([Attr | Attrs], Spirit) ->
    NSpirit = sub_amend(Attr, Spirit),
    sub_attrs_amend(Attrs, NSpirit).

sub(FieldIndex, DelV, Spirit) ->
    FieldIndexV = erlang:element(FieldIndex, Spirit),
    erlang:setelement(FieldIndex, Spirit, erlang:max(0, FieldIndexV - DelV)).

-spec sub_by_sat(sat(), non_neg_integer(), #attr{}) -> #attr{}.
sub_by_sat(Sat, AddV, Spirit) ->
    sub(sat_2_field_index(Sat), AddV, Spirit).


%%del_if_enough(SpiritType, DelValue, Spirit) when DelValue >= 0 ->
%%FieldIndexV = erlang:element(SpiritType, Spirit),
%%if FieldIndexV < DelValue ->
%%?not_enough;
%%true ->
%%erlang:setelement(SpiritType, Spirit, FieldIndexV - DelValue)
%%end.


ratio(Ratio, Attr) ->
    lists:foldl(fun(Index, Tuple) ->
        setelement(Index, Tuple, com_util:ceil(element(Index, Tuple) * Ratio))
    end,
    Attr,
    lists:seq(2, tuple_size(Attr))).

%% 只拿二级属性
secondary(Attr) ->
    #attr
    {
        atk = Attr#attr.atk,
        def = Attr#attr.def,
        crit = Attr#attr.crit,
        block = Attr#attr.block,
        pliable = Attr#attr.pliable,
        pure_atk = Attr#attr.pure_atk,
        break_def = Attr#attr.break_def,
        atk_deep = Attr#attr.atk_deep,
        atk_free = Attr#attr.atk_free,
        atk_speed = Attr#attr.atk_speed,
        precise = Attr#attr.precise
    }.

%% @doc 二级属性修正
amend(CfgId) when is_integer(CfgId) ->
    case load_spirit_attr:lookup_attr(CfgId) of
        ?none -> ?err(none_cfg);
        Attr -> amend(Attr)
    end;
amend(Attr = #attr{strength = _Str, def = _Def, intellect = _Int, nimble = _Ni, mp = _Mp, strong = _Sto, atk = _Atk, hp = _Hp, crit = _Crit}) ->
%%     Attr#attr{atk = Atk + Str * 5 + Ni * 2,
%%         hp = Hp + Str + Sto * 15,
%%         mp = Mp + Int,
%%         crit = Crit + Ni * 3,
%%         def = Def + Sto * 2
%%     };
    %% 二级属性不在这里加了
    Attr;
amend(_Attr) ->
    ?debug_log_equip("---------error Attr~w", [_Attr]),
    #attr{}.
%% get attr record
get_attr(CfgId) ->
    #attr{} = amend(CfgId).
get_base_attr(CfgId) ->
    case load_spirit_attr:lookup_attr(CfgId) of
        ?none -> ?err(none_cfg);
        Attr -> Attr
    end.

get_attr_value_by_sats(Sat, Spirit) ->
    erlang:element(sat_2_field_index(Sat), Spirit).
