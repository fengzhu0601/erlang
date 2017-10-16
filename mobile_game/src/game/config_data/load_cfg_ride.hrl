%%%-------------------------------------------------------------------
%%% @author fengzhu
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 11. 五月 2016 下午2:54
%%%-------------------------------------------------------------------
-author("fengzhu").

%%坐骑配置表
-record(ride_attr_cfg,
{
  id,         %% 坐骑ID
  level,      %% 进化等级
  form_id,    %% 形象id,根据形象Id判断是否是同一个坐骑
  cost_id,    %% 消耗ID
  evolve_attr %% 进化后的属性
}).

%% 坐骑形象表
-record(ride_form_cfg,
{
  id,       %% 坐骑id
  speed     %% 坐骑移动速度
}).

%% 兽魂配置表
-record(ride_soul_attr_cfg,
{
  id,         %%兽魂id
  level,      %% 兽魂等级
  exp,        %%升级经验
  get_exp,    %% 升级消耗{costid, 经验}
  grade,      %%阶数
  grade_cost, %%进阶消耗id
  attr,       %%升级属性
  grade_attr, %%进阶属性
  form_id,    %%形象id
  out_pirce,  %%吐出的奖励id
  out_cd,     %%吐出的cd
  out_num,     %%每天喷吐次数
  get_happy
}).

%% 兽魂表情表
-record(ride_soul_form_cfg,
{
  id,       %%兽魂表情Id
  happy     %%兽魂愉悦值
}).