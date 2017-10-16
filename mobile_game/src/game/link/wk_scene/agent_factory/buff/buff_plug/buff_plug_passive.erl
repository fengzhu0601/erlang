%%%-------------------------------------------------------------------
%%% @author hank
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 09. Mar 2016 5:05 PM
%%%-------------------------------------------------------------------
-module(buff_plug_passive).
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
apply(#agent{idx = AIdx, buff_states = BuffState} = AAgent, BAgent, _Target, #buff_cfg{id = BuffId, time = Time} = Buff, {Damage}) ->
    case lists:keyfind(BuffId, 1, BuffState) of
        {BuffId, _, _, [Ref], ChangeData} ->
            scene_eng:cancel_timer(Ref),
            {NewAAgent, _} = add_buff(AAgent, BAgent, Buff, Damage),
            NewRef = scene_eng:start_timer(Time, ?MODULE, {remove_buff, NewAAgent, BuffId}),
            NewBuffState = lists:keyreplace(BuffId, 1, BuffState, {BuffId, AIdx, com_time:now() + Time div 1000, [NewRef], ChangeData}),
            ?update_agent(AIdx, NewAAgent#agent{buff_states = NewBuffState});
        _ ->
            buff_system:send_buff2client(AAgent, BuffId, Time),
            {NewAAgent, ChangeData} = add_buff(AAgent, BAgent, Buff, Damage),
            Ref = scene_eng:start_timer(Time, ?MODULE, {remove_buff, NewAAgent, BuffId}),
            NewBuffState = BuffState ++ [{BuffId, AIdx, com_time:now() + Time div 1000, [Ref], ChangeData}],
            ?update_agent(AIdx, NewAAgent#agent{buff_states = NewBuffState})
    end,
    ok.

add_buff(#agent{idx = AIdx} = AAgent, _BAgent, #buff_cfg{id = BuffId, passive_info = [_, DType, DValue, _A1, A2, Effect], prop_type = PropType}, Damage) ->
    case A2 of
        1 ->    %% 作用者是攻击方
            AddValue = case DType of
                1 ->
                    trunc(buff_util:get_attr_value(AAgent, PropType) * DValue / 1000);
                _ ->
                    trunc(Damage * DValue / 1000)
            end,
            case Effect of
                1 ->
                    buff_util:player_change_anger(AAgent, AddValue);
                5 ->
                    buff_util:player_change_hp(AAgent, AIdx, BuffId, AddValue);
                6 ->
                    buff_util:player_change_mp(AAgent, AddValue);
                _ ->
                    ignore
            end,
            {AAgent, []};
        2 ->    %% 作用者是受击方
            AddValue = trunc(buff_util:get_attr_value(AAgent, PropType) * DValue / 1000),
            buff_util:change_agent_attrs(AAgent, [{24, AddValue}], 2)
    end.

remove_buff(#agent{idx = Idx} = Agent, BuffId) ->
    buff_system:cancel_buff2client(Agent, BuffId),
    case ?get_agent(Idx) of
        ?undefined ->
            ignore;
        NewAgent ->
            BuffState = NewAgent#agent.buff_states,
            case lists:keyfind(BuffId, 1, BuffState) of
                {BuffId, _, _, _, ChangeData} ->
                    FinalAgent = NewAgent#agent{attr = agent_util:sub_attrs(NewAgent#agent.attr, ChangeData)},
                    NewBuffState = lists:keydelete(BuffId, 1, BuffState),
                    ?update_agent(Idx, FinalAgent#agent{buff_states = NewBuffState});
                _ ->
                    ?ERROR_LOG("can not find buff id in list:~p", [BuffId])
            end
    end,
    ok.

handle_timer(_Ref, {remove_buff, Agent, BuffId}) ->
    remove_buff(Agent, BuffId).