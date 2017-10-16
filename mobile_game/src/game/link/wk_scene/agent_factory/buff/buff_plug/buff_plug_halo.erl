-module(buff_plug_halo).

%% API
-export([
    apply/5
]).

-export(
[
    % handle_timer/2
]).

-include("inc.hrl").
-include("player.hrl").
-include("buff_system.hrl").
-include("scene_def.hrl").
-include("skill_struct.hrl").
-include("scene_agent.hrl").
-include("load_cfg_buff.hrl").
-include("load_spirit_attr.hrl").

apply(#agent{idx = Idx, buff_states = BuffState} = PetAgent, _, _, #buff_cfg{haloid = HaloId, time = Time}, _) ->
	case lists:keyfind(HaloId, 1, BuffState) of
		{HaloId, _, _} ->
			NewBuffState = lists:keyreplace(HaloId, 1, BuffState, {HaloId, Idx, com_time:now() + Time div 1000}),
			?update_agent(Idx, PetAgent#agent{buff_states = NewBuffState});
		_ ->
			NewBuffState = BuffState ++ [{HaloId, Idx, com_time:now() + Time div 1000}],
			?update_agent(Idx, PetAgent#agent{buff_states = NewBuffState})
	end,
	ok.

% apply(#agent{idx = AIdx, x = AX, y = AY} = AAgent, #agent{x = BX, y = BY} = BAgent, _Target, #buff_cfg{id = BuffId, haloid = HaloId} = _BuffCfg, {Time}) ->
%     case load_cfg_buff:lookup_buff_cfg(BuffId) of
%         #buff_cfg{haloid = HaloId} = BuffCfg ->
%             case load_cfg_halo:lookup_halo_cfg(HaloId) of
%                 #halo_cfg{radius = Radius, buff_id = HaloBuffId} ->
%                     ?DEBUG_LOG("Dis:~p, Radius:~p"m, [math:pow(((BX - AX) * (BX - AX) + (BY - AY) * (BY - AY)), 0.5), Radius]),
%                     case math:pow(((BX - AX) * (BX - AX) + (BY - AY) * (BY - AY)), 0.5) =< Radius / ?GRID_PIX of
%                         true ->
%                             buff_system:release(BAgent, AAgent, [{2, load_cfg_buff:lookup_buff_cfg(HaloBuffId)}], {Time});
%                         _ ->
%                             pass
%                     end;
%                 _ ->
%                     pass
%             end;
%         _ ->
%             pass
%     end,
%     ok.