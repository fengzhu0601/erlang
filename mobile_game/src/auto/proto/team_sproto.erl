%% Auto generated by sproto from team.sproto
%% Don't edit it.

-module(team_sproto).
-export([pkg_msg/2, unpkg_msg/2, to_s/1]).
-include("team_sproto.hrl").

%% id=1  
pkg_msg(?MSG_TEAM_CREATE, {Teamid, Teamtype, Teamname, Teammembers}) ->
<<?MSG_TEAM_CREATE:16, 
Teamid:32,
    Teamtype,
    (byte_size(Teamname)), Teamname/binary,
    (length(Teammembers)):16, (iolist_to_binary([<<
Id:64,
    (byte_size(Name)), Name/binary,
    Level,
    Jifen:32,
    Combar_power:32,
    Carrer,
    MaxHp:32,
    Online>>
|| {Id, Name, Level, Jifen, Combar_power, Carrer, MaxHp, Online} <- Teammembers]))/binary >>
;

%% id=2  
pkg_msg(?MSG_TEAM_QUIT, {Id}) ->
<<?MSG_TEAM_QUIT:16, 
Id:64>>
;

%% id=4  
pkg_msg(?MSG_TEAM_JOIN, {Teamid, Teamtype, Teamname, Teammembers}) ->
<<?MSG_TEAM_JOIN:16, 
Teamid:32,
    Teamtype,
    (byte_size(Teamname)), Teamname/binary,
    (length(Teammembers)):16, (iolist_to_binary([<<
Id:64,
    (byte_size(Name)), Name/binary,
    Level,
    Jifen:32,
    Combar_power:32,
    Carrer,
    MaxHp:32,
    Online>>
|| {Id, Name, Level, Jifen, Combar_power, Carrer, MaxHp, Online} <- Teammembers]))/binary >>
;

%% id=5  
pkg_msg(?MSG_TEAM_MEMBER_JOIN, {TeamMember}) ->
<<?MSG_TEAM_MEMBER_JOIN:16, 
(begin {Id, Name, Level, Jifen, Combar_power, Carrer, MaxHp, Online}=TeamMember, <<
Id:64,
    (byte_size(Name)), Name/binary,
    Level,
    Jifen:32,
    Combar_power:32,
    Carrer,
    MaxHp:32,
    Online>>
 end)/binary>>
;

%% id=6  
pkg_msg(?MSG_TEAM_DISSOLVE, {}) ->
<<?MSG_TEAM_DISSOLVE:16>> 
;

%% id=7  
pkg_msg(?MSG_TEAM_GC_LIST_BY_TYPE, {Teammembers}) ->
<<?MSG_TEAM_GC_LIST_BY_TYPE:16, 
Teammembers/binary>>
;

%% id=8  
pkg_msg(?MSG_TEAM_GC_SHENQING_LIST, {PlayerInfo}) ->
<<?MSG_TEAM_GC_SHENQING_LIST:16, 
PlayerInfo/binary>>
;

%% id=9  
pkg_msg(?MSG_TEAM_GC_DEAL_SHENQING, {IsOk}) ->
<<?MSG_TEAM_GC_DEAL_SHENQING:16, 
IsOk>>
;

%% id=12  
pkg_msg(?MSG_TEAM_GC_NOTICE_JOIN_MY_TEAM_OF_PLAYERS, {TeamId, Name}) ->
<<?MSG_TEAM_GC_NOTICE_JOIN_MY_TEAM_OF_PLAYERS:16, 
TeamId:32,
    (byte_size(Name)), Name/binary>>
;

%% id=13  
pkg_msg(?MSG_TEAM_GC_APPLY_JOIN, {IsOk}) ->
<<?MSG_TEAM_GC_APPLY_JOIN:16, 
IsOk>>
;

%% id=17  
pkg_msg(?MSG_TEAM_NOTICE_MASTER_REFUSE_ASK, {Name}) ->
<<?MSG_TEAM_NOTICE_MASTER_REFUSE_ASK:16, 
(byte_size(Name)), Name/binary>>
;

%% id=19  
pkg_msg(?MSG_TEAM_INVITE_RESULT, {Player_id, Name, Result}) ->
<<?MSG_TEAM_INVITE_RESULT:16, 
Player_id:64,
    (byte_size(Name)), Name/binary,
    Result>>
;

