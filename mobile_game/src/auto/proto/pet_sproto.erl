%% Auto generated by sproto from pet.sproto
%% Don't edit it.

-module(pet_sproto).
-export([pkg_msg/2, unpkg_msg/2, to_s/1]).
-include("pet_sproto.hrl").

%% id=1  
pkg_msg(?MSG_PET_LIST, {Way, Pet_list}) ->
<<?MSG_PET_LIST:16, 
Way,
    (length(Pet_list)):16, (iolist_to_binary([<<
Id:32,
    Bid:32,
    (byte_size(Name)), Name/binary,
    Level:32,
    Exp:32,
    Tacit_value,
    Status,
    Quality,
    Facade:32,
    Advance_count,
    Exclusive_skill:32,
    (begin {S1, S2, S3}=Initiative_skill, <<
S1:32,
    S2:32,
    S3:32>>
 end)/binary,
    (begin {S_1, S_2, S_3, S_4, S_5, S_6}=Passivity_skill, <<
S_1:32,
    S_2:32,
    S_3:32,
    S_4:32,
    S_5:32,
    S_6:32>>
 end)/binary,
    (begin {AttId, AttHp, AttMp, AttSp, AttNp, AttStrength, AttIntellect, AttNimble, AttStrong, AttAtk, AttDef, AttCrit, AttBlock, AttPliable, AttPure_atk, AttBreak_def, AttAtk_deep, AttAtk_free, AttAtk_speed, AttPrecise, AttThunder_atk, AttThunder_def, AttFire_atk, AttFire_def, AttIce_atk, AttIce_def, AttMove_speed, AttRun_speed, AttSuckBlood, AttReverse, AttBati}=Attr, <<
AttId,
    AttHp:32,
    AttMp:32,
    AttSp:32,
    AttNp:32,
    AttStrength:32,
    AttIntellect:32,
    AttNimble:32,
    AttStrong:32,
    AttAtk:32,
    AttDef:32,
    AttCrit:32,
    AttBlock:32,
    AttPliable:32,
    AttPure_atk:32,
    AttBreak_def:32,
    AttAtk_deep:32,
    AttAtk_free:32,
    AttAtk_speed:32,
    AttPrecise:32,
    AttThunder_atk:32,
    AttThunder_def:32,
    AttFire_atk:32,
    AttFire_def:32,
    AttIce_atk:32,
    AttIce_def:32,
    AttMove_speed:32,
    AttRun_speed:32,
    AttSuckBlood:32,
    AttReverse:32,
    AttBati:32>>
 end)/binary,
    Pet_power:32>>
|| {Id, Bid, Name, Level, Exp, Tacit_value, Status, Quality, Facade, Advance_count, Exclusive_skill, Initiative_skill, Passivity_skill, Attr, Pet_power} <- Pet_list]))/binary >>
;

%% id=2  
pkg_msg(?MSG_PET_SEAL, {}) ->
<<?MSG_PET_SEAL:16>> 
;

%% id=3  
pkg_msg(?MSG_PET_SKILL_STUDY, {Petid, Pet_skill_pos, Skill_id}) ->
<<?MSG_PET_SKILL_STUDY:16, 
Petid:32,
    Pet_skill_pos,
    Skill_id:32>>
;

%% id=4  
pkg_msg(?MSG_PET_SKILL_FORGET, {Petid, Pet_skill_id}) ->
<<?MSG_PET_SKILL_FORGET:16, 
Petid:32,
    Pet_skill_id:32>>
;

%% id=5  
pkg_msg(?MSG_PET_SKILL_UPLEVEL, {Petid, Pet_skill_pos, Skill_id}) ->
<<?MSG_PET_SKILL_UPLEVEL:16, 
Petid:32,
    Pet_skill_pos,
    Skill_id:32>>
;

%% id=6  
pkg_msg(?MSG_PET_ADVANCE, {Petid}) ->
<<?MSG_PET_ADVANCE:16, 
Petid:32>>
;

