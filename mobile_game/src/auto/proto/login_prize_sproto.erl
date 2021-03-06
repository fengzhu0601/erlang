%% Auto generated by sproto from login_prize.sproto
%% Don't edit it.

-module(login_prize_sproto).
-export([pkg_msg/2, unpkg_msg/2, to_s/1]).
-include("login_prize_sproto.hrl").

%% id=1  
pkg_msg(?MSG_LOGIN_DAY_DATA_SC, {LoginDay, SigninDay}) ->
<<?MSG_LOGIN_DAY_DATA_SC:16, 
LoginDay,
    SigninDay>>
;

%% id=2  
pkg_msg(?MSG_ROLL_ITEM_DATA_SC, {Time, Count, ItemData}) ->
<<?MSG_ROLL_ITEM_DATA_SC:16, 
Time:32,
    Count,
    (length(ItemData)):16, (iolist_to_binary([<<
ItemBid:32,
    Num:32,
    IsLock>>
|| {ItemBid, Num, IsLock} <- ItemData]))/binary >>
;

%% id=3  
pkg_msg(?MSG_ROLL_ITEM_UPDATE_SC, {Index, IsLock}) ->
<<?MSG_ROLL_ITEM_UPDATE_SC:16, 
Index,
    IsLock>>
;

%% id=4  
pkg_msg(?MSG_SIGNIN_REWARD_CS, {LoginDay, SigninDay}) ->
<<?MSG_SIGNIN_REWARD_CS:16, 
LoginDay,
    SigninDay>>
;

%% id=5  
pkg_msg(?MSG_LEVEL_REWARD_CS, {}) ->
<<?MSG_LEVEL_REWARD_CS:16>> 
;

%% id=6  
pkg_msg(?MSG_ROLL_LOTTERY_CS, {Count, Index}) ->
<<?MSG_ROLL_LOTTERY_CS:16, 
Count,
    Index>>
;

%% id=7  
pkg_msg(?MSG_SIGN, {LoginDay, Lists, ReplyNum}) ->
<<?MSG_SIGN:16, 
LoginDay,
    (length(Lists)):16, (iolist_to_binary([<<
Day,
    IsSign>>
|| {Day, IsSign} <- Lists]))/binary ,
    ReplyNum>>
;

%% id=8  
pkg_msg(?MSG_SUPPLY_SIGN, {LoginDay, Lists, ReplyNum}) ->
<<?MSG_SUPPLY_SIGN:16, 
LoginDay,
    (length(Lists)):16, (iolist_to_binary([<<
Day,
    IsSign>>
|| {Day, IsSign} <- Lists]))/binary ,
    ReplyNum>>
;

%% id=9  
pkg_msg(?MSG_PUSH_SIGN_INFO, {LoginDay, Lists}) ->
<<?MSG_PUSH_SIGN_INFO:16, 
LoginDay,
    (length(Lists)):16, (iolist_to_binary([<<
Day,
    IsSign>>
|| {Day, IsSign} <- Lists]))/binary >>
;
pkg_msg(Id, _) -> ok.



%% id = 1  
unpkg_msg(?MSG_LOGIN_DAY_DATA_SC, Acc0) ->
{{}, Acc0};

%% id = 2  
unpkg_msg(?MSG_ROLL_ITEM_DATA_SC, Acc0) ->
{{}, Acc0};

%% id = 3  
unpkg_msg(?MSG_ROLL_ITEM_UPDATE_SC, Acc0) ->
{{}, Acc0};

%% id = 4  
unpkg_msg(?MSG_SIGNIN_REWARD_CS, Acc0) ->
<<Dayth,
Acc1/binary>> = Acc0,
 {{Dayth}, Acc1};

%% id = 5  
unpkg_msg(?MSG_LEVEL_REWARD_CS, Acc0) ->
<<Level,
Acc1/binary>> = Acc0,
 {{Level}, Acc1};

%% id = 6  
unpkg_msg(?MSG_ROLL_LOTTERY_CS, Acc0) ->
{{}, Acc0};

%% id = 7  
unpkg_msg(?MSG_SIGN, Acc0) ->
<<SignType,
Acc1/binary>> = Acc0,
 {{SignType}, Acc1};

%% id = 8  
unpkg_msg(?MSG_SUPPLY_SIGN, Acc0) ->
<<Dayth,
Acc1/binary>> = Acc0,
 {{Dayth}, Acc1};

%% id = 9  
unpkg_msg(?MSG_PUSH_SIGN_INFO, Acc0) ->
{{}, Acc0};
unpkg_msg(Id, _) -> ok.




to_s(?MSG_LOGIN_DAY_DATA_SC) -> <<"MSG_LOGIN_DAY_DATA_SC">>; %% high 31, id 1
to_s(?MSG_ROLL_ITEM_DATA_SC) -> <<"MSG_ROLL_ITEM_DATA_SC">>; %% high 31, id 2
to_s(?MSG_ROLL_ITEM_UPDATE_SC) -> <<"MSG_ROLL_ITEM_UPDATE_SC">>; %% high 31, id 3
to_s(?MSG_SIGNIN_REWARD_CS) -> <<"MSG_SIGNIN_REWARD_CS">>; %% high 31, id 4
to_s(?MSG_LEVEL_REWARD_CS) -> <<"MSG_LEVEL_REWARD_CS">>; %% high 31, id 5
to_s(?MSG_ROLL_LOTTERY_CS) -> <<"MSG_ROLL_LOTTERY_CS">>; %% high 31, id 6
to_s(?MSG_SIGN) -> <<"MSG_SIGN">>; %% high 31, id 7
to_s(?MSG_SUPPLY_SIGN) -> <<"MSG_SUPPLY_SIGN">>; %% high 31, id 8
to_s(?MSG_PUSH_SIGN_INFO) -> <<"MSG_PUSH_SIGN_INFO">>; %% high 31, id 9
to_s(_) -> <<"unknown msg">>.
