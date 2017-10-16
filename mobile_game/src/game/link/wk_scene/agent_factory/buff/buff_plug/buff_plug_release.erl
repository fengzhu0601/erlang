%%%-------------------------------------------------------------------
%%% @author hank
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 09. Mar 2016 5:06 PM
%%%-------------------------------------------------------------------
-module(buff_plug_release).
-author("hank").

%% API
-export([apply/2,
    add/3,
    remove/2,
    replace/4,
    overlap/5]).

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


apply(#buff_cfg{id = _ID, time = Time, pile = Pile} = _Buff, #agent{} = Agent) ->
    ReleaseT = com_time:timestamp_msec() + Time,
    BuffInfo = #buff_state{buffType = ?BUFF_TYPE_EMIT, buffTime = ReleaseT},
    case buff_state:is_state(Agent, ?BUFF_TYPE_EMIT) of
        true ->
            if
                Pile >= 0 ->
                    buff_state:buff_overlap(Agent, BuffInfo, Pile, _Buff, ?MODULE);
                true -> ok %不是替换
            end;
        _ -> buff_state:buff_add(Agent, BuffInfo, _Buff, ?MODULE)
    end.

add(#agent{idx = Idx, attr = Attr} = Agent, #buff_state{} = NBuff, #buff_cfg{move_speed = Speed, time = Time} = _Buff) ->
    if
        Speed =/= 0 ->
            OSpeed = Attr#attr.move_speed,
            MySpeed = trunc(OSpeed + OSpeed * Speed / 1000),
            ORSpeed = Attr#attr.run_speed,
            MyRSpeed = trunc(ORSpeed + ORSpeed * Speed / 1000),
            ?INFO_LOG("get buff speed: ~p, time: ~p ", [MySpeed, Time]),
            buff_util:player_change_speed(Agent, MySpeed, MyRSpeed),
            TimeRef = scene_eng:start_timer(Time + 2000, ?MODULE, {recover_speed, Idx, OSpeed, ORSpeed}),
            NBuff#buff_state{ref = {TimeRef, OSpeed, ORSpeed}}; % 用于处理叠加效果的
        true -> NBuff
    end.

replace(_Agent, #buff_state{} = _OBuff, #buff_state{} = NBuff, #buff_cfg{} = _Buff) ->
    NBuff.

overlap(#agent{idx = Idx} = _Agent, #buff_state{buffTime = MyBuffTime, ref = Ref} = _OBuff,
        #buff_state{} = NBuff, #buff_cfg{time = Time, move_speed = Mspeed} = _Buff, Pile) ->
    if

        Mspeed =/= 0 ->
            {TimeRef, OSpeed, ORSpeed} = Ref,
            scene_eng:cancel_timer(TimeRef),
            Agent = ?get_agent(Idx),
            #agent{attr = Attr} = Agent,
            if
                Pile =:= 2 ->
                    OOSpeed = Attr#attr.move_speed,
                    MySpeed = trunc(OOSpeed + OOSpeed * Mspeed / 1000),
                    OORSpeed = Attr#attr.run_speed,
                    MyRSpeed = trunc(OORSpeed + OORSpeed * Mspeed / 1000),
                    ?INFO_LOG("get buff speed: ~p, time: ~p ", [MySpeed, Time]),
                    buff_util:player_change_speed(Agent, MySpeed, MyRSpeed),
                    NTimeRef = scene_eng:start_timer(Time, ?MODULE, {recover_speed, Idx, OSpeed, ORSpeed}),
                    NBuff#buff_state{ref = {NTimeRef, OSpeed, ORSpeed}};
                true ->  % 除了2 都视为时间叠加
                    NTimeRef = scene_eng:start_timer(Time, ?MODULE, {recover_speed, Idx, OSpeed, ORSpeed}),
                    NBuff#buff_state{ref = {NTimeRef, OSpeed, ORSpeed}}
            end;
        true -> NBuff
    end.

remove(_Agent, #buff_state{} = _OBuff) ->
    ok.


%恢复速度
handle_timer(_Ref, {recover_speed, Idx, OSpeed, ORSpeed}) ->
    case ?get_agent(Idx) of
        ?undefined -> ok;
        Agent ->
%%      NAgent = Agent#agent{ move_vec = MV},
            ?INFO_LOG("recover speed: ~p ", [OSpeed]),
            buff_util:player_change_speed(Agent, OSpeed, ORSpeed)
    end,
    ok.