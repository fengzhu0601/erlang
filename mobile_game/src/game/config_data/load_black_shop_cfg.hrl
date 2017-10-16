%%%-------------------------------------------------------------------
%%% @author lan
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 17. 五月 2016 下午4:18
%%%-------------------------------------------------------------------
-author("lan").

-record(black_shop_cfg,
{
    id,             %% 索引id
    item,           %% 拍卖商品的bid
    num,            %% 数量
    ratio,          %% 权重
    type,           %% 类型
    seller,         %% 出售者
    money_type,     %% 货币类型（10金币、11钻石）
    start_price,    %% 起始价格
    end_price,      %% 一口价
    step_price,      %% 单位价格
    turn,            %% 当天拍卖的次数（根据这个次数选择被拍卖的商品）
    vip_level       %% vip可见等级
}).
