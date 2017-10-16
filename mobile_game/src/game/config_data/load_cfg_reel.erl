%%%-------------------------------------------------------------------
%%% @author fengzhu
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 24. 四月 2017 下午2:45
%%%-------------------------------------------------------------------
-module(load_cfg_reel).
-author("fengzhu").

-include("inc.hrl").
-include_lib("config/include/config.hrl").
-include("load_cfg_reel.hrl").
%% API
-export([]).

load_config_meta() ->
    [
        #config_meta{
            record = #reel_cfg{},
            fields = ?record_fields(reel_cfg),
            file = "reel.txt",
            keypos = #reel_cfg.pos,
            verify = fun verify/1,
            is_compile = true},

        #config_meta{
            record = #pay_line_cfg{},
            fields = ?record_fields(pay_line_cfg),
            file = "pay_line.txt",
            keypos = #pay_line_cfg.line_id,
            verify = fun verify/1,
            is_compile = true},

        #config_meta{
            record = #odds_cfg{},
            fields = ?record_fields(odds_cfg),
            file = "odds.txt",
            keypos = #odds_cfg.pic_id,
            verify = fun verify/1,
            is_compile = true}
    ].

verify(#reel_cfg{}) ->
    ok;
verify(#odds_cfg{}) ->
    ok;
verify(#pay_line_cfg{}) ->
    ok.
