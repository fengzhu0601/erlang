%% Auto generated by sproto from rank.sproto
%% Don't edit it.

-module(rank_sproto).
-export([pkg_msg/2, unpkg_msg/2, to_s/1]).
-include("rank_sproto.hrl").

%% id=1  
pkg_msg(?MSG_RANK_LEV, {MyIndex, Size, Ranks}) ->
<<?MSG_RANK_LEV:16, 
MyIndex:16,
    Size,
    (length(Ranks)):16, (iolist_to_binary([<<
Index:16,
    PlayerCarrer,
    PlayerId:64,
    (byte_size(PlayerName)), PlayerName/binary,
    PlayerLev,
    PlayerPower:32>>
|| {Index, PlayerCarrer, PlayerId, PlayerName, PlayerLev, PlayerPower} <- Ranks]))/binary >>
;

%% id=2  
pkg_msg(?MSG_RANK_POWER, {MyIndex, Size, Ranks}) ->
<<?MSG_RANK_POWER:16, 
MyIndex:16,
    Size,
    (length(Ranks)):16, (iolist_to_binary([<<
Index:16,
    PlayerCarrer,
    PlayerId:64,
    (byte_size(PlayerName)), PlayerName/binary,
    PlayerLev,
    PlayerPower:32>>
|| {Index, PlayerCarrer, PlayerId, PlayerName, PlayerLev, PlayerPower} <- Ranks]))/binary >>
;

%% id=3  
pkg_msg(?MSG_RANK_ARENA, {MyIndex, ArenaLev, ArenaCent, Size, Ranks}) ->
<<?MSG_RANK_ARENA:16, 
MyIndex:16,
    ArenaLev,
    ArenaCent:16,
    Size,
    (length(Ranks)):16, (iolist_to_binary([<<
Index:16,
    ArenaLev,
    ArenaCent:16,
    PlayerId:64,
    (byte_size(PlayerName)), PlayerName/binary,
    PlayerLev,
    PlayerCarrer,
    PlayerPower:32>>
|| {Index, ArenaLev, ArenaCent, PlayerId, PlayerName, PlayerLev, PlayerCarrer, PlayerPower} <- Ranks]))/binary >>
;

%% id=4  
pkg_msg(?MSG_RANK_PET, {MyRank, Size, Ranks}) ->
<<?MSG_RANK_PET:16, 
(begin {Index, PetLev, PetName, PetAC, PetPower, PlayerId, PlayerName}=MyRank, <<
Index:16,
    PetLev,
    (byte_size(PetName)), PetName/binary,
    PetAC,
    PetPower:32,
    PlayerId:64,
    (byte_size(PlayerName)), PlayerName/binary>>
 end)/binary,
    Size,
    (length(Ranks)):16, (iolist_to_binary([<<
Index:16,
    PetLev,
    (byte_size(PetName)), PetName/binary,
    PetAC,
    PetPower:32,
    PlayerId:64,
    (byte_size(PlayerName)), PlayerName/binary>>
|| {Index, PetLev, PetName, PetAC, PetPower, PlayerId, PlayerName} <- Ranks]))/binary >>
;

%% id=5  
pkg_msg(?MSG_RANK_GUILD, {MyRank, Size, Ranks}) ->
<<?MSG_RANK_GUILD:16, 
(begin {Index, Guild_id, Totem_id, Border_id, GuildLev, GuildName, MasterId, MasterName}=MyRank, <<
Index:16,
    Guild_id:32,
    Totem_id,
    Border_id,
    GuildLev,
    (byte_size(GuildName)), GuildName/binary,
    MasterId:64,
    (byte_size(MasterName)), MasterName/binary>>
 end)/binary,
    Size,
    (length(Ranks)):16, (iolist_to_binary([<<
Index:16,
    Guild_id:32,
    Totem_id,
    Border_id,
    GuildLev,
    (byte_size(GuildName)), GuildName/binary,
    MasterId:64,
    (byte_size(MasterName)), MasterName/binary>>
|| {Index, Guild_id, Totem_id, Border_id, GuildLev, GuildName, MasterId, MasterName} <- Ranks]))/binary >>
;

