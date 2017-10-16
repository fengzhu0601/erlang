%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 22. 四月 2016 上午11:12
%%%-------------------------------------------------------------------
-module(situation_calculate).
-author("clark").

%% API
-export
([
    calculate/2
]).


-include("inc.hrl").
-include("scene_agent.hrl").



calculate(ActionType, Idx) ->
    case ?get_agent(Idx) of
        #agent{} = A -> do_calculate(ActionType, A);
        _ -> 0
    end.




%% 计算威胁度
do_calculate(be_attack, #agent{x=X, y=Y, hp = Hp, max_hp = MaxHp}) ->
    case room_system:get_near_pos_player({X, Y}) of
        #agent{x=PlayerX, y=PlayerY} ->
            Dx = erlang:abs(PlayerX-X),
            Dy = erlang:abs(PlayerY-Y),
            if
                Dx =< 2 orelse Dy =< 2 ->

                    Rata = Hp/MaxHp,
                    if
                        Rata < 0.3 ->  80;  %% 距离逼近 + 生命值低
                        true -> 30          %% 距离逼近
                    end;

                true ->
                    30
            end;

        _ ->
            0
    end;


%% 计算灵活度
do_calculate(flexible, #agent{x=X, y=Y}) ->
    case room_system:get_near_pos_player({X, Y}) of
        #agent{x=PlayerX, y=PlayerY} ->
            Num = room_system:count_near_pos_monster({PlayerX, PlayerY, 3, 2}),
            if
                Num < 2 -> 70;
                true -> 20
            end;

        _ ->
            100
    end;


%% 计算收益
do_calculate(attack, #agent{x=_X, y=_Y}) ->
    50.
