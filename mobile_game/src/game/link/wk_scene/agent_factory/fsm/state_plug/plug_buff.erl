%%%-------------------------------------------------------------------
%%% @author hank
%%% @copyright (C) 2016, <COMPANY>
%%% @doc  buff处理
%%%
%%% @end
%%% Created : 03. Mar 2016 11:26 AM
%%%-------------------------------------------------------------------
-module(plug_buff).
-author("hank").

%% API
-export([]).
-include("i_plug.hrl").
-include("skill_struct.hrl").
-include("load_spirit_attr.hrl").
-include("inc.hrl").
-include("scene.hrl").
-include("scene_agent.hrl").


can_start(#agent{x = _CurX, y = _CurY}, {_SkillId, _SkillDuanId}) -> ret:ok().
start(#agent{} = Agent, TPar) -> restart(Agent, TPar).
restart(#agent{} = Agent, _TPar) -> Agent.
stop(#agent{} = Agent) -> Agent.
can_interrupt(#agent{} = _Agent, _StatePlugList) -> ret:ok().
on_event(_Agent, _Event) -> none.

run
(
    #agent
    {
      id = _PlayerId,
      type = Type,
      idx = Idx,
      pl_attack = #pl_attack_info{skill_id = _SkillID}
    } = Agent,
    {SkillId, SkillDuanId, Dir, SyncX, SyncY, SyncH}
) ->
  Agent.
