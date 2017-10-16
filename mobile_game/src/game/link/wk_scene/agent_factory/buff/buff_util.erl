%%%-------------------------------------------------------------------
%%% @author hank
%%% @copyright (C) 2016, <COMPANY>
%%% @doc  buff的处理
%%%
%%% @end
%%% Created : 03. Mar 2016 3:46 PM
%%%-------------------------------------------------------------------
-module(buff_util).
-author("hank").

%% API
-export([
    get_random_num/1,
    player_change_speed/3,
    player_change_hp/4,
    player_change_mp/2,
    player_change_anger/2,
    change_agent_attrs/3,
    get_attr_value/2,
    change_attr/3,
    conver_attr/3
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
-include("porsche_event.hrl").

-spec get_random_num(integer()) -> integer().
get_random_num(Max) ->
    <<A:32, B:32, C:32>> = crypto:rand_bytes(12),
    random:seed({A, B, C}),
    random:uniform(Max).

% 加血
handle_timer(_Ref, {change_hp, BIdx, AIdx, BuffId, AddHp, Inter, Times}) ->
    case ?get_agent(BIdx) of
        ?undefined ->
            ignore;
        #agent{state = ?st_die} -> ok;
        #agent{} = A ->
            case Times > 0 of
                true ->
                    buff_util:player_change_hp(A, AIdx, BuffId, AddHp),
                    Ref = scene_eng:start_timer(Inter, ?MODULE, {change_hp, BIdx, AIdx, BuffId, AddHp, Inter, Times - 1}),
                    save_buff_ref(BIdx, BuffId, Ref);
                _ ->
                    ok
            end
    end;

% 加蓝
handle_timer(_Ref, {change_mp, BIdx, AIdx, BuffId, AddMp, Inter, Times}) ->
    case ?get_agent(BIdx) of
        ?undefined ->
            ignore;
        #agent{state = ?st_die} -> ok;
        #agent{} = A ->
            case Times > 0 of
                true ->
                    buff_util:player_change_mp(A, AddMp),
                    Ref = scene_eng:start_timer(Inter, ?MODULE, {change_mp, BIdx, AIdx, BuffId, AddMp, Inter, Times - 1}),
                    save_buff_ref(BIdx, BuffId, Ref);
                _ ->
                    ok
            end
    end.

save_buff_ref(Idx, BuffId, Ref) ->
    case ?get_agent(Idx) of
        ?undefined ->
            ignore;
        #agent{buff_states = BuffState} = A ->
            NewBuffState = case lists:keyfind(BuffId, 1, BuffState) of
                {BuffId, AIdx, EndTime, [BuffRef], Data} ->
                    lists:keyreplace(BuffId, 1, BuffState, {BuffId, AIdx, EndTime, [BuffRef, Ref], Data});
                {BuffId, AIdx, EndTime, [BuffRef, _OldRef], Data} ->
                    lists:keyreplace(BuffId, 1, BuffState, {BuffId, AIdx, EndTime, [BuffRef, Ref], Data});
                _ ->
                    BuffState
            end,
            ?update_agent(Idx, A#agent{buff_states = NewBuffState})
    end.

player_change_speed(#agent{idx = _Idx} = Agent, NewSpeed, NewRSpd) ->
    Agent1 = change_agent_attr(Agent, ?PL_ATTR_MOVE_SPEED, NewSpeed),
    change_agent_attr(Agent1, ?PL_ATTR_RUN_SPEED, NewRSpd).

player_change_hp(#agent{idx = Idx, max_hp = FullHp, hp = OHp} = A, AttackIdx, BuffId, AddHp) ->
    NewHp = min(max(0, trunc(AddHp + OHp)), FullHp),
    Buff = load_cfg_buff:lookup_buff_cfg(BuffId),
    if
        NewHp =< 0 ->
            ?update_agent(Idx, A#agent{hp = 0}),
            scene_player:is_notify_teammate(A#agent{hp = 0}),
            case ?get_agent(AttackIdx) of
                #agent{} = Attacker ->
                    case Buff#buff_cfg.type of
                        5 ->
                            map_aoi:broadcast_view_me_agnets_and_me(A, scene_sproto:pkg_msg(?MSG_SCENE_BUFF_DAMAGE, {Idx, AddHp, 0}));
                        _ ->
                            ignore
                    end,
                    case Idx > 0 of
                        true ->
                            evt_util:send(#player_die{killer = Attacker, die = A#agent{hp = 0}});
                        _ ->
                            map_aoi:broadcast_view_me_agnets_and_me(A, scene_sproto:pkg_msg(?MSG_SCENE_AGENT_DATA_CHANGE, {Idx, ?PL_HP, 0})),
                            evt_util:send(#monster_die{killer = Attacker, die = A#agent{hp = 0}})
                            % case AttackIdx > 0 of
                            %     true -> ?send_mod_msg(Attacker#agent.pid, player_mng, {team_fuben_kill_monster, A#agent.id});
                            %     _ -> pass
                            % end
                    end,
                    map_agent:on_agent_die(A#agent{hp = 0}, Attacker);
                _ ->
                    case Idx < 0 of
                        true ->
                            case Buff#buff_cfg.type of
                                5 ->
                                    map_aoi:broadcast_view_me_agnets_and_me(A, scene_sproto:pkg_msg(?MSG_SCENE_BUFF_DAMAGE, {Idx, AddHp, 0}));
                                _ ->
                                    ignore
                            end,
                            scene_monster:die(Idx),
                            evt_util:send(#monster_die{killer = ?undefined, die = A});
                        _ ->
                            case Buff#buff_cfg.type of
                                5 ->
                                    map_aoi:broadcast_view_me_agnets_and_me(A, scene_sproto:pkg_msg(?MSG_SCENE_BUFF_DAMAGE, {Idx, AddHp, 0}));
                                _ ->
                                    map_aoi:broadcast_view_me_agnets_and_me(A, scene_sproto:pkg_msg(?MSG_SCENE_AGENT_DATA_CHANGE, {Idx, ?PL_HP, 0}))
                            end
                    end
            end;
        NewHp >= FullHp ->
            ?update_agent(Idx, A#agent{hp = FullHp}),
            scene_player:is_notify_teammate(A#agent{hp = FullHp}),
            case Buff#buff_cfg.type of
                5 ->
                    map_aoi:broadcast_view_me_agnets_and_me(A, scene_sproto:pkg_msg(?MSG_SCENE_BUFF_DAMAGE, {Idx, AddHp, FullHp}));
                _ ->
                    map_aoi:broadcast_view_me_agnets_and_me(A, scene_sproto:pkg_msg(?MSG_SCENE_AGENT_DATA_CHANGE, {Idx, ?PL_HP, FullHp}))
            end;
        true ->
            ?update_agent(Idx, A#agent{hp = NewHp}),
            scene_player:is_notify_teammate(A#agent{hp = NewHp}),
            case Buff#buff_cfg.type of
                5 ->
                    map_aoi:broadcast_view_me_agnets_and_me(A, scene_sproto:pkg_msg(?MSG_SCENE_BUFF_DAMAGE, {Idx, AddHp, NewHp}));
                _ ->
                    map_aoi:broadcast_view_me_agnets_and_me(A, scene_sproto:pkg_msg(?MSG_SCENE_AGENT_DATA_CHANGE, {Idx, ?PL_HP, NewHp}))
            end
    end.


player_change_mp(#agent{idx = Idx, pid = Pid, max_mp = FullMp, mp = OMp} = A, AddMp) ->
    NewMp = min(FullMp, trunc(AddMp + OMp)),
    ?update_agent(Idx, A#agent{mp = NewMp}),
    ?ifdo(Idx > 0, ?send_to_client(Pid, scene_sproto:pkg_msg(?MSG_SCENE_AGENT_DATA_CHANGE, {Idx, ?PL_MP, NewMp}))).

player_change_anger(#agent{idx = Idx, pid = Pid, anger_value = AngerValue, max_anger_value = MaxAngerValue} = A, AddValue) ->
    NewAngerValue = min(AngerValue + AddValue, MaxAngerValue),
    ?update_agent(Idx, A#agent{anger_value = NewAngerValue}),
    ?ifdo(Idx > 0, ?send_to_client(Pid, crown_sproto:pkg_msg(?MSG_CROWN_ANGER_CHANGE, {NewAngerValue}))).

get_attr_value(Agent, AttrId) ->
    if
        AttrId =:= ?PL_ATTR_HP ->
            Agent#agent.hp;
        AttrId =:= ?PL_ATTR_MP ->
            Agent#agent.mp;
        AttrId =:= ?PL_ATTR_SP ->
            Agent#agent.attr#attr.sp;
        AttrId =:= ?PL_ATTR_NP ->
            Agent#agent.attr#attr.hp;
        AttrId =:= ?PL_ATTR_STRENGTH ->
            Agent#agent.attr#attr.strength;  %%力量
        AttrId =:= ?PL_ATTR_INTELLECT ->
            Agent#agent.attr#attr.intellect;  %%智力
        AttrId =:= ?PL_ATTR_NIMBLE ->
            Agent#agent.attr#attr.nimble;  %%敏捷
        AttrId =:= ?PL_ATTR_STRONG ->
            Agent#agent.attr#attr.strong;  %%体质
        AttrId =:= ?PL_ATTR_ATK ->
            Agent#agent.attr#attr.atk;  %%攻击
        AttrId =:= ?PL_ATTR_DEF ->
            Agent#agent.attr#attr.def;  %%防御
        AttrId =:= ?PL_ATTR_CRIT ->
            Agent#agent.attr#attr.crit;  %%暴击
        AttrId =:= ?PL_ATTR_BLOCK ->
            Agent#agent.attr#attr.block;   %%格挡
        AttrId =:= ?PL_ATTR_PLIABLE ->
            Agent#agent.attr#attr.pliable;   %%柔韧
        AttrId =:= ?PL_ATTR_PURE_ATK ->
            Agent#agent.attr#attr.pure_atk;  %%无视防御伤害
        AttrId =:= ?PL_ATTR_BREAK_DEF ->
            Agent#agent.attr#attr.break_def;  %%破甲
        AttrId =:= ?PL_ATTR_ATK_DEEP ->
            Agent#agent.attr#attr.atk_deep;  %%伤害加深
        AttrId =:= ?PL_ATTR_ATK_FREE ->
            Agent#agent.attr#attr.atk_free;  %%伤害减免
        AttrId =:= ?PL_ATTR_ATK_SPEED ->
            Agent#agent.attr#attr.atk_speed;  %%攻击速度
        AttrId =:= ?PL_ATTR_PRECISE ->
            Agent#agent.attr#attr.precise;   %%精确
        AttrId =:= ?PL_ATTR_THUNDER_ATK ->
            Agent#agent.attr#attr.thunder_atk;   %%雷公
        AttrId =:= ?PL_ATTR_THUNDER_DEF ->
            Agent#agent.attr#attr.thunder_def;   %%雷放
        AttrId =:= ?PL_ATTR_FIRE_ATK ->
            Agent#agent.attr#attr.fire_atk;   %%火攻
        AttrId =:= ?PL_ATTR_FIRE_DEF ->
            Agent#agent.attr#attr.fire_def;   %%火访
        AttrId =:= ?PL_ATTR_ICE_ATK ->
            Agent#agent.attr#attr.ice_atk;  %%冰攻
        AttrId =:= ?PL_ATTR_ICE_DEF ->
            Agent#agent.attr#attr.ice_def;  %%冰防
        AttrId =:= ?PL_ATTR_MOVE_SPEED ->
            Agent#agent.attr#attr.move_speed; %%移动速度
        AttrId =:= ?PL_ATTR_RUN_SPEED ->
            Agent#agent.attr#attr.run_speed; %%移动速度
        true ->
            0
    end.

conver_attr(Agent, OAgent, AttrId) ->
    if
        AttrId =:= ?PL_ATTR_HP ->
            Agent#agent{hp = OAgent#agent.hp};
        AttrId =:= ?PL_ATTR_MP ->
            Agent#agent{mp = OAgent#agent.mp};
        AttrId =:= ?PL_ATTR_SP ->
            Agent#agent{attr = Agent#agent.attr#attr{sp = OAgent#agent.attr#attr.sp}};
        AttrId =:= ?PL_ATTR_NP ->
            Agent#agent{attr = Agent#agent.attr#attr{np = OAgent#agent.attr#attr.hp}};
        AttrId =:= ?PL_ATTR_STRENGTH ->
            Agent#agent{attr = Agent#agent.attr#attr{strength = OAgent#agent.attr#attr.strength}}; %%力量
        AttrId =:= ?PL_ATTR_INTELLECT ->
            Agent#agent{attr = Agent#agent.attr#attr{intellect = OAgent#agent.attr#attr.intellect}}; %%智力
        AttrId =:= ?PL_ATTR_NIMBLE ->
            Agent#agent{attr = Agent#agent.attr#attr{nimble = OAgent#agent.attr#attr.nimble}};%%敏捷
        AttrId =:= ?PL_ATTR_STRONG ->
            Agent#agent{attr = Agent#agent.attr#attr{strong = OAgent#agent.attr#attr.strong}}; %%体质
        AttrId =:= ?PL_ATTR_ATK ->
            Agent#agent{attr = Agent#agent.attr#attr{atk = OAgent#agent.attr#attr.atk}}; %%攻击
        AttrId =:= ?PL_ATTR_DEF ->
            Agent#agent{attr = Agent#agent.attr#attr{def = OAgent#agent.attr#attr.def}}; %%防御
        AttrId =:= ?PL_ATTR_CRIT ->
            Agent#agent{attr = Agent#agent.attr#attr{crit = OAgent#agent.attr#attr.crit}}; %%暴击
        AttrId =:= ?PL_ATTR_BLOCK ->
            Agent#agent{attr = Agent#agent.attr#attr{block = OAgent#agent.attr#attr.block}};  %%格挡
        AttrId =:= ?PL_ATTR_PLIABLE ->
            Agent#agent{attr = Agent#agent.attr#attr{pliable = OAgent#agent.attr#attr.pliable}};  %%柔韧
        AttrId =:= ?PL_ATTR_PURE_ATK ->
            Agent#agent{attr = Agent#agent.attr#attr{pure_atk = OAgent#agent.attr#attr.pure_atk}}; %%无视防御伤害
        AttrId =:= ?PL_ATTR_BREAK_DEF ->
            Agent#agent{attr = Agent#agent.attr#attr{break_def = OAgent#agent.attr#attr.break_def}}; %%破甲
        AttrId =:= ?PL_ATTR_ATK_DEEP ->
            Agent#agent{attr = Agent#agent.attr#attr{atk_deep = OAgent#agent.attr#attr.atk_deep}}; %%伤害加深
        AttrId =:= ?PL_ATTR_ATK_FREE ->
            Agent#agent{attr = Agent#agent.attr#attr{atk_free = OAgent#agent.attr#attr.atk_free}}; %%伤害减免
        AttrId =:= ?PL_ATTR_ATK_SPEED ->
            Agent#agent{attr = Agent#agent.attr#attr{atk_speed = OAgent#agent.attr#attr.atk_speed}}; %%攻击速度
        AttrId =:= ?PL_ATTR_PRECISE ->
            Agent#agent{attr = Agent#agent.attr#attr{precise = OAgent#agent.attr#attr.precise}};  %%精确
        AttrId =:= ?PL_ATTR_THUNDER_ATK ->
            Agent#agent{attr = Agent#agent.attr#attr{thunder_atk = OAgent#agent.attr#attr.thunder_atk}};  %%雷公
        AttrId =:= ?PL_ATTR_THUNDER_DEF ->
            Agent#agent{attr = Agent#agent.attr#attr{thunder_def = OAgent#agent.attr#attr.thunder_def}};  %%雷放
        AttrId =:= ?PL_ATTR_FIRE_ATK ->
            Agent#agent{attr = Agent#agent.attr#attr{fire_atk = OAgent#agent.attr#attr.fire_atk}};  %%火攻
        AttrId =:= ?PL_ATTR_FIRE_DEF ->
            Agent#agent{attr = Agent#agent.attr#attr{fire_def = OAgent#agent.attr#attr.fire_def}};  %%火访
        AttrId =:= ?PL_ATTR_ICE_ATK ->
            Agent#agent{attr = Agent#agent.attr#attr{ice_atk = OAgent#agent.attr#attr.ice_atk}}; %%冰攻
        AttrId =:= ?PL_ATTR_ICE_DEF ->
            Agent#agent{attr = Agent#agent.attr#attr{ice_def = OAgent#agent.attr#attr.ice_def}}; %%冰防
        AttrId =:= ?PL_ATTR_MOVE_SPEED ->
            Agent#agent{attr = Agent#agent.attr#attr{move_speed = OAgent#agent.attr#attr.move_speed}};%%移动速度
        AttrId =:= ?PL_ATTR_RUN_SPEED ->
            Agent#agent{attr = Agent#agent.attr#attr{run_speed = OAgent#agent.attr#attr.run_speed}};%%移动速度
        true ->
            Agent
    end.

change_attr(#agent{idx = Idx, attr = Attr} = Agent, AttrId, AttrValue) ->
    if
        AttrId =:= ?PL_ATTR_HP ->
            {Agent#agent{hp = AttrValue}, [{?pd_attr_hp, AttrValue}]};
        AttrId =:= ?PL_ATTR_MP ->
            {Agent#agent{mp = AttrValue}, [{?pd_attr_mp, AttrValue}]};
        AttrId =:= ?PL_ATTR_SP ->
            {Agent#agent{attr = Attr#attr{sp = AttrValue}}, [{?pd_attr_sp, AttrValue}]};
        AttrId =:= ?PL_ATTR_NP ->
            {Agent#agent{attr = Attr#attr{np = AttrValue}}, [{?pd_attr_np, AttrValue}]};
        AttrId =:= ?PL_ATTR_STRENGTH ->
            {Agent#agent{attr = Attr#attr{strength = AttrValue}}, [{?pd_attr_strength, AttrValue}]}; %%力量
        AttrId =:= ?PL_ATTR_INTELLECT ->
            {Agent#agent{attr = Attr#attr{intellect = AttrValue}}, [{?pd_attr_intellect, AttrValue}]}; %%智力
        AttrId =:= ?PL_ATTR_NIMBLE ->
            {Agent#agent{attr = Attr#attr{nimble = AttrValue}}, [{?pd_attr_hp, AttrValue}]};%%敏捷
        AttrId =:= ?PL_ATTR_STRONG ->
            {Agent#agent{attr = Attr#attr{strong = AttrValue}}, [{?pd_attr_strong, AttrValue}]}; %%体质
        AttrId =:= ?PL_ATTR_ATK ->
            {Agent#agent{attr = Attr#attr{atk = AttrValue}}, [{?pd_attr_atk, AttrValue}]}; %%攻击
        AttrId =:= ?PL_ATTR_DEF ->
            {Agent#agent{attr = Attr#attr{def = AttrValue}}, [{?pd_attr_def, AttrValue}]}; %%防御
        AttrId =:= ?PL_ATTR_CRIT ->
            {Agent#agent{attr = Attr#attr{crit = AttrValue}}, [{?pd_attr_crit, AttrValue}]}; %%暴击
        AttrId =:= ?PL_ATTR_BLOCK ->
            {Agent#agent{attr = Attr#attr{block = AttrValue}}, [{?pd_attr_block, AttrValue}]};  %%格挡
        AttrId =:= ?PL_ATTR_PLIABLE ->
            {Agent#agent{attr = Attr#attr{pliable = AttrValue}}, [{?pd_attr_pliable, AttrValue}]};  %%柔韧
        AttrId =:= ?PL_ATTR_PURE_ATK ->
            {Agent#agent{attr = Attr#attr{pure_atk = AttrValue}}, [{?pd_attr_pure_atk, AttrValue}]}; %%无视防御伤害
        AttrId =:= ?PL_ATTR_BREAK_DEF ->
            {Agent#agent{attr = Attr#attr{break_def = AttrValue}}, [{?pd_attr_break_def, AttrValue}]}; %%破甲
        AttrId =:= ?PL_ATTR_ATK_DEEP ->
            {Agent#agent{attr = Attr#attr{atk_deep = AttrValue}}, [{?pd_attr_atk_deep, AttrValue}]}; %%伤害加深
        AttrId =:= ?PL_ATTR_ATK_FREE ->
            {Agent#agent{attr = Attr#attr{atk_free = AttrValue}}, [{?pd_attr_atk_free, AttrValue}]}; %%伤害减免
        AttrId =:= ?PL_ATTR_ATK_SPEED ->
            {Agent#agent{attr = Attr#attr{atk_speed = AttrValue}}, [{?pd_attr_atk_speed, AttrValue}]}; %%攻击速度
        AttrId =:= ?PL_ATTR_PRECISE ->
            {Agent#agent{attr = Attr#attr{precise = AttrValue}}, [{?pd_attr_precise, AttrValue}]};  %%精确
        AttrId =:= ?PL_ATTR_THUNDER_ATK ->
            {Agent#agent{attr = Attr#attr{thunder_atk = AttrValue}}, [{?pd_attr_thunder_atk, AttrValue}]};  %%雷公
        AttrId =:= ?PL_ATTR_THUNDER_DEF ->
            {Agent#agent{attr = Attr#attr{thunder_def = AttrValue}}, [{?pd_attr_thunder_def, AttrValue}]};  %%雷放
        AttrId =:= ?PL_ATTR_FIRE_ATK ->
            {Agent#agent{attr = Attr#attr{fire_atk = AttrValue}}, [{?pd_attr_fire_atk, AttrValue}]};  %%火攻
        AttrId =:= ?PL_ATTR_FIRE_DEF ->
            {Agent#agent{attr = Attr#attr{fire_def = AttrValue}}, [{?pd_attr_fire_def, AttrValue}]};  %%火访
        AttrId =:= ?PL_ATTR_ICE_ATK ->
            {Agent#agent{attr = Attr#attr{ice_atk = AttrValue}}, [{?pd_attr_ice_atk, AttrValue}]}; %%冰攻
        AttrId =:= ?PL_ATTR_ICE_DEF ->
            {Agent#agent{attr = Attr#attr{ice_def = AttrValue}}, [{?pd_attr_ice_def, AttrValue}]}; %%冰防
        AttrId =:= ?PL_ATTR_MOVE_SPEED ->
            case Idx < 0 of
                true ->
                    MoveVec = Agent#agent.move_vec,
                    {Agent#agent{attr = Attr#attr{move_speed = AttrValue}, move_vec = MoveVec#move_vec{x_speed = AttrValue}}, [{?pd_attr_move_speed, AttrValue}]}; %% 移动速度
                _ ->
                    {Agent#agent{attr = Attr#attr{move_speed = AttrValue}}, [{?pd_attr_move_speed, AttrValue}]} %% 移动速度
            end;
        AttrId =:= ?PL_ATTR_RUN_SPEED ->
            case Idx > 0 of
                true ->
                    MoveVec = Agent#agent.move_vec,
                    {Agent#agent{attr = Attr#attr{run_speed = AttrValue}, move_vec = MoveVec#move_vec{x_speed = AttrValue}}, [{?pd_attr_run_speed, AttrValue}]}; %% 跑步速度
                _ ->
                    {Agent#agent{attr = Attr#attr{run_speed = AttrValue}}, [{?pd_attr_run_speed, AttrValue}]} %% 跑步速度
            end;
        true ->
            {Agent, []}
    end.

% Internal method
change_agent_attr(#agent{idx = Idx} = Agent, AttrId, AttrValue) ->
    {Agent1, Fields} = change_attr(Agent, AttrId, AttrValue),
    Root = player_prop_zip_key:get_zip_keys_data_ex(#zip_keys_data{}, Fields),
    {[_Data1, Data]} = player_prop_zip_key:get_final_ret(Root),
    ?update_agent(Idx, Agent1),
    case Idx > 0 of
        true ->
            Msg = player_sproto:pkg_msg(?MSG_PLAYER_FIELD_CHANGE, {[Data]}),
            ?send_to_client(Agent1#agent.pid, Msg);
        _ ->
            case AttrId =:= ?PL_ATTR_MOVE_SPEED of
                true ->
                    [{_, Value}] = Fields,
                    map_aoi:broadcast_view_me_agnets_and_me(Agent, scene_sproto:pkg_msg(?MSG_SCENE_AGENT_DATA_CHANGE, {Idx, ?PL_MOVE_SPEED, Value}));
                _ ->
                    ignore
            end
    end,
    Agent1.

change_agent_attrs(#agent{idx = Idx} = Agent, Attrs, AttrType) ->
    put(?pd_agent_attrs_sync, []),
    {NAgent, ChangeData} = if
        AttrType =:= 1 ->
            {Attr, ChangeList} = agent_util:add_attrs_pre(Agent#agent.attr, Attrs),
            {Agent#agent{attr = Attr}, ChangeList};
        AttrType =:= 2 ->
            {Agent#agent{attr = agent_util:add_attrs(Agent#agent.attr, Attrs)}, Attrs};
        true ->
            {Agent, []}
    end,
    % 改变属性有可能改变最大血量,蓝量
    NNAgent = NAgent#agent{max_hp = NAgent#agent.attr#attr.hp, max_mp = NAgent#agent.attr#attr.mp},
    ?update_agent(Idx, NNAgent),
    Fields = util:get_pd_field(?pd_agent_attrs_sync, []),
    Root = player_prop_zip_key:get_zip_keys_data_ex(#zip_keys_data{}, Fields),
    {[_Data1, Data]} = player_prop_zip_key:get_final_ret(Root),
    Msg = player_sproto:pkg_msg(?MSG_PLAYER_FIELD_CHANGE, {[Data]}),
    ?ifdo(Idx > 0, ?send_to_client(NNAgent#agent.pid, Msg)),
    {NNAgent, ChangeData}.