%% id=7  
pkg_msg(?MSG_PET_UPLEVEL, {Petid, Level}) ->
<<?MSG_PET_UPLEVEL:16, 
Petid:32,
    Level:32>>
;

%% id=8  
pkg_msg(?MSG_PET_TREASURE, {Petid, Treasureid, Finish_time}) ->
<<?MSG_PET_TREASURE:16, 
Petid:32,
    Treasureid:32,
    Finish_time:32>>
;

%% id=9  
pkg_msg(?MSG_PET_CANCEL_TREASURE, {Petid, Treasureid}) ->
<<?MSG_PET_CANCEL_TREASURE:16, 
Petid:32,
    Treasureid:32>>
;

%% id=10  
pkg_msg(?MSG_PET_SKILL_POS_OPEN, {Petid, Type, Position}) ->
<<?MSG_PET_SKILL_POS_OPEN:16, 
Petid:32,
    Type,
    Position>>
;

%% id=11  
pkg_msg(?MSG_PET_STATE, {Petid, Newstate}) ->
<<?MSG_PET_STATE:16, 
Petid:32,
    Newstate>>
;

%% id=12  
pkg_msg(?MSG_PET_ATTR_CHANGE, {Attr}) ->
<<?MSG_PET_ATTR_CHANGE:16, 
(begin {AttId, AttHp, AttMp, AttSp, AttNp, AttStrength, AttIntellect, AttNimble, AttStrong, AttAtk, AttDef, AttCrit, AttBlock, AttPliable, AttPure_atk, AttBreak_def, AttAtk_deep, AttAtk_free, AttAtk_speed, AttPrecise, AttThunder_atk, AttThunder_def, AttFire_atk, AttFire_def, AttIce_atk, AttIce_def, AttMove_speed, AttRun_speed, AttSuckBlood, AttReverse, AttBati}=Attr, <<
AttId,
    AttHp:32,
    AttMp:32,
    AttSp:32,
    AttNp:32,
    AttStrength:32,
    AttIntellect:32,
    AttNimble:32,
    AttStrong:32,
    AttAtk:32,
    AttDef:32,
    AttCrit:32,
    AttBlock:32,
    AttPliable:32,
    AttPure_atk:32,
    AttBreak_def:32,
    AttAtk_deep:32,
    AttAtk_free:32,
    AttAtk_speed:32,
    AttPrecise:32,
    AttThunder_atk:32,
    AttThunder_def:32,
    AttFire_atk:32,
    AttFire_def:32,
    AttIce_atk:32,
    AttIce_def:32,
    AttMove_speed:32,
    AttRun_speed:32,
    AttSuckBlood:32,
    AttReverse:32,
    AttBati:32>>
 end)/binary>>
;

%% id=13  
pkg_msg(?MSG_PET_TREASURE_LIST, {Lists}) ->
<<?MSG_PET_TREASURE_LIST:16, 
(length(Lists)):16, (iolist_to_binary([<<
Petid:32,
    Treasureid:32,
    Finish_time:32>>
|| {Petid, Treasureid, Finish_time} <- Lists]))/binary >>
;

%% id=14  
pkg_msg(?MSG_PET_TREASURE_LOG_LIST, {Lists}) ->
<<?MSG_PET_TREASURE_LOG_LIST:16, 
(length(Lists)):16, (iolist_to_binary([<<
(byte_size(Name)), Name/binary,
    Treasureid:32,
    (length(Prizes)):16, (iolist_to_binary([<<
ItemBid:32,
    Count:16>>
|| {ItemBid, Count} <- Prizes]))/binary ,
    Finish_time:32>>
|| {Name, Treasureid, Prizes, Finish_time} <- Lists]))/binary >>
;

%% id=15  
pkg_msg(?MSG_PUSH_PET_TREASURE_FINISH, {Level, Exp}) ->
<<?MSG_PUSH_PET_TREASURE_FINISH:16, 
Level,
    Exp:32>>
;

