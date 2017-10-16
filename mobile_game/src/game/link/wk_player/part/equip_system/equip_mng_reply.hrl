%% 装备模块回复码定义
%%----------------------------------------------------
%% ?MSG_EQUIP_DRESS 穿着装备
-define(REPLY_MSG_EQUIP_DRESS_OK, 0).   %% 穿装备成功
-define(REPLY_MSG_EQUIP_DRESS_1, 1).   %% 装备未鉴定，不能穿着
-define(REPLY_MSG_EQUIP_DRESS_2, 2).   %% 装备穿着失败
-define(REPLY_MSG_EQUIP_DRESS_3, 3).   %% 所要穿着的类型不符
-define(REPLY_MSG_EQUIP_DRESS_255, 255). %% 穿着失败，请重试。重试失败请联系GM

%%----------------------------------------------------
%% ?MSG_EQUIP_UNDRESS 脱装备
-define(REPLY_MSG_EQUIP_UNDRESS_OK, 0).   %% 脱装备成功
-define(REPLY_MSG_EQUIP_UNDRESS_1, 1).   %% 背包满，无法脱装备
-define(REPLY_MSG_EQUIP_UNDRESS_2, 2).   %% 无法找到要脱的装备
-define(REPLY_MSG_EQUIP_UNDRESS_255, 255). %% 脱装备失败，请重试。重试失败请联系GM

%%----------------------------------------------------
%% ?MSG_EQUIP_QIANG_HUA 强化装备
-define(REPLY_MSG_EQUIP_QIANG_HUA_OK, 0).    %% 强化装备成功
-define(REPLY_MSG_EQUIP_QIANG_HUA_1, 1).    %% 未鉴定
-define(REPLY_MSG_EQUIP_QIANG_HUA_2, 2).    %% 强化装备达到最大等级
-define(REPLY_MSG_EQUIP_QIANG_HUA_3, 3).    %% 装备强化失败，花费不足
-define(REPLY_MSG_EQUIP_QIANG_HUA_4, 4).    %% 装备不可强化
-define(REPLY_MSG_EQUIP_QIANG_HUA_255, 255). %% 强化装备失败，请重试。重试失败请联系GM。

%%----------------------------------------------------
%% ?MSG_EQUIP_HE_CHENG 合成装备
-define(REPLY_MSG_EQUIP_HE_CHENG_OK, 0).   %% 合成装备成功
-define(REPLY_MSG_EQUIP_HE_CHENG_1, 1).   %% 合成装备花费不足
-define(REPLY_MSG_EQUIP_HE_CHENG_2, 2).   %% 非法操作，合成装备失败
-define(REPLY_MSG_EQUIP_HE_CHENG_3, 3).   %% 装备不可合成
-define(REPLY_MSG_EQUIP_HE_CHENG_4, 4).   %% 合成时锁定的属性条数超过玩家最大允许条数
-define(REPLY_MSG_EQUIP_HE_CHENG_255, 255).   %% 合成装备失败，请重试。重试失败请联系GM。
%%----------------------------------------------------
%% ?MSG_EQUIP_JIANDING 鉴定装备
-define(REPLY_MSG_EQUIP_JIANDING_OK, 0).   %% 鉴定装备成功
-define(REPLY_MSG_EQUIP_JIANDING_1, 1).   %% 鉴定装备失败，钻石不足
-define(REPLY_MSG_EQUIP_JIANDING_2, 2).   %% 鉴定装备失败，花费不足
-define(REPLY_MSG_EQUIP_JIANDING_3, 3).   %% 装备已鉴定，无需再鉴定
-define(REPLY_MSG_EQUIP_JIANDING_255, 255).   %% 鉴定装备失败，请重试。重试失败请联系GM。


%%----------------------------------------------------
%% ?MSG_EQUIP_EMBED_GEM 装备镶嵌宝石
-define(REPLY_MSG_EQUIP_EMBED_GEM_OK, 0).   %% 镶嵌宝石成功
-define(REPLY_MSG_EQUIP_EMBED_GEM_1, 1).   %% 镶嵌宝石失败，钻石不足
-define(REPLY_MSG_EQUIP_EMBED_GEM_2, 2).   %% 镶嵌宝石失败，宝石孔位不足
-define(REPLY_MSG_EQUIP_EMBED_GEM_3, 3).   %% 镶嵌宝石失败，花费不足
-define(REPLY_MSG_EQUIP_EMBED_GEM_4, 4).   %% 镶嵌宝石失败,不能镶嵌同类型宝石
-define(REPLY_MSG_EQUIP_EMBED_GEM_255, 255).   %% 镶嵌宝石失败，请重试。重试失败，请联系GM


