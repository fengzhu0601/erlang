-record(phase_achievement_cfg,
{
    id,
    goal_list,
    prize
}).

-define(PHASE_AC_LEVEL, 1).             %%玩家等级
-define(PHASE_AC_ADD_BLUE_EQUIP, 2).     %%装备蓝色品质的装备件数                           Max
-define(PHASE_AC_EQUIP_QIANGHUA, 3).    %%背包与仓库内同时存在强化等级达到X值的装备件数            Max
-define(PHASE_AC_EQUIP_HECHENG_BLUE, 4).     %%合成蓝色品质装备件数
-define(PHASE_AC_FRIEND_COUNT, 5).      %%好友数量
-define(PHASE_AC_ARENA_RENJI, 6).       %%参与竞技场人机模式次数
-define(PHASE_AC_ARENA_ONE_WIN, 7).     %%参与竞技场匹配模式且胜利次数
-define(PHASE_AC_ARENA_TEAM_WIN, 8).    %%参与竞技场团队模式且胜利次数
-define(PHASE_AC_ARENA_WIN, 9).         %%参与竞技场匹配模式或团队模式的总胜利次数
-define(PHASE_AC_ARENA_RANK, 10).       %%参与竞技场人机模式的排名达到的排名                     Min
-define(PHASE_AC_KAPIA_BIANSHEN, 11).   %%卡牌变身次数
-define(PHASE_AC_KAPAI_CHOUJING, 12).  %%卡牌抽奖次数
-define(PHASE_AC_ZUANSHI_KA, 13).        %%钻石卡拥有数量
-define(PHASE_AC_KAPAI_BOSS_QUALITY_KA, 14). %%拥有相同BOSS不同品质的卡牌数量                   Max
-define(PHASE_AC_GONGHUI_JOIN, 15).           %%加入公会
-define(PHASE_AC_GONGHUI_UPGRADE, 16).        %%提升公会科技的次数
-define(PHASE_AC_GONGHUI_ONE_LEVEL, 17).      %%公会内个人科技等级高于X级
-define(PHASE_AC_LONGWEN_XIDIAN, 18).         %%使用龙纹洗点次数
-define(PHASE_AC_LONGWEN_ADD, 19).            %%同时装备龙纹个数                                Max
-define(PHASE_AC_INSTANCE_CHAPER_1, 20).        %%X章节普通难度通关
-define(PHASE_AC_PAIMAI_SHANGJIA, 21).        %%拍卖行成功上架装备数量
-define(PHASE_AC_PAIMAI_JIAOYI, 22).        %%拍卖行成功拍卖装备数量
-define(PHASE_AC_HUANGGUAN_USE, 23).  %%皇冠技能使用种类
-define(PHASE_AC_BEIBAO_STAR, 24).  %%背包开启页数                                            Max
-define(PHASE_AC_EQUIP_JICHENG, 25).  %%装备继承次数
-define(PHASE_AC_INSTANCE_CHAPER_2, 26).%%通关困难难度
-define(PHASE_AC_INSTANCE_CHAPER_3, 27).%%X章节噩梦难度通关
-define(PHASE_AC_EQUIP_HECHENG_ZISE, 28).%%合成紫色品质装备
-define(PHASE_AC_EQUIP_HECHENG_CHENGSE, 29).%%合成橙色品质装备
-define(PHASE_AC_ADD_ZISE_EQUIP, 30).%%玩家同时穿戴紫色装备件数                   Max
-define(PHASE_AC_ADD_CHENGSE_EQUIP, 31).%%玩家同时穿戴橙色装备件数                   Max
-define(PHASE_AC_ADD_LVSE_EQUIP,32).%%玩家同时穿戴绿色套装件数                         Max
