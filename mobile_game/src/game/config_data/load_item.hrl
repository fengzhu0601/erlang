%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 31. 七月 2015 上午11:56
%%%-------------------------------------------------------------------
-author("clark").


%% 物品配置结构
-record(item_attr_cfg,
{
    bid = 0                 %% 物品bid
    , type = 0               %% 物品类型
    , lev = 0                %% 物品使用等级
    , quality = 0            %% 物品品质
    , overlap = 1            %% 最大堆叠数（是否可以堆叠由堆叠数决定，当堆叠数等于1时，无法堆叠
    , job = 0                %% 物品职业(默认为通用---详情见game.hrl中职业部分
    , use_type = 0           %% 使用方式
    , use_effect = []        %% 使用效果
    , cant_sell = 0           %% 不可出售 0可出售 1不可出售
    , cant_qhjch = 0          %% 不可强化 不可进程 0可强化 1不可强化
    , cant_hecheng = 0        %% 不可出售 0可合成 1不可合成
    , val = 0                %% 物品售卖时的价格列表售卖价格单位为金币
    , improve_effect
    , gem_effect
    , instance_buff = 0
    , is_bind = 0           %% 是否绑定(0:没有 1:装备后绑定)
    , resolve = 0
}).


