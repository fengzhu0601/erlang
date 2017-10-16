%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%% 僵直
%%% @end
%%% Created : 10. 十一月 2015 上午11:17
%%%-------------------------------------------------------------------
-module(plug_stiff).
-author("clark").

%% API
-export([]).


-include("i_plug.hrl").
-include("skill_struct.hrl").
-include("load_spirit_attr.hrl").
-include("inc.hrl").
-include("scene.hrl").
-include("scene_agent.hrl").



on_event(_Agent, _Event) -> none.
can_start(#agent{}, _TPar) -> ret:ok().
run(#agent{} = Agent, _TPar) -> Agent.
start(#agent{} = Agent, TPar) -> restart(Agent, TPar).

restart(#agent{ idx = Idx, pl_stiff = #pl_stiff_info{stiff_end_tm = EndTm} } = Agent, {SkillCfg}) ->
    StTm =
        case SkillCfg#skill_cfg.hard_time of
            0 ->
                0;
            StiffTm ->
                com_time:timestamp_msec() + StiffTm
        end,
%%     StTm1 = erlang:max(StTm, EndTm) + 1447268483690 + 9999999,
    StTm1 = erlang:max(StTm, EndTm),
    Agent1 = Agent#agent{ pl_stiff = #pl_stiff_info{stiff_end_tm = StTm1}},
    ?update_agent(Idx, Agent1),
    Agent1.


stop(#agent{} = Agent) ->
    Agent#agent{ pl_stiff = #pl_stiff_info{stiff_end_tm = 0}}.


can_interrupt(#agent{pl_stiff = #pl_stiff_info{stiff_end_tm = _EndTm}} = Agent, _StatePlugList) ->
%%     ?INFO_LOG("can_interrupt ~p",[EndTm]),
    case is_stiff(Agent) of
        ok ->
            %% 遍历状态插件， 看是否都满足可以打断的（例如说自身僵直时转到攻击， 是不许的）
            ret:error(cant_interrupt);
        _ ->
            ret:ok()
    end.


is_stiff(#agent{pl_stiff = #pl_stiff_info{stiff_end_tm = EndTm}} = _Agent) ->
    CurTm = com_time:timestamp_msec(),
    if
        CurTm > EndTm ->
            ret:error(isnot_stiff);
        true ->
            ret:ok()
    end;

is_stiff(Idx) ->
    case ?get_agent(Idx) of
        #agent{} = Agt -> is_stiff(Agt);
        _ -> ret:error(isnot_stiff)
    end.