%%%-------------------------------------------------------------------
%%% @author hank
%%% @copyright (C) 2016, <SANTI>
%%% @doc  博学buff实现
%%%
%%% @end
%%% Created : 16. May 2016 2:10 PM
%%%-------------------------------------------------------------------
-module(buff_plug_erudition).
-author("hank").

%% API
-export([apply/2,
    add/3,
    remove/2,
    replace/4,
    overlap/5]).

-include("inc.hrl").
-include("player.hrl").
-include("buff_system.hrl").
-include("scene_def.hrl").
-include("skill_struct.hrl").
-include("scene_agent.hrl").
-include("load_cfg_buff.hrl").
-include("load_spirit_attr.hrl").

apply(#buff_cfg{id = _ID, time = Time, pile = Pile} = _Buff, #agent{} = Agent) ->
%%    ReleaseT = com_time:timestamp_msec() + Time,
%%    BuffInfo = #buff_state{buffType = TAG, buffTime = ReleaseT},
%%    case buff_state:is_state(Agent, TAG) of
%%        true ->
%%            if
%%                Pile >= 0 ->
%%                    buff_state:buff_overlap(Agent, BuffInfo, Pile, _Buff, ?MODULE);
%%                true -> buff_state:buff_replace(Agent, BuffInfo, _Buff, ?MODULE)
%%            end;
%%        _ -> buff_state:buff_add(Agent, BuffInfo, _Buff, ?MODULE)
%%    end,
    ok.


add(_Agent, #buff_state{} = NBuff, #buff_cfg{} = _Buff) ->
    NBuff.

replace(_Agent, #buff_state{} = _OBuff, #buff_state{} = NBuff, #buff_cfg{} = _Buff) ->
    NBuff.

overlap(_Agent, #buff_state{} = _OBuff, #buff_state{} = NBuff, #buff_cfg{} = _Buff, _Pile) ->
    NBuff.

remove(_Agent, #buff_state{} = _OBuff) ->
    ok.
