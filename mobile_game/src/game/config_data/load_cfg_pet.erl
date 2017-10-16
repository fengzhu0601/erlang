%%%-------------------------------------------------------------------
%%% @author fengzhu
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 04. 一月 2016 下午4:19
%%%-------------------------------------------------------------------
-module(load_cfg_pet).
% -author("fengzhu").

% %% API
% -export([
%   find_egg_itembid/1
% ]).

% -include_lib("config/include/config.hrl").
% -include("inc.hrl").
% -include("load_cfg_pet.hrl").
% -include("load_item.hrl").

% load_config_meta() ->
%   [
%     #config_meta{record = #pet_cfg{},
%       fields = ?record_fields(pet_cfg),
%       file = "pet.txt",
%       keypos = #pet_cfg.id,
%       verify = fun verify_pet_cfg/1
%     },
%     #config_meta{record = #pet_level_cfg{},
%       fields = ?record_fields(pet_level_cfg),
%       file = "pet_level.txt",
%       keypos = [#pet_level_cfg.id, #pet_level_cfg.level],
%       verify = fun verify_pet_level_cfg/1
%     },
%     #config_meta{record = #pet_quality_ratio_cfg{},
%       fields = ?record_fields(pet_quality_ratio_cfg),
%       file = "pet_quality_ratio.txt",
%       keypos = #pet_quality_ratio_cfg.quality,
%       verify = fun verify_pet_quality_cfg/1
%     },
%     #config_meta{record = #pet_advance_cfg{},
%       fields = ?record_fields(pet_advance_cfg),
%       file = "pet_advance.txt",
%       keypos = [#pet_advance_cfg.pet_id, #pet_advance_cfg.level],
%       verify = fun verify_pet_advance_cfg/1
%     },
%     #config_meta{record = #pet_advance_prop_cfg{},
%       fields = ?record_fields(pet_advance_prop_cfg),
%       file = "pet_advance_prop.txt",
%       keypos = #pet_advance_prop_cfg.diff_value,
%       verify = fun verify_pet_advance_pro_cfg/1},

%     #config_meta{record = #pet_skill_level_cfg{},
%       fields = ?record_fields(pet_skill_level_cfg),
%       file = "pet_skill_level.txt",
%       keypos = #pet_skill_level_cfg.id,
%       verify = fun verify_pet_skill_level_cfg/1
%     },
%     #config_meta{record = #pet_treasure_cfg{},
%       fields = ?record_fields(pet_treasure_cfg),
%       file = "pet_treasure.txt",
%       keypos = #pet_treasure_cfg.id,
%       groups = [#pet_treasure_cfg.type],
%       verify = fun verify_pet_treasure_cfg/1
%     },
%     #config_meta{record = #pet_skill_pos_open_cfg{},
%       fields = ?record_fields(pet_skill_pos_open_cfg),
%       file = "pet_skill_pos_open.txt",
%       keypos = [#pet_skill_pos_open_cfg.type, #pet_skill_pos_open_cfg.pos],
%       verify = fun verify_pet_skill_pos_open_cfg/1
%     }
%   ].