%% id=6  
pkg_msg(?MSG_RANK_FRIEND, {MyRank, Size, Ranks}) ->
<<?MSG_RANK_FRIEND:16, 
MyRank:16,
    Size,
    (length(Ranks)):16, (iolist_to_binary([<<
Index:16,
    PlayerCarrer,
    PlayerId:64,
    (byte_size(PlayerName)), PlayerName/binary,
    PlayerLev,
    PlayerPower:32,
    FriendScore:16>>
|| {Index, PlayerCarrer, PlayerId, PlayerName, PlayerLev, PlayerPower, FriendScore} <- Ranks]))/binary >>
;

%% id=7  
pkg_msg(?MSG_RANK_ACCOMPLISHMENT, {MyRank, Size, Ranks}) ->
<<?MSG_RANK_ACCOMPLISHMENT:16, 
(begin {Index, PlayerCarrer, PlayerId, PlayerName, PlayerLev, PlayerPower, AccomplishmentScore}=MyRank, <<
Index:16,
    PlayerCarrer,
    PlayerId:64,
    (byte_size(PlayerName)), PlayerName/binary,
    PlayerLev,
    PlayerPower:32,
    AccomplishmentScore:16>>
 end)/binary,
    Size,
    (length(Ranks)):16, (iolist_to_binary([<<
Index:16,
    PlayerCarrer,
    PlayerId:64,
    (byte_size(PlayerName)), PlayerName/binary,
    PlayerLev,
    PlayerPower:32,
    AccomplishmentScore:16>>
|| {Index, PlayerCarrer, PlayerId, PlayerName, PlayerLev, PlayerPower, AccomplishmentScore} <- Ranks]))/binary >>
;

%% id=8  
pkg_msg(?MSG_RANK_SHENMO, {MyRank, Size, Ranks}) ->
<<?MSG_RANK_SHENMO:16, 
(begin {Index, PlayerCarrer, PlayerId, PlayerName, PlayerLev, PlayerPower, Group, Honour, TitleName}=MyRank, <<
Index:16,
    PlayerCarrer,
    PlayerId:64,
    (byte_size(PlayerName)), PlayerName/binary,
    PlayerLev,
    PlayerPower:32,
    (byte_size(Group)), Group/binary,
    Honour:64,
    (byte_size(TitleName)), TitleName/binary>>
 end)/binary,
    Size,
    (length(Ranks)):16, (iolist_to_binary([<<
Index:16,
    PlayerCarrer,
    PlayerId:64,
    (byte_size(PlayerName)), PlayerName/binary,
    PlayerLev,
    PlayerPower:32,
    (byte_size(Group)), Group/binary,
    Honour:64,
    (byte_size(TitleName)), TitleName/binary>>
|| {Index, PlayerCarrer, PlayerId, PlayerName, PlayerLev, PlayerPower, Group, Honour, TitleName} <- Ranks]))/binary >>
;

%% id=9  
pkg_msg(?MSG_RANK_DAILY_1, {MyRank, Size, Ranks}) ->
<<?MSG_RANK_DAILY_1:16, 
(begin {Index, PlayerCarrer, PlayerId, PlayerName, PlayerLev, PlayerPower, Max_count}=MyRank, <<
Index:16,
    PlayerCarrer,
    PlayerId:64,
    (byte_size(PlayerName)), PlayerName/binary,
    PlayerLev,
    PlayerPower:32,
    Max_count:32>>
 end)/binary,
    Size,
    (length(Ranks)):16, (iolist_to_binary([<<
Index:16,
    PlayerCarrer,
    PlayerId:64,
    (byte_size(PlayerName)), PlayerName/binary,
    PlayerLev,
    PlayerPower:32,
    Max_count:32>>
|| {Index, PlayerCarrer, PlayerId, PlayerName, PlayerLev, PlayerPower, Max_count} <- Ranks]))/binary >>
;

