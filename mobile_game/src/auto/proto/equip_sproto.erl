%% Auto generated by sproto from equip.sproto
%% Don't edit it.

-module(equip_sproto).
-export([pkg_msg/2, unpkg_msg/2, to_s/1]).
-include("equip_sproto.hrl").

%% id=1  
pkg_msg(?MSG_EQUIP_DRESS, {ReplyNum}) ->
<<?MSG_EQUIP_DRESS:16, 
ReplyNum>>
;

%% id=2  
pkg_msg(?MSG_EQUIP_UNDRESS, {ReplyNum}) ->
<<?MSG_EQUIP_UNDRESS:16, 
ReplyNum>>
;

%% id=3  
pkg_msg(?MSG_EQUIP_JIANDING, {ReplyNum}) ->
<<?MSG_EQUIP_JIANDING:16, 
ReplyNum>>
;

%% id=4  
pkg_msg(?MSG_EQUIP_EMBED_GEM, {ReplyNum}) ->
<<?MSG_EQUIP_EMBED_GEM:16, 
ReplyNum>>
;

%% id=5  
pkg_msg(?MSG_EQUIP_UNEMBED_GEM, {ReplyNum}) ->
<<?MSG_EQUIP_UNEMBED_GEM:16, 
ReplyNum>>
;

%% id=6  
pkg_msg(?MSG_EQUIP_QIANG_HUA, {ReplyNum}) ->
<<?MSG_EQUIP_QIANG_HUA:16, 
ReplyNum>>
;

%% id=7  
pkg_msg(?MSG_EQUIP_HE_CHENG, {ReplyNum}) ->
<<?MSG_EQUIP_HE_CHENG:16, 
ReplyNum>>
;

%% id=9  
pkg_msg(?MSG_EQUIP_JI_CHENG, {ReplyNum}) ->
<<?MSG_EQUIP_JI_CHENG:16, 
ReplyNum>>
;

%% id=10  
pkg_msg(?MSG_EQUIP_UNEMBED_ALL_GEM, {ReplyNum}) ->
<<?MSG_EQUIP_UNEMBED_ALL_GEM:16, 
ReplyNum>>
;

%% id=11  
pkg_msg(?MSG_EQUIP_JIANDING_ALL, {ReplyNum}) ->
<<?MSG_EQUIP_JIANDING_ALL:16, 
ReplyNum>>
;

%% id=12  
pkg_msg(?MSG_EQUIP_SLOT, {ReplyNum}) ->
<<?MSG_EQUIP_SLOT:16, 
ReplyNum>>
;

%% id=13  
pkg_msg(?MSG_EQUIP_EXCHANGE, {ItemList, ReplyNum}) ->
<<?MSG_EQUIP_EXCHANGE:16, 
(length(ItemList)):16, (iolist_to_binary([<<
ItemId:32,
    ItemCount>>
|| {ItemId, ItemCount} <- ItemList]))/binary ,
    ReplyNum>>
;

%% id=14  
pkg_msg(?MSG_EQUIP_ONE_KEY_EXCHANGE, {ItemList, ReplyNum}) ->
<<?MSG_EQUIP_ONE_KEY_EXCHANGE:16, 
(length(ItemList)):16, (iolist_to_binary([<<
ItemId:32,
    ItemCount>>
|| {ItemId, ItemCount} <- ItemList]))/binary ,
    ReplyNum>>
;

%% id=15  
pkg_msg(?MSG_EQUIP_ACTIVATE_FUMO_MODE, {ReplyNum}) ->
<<?MSG_EQUIP_ACTIVATE_FUMO_MODE:16, 
ReplyNum>>
;

%% id=16  
pkg_msg(?MSG_EQUIP_IMBUE_WEAPON, {ReplyNum}) ->
<<?MSG_EQUIP_IMBUE_WEAPON:16, 
ReplyNum>>
;

%% id=17  
pkg_msg(?MSG_EQUIP_CUI_QU, {ReplyNum}) ->
<<?MSG_EQUIP_CUI_QU:16, 
ReplyNum>>
;

