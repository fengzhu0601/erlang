%%%-------------------------------------------------------------------
%%% @author hank
%%% @copyright (C) 2016, <COMPANY>
%%% @doc  移动的 buff
%%%
%%% @end
%%% Created : 04. Mar 2016 6:27 PM
%%%-------------------------------------------------------------------
-module(buff_plug_move).
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

apply(#agent{idx = AIdx} = AAgent, BAgent, Target, #buff_cfg{id = BuffId, move_speed = SpeedPre, time = Time} = _Buff, _ExtInfo) ->
    BuffAgent = case Target of
        1 -> buff_system:get_real_buff_agent(AAgent);
        2 -> buff_system:get_real_buff_agent(BAgent)
    end,
    Attr = BuffAgent#agent.attr,
    BuffState = BuffAgent#agent.buff_states,
    case lists:keyfind(BuffId, 1, BuffState) of
        {BuffId, _, _, [Ref], ChangeData} ->
            scene_eng:cancel_timer(Ref),
            NewRef = scene_eng:start_timer(Time, ?MODULE, {remove_buff, BuffAgent, BuffId}),
            NewBuffState = lists:keyreplace(BuffId, 1, BuffState, {BuffId, AIdx, com_time:now() + Time div 1000, [NewRef], ChangeData}),
            ?update_agent(BuffAgent#agent.idx, BuffAgent#agent{buff_states = NewBuffState});
        _ ->
            buff_system:send_buff2client(BuffAgent, BuffId, Time),
            MSpeed = Attr#attr.move_speed, RSpeed = Attr#attr.run_speed,
            NMSpeed = max(0, trunc(MSpeed + MSpeed * SpeedPre / 1000)),
            NRSpeed = max(0, trunc(RSpeed + RSpeed * SpeedPre / 1000)),
            NewBAgent = buff_util:player_change_speed(BuffAgent, NMSpeed, NRSpeed),
            Ref = scene_eng:start_timer(Time, ?MODULE, {remove_buff, NewBAgent, BuffId}),
            NewBuffState = BuffState ++ [{BuffId, AIdx, com_time:now() + Time div 1000, [Ref], [NMSpeed - MSpeed, NRSpeed - RSpeed]}],
            ?update_agent(BuffAgent#agent.idx, NewBAgent#agent{buff_states = NewBuffState})
    end,
    ok.

remove_buff(#agent{idx = Idx} = Agent, BuffId) ->
    buff_system:cancel_buff2client(Agent, BuffId),
    case ?get_agent(Idx) of
        ?undefined ->
            ignore;
        NewAgent ->
            BuffState = NewAgent#agent.buff_states,
            case lists:keyfind(BuffId, 1, BuffState) of
                {BuffId, _, _, _, [AddMoveSpeed, AddRunSpeed]} ->
                    Attr = NewAgent#agent.attr,
                    MSpeed = Attr#attr.move_speed, RSpeed = Attr#attr.run_speed,
                    NMSpeed = max(0, MSpeed - AddMoveSpeed),
                    NRSpeed = max(0, RSpeed - AddRunSpeed),
                    FinalAgent = buff_util:player_change_speed(NewAgent, NMSpeed, NRSpeed),
                    NewBuffState = lists:keydelete(BuffId, 1, BuffState),
                    ?update_agent(Idx, FinalAgent#agent{buff_states = NewBuffState});
                _ ->
                    ?ERROR_LOG("can not find buff id in list:~p", [BuffId])
            end
    end,
    ok.

handle_timer(_Ref, {remove_buff, Agent, BuffId}) ->
    remove_buff(Agent, BuffId).