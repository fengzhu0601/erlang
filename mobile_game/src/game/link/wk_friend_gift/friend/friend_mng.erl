%%% coding:utf-8
%%%-------------------------------------------------------------------
%%% @author zlb
%%% @doc 好友模块 
%%%
%%% @end
%%%-------------------------------------------------------------------

-module(friend_mng).
-include_lib("pangzi/include/pangzi.hrl").

-include("inc.hrl").
-include("player.hrl").
-include("player_mod.hrl").
-include("friend.hrl").
-include("friend_struct.hrl").
-include("friend_mng_reply.hrl").
-include("handle_client.hrl").
-include("day_reset.hrl").
-include("load_phase_ac.hrl").
-include("system_log.hrl").
-include("../../wk_open_server_happy/open_server_happy.hrl").
-include("scene_def.hrl").
-include("achievement.hrl").

-define(NEAR_MAX, 50).


-export([
    lookup_fp/1, lookup_fc/1
    , get_friend_score/1
    , rename/0, level_up/0, change_job/0   %% 更新相关信息需要通知全体好友
    , apply_friend_state/1                 %% 获取申请好友状态
    , is_valid_gift_qua/1
    , send_my_info/0
]).
%%是否有效的礼包品质
is_valid_gift_qua(Qua) ->
    lists:member(Qua, ?GIFT_QUAS).

%% 获取友好度
get_friend_score(Id) ->
    #friend_private{score = Score} = lookup_fp(Id),
    Score.

lookup_fp(PlayerId) ->
    case dbcache:lookup(?player_friend_private, PlayerId) of
        [FP] -> FP;
        _E -> ?none
    end.
lookup_fc(PlayerId) ->
    case dbcache:lookup(?player_friend_common, PlayerId) of
        [FC] -> FC;
        _ -> ?none
    end.

rename() ->     %% 改名更新好友信息
    change_info(?TRUE).
level_up() ->   %% 升级更新好友信息
    change_info(?TRUE).
change_job() -> %% 换职业更新好友信息
    change_info(?TRUE).


