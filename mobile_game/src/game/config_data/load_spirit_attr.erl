%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 08. 七月 2015 上午11:49
%%%-------------------------------------------------------------------
-module(load_spirit_attr).
-author("clark").

%% API
-export
([
    print_attr/1
    , get_attr/1
]).

-include_lib("config/include/config.hrl").
-include("inc.hrl").
-include("load_spirit_attr.hrl").


load_config_meta() ->
    [
        #config_meta
        {
            record = #attr{},
            fields = ?record_fields(attr),
            file = "spirit_attr.txt",
            keypos = #attr.id,
            verify = fun verify/1
        },

        #config_meta
        {
            record = #random_sats_cfg{},
            fields = ?record_fields(random_sats_cfg),
            file = "random_sats_cfg.txt",
            keypos = #random_sats_cfg.id,
            rewrite = fun change/1,
            verify = fun verify_random/1
        }
    ].



verify(#attr{id = Id} = Attr) ->
    com_record:foreach(fun(V) ->
        ?check(is_integer(V) andalso V >= 0, "attr.txt [~p] 无效配置 V ~p >0", [Id, V])
    end,
        Attr),
    ok.


verify_random(#random_sats_cfg{id = Id, sats = Attrs}) ->
    lists:foreach(fun({AttrCode, _Probo, Min, Max}) ->
        ?check(game_def:is_valid_sat(AttrCode) andalso
            is_integer(Max) andalso
            is_integer(Min) andalso
            Min =< Max, "equip_output.txt [~p] 无效 jd_attr:(attrcode ~w, Min ~w, Max ~w)", [Id, AttrCode, Min, Max])
    end, Attrs),
    ok.



change(_) ->
    NewCfgList =
        ets:foldl(fun({_, #random_sats_cfg{id = Id, min_num = MinN, max_num = MaxN, sats = Attrs} = Cfg}, FAcc) ->
            {Tj, SJAs} = com_util:probo_build(Attrs),
            JdLen = length(Attrs),
            ?check(com_util:is_valid_uint_max(MinN, JdLen) andalso com_util:is_valid_uint_max(MaxN, JdLen)
                , "random_attr.txt [~p] attrs ~w 条数约束错误 ~p min_num~w, max_num~w", [Id, Attrs, JdLen, MinN, MaxN]),
            ?check(Tj == 100 orelse SJAs == [], "random_attr.txt [~p] attrs 权重和不为100 ~p", [Id, SJAs]),

            [Cfg#random_sats_cfg{sats = SJAs} | FAcc]
        end, [], random_sats_cfg),
    NewCfgList.


change() ->
    case
    [
        id,
        hp,
        mp,
        sp,
        np,
        strength,
        intellect,
        nimble,
        strong,
        atk,
        def,
        crit,
        block,
        pliable,
        pure_atk,
        break_def,
        atk_deep,
        atk_free,
        atk_speed,
        precise,
        thunder_atk,
        thunder_def,
        fire_atk,
        fire_def,
        ice_atk,
        ice_def,
        move_speed,
        run_speed % 跑步速度
    ] =:= record_info(fields, attr) of
        true -> ok;
        false ->
            ?ERROR_LOG("请同步 attr fields")
    end,
    ok.

print_attr(#attr{hp = _Hp, mp = _Mp, sp = _Sp, np = _Np, strength = _Str, intellect = _Int, nimble = _Ni
    , strong = _Stro, atk = _Atk, def = _Def, crit = _Crit, block = _Blo, pliable = _Pli, pure_atk = _PAtk, break_def = _BDef
    , atk_deep = _AtkD, atk_free = _AtkF, atk_speed = _AtkSp, precise = _Prec, thunder_atk = _TAtk, thunder_def = _TDef
    , fire_atk = _FAtk, fire_def = _FDef, ice_atk = _IAtk, ice_def = _IDef, move_speed = _MSp, run_speed = _RSp}) ->
    ?debug_log_attr("Attr Hp ~w, Mp ~w, 体力 ~w, 能量 ~w, 力量 ~w, 智力 ~w， 敏捷 ~w, 体质 ~w, atk ~w, def ~w, 暴击等级 ~w, 格铛 ~w, 柔韧 ~w, 无视防御伤害 ~w,"
    " 破甲 ~w, 伤害加深 ~w, 伤害减免 ~w, 攻击速度 ~w, 精准 ~w, 雷攻 ~w, 雷防 ~w, 火攻 ~w, 火防 ~w, 冰攻击 ~w, 冰防御 ~w, 移动速度 ~w, 跑步速度 ~w",
        [_Hp, _Mp, _Sp, _Np, _Str, _Int, _Ni, _Stro, _Atk, _Def, _Crit, _Blo, _Pli, _PAtk, _BDef, _AtkD, _AtkF, _AtkSp, _Prec, _TAtk,
            _TDef, _FAtk, _FDef, _IAtk, _IDef, _MSp, _RSp]).


get_attr(Id) ->
    case lookup_attr(Id) of
        #attr{} = Attr -> Attr;
        _ -> nil
    end.