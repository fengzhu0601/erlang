-module(aoe_sector).

-export([grid_point/2,
        aoe_grid_sector/3,
        point_in_sector_aoe/5,
        point_in_sector_aoe/7,
    floor_neg/1,
    angle_normal/1]).

%% Algorithm description:
%% assume the attack region is a sector, and every cell is a square;
%% let the LB(left bottom) point be the representative of the grid cell respectively,
%% the aoe is the set of the LBs.
%% partition the X-axis in a series of holes according to the cell side size.
%% for ervery hole on the x-axis, find the aoe range in the Y direction.
%% process these problems for each quadrant.


%%    ================ predefined macros ================
%% ?cell_side_size is the length of cell side, in pixel.
%%        the user should modify the macro according to the actual situation.
-define(cell_side_size, 40).

-define(half_pi, (math:pi()/2)).
-define(pi, (math:pi())).
-define(half_3pi, (3*math:pi()/2)).
-define(two_pi, (2*math:pi())).

%%    ================ auxilliary functions ================

floor_neg(Neg)->
    Trunc = erlang:trunc(Neg),
    if
        Neg < Trunc -> Trunc -1;
	true -> Trunc
    end.

%% the normalized angle should fall into the interval [0, 2*math:pi()).
angle_normal(Angle)->
    Round = erlang:trunc(Angle /?two_pi),
    Angle_t = Angle - Round * ?two_pi,
    if
        Angle_t >=0 -> Angle_t;
        true -> Angle_t + ?two_pi
    end.

%% the quadrant ordinal should be any of 0,1,2,3.
angle_quadrant(Angle_n)->
    erlang:trunc(2 * Angle_n / ?pi).

%% Q_s = 0,1,2,3 is the quadrant ordinal of Angle_n_s.
%%     Angle_amplitude =< ?two_pi.
%%     Angle_e = Angle_n_s + Angle_amplitude,
%%    notice: Angle_e may not be normal.
sector_quadrant({Q_s,Angle_n_s,Angle_e,Radius})->
    Half_pi = ?half_pi,
    Pi = ?pi,
    Half_3pi = ?half_3pi,
    Two_pi = ?two_pi,

    case Q_s of
        0 ->
            if
                Angle_e =< Half_pi -> 
                    [{0,Angle_n_s,Angle_e,Radius}];
		true -> 
                    [{0,Angle_n_s,Half_pi,Radius}] 
                    ++ 
                    sector_quadrant({1,Half_pi,Angle_e,Radius})
            end;
        1 ->
            if
                Angle_e =< Pi -> 
                    [{1,Angle_n_s,Angle_e,Radius}];
		true -> 
                    [{1,Angle_n_s,Pi,Radius}] 
                    ++ 
                    sector_quadrant({2,Pi,Angle_e,Radius})
            end;
        2 ->
            if
                Angle_e =< Half_3pi -> 
                    [{2,Angle_n_s,Angle_e,Radius}];
		true -> 
                    [{2,Angle_n_s,Half_3pi,Radius}] 
                    ++ 
                    sector_quadrant({3,Half_3pi,Angle_e,Radius})
            end;
        3 ->
            if
                Angle_e =< Two_pi -> 
                    [{3,Angle_n_s,Angle_e,Radius}];
		true -> 
                    [{3,Angle_n_s,Two_pi,Radius}] 
                    ++ 
                    sector_quadrant({0,0,Angle_e-Two_pi,Radius})
            end
    end.

%% return the coordinates of Left Bottom point of the grid that contains the point, {P_x, P_y}.
grid_point({P_x,P_y})->
    [G_x, G_y] = 
        lists:map(
            fun(P) ->
                O = P /?cell_side_size,
                T = erlang:trunc(O),
                Q =
                    if
                        O < T -> T - 1;
                        true -> T
                    end,
                Q * ?cell_side_size
            end,
        [P_x, P_y]),
    {G_x,G_y}.

grid_point(P_x,P_y)->
    grid_point({P_x,P_y}).

%%    ================ cell (representative) points around rays and arcs ================
yp_endpoint(Angle_n,Radius) ->
    erlang:trunc(Radius * math:sin(Angle_n) / ?cell_side_size) .

yn_endpoint(Angle_n,Radius) ->
    floor_neg(Radius * math:sin(Angle_n) / ?cell_side_size).

