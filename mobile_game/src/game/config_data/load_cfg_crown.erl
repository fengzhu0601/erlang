%%%-------------------------------------------------------------------
%%% @author fengzhu
%%% @copyright (C) 2016, <COMPANY>
%%% @doc 皇冠
%%%
%%% @end
%%% Created : 04. 一月 2016 下午3:11
%%%-------------------------------------------------------------------
-module(load_cfg_crown).
-author("fengzhu").

%% API
-export([
    is_anger_skill/1
]).

-export([
    get_skill_open_level/1,
    get_open_crown_before/1,
    get_crown_skill_type/1
]).

-export([
    get_skill_activate_cost_id/2,
    get_skill_id/2,
    get_crown_skill_modify_id/2
]).

-include_lib("config/include/config.hrl").
-include("inc.hrl").
-include("load_cfg_crown.hrl").

load_config_meta() ->
    [
        #config_meta{record = #crown_gem_cfg{},         %% 宝石部分重新设置皇冠技能之后暂且用不到
            fields = ?record_fields(crown_gem_cfg),
            file = "crown_gem.txt",
            keypos = #crown_gem_cfg.bid,
            verify = fun verify_gem/1},

        #config_meta{record = #crown_main_cfg{},
            fields = ?record_fields(crown_main_cfg),
            file = "crown_main.txt",
            keypos = #crown_main_cfg.id,
            verify = fun verify_main/1},

        #config_meta{record = #crown_skill_cfg{},
            fields = ?record_fields(crown_skill_cfg),
            file = "crown_skill.txt",
%%            keypos = #crown_skill_cfg.id,
            keypos = [#crown_skill_cfg.crown_skill_id, #crown_skill_cfg.level],
            all = [#crown_skill_cfg.skill_id],
            verify = fun verify_skill/1}
    ].