%% id=20  
pkg_msg(?MSG_TEAM_BE_INVITE, {Player_id, Name, Type, Scene_id}) ->
<<?MSG_TEAM_BE_INVITE:16, 
Player_id:64,
    (byte_size(Name)), Name/binary,
    Type,
    Scene_id:32>>
;

%% id=21  
pkg_msg(?MSG_TEAM_HANDLE_INVITE, {Err_code}) ->
<<?MSG_TEAM_HANDLE_INVITE:16, 
Err_code>>
;

%% id=23  
pkg_msg(?MSG_TEAM_GET_ALL_INFO, {Teamlist}) ->
<<?MSG_TEAM_GET_ALL_INFO:16, 
(length(Teamlist)):16, (iolist_to_binary([<<
Team_id:32,
    (byte_size(Team_name)), Team_name/binary,
    Master_id:64,
    (length(Members)):16, (iolist_to_binary([<<
PlayerId:64,
    (byte_size(PlayerName)), PlayerName/binary,
    PlayerJob,
    PlayerLev,
    PlayerPower:32>>
|| {PlayerId, PlayerName, PlayerJob, PlayerLev, PlayerPower} <- Members]))/binary >>
|| {Team_id, Team_name, Master_id, Members} <- Teamlist]))/binary >>
;
pkg_msg(Id, _) -> ok.



%% id = 1  
unpkg_msg(?MSG_TEAM_CREATE, Acc0) ->
<<TeamType,
TeamNameLen, TeamName:TeamNameLen/binary,
Acc1/binary>> = Acc0,
 {{TeamType,TeamName}, Acc1};

%% id = 2  
unpkg_msg(?MSG_TEAM_QUIT, Acc0) ->
{{}, Acc0};

%% id = 3  
unpkg_msg(?MSG_TEAM_KICKOUT, Acc0) ->
<<Id:64,
Acc1/binary>> = Acc0,
 {{Id}, Acc1};

%% id = 4  
unpkg_msg(?MSG_TEAM_JOIN, Acc0) ->
<<TeamId:32,
Acc1/binary>> = Acc0,
 {{TeamId}, Acc1};

%% id = 6  
unpkg_msg(?MSG_TEAM_DISSOLVE, Acc0) ->
{{}, Acc0};

%% id = 7  
unpkg_msg(?MSG_TEAM_GC_LIST_BY_TYPE, Acc0) ->
<<Type,
Acc1/binary>> = Acc0,
 {{Type}, Acc1};

%% id = 8  
unpkg_msg(?MSG_TEAM_GC_SHENQING_LIST, Acc0) ->
{{}, Acc0};

%% id = 9  
unpkg_msg(?MSG_TEAM_GC_DEAL_SHENQING, Acc0) ->
<<IsOk,
PlayerId:64,
Acc1/binary>> = Acc0,
 {{IsOk,PlayerId}, Acc1};

%% id = 10  
unpkg_msg(?MSG_TEAM_GC_RE, Acc0) ->
<<ReOrUre,
Acc1/binary>> = Acc0,
 {{ReOrUre}, Acc1};

%% id = 11  
unpkg_msg(?MSG_TEAM_GC_JOIN_MY_TAEA, Acc0) ->
<<Size,
PlayerIdList/binary>> = Acc0,
 {{Size,PlayerIdList}, <<>>};

%% id = 13  
unpkg_msg(?MSG_TEAM_GC_APPLY_JOIN, Acc0) ->
<<TeamId:32,
Acc1/binary>> = Acc0,
 {{TeamId}, Acc1};

%% id = 14  
unpkg_msg(?MSG_TEAM_GC_FAST_JOIN, Acc0) ->
<<TeamType,
Acc1/binary>> = Acc0,
 {{TeamType}, Acc1};

%% id = 15  
unpkg_msg(?MSG_TEAM_AUTO_JOIN_FLG, Acc0) ->
<<Flg,
Acc1/binary>> = Acc0,
 {{Flg}, Acc1};

%% id = 16  
unpkg_msg(?MSG_TEAM_REFUSE_ASK, Acc0) ->
<<TeamId:32,
Acc1/binary>> = Acc0,
 {{TeamId}, Acc1};

%% id = 18  
unpkg_msg(?MSG_TEAM_INVITE, Acc0) ->
<<Player_id:64,
Type,
Scene_id:32,
Acc1/binary>> = Acc0,
 {{Player_id,Type,Scene_id}, Acc1};

