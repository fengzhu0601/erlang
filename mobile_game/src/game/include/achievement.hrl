%-define(AC_DOING, 1).
-define(AC_CAN_GET_PRIZE, 2).
-define(player_achievement_tab, player_achievement_tab).
-define(pd_ac_list, pd_ac_list).
-define(pd_instance_ac_list, pd_instance_ac_list).


-define(lianji, 1).
-define(shouji, 2).
-define(passtime, 3).
-define(kill_monster, 4). %% course_mng
-define(relive_num, 5).
-define(add_xue, 6).

%-record(achievement_cfg, {
%    id,
%    type,
%    event = 0,
%    event_goal = 0,
%    max_value,
%    reward,
%    title
%}).

-record(player_achievement_tab, {
    id,
    list = []
}).


%-record(ac, {
%    id,
%    star = 0,
%    current_value = 0,
%    event_goal,
%    max_value,
%    status = ?AC_DOING,
%    is_get_prize_star = 0
%}).

-record(instance_ac, {
    id,
    goal
}).

-define(emolieshou, 10001).         %% 恶魔猎手
-define(guaiwulieren, 10002).       %% 怪物猎人
-define(gonghuixinxing, 40001).     %%公会新星
-define(gonghuishouling, 40002).    %%公会首领
-define(gongxiandaren, 40003).      %%贡献达人
-define(qianghuazhixing, 40004).    %%强化之星
-define(qianghuadaren, 40005).      %% 强化达人
-define(qianghuayizhi, 40006).      %% 强化意志
-define(hechenggaoshou, 40007).     %%合成高手
-define(yishenshenzhuang, 40008).   %%一身神装
-define(taozhuangzhishen, 40009).    %%套装之神
-define(zhuxiandaren, 40010).       %%主线达人
-define(zhixiandaren, 40011).       %%支线达人
-define(richanggaoshou, 40012).     %%日常高手
-define(xingjidaren, 40013).        %%星级达人
-define(lianjigaoshou, 40014).      %%连击高手
-define(lianjidashi, 40015).        %%连击大师
-define(fubengaoshou, 40016).       %%副本高手
-define(wuweiqiangze, 40017).       %%无畏强者
-define(sierhousheng, 40018).       %%死而后生
-define(yuandifuhuo, 40019).        %%原地复活
-define(longwenshitan, 40020).       %%龙纹试探
-define(longwendashi, 40021).        %%龙纹大师
-define(huangguanzhili, 40022).     %%皇冠之力
-define(paimaidashi, 40023).        %%拍卖大师
-define(gouwukuang, 40024).         %%购物狂
-define(jingjiagaoshou, 40025).     %%竞价高手
-define(chongwuzhixing, 40026).     %%宠物之星
-define(chongwudaren, 40027).        %%宠物达人
-define(chongwudashi, 40028).        %%宠物大师
-define(renmaidashi, 40029).        %%人脉大师
-define(renqibaopeng, 40030).       %%人气爆棚
-define(lipindashi, 40031).         %%礼品大师
-define(wuxianlibao, 40032).        %%无限礼包
-define(pkshilian, 40033).          %%PK试炼
-define(pkrumen, 40034).            %%PK入门
-define(pkgaoshou, 40035).          %%PK高手
-define(pkdashi, 40036).            %%PK大师
-define(zuiqiangwangze, 40037).     %%最强王者
-define(dantiaozhiwang, 40038).     %%单挑之王
-define(jianyibuqu, 40039).         %%坚毅不屈
-define(baiyingaoshou, 40040).      %%白银高手
-define(chucigouwu, 40041).         %%初次购物
-define(jiacaiwanguan, 40042).      %%家财万贯
-define(zuanshizhiwang, 40043).     %%钻石之王
-define(zishenwanjia, 40044).       %%资深玩家
-define(zuiqiangzhanli, 40045).     %%最强战力
-define(beibaodaren, 40046).        %%背包达人
-define(cangkudaren, 40047).        %%仓库达人
-define(tulongze, 40048).           %%屠龙者
-define(damaoxianjia, 40049).       %%大冒险家
-define(jiushize, 40050).           %%救世者
-define(renwukuangren, 40051).      %%任务狂人
-define(baoshishoucangjia, 40052).  %%宝石收藏家
-define(shanshanbaoshi, 40053).     %%闪闪的宝石
-define(zhennuli, 40054).           %%真努力
-define(yuelaiyueda, 40055).        %%越来越大
-define(angguishisi, 40056).        %%昂贵的史诗
-define(shanguangchuanqi, 40057).   %%闪光的传奇
-define(xiangqiandaren, 40058).     %%镶嵌达人
-define(chaijieshengshou, 40059).   %%拆解圣手
-define(fumozhuanjia, 40060).       %%附魔专家
-define(cuiqudashi, 40061).         %%萃取大师
-define(bilvzhengcheng, 40062).     %%碧绿的征程
-define(chongwudalianmeng, 40063).  %%宠物大联盟
-define(shenzhixushoushi, 40064).   %%神之训兽师
-define(chaojiqishou, 40065).       %%超级骑手
-define(shenjizuoqi, 40066).        %%神级坐骑
-define(dongwuhuoban, 40067).       %%动物伙伴
-define(xukonglingzhu, 40068).      %%虚空领主
-define(shuijingzhongjiezhe, 40069).%%水晶终结者
-define(fanxingmantian, 40070).     %%繁星满天
-define(shejiaodaren, 40071).       %%社交达人
-define(chaojixueyuan, 40072).      %%超级学员
-define(tiancaixueyuan, 40073).     %%天才学院
-define(xueba, 40074).              %%学霸
-define(jinengdashi, 40075).        %%技能大师



































