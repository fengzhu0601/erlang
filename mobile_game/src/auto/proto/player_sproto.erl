%% Auto generated by sproto from player.sproto
%% Don't edit it.

-module(player_sproto).
-export([pkg_msg/2, unpkg_msg/2, to_s/1]).
-include("player_sproto.hrl").

%% id=1  
pkg_msg(?MSG_PLAYER_ACCOUNT_LOGIN, {Finalplayer, Info}) ->
<<?MSG_PLAYER_ACCOUNT_LOGIN:16, 
Finalplayer,
    Info/binary>>
;

%% id=2  
pkg_msg(?MSG_PLAYER_ERROR, {CmdId, ErrCode, Arg}) ->
<<?MSG_PLAYER_ERROR:16, 
CmdId:16,
    ErrCode:16,
    Arg/binary>>
;

%% id=4  
pkg_msg(?MSG_PLAYER_CREATE_ROLE, {}) ->
<<?MSG_PLAYER_CREATE_ROLE:16>> 
;

%% id=8  
pkg_msg(?MSG_PLAYER_CLIENT_DATA_GET, {Type, Data}) ->
<<?MSG_PLAYER_CLIENT_DATA_GET:16, 
Type,
    Data/binary>>
;

%% id=9  
pkg_msg(?MSG_PLAYER_ONLINE_FINISH, {Uptime}) ->
<<?MSG_PLAYER_ONLINE_FINISH:16, 
Uptime:64>>
;

%% id=10  
pkg_msg(?MSG_PLAYER_ECHO, {Msg}) ->
<<?MSG_PLAYER_ECHO:16, 
Msg/binary>>
;

%% id=11  
pkg_msg(?MSG_PLAYER_GET_SERVER_TIME, {TimetampMsec}) ->
<<?MSG_PLAYER_GET_SERVER_TIME:16, 
TimetampMsec:64>>
;

%% id=15  
pkg_msg(?MSG_PLAYER_DATA_CHANGED, {Type, Value}) ->
<<?MSG_PLAYER_DATA_CHANGED:16, 
Type,
    Value:32>>
;

%% id=16  
pkg_msg(?MSG_PLAYER_ATTR_CHANGE, {Attr}) ->
<<?MSG_PLAYER_ATTR_CHANGE:16, 
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

%% id=17  
pkg_msg(?MSG_PLAYER_LOOKUP_PLAYER_ATTR, {Id, Name, Career, Level, CombatPower, Attr, EqmL, List}) ->
<<?MSG_PLAYER_LOOKUP_PLAYER_ATTR:16, 
Id:64,
    (byte_size(Name)), Name/binary,
    Career,
    Level,
    CombatPower:32,
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
    (length(EqmL)):16, (iolist_to_binary([<<
Id:32,
    Bid:32,
    Pos,
    Qly,
    Qua:16,
    Bind,
    IsJd,
    SuitId:32,
    QhLev,
    Power:32,
    (length(ExtraAttr)):16, (iolist_to_binary([<<
ExtraModId,
    (length(Attr)):16, (iolist_to_binary([<<
AttrCode,
    AttrVal:32,
    AttrPer>>
|| {AttrCode, AttrVal, AttrPer} <- Attr]))/binary >>
|| {ExtraModId, Attr} <- ExtraAttr]))/binary ,
    (length(GemInfo)):16, (iolist_to_binary([<<GemId:32>> || GemId <- GemInfo]))/binary,
    (length(ItemEx)):16, (iolist_to_binary([<<
Key,
    Val:32>>
|| {Key, Val} <- ItemEx]))/binary ,
    (length(SkillChanges)):16, (iolist_to_binary([<<Id:32>> || Id <- SkillChanges]))/binary,
    (length(JDListMax)):16, (iolist_to_binary([<<Max:32>> || Max <- JDListMax]))/binary,
    (length(JDListMin)):16, (iolist_to_binary([<<Min:32>> || Min <- JDListMin]))/binary,
    Fumo:16,
    (length(FumoAttrList)):16, (iolist_to_binary([<<
TypeId,
    AttrId,
    AttrVal:32>>
|| {TypeId, AttrId, AttrVal} <- FumoAttrList]))/binary >>
|| {Id, Bid, Pos, Qly, Qua, Bind, IsJd, SuitId, QhLev, Power, ExtraAttr, GemInfo, ItemEx, SkillChanges, JDListMax, JDListMin, Fumo, FumoAttrList} <- EqmL]))/binary ,
    (length(List)):16, (iolist_to_binary([<<
PartType,
    QhLevel>>
|| {PartType, QhLevel} <- List]))/binary >>
;

