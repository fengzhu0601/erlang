
%%-behaviour(monster_ai).

-export
([
    action/2,
    action/3
]).

%% 所有的状态装换都要只用这个 用于monster
-define(change_st(__NextSt, __Arg, __A, __DebugMsg),
    (fun(#agent{idx = __FIdx, state = FSt} = FA) ->
        ?debug_log_monster_ai("[st_change] idx ~p [~p -> ~p] ~p", [__FIdx, FSt, __NextSt, __DebugMsg]),
        ?MODULE:__NextSt(?event_start, __Arg,
            (?MODULE:FSt(?event_leave, nil, FA)))
    end)(__A)).

