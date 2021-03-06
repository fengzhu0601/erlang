%% Auto generated by sproto from bounty.sproto
%% Don't edit it.

-module(bounty_sproto).
-export([pkg_msg/2, unpkg_msg/2, to_s/1]).
-include("bounty_sproto.hrl").

%% id=1  
pkg_msg(?MSG_BOUNTY_TASK_LIST, {RefreshTimestamp, RefreshNum, BountyTask}) ->
<<?MSG_BOUNTY_TASK_LIST:16, 
RefreshTimestamp:32,
    RefreshNum,
    (length(BountyTask)):16, (iolist_to_binary([<<
TaskId:16,
    CurNum,
    TotalNum,
    TaskStatus>>
|| {TaskId, CurNum, TotalNum, TaskStatus} <- BountyTask]))/binary >>
;

%% id=2  
pkg_msg(?MSG_BOUNTY_PUSH_LIVENESS_PRIZE_LIST, {Liveness, LivenessPirze}) ->
<<?MSG_BOUNTY_PUSH_LIVENESS_PRIZE_LIST:16, 
Liveness:16,
    (length(LivenessPirze)):16, (iolist_to_binary([<<
Id,
    Status>>
|| {Id, Status} <- LivenessPirze]))/binary >>
;

%% id=3  
pkg_msg(?MSG_BOUNTY_COMPLETE, {Replynum}) ->
<<?MSG_BOUNTY_COMPLETE:16, 
Replynum>>
;

%% id=4  
pkg_msg(?MSG_BOUNTY_LIVENESS_GET_PRIZE, {Replynum}) ->
<<?MSG_BOUNTY_LIVENESS_GET_PRIZE:16, 
Replynum>>
;
pkg_msg(Id, _) -> ok.



%% id = 1  
unpkg_msg(?MSG_BOUNTY_TASK_LIST, Acc0) ->
<<Type,
Acc1/binary>> = Acc0,
 {{Type}, Acc1};

%% id = 3  
unpkg_msg(?MSG_BOUNTY_COMPLETE, Acc0) ->
<<TaskId:16,
Acc1/binary>> = Acc0,
 {{TaskId}, Acc1};

%% id = 4  
unpkg_msg(?MSG_BOUNTY_LIVENESS_GET_PRIZE, Acc0) ->
<<Index,
Acc1/binary>> = Acc0,
 {{Index}, Acc1};
unpkg_msg(Id, _) -> ok.




to_s(?MSG_BOUNTY_TASK_LIST) -> <<"MSG_BOUNTY_TASK_LIST">>; %% high 47, id 1
to_s(?MSG_BOUNTY_PUSH_LIVENESS_PRIZE_LIST) -> <<"MSG_BOUNTY_PUSH_LIVENESS_PRIZE_LIST">>; %% high 47, id 2
to_s(?MSG_BOUNTY_COMPLETE) -> <<"MSG_BOUNTY_COMPLETE">>; %% high 47, id 3
to_s(?MSG_BOUNTY_LIVENESS_GET_PRIZE) -> <<"MSG_BOUNTY_LIVENESS_GET_PRIZE">>; %% high 47, id 4
to_s(_) -> <<"unknown msg">>.
