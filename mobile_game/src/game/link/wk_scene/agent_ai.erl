%%% coding:utf-8
%%%-------------------------------------------------------------------
%%% @author wcg
%%% @doc 
%%%
%%% @end
%%%-------------------------------------------------------------------
%% API
-module(agent_ai).

-include("inc.hrl").

-define(DEFAULT_EXPORTS, [{action, 3}, {action, 2}]).

-export
([
    parse_transform/2
]).


parse_transform(Forms, _Opts) ->
    {ok, Meta} = smerl:new_from_forms(Forms),
    StFunList = get_st_func_exports(Meta),
    NewMeta = smerl:set_exports(Meta, StFunList ++ ?DEFAULT_EXPORTS),
    smerl:to_forms(NewMeta).

get_st_func_exports(Meta) ->
    Fun = fun({function, _Line, FuncName, 3, _Clauses}) ->
        case is_st_prefix(FuncName) of
            ?true ->
                {?true, {FuncName, 3}};
            ?false ->
                ?false
        end;
        (_) ->
            ?false
    end,
    lists:filtermap(Fun, smerl:get_all_func(Meta)).

is_st_prefix([$s, $t, $_ | _]) ->
    ?true;
is_st_prefix(FuncName) when is_list(FuncName) ->
    ?false;
is_st_prefix(FuncName) when is_atom(FuncName) ->
    is_st_prefix(atom_to_list(FuncName)).
