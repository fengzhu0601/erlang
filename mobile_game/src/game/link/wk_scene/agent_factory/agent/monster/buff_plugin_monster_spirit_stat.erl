%%%-------------------------------------------------------------------
%%% @author zl
%%% @doc 给怪物的,因为怪物在scene场景,不能和player公用一个模块
%%%
%%% @end
%%%-------------------------------------------------------------------

-module(buff_plugin_monster_spirit_stat).

-include("inc.hrl").
-include("load_spirit_attr.hrl").
%%-include("buff.hrl").
%%-include("buff_plugin.hrl").

%%-include("scene.hrl").
%%-include("scene_agent.hrl").


%%%% sprite 的操作 如果更改的是MAxHP, 会自动调整Hp
%%add(#buff_cfg{type=Type, buff_or_debuff= Effect, value=Value }=Cfg, Idx) -> 
%%case ?get_agent(Idx) of
%%?undefined ->
%%?ERROR_LOG("can not find monster ~p", [Idx]);
%%#agent{state=?st_die} ->
%%ok; %% TODO return can remove
%%A ->
%%%% Value 可以是整数和浮点数, 浮点数表示百分比
%%ChangeV =
%%if is_float(Value) ->
%%round(Value* scene_monster:get_spirit_by_sat(A, Type));
%%true ->
%%Value
%%end,

%%%% TODO 合并msg,一起发送 push, block
%%if Effect =:= ?POSITIVE_BUFF -> %% ++
%%scene_monster:add_spirit_by_sat(A, Type, ChangeV);
%%true ->
%%scene_monster:del_spirit_by_sat(A, Type, ChangeV)
%%end,

%%Buff = buff:new(Cfg),
%%scene_monster_buff:apply_after(Buff, Idx),
%%Buff#buff{extern=ChangeV}
%%end.

%%%% add times
%%update(Cfg, Buff, _Arg) -> 
%%buff_plugin:default_update(Cfg, Buff).

%%del(Buff, Idx) ->
%%case ?get_agent(Idx) of
%%?undefined ->
%%?ERROR_LOG("can not find monster ~p", [Idx]);
%%#agent{state=?st_die} ->
%%ok;
%%A ->
%%case buff:lookup_buff_cfg(Buff#buff.id) of
%%#buff_cfg{buff_or_debuff= ?POSITIVE_BUFF, type=Type} -> %%
%%scene_monster:del_spirit_by_sat(A, Type, Buff#buff.extern);
%%#buff_cfg{buff_or_debuff= ?NEGATIVE_BUFF, type=Type} -> %%
%%scene_monster:add_spirit_by_sat(A, Type, Buff#buff.extern)
%%end
%%end.


%%interval(#buff{times=0},_) -> remove;
%%interval(#buff{times=Times}=Buff, _) -> 
%%Buff#buff{times=Times-1}.

