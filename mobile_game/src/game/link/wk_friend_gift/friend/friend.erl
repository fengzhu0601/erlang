%%%-------------------------------------------------------------------
%%% @author yujian
%%% @doc 好友辅助函数模块
%%%-------------------------------------------------------------------
-module(friend).
-include("inc.hrl").
-include("friend.hrl").
-include("friend_struct.hrl").
-include("rank.hrl").
-include("player.hrl").
-include("virtual_db.hrl").
-include("player_data_db.hrl").



-export([
    add_score/2
    , add_gift_score/3
    , broadcast/3
    , push_robot_list/1
    , is_robot_list/1
]).

%% @doc 赠送花朵，加通用好友度，以及双方的好友度
add_score(?give_flowers_get_score, {FP, PlayerId, ItemScore}) ->
    #{day_score_max := DayScoreMax} = misc_cfg:get_friend_cfg(),
    score_update(FP, DayScoreMax, PlayerId, ItemScore, ?TRUE);

%% @todo 私聊加友好度功能没有完成 1.判断是否已满 2.判断是否可以添加 3.
add_score(?chat_get_score, _SelfId) ->
    ok.
%%     FP= #friend_private{day_chat_score = DScore, score = Score} = friend_mng:lookup_fp(SelfId),
%%     #{day_chat_score_max := ChatScoreMax}=misc_cfg:get_friend_cfg(),
%%     ok.
%%     case score_update(FP, ChatScoreMax, SelfId, ItemScore) of
%%         FP -> ignore;
%%         {NewFP, AllScore} ->
%%
%%     end,
%%
%%     if
%%         DScore >= ChatScoreMax -> ignore;
%%         ChatC + 1 >= ?CHAT_PER_SCORE->
%%             put(?pd_friend_chat_count, ChatC+1),
%%             event_eng:post( ?ev_friend_score, {?ev_friend_score, 0}, 1 ),
%%             update_fp(FP#friend_private{day_chat_score= DScore+1, score = Score+1});
%%         ?true -> put(?pd_friend_chat_count, ChatC+1)
%%     end.

%% 赠送礼包只给自己加通用友好度
add_gift_score(FP, GiftQua, PlayerId) ->
    #{day_score_max := DayScoreMax, gift_per_score := GiftScoreL} = misc_cfg:get_friend_cfg(),
    case lists:keyfind(GiftQua, 1, GiftScoreL) of
        {_, GScore} ->
            {NewFP, _} = score_update(FP, DayScoreMax, PlayerId, GScore, ?FALSE),
            NewFP;
        _ -> FP
    end.

score_update(FP = #friend_private{day_gift_score = ToDayScore, score = Score, friend_ids = FriendIds}, ToDayMaxScore, ToPlayerId, AddScore, IsCommentScore) ->
    NewAddScore = 
    if
      ToDayScore >= 
        ToDayMaxScore -> 0;
      ToDayScore + AddScore >= 
        ToDayMaxScore -> ToDayMaxScore - ToDayScore;
      ?true -> 
        AddScore
    end,
    case NewAddScore of
        0 -> 
          {FP, 0};
        NewAddScore ->
          {NewFriendIds, AllScore} = 
          case IsCommentScore of
            ?TRUE ->
                case lists:keyfind(ToPlayerId, 1, FriendIds) of
                    false ->
                        {FriendIds, 0};
                    {PlayerId, PlayerScore} ->
                        {lists:keyreplace(PlayerId, 1, FriendIds, {PlayerId, PlayerScore + NewAddScore}),PlayerScore + NewAddScore}
                end;
            ?FALSE -> 
                {FriendIds, 0}
         end,
        event_eng:post(?ev_friend_score, {?ev_friend_score, 0}, NewAddScore),
        NewScore = Score + NewAddScore,
        ranking_lib:update(?ranking_meili, get(?pd_id), NewScore),
        {FP#friend_private{
              day_gift_score = ToDayScore + NewAddScore,
              score = NewScore,
              friend_ids = NewFriendIds},
              AllScore}
    end.

broadcast(MyPlayerName, ToPlayerName, MsgBin) ->
    chat_mng:chat_sys_broadcast(?Language(7, {MyPlayerName, ToPlayerName, MsgBin})).

%% 随机推送机器人列表Num推送机器人的个数
push_robot_list(Num) ->
    RobotIdList = robot_new_server:get_robot_id_list(),
    RobotInfos1 = lists:foldl(
        fun(Id, Acc) ->
                #{platform_id := _PlatformId, id := ServerId} = global_data:get_server_info(),
                PlayerId = tool:make_player_id(5000, ServerId, Id),
                case player:lookup_info(PlayerId, [?pd_name, ?pd_level, ?pd_career, ?pd_combat_power]) of
                    [Name, Level, Career, Power] ->
                        [{PlayerId, Name, Level, Career, Power, 0, 0, 0, 0, 1} | Acc]; %% 元组中最后一项写为1，是保证前端显示机器人时候为在线状态
                    _ ->
                        Acc
                end
        end,
        [],
        RobotIdList
    ),
    RobotInfos = case length(RobotInfos1) > Num of
        true -> com_util:rand_more(RobotInfos1, Num);
        _ -> RobotInfos1
    end,
    my_ets:set(robot_friend_list, RobotInfos),
    RobotInfos.

is_robot_list(PlayerId) ->
    RobotList = my_ets:get(robot_friend_list, []),
    case lists:keyfind(PlayerId, 1, RobotList) of
        false -> false;
        _ -> true
    end.
