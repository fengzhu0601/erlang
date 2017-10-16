%%%-------------------------------------------------------------------
%%% @author fengzhu
%%% @copyright (C) 2016, <COMPANY>
%%% @doc 宝石
%%%
%%% @end
%%% Created : 04. 一月 2016 下午2:41
%%%-------------------------------------------------------------------
-author("fengzhu").

%% 宝石配置
-record(gem_cfg,
{
    id = 0            %% 宝石id
    , lev = 0         %% 宝石等级
    , type = 0        %% 宝石类型
    , up_cost = 0     %% 升级消耗
    , embed_cost = 0  %% 镶嵌消耗
    , attr = 0        %% 宝石对应的属性
    , up_exp = 0      %% 宝石升级所需经验
    , exp = 0         %% 宝石所兑换的经验值
    , exp_cost = 0    %% 宝石兑换经验需要消耗的金币
    , next_level_id = 0 %% 宝石的下个等级id
}).

%% 合成宝石需要宝石数量
-define(UPDATE_GEM_NEED_NUM, 3).

%% 玩家史诗宝石表
-record(player_epic_gems_tab,
{
    id = 0,                %% 玩家ID int
    gems = []              %% 拥有的所有宝石
}).

%% 史诗宝石
-record(epic_gems,
{
    id,                 %% 史诗宝石Id
    bid,                %% 史诗宝石对应的bid
    exp                 %% 史诗宝石当前经验
}).