%% id=30  
pkg_msg(?MSG_PLAYER_INIT_CLIENT, {PlayerId, Name, Career, Level, Exp, Fragment, Longwen, Money, Diamond, Honour, Jinxing, Yinxing, Hp, Mp, Sp, Sp_count, Attr, Combat_power, Yuansu_moli, Guangan_moli, Mingyun_moli}) ->
<<?MSG_PLAYER_INIT_CLIENT:16, 
PlayerId:64,
    (byte_size(Name)), Name/binary,
    Career,
    Level,
    Exp:32,
    Fragment:32,
    Longwen:32,
    Money:32,
    Diamond:32,
    Honour:32,
    Jinxing:32,
    Yinxing:32,
    Hp:32,
    Mp:32,
    Sp:16,
    Sp_count,
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
    Combat_power:32,
    Yuansu_moli:32,
    Guangan_moli:32,
    Mingyun_moli:32>>
;

%% id=31  
pkg_msg(?MSG_PLAYER_NAME_TO_ID, {PlayerId, Name}) ->
<<?MSG_PLAYER_NAME_TO_ID:16, 
PlayerId:64,
    (byte_size(Name)), Name/binary>>
;

%% id=32  
pkg_msg(?MSG_PLAYER_SYS_TIME, {Time_sec}) ->
<<?MSG_PLAYER_SYS_TIME:16, 
Time_sec:64>>
;

%% id=33  
pkg_msg(?MSG_PLAYER_SYNC_SOCIETY_BUFS, {Society_bufs}) ->
<<?MSG_PLAYER_SYNC_SOCIETY_BUFS:16, 
(length(Society_bufs)):16, (iolist_to_binary([<<Id:16>> || Id <- Society_bufs]))/binary>>
;

%% id=34  
pkg_msg(?MSG_PLAYER_SYNC_FIELD, {Fields}) ->
<<?MSG_PLAYER_SYNC_FIELD:16, 
(length(Fields)):16, (iolist_to_binary([<<
Id:16,
    Val:32>>
|| {Id, Val} <- Fields]))/binary >>
;

%% id=35  
pkg_msg(?MSG_PLAYER_COST_DIAMOND_BUY_SP, {Reply}) ->
<<?MSG_PLAYER_COST_DIAMOND_BUY_SP:16, 
Reply>>
;

%% id=36  
pkg_msg(?MSG_VERSION, {ReplyNum}) ->
<<?MSG_VERSION:16, 
ReplyNum>>
;

%% id=37  
pkg_msg(?MSG_PLAYER_TASK_IS_OPEN, {Isopen}) ->
<<?MSG_PLAYER_TASK_IS_OPEN:16, 
Isopen>>
;

%% id=38  
pkg_msg(?MSG_PLAYER_FIELD_CHANGE, {Fields}) ->
<<?MSG_PLAYER_FIELD_CHANGE:16, 
(length(Fields)):16, (iolist_to_binary([<<
Ids:32,
    (length(Vals)):16, (iolist_to_binary([<<Val:32>> || Val <- Vals]))/binary>>
|| {Ids, Vals} <- Fields]))/binary >>
;

