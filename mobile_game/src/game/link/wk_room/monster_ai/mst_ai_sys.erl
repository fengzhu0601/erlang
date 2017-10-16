%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 10. 四月 2016 上午4:46
%%%-------------------------------------------------------------------
-module(mst_ai_sys).
-author("clark").

%% API
-export
([
    gearbox_callback/1,
    init/2,
    uninit/1,
    set_state/1,
    change_ai/2,
    recursion_ai/1,
    back_ai/0,
    is_mutex/1,
    is_mutex_auto_evaluate/1,
    is_next_segment/0,
    play_next_segment/0,
    get_ai_field/2,
    get_ai_field_by_cfg/2,
    get_monster_id/1,
    is_ai_pause/1,
    set_ai_pause/2
]).

-export
([
    on_recursion_ai/2
    , gearbox_callback_begin/1
    , gearbox_callback_end/1
    , on_ai_frame/1
]).

-include("mst_ai_sys.hrl").
-include("inc.hrl").
-include("scene_agent.hrl").
-include("lua_evt.hrl").


-define(make_ai_sign(Idx),              {npc_ai, Idx}).                 %% 规则器标志
-define(make_return_ai_stack(Idx),      {ai_stack,Idx}).                %% AI返回值
-define(make_ai_cfgkey(Idx),            {npc_ai_cfgkey, Idx}).          %% AI配置表
-define(make_ai_mutex_map,              '@ai_mutex_map@').              %% 互斥表
-define(make_ai_mutex_temp,             '@ai_mutex_temp@').             %% 互斥值
-define(make_ai_temp_data(Idx),         {npc_ai_temp_data, Idx}).       %% AI临时数据
-define(make_ai_lua_data(Idx),          {npc_ai_lua_data, Idx}).        %% AI_lua数据
-define(make_ai_monster_id(Idx),        {npc_ai_monster_id, Idx}).      %% AI_lua数据
-define(make_ai_monster_timer(Idx),     {npc_ai_monster_timer, Idx}).   %% AI_lua数据
-define(make_ai_runing(Idx),            {make_ai_runing, Idx}).         %% AI_lua数据


set_ai_pause(Idx, IsPause) ->
    util:set_pd_field(?make_ai_runing(Idx), IsPause).


is_ai_pause(Idx) ->
    util:get_pd_field(?make_ai_runing(Idx), true).


on_ai_frame(Idx) ->
    Ret = get(?make_ai_monster_timer(Idx)),
    timer_server:stop(Ret),
    NewRet = timer_server:start(1000, {?MODULE, on_ai_frame, [Idx]}),
    put(?make_ai_monster_timer(Idx), NewRet),

    mst_ai_lua:on_ai_evt(Idx, ?LUA_EVT_FRAME, []),
    ok.

init(Idx, MonsterId) ->
    set_ai_pause(Idx, true),
    ok = change_ai(Idx, MonsterId),
    LuaArgs = mst_ai_lua:get_monster_cfg(MonsterId),
    util:set_pd_field(?make_ai_lua_data(Idx), LuaArgs),
    util:set_pd_field(?make_ai_monster_id(Idx), MonsterId),
    mst_ai_lua:init_ai_part(Idx, MonsterId),

    Timer = timer_server:start(1000, {?MODULE, on_ai_frame, [Idx]}),
    put(?make_ai_monster_timer(Idx), Timer),

    set_ai_pause(Idx, true),
    ok.

uninit(Idx) ->
    mst_ai_lua:uninit_ai_part(Idx),
    porsche_gearbox:uninit( ?make_ai_sign(Idx) ),
    util:del_pd_field(?make_ai_lua_data(Idx)),
    util:del_pd_field(?make_ai_monster_id(Idx)),
    Timer = get(?make_ai_monster_timer(Idx)),
    timer_server:stop(Timer),
    util:del_pd_field(?make_ai_runing(Idx)),

    ok.

get_monster_id(Idx) ->
    util:get_pd_field(?make_ai_monster_id(Idx), 0).

get_ai_field(Idx, Key) ->
    case util:get_pd_field(?make_ai_lua_data(Idx), nil) of
        nil ->
            nil;

        LuaArgs ->
%%             ?INFO_LOG("get_ai_field ~p", [LuaArgs]),
            case lists:keyfind(Key, 1, LuaArgs) of
                false -> nil;
                {_, Val} -> Val
            end
    end.

get_ai_field_by_cfg(Idx, alert_radius) ->
    get_ai_field(Idx, <<"alertRadius">>);
get_ai_field_by_cfg(Idx, stroll_radius) ->
    get_ai_field(Idx, <<"strollRadius">>);
get_ai_field_by_cfg(Idx, chase_radius) ->
    get_ai_field(Idx, <<"chaseRadius">>);
get_ai_field_by_cfg(Idx, chase_speed) ->
    get_ai_field(Idx, <<"chaseSpeed">>);
