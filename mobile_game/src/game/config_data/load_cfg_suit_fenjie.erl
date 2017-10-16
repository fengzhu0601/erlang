%%%-------------------------------------------------------------------
%%% @author lan
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 24. 九月 2016 下午2:36
%%%-------------------------------------------------------------------
-module(load_cfg_suit_fenjie).
-author("lan").

%% API
-export([
	get_suit_fenjie_cost/1,
	get_create_goods_list/2
]).


-include("load_cfg_suit_fenjie.hrl").
-include_lib("config/include/config.hrl").
-include("inc.hrl").



load_config_meta() ->
	[
		#config_meta
		{
			record = #suit_fenjie_cfg{},
			fields = ?record_fields(suit_fenjie_cfg),
			file = "suit_fenjie.txt",
			keypos = #suit_fenjie_cfg.id,
			verify = fun verify/1
		}
	].

verify(#suit_fenjie_cfg{id = Id, num = Num, quality = QuGoodsList, suipian = SuiPian, cost = CostId}) ->
	?check(load_item:is_exist_item_cfg(Id), "配置suit_fenjie.txt id:~p 在配置表generated_item_all.txt 中没有找到", [Id]),
	?check(erlang:size(Num) =:= 2, "配置suit_fenjie.txt id:~p, num:~p 格式不正确", [Id, Num]),
	GoodsList =
		lists:foldl
		(
			fun({_, List}, AccList) ->
				[GId || {GId, _N} <- List] ++ AccList
			end,
			[],
			QuGoodsList
		),
	lists:foreach
	(
		fun(GID1) ->
			?check(load_item:is_exist_item_cfg(GID1), "配置表suit_fenjie.txt id:~p itemId:~p在配置表generated_item_all.txt中没有找到", [Id, GID1])
		end,
		GoodsList
	),
	case SuiPian of
		{_Min, _Max, SuiPianId} ->
			?check(load_item:is_exist_item_cfg(SuiPianId), "配置suit_fenjie.txt id:~p 碎片id:~p在配置表generated_item_all.txt 中没有找到", [Id,SuiPianId]);
		Mes ->
			?ERROR_LOG("配置suit_fenjie.txt id:~p suipian:~p 格式不正确", [Id, Mes])
	end,
	?check(cost:is_exist_cost_cfg(CostId), "配置suit_fenjie.txt id [~p] costId: ~p 在cost.txt表中没有找到", [Id, CostId]),
	ok.




%% 获取消耗id
get_suit_fenjie_cost(Bid) ->
	case lookup_suit_fenjie_cfg(Bid) of
		#suit_fenjie_cfg{cost = CostId} ->
			CostId;
		_ ->
			{error, unknown_type}
	end.

%% 获取物品生成数量列表
get_create_goods_list(Bid, Quality) ->
	case lookup_suit_fenjie_cfg(Bid) of
		#suit_fenjie_cfg{
			suipian = {Min, Max, SuiPianId},
			quality = QualGoodsList,
			num = {MinNum, MaxNum}
		} ->
			Count = com_util:random(Min, Max),
			SuiPianList = [{SuiPianId, Count}],

			GoodsList = util:get_field(QualGoodsList, Quality, []),
			GoodsNum = com_util:random(MinNum, MaxNum),

			Fun =
				fun
					(_ThisFun, [], _) -> [];
					(_ThisFun,_List, 0) -> [];
					(ThisFun, List, Num) ->
						[GoodsBid] = util:get_val_by_weight(List, 1),
						[{GoodsBid, 1} | ThisFun(ThisFun, List, Num-1)]
				end,
			GoodsList1 = Fun(Fun, GoodsList, GoodsNum),
%%			?INFO_LOG("GoodsList1 = ~p", [GoodsList1]),
			SuiPianList ++ GoodsList1;
		_ ->
			?ERROR_LOG("Bid:~p, Quality:~p not find fenjie cfg", [Bid, Quality]),
			[]
	end.