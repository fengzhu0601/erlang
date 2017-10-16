-define(player_friend_private, player_friend_private).    %% 玩家好友私人表

-define(player_friend_common, player_friend_common).   %% 玩家好友公共表


%% 好友系统聊天代码
-define(FRIEND_CHAT_SYS_TEXT_1, <<"对方已经通过您的好友申请,常联系可以增加友好值! "/utf8>>).  %% 对方已经通过您的好友申请，常联系可以增加友好值！

-define(pd_friend_chat_count, pd_friend_chat_count).   %% 好友聊天条数记录进程字典（用于好友度

-define(CHAT_PER_SCORE, 5). %% 每五条得一分

-define(DEF_GIFT_TYPES, [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]).  %% 默认礼物类型（杂项表里面配置第一个物品的id，其他累加

%% 好友礼包品质
-define(GIFT_BLUE, 0).  %蓝
-define(GIFT_PUR, 1).  %紫
-define(GIFT_ORG, 2).  %橙

-define(GIFT_QUAS,
    [
        ?GIFT_BLUE
        , ?GIFT_PUR
        , ?GIFT_ORG
    ]
).




%% 申请好友状态
-define(FRIEND_UNAPPLY, 1). %% 未申请好友
-define(FRIEND_APPLYED, 2). %% 已经是好友
-define(FRIEND_APPLYING, 3). %% 正在申请中

-define(T_ADD_FRIEND, 1).  %% 添加好友信息
-define(T_UPDATE_FRIEND, 2).  %% 更新好友信息


-define(T_SEND_GIFT_APPLY, 1).  %% 添加赠送礼包玩家id
-define(T_RECV_GIFT_APPLY, 2).  %% 添加接受礼包玩家id
-define(T_ADD_FRIEND_APPLY, 3).  %% 添加好友申请id
-define(T_SUB_FRIEND_APPLY, 4).  %% 删除好友申请id
-define(T_ADD_REQ_APPLY, 5).  %% 添加索取红包申请id
-define(T_SUB_REQ_APPLY, 6).  %% 删除索取红包申请id



-define(give_flowers_get_score, give_flowers_get_score). %获取好友度的类型
-define(chat_get_score, chat_get_score).%获取好友度的类型