% verify_pet_cfg(PetCfg) ->
%   ?check(length(PetCfg#pet_cfg.facade) > 0, "pet ~p not default facade", [PetCfg#pet_cfg.id]),
%   ?check(cost:is_exist_cost_cfg(PetCfg#pet_cfg.hatch_cost), "pet ~p hatch_cost error", [PetCfg#pet_cfg.id, PetCfg#pet_cfg.hatch_cost]),
%   ?check(cost:is_exist_cost_cfg(PetCfg#pet_cfg.seal_cost), "pet ~p seal_cost error", [PetCfg#pet_cfg.id, PetCfg#pet_cfg.seal_cost]),
%   ok.

% verify_pet_level_cfg(PetLevelCfg) ->
%   ?check(load_spirit_attr:is_exist_attr(PetLevelCfg#pet_level_cfg.attr), "pet_level_cfg id ~p attr ~p not exist in attr table",
%     [PetLevelCfg#pet_level_cfg.id, PetLevelCfg#pet_level_cfg.attr]),
%   ok.

% verify_pet_quality_cfg(_QualityCfg) ->
%   ok.

% verify_pet_advance_cfg(AdvanceCfg) ->
%   ?check(cost:is_exist_cost_cfg(AdvanceCfg#pet_advance_cfg.cost), "pet_advance_cfg id ~p cost ~p not exist in cost table",
%     [AdvanceCfg#pet_advance_cfg.id, AdvanceCfg#pet_advance_cfg.cost]),
%   ?check(load_spirit_attr:is_exist_attr(AdvanceCfg#pet_advance_cfg.attr_basic_add), "pet_advance_cfg id ~p attr ~p not exist in attr table",
%     [AdvanceCfg#pet_advance_cfg.id, AdvanceCfg#pet_advance_cfg.attr_basic_add]),

%   ok.

% verify_pet_advance_pro_cfg(#pet_advance_prop_cfg{diff_value = Diff, per = Per}) ->
%   ?check(is_integer(Diff), "pet_advance_prop.txt id ~p  diff_value error", [Diff]),
%   ?check((Per >= 0) andalso (Per =< 100), "pet_advance_prop.txt id ~p per error", [Diff]),
%   ok.

% verify_pet_skill_level_cfg(PetSkillSlot) ->
% %% 	study_cost, uplevel_cost, forget_cost
%   ?check(cost:is_exist_cost_cfg(PetSkillSlot#pet_skill_level_cfg.study_cost), "pet_skill_level_cfg id ~p study ~p not exist in attr table",
%     [PetSkillSlot#pet_skill_level_cfg.id, PetSkillSlot#pet_skill_level_cfg.study_cost]),
%   ?check(cost:is_exist_cost_cfg(PetSkillSlot#pet_skill_level_cfg.uplevel_cost), "pet_skill_level_cfg id ~p upgrade ~p not exist in table",
%     [PetSkillSlot#pet_skill_level_cfg.id, PetSkillSlot#pet_skill_level_cfg.uplevel_cost]),
%   ?check(cost:is_exist_cost_cfg(PetSkillSlot#pet_skill_level_cfg.forget_cost), "pet_skill_level_cfg id ~p forget ~p not exist in attr table",
%     [PetSkillSlot#pet_skill_level_cfg.id, PetSkillSlot#pet_skill_level_cfg.forget_cost]),
%   ok.

% verify_pet_treasure_cfg(PetTreasureCfg) ->
%   ?check(cost:is_exist_cost_cfg(PetTreasureCfg#pet_treasure_cfg.cost), "pet_treasure_cfg id ~p cost ~p not exist cost table",
%     [PetTreasureCfg#pet_treasure_cfg.id, PetTreasureCfg#pet_treasure_cfg.cost]),
%   ok.

% verify_pet_skill_pos_open_cfg(PetSkillPosOpen) ->
%   ?check(cost:is_exist_cost_cfg(PetSkillPosOpen#pet_skill_pos_open_cfg.cost), "pet_skill_pos_open_cfg id ~p cost ~p not exist cost table",
%     [PetSkillPosOpen#pet_skill_pos_open_cfg.id, PetSkillPosOpen#pet_skill_pos_open_cfg.cost]),
%   ok.


% find_egg_itembid(PetCfgId) ->
%   ItemCidS = load_item:lookup_group_item_attr_cfg(#item_attr_cfg.type, 6),
%   com_lists:break(
%     fun
%       (ItemCid) ->
%         case lists:keymember(PetCfgId, 2, load_item:lookup_item_attr_cfg(ItemCid, #item_attr_cfg.use_effect)) of
%           ?true -> {break, ItemCid};
%           ?false -> continue
%         end
%     end,
%     ?false,
%     ItemCidS).