%% id=18  
pkg_msg(?MSG_EQUIP_FUMO_MODE_LIST, {FumoModeList}) ->
<<?MSG_EQUIP_FUMO_MODE_LIST:16, 
(length(FumoModeList)):16, (iolist_to_binary([<<ModeId:16>> || ModeId <- FumoModeList]))/binary>>
;

%% id=19  
pkg_msg(?MSG_EQUIP_EPIC_SLOT, {ReplyNum}) ->
<<?MSG_EQUIP_EPIC_SLOT:16, 
ReplyNum>>
;

%% id=20  
pkg_msg(?MSG_EQUIP_EPIC_EMBED_GEM, {ReplyNum}) ->
<<?MSG_EQUIP_EPIC_EMBED_GEM:16, 
ReplyNum>>
;

%% id=21  
pkg_msg(?MSG_EQUIP_EPIC_UNEMBED_GEM, {ReplyNum}) ->
<<?MSG_EQUIP_EPIC_UNEMBED_GEM:16, 
ReplyNum>>
;

%% id=22  
pkg_msg(?MSG_EQUIP_PART_QAINGHUA_INIT, {List}) ->
<<?MSG_EQUIP_PART_QAINGHUA_INIT:16, 
(length(List)):16, (iolist_to_binary([<<
PartType,
    QhLevel>>
|| {PartType, QhLevel} <- List]))/binary >>
;

%% id=23  
pkg_msg(?MSG_PART_QIANGHUA, {ReplyNum, PartType, NewLevel}) ->
<<?MSG_PART_QIANGHUA:16, 
ReplyNum,
    PartType,
    NewLevel>>
;

%% id=24  
pkg_msg(?MSG_EQUIP_XILIAN, {ReplyNum}) ->
<<?MSG_EQUIP_XILIAN:16, 
ReplyNum>>
;
pkg_msg(Id, _) -> ok.



%% id = 1  
unpkg_msg(?MSG_EQUIP_DRESS, Acc0) ->
<<EqmPos,
ItemId:32,
Acc1/binary>> = Acc0,
 {{EqmPos,ItemId}, Acc1};

%% id = 2  
unpkg_msg(?MSG_EQUIP_UNDRESS, Acc0) ->
<<EqmId:32,
Acc1/binary>> = Acc0,
 {{EqmId}, Acc1};

%% id = 3  
unpkg_msg(?MSG_EQUIP_JIANDING, Acc0) ->
<<EqmId:32,
Acc1/binary>> = Acc0,
 {{EqmId}, Acc1};

%% id = 4  
unpkg_msg(?MSG_EQUIP_EMBED_GEM, Acc0) ->
<<BucketType,
EqmId:32,
SlotIndex,
GemId:32,
Acc1/binary>> = Acc0,
 {{BucketType,EqmId,SlotIndex,GemId}, Acc1};

%% id = 5  
unpkg_msg(?MSG_EQUIP_UNEMBED_GEM, Acc0) ->
<<BucketType,
EqmId:32,
SlotIndex,
Acc1/binary>> = Acc0,
 {{BucketType,EqmId,SlotIndex}, Acc1};

%% id = 6  
unpkg_msg(?MSG_EQUIP_QIANG_HUA, Acc0) ->
<<BucketType,
EqmId:32,
IsDownLevelFree,
Acc1/binary>> = Acc0,
 {{BucketType,EqmId,IsDownLevelFree}, Acc1};

%% id = 7  
unpkg_msg(?MSG_EQUIP_HE_CHENG, Acc0) ->
<<HechengType,
BucketType,
EqmId:32,
ItemId1:32,
ItemId2:32,
L__attrList:16, Acc1/binary>> = Acc0,
{AttrList, Acc2} = unpkg_list_struct__(L__attrList, Acc1, [], fun unpkg_ano_s__0/1)
,
{{HechengType,BucketType,EqmId,ItemId1,ItemId2,AttrList}, Acc2};

%% id = 9  
unpkg_msg(?MSG_EQUIP_JI_CHENG, Acc0) ->
<<BucketType1,
EqmId:32,
BucketType2,
ItemId:32,
Acc1/binary>> = Acc0,
 {{BucketType1,EqmId,BucketType2,ItemId}, Acc1};

