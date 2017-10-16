%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 16. 四月 2016 上午11:31
%%%-------------------------------------------------------------------
-module(room_map).
-author("clark").

%% API
-export
([
    is_walkable/2,
    is_walkable/3,
    add_monster_wall/1,
    clear_monster_wall/0
]).


-include("inc.hrl").
-include("scene.hrl").

-define(monster_wall, '@monster_wall@').

%% 实现不同的实体类型有不同的行走限制
%% 例如怪不能走过地图的怪物墙

is_walkable(Idx, {X, Y, _h}) ->
    is_walkable(Idx, {X,Y});


is_walkable(Idx, {X, Y}) ->
    (get(?pd_map_id)):is_walkable(X, Y).
    % if
    %     Idx > 0 ->
    %         (get(?pd_map_id)):is_walkable(X, Y);
    %     true ->
    %         IsInWall = is_in_monster_wall(X),
    %         if
    %             IsInWall ->
    %                 false;
    %             true ->
    %                 (get(?pd_map_id)):is_walkable(X, Y)
    %         end
    % end.


is_walkable(Idx, X, Y) ->
    is_walkable(Idx, {X,Y}).


%% 怪物墙
add_monster_wall(X) ->

    if
        X > 0 ->
            X1 = X+30,
            ?INFO_LOG("============ add_monster_wall ~p", [X1]),
            List = util:get_pd_field(?monster_wall, []),
            List1 = [X1|List],
            util:set_pd_field(?monster_wall, List1);

        true ->
            pass
    end,
    ok.


clear_monster_wall() ->
    util:set_pd_field(?monster_wall, []),
    ok.

% is_in_monster_wall(X) ->
%     R = 2,
%     List = util:get_pd_field(?monster_wall, []),
%     lists:any
%     (
%         fun
%             (WallX0) ->
%                 WallX = WallX0,
%                 if
%                     X >= (WallX - R) andalso X =< (WallX + R) ->
%                         true;

%                     true ->
%                         false
%                 end
%         end,
%         List
%     ).

