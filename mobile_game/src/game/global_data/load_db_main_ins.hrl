%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 05. 一月 2016 下午2:56
%%%-------------------------------------------------------------------
-author("clark").


-define(player_main_ins_tab, player_main_ins_tab).
-record(player_main_ins_tab,
{
    id,
    star_coin = 0,
    mng
}).


-define(player_main_ins_rank, main_ins_rank).
-record(main_ins_rank,
{
    scene_id,
    rank_list = [] %% [{PlayerId, FenShu}]
}).


-define(main_chapter_prize, main_chapter_prize).
-record(main_chapter_prize,
{
    id, %% {playerid, chapter id,sub}
    goal_value={0,0,0},
    current_value=0,
    ins_list=[],
    is_get={0,0,0}
}).


-define(main_chapter_prize_status, main_chapter_prize_status).
-record(main_chapter_prize_status,
{
    id,
    isget_list=[] %% {{chapter_id,sub}, {0,0,0}}
}).