%% Angle_n /= math:pi()/2 or 3*math:pi()/2.
%% Ox /= 0.
yp_steppoint_on_ray(Ox, Angle_n) ->
    erlang:trunc(Ox * math:tan(Angle_n)) .

%% Angle_n /= math:pi()/2 or 3*math:pi()/2.
%% Ox /= 0.
yn_steppoint_on_ray(Ox, Angle_n) ->
    floor_neg(Ox * math:tan(Angle_n)).

yp_steppoint_on_arc(Ox, Radius)->
    erlang:trunc(math:sqrt(Radius*Radius - Ox*Ox*?cell_side_size*?cell_side_size)/?cell_side_size) .

yn_steppoint_on_arc(Ox, Radius)->
    floor_neg(-math:sqrt(Radius*Radius - Ox*Ox*?cell_side_size*?cell_side_size)/?cell_side_size).

%% Q = 0,1,2,3 is the quadrant ordinal of Angle_n,i.e.,
%%    Q = angle_quadrant(Angle_n);
%% X_n is the X coordinate for the endpoint, i.e.,
%%    X_n = Radius * math:cos(Angle_n);
%% Dx_n is the Division of X_n by ?cell_side_size, i.e.,
%%    Dx_n = X_n/?cell_side_size;
%% Tx_n is the Trunc of Dx_n, i.e.,
%%    Tx_n = erlang:trunc(Dx_n);
stepboxes_around_ray(Q, Tx_n, Dx_n, Angle_n, Radius)->
    if
        Tx_n == 0 ->
            case Q of
                0 -> [{0,0,yp_endpoint(Angle_n,Radius) }];
		1 -> [{-1,0,yp_endpoint(Angle_n,Radius) }];
		2 -> [{-1,yn_endpoint(Angle_n,Radius) ,-1}];
		3 -> [{0,yn_endpoint(Angle_n,Radius),-1}]
            end;
        Tx_n == Dx_n ->
            case Q of
                0 -> 
                    L0 = [{0,0}]++lists:map(fun(Ox) -> {Ox,yp_steppoint_on_ray(Ox, Angle_n)} end,lists:seq(1,Tx_n,1)),
                    L1 = lists:sublist(L0,1,Tx_n),
                    L2 = lists:sublist(L0,2,Tx_n),
                    lists:zipwith(fun({Ox,Yp1},{_,Yp2})->{Ox,Yp1,Yp2}end,L1,L2);
		1 -> 
                    L0 = lists:map(fun(Ox) -> {Ox,yp_steppoint_on_ray(Ox, Angle_n)} end,lists:seq(Tx_n,-1,1))++[{0,0}],
                    L1 = lists:sublist(L0,1,-Tx_n),
                    L2 = lists:sublist(L0,2,-Tx_n),
                    lists:zipwith(fun({_,Yp1},{Ox,Yp2})->{Ox,Yp1,Yp2}end,L2,L1);
		2 -> 
                    L0 = lists:map(fun(Ox) -> {Ox,yn_steppoint_on_ray(Ox, Angle_n)} end,lists:seq(Tx_n,-1,1))++[{0,-1}],
                    L1 = lists:sublist(L0,1,-Tx_n),
                    L2 = lists:sublist(L0,2,-Tx_n),
                    lists:zipwith(fun({Ox,Yp1},{_,Yp2})->{Ox,Yp1,Yp2}end,L1,L2);
		3 -> 
                    L0 = [{0,-1}]++lists:map(fun(Ox) -> {Ox,yn_steppoint_on_ray(Ox, Angle_n)} end,lists:seq(1,Tx_n,1)),
                    L1 = lists:sublist(L0,1,Tx_n),
                    L2 = lists:sublist(L0,2,Tx_n),
                    lists:zipwith(fun({_,Yp1},{Ox,Yp2})->{Ox,Yp1,Yp2}end,L2,L1)
            end;
        true ->
            case Q of
                0 ->
                    Lst1 = [{0,0}]++lists:map(fun(Ox) -> {Ox,yp_steppoint_on_ray(Ox, Angle_n)} end,lists:seq(1,Tx_n,1)),
                    Lst2 = lists:sublist(Lst1,2,Tx_n) ++[{Tx_n, yp_endpoint(Angle_n,Radius)}],
                    lists:zipwith(fun({Ox,Yp1},{_,Yp2})->{Ox,Yp1,Yp2}end,Lst1,Lst2);
		1 -> 
                    Lst1 = lists:map(fun(Ox) -> {Ox,yp_steppoint_on_ray(Ox, Angle_n)} end,lists:seq(Tx_n,-1,1))++[{0,0}],
                    Lst2 = [{Tx_n-1, yp_endpoint(Angle_n,Radius)}]++lists:sublist(Lst1,1,-Tx_n),
                    lists:zipwith(fun({_,Yp1},{Ox,Yp2})->{Ox,Yp1,Yp2}end,Lst1,Lst2);
		2 -> 
                    Lst1 = lists:map(fun(Ox) -> {Ox,yn_steppoint_on_ray(Ox, Angle_n)} end,lists:seq(Tx_n,-1,1))++[{0,-1}],
                    Lst2 = [{Tx_n-1, yn_endpoint(Angle_n,Radius)}]++lists:sublist(Lst1,1,-Tx_n),
                    lists:zipwith(fun({Ox,Yp1},{_,Yp2})->{Ox,Yp1,Yp2}end,Lst2,Lst1);
		3 -> 
                    Lst1 = [{0,-1}]++lists:map(fun(Ox) -> {Ox,yn_steppoint_on_ray(Ox, Angle_n)} end,lists:seq(1,Tx_n,1)),
                    Lst2 = lists:sublist(Lst1,2,Tx_n)++[{Tx_n, yn_endpoint(Angle_n,Radius)}],
                    lists:zipwith(fun({_,Yp1},{Ox,Yp2})->{Ox,Yp1,Yp2}end,Lst2,Lst1)
            end
    end.