%% id=39  
pkg_msg(?MSG_PLAYER_SKILL_CHANGE, {Skill_change}) ->
<<?MSG_PLAYER_SKILL_CHANGE:16, 
(length(Skill_change)):16, (iolist_to_binary([<<Ids:32>> || Ids <- Skill_change]))/binary>>
;

%% id=40  
pkg_msg(?MSG_PLAYER_EFFECT_CHANGE, {Effect}) ->
<<?MSG_PLAYER_EFFECT_CHANGE:16, 
(length(Effect)):16, (iolist_to_binary([<<Ids:16>> || Ids <- Effect]))/binary>>
;

%% id=41  
pkg_msg(?MSG_PLAYER_AVATAR_CHANGE, {Job, Changeset}) ->
<<?MSG_PLAYER_AVATAR_CHANGE:16, 
Job,
    (length(Changeset)):16, (iolist_to_binary([<<Ids:32>> || Ids <- Changeset]))/binary>>
;

%% id=42  
pkg_msg(?MSG_PLAYER_OFFLINE_INFO, {Errorcode}) ->
<<?MSG_PLAYER_OFFLINE_INFO:16, 
Errorcode>>
;

%% id=43  
pkg_msg(?MSG_PLAYER_EARNINGS_CHANGE, {Result}) ->
<<?MSG_PLAYER_EARNINGS_CHANGE:16, 
Result:16>>
;

%% id=44  
pkg_msg(?MSG_SHOW_NEAR_PLAYER_SET, {Send}) ->
<<?MSG_SHOW_NEAR_PLAYER_SET:16, 
Send:16>>
;

%% id=47  
pkg_msg(?MSG_DRESS_SHAPESHIFT, {CardId}) ->
<<?MSG_DRESS_SHAPESHIFT:16, 
CardId:32>>
;

%% id=45  
pkg_msg(?MSG_PLAYER_DELETE, {Isok}) ->
<<?MSG_PLAYER_DELETE:16, 
Isok>>
;

%% id=48  
pkg_msg(?MSG_PLAYER_GM, {Info}) ->
<<?MSG_PLAYER_GM:16, 
(length(Info)):16, (iolist_to_binary([<<
Index,
    Val>>
|| {Index, Val} <- Info]))/binary >>
;

%% id=49  
pkg_msg(?MSG_PLAYER_QQ_AUTH_LOGIN, {Finalplayer, Info}) ->
<<?MSG_PLAYER_QQ_AUTH_LOGIN:16, 
Finalplayer,
    Info/binary>>
;

%% id=50  
pkg_msg(?MSG_PLAYER_PING, {}) ->
<<?MSG_PLAYER_PING:16>> 
;

%% id=51  
pkg_msg(?MSG_PLAYER_RECONNECTION, {Isok}) ->
<<?MSG_PLAYER_RECONNECTION:16, 
Isok>>
;

%% id=52  
pkg_msg(?MSG_PlAYER_RIDE, {RideId}) ->
<<?MSG_PlAYER_RIDE:16, 
RideId:16>>
;

%% id=53  
pkg_msg(?MSG_PLAYER_ACTIVITY_LIST, {Info}) ->
<<?MSG_PLAYER_ACTIVITY_LIST:16, 
Info/binary>>
;

%% id=55  
pkg_msg(?MSG_PLAYER_DO_SURVEY_NOTIFY, {Result}) ->
<<?MSG_PLAYER_DO_SURVEY_NOTIFY:16, 
Result>>
;

%% id=56  
pkg_msg(?MSG_PLAYER_SP_REFRESH_TIME, {Time_sec}) ->
<<?MSG_PLAYER_SP_REFRESH_TIME:16, 
Time_sec:32>>
;

%% id=57  
pkg_msg(?MSG_PLAYER_CD_KEY, {ReplyNum}) ->
<<?MSG_PLAYER_CD_KEY:16, 
ReplyNum>>
;

%% id=58  
pkg_msg(?MSG_PLAYER_ADD_HOURLY_SP, {ReplyNum}) ->
<<?MSG_PLAYER_ADD_HOURLY_SP:16, 
ReplyNum>>
;