%% id=16  
pkg_msg(?MSG_PET_EGG_DATA, {Pet}) ->
<<?MSG_PET_EGG_DATA:16, 
(begin {Id, Bid, Name, Level, Exp, Tacit_value, Status, Quality, Facade, Advance_count, Exclusive_skill, Initiative_skill, Passivity_skill, Attr, Pet_power}=Pet, <<
Id:32,
    Bid:32,
    (byte_size(Name)), Name/binary,
    Level:32,
    Exp:32,
    Tacit_value,
    Status,
    Quality,
    Facade:32,
    Advance_count,
    Exclusive_skill:32,
    (begin {S1, S2, S3}=Initiative_skill, <<
S1:32,
    S2:32,
    S3:32>>
 end)/binary,
    (begin {S_1, S_2, S_3, S_4, S_5, S_6}=Passivity_skill, <<
S_1:32,
    S_2:32,
    S_3:32,
    S_4:32,
    S_5:32,
    S_6:32>>
 end)/binary,
    (begin {AttId, AttHp, AttMp, AttSp, AttNp, AttStrength, AttIntellect, AttNimble, AttStrong, AttAtk, AttDef, AttCrit, AttBlock, AttPliable, AttPure_atk, AttBreak_def, AttAtk_deep, AttAtk_free, AttAtk_speed, AttPrecise, AttThunder_atk, AttThunder_def, AttFire_atk, AttFire_def, AttIce_atk, AttIce_def, AttMove_speed, AttRun_speed, AttSuckBlood, AttReverse, AttBati}=Attr, <<
AttId,
    AttHp:32,
    AttMp:32,
    AttSp:32,
    AttNp:32,
    AttStrength:32,
    AttIntellect:32,
    AttNimble:32,
    AttStrong:32,
    AttAtk:32,
    AttDef:32,
    AttCrit:32,
    AttBlock:32,
    AttPliable:32,
    AttPure_atk:32,
    AttBreak_def:32,
    AttAtk_deep:32,
    AttAtk_free:32,
    AttAtk_speed:32,
    AttPrecise:32,
    AttThunder_atk:32,
    AttThunder_def:32,
    AttFire_atk:32,
    AttFire_def:32,
    AttIce_atk:32,
    AttIce_def:32,
    AttMove_speed:32,
    AttRun_speed:32,
    AttSuckBlood:32,
    AttReverse:32,
    AttBati:32>>
 end)/binary,
    Pet_power:32>>
 end)/binary>>
;
pkg_msg(Id, _) -> ok.



%% id = 1  
unpkg_msg(?MSG_PET_LIST, Acc0) ->
{{}, Acc0};

%% id = 2  
unpkg_msg(?MSG_PET_SEAL, Acc0) ->
<<Petid:32,
Acc1/binary>> = Acc0,
 {{Petid}, Acc1};

%% id = 3  
unpkg_msg(?MSG_PET_SKILL_STUDY, Acc0) ->
<<Petid:32,
Pet_skill_pos,
Skill_book:32,
Acc1/binary>> = Acc0,
 {{Petid,Pet_skill_pos,Skill_book}, Acc1};

%% id = 4  
unpkg_msg(?MSG_PET_SKILL_FORGET, Acc0) ->
<<Petid:32,
Skill_id:32,
Acc1/binary>> = Acc0,
 {{Petid,Skill_id}, Acc1};

%% id = 5  
unpkg_msg(?MSG_PET_SKILL_UPLEVEL, Acc0) ->
<<Petid:32,
Skill_id:32,
Acc1/binary>> = Acc0,
 {{Petid,Skill_id}, Acc1};

%% id = 6  
unpkg_msg(?MSG_PET_ADVANCE, Acc0) ->
<<Petid:32,
L__costs:16, Acc1/binary>> = Acc0,
{Costs, Acc2} = unpkg_list_struct__(L__costs, Acc1, [], fun unpkg_ano_s__0/1)
,
{{Petid,Costs}, Acc2};

