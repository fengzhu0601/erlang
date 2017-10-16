%%%-------------------------------------------------------------------
%%% @author fengzhu
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 05. 一月 2016 下午12:04
%%%-------------------------------------------------------------------
-module(load_cfg_monster_script).
-author("fengzhu").

%% API
-export([]).

-include_lib("config/include/config.hrl").
-include("inc.hrl").
-include("load_cfg_monster_script.hrl").

load_config_meta() ->
  [
    #config_meta{record = #monster_script_cfg{},
      fields = ?record_fields(monster_script_cfg),
      file = "monster_script.txt",
      keypos = #monster_script_cfg.id,
      verify = fun verify/1}
  ].


verify(#monster_script_cfg{id = Id, instructs = InsList} = _R) ->
  ?check(InsList =/= [] andalso is_list(InsList), "monster_script.txt [~p]  instructs bad", [Id]),

  lists:foreach(fun({PerCond, Act}) ->
    ?check(is_valid_percond(PerCond),
      "monster_script.txt [~p]  instructs.percond ~p bad", [Id, PerCond]),
    ?check(is_valid_action(Act),
      "monster_script.txt [~p]  instructs.action ~p bad", [Id, Act]),
    ok;
    (_E) ->
      ?check(false, "monster_script.txt [~p]  instructs ~p bad", [Id, _E])
                end),

  ok.

is_valid_percond({true, Var}) ->
  is_valid_var(Var);
is_valid_percond({Var, Test, Value}) ->
  is_valid_var(Var) andalso is_valid_test(Test)
    andalso is_valid_value(Value).

is_valid_var(hp) -> true;
is_valid_var(_) -> false.

is_valid_test(eq) -> true;
is_valid_test(ne) -> true;
is_valid_test(le) -> true;
is_valid_test(lt) -> true;
is_valid_test(ge) -> true;
is_valid_test(gt) -> true;
is_valid_test(_) -> false.

is_valid_value({self_per, V}) ->
  V < 100 andalso V > 0;
is_valid_value(V) ->
  is_integer(V).

%% action
%%
%% release_skill
is_valid_action(debug_action) ->
  true;
is_valid_action(_) ->
  false.