%% id=59  
pkg_msg(?MSG_PLAYER_PUSH_HOURLY_SP_STATUS, {Status}) ->
<<?MSG_PLAYER_PUSH_HOURLY_SP_STATUS:16, 
Status>>
;

%% id=60  
pkg_msg(?MSG_PLAYER_RESET_PLAYER_NAME, {Issuc}) ->
<<?MSG_PLAYER_RESET_PLAYER_NAME:16, 
Issuc>>
;

%% id=62  
pkg_msg(?MSG_PLAYER_PUSH_SHARE_GAME, {Status, Prize_status}) ->
<<?MSG_PLAYER_PUSH_SHARE_GAME:16, 
Status,
    Prize_status>>
;

%% id=63  
pkg_msg(?MSG_PLAYER_GET_SHARE_GAME_PRIZE, {Reply}) ->
<<?MSG_PLAYER_GET_SHARE_GAME_PRIZE:16, 
Reply>>
;
pkg_msg(Id, _) -> ok.



%% id = 1  
unpkg_msg(?MSG_PLAYER_ACCOUNT_LOGIN, Acc0) ->
<<PlatformPlayerNameLen, PlatformPlayerName:PlatformPlayerNameLen/binary,
PassworldLen, Passworld:PassworldLen/binary,
PlatformId,
ServerId:16,
Machine_macLen, Machine_mac:Machine_macLen/binary,
Machine_idLen, Machine_id:Machine_idLen/binary,
Machine_styleLen, Machine_style:Machine_styleLen/binary,
Machine_infoLen, Machine_info:Machine_infoLen/binary,
Acc1/binary>> = Acc0,
 {{PlatformPlayerName,Passworld,PlatformId,ServerId,Machine_mac,Machine_id,Machine_style,Machine_info}, Acc1};

%% id = 4  
unpkg_msg(?MSG_PLAYER_CREATE_ROLE, Acc0) ->
<<Index,
Career,
Name/binary>> = Acc0,
 {{Index,Career,Name}, <<>>};

%% id = 7  
unpkg_msg(?MSG_PLAYER_CLIENT_DATA_POST, Acc0) ->
<<Type,
Data/binary>> = Acc0,
 {{Type,Data}, <<>>};

%% id = 8  
unpkg_msg(?MSG_PLAYER_CLIENT_DATA_GET, Acc0) ->
<<Type,
Acc1/binary>> = Acc0,
 {{Type}, Acc1};

%% id = 10  
unpkg_msg(?MSG_PLAYER_ECHO, Acc0) ->
<<Msg/binary>> = Acc0,
 {{Msg}, <<>>};

%% id = 11  
unpkg_msg(?MSG_PLAYER_GET_SERVER_TIME, Acc0) ->
{{}, Acc0};

%% id = 17  
unpkg_msg(?MSG_PLAYER_LOOKUP_PLAYER_ATTR, Acc0) ->
<<Id:64,
Acc1/binary>> = Acc0,
 {{Id}, Acc1};

%% id = 31  
unpkg_msg(?MSG_PLAYER_NAME_TO_ID, Acc0) ->
<<NameLen, Name:NameLen/binary,
Acc1/binary>> = Acc0,
 {{Name}, Acc1};

%% id = 32  
unpkg_msg(?MSG_PLAYER_SYS_TIME, Acc0) ->
{{}, Acc0};

%% id = 35  
unpkg_msg(?MSG_PLAYER_COST_DIAMOND_BUY_SP, Acc0) ->
<<Count,
Acc1/binary>> = Acc0,
 {{Count}, Acc1};

%% id = 36  
unpkg_msg(?MSG_VERSION, Acc0) ->
<<DebugId:16,
MainVersionId:16,
AssistVersionId:16,
ResourceVersionId:16,
Acc1/binary>> = Acc0,
 {{DebugId,MainVersionId,AssistVersionId,ResourceVersionId}, Acc1};

