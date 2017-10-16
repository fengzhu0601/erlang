%%%-------------------------------------------------------------------
%%% @author fengzhu
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 04. 一月 2016 下午2:51
%%%-------------------------------------------------------------------
-module(load_cfg_daily_task).
-author("fengzhu").

%% API
-export([]).

-include_lib("config/include/config.hrl").
-include("inc.hrl").
-include("load_cfg_daily_task.hrl").


load_config_meta() ->
  [
    #config_meta{
      record = #task_daily_star_cfg{},
      fields = ?record_fields(task_daily_star_cfg),
      file = "task_daily_star.txt",
      keypos = #task_daily_star_cfg.id,
      rewrite = fun change/1,
      verify = fun verify_star/1}
  ].

verify_star(#task_daily_star_cfg{id = Id, up_probo = _Upp, prize = Prize, task_ids = _TaskIds}) ->
  ?check(check_player_level(Id), "task_daily_star.txt中，[~w] 是无效的玩家等级。", [Id]),
  check_prize(Prize),
  ok.

%% 每日任务星级转换
change(_) ->
  NewCfgList =
    ets:foldl(
      fun
        ({_, #task_daily_star_cfg{id = Id, up_probo = ProboList} = Cfg}, FAcc) ->
          {Total, NProtoL} = com_util:probo_build_single(ProboList),
          ?check(Total =:= 100, "task_daily_star.txt [~w] up_probo 权重和不为100 ~w", [Id, ProboList]),
          [Cfg#task_daily_star_cfg{up_probo = NProtoL} | FAcc]
      end
      ,
      [],
      task_daily_star_cfg),
  NewCfgList.

check_player_level(Id) ->
  is_integer(Id) andalso (1 =< Id).

check_prize(Prize) ->
  ?check(is_list(Prize), "in task_daily_star.txt, [~p] is not a list", [Prize]),
  ?check(length(Prize) == 5, "in task_daily_star.txt, the element number of [~p] is not 5", [Prize]),
  lists:foreach(
    fun
      (PrizeID) ->
        ?check(prize:is_exist_prize_cfg(PrizeID), "in task_daily_star.txt, [~p] is not a valid PrizeID", [PrizeID])
    end,
    Prize).

