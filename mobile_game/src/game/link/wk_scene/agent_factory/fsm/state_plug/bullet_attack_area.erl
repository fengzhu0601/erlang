%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 14. 十一月 2015 上午8:59
%%%-------------------------------------------------------------------
-module(bullet_attack_area).
-author("clark").

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


run(#agent{type = ?agent_skill_obj, pl_from_skill = FromSkill} = Agent, {SkillId, _SkillDuanId}) ->
    %% 攻击区(目前不做打断处理, 先暂时依据前端的判断)
    attack_area_tgr:create_bullet_hit_area(Agent, {SkillId, FromSkill}),
%%     Agent1 = attack_area_tgr:start(Agent, SkillId),
    Agent.


