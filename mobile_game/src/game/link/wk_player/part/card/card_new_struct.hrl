%%%-------------------------------------------------------------------
%%% @author fengzhu
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 20. 十二月 2016 上午10:31
%%%-------------------------------------------------------------------
-author("fengzhu").

-record(card_new_info,{
    card_id,        %% 卡牌Id
    use_times,      %% 使用次数
    max_times       %% 激活条件
}).

-define(player_card_new_tab, player_card_new_tab).
-record(player_card_new_tab, {
    id,
    card_list = []      %%{卡牌Id,使用次数,激活条件,是否已经激活}
}).

-define(player_card_list, player_card_list).

-define(player_crown_skill_list, player_crown_skill_list).
