%% Auto generated by sproto from main_star_shop.sproto
%% Don't edit it.

-module(main_star_shop_sproto).
-export([pkg_msg/2, unpkg_msg/2, to_s/1]).
-include("main_star_shop_sproto.hrl").

%% id=1  
pkg_msg(?MSG_MAIN_STAR_SHOP_DATA, {Next_time_refresh, Count, ItemList}) ->
<<?MSG_MAIN_STAR_SHOP_DATA:16, 
Next_time_refresh:32,
    Count,
    (length(ItemList)):16, (iolist_to_binary([<<
Id:16,
    IsBuy>>
|| {Id, IsBuy} <- ItemList]))/binary >>
;

%% id=2  
pkg_msg(?MSG_MAIN_STAR_SHOP_BUY, {}) ->
<<?MSG_MAIN_STAR_SHOP_BUY:16>> 
;
pkg_msg(Id, _) -> ok.



%% id = 1  
unpkg_msg(?MSG_MAIN_STAR_SHOP_DATA, Acc0) ->
<<Type,
Acc1/binary>> = Acc0,
 {{Type}, Acc1};

%% id = 2  
unpkg_msg(?MSG_MAIN_STAR_SHOP_BUY, Acc0) ->
<<Id:16,
Acc1/binary>> = Acc0,
 {{Id}, Acc1};
unpkg_msg(Id, _) -> ok.




to_s(?MSG_MAIN_STAR_SHOP_DATA) -> <<"MSG_MAIN_STAR_SHOP_DATA">>; %% high 41, id 1
to_s(?MSG_MAIN_STAR_SHOP_BUY) -> <<"MSG_MAIN_STAR_SHOP_BUY">>; %% high 41, id 2
to_s(_) -> <<"unknown msg">>.