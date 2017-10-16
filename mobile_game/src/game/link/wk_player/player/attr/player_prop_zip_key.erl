%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%% 发给前端时用于压缩数据的索引
%%% @end
%%% Created : 22. 八月 2015 下午5:05
%%%-------------------------------------------------------------------
-module(player_prop_zip_key).
-author("clark").

%% API
-export(
[
    get_zip_keys_data/2
    , get_zip_keys_data/3
    , get_zip_keys_data_ex/2
    , get_final_ret/1
]).

-include("inc.hrl").
-include("player.hrl").



%% 00 =
%% [
%%     MONEY           =   1,      %% 金钱
%%     DIAMOND         =   2,      %% 钻石
%%     DRAGON_SOULS    =   3,      %% 龙纹
%%     LEVEL           =   4,      %% 等级
%%     EXP             =   5,      %% 经验
%%     HP              =   6,      %% 当前血量
%%     DRAGON_SPIRITS  =   7,      %% 精魄 pd_fragment (特别处理)
%%     HONOUR          =   8,      %% 荣耀
%%     COMBAT_POWER    =   9,      %% 战斗力
%%     HEAL_COUNT      =   10,     %% 已加血次数
%%     HEAL_TIME       =   11,     %% 最近一次加血时间
%%     DEAD_COUNT      =   12,     %% 已复活次数
%%     FRAGMENT        =   13,     %% 碎片
%%     SP              =   14,     %% 当前体力
%%     SP_COUNT        =   15,      %% 每天体力已购买次数
%%     JINXING         =   16,
%%     YINXING         =   17
%% ]
%% 01 =
%% [
%%     MAX_HP          =   1,      %% max_hp
%%     MAX_MP          =   2,      %% max_mp
%%     MAX_SP          =   3,      %% max_体力
%%     MAX_NP          =   4,      %% max_能量
%%     STRENGTH        =   5,      %% 力量
%%     INTELLECT       =   6,      %% 智力
%%     NIMBLE          =   7,      %% 敏捷
%%     STRONG          =   8,      %% 体质
%%     ATK             =   9,      %% 攻击
%%     DEF             =   10,     %% 防御
%%     CRIT            =   11,     %% 暴击等级
%%     BLOCK           =   12,     %% 格挡
%%     PLIABLE         =   13,     %% 柔韧
%%     PURE_ATK        =   14,     %% 无视防御伤害
%%     BREAK_DEF       =   15,     %% 破甲
%%     ATK_DEEP        =   16,     %% 伤害加深
%%     ATK_FREE        =   17,     %% 伤害减免
%%     ATK_SPEED       =   18,     %% 攻击速度
%%     PRECISE         =   19,     %% 精确
%%     THUNDER_ATK     =   20,     %% 雷攻
%%     THUNDER_DEF     =   21,     %% 雷防
%%     FIRE_ATK        =   22,     %% 火攻
%%     FIRE_DEF        =   23,     %% 火防
%%     ICE_ATK         =   24,     %% 冰攻
%%     ICE_DEF         =   25,     %% 冰防
%%     MOVE_SPEED      =   26,     %% 移动速度
%%     RUN_SPEED       =   27,     %% 跑步速度
%%     SUCK_BLOOD      =   28,     %% 吸血
%%     REVERSE         =   29,     %% 反伤
%% ]