%% Angle_n_s, Angle_n_e are in the same quadrant.
%% Q = 0,1,2,3 is the quadrant ordinal of Angle_n,i.e.,
%%    Q = angle_quadrant(Angle_n_s);
%% X_s, X_e are the X coordinates for the endpoint, i.e.,
%%    X_s = Radius * math:cos(Angle_n_s),
%%    X_e = Radius * math:cos(Angle_n_e);
%% Dx_s, Dx_e are the Divisions of X_s, X_e by ?cell_side_size, i.e.,
%%    Dx_s = X_s/?cell_side_size,
%%    Dx_e = X_e/?cell_side_size;
%% Tx_s, Tx_e are the Truncs of Dx_s, Dx_e, i.e.,
%%    Tx_s = erlang:trunc(Dx_s),
%%    Tx_e = erlang:trunc(Dx_e);
stepboxes_around_arc(Q,  Tx_s, Tx_e, Dx_s, Dx_e, Angle_n_s, Angle_n_e, Radius)->
    if
        Tx_s == Tx_e ->
            case Q of
                0 -> [{Tx_s, yp_endpoint(Angle_n_s,Radius), yp_endpoint(Angle_n_e,Radius)}];
		1 -> [{Tx_s - 1, yp_endpoint(Angle_n_e,Radius), yp_endpoint(Angle_n_s,Radius)}];
		2 -> [{Tx_s - 1, yn_endpoint(Angle_n_e,Radius), yn_endpoint(Angle_n_s,Radius)}];
		3 -> [{Tx_s, yn_endpoint(Angle_n_s,Radius), yn_endpoint(Angle_n_e,Radius)}]
            end;
        true ->
                case Q of
                    0 ->
                        {Ret_L,Left_end} =
                            if
                                Tx_e == Dx_e -> {[],Tx_e};
                                true ->{[{Tx_e, yp_steppoint_on_arc(Tx_e + 1, Radius), yp_endpoint(Angle_n_e,Radius)}],Tx_e+1}
                            end,
                        {Ret_R,Right_end} =
                            if
                                Tx_s == Dx_s -> {[],Tx_s};
        		        true -> {[{Tx_s, yp_endpoint(Angle_n_s,Radius), yp_steppoint_on_arc(Tx_s, Radius)}],Tx_s}
                            end;
		    1 ->
                        {Ret_L,Left_end} =
                            if
                                Tx_e == Dx_e -> {[],Tx_e};
                                true ->{[{Tx_e - 1, yp_endpoint(Angle_n_e,Radius), yp_steppoint_on_arc(Tx_e, Radius)}],Tx_e}
                            end,
                        {Ret_R,Right_end} =
                            if
                                Tx_s == Dx_s -> {[],Tx_s};
        		        true -> {[{Tx_s - 1, yp_steppoint_on_arc(Tx_s-1, Radius), yp_endpoint(Angle_n_s,Radius)}],Tx_s-1}
                            end;
		    2 ->
                        {Ret_L,Left_end} =
                            if
                                Tx_s == Dx_s -> {[],Tx_s};
                                true ->{[{Tx_s - 1, yn_steppoint_on_arc(Tx_s, Radius), yn_endpoint(Angle_n_s,Radius)}],Tx_s}
                            end,
                        {Ret_R, Right_end} =
                            if
                                Tx_e == Dx_e -> {[],Tx_e};
        		        true -> {[{Tx_e - 1, yn_steppoint_on_arc(Tx_e - 1, Radius), yn_endpoint(Angle_n_e,Radius)}],Tx_e-1}
                            end;
		    3 ->
                        {Ret_L,Left_end} =
                            if
                                Tx_s == Dx_s -> {[],Tx_s};
                                true ->{[{Tx_s, yn_endpoint(Angle_n_s,Radius), yn_steppoint_on_arc(Tx_s+1, Radius)}],Tx_s+1}
                            end,
                        {Ret_R, Right_end} =
                            if
                                Tx_e == Dx_e -> {[],Tx_e};
        		        true -> {[{Tx_e, yn_steppoint_on_arc(Tx_e, Radius), yn_endpoint(Angle_n_e,Radius)}],Tx_e}
                            end
                end,

                Ret_M =
                    if
                        Left_end == Right_end -> [];
			true ->
                            Span = Right_end - Left_end,
                            Lst0 = lists:seq(Left_end,Right_end-1,1),
                            Lst = 
                                case Q of 
                                    0 -> lists:map(fun(Ox)->yp_steppoint_on_arc(Ox, Radius) end,lists:seq(Left_end,Right_end,1));
                                    1 -> lists:map(fun(Ox)->yp_steppoint_on_arc(Ox, Radius) end,lists:seq(Left_end,Right_end,1));
                                    2 -> lists:map(fun(Ox)->yn_steppoint_on_arc(Ox, Radius) end,lists:seq(Left_end,Right_end,1));
                                    3 -> lists:map(fun(Ox)->yn_steppoint_on_arc(Ox, Radius) end,lists:seq(Left_end,Right_end,1))
                                end,
                            Lst1 = lists:sublist(Lst,1,Span),
                            Lst2 = lists:sublist(Lst,2,Span),
                            case Q of
                                0 -> lists:zip3(Lst0,Lst2,Lst1);
				1 -> lists:zip3(Lst0,Lst1,Lst2);
				2 -> lists:zip3(Lst0,Lst2,Lst1);
				3 -> lists:zip3(Lst0,Lst1,Lst2)
                            end
                    end,

                Ret_L ++ Ret_M ++ Ret_R
    end.

