%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 05. 一月 2016 下午2:56
%%%-------------------------------------------------------------------
-module(load_db_main_ins).
-author("clark").

%% API
-export([]).



-include_lib("pangzi/include/pangzi.hrl").
-include("inc.hrl").
-include_lib("main_ins_struct.hrl").


load_db_table_meta() ->
    [
        #db_table_meta
        {
            name = ?player_main_ins_tab,
            fields = ?record_fields(player_main_ins_tab),
            shrink_size=5,
            flush_interval = 6
        },
        #db_table_meta
        {
            name = ?player_main_ins_rank,
            fields = ?record_fields(main_ins_rank),
            shrink_size=5,
            flush_interval = 6
        },
        #db_table_meta
        {
            name = ?main_chapter_prize,
            fields = ?record_fields(main_chapter_prize),
            shrink_size=5,
            flush_interval = 6
        },
        #db_table_meta
        {
            name = ?main_chapter_prize_status,
            fields = ?record_fields(main_chapter_prize_status),
            shrink_size=5,
            flush_interval=6
        },
        #db_table_meta
        {
            name = ?player_main_ins_challenge_tab,
            fields = ?record_fields(player_main_ins_challenge_tab),
            shrink_size=5,
            flush_interval = 6
        }
    ].

