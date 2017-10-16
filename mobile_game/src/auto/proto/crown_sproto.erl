%% Auto generated by sproto from crown.sproto
%% Don't edit it.

-module(crown_sproto).
-export([pkg_msg/2, unpkg_msg/2, to_s/1]).
-include("crown_sproto.hrl").

%% id=10  
pkg_msg(?MSG_CROWN_INIT_CLIENT, {Anger_point, Gems, Dress_gems}) ->
<<?MSG_CROWN_INIT_CLIENT:16, 
Anger_point:16,
    (length(Gems)):16, (iolist_to_binary([<<
Id:16,
    CfgId:16,
    (length(Sats)):16, (iolist_to_binary([<<
SatId,
    Value:32>>
|| {SatId, Value} <- Sats]))/binary >>
|| {Id, CfgId, Sats} <- Gems]))/binary ,
    (length(Dress_gems)):16, (iolist_to_binary([<<
Position,
    Id:16>>
|| {Position, Id} <- Dress_gems]))/binary >>
;

%% id=8  
pkg_msg(?MSG_CROWN_GEM_ADD, {Id, CfgId}) ->
<<?MSG_CROWN_GEM_ADD:16, 
Id:16,
    CfgId:16>>
;

%% id=1  
pkg_msg(?MSG_CROWN_GEM_SELL, {}) ->
<<?MSG_CROWN_GEM_SELL:16>> 
;

%% id=2  
pkg_msg(?MSG_CROWN_GEM_ENCHANT, {Id, Sats}) ->
<<?MSG_CROWN_GEM_ENCHANT:16, 
Id:16,
    (length(Sats)):16, (iolist_to_binary([<<
SatId,
    Value:32>>
|| {SatId, Value} <- Sats]))/binary >>
;

%% id=3  
pkg_msg(?MSG_CROWN_GEM_UPGRADE, {Id}) ->
<<?MSG_CROWN_GEM_UPGRADE:16, 
Id:16>>
;

%% id=4  
pkg_msg(?MSG_CROWN_GEM_DRESS, {Position, Id}) ->
<<?MSG_CROWN_GEM_DRESS:16, 
Position,
    Id:16>>
;

%% id=5  
pkg_msg(?MSG_CROWN_GEM_UNDRESS, {Id}) ->
<<?MSG_CROWN_GEM_UNDRESS:16, 
Id:16>>
;

%% id=6  
pkg_msg(?MSG_CROWN_ANGER_CHANGE, {Anger_point}) ->
<<?MSG_CROWN_ANGER_CHANGE:16, 
Anger_point:16>>
;
pkg_msg(Id, _) -> ok.



%% id = 1  
unpkg_msg(?MSG_CROWN_GEM_SELL, Acc0) ->
<<L__IdList:16, Acc1/binary>> = Acc0,
{IdList, Acc2} = 
unpkg_list_u16(L__IdList, Acc1, []),
{{IdList}, Acc2};

%% id = 2  
unpkg_msg(?MSG_CROWN_GEM_ENCHANT, Acc0) ->
<<Id:16,
Acc1/binary>> = Acc0,
 {{Id}, Acc1};

%% id = 3  
unpkg_msg(?MSG_CROWN_GEM_UPGRADE, Acc0) ->
<<Id:16,
Acc1/binary>> = Acc0,
 {{Id}, Acc1};

%% id = 4  
unpkg_msg(?MSG_CROWN_GEM_DRESS, Acc0) ->
<<Position,
Id:16,
Acc1/binary>> = Acc0,
 {{Position,Id}, Acc1};

%% id = 5  
unpkg_msg(?MSG_CROWN_GEM_UNDRESS, Acc0) ->
<<Id:16,
Acc1/binary>> = Acc0,
 {{Id}, Acc1};
unpkg_msg(Id, _) -> ok.




to_s(?MSG_CROWN_INIT_CLIENT) -> <<"MSG_CROWN_INIT_CLIENT">>; %% high 15, id 10
to_s(?MSG_CROWN_GEM_ADD) -> <<"MSG_CROWN_GEM_ADD">>; %% high 15, id 8
to_s(?MSG_CROWN_GEM_SELL) -> <<"MSG_CROWN_GEM_SELL">>; %% high 15, id 1
to_s(?MSG_CROWN_GEM_ENCHANT) -> <<"MSG_CROWN_GEM_ENCHANT">>; %% high 15, id 2
to_s(?MSG_CROWN_GEM_UPGRADE) -> <<"MSG_CROWN_GEM_UPGRADE">>; %% high 15, id 3
to_s(?MSG_CROWN_GEM_DRESS) -> <<"MSG_CROWN_GEM_DRESS">>; %% high 15, id 4
to_s(?MSG_CROWN_GEM_UNDRESS) -> <<"MSG_CROWN_GEM_UNDRESS">>; %% high 15, id 5
to_s(?MSG_CROWN_ANGER_CHANGE) -> <<"MSG_CROWN_ANGER_CHANGE">>; %% high 15, id 6
to_s(_) -> <<"unknown msg">>.
unpkg_list_u16(0, Bin, List) -> {lists:reverse(List), Bin};
unpkg_list_u16(Len, Bin, List) -> 
 <<E:16,Bin1/binary>> = Bin,
unpkg_list_u16(Len-1, Bin1, [E|List]).