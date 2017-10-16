-module(pangzi_sup).

-behaviour(supervisor).

%% API
-export([start_link/0,
         all_dbs/0,
         table_info/1,
         all_workers/0]).

%% Supervisor callbacks
-export([init/1]).

-define(no_pangzi_behaviour, 1).
-include("../include/pangzi.hrl").
-include("../../common/include/inc.hrl").

                                                %-type db_table_meta() :: #db_table_meta{}.

%% Helper macro for declaring children of supervisor
-define(CHILD(I, Type), {I, {I, start_link, []}, transient, 5000, Type, [I]}).

%% 存放所有的db_table
-define(TAB, pangzi_tables).

-define(META_TYPE, pangzi:db_table_meta()).

%% 默认的数据持久时间 (分钟)
-define(DEFAULT_INVERVAL, 1).

%% ===================================================================
%% API functions
%% ===================================================================

start_link() ->
    %%?DEBUG_LOG("pangzi_sup start_link"),
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).


%% @doc show all alive pangzi workers.
all_workers() ->
    [Name || {Name,_,_,_}  <- supervisor:which_children(?MODULE)].

%% @doc return all db name in list.
-spec all_dbs() -> [atom()].
all_dbs() ->
    com_ets:keys(?TAB).

%% @doc info show db meta info.
-spec table_info(Tab :: atom()) -> ?META_TYPE | undefined.
table_info(Tab) ->
    case ets:lookup(?TAB, Tab) of
        [] -> undefined;
        [M] -> M
    end.

%% ===================================================================
%% Supervisor callbacks
%% ===================================================================

%%tables_name(Metas) ->
%%[Meta#db_table_meta.name || Meta <- Metas].

init([]) ->
    ok = application:ensure_started(mnesia),
    Mods = com_module:get_all_behaviour_mod("./ebin", ?pangzi_behaviour),

    Metas=get_all_meta_info(Mods),
    ?DEBUG_LOG("pangzi all db_table_meta:~p", [Mods]),

    ok=pangzi_gen_code:gen_db_module(Metas),

%%% start process for echo table
    ChildSpecs = [
                  {Meta#db_table_meta.name,
                   {pangzi_worker, start_link, [Meta]},
                   permanent,
                   100,
                   worker,
                   []
                  } || Meta <- Metas ],
    {ok, {{one_for_one, 1, 5}, ChildSpecs}}.


-include("../common/include/eunit_ext.hrl").

check_meta(Meta) ->
    %%?DEBUG_LOG("Meta:~p",[Meta]),
    ?Assert2(lists:member(Meta#db_table_meta.type, [?set, ?ordered_set]),
             "Error db_table_meta type is invailed ~p", [Meta]),

    ShrinkSize = Meta#db_table_meta.shrink_size,

    ?check(is_integer(ShrinkSize) andalso
           ShrinkSize > 0,
           "db_table_meta ~p shrink_size 无效, 必须>= 0", [Meta#db_table_meta.name]),

    ShrinkInterval = Meta#db_table_meta.shrink_interval,
    ?check(is_integer(ShrinkInterval)
           andalso ShrinkInterval > 0
           andalso ShrinkInterval =< 100,
           "db_table_meta ~p shrink_interval 无效, 必须 > 0 < 100", [Meta#db_table_meta.name]),


    case Meta#db_table_meta.kv of
        false -> ok;
        true ->
            ?Assert2(Meta#db_table_meta.index =:= [], "Error db_table_meta ~p 不能同时指定 kv 和index", [Meta])
    end,
    ok.



%get_options(EtsOps) ->
%[ %% defualt
%com_lists:get_member(named_table, EtsOps, named_table),
%com_lists:get_member(public, EtsOps, public),
%com_lists:get_member({write_concurrency, false}, EtsOps, {write_concurrency, true}),
%com_lists:get_member({read_concurrency, false}, EtsOps, {read_concurrency, true})
%]
%++
%com_lists:drop(
%fun(E) ->
%lists:member(E,
%[named_table,
%public,
%private,
%protected,
%{write_concurrency, true},
%{write_concurrency, false},
%{read_concurrency, true},
%{read_concurrency, false}
%]) end,
%EtsOps).


%% load an check mates
-spec get_all_meta_info([atom()]) -> [?META_TYPE].
get_all_meta_info(Modules) ->
    ?TAB = ets:new(?TAB, [protected, named_table, {keypos, #db_table_meta.name}]),
    lists:foldl(
      fun(Mod, AccIn) ->
              Metas = Mod:load_db_table_meta(),
              lists:map(
                fun(Meta) ->
                        check_meta(Meta),
                        case ets:insert_new(?TAB, {Meta#db_table_meta.name, Meta}) of
                            false ->
                                ?ERROR_LOG("meta name ~p repleate ~p other ~p", [Meta#db_table_meta.name, Meta, ets:lookup(?TAB, Meta#db_table_meta.name)]),
                                exit(badarg);
                            true ->
                                ok
                        end,
                        Meta
                end,
                Metas) ++ AccIn
      end,
      [],
      Modules).