%% id = 37  
unpkg_msg(?MSG_PLAYER_TASK_IS_OPEN, Acc0) ->
{{}, Acc0};

%% id = 44  
unpkg_msg(?MSG_SHOW_NEAR_PLAYER_SET, Acc0) ->
<<Receive:16,
Acc1/binary>> = Acc0,
 {{Receive}, Acc1};

%% id = 45  
unpkg_msg(?MSG_PLAYER_DELETE, Acc0) ->
<<Index,
Acc1/binary>> = Acc0,
 {{Index}, Acc1};

%% id = 46  
unpkg_msg(?MSG_PLAYER_JOIN_GAME, Acc0) ->
<<Index,
Wx,
Wy,
Acc1/binary>> = Acc0,
 {{Index,Wx,Wy}, Acc1};

%% id = 49  
unpkg_msg(?MSG_PLAYER_QQ_AUTH_LOGIN, Acc0) ->
<<OpenidLen, Openid:OpenidLen/binary,
AccessTokenLen, AccessToken:AccessTokenLen/binary,
PlatformId,
ServerId:16,
Machine_macLen, Machine_mac:Machine_macLen/binary,
Machine_idLen, Machine_id:Machine_idLen/binary,
Machine_styleLen, Machine_style:Machine_styleLen/binary,
Machine_infoLen, Machine_info:Machine_infoLen/binary,
Acc1/binary>> = Acc0,
 {{Openid,AccessToken,PlatformId,ServerId,Machine_mac,Machine_id,Machine_style,Machine_info}, Acc1};

%% id = 50  
unpkg_msg(?MSG_PLAYER_PING, Acc0) ->
{{}, Acc0};

%% id = 51  
unpkg_msg(?MSG_PLAYER_RECONNECTION, Acc0) ->
<<PlatformPlayerNameLen, PlatformPlayerName:PlatformPlayerNameLen/binary,
PlatformId,
ServerId:16,
Machine_macLen, Machine_mac:Machine_macLen/binary,
Machine_idLen, Machine_id:Machine_idLen/binary,
Machine_styleLen, Machine_style:Machine_styleLen/binary,
Machine_infoLen, Machine_info:Machine_infoLen/binary,
Index,
Wx,
Wy,
Acc1/binary>> = Acc0,
 {{PlatformPlayerName,PlatformId,ServerId,Machine_mac,Machine_id,Machine_style,Machine_info,Index,Wx,Wy}, Acc1};

%% id = 54  
unpkg_msg(?MSG_PLAYER_UNDRESS_SHAPESHIFT, Acc0) ->
{{}, Acc0};

%% id = 55  
unpkg_msg(?MSG_PLAYER_DO_SURVEY_NOTIFY, Acc0) ->
{{}, Acc0};

%% id = 56  
unpkg_msg(?MSG_PLAYER_SP_REFRESH_TIME, Acc0) ->
{{}, Acc0};

%% id = 57  
unpkg_msg(?MSG_PLAYER_CD_KEY, Acc0) ->
<<Cd_keyLen, Cd_key:Cd_keyLen/binary,
Acc1/binary>> = Acc0,
 {{Cd_key}, Acc1};

%% id = 58  
unpkg_msg(?MSG_PLAYER_ADD_HOURLY_SP, Acc0) ->
{{}, Acc0};

%% id = 59  
unpkg_msg(?MSG_PLAYER_PUSH_HOURLY_SP_STATUS, Acc0) ->
{{}, Acc0};

%% id = 60  
unpkg_msg(?MSG_PLAYER_RESET_PLAYER_NAME, Acc0) ->
<<NameLen, Name:NameLen/binary,
Acc1/binary>> = Acc0,
 {{Name}, Acc1};

%% id = 61  
unpkg_msg(?MSG_PLAYER_PROGRESS_NOTICE, Acc0) ->
<<Progress_id:16,
Acc1/binary>> = Acc0,
 {{Progress_id}, Acc1};