%% NOTICE: at the joining point, the stepbox for ray may not be indentical to that for arc.
umerge_stepboxes_around_arc_ray(Q, TL_stepboxes_ray,TL_stepboxes_arc)->
    Length_ray = erlang:length(TL_stepboxes_ray),
    Length_arc = erlang:length(TL_stepboxes_arc),
    case Q of
        0 ->
            Ret_L = lists:sublist(TL_stepboxes_ray,1,Length_ray-1),
            [{Ox,Y_L_ray,Y_U_ray}] = lists:sublist(TL_stepboxes_ray,Length_ray,1),
            [{Ox,Y_L_arc,Y_U_arc}|Ret_R] = TL_stepboxes_arc;
	1 ->
            Ret_L = lists:sublist(TL_stepboxes_arc,1,Length_arc-1),
            [{Ox,Y_L_arc,Y_U_arc}] = lists:sublist(TL_stepboxes_arc,Length_arc,1),
            [{Ox,Y_L_ray,Y_U_ray}|Ret_R] = TL_stepboxes_ray;
	2->
            Ret_L = lists:sublist(TL_stepboxes_arc,1,Length_arc-1),
            [{Ox,Y_L_arc,Y_U_arc}] = lists:sublist(TL_stepboxes_arc,Length_arc,1),
            [{Ox,Y_L_ray,Y_U_ray}|Ret_R] = TL_stepboxes_ray;
	3 ->
            Ret_L = lists:sublist(TL_stepboxes_ray,1,Length_ray-1),
            [{Ox,Y_L_ray,Y_U_ray}] = lists:sublist(TL_stepboxes_ray,Length_ray,1),
            [{Ox,Y_L_arc,Y_U_arc}|Ret_R] = TL_stepboxes_arc
    end,
    Ret_M = [{Ox,erlang:min(Y_L_ray,Y_L_arc),erlang:max(Y_U_ray,Y_U_arc)}],
    Ret_L ++ Ret_M ++ Ret_R.