%% id=10  
pkg_msg(?MSG_RANK_DAILY_2, {MyRank, Size, Ranks}) ->
<<?MSG_RANK_DAILY_2:16, 
(begin {Index, PlayerCarrer, PlayerId, PlayerName, PlayerLev, PlayerPower, Max_integral}=MyRank, <<
Index:16,
    PlayerCarrer,
    PlayerId:64,
    (byte_size(PlayerName)), PlayerName/binary,
    PlayerLev,
    PlayerPower:32,
    Max_integral:32>>
 end)/binary,
    Size,
    (length(Ranks)):16, (iolist_to_binary([<<
Index:16,
    PlayerCarrer,
    PlayerId:64,
    (byte_size(PlayerName)), PlayerName/binary,
    PlayerLev,
    PlayerPower:32,
    Max_integral:32>>
|| {Index, PlayerCarrer, PlayerId, PlayerName, PlayerLev, PlayerPower, Max_integral} <- Ranks]))/binary >>
;

%% id=11  
pkg_msg(?MSG_RANK_ABYSS, {MyRank, Size, Ranks}) ->
<<?MSG_RANK_ABYSS:16, 
(begin {Index, PlayerCarrer, PlayerId, PlayerName, PlayerLev, PlayerPower, Easy_layer, Hard_layer, Score}=MyRank, <<
Index:16,
    PlayerCarrer,
    PlayerId:64,
    (byte_size(PlayerName)), PlayerName/binary,
    PlayerLev,
    PlayerPower:32,
    Easy_layer:16,
    Hard_layer:16,
    Score:32>>
 end)/binary,
    Size,
    (length(Ranks)):16, (iolist_to_binary([<<
Index:16,
    PlayerCarrer,
    PlayerId:64,
    (byte_size(PlayerName)), PlayerName/binary,
    PlayerLev,
    PlayerPower:32,
    Easy_layer:16,
    Hard_layer:16,
    Score:32>>
|| {Index, PlayerCarrer, PlayerId, PlayerName, PlayerLev, PlayerPower, Easy_layer, Hard_layer, Score} <- Ranks]))/binary >>
;

%% id=12  
pkg_msg(?MSG_RANK_SKY_KILL_MONSTER, {MyRank, Size, Ranks}) ->
<<?MSG_RANK_SKY_KILL_MONSTER:16, 
(begin {Index, PlayerCarrer, PlayerId, PlayerName, PlayerLev, PlayerGuildName, Kill_count}=MyRank, <<
Index:16,
    PlayerCarrer,
    PlayerId:64,
    (byte_size(PlayerName)), PlayerName/binary,
    PlayerLev,
    (byte_size(PlayerGuildName)), PlayerGuildName/binary,
    Kill_count:16>>
 end)/binary,
    Size,
    (length(Ranks)):16, (iolist_to_binary([<<
Index:16,
    PlayerCarrer,
    PlayerId:64,
    (byte_size(PlayerName)), PlayerName/binary,
    PlayerLev,
    (byte_size(PlayerGuildName)), PlayerGuildName/binary,
    Kill_count:16>>
|| {Index, PlayerCarrer, PlayerId, PlayerName, PlayerLev, PlayerGuildName, Kill_count} <- Ranks]))/binary >>
;

%% id=13  
pkg_msg(?MSG_RANK_SKY_KILL_PLAYER, {MyRank, Size, Ranks}) ->
<<?MSG_RANK_SKY_KILL_PLAYER:16, 
(begin {Index, PlayerCarrer, PlayerId, PlayerName, PlayerLev, PlayerGuildName, Kill_count}=MyRank, <<
Index:16,
    PlayerCarrer,
    PlayerId:64,
    (byte_size(PlayerName)), PlayerName/binary,
    PlayerLev,
    (byte_size(PlayerGuildName)), PlayerGuildName/binary,
    Kill_count:16>>
 end)/binary,
    Size,
    (length(Ranks)):16, (iolist_to_binary([<<
Index:16,
    PlayerCarrer,
    PlayerId:64,
    (byte_size(PlayerName)), PlayerName/binary,
    PlayerLev,
    (byte_size(PlayerGuildName)), PlayerGuildName/binary,
    Kill_count:16>>
|| {Index, PlayerCarrer, PlayerId, PlayerName, PlayerLev, PlayerGuildName, Kill_count} <- Ranks]))/binary >>
;