%% id = 62  
unpkg_msg(?MSG_PLAYER_PUSH_SHARE_GAME, Acc0) ->
{{}, Acc0};

%% id = 63  
unpkg_msg(?MSG_PLAYER_GET_SHARE_GAME_PRIZE, Acc0) ->
<<Type,
Acc1/binary>> = Acc0,
 {{Type}, Acc1};
unpkg_msg(Id, _) -> ok.




to_s(?MSG_PLAYER_ACCOUNT_LOGIN) -> <<"MSG_PLAYER_ACCOUNT_LOGIN">>; %% high 1, id 1
to_s(?MSG_PLAYER_ERROR) -> <<"MSG_PLAYER_ERROR">>; %% high 1, id 2
to_s(?MSG_PLAYER_CREATE_ROLE) -> <<"MSG_PLAYER_CREATE_ROLE">>; %% high 1, id 4
to_s(?MSG_PLAYER_CLIENT_DATA_POST) -> <<"MSG_PLAYER_CLIENT_DATA_POST">>; %% high 1, id 7
to_s(?MSG_PLAYER_CLIENT_DATA_GET) -> <<"MSG_PLAYER_CLIENT_DATA_GET">>; %% high 1, id 8
to_s(?MSG_PLAYER_ONLINE_FINISH) -> <<"MSG_PLAYER_ONLINE_FINISH">>; %% high 1, id 9
to_s(?MSG_PLAYER_ECHO) -> <<"MSG_PLAYER_ECHO">>; %% high 1, id 10
to_s(?MSG_PLAYER_GET_SERVER_TIME) -> <<"MSG_PLAYER_GET_SERVER_TIME">>; %% high 1, id 11
to_s(?MSG_PLAYER_DATA_CHANGED) -> <<"MSG_PLAYER_DATA_CHANGED">>; %% high 1, id 15
to_s(?MSG_PLAYER_ATTR_CHANGE) -> <<"MSG_PLAYER_ATTR_CHANGE">>; %% high 1, id 16
to_s(?MSG_PLAYER_LOOKUP_PLAYER_ATTR) -> <<"MSG_PLAYER_LOOKUP_PLAYER_ATTR">>; %% high 1, id 17
to_s(?MSG_PLAYER_INIT_CLIENT) -> <<"MSG_PLAYER_INIT_CLIENT">>; %% high 1, id 30
to_s(?MSG_PLAYER_NAME_TO_ID) -> <<"MSG_PLAYER_NAME_TO_ID">>; %% high 1, id 31
to_s(?MSG_PLAYER_SYS_TIME) -> <<"MSG_PLAYER_SYS_TIME">>; %% high 1, id 32
to_s(?MSG_PLAYER_SYNC_SOCIETY_BUFS) -> <<"MSG_PLAYER_SYNC_SOCIETY_BUFS">>; %% high 1, id 33
to_s(?MSG_PLAYER_SYNC_FIELD) -> <<"MSG_PLAYER_SYNC_FIELD">>; %% high 1, id 34
to_s(?MSG_PLAYER_COST_DIAMOND_BUY_SP) -> <<"MSG_PLAYER_COST_DIAMOND_BUY_SP">>; %% high 1, id 35
to_s(?MSG_VERSION) -> <<"MSG_VERSION">>; %% high 1, id 36
to_s(?MSG_PLAYER_TASK_IS_OPEN) -> <<"MSG_PLAYER_TASK_IS_OPEN">>; %% high 1, id 37
to_s(?MSG_PLAYER_FIELD_CHANGE) -> <<"MSG_PLAYER_FIELD_CHANGE">>; %% high 1, id 38
to_s(?MSG_PLAYER_SKILL_CHANGE) -> <<"MSG_PLAYER_SKILL_CHANGE">>; %% high 1, id 39
to_s(?MSG_PLAYER_EFFECT_CHANGE) -> <<"MSG_PLAYER_EFFECT_CHANGE">>; %% high 1, id 40
to_s(?MSG_PLAYER_AVATAR_CHANGE) -> <<"MSG_PLAYER_AVATAR_CHANGE">>; %% high 1, id 41
to_s(?MSG_PLAYER_OFFLINE_INFO) -> <<"MSG_PLAYER_OFFLINE_INFO">>; %% high 1, id 42
to_s(?MSG_PLAYER_EARNINGS_CHANGE) -> <<"MSG_PLAYER_EARNINGS_CHANGE">>; %% high 1, id 43
to_s(?MSG_SHOW_NEAR_PLAYER_SET) -> <<"MSG_SHOW_NEAR_PLAYER_SET">>; %% high 1, id 44
to_s(?MSG_DRESS_SHAPESHIFT) -> <<"MSG_DRESS_SHAPESHIFT">>; %% high 1, id 47
to_s(?MSG_PLAYER_DELETE) -> <<"MSG_PLAYER_DELETE">>; %% high 1, id 45
to_s(?MSG_PLAYER_JOIN_GAME) -> <<"MSG_PLAYER_JOIN_GAME">>; %% high 1, id 46
to_s(?MSG_PLAYER_GM) -> <<"MSG_PLAYER_GM">>; %% high 1, id 48
to_s(?MSG_PLAYER_QQ_AUTH_LOGIN) -> <<"MSG_PLAYER_QQ_AUTH_LOGIN">>; %% high 1, id 49
to_s(?MSG_PLAYER_PING) -> <<"MSG_PLAYER_PING">>; %% high 1, id 50
to_s(?MSG_PLAYER_RECONNECTION) -> <<"MSG_PLAYER_RECONNECTION">>; %% high 1, id 51
to_s(?MSG_PlAYER_RIDE) -> <<"MSG_PlAYER_RIDE">>; %% high 1, id 52
to_s(?MSG_PLAYER_ACTIVITY_LIST) -> <<"MSG_PLAYER_ACTIVITY_LIST">>; %% high 1, id 53
to_s(?MSG_PLAYER_UNDRESS_SHAPESHIFT) -> <<"MSG_PLAYER_UNDRESS_SHAPESHIFT">>; %% high 1, id 54
to_s(?MSG_PLAYER_DO_SURVEY_NOTIFY) -> <<"MSG_PLAYER_DO_SURVEY_NOTIFY">>; %% high 1, id 55
to_s(?MSG_PLAYER_SP_REFRESH_TIME) -> <<"MSG_PLAYER_SP_REFRESH_TIME">>; %% high 1, id 56
to_s(?MSG_PLAYER_CD_KEY) -> <<"MSG_PLAYER_CD_KEY">>; %% high 1, id 57
to_s(?MSG_PLAYER_ADD_HOURLY_SP) -> <<"MSG_PLAYER_ADD_HOURLY_SP">>; %% high 1, id 58
to_s(?MSG_PLAYER_PUSH_HOURLY_SP_STATUS) -> <<"MSG_PLAYER_PUSH_HOURLY_SP_STATUS">>; %% high 1, id 59
to_s(?MSG_PLAYER_RESET_PLAYER_NAME) -> <<"MSG_PLAYER_RESET_PLAYER_NAME">>; %% high 1, id 60
to_s(?MSG_PLAYER_PROGRESS_NOTICE) -> <<"MSG_PLAYER_PROGRESS_NOTICE">>; %% high 1, id 61
to_s(?MSG_PLAYER_PUSH_SHARE_GAME) -> <<"MSG_PLAYER_PUSH_SHARE_GAME">>; %% high 1, id 62
to_s(?MSG_PLAYER_GET_SHARE_GAME_PRIZE) -> <<"MSG_PLAYER_GET_SHARE_GAME_PRIZE">>; %% high 1, id 63
to_s(_) -> <<"unknown msg">>.