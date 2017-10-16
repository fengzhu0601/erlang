%%%-------------------------------------------------------------------
%%% @author hank
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 09. Mar 2016 5:04 PM
%%%-------------------------------------------------------------------
-module(buff_plug_group).
-author("hank").

%% API
-export([
    apply/5
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

apply(#agent{idx = AIdx} = AAgent, #agent{idx = BIdx} = BAgent, Target, #buff_cfg{sub_buffs = Buffs}, ExtInfo) ->
    case is_list(Buffs) of
        true ->
            lists:foreach(
                fun({BuffId, Delay}) ->
                    case load_cfg_buff:lookup_buff_cfg(BuffId) of
                        #buff_cfg{} = Buff ->
                            case Delay =:= 0 of
                                true ->
                                    buff_system:release(AAgent, BAgent, [{Target, Buff}], ExtInfo);
                                _ ->
                                    scene_eng:start_timer(Delay, ?MODULE, {add_buff, AIdx, BIdx, [{Target, Buff}], ExtInfo})
                            end;
                        _ ->
                            ignore
                    end
                end,
                Buffs
            );
        _ ->
            ignore
    end.

handle_timer(_Ref, {add_buff, AIdx, BIdx, Buff, ExtInfo}) ->
    case ?get_agent(AIdx) =/= ?undefined andalso ?get_agent(BIdx) =/= ?undefined of
        true ->
            buff_system:release(?get_agent(AIdx), ?get_agent(BIdx), Buff, ExtInfo);
        _ ->
            ignore
    end.