%% 00
get_zip_key(?pd_money) -> ret:data2(0, 2 + 1);
get_zip_key(?pd_diamond) -> ret:data2(0, 2 + 2);
get_zip_key(?pd_fragment) -> ret:data2(0, 2 + 3);
get_zip_key(?pd_level) -> ret:data2(0, 2 + 4);
get_zip_key(?pd_exp) -> ret:data2(0, 2 + 5);
get_zip_key(?pd_hp) -> ret:data2(0, 2 + 6);
get_zip_key(?pd_longwens) -> ret:data2(0, 2 + 7); %%
get_zip_key(?pd_honour) -> ret:data2(0, 2 + 8);
get_zip_key(?pd_combat_power) -> ret:data2(0, 2 + 9);
get_zip_key(?pd_attr_add_hp_times) -> ret:data2(0, 2 + 10);
get_zip_key(?pd_attr_add_hp_mp_cd) -> ret:data2(0, 2 + 11);
get_zip_key(?pd_attr_relive_times) -> ret:data2(0, 2 + 12);
get_zip_key(?pd_sp) -> ret:data2(0, 2 + 14);
get_zip_key(?pd_sp_buy_count) -> ret:data2(0, 2 + 15);
get_zip_key(?pd_main_ins_jinxing) ->ret:data2(0, 2+16);
get_zip_key(?pd_main_ins_yinxing) ->ret:data2(0, 2+17);
get_zip_key(?pd_crown_yuansu_moli) ->ret:data2(0, 2+18);
get_zip_key(?pd_crown_guangan_moli) ->ret:data2(0, 2+19);
get_zip_key(?pd_crown_mingyun_moli) ->ret:data2(0, 2+20);
%% 01
get_zip_key(?pd_attr_max_hp) -> ret:data2(1, 1 + 1);
get_zip_key(?pd_attr_max_mp) -> ret:data2(1, 1 + 2);
get_zip_key(?pd_attr_max_sp) -> ret:data2(1, 1 + 3);
get_zip_key(?pd_attr_max_np) -> ret:data2(1, 1 + 4);
get_zip_key(?pd_attr_strength) -> ret:data2(1, 1 + 5);
get_zip_key(?pd_attr_intellect) -> ret:data2(1, 1 + 6);
get_zip_key(?pd_attr_nimble) -> ret:data2(1, 1 + 7);
get_zip_key(?pd_attr_strong) -> ret:data2(1, 1 + 8);
get_zip_key(?pd_attr_atk) -> ret:data2(1, 1 + 9);
get_zip_key(?pd_attr_def) -> ret:data2(1, 1 + 10);
get_zip_key(?pd_attr_crit) -> ret:data2(1, 1 + 11);
get_zip_key(?pd_attr_block) -> ret:data2(1, 1 + 12);
get_zip_key(?pd_attr_pliable) -> ret:data2(1, 1 + 13);
get_zip_key(?pd_attr_pure_atk) -> ret:data2(1, 1 + 14);
get_zip_key(?pd_attr_break_def) -> ret:data2(1, 1 + 15);
get_zip_key(?pd_attr_atk_deep) -> ret:data2(1, 1 + 16);
get_zip_key(?pd_attr_atk_free) -> ret:data2(1, 1 + 17);
get_zip_key(?pd_attr_atk_speed) -> ret:data2(1, 1 + 18);
get_zip_key(?pd_attr_precise) -> ret:data2(1, 1 + 19);
get_zip_key(?pd_attr_thunder_atk) -> ret:data2(1, 1 + 20);
get_zip_key(?pd_attr_thunder_def) -> ret:data2(1, 1 + 21);
get_zip_key(?pd_attr_fire_atk) -> ret:data2(1, 1 + 22);
get_zip_key(?pd_attr_fire_def) -> ret:data2(1, 1 + 23);
get_zip_key(?pd_attr_ice_atk) -> ret:data2(1, 1 + 24);
get_zip_key(?pd_attr_ice_def) -> ret:data2(1, 1 + 25);
get_zip_key(?pd_attr_move_speed) -> ret:data2(1, 1 + 26);
get_zip_key(?pd_attr_run_speed) -> ret:data2(1, 1 + 27);
get_zip_key(?pd_attr_suck_blood) -> ret:data2(1, 1 + 28);
get_zip_key(?pd_attr_reverse) -> ret:data2(1, 1 + 29);
%% other
get_zip_key(_ServerKey) -> ret:error(unknown).


get_zip_keys_data(Key, Val) -> 
    get_zip_keys_data(#zip_keys_data{}, Key, Val).
get_zip_keys_data(Root = #zip_keys_data{}, Key, Val) ->
    case get_zip_key(Key) of
        {error, _Error} ->
            Root;
        {TableID, KeyOfVal} ->
            case TableID of
                0 ->
                    NewKeyData = util:set_binary(Root#zip_keys_data.keys_00, {KeyOfVal, 1}, 1),
                    NewValList = [{KeyOfVal, Val} | Root#zip_keys_data.vals_00],
                    Root1 = setelement(#zip_keys_data.keys_00, Root, NewKeyData),
                    setelement(#zip_keys_data.vals_00, Root1, NewValList);
                1 ->
                    NewKeyData = util:set_binary(Root#zip_keys_data.keys_01, {KeyOfVal, 1}, 1),
                    NewValList = [{KeyOfVal, Val} | Root#zip_keys_data.vals_01],
                    Root1 = setelement(#zip_keys_data.keys_01, Root, NewKeyData),
                    setelement(#zip_keys_data.vals_01, Root1, NewValList);
                _ ->
                    Root
            end;
        _ ->
            Root
    end.


get_zip_keys_data_ex(Root = #zip_keys_data{}, []) -> 
    Root;
get_zip_keys_data_ex(Root = #zip_keys_data{}, [{Key, Val} | TailList]) ->
    NewRoot = get_zip_keys_data(Root, Key, Val),
    get_zip_keys_data_ex(NewRoot, TailList).


get_list(RetList, _ValList, _Max, _Max) -> 
    RetList;
get_list(RetList, ValList, I, Max) ->
    case lists:keyfind(I, 1, ValList) of
        false -> 
            get_list(RetList, ValList, I + 1, Max);
        {_ID, Val} -> 
            get_list([Val | RetList], ValList, I + 1, Max);
        _ -> 
            get_list(RetList, ValList, I + 1, Max)
    end.


get_final_ret(Root) ->
    <<IDs1:32>> = Root#zip_keys_data.keys_00,
    <<IDs2:32>> = Root#zip_keys_data.keys_01,
    List1 = get_list([], Root#zip_keys_data.vals_00, 1, 33),
    List2 = get_list([], Root#zip_keys_data.vals_01, 1, 33),
    Data =
        {[
            {IDs1, lists:reverse(List1)},
            {IDs2, lists:reverse(List2)}
        ]},
    Data.