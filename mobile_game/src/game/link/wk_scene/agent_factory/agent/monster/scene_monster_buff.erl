%%%-------------------------------------------------------------------
%%% @author zl
%%% @doc 管理场景怪物的buff
%%%
%%% @end
%%%-------------------------------------------------------------------

-module(scene_monster_buff).

-include("inc.hrl").
%%-include("buff.hrl").

%%-include("scene_agent.hrl").

%%-export([add_buff/3
%%,apply_after/2
%%]).

%%%% cb
%%-export([handle_timer/2]).

%%-define(mon_buff(Idx), {mon_buff, Idx}).

%%%% player process
%%apply_after(Buff, Idx) ->
%%scene_eng:start_timer(Buff#buff.interval * 1000,
%%?MODULE,
%%{apply_interval, Idx, Buff#buff.id}),
%%ok.

%%%%cancel_apply_interval(Buff) ->
%%%%timer_eng:cancel_timer({buff, Buff#buff.id}).


%%%% 死亡时移除的buff
%%%%remove_all_buffs_when_die() ->
%%%%Mng = get(?pd_buff_mmg),
%%%%put(?pd_buf_mng,
%%%%buff:remove_all_buffs_when_die(get(?pd_buf_mng))).


%%%% TODO delete buff then monster die.
%%%% shuld be woking
%%add_buff(BuffList, #agent{idx=Idx}, _ReleaseA) ->
%%Mng=
%%lists:foldl(fun(BuffId, Acc) ->
%%buff:add(buff:lookup_buff_cfg(BuffId), Idx, Acc)
%%end,
%%get_buff_mng(Idx),
%%BuffList),
%%put(?mon_buff(Idx), Mng).


%%%%del_buff(BuffId) ->


%%%% @private INLINE
%%get_buff_mng(Idx) ->
%%case get(?mon_buff(Idx)) of
%%?undefined ->
%%buff:new_mng();
%%Mng ->
%%Mng
%%end.

%%handle_timer(_TRef, {apply_interval, Idx, BuffId}) ->
%%case get(?mon_buff(Idx)) of
%%?undefined ->
%%?ERROR_LOG("idx ~p apply_interval buff ~p but can not mng", [Idx, BuffId]);
%%_Mng ->
%%?debug_log_buff("monster ~p apply buff ~p", [Idx, BuffId]),
%%case gb_trees:lookup(BuffId, _Mng) of
%%?none ->
%%?ERROR_LOG("idx ~p apply_interval buff ~p but can not find", [Idx, BuffId]);
%%{?value, Buff} ->
%%Plugin = buff:get_plugin(BuffId),
%%Mng=
%%case Plugin:interval(Buff, nil) of
%%remove ->
%%?debug_log_buff("plugin ~p interval remove buff ~p", [Plugin, Buff#buff.id]),
%%Plugin:del(Buff, nil),
%%gb_trees:delete(BuffId, _Mng);
%%NewBuff ->
%%?assert(is_record(NewBuff, buff)),
%%gb_trees:update(BuffId, Buff, _Mng)
%%end,
%%put(?mon_buff(Idx), Mng)
%%end
%%end.
