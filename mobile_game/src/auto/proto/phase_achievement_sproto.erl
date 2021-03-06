%% Auto generated by sproto from phase_achievement.sproto
%% Don't edit it.

-module(phase_achievement_sproto).
-export([pkg_msg/2, unpkg_msg/2, to_s/1]).
-include("phase_achievement_sproto.hrl").

%% id=1  
pkg_msg(?MSG_PHASE_ACHIEVEMENT_LIST, {Pc, Info}) ->
<<?MSG_PHASE_ACHIEVEMENT_LIST:16, 
(length(Pc)):16, (iolist_to_binary([<<
Goaltype,
    Count>>
|| {Goaltype, Count} <- Pc]))/binary ,
    (length(Info)):16, (iolist_to_binary([<<
Jieduan,
    Isget>>
|| {Jieduan, Isget} <- Info]))/binary >>
;

%% id=2  
pkg_msg(?MSG_PHASE_ACHIEVEMENT_PROGRESS, {Goaltype, Count}) ->
<<?MSG_PHASE_ACHIEVEMENT_PROGRESS:16, 
Goaltype,
    Count>>
;

%% id=3  
pkg_msg(?MSG_PHASE_ACHIEVEMENT_GET_PRIZE, {}) ->
<<?MSG_PHASE_ACHIEVEMENT_GET_PRIZE:16>> 
;
pkg_msg(Id, _) -> ok.



%% id = 1  
unpkg_msg(?MSG_PHASE_ACHIEVEMENT_LIST, Acc0) ->
{{}, Acc0};

%% id = 3  
unpkg_msg(?MSG_PHASE_ACHIEVEMENT_GET_PRIZE, Acc0) ->
<<Jieduan,
Acc1/binary>> = Acc0,
 {{Jieduan}, Acc1};
unpkg_msg(Id, _) -> ok.




to_s(?MSG_PHASE_ACHIEVEMENT_LIST) -> <<"MSG_PHASE_ACHIEVEMENT_LIST">>; %% high 39, id 1
to_s(?MSG_PHASE_ACHIEVEMENT_PROGRESS) -> <<"MSG_PHASE_ACHIEVEMENT_PROGRESS">>; %% high 39, id 2
to_s(?MSG_PHASE_ACHIEVEMENT_GET_PRIZE) -> <<"MSG_PHASE_ACHIEVEMENT_GET_PRIZE">>; %% high 39, id 3
to_s(_) -> <<"unknown msg">>.
