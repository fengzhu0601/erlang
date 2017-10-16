%%%-------------------------------------------------------------------
%%% @author fengzhu
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 01. 九月 2016 下午8:06
%%%-------------------------------------------------------------------
-module(load_cfg_shangjin_task).
-author("fengzhu").

%% API
-export([
    get_bounty_liveness_by_id/1
    , get_bounty_prizeId_by_id/1
]).

-include_lib("config/include/config.hrl").
-include("inc.hrl").
-include("load_cfg_shangjin_task.hrl").

load_config_meta() ->
    [
        #config_meta{record = #bounty_task_cfg{},
            fields = record_info(fields, bounty_task_cfg),
            file = "shangjin_task.txt",
            keypos = #bounty_task_cfg.id,
            verify = fun verify/1},

        #config_meta{record = #bounty_task_rank_cfg{},
            fields = record_info(fields, bounty_task_rank_cfg),
            file = "shangjin_task_rank.txt",
            keypos = #bounty_task_rank_cfg.id,
            verify = fun verify/1}
    ].

verify(#bounty_task_cfg{id = Id, condition = Condition, prize = Prize, weight = Weight, integral = Integral}) ->
    ?check(Weight >= 0, "shangjin_task.txt中， [~p] weight: ~p 配置无效。", [Id, Weight]),
    ok;

verify(#bounty_task_rank_cfg{id = Id, prize = PrizeId}) ->
    ?check(prize:is_exist_prize_cfg(PrizeId),
        "shangjin_task_rank.txt id:[~p] 奖励id:~p 在配置表 prize.txt 中没有找到", [Id, PrizeId]) ,
    ok;

verify(_R) ->
    ?ERROR_LOG("shop.txt ~p 无效格式", [_R]),
    exit(bad).


%% 根据赏金任务id获得活跃度
get_bounty_liveness_by_id(Id) ->
    case lookup_bounty_task_cfg(Id) of
        ?none ->
            0;
        Cfg ->
            Cfg#bounty_task_cfg.integral
    end.

%% 奖励Id
get_bounty_prizeId_by_id(Id) ->
    case lookup_bounty_task_cfg(Id) of
        ?none ->
            0;
        Cfg ->
            Cfg#bounty_task_cfg.prize
    end.

