-module(load_offset_goods).

%% API
-export([
    %pack_offset_goods/1
    get_offset/1
]).


-include("inc.hrl").
-include_lib("config/include/config.hrl").
-include("load_dial_prize.hrl").
-include("load_item.hrl").
-include("item.hrl").
-include("item_new.hrl").
-include("load_offset_goods.hrl").

get_offset(R) ->
    {R#offset_goods_cfg.bid,
    R#offset_goods_cfg.name,
    R#offset_goods_cfg.type}.


% get_offset_goods_list(Page) ->
%     List = ets:tab2list(offset_goods_cfg),
%     End = Page * 15,
%     Begin = End - 14,
%     Size = length(List),
%     if
%         Size =< 15 ->
%             List;
%         Page =:= 0 ->
%             lists:sublist(List, 1, 15);
%         true ->
%             lists:sublist(List, Begin, End)
%     end.


% pack_offset_goods(Page) ->
%     ?DEBUG_LOG("Page------------------------:~p",[Page]),
%     ItemList = get_offset_goods_list(Page),
%     Count = length(ItemList),
%     MapsItemList = 
%     lists:foldl(fun({_, Pl}, Acc) ->
%             M =  #{
%                 <<"ItemID">> => Pl#offset_goods_cfg.bid,
%                 <<"ItemType">> => Pl#offset_goods_cfg.type,
%                 <<"ItemName">> => Pl#offset_goods_cfg.name
%                 },
%             [M|Acc]
%     end,
%     [],
%     ItemList),
%     #{<<"Result">> => 0, <<"Count">> => Count, <<"Page">> => 1, <<"ItemList">> => MapsItemList}.


load_config_meta() ->
    [
        #config_meta{record = #offset_goods_cfg{},
            fields = ?record_fields(offset_goods_cfg),
            file = "offset_goods.txt",   %% TODO:这里的文件是预处理生成的，使用item.txt和equip.txt拼接而成(处理的脚本为config_pp
            keypos = #offset_goods_cfg.bid,
            verify = fun verify/1}
    ].



verify(#offset_goods_cfg{bid = Id, name=Name, type = _Type}) ->
    ?check(load_item:is_exist_item_attr_cfg(Id), "offset_goods Id~p 没有找到", [Id]),
    ?check(Name =/= undefined, "offset_goods.txt中 id: [~p] name: ~p 配置无效。", [Id, Name]),
    ok;

verify(_R) ->
    ?ERROR_LOG("item ~p 无效格式", [_R]),
    exit(bad).



