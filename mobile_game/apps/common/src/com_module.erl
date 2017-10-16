-module(com_module).

-include("com_define.hrl").

%% ====================================================================
%% API functions
%% ====================================================================
-export([get_all_module/1,
         load_module_if_not_loaded/1,
         get_all_behaviour_mod/1,
         get_all_behaviour_mod/2,
         safe_apply/3,
         is_include_behaviour/2,
         behaviour_apply/4]).

%% @doc 返回所有的模块名称
%% TODO 在所有搜索路径中搜索
-spec get_all_module(Path::string()) -> [atom()].
get_all_module(Path)->
    {ok,ALLFiles} = file:list_dir(Path),
    lists:foldl(fun(FileName,AccModules)->
                        case get_module_by_beam(FileName) of
                            []->
                                AccModules;
                            NewModule->
                                [NewModule|AccModules]
                        end
                end, [] ,ALLFiles).

load_module_if_not_loaded(NewModule)->
    case erlang:module_loaded(NewModule) of
        false->
            c:l(NewModule);
        _->
            nothing
    end.

-spec get_all_behaviour_mod(string(), atom()) -> term().
get_all_behaviour_mod(Behaviour) ->
    lists:filter(fun(Mod)->is_include_behaviour(Mod,Behaviour) end,
                 lists:map(fun({Mod,_Path}) -> Mod end,
                           code:all_loaded())).

get_all_behaviour_mod(Path, Behaviour)->
    lists:filter(fun(Mod)->is_include_behaviour(Mod,Behaviour) end,
                 get_all_module(Path)).

%% @doc run func args for all of include behaviour module
-spec behaviour_apply(Path::string(), atom(), atom(), [term()]) -> term().
behaviour_apply(Path, Behaviour,Func,Args)->
    lists:foreach(fun(Mod)->
                          safe_apply(Mod, Func, Args)
                  end, get_all_behaviour_mod(Path, Behaviour)).

safe_apply(Mod, Func, Args)->
    try
        erlang:apply(Mod, Func, Args)
    catch
        E:R->
            io:format("~p:~p ~p ~p ~p ~n",[Mod, Func, Args,E,R])
    end.

%% ====================================================================
%% Internal functions
%% ====================================================================
get_module_by_beam(FileName)->
    case string:right(FileName,5) of
        ".beam"->
            erlang:list_to_atom(string:substr(FileName,1,string:len(FileName) - 5));
        _->
            []
    end.


-spec is_include_behaviour(atom(), atom()) -> boolean().
is_include_behaviour(Mod,Behav)->
    lists:foldl(fun({?behaviour, [B]}, _Acc) when Behav =:= B ->
                        ?true;
                   (_, Acc) -> Acc
                end,
                ?false,
                Mod:module_info(?attributes)).
