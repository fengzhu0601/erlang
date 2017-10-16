%%%-------------------------------------------------------------------
%%% @author hank
%%% @copyright (C) 2016, <COMPANY>
%%% @doc 属性 buff  添加基本属性，血蓝除外
%%%
%%% @end
%%% Created : 09. Mar 2016 4:54 PM
%%%-------------------------------------------------------------------
-module(buff_plug_attrs).
-author("hank").

%% API
-export([
    apply/5,
    remove_buff/2,
    delete_halo_buff/4
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

apply(#agent{idx = AIdx}, #agent{idx = BIdx, buff_states = BuffState}, _Target, #buff_cfg{id = BuffId, attr_type = AttrType, attrs = Attrs, time = Time} = _BuffCfg, {time, NowTime}) ->
    %% 获取Agent身上需要移除的光环buff和剩下的buff
    {DelBuffList, NewBuffState} = lists:foldl(
        fun
            ({{OldId, halo_buff, OldTime}, _, _, OldRef, OldChangeData} = Tuple, {DelList, ResList}) ->
                case OldTime =:= NowTime of
                    true -> {DelList, [Tuple | ResList]};
                    _ -> {[{OldId, OldRef, OldChangeData} | DelList], ResList}
                end;
            (Other, {DelList, ResList}) ->
                {DelList, [Other | ResList]}
        end,
        {[], []},
        BuffState
    ),
    %% 移除旧的光环buff
    buff_system:delete_halo_buff(BIdx, DelBuffList),
    %% 添加新的光环buff
    NewBAgent = ?get_agent(BIdx),
    buff_system:send_buff2client(NewBAgent, BuffId, Time),
    {FinalBAgent, FinalChangeData} = buff_util:change_agent_attrs(NewBAgent, Attrs, AttrType),
    FinalRef = scene_eng:start_timer(Time, ?MODULE, {remove_halo_buff, FinalBAgent, {BuffId, halo_buff, NowTime}}),
    FinalBuffState = NewBuffState ++ [{{BuffId, halo_buff, NowTime}, AIdx, com_time:now() + Time div 1000, [FinalRef], FinalChangeData}],
    ?update_agent(BIdx, FinalBAgent#agent{buff_states = FinalBuffState});
apply(#agent{idx = AIdx} = AAgent, BAgent, Target, #buff_cfg{id = BuffId, attr_type = AttrType, attrs = Attrs, time = Time} = _BuffCfg, _ExtInfo) ->
    BuffAgent = case Target of
        1 -> buff_system:get_real_buff_agent(AAgent);
        2 -> buff_system:get_real_buff_agent(BAgent)
    end,
    BuffState = BuffAgent#agent.buff_states,
    case lists:keyfind(BuffId, 1, BuffState) of
        {BuffId, _, _, [Ref], ChangeData} ->
            scene_eng:cancel_timer(Ref),
            NewRef = scene_eng:start_timer(Time, ?MODULE, {remove_buff, BuffAgent, BuffId}),
            NewBuffState = lists:keyreplace(BuffId, 1, BuffState, {BuffId, AIdx, com_time:now() + Time div 1000, [NewRef], ChangeData}),
            ?update_agent(BuffAgent#agent.idx, BuffAgent#agent{buff_states = NewBuffState});
        _ ->
            buff_system:send_buff2client(BuffAgent, BuffId, Time),
            {NewBAgent, ChangeData} = buff_util:change_agent_attrs(BuffAgent, Attrs, AttrType),
            Ref = scene_eng:start_timer(Time, ?MODULE, {remove_buff, NewBAgent, BuffId}),
            NewBuffState = BuffState ++ [{BuffId, AIdx, com_time:now() + Time div 1000, [Ref], ChangeData}],
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
                {BuffId, _, _, _, ChangeData} ->
                    FinalAgent = NewAgent#agent{attr = agent_util:sub_attrs(NewAgent#agent.attr, ChangeData)},
                    NewBuffState = lists:keydelete(BuffId, 1, BuffState),
                    ?update_agent(Idx, FinalAgent#agent{buff_states = NewBuffState});
                _ ->
                    ?ERROR_LOG("can not find buff id in list:~p", [BuffId])
            end
    end,
    ok.

remove_halo_buff(#agent{idx = Idx} = Agent, {BuffId, halo_buff, _NowTime} = Buff) ->
    buff_system:cancel_buff2client(Agent, BuffId),
    case ?get_agent(Idx) of
        ?undefined ->
            ignore;
        NewAgent ->
            BuffState = NewAgent#agent.buff_states,
            case lists:keyfind(Buff, 1, BuffState) of
                {Buff, _, _, _, ChangeData} ->
                    FinalAgent = NewAgent#agent{attr = agent_util:sub_attrs(NewAgent#agent.attr, ChangeData)},
                    NewBuffState = lists:keydelete(Buff, 1, BuffState),
                    ?update_agent(Idx, FinalAgent#agent{buff_states = NewBuffState});
                _ ->
                    pass
            end
    end,
    ok.

delete_halo_buff(Idx, BuffId, [Ref], ChangeData) ->
    scene_eng:cancel_timer(Ref),
    case ?get_agent(Idx) of
        ?undefined ->
            ignore;
        NewAgent ->
            buff_system:cancel_buff2client(NewAgent, BuffId),
            ?update_agent(Idx, NewAgent#agent{attr = agent_util:sub_attrs(NewAgent#agent.attr, ChangeData)})
    end.

handle_timer(_Ref, {remove_buff, Agent, BuffId}) ->
    remove_buff(Agent, BuffId);
handle_timer(_Ref, {remove_halo_buff, Agent, Buff}) ->
    remove_halo_buff(Agent, Buff).