%% id = 10  
unpkg_msg(?MSG_EQUIP_UNEMBED_ALL_GEM, Acc0) ->
<<BucketType,
EqmId:32,
Acc1/binary>> = Acc0,
 {{BucketType,EqmId}, Acc1};

%% id = 11  
unpkg_msg(?MSG_EQUIP_JIANDING_ALL, Acc0) ->
{{}, Acc0};

%% id = 12  
unpkg_msg(?MSG_EQUIP_SLOT, Acc0) ->
<<BucketType,
EqmId:32,
SlotNum,
CostId:32,
Acc1/binary>> = Acc0,
 {{BucketType,EqmId,SlotNum,CostId}, Acc1};

%% id = 13  
unpkg_msg(?MSG_EQUIP_EXCHANGE, Acc0) ->
<<ItemId:32,
Acc1/binary>> = Acc0,
 {{ItemId}, Acc1};

%% id = 14  
unpkg_msg(?MSG_EQUIP_ONE_KEY_EXCHANGE, Acc0) ->
<<L__qualityList:16, Acc1/binary>> = Acc0,
{QualityList, Acc2} = unpkg_list_struct__(L__qualityList, Acc1, [], fun unpkg_ano_s__1/1)
,
{{QualityList}, Acc2};

%% id = 15  
unpkg_msg(?MSG_EQUIP_ACTIVATE_FUMO_MODE, Acc0) ->
<<FumoModeId:16,
Acc1/binary>> = Acc0,
 {{FumoModeId}, Acc1};

%% id = 16  
unpkg_msg(?MSG_EQUIP_IMBUE_WEAPON, Acc0) ->
<<FuMoId:16,
BucketType,
EqmId:32,
FumoType,
FmId:32,
Acc1/binary>> = Acc0,
 {{FuMoId,BucketType,EqmId,FumoType,FmId}, Acc1};

%% id = 17  
unpkg_msg(?MSG_EQUIP_CUI_QU, Acc0) ->
<<BucketType,
EqmId:32,
Acc1/binary>> = Acc0,
 {{BucketType,EqmId}, Acc1};

%% id = 18  
unpkg_msg(?MSG_EQUIP_FUMO_MODE_LIST, Acc0) ->
{{}, Acc0};

%% id = 19  
unpkg_msg(?MSG_EQUIP_EPIC_SLOT, Acc0) ->
<<BucketType,
EqmId:32,
CostId:32,
Acc1/binary>> = Acc0,
 {{BucketType,EqmId,CostId}, Acc1};

%% id = 20  
unpkg_msg(?MSG_EQUIP_EPIC_EMBED_GEM, Acc0) ->
<<BucketType,
EqmId:32,
GemId:32,
Acc1/binary>> = Acc0,
 {{BucketType,EqmId,GemId}, Acc1};

%% id = 21  
unpkg_msg(?MSG_EQUIP_EPIC_UNEMBED_GEM, Acc0) ->
<<BucketType,
EqmId:32,
Acc1/binary>> = Acc0,
 {{BucketType,EqmId}, Acc1};

%% id = 23  
unpkg_msg(?MSG_PART_QIANGHUA, Acc0) ->
<<PartType,
UseJuanZhou,
Acc1/binary>> = Acc0,
 {{PartType,UseJuanZhou}, Acc1};

%% id = 24  
unpkg_msg(?MSG_EQUIP_XILIAN, Acc0) ->
<<ItemId:32,
BucketType,
L__lockAttr:16, Acc1/binary>> = Acc0,
{LockAttr, Acc2} = 
unpkg_list_u8(L__lockAttr, Acc1, []),
{{ItemId,BucketType,LockAttr}, Acc2};
unpkg_msg(Id, _) -> ok.


unpkg_ano_s__0(Acc0) ->
<<JdAttrId,
JdAttrVal:32,
Acc1/binary>> = Acc0,
 {{JdAttrId,JdAttrVal}, Acc1}.
unpkg_ano_s__1(Acc0) ->
<<Quality,
Acc1/binary>> = Acc0,
 {{Quality}, Acc1}.


