%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 15. 三月 2016 下午5:41
%%%-------------------------------------------------------------------
-module(my_ets).
-author("clark").

%% API
-export
([
    set/2
    , get/2
    , delete/1
    , call_fun/3
    , cast_fun/3
]).



%% 仅用于回调,不对外提供
-export
([
    self_add/1
    , self_dec/1
]).





-define(global_table, global_table).
-define(get_global_key(X), {my_ets, X}).


get(Key, Default) ->
    case ets:lookup(?global_table, ?get_global_key(Key)) of
        [] ->
            Default;
        [{?get_global_key(Key), Val}] ->
            Val
    end.


set(Key, Val) ->
    Key1 = ?get_global_key(Key),
    ets:insert(?global_table, {Key1, Val}),
    case {Key, Val} of
        {center_svr_node_info, {CenterSvrNode, true}} ->
            com_prog:monitor_center_svr_info([{team_server, CenterSvrNode}, {arena_server, CenterSvrNode}]);
        _ ->
            pass
    end.


delete(Key) ->
    Key1 = ?get_global_key(Key),
    ets:delete(?global_table, Key1).



cast_fun(Mod, Fun, Args) ->
    ?global_table!{sync, Mod, Fun, Args},
    ok.

call_fun(Mod, Fun, Args) ->
    {ok, Ret} = gen_server:call(?global_table, {sync, Mod, Fun, Args}),
    Ret.



%% private ---------------
%% 慎用
self_add(Key) ->
    Val = get(Key, 0),
    set(Key, Val+1),
    Val+1.

%% 慎用
self_dec(Key) ->
    Val = get(Key, 0),
    set(Key, Val-1),
    Val-1.
