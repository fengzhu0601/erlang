-module(pangzi_app).

-behaviour(application).

%% Application callbacks
-export([start/2, stop/1]).

-export([init_db_schema/0,
         delete_table/1
        ]).

-include_lib("common/include/com_log.hrl").

-define(MNESIA_DIR, "../Database/Mnesia.game").

%% @doc 初始化一个schema 如果已经存在不会再次创建.
%%
init_db_schema() ->
    case filelib:is_dir(?MNESIA_DIR) andalso
        {ok, []} =/= file:list_dir(?MNESIA_DIR)
    of
        false ->
            case filelib:ensure_dir(filename:dirname(?MNESIA_DIR) ++ "/") of
                ok ->
                    ok = application:set_env(mnesia, dir, ?MNESIA_DIR),
                    Nodes = [node()],
                    ok = mnesia:delete_schema(Nodes),
                    ok = mnesia:create_schema(Nodes),
                    ?INFO_LOG("init db schema ok");
                {error, Why} ->
                    ?ERROR_LOG("create ~p error ~p", [?MNESIA_DIR, Why]),
                    erlang:halt()
            end;
        true ->
            ?INFO_LOG("init db schema ok"),
            ok
    end.



delete_table(Tab) ->
    ok = application:set_env(mnesia, dir, ?MNESIA_DIR),
    ok=mnesia:start(),
    case mnesia:delete_table(Tab) of
        {atomic, ok} ->
            io:format("Clear ~p table!\n", [Tab]);
        {aborted, Reason} ->
            io:format("Clear ~p table aborted:~p!\n", [Tab, Reason])
    end.

%% ===================================================================
%% Application callbacks
%% ===================================================================
start(_StartType, _StartArgs) ->
    ok=application:set_env(mnesia, dc_dump_limit, 40),
    ok=application:set_env(mnesia, dump_log_write_threshold, 10000),
    ok=application:set_env(mnesia, dir, ?MNESIA_DIR),
    ok=pangzi_app:init_db_schema(),
    case application:start(mnesia) of
        ok -> ok;
        {error, {already_started, _}} -> ok;
        _E ->
            ?ERROR_LOG("start mnesia ~p", [_E]),
            exit(err)
    end,
    pangzi_sup:start_link().

stop(_State) ->
    %io:format("pangzi app call stop~p ~n", [_State]),
    % can not call stop mneia why?
    %%ok=application:stop(mnesia),
    ok.
