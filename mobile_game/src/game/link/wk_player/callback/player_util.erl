%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 01. 七月 2015 上午10:57
%%%-------------------------------------------------------------------
-module(player_util).
-author("clark").

%% API
-export([
    fun_is_more/2,
    fun_is_more_and_no_negative/2
]).
%%     fun_add_thing/1,
%%     fun_del_thing/1]).


-include("inc.hrl").
-include_lib("common/include/inc.hrl").
-include("player.hrl").
-include("item_bucket.hrl").



%% vip = get(?pd_vip),
%% card_vip = get(?pd_card_vip),
%% card_vip_give_tm = get(?pd_card_vip_give_tm),
%% card_vip_end_tm = get(?pd_card_vip_end_tm),
%% day_total_consume = get(?pd_day_total_consume),
%% total_consume = get(?pd_total_consume)




%% SrcVal 是否大于或等于 DestVal(需大于1)
fun_is_more(SrcVal, DestVal) ->
    fun() ->
        if
            SrcVal >= DestVal ->
                true;
            true ->
                false
        end
    end.

%% SrcVal 是否大于或等于 DestVal(需大于1)
fun_is_more_and_no_negative(SrcVal, DestVal) ->
    fun() ->
%%         ?DEBUG_LOG_COLOR(?color_yellow, "fun_is_more_and_no_negative ~p", [[SrcVal, DestVal]]),
        if
            SrcVal < 0 ->
                false;
            DestVal < 0 ->
                false;
            SrcVal >= DestVal ->
                true;
            true ->
                false
        end
    end.


%% -----------------------------------------------------------------------------------
%% 添加物品添加物品
%% fun_add_thing(ItemList) ->
%%     fun() ->
%%         %item_bucket:add(?BUCKET_TYPE_BAG, [{GoodsId, GoodsNum},{?PL_MONER, 1000}])
%%         item_bucket:add(?BUCKET_TYPE_BAG, ItemList)
%%     end.
%%
%%
%% %% 删除物品或数据
%% fun_del_thing(ItemList) ->
%%     fun() ->
%%         item_bucket:del(?BUCKET_TYPE_BAG, ItemList)
%%     end.