%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%% 计算弹道
%%% @end
%%% Created : 10. 九月 2015 上午4:44
%%%-------------------------------------------------------------------
-module(calculate_trajectory).
-author("clark").

%% API
-export(
[
    direct_path/6
    , opposite_dirc/1
]).


-include("inc.hrl").
-include("scene.hrl").
-include("scene_agent.hrl").


%% 返回一条点ａ到点b的路径，如果寻路中有不可走点
%% 则直接返回
%% HACK c
%% direct_path(Xs,Ys,Xd,Yd, <<>>, maxStep)
%% -> [] | [D,..]
direct_path(Xs, Ys, _, _, Ds, 0) ->
    {lists:reverse(Ds), Xs, Ys};
direct_path(X, Y, X, Y, Ds, _) ->
    {lists:reverse(Ds), X, Y};
direct_path(Xs, Ys, Xd, Yd, Ds, N) ->
    if
        Xd > Xs ->
            Nx = Xs + 1, % ->
            if
                Yd < Ys -> % ^
                    Ny = Ys - 1,
                    D = ?D_RU;
                Yd > Ys ->
                    Ny = Ys + 1,
                    D = ?D_RD;
                true ->
                    Ny = Ys,
                    D = ?D_R
            end;
        Xd < Xs ->
            Nx = Xs - 1,
            if
                Yd < Ys ->
                    Ny = Ys - 1,
                    D = ?D_LU;
                Yd > Ys ->
                    Ny = Ys + 1,
                    D = ?D_LD;
                true ->
                    Ny = Ys,
                    D = ?D_L
            end;
        true ->
            Nx = Xs,
            if
                Yd < Ys ->
                    Ny = Ys - 1,
                    D = ?D_U;
                true ->
                    Ny = Ys + 1,
                    D = ?D_D
            end
    end,

    case scene_map:is_walkable(Nx, Ny) of
        ?true ->
            direct_path(Nx, Ny, Xd, Yd, [D | Ds], N - 1);
        ?false ->
            %%?WARN_LOG("direct_path point nonwalkable ~p", [{Nx, Ny}]),
            {lists:reverse(Ds), Xs, Ys}
    end.


%% 相反矢量
opposite_dirc(?D_U) -> ?D_D;
opposite_dirc(?D_D) -> ?D_U;
opposite_dirc(?D_L) -> ?D_R;
opposite_dirc(?D_R) -> ?D_L;
opposite_dirc(?D_LU) -> ?D_RD;
opposite_dirc(?D_RU) -> ?D_LD;
opposite_dirc(?D_LD) -> ?D_RU;
opposite_dirc(?D_RD) -> ?D_LU;
opposite_dirc(N) -> N.

%% 向前矢量
get_forth_vector(?D_L, RushRange) -> RushRange;
get_forth_vector(?D_R, RushRange) -> RushRange.