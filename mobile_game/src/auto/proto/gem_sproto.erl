%% Auto generated by sproto from gem.sproto
%% Don't edit it.

-module(gem_sproto).
-export([pkg_msg/2, unpkg_msg/2, to_s/1]).
-include("gem_sproto.hrl").

%% id=1  
pkg_msg(?MSG_GEM_UPDATE, {ReplyNum}) ->
<<?MSG_GEM_UPDATE:16, 
ReplyNum>>
;

%% id=2  
pkg_msg(?MSG_EPIC_GEM_UP, {ReplyNum}) ->
<<?MSG_EPIC_GEM_UP:16, 
ReplyNum>>
;
pkg_msg(Id, _) -> ok.



%% id = 1  
unpkg_msg(?MSG_GEM_UPDATE, Acc0) ->
<<Gemid:32,
Num:16,
Acc1/binary>> = Acc0,
 {{Gemid,Num}, Acc1};

%% id = 2  
unpkg_msg(?MSG_EPIC_GEM_UP, Acc0) ->
<<BucketType,
EqmId:32,
GemId:32,
L__itemList:16, Acc1/binary>> = Acc0,
{ItemList, Acc2} = unpkg_list_struct__(L__itemList, Acc1, [], fun unpkg_ano_s__0/1)
,
{{BucketType,EqmId,GemId,ItemList}, Acc2};
unpkg_msg(Id, _) -> ok.


unpkg_ano_s__0(Acc0) ->
<<ItemId:32,
ItemCount,
Acc1/binary>> = Acc0,
 {{ItemId,ItemCount}, Acc1}.


to_s(?MSG_GEM_UPDATE) -> <<"MSG_GEM_UPDATE">>; %% high 5, id 1
to_s(?MSG_EPIC_GEM_UP) -> <<"MSG_EPIC_GEM_UP">>; %% high 5, id 2
to_s(_) -> <<"unknown msg">>.
unpkg_list_struct__(0, Bin, List, _Fn) -> {lists:reverse(List), Bin};
unpkg_list_struct__(L, Bin, List, Fn) -> {E, Bin1} = Fn(Bin), unpkg_list_struct__(L-1, Bin1, [E|List], Fn).