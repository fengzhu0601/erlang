%%%-------------------------------------------------------------------
%%% @author fengzhu
%%% @copyright (C) 2016, <COMPANY>
%%% @doc 商城
%%%
%%% @end
%%% Created : 04. 一月 2016 下午3:33
%%%-------------------------------------------------------------------
-module(load_cfg_mall).
-author("fengzhu").

%% API
-export([
  get_time/1
]).

-include_lib("config/include/config.hrl").
-include("inc.hrl").
-include("load_cfg_mall.hrl").

load_config_meta() ->
    [
        #config_meta{record = #mall_cfg{},
        fields = ?record_fields(?mall_cfg),
        file = "mall.txt",
        keypos = #mall_cfg.id,
        verify = fun verify_mall/1}
    ].

verify_mall(#mall_cfg{id = Id, item_bid = ItemBid, money_type = MoneyType, price = Price, rate = Rate, time = Time, label = Labels}) ->
    ?check(com_util:is_valid_uint64(Id), "mall.txt id [~w] 无效! ", [Id]),
    ?check(load_item:is_exist_item_attr_cfg(ItemBid), "mall.txt id [~w] item_bid [~w] 物品不存在! ", [Id, ItemBid]),
    ?check(player_def:is_valid_special_item_id(MoneyType), "mall.txt  id [~w]  money_type [~w] 无效  ", [Id, MoneyType]),
    ?check(com_util:is_valid_uint64(Price), "mall.txt  id [~w]  price [~w] 无效  ", [Id, Price]),
    ?check(com_util:is_valid_uint16(Rate), "mall.txt id [~w] rate [~w] 无效! ", [Id, Rate]),
    ?check(check_time(Time), "mall.txt id [~w] time [~w] 无效! ", [Id, Time]),
    lists:foreach(fun(Label) ->
        ?check(lists:member(Label, ?MALL_LABEL_ALL), "mall.txt id [~w] time [~w] 无效! ", [Id, Labels])
    end, Labels),
    ok.

check_time(?undefined) -> ?true;
check_time({DateTimeS = {{_Y, _M, _D}, {_H, _Mi, _S}}, DateTimeE = {{_YE, _ME, _DE}, {_HE, _MiE, _SE}}}) ->
    case catch com_time:localtime_to_sec(DateTimeS) of
        SSec when is_integer(SSec) ->
            case catch com_time:localtime_to_sec(DateTimeE) of
                ESec when is_integer(ESec) -> 
                    ?true;
                _ -> 
                    ?false
            end;
        _ -> 
            ?false
    end;

check_time({DateTime = {{_Y, _M, _D}, {_H, _Mi, _S}}, HourLen}) ->
    case catch com_time:localtime_to_sec(DateTime) of
        Sec when is_integer(Sec) ->
            com_util:is_valid_uint16(HourLen);
        _ -> 
            ?false
    end.

get_time(CfgId) ->
    case lookup_mall_cfg(CfgId) of
        #mall_cfg{time = {DateTime, Time}} ->
            Now = com_time:now(),
            StarSec = com_time:localtime_to_sec(DateTime),
            case Now - StarSec of
                Sec when Sec > 0, is_integer(Time) ->
                    TimeLenSec = ?SECONDS_PER_HOUR * Time,
                    case (TimeLenSec - Sec) > 0 of
                        ?true ->
                            StarSec + TimeLenSec;
                        _ -> 
                            0
                    end;
                Sec when Sec > 0 ->
                    EndTimeSec = com_time:localtime_to_sec(Time),
                    case EndTimeSec - Now > 0 of
                        ?true -> 
                            EndTimeSec;
                        _ -> 
                            0
                    end;
                _ -> 
                    0
            end;
        _Other -> 
            0
    end.
