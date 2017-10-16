%%%-------------------------------------------------------------------
%%% @author hank
%%% @copyright (C) 2016, <COMPANY>
%%% @doc  read buf configure file
%%%
%%% @end
%%% Created : 01. Mar 2016 2:38 PM
%%%-------------------------------------------------------------------
-module(load_cfg_buff).
-author("hank").

-include_lib("config/include/config.hrl").
-include("inc.hrl").
-include("load_cfg_buff.hrl").
-include("load_cfg_skill.hrl").
-include("load_segments.hrl").

%% API
-export([lookup_buff/1,
  lookup_buff_by_skill/1,
  lookup_buff_by_skill_modify/1,
  lookup_buff_info_by_skill/1]).


load_config_meta() ->
  [
    #config_meta{record = #buff_cfg{},
      fields = ?record_fields(buff_cfg),
      file = "buff.txt",
      keypos = #buff_cfg.id,
      verify = fun verify_buff/1}
  ].


verify_buff(#buff_cfg{id = _Id}) ->
  ok.

lookup_buff(Key) ->
  lookup_buff_cfg(Key).


lookup_buff_by_skill_modify(SkillId) ->
  case load_cfg_skill:lookup_skill_modify_cfg(SkillId) of
    ?none ->
      {[], 0, 0};
    #skill_modify_cfg{buff = _BuffId, trigger_type = TriggerType,
      buff_target_type = TargetType} ->
      SegList1 = case lookup_buff_cfg(_BuffId) of
                   none -> [];
                   Buff -> [Buff]
                 end,
      {SegList1, TargetType, TriggerType}
  end.


lookup_buff_by_skill(SkillId) ->
%%  BuffList = case load_cfg_skill:lookup_skill_cfg(SkillId) of
%%    none -> [];
%%    #skill_cfg{buffs = Buffs} -> Buffs
%%  end,
  {BuffList, Target} = case load_segments:lookup_segments_cfg(SkillId) of
                         none -> {[], 0, 0};
                         #segments_cfg{buffs = undefined} -> {[], 0};
                         #segments_cfg{buffs = Buffs, target_type = Target2} -> {Buffs, Target2}
                       end,
  SegList1 =
    lists:foldl
    (
      fun
        (BuffId, Acc) ->
          case lookup_buff_cfg(BuffId) of
            none -> Acc;
            Buff -> [Buff | Acc]
          end
      end,
      [],
      BuffList
    ),
  {SegList1, Target}.

lookup_buff_info_by_skill(SkillId) ->
  BuffList = case load_cfg_skill:lookup_skill_cfg(SkillId) of
               none -> [];
               #skill_cfg{buffs = Buffs} -> Buffs
             end,
  SegList1 =
    lists:foldl
    (
      fun
        (BuffId, Acc) ->
          case lookup_buff_cfg(BuffId) of
            none -> Acc;
            #buff_cfg{id = ID, time = Time} -> [{ID, Time} | Acc]
          end
      end,
      [],
      BuffList
    ),
  SegList1.
