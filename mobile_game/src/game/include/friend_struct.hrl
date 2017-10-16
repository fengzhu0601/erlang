%% 好友结构
-record(friend_private, {
    id = 0  %% 玩家id
    , ver = 0  %% 结构版本号
    , friend_ids = [] %% 好友id列表, [{PlayerId::好友id, score::友好度}]
    , day_chat_score = 0  %% 当天通过聊天获得的好友度，用于限制聊天好友度的获得
    , day_gift_score = 0  %% 当天通过送红包获得的好友度，用于限制送红包好友度的获得
    , score = 0  %% 友好度
    , send_flowers = [] %% 别人送花的历史记录
    , msg_id = 0  %% 别人送花的历史记录的id用于删除
}
).


%% 好友礼包结构
-record(friend_common, {
    id
    , ver = 0  %% 结构版本号
    , open_rob = 0  %% 开启被抢红包模式 0不开启 1开启
    , gift_qua = 0  %% 红包品质 0蓝 1紫 2橙
    , send_count = 0  %% 送出红包数量
    , recv_count = 0  %% 收到红包数量
    , send_gift_applys = []  %% 赠送礼物申请信息  [{Id, ItemTpL}]
    , req_gift_applys = []  %% 索取礼物申请信息  [{Id, Qua}]
    , recv_friend_applys = []  %% 好友申请信息      [Id]

    , send_gift_type = [] %% 等待送出去的礼包类型，为了不重复做的
    , send_player_ids = [] %% 已经送给的玩家id列表，不能重复送同一人礼包
    , recv_player_ids = [] %% 已经收到的玩家id列表，不能重复收同一人礼包
    , send_friend_ids = [] %% 已经申请玩家好友id列表，为了不能重复申请
    , send_req_ids = [] %% 已经申请索取礼包id列表,为了不能重复申请索取
}
).