%% id=14  
pkg_msg(?MSG_RANK_SUIT, {MyRank, SuitNum, SuitNumAll, EquipNum, EquipNumAll, Size, Ranks}) ->
<<?MSG_RANK_SUIT:16, 
MyRank:16,
    SuitNum,
    SuitNumAll,
    EquipNum:16,
    EquipNumAll:16,
    Size,
    (length(Ranks)):16, (iolist_to_binary([<<
Index:16,
    PlayerCareer,
    PlayerId:64,
    (byte_size(PlayerName)), PlayerName/binary,
    PlayerLev,
    PlayerPower:32,
    Suit_num,
    Suit_num_all,
    Equip_num:16,
    Equip_num_all:16>>
|| {Index, PlayerCareer, PlayerId, PlayerName, PlayerLev, PlayerPower, Suit_num, Suit_num_all, Equip_num, Equip_num_all} <- Ranks]))/binary >>
;

%% id=15  
pkg_msg(?MSG_RANK_GUILD_BOSS, {MyRank, Size, Ranks}) ->
<<?MSG_RANK_GUILD_BOSS:16, 
(begin {Index, PlayerCarrer, PlayerId, PlayerName, PlayerLev, PlayerPos, PlayerPower, Damage}=MyRank, <<
Index:16,
    PlayerCarrer,
    PlayerId:64,
    (byte_size(PlayerName)), PlayerName/binary,
    PlayerLev,
    PlayerPos,
    PlayerPower:32,
    Damage:32>>
 end)/binary,
    Size,
    (length(Ranks)):16, (iolist_to_binary([<<
Index:16,
    PlayerCarrer,
    PlayerId:64,
    (byte_size(PlayerName)), PlayerName/binary,
    PlayerLev,
    PlayerPos,
    PlayerPower:32,
    Damage:32>>
|| {Index, PlayerCarrer, PlayerId, PlayerName, PlayerLev, PlayerPos, PlayerPower, Damage} <- Ranks]))/binary >>
;

%% id=16  
pkg_msg(?MSG_RANK_GWGC, {MyRankData, Size, Ranks}) ->
<<?MSG_RANK_GWGC:16, 
(begin {Index, PlayerCarrer, PlayerId, PlayerName, PlayerLev, PlayerPower, Jifen}=MyRankData, <<
Index:16,
    PlayerCarrer,
    PlayerId:64,
    (byte_size(PlayerName)), PlayerName/binary,
    PlayerLev,
    PlayerPower:32,
    Jifen:32>>
 end)/binary,
    Size,
    (length(Ranks)):16, (iolist_to_binary([<<
Index:16,
    PlayerCarrer,
    PlayerId:64,
    (byte_size(PlayerName)), PlayerName/binary,
    PlayerLev,
    PlayerPower:32,
    Jifen:32>>
|| {Index, PlayerCarrer, PlayerId, PlayerName, PlayerLev, PlayerPower, Jifen} <- Ranks]))/binary >>
;

%% id=17  
pkg_msg(?MSG_RANK_BOUNTY, {MyRankData, Size, Ranks}) ->
<<?MSG_RANK_BOUNTY:16, 
(begin {Index, PlayerCarrer, PlayerId, PlayerName, PlayerLev, PlayerPower, Liveness}=MyRankData, <<
Index:16,
    PlayerCarrer,
    PlayerId:64,
    (byte_size(PlayerName)), PlayerName/binary,
    PlayerLev,
    PlayerPower:32,
    Liveness:16>>
 end)/binary,
    Size,
    (length(Ranks)):16, (iolist_to_binary([<<
Index:16,
    PlayerCarrer,
    PlayerId:64,
    (byte_size(PlayerName)), PlayerName/binary,
    PlayerLev,
    PlayerPower:32,
    Liveness:16>>
|| {Index, PlayerCarrer, PlayerId, PlayerName, PlayerLev, PlayerPower, Liveness} <- Ranks]))/binary >>
;

