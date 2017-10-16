%%%-------------------------------------------------------------------
%%% @author hank
%%% @copyright (C) 2016, <COMPANY>
%%% @doc 标记 buff
%%%
%%% @end
%%% Created : 07. Mar 2016 12:05 PM
%%%-------------------------------------------------------------------
-module(buff_plug_hudun).

%% API
-export([
    apply/5,
    remove_buff/1,
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

apply(#agent{idx = AIdx} = AAgent, BAgent, Target, #buff_cfg{id = BuffId, time = Time} = Buff, _ExtInfo) ->
    BuffAgent = case Target of
        1 -> buff_system:get_real_buff_agent(AAgent);
        _ -> buff_system:get_real_buff_agent(BAgent)
    end,
    BuffState = BuffAgent#agent.buff_states,
    case lists:keyfind(BuffId, 1, BuffState) of
        {BuffId, _, _, [Ref], _} ->
            scene_eng:cancel_timer(Ref),
            NewRef = scene_eng:start_timer(Time, ?MODULE, {remove_buff, BuffAgent, BuffId}),
            NewBuffState = lists:keyreplace(BuffId, 1, BuffState, {BuffId, AIdx, com_time:now() + Time div 1000, [NewRef], []}),
            add_hudun_buff(AAgent, BuffAgent#agent{buff_states = NewBuffState}, Buff);
        _ ->
            buff_system:send_buff2client(BuffAgent, BuffId, Time),
            Ref = scene_eng:start_timer(Time, ?MODULE, {remove_buff, BuffAgent, BuffId}),
            NewBuffState = BuffState ++ [{BuffId, AIdx, com_time:now() + Time div 1000, [Ref], []}],
            add_hudun_buff(AAgent, BuffAgent#agent{buff_states = NewBuffState}, Buff)
    end,
    ok.

add_hudun_buff(#agent{attr = Attr}, #agent{idx = Idx} = BuffAgent, #buff_cfg{prop_type = PropType, value = Value}) ->
    HundunVal = Value + element(PropType - 8, Attr),
    NewAgent = BuffAgent#agent{hudun_hp = HundunVal},
    ?update_agent(Idx, NewAgent).

remove_buff(#agent{buff_states = BuffState} = Agent) ->
    [{BuffId, _, _, [Ref], _}] = lists:filter(
        fun({Id, _, _, _, _}) ->
            case load_cfg_buff:lookup_buff_cfg(Id) of
                #buff_cfg{type = Type} ->
                    Type =:= 13;
                _ ->
                    false
            end
        end,
        BuffState
    ),
    scene_eng:cancel_timer(Ref),
    buff_system:cancel_buff2client(Agent, BuffId),
    NewBuffState = lists:keydelete(BuffId, 1, BuffState),
    Agent#agent{buff_states = NewBuffState}.

remove_buff(#agent{idx = Idx} = Agent, BuffId) ->
    buff_system:cancel_buff2client(Agent, BuffId),
    case ?get_agent(Idx) of
        ?undefined ->
            ignore;
        NewAgent ->
            BuffState = NewAgent#agent.buff_states,
            NewBuffState = lists:keydelete(BuffId, 1, BuffState),
            ?update_agent(Idx, NewAgent#agent{hudun_hp = 0, buff_states = NewBuffState})
    end,
    ok.

handle_timer(_Ref, {remove_buff, Agent, BuffId}) ->
    remove_buff(Agent, BuffId).

