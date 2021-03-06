%% Auto generated by sproto from pet_new.sproto
%% Don't edit it.

-module(pet_new_sproto).
-export([pkg_msg/2, unpkg_msg/2, to_s/1]).
-include("pet_new_sproto.hrl").

%% id=1  
pkg_msg(?MSG_PET_NEW_PET_LIST, {Info}) ->
<<?MSG_PET_NEW_PET_LIST:16, 
Info/binary>>
;

%% id=2  
pkg_msg(?MSG_PET_NEW_UPGRADE, {Id, Level, Exp}) ->
<<?MSG_PET_NEW_UPGRADE:16, 
Id:32,
    Level,
    Exp:64>>
;

%% id=3  
pkg_msg(?MSG_PET_NEW_ADVANCE, {Id, Advance}) ->
<<?MSG_PET_NEW_ADVANCE:16, 
Id:32,
    Advance>>
;

%% id=4  
pkg_msg(?MSG_PET_NEW_UPGRADE_SKILL, {Id, Level}) ->
<<?MSG_PET_NEW_UPGRADE_SKILL:16, 
Id:32,
    Level>>
;

%% id=5  
pkg_msg(?MSG_PET_NEW_DEL, {Id}) ->
<<?MSG_PET_NEW_DEL:16, 
Id:32>>
;

%% id=6  
pkg_msg(?MSG_PET_NEW_UPDATE_AND_ADD, {Info}) ->
<<?MSG_PET_NEW_UPDATE_AND_ADD:16, 
Info/binary>>
;

%% id=7  
pkg_msg(?MSG_PET_NEW_PASSIVITY_SKILL_INLAY, {}) ->
<<?MSG_PET_NEW_PASSIVITY_SKILL_INLAY:16>> 
;

%% id=8  
pkg_msg(?MSG_PET_NEW_SHANGZHEN, {}) ->
<<?MSG_PET_NEW_SHANGZHEN:16>> 
;

%% id=9  
pkg_msg(?MSG_PET_NEW_GAN, {Id, Status}) ->
<<?MSG_PET_NEW_GAN:16, 
Id:32,
    Status>>
;

%% id=10  
pkg_msg(?MSG_PET_NEW_FENGYIN, {}) ->
<<?MSG_PET_NEW_FENGYIN:16>> 
;

%% id=11  
pkg_msg(?MSG_PET_NEW_SHANGZHEN_LIST, {Info}) ->
<<?MSG_PET_NEW_SHANGZHEN_LIST:16, 
Info/binary>>
;
pkg_msg(Id, _) -> ok.



%% id = 1  
unpkg_msg(?MSG_PET_NEW_PET_LIST, Acc0) ->
{{}, Acc0};

%% id = 2  
unpkg_msg(?MSG_PET_NEW_UPGRADE, Acc0) ->
<<Id:32,
Chongwudanid:32,
Num:16,
Acc1/binary>> = Acc0,
 {{Id,Chongwudanid,Num}, Acc1};

%% id = 3  
unpkg_msg(?MSG_PET_NEW_ADVANCE, Acc0) ->
<<Id:32,
Count,
Acc1/binary>> = Acc0,
 {{Id,Count}, Acc1};

%% id = 4  
unpkg_msg(?MSG_PET_NEW_UPGRADE_SKILL, Acc0) ->
<<Id:32,
Count,
Acc1/binary>> = Acc0,
 {{Id,Count}, Acc1};

%% id = 5  
unpkg_msg(?MSG_PET_NEW_DEL, Acc0) ->
<<Id:32,
Acc1/binary>> = Acc0,
 {{Id}, Acc1};

%% id = 7  
unpkg_msg(?MSG_PET_NEW_PASSIVITY_SKILL_INLAY, Acc0) ->
<<Id:32,
Slot,
Eggid:32,
Acc1/binary>> = Acc0,
 {{Id,Slot,Eggid}, Acc1};

%% id = 8  
unpkg_msg(?MSG_PET_NEW_SHANGZHEN, Acc0) ->
<<Id:32,
Status,
Index,
Acc1/binary>> = Acc0,
 {{Id,Status,Index}, Acc1};

%% id = 9  
unpkg_msg(?MSG_PET_NEW_GAN, Acc0) ->
<<Id:32,
Status,
Acc1/binary>> = Acc0,
 {{Id,Status}, Acc1};

%% id = 10  
unpkg_msg(?MSG_PET_NEW_FENGYIN, Acc0) ->
<<Id:32,
Acc1/binary>> = Acc0,
 {{Id}, Acc1};

%% id = 11  
unpkg_msg(?MSG_PET_NEW_SHANGZHEN_LIST, Acc0) ->
{{}, Acc0};
unpkg_msg(Id, _) -> ok.




to_s(?MSG_PET_NEW_PET_LIST) -> <<"MSG_PET_NEW_PET_LIST">>; %% high 43, id 1
to_s(?MSG_PET_NEW_UPGRADE) -> <<"MSG_PET_NEW_UPGRADE">>; %% high 43, id 2
to_s(?MSG_PET_NEW_ADVANCE) -> <<"MSG_PET_NEW_ADVANCE">>; %% high 43, id 3
to_s(?MSG_PET_NEW_UPGRADE_SKILL) -> <<"MSG_PET_NEW_UPGRADE_SKILL">>; %% high 43, id 4
to_s(?MSG_PET_NEW_DEL) -> <<"MSG_PET_NEW_DEL">>; %% high 43, id 5
to_s(?MSG_PET_NEW_UPDATE_AND_ADD) -> <<"MSG_PET_NEW_UPDATE_AND_ADD">>; %% high 43, id 6
to_s(?MSG_PET_NEW_PASSIVITY_SKILL_INLAY) -> <<"MSG_PET_NEW_PASSIVITY_SKILL_INLAY">>; %% high 43, id 7
to_s(?MSG_PET_NEW_SHANGZHEN) -> <<"MSG_PET_NEW_SHANGZHEN">>; %% high 43, id 8
to_s(?MSG_PET_NEW_GAN) -> <<"MSG_PET_NEW_GAN">>; %% high 43, id 9
to_s(?MSG_PET_NEW_FENGYIN) -> <<"MSG_PET_NEW_FENGYIN">>; %% high 43, id 10
to_s(?MSG_PET_NEW_SHANGZHEN_LIST) -> <<"MSG_PET_NEW_SHANGZHEN_LIST">>; %% high 43, id 11
to_s(_) -> <<"unknown msg">>.