get_ai_field_by_cfg(Idx, rand_skill) ->
    MonsterId = mst_ai_sys:get_monster_id(Idx),
    {Segment, Skill} = mst_ai_lua:get_monster_rand_skill(MonsterId),
    {Segment, Skill};
get_ai_field_by_cfg(_Idx, _Key) ->
    ?INFO_LOG("why get_ai_field_by_cfg ~p", [{_Idx, _Key}]),
    nil.



change_ai(Idx, CfgKey) ->
    change_ai(Idx, CfgKey, 1).

change_ai(Idx, _CfgKey, StateId) ->
    CfgKey =
        if
            _CfgKey == attack -> attack;
            _CfgKey == talking -> talking;
            true -> common
        end,
    case ?get_agent(Idx) of
        A when is_record(A, agent) ->
%%             ?INFO_LOG("--------------- change_ai ----------- ~p", [{Idx, CfgKey, StateId}]),
            porsche_gearbox:uninit(?make_ai_sign(Idx)),
            Charts = load_rule_chart:get_ai_states(CfgKey),
            porsche_gearbox:init( ?make_ai_sign(Idx), Charts, fun mst_ai_sys:gearbox_callback/1, StateId ),
            evt_util:sub( #rule_callback_begine{}, fun mst_ai_sys:gearbox_callback_begin/1 ),
            evt_util:sub( #rule_callback_end{}, fun mst_ai_sys:gearbox_callback_end/1 ),
            util:set_pd_field(?make_ai_cfgkey(Idx), CfgKey);

        _ ->
            pass
    end,
    ok.

recursion_ai({{AICfgKey, StateId, UserData}, ReturnStateId}) ->
    Idx = get_cur_idx(),
    case ?get_agent(Idx) of
        A when is_record(A, agent) ->
            timer_server:start(0, {mst_ai_sys, on_recursion_ai, [{Idx, AICfgKey, StateId, UserData}, ReturnStateId]});

        _ ->
            pass
    end,
    ok.

on_recursion_ai({Idx, CfgKey, StateId, UserData}, ReturnStateId) ->
    case ?get_agent(Idx) of
        A when is_record(A, agent) ->
            util:set_pd_field(?make_ai_temp_data(Idx), UserData),
            CurAiCfgKey = util:get_pd_field(?make_ai_cfgkey(Idx), nil),
            ok = change_ai(Idx, CfgKey, StateId),
            AiList = util:get_pd_field(?make_return_ai_stack(Idx), []),
            AiList1 = [{CurAiCfgKey, ReturnStateId} | AiList],
            util:set_pd_field(?make_return_ai_stack(Idx), AiList1);

        _ ->
            pass
    end,
    ok.

is_next_segment() ->
    Idx = get_cur_idx(),
    case ?get_agent(Idx) of
        A when is_record(A, agent) ->
            {SkillId, Index} = util:get_pd_field(?make_ai_temp_data(Idx), {0,0}),
            case load_cfg_skill:get_segments_by_skillid(SkillId, Index+1) of
                nil ->
%%                     ?INFO_LOG("is_next_segment false"),
                    false;

                _SegmentId ->
%%                     ?INFO_LOG("is_next_segment true"),
                    true
            end;

        _ ->
%%             ?INFO_LOG("is_next_segment false"),
            false
    end.

play_next_segment() ->
    Idx = get_cur_idx(),
    case ?get_agent(Idx) of
        A when is_record(A, agent) ->
            {SkillId, Index} = util:get_pd_field(?make_ai_temp_data(Idx), {0,0}),
            case load_cfg_skill:get_segments_by_skillid(SkillId, Index+1) of
                nil ->
                    nil;

                SegmentId ->
%%                     ?INFO_LOG("play_next_segment ~p", [SegmentId]),
                    util:set_pd_field(?make_ai_temp_data(Idx), {SkillId, Index+1}),
                    mst_ai_plug:skill_segment(SegmentId)
            end;

        _ ->
            pass
    end,
    ok.


back_ai() ->
    Idx = get_cur_idx(),
    case ?get_agent(Idx) of
        A when is_record(A, agent) ->
            case util:get_pd_field(?make_return_ai_stack(Idx), []) of
                [{AiCfgKey, StateId}|AiList] ->
%%                     ?INFO_LOG("back_ai ~p", [{Idx, StateId}]),
                    util:set_pd_field(?make_return_ai_stack(Idx), AiList),
                    ok = change_ai(Idx, AiCfgKey, StateId),
                    ok;

                _ ->
                    ok
            end;

        _ ->
            pass
    end,
    ok.


set_state({Dt, Id}) ->
    if
        Dt > 0 -> porsche_gearbox:set_state(porsche_gearbox:get_cur_porschekey(), Id, Dt);
        true -> porsche_gearbox:set_state(porsche_gearbox:get_cur_porschekey(), Id)
    end,
    ok.

gearbox_callback_begin(#rule_callback_begine{gearbox_id=PorscheKey}) ->
    case porsche_gearbox:get_cur_porschekey() of
        PorscheKey ->
            util:set_pd_field(?make_ai_mutex_map, []),
%%             ?INFO_LOG("begin ai =========================="),
            ok;

        _ ->
            pass
    end,
    ok.

gearbox_callback_end(#rule_callback_end{gearbox_id=PorscheKey}) ->
    case porsche_gearbox:get_cur_porschekey() of
        PorscheKey ->
            MutexList = util:get_pd_field(?make_ai_mutex_map, []),
            lists:foreach
            (
                fun({_Id, _Val, {FunKey, IsOverTime, TrueDo}}) ->
                    do_funckey(FunKey, IsOverTime, TrueDo)
                end,
                MutexList
            ),
            util:set_pd_field(?make_ai_mutex_map, []),
%%             ?INFO_LOG("end ai =========================="),
            ok;

        _ ->
            pass
    end,
    ok.

gearbox_callback({Can, TrueDo, FalseDo}) ->
    Idx = get_cur_idx(),
    case pl_util:is_dizzy(Idx) of
        ok ->
            pass;

        _ ->
            %% must
            ok = porsche_gearbox:evt_do(TrueDo, ?ai_cfg_must, false),

            IsActive =
                case porsche_gearbox:get_cur_evtargs() of
                    nil ->
                        false;

                    #agent_move_over{idx=IdxArgs} ->
                        Idx = get_cur_idx(),
                        if
                            IdxArgs == Idx -> true;
                            true -> false
                        end;

                    #agent_relaxation{idx=IdxArgs} ->
                        if
                            IdxArgs == Idx -> true;
                            true -> false
                        end;

                    _ ->
                        true
                end,

            if
                IsActive ->
                    %% 条件
%%                     ?INFO_LOG("Can ~p ", [Can]),
                    case porsche_gearbox:evt_can(Can, ?ai_cfg_can, false) of
                        true ->
                            %% 动作
                            FunKey = porsche_gearbox:get_cur_funckey(),
                            IsOverTime = porsche_gearbox:is_over_times(),
                            util:set_pd_field(?make_ai_mutex_temp, nil),
                            case porsche_gearbox:evt_any(Can, ?ai_cfg_mutex, false) of
                                true ->
                                    handle_mutex({FunKey, IsOverTime, TrueDo});

                                _ ->
                                    do_funckey(FunKey, IsOverTime, TrueDo)
                            end,
                            ok;

                        _ ->
                            ok = porsche_gearbox:evt_do(FalseDo, ?ai_cfg_do, false),
                            ret:error(cant)
                    end;

                true ->
                    pass
            end
    end.





do_funckey(FunKey, IsOverTime, TrueDo) ->
    ok = porsche_gearbox:evt_do(TrueDo, ?ai_cfg_do, false),
    if
        IsOverTime ->
%%             ?INFO_LOG("s do_funckey ~p", [{FunKey, TrueDo}]),
            porsche_gearbox:add_func_times(FunKey),
%%             ?INFO_LOG("e do_funckey"),
            ok = porsche_gearbox:evt_do(TrueDo, ?ai_cfg_done, false);


        true ->
            pass
    end,
    ok.

is_mutex({MutexId, Value}) ->
    util:set_pd_field(?make_ai_mutex_temp, {MutexId, Value}),
    true.

is_mutex_auto_evaluate({MutexId, Type}) ->
    Value = situation_calculate:calculate(Type, get_cur_idx()),
    util:set_pd_field(?make_ai_mutex_temp, {MutexId, Value}),
    true.

handle_mutex({FunKey, IsOverTime, TrueDo}) ->
    case util:get_pd_field(?make_ai_mutex_temp, nil) of
        {MutexId, Value} ->
%%             ?INFO_LOG("handle_mutex ~p ", [{MutexId, Value}]),
            MutexList = util:get_pd_field(?make_ai_mutex_map, []),
            IsAdd =
                case lists:keyfind(MutexId, 1, MutexList) of
                    false ->
                        true;

                    {_Id, OldValue, _Callback} ->
                        if
                            Value > OldValue ->
                                true;

                            Value < OldValue ->
                                false;

                            true ->
                                Rand = com_util:random(0, 100),
                                if
                                    Rand >= 50 -> true;
                                    true -> false
                                end
                        end
                end,
            if
                IsAdd ->
%%                     ?INFO_LOG("handle_mutex IsAdd ~p ", [{MutexId, Value}]),
                    MutexList1 = lists:keystore(MutexId, 1, MutexList, {MutexId, Value, {FunKey, IsOverTime, TrueDo}}),
                    util:set_pd_field(?make_ai_mutex_map, MutexList1),
                    util:set_pd_field(?make_ai_mutex_temp, MutexId),
                    true;

                true ->
%%                     ?INFO_LOG("handle_mutex IsAdd ~p", [false]),
                    false
            end;


        _ ->
            pass
    end,
    ok.



get_cur_idx() ->
    {_, IdxSrc} = porsche_gearbox:get_cur_porschekey(),
    if
        IdxSrc == nil -> 0;
        true -> IdxSrc
    end.



