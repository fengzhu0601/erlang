%%%-------------------------------------------------------------------
%%% @author lan
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 24. 九月 2016 下午2:37
%%%-------------------------------------------------------------------
-author("lan").


-record(suit_fenjie_cfg,
{
	id,					%% 套装的bid
	type,				%% 套装的部位类型
	num,				%% 分解后生成物品的数量
	quality,			%% 根据套装的品质来选择物品
	suipian,			%% 套装分解生成的套装碎片的数量
	cost				%% 消耗id
}).