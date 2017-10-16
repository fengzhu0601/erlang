%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 12. 九月 2015 下午5:19
%%%-------------------------------------------------------------------
-module(map_point).
-author("clark").

%% API
-export(
[
    p_point_insert/2
    , p_point_remove/2
    , p_point_update/3
%%     ,get_p_point/1
%%     ,get_move_point/3
%%     ,get_move_end_point/3
]).


-include("inc.hrl").
-include("scene.hrl").
-include("scene_agent.hrl").

-define(p_point, '@p_point@').



%% INLINE
?INLINE(p_point_insert, 2).
p_point_insert(_Idx, _Point) -> ret:ok().
%%     case erlang:get({?p_point, Point}) of
%%         ?undefined ->
%%             erlang:put({?p_point, Point}, {1,{Idx, nil, nil}});
%%         Set ->
%%             ?Assert2(not gb_sets:is_member(Idx, Set), "idx ~p alread in ~p", [Idx, Point]),
%%             erlang:put({?p_point, Point}, gb_sets:insert(Idx, Set))
%%     end.

%% HACK 频繁的删除,肯能会印象性能
?INLINE(p_point_remove, 2).
p_point_remove(_Idx, _Point) -> ret:ok().
%%     case erlang:erase({?p_point, Point}) of
%%         {1, {Idx, nil, nil}} ->
%%             ok;
%%         Set ->
%%             ?Assert2(Set =/= ?undefined, "Idx ~p Point ~p", [Idx, Point]),
%%             ?assert(gb_sets:is_member(Idx, Set)),
%%             erlang:put({?p_point, Point}, gb_sets:delete(Idx, Set))
%%     end.

?INLINE(p_point_update, 3).
p_point_update(_Idx, _OldPoint, _NewPoint) -> ret:ok().
%%     ?ENV_develop((fun() -> {_,_} = NewPoint,
%%         {_,_} = OldPoint end)()),
%%
%%     %%?debug_log_scene_aoi("upos idx ~p o~p n~p", [Idx, OldPoint, NewPoint]),
%%     p_point_remove(Idx, OldPoint),
%%     p_point_insert(Idx, NewPoint).

%%
%% ?INLINE(get_p_point, 1).
%% get_p_point(Point) ->
%%     erlang:get({?p_point, Point}).
%%
%%
%% %% @doc
%% %get_move_point(?D_NONE, Point, _) -> Point;
%% get_move_point(?D_U, {X,0}, _) -> {X,0};
%% get_move_point(?D_U, {X,Y}, _) -> {X,Y-1};
%% get_move_point(?D_D, {X,Y}, {_,H}) when Y+1 =:= H -> {X, H};
%% get_move_point(?D_D, {X,Y}, _) -> {X,Y+1};
%% get_move_point(?D_L, {0,Y}, _) -> {0,Y};
%% get_move_point(?D_L, {X,Y}, _) -> {X-1,Y};
%% get_move_point(?D_R, {X,Y}, {W,_}) when X+1 =:= W-> {X,Y};
%% get_move_point(?D_R, {X,Y}, _) -> {X+1, Y};
%% get_move_point(?D_LU, {X,Y}, _) -> {erlang:max(0, X-1), erlang:max(0, Y-1)};
%% get_move_point(?D_RU, {X,Y}, {W,_}) -> {erlang:min(W-1, X+1), erlang:max(0, Y-1)};
%% get_move_point(?D_LD, {X,Y}, {_,H}) -> {erlang:max(0, X-1), erlang:min(H-1, Y+1)};
%% get_move_point(?D_RD, {X,Y}, {W,H}) -> {erlang:min(W-1, X+1), erlang:min(H-1, Y+1)}.
%%
%%
%% get_move_end_point(Dist, D, Point) ->
%%     get_move_end_point__(Dist, D, Point, {get(?pd_map_width), get(?pd_map_height)}).
%%
%%
%% get_move_end_point__(0, _D, Point, _Max) ->
%%     Point;
%% get_move_end_point__(Dist, D, Point, Max) ->
%%     Np = map_point:get_move_point(D, Point, Max),
%%     case scene_map:is_walkable(Np) of
%%         true ->
%%             get_move_end_point__(Dist-1, D, Np, Max);
%%         false ->
%%             Point
%%     end.