%% id = 8  
unpkg_msg(?MSG_PET_TREASURE, Acc0) ->
<<Petid:32,
Treasureid:32,
Acc1/binary>> = Acc0,
 {{Petid,Treasureid}, Acc1};

%% id = 9  
unpkg_msg(?MSG_PET_CANCEL_TREASURE, Acc0) ->
<<Petid:32,
Treasureid:32,
Acc1/binary>> = Acc0,
 {{Petid,Treasureid}, Acc1};

%% id = 10  
unpkg_msg(?MSG_PET_SKILL_POS_OPEN, Acc0) ->
<<Petid:32,
Type,
Position,
Acc1/binary>> = Acc0,
 {{Petid,Type,Position}, Acc1};

%% id = 11  
unpkg_msg(?MSG_PET_STATE, Acc0) ->
<<Petid:32,
Acc1/binary>> = Acc0,
 {{Petid}, Acc1};

%% id = 14  
unpkg_msg(?MSG_PET_TREASURE_LOG_LIST, Acc0) ->
{{}, Acc0};

%% id = 16  
unpkg_msg(?MSG_PET_EGG_DATA, Acc0) ->
<<Pet_id:32,
Acc1/binary>> = Acc0,
 {{Pet_id}, Acc1};
unpkg_msg(Id, _) -> ok.


unpkg_ano_s__0(Acc0) ->
<<Type,
Value:32,
Acc1/binary>> = Acc0,
 {{Type,Value}, Acc1}.


to_s(?MSG_PET_LIST) -> <<"MSG_PET_LIST">>; %% high 19, id 1
to_s(?MSG_PET_SEAL) -> <<"MSG_PET_SEAL">>; %% high 19, id 2
to_s(?MSG_PET_SKILL_STUDY) -> <<"MSG_PET_SKILL_STUDY">>; %% high 19, id 3
to_s(?MSG_PET_SKILL_FORGET) -> <<"MSG_PET_SKILL_FORGET">>; %% high 19, id 4
to_s(?MSG_PET_SKILL_UPLEVEL) -> <<"MSG_PET_SKILL_UPLEVEL">>; %% high 19, id 5
to_s(?MSG_PET_ADVANCE) -> <<"MSG_PET_ADVANCE">>; %% high 19, id 6
to_s(?MSG_PET_UPLEVEL) -> <<"MSG_PET_UPLEVEL">>; %% high 19, id 7
to_s(?MSG_PET_TREASURE) -> <<"MSG_PET_TREASURE">>; %% high 19, id 8
to_s(?MSG_PET_CANCEL_TREASURE) -> <<"MSG_PET_CANCEL_TREASURE">>; %% high 19, id 9
to_s(?MSG_PET_SKILL_POS_OPEN) -> <<"MSG_PET_SKILL_POS_OPEN">>; %% high 19, id 10
to_s(?MSG_PET_STATE) -> <<"MSG_PET_STATE">>; %% high 19, id 11
to_s(?MSG_PET_ATTR_CHANGE) -> <<"MSG_PET_ATTR_CHANGE">>; %% high 19, id 12
to_s(?MSG_PET_TREASURE_LIST) -> <<"MSG_PET_TREASURE_LIST">>; %% high 19, id 13
to_s(?MSG_PET_TREASURE_LOG_LIST) -> <<"MSG_PET_TREASURE_LOG_LIST">>; %% high 19, id 14
to_s(?MSG_PUSH_PET_TREASURE_FINISH) -> <<"MSG_PUSH_PET_TREASURE_FINISH">>; %% high 19, id 15
to_s(?MSG_PET_EGG_DATA) -> <<"MSG_PET_EGG_DATA">>; %% high 19, id 16
to_s(_) -> <<"unknown msg">>.
unpkg_list_struct__(0, Bin, List, _Fn) -> {lists:reverse(List), Bin};
unpkg_list_struct__(L, Bin, List, Fn) -> {E, Bin1} = Fn(Bin), unpkg_list_struct__(L-1, Bin1, [E|List], Fn).