%% converge the cell reprentative LBs bounded by the lower and upper curves between two vertical lines.
zip_stepboxes({Stepboxes_curve_L,Stepboxes_curve_U}) ->
     lists:append(
        lists:zipwith(
            fun({Ox,Y_LL,Y_LU},{Ox,Y_UL,Y_UU})->lists:map(fun(Y)->{Ox,Y} end,lists:seq(erlang:min(Y_LL,Y_UL),erlang:max(Y_LU,Y_UU),1))end, 
            Stepboxes_curve_L,
            Stepboxes_curve_U)).

%%    ================ output aoe sector grid(the LBs list) ================

%%    return:
%%        the aoe of the sector, represented with the LBs grid 
%%    Auguments:
%%    Angle_amplitude =< ?two_pi.
%%    Angle_s, Angle_amplitude are in radian.
%%    Radius is positive.
%%    Notice: every LB is representated with the coordinates, {X_p, Y_p},
%%        where both X_p and Y_p are in the unit of pixels.
aoe_grid_sector(Angle_s, Angle_amplitude, Radius)->
    Two_pi = 2*math:pi(),

    Angle_n_s =
        if
            Angle_amplitude == Two_pi -> 0;
	    true -> angle_normal(Angle_s)
        end,

    Angle_e = Angle_n_s + Angle_amplitude,
    Q_s = angle_quadrant(Angle_n_s),

    lists:map(
        fun({O_x,O_y}) -> {O_x * ?cell_side_size, O_y * ?cell_side_size} end,
        lists:append(
            lists:map(
                fun({Q,A_n_s,A_n_e,Radius_}) ->
                    X_s = Radius_ * math:cos(A_n_s),
                    Dx_s = X_s/?cell_side_size,
                    Tx_s = erlang:trunc(Dx_s),
                    X_e = Radius_ * math:cos(A_n_e),
                    Dx_e = X_e/?cell_side_size,
                    Tx_e = erlang:trunc(Dx_e),
                    TL_stepboxes_ray_s = stepboxes_around_ray(Q, Tx_s, Dx_s,  A_n_s, Radius_),
                    TL_stepboxes_ray_e = stepboxes_around_ray(Q, Tx_e, Dx_e, A_n_e,Radius_),
		    TL_stepboxes_arc = stepboxes_around_arc(Q,  Tx_s, Tx_e, Dx_s, Dx_e, A_n_s, A_n_e, Radius_),
                    {Stepboxes_curve_L,Stepboxes_curve_U} =
                        case Q of
                            0 -> {TL_stepboxes_ray_s,umerge_stepboxes_around_arc_ray(0, TL_stepboxes_ray_e,TL_stepboxes_arc)};
                            1 -> {TL_stepboxes_ray_e,umerge_stepboxes_around_arc_ray(1, TL_stepboxes_ray_s,TL_stepboxes_arc)};
                            2 -> {umerge_stepboxes_around_arc_ray(2, TL_stepboxes_ray_e,TL_stepboxes_arc),TL_stepboxes_ray_s};
                            3 -> {umerge_stepboxes_around_arc_ray(3, TL_stepboxes_ray_s,TL_stepboxes_arc),TL_stepboxes_ray_e}
                        end,
                    zip_stepboxes({Stepboxes_curve_L,Stepboxes_curve_U})
                end,
                sector_quadrant({Q_s,Angle_n_s,Angle_e,Radius})))).

%% ====================Deteminiation funtions==================

%% determin whether the point({P_x,P_y}) is in the sector({Center_x, Center_y, Angle_s, Angle_amplitude, Radius}).
point_in_sector_aoe(P_x,P_y,Center_x, Center_y, Angle_s, Angle_amplitude, Radius)->
    lists:member(grid_point({P_x - Center_x, P_y - Center_y}),aoe_grid_sector(Angle_s, Angle_amplitude, Radius)).

%% {P_x, P_y} is the coordinates of a Point.
%% {Center_x, Center_y} is the center of the sector.
%% Aoe_grid is a tuple list of point coordinates.
point_in_sector_aoe(P_x, P_y, Center_x, Center_y, Aoe_grid)->
    lists:member(grid_point({P_x - Center_x, P_y - Center_y}), Aoe_grid).

%% ======================================