%% id=18  
pkg_msg(?MSG_RANK_PET_NEW, {MyRank, Size, Ranks}) ->
<<?MSG_RANK_PET_NEW:16, 
(begin {Index, PlayerCarrer, PlayerId, PlayerName, PlayerLev, PlayerPower, PetPower}=MyRank, <<
Index:16,
    PlayerCarrer,
    PlayerId:64,
    (byte_size(PlayerName)), PlayerName/binary,
    PlayerLev,
    PlayerPower:32,
    PetPower:32>>
 end)/binary,
    Size,
    (length(Ranks)):16, (iolist_to_binary([<<
Index:16,
    PlayerCarrer,
    PlayerId:64,
    (byte_size(PlayerName)), PlayerName/binary,
    PlayerLev,
    PlayerPower:32,
    PetPower:32>>
|| {Index, PlayerCarrer, PlayerId, PlayerName, PlayerLev, PlayerPower, PetPower} <- Ranks]))/binary >>
;

%% id=19  
pkg_msg(?MSG_RANK_SUIT_NEW, {MyRank, Size, Ranks}) ->
<<?MSG_RANK_SUIT_NEW:16, 
(begin {Index, PlayerCarrer, PlayerId, PlayerName, PlayerLev, PlayerPower, Suit_num}=MyRank, <<
Index:16,
    PlayerCarrer,
    PlayerId:64,
    (byte_size(PlayerName)), PlayerName/binary,
    PlayerLev,
    PlayerPower:32,
    Suit_num:16>>
 end)/binary,
    Size,
    (length(Ranks)):16, (iolist_to_binary([<<
Index:16,
    PlayerCarrer,
    PlayerId:64,
    (byte_size(PlayerName)), PlayerName/binary,
    PlayerLev,
    PlayerPower:32,
    Suit_num:16>>
|| {Index, PlayerCarrer, PlayerId, PlayerName, PlayerLev, PlayerPower, Suit_num} <- Ranks]))/binary >>
;

%% id=20  
pkg_msg(?MSG_RANK_RIDE, {MyRankData, Size, Ranks}) ->
<<?MSG_RANK_RIDE:16, 
(begin {Index, PlayerCarrer, PlayerId, PlayerName, PlayerLev, PlayerPower, RidePower}=MyRankData, <<
Index:16,
    PlayerCarrer,
    PlayerId:64,
    (byte_size(PlayerName)), PlayerName/binary,
    PlayerLev,
    PlayerPower:32,
    RidePower:32>>
 end)/binary,
    Size,
    (length(Ranks)):16, (iolist_to_binary([<<
Index:16,
    PlayerCarrer,
    PlayerId:64,
    (byte_size(PlayerName)), PlayerName/binary,
    PlayerLev,
    PlayerPower:32,
    RidePower:32>>
|| {Index, PlayerCarrer, PlayerId, PlayerName, PlayerLev, PlayerPower, RidePower} <- Ranks]))/binary >>
;

%% id=21  
pkg_msg(?MSG_RANK_DAILY_4, {MyRank, Size, Ranks}) ->
<<?MSG_RANK_DAILY_4:16, 
(begin {Index, PlayerCarrer, PlayerId, PlayerName, PlayerLev, PlayerPower, Max_integral}=MyRank, <<
Index:16,
    PlayerCarrer,
    PlayerId:64,
    (byte_size(PlayerName)), PlayerName/binary,
    PlayerLev,
    PlayerPower:32,
    Max_integral:32>>
 end)/binary,
    Size,
    (length(Ranks)):16, (iolist_to_binary([<<
Index:16,
    PlayerCarrer,
    PlayerId:64,
    (byte_size(PlayerName)), PlayerName/binary,
    PlayerLev,
    PlayerPower:32,
    Max_integral:32>>
|| {Index, PlayerCarrer, PlayerId, PlayerName, PlayerLev, PlayerPower, Max_integral} <- Ranks]))/binary >>
;

