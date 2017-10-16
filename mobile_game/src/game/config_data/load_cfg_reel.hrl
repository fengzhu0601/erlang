%%%-------------------------------------------------------------------
%%% @author fengzhu
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 24. 四月 2017 下午2:45
%%%-------------------------------------------------------------------
-author("fengzhu").

-record(reel_cfg,
{
    pos,
    reel1,
    reel2,
    reel3,
    reel4,
    reel5
}).

-record(pay_line_cfg,
{
    line_id,
    pos1,
    pos2,
    pos3,
    pos4,
    pos5
}).

-record(odds_cfg,
{
    pic_id,     %% 图片Id
    link1,      %% 1连对应的赔率倍数
    link2,
    link3,
    link4,
    link5
}).

