%%%-------------------------------------------------------------------
%%% @author hank
%%% @copyright (C) 2016, <COMPANY>
%%% @doc  buff cd重置功能
%%%
%%% @end
%%% Created : 04. Mar 2016 6:13 PM
%%%-------------------------------------------------------------------
-module(buff_plug_reset).
-author("hank").

%% API
-export([
    apply/5
    % add/3,
    % replace/4,
    % overlap/5
    % remove_buff/2
]).

-include("inc.hrl").
-include("player.hrl").
-include("buff_system.hrl").
-include("scene_def.hrl").
-include("skill_struct.hrl").
-include("scene_agent.hrl").
-include("load_cfg_buff.hrl").
-include("load_spirit_attr.hrl").

apply(AAgent, BAgent, Target, #buff_cfg{id = BuffId, reset_skill_id = SkillId} = _Buff, _ExtInfo) ->
    BuffAgent = case Target of
        1 -> buff_system:get_real_buff_agent(AAgent);
        2 -> buff_system:get_real_buff_agent(BAgent)
    end,
    ok.

% apply(#buff_cfg{id = _ID, time = Time} = BuffCfg, #agent{idx = Idx, attr = Attr, hp = Hp, max_hp = MaxHp, mp = Mp,
%     max_mp = MaxMp} = Agent) ->
%     ReleaseT = com_time:timestamp_msec() + Time,
%     BuffInfo = #buff_state{buffType = ?BUFF_TYPE_RESETCD, buffTime = ReleaseT},
%     buff_state:buff_add(Agent, BuffInfo, BuffCfg, ?MODULE),
%     ok.


% add(#agent{idx = Idx} = Agent, #buff_state{} = NBuff, #buff_cfg{reset_skill_id = RestId} = _Buff) ->
%     % 改变客户端进程数据
% %%    world:send_to_player(Idx, ?mod_msg(skill_mng, {reset_skill_cd, RestId})),
%     map_aoi:broadcast_view_me_agnets_and_me(Agent,
%         scene_sproto:pkg_msg(?MSG_SCENE_AGENT_DATA_CHANGE,
%             {Idx, ?PL_SKILL_CD_RESET, RestId})),
%     NBuff.

% replace(_Agent, #buff_state{} = _OBuff, #buff_state{} = NBuff, #buff_cfg{} = _Buff) ->
%     NBuff.

% overlap(_Agent, #buff_state{} = _OBuff, #buff_state{} = NBuff, #buff_cfg{} = _Buff, _Pile) ->
%     NBuff.

% remove(_Agent, #buff_state{} = _OBuff) ->
%     ok.