verify_main(#crown_main_cfg{open_crown_before = OpenCrownBefore}) ->
    ?check(is_list(OpenCrownBefore), "crown_main.txt open_crown_before[~w] 无效! ", [OpenCrownBefore]).

verify_skill(#crown_skill_cfg{id = Id, skill_id = SkillId, skill_modify_id = ModId, cost = CostID}) ->
    case ModId =/= ?undefined andalso ModId =/= 0 of
        true ->
            ?check(load_cfg_skill:is_exist_skill_modify_cfg(ModId), "skill_modify.txt [~p] skill_modify_id:~p 没有找到", [Id, ModId]);
        _ -> pass
    end,
    case SkillId =/= ?undefined andalso SkillId =/= 0 of
        true ->
            ?check(load_cfg_skill:is_exist_skill_cfg(SkillId), "crown_skill.txt [~p] skill_id:~p 没有找到", [Id, SkillId]);
        _ ->
            pass
    end,
    case CostID =/= ?undefined andalso CostID =/= 0 of
        true ->
            ?check(cost:is_exist_cost_cfg(CostID), "cost.txt [~p] cost: ~p 没有找到", [Id, CostID]);
        _ ->
            pass
    end,
    ok.

%% 获取皇冠技能的开启等级
get_skill_open_level(SkillId) ->
    case lookup_crown_main_cfg(SkillId) of
        #crown_main_cfg{open_level = Level} ->
            Level;
        _ ->
          ret:error(unknown_type)
    end.

get_open_crown_before(SkillId) ->
    case lookup_crown_main_cfg(SkillId) of
        #crown_main_cfg{open_crown_before = OpenCrownBefore} ->
            OpenCrownBefore;
        _ ->
            ret:error(unknown_type)
    end.

%% get_open_crown_all_before(SkillId) ->
%%     case lookup_crown_main_cfg(SkillId) of
%%         #crown_main_cfg{open_crown_all_before = Count} ->
%%             Count;
%%         _ ->
%%             ret:error(unknown_type)
%%     end.
%%
%% get_open_crown_before_class(SkillId) ->
%%     case lookup_crown_main_cfg(SkillId) of
%%         #crown_main_cfg{open_crown_before_class = Count} ->
%%             Count;
%%         _ ->
%%             ret:error(unknown_type)
%%     end.
%%
%% get_crown_skill_class(SkillId) ->
%%     case lookup_crown_main_cfg(SkillId) of
%%         #crown_main_cfg{class = Class} ->
%%             Class;
%%         _ ->
%%             ret:error(unknown_type)
%%     end.

%% 获取皇冠技能的类型（1 主动，2 被动，3 选择性被动（皇冠之星））
get_crown_skill_type(SkillId) ->
    case lookup_crown_main_cfg(SkillId) of
        #crown_main_cfg{skill_type = SkillType} ->
            SkillType;
        _ ->
            ret:error(unknown_type)
    end.

%% %% 获取皇冠的类型
%% get_crown_type(SkillId) ->
%%     case lookup_crown_main_cfg(SkillId) of
%%         #crown_main_cfg{crown_type = Type} ->
%%             Type;
%%         _ ->
%%             ret:error(unknown_type)
%%     end.


%% 获取技能的激活消耗id
get_skill_activate_cost_id(CrownSkillId, Level) ->
    case lookup_crown_skill_cfg({CrownSkillId, Level}) of
        #crown_skill_cfg{cost = CostId} ->
            CostId;
        _ ->
            ret:error(unknown_type)
    end.

%% 获取技能表的技能id
get_skill_id(CrownSkillId, Level) ->
    case lookup_crown_skill_cfg({CrownSkillId, Level}) of
        #crown_skill_cfg{skill_id = SkillId} ->
            SkillId;
        _ ->
            ret:error(unknown_type)
    end.

%% 获取皇冠技能的技能修改集的id
get_crown_skill_modify_id(CrownSkillId, Level) ->
    case lookup_crown_skill_cfg({CrownSkillId, Level}) of
        #crown_skill_cfg{skill_modify_id = ModifyId} ->
            ModifyId;
        _ ->
            ret:error(unknown_type)
    end.

verify_gem(#crown_gem_cfg{type = Type, level = Lvl,
    upgrade_cost = Cost,
    sell_fragment = Sell,
    enchant_sats = RandomSats,
    enchant_cost = EnchantCost,
    attr_id = AttrId}) ->
    ?check(cost:is_exist_cost_cfg(Cost), "~s type:~p level:~p upgrade_cost~p 没有找到> 0", [?CROWN_CFG_FILE, Type, Lvl, Cost]),
    ?check(cost:is_exist_cost_cfg(EnchantCost), "~s type:~p level:~p enchanCost ~p 没有找到> 0", [?CROWN_CFG_FILE, Type, Lvl, EnchantCost]),
    ?check(load_spirit_attr:is_exist_attr(AttrId), "~s type:~p level:~p attr_id ~p 没有找到> 0", [?CROWN_CFG_FILE, Type, Lvl, AttrId]),
    ?check(?is_pos_integer(Sell), "~s type:~p level:~p sell_fragment ~p 无效> 0", [?CROWN_CFG_FILE, Type, Lvl, Sell]),
    ?check(?is_pos_integer(Type), "~s type:~p level:~p type ~p 无效> 0", [?CROWN_CFG_FILE, Type, Lvl, Type]),
    ?check(?is_pos_integer(Lvl), "~s type:~p level:~p type ~p 无效> 0", [?CROWN_CFG_FILE, Type, Lvl, Lvl]),
    ?check(load_spirit_attr:is_exist_random_sats_cfg(RandomSats), "~s type:~p level:~p enchant_sats ~p 没有找到", [?CROWN_CFG_FILE, Type, Lvl, RandomSats]),
    ok.

is_anger_skill(SkillID) ->
%%   ?INFO_LOG("is_ anger skill:~p",[SkillID]),
%%   ?INFO_LOG("lookup_crown_skill_cfg:~p",[lookup_all_crown_skill_cfg(#crown_skill_cfg.skill_id)]),
     lists:member(SkillID, lookup_all_crown_skill_cfg(#crown_skill_cfg.skill_id)).