%%----------------------------------------------------
%% ?MSG_EQUIP_UNEMBED_GEM 装备摘除宝石
-define(REPLY_MSG_EQUIP_UNEMBED_GEM_OK, 0).   %% 摘除宝石成功
-define(REPLY_MSG_EQUIP_UNEMBED_GEM_1, 1).   %% 摘除宝石失败，背包已满
-define(REPLY_MSG_EQUIP_UNEMBED_GEM_2, 2).   %% 摘除宝石失败，孔位没宝石
-define(REPLY_MSG_EQUIP_UNEMBED_GEM_3, 3).   %% 摘除宝石失败，孔位还没打孔
-define(REPLY_MSG_EQUIP_UNEMBED_GEM_255, 255).   %% 摘除宝石失败，请重试。重试失败，请联系GM




%%----------------------------------------------------
%% ?MSG_EQUIP_JI_CHENG 继承装备
-define(REPLY_MSG_EQUIP_JI_CHENG_OK, 0).   %% 继承装备成功
-define(REPLY_MSG_EQUIP_JI_CHENG_1, 1).   %% 继承装备失败，背包已满
-define(REPLY_MSG_EQUIP_JI_CHENG_2, 2).   %% 继承装备失败，钻石不足
-define(REPLY_MSG_EQUIP_JI_CHENG_3, 3).   %% 继承装备失败，花费不足
-define(REPLY_MSG_EQUIP_JI_CHENG_4, 4).   %% 继承装备失败，只能继承强化等级更高的装备哦
-define(REPLY_MSG_EQUIP_JI_CHENG_5, 5).   %% 继承装备失败，只能继承同一部位的装备哦
-define(REPLY_MSG_EQUIP_JI_CHENG_6, 6).   %% 继承装备失败，装备不可继承
-define(REPLY_MSG_EQUIP_JI_CHENG_255, 255).   %% 继承装备失败，请重试。重试失败，请联系GM。


%%----------------------------------------------------
%% ?MSG_EQUIP_UNEMBED_ALL_GEM 装备摘除宝石
-define(REPLY_MSG_EQUIP_UNEMBED_ALL_GEM_OK, 0).   %% 摘除宝石成功
-define(REPLY_MSG_EQUIP_UNEMBED_ALL_GEM_1, 1).   %% 摘除宝石失败，背包已满
-define(REPLY_MSG_EQUIP_UNEMBED_ALL_GEM_255, 255).   %% 摘除宝石失败，请重试。重试失败，请联系GM

%%-----------------------------------------------------
%% 装备打孔
-define(REPLY_MSG_EQUIP_SLOT_OK, 0).         %% 装备打孔成功
-define(REPLY_MSG_EQUIP_CANT_SLOT, 1).       %% 该物品不能打孔
-define(REPLY_MSG_EQUIP_MAX_SLOT, 2).        %% 已超过最大孔数
-define(REPLY_MSG_EQUIP_COST_NOT_ENOUGH, 3). %% 消耗的物品不足
-define(REPLY_MSG_EQUIP_SLOT_LITTLE_1, 4).   %% 要打的孔数量小于1
-define(REPLY_MSG_EQUIP_SLOT_PUNCH_TYPE_ERR, 5).   %% 打孔器类型错误
-define(REPLY_MSG_EQUIP_SLOT_255, 255).      %% 打孔失败，请重试。重试失败，请联系GM


%%----------------------------------------------------
%% 单件装备提炼
-define(REPLY_MSG_EQUIP_EXCHANGE_OK, 0).               %% 装备提炼成功
-define(REPLY_MSG_EQUIP_EXCHANGE_1, 1).                %% 装备不能提炼
-define(REPLY_MSG_EQUIP_EXCHANGE_2, 2).                %% 背包不足
-define(REPLY_MSG_EQUIP_EXCHANGE_3, 3).                %% 花费不足
-define(REPLY_MSG_EQUIP_EXCHANGE_255, 255).            %% 其他错误


