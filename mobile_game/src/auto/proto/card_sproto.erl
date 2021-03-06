%% Auto generated by sproto from card.sproto
%% Don't edit it.

-module(card_sproto).
-export([pkg_msg/2, unpkg_msg/2, to_s/1]).
-include("card_sproto.hrl").

%% id=1  
pkg_msg(?MSG_CARD_AWARD, {ReplyNum, ItemTpL}) ->
<<?MSG_CARD_AWARD:16, 
ReplyNum,
    (length(ItemTpL)):16, (iolist_to_binary([<<
ItemBid:32,
    Count:32>>
|| {ItemBid, Count} <- ItemTpL]))/binary >>
;

%% id=2  
pkg_msg(?MSG_CARD_AWARD_INFO, {PageData}) ->
<<?MSG_CARD_AWARD_INFO:16, 
(length(PageData)):16, (iolist_to_binary([<<
Time:64,
    Id:64,
    (byte_size(Name)), Name/binary,
    (length(ItemTpL)):16, (iolist_to_binary([<<
ItemBid:32,
    Count:32>>
|| {ItemBid, Count} <- ItemTpL]))/binary >>
|| {Time, Id, Name, ItemTpL} <- PageData]))/binary >>
;

%% id=3  
pkg_msg(?MSG_CARD_BROADCAST_NOTICE, {Id, Name, ItemTpL}) ->
<<?MSG_CARD_BROADCAST_NOTICE:16, 
Id:64,
    (byte_size(Name)), Name/binary,
    (length(ItemTpL)):16, (iolist_to_binary([<<
ItemBid:32,
    Count:32>>
|| {ItemBid, Count} <- ItemTpL]))/binary >>
;
pkg_msg(Id, _) -> ok.



%% id = 1  
unpkg_msg(?MSG_CARD_AWARD, Acc0) ->
<<L__Info:16, Acc1/binary>> = Acc0,
{Info, Acc2} = unpkg_list_struct__(L__Info, Acc1, [], fun unpkg_ano_s__0/1)
,
{{Info}, Acc2};

%% id = 2  
unpkg_msg(?MSG_CARD_AWARD_INFO, Acc0) ->
{{}, Acc0};

%% id = 3  
unpkg_msg(?MSG_CARD_BROADCAST_NOTICE, Acc0) ->
{{}, Acc0};
unpkg_msg(Id, _) -> ok.


unpkg_ano_s__0(Acc0) ->
<<ItemBid:32,
Count:16,
Acc1/binary>> = Acc0,
 {{ItemBid,Count}, Acc1}.


to_s(?MSG_CARD_AWARD) -> <<"MSG_CARD_AWARD">>; %% high 23, id 1
to_s(?MSG_CARD_AWARD_INFO) -> <<"MSG_CARD_AWARD_INFO">>; %% high 23, id 2
to_s(?MSG_CARD_BROADCAST_NOTICE) -> <<"MSG_CARD_BROADCAST_NOTICE">>; %% high 23, id 3
to_s(_) -> <<"unknown msg">>.
unpkg_list_struct__(0, Bin, List, _Fn) -> {lists:reverse(List), Bin};
unpkg_list_struct__(L, Bin, List, Fn) -> {E, Bin1} = Fn(Bin), unpkg_list_struct__(L-1, Bin1, [E|List], Fn).