%% id=22  
pkg_msg(?MSG_RANK_DAILY_5, {MyRank, Size, Ranks}) ->
<<?MSG_RANK_DAILY_5:16, 
(begin {Index, PlayerCarrer, PlayerId, PlayerName, PlayerLev, PlayerPower, Max_integral}=MyRank, <<
Index:16,
    PlayerCarrer,
    PlayerId:64,
    (byte_size(PlayerName)), PlayerName/binary,
    PlayerLev,
    PlayerPower:32,
    Max_integral:32>>
 end)/binary,
    Size,
    (length(Ranks)):16, (iolist_to_binary([<<
Index:16,
    PlayerCarrer,
    PlayerId:64,
    (byte_size(PlayerName)), PlayerName/binary,
    PlayerLev,
    PlayerPower:32,
    Max_integral:32>>
|| {Index, PlayerCarrer, PlayerId, PlayerName, PlayerLev, PlayerPower, Max_integral} <- Ranks]))/binary >>
;
pkg_msg(Id, _) -> ok.



%% id = 1  
unpkg_msg(?MSG_RANK_LEV, Acc0) ->
<<StartPos,
Len,
Acc1/binary>> = Acc0,
 {{StartPos,Len}, Acc1};

%% id = 2  
unpkg_msg(?MSG_RANK_POWER, Acc0) ->
<<StartPos,
Len,
Acc1/binary>> = Acc0,
 {{StartPos,Len}, Acc1};

%% id = 3  
unpkg_msg(?MSG_RANK_ARENA, Acc0) ->
<<StartPos,
Len,
Acc1/binary>> = Acc0,
 {{StartPos,Len}, Acc1};

%% id = 4  
unpkg_msg(?MSG_RANK_PET, Acc0) ->
<<StartPos,
Len,
Acc1/binary>> = Acc0,
 {{StartPos,Len}, Acc1};

%% id = 5  
unpkg_msg(?MSG_RANK_GUILD, Acc0) ->
<<StartPos,
Len,
Acc1/binary>> = Acc0,
 {{StartPos,Len}, Acc1};

%% id = 6  
unpkg_msg(?MSG_RANK_FRIEND, Acc0) ->
<<StartPos,
Len,
Acc1/binary>> = Acc0,
 {{StartPos,Len}, Acc1};

%% id = 7  
unpkg_msg(?MSG_RANK_ACCOMPLISHMENT, Acc0) ->
<<StartPos,
Len,
Acc1/binary>> = Acc0,
 {{StartPos,Len}, Acc1};

%% id = 8  
unpkg_msg(?MSG_RANK_SHENMO, Acc0) ->
<<StartPos,
Len,
Acc1/binary>> = Acc0,
 {{StartPos,Len}, Acc1};

%% id = 9  
unpkg_msg(?MSG_RANK_DAILY_1, Acc0) ->
<<StartPos,
Len,
Acc1/binary>> = Acc0,
 {{StartPos,Len}, Acc1};

%% id = 10  
unpkg_msg(?MSG_RANK_DAILY_2, Acc0) ->
<<StartPos,
Len,
Acc1/binary>> = Acc0,
 {{StartPos,Len}, Acc1};

%% id = 11  
unpkg_msg(?MSG_RANK_ABYSS, Acc0) ->
<<StartPos,
Len,
Acc1/binary>> = Acc0,
 {{StartPos,Len}, Acc1};

%% id = 12  
unpkg_msg(?MSG_RANK_SKY_KILL_MONSTER, Acc0) ->
<<StartPos,
Len,
Acc1/binary>> = Acc0,
 {{StartPos,Len}, Acc1};

%% id = 13  
unpkg_msg(?MSG_RANK_SKY_KILL_PLAYER, Acc0) ->
<<StartPos,
Len,
Acc1/binary>> = Acc0,
 {{StartPos,Len}, Acc1};

%% id = 14  
unpkg_msg(?MSG_RANK_SUIT, Acc0) ->
<<StartPos,
Len,
Acc1/binary>> = Acc0,
 {{StartPos,Len}, Acc1};

%% id = 15  
unpkg_msg(?MSG_RANK_GUILD_BOSS, Acc0) ->
<<StartPos,
Len,
Acc1/binary>> = Acc0,
 {{StartPos,Len}, Acc1};

%% id = 16  
unpkg_msg(?MSG_RANK_GWGC, Acc0) ->
<<StartPos,
Len,
Acc1/binary>> = Acc0,
 {{StartPos,Len}, Acc1};

%% id = 17  
unpkg_msg(?MSG_RANK_BOUNTY, Acc0) ->
<<StartPos,
Len,
Acc1/binary>> = Acc0,
 {{StartPos,Len}, Acc1};

