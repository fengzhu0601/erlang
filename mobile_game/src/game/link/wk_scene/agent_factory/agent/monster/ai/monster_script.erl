%%%-------------------------------------------------------------------
%%% @author zl
%%% @doc 提供一些附加的通用行为
%%%      比如hp少于多少做什么
%%%      
%%%   script 由 instruc组成
%%%   每个instruct触发，由条件,动作组成
%%%   
%%% @end
%%%-------------------------------------------------------------------

-module(monster_script).

%%-include_lib("config/include/config.hrl").

-include("inc.hrl").
-include("scene_agent.hrl").


-export([init/2,
    uninit/1
]).

-record(instr,
{trigger = nil,
    percond,
    act
}).

%%-record(monster_script_cfg, {
%%    id, %% monster.id
%%    instructs %%[inster()]
%%}).

%% use this is for min use memory
-define(pd_m_scripts(__Idx), {'@m_scripts@', __Idx}).

init(_Idx, _MonsterId) ->
    todo.

uninit(Idx) ->
    erase(?pd_m_scripts(Idx)).

%%load_config_meta() ->
%%    [
%%        #config_meta{record = #monster_script_cfg{},
%%            fields = ?record_fields(monster_script_cfg),
%%            file = "monster_script.txt",
%%            keypos = #monster_script_cfg.id,
%%            verify = fun verify/1}
%%    ].
%%
%%
%%verify(#monster_script_cfg{id = Id, instructs = InsList} = _R) ->
%%    ?check(InsList =/= [] andalso is_list(InsList), "monster_script.txt [~p]  instructs bad", [Id]),
%%
%%    lists:foreach(fun({PerCond, Act}) ->
%%        ?check(is_valid_percond(PerCond),
%%            "monster_script.txt [~p]  instructs.percond ~p bad", [Id, PerCond]),
%%        ?check(is_valid_action(Act),
%%            "monster_script.txt [~p]  instructs.action ~p bad", [Id, Act]),
%%        ok;
%%        (_E) ->
%%            ?check(false, "monster_script.txt [~p]  instructs ~p bad", [Id, _E])
%%    end),
%%
%%    ok.

%%is_valid_percond({true, Var}) ->
%%    is_valid_var(Var);
%%is_valid_percond({Var, Test, Value}) ->
%%    is_valid_var(Var) andalso is_valid_test(Test)
%%        andalso is_valid_value(Value).
%%
%%is_valid_var(hp) -> true;
%%is_valid_var(_) -> false.
%%
%%is_valid_test(eq) -> true;
%%is_valid_test(ne) -> true;
%%is_valid_test(le) -> true;
%%is_valid_test(lt) -> true;
%%is_valid_test(ge) -> true;
%%is_valid_test(gt) -> true;
%%is_valid_test(_) -> false.
%%
%%is_valid_value({self_per, V}) ->
%%    V < 100 andalso V > 0;
%%is_valid_value(V) ->
%%    is_integer(V).


%%%% action
%%%%
%%%% release_skill
%%is_valid_action(debug_action) ->
%%    true;
%%is_valid_action(_) ->
%%    false.

%% =========== test 语法实现
test(eq, V1, V2) -> V1 =:= V2;
test(ne, V1, V2) -> V1 =/= V2;
test(le, V1, V2) -> V1 =< V2;
test(lt, V1, V2) -> V1 < V2;
test(ge, V1, V2) -> V1 >= V2;
test(gt, V1, V2) -> V1 > V2.



%%load_script(Monster)


%% ======== percondition 实现
%% {true, Var}
%% {TestOp, Var, Value}
%% TestOp:: eq, le, ne, ge, lt, gt
%% Value :: integer | {max_per, integer}
is_percondition_pass(nil, _Env) ->
    true;
is_percondition_pass({Var, Test, Value}, Env) ->
    case get_var_value(Var, Env) of
        nil -> false;
        V1 ->
            V2 = get_value(Value, Var, Env),
            test(Test, V1, V2)
    end;
is_percondition_pass({true, Var}, Env) ->
    case get_var_value(Var, Env) of
        true -> true;
        _ -> false
    end.

%% 实现每个var 的gettor
get_var_value(hp, Mon) ->
    Mon#agent.hp;
get_var_value(Var, _M) ->
    ?ERROR_LOG("unknonw var ~p", [Var]),
    nil.

get_full_var_value(hp, Mon) ->
    Mon#agent.max_hp;
get_full_var_value(Var, _M) ->
    ?ERROR_LOG("unknonw var ~p", [Var]),
    nil.

get_value({max_per, Value}, Var, Env) ->
    round((get_full_var_value(Var, Env) / 100) * Value).
get_value(Integer) ->
    Integer.

