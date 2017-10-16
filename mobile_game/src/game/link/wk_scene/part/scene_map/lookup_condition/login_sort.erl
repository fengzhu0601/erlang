%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 13. 十一月 2015 下午10:33
%%%-------------------------------------------------------------------
-module(login_sort).
-author("clark").

%% API
-export(
[
    enter/1
    , exit/1
    , is_near/2
]).



-include("inc.hrl").
-include("scene.hrl").
-include("scene_agent.hrl").

-define(login_sort_timer, login_sort_timer).
-define(login_sort_list, login_sort_list).


enter(Idx) ->
    List = util:get_pd_field(?login_sort_list, []),
    List1 = [{Idx}|List],
    util:set_pd_field(?login_sort_list, List1),
    sort(),
    ?get_agent(Idx).


exit(Idx) ->
    List = util:get_pd_field(?login_sort_list, []),
    List1 = lists:keydelete(Idx,1,List),
    util:set_pd_field(?login_sort_list, List1),
    sort(),
    ?get_agent(Idx).




sort() ->
    List = util:get_pd_field(?login_sort_list, []),
    List1 = lists:reverse(List),
    lists:foldl
    (
        fun({Idx}, Acc) ->
            Agent = ?get_agent(Idx),
            case Agent of
                #agent{} ->
                    Agent1 = Agent#agent{login_num=Acc},
                    ?update_agent(Idx, Agent1),
                    Acc+1;
                _ ->
                    Acc
            end
        end,
        1,
        List1
    ),
    ok.


%% is_near(#agent{idx = AIdx, login_num = ALNum, show_player_count = PlayerCount}, #agent{idx = BIdx, login_num = BLNum}) ->
%%     Limit = my_ets:get(misc_scene_view_max, 20),
%%     Limit1 = round(Limit/2),
%%     PlayerCount1 = round(PlayerCount/2),
%%     Limit2 = erlang:min(PlayerCount1, Limit1),
%%     ScenePlayerCounts = scene_player:players_count(),
%%
%%     {LL, LR}=
%%         if
%%             ALNum >= Limit2 andalso ScenePlayerCounts - ALNum >= Limit2 ->
%%                 {Limit2, Limit2};
%%             ALNum < Limit2 andalso ScenePlayerCounts - ALNum >= Limit2 ->
%%                 {ALNum, Limit2 + (Limit2 - ALNum)};
%%             ALNum >= Limit2 andalso ScenePlayerCounts - ALNum < Limit2 ->
%%                 {Limit2 + (Limit2 - (ScenePlayerCounts - ALNum)), ScenePlayerCounts - ALNum};
%%             true ->
%%                 {ALNum, ScenePlayerCounts - ALNum}
%%         end,
%%
%%
%%     if
%%         PlayerCount =:= 0 ->
%%             ret:error(isnt_near);
%%         AIdx =/= BIdx ->
%%             Dt = ALNum - BLNum,
%%             if
%%                 Dt >= 0 ->
%%                     Dt1 = erlang:abs(Dt),
%%                     if
%%                         Dt1 =< LL andalso ALNum =/= 0  andalso BLNum =/= 0 ->
%% %%                     io:format("LL is_near ok ~p~n",[{AIdx, ALNum, BIdx, BLNum}]),
%%                             ok;
%%                         true ->
%% %%                     io:format("LL is_near faile ~p~n",[{AIdx, ALNum, BIdx, BLNum}]),
%%                             ret:error(isnt_near)
%%                     end;
%%                 true ->
%%                     Dt2 = erlang:abs(Dt),
%% %%                    io:format("{Dt2:~p, LR:~p}", [Dt2, LR]),
%%                     if
%%                         Dt2 >= LR andalso ALNum =/= 0  andalso BLNum =/= 0 ->
%% %%                     io:format("LR is_near ok ~p~n",[{AIdx, ALNum, BIdx, BLNum}]),
%%                             ok;
%%                         true ->
%% %%                     io:format("LR is_near faile ~p~n",[{AIdx, ALNum, BIdx, BLNum}]),
%%                             ret:error(isnt_near)
%%                     end
%%             end;
%%
%%         true ->
%%             ok
%%     end;
%% %%     if
%% %%         AIdx =/= BIdx ->
%% %%             Dt = erlang:abs(ALNum - BLNum),
%% %%             if
%% %%                 Dt =< Limit2 andalso ALNum =/= 0  andalso BLNum =/= 0 ->
%% %% %%                     io:format("is_near ok ~p~n",[{AIdx, ALNum, BIdx, BLNum}]),
%% %%                     ok;
%% %%                 true ->
%% %% %%                     io:format("is_near faile ~p~n",[{AIdx, ALNum, BIdx, BLNum}]),
%% %%                     ret:error(isnt_near)
%% %%             end;
%% %%         true ->
%% %%             ok
%% %%     end;

is_near(#agent{login_num = ALNum, show_player_count = PlayerCount}, #agent{login_num = BLNum}) ->
    Limit = my_ets:get(misc_scene_view_max, 20),
    Limit1 = erlang:min(Limit, PlayerCount),
    Dt = ALNum - BLNum,
    if
        Dt =< Limit1 -> ok;
        true -> ret:error(isnt_near)
    end;


is_near(_A, _B) ->
    ret:error(isnt_near).

