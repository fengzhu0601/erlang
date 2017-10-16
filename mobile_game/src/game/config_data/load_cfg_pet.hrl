%%%-------------------------------------------------------------------
%%% @author fengzhu
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 04. 一月 2016 下午4:19
%%%-------------------------------------------------------------------
% -author("fengzhu").

% %%宠物配置表
% -record(pet_cfg,
% {
%   id,
%   name,
%   quality,
%   facade = 0,
%   tacit_value = 0,
%   exclusive_skill = [],
%   hatch_cost = 1,
%   seal_cost = 0,
%   jd_attr_min_num,
%   jd_attr_max_num,
%   jd_attr
% }).

% -record(pet_level_cfg,
% {
%   id,
%   level,
%   need_exp,
%   attr
% }).

% -record(pet_quality_ratio_cfg,
% {
%   quality = 0,
%   max_level,
%   initialtive_open,
%   initialtive_max,
%   passivity_open,
%   passivity_max
% }).

% -record(pet_advance_cfg,
% {
%   id = 0,
%   pet_id = 0,
%   level = 0,
%   cost,
%   mini_slots = 0,
%   attr_basic_add,
%   tacit_value_add,
%   min_num,
%   max_num,
%   attr_prize,
%   facade_prize
% }).

% -record(pet_advance_prop_cfg,
% {
%   diff_value,
%   per
% }).

% -record(pet_skill_level_cfg,
% {
%   id,
%   next_id,
%   level,
%   buff_id,
%   skill_id,
%   type,
%   study_cost,
%   uplevel_cost,
%   forget_cost
% }).

% -record(pet_treasure_cfg,
% {
%   id = 0,
%   weight = 0,
%   type = 0,
%   need_time = 0,
%   cost = 0,
%   reward = 0
% }).

% -record(pet_skill_pos_open_cfg,
% {
%   id = 0,
%   type = 0,
%   pos = 0,
%   cost = 0
% }).