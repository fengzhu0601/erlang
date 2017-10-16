%%%-------------------------------------------------------------------
%%% @author fengzhu
%%% @copyright (C) 2016, <COMPANY>
%%% @doc 卡牌大师
%%%
%%% @end
%%% Created : 05. 一月 2016 上午11:08
%%%-------------------------------------------------------------------
-author("fengzhu").

-record(card_cfg, {
  group
  , quality          %% 品质 1一星 2两星 3三星 4四星
  , prize_id         %% 奖励id
}).

-define(CARD_ONE_STAR, 1).  %% 一星
-define(CARD_TWO_STAR, 2).  %% 两星
-define(CARD_THR_STAR, 3).  %% 三星
-define(CARD_FOUR_STAR, 4).  %% 四星
-define(CARD_STAR_ALL, [
  ?CARD_ONE_STAR
  , ?CARD_TWO_STAR
  , ?CARD_THR_STAR
  , ?CARD_FOUR_STAR]
).   %% 所有的星星

-record(card_award_info, {
  time_stamp
  , id = 0
  , name = <<>>
  , awards = []
}).

%%变身卡牌的配置结构
-record(item_card_attr_cfg,
{
  id = 0                  %%卡牌id(对应物品id)
  ,card_class             %% 相同boss卡牌的组
  ,time = 0               %%持续时间
  ,buffs=[]
  ,activation_num=0       %%使用次数
  ,activation_buffs=[]    %%激活属性
}).