%% id = 18  
unpkg_msg(?MSG_RANK_PET_NEW, Acc0) ->
<<StartPos,
Len,
Acc1/binary>> = Acc0,
 {{StartPos,Len}, Acc1};

%% id = 19  
unpkg_msg(?MSG_RANK_SUIT_NEW, Acc0) ->
<<StartPos,
Len,
Acc1/binary>> = Acc0,
 {{StartPos,Len}, Acc1};

%% id = 20  
unpkg_msg(?MSG_RANK_RIDE, Acc0) ->
<<StartPos,
Len,
Acc1/binary>> = Acc0,
 {{StartPos,Len}, Acc1};

%% id = 21  
unpkg_msg(?MSG_RANK_DAILY_4, Acc0) ->
<<StartPos,
Len,
Acc1/binary>> = Acc0,
 {{StartPos,Len}, Acc1};

%% id = 22  
unpkg_msg(?MSG_RANK_DAILY_5, Acc0) ->
<<StartPos,
Len,
Acc1/binary>> = Acc0,
 {{StartPos,Len}, Acc1};
unpkg_msg(Id, _) -> ok.




to_s(?MSG_RANK_LEV) -> <<"MSG_RANK_LEV">>; %% high 24, id 1
to_s(?MSG_RANK_POWER) -> <<"MSG_RANK_POWER">>; %% high 24, id 2
to_s(?MSG_RANK_ARENA) -> <<"MSG_RANK_ARENA">>; %% high 24, id 3
to_s(?MSG_RANK_PET) -> <<"MSG_RANK_PET">>; %% high 24, id 4
to_s(?MSG_RANK_GUILD) -> <<"MSG_RANK_GUILD">>; %% high 24, id 5
to_s(?MSG_RANK_FRIEND) -> <<"MSG_RANK_FRIEND">>; %% high 24, id 6
to_s(?MSG_RANK_ACCOMPLISHMENT) -> <<"MSG_RANK_ACCOMPLISHMENT">>; %% high 24, id 7
to_s(?MSG_RANK_SHENMO) -> <<"MSG_RANK_SHENMO">>; %% high 24, id 8
to_s(?MSG_RANK_DAILY_1) -> <<"MSG_RANK_DAILY_1">>; %% high 24, id 9
to_s(?MSG_RANK_DAILY_2) -> <<"MSG_RANK_DAILY_2">>; %% high 24, id 10
to_s(?MSG_RANK_ABYSS) -> <<"MSG_RANK_ABYSS">>; %% high 24, id 11
to_s(?MSG_RANK_SKY_KILL_MONSTER) -> <<"MSG_RANK_SKY_KILL_MONSTER">>; %% high 24, id 12
to_s(?MSG_RANK_SKY_KILL_PLAYER) -> <<"MSG_RANK_SKY_KILL_PLAYER">>; %% high 24, id 13
to_s(?MSG_RANK_SUIT) -> <<"MSG_RANK_SUIT">>; %% high 24, id 14
to_s(?MSG_RANK_GUILD_BOSS) -> <<"MSG_RANK_GUILD_BOSS">>; %% high 24, id 15
to_s(?MSG_RANK_GWGC) -> <<"MSG_RANK_GWGC">>; %% high 24, id 16
to_s(?MSG_RANK_BOUNTY) -> <<"MSG_RANK_BOUNTY">>; %% high 24, id 17
to_s(?MSG_RANK_PET_NEW) -> <<"MSG_RANK_PET_NEW">>; %% high 24, id 18
to_s(?MSG_RANK_SUIT_NEW) -> <<"MSG_RANK_SUIT_NEW">>; %% high 24, id 19
to_s(?MSG_RANK_RIDE) -> <<"MSG_RANK_RIDE">>; %% high 24, id 20
to_s(?MSG_RANK_DAILY_4) -> <<"MSG_RANK_DAILY_4">>; %% high 24, id 21
to_s(?MSG_RANK_DAILY_5) -> <<"MSG_RANK_DAILY_5">>; %% high 24, id 22
to_s(_) -> <<"unknown msg">>.