to_s(?MSG_EQUIP_DRESS) -> <<"MSG_EQUIP_DRESS">>; %% high 4, id 1
to_s(?MSG_EQUIP_UNDRESS) -> <<"MSG_EQUIP_UNDRESS">>; %% high 4, id 2
to_s(?MSG_EQUIP_JIANDING) -> <<"MSG_EQUIP_JIANDING">>; %% high 4, id 3
to_s(?MSG_EQUIP_EMBED_GEM) -> <<"MSG_EQUIP_EMBED_GEM">>; %% high 4, id 4
to_s(?MSG_EQUIP_UNEMBED_GEM) -> <<"MSG_EQUIP_UNEMBED_GEM">>; %% high 4, id 5
to_s(?MSG_EQUIP_QIANG_HUA) -> <<"MSG_EQUIP_QIANG_HUA">>; %% high 4, id 6
to_s(?MSG_EQUIP_HE_CHENG) -> <<"MSG_EQUIP_HE_CHENG">>; %% high 4, id 7
to_s(?MSG_EQUIP_JI_CHENG) -> <<"MSG_EQUIP_JI_CHENG">>; %% high 4, id 9
to_s(?MSG_EQUIP_UNEMBED_ALL_GEM) -> <<"MSG_EQUIP_UNEMBED_ALL_GEM">>; %% high 4, id 10
to_s(?MSG_EQUIP_JIANDING_ALL) -> <<"MSG_EQUIP_JIANDING_ALL">>; %% high 4, id 11
to_s(?MSG_EQUIP_SLOT) -> <<"MSG_EQUIP_SLOT">>; %% high 4, id 12
to_s(?MSG_EQUIP_EXCHANGE) -> <<"MSG_EQUIP_EXCHANGE">>; %% high 4, id 13
to_s(?MSG_EQUIP_ONE_KEY_EXCHANGE) -> <<"MSG_EQUIP_ONE_KEY_EXCHANGE">>; %% high 4, id 14
to_s(?MSG_EQUIP_ACTIVATE_FUMO_MODE) -> <<"MSG_EQUIP_ACTIVATE_FUMO_MODE">>; %% high 4, id 15
to_s(?MSG_EQUIP_IMBUE_WEAPON) -> <<"MSG_EQUIP_IMBUE_WEAPON">>; %% high 4, id 16
to_s(?MSG_EQUIP_CUI_QU) -> <<"MSG_EQUIP_CUI_QU">>; %% high 4, id 17
to_s(?MSG_EQUIP_FUMO_MODE_LIST) -> <<"MSG_EQUIP_FUMO_MODE_LIST">>; %% high 4, id 18
to_s(?MSG_EQUIP_EPIC_SLOT) -> <<"MSG_EQUIP_EPIC_SLOT">>; %% high 4, id 19
to_s(?MSG_EQUIP_EPIC_EMBED_GEM) -> <<"MSG_EQUIP_EPIC_EMBED_GEM">>; %% high 4, id 20
to_s(?MSG_EQUIP_EPIC_UNEMBED_GEM) -> <<"MSG_EQUIP_EPIC_UNEMBED_GEM">>; %% high 4, id 21
to_s(?MSG_EQUIP_PART_QAINGHUA_INIT) -> <<"MSG_EQUIP_PART_QAINGHUA_INIT">>; %% high 4, id 22
to_s(?MSG_PART_QIANGHUA) -> <<"MSG_PART_QIANGHUA">>; %% high 4, id 23
to_s(?MSG_EQUIP_XILIAN) -> <<"MSG_EQUIP_XILIAN">>; %% high 4, id 24
to_s(_) -> <<"unknown msg">>.
unpkg_list_struct__(0, Bin, List, _Fn) -> {lists:reverse(List), Bin};
unpkg_list_struct__(L, Bin, List, Fn) -> {E, Bin1} = Fn(Bin), unpkg_list_struct__(L-1, Bin1, [E|List], Fn).
unpkg_list_u8(0, Bin, List) -> {lists:reverse(List), Bin};
unpkg_list_u8(Len, Bin, List) -> 
 <<E,Bin1/binary>> = Bin,
unpkg_list_u8(Len-1, Bin1, [E|List]).
