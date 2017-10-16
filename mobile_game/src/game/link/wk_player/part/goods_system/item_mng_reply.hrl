%% 物品模块回复码定义
%%----------------------------------------------------
%% MSG_ITEM_BUCKET_DEL 删除物品
-define(REPLY_MSG_ITEM_BUCKET_DEL_OK, 0).  %% 删除成功
%-define(REPLY_MSG_ITEM_BUCKET_DEL_1,    1).  %% 未找到所要删除的物品
-define(REPLY_MSG_ITEM_BUCKET_DEL_1, 1).  %% 该物品不可丢弃
-define(REPLY_MSG_ITEM_BUCKET_DEL_255, 255).  %% 删除失败，请重试。重试失败请联系GM
%%----------------------------------------------------
%% MSG_ITEM_BUCKET_SORT 整理背包
-define(REPLY_MSG_ITEM_BUCKET_SORT_OK, 0).  %% 整理成功
-define(REPLY_MSG_ITEM_BUCKET_SORT_255, 255).  %% 整理失败，请重试。重试失败请联系GM

%%----------------------------------------------------
%% MSG_ITEM_BUCKET_MOVE 移动物品（同一背包内
-define(REPLY_MSG_ITEM_BUCKET_MOVE_OK, 0).  %% 移动成功
-define(REPLY_MSG_ITEM_BUCKET_MOVE_1, 1).  %% 新位置未解锁
-define(REPLY_MSG_ITEM_BUCKET_MOVE_2, 2).  %% 位置未发生变化，无需移动
-define(REPLY_MSG_ITEM_BUCKET_MOVE_255, 255).  %% 移动失败，请重试。重试失败请联系GM

%%----------------------------------------------------
%% MSG_ITEM_BUCKET_SPLIT 拆分物品
-define(REPLY_MSG_ITEM_BUCKET_SPLIT_OK, 0).  %% 拆分成功
-define(REPLY_MSG_ITEM_BUCKET_SPLIT_1, 1).  %% 拆分数量大于实际数量
-define(REPLY_MSG_ITEM_BUCKET_SPLIT_255, 255).  %% 拆分失败，请重试。重试失败请联系GM
%%----------------------------------------------------
%% MSG_ITEM_BUCKET_MOVE 移动物品（不同背包之间
-define(REPLY_MSG_ITEM_BUCKET_MOVE_CROSS_OK, 0).  %% 移动成功
-define(REPLY_MSG_ITEM_BUCKET_MOVE_CROSS_1, 1).  %% 新位置不可用
-define(REPLY_MSG_ITEM_BUCKET_MOVE_CROSS_2, 2).  %% 该物品不能存入仓库
-define(REPLY_MSG_ITEM_BUCKET_MOVE_CROSS_255, 255).  %% 移动失败，请重试。重试失败请联系GM

%%----------------------------------------------------
%% MSG_ITEM_BUCKET_UNLOCK 背包解锁
-define(REPLY_MSG_ITEM_BUCKET_UNLOCK_OK, 0).  %% 解锁成功
-define(REPLY_MSG_ITEM_BUCKET_UNLOCK_1, 1).  %% 已经解锁过了，无需解锁
-define(REPLY_MSG_ITEM_BUCKET_UNLOCK_2, 2).  %% 解锁需要一步一步来哟
-define(REPLY_MSG_ITEM_BUCKET_UNLOCK_3, 3).  %% 钻石不足
-define(REPLY_MSG_ITEM_BUCKET_UNLOCK_4, 4).  %% 正在解锁中
-define(REPLY_MSG_ITEM_BUCKET_UNLOCK_255, 255).  %% 解锁失败，请重试。重试失败请联系GM

%%----------------------------------------------------
%% MSG_ITEM_BUCKET_MERGE    
-define(REPLY_MSG_ITEM_BUCKET_MERGE_OK, 0).  %% 合并物品成功
-define(REPLY_MSG_ITEM_BUCKET_MERGE_1, 1).  %% 被合并的物品数量超过最大对叠数
-define(REPLY_MSG_ITEM_BUCKET_MERGE_2, 2).  %% 不同的物品无法合并
-define(REPLY_MSG_ITEM_BUCKET_MERGE_255, 255).  %% 合并失败，请重试。重试失败请联系GM

%%----------------------------------------------------
%% MSG_ITEM_USE
-define(REPLY_MSG_ITEM_USE_OK, 0).  %% 使用物品成功
-define(REPLY_MSG_ITEM_USE_1, 1).  %% 物品不能使用
-define(REPLY_MSG_ITEM_USE_2, 2).  %% 物品没有找到
-define(REPLY_MSG_ITEM_USE_3, 3).  %% 物品数量不足
-define(REPLY_MSG_ITEM_USE_4, 4).  %% 好友礼包品质与所使用的物品不同
-define(REPLY_MSG_ITEM_USE_5, 5).  %% 孵化宠物蛋消耗不足
-define(REPLY_MSG_ITEM_USE_6, 6).  %% 已拥有该坐骑
-define(REPLY_MSG_ITEM_USE_255, 255).%% 使用异常
%%----------------------------------------------------
%% MSG_ITEM_UNBIND
-define(REPLY_MSG_ITEM_UNBIND_OK, 0).	%% 解绑成功
-define(REPLY_MSG_ITEM_UNBIND_1, 1).	%% 没有足够的材料
-define(REPLY_MSG_ITEM_UNBIND_255, 255).	%% 解绑失败
%%----------------------------------------------------
%% 物品合成回复码
-define(REPLY_MSG_GOODS_COMPOUND_OK, 0).      %% 物品合成成功
-define(REPLY_MSG_GOODS_COMPOUND_1, 1).       %% 消耗不足
-define(REPLY_MSG_GOODS_COMPOUND_2, 2).       %% 背包剩余空间不足
-define(REPLY_MSG_GOODS_COMPOUND_255, 255).   %% 其他错误



%%----------------------------------------------------
%%----------------------------------------------------
%%----------------------------------------------------
%%----------------------------------------------------
%%----------------------------------------------------




