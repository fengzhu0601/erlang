%% coding:utf-8
%%%-------------------------------------------------------------------
%%% @author wcg
%%% @doc 
%%%
%%% @end
%%%-------------------------------------------------------------------
%% API
-module(pet_ai).
-include("inc.hrl").
-include("scene.hrl").
-include("scene_agent.hrl").
-include("scene_monster.hrl").
-include("monster_ai.hrl").

-export([
    st_stand/3
]).

-export([handle_timer/2]).

-define(enable_debug_log_pet_ai, true).

-define(get_pet_enemy(IDX), get({pet_enemy, IDX})).
-define(put_pet_enemy(IDX, Agent), put({pet_enemy, IDX}, Agent)).
-define(erase_pet_enemy(IDX), erase({pet_enemy, IDX})).

-define(RELEASE_SKILL_RANGE, 3).

action(Event, Agent) ->
    action(Event, nil, Agent).

action(Event, EventArg, A) ->
    ?debug_log_pet_ai("~p ~p ~p", [A#agent.idx, A#agent.state, Event]),
    ?MODULE:(A#agent.state)(Event, EventArg, A).

st_stand(?event_start, _, A) ->
    ?assert(?undefined =:= ?get_m_enemy(A#agent.idx)),
    ?update_agent(A#agent.idx, A#agent{state = ?st_stand});  %% do nothing
st_stand(?event_leave, _, A) -> A;
st_stand(?event_has_enemy, _, A) -> A;
st_stand(?event_beat_back_stiff_end, _, A) -> A;
st_stand(?event_stiff_end, _, A) -> ?change_st(?st_reaction, 800, A, <<"event_stiff_end">>);
st_stand(?event_move_step, _, A) -> A;
st_stand(?event_move_over, _Arg, A) -> A;
st_stand(_Event, _Arg, _A) ->
    ?ERROR_LOG("idx ~p unknow event ~p arg ~p st ~p", [_A#agent.idx, _Event, _Arg, _A#agent.state]).

%% state_timer timeout
handle_timer(_Ref, {Event, Idx}) ->
    #agent{state = St} = A = ?get_agent(Idx),
    ?ERROR_LOG("~p ~p ~p", [Idx, St, Event]),
    ?MODULE:St(Event, nil, A);
handle_timer(_Ref, {Event, Arg, Idx}) ->
    #agent{state = St} = A = ?get_agent(Idx),
    ?debug_log_pet_ai("~p ~p ~p", [Idx, St, Event]),
    ?MODULE:St(Event, Arg, A);
handle_timer(_Ref, Msg) ->
    ?ERROR_LOG("unknown msg ~p", [Msg]).

