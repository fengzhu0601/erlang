%%%-------------------------------------------------------------------
%%% @author hank
%%% @copyright (C) 2016, <COMPANY>
%%% @doc  buff 属性值加值 模块 这里只处理加血加蓝
%%%
%%% @end
%%% Created : 04. Mar 2016 5:36 PM
%%%-------------------------------------------------------------------
-module(buff_plug_addattr).
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

% 属性加值应用
apply(#agent{idx = AIdx} = AAgent, #agent{idx = BIdx, buff_states = BuffState}, _Target, #buff_cfg{id = BuffId, time = Time, interval = Interval, attrs = Attrs} = Buff, {time, NowTime}) ->
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
    Ref = scene_eng:start_timer(Time, ?MODULE, {remove_halo_buff, NewBAgent, {BuffId, halo_buff, NowTime}}),
    FinalBuffState = NewBuffState ++ [{{BuffId, halo_buff, NowTime}, AIdx, com_time:now() + Time div 1000, [Ref], []}],
    ?update_agent(BIdx, NewBAgent#agent{buff_states = FinalBuffState}),
    Ret = case Attrs of
        [{?PL_ATTR_HP, _}] ->
            case get({last_halo_add_hp_time, BIdx}) of
                undefined ->
                    {true, {last_halo_add_hp_time, BIdx}};
                LastTime -> 
                    case com_time:now() - LastTime >= Interval div 1000 of
                        true -> {true, {last_halo_add_hp_time, BIdx}};
                        _ -> false
                    end
            end;
        [{?PL_ATTR_MP, _}] ->
            case get({last_halo_add_mp_time, BIdx}) of
                undefined ->
                    {true, {last_halo_add_mp_time, BIdx}};
                LastTime ->
                    case com_time:now() - LastTime >= Interval div 1000 of
                        true -> {true, {last_halo_add_mp_time, BIdx}};
                        _ -> false
                    end
            end;
        _ ->
            false
    end,
    case Ret of
        {true, Atom} ->
            add_buff(AAgent, NewBAgent#agent{buff_states = FinalBuffState}, Buff#buff_cfg{interval = Time}),
            put(Atom, com_time:now());
        _ ->
            pass
    end;
apply(#agent{idx = AIdx} = AAgent, BAgent, _Target, #buff_cfg{id = BuffId, time = Time} = Buff, _ExtInfo) ->
    BuffAgent = buff_system:get_real_buff_agent(BAgent),
    #agent{idx = BIdx, buff_states = BuffState} = BuffAgent,
    case lists:keyfind(BuffId, 1, BuffState) of
        {BuffId, _, _, RefList, _} ->
            [scene_eng:cancel_timer(Ref) || Ref <- RefList],
            NewRef = scene_eng:start_timer(Time, ?MODULE, {remove_buff, BuffAgent, BuffId}),
            NewBuffState = lists:keyreplace(BuffId, 1, BuffState, {BuffId, AIdx, com_time:now() + Time div 1000, [NewRef], []}),
            ?update_agent(BIdx, BuffAgent#agent{buff_states = NewBuffState}),
            add_buff(AAgent, BuffAgent#agent{buff_states = NewBuffState}, Buff);
        _ ->
            buff_system:send_buff2client(BuffAgent, BuffId, Time),
            Ref = scene_eng:start_timer(Time, ?MODULE, {remove_buff, BuffAgent, BuffId}),
            NewBuffState = BuffState ++ [{BuffId, AIdx, com_time:now() + Time div 1000, [Ref], []}],
            ?update_agent(BIdx, BuffAgent#agent{buff_states = NewBuffState}),
            add_buff(AAgent, BuffAgent#agent{buff_states = NewBuffState}, Buff)
    end,
    ok.

add_buff(#agent{idx = _AIdx, attr = Attr} = AAgent, #agent{idx = BIdx, max_hp = BMaxHp, max_mp = BMaxMp} = BAgent, #buff_cfg{id = BuffId, time = Time, interval = Interval, prop_type = PropType, attr_type = AttrType, attrs = Attrs, convert_trage = CT}) ->
    AttackIdx = case AAgent#agent.type of
        ?agent_skill_obj ->
            AAgent#agent.fidx;
        _ ->
            AAgent#agent.idx
    end,
    lists:foreach(
        fun({AttrId, Value}) ->
                case AttrId of
                    ?PL_ATTR_HP ->
                        AddHp = case AttrType of
                            1 ->
                                case CT of
                                    2 ->    %% 宠物主动技能修改集buff
                                        trunc((element(PropType - 8, Attr)) * Value / 1000);
                                    _ ->
                                        trunc(BMaxHp * Value / 1000)
                                end;
                            _ ->
                                Value
                        end,
                        case Interval of
                            0 ->
                                buff_util:player_change_hp(BAgent, AddHp);
                            _ ->
                                Times = max(1, trunc(Time / Interval)),
                                buff_util:handle_timer(0, {change_hp, BIdx, AttackIdx, BuffId, AddHp, Interval, Times})
                        end;
                    ?PL_ATTR_MP ->
                        AddMp = case AttrType of
                            1 ->
                                case CT of
                                    2 ->    %% 宠物主动技能修改集buff
                                        trunc((element(PropType - 8, Attr)) * Value / 1000);
                                    _ ->
                                        trunc(BMaxMp * Value / 1000)
                                end;
                            _ ->
                                Value
                        end,
                        case Interval of
                            0 ->
                                buff_util:player_change_mp(BAgent, AddMp);
                            _ ->
                                Times = max(1, trunc(Time / Interval)),
                                buff_util:handle_timer(0, {change_mp, BIdx, AttackIdx, BuffId, AddMp, Interval, Times})
                        end;
                    _ ->
                        ?ERROR_LOG("error type to add attr:~p", [{BuffId, AttrId}])
                end
        end,
        Attrs
    ).

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

remove_halo_buff(#agent{idx = Idx} = Agent, {BuffId, halo_buff, _NowTime} = Buff) ->
    buff_system:cancel_buff2client(Agent, BuffId),
    case ?get_agent(Idx) of
        ?undefined ->
            ignore;
        NewAgent ->
            BuffState = NewAgent#agent.buff_states,
            case lists:keyfind(Buff, 1, BuffState) of
                {Buff, _, _, _, _} ->
                    NewBuffState = lists:keydelete(Buff, 1, BuffState),
                    ?update_agent(Idx, NewAgent#agent{buff_states = NewBuffState});
                _ ->
                    pass
            end
    end,
    ok.

delete_halo_buff(Idx, BuffId, RefList, _ChangeData) ->
    [scene_eng:cancel_timer(Ref) || Ref <- RefList],
    case ?get_agent(Idx) of
        ?undefined ->
            ignore;
        NewAgent ->
            buff_system:cancel_buff2client(NewAgent, BuffId)
    end.

handle_timer(_Ref, {remove_buff, Agent, BuffId}) ->
    remove_buff(Agent, BuffId);
handle_timer(_Ref, {remove_halo_buff, Agent, Buff}) ->
    remove_halo_buff(Agent, Buff).