%% id = 21  
unpkg_msg(?MSG_TEAM_HANDLE_INVITE, Acc0) ->
<<Player_id:64,
Type,
Scene_id:32,
Result,
Acc1/binary>> = Acc0,
 {{Player_id,Type,Scene_id,Result}, Acc1};

%% id = 22  
unpkg_msg(?MSG_TEAM_CALL_TEAMMATE, Acc0) ->
<<Type,
Scene_id:32,
Acc1/binary>> = Acc0,
 {{Type,Scene_id}, Acc1};

%% id = 23  
unpkg_msg(?MSG_TEAM_GET_ALL_INFO, Acc0) ->
<<Type,
Scene_id:32,
Acc1/binary>> = Acc0,
 {{Type,Scene_id}, Acc1};
unpkg_msg(Id, _) -> ok.




to_s(?MSG_TEAM_CREATE) -> <<"MSG_TEAM_CREATE">>; %% high 21, id 1
to_s(?MSG_TEAM_QUIT) -> <<"MSG_TEAM_QUIT">>; %% high 21, id 2
to_s(?MSG_TEAM_KICKOUT) -> <<"MSG_TEAM_KICKOUT">>; %% high 21, id 3
to_s(?MSG_TEAM_JOIN) -> <<"MSG_TEAM_JOIN">>; %% high 21, id 4
to_s(?MSG_TEAM_MEMBER_JOIN) -> <<"MSG_TEAM_MEMBER_JOIN">>; %% high 21, id 5
to_s(?MSG_TEAM_DISSOLVE) -> <<"MSG_TEAM_DISSOLVE">>; %% high 21, id 6
to_s(?MSG_TEAM_GC_LIST_BY_TYPE) -> <<"MSG_TEAM_GC_LIST_BY_TYPE">>; %% high 21, id 7
to_s(?MSG_TEAM_GC_SHENQING_LIST) -> <<"MSG_TEAM_GC_SHENQING_LIST">>; %% high 21, id 8
to_s(?MSG_TEAM_GC_DEAL_SHENQING) -> <<"MSG_TEAM_GC_DEAL_SHENQING">>; %% high 21, id 9
to_s(?MSG_TEAM_GC_RE) -> <<"MSG_TEAM_GC_RE">>; %% high 21, id 10
to_s(?MSG_TEAM_GC_JOIN_MY_TAEA) -> <<"MSG_TEAM_GC_JOIN_MY_TAEA">>; %% high 21, id 11
to_s(?MSG_TEAM_GC_NOTICE_JOIN_MY_TEAM_OF_PLAYERS) -> <<"MSG_TEAM_GC_NOTICE_JOIN_MY_TEAM_OF_PLAYERS">>; %% high 21, id 12
to_s(?MSG_TEAM_GC_APPLY_JOIN) -> <<"MSG_TEAM_GC_APPLY_JOIN">>; %% high 21, id 13
to_s(?MSG_TEAM_GC_FAST_JOIN) -> <<"MSG_TEAM_GC_FAST_JOIN">>; %% high 21, id 14
to_s(?MSG_TEAM_AUTO_JOIN_FLG) -> <<"MSG_TEAM_AUTO_JOIN_FLG">>; %% high 21, id 15
to_s(?MSG_TEAM_REFUSE_ASK) -> <<"MSG_TEAM_REFUSE_ASK">>; %% high 21, id 16
to_s(?MSG_TEAM_NOTICE_MASTER_REFUSE_ASK) -> <<"MSG_TEAM_NOTICE_MASTER_REFUSE_ASK">>; %% high 21, id 17
to_s(?MSG_TEAM_INVITE) -> <<"MSG_TEAM_INVITE">>; %% high 21, id 18
to_s(?MSG_TEAM_INVITE_RESULT) -> <<"MSG_TEAM_INVITE_RESULT">>; %% high 21, id 19
to_s(?MSG_TEAM_BE_INVITE) -> <<"MSG_TEAM_BE_INVITE">>; %% high 21, id 20
to_s(?MSG_TEAM_HANDLE_INVITE) -> <<"MSG_TEAM_HANDLE_INVITE">>; %% high 21, id 21
to_s(?MSG_TEAM_CALL_TEAMMATE) -> <<"MSG_TEAM_CALL_TEAMMATE">>; %% high 21, id 22
to_s(?MSG_TEAM_GET_ALL_INFO) -> <<"MSG_TEAM_GET_ALL_INFO">>; %% high 21, id 23
to_s(_) -> <<"unknown msg">>.