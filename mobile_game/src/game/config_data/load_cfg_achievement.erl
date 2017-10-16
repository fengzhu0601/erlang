%%%-------------------------------------------------------------------
%%% @author fengzhu
%%% @copyright (C) 2015, <COMPANY>
%%% @doc 成就系统
%%%
%%% @end
%%% Created : 31. 十二月 2015 下午3:59
%%%-------------------------------------------------------------------
-module(load_cfg_achievement).
-author("fengzhu").

%% API
-export([
    get_reg_achievement_cfg/0,
    achievements2info/1,
    get_ac_cfg/1,
    get_ac_title_cfg/1
]).

-include_lib("config/include/config.hrl").
-include("inc.hrl").
-include("load_cfg_achievement.hrl").

load_config_meta() ->
    [
        #config_meta{record = #achievement_cfg{},
        fields = ?record_fields(achievement_cfg),
        file = "achievement.txt",
        keypos = #achievement_cfg.id,
        verify = fun verify/1}
    ].

verify(_AchievmentCfg) ->
    ok.

%%获得通用成就的AC列表
get_reg_achievement_cfg() ->
    lists:foldl(fun({Key, AcCfg}, Data) ->
        Type = AcCfg#achievement_cfg.type,
        if
            Type =:= 1 ->
                Ac = #ac{
                    id = Key,
                    event_goal = AcCfg#achievement_cfg.event_goal,
                    max_value = AcCfg#achievement_cfg.max_value},
                [Ac | Data];
            true ->
                Data
        end
    end,
    [],
    ets:tab2list(achievement_cfg)).


achievements2info(List) ->
    Fun =
    fun(Achievement) ->
      case Achievement#ac.current_value of
        0 ->
          ?false;
        _ ->
          {?true, {Achievement#ac.id,
            Achievement#ac.current_value,
            Achievement#ac.star,
            Achievement#ac.status,
            Achievement#ac.is_get_prize_star
          }}
      end
    end,
    lists:filtermap(Fun, List).

%根据ID查询一条配置信息
get_ac_cfg(Id) ->
  case lookup_achievement_cfg(Id) of
    ?none ->
      ?none;
    Cfg ->
      Cfg
  end.

%根据ID查询一条配置信息的称号
get_ac_title_cfg(Id) ->
  case lookup_achievement_cfg(Id, #achievement_cfg.title) of
    ?none ->
      ?none;
    Title ->
      Title
  end.

