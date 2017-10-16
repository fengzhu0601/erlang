-ifndef(COM_PROTO_HRL_).

-define(COM_PROTO_HRL_, 1).
%% @doc 协议号定义

%% 主协议
                                                %-define(CLIENT_2_LOGIC_CMD , 16#2). %%client <-> logic
                                                %-define(CLIENT_2_GATE_CMD  , 16#3). %%client <-> gate
                                                %-define(VERIFY_2_LOGIC_CMD , 16#4). %%verify <-> logic 平台购买服务器
                                                %-define(PUSH_2_LOGIC_CMD   , 16#5). %%push <-> logic
                                                %-define(LOGIC_2_CENTER_CMD , 16#6). %%logic <-> mngCenter中心管理器
                                                %-define(PUSH_2_CENTER_CMD  , 16#7). %%push <-> mngCenter
                                                %-define(ROBOT_2_LOGIC_CMD  , 16#8). %%robot <-> Logic

%%%错误码,内部使用对应数字的负数
%%%{{{
                                                %-define(ERR_NO_ERROR                 , 16#0000). %%没有错误
%%%Logic server
                                                %-define(ERR_PLAYER_NAME_USED         , 16#0001). %%玩家用户名以注册
                                                %-define(ERR_NO_PLAYER                , 16#0002). %%玩家不存在
                                                %-define(ERR_PLAYER_IS_ONLINE         , 16#0003). %%玩家以在线
                                                %-define(ERR_PLAYER_PASSWORD_INCORRECT, 16#0004). %%玩家密码不正确

%%%money
                                                %-define(ERR_MONEY_NOT_ENOUGH         , 16#0005). %%钱不够
                                                %-define(ERR_DIRTY_WORD               , 16#0006). %%有敏感词

%%%table
                                                %-define(ERR_TABLE_OTHER_USER_SIT     , 16#0010). %%指定的位置已经被别人占有/坐下失败
                                                %-define(ERR_TABLE_PLAYER_OP_TIMEOUT  , 16#0011). %%玩家操作超时
                                                %-define(ERR_TABLE_PLAYER_JOIN_FAILED , 16#0012). %%玩家加入牌桌失败
                                                %-define(ERR_TABLE_SEAT_IS_FULL       , 16#0013). %%牌桌座位都有人坐下了


%%%item
                                                %-define(ERR_ITEM_NO_ITEM             , 16#0040). %%没有指定物品
                                                %-define(ERR_ITEM_NOT_ENOUGH          , 16#0041). %%没有足够的物品
                                                %-define(ERR_ITEM_NOT_USED            , 16#0042). %%不能使用
                                                %-define(ERR_ITEM_NOT_BUY             , 16#0043). %%不能购买(非卖品)
                                                %-define(ERR_ITEM_PRESENT_FAILED      , 16#0044). %%赠送物品失败
                                                %-define(ERR_ITEM_ADD_COUNT_TOOBIG    , 16#0045). %%超过物品携带数
                                                %-define(ERR_ITEM_PRSENT_ITEM_FULL    , 16#0046). %%赠送的物品超过对方携带上线
                                                %-define(ERR_ITEM_CAN_NOT_EQUIP       , 16#0047). %%不能装备
                                                %-define(ERR_ITEM_NO_EQUIP            , 16#0048). %%没有装备物品

%%%friend
                                                %-define(ERR_CANNOT_ADD_FRIEND_SELF   , 16#0070). %%不能添加自己为好友
                                                %-define(ERR_ALREADY_SEND_FRIEND_REQ  , 16#0071). %%已经发送好友请求
                                                %-define(ERR_ALREADY_BE_FRIEND        , 16#0072). %%已经是你的好友
                                                %-define(ERR_INVALID_FRIEND_REQUEST   , 16#0073). %%无效的好友申请处理

%%%gate server
                                                %-define(ERR_GATE_NO_LOGIC_SERVER     , 16#0200). %%找不到logic server
                                                %-define(ERR_GATE_CLIENT_VERSION_LOW  , 16#0201). %%客户端版本太低

%%%}}}

%%% CLIENT_2_GATE_CMD 下的子协议号定义
                                                %-define(CMD_CG_ROBOT_Get_SpecLogicInfo, 16#21).

%%% VERIFY_2_LOGIC_CMD 下的子协议号定义 {{{
                                                %-define(CMD_VL_Register_VerifyReq , 16#0001). %%注册Verify 服务器请求
                                                %-define(CMD_VL_Register_VerifyRsp , 16#0002). %%注册Verify 服务器请求回复
                                                %-define(CMD_VL_VerifyReq, 16#0003). %%购买东西请求
                                                %-define(CMD_VL_VerifyRsp, 16#0004). %%购买东西请求回复


%%% }}}
%%%
%%% CLIENT_2_LOGIN_CMD 下的子协议号定义
%%% {{{
                                                %-define(CMD_CL_Client_GetUserID    , 16#0002). %% 玩家登录获得userId
                                                %-define(CMD_CL_Client_Login        , 16#0003). %% 玩家登录请求%% 玩家初始化完毕
                                                %-define(CMD_CL_Client_Register     , 16#0004). %% 玩家注册 (第一次进入游戏)
                                                %-define(CMD_CL_Client_JoinTable    , 16#0005). %% 玩家进入牌局
                                                %-define(CMD_CL_Client_LeaveTable   , 16#0006). %% 玩家离开牌局;
                                                %-define(CMD_CL_Client_SitDown      , 16#0007). %% 玩家坐下等待开始
                                                %-define(CMD_CL_Client_GetTableInfo , 16#0008). %% 玩家得到牌桌基本信息
                                                %-define(CMD_CL_Client_StandUp      , 16#0009). %% 玩家站起
                                                %-define(CMD_CL_Client_Offline      , 16#000A). %% 玩家下线

                                                %-define(CMD_CL_Client_ModifyInfo   , 16#000B). %% 改变玩家属性
                                                %-define(CMD_CL_Client_GetUserInfo  , 16#000C). %% 得到玩家属性
                                                %-define(CMD_CL_Client_GMCommand    , 16#000D). %% GM命令
                                                %-define(CMD_CL_Client_InviteFriend , 16#000E). %% 邀请好友加入游戏
                                                %-define(CMD_CL_Client_GetTiger     , 16#000F). %% 获得老虎机的五张牌及牌型

                                                %-define(CMD_CL_Client_Heartbeat    , 16#0010). %% 心跳协议

                                                %-define(CMD_CL_Client_ChatSend     , 16#0030). %% 玩家发送聊天
                                                %-define(CMD_CL_Client_ChatRecv     , 16#0031). %% 玩家接收聊天

                                                %-define(CMD_CL_Client_GetNoEmptyTable ,16#0042). %%得到一个有人的桌子

%%%德州扑克开始
                                                %-define(CMD_CL_Client_PlayerOption , 16#00FF). %%玩家操作
                                                %-define(CMD_CL_Client_WaitOption   , 16#0100). %%等待玩家操作
                                                %-define(CMD_CL_Client_GetHandCards , 16#0101). %%得到手牌
                                                %-define(CMD_CL_Client_NewStart     , 16#0102). %%新一轮开始
                                                %-define(CMD_CL_Client_FlopStart    , 16#0103). %%三张公牌
                                                %-define(CMD_CL_Client_TurnStart    , 16#0104). %%4张公牌
                                                %-define(CMD_CL_Client_RiverStart   , 16#0105). %%5张公牌
                                                %-define(CMD_CL_Client_WinMoney     , 16#0106). %%玩家赢得的筹码
                                                %-define(CMD_CL_Client_BankRollLess , 16#0107). %%玩家带的钱不够了，
                                                %-define(CMD_CL_Client_GiveHGMoney  , 16#0108). %%给和关消费
                                                %-define(CMD_CL_Client_GetLastResult, 16#0109). %%获取上一局的结果信息
                                                %-define(CMD_CL_Client_TableBaseBetChange, 16#010A). %%底注改变
                                                %-define(CMD_CL_Client_InteractiveOp , 16#010B). %%交互物品通知
%%%-define(CMD_CL_Client_UpdatePlayNumber , 16#010C). %%玩牌次数更新

%%%单桌赛
                                                %-define(CMD_CL_Client_GetGameOrder  , 16#0130). %%单桌赛 得到比赛明次
                                                %-define(CMD_CL_Client_SNGGameOver      , 16#0131). %%单桌赛 比赛结束

%%%物品
                                                %-define(CMD_CL_Client_BuyItem         , 16#01A0). %%玩家买物品
                                                %-define(CMD_CL_Client_AddItem         , 16#01A2). %%玩家得到物品
                                                %-define(CMD_CL_Client_PresentItem     , 16#01A3). %%玩家送物品
                                                %-define(CMD_CL_Client_GetUserItemInfo , 16#01A4). %%玩家得到所有物品信息
                                                %-define(CMD_CL_Client_DelItem         , 16#01A5). %%删除玩家物品
%%%-define(CMD_CL_Client_LoadAchieve   , 16#01A6). %%得到成就物品
                                                %-define(CMD_CL_Client_UseItem         , 16#01A7). %%使用物品
                                                %-define(CMD_CL_Client_EquipItem       , 16#01A8). %%装备物品
                                                %-define(CMD_CL_Client_UnequipItem     , 16#01A9). %%卸载装备
                                                %-define(CMD_CL_Client_PlanAppleReq    , 16#01AA). %%苹果平台支付

%%%成就
%%%-define(CMD_CL_Client_GetAchieve  , 16#0200). %%玩家获得成就

%%%好友系统
                                                %-define(CMD_CL_Client_AddFriendShip             , 16#0201). %%请求加为好友
                                                %-define(CMD_CL_Client_ConfirmFriendApplication  , 16#0202). %%确认加为好友信息
                                                %-define(CMD_CL_Client_RejectFriendApplication   , 16#0203). %%拒绝加为好友信息
                                                %-define(CMD_CL_Client_GetFriendApplication      , 16#0204). %%获取加为好友申请列表
                                                %-define(CMD_CL_Client_GetFriendList             , 16#0205). %%获取好友列表
                                                %-define(CMD_CL_Client_Tell_Friend_Handle_Result , 16#0206). %%通知好友请求处理结果
                                                %-define(CMD_CL_Client_AskIsFriend               , 16#0207). %%查询是否是好友
                                                %-define(CMD_CL_Client_TraceFriendRoom           , 16#0208). %%跟踪好友房间
                                                %-define(CMD_CL_Client_SendFriendChip            , 16#0209). %%赠送好友

                                                %-define(CMD_CL_Client_Mail_Send                 , 16#0210). %%发送邮件
                                                %-define(CMD_CL_Client_Mail_Recive               , 16#0211). %%接收邮件
                                                %-define(CMD_CL_Client_Mail_Delete               , 16#0211). %%

%%%全局排行
                                                %-define(CMD_CL_Client_GlobalRank_GetMoneyRankTable , 16#0230). %%得到全局筹码排行
                                                %-define(CMD_CL_Client_GlobalRank_GetPlayerMoneyRank, 16#0231). %%得到指定玩家的全局筹码排行

%%%推送
                                                %-define(CMD_CL_Client_SetPushToken        , 16#0240). %%设置推送Token

%%% 机器人专属
                                                %-define(CMD_CL_Client_GetBestPattern, 16#0190). %%得到最佳牌型

%%% }}}

%%% ROBOT_2_LOGIC_CMD 下的子协议号定义 {{{
                                                %-define(CMD_RL_Register_Logic, 16#1).
                                                %-define(CMD_RL_RobotSitdown  , 16#2).

%%%}}}

-endif.
%%set vim: foldmethod=marker
