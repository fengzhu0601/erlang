%%%-------------------------------------------------------------------
%%% @author zl
%%% @doc run in scene process
%%%
%%% @end
%%%-------------------------------------------------------------------

-module(buff_plugin_monster_hp).

-include("inc.hrl").

%%-include("buff.hrl").
%%-include("buff_plugin.hrl").

%%-include("scene.hrl").
%%-include("scene_agent.hrl").
%%%%-include("scene_monster.hrl").

%%effect(#buff{extern=V,id=Id}, Idx) ->
%%case ?get_agent(Idx) of
%%?undefined ->
%%?ERROR_LOG("can not find monster ~p", [Idx]);
%%#agent{state=?st_die} ->
%%ok;
%%A ->
%%case buff:lookup_buff_cfg(Id, #buff_cfg.buff_or_debuff) of
%%?POSITIVE_BUFF ->
%%scene_monster:add_hp(A, V);
%%?NEGATIVE_BUFF ->
%%scene_monster:del_hp(A, V)
%%end
%%end.


%%add(Cfg, Idx) -> 
%%?assert(Idx < 0),
%%?assert(com_process:get_type() =:= ?PT_SCENE),
%%Buff = buff:new(Cfg),
%%scene_monster_buff:apply_after(Buff, Idx),
%%effect(Buff, Idx),
%%Buff.


%%%% add times
%%update(Cfg, Buff, _Arg) -> 
%%buff_plugin:default_update(Cfg, Buff).


%%del(_Buff, _Idx) ->
%%ok.

%%interval(#buff{times=0}, _) -> remove;
%%interval(#buff{times=Times}=Buff, Arg) -> 
%%effect(Buff, Arg),
%%Buff#buff{times=Times-1}.