change_info(IsOnline) ->
    Id = get(?pd_id),
    Name = get(?pd_name),
    Lev = get(?pd_level),
    Career = get(?pd_career),
    CombatPower = get(?pd_combat_power),
    case {lookup_fp(Id), lookup_fc(Id)} of
        {#friend_private{friend_ids = FIds}, #friend_common{open_rob = OpenRob, gift_qua = GiftQua, send_count = Send, recv_count = _Recv}} ->
            lists:foreach(fun({FId, ThisPlayerScore}) ->
                %FriendInfo =  {Id, Name, Lev, Career, Score, OpenRob, GiftQua, Send, Recv, IsOnline},
                FriendInfo = {Id, Name, Lev, Career, CombatPower, GiftQua, Send, OpenRob, ThisPlayerScore, IsOnline},
                Pkg = ?to_client_msg(friend_sproto:pkg_msg(?MSG_FRIEND_CHANGE, {?T_UPDATE_FRIEND, FriendInfo})),
                world:send_to_player_if_online(FId, Pkg)
            end,
            FIds);
        _ ->
            ignore
    end.

apply_friend_state(PlayerId) ->
    SelfId = get(?pd_id),
    #friend_private{friend_ids = FIds} = lookup_fp(SelfId),
    #friend_common{recv_friend_applys = FAL} = lookup_fc(PlayerId),
    IsFriend = lists:keymember(PlayerId, 1, FIds),
    IsApply = lists:member(SelfId, FAL),
    if
        IsApply -> ?FRIEND_APPLYING;
        IsFriend -> ?FRIEND_APPLYED;
        ?true -> ?FRIEND_UNAPPLY
    end.

handle_client({Pack, Arg}) ->
    handle_client(Pack, Arg).

%% 删除好友
handle_client(?MSG_FRIEND_DEL, {PlayerId}) ->
    SelfId = get(?pd_id),
    del_friend(SelfId, PlayerId),
    msg_service:send_msg(PlayerId, ?mod_msg(friend_mng, {del, SelfId})),
%%    world:send_to_player(PlayerId, ?mod_msg(friend_mng, {del, SelfId})),
    ok;

%% 申请添加好友
handle_client(?MSG_FRIEND_APPLY, {PlayerId}) ->
    case friend:is_robot_list(PlayerId) of
        true ->
            phase_achievement_mng:do_pc(?PHASE_AC_FRIEND_COUNT, 1),
            open_server_happy_mng:sync_task(?HAVE_FRIEND_COUNT, 1),
            add_robot_friend(PlayerId),
            ?player_send(friend_sproto:pkg_msg(?MSG_FRIEND_APPLY, {?REPLY_MSG_FRIEND_APPLY_OK}));

        _ ->
            ReplyNum = case apply_add_friend(PlayerId) of
                           ok ->
                               phase_achievement_mng:do_pc(?PHASE_AC_FRIEND_COUNT, 1),
                               open_server_happy_mng:sync_task(?HAVE_FRIEND_COUNT, 1),
                               ?REPLY_MSG_FRIEND_APPLY_OK;
                           {error, Reason} ->
                               ?debug_log_friend("add fail ~w", [Reason]),
                               if
                                   Reason =:= already_friend ->
                                       ?REPLY_MSG_FRIEND_APPLY_1;
                                   Reason =:= friend_max ->
                                       ?REPLY_MSG_FRIEND_APPLY_2;
                                   Reason =:= cant_add_self ->
                                       ?REPLY_MSG_FRIEND_APPLY_3;
                                   Reason =:= player_not_found ->
                                       ?REPLY_MSG_FRIEND_APPLY_4;
                                   Reason =:= already_apply ->
                                       ?REPLY_MSG_FRIEND_APPLY_5;
                                   ?true ->
                                       ?REPLY_MSG_FRIEND_APPLY_255
                               end
                       end,
            ?player_send(friend_sproto:pkg_msg(?MSG_FRIEND_APPLY, {ReplyNum}))
    end;

%% 添加好友回复
handle_client(?MSG_FRIEND_REPLY_APPLY, {PlayerId, IsAgree}) ->
%%    ?if_(PlayerId =:= 0, ?return_err(?ERR_FRIEND_REPLY_APPLY_PLAYERID) ),
    ?if_(PlayerId =:= 0, ?player_send(friend_sproto:pkg_msg(?MSG_FRIEND_REPLY_APPLY, {0, PlayerId}))),
    ReplyNum = case rep_apply_add_friend(PlayerId, IsAgree) of
                   ok ->
                       ?REPLY_MSG_FRIEND_REPLY_APPLY_OK;
                   {error, Reason} ->
                       if
                           Reason == already_friend ->
                               ?REPLY_MSG_FRIEND_REPLY_APPLY_1;
                           Reason == friend_max ->
                               ?REPLY_MSG_FRIEND_REPLY_APPLY_2;
                           Reason == apply_timeout ->
                               ?REPLY_MSG_FRIEND_REPLY_APPLY_3;
                           ?true ->
                               ?REPLY_MSG_FRIEND_REPLY_APPLY_255
                       end
               end,
    % ?DEBUG_LOG("ReplyNum-------------------:~p", [{ReplyNum,PlayerId}]),
    ?player_send(friend_sproto:pkg_msg(?MSG_FRIEND_REPLY_APPLY, {ReplyNum, PlayerId}));

%% 精确搜索好友信息
% handle_client(?MSG_FRIEND_INFOS, {Name}) ->
%     Names = esqlite_config:like(player_tab, Name),
%     case is_list(Names) of
%         true ->
%             FriendInfos = lists:foldl(
%                 fun
%                     ({TmpName}, AccIn) ->
%                         case platfrom:get_player_id_by_name(TmpName) of
%                             Id when is_integer(Id) ->
%                                 [get_friend_info_def(Id, 0) | AccIn];
%                             _R ->
%                                 AccIn
%                         end
%                 end,
%                 [],
%                 Names
%             ),
%             ?player_send(friend_sproto:pkg_msg(?MSG_FRIEND_INFOS, {FriendInfos}));
%         _ ->
%             ?player_send(friend_sproto:pkg_msg(?MSG_FRIEND_INFOS, {[]}))
%     end;

%% 精确搜索好友信息
handle_client(?MSG_FRIEND_INFOS, {Name}) ->
    ?DEBUG_LOG("Name--------------------:~p",[Name]),
    List = gm_data:like(player, Name),
    FriendInfos = 
    lists:foldl(fun(L, AccIn) ->
        Data = get_friend_info_def(lists:nth(1, L), 0),
        case element(1, Data) of
            0 ->
                AccIn;
            _ ->
                [Data|AccIn]
        end   
        %[get_friend_info_def(lists:nth(1, L), 0) | AccIn]   
    end,
    [],
    List),
    ?player_send(friend_sproto:pkg_msg(?MSG_FRIEND_INFOS, {FriendInfos}));
       
    %%FriendInfo = case player:get_player_id_by_name(Name) of
    %%Id when is_integer(Id) ->
    %%get_friend_info_def(Id);
    %%_ -> friend_info_def()
    %%end,
    %%TL = ets:tab2list(?player_friend_private),
    %%SelfId = get(?pd_id),

    %%FriendInfos = lists:foldl(fun(#friend_private{id = Id}, Acc) ->
    %%if
    %%Id =/= SelfId ->
    %%?debug_log_friend("~w-----------friend ~w", [Id, get_friend_info_def(Id)]),
    %%[get_friend_info_def(Id)|Acc];
    %%?true -> Acc
    %%end
    %%end, [], TL),
    %%?debug_log_friend("friendL ~w", [FriendInfos]),

%?player_send( friend_sproto:pkg_msg(?MSG_FRIEND_INFOS, {[FriendInfo] }) );
%% 获取好友列表
handle_client(?MSG_FRIEND_LIST, {}) ->
    SelfId = get(?pd_id),
    #friend_private{friend_ids = FIds} = lookup_fp(SelfId),
    FriendsInfos = [get_friend_info_def(FId, ThisPlayerScore) || {FId, ThisPlayerScore} <- FIds],
    ?player_send(friend_sproto:pkg_msg(?MSG_FRIEND_LIST, {FriendsInfos}));

%% 获取个人面板信息
handle_client(?MSG_FRIEND_MY_INFO, {}) ->
    send_my_info();

%% 获取申请信息列表
handle_client(?MSG_FRIEND_MSGS, {}) ->
    send_applys_info();

%% 获取附近玩家(红包)信息
handle_client(?MSG_FRIEND_NEAR, {Count}) ->
    SelfId = get(?pd_id),
    Ids = scene_player:get_all_player_ids_by_scene(get(?pd_scene_id)),
    NewIds =
        lists:foldl(
            fun(PlayerId, Acc) ->
                IsRobot = robot_new:is_robot(PlayerId),
                if
                    IsRobot ->
                        Acc;
                    true ->
                        [PlayerId | Acc]
                end
            end,
            [],
            Ids
        ),
    ?INFO_LOG("==================== MSG_FRIEND_NEAR ==================== ~p", [NewIds]),
    Ids1 = lists:sublist(NewIds, min(Count, ?NEAR_MAX)),
    FriendInfos = lists:foldl(
        fun(Id, Acc) ->
                case Id =/= SelfId of
                    true -> [get_friend_info_def(Id, 0) | Acc];
                    _ -> Acc
                end
        end,
        [],
        Ids1
    ),
    %% 当附近的玩家数量不足5人时由系统自动推送机器人数量使列表增加至5-8人
    Len = length(FriendInfos),
    FriendInfos1 = case Len < 5 of
        true ->
            [Num] = com_util:rand_more([0, 1, 2, 3], 1),
            FriendInfos ++ friend:push_robot_list(5 - Len + Num);
        _ ->
            FriendInfos
    end,
    ?debug_log_friend("Ids  ~w, List ~w, Pkg ~w", [Ids, FriendInfos1, friend_sproto:pkg_msg(?MSG_FRIEND_NEAR, {FriendInfos1})]),
    ?player_send(friend_sproto:pkg_msg(?MSG_FRIEND_NEAR, {FriendInfos1}));

%% 抢红包
handle_client(?MSG_FRIEND_ROB_GIFT, {Id}) ->
    ReplyNum = case rob_gift(Id) of
                   ok ->
                       ?REPLY_MSG_FRIEND_ROB_GIFT_OK;
                   {error, Reason} ->
                       if
                           Reason =:= not_open_rob ->
                               ?REPLY_MSG_FRIEND_ROB_GIFT_1;
                           Reason =:= send_max ->
                               ?REPLY_MSG_FRIEND_ROB_GIFT_2;
                           Reason =:= recv_max ->
                               ?REPLY_MSG_FRIEND_ROB_GIFT_3;
                           Reason =:= already_get ->
                               ?REPLY_MSG_FRIEND_ROB_GIFT_4;
                           % Reason =:= already_send->
                           %    ?REPLY_MSG_FRIEND_ROB_GIFT_5;
                           Reason =:= cant_self ->
                               ?REPLY_MSG_FRIEND_ROB_GIFT_6;
                           Reason =:= is_offline ->
                               ?REPLY_MSG_FRIEND_ROB_GIFT_7;
                           ?true ->
                               ?REPLY_MSG_FRIEND_ROB_GIFT_255
                       end
               end,
    ?player_send(friend_sproto:pkg_msg(?MSG_FRIEND_ROB_GIFT, {ReplyNum}));


%% 索取红包申请
handle_client(?MSG_FRIEND_ASK_FOR_GIFT, {Id}) ->
    ReplyNum = case ask_for_gift_apply(Id) of
                   ok -> ?REPLY_MSG_FRIEND_ASK_FOR_GIFT_OK;
                   {error, Reason} ->
                       if
                           Reason =:= cant_self ->
                               ?REPLY_MSG_FRIEND_ASK_FOR_GIFT_1;
                           Reason =:= send_max ->
                               ?REPLY_MSG_FRIEND_ASK_FOR_GIFT_2;
                           Reason =:= already_get ->
                               ?REPLY_MSG_FRIEND_ASK_FOR_GIFT_3;
                           Reason =:= recv_max ->
                               ?REPLY_MSG_FRIEND_ASK_FOR_GIFT_4;
                           Reason =:= already_apply ->
                               ?REPLY_MSG_FRIEND_ASK_FOR_GIFT_5;
                           Reason =:= is_offline ->
                               ?REPLY_MSG_FRIEND_ASK_FOR_GIFT_6;
                           ?true ->
                               ?ERROR_LOG("ask_for_gift_apply error ~w", [Reason]),
                               ?REPLY_MSG_FRIEND_ASK_FOR_GIFT_255 end
               end,
    ?player_send(friend_sproto:pkg_msg(?MSG_FRIEND_ASK_FOR_GIFT, {ReplyNum}));

%% 回复申请索取红包
handle_client(?MSG_FRIEND_REP_ASK_FOR_GIFT, {Id, IsAgree}) ->
    ReplyNum = case rep_ask_for_gift_apply(Id, IsAgree) of
                   ok ->
                       ?REPLY_MSG_FRIEND_REP_ASK_FOR_GIFT_OK;
                   {error, Reason} ->
                       ?debug_log_friend("req ask gift ~w", [Reason]),
                       if
                           Reason == send_max ->
                               ?REPLY_MSG_FRIEND_REP_ASK_FOR_GIFT_1;
                           Reason == recv_max ->
                               ?REPLY_MSG_FRIEND_REP_ASK_FOR_GIFT_2;
                           Reason == already_get ->
                               ?REPLY_MSG_FRIEND_REP_ASK_FOR_GIFT_3;
                           Reason == apply_timeout ->
                               ?REPLY_MSG_FRIEND_REP_ASK_FOR_GIFT_4;
                           ?true ->
                               ?REPLY_MSG_FRIEND_REP_ASK_FOR_GIFT_255
                       end
               end,
    ?player_send(friend_sproto:pkg_msg(?MSG_FRIEND_REP_ASK_FOR_GIFT, {ReplyNum}));

%% 赠送红包申请
handle_client(?MSG_FRIEND_SEND_GIFT, {Id}) ->
    ReplyNum = case send_gift_apply(Id) of
                   ok ->
                       ?REPLY_MSG_FRIEND_SEND_GIFT_OK;
                   {error, Reason} ->
                       ?DEBUG_LOG("---------    ~w", [Reason]),
                       if
                           Reason =:= send_max -> ?REPLY_MSG_FRIEND_SEND_GIFT_1;
                           Reason =:= recv_max -> ?REPLY_MSG_FRIEND_SEND_GIFT_2;
                           Reason =:= already_get -> ?REPLY_MSG_FRIEND_SEND_GIFT_3;
                           Reason =:= cant_self -> ?REPLY_MSG_FRIEND_SEND_GIFT_4;
                           Reason =:= is_offline -> ?REPLY_MSG_FRIEND_SEND_GIFT_5;
                           ?true ->
                               ?REPLY_MSG_FRIEND_SEND_GIFT_255
                       end
               end,
    ?DEBUG_LOG("---------    ~w", [ReplyNum]),
    ?player_send(friend_sproto:pkg_msg(?MSG_FRIEND_SEND_GIFT, {ReplyNum}));

%% 接受赠送红包    
handle_client(?MSG_FRIEND_ACCEPT_SEND_GIFT, {Id}) ->

    ReplyNum = case rep_send_gift_apply(Id) of
                   ok ->
                       ?REPLY_MSG_FRIEND_ACCEPT_SEND_GIFT_OK;
                   {error, Reason} ->
                       if
                           Reason =:= apply_timeout -> ?REPLY_MSG_FRIEND_ACCEPT_SEND_GIFT_1;
                           ?true ->
                               ?REPLY_MSG_FRIEND_ACCEPT_SEND_GIFT_255
                       end
               end,
    ?player_send(friend_sproto:pkg_msg(?MSG_FRIEND_ACCEPT_SEND_GIFT, {ReplyNum}));

%% 设置抢红包状态 
handle_client(?MSG_FRIEND_SET_GIFT_STAT, {Stat}) ->
    friend_gift_svr:set_rob_stat(get(?pd_id), Stat);

%% 请求已经发送过红包的id列表
handle_client(?MSG_FRIEND_GIFT_APPLYS, {}) ->
    SelfId = get(?pd_id),
    _FC = #friend_common{send_player_ids = SendIds, recv_player_ids = RecvIds
        , send_friend_ids = SendFIds, send_req_ids = SendRIds
    } = lookup_fc(SelfId),
    ?debug_log_friend("FC ~w", [_FC]),
    ?player_send(friend_sproto:pkg_msg(?MSG_FRIEND_GIFT_APPLYS, {SendIds, RecvIds, SendFIds, SendRIds}));


%% 1.必须是好友必须在线 2.删除掉花朵道具，查找出花朵添加的好友度 3.添加好友度，4.广播公告 5.赠送的人也获得友好度，并且产生一条记录
handle_client(?MSG_GIVE_GIFT_TO_FRIEND, {ItemBid, ToPlayerId, MsgBin}) ->
    PlayerId = get(?pd_id),
    case world:is_player_online(PlayerId) of
        true ->
            case apply_friend_state(ToPlayerId) of
                ?FRIEND_APPLYED ->
                    case game_res:try_del([{ItemBid, 1}], ?FLOW_REASON_FRIEND_GIFT) of
                        ok -> %1.增加友好度 2.广播\场景播放特效 3.对方增加友好度、产生一条记录
                            #{item_flowers_give_score := ItemScoreList} = misc_cfg:get_friend_cfg(),
                            case lists:keyfind(ItemBid, 1, ItemScoreList) of
                                false -> ?return_err(?ERR_NO_CFG);
                                {ItemBid, ItemScore, IsBroadcast, EffectId, BroadcastType} ->
                                    case IsBroadcast of
                                        ?TRUE ->
                                            friend:broadcast(get(?pd_name), player:lookup_info(ToPlayerId, ?pd_name), MsgBin);
                                        ?FALSE -> ok
                                    end,
                                    case EffectId of
                                        0 -> ok;
                                        EffectId -> scene_mng:scene_broadcast_effect(BroadcastType, EffectId)
                                    end,
                                    {FP, _AllScore} = friend:add_score(?give_flowers_get_score, {lookup_fp(get(?pd_id)), ToPlayerId, ItemScore}),
                                    update_fp(FP),
                                    Pkg = get_friend_info_def(ToPlayerId, _AllScore),
                                    ?player_send(friend_sproto:pkg_msg(?MSG_FRIEND_CHANGE, {?T_UPDATE_FRIEND, Pkg})),
                                    world:send_to_player_if_online(ToPlayerId, ?mod_msg(?MODULE, {add_player_score, PlayerId, ItemBid, MsgBin, ItemScore})),
                                    ?player_send(friend_sproto:pkg_msg(?MSG_GIVE_GIFT_TO_FRIEND, {})),
                                    send_my_info()
                            end;
                        _ -> ?return_err(?ERR_COST_NOT_ENOUGH)
                    end;
                Other -> ?return_err(Other)
            end;
        false ->
            ?return_err(?ERR_PLAYER_OFFLINE)
    end;

handle_client(?MSG_DEL_GIFT_INFO, {MsgId}) ->
    FP = #friend_private{send_flowers = SendFlowersInfo} = lookup_fp(get(?pd_id)),
    NewSendFlowersInfo = lists:keydelete(MsgId, 1, SendFlowersInfo),
    update_fp(FP#friend_private{send_flowers = NewSendFlowersInfo}),
    ?player_send(friend_sproto:pkg_msg(?MSG_DEL_GIFT_INFO, {}));

handle_client(Mod, Msg) ->
    ?ERROR_LOG("no known msg Mod:~s Msg:~p", [friend_sproto:to_s(Mod), Msg]).


handle_frame(_) -> ok.

%% 删除好友
handle_msg(_FromMod, {del, PlayerId}) ->
    SelfId = get(?pd_id),
    del_friend(SelfId, PlayerId);

%% 添加好友
handle_msg(_FromMod, {add_friend, PlayerId}) ->
    SelfId = get(?pd_id),
    FP = lookup_fp(SelfId),
    event_eng:post(?ev_friend_add, {?ev_friend_add, 0}, 1),
    add_friend(FP, PlayerId);

%% 推送好友信息变化
handle_msg(_FromMod, {push_change_info, IsOnline}) ->
    change_info(IsOnline);

%% 被抢红包
handle_msg(_FromMod, {rob_gift, PlayerId, GiftQua}) ->
    FP = lookup_fp(get(?pd_id)),
    NFP = friend:add_gift_score(FP, GiftQua, PlayerId),
    update_fp(NFP),
    send_my_info(),
    change_info(?TRUE);

%% 索取红包转发
handle_msg(_FromMod, {ask_for_gift_apply, PlayerId, PName, PLev, PCareer, GiftQua, DelIdsTp}) ->
    case DelIdsTp of
        {[], [], []} -> ignore;
        _ ->
            send_del_apply(DelIdsTp)
    end,
    send_my_info(),
    ?player_send(friend_sproto:pkg_msg(?MSG_FRIEND_GIFT_MSG, {PlayerId, PName, PLev, PCareer, GiftQua}));

%% 回复索取红包
handle_msg(_FromMod, {rep_ask_for_gift_apply, ItemTpL}) ->
    case is_list(ItemTpL) of
        ?true ->
            game_res:try_give_ex(ItemTpL, ?S_MAIL_FRIEND_GIFT, ?FLOW_REASON_FRIEND_GIFT);
        _ -> ignore
    end,
    send_my_info(),
    change_info(?TRUE);

%% 转发赠送红包消息
handle_msg(_FromMod, {send_gift_apply, PlayerId, ItemTpL, DelIdsTp}) ->
    change_info(?TRUE),
    case DelIdsTp of
        {[], [], []} -> ignore;
        _ ->
            send_del_apply(DelIdsTp)
    end,
    CliItemTpL = to_cli_itemtps(ItemTpL, []),
    [PName, PLev, PCareer] = player:lookup_info(PlayerId, [?pd_name, ?pd_level, ?pd_career]),
    ?player_send(friend_sproto:pkg_msg(?MSG_FRIEND_SEND_GIFT_MSG, {PlayerId, PName, PLev, PCareer, CliItemTpL}));


%% 设置抢红包模式
handle_msg(_FromMod, {set_rob_stat, Stat}) ->
    change_info(?TRUE),
    ?player_send(friend_sproto:pkg_msg(?MSG_FRIEND_SET_GIFT_STAT, {Stat}));


%% 凌晨0点重置
handle_msg(_FromMod, zore_reset) ->
    ?player_send(friend_sproto:pkg_msg(?MSG_FRIEND_GIFT_APPLYS, {[], [], [], []})),
    ?player_send(friend_sproto:pkg_msg(?MSG_FRIEND_MSGS, {[], [], [], []})),
    FP = lookup_fp(get(?pd_id)),
    update_fp(FP#friend_private{send_flowers = [], msg_id = 0}),
    send_my_info();


%% 别人赠送鲜花给自己，更新友好度、更新日志信息
handle_msg(_FromMod, {add_player_score, PlayerId, ItemBid, MsgBin, AddScore}) ->
    {FP, PlayerAllScore} = friend:add_score(?give_flowers_get_score, {lookup_fp(get(?pd_id)), PlayerId, AddScore}),
    MsgId = FP#friend_private.msg_id,
    NewPF = FP#friend_private{send_flowers = [{MsgId, PlayerId, ItemBid, MsgBin} | FP#friend_private.send_flowers]},
    update_fp(NewPF#friend_private{msg_id = MsgId + 1}),
    Pkg = get_friend_info_def(PlayerId, PlayerAllScore),
    ?player_send(friend_sproto:pkg_msg(?MSG_FRIEND_CHANGE, {?T_UPDATE_FRIEND, Pkg})),
    [PlayerName, PlayerLevel, PlayerCareer] = player:lookup_info(PlayerId, [?pd_name, ?pd_level, ?pd_career]),
    ?player_send(friend_sproto:pkg_msg(?MSG_GIVE_GIFT_RECIVE_INFO, {MsgId, PlayerId, PlayerName, PlayerLevel, PlayerCareer, ItemBid, MsgBin})),
    send_my_info();

handle_msg(FromMod, Msg) ->
    ?ERROR_LOG("~p recv a unknown msg ~p from ~p", [?pname(), Msg, FromMod]).


create_mod_data(SelfId) ->
    case dbcache:insert_new(?player_friend_private, #friend_private{id = SelfId}) of
        ?true -> 
            ok;
        ?false -> 
            ?ERROR_LOG("player ~p create new player_friend_private not alread exists ", [SelfId])
    end,

    FC = friend_gift_svr:init_friend_gifts(#friend_common{id = SelfId}),
    case dbcache:insert_new(?player_friend_common, FC) of
        ?true -> 
            ok;
        ?false -> 
            ?ERROR_LOG("player ~p create new player_friend_common not alread exists ", [SelfId])
    end.

load_mod_data(PlayerId) ->
    case dbcache:load_data(?player_friend_private, PlayerId) of
        [] ->
            ?ERROR_LOG("player ~p can not find player_friend_private mode", [PlayerId]),
            exit({?err_load, "can not find data"});
        [#friend_private{}] -> 
            ok
    end.


init_client() -> ok.

view_data(Msg) ->
    Msg.

online() ->
    Id = get(?pd_id),
    ?ifdo(player:is_daliy_first_online() =:= ?false, reset_private(Id)),
    change_info(?TRUE).
    %% test
    % case load_cfg_scene:get_pid(105) of
    %     ?none -> 
    %         pass;
    %     Pid ->
    %         %exit(Pid, test),
    %         Pid ! test
    %         %exit(self(), kill)
    % end.

offline(_PlayerId) -> change_info(?FALSE).
save_data(_) -> ok.
load_db_table_meta() ->
    [
        #db_table_meta{
            name = ?player_friend_private
            , fields = ?record_fields(friend_private)
            , record_name = friend_private
            , shrink_size = 1
            %,load_all = true
            , flush_interval = 3}
    ].

on_day_reset(_Player) ->
%%    ?INFO_LOG("===========================Player:~p================================",[_Player]),
%%    ?INFO_LOG("Player:~p",[_Player]),
    %friend_gift_svr:zore_reset().
    ok.
%%----------------------------------------------------
%% 私有方法
update_fp(FP) ->
    dbcache:update(?player_friend_private, FP).

reset_private(Id) ->
    dbcache:update_element(?player_friend_private, Id, [{#friend_private.day_chat_score, 0}, {#friend_private.day_gift_score, 0}]).

%% 删除好友
del_friend(SelfId, PlayerId) ->
    Friend = #friend_private{friend_ids = FIds} = lookup_fp(SelfId),
    NFIds = lists:keydelete(PlayerId, 1, FIds),
    friend_gift_svr:del_friend(SelfId, PlayerId),
    update_fp(Friend#friend_private{friend_ids = NFIds}),
    case lists:keyfind(PlayerId, 1, FIds) of                              %%  判断删除之前的好友列表里面是否有当前玩家，如果已经删除则不需要向客户端发送消息
        false ->
            pass;
        _ ->
            ?player_send(friend_sproto:pkg_msg(?MSG_FRIEND_DEL, {PlayerId}))
    end.
%% 申请添加好友
apply_add_friend(PlayerId) ->
    #{max := Max, vip_max := VipMax} = misc_cfg:get_friend_cfg(),
    SelfId = get(?pd_id),
    #friend_private{friend_ids = FIdL} = lookup_fp(SelfId),
    FLen = length(FIdL),
    IsFriend = lists:keymember(PlayerId, 1, FIdL),

    %% TODO: vip接口
    %IsVip = ?false,
    IsVip = api:player_is_Vip(),
    if
        IsFriend -> {error, already_friend};
%%        IsVip, FLen >= VipMax -> {error, friend_max};
%%        FLen >= Max -> {error, friend_max};
        %% vip玩家
        IsVip, FLen >= VipMax -> {error, friend_max};
        %% 非vip玩家
        IsVip =:= ?false, FLen >= Max -> {error, friend_max};

        SelfId =:= PlayerId -> {error, cant_add_self};
        ?true ->
            case lookup_fp(PlayerId) of
                #friend_private{} ->
                    case friend_gift_svr:apply_add_friend(SelfId, PlayerId) of
                        {ok, DelIdsTp} ->
                            Name = get(?pd_name),
                            Lev = get(?pd_level),
                            Career = get(?pd_career),
                            case DelIdsTp of
                                {[], [], []} -> ignore;
                                _ ->
                                    world:send_to_player_if_online(PlayerId,
                                        ?to_client_msg(friend_sproto:pkg_msg(?MSG_FRIEND_DEL_MSG, DelIdsTp))
                                    )
                            end,
                            world:send_to_player_if_online(PlayerId,
                                ?to_client_msg(friend_sproto:pkg_msg(?MSG_FRIEND_APPLY_MSG, {SelfId, Name, Lev, Career}))
                            ),
                            ?player_send(friend_sproto:pkg_msg(?MSG_FRIEND_ADD_GIFT_APPLY, {?T_ADD_FRIEND_APPLY, PlayerId})),
                            ok;
                        {error, Err} -> {error, Err}
                    end;
                _ -> {error, player_not_found}
            end
    end.
%% 回复申请添加好友
rep_apply_add_friend(PlayerId, IsAgree) ->
    #{max := Max, vip_max := VipMax} = misc_cfg:get_friend_cfg(),
    SelfId = get(?pd_id),
    FP = #friend_private{friend_ids = FIdL} = lookup_fp(SelfId),
    FLen = length(FIdL),
    IsFriend = lists:keymember(PlayerId, 1, FIdL),
    %% TODO: vip接口
    %IsVip = ?false,
    IsVip = api:player_is_Vip(),
    if
        IsFriend -> {error, already_friend};
    %IsVip, FLen >= VipMax -> {error, friend_max};
%%        FLen >= Max -> {error, friend_max};
    %% vip玩家
        IsVip, FLen >= VipMax -> {error, friend_max};
    %% 非vip玩家
        IsVip =:= ?false, FLen >= Max -> {error, friend_max};
        ?true ->
            send_del_apply({[], [], [PlayerId]}),
            send_del_apply2({[], [], [get(?pd_id)]}, PlayerId),
            case friend_gift_svr:rep_apply_add_friend(SelfId, PlayerId) of
                ok when IsAgree =:= ?FALSE ->
                    world:send_to_player_if_online(PlayerId,
                        ?to_client_msg(friend_sproto:pkg_msg(?MSG_FRIEND_ADD_GIFT_APPLY, {?T_SUB_FRIEND_APPLY, SelfId}))
                    ),
                    ok;
                ok ->
                    add_friend(FP, PlayerId),
                    world:send_to_player(PlayerId, ?mod_msg(friend_mng, {add_friend, SelfId})),
                    %%world:send_to_player_if_online(PlayerId,
                    %%?to_client_msg(friend_sproto:pkg_msg(?MSG_FRIEND_ADD_GIFT_APPLY, {?T_SUB_FRIEND_APPLY, SelfId}))
                    %%),
                    ok;
                {error, Err} -> {error, Err}
            end
    end.

add_friend(FP = #friend_private{id = Id, friend_ids = FIdL}, PlayerId) ->
    update_fp(FP#friend_private{friend_ids = [{PlayerId, 0} | FIdL]}),
    achievement_mng:do_ac(?shejiaodaren),
    Pkg = get_friend_info_def(PlayerId, 0),
    % ?DEBUG_LOG("friend_sproto:pkg:~p", [friend_sproto:pkg_msg(?MSG_FRIEND_CHANGE, {?T_ADD_FRIEND, Pkg})]),
    ?player_send(friend_sproto:pkg_msg(?MSG_FRIEND_CHANGE, {?T_ADD_FRIEND, Pkg})),
    chat_mng:chat_sys_p2p_friend(Id, {PlayerId, ?FRIEND_CHAT_SYS_TEXT_1}).

friend_info_def() ->
    {0, <<>>, 1, 1, 0, 0, 0, 0, 0, 0}.
get_friend_info_def(PlayerId, ThisPlayerScore) ->
    case get_friend_info(PlayerId, ThisPlayerScore) of
        {ok, FriendInfo} -> FriendInfo;
        _ -> friend_info_def()
    end.
get_friend_info(PlayerId, ThisPlayerScore) ->
    case player:lookup_info(PlayerId, [?pd_name, ?pd_level, ?pd_career, ?pd_combat_power]) of
        [PName, PLev, PCareer, CombatPower] when is_binary(PName), is_integer(PLev), is_integer(PCareer) ->
            #friend_common{gift_qua = GiftQua, send_count = GiftNum, open_rob = GiftStat} = lookup_fc(PlayerId),
            SenceId = scene_mng:lookup_player_scene_id_if_online(PlayerId),
%%             IsOnline = ?if_else(SenceId =:= offline, ?FALSE, ?TRUE),
            IsOnline =
                case friend:is_robot_list(PlayerId) of                       %% 判断当如果是机器人时，在好友列表中显示为在线状态
                    true -> ?TRUE;
                    _ -> ?if_else(SenceId =:= offline, ?FALSE, ?TRUE)
                end,
            {ok, {PlayerId, PName, PLev, PCareer, CombatPower, GiftQua, GiftNum, GiftStat, ThisPlayerScore, IsOnline}};
        _ -> error
    end.

send_my_info() ->
    SelfId = get(?pd_id),
    #friend_private{score = Score} = lookup_fp(SelfId),
    #friend_common{gift_qua = GiftQua, send_count = SendGiftNum
        , recv_count = RecvGiftNum, open_rob = GiftStat
    } = lookup_fc(SelfId),
    ?player_send(friend_sproto:pkg_msg(?MSG_FRIEND_MY_INFO, {Score, GiftQua, SendGiftNum, RecvGiftNum, GiftStat})).



send_applys_info() ->
    SelfId = get(?pd_id),
    #friend_common{send_gift_applys = SGAL, req_gift_applys = RGAL, recv_friend_applys = FAL} = lookup_fc(SelfId),
    CliSGAL = [begin
                   case player:lookup_info(GiftFId, [?pd_name, ?pd_level, ?pd_career]) of
                       [PName, PLev, PCareer] when is_binary(PName), is_integer(PLev), is_integer(PCareer) ->
                           {GiftFId, PName, PLev, PCareer, to_cli_itemtps(TpL, [])};
                       _ -> {0, <<>>, 0, 0, []}
                   end
               end || {GiftFId, TpL} <- SGAL],
    CliRGAL = [begin
                   case player:lookup_info(GiftFId, [?pd_name, ?pd_level, ?pd_career]) of
                       [PName, PLev, PCareer] when is_binary(PName), is_integer(PLev), is_integer(PCareer) ->
                           {GiftFId, PName, PLev, PCareer, GiftQua};
                       _ -> {0, <<>>, 0, 0, 0}
                   end
               end || {GiftFId, GiftQua} <- RGAL],
    CliFAL = [begin
                  case player:lookup_info(FId, [?pd_name, ?pd_level, ?pd_career]) of
                      [PName, PLev, PCareer] when is_binary(PName), is_integer(PLev), is_integer(PCareer) ->
                          {FId, PName, PLev, PCareer};
                      _ -> {0, <<>>, 0, 0}
                  end
              end || FId <- FAL],

    #friend_private{send_flowers = SendFlowers} = lookup_fp(SelfId),
    FunMap = fun({MsgId, PlayerId, ItemBid, MsgBin}) ->
        [PlayerName, PlayerLevel, PlayerCareer] = player:lookup_info(PlayerId, [?pd_name, ?pd_level, ?pd_career]),
        {MsgId, PlayerId, PlayerName, PlayerLevel, PlayerCareer, ItemBid, MsgBin}
    end,
    ?player_send(friend_sproto:pkg_msg(?MSG_FRIEND_MSGS, {CliSGAL, CliRGAL, CliFAL, lists:map(FunMap, SendFlowers)})).

to_cli_itemtps([], Ret) -> lists:reverse(Ret);
to_cli_itemtps([Tp | TpL], Ret) ->
    ItemBid = element(1, Tp),
    ItemCount = element(2, Tp),
    to_cli_itemtps(TpL, [{ItemBid, ItemCount} | Ret]).




%% 抢红包
rob_gift(Id) ->
    SelfId = get(?pd_id),
    #friend_common{open_rob = POpenRob
        , gift_qua = GiftQua
    } = lookup_fc(Id),
    SenceId = scene_mng:lookup_player_scene_id_if_online(Id),
    IsOnline = ?if_else(SenceId =:= offline, ?FALSE, ?TRUE),
    if
        IsOnline =:= ?FALSE -> {error, is_offline};
        POpenRob =:= ?FALSE -> {error, not_open_rob};
        SelfId =:= Id -> {error, cant_self};
        ?true ->
            case friend_gift_svr:rob_gift(Id, SelfId, GiftQua) of
                {ok, PrizeItemTp} ->
                    game_res:try_give_ex(PrizeItemTp, ?S_MAIL_FRIEND_GIFT, ?FLOW_REASON_FRIEND_GIFT),
                    change_info(?TRUE),
                    send_my_info(),
                    world:send_to_player_if_online(Id, ?mod_msg(friend_mng, {rob_gift, SelfId, GiftQua})),
                    ok;
                {error, Err} -> {error, Err}
            end
    end.



%% 申请索取红包
ask_for_gift_apply(Id) ->
    SenceId = scene_mng:lookup_player_scene_id_if_online(Id),
    IsOnline = ?if_else(SenceId =:= offline, ?FALSE, ?TRUE),

    #friend_common{gift_qua = GiftQua} = lookup_fc(Id),
    SelfId = get(?pd_id),
    if
        Id =:= SelfId -> {error, cant_self};
        IsOnline =:= ?FALSE -> {error, is_offline};
        ?true ->
            case friend_gift_svr:ask_for_gift_apply(SelfId, Id) of
                {ok, DelIdsTp} ->
                    Name = get(?pd_name),
                    Lev = get(?pd_level),
                    Career = get(?pd_career),
                    world:send_to_player(Id, ?mod_msg(friend_mng, {ask_for_gift_apply, SelfId, Name, Lev, Career, GiftQua, DelIdsTp})),
                    ?player_send(friend_sproto:pkg_msg(?MSG_FRIEND_ADD_GIFT_APPLY, {?T_ADD_REQ_APPLY, Id})),
                    ok;
                {error, Err} -> {error, Err}
            end
    end.
%% 回复申请索取红包
rep_ask_for_gift_apply(PlayerId, IsAgree) ->
    SelfId = get(?pd_id),
    %% TODO:是否加入离线判断，需要和策划沟通
    send_del_apply({[], [PlayerId], []}),
    case friend_gift_svr:rep_ask_for_gift_apply(SelfId, PlayerId, IsAgree) of
        {ok, PrizeTpL, GiftQua} when is_list(PrizeTpL) ->
            world:send_to_player(PlayerId, ?mod_msg(friend_mng, {rep_ask_for_gift_apply, PrizeTpL})),
            FP = lookup_fp(SelfId),
            NFP = friend:add_gift_score(FP, GiftQua, PlayerId),
            update_fp(NFP),
            %world:send_to_player_if_online(PlayerId,
            %    ?to_client_msg(friend_sproto:pkg_msg(?MSG_FRIEND_ADD_GIFT_APPLY, {?T_SUB_REQ_APPLY, SelfId}))
            %),

            send_my_info(),
            change_info(?TRUE),
            ok;
        {ok, _PrizeId, _} ->
            ?debug_log_friend("----------~w", [_PrizeId]),
            world:send_to_player_if_online(PlayerId,
                ?to_client_msg(friend_sproto:pkg_msg(?MSG_FRIEND_ADD_GIFT_APPLY, {?T_SUB_REQ_APPLY, SelfId}))
            ),
            change_info(?TRUE),
            ok;
        {error, Err} ->
            {error, Err}
    end.

%% 赠送红包申请
send_gift_apply(Id) ->
    SelfId = get(?pd_id),
    SenceId = scene_mng:lookup_player_scene_id_if_online(Id),
%%     IsOnline = ?if_else(SenceId =:= offline, ?FALSE, ?TRUE),

    IsOnline =
        case friend:is_robot_list(Id) of
            true -> ?TRUE;
            _ -> ?if_else(SenceId =:= offline, ?FALSE, ?TRUE)
        end,
    if
        IsOnline =:= ?FALSE -> {error, is_offline};
        Id =:= SelfId -> {error, cant_slef};
        ?true ->
            case friend_gift_svr:send_gift_apply(SelfId, Id) of
                {ok, GiftQua} ->
                    FP = lookup_fp(SelfId),
                    NFP = friend:add_gift_score(FP, GiftQua, Id),
                    update_fp(NFP),
                    change_info(?TRUE),
                    send_my_info(),
                    ok;
                {error, Err} -> {error, Err}
            end
    end.
%% 接受红包赠送
rep_send_gift_apply(Id) ->
    SelfId = get(?pd_id),
    send_del_apply({[Id], [], []}),
    case friend_gift_svr:rep_send_gift_apply(SelfId, Id) of
        {ok, ItemTpL} ->
            game_res:try_give_ex(ItemTpL, ?S_MAIL_FRIEND_GIFT, ?FLOW_REASON_FRIEND_GIFT),
            ok;
        {error, Err} ->
            {error, Err}
    end.


send_del_apply(_Del = {DelSIdL, DelRGiftIdL, DelFIdL}) ->
    %?player_send(_Pkg = friend_sproto:pkg_msg(?MSG_FRIEND_DEL_MSG, {DelSIdL, DelRGiftIdL, DelFIdL})),
    _Pkg = friend_sproto:pkg_msg(?MSG_FRIEND_DEL_MSG, {DelSIdL, DelRGiftIdL, DelFIdL}),
    ?player_send(_Pkg ).
   


send_del_apply2(_Del = {DelSIdL, DelRGiftIdL, DelFIdL}, PlayerId) ->
    Pkg = friend_sproto:pkg_msg(?MSG_FRIEND_DEL_MSG, {DelSIdL, DelRGiftIdL, DelFIdL}),
    world:send_to_player_if_online(PlayerId,?to_client_msg(Pkg)).

add_robot_friend(PlayerId) ->
    SelfId = get(?pd_id),
    #{max := Max, vip_max := VipMax} = misc_cfg:get_friend_cfg(),
    FP = #friend_private{friend_ids = FIdL} = lookup_fp(SelfId),
    IsVip = api:player_is_Vip(),
    FLen = length(FIdL),

    if
        IsVip, FLen >= VipMax ->
            ?player_send(friend_sproto:pkg_msg(?MSG_FRIEND_APPLY, {?REPLY_MSG_FRIEND_APPLY_2}));
        IsVip =:= ?false, FLen >= Max ->
            ?player_send(friend_sproto:pkg_msg(?MSG_FRIEND_APPLY, {?REPLY_MSG_FRIEND_APPLY_2}));
        true ->
            add_robot_friend(FP, PlayerId)
    end.

add_robot_friend(FP = #friend_private{id = _Id, friend_ids = FIdL}, PlayerId) ->
    achievement_mng:do_ac(?shejiaodaren),
    update_fp(FP#friend_private{friend_ids = [{PlayerId, 0} | FIdL]}),
    Pkg = get_friend_info_def(PlayerId, 0),
    ?player_send(friend_sproto:pkg_msg(?MSG_FRIEND_CHANGE, {?T_ADD_FRIEND, Pkg})).

