%%%-------------------------------------------------------------------
%%% @author lan
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 17. 五月 2016 下午4:17
%%%-------------------------------------------------------------------
-module(load_black_shop_cfg).
-author("lan").

%% API
-export([
    get_all_black_shop_id/0
    ,get_black_shop_item/1
    ,get_turn/1
    ,get_auction_list_by_turn/1
    ,get_goods_vip_level/1
]).

-include("inc.hrl").
-include_lib("config/include/config.hrl").
-include("load_black_shop_cfg.hrl").



load_config_meta() ->
    [
        #config_meta{
            record = #black_shop_cfg{},
            fields = ?record_fields(black_shop_cfg),
            file = "black_shop.txt",
            keypos = #black_shop_cfg.id,
            all = [#black_shop_cfg.id],
            verify = fun verify/1
        }
    ].

verify(#black_shop_cfg{id = Id, item = Bid}) ->
    ?check(is_integer(Id), "black_shop.txt中， [~p] id: ~p 配置无效。", [Id, Id]);

verify(_E) ->
    ?ERROR_LOG("black_shop_cfg ~p 无效的配置格式", [_E]),
     exit(bad).

%% 根据获取配置中拍卖物品的绑定id
get_black_shop_item(Id) ->
    case lookup_black_shop_cfg(Id) of
        #black_shop_cfg{item = Item} -> Item;
        _ -> {error, no_msg}
    end.


get_all_black_shop_id() ->
    [Id || Id <- lookup_all_black_shop_cfg(#black_shop_cfg.id), is_integer(Id)].

%% 获得轮数
get_turn(Id) ->
    case lookup_black_shop_cfg(Id) of
        #black_shop_cfg{turn = Turn} ->
            Turn;
        _ ->
            {error, unknown_type}
    end.

%% 获取商品的可见vip等级
get_goods_vip_level(Id) ->
    case lookup_black_shop_cfg(Id) of
        #black_shop_cfg{vip_level = VipLevel} ->
            VipLevel;
        _ ->
            {error, unknown_type}
    end.

%% 获取相应轮数的拍卖列表根据权重、轮数
get_auction_list_by_turn(Turn) ->
    ACList = get_id_list_by_turn(Turn),
    #{refresh_num := RefreshNum} = misc_cfg:get_black_shop_misc(),
    IdList =
        case length(ACList) =< RefreshNum of
            true ->
                ACList;
            _ ->
                RIdList = [{Id, get_tatio(Id)} || Id <- ACList],
                NewList = util:get_val_by_weight(RIdList, RefreshNum),
                NewList
        end,
    IdList.



%% 获得权重
get_tatio(Id) ->
    case lookup_black_shop_cfg(Id) of
        #black_shop_cfg{ratio = Ratio} ->
            Ratio;
        _ ->
            {error, unknown_type}
    end.

%% 获得当前轮数的拍卖列表
get_id_list_by_turn(Turn) ->
    List =
        lists:foldl
        (
            fun(Id, AccList) ->
                case get_turn(Id) =:= Turn of
                    true ->
                        [Id | AccList];
                    _ ->
                        AccList
                end
            end,
            [],
            lookup_all_black_shop_cfg(#black_shop_cfg.id)
        ),
    List.



% -record(state, {
%     id = black_shop,
%     turn = 0,               %% 涮的次数
%     start_time = 0,         %% 开市的开始时间
%     close_time = 0,         %% 休市的开始时间
%     is_open = 0,            %% 1开市，0休市
%     %out_time = 0,          %% 记录本次倒计时 时间(倒计时时间的秒数)
%     %close_server_time = 0  %% 关闭服务器的时间
%     open_time = 0,           %% 已经开市了多少时间
%     xiushi_time = 0,          %% 已经休市了多少时间
%     total_xiushi_time=0     %% 一共要休市多久
% }).