%%%-------------------------------------------------------------------
%%% @author hank
%%% @copyright (C) 2016, <COMPANY>
%%% @doc  buff 管理模块
%%%
%%% @end
%%% Created : 04. Mar 2016 5:22 PM
%%%-------------------------------------------------------------------
-module(buff_system).
-author("hank").

%% API
-export([
    send_buff2client/3,
    cancel_buff2client/2,
    release/4,
    get_real_buff_agent/1,
    delete_halo_buff/2
    ]).

-include("inc.hrl").
-include("player.hrl").
-include("buff_system.hrl").
-include("scene.hrl").
-include("skill_struct.hrl").
-include("scene_agent.hrl").
-include("load_cfg_buff.hrl").
-include("load_spirit_attr.hrl").

%% 这里的attack是指buff的产生者，有可能是玩家，也有可能是释放物
release(Attacker, Agent, Buffs, ExtInfo) ->
    lists:foreach(
        fun({Target, #buff_cfg{prob = Prob, type = Type, time = Time} = Buff}) ->
                RN = buff_util:get_random_num(1000),
                if
                    RN =< Prob andalso Time > 0 ->
                        % ?DEBUG_LOG("release buff:~p", [Buff]),
                        if
                            Type =:= 1 ->   %% 标记buff，客户端处理
                                buff_plug_tag:apply(Attacker, Agent, Target, Buff, ExtInfo);
                            Type =:= 2 ->   %% 属性buff
                                buff_plug_attrs:apply(Attacker, Agent, Target, Buff, ExtInfo);
                            Type =:= 3 ->
                                buff_plug_move:apply(Attacker, Agent, Target, Buff, ExtInfo);
                            Type =:= 4 -> % 加基本属性
                                buff_plug_addattr:apply(Attacker, Agent, Target, Buff, ExtInfo);
                            Type =:= 5 ->
                                buff_plug_hurt:apply(Attacker, Agent, Target, Buff, ExtInfo);
                            Type =:= 6 ->
                                buff_plug_group:apply(Attacker, Agent, Target, Buff, ExtInfo);
                            Type =:= 7 ->
                                buff_plug_passive:apply(Attacker, Agent, Target, Buff, ExtInfo);
                            % Type =:= 8 ->
                            %     buff_plug_release:apply(Buff, Agent);
                            % Type =:= 9 -> % 重置
                            %     buff_plug_reset:apply(Attacker, Agent, Target, Buff, ExtInfo);
                            % Type =:= 10 -> % 博学
                            %     buff_plug_erudition:apply(Buff, Agent);
                            Type =:= 11 ->  %% 光环buff
                                buff_plug_halo:apply(Attacker, Agent, Target, Buff, ExtInfo);
                            Type =:= 13 ->  %% 护盾
                                buff_plug_hudun:apply(Attacker, Agent, Target, Buff, ExtInfo);
                            true ->
                                ok
                        end;
                    true -> ignore
                end
        end,
        Buffs
    ),
    ok.

send_buff2client(_, BuffId, 0) ->
    ?ERROR_LOG("error, buff last time = 0, buff_id = ~p", [BuffId]);
send_buff2client(#agent{idx = Idx} = Agent, BuffId, Time) ->
    Timeout = Time + com_time:timestamp_msec(),
    map_aoi:broadcast_view_me_agnets_and_me(Agent, scene_sproto:pkg_msg(?MSG_SCENE_ADD_BUFF, {Idx, BuffId, Timeout})).

cancel_buff2client(#agent{idx = Idx} = Agent, BuffId) ->
    % ?INFO_LOG("cancel buff to clients id:~p", [BuffId]),
    map_aoi:broadcast_view_me_agnets_and_me(Agent, scene_sproto:pkg_msg(?MSG_SCENE_DEL_BUFF, {Idx, BuffId})).

get_real_buff_agent(?undefined) -> ?undefined;
get_real_buff_agent(#agent{fidx = FIdx, type = Type} = Agent) ->
    case Type of
        ?agent_skill_obj ->
            ?get_agent(FIdx);
        ?agent_pet ->
            ?get_agent(FIdx);
        _ ->
            Agent
    end.

%% 移除光环buff
delete_halo_buff(Idx, BuffList) ->
    lists:foreach(
        fun({BuffId, Ref, ChangeData}) ->
                Buff = load_cfg_buff:lookup_buff_cfg(BuffId), 
                case Buff#buff_cfg.type of
                    2 ->    %% 属性buff
                        buff_plug_attrs:delete_halo_buff(Idx, BuffId, Ref, ChangeData);
                    4 ->    %% 间隔性生效buff
                        buff_plug_addattr:delete_halo_buff(Idx, BuffId, Ref, ChangeData);
                    _ ->
                        pass
                end
        end,
        BuffList
    ).