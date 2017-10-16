%%%-------------------------------------------------------------------
%%% @author hank
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 09. Mar 2016 5:02 PM
%%%-------------------------------------------------------------------
-module(buff_plug_hurt).
-author("hank").

%% API
-export([
    apply/5,
    remove_buff/2
]).

-export(
[
    handle_timer/2
]).

-include("inc.hrl").
-include("player.hrl").
-include("buff_system.hrl").
-include("scene_def.hrl").
-include("skill_struct.hrl").
-include("scene_agent.hrl").
-include("load_cfg_buff.hrl").
-include("load_spirit_attr.hrl").

% 属性加值应用
apply(#agent{idx = AIdx} = AAgent, #agent{idx = BIdx, buff_states = BuffState} = BAgent, _Target, #buff_cfg{id = BuffId, time = Time} = Buff, {Damage}) ->
    case lists:keyfind(BuffId, 1, BuffState) of
        {BuffId, _, _, RefList, _} ->
            [scene_eng:cancel_timer(Ref) || Ref <- RefList],
            NewRef = scene_eng:start_timer(Time, ?MODULE, {remove_buff, BAgent, BuffId}),
            NewBuffState = lists:keyreplace(BuffId, 1, BuffState, {BuffId, AIdx, com_time:now() + Time div 1000, [NewRef], []}),
            ?update_agent(BIdx, BAgent#agent{buff_states = NewBuffState}),
            add_buff(AAgent, BAgent#agent{buff_states = NewBuffState}, Buff, Damage);
        _ ->
            buff_system:send_buff2client(BAgent, BuffId, Time),
            Ref = scene_eng:start_timer(Time, ?MODULE, {remove_buff, BAgent, BuffId}),
            NewBuffState = BuffState ++ [{BuffId, AIdx, com_time:now() + Time div 1000, [Ref], []}],
            ?update_agent(BIdx, BAgent#agent{buff_states = NewBuffState}),
            add_buff(AAgent, BAgent#agent{buff_states = NewBuffState}, Buff, Damage)
    end,
    ok.

add_buff(AAgent, #agent{idx = BIdx, attr = Attr}, #buff_cfg{id = BuffId, time = Time, interval = Interval, attr_type = AttrType, prop_type = PropType, damage = DamageType}, Damage) ->
    AttackIdx = case AAgent#agent.type of
        ?agent_skill_obj ->
            AAgent#agent.fidx;
        _ ->
            AAgent#agent.idx
    end,
    Times = case Interval of
        0 ->
            1;
        _ ->
            trunc(Time / Interval)
    end,
    case DamageType of
        [DType, Deffect, Dvalue] ->
            Value = case DType of
                1 ->
                    trunc(-1 * buff_util:get_attr_value(AAgent, PropType) * Dvalue / 1000);
                _ ->
                    case AttrType of
                        1 ->
                            trunc(-1 * Damage * Dvalue / 1000);
                        _ ->
                            -1 * Dvalue
                    end
            end,
            AddValue = case Deffect of
                1 ->
                    Value;
                2 ->
                    trunc(Value * (1 - Attr#attr.fire_def / 100));
                3 ->
                    trunc(Value * (1 - Attr#attr.ice_def / 100));
                4 ->
                    trunc(Value * (1 - Attr#attr.thunder_def / 100));
                _ ->
                    Value
            end,
            buff_util:handle_timer(0, {change_hp, BIdx, AttackIdx, BuffId, AddValue, Interval, Times});
        _ ->
            buff_util:handle_timer(0, {change_hp, BIdx, AttackIdx, BuffId, -1 * DamageType, Interval, Times})
    end.

remove_buff(#agent{idx = Idx} = Agent, BuffId) ->
    buff_system:cancel_buff2client(Agent, BuffId),
    case ?get_agent(Idx) of
        ?undefined ->
            ignore;
        NewAgent ->
            BuffState = NewAgent#agent.buff_states,
            case lists:keyfind(BuffId, 1, BuffState) of
                {BuffId, _, _, _, _} ->
                    NewBuffState = lists:keydelete(BuffId, 1, BuffState),
                    ?update_agent(Idx, NewAgent#agent{buff_states = NewBuffState});
                _ ->
                    ?ERROR_LOG("can not find buff id in list:~p", [BuffId])
            end
    end,
    ok.

handle_timer(_Ref, {remove_buff, Agent, BuffId}) ->
    remove_buff(Agent, BuffId).
