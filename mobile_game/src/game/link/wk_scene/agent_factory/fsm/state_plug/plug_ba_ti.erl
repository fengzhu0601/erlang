%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%% 霸体
%%% @end
%%% Created : 10. 十一月 2015 上午11:17
%%%-------------------------------------------------------------------
-module(plug_ba_ti).
-author("clark").

%% API
-export
([
    is_ba_it/1
]).

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
restart(#agent{ pl_ba_ti_info = #pl_ba_ti_info{bati_end_tm = EndTm} } = Agent, {_SkillId, SkillDuanId}) ->
    %% 记录霸体终止时间即可，没必要开定时器
    %% 后面要让前端发个消息时间上来以做损失补偿
    SkillCfg = load_cfg_skill:lookup_skill_cfg(SkillDuanId),
    BtTm =
        case SkillCfg#skill_cfg.ba_ti of
            0 ->
                0;
            BaTiTm ->
                com_time:timestamp_msec() + BaTiTm
        end,
    BtTm1 = erlang:max(BtTm, EndTm),
    Agent#agent{ pl_ba_ti_info = #pl_ba_ti_info{bati_end_tm = BtTm1}}.


stop(#agent{} = Agent) ->
    Agent#agent{ pl_ba_ti_info = #pl_ba_ti_info{bati_end_tm = 0}}.


can_interrupt(#agent{} = Agent, StatePlugList) ->
    case is_ba_it(Agent) of
        ok ->
            case has_be_attack_plug(StatePlugList) of
                ok ->
                    ?INFO_LOG("is ba_ti"),
                    ret:error(cant_interrupt);
                _ ->
                    ?INFO_LOG("is ba_ti but can"),
                    ret:ok()
            end;
        _ ->
            ret:ok()
    end.


is_ba_it(#agent{pl_ba_ti_info = #pl_ba_ti_info{bati_end_tm = EndTm}} = _Agent) ->
    CurTm = com_time:timestamp_msec(),
    if
        CurTm > EndTm ->
            ret:error(isnot_ba_ti);
        true ->
            ret:ok()
    end.


has_be_attack_plug([]) ->
    ret:error(no);
has_be_attack_plug([{Plug, _TPar}|TailList]) ->
    if
        Plug =:= plug_beat_vertical ->
            ret:ok();
        Plug =:= plug_beat_horizontal ->
            ret:ok();
        Plug =:= plug_stiff ->
            ret:ok();
        true ->
            has_be_attack_plug(TailList)
    end.
