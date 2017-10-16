%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 10. 十一月 2015 下午3:38
%%%-------------------------------------------------------------------
-module(pl_fsm).
-author("clark").


%% API
-export
([
    build_plug/1
    , can_set_state/2
    , set_state/2
    , on_event/2
]).



-include("skill_struct.hrl").
-include("load_spirit_attr.hrl").
-include("inc.hrl").
-include("scene.hrl").
-include("scene_agent.hrl").

on_event(Agent, Event) ->
    PlugList = Agent#agent.pl_cur_state_plugs,
    Ret =
        lists:foldl
        (
            fun
                (Plug, Ret) ->
                    case Ret of
                        ok ->
                            ok;
                        _Other ->
                            Plug:on_event(Agent, Event)
                    end
            end,
            none,
            PlugList
        ),
    Ret.

can_set_state(Agent, NewPlugList) ->
    PlugList = Agent#agent.pl_cur_state_plugs,
    Ret =
        lists:foldl
        (
            fun
                (Plug, Ret) ->
                    case Ret of
                        ok ->
                            %% 是否充许中断
                            Plug:can_interrupt(Agent, NewPlugList);
                        Other ->
                            Other
                    end
            end,
            ret:ok(),
            PlugList
        ),
    case Ret of
        ok ->
            Ret1 = lists:foldl
            (
                fun
                    ({Plug, TPar}, Ret) ->
                        case Ret of
                            ok ->
                                %% 是否充许开始
                                % %% 先处理buff状态
                                % case buff_system:can_start_plug_state(Agent, Plug,TPar) of
                                %     ok -> Plug:can_start(Agent, TPar);
                                %     OtherState -> OtherState
                                % end;
                               Plug:can_start(Agent, TPar);
                            Other1 ->
                                Other1
                        end
                end,
                ret:ok(),
                NewPlugList
            ),
            Ret1;
        Other ->
            Other
    end.

set_state(Agent = #agent{idx = undefined}, _NewPlugList) ->
    Agent;
set_state(Agent = #agent{idx = Idx}, NewPlugList) ->
    if
        Idx =< 0 -> move_tgr_util:stop_all_move_tgr(Agent);
        true -> pass
    end,

    % PlugsList = Agent#agent.pl_cur_state_plugs,
    % Agent2 =
    %     lists:foldl
    %     (
    %         fun
    %             (Plug, Agent1) ->
    %                 Plug:stop(Agent1)
    %         end,
    %         Agent,
    %         PlugsList
    %     ),

    {Agent5, _} =
        lists:foldl
        (
            fun
                ({Plug, TPar}, {Agent3, Ret}) ->
                    Agent4 = Plug:start(Agent3, TPar),
                    {Agent4, [Plug | Ret]}
            end,
            {Agent, []},
            NewPlugList
        ),

    {Agent8, PlugsList1} =
        lists:foldl
        (
            fun
                ({Plug, TPar}, {Agent6, Ret}) ->
                    Agent7 = Plug:run(Agent6, TPar),
                    {Agent7, [Plug | Ret]}
            end,
            {Agent5, []},
            NewPlugList
        ),

    Agent9 = Agent8#agent{pl_cur_state_plugs = PlugsList1},
    ?update_agent(Idx, Agent9),
    Agent9.


build_plug(PlugSign) ->
    case PlugSign of
        ?pl_attack -> plug_attack;
        ?pl_ba_ti -> plug_ba_ti;
        ?pl_be_attacked -> plug_be_attack;
        ?pl_beat_back -> plug_beat_back;
        ?pl_beat_fly -> plug_beat_fly;
        ?pl_beat_up -> plug_beat_up;
        ?pl_dead -> plug_dead;
        ?pl_jumping -> plug_jumping;
        ?pl_moving -> plug_moving;
        ?pl_path_teleport -> plug_path_teleport;
        ?pl_rush -> plug_rush;
        ?pl_stiff -> plug_stiff;
        ?pl_beat_horizontal -> plug_beat_horizontal;
        ?pl_beat_vertical -> plug_beat_vertical;
        ?pl_bullet_attack_area -> bullet_attack_area;
        ?pl_wait_for_moving -> plug_wait_for_moving;
        ?pl_dizzy -> plug_dizzy;
        _ -> unknow_state_plug
    end.



