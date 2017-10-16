%%%-------------------------------------------------------------------
%%% @author hank
%%% @copyright (C) 2016, <COMPANY>
%%% @doc 标记 buff
%%%
%%% @end
%%% Created : 07. Mar 2016 12:05 PM
%%%-------------------------------------------------------------------
-module(buff_plug_tag).
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

apply(AAgent, BAgent, Target, #buff_cfg{id = BuffId, time = Time} = _Buff, _ExtInfo) ->
    BuffAgent = case Target of
        1 -> buff_system:get_real_buff_agent(AAgent);
        _ -> buff_system:get_real_buff_agent(BAgent)
    end,
    buff_system:send_buff2client(BuffAgent, BuffId, Time),
    _Ref = scene_eng:start_timer(Time, ?MODULE, {remove_buff, BuffAgent, BuffId}),
    ok.

remove_buff(Agent, BuffId) ->
    buff_system:cancel_buff2client(Agent, BuffId),
    ok.

handle_timer(_Ref, {remove_buff, Agent, BuffId}) ->
    remove_buff(Agent, BuffId).