%%----------------------------------------------------
%% 装备一键提炼回复
-define(REPLY_MSG_ONE_KEY_EQUIP_EXCHANGE_OK, 0).       %% 装备提炼成功
-define(REPLY_MSG_ONE_KEY_EQUIP_EXCHANGE_1, 1).        %% 没有符合条件的装备
-define(REPLY_MSG_ONE_KEY_EQUIP_EXCHANGE_2, 2).        %% 背包不足
-define(REPLY_MSG_ONE_KEY_EQUIP_EXCHANGE_3, 3).        %% 花费不足
-define(REPLY_MSG_ONE_KEY_EQUIP_EXCHANGE_255, 255).      %% 其他错误


%%----------------------------------------------------
%% 附魔卷轴合成回复
-define(REPLY_MSG_FUMO_JUANZHOU_HECHENG_OK, 0).       %% 附魔卷轴合成成功
-define(REPLY_MSG_FUMO_JUANZHOU_HECHENG_1, 1).        %% 消耗不足
-define(REPLY_MSG_FUMO_JUANZHOU_HECHENG_2, 2).        %% 背包剩余空间不足
-define(REPLY_MSG_FUMO_JUANZHOU_HECHENG_255, 255).    %% 其他错误

%%----------------------------------------------------
%% 装备附魔
-define(REPLY_MSG_EQUIP_IMBUE_WEAPON_OK, 0).          %% 装备附魔成功
-define(REPLY_MSG_EQUIP_IMBUE_WEAPON_1, 1).           %% 没有找到该附魔公式
-define(REPLY_MSG_EQUIP_IMBUE_WEAPON_2, 2).           %% 附魔公式没有被激活
-define(REPLY_MSG_EQUIP_IMBUE_WEAPON_3, 3).           %% 该装备已经被附魔
-define(REPLY_MSG_EQUIP_IMBUE_WEAPON_4, 4).           %% 该装备不能被附魔
-define(REPLY_MSG_EQUIP_IMBUE_WEAPON_5, 5).           %% 消耗不足
-define(REPLY_MSG_EQUIP_IMBUE_WEAPON_6, 6).           %% 该装备没有鉴定
-define(REPLY_MSG_EQUIP_IMBUE_WEAPON_255, 255).       %% 其他错误

%%----------------------------------------------------
%% 装备萃取
-define(REPLY_MSG_EQUIP_CUI_QU_OK, 0).               %% 装备萃取
-define(REPLY_MSG_EQUIP_CUI_QU_1, 1).                 %% 消耗不足
-define(REPLY_MSG_EQUIP_CUI_QU_2, 2).                 %% 该装备没有附魔
-define(REPLY_MSG_EQUIP_CUI_QU_3, 3).                 %% 该装备有宝石
-define(REPLY_MSG_EQUIP_CUI_QU_255, 255).               %% 其它错误


%%----------------------------------------------------
%% 附魔公式的激活
-define(REPLY_MSG_EQUIP_FUMO_STATE_ACTIVATE_OK, 0).   %% 附魔公式激活成功
-define(REPLY_MSG_EQUIP_FUMO_STATE_ACTIVATE_1, 1).    %% 消耗不足
-define(REPLY_MSG_EQUIP_FUMO_STATE_ACTIVATE_2, 2).    %% 该附魔公式已经被激活
-define(REPLY_MSG_EQUIP_FUMO_STATE_ACTIVATE_255, 255). %% 其他错误

%%----------------------------------------------------
%% 穿装备的部位强化
-define(REPLY_MSG_EQUIP_PART_QIANG_HUA_OK, 0).		%% 强化成功
-define(REPLY_MSG_EQUIP_PART_QIANG_HUA_1,  1).		%% 强化失败
-define(REPLY_MSG_EQUIP_PART_QIANG_HUA_2,  2).		%% 强化失败，花费不足
-define(REPLY_MSG_EQUIP_PART_QIANG_HUA_3,  3).		%% 强化失败，已达到最大等级
-define(REPLY_MSG_EQUIP_PART_QIANG_HUA_4,  4).		%% 强化失败，没找到该部位的类型
-define(REPLY_MSG_EQUIP_PART_QIANG_HUA_5,  5).		%% 没找到配置
-define(REPLY_MSG_EQUIP_PART_QIANG_HUA_255, 255).	%% 其它错误
%%----------------------------------------------------
%% 装备洗炼
-define(REPLY_MSG_EQUIP_XILIAN_OK, 0).				%% 洗炼成功
-define(REPLY_MSG_EQUIP_XILIAN_1, 1).				%% 改装备不能洗炼
-define(REPLY_MSG_EQUIP_XILIAN_2, 2).				%% 花费不足
-define(REPLY_MSG_EQUIP_XILIAN_255, 255).			%% 其它错误
%%----------------------------------------------------


