%%%-------------------------------------------------------------------
%%% @author fengzhu
%%% @copyright (C) 2016, <COMPANY>
%%% @doc 皇冠
%%%
%%% @end
%%% Created : 04. 一月 2016 下午3:11
%%%-------------------------------------------------------------------
-author("fengzhu").

-define(all_crown_type_list, [1,2,3,4]).

-record(crown_main_cfg,
{
    id,                               %% 皇冠技能id
    open_level,                       %% 开启条件1角色等级
    open_crown_before,                %% 开启条件2前置等级
    skill_type                        %% 技能类型(1主动，2被动，3选择性被动)
}).


-record(crown_skill_cfg,
{
    id,
    crown_skill_id,                 %% 关联皇冠技能id
    level,                          %% 技能等级
    skill_modify_id,                %% 修改集id（skill_modify表的id）
    skill_id,                       %% 技能id（取第一段）
    cost                            %% 激活消耗
}).

-record(crown_gem_cfg,
{
  type, %% 1 ice, 10 fire, 100 throuhgt
  level,
  upgrade_cost, %%
  sell_fragment, %% 兑换碎片的数量
  attr_id,
  bid, %% 用于前台
  enchant_cost, %% 附魔兑换
  enchant_sats%% random_sats_cfg 中的id
}).

-define(CROWN_CFG_FILE, "crown_